import 'package:cashflow/core/prefs.dart';
import 'package:cashflow/core/security/biometric_service.dart';
import 'package:cashflow/core/security/pin_service.dart';
import 'package:cashflow/core/system.dart';
import 'package:cashflow/data/local/database.dart';
import 'package:cashflow/data/repositories/local_writer.dart';
import 'package:cashflow/data/repositories/plan_repository.dart';
import 'package:cashflow/data/repositories/profile_repository.dart';
import 'package:cashflow/features/lock/lock_controller.dart';
import 'package:cashflow/features/settings/settings_screen.dart';
import 'package:cashflow/shared/widgets/glass.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

class _FakeSystem extends SystemService {
  final opened = <String>[];

  @override
  Future<String> appVersion() async => '1.0.0';

  @override
  Future<void> openAppSettings() async => opened.add('app-settings');

  @override
  Future<void> openUrl(String url) async => opened.add(url);
}

void main() {
  late Harness h;
  late _FakeSystem system;

  setUp(() async {
    h = Harness(biometrics: FakeBiometrics(available: FingerprintState.ready));
    await h.init();
    system = _FakeSystem();
    h.extraOverrides = [systemServiceProvider.overrideWithValue(system)];
  });
  tearDown(() => h.dispose());

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  ProfileRepository profiles() => ProfileRepository(LocalWriter(h.db, userId: Harness.userId));

  Future<void> openSettings(WidgetTester tester) async {
    await profiles().saveOpening(cash: 0, online: 0, language: 'en');
    await openUnlockedHome(tester, h);
    await tester.tap(find.bySemanticsLabel('Settings'));
    await settle(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);
  }

  ProviderContainer container(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(SettingsScreen)));

  Future<void> scrollTo(WidgetTester tester, String text) async {
    await tester.scrollUntilVisible(find.text(text), 200, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text(text));
    await settle(tester);
  }

  testWidgets('Theme, language and default reminder are picked from sheets and saved (FR-G1, FR-U9, FR-R2)', (tester) async {
    await openSettings(tester);
    expect(find.text('You are on Free'), findsOneWidget);
    expect(find.text('CashFlow 1.0.0 · Made in India'), findsNothing); // at the bottom

    await tester.tap(find.text('Theme'));
    await settle(tester);
    await tester.tap(find.text('Dark'));
    await settle(tester);
    expect(container(tester).read(themeModeProvider), ThemeMode.dark);
    expect(h.prefs.themeMode, ThemeMode.dark);

    await tester.tap(find.text('Default reminder'));
    await settle(tester);
    expect(find.text('Used for new udhar due dates and bills. You can change it on each item.'), findsOneWidget);
    await tester.tap(find.text('7 days before'));
    await settle(tester);
    expect((await profiles().current())!.defaultReminderDays, 7);
    expect(find.text('7 days before'), findsOneWidget); // the row shows the new value

    await tester.tap(find.text('Language'));
    await settle(tester);
    await tester.tap(find.text('हिन्दी').last);
    await settle(tester);
    expect(h.prefs.language, 'hi');
    expect((await profiles().current())!.language, 'hi');
    expect(find.text('सामान्य'), findsOneWidget); // "General" in Hindi, at once
    await closeApp(tester);
  });

  testWidgets('switches: hide amounts, reduce glass, anonymous usage', (tester) async {
    await openSettings(tester);
    await tester.tap(find.text('Hide amounts in notifications'));
    await settle(tester);
    expect((await profiles().current())!.hideAmounts, isTrue);

    await scrollTo(tester, 'Reduce glass effects');
    await tester.tap(find.text('Reduce glass effects'));
    await settle(tester);
    expect(container(tester).read(reduceGlassProvider), isTrue);
    expect(h.prefs.reduceGlass, isTrue);

    await tester.tap(find.text('Share anonymous usage'));
    await settle(tester);
    expect((await profiles().current())!.analyticsOptIn, isFalse);
    await closeApp(tester);
  });

  testWidgets('Lock after: Immediately is used at once and kept after a restart (FR-L8)', (tester) async {
    await openSettings(tester);
    expect(find.text('1 minute'), findsOneWidget); // default
    await tester.tap(find.text('Lock after'));
    await settle(tester);
    await tester.tap(find.text('Immediately'));
    await settle(tester);
    expect(h.prefs.lockAfterSeconds, 0);
    expect(container(tester).read(lockControllerProvider).lockAfter, Duration.zero);
    await closeApp(tester);

    final restarted = ProviderContainer(overrides: h.overrides);
    addTearDown(restarted.dispose);
    expect(restarted.read(lockControllerProvider).lockAfter, Duration.zero);
  });

  testWidgets('App lock: fingerprint turns on only after the system check; Change PIN needs the old PIN (FR-L4, FR-L8)', (tester) async {
    await openSettings(tester);
    expect(find.text('PIN'), findsOneWidget);
    await tester.tap(find.text('App lock'));
    await settle(tester);
    await tester.tap(find.text('Unlock with fingerprint'));
    await settle(tester);
    expect(h.biometrics.prompts, 1);
    expect(h.biometrics.enabled, isTrue);

    await tester.tap(find.text('Change PIN'));
    await settle(tester);
    expect(find.text('Enter your current PIN'), findsOneWidget);
    await typeDigits(tester, '1111');
    await settle(tester);
    expect(find.text('Wrong PIN. 4 tries left'), findsOneWidget);
    await typeDigits(tester, '4829');
    await settle(tester);
    expect(find.text('Choose a new PIN'), findsOneWidget);
    await typeDigits(tester, '7351');
    await settle(tester);
    await typeDigits(tester, '7350'); // mismatch: back to the new PIN step
    await settle(tester);
    expect(find.text("PINs don't match. Try again."), findsOneWidget);
    await typeDigits(tester, '7351');
    await settle(tester);
    await typeDigits(tester, '7351');
    await settle(tester);
    expect(find.text('PIN changed'), findsOneWidget);
    expect(find.text('PIN + Fingerprint'), findsOneWidget);
    final pins = PinService(iterations: 1000, offThread: false);
    expect((await pins.verify('7351')).outcome, PinOutcome.ok);
    await tester.pump(const Duration(seconds: 5)); // let the "PIN changed" snackbar finish
    await closeApp(tester);
  });

  testWidgets('Help opens the phone settings; Log out only explains for now (nothing is erased)', (tester) async {
    await openSettings(tester);
    await scrollTo(tester, 'Reminders not coming?');
    await tester.tap(find.text('Reminders not coming?'));
    await settle(tester);
    expect(find.text('Turn on Auto-launch / Auto-start'), findsOneWidget);
    await tester.tap(find.text('Open phone settings'));
    await settle(tester);
    expect(system.opened, ['app-settings']);
    await tester.tapAt(const Offset(20, 20)); // close the sheet
    await settle(tester);

    await scrollTo(tester, 'Log out');
    await tester.tap(find.text('Log out'));
    await settle(tester);
    expect(find.text('Log out?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(find.text('Log out?'), findsNothing);
    expect(await profiles().current(), isNotNull);

    await scrollTo(tester, 'CashFlow 1.0.0 · Made in India');
    expect(find.text('CashFlow 1.0.0 · Made in India'), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('Premium: plan card shows the renewal date and Manage opens Play subscriptions', (tester) async {
    await h.db.into(h.db.planCache).insertOnConflictUpdate(
          PlanCacheCompanion(id: const Value(1), isPremium: const Value(true), activeUntil: Value(DateTime.utc(2027, 1, 14, 6))),
        );
    await openSettings(tester);
    expect(find.text('CashFlow Premium'), findsOneWidget);
    expect(find.text('Renews 14 Jan 2027'), findsOneWidget);
    await tester.tap(find.text('Manage'));
    await settle(tester);
    expect(system.opened.single, contains('play.google.com/store/account/subscriptions'));
    await closeApp(tester);
  });

  testWidgets('Hindi at 2× text: Settings has no overflow', (tester) async {
    await h.prefs.setLanguage('hi');
    await profiles().saveOpening(cash: 0, online: 0, language: 'hi');
    await openUnlockedHome(tester, h);
    await tester.tap(find.bySemanticsLabel('सेटिंग्स').first);
    await settle(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await settle(tester);
    for (var i = 0; i < 8; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await settle(tester);
    }
    expect(tester.takeException(), isNull);
    await closeApp(tester);
  });

  testWidgets('Default reminder 7 days is preselected on a new udhar due date', (tester) async {
    await PlanRepository(h.db).setPremiumForDev(true);
    await profiles().saveOpening(cash: 0, online: 0, language: 'en');
    await profiles().setDefaultReminder(7);
    await openUnlockedHome(tester, h);
    await tester.tap(find.bySemanticsLabel('Add'));
    await settle(tester);
    await tester.tap(find.text('Lent').last);
    await settle(tester);
    await typeDigits(tester, '500');
    await tester.tap(find.text('Done'));
    await settle(tester);
    await tester.tap(find.text('Choose a person').first);
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Rahul');
    await settle(tester);
    await tester.tap(find.text('Add person: Rahul'));
    await settle(tester);
    await tester.tap(find.text('Cash'));
    await tester.tap(find.text('1 week'));
    await settle(tester);
    await tester.tap(find.text('Save lent'));
    await settle(tester);
    final debt = (await h.db.select(h.db.debts).get()).single;
    expect(debt.reminderDays, '0,7');
    await closeApp(tester);
  });
}
