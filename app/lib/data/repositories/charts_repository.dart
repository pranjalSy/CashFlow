import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/dates.dart';
import '../local/database.dart';
import '../providers.dart';

/// One slice of the spending donut: a category (null id = no category) or the udhar slice.
class SpendSlice {
  const SpendSlice({required this.categoryId, required this.amount, this.isUdhar = false});

  final String? categoryId;
  final int amount;
  final bool isUdhar;
}

/// Income and expense of one India month (Trends, FR-C1).
class MonthTotals {
  const MonthTotals({required this.year, required this.month, required this.income, required this.expense});

  final int year;
  final int month;
  final int income;
  final int expense;

  int get saved => income - expense;
}

/// Charts numbers as SQL aggregates (FR-C1, TRD 7). Udhar is never an expense; with
/// "Include udhar" on, money lent in the month is shown as its own slice.
class ChartsRepository {
  ChartsRepository(this.db, this.userId);

  final AppDatabase db;
  final String userId;

  /// Expense by category in an India month, biggest first.
  Future<List<SpendSlice>> spending(int year, int month, {bool includeUdhar = false}) async {
    final (start, end) = Ist.monthRange(year, month);
    final rows = await db.customSelect(
      'SELECT category_id, SUM(amount) AS total FROM transactions '
      "WHERE user_id = ?1 AND deleted_at IS NULL AND kind = 'expense' AND occurred_at >= ?2 AND occurred_at < ?3 "
      'GROUP BY category_id ORDER BY total DESC',
      variables: [Variable<String>(userId), Variable<DateTime>(start), Variable<DateTime>(end)],
      readsFrom: {db.transactions},
    ).get();
    final slices = [for (final r in rows) SpendSlice(categoryId: r.readNullable<String>('category_id'), amount: r.read<int>('total'))];
    if (includeUdhar) {
      final lent = await db.customSelect(
        "SELECT COALESCE(SUM(amount), 0) AS total FROM debts WHERE user_id = ?1 AND deleted_at IS NULL AND direction = 'lent' "
        'AND occurred_at >= ?2 AND occurred_at < ?3',
        variables: [Variable<String>(userId), Variable<DateTime>(start), Variable<DateTime>(end)],
        readsFrom: {db.debts},
      ).getSingle();
      final total = lent.read<int>('total');
      if (total > 0) slices.add(SpendSlice(categoryId: null, amount: total, isUdhar: true));
      slices.sort((a, b) => b.amount.compareTo(a.amount));
    }
    return slices;
  }

  /// Income and expense of one India month.
  Future<MonthTotals> totals(int year, int month) async {
    final (start, end) = Ist.monthRange(year, month);
    final r = await db.customSelect(
      "SELECT COALESCE(SUM(CASE WHEN kind = 'income' THEN amount END), 0) AS income, "
      "COALESCE(SUM(CASE WHEN kind = 'expense' THEN amount END), 0) AS expense FROM transactions "
      'WHERE user_id = ?1 AND deleted_at IS NULL AND occurred_at >= ?2 AND occurred_at < ?3',
      variables: [Variable<String>(userId), Variable<DateTime>(start), Variable<DateTime>(end)],
      readsFrom: {db.transactions},
    ).getSingle();
    return MonthTotals(year: year, month: month, income: r.read<int>('income'), expense: r.read<int>('expense'));
  }

  /// The 6 months ending with [year]/[month], oldest first.
  Future<List<MonthTotals>> trend(int year, int month) async {
    final end = LocalDate(year, month, 1);
    return [for (var i = 5; i >= 0; i--) await totals(end.addMonths(-i).year, end.addMonths(-i).month)];
  }

  /// Expense of one category (or all expenses when [categoryId] is null) in an India month.
  Future<int> spent(int year, int month, {String? categoryId}) async {
    final (start, end) = Ist.monthRange(year, month);
    final r = await db.customSelect(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM transactions '
      "WHERE user_id = ?1 AND deleted_at IS NULL AND kind = 'expense' AND occurred_at >= ?2 AND occurred_at < ?3 "
      '${categoryId == null ? '' : 'AND category_id = ?4'}',
      variables: [Variable<String>(userId), Variable<DateTime>(start), Variable<DateTime>(end), if (categoryId != null) Variable<String>(categoryId)],
      readsFrom: {db.transactions},
    ).getSingle();
    return r.read<int>('total');
  }

  /// Average monthly expense over the 3 months before [year]/[month] (limit suggestion, FR-BG4).
  Future<int> averageOfLast3(int year, int month, {String? categoryId}) async {
    final m = LocalDate(year, month, 1);
    var sum = 0;
    for (var i = 1; i <= 3; i++) {
      final d = m.addMonths(-i);
      sum += await spent(d.year, d.month, categoryId: categoryId);
    }
    return (sum / 3).round();
  }
}

final chartsRepositoryProvider = Provider<ChartsRepository>((ref) => ChartsRepository(ref.watch(databaseProvider), ref.watch(userIdProvider)));
