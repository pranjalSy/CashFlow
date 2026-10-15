import 'package:cashflow/core/security/biometric_service.dart';
import 'package:cashflow/core/security/pin_service.dart';
import 'package:cashflow/data/repositories/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  late Harness h;

  setUp(() async {
    h = Harness();
    await h.init();
  });
  tearDown(() => h.dispose());

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  Future<void> toPinScreen(WidgetTester tester) async {
    await tester.pumpWidget(h.app(themeMode: ThemeMode.light));
    await settle(tester);
    await tester.tap(find.text('Create account'));
    await settle(tester);
    await tester.tap(find.text('Continue'));
    await settle(tester);
  }

  testWidgets('first run saves the opening balance and finishes on Home', (tester) async {
    await toPinScreen(tester);
    await typeDigits(tester, '4829');
    await settle(tester);
    await typeDigits(tester, '4829');
    await settle(tester);
    // No fingerprint sensor: that step is skipped automatically (C5).
    expect(find.text('How much money do you have now?'), findsOneWidget);
    await typeDigits(tester, '850');
    await tester.tap(find.text('In bank / UPI'));
    await tester.pump();
    await typeDigits(tester, '111500');
    await tester.pump();
    expect(find.text('₹1,12,350'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.text('Track udhar with your contacts'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await settle(tester);
    expect(find.text('Home'), findsWidgets);

    final p = await h.db.select(h.db.profiles).getSingle();
    expect(p.openingCash, 85000);
    expect(p.openingOnline, 11150000);
    expect(p.onboardingDone, isTrue);
    expect(await h.db.flag(ProfileRepository.onboardingFlag), 'true');
    expect(await h.db.select(h.db.syncOutbox).get(), isNotEmpty);
    expect(h.contacts.requests, 0);
  });

  testWidgets('"Allow contacts" asks the system permission', (tester) async {
    await toPinScreen(tester);
    await typeDigits(tester, '4829');
    await settle(tester);
    await typeDigits(tester, '4829');
    await settle(tester);
    await tester.tap(find.text('Skip for now'));
    await settle(tester);
    await tester.tap(find.text('Allow contacts'));
    await settle(tester);
    expect(h.contacts.requests, 1);
    expect(find.text('Home'), findsWidgets);
  });

  testWidgets('language choice applies immediately (Hindi)', (tester) async {
    await tester.pumpWidget(h.app(themeMode: ThemeMode.light));
    await settle(tester);
    await tester.tap(find.text('Log in'));
    await settle(tester);
    expect(find.text('Coming soon'), findsWidgets);
    await tester.tap(find.text('हिन्दी'));
    await settle(tester);
    expect(find.text('अपनी भाषा चुनें'), findsOneWidget);
    expect(h.prefs.language, 'hi');
    await tester.tap(find.text('आगे बढ़ें'));
    await settle(tester);
    expect(find.text('4 अंकों का PIN बनाएं'), findsOneWidget);
  });

  testWidgets('PIN mismatch asks again', (tester) async {
    await toPinScreen(tester);
    await typeDigits(tester, '4829');
    await settle(tester);
    expect(find.text('Enter the PIN again'), findsOneWidget);
    await typeDigits(tester, '1111');
    await settle(tester);
    expect(find.text("PINs don't match. Try again."), findsOneWidget);
    expect(find.text('Create a 4-digit PIN'), findsOneWidget);
  });

  testWidgets('enrolled fingerprint is offered; enabling needs one successful scan', (tester) async {
    h = Harness(biometrics: FakeBiometrics(available: FingerprintState.ready));
    await h.init();
    await toPinScreen(tester);
    await typeDigits(tester, '4829');
    await settle(tester);
    await typeDigits(tester, '4829');
    await settle(tester);
    expect(find.text('Unlock with fingerprint?'), findsOneWidget);
    await tester.tap(find.text('Use fingerprint'));
    await settle(tester);
    expect(h.biometrics.prompts, 1);
    expect(h.biometrics.enabled, isTrue);
    expect(find.text('How much money do you have now?'), findsOneWidget);
  });

  testWidgets('sensor without a finger shows "Set up fingerprint first"', (tester) async {
    h = Harness(biometrics: FakeBiometrics(available: FingerprintState.notEnrolled));
    await h.init();
    await toPinScreen(tester);
    await typeDigits(tester, '4829');
    await settle(tester);
    await typeDigits(tester, '4829');
    await settle(tester);
    expect(find.text('Set up fingerprint first'), findsOneWidget);
  });

  testWidgets('returning user: lock screen; wrong PIN counts down, right PIN opens Home', (tester) async {
    await h.db.setFlag(ProfileRepository.onboardingFlag, 'true');
    await PinService(iterations: 1000, offThread: false).setPin('4829');
    await tester.pumpWidget(h.app(themeMode: ThemeMode.light));
    await settle(tester);
    expect(find.text('Enter your PIN'), findsOneWidget);
    await typeDigits(tester, '0000');
    await settle(tester);
    expect(find.text('Wrong PIN. 4 tries left'), findsOneWidget);
    await typeDigits(tester, '4829');
    await settle(tester);
    expect(find.text('Home'), findsWidgets);
  });

  testWidgets('returning user with fingerprint is asked for it first', (tester) async {
    h = Harness(biometrics: FakeBiometrics(available: FingerprintState.ready)..enabled = true);
    await h.init();
    await h.db.setFlag(ProfileRepository.onboardingFlag, 'true');
    await PinService(iterations: 1000, offThread: false).setPin('4829');
    await tester.pumpWidget(h.app(themeMode: ThemeMode.light));
    await settle(tester);
    expect(h.biometrics.prompts, 1);
    expect(find.text('Home'), findsWidgets);
  });
}
