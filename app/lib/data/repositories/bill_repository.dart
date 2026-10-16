import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/dates.dart';
import '../../core/utils/streams.dart';
import '../local/database.dart';
import '../providers.dart';
import 'category_repository.dart';
import 'local_writer.dart';

/// Bill types (FR-B1), stored as these keys.
const billTypes = ['electricity', 'gas', 'mobile', 'internet', 'dth', 'water', 'insurance', 'other'];

/// "Comes every N months" choices (FR-B6).
const billGaps = [1, 2, 3, 6, 12];

/// Popular providers with their usual gap (FR-B1: "Popular in Gujarat"). Names are brand names, not translated.
const popularProviders = [
  (name: 'Torrent Power', type: 'electricity', gap: 2),
  (name: 'Adani Total Gas', type: 'gas', gap: 2),
];

/// What the Add bill form saves (FR-B6). Money in paise.
class BillDraft {
  const BillDraft({
    required this.type,
    required this.name,
    this.customerId,
    required this.everyMonths,
    required this.nextDue,
    this.usualAmount,
    this.reminderDays = const [],
  });

  final String type;
  final String name;
  final String? customerId;
  final int everyMonths;
  final LocalDate nextDue;
  final int? usualAmount;
  final List<int> reminderDays;
}

/// A bill with its payments, newest first.
class BillWithPayments {
  const BillWithPayments(this.bill, this.payments);

  final Bill bill;
  final List<BillPayment> payments;

  LocalDate get nextDue => LocalDate.parse(bill.nextDueDate);

  /// Paid for a due date in [month] (IST), so the card shows "Paid".
  bool paidIn(LocalDate month) => payments.any((p) {
        final d = LocalDate.parse(p.dueDate);
        return d.year == month.year && d.month == month.month;
      });

  /// Last bill amount, else the usual amount (shown on the card).
  int? get lastAmount => payments.isNotEmpty ? payments.first.amount : bill.usualAmount;
}

/// One amount suggestion: a past bill (FR-B4).
class BillSuggestion {
  const BillSuggestion(this.amount, this.dueDate);

  final int amount;

  /// Null for the usual amount (first payment).
  final LocalDate? dueDate;
}

/// Totals at the top of the Bills tab (screen 17), from SQL.
class BillSummary {
  const BillSummary({required this.total, required this.paid, required this.left});

  /// Paid this month plus the expected amount of the ones still due this month.
  final int total;
  final int paid;
  final int left;
}

/// Bills (FR-B1–B7). Premium; the server re-checks in Phase D.
class BillRepository {
  BillRepository(this._w);

  final LocalWriter _w;
  AppDatabase get _db => _w.db;

  Future<Bill?> byId(String id) => (_db.select(_db.bills)..where((b) => b.id.equals(id))).getSingleOrNull();

  Future<String> add(BillDraft d) => _w.action((batch) async {
        final now = _w.now();
        final id = _w.newId();
        await _db.into(_db.bills).insert(BillsCompanion.insert(
              id: id,
              userId: _w.userId,
              createdAt: now,
              updatedAt: now,
              billType: d.type,
              name: d.name.trim(),
              customerId: Value(_blankToNull(d.customerId)),
              everyMonths: d.everyMonths,
              nextDueDate: d.nextDue.toIso(),
              usualAmount: Value(d.usualAmount),
              reminderDays: Value(d.reminderDays.isEmpty ? null : d.reminderDays.join(',')),
            ));
        await _w.queue('bills', id, batch);
        return id;
      });

  Future<void> update(String id, BillDraft d) => _w.action((batch) async {
        await (_db.update(_db.bills)..where((b) => b.id.equals(id))).write(BillsCompanion(
              billType: Value(d.type),
              name: Value(d.name.trim()),
              customerId: Value(_blankToNull(d.customerId)),
              everyMonths: Value(d.everyMonths),
              nextDueDate: Value(d.nextDue.toIso()),
              usualAmount: Value(d.usualAmount),
              reminderDays: Value(d.reminderDays.isEmpty ? null : d.reminderDays.join(',')),
              updatedAt: Value(_w.now()),
              isSynced: const Value(false),
            ));
        await _w.queue('bills', id, batch);
      });

  /// Pause or resume (FR-B3): a paused bill sends no reminders or popups.
  Future<void> setPaused(String id, bool paused) => _w.action((batch) async {
        await (_db.update(_db.bills)..where((b) => b.id.equals(id)))
            .write(BillsCompanion(paused: Value(paused), updatedAt: Value(_w.now()), isSynced: const Value(false)));
        await _w.queue('bills', id, batch);
      });

  /// Soft delete; expenses already added stay.
  Future<void> delete(String id) => _w.action((batch) async {
        final now = _w.now();
        await (_db.update(_db.bills)..where((b) => b.id.equals(id)))
            .write(BillsCompanion(deletedAt: Value(now), updatedAt: Value(now), isSynced: const Value(false)));
        await _w.queue('bills', id, batch, op: 'delete');
      });

  /// "Yes, paid" (FR-B4, TRD 6.3): a payment for the current due date + an expense in category Bills,
  /// and the next due date moves forward by the gap (15 Nov + 2 months = 15 Jan), in one action.
  Future<void> markPaid(String billId, {required int amount, required DateTime paidAt, required String paymentMode, String? onlineMethod}) =>
      _w.action((batch) async {
        final bill = await byId(billId);
        if (bill == null) throw StateError('bill not found');
        final now = _w.now();
        final payId = _w.newId();
        final txnId = _w.newId();
        await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
              id: txnId,
              userId: _w.userId,
              createdAt: now,
              updatedAt: now,
              kind: 'expense',
              amount: amount,
              occurredAt: paidAt.toUtc(),
              paymentMode: paymentMode,
              onlineMethod: Value(paymentMode == 'online' ? onlineMethod : null),
              title: Value(bill.name),
              categoryId: Value(await CategoryRepository(_w).idForKey('expense', 'catBills')),
              source: const Value('bill'),
              sourceId: Value(payId),
            ));
        await _w.queue('transactions', txnId, batch);
        await _db.into(_db.billPayments).insert(BillPaymentsCompanion.insert(
              id: payId,
              userId: _w.userId,
              createdAt: now,
              updatedAt: now,
              billId: billId,
              dueDate: bill.nextDueDate,
              amount: amount,
              paidAt: paidAt.toUtc(),
              transactionId: Value(txnId),
            ));
        await _w.queue('bill_payments', payId, batch);
        final next = LocalDate.parse(bill.nextDueDate).addMonths(bill.everyMonths);
        await (_db.update(_db.bills)..where((b) => b.id.equals(billId)))
            .write(BillsCompanion(nextDueDate: Value(next.toIso()), updatedAt: Value(now), isSynced: const Value(false)));
        await _w.queue('bills', billId, batch);
        await _db.clearFlag('bill_ask_after_$billId');
        await _db.setFlag('last_payment_expense', paymentMode == 'online' ? 'online:${onlineMethod ?? 'upi'}' : 'cash');
      });

  /// Amounts of the last 3 bills, newest first; first time, the usual amount (FR-B4).
  Future<List<BillSuggestion>> suggestions(String billId) async {
    final ps = await (_db.select(_db.billPayments)
          ..where((p) => p.billId.equals(billId) & p.deletedAt.isNull())
          ..orderBy([(p) => OrderingTerm.desc(p.dueDate)])
          ..limit(3))
        .get();
    if (ps.isNotEmpty) return [for (final p in ps) BillSuggestion(p.amount, LocalDate.parse(p.dueDate))];
    final usual = (await byId(billId))?.usualAmount;
    return usual == null ? const [] : [BillSuggestion(usual, null)];
  }

  /// Bills due on or before [today], not paused and not asked again later (FR-B2 popup).
  Future<List<Bill>> dueToAsk(LocalDate today) async {
    final bs = await (_db.select(_db.bills)
          ..where((b) => b.userId.equals(_w.userId) & b.deletedAt.isNull() & b.paused.equals(false) & b.nextDueDate.isSmallerOrEqualValue(today.toIso()))
          ..orderBy([(b) => OrderingTerm.asc(b.nextDueDate)]))
        .get();
    final out = <Bill>[];
    for (final b in bs) {
      final after = await _db.flag('bill_ask_after_${b.id}');
      if (after == null || !today.isBefore(LocalDate.parse(after))) out.add(b);
    }
    return out;
  }

  /// "Not yet": ask again tomorrow (FR-B2).
  Future<void> askAgainTomorrow(String billId, LocalDate today) => _db.setFlag('bill_ask_after_$billId', today.addDays(1).toIso());

  Stream<List<BillWithPayments>> watchAll() {
    final bills = (_db.select(_db.bills)
          ..where((b) => b.userId.equals(_w.userId) & b.deletedAt.isNull())
          ..orderBy([(b) => OrderingTerm.asc(b.nextDueDate)]))
        .watch();
    final pays = (_db.select(_db.billPayments)
          ..where((p) => p.userId.equals(_w.userId) & p.deletedAt.isNull())
          ..orderBy([(p) => OrderingTerm.desc(p.dueDate)]))
        .watch();
    return combineLatest2(bills, pays, (List<Bill> bs, List<BillPayment> ps) {
      return [for (final b in bs) BillWithPayments(b, ps.where((p) => p.billId == b.id).toList())];
    });
  }

  Stream<BillWithPayments?> watchOne(String id) => watchAll().map((l) => l.where((b) => b.bill.id == id).firstOrNull);

  /// This month (IST): paid bills, plus the last amount (or usual amount) of bills still due this month.
  Stream<BillSummary> watchSummary(LocalDate today) {
    final from = LocalDate(today.year, today.month, 1).toIso();
    final to = LocalDate(today.year, today.month, LocalDate.daysInMonth(today.year, today.month)).toIso();
    return _db.customSelect(
      'SELECT '
      '(SELECT COALESCE(SUM(p.amount), 0) FROM bill_payments p JOIN bills b ON b.id = p.bill_id '
      '  WHERE p.user_id = ?3 AND p.deleted_at IS NULL AND b.deleted_at IS NULL AND p.due_date BETWEEN ?1 AND ?2) AS paid_sum, '
      '(SELECT COUNT(*) FROM bill_payments p JOIN bills b ON b.id = p.bill_id '
      '  WHERE p.user_id = ?3 AND p.deleted_at IS NULL AND b.deleted_at IS NULL AND p.due_date BETWEEN ?1 AND ?2) AS paid_count, '
      '(SELECT COALESCE(SUM(COALESCE((SELECT p.amount FROM bill_payments p WHERE p.bill_id = b.id AND p.deleted_at IS NULL '
      '  ORDER BY p.due_date DESC LIMIT 1), b.usual_amount, 0)), 0) FROM bills b '
      '  WHERE b.user_id = ?3 AND b.deleted_at IS NULL AND b.paused = 0 AND b.next_due_date <= ?2) AS due_sum, '
      '(SELECT COUNT(*) FROM bills b WHERE b.user_id = ?3 AND b.deleted_at IS NULL AND b.paused = 0 AND b.next_due_date <= ?2) AS due_count',
      variables: [Variable.withString(from), Variable.withString(to), Variable.withString(_w.userId)],
      readsFrom: {_db.bills, _db.billPayments},
    ).watchSingle().map((r) => BillSummary(
          total: r.read<int>('paid_sum') + r.read<int>('due_sum'),
          paid: r.read<int>('paid_count'),
          left: r.read<int>('due_count'),
        ));
  }

  static String? _blankToNull(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
}

final billRepositoryProvider = Provider<BillRepository>((ref) => BillRepository(ref.watch(localWriterProvider)));
