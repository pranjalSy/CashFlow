import 'package:drift/drift.dart';

import '../../core/utils/dates.dart';
import '../local/database.dart';

/// Money moved in one period, split by cash and online (PRD §8). All values paise.
class Flow {
  const Flow({
    this.income = 0,
    this.expense = 0,
    this.lent = 0,
    this.borrowed = 0,
    this.repaidToYou = 0,
    this.repaidByYou = 0,
  });

  final int income;
  final int expense;

  /// New "lent" udhar dated in the period.
  final int lent;

  /// New "borrowed" udhar dated in the period.
  final int borrowed;

  /// Repayments received on money you lent (Loan In).
  final int repaidToYou;

  /// Repayments you paid on money you borrowed (Loan Out).
  final int repaidByYou;

  /// Monthly Net = Income − Expense − Lent + Borrowed + Repayments received − Repayments paid.
  int get net => income - expense - lent + borrowed + repaidToYou - repaidByYou;

  Flow operator +(Flow o) => Flow(
        income: income + o.income,
        expense: expense + o.expense,
        lent: lent + o.lent,
        borrowed: borrowed + o.borrowed,
        repaidToYou: repaidToYou + o.repaidToYou,
        repaidByYou: repaidByYou + o.repaidByYou,
      );
}

class MonthSummary {
  const MonthSummary({required this.month, required this.cash, required this.online, required this.openingCash, required this.openingOnline, required this.beforeCash, required this.beforeOnline});

  /// Flows inside the month, by payment mode.
  final Flow cash;
  final Flow online;
  final int openingCash;
  final int openingOnline;

  /// Net of everything before the month, by payment mode.
  final int beforeCash;
  final int beforeOnline;
  final ({int year, int month}) month;

  Flow get total => cash + online;
  int get net => total.net;

  int get cashBalance => openingCash + beforeCash + cash.net;
  int get onlineBalance => openingOnline + beforeOnline + online.net;

  /// Big Home number: balance at the end of the month (FR-O6).
  int get balance => cashBalance + onlineBalance;
}

class PersonBalance {
  const PersonBalance({required this.personId, required this.lent, required this.repaidToYou, required this.borrowed, required this.repaidByYou});

  final String personId;
  final int lent;
  final int repaidToYou;
  final int borrowed;
  final int repaidByYou;

  /// Contact Net: positive = the person owes the user (To receive).
  int get net => (lent - repaidToYou) - (borrowed - repaidByYou);
}

/// Totals as SQL aggregates on the phone database (TRD 7). Deleted rows never count.
class Calculations {
  Calculations(this.db, this.userId);

  final AppDatabase db;
  final String userId;

  static const _modes = ['cash', 'online'];
  static final _beginning = DateTime.utc(2000);

  Set<ResultSetImplementation> get _sources => {db.transactions, db.debts, db.debtPayments, db.profiles};

  /// One row per payment mode with all six flows for `occurred_at` in [from, to).
  Selectable<QueryRow> _flowQuery(DateTime? from, DateTime to) {
    return db.customSelect(
      '''
      SELECT m.mode AS mode,
        (SELECT COALESCE(SUM(amount),0) FROM transactions WHERE user_id = ?1 AND deleted_at IS NULL AND kind = 'income' AND payment_mode = m.mode AND occurred_at < ?3 AND occurred_at >= ?2) AS income,
        (SELECT COALESCE(SUM(amount),0) FROM transactions WHERE user_id = ?1 AND deleted_at IS NULL AND kind = 'expense' AND payment_mode = m.mode AND occurred_at < ?3 AND occurred_at >= ?2) AS expense,
        (SELECT COALESCE(SUM(amount),0) FROM debts WHERE user_id = ?1 AND deleted_at IS NULL AND direction = 'lent' AND payment_mode = m.mode AND occurred_at < ?3 AND occurred_at >= ?2) AS lent,
        (SELECT COALESCE(SUM(amount),0) FROM debts WHERE user_id = ?1 AND deleted_at IS NULL AND direction = 'borrowed' AND payment_mode = m.mode AND occurred_at < ?3 AND occurred_at >= ?2) AS borrowed,
        (SELECT COALESCE(SUM(p.amount),0) FROM debt_payments p JOIN debts d ON d.id = p.debt_id
           WHERE p.user_id = ?1 AND p.deleted_at IS NULL AND d.deleted_at IS NULL AND d.direction = 'lent' AND p.payment_mode = m.mode AND p.occurred_at < ?3 AND p.occurred_at >= ?2) AS repaid_to_you,
        (SELECT COALESCE(SUM(p.amount),0) FROM debt_payments p JOIN debts d ON d.id = p.debt_id
           WHERE p.user_id = ?1 AND p.deleted_at IS NULL AND d.deleted_at IS NULL AND d.direction = 'borrowed' AND p.payment_mode = m.mode AND p.occurred_at < ?3 AND p.occurred_at >= ?2) AS repaid_by_you
      FROM (SELECT 'cash' AS mode UNION ALL SELECT 'online') m
      ''',
      variables: [Variable<String>(userId), Variable<DateTime>(from ?? _beginning), Variable<DateTime>(to)],
      readsFrom: _sources,
    );
  }

  static Map<String, Flow> _flows(List<QueryRow> rows) => {
        for (final r in rows)
          r.read<String>('mode'): Flow(
            income: r.read<int>('income'),
            expense: r.read<int>('expense'),
            lent: r.read<int>('lent'),
            borrowed: r.read<int>('borrowed'),
            repaidToYou: r.read<int>('repaid_to_you'),
            repaidByYou: r.read<int>('repaid_by_you'),
          ),
      };

  Future<(int, int)> _opening() async {
    final p = await (db.select(db.profiles)..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())).getSingleOrNull();
    return (p?.openingCash ?? 0, p?.openingOnline ?? 0);
  }

  /// Summary for an India month (`occurred_at` in IST month range).
  Future<MonthSummary> month(int year, int month) async {
    final (start, end) = Ist.monthRange(year, month);
    final inMonth = _flows(await _flowQuery(start, end).get());
    final before = _flows(await _flowQuery(null, start).get());
    final (oc, oo) = await _opening();
    return MonthSummary(
      month: (year: year, month: month),
      cash: inMonth[_modes[0]]!,
      online: inMonth[_modes[1]]!,
      openingCash: oc,
      openingOnline: oo,
      beforeCash: before[_modes[0]]!.net,
      beforeOnline: before[_modes[1]]!.net,
    );
  }

  /// Live version for the Home screen: re-runs when any money table changes.
  Stream<MonthSummary> watchMonth(int year, int month) {
    final (_, end) = Ist.monthRange(year, month);
    return _flowQuery(null, end).watch().asyncMap((_) => this.month(year, month));
  }

  Selectable<QueryRow> _peopleQuery() => db.customSelect(
        '''
        SELECT d.person_id AS person_id,
          COALESCE(SUM(CASE WHEN d.direction = 'lent' THEN d.amount END), 0) AS lent,
          COALESCE(SUM(CASE WHEN d.direction = 'borrowed' THEN d.amount END), 0) AS borrowed,
          COALESCE(SUM(CASE WHEN d.direction = 'lent' THEN (SELECT COALESCE(SUM(p.amount),0) FROM debt_payments p WHERE p.debt_id = d.id AND p.deleted_at IS NULL) END), 0) AS repaid_to_you,
          COALESCE(SUM(CASE WHEN d.direction = 'borrowed' THEN (SELECT COALESCE(SUM(p.amount),0) FROM debt_payments p WHERE p.debt_id = d.id AND p.deleted_at IS NULL) END), 0) AS repaid_by_you
        FROM debts d
        WHERE d.user_id = ?1 AND d.deleted_at IS NULL
        GROUP BY d.person_id
        ''',
        variables: [Variable<String>(userId)],
        readsFrom: {db.debts, db.debtPayments},
      );

  static PersonBalance _person(QueryRow r) => PersonBalance(
        personId: r.read<String>('person_id'),
        lent: r.read<int>('lent'),
        borrowed: r.read<int>('borrowed'),
        repaidToYou: r.read<int>('repaid_to_you'),
        repaidByYou: r.read<int>('repaid_by_you'),
      );

  /// Contact Net for every person with udhar (all time).
  Future<Map<String, PersonBalance>> people() async => {for (final r in await _peopleQuery().get()) r.read<String>('person_id'): _person(r)};

  Stream<Map<String, PersonBalance>> watchPeople() =>
      _peopleQuery().watch().map((rows) => {for (final r in rows) r.read<String>('person_id'): _person(r)});

  /// Remaining amount of one udhar: amount − its repayments.
  Future<int> debtRemaining(String debtId) async {
    final row = await db.customSelect(
      'SELECT d.amount - COALESCE((SELECT SUM(amount) FROM debt_payments WHERE debt_id = d.id AND deleted_at IS NULL),0) AS remaining FROM debts d WHERE d.id = ?1',
      variables: [Variable<String>(debtId)],
      readsFrom: {db.debts, db.debtPayments},
    ).getSingleOrNull();
    return row?.read<int>('remaining') ?? 0;
  }

  /// Expense spent in a month, optionally for one category (budgets exclude udhar).
  Future<int> expenseInMonth(int year, int month, {String? categoryId}) async {
    final (start, end) = Ist.monthRange(year, month);
    final row = await db.customSelect(
      'SELECT COALESCE(SUM(amount),0) AS s FROM transactions WHERE user_id = ?1 AND deleted_at IS NULL AND kind = \'expense\' AND occurred_at >= ?2 AND occurred_at < ?3 ${categoryId == null ? '' : 'AND category_id = ?4'}',
      variables: [Variable<String>(userId), Variable<DateTime>(start), Variable<DateTime>(end), if (categoryId != null) Variable<String>(categoryId)],
      readsFrom: {db.transactions},
    ).getSingle();
    return row.read<int>('s');
  }
}
