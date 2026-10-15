import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/dates.dart';
import '../../core/utils/streams.dart';
import '../local/database.dart';
import '../providers.dart';
import 'local_writer.dart';

enum EntryKind { income, expense, lent, borrowed }

/// One row of the Home list: income, expense or udhar (DESIGN_DECISIONS E1).
class HomeEntry {
  const HomeEntry({
    required this.id,
    required this.kind,
    required this.amount,
    required this.occurredAt,
    required this.paymentMode,
    this.onlineMethod,
    this.title,
    this.categoryId,
    this.personId,
    this.dueDate,
    this.note,
  });

  final String id;
  final EntryKind kind;
  final int amount;
  final DateTime occurredAt;
  final String paymentMode;
  final String? onlineMethod;
  final String? title;
  final String? categoryId;
  final String? personId;
  final String? dueDate;
  final String? note;

  bool get isUdhar => kind == EntryKind.lent || kind == EntryKind.borrowed;
}

/// Data the add/edit form saves.
class EntryDraft {
  const EntryDraft({
    required this.kind,
    required this.amount,
    required this.paymentMode,
    this.onlineMethod,
    required this.occurredAt,
    this.categoryId,
    this.title,
    this.note,
  });

  /// `income` or `expense`.
  final String kind;
  final int amount;
  final String paymentMode;
  final String? onlineMethod;
  final DateTime occurredAt;
  final String? categoryId;
  final String? title;
  final String? note;
}

/// Income and expense entries (FR-T1–T9) plus the merged Home list.
class EntryRepository {
  EntryRepository(this._w);

  final LocalWriter _w;
  AppDatabase get _db => _w.db;

  Future<Txn?> byId(String id) => (_db.select(_db.transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<String> add(EntryDraft d) => _w.action((batch) async {
        final now = _w.now();
        final id = _w.newId();
        await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
              id: id,
              userId: _w.userId,
              createdAt: now,
              updatedAt: now,
              kind: d.kind,
              amount: d.amount,
              occurredAt: d.occurredAt.toUtc(),
              paymentMode: d.paymentMode,
              onlineMethod: Value(d.paymentMode == 'online' ? d.onlineMethod : null),
              title: Value(_blankToNull(d.title)),
              categoryId: Value(d.categoryId),
              note: Value(_blankToNull(d.note)),
            ));
        await _w.queue('transactions', id, batch);
        await _db.setFlag('last_payment_${d.kind}', d.paymentMode == 'online' ? 'online:${d.onlineMethod ?? 'upi'}' : 'cash');
        return id;
      });

  Future<void> update(String id, EntryDraft d) => _w.action((batch) async {
        await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(TransactionsCompanion(
              kind: Value(d.kind),
              amount: Value(d.amount),
              occurredAt: Value(d.occurredAt.toUtc()),
              paymentMode: Value(d.paymentMode),
              onlineMethod: Value(d.paymentMode == 'online' ? d.onlineMethod : null),
              title: Value(_blankToNull(d.title)),
              categoryId: Value(d.categoryId),
              note: Value(_blankToNull(d.note)),
              updatedAt: Value(_w.now()),
              isSynced: const Value(false),
            ));
        await _w.queue('transactions', id, batch);
      });

  /// Soft delete with a 5 s undo window (E4). Returns the batch id for [undoDelete].
  Future<String> delete(String id) => _w.action((batch) async {
        await (_db.update(_db.transactions)..where((t) => t.id.equals(id)))
            .write(TransactionsCompanion(deletedAt: Value(_w.now()), updatedAt: Value(_w.now()), isSynced: const Value(false)));
        await _w.queue('transactions', id, batch, op: 'delete', undoable: true);
        return batch;
      });

  Future<void> undoDelete(String id, String batch) => _w.db.transaction(() async {
        await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(const TransactionsCompanion(deletedAt: Value(null)));
        await _w.dropBatch(batch);
      });

  /// Last payment choice for a kind, to pre-select it next time.
  Future<(String, String?)?> lastPayment(String kind) async {
    final v = await _db.flag('last_payment_$kind');
    if (v == null) return null;
    if (v == 'cash') return ('cash', null);
    return ('online', v.split(':').last);
  }

  /// Home list for an India month, newest first: income, expense and udhar.
  Stream<List<HomeEntry>> watchMonth(int year, int month) {
    final (start, end) = Ist.monthRange(year, month);
    final txns = (_db.select(_db.transactions)
          ..where((t) => t.userId.equals(_w.userId) & t.deletedAt.isNull() & t.occurredAt.isBiggerOrEqualValue(start) & t.occurredAt.isSmallerThanValue(end)))
        .watch();
    final debts = (_db.select(_db.debts)
          ..where((d) => d.userId.equals(_w.userId) & d.deletedAt.isNull() & d.occurredAt.isBiggerOrEqualValue(start) & d.occurredAt.isSmallerThanValue(end)))
        .watch();
    return combineLatest2(txns, debts, (List<Txn> t, List<Debt> d) {
      final list = <HomeEntry>[
        for (final x in t)
          HomeEntry(
            id: x.id,
            kind: x.kind == 'income' ? EntryKind.income : EntryKind.expense,
            amount: x.amount,
            occurredAt: x.occurredAt,
            paymentMode: x.paymentMode,
            onlineMethod: x.onlineMethod,
            title: x.title,
            categoryId: x.categoryId,
            note: x.note,
          ),
        for (final x in d)
          HomeEntry(
            id: x.id,
            kind: x.direction == 'lent' ? EntryKind.lent : EntryKind.borrowed,
            amount: x.amount,
            occurredAt: x.occurredAt,
            paymentMode: x.paymentMode,
            onlineMethod: x.onlineMethod,
            personId: x.personId,
            dueDate: x.dueDate,
            note: x.note,
          ),
      ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      return list;
    });
  }

  static String? _blankToNull(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
}

final entryRepositoryProvider = Provider<EntryRepository>((ref) => EntryRepository(ref.watch(localWriterProvider)));
