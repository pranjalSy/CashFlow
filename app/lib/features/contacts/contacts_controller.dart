import 'dart:convert';

import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services.dart';
import '../../data/providers.dart';
import '../../data/repositories/debt_repository.dart';
import '../../data/repositories/people_repository.dart';
import '../../data/repositories/calculations.dart';
import '../home/home_controller.dart';

/// What to call a phone contact: its name, else its name parts or nickname, else its first number.
/// Null when it has neither a name nor a number (such contacts are not listed).
String? contactName(Contact c) {
  String? clean(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();
  final n = c.name;
  final parts = n == null ? null : clean([n.first, n.middle, n.last].whereType<String>().join(' '));
  return clean(c.displayName) ?? parts ?? clean(n?.nickname) ?? clean(c.phones.isEmpty ? null : c.phones.first.number);
}

/// Phone contacts (read on the phone only, FR-D10). Null when permission is off.
/// Contacts without a name come after the named ones; contacts with no name and no number are left out.
/// The last list is kept in the encrypted phone database (a phone-only flag, never uploaded) and shown at
/// once on the next open, then refreshed from the phone, so the tab does not flash "Contacts are off".
final phoneContactsProvider = StreamProvider<List<Contact>?>((ref) async* {
  final access = ref.watch(contactsAccessProvider);
  final db = ref.watch(databaseProvider);
  const key = 'contacts_cache';
  final cached = await db.flag(key);
  if (cached != null) yield _decode(cached);
  if (!await access.granted()) {
    if (cached != null) await db.clearFlag(key);
    yield null;
    return;
  }
  final list = (await access.readAll()).where((c) => contactName(c) != null).toList();
  int rank(Contact c) => RegExp(r'\p{L}', unicode: true).hasMatch(c.displayName ?? '') ? 0 : 1;
  list.sort((a, b) {
    final r = rank(a).compareTo(rank(b));
    return r != 0 ? r : contactName(a)!.toLowerCase().compareTo(contactName(b)!.toLowerCase());
  });
  await db.setFlag(key, jsonEncode([
    for (final c in list) {'i': c.id, 'n': contactName(c), 'p': [for (final p in c.phones) p.number]},
  ]));
  yield list;
});

List<Contact> _decode(String json) => [
      for (final m in (jsonDecode(json) as List).cast<Map<String, dynamic>>())
        Contact(id: m['i'] as String?, displayName: m['n'] as String?, phones: [for (final p in (m['p'] as List).cast<String>()) Phone(number: p)]),
    ];

final personBalancesProvider = StreamProvider<Map<String, PersonBalance>>((ref) => ref.watch(calculationsProvider).watchPeople());

final lastActivityProvider = StreamProvider<Map<String, DateTime>>((ref) => ref.watch(debtRepositoryProvider).watchLastActivity());

/// Someone to show on Person detail: a saved person, or a phone contact not saved yet.
class PersonRef {
  const PersonRef({this.id, required this.name, this.phone, this.contactId});

  final String? id;
  final String name;
  final String? phone;
  final String? contactId;

  String? get normalizedPhone => PeopleRepository.normalizePhone(phone);

  Map<String, String> toQuery() => {
        'name': name,
        'phone': ?phone,
        'cid': ?contactId,
      };
}
