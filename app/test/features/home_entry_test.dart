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

  Future<void> addExpense(WidgetTester tester, String digits) async {
    await tester.tap(find.bySemanticsLabel('Add'));
    await settle(tester);
    await tester.tap(find.text('Expense').last);
    await settle(tester);
    await typeDigits(tester, digits);
    await tester.tap(find.text('Done'));
    await settle(tester);
  }

  testWidgets('empty Home, then add an expense: payment is required, Save never disabled', (tester) async {
    await openUnlockedHome(tester, h);
    expect(find.text('No entries yet'), findsOneWidget);
    expect(find.text('−₹0'), findsNothing); // zero expense has no minus sign (phone test, 16 Oct)
    expect(find.bySemanticsLabel('Settings'), findsOneWidget); // the avatar opens Settings

    await addExpense(tester, '2450');
    expect(find.text('− ₹2,450'), findsOneWidget);
    await tester.tap(find.text('Save expense'));
    await settle(tester);
    expect(find.text('Choose how you paid'), findsOneWidget); // red message, nothing saved
    expect(await h.db.select(h.db.transactions).get(), isEmpty);

    await tester.tap(find.text('Online'));
    await settle(tester);
    expect(find.text('UPI'), findsOneWidget);
    await tester.tap(find.text('Save expense'));
    await settle(tester);

    final rows = await h.db.select(h.db.transactions).get();
    expect(rows.single.amount, 245000);
    expect(rows.single.paymentMode, 'online');
    expect(rows.single.onlineMethod, 'upi');
    expect(find.text('−₹2,450'), findsWidgets); // tile + summary
    expect(find.text('No entries yet'), findsNothing);
    await closeApp(tester);
  });

  testWidgets('full swipe asks to confirm; Delete removes; Undo brings it back', (tester) async {
    await openUnlockedHome(tester, h);
    await addExpense(tester, '80');
    await tester.tap(find.text('Cash'));
    await tester.tap(find.text('Save expense'));
    await settle(tester);
    final tile = find.text('−₹80').last;
    await tester.drag(tile, const Offset(-300, 0));
    await settle(tester);
    expect(find.text('Delete this entry?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await settle(tester);
    expect((await h.db.select(h.db.transactions).getSingle()).deletedAt, isNotNull);
    expect(find.text('Undo'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect((await h.db.select(h.db.transactions).getSingle()).deletedAt, isNull);
    await closeApp(tester);
  });

  testWidgets('income with a new category typed in the picker', (tester) async {
    await openUnlockedHome(tester, h);
    await tester.tap(find.bySemanticsLabel('Add'));
    await settle(tester);
    await tester.tap(find.text('Income').last);
    await settle(tester);
    await typeDigits(tester, '45000');
    await tester.tap(find.text('Done'));
    await settle(tester);
    await tester.tap(find.text('Category'));
    await settle(tester);
    expect(find.text('Salary'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Tuition');
    await settle(tester);
    await tester.tap(find.text('Create "Tuition"'));
    await settle(tester);
    expect(find.text('Tuition'), findsOneWidget);
    await tester.tap(find.text('Online'));
    await tester.tap(find.text('Save income'));
    await settle(tester);
    final t = await h.db.select(h.db.transactions).getSingle();
    expect(t.kind, 'income');
    final cats = await h.db.select(h.db.categories).get();
    expect(cats.where((c) => c.name == 'Tuition' && c.kind == 'income'), hasLength(1));
    expect(find.text('+₹45,000'), findsWidgets);
    await closeApp(tester);
  });

  testWidgets('Home in dark mode renders without errors', (tester) async {
    await openUnlockedHome(tester, h, themeMode: ThemeMode.dark);
    expect(tester.takeException(), isNull);
    expect(find.text('Home'), findsWidgets);
    await closeApp(tester);
  });
}
