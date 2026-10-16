import 'package:cashflow/core/utils/dates.dart';
import 'package:cashflow/data/repositories/bill_repository.dart';
import 'package:cashflow/data/repositories/local_writer.dart';
import 'package:cashflow/data/repositories/plan_repository.dart';
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

  BillRepository bills() => BillRepository(LocalWriter(h.db, userId: Harness.userId));

  testWidgets('Premium: add a Torrent Power bill from the + menu; the next dates are previewed (FR-B1, B6)', (tester) async {
    await PlanRepository(h.db).setPremiumForDev(true);
    await openUnlockedHome(tester, h);
    await tester.tap(find.bySemanticsLabel('EMI'));
    await settle(tester);
    await tester.tap(find.text('Bills'));
    await settle(tester);
    expect(find.text('No bills yet'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Add'));
    await settle(tester);
    await tester.tap(find.text('Add bill').last);
    await settle(tester);
    expect(find.text('Which bill?'), findsOneWidget);
    await tester.tap(find.text('Torrent Power'));
    await settle(tester);
    expect(find.text('Torrent Power'), findsOneWidget); // name filled in
    await tester.tap(find.text('Save bill'));
    await settle(tester);
    expect(find.text('Choose the next due date'), findsWidgets); // required, nothing saved
    expect(await h.db.select(h.db.bills).get(), isEmpty);

    await tester.tap(find.text('Choose the next due date').first);
    await settle(tester);
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(find.textContaining('Then '), findsOneWidget);
    await tester.tap(find.text('Save bill'));
    await settle(tester);

    final bill = (await h.db.select(h.db.bills).get()).single;
    expect(bill.name, 'Torrent Power');
    expect(bill.everyMonths, 2);
    expect(bill.billType, 'electricity');
    expect(find.text('Electricity'), findsOneWidget); // on the list
    await closeApp(tester);
  });

  testWidgets('Premium: due popup on Home open; Yes, paid with the usual-amount chip adds a Bills expense (FR-B2, B4)', (tester) async {
    await PlanRepository(h.db).setPremiumForDev(true);
    await bills().add(BillDraft(type: 'electricity', name: 'Torrent Power', everyMonths: 2, nextDue: Ist.today(), usualAmount: 150000));
    await openUnlockedHome(tester, h);
    expect(find.text('Bill due today'), findsOneWidget);
    expect(find.text('Did you pay this bill?'), findsOneWidget);
    await tester.tap(find.text('Yes, paid'));
    await settle(tester);
    expect(find.text('How much was it?'), findsOneWidget);
    expect(find.text('₹1,500'), findsOneWidget); // usual amount chip, chosen
    await tester.tap(find.text('Cash').last);
    await tester.tap(find.text('Save ₹1,500'));
    await settle(tester);
    final txn = (await h.db.select(h.db.transactions).get()).single;
    expect(txn.amount, 150000);
    expect(txn.source, 'bill');
    final bill = (await h.db.select(h.db.bills).get()).single;
    expect(bill.nextDueDate, Ist.today().addMonths(2).toIso());
    await closeApp(tester);
  });

  testWidgets('Premium: Not yet asks again tomorrow', (tester) async {
    await PlanRepository(h.db).setPremiumForDev(true);
    await bills().add(BillDraft(type: 'internet', name: 'JioFiber', everyMonths: 1, nextDue: Ist.today()));
    await openUnlockedHome(tester, h);
    await tester.tap(find.text('Not yet'));
    await settle(tester);
    expect(find.text('Did you pay this bill?'), findsNothing);
    expect(await bills().dueToAsk(Ist.today()), isEmpty);
    expect(await bills().dueToAsk(Ist.today().addDays(1)), hasLength(1));
    await closeApp(tester);
  });
}
