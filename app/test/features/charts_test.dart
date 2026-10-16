import 'package:cashflow/data/repositories/category_repository.dart';
import 'package:cashflow/data/repositories/entry_repository.dart';
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
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
  }

  Future<void> seedFood(int rupees) async {
    final w = LocalWriter(h.db, userId: Harness.userId);
    final food = await CategoryRepository(w).idForKey('expense', 'catFood');
    await EntryRepository(w).add(EntryDraft(kind: 'expense', amount: rupees * 100, paymentMode: 'cash', occurredAt: DateTime.now(), categoryId: food));
  }

  testWidgets('Free: Charts shows the locked card', (tester) async {
    await openUnlockedHome(tester, h);
    await tester.tap(find.bySemanticsLabel('Charts'));
    await settle(tester);
    expect(find.text('See where your money goes'), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('Premium: Spending shows the month total and the category; Trends shows 6 months (FR-C1)', (tester) async {
    await PlanRepository(h.db).setPremiumForDev(true);
    await seedFood(6200);
    await openUnlockedHome(tester, h);
    await tester.tap(find.bySemanticsLabel('Charts'));
    await settle(tester);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('₹6,200'), findsWidgets); // donut centre + row
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Set a monthly budget'), findsOneWidget);
    await tester.tap(find.text('Trends'));
    await settle(tester);
    expect(find.text('Last 6 months'), findsOneWidget);
    expect(find.text('Avg expense'), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('Premium: set a monthly budget from the Charts card; the ring and colour follow the rule (FR-BG1, BG3, BG4)', (tester) async {
    await PlanRepository(h.db).setPremiumForDev(true);
    await seedFood(2850);
    await openUnlockedHome(tester, h);
    await tester.tap(find.bySemanticsLabel('Charts'));
    await settle(tester);
    await tester.tap(find.text('Set a monthly budget'));
    await settle(tester);
    await tester.tap(find.text('Set a monthly budget'));
    await settle(tester);
    expect(find.text('Monthly budget'), findsOneWidget);
    await tester.tap(find.text('Save limit'));
    await settle(tester);
    expect(find.text('Enter an amount'), findsOneWidget); // Save is never disabled; it says what is missing
    await typeDigits(tester, '3500');
    await tester.tap(find.text('Save limit'));
    await settle(tester);
    final b = (await h.db.select(h.db.budgets).get()).single;
    expect(b.monthlyLimit, 350000);
    expect(find.text('81%'), findsOneWidget); // 2,850 of 3,500
    await closeApp(tester);
  });
}
