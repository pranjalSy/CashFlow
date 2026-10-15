import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/database.dart';
import '../providers.dart';
import 'local_writer.dart';

/// People used in udhar (FR-D7, FR-D10). Only people used in an entry are stored.
class PeopleRepository {
  PeopleRepository(this._w);

  final LocalWriter _w;
  AppDatabase get _db => _w.db;

  SimpleSelectStatement<$PeopleTable, PeopleData> _mine() =>
      _db.select(_db.people)..where((p) => p.userId.equals(_w.userId) & p.deletedAt.isNull());

  Stream<Map<String, PeopleData>> watchAll() => _mine().watch().map((list) => {for (final p in list) p.id: p});

  Future<PeopleData?> byId(String id) => (_db.select(_db.people)..where((p) => p.id.equals(id))).getSingleOrNull();

  Stream<PeopleData?> watchById(String id) => (_db.select(_db.people)..where((p) => p.id.equals(id))).watchSingleOrNull();

  /// Same number → same person (FR-D7). Without a number a new person is made.
  Future<PeopleData> findOrCreate({required String name, String? phone, String? contactId}) async {
    final normalized = normalizePhone(phone);
    if (normalized != null) {
      final existing = await (_mine()..where((p) => p.phoneNormalized.equals(normalized))).getSingleOrNull();
      if (existing != null) return existing;
    }
    return _w.action((batch) async {
      final now = _w.now();
      final id = _w.newId();
      await _db.into(_db.people).insert(PeopleCompanion.insert(
            id: id,
            userId: _w.userId,
            createdAt: now,
            updatedAt: now,
            name: name.trim(),
            phoneNormalized: Value(normalized),
            contactCacheId: Value(contactId),
          ));
      await _w.queue('people', id, batch);
      return (await byId(id))!;
    });
  }

  /// E.164 for Indian numbers: "98250 44321", "+91-98250-44321", "098250 44321" → "+919825044321".
  static String? normalizePhone(String? raw) {
    if (raw == null) return null;
    var digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return null;
    if (digits.startsWith('+')) return '+${digits.substring(1).replaceAll('+', '')}';
    digits = digits.replaceAll('+', '');
    if (digits.startsWith('00')) return '+${digits.substring(2)}';
    if (digits.length == 11 && digits.startsWith('0')) digits = digits.substring(1);
    if (digits.length == 10) return '+91$digits';
    if (digits.length == 12 && digits.startsWith('91')) return '+$digits';
    return '+$digits';
  }
}

final peopleRepositoryProvider = Provider<PeopleRepository>((ref) => PeopleRepository(ref.watch(localWriterProvider)));

final peopleByIdProvider = StreamProvider<Map<String, PeopleData>>((ref) => ref.watch(peopleRepositoryProvider).watchAll());
