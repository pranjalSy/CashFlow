import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' show Database;

import 'tables.dart';

part 'database.g.dart';

/// The phone database (Drift + SQLite3MultipleCiphers). The UI reads only from here (TRD 1).
@DriftDatabase(tables: [
  Profiles,
  Categories,
  People,
  Transactions,
  Debts,
  DebtPayments,
  DebtExtensions,
  Emis,
  EmiInstallments,
  Bills,
  BillPayments,
  Budgets,
  BudgetCategoryLimits,
  SyncOutbox,
  SyncCursors,
  PlanCache,
  AppFlags,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = OFF');
        },
      );

  // ---- AppFlags helpers ----

  Future<String?> flag(String key) async =>
      (await (select(appFlags)..where((f) => f.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setFlag(String key, String value) =>
      into(appFlags).insertOnConflictUpdate(AppFlagsCompanion.insert(key: key, value: value));

  Future<void> clearFlag(String key) => (delete(appFlags)..where((f) => f.key.equals(key))).go();
}

/// Thrown when the bundled SQLite has no encryption: we never open an unencrypted database.
class EncryptionUnavailable implements Exception {
  @override
  String toString() => 'SQLite3MultipleCiphers is not available in this build';
}

/// Opens (or creates) the encrypted database file. [key] comes from secure storage.
QueryExecutor openEncryptedDatabase(File file, String key) {
  return NativeDatabase.createInBackground(
    file,
    setup: (raw) => applyKey(raw, key),
  );
}

/// Sets the cipher key on a raw connection; refuses to continue without SQLite3MultipleCiphers.
void applyKey(Database raw, String key) {
  if (raw.select('PRAGMA cipher;').isEmpty) throw EncryptionUnavailable();
  final escaped = key.replaceAll("'", "''");
  raw.execute("PRAGMA key = '$escaped';");
  // Fails right here with a wrong key instead of later on the first query.
  raw.select('SELECT count(*) FROM sqlite_master;');
}
