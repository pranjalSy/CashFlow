import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/database.dart';
import '../providers.dart';
import 'local_writer.dart';

/// A default category: localized name key, icon key, colour (FR-T3, F5).
class DefaultCategory {
  const DefaultCategory(this.key, this.icon, this.color);

  final String key;
  final String icon;
  final int color;
}

const defaultExpenseCategories = [
  DefaultCategory('catFood', 'food', 0xFFC2410C),
  DefaultCategory('catGroceries', 'groceries', 0xFF15803D),
  DefaultCategory('catTravel', 'travel', 0xFF2B4BC7),
  DefaultCategory('catFuel', 'fuel', 0xFFB45309),
  DefaultCategory('catShopping', 'shopping', 0xFFA3165A),
  DefaultCategory('catBills', 'bills', 0xFFCA8A04),
  DefaultCategory('catRent', 'rent', 0xFF5B3FC4),
  DefaultCategory('catHealth', 'health', 0xFFC62828),
  DefaultCategory('catEducation', 'education', 0xFF0E7490),
  DefaultCategory('catFun', 'fun', 0xFF7C3AED),
  DefaultCategory('catRecharge', 'recharge', 0xFF0E7C86),
  DefaultCategory('catGifts', 'gifts', 0xFFBE185D),
  DefaultCategory('catPersonal', 'personal', 0xFF6D28D9),
  DefaultCategory('catEmi', 'emi', 0xFF3B5BDB),
  DefaultCategory('catOthers', 'others', 0xFF5B6B7F),
];

const defaultIncomeCategories = [
  DefaultCategory('catSalary', 'salary', 0xFF15803D),
  DefaultCategory('catBusiness', 'business', 0xFF2B4BC7),
  DefaultCategory('catFreelance', 'freelance', 0xFF0E7490),
  DefaultCategory('catInterest', 'interest', 0xFFB45309),
  DefaultCategory('catGift', 'gifts', 0xFFBE185D),
  DefaultCategory('catRefund', 'refund', 0xFF0E7C86),
  DefaultCategory('catOthers', 'others', 0xFF5B6B7F),
];

/// Colours for new user categories, cycled.
const _userColors = [0xFF3B5BDB, 0xFF15803D, 0xFFC2410C, 0xFFA3165A, 0xFF0E7490, 0xFF7C3AED];

class CategoryRepository {
  CategoryRepository(this._w);

  final LocalWriter _w;
  AppDatabase get _db => _w.db;

  SimpleSelectStatement<$CategoriesTable, Category> _mine() =>
      _db.select(_db.categories)..where((c) => c.userId.equals(_w.userId) & c.deletedAt.isNull());

  /// Adds the default categories once (in the user's language through their name keys).
  Future<void> ensureDefaults() async {
    final count = await (_db.selectOnly(_db.categories)
          ..addColumns([_db.categories.id.count()])
          ..where(_db.categories.userId.equals(_w.userId)))
        .map((r) => r.read(_db.categories.id.count()) ?? 0)
        .getSingle();
    if (count > 0) return;
    await _w.action((batch) async {
      final now = _w.now();
      Future<void> add(String kind, List<DefaultCategory> list) async {
        for (final (i, d) in list.indexed) {
          final id = _w.newId();
          await _db.into(_db.categories).insert(CategoriesCompanion.insert(
                id: id,
                userId: _w.userId,
                createdAt: now,
                updatedAt: now,
                kind: kind,
                name: d.key,
                nameKey: Value(d.key),
                icon: d.icon,
                color: d.color,
                isDefault: const Value(true),
                sortOrder: Value(i),
              ));
          await _w.queue('categories', id, batch);
        }
      }

      await add('expense', defaultExpenseCategories);
      await add('income', defaultIncomeCategories);
    });
  }

  /// Id of a default category by its name key (for example `catEmi`, `catBills`), adding the defaults first if needed.
  Future<String?> idForKey(String kind, String nameKey) async {
    Future<Category?> find() => (_db.select(_db.categories)
          ..where((c) => c.userId.equals(_w.userId) & c.deletedAt.isNull() & c.kind.equals(kind) & c.nameKey.equals(nameKey))
          ..limit(1))
        .getSingleOrNull();
    var c = await find();
    if (c == null) {
      await ensureDefaults();
      c = await find();
    }
    return c?.id;
  }

  Stream<List<Category>> watchKind(String kind) =>
      (_mine()..where((c) => c.kind.equals(kind))..orderBy([(c) => OrderingTerm.asc(c.sortOrder), (c) => OrderingTerm.asc(c.name)])).watch();

  Stream<Map<String, Category>> watchAll() => _mine().watch().map((list) => {for (final c in list) c.id: c});

  /// Up to 4 most recently used categories of a kind.
  Future<List<Category>> recent(String kind) => (_mine()
        ..where((c) => c.kind.equals(kind) & c.lastUsedAt.isNotNull())
        ..orderBy([(c) => OrderingTerm.desc(c.lastUsedAt)])
        ..limit(4))
      .get();

  /// A category typed once is saved automatically and found next time (FR-T3).
  Future<Category> create(String kind, String name) async {
    final trimmed = name.trim();
    final existing = await (_mine()..where((c) => c.kind.equals(kind) & c.name.lower().equals(trimmed.toLowerCase()))).getSingleOrNull();
    if (existing != null) return existing;
    final count = (await (_mine()..where((c) => c.kind.equals(kind))).get()).length;
    return _w.action((batch) async {
      final now = _w.now();
      final id = _w.newId();
      await _db.into(_db.categories).insert(CategoriesCompanion.insert(
            id: id,
            userId: _w.userId,
            createdAt: now,
            updatedAt: now,
            kind: kind,
            name: trimmed,
            icon: 'custom',
            color: _userColors[count % _userColors.length],
            sortOrder: Value(100 + count),
          ));
      await _w.queue('categories', id, batch);
      return (await (_db.select(_db.categories)..where((c) => c.id.equals(id))).getSingle());
    });
  }

  /// Remembers when a category was used (local only, for the "Recent" row).
  Future<void> touch(String id) =>
      (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(CategoriesCompanion(lastUsedAt: Value(_w.now())));
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) => CategoryRepository(ref.watch(localWriterProvider)));

final categoriesByIdProvider = StreamProvider<Map<String, Category>>((ref) => ref.watch(categoryRepositoryProvider).watchAll());
