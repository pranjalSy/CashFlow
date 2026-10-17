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
      final h = Harness(contacts: FakeContacts(allowed: true, contacts: const [
          Contact(id: '1', phones: [Phone(number: '90000 00001')]),
          Contact(id: '5', displayName: '+91 90000 00002', phones: [Phone(number: '+91 90000 00002')]), // Android: number as name
          Contact(id: '2', displayName: 'zoya'),
          Contact(id: '3'),
          Contact(id: '4', displayName: 'Amit'),
        ]));
      await h.init();
      final container = ProviderContainer(overrides: h.overrides);
      addTearDown(container.dispose);
      container.listen(phoneContactsProvider, (_, _) {}); // keep it running (unlistened providers pause)
      final list = (await container.read(phoneContactsProvider.future))!;
      expect(list.map((c) => c.id), ['4', '2', '5', '1']);
      expect(list.map(contactName), ['Amit', 'zoya', '+91 90000 00002', '90000 00001']);
    });

    test('the last list is kept on the phone and shown first next time (owner, 17 Oct)', () async {
      final h = Harness(contacts: FakeContacts(allowed: true, contacts: const [Contact(id: '1', displayName: 'Rahul', phones: [Phone(number: '98765 43210')])]));
      await h.init();
      final first = ProviderContainer(overrides: h.overrides);
      first.listen(phoneContactsProvider, (_, _) {});
      await first.read(phoneContactsProvider.future);
      first.dispose();
      h.contacts.contacts = const []; // the phone has not answered yet / returns nothing
      final second = ProviderContainer(overrides: h.overrides);
      second.listen(phoneContactsProvider, (_, _) {});
      final cachedFirst = await second.read(phoneContactsProvider.future);
      expect(cachedFirst!.single.displayName, 'Rahul');
      expect(cachedFirst.single.phones.single.number, '98765 43210');
      second.dispose();
    });
  });
}
