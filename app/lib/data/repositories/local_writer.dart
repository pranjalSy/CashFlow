import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';

/// Every write goes to the phone database and the upload outbox in one transaction (TRD 8).
class LocalWriter {
  LocalWriter(this.db, {required this.userId, DateTime Function()? clock, Uuid? uuid})
      : _clock = clock ?? DateTime.now,
        _uuid = uuid ?? const Uuid();

  final AppDatabase db;
  final String userId;
  final DateTime Function() _clock;
  final Uuid _uuid;

  /// Undo window before a delete or mark-paid can upload (FR-H4, FR-E11).
  static const undoWindow = Duration(seconds: 5);

  DateTime now() => _clock().toUtc();

  String newId() => _uuid.v4();

  /// Runs [body] in one database transaction; rows queued inside share one batch id
  /// so they upload together (TRD 6.3 atomic actions).
  Future<T> action<T>(Future<T> Function(String batchId) body) {
    final batchId = newId();
    return db.transaction(() => body(batchId));
  }

  Future<void> queue(String table, String rowId, String batchId, {String op = 'upsert', bool undoable = false}) {
    return db.into(db.syncOutbox).insert(SyncOutboxCompanion.insert(
          op: op,
          entityTable: table,
          rowId: rowId,
          batchId: batchId,
          createdAt: now(),
          notBefore: Value(undoable ? now().add(undoWindow) : null),
        ));
  }

  /// Undo inside the window: drops the queued rows of [batchId] so nothing reaches the server.
  Future<void> dropBatch(String batchId) =>
      (db.delete(db.syncOutbox)..where((o) => o.batchId.equals(batchId))).go();
}

/// The id used as `user_id` before account login exists (Phase D). Created once per install;
/// replaced by the account id at first login (T16).
Future<String> localUserId(AppDatabase db) async {
  const key = 'local_user_id';
  final existing = await db.flag(key);
  if (existing != null) return existing;
  final id = const Uuid().v4();
  await db.setFlag(key, id);
  return id;
}
