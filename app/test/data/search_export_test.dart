import 'dart:convert';

import 'package:cashflow/core/utils/dates.dart';
import 'package:cashflow/data/local/database.dart';
import 'package:cashflow/data/repositories/category_repository.dart';
import 'package:cashflow/data/repositories/debt_repository.dart';
import 'package:cashflow/data/repositories/emi_repository.dart';
import 'package:cashflow/data/repositories/entry_repository.dart';
import 'package:cashflow/data/repositories/export_repository.dart';
import 'package:cashflow/data/repositories/local_writer.dart';
import 'package:cashflow/data/repositories/people_repository.dart';
import 'package:cashflow/data/repositories/search_repository.dart';
import 'package:cashflow/features/export/export_builder.dart';
import 'package:cashflow/l10n/app_localizations.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late LocalWriter w;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    w = LocalWriter(db, userId: 'u1', clock: () => DateTime.utc(2026, 10, 14, 6));
  });
  tearDown(() => db.close());

  Future<String> seed() async {
    final food = (await CategoryRepository(w).idForKey('expense', 'catFood'))!;
    final entries = EntryRepository(w);
    await entries.add(EntryDraft(kind: 'expense', amount: 124000, paymentMode: 'online', onlineMethod: 'upi', occurredAt: DateTime.utc(2026, 10, 12), categoryId: food, title: 'Dinner with Rahul'));
    await entries.add(EntryDraft(kind: 'expense', amount: 60000, paymentMode: 'cash', occurredAt: DateTime.utc(2026, 9, 20), categoryId: food, title: 'Movie', note: 'with Rahul'));
    await entries.add(EntryDraft(kind: 'income', amount: 4500000, paymentMode: 'online', onlineMethod: 'bank', occurredAt: DateTime.utc(2026, 10, 1), title: 'Salary'));
    final rahul = await PeopleRepository(w).findOrCreate(name: 'Rahul Sharma', phone: '9876543210');
    final debts = DebtRepository(w);
    final id = await debts.add(personId: rahul.id, direction: 'lent', amount: 500000, occurredAt: DateTime.utc(2026, 10, 1), paymentMode: 'cash', premium: false);
    await debts.recordRepayment(debtId: id, amount: 200000, occurredAt: DateTime.utc(2026, 10, 8), paymentMode: 'online', onlineMethod: 'upi');
    return food;
  }

  group('search (FR-C3)', () {
    test('a name finds the person and every entry about them, newest first', () async {
      await seed();
      final s = SearchRepository(db, 'u1');
      final people = await s.people('rahul');
      expect(people.single.name, 'Rahul Sharma');
      final hits = await s.entries('rahul', personIds: {people.single.id});
      expect(hits.map((h) => h.kind), [SearchKind.expense, SearchKind.repayment, SearchKind.lent, SearchKind.expense]);
      expect(hits.first.title, 'Dinner with Rahul');
      expect(hits.last.note, 'with Rahul');
    });

    test('an amount like 2000 finds ₹2,000; a category or payment name found by the caller works too', () async {
      final food = await seed();
      final s = SearchRepository(db, 'u1');
      expect((await s.entries('2000')).single.kind, SearchKind.repayment);
      expect((await s.entries('2,000')).single.amount, 200000);
      expect((await s.entries('xyz', categoryIds: {food})).length, 2);
      expect((await s.entries('xyz', modes: {'upi'})).length, 2); // dinner + repayment
      expect(await s.entries('zomato'), isEmpty);
    });

    test('a phone number finds the person', () async {
      await seed();
      expect((await SearchRepository(db, 'u1').people('98765')).single.name, 'Rahul Sharma');
    });

    test('recent: last 4, newest first, no repeats', () async {
      final s = SearchRepository(db, 'u1');
      for (final q in ['rahul', 'food', '2000', 'upi', 'Rahul', 'movie']) {
        await s.remember(q);
      }
      expect(await s.recent(), ['movie', 'Rahul', 'upi', '2000']);
      await s.forget('upi');
      expect(await s.recent(), ['movie', 'Rahul', '2000']);
    });
  });

  group('export (FR-C2)', () {
    test('rows for a range in three groups; EMI and bill payments are their own group', () async {
      await seed();
      final emi = EmiRepository(w);
      final id = await emi.add(const EmiDraft(name: 'Bike', icon: 'bike', loanAmount: 9000000, rateBp: 1200, months: 12, emiAmount: 799639, firstDue: LocalDate(2026, 10, 5)));
      final first = (await emi.watchOne(id).first)!.nextDue!;
      await emi.markPaid(first.id, paidAt: DateTime.utc(2026, 10, 5), paymentMode: 'cash');
      final rows = await ExportRepository(db, 'u1').rows(const LocalDate(2026, 10, 1), const LocalDate(2026, 10, 31));
      int n(ExportGroup g) => rows.where((r) => r.group == g).length;
      expect(n(ExportGroup.incomeExpense), 2); // salary + dinner (September movie is outside)
      expect(n(ExportGroup.udhar), 2); // lent + repayment
      expect(n(ExportGroup.emiBills), 1);
      expect(rows.first.at.isBefore(rows.last.at), isTrue);
    });

    test('CSV: UTF-8 with BOM, a header in the user language, signed plain amounts', () async {
      await seed();
      final rows = await ExportRepository(db, 'u1').rows(const LocalDate(2026, 10, 1), const LocalDate(2026, 10, 31));
      final l = lookupAppLocalizations(const Locale('hi'));
      final cats = {for (final c in await db.select(db.categories).get()) c.id: c};
      final people = {for (final p in await db.select(db.people).get()) p.id: p};
      final csv = buildCsv(rows, ExportNames(l: l, locale: const Locale('hi'), categories: cats, people: people));
      expect(csv.take(3), [0xEF, 0xBB, 0xBF]);
      final text = utf8.decode(csv.skip(3).toList());
      final lines = text.trim().split('\n');
      expect(lines.first, contains('"तारीख"'));
      expect(lines.length, 1 + rows.length);
      expect(text, contains('-1240.00'));
      expect(text, contains('45000.00'));
      expect(text, contains('"Rahul Sharma"'));
    });
  });
}
