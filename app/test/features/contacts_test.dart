import 'package:cashflow/core/services.dart';
import 'package:cashflow/features/contacts/contacts_controller.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  // Owner bug (16 Oct 2026): contacts saved without a name showed as "?".
  group('phone contacts without a name', () {
    test('name, else name parts, else nickname, else number; nothing → null', () {
      expect(contactName(const Contact(displayName: ' Rahul Sharma ')), 'Rahul Sharma');
      expect(contactName(const Contact(name: Name(first: 'Amit', last: 'Patel'))), 'Amit Patel');
      expect(contactName(const Contact(name: Name(nickname: 'Chhotu'))), 'Chhotu');
      expect(contactName(const Contact(displayName: '', phones: [Phone(number: '98765 43210')])), '98765 43210');
      expect(contactName(const Contact()), isNull);
    });

    test('list: named first (A–Z), number-only after, empty ones left out', () async {
      final container = ProviderContainer(overrides: [
        contactsAccessProvider.overrideWithValue(FakeContacts(allowed: true, contacts: const [
          Contact(id: '1', phones: [Phone(number: '90000 00001')]),
          Contact(id: '5', displayName: '+91 90000 00002', phones: [Phone(number: '+91 90000 00002')]), // Android: number as name
          Contact(id: '2', displayName: 'zoya'),
          Contact(id: '3'),
          Contact(id: '4', displayName: 'Amit'),
        ])),
      ]);
      addTearDown(container.dispose);
      final list = (await container.read(phoneContactsProvider.future))!;
      expect(list.map((c) => c.id), ['4', '2', '5', '1']);
      expect(list.map(contactName), ['Amit', 'zoya', '+91 90000 00002', '90000 00001']);
    });
  });
}
