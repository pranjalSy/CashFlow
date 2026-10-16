import 'package:cashflow/core/utils/dates.dart';
import 'package:cashflow/data/local/database.dart';
import 'package:cashflow/data/repositories/emi_repository.dart';
import 'package:cashflow/data/repositories/local_writer.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late EmiRepository repo;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = EmiRepository(LocalWriter(db, userId: 'u1', clock: () => DateTime.utc(2026, 10, 14, 6)));
  });
  tearDown(() => db.close());

  const bike = EmiDraft(
    name: 'Bike loan',
    icon: 'bike',
    lender: 'HDFC',
    itemPrice: 11000000,
    downPayment: 2000000,
    loanAmount: 9000000,
    rateBp: 1200,
    months: 12,
    emiAmount: 799639,
    firstDue: LocalDate(2026, 7, 5),
  );

  Future<EmiWithInstallments> load(String id) async => (await repo.watchOne(id).first)!;

  Future<void> payNext(String id, {int times = 1}) async {
    for (var k = 0; k < times; k++) {
      final next = (await load(id)).nextDue!;
      await repo.markPaid(next.id, paidAt: DateTime.utc(2026, 10, 14, 6), paymentMode: 'online', onlineMethod: 'bank');
    }
  }

  test('add makes all 12 installments; last one ₹7,996.40; total interest ₹5,956.69 (FR-E4, PRD §8)', () async {
    final id = await repo.add(bike);
    final e = await load(id);
    expect(e.total, 12);
    expect(e.installments.first.amount, 799639);
    expect(e.installments.last.amount, 799640);
    expect(e.totalInterest, 595669);
    expect(e.installments[4].dueDate, '2026-11-05');
    expect(e.installments[4].interestPart, 61186); // ₹611.86 (screen 19)
    expect(e.lastDue, const LocalDate(2027, 6, 5));
    expect(await repo.watchRemaining(id).first, 9595669);
  });

  test('day 31 uses the last day of short months', () async {
    final id = await repo.add(const EmiDraft(name: 'Phone', icon: 'phone', loanAmount: 2939400, rateBp: 0, months: 6, emiAmount: 489900, firstDue: LocalDate(2026, 1, 31)));
    final dates = (await load(id)).installments.map((i) => i.dueDate).toList();
    expect(dates.take(4), ['2026-01-31', '2026-02-28', '2026-03-31', '2026-04-30']);
  });

  test('mark paid: installment paid + EMI expense in one action; 4 paid leaves ₹63,971.13 (FR-E11)', () async {
    final id = await repo.add(bike);
    await payNext(id, times: 4);
    final e = await load(id);
    expect(e.paidCount, 4);
    expect(await repo.watchRemaining(id).first, 6397113);
    final txns = await db.select(db.transactions).get();
    expect(txns, hasLength(4));
    expect(txns.every((t) => t.kind == 'expense' && t.source == 'emi' && t.amount == 799639 && t.paymentMode == 'online'), isTrue);
    final cat = await (db.select(db.categories)..where((c) => c.id.equals(txns.first.categoryId!))).getSingle();
    expect(cat.nameKey, 'catEmi');
    expect(e.installments.first.transactionId, isNotNull);
  });

  test('only the next due installment can be paid', () async {
    final id = await repo.add(bike);
    final third = (await load(id)).installments[2];
    expect(() => repo.markPaid(third.id, paidAt: DateTime.utc(2026, 10, 14), paymentMode: 'cash'), throwsStateError);
    expect(await db.select(db.transactions).get(), isEmpty);
  });

  test('undo inside 5 s: back to due, expense gone, nothing queued for upload', () async {
    final id = await repo.add(bike);
    final first = (await load(id)).nextDue!;
    final batch = await repo.markPaid(first.id, paidAt: DateTime.utc(2026, 10, 14), paymentMode: 'cash');
    final queued = await (db.select(db.syncOutbox)..where((o) => o.batchId.equals(batch))).get();
    expect(queued.every((o) => o.notBefore != null), isTrue); // held for the undo window
    await repo.undoMarkPaid(first.id, batch);
    expect((await load(id)).paidCount, 0);
    expect(await db.select(db.transactions).get(), isEmpty);
    expect(await (db.select(db.syncOutbox)..where((o) => o.batchId.equals(batch))).get(), isEmpty);
  });

  test('last installment closes the EMI; mark unpaid reopens it and removes the expense (FR-E8)', () async {
    final id = await repo.add(bike);
    await payNext(id, times: 12);
    var e = await load(id);
    expect(e.closed, isTrue);
    expect(await repo.watchRemaining(id).first, 0);
    await repo.markUnpaid(e.lastPaid!.id);
    e = await load(id);
    expect(e.closed, isFalse);
    expect(e.paidCount, 11);
    final live = await (db.select(db.transactions)..where((t) => t.deletedAt.isNull())).get();
    expect(live, hasLength(11));
  });

  test('summary: still to pay this month (late ones too) and next date, from SQL', () async {
    final bikeId = await repo.add(bike);
    await payNext(bikeId, times: 4); // Jul–Oct paid
    await repo.add(const EmiDraft(name: 'Phone EMI', icon: 'phone', lender: 'Bajaj', loanAmount: 2939400, rateBp: 0, months: 6, emiAmount: 489900, firstDue: LocalDate(2026, 10, 18)));
    final s = await repo.watchSummary(const LocalDate(2026, 11, 2)).first;
    // Nov: bike ₹7,996.39 (5 Nov) + phone 18 Oct (late) and 18 Nov, ₹4,899 each.
    expect(s.dueThisMonth, 799639 + 2 * 489900);
    expect(s.countThisMonth, 2);
    expect(s.nextDue, const LocalDate(2026, 11, 5));
  });

  test('due popup list: next due installment on or before today', () async {
    final id = await repo.add(bike);
    await payNext(id, times: 3);
    final due = await repo.dueToAsk(const LocalDate(2026, 10, 5));
    expect(due.single.$2.seq, 4);
    expect(await repo.dueToAsk(const LocalDate(2026, 7, 4)), isEmpty);
  });

  test('edit: name always; terms only while nothing is paid', () async {
    final id = await repo.add(bike);
    await repo.update(id, const EmiDraft(name: 'Bike', icon: 'bike', loanAmount: 9000000, rateBp: 1200, months: 6, emiAmount: 1552903, firstDue: LocalDate(2026, 7, 5)));
    expect((await load(id)).total, 6);
    await payNext(id);
    await repo.update(id, const EmiDraft(name: 'Scooter', icon: 'bike', loanAmount: 100, rateBp: 0, months: 1, emiAmount: 100, firstDue: LocalDate(2026, 7, 5)));
    final e = await load(id);
    expect(e.emi.name, 'Scooter');
    expect(e.total, 6);
    expect(e.emi.loanAmount, 9000000);
  });

  test('delete keeps expenses already added', () async {
    final id = await repo.add(bike);
    await payNext(id);
    await repo.delete(id);
    expect(await repo.watchOne(id).first, isNull);
    expect(await (db.select(db.transactions)..where((t) => t.deletedAt.isNull())).get(), hasLength(1));
  });
}
