import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services.dart';
import '../../data/repositories/debt_repository.dart';
import '../../data/repositories/people_repository.dart';
import '../../data/repositories/calculations.dart';
import '../home/home_controller.dart';

/// Phone contacts (read on the phone only, FR-D10). Null when permission is off.
final phoneContactsProvider = FutureProvider<List<Contact>?>((ref) async {
  final access = ref.watch(contactsAccessProvider);
  if (!await access.granted()) return null;
  final list = await access.readAll();
  list.sort((a, b) => (a.displayName ?? '').toLowerCase().compareTo((b.displayName ?? '').toLowerCase()));
  return list;
});

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
