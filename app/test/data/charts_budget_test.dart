import 'package:cashflow/data/local/database.dart';
import 'package:cashflow/data/repositories/budget_repository.dart';
import 'package:cashflow/data/repositories/category_repository.dart';
import 'package:cashflow/data/repositories/charts_repository.dart';
import 'package:cashflow/data/repositories/debt_repository.dart';
import 'package:cashflow/data/repositories/entry_repository.dart';
import 'package:cashflow/data/repositories/local_writer.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late LocalWriter w;
  late ChartsRepository charts;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    w = LocalWriter(db, userId: 'u1', clock: () => DateTime.utc(2026, 10, 14, 6));
    charts = ChartsRepository(db, 'u1');
  });
  tearDown(() => db.close());

  Future<String> cat(String key) async => (await CategoryRepository(w).idForKey('expense', key))!;

  Future<void> spend(int rupees, String? categoryId, DateTime at, {String kind = 'expense'}) => EntryRepository(w).add(EntryDraft(
        kind: kind,
        amount: rupees * 100,
        paymentMode: 'cash',
        occurredAt: at,
        categoryId: categoryId,
      ));

  test('spending by category for the India month, biggest first; udhar only when switched on (FR-C1)', () async {
    final food = await cat('catFood');
    final bills = await cat('catBills');
    await spend(6200, food, DateTime.utc(2026, 10, 3));
    await spend(2840, bills, DateTime.utc(2026, 10, 5));
    await spend(500, food, DateTime.utc(2026, 9, 30, 19)); // 1 Oct 00:30 IST → October
    await spend(999, food, DateTime.utc(2026, 9, 30, 18)); // 30 Sep 23:30 IST → September
    await spend(45000, null, DateTime.utc(2026, 10, 1), kind: 'income');
    await DebtRepository(w).add(personId: 'p', direction: 'lent', amount: 300000, occurredAt: DateTime.utc(2026, 10, 9), paymentMode: 'cash', premium: false);

    final s = await charts.spending(2026, 10);
    expect(s.map((x) => (x.categoryId, x.amount)), [(food, 670000), (bills, 284000)]);
    final withUdhar = await charts.spending(2026, 10, includeUdhar: true);
    expect(withUdhar.first.isUdhar, isFalse);
    expect(withUdhar.where((x) => x.isUdhar).single.amount, 300000);
    expect(await charts.spent(2026, 9), 99900);
  });

  test('6-month trend, oldest first, with saved = income − expense', () async {
    await spend(45000, null, DateTime.utc(2026, 10, 1), kind: 'income');
    await spend(28500, null, DateTime.utc(2026, 10, 2));
    await spend(40000, null, DateTime.utc(2026, 5, 2), kind: 'income');
    final t = await charts.trend(2026, 10);
    expect(t.map((m) => m.month), [5, 6, 7, 8, 9, 10]);
    expect(t.last.saved, 1650000);
    expect(t.first.income, 4000000);
  });

  test('3-month average for limit suggestions', () async {
    final food = await cat('catFood');
    await spend(4500, food, DateTime.utc(2026, 7, 5));
    await spend(4650, food, DateTime.utc(2026, 8, 5));
    await spend(4800, food, DateTime.utc(2026, 9, 5));
    expect(await charts.averageOfLast3(2026, 10, categoryId: food), 465000);
  });

  test('budget bands: under 80% ok, 80–99% near, 100%+ over (FR-BG3)', () {
    expect(budgetBand(2799900, 3500000), BudgetBand.ok);
    expect(budgetBand(2850000, 3500000), BudgetBand.near); // 81%
    expect(budgetBand(680000, 600000), BudgetBand.over); // 113%
  });

  test('limit suggestions: average rounded to ₹100 plus ₹1,000 steps around it', () {
    expect(limitSuggestions(465000), [400000, 470000, 500000]);
  });

  test('monthly budget and category limits: one each, update and remove', () async {
    final repo = BudgetRepository(w);
    await repo.setMonthly(3500000, alert: true);
    await repo.setMonthly(4000000, alert: false);
    final b = (await db.select(db.budgets).get()).single;
    expect(b.monthlyLimit, 4000000);
    expect(b.alertEnabled, isFalse);
    final food = await cat('catFood');
    await repo.setCategory(food, 500000, alert: true);
    await repo.setCategory(food, 600000, alert: true);
    expect((await (db.select(db.budgetCategoryLimits)..where((x) => x.deletedAt.isNull())).get()).single.limitAmount, 600000);
    await repo.removeCategory(food);
    await repo.removeMonthly();
    expect(await repo.watchLimits().first, isEmpty);
    expect(await repo.watchBudget().first, isNull);
  });
}
