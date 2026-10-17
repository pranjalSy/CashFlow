import 'package:cashflow/core/utils/dates.dart';
import 'package:cashflow/data/repositories/emi_repository.dart';
import 'package:cashflow/data/repositories/local_writer.dart';
import 'package:cashflow/data/repositories/plan_repository.dart';
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
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  EmiRepository emis() => EmiRepository(LocalWriter(h.db, userId: Harness.userId));

  Future<void> openEmiTab(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('EMI'));
    await settle(tester);
  }

  /// Add EMI form up to the loan, rate and "I know the" choice.
  Future<void> fillLoan(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Add'));
    await settle(tester);
    await tester.tap(find.text('Add EMI').last);
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'Bike loan');
    await tester.tap(find.text('Loan amount'));
    await settle(tester);
    await typeDigits(tester, '90000');
    await tester.tap(find.text('Interest (yearly)'));
    await settle(tester);
    await typeDigits(tester, '12');
  }

  testWidgets('Free: EMI tab shows the locked card', (tester) async {
    await openUnlockedHome(tester, h);
    await openEmiTab(tester);
    expect(find.text('Never miss an EMI or bill'), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('Premium: add EMI with months → ₹7,996.39; mark paid needs Paid via; Undo (FR-E1–E11)', (tester) async {
    await PlanRepository(h.db).setPremiumForDev(true);
    await openUnlockedHome(tester, h);
    await openEmiTab(tester);
    expect(find.text('No EMIs yet'), findsOneWidget);
    await fillLoan(tester);
    await tester.tap(find.text('Number of months'));
    await settle(tester);
    await typeDigits(tester, '12');
    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(find.text('₹7,996.39'), findsOneWidget);
    expect(find.text('₹5,956.69'), findsOneWidget);
    expect(find.text('₹95,956.69'), findsOneWidget);
    await tester.tap(find.text('Save EMI'));
    await settle(tester);

    expect(find.text('Bike loan'), findsOneWidget);
    expect(find.text('0 of 12 paid · 12 left'), findsOneWidget);
    expect(find.text('₹95,957 remaining'), findsOneWidget); // whole rupees on the card (screen 17)

    await tester.tap(find.text('Bike loan'));
    await settle(tester);
    expect(find.text('Mark paid'), findsOneWidget); // only on the next due installment
    await tester.tap(find.text('Mark paid'));
    await settle(tester);
    expect(find.text('Mark as paid'), findsOneWidget);
    await tester.tap(find.text('Mark paid').last);
    await settle(tester);
    expect(find.text('Choose how you paid'), findsOneWidget);
    expect(await h.db.select(h.db.transactions).get(), isEmpty);

    await tester.tap(find.text('Cash').last);
    await tester.tap(find.text('Mark paid').last);
    await settle(tester);
    expect(find.text('Installment 1 paid'), findsOneWidget);
    final txn = (await h.db.select(h.db.transactions).get()).single;
    expect(txn.amount, 799639);
    expect(txn.source, 'emi');

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(await h.db.select(h.db.transactions).get(), isEmpty);
    final installments = await h.db.select(h.db.emiInstallments).get();
    expect(installments.where((i) => i.status == 'paid'), isEmpty);
    await closeApp(tester);
  });

  testWidgets('Premium: EMI ₹800 is not possible; Save does not save (FR-E9)', (tester) async {
    await PlanRepository(h.db).setPremiumForDev(true);
    await openUnlockedHome(tester, h);
    await openEmiTab(tester);
    await fillLoan(tester);
    await tester.tap(find.text('EMI amount'));
    await settle(tester);
    await typeDigits(tester, '800');
    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(find.text('Not possible'), findsOneWidget);
    expect(find.textContaining('Interest alone is ₹900 a month'), findsOneWidget);
    await tester.tap(find.text('Save EMI'));
    await settle(tester);
    expect(find.text('Not possible'), findsOneWidget); // still on the form
    expect(await h.db.select(h.db.emis).get(), isEmpty);
    await closeApp(tester);
  });

  testWidgets('Premium: EMI amount ₹8,500 → 12 months, last EMI ₹2,112.98', (tester) async {
    await PlanRepository(h.db).setPremiumForDev(true);
    await openUnlockedHome(tester, h);
    await openEmiTab(tester);
    await fillLoan(tester);
    await tester.tap(find.text('EMI amount'));
    await settle(tester);
    await typeDigits(tester, '8500');
    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(find.text('12 months'), findsOneWidget);
    expect(find.textContaining('₹2,112.9'), findsOneWidget); // ₹2,112.98 ±1 paisa (monthly rounding, see T03)
    await closeApp(tester);
  });

  testWidgets('Premium: "Paid or not?" on Home open; Paid opens Mark paid and adds the expense (FR-E6, E7)', (tester) async {
    await PlanRepository(h.db).setPremiumForDev(true);
    final today = Ist.today();
    await emis().add(EmiDraft(name: 'Bike loan', icon: 'bike', lender: 'HDFC', loanAmount: 9000000, rateBp: 1200, months: 12, emiAmount: 799639, firstDue: today));
    await openUnlockedHome(tester, h);
    expect(find.text('EMI due today'), findsOneWidget);
    expect(find.text('Paid or not?'), findsOneWidget);
    await tester.tap(find.text('Paid'));
    await settle(tester);
    expect(find.text('Mark as paid'), findsOneWidget);
    await tester.tap(find.text('Online').last);
    await settle(tester);
    await tester.tap(find.text('Mark paid').last);
    await settle(tester);
    final txn = (await h.db.select(h.db.transactions).get()).single;
    expect(txn.paymentMode, 'online');
    expect(txn.amount, 799639);
    await tester.pump(LocalWriter.undoWindow); // let the Undo snackbar time out
    await closeApp(tester);
  });

  testWidgets('Premium: Not yet closes the popup, nothing is saved', (tester) async {
    await PlanRepository(h.db).setPremiumForDev(true);
    await emis().add(EmiDraft(name: 'Phone', icon: 'phone', loanAmount: 2939400, rateBp: 0, months: 6, emiAmount: 489900, firstDue: Ist.today()));
    await openUnlockedHome(tester, h);
    await tester.tap(find.text('Not yet'));
    await settle(tester);
    expect(find.text('Paid or not?'), findsNothing);
    expect(await h.db.select(h.db.transactions).get(), isEmpty);
    await closeApp(tester);
  });

  testWidgets('EMI detail does not scroll on open when the due installment already fits (phone test, 16 Oct)', (tester) async {
    await PlanRepository(h.db).setPremiumForDev(true);
    await emis().add(EmiDraft(name: 'Bike loan', icon: 'bike', loanAmount: 9000000, rateBp: 1200, months: 12, emiAmount: 799639, firstDue: Ist.today().addDays(3)));
    await openUnlockedHome(tester, h);
    await openEmiTab(tester);
    await tester.tap(find.text('Bike loan'));
    await settle(tester);
    expect(tester.state<ScrollableState>(find.byType(Scrollable).last).position.pixels, 0);
    expect(find.text('Remaining to pay'), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('dev Premium switch also turns on from the row', (tester) async {
    await openUnlockedHome(tester, h);
    await tester.tap(find.bySemanticsLabel('Settings'));
    await settle(tester);
    await tester.scrollUntilVisible(find.text('Premium (dev only)'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Premium (dev only)'));
    await settle(tester);
    expect(await PlanRepository(h.db).isPremium(), isTrue);
    await closeApp(tester);
  });
}
