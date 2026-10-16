import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/dates.dart';
import '../../core/utils/emi.dart';
import '../../core/utils/streams.dart';
import '../local/database.dart';
import '../providers.dart';
import 'category_repository.dart';
import 'local_writer.dart';

/// What the Add EMI form saves (FR-E1). Money in paise, rate in basis points.
class EmiDraft {
  const EmiDraft({
    required this.name,
    required this.icon,
    this.lender,
    this.itemPrice,
    this.downPayment,
    required this.loanAmount,
    required this.rateBp,
    required this.months,
    required this.emiAmount,
    required this.firstDue,
  });

  final String name;
  final String icon;
  final String? lender;
  final int? itemPrice;
  final int? downPayment;
  final int loanAmount;
  final int rateBp;
  final int months;
  final int emiAmount;
  final LocalDate firstDue;
}

/// One EMI with its installments in order (seq 1…n).
class EmiWithInstallments {
  const EmiWithInstallments(this.emi, this.installments);

  final EmiLoan emi;
  final List<EmiInstallment> installments;

  int get paidCount => installments.where((i) => i.status == 'paid').length;
  int get total => installments.length;
  bool get closed => emi.status == 'closed';
  int get totalInterest => installments.fold(0, (a, i) => a + i.interestPart);

  /// The only installment that can be marked paid: the first one not paid yet (FR-E11).
  EmiInstallment? get nextDue => installments.where((i) => i.status != 'paid').firstOrNull;
  LocalDate get lastDue => LocalDate.parse(installments.last.dueDate);

  /// The last paid installment: the only one "Mark as unpaid" is offered on, so the order stays.
  EmiInstallment? get lastPaid => installments.where((i) => i.status == 'paid').lastOrNull;
}

/// Totals shown at the top of the EMI tab (FR-E5), from SQL sums.
class EmiSummary {
  const EmiSummary({required this.dueThisMonth, required this.countThisMonth, this.nextDue});

  final int dueThisMonth;
  final int countThisMonth;
  final LocalDate? nextDue;
}

/// EMIs and their installments (FR-E1–E11). Premium; the server re-checks in Phase D.
class EmiRepository {
  EmiRepository(this._w);

  final LocalWriter _w;
  AppDatabase get _db => _w.db;

  Future<EmiLoan?> byId(String id) => (_db.select(_db.emis)..where((e) => e.id.equals(id))).getSingleOrNull();

  /// Creates the EMI and every installment in one action (FR-E4).
  Future<String> add(EmiDraft d) => _w.action((batch) async {
        final now = _w.now();
        final id = _w.newId();
        await _db.into(_db.emis).insert(EmisCompanion.insert(
              id: id,
              userId: _w.userId,
              createdAt: now,
              updatedAt: now,
              name: d.name.trim(),
              icon: Value(d.icon),
              lender: Value(_blankToNull(d.lender)),
              itemPrice: Value(d.itemPrice),
              downPayment: Value(d.downPayment),
              loanAmount: d.loanAmount,
              rateBp: d.rateBp,
              months: d.months,
              emiAmount: d.emiAmount,
              firstDueDate: d.firstDue.toIso(),
            ));
        await _w.queue('emis', id, batch);
        await _insertSchedule(id, d, batch);
        return id;
      });

  /// Edit (FR-E8). Name, icon and lender can always change; the loan terms only while
  /// nothing is paid, and then the installments are made again.
  Future<void> update(String id, EmiDraft d) => _w.action((batch) async {
        final now = _w.now();
        final paid = await paidCount(id);
        await (_db.update(_db.emis)..where((e) => e.id.equals(id))).write(EmisCompanion(
              name: Value(d.name.trim()),
              icon: Value(d.icon),
              lender: Value(_blankToNull(d.lender)),
              updatedAt: Value(now),
              isSynced: const Value(false),
            ));
        if (paid == 0) {
          await (_db.update(_db.emis)..where((e) => e.id.equals(id))).write(EmisCompanion(
                itemPrice: Value(d.itemPrice),
                downPayment: Value(d.downPayment),
                loanAmount: Value(d.loanAmount),
                rateBp: Value(d.rateBp),
                months: Value(d.months),
                emiAmount: Value(d.emiAmount),
                firstDueDate: Value(d.firstDue.toIso()),
              ));
          final old = await (_db.select(_db.emiInstallments)..where((i) => i.emiId.equals(id) & i.deletedAt.isNull())).get();
          for (final i in old) {
            await _softDeleteInstallment(i.id, now, batch);
          }
          await _insertSchedule(id, d, batch);
        }
        await _w.queue('emis', id, batch);
      });

  /// Soft delete of the EMI and its installments. Expenses already added stay (deleteEmiBody).
  Future<void> delete(String id) => _w.action((batch) async {
        final now = _w.now();
        await (_db.update(_db.emis)..where((e) => e.id.equals(id)))
            .write(EmisCompanion(deletedAt: Value(now), updatedAt: Value(now), isSynced: const Value(false)));
        await _w.queue('emis', id, batch, op: 'delete');
        final list = await (_db.select(_db.emiInstallments)..where((i) => i.emiId.equals(id) & i.deletedAt.isNull())).get();
        for (final i in list) {
          await _softDeleteInstallment(i.id, now, batch);
        }
      });

  /// Mark paid (FR-E7, FR-E11, TRD 6.3 `mark_installment_paid`): the installment is paid, an
  /// expense in category EMI is added, and the EMI closes after the last one, in one action.
  /// Only the next due installment can be paid. Returns the batch id for [undoMarkPaid].
  Future<String> markPaid(String installmentId, {required DateTime paidAt, required String paymentMode, String? onlineMethod}) => _w.action((batch) async {
        final inst = await _installment(installmentId);
        if (inst == null || inst.status == 'paid') throw StateError('installment not payable');
        final next = await _nextDue(inst.emiId);
        if (next?.id != inst.id) throw StateError('only the next due installment can be paid');
        final emi = (await byId(inst.emiId))!;
        final now = _w.now();
        final txnId = _w.newId();
        await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
              id: txnId,
              userId: _w.userId,
              createdAt: now,
              updatedAt: now,
              kind: 'expense',
              amount: inst.amount,
              occurredAt: paidAt.toUtc(),
              paymentMode: paymentMode,
              onlineMethod: Value(paymentMode == 'online' ? onlineMethod : null),
              title: Value(emi.name),
              categoryId: Value(await _emiCategoryId()),
              source: const Value('emi'),
              sourceId: Value(inst.id),
            ));
        await _w.queue('transactions', txnId, batch, undoable: true);
        await (_db.update(_db.emiInstallments)..where((i) => i.id.equals(inst.id))).write(EmiInstallmentsCompanion(
              status: const Value('paid'),
              paidAt: Value(paidAt.toUtc()),
              transactionId: Value(txnId),
              updatedAt: Value(now),
              isSynced: const Value(false),
            ));
        await _w.queue('emi_installments', inst.id, batch, undoable: true);
        if (await _nextDue(inst.emiId) == null) {
          await _setStatus(emi.id, 'closed', now);
          await _w.queue('emis', emi.id, batch, undoable: true);
        }
        await _db.setFlag('last_payment_expense', paymentMode == 'online' ? 'online:${onlineMethod ?? 'upi'}' : 'cash');
        return batch;
      });

  /// Undo inside the 5 s window: back to due, the expense removed, nothing uploaded.
  Future<void> undoMarkPaid(String installmentId, String batch) => _db.transaction(() async {
        await _revert(installmentId, hardDeleteTxn: true);
        await _w.dropBatch(batch);
      });

  /// "Mark as unpaid" on a paid installment (FR-E11): removes its expense too.
  Future<void> markUnpaid(String installmentId) => _w.action((batch) async {
        final inst = await _installment(installmentId);
        if (inst == null || inst.status != 'paid') return;
        final txnId = inst.transactionId;
        await _revert(installmentId, hardDeleteTxn: false);
        await _w.queue('emi_installments', inst.id, batch);
        await _w.queue('emis', inst.emiId, batch);
        if (txnId != null) await _w.queue('transactions', txnId, batch, op: 'delete');
      });

  Stream<List<EmiWithInstallments>> watchAll() {
    final emis = (_db.select(_db.emis)
          ..where((e) => e.userId.equals(_w.userId) & e.deletedAt.isNull())
          ..orderBy([(e) => OrderingTerm.asc(e.firstDueDate)]))
        .watch();
    final inst = (_db.select(_db.emiInstallments)
          ..where((i) => i.userId.equals(_w.userId) & i.deletedAt.isNull())
          ..orderBy([(i) => OrderingTerm.asc(i.seq)]))
        .watch();
    return combineLatest2(emis, inst, (List<EmiLoan> es, List<EmiInstallment> is_) {
      final byEmi = <String, List<EmiInstallment>>{};
      for (final i in is_) {
        byEmi.putIfAbsent(i.emiId, () => []).add(i);
      }
      return [for (final e in es) EmiWithInstallments(e, byEmi[e.id] ?? const [])];
    });
  }

  Stream<EmiWithInstallments?> watchOne(String id) => watchAll().map((list) => list.where((e) => e.emi.id == id).firstOrNull);

  /// Still to pay this month (IST), late ones included, and the next date from today, as SQL.
  Stream<EmiSummary> watchSummary(LocalDate today) {
    final end = LocalDate(today.year, today.month, LocalDate.daysInMonth(today.year, today.month)).toIso();
    return _db.customSelect(
      'SELECT '
      'COALESCE(SUM(CASE WHEN i.due_date <= ?1 THEN i.amount END), 0) AS due_sum, '
      'COUNT(DISTINCT CASE WHEN i.due_date <= ?1 THEN i.emi_id END) AS due_count, '
      'MIN(CASE WHEN i.due_date >= ?2 THEN i.due_date END) AS next_due '
      'FROM emi_installments i JOIN emis e ON e.id = i.emi_id '
      "WHERE i.user_id = ?3 AND i.deleted_at IS NULL AND e.deleted_at IS NULL AND e.status = 'active' AND i.status = 'due'",
      variables: [Variable.withString(end), Variable.withString(today.toIso()), Variable.withString(_w.userId)],
      readsFrom: {_db.emis, _db.emiInstallments},
    ).watchSingle().map((r) {
      final next = r.readNullable<String>('next_due');
      return EmiSummary(dueThisMonth: r.read<int>('due_sum'), countThisMonth: r.read<int>('due_count'), nextDue: next == null ? null : LocalDate.parse(next));
    });
  }

  /// Sum still to pay on an EMI (FR-E5, FR-E10), as SQL.
  Stream<int> watchRemaining(String emiId) => _db.customSelect(
        "SELECT COALESCE(SUM(amount), 0) AS left FROM emi_installments WHERE emi_id = ?1 AND deleted_at IS NULL AND status = 'due'",
        variables: [Variable.withString(emiId)],
        readsFrom: {_db.emiInstallments},
      ).watchSingle().map((r) => r.read<int>('left'));

  /// The next due installment of each active EMI that is due on or before [today] (FR-E6 popup).
  Future<List<(EmiLoan, EmiInstallment)>> dueToAsk(LocalDate today) async {
    final es = await (_db.select(_db.emis)..where((e) => e.userId.equals(_w.userId) & e.deletedAt.isNull() & e.status.equals('active'))).get();
    final out = <(EmiLoan, EmiInstallment)>[];
    for (final e in es) {
      final next = await _nextDue(e.id);
      if (next != null && !LocalDate.parse(next.dueDate).isAfter(today)) out.add((e, next));
    }
    return out;
  }

  Future<void> _insertSchedule(String emiId, EmiDraft d, String batch) async {
    final now = _w.now();
    final plan = Emi.schedule(principal: d.loanAmount, rateBp: d.rateBp, emi: d.emiAmount, months: d.months, firstDue: d.firstDue);
    for (final p in plan) {
      final iid = _w.newId();
      await _db.into(_db.emiInstallments).insert(EmiInstallmentsCompanion.insert(
            id: iid,
            userId: _w.userId,
            createdAt: now,
            updatedAt: now,
            emiId: emiId,
            seq: p.seq,
            dueDate: p.dueDate.toIso(),
            amount: p.amount,
            interestPart: p.interest,
            principalPart: p.principal,
          ));
      await _w.queue('emi_installments', iid, batch);
    }
  }

  Future<void> _revert(String installmentId, {required bool hardDeleteTxn}) async {
    final inst = await _installment(installmentId);
    if (inst == null) return;
    final now = _w.now();
    final txnId = inst.transactionId;
    if (txnId != null) {
      final q = _db.update(_db.transactions)..where((t) => t.id.equals(txnId));
      await q.write(TransactionsCompanion(deletedAt: Value(now), updatedAt: Value(now), isSynced: const Value(false)));
      if (hardDeleteTxn) await (_db.delete(_db.transactions)..where((t) => t.id.equals(txnId))).go();
    }
    await (_db.update(_db.emiInstallments)..where((i) => i.id.equals(inst.id))).write(EmiInstallmentsCompanion(
          status: const Value('due'),
          paidAt: const Value(null),
          transactionId: const Value(null),
          updatedAt: Value(now),
          isSynced: const Value(false),
        ));
    await _setStatus(inst.emiId, 'active', now);
  }

  Future<void> _softDeleteInstallment(String id, DateTime now, String batch) async {
    await (_db.update(_db.emiInstallments)..where((i) => i.id.equals(id)))
        .write(EmiInstallmentsCompanion(deletedAt: Value(now), updatedAt: Value(now), isSynced: const Value(false)));
    await _w.queue('emi_installments', id, batch, op: 'delete');
  }

  Future<void> _setStatus(String emiId, String status, DateTime now) => (_db.update(_db.emis)..where((e) => e.id.equals(emiId)))
      .write(EmisCompanion(status: Value(status), updatedAt: Value(now), isSynced: const Value(false)));

  Future<EmiInstallment?> _installment(String id) => (_db.select(_db.emiInstallments)..where((i) => i.id.equals(id))).getSingleOrNull();

  Future<EmiInstallment?> _nextDue(String emiId) => (_db.select(_db.emiInstallments)
        ..where((i) => i.emiId.equals(emiId) & i.deletedAt.isNull() & i.status.equals('due'))
        ..orderBy([(i) => OrderingTerm.asc(i.seq)])
        ..limit(1))
      .getSingleOrNull();

  Future<int> paidCount(String emiId) async => (await (_db.select(_db.emiInstallments)
            ..where((i) => i.emiId.equals(emiId) & i.deletedAt.isNull() & i.status.equals('paid')))
          .get())
      .length;

  Future<String?> _emiCategoryId() async {
    Future<Category?> find() => (_db.select(_db.categories)
          ..where((c) => c.userId.equals(_w.userId) & c.deletedAt.isNull() & c.kind.equals('expense') & c.nameKey.equals('catEmi'))
          ..limit(1))
        .getSingleOrNull();
    var c = await find();
    if (c == null) {
      await CategoryRepository(_w).ensureDefaults();
      c = await find();
    }
    return c?.id;
  }

  static String? _blankToNull(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
}

final emiRepositoryProvider = Provider<EmiRepository>((ref) => EmiRepository(ref.watch(localWriterProvider)));
