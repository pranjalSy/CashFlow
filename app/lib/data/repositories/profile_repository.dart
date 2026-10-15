import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/database.dart';
import '../providers.dart';
import 'local_writer.dart';

/// The user's profile row (opening balance, language, preferences) and first-run state.
class ProfileRepository {
  ProfileRepository(this._w);

  final LocalWriter _w;
  AppDatabase get _db => _w.db;

  static const onboardingFlag = 'onboarding_done';

  Future<Profile?> current() =>
      (_db.select(_db.profiles)..where((p) => p.userId.equals(_w.userId) & p.deletedAt.isNull())).getSingleOrNull();

  Stream<Profile?> watch() =>
      (_db.select(_db.profiles)..where((p) => p.userId.equals(_w.userId) & p.deletedAt.isNull())).watchSingleOrNull();

  Future<bool> onboardingDone() async => (await _db.flag(onboardingFlag)) == 'true';

  /// Creates or updates the profile with the opening balance (FR-O7). Amounts in paise.
  Future<void> saveOpening({required int cash, required int online, required String language}) async {
    await _w.action((batch) async {
      final now = _w.now();
      final existing = await current();
      final id = existing?.id ?? _w.newId();
      await _db.into(_db.profiles).insertOnConflictUpdate(ProfilesCompanion(
            id: Value(id),
            userId: Value(_w.userId),
            createdAt: Value(existing?.createdAt ?? now),
            updatedAt: Value(now),
            openingCash: Value(cash),
            openingOnline: Value(online),
            language: Value(language),
            isSynced: const Value(false),
          ));
      await _w.queue('profiles', id, batch);
    });
  }

  Future<void> setLanguage(String language) async {
    final p = await current();
    if (p == null) return;
    await _w.action((batch) async {
      await (_db.update(_db.profiles)..where((t) => t.id.equals(p.id)))
          .write(ProfilesCompanion(language: Value(language), updatedAt: Value(_w.now()), isSynced: const Value(false)));
      await _w.queue('profiles', p.id, batch);
    });
  }

  Future<void> setHideAmounts(bool hide) async {
    final p = await current();
    if (p == null) return;
    await _w.action((batch) async {
      await (_db.update(_db.profiles)..where((t) => t.id.equals(p.id)))
          .write(ProfilesCompanion(hideAmounts: Value(hide), updatedAt: Value(_w.now()), isSynced: const Value(false)));
      await _w.queue('profiles', p.id, batch);
    });
  }

  /// Marks first run complete; makes sure a profile exists even if the opening balance was skipped.
  Future<void> finishOnboarding({required String language}) async {
    if (await current() == null) await saveOpening(cash: 0, online: 0, language: language);
    final p = (await current())!;
    await _w.action((batch) async {
      await (_db.update(_db.profiles)..where((t) => t.id.equals(p.id)))
          .write(ProfilesCompanion(onboardingDone: const Value(true), updatedAt: Value(_w.now()), isSynced: const Value(false)));
      await _w.queue('profiles', p.id, batch);
      await _db.setFlag(onboardingFlag, 'true');
    });
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ProfileRepository(ref.watch(localWriterProvider)));

final profileProvider = StreamProvider<Profile?>((ref) => ref.watch(profileRepositoryProvider).watch());
