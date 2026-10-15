import 'package:cashflow/data/local/database.dart';
import 'package:cashflow/data/repositories/category_repository.dart';
import 'package:cashflow/data/repositories/entry_repository.dart';
import 'package:cashflow/data/repositories/local_writer.dart';
import 'package:cashflow/data/repositories/people_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late LocalWriter w;
  final at = DateTime.utc(2026, 10, 13, 13, 10); // 13 Oct 18:40 IST

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    w = LocalWriter(db, userId: 'u1', clock: () => at);
  });
  tearDown(() => db.close());

  EntryDraft draft({String kind = 'expense', int amount = 245000, String mode = 'online', String? method = 'upi'}) =>
      EntryDraft(kind: kind, amount: amount, paymentMode: mode, onlineMethod: method, occurredAt: at, title: '  Groceries  ', note: '');

  test('add stores paise, trims title, blanks become null, queues upload', () async {
    final repo = EntryRepository(w);
    final id = await repo.add(draft());
    final t = (await repo.byId(id))!;
    expect(t.amount, 245000);
    expect(t.title, 'Groceries');
    expect(t.note, isNull);
    expect(t.onlineMethod, 'upi');
    expect((await db.select(db.syncOutbox).get()).single.rowId, id);
    expect(await repo.lastPayment('expense'), ('online', 'upi'));
  });

  test('cash entries drop the online method', () async {
    final repo = EntryRepository(w);
    final id = await repo.add(draft(mode: 'cash', method: 'upi'));
    expect((await repo.byId(id))!.onlineMethod, isNull);
    expect(await repo.lastPayment('expense'), ('cash', null));
  });

  test('update changes the row and queues it again', () async {
    final repo = EntryRepository(w);
    final id = await repo.add(draft());
    await repo.update(id, draft(amount: 300000, kind: 'income', mode: 'cash', method: null));
    final t = (await repo.byId(id))!;
    expect(t.amount, 300000);
    expect(t.kind, 'income');
    expect((await db.select(db.syncOutbox).get()).length, 2);
  });

  test('delete is soft with a 5 s undo window; undo restores and nothing uploads', () async {
    final repo = EntryRepository(w);
    final id = await repo.add(draft());
    final batch = await repo.delete(id);
    expect((await repo.byId(id))!.deletedAt, isNotNull);
    final del = (await db.select(db.syncOutbox).get()).last;
    expect(del.op, 'delete');
    expect(del.notBefore, at.add(const Duration(seconds: 5)));
    await repo.undoDelete(id, batch);
    expect((await repo.byId(id))!.deletedAt, isNull);
    expect((await db.select(db.syncOutbox).get()).where((o) => o.op == 'delete'), isEmpty);
  });

  test('Home list merges income, expense and udhar, newest first, without deleted', () async {
    final repo = EntryRepository(w);
    await repo.add(draft());
    await repo.add(EntryDraft(kind: 'income', amount: 4500000, paymentMode: 'online', onlineMethod: 'bank', occurredAt: at.subtract(const Duration(hours: 9))));
    final gone = await repo.add(draft(amount: 100));
    await repo.delete(gone);
    await db.into(db.debts).insert(DebtsCompanion.insert(
          id: 'd1', userId: 'u1', createdAt: at, updatedAt: at, personId: 'p1', direction: 'lent', amount: 500000,
          occurredAt: at.add(const Duration(hours: 1)), paymentMode: 'online',
        ));
    final list = await repo.watchMonth(2026, 10).first;
    expect(list.map((e) => e.kind), [EntryKind.lent, EntryKind.expense, EntryKind.income]);
    expect(list.first.personId, 'p1');
    expect(await repo.watchMonth(2026, 11).first, isEmpty);
  });

  group('categories', () {
    test('defaults are added once, with localized name keys', () async {
      final repo = CategoryRepository(w);
      await repo.ensureDefaults();
      await repo.ensureDefaults();
      final exp = await repo.watchKind('expense').first;
      final inc = await repo.watchKind('income').first;
      expect(exp.length, defaultExpenseCategories.length);
      expect(inc.length, defaultIncomeCategories.length);
      expect(exp.first.nameKey, 'catFood');
    });

    test('a typed category is saved once and reused (FR-T3)', () async {
      final repo = CategoryRepository(w);
      final a = await repo.create('expense', ' Gym ');
      final b = await repo.create('expense', 'gym');
      expect(a.id, b.id);
      expect(a.name, 'Gym');
      final other = await repo.create('income', 'Gym');
      expect(other.id, isNot(a.id));
    });

    test('recent shows the last used first, at most 4', () async {
      final repo = CategoryRepository(w);
      await repo.ensureDefaults();
      final exp = await repo.watchKind('expense').first;
      for (final c in exp.take(5)) {
        await repo.touch(c.id);
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }
      final recent = await repo.recent('expense');
      expect(recent.length, 4);
    });
  });

  test('Indian phone numbers normalize to E.164', () {
    expect(PeopleRepository.normalizePhone('98250 44321'), '+919825044321');
    expect(PeopleRepository.normalizePhone('+91-98250-44321'), '+919825044321');
    expect(PeopleRepository.normalizePhone('098250 44321'), '+919825044321');
    expect(PeopleRepository.normalizePhone('919825044321'), '+919825044321');
    expect(PeopleRepository.normalizePhone(''), isNull);
    expect(PeopleRepository.normalizePhone(null), isNull);
  });
}
