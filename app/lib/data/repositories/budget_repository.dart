import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/database.dart';
import '../providers.dart';
import 'local_writer.dart';

/// Budget colour band (FR-BG3): under 80% green, 80–99% orange, 100%+ red.
enum BudgetBand { ok, near, over }

BudgetBand budgetBand(int spent, int limit) {
  if (limit <= 0) return BudgetBand.ok;
  final pct = spent * 100 / limit;
  if (pct >= 100) return BudgetBand.over;
  if (pct >= 80) return BudgetBand.near;
  return BudgetBand.ok;
}

/// Round-number suggestions around an average (FR-BG4): the average rounded to ₹100, plus the
/// ₹1,000 steps just below and above it. Paise.
List<int> limitSuggestions(int average) {
  final out = <int>{};
  if (average > 0) out.add((average / 10000).round() * 10000);
  final k = (average / 100000).floor();
  if (k > 0) out.add(k * 100000);
  out.add((k + 1) * 100000);
  return out.where((v) => v > 0).toList()..sort();
}

/// Monthly budget and category limits (FR-BG1–BG5). The limit repeats every month. Premium.
class BudgetRepository {
  BudgetRepository(this._w);

  final LocalWriter _w;
  AppDatabase get _db => _w.db;

  Stream<Budget?> watchBudget() =>
      (_db.select(_db.budgets)..where((b) => b.userId.equals(_w.userId) & b.deletedAt.isNull())..limit(1)).watchSingleOrNull();

  Stream<List<BudgetCategoryLimit>> watchLimits() => (_db.select(_db.budgetCategoryLimits)
        ..where((b) => b.userId.equals(_w.userId) & b.deletedAt.isNull())
        ..orderBy([(b) => OrderingTerm.asc(b.createdAt)]))
      .watch();

  /// Sets the overall monthly limit (one row per user).
  Future<void> setMonthly(int limit, {required bool alert}) => _w.action((batch) async {
        final now = _w.now();
        final existing = await (_db.select(_db.budgets)..where((b) => b.userId.equals(_w.userId) & b.deletedAt.isNull())).getSingleOrNull();
        if (existing == null) {
          final id = _w.newId();
          await _db.into(_db.budgets).insert(BudgetsCompanion.insert(
                id: id,
                userId: _w.userId,
                createdAt: now,
                updatedAt: now,
                monthlyLimit: limit,
                alertEnabled: Value(alert),
              ));
          await _w.queue('budgets', id, batch);
        } else {
          await (_db.update(_db.budgets)..where((b) => b.id.equals(existing.id)))
              .write(BudgetsCompanion(monthlyLimit: Value(limit), alertEnabled: Value(alert), updatedAt: Value(now), isSynced: const Value(false)));
          await _w.queue('budgets', existing.id, batch);
        }
      });

  Future<void> removeMonthly() => _w.action((batch) async {
        final now = _w.now();
        final rows = await (_db.select(_db.budgets)..where((b) => b.userId.equals(_w.userId) & b.deletedAt.isNull())).get();
        for (final b in rows) {
          await (_db.update(_db.budgets)..where((x) => x.id.equals(b.id)))
              .write(BudgetsCompanion(deletedAt: Value(now), updatedAt: Value(now), isSynced: const Value(false)));
          await _w.queue('budgets', b.id, batch, op: 'delete');
        }
      });

  /// Sets a category limit (one per category).
  Future<void> setCategory(String categoryId, int limit, {required bool alert}) => _w.action((batch) async {
        final now = _w.now();
        final existing = await (_db.select(_db.budgetCategoryLimits)
              ..where((b) => b.userId.equals(_w.userId) & b.deletedAt.isNull() & b.categoryId.equals(categoryId)))
            .getSingleOrNull();
        if (existing == null) {
          final id = _w.newId();
          await _db.into(_db.budgetCategoryLimits).insert(BudgetCategoryLimitsCompanion.insert(
                id: id,
                userId: _w.userId,
                createdAt: now,
                updatedAt: now,
                categoryId: categoryId,
                limitAmount: limit,
                alertEnabled: Value(alert),
              ));
          await _w.queue('budget_category_limits', id, batch);
        } else {
          await (_db.update(_db.budgetCategoryLimits)..where((b) => b.id.equals(existing.id)))
              .write(BudgetCategoryLimitsCompanion(limitAmount: Value(limit), alertEnabled: Value(alert), updatedAt: Value(now), isSynced: const Value(false)));
          await _w.queue('budget_category_limits', existing.id, batch);
        }
      });

  Future<void> removeCategory(String categoryId) => _w.action((batch) async {
        final now = _w.now();
        final rows = await (_db.select(_db.budgetCategoryLimits)
              ..where((b) => b.userId.equals(_w.userId) & b.deletedAt.isNull() & b.categoryId.equals(categoryId)))
            .get();
        for (final b in rows) {
          await (_db.update(_db.budgetCategoryLimits)..where((x) => x.id.equals(b.id)))
              .write(BudgetCategoryLimitsCompanion(deletedAt: Value(now), updatedAt: Value(now), isSynced: const Value(false)));
          await _w.queue('budget_category_limits', b.id, batch, op: 'delete');
        }
      });
}

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) => BudgetRepository(ref.watch(localWriterProvider)));
