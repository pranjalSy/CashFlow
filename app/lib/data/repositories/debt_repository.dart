import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/dates.dart';
import '../../core/utils/streams.dart';
import '../local/database.dart';
import '../providers.dart';
import 'local_writer.dart';

/// One udhar with its repayments, for Person detail.
class DebtWithPayments {
  const DebtWithPayments(this.debt, this.payments);

  final Debt debt;
  final List<DebtPayment> payments;

  int get repaid => payments.fold(0, (a, p) => a + p.amount);
  int get remaining => debt.amount - repaid;
  bool get lent => debt.direction == 'lent';
}

/// Result of saving a repayment (G5–G8): what was applied to the udhar and the extra left over.
class RepaymentResult {
  const RepaymentResult({required this.applied, required this.extra, required this.settled});

  final int applied;
  final int extra;
  final bool settled;
}

/// Udhar: lent/borrowed, repayments (never above the remaining amount), extra as a new
/// opposite udhar, due dates (Premium) — FR-D1–D11.
class DebtRepository {
  DebtRepository(this._w);

  final LocalWriter _w;
  AppDatabase get _db => _w.db;

  Future<Debt?> byId(String id) => (_db.select(_db.debts)..where((d) => d.id.equals(id))).getSingleOrNull();

  /// Adds a lent or borrowed entry. [dueDate] and [reminderDays] are kept only for Premium (G3);
  /// the caller passes [premium] from the plan, the server enforces it again.
  Future<String> add({
    required String personId,
    required String direction,
    required int amount,
    required DateTime occurredAt,
    required String paymentMode,
    String? onlineMethod,
    String? note,
    LocalDate? dueDate,
    List<int> reminderDays = const [],
    required bool premium,
    String? extraFromDebtId,
  }) =>
      _w.action((batch) async {
        final now = _w.now();
        final id = _w.newId();
        await _db.into(_db.debts).insert(DebtsCompanion.insert(
              id: id,
              userId: _w.userId,
              createdAt: now,
              updatedAt: now,
              personId: personId,
              direction: direction,
              amount: amount,
              occurredAt: occurredAt.toUtc(),
              paymentMode: paymentMode,
              onlineMethod: Value(paymentMode == 'online' ? onlineMethod : null),
              note: Value(note == null || note.trim().isEmpty ? null : note.trim()),
              dueDate: Value(premium ? dueDate?.toIso() : null),
              reminderDays: Value(premium && reminderDays.isNotEmpty ? reminderDays.join(',') : null),
              extraFromDebtId: Value(extraFromDebtId),
            ));
        await _w.queue('debts', id, batch);
        return id;
      });

  Future<int> remaining(String debtId) async {
    final d = await byId(debtId);
    if (d == null) return 0;
    final paid = await (_db.selectOnly(_db.debtPayments)
          ..addColumns([_db.debtPayments.amount.sum()])
          ..where(_db.debtPayments.debtId.equals(debtId) & _db.debtPayments.deletedAt.isNull()))
        .map((r) => r.read(_db.debtPayments.amount.sum()) ?? 0)
        .getSingle();
    return d.amount - paid;
  }

  /// Saves a repayment capped at the remaining amount (G8, TRD 6.3 `record_repayment`).
  /// Any extra is returned and remembered on the udhar ("₹X extra not added").
  Future<RepaymentResult> recordRepayment({
    required String debtId,
    required int amount,
    required DateTime occurredAt,
    required String paymentMode,
    String? onlineMethod,
  }) =>
      _w.action((batch) async {
        final left = await remaining(debtId);
        if (left <= 0) return const RepaymentResult(applied: 0, extra: 0, settled: true);
        final applied = math.min(amount, left);
        final extra = amount - applied;
        final now = _w.now();
        final id = _w.newId();
        await _db.into(_db.debtPayments).insert(DebtPaymentsCompanion.insert(
              id: id,
              userId: _w.userId,
              createdAt: now,
              updatedAt: now,
              debtId: debtId,
              amount: applied,
              occurredAt: occurredAt.toUtc(),
              paymentMode: paymentMode,
              onlineMethod: Value(paymentMode == 'online' ? onlineMethod : null),
            ));
        await _w.queue('debt_payments', id, batch);
        final settled = applied == left;
        await (_db.update(_db.debts)..where((d) => d.id.equals(debtId))).write(DebtsCompanion(
              status: Value(settled ? 'settled' : 'partial'),
              extraNotAdded: Value(extra > 0 ? extra : null),
              updatedAt: Value(now),
              isSynced: const Value(false),
            ));
        await _w.queue('debts', debtId, batch);
        return RepaymentResult(applied: applied, extra: extra, settled: settled);
      });

  /// "Yes" on the extra snackbar: the extra becomes udhar in the other direction (G7).
  Future<String?> addExtraAsDebt(String fromDebtId, {required bool premium}) async {
    final from = await byId(fromDebtId);
    final extra = from?.extraNotAdded;
    if (from == null || extra == null || extra <= 0) return null;
    return _w.action((batch) async {
      final id = await add(
        personId: from.personId,
        direction: from.direction == 'lent' ? 'borrowed' : 'lent',
        amount: extra,
        occurredAt: _w.now(),
        paymentMode: from.paymentMode,
        onlineMethod: from.onlineMethod,
        premium: premium,
        extraFromDebtId: from.id,
      );
      await (_db.update(_db.debts)..where((d) => d.id.equals(fromDebtId)))
          .write(DebtsCompanion(extraNotAdded: const Value(null), updatedAt: Value(_w.now()), isSynced: const Value(false)));
      await _w.queue('debts', fromDebtId, batch);
      return id;
    });
  }

  /// New due date with history (FR-D4, G10). Premium.
  Future<void> extendDueDate(String debtId, LocalDate newDate) => _w.action((batch) async {
        final d = await byId(debtId);
        if (d == null) return;
        final now = _w.now();
        final extId = _w.newId();
        await _db.into(_db.debtExtensions).insert(DebtExtensionsCompanion.insert(
              id: extId,
              userId: _w.userId,
              createdAt: now,
              updatedAt: now,
              debtId: debtId,
              oldDueDate: Value(d.dueDate),
              newDueDate: newDate.toIso(),
            ));
        await _w.queue('debt_extensions', extId, batch);
        await (_db.update(_db.debts)..where((x) => x.id.equals(debtId)))
            .write(DebtsCompanion(dueDate: Value(newDate.toIso()), updatedAt: Value(now), isSynced: const Value(false)));
        await _w.queue('debts', debtId, batch);
        await _db.clearFlag('debt_ask_after_$debtId');
      });

  /// Soft delete of an udhar and its repayments, held 5 s for Undo (FR-H4). Returns the batch id.
  Future<String> delete(String debtId) => _w.action((batch) async {
        final now = _w.now();
        await (_db.update(_db.debts)..where((d) => d.id.equals(debtId)))
            .write(DebtsCompanion(deletedAt: Value(now), updatedAt: Value(now), isSynced: const Value(false)));
        await _w.queue('debts', debtId, batch, op: 'delete', undoable: true);
        final payments = await (_db.select(_db.debtPayments)..where((p) => p.debtId.equals(debtId) & p.deletedAt.isNull())).get();
        for (final p in payments) {
          await (_db.update(_db.debtPayments)..where((x) => x.id.equals(p.id)))
              .write(DebtPaymentsCompanion(deletedAt: Value(now), updatedAt: Value(now), isSynced: const Value(false)));
          await _w.queue('debt_payments', p.id, batch, op: 'delete', undoable: true);
        }
        return batch;
      });

  /// Undo inside the window: the udhar and the repayments deleted with it come back; nothing uploads.
  Future<void> undoDelete(String debtId, String batch) => _db.transaction(() async {
        final d = await byId(debtId);
        final at = d?.deletedAt;
        if (at == null) return;
        await (_db.update(_db.debts)..where((x) => x.id.equals(debtId))).write(const DebtsCompanion(deletedAt: Value(null)));
        await (_db.update(_db.debtPayments)..where((p) => p.debtId.equals(debtId) & p.deletedAt.equals(at)))
            .write(const DebtPaymentsCompanion(deletedAt: Value(null)));
        await _w.dropBatch(batch);
      });

  /// A person's udhar, newest first, each with its repayments.
  Stream<List<DebtWithPayments>> watchPerson(String personId) {
    final debts = (_db.select(_db.debts)
          ..where((d) => d.userId.equals(_w.userId) & d.personId.equals(personId) & d.deletedAt.isNull())
          ..orderBy([(d) => OrderingTerm.desc(d.occurredAt)]))
        .watch();
    final payments = (_db.select(_db.debtPayments)
          ..where((p) => p.userId.equals(_w.userId) & p.deletedAt.isNull())
          ..orderBy([(p) => OrderingTerm.asc(p.occurredAt)]))
        .watch();
    return combineLatest2(debts, payments, (List<Debt> ds, List<DebtPayment> ps) {
      return [for (final d in ds) DebtWithPayments(d, ps.where((p) => p.debtId == d.id).toList())];
    });
  }

  /// When each person last had udhar activity (for "Recent" on the Contacts tab).
  Stream<Map<String, DateTime>> watchLastActivity() => (_db.select(_db.debts)..where((d) => d.userId.equals(_w.userId) & d.deletedAt.isNull()))
      .watch()
      .map((ds) {
        final m = <String, DateTime>{};
        for (final d in ds) {
          final prev = m[d.personId];
          if (prev == null || d.occurredAt.isAfter(prev)) m[d.personId] = d.occurredAt;
        }
        return m;
      });

  /// Open udhar with a due date on or before [today] that is not snoozed (due popup, G9).
  Future<List<DebtWithPayments>> dueToAsk(LocalDate today) async {
    final ds = await (_db.select(_db.debts)
          ..where((d) => d.userId.equals(_w.userId) & d.deletedAt.isNull() & d.status.isNotValue('settled') & d.dueDate.isNotNull()))
        .get();
    final out = <DebtWithPayments>[];
    for (final d in ds) {
      if (LocalDate.parse(d.dueDate!).isAfter(today)) continue;
      final after = await _db.flag('debt_ask_after_${d.id}');
      if (after != null && today.isBefore(LocalDate.parse(after))) continue;
      final ps = await (_db.select(_db.debtPayments)..where((p) => p.debtId.equals(d.id) & p.deletedAt.isNull())).get();
      final item = DebtWithPayments(d, ps);
      if (item.remaining > 0) out.add(item);
    }
    return out;
  }

  /// "Not yet": ask again tomorrow (G9).
  Future<void> askAgainTomorrow(String debtId, LocalDate today) => _db.setFlag('debt_ask_after_$debtId', today.addDays(1).toIso());
}

final debtRepositoryProvider = Provider<DebtRepository>((ref) => DebtRepository(ref.watch(localWriterProvider)));
