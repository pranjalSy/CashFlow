import 'package:cashflow/app/app.dart';
import 'package:cashflow/core/config/flavor.dart';
import 'package:cashflow/core/prefs.dart';
import 'package:cashflow/core/security/biometric_service.dart';
import 'package:cashflow/core/security/pin_service.dart';
import 'package:cashflow/core/services.dart';
import 'package:cashflow/data/local/database.dart';
import 'package:cashflow/data/providers.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeBiometrics extends BiometricService {
  FakeBiometrics({this.available = FingerprintState.unavailable, this.succeed = true});

  final FingerprintState available;
  final bool succeed;
  bool enabled = false;
  int prompts = 0;

  @override
  Future<FingerprintState> state() async => available;

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<void> setEnabled(bool value) async => enabled = value;

  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return succeed;
  }
}

class FakeContacts extends ContactsAccess {
  FakeContacts({this.allowed = false, this.contacts = const []});

  bool allowed;
  final List<Contact> contacts;
  int requests = 0;

  @override
  Future<bool> granted() async => allowed;

  @override
  Future<bool> request() async {
    requests++;
    return allowed;
  }

  @override
  Future<List<Contact>> readAll() async => contacts;
}

/// Everything the app needs, in memory: database, prefs, secure storage, fake sensors.
class Harness {
  Harness({FakeBiometrics? biometrics, FakeContacts? contacts})
      : biometrics = biometrics ?? FakeBiometrics(),
        contacts = contacts ?? FakeContacts();

  final db = AppDatabase(NativeDatabase.memory());
  final FakeBiometrics biometrics;
  final FakeContacts contacts;
  static const userId = 'test-user';
  late UiPrefs prefs;

  Future<void> init({Map<String, Object> prefsValues = const {}}) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    SharedPreferences.setMockInitialValues(prefsValues);
    FlutterSecureStorage.setMockInitialValues({});
    prefs = UiPrefs(await SharedPreferences.getInstance());
  }

  List<Override> get overrides => [
        databaseProvider.overrideWithValue(db),
        userIdProvider.overrideWithValue(userId),
        uiPrefsProvider.overrideWithValue(prefs),
        pinServiceProvider.overrideWithValue(PinService(iterations: 1000, offThread: false)),
        biometricServiceProvider.overrideWithValue(biometrics),
        contactsAccessProvider.overrideWithValue(contacts),
      ];

  Widget app({ThemeMode? themeMode}) {
    FlavorConfig.init(Flavor.dev);
    return ProviderScope(overrides: overrides, child: CashFlowApp(themeMode: themeMode));
  }

  Future<void> dispose() => db.close();
}

/// Taps digits on the number pad.
Future<void> typeDigits(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    await tester.tap(find.text(d).last);
    await tester.pump();
  }
}
