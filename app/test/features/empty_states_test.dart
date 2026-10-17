import 'package:cashflow/data/local/database.dart';
import 'package:cashflow/data/repositories/plan_repository.dart';
import 'package:cashflow/shared/widgets/states.dart';
import 'package:drift/drift.dart' show Value;
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

  testWidgets('Home: "Tap + to add" only the first time; it does not come back after a delete (FR-U8)', (tester) async {
    await openUnlockedHome(tester, h);
    expect(find.text('No entries yet'), findsOneWidget);
    expect(find.text('Tap + to add'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Add'));
    await settle(tester);
    await tester.tap(find.text('Expense').last);
    await settle(tester);
    await typeDigits(tester, '80');
    await tester.tap(find.text('Done'));
    await settle(tester);
    await tester.tap(find.text('Cash'));
    await tester.tap(find.text('Save expense'));
    await settle(tester);
    expect(find.text('Tap + to add'), findsNothing);

    await h.db.update(h.db.transactions).write(TransactionsCompanion(deletedAt: Value(DateTime.utc(2026, 10, 17))));
    await settle(tester);
    expect(find.text('No entries yet'), findsOneWidget);
    expect(find.text('Tap + to add'), findsNothing);
    await closeApp(tester);
  });

  testWidgets('EMI & Bills empty: one button each opens the add form (screen 28)', (tester) async {
    await PlanRepository(h.db).setPremiumForDev(true);
    await openUnlockedHome(tester, h);
    await tester.tap(find.bySemanticsLabel('EMI'));
    await settle(tester);
    expect(find.text('No EMIs yet'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(EmptyState), matching: find.text('Add EMI')));
    await settle(tester);
    expect(find.text('Loan amount'), findsOneWidget);
    await closeApp(tester);
  });
}
