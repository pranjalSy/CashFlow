import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/database.dart';
import '../providers.dart';

/// The plan mirrored from the server (TRD 13.2). Until billing exists (T20) only the dev flavor
/// can switch Premium on, so Premium screens can be tested; prod is always Free here.
class PlanRepository {
  PlanRepository(this._db);

  final AppDatabase _db;

  Stream<bool> watchPremium() =>
      (_db.select(_db.planCache)..where((p) => p.id.equals(1))).watchSingleOrNull().map((p) => p?.isPremium ?? false);

  /// When the current Premium period ends ("Renews …" in Settings); null when unknown.
  Stream<DateTime?> watchActiveUntil() =>
      (_db.select(_db.planCache)..where((p) => p.id.equals(1))).watchSingleOrNull().map((p) => p?.activeUntil);

  Future<bool> isPremium() async => (await (_db.select(_db.planCache)..where((p) => p.id.equals(1))).getSingleOrNull())?.isPremium ?? false;

  /// Dev flavor only (Settings › Developer). The server decides in Phase D.
  Future<void> setPremiumForDev(bool on) =>
      _db.into(_db.planCache).insertOnConflictUpdate(PlanCacheCompanion(id: const Value(1), isPremium: Value(on)));
}

final planRepositoryProvider = Provider<PlanRepository>((ref) => PlanRepository(ref.watch(databaseProvider)));

final isPremiumProvider = StreamProvider<bool>((ref) => ref.watch(planRepositoryProvider).watchPremium());

final planActiveUntilProvider = StreamProvider<DateTime?>((ref) => ref.watch(planRepositoryProvider).watchActiveUntil());
