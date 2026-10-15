import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local/database.dart';
import 'local/local_store.dart';
import 'repositories/local_writer.dart';

/// Opened once in bootstrap and injected with an override.
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('databaseProvider is overridden in bootstrap'));

final localStoreProvider = Provider<LocalStore>((ref) => LocalStore());

/// Owner of all local rows (local install id until account login).
final userIdProvider = Provider<String>((ref) => throw UnimplementedError('userIdProvider is overridden in bootstrap'));

final localWriterProvider = Provider<LocalWriter>(
  (ref) => LocalWriter(ref.watch(databaseProvider), userId: ref.watch(userIdProvider)),
);
