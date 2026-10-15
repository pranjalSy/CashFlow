import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database.dart';

/// Where the phone data lives and how it is opened and wiped (TRD 9, 11.1).
class LocalStore {
  LocalStore({FlutterSecureStorage? storage, Future<Directory> Function()? directory})
      : _storage = storage ?? const FlutterSecureStorage(),
        _directory = directory ?? getApplicationSupportDirectory;

  final FlutterSecureStorage _storage;
  final Future<Directory> Function() _directory;

  static const dbKeyName = 'db_key_v1';
  static const dbFileName = 'cashflow.db';

  Future<File> databaseFile() async => File(p.join((await _directory()).path, dbFileName));

  /// Random 256-bit key, created once and kept only in Android Keystore-backed storage.
  Future<String> databaseKey() async {
    final existing = await _storage.read(key: dbKeyName);
    if (existing != null && existing.isNotEmpty) return existing;
    final rnd = Random.secure();
    final key = List.generate(32, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    await _storage.write(key: dbKeyName, value: key);
    return key;
  }

  Future<AppDatabase> open() async {
    final file = await databaseFile();
    final key = await databaseKey();
    return AppDatabase(openEncryptedDatabase(file, key));
  }

  /// Logout / remote wipe (FR-A2, J6): closes the database, deletes its files and every
  /// secure-storage entry (database key, PIN hash, fingerprint flag, counters).
  Future<void> wipe({AppDatabase? openDb}) async {
    await openDb?.close();
    final file = await databaseFile();
    for (final path in [file.path, '${file.path}-wal', '${file.path}-shm', '${file.path}-journal']) {
      final f = File(path);
      if (await f.exists()) await f.delete();
    }
    await _storage.deleteAll();
  }
}
