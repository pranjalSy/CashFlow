import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'security/biometric_service.dart';
import 'security/pin_service.dart';

final pinServiceProvider = Provider<PinService>((ref) => PinService());

final biometricServiceProvider = Provider<BiometricService>((ref) => BiometricService());

/// Phone contacts permission and reading (contacts stay on the phone, FR-D10).
class ContactsAccess {
  const ContactsAccess();

  Future<bool> granted() => FlutterContacts.permissions.has(PermissionType.read);

  Future<bool> request() async {
    final status = await FlutterContacts.permissions.request(PermissionType.read);
    return status == PermissionStatus.granted || status == PermissionStatus.limited;
  }

  Future<void> openSettings() => FlutterContacts.permissions.openSettings();

  /// Name + phone numbers only; nothing is uploaded from here.
  Future<List<Contact>> readAll() => FlutterContacts.getAll(properties: {ContactProperty.name, ContactProperty.phone});
}

final contactsAccessProvider = Provider<ContactsAccess>((ref) => const ContactsAccess());
