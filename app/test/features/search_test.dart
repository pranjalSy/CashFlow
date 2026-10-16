import 'package:cashflow/data/repositories/entry_repository.dart';
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

  testWidgets('Free: the search button shows the Premium sheet', (tester) async {
    await openUnlockedHome(tester, h);
    await tester.tap(find.bySemanticsLabel('Search'));
    await settle(tester);
    expect(find.text('Search is Premium'), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('Premium: results as you type, people first; a filter with nothing offers "Search in All" (FR-C3)', (tester) async {
    await PlanRepository(h.db).setPremiumForDev(true);
    final w = LocalWriter(h.db, userId: Harness.userId);
    await EntryRepository(w).add(EntryDraft(kind: 'expense', amount: 124000, paymentMode: 'cash', occurredAt: DateTime.now(), title: 'Dinner with Rahul'));
    await PeopleRepository(w).findOrCreate(name: 'Rahul Sharma');
    await openUnlockedHome(tester, h);
    await tester.tap(find.bySemanticsLabel('Search'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'rahul');
    await tester.pump(const Duration(milliseconds: 300));
    await settle(tester);
    expect(find.text('People · 1'), findsOneWidget);
    expect(find.text('Entries · 1'), findsOneWidget);
    expect(find.textContaining('Dinner with', findRichText: true), findsOneWidget);
    await tester.tap(find.text('Income'));
    await settle(tester);
    expect(find.text('No results for “rahul”'), findsOneWidget);
    expect(find.text('Search in All'), findsOneWidget);
    await tester.tap(find.text('Search in All'));
    await settle(tester);
    expect(find.text('Entries · 1'), findsOneWidget);
    await closeApp(tester);
  });
}
