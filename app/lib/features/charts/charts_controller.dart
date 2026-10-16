import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/dates.dart';
import '../../data/providers.dart';
import '../../data/repositories/charts_repository.dart';

/// Month shown on Charts and Budget (shared, starts at the current India month).
class ChartsMonth extends Notifier<({int year, int month})> {
  @override
  ({int year, int month}) build() {
    final t = Ist.today();
    return (year: t.year, month: t.month);
  }

  void shift(int months) {
    final d = LocalDate(state.year, state.month, 1).addMonths(months);
    state = (year: d.year, month: d.month);
  }

  void set(int year, int month) => state = (year: year, month: month);
}

final chartsMonthProvider = NotifierProvider<ChartsMonth, ({int year, int month})>(ChartsMonth.new);

/// Ticks whenever money tables change, so chart numbers refresh after a new entry.
final _moneyChanges = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  var n = 0;
  return db
      .tableUpdates(TableUpdateQuery.onAllTables([db.transactions, db.debts, db.categories, db.budgets, db.budgetCategoryLimits]))
      .map((_) => ++n);
});

class SpendingData {
  const SpendingData({required this.slices, required this.total, required this.previousTotal});

  final List<SpendSlice> slices;
  final int total;
  final int previousTotal;
}

final spendingProvider = FutureProvider.family<SpendingData, ({int year, int month, bool udhar})>((ref, k) async {
  ref.watch(_moneyChanges);
  final repo = ref.watch(chartsRepositoryProvider);
  final slices = await repo.spending(k.year, k.month, includeUdhar: k.udhar);
  final prev = LocalDate(k.year, k.month, 1).addMonths(-1);
  return SpendingData(
    slices: slices,
    total: slices.fold(0, (a, s) => a + s.amount),
    previousTotal: await repo.spent(prev.year, prev.month),
  );
});

final trendProvider = FutureProvider.family<List<MonthTotals>, ({int year, int month})>((ref, k) async {
  ref.watch(_moneyChanges);
  return ref.watch(chartsRepositoryProvider).trend(k.year, k.month);
});

/// Spent this month overall and per category id (Budget, FR-BG1), with each category's 3-month average.
class BudgetSpend {
  const BudgetSpend({required this.overall, required this.byCategory, required this.overallAverage});

  final int overall;
  final Map<String, int> byCategory;
  final int overallAverage;
}

final budgetSpendProvider = FutureProvider.family<BudgetSpend, ({int year, int month})>((ref, k) async {
  ref.watch(_moneyChanges);
  final repo = ref.watch(chartsRepositoryProvider);
  final slices = await repo.spending(k.year, k.month);
  return BudgetSpend(
    overall: slices.fold(0, (a, s) => a + s.amount),
    byCategory: {for (final s in slices) ?s.categoryId: s.amount},
    overallAverage: await repo.averageOfLast3(k.year, k.month),
  );
});

/// 3-month average spend of one category (limit sheet suggestion).
final chartsAverageProvider = FutureProvider.family<int, ({String categoryId, int year, int month})>((ref, k) {
  return ref.watch(chartsRepositoryProvider).averageOfLast3(k.year, k.month, categoryId: k.categoryId);
});
