import 'package:cashflow/core/utils/dates.dart';
import 'package:cashflow/data/repositories/debt_repository.dart';
import 'package:cashflow/data/repositories/local_writer.dart';
import 'package:cashflow/data/repositories/people_repository.dart';
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

  DebtRepository debts() => DebtRepository(LocalWriter(h.db, userId: Harness.userId));

  /// Rahul borrowed ₹5,000 from you on 1 Oct, ₹2,000 already back, due today.
  Future<String> dueUdhar() async {
    final rahul = await PeopleRepository(LocalWriter(h.db, userId: Harness.userId)).findOrCreate(name: 'Rahul Sharma');
    final repo = debts();
    final id = await repo.add(
      personId: rahul.id,
      direction: 'lent',
      amount: 500000,
      occurredAt: DateTime.utc(2026, 10, 1, 6),
      paymentMode: 'cash',
      dueDate: Ist.today(),
      premium: true,
    );
    await repo.recordRepayment(debtId: id, amount: 200000, occurredAt: DateTime.utc(2026, 10, 5, 6), paymentMode: 'cash');
    await PlanRepository(h.db).setPremiumForDev(true);
    return id;
  }

  testWidgets('Free: add lent from the + menu, due date shows Premium, overpayment adds the extra as borrowed', (tester) async {
    await openUnlockedHome(tester, h);
    await tester.tap(find.bySemanticsLabel('Add'));
    await settle(tester);
    await tester.tap(find.text('Lent').last);
    await settle(tester);
    expect(find.text('You gave someone'), findsOneWidget); // Lent | Borrowed switch at the top (screen 15)

    await typeDigits(tester, '5000');
    await tester.tap(find.text('Done'));
    await settle(tester);
    await tester.tap(find.text('Save lent'));
    await settle(tester);
    expect(find.text('Choose who you gave money to'), findsOneWidget); // red message, nothing saved
    expect(await h.db.select(h.db.debts).get(), isEmpty);

    await tester.tap(find.text('No due date'));
    await settle(tester);
    expect(find.text('Due dates are Premium'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await settle(tester);

    await tester.tap(find.text('Choose a person').first);
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Rahul Sharma');
    await settle(tester);
    await tester.tap(find.text('Add person: Rahul Sharma'));
    await settle(tester);
    await tester.tap(find.text('Cash'));
    await tester.tap(find.text('Save lent'));
    await settle(tester);
    final debt = (await h.db.select(h.db.debts).get()).single;
    expect(debt.amount, 500000);
    expect(debt.dueDate, isNull);

    await tester.tap(find.bySemanticsLabel('Contacts'));
    await settle(tester);
    await tester.tap(find.text('Rahul Sharma').first);
    await settle(tester);
    expect(find.text('Rahul owes you'), findsOneWidget);

    await tester.tap(find.text('Repayment'));
    await settle(tester);
    await typeDigits(tester, '6000');
    await tester.tap(find.text('Cash').last);
    await tester.tap(find.text('Save payment'));
    await settle(tester);
    expect(find.text('Payment saved'), findsOneWidget);
    expect(find.text('₹1,000 extra. Add it as borrowed?'), findsOneWidget);
    await tester.tap(find.text('Yes'));
    await settle(tester);

    final payment = (await h.db.select(h.db.debtPayments).get()).single;
    expect(payment.amount, 500000); // capped at the remaining amount (G8)
    final all = await h.db.select(h.db.debts).get();
    expect(all.firstWhere((d) => d.id == debt.id).status, 'settled');
    final extra = all.singleWhere((d) => d.id != debt.id);
    expect(extra.direction, 'borrowed');
    expect(extra.amount, 100000);
    await closeApp(tester);
  });

  testWidgets('Premium: due popup on Home open, Got some saves a repayment (G9)', (tester) async {
    final id = await dueUdhar();
    await openUnlockedHome(tester, h);
    expect(find.text('Udhar due today'), findsOneWidget);
    expect(find.text('Rahul Sharma · ₹3,000'), findsOneWidget);
    expect(find.text('Did you get it?'), findsOneWidget);

    await tester.tap(find.text('Got some'));
    await settle(tester);
    await typeDigits(tester, '1000');
    expect(find.text('₹2,000 will still be left'), findsOneWidget);
    await tester.tap(find.text('Save ₹1,000'));
    await settle(tester);
    expect(find.text('Choose how you received it'), findsOneWidget); // payment is required
    await tester.tap(find.text('Cash').last);
    await tester.tap(find.text('Save ₹1,000'));
    await settle(tester);

    expect(find.text('Udhar due today'), findsNothing);
    expect(await debts().remaining(id), 200000);
    await closeApp(tester);
  });

  testWidgets('Premium: Got full settles the udhar', (tester) async {
    final id = await dueUdhar();
    await openUnlockedHome(tester, h);
    await tester.tap(find.text('Got full ₹3,000'));
    await settle(tester);
    await tester.tap(find.text('Online'));
    await settle(tester);
    await tester.tap(find.text('Save ₹3,000'));
    await settle(tester);
    expect((await debts().byId(id))!.status, 'settled');
    expect(await debts().dueToAsk(Ist.today()), isEmpty);
    await closeApp(tester);
  });

  testWidgets('Premium: Not yet asks again tomorrow, not today', (tester) async {
    await dueUdhar();
    await openUnlockedHome(tester, h);
    await tester.tap(find.text('Not yet'));
    await settle(tester);
    expect(find.text('Udhar due today'), findsNothing);
    expect(await debts().dueToAsk(Ist.today()), isEmpty);
    expect(await debts().dueToAsk(Ist.today().addDays(1)), hasLength(1));
    await closeApp(tester);
  });

  testWidgets('Free: no due popup even when a due date exists', (tester) async {
    await dueUdhar();
    await PlanRepository(h.db).setPremiumForDev(false);
    await openUnlockedHome(tester, h);
    expect(find.text('Udhar due today'), findsNothing);
    await closeApp(tester);
  });
}
