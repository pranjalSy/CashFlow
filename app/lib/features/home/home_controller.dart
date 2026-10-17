import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/dates.dart';
import '../../data/providers.dart';
import '../../data/repositories/calculations.dart';
import '../../data/repositories/entry_repository.dart';

/// Month shown on Home; everything on the screen follows it (FR-O6).
final homeMonthProvider = NotifierProvider<HomeMonth, ({int year, int month})>(HomeMonth.new);

class HomeMonth extends Notifier<({int year, int month})> {
  @override
  ({int year, int month}) build() {
    final t = Ist.today();
    return (year: t.year, month: t.month);
  }

  void shift(int months) {
    final d = LocalDate(state.year, state.month, 1).addMonths(months);
    state = (year: d.year, month: d.month);
  }
}

enum HomeFilter { all, expense, income, udhar }

final homeFilterProvider = NotifierProvider<HomeFilterNotifier, HomeFilter>(HomeFilterNotifier.new);

class HomeFilterNotifier extends Notifier<HomeFilter> {
  @override
  HomeFilter build() => HomeFilter.all;

  void set(HomeFilter f) => state = f;
}

final calculationsProvider = Provider<Calculations>((ref) => Calculations(ref.watch(databaseProvider), ref.watch(userIdProvider)));

final homeSummaryProvider = StreamProvider<MonthSummary>((ref) {
  final m = ref.watch(homeMonthProvider);
  return ref.watch(calculationsProvider).watchMonth(m.year, m.month);
});

final homeEntriesProvider = StreamProvider<List<HomeEntry>>((ref) {
  final m = ref.watch(homeMonthProvider);
  return ref.watch(entryRepositoryProvider).watchMonth(m.year, m.month);
});

/// True once anything was ever added (deleted rows count too), so the "Tap + to add" hint
/// shows only the first time (FR-U8).
final everAddedProvider = StreamProvider<bool>((ref) {
  final db = ref.watch(databaseProvider);
  return db
      .customSelect('SELECT EXISTS(SELECT 1 FROM transactions) OR EXISTS(SELECT 1 FROM debts) AS any_row', readsFrom: {db.transactions, db.debts})
      .watchSingle()
      .map((r) => r.read<bool>('any_row'));
});
