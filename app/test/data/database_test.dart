import 'dart:convert';
import 'dart:io';

import 'package:cashflow/data/local/database.dart';
import 'package:cashflow/data/local/local_store.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('cashflow_db_test');
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  LocalStore store() => LocalStore(directory: () async => dir);

  test('bundled SQLite has encryption (SQLite3MultipleCiphers)', () async {
    final db = AppDatabase(NativeDatabase.memory());
    expect(await db.customSelect('PRAGMA cipher').get(), isNotEmpty);
    await db.close();
  });

  test('database file is encrypted on disk and needs the right key', () async {
    final s = store();
    final db = await s.open();
    await db.into(db.appFlags).insert(AppFlagsCompanion.insert(key: 'hello', value: 'secret-value-123'));
    await db.close();

    final bytes = await (await s.databaseFile()).readAsBytes();
    expect(bytes.length, greaterThan(0));
    expect(ascii.decode(bytes.sublist(0, 15), allowInvalid: true), isNot('SQLite format 3'));
    expect(latin1.decode(bytes).contains('secret-value-123'), isFalse);

    final wrong = AppDatabase(openEncryptedDatabase(await s.databaseFile(), 'not-the-key'));
    await expectLater(wrong.customSelect('SELECT 1').get(), throwsA(anything));
    await wrong.close();

    final again = await s.open();
    expect(await again.flag('hello'), 'secret-value-123');
    await again.close();
  });

  test('the same key is reused across opens', () async {
    final s = store();
    final k1 = await s.databaseKey();
    final k2 = await s.databaseKey();
    expect(k1, k2);
    expect(k1.length, 64);
  });

  test('all tables exist with sync columns, money as integers', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final now = DateTime.utc(2026, 10, 13, 13, 10);
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
          id: 't1',
          userId: 'u1',
          createdAt: now,
          updatedAt: now,
          kind: 'expense',
          amount: 245000,
          occurredAt: now,
          paymentMode: 'online',
          onlineMethod: const Value('upi'),
        ));
    final row = await db.select(db.transactions).getSingle();
    expect(row.amount, 245000);
    expect(row.occurredAt.isUtc, isTrue);
    expect(row.isSynced, isFalse);
    expect(row.deletedAt, isNull);
    final names = (await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'table'").get()).map((r) => r.read<String>('name')).toSet();
    expect(names, containsAll(<String>[
      'profiles', 'categories', 'people', 'transactions', 'debts', 'debt_payments', 'debt_extensions', 'emis',
      'emi_installments', 'bills', 'bill_payments', 'budgets', 'budget_category_limits',
      'sync_outbox', 'sync_cursors', 'plan_cache', 'app_flags',
    ]));
    await db.close();
  });

  test('logout wipe removes the database files and every secure key', () async {
    final s = store();
    final db = await s.open();
    await db.setFlag('x', 'y');
    await const FlutterSecureStorage().write(key: 'pin_hash', value: 'abc');
    await s.wipe(openDb: db);
    expect(await (await s.databaseFile()).exists(), isFalse);
    expect(dir.listSync().where((e) => e.path.contains('cashflow.db')), isEmpty);
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
  });
}
