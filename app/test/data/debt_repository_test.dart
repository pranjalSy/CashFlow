import 'package:cashflow/core/utils/dates.dart';
import 'package:cashflow/data/local/database.dart';
import 'package:cashflow/data/repositories/calculations.dart';
import 'package:cashflow/data/repositories/debt_repository.dart';
import 'package:cashflow/data/repositories/local_writer.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DebtRepository repo;
  final at = DateTime.utc(2026, 10, 1, 6);

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DebtRepository(LocalWriter(db, userId: 'u1', clock: () => DateTime.utc(2026, 10, 14, 6)));
  });
  tearDown(() => db.close());

  Future<String> lend(int rupees, {bool premium = false, LocalDate? due, String direction = 'lent'}) => repo.add(
        personId: 'rahul',
        direction: direction,
        amount: rupees * 100,
        occurredAt: at,
        paymentMode: 'online',
        onlineMethod: 'upi',
        premium: premium,
        dueDate: due,
        reminderDays: const [0, 3],
      );

  Future<RepaymentResult> repay(String id, int rupees) =>
      repo.recordRepayment(debtId: id, amount: rupees * 100, occurredAt: at.add(const Duration(days: 7)), paymentMode: 'cash');

  test('partial repayment: status partial, remaining goes down (FR-D2)', () async {
    final id = await lend(5000);
    final r = await repay(id, 2000);
    expect(r.applied, 200000);
    expect(r.extra, 0);
    expect(r.settled, isFalse);
    expect((await repo.byId(id))!.status, 'partial');
    expect(await repo.remaining(id), 300000);
  });

  test('overpayment: repayment row capped at remaining, udhar settled, extra remembered (G5, G8)', () async {
    final id = await lend(3000, direction: 'borrowed'); // you owe 3,000
    final r = await repay(id, 5000); // you paid 5,000
    expect(r.applied, 300000);
    expect(r.extra, 200000);
    expect(r.settled, isTrue);
    final payments = await db.select(db.debtPayments).get();
    expect(payments.single.amount, 300000); // never above the remaining amount
    final d = (await repo.byId(id))!;
    expect(d.status, 'settled');
    expect(d.extraNotAdded, 200000);
  });

  test('"Yes" adds the extra as udhar in the opposite direction and clears the note (G7)', () async {
    final id = await lend(3000, direction: 'borrowed');
    await repay(id, 5000);
    final newId = await repo.addExtraAsDebt(id, premium: false);
    final extra = (await repo.byId(newId!))!;
    expect(extra.direction, 'lent');
    expect(extra.amount, 200000);
    expect(extra.extraFromDebtId, id);
    expect((await repo.byId(id))!.extraNotAdded, isNull);
    // Contact Net: borrowed 3,000 repaid 3,000 → 0; plus lent 2,000 → Rahul owes 2,000.
    final people = await Calculations(db, 'u1').people();
    expect(people['rahul']!.net, 200000);
  });

  test('a settled udhar takes no more repayments', () async {
    final id = await lend(1000);
    await repay(id, 1000);
    final r = await repay(id, 500);
    expect(r.applied, 0);
    expect((await db.select(db.debtPayments).get()).length, 1);
  });

  test('due date and reminders are kept only for Premium (G3)', () async {
    final free = await lend(1000, due: const LocalDate(2026, 10, 25));
    final paid = await lend(1000, premium: true, due: const LocalDate(2026, 10, 25));
    expect((await repo.byId(free))!.dueDate, isNull);
    expect((await repo.byId(free))!.reminderDays, isNull);
    expect((await repo.byId(paid))!.dueDate, '2026-10-25');
    expect((await repo.byId(paid))!.reminderDays, '0,3');
  });

  test('extend due date keeps history (FR-D4, G10)', () async {
    final id = await lend(1000, premium: true, due: const LocalDate(2026, 10, 25));
    await repo.extendDueDate(id, const LocalDate(2026, 11, 5));
    expect((await repo.byId(id))!.dueDate, '2026-11-05');
    final ext = await db.select(db.debtExtensions).getSingle();
    expect(ext.oldDueDate, '2026-10-25');
    expect(ext.newDueDate, '2026-11-05');
  });

  test('due popup list: due today or earlier, open, not snoozed; "Not yet" asks tomorrow (G9)', () async {
    const today = LocalDate(2026, 10, 25);
    final due = await lend(1000, premium: true, due: today);
    await lend(1000, premium: true, due: const LocalDate(2026, 10, 30)); // later
    final settled = await lend(1000, premium: true, due: today);
    await repay(settled, 1000);
    expect((await repo.dueToAsk(today)).map((d) => d.debt.id), [due]);
    await repo.askAgainTomorrow(due, today);
    expect(await repo.dueToAsk(today), isEmpty);
    expect((await repo.dueToAsk(today.addDays(1))).map((d) => d.debt.id), [due]);
  });

  test('person history lists udhar with its repayments; delete removes both', () async {
    final id = await lend(5000);
    await repay(id, 2000);
    final hist = await repo.watchPerson('rahul').first;
    expect(hist.single.repaid, 200000);
    expect(hist.single.remaining, 300000);
    await repo.delete(id);
    expect(await repo.watchPerson('rahul').first, isEmpty);
    expect((await db.select(db.debtPayments).getSingle()).deletedAt, isNotNull);
  });
}
