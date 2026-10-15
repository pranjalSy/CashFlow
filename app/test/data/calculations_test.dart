import 'package:cashflow/data/local/database.dart';
import 'package:cashflow/data/repositories/calculations.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late Calculations calc;
  const u = 'u1';
  final oct = DateTime.utc(2026, 10, 10, 6); // 10 Oct, 11:30 IST
  var n = 0;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    calc = Calculations(db, u);
  });
  tearDown(() => db.close());

  Future<void> txn(String kind, int rupees, {String mode = 'online', DateTime? at, bool deleted = false, String? cat, String user = u}) =>
      db.into(db.transactions).insert(TransactionsCompanion.insert(
            id: 't${n++}', userId: user, createdAt: oct, updatedAt: oct, kind: kind, amount: rupees * 100,
            occurredAt: at ?? oct, paymentMode: mode, categoryId: Value(cat), deletedAt: Value(deleted ? oct : null),
          ));

  Future<String> debt(String direction, int rupees, {String person = 'rahul', String mode = 'cash', DateTime? at}) async {
    final id = 'd${n++}';
    await db.into(db.debts).insert(DebtsCompanion.insert(
          id: id, userId: u, createdAt: oct, updatedAt: oct, personId: person, direction: direction,
          amount: rupees * 100, occurredAt: at ?? oct, paymentMode: mode,
        ));
    return id;
  }

  Future<void> repay(String debtId, int rupees, {String mode = 'cash', DateTime? at}) =>
      db.into(db.debtPayments).insert(DebtPaymentsCompanion.insert(
            id: 'p${n++}', userId: u, createdAt: oct, updatedAt: oct, debtId: debtId, amount: rupees * 100,
            occurredAt: at ?? oct, paymentMode: mode,
          ));

  test('Monthly Net reference: 45,000 − 28,500 − 5,000 + 2,000 = 13,500', () async {
    await txn('income', 45000);
    await txn('expense', 28500);
    await debt('lent', 5000);
    await debt('borrowed', 2000, person: 'amit');
    final m = await calc.month(2026, 10);
    expect(m.total.income, 4500000);
    expect(m.total.expense, 2850000);
    expect(m.total.lent, 500000);
    expect(m.total.borrowed, 200000);
    expect(m.net, 1350000);
  });

  test('repayments count in the net (received +, paid −)', () async {
    final lent = await debt('lent', 5000);
    final borrowed = await debt('borrowed', 3000, person: 'amit');
    await repay(lent, 2000);
    await repay(borrowed, 1000);
    final m = await calc.month(2026, 10);
    expect(m.total.repaidToYou, 200000);
    expect(m.total.repaidByYou, 100000);
    expect(m.net, -500000 + 300000 + 200000 - 100000);
  });

  test('Contact Net reference: lent 5,000, repaid 2,000 → 3,000 to receive', () async {
    final d = await debt('lent', 5000);
    await repay(d, 2000);
    final b = await debt('borrowed', 2000, person: 'amit');
    final people = await calc.people();
    expect(people['rahul']!.net, 300000);
    expect(people['amit']!.net, -200000);
    expect(await calc.debtRemaining(d), 300000);
    expect(await calc.debtRemaining(b), 200000);
  });

  test('balance at month end = opening + all nets up to that month, cash and online apart', () async {
    await db.into(db.profiles).insert(ProfilesCompanion.insert(
          id: 'p', userId: u, createdAt: oct, updatedAt: oct, openingCash: const Value(850000), openingOnline: const Value(11150000),
        ));
    await txn('income', 10000, at: DateTime.utc(2026, 9, 5)); // September, online
    await txn('expense', 500, mode: 'cash', at: DateTime.utc(2026, 9, 6));
    await txn('expense', 2450); // October, online
    final sep = await calc.month(2026, 9);
    expect(sep.cashBalance, 850000 - 50000);
    expect(sep.onlineBalance, 11150000 + 1000000);
    final octM = await calc.month(2026, 10);
    expect(octM.cashBalance, 800000);
    expect(octM.onlineBalance, 12150000 - 245000);
    expect(octM.balance, 800000 + 12150000 - 245000);
    expect(octM.net, -245000);
  });

  test('months follow India time (IST) at the edges', () async {
    await txn('expense', 100, at: DateTime.utc(2026, 10, 31, 18, 29)); // 31 Oct 23:59 IST
    await txn('expense', 200, at: DateTime.utc(2026, 10, 31, 18, 30)); // 1 Nov 00:00 IST
    expect((await calc.month(2026, 10)).total.expense, 10000);
    expect((await calc.month(2026, 11)).total.expense, 20000);
  });

  test('deleted rows and other users never count', () async {
    await txn('expense', 999, deleted: true);
    await txn('income', 777, user: 'someone-else');
    final m = await calc.month(2026, 10);
    expect(m.total.expense, 0);
    expect(m.total.income, 0);
  });

  test('budget spent: expenses only, per category', () async {
    await txn('expense', 4200, cat: 'food');
    await txn('expense', 800, cat: 'fun');
    await txn('income', 45000, cat: 'salary');
    await debt('lent', 5000);
    expect(await calc.expenseInMonth(2026, 10), 500000);
    expect(await calc.expenseInMonth(2026, 10, categoryId: 'food'), 420000);
  });

  test('watchMonth emits again when an entry is added', () async {
    final stream = calc.watchMonth(2026, 10);
    final values = <int>[];
    final sub = stream.listen((m) => values.add(m.total.expense));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await txn('expense', 300);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await sub.cancel();
    expect(values.first, 0);
    expect(values.last, 30000);
  });
}
