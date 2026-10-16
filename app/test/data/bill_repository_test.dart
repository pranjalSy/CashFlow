import 'package:cashflow/core/utils/dates.dart';
import 'package:cashflow/data/local/database.dart';
import 'package:cashflow/data/repositories/bill_repository.dart';
import 'package:cashflow/data/repositories/local_writer.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late BillRepository repo;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = BillRepository(LocalWriter(db, userId: 'u1', clock: () => DateTime.utc(2026, 11, 15, 6)));
  });
  tearDown(() => db.close());

  const torrent = BillDraft(type: 'electricity', name: 'Torrent Power', everyMonths: 2, nextDue: LocalDate(2026, 11, 15), usualAmount: 150000, reminderDays: [0, 3]);

  Future<void> pay(String id, int rupees) => repo.markPaid(id, amount: rupees * 100, paidAt: DateTime.utc(2026, 11, 15, 6), paymentMode: 'online', onlineMethod: 'upi');

  test('Yes, paid: payment + Bills expense, next due moves by the gap (15 Nov + 2 months = 15 Jan, FR-B4)', () async {
    final id = await repo.add(torrent);
    await pay(id, 1840);
    final bill = (await repo.byId(id))!;
    expect(bill.nextDueDate, '2027-01-15');
    final txn = (await db.select(db.transactions).get()).single;
    expect(txn.amount, 184000);
    expect(txn.kind, 'expense');
    expect(txn.source, 'bill');
    final cat = await (db.select(db.categories)..where((c) => c.id.equals(txn.categoryId!))).getSingle();
    expect(cat.nameKey, 'catBills');
    final p = (await db.select(db.billPayments).get()).single;
    expect(p.dueDate, '2026-11-15');
    expect(p.transactionId, txn.id);
  });

  test('suggestions: usual amount first time, then the last 3 bills newest first', () async {
    final id = await repo.add(torrent);
    expect((await repo.suggestions(id)).single.amount, 150000);
    for (final r in [1690, 1520, 1840, 1700]) {
      await pay(id, r);
    }
    final s = await repo.suggestions(id);
    expect(s.map((x) => x.amount), [170000, 184000, 152000]);
    expect(s.first.dueDate, const LocalDate(2027, 5, 15));
  });

  test('due popup: due on or before today; Not yet waits a day; paused bills never ask (FR-B2, FR-B3)', () async {
    final id = await repo.add(torrent);
    expect(await repo.dueToAsk(const LocalDate(2026, 11, 14)), isEmpty);
    expect(await repo.dueToAsk(const LocalDate(2026, 11, 15)), hasLength(1));
    await repo.askAgainTomorrow(id, const LocalDate(2026, 11, 15));
    expect(await repo.dueToAsk(const LocalDate(2026, 11, 15)), isEmpty);
    expect(await repo.dueToAsk(const LocalDate(2026, 11, 16)), hasLength(1));
    await repo.setPaused(id, true);
    expect(await repo.dueToAsk(const LocalDate(2026, 11, 20)), isEmpty);
  });

  test('summary for the month: paid ones + what is still due', () async {
    final a = await repo.add(torrent);
    await repo.add(const BillDraft(type: 'internet', name: 'JioFiber', everyMonths: 1, nextDue: LocalDate(2026, 11, 20), usualAmount: 79900));
    await repo.add(const BillDraft(type: 'insurance', name: 'Star Health', everyMonths: 12, nextDue: LocalDate(2027, 3, 12), usualAmount: 1250000));
    await pay(a, 1840);
    final s = await repo.watchSummary(const LocalDate(2026, 11, 15)).first;
    expect(s.paid, 1);
    expect(s.left, 1);
    expect(s.total, 184000 + 79900);
  });

  test('delete keeps expenses already added', () async {
    final id = await repo.add(torrent);
    await pay(id, 1840);
    await repo.delete(id);
    expect(await repo.watchOne(id).first, isNull);
    expect(await db.select(db.transactions).get(), hasLength(1));
  });
}
