import 'package:cashflow/data/local/database.dart';
import 'package:cashflow/data/repositories/local_writer.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  final t0 = DateTime.utc(2026, 10, 14, 6);

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('an action writes rows and outbox entries in one batch', () async {
    final w = LocalWriter(db, userId: 'u1', clock: () => t0);
    final batch = await w.action((batchId) async {
      await w.queue('transactions', 'a', batchId);
      await w.queue('emi_installments', 'b', batchId);
      return batchId;
    });
    final rows = await db.select(db.syncOutbox).get();
    expect(rows.map((r) => r.batchId).toSet(), {batch});
    expect(rows.map((r) => r.entityTable), ['transactions', 'emi_installments']);
    expect(rows.every((r) => r.notBefore == null), isTrue);
  });

  test('undoable changes wait 5 seconds and can be dropped', () async {
    final w = LocalWriter(db, userId: 'u1', clock: () => t0);
    final batch = await w.action((batchId) async {
      await w.queue('transactions', 'a', batchId, op: 'delete', undoable: true);
      return batchId;
    });
    final row = await db.select(db.syncOutbox).getSingle();
    expect(row.notBefore, t0.add(const Duration(seconds: 5)));
    await w.dropBatch(batch);
    expect(await db.select(db.syncOutbox).get(), isEmpty);
  });

  test('a failed action leaves nothing behind', () async {
    final w = LocalWriter(db, userId: 'u1', clock: () => t0);
    await expectLater(
      w.action((batchId) async {
        await w.queue('transactions', 'a', batchId);
        throw StateError('boom');
      }),
      throwsStateError,
    );
    expect(await db.select(db.syncOutbox).get(), isEmpty);
  });

  test('local user id is created once', () async {
    final a = await localUserId(db);
    final b = await localUserId(db);
    expect(a, b);
    expect(a.length, 36);
  });

  test('flags', () async {
    await db.setFlag('k', 'v1');
    await db.setFlag('k', 'v2');
    expect(await db.flag('k'), 'v2');
    await db.clearFlag('k');
    expect(await db.flag('k'), isNull);
    expect(const Value(1).present, isTrue);
  });
}
