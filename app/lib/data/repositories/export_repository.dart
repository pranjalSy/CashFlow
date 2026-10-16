import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/dates.dart';
import '../local/database.dart';
import '../providers.dart';

/// Which "Include" box a row belongs to (FR-C2).
enum ExportGroup { incomeExpense, udhar, emiBills }

/// What a row is, for the Type column.
enum ExportKind { income, expense, emi, bill, lent, borrowed, repaymentIn, repaymentOut }

class ExportRow {
  const ExportRow({
    required this.group,
    required this.kind,
    required this.at,
    required this.amount,
    required this.paymentMode,
    this.onlineMethod,
    this.title,
    this.categoryId,
    this.personId,
    this.note,
  });

  final ExportGroup group;
  final ExportKind kind;
  final DateTime at;

  /// Paise, always positive; the sign comes from [kind].
  final int amount;
  final String paymentMode;
  final String? onlineMethod;
  final String? title;
  final String? categoryId;
  final String? personId;
  final String? note;

  /// Money in (+) or out (−) of the user's cash/online balance.
  bool get isIn => kind == ExportKind.income || kind == ExportKind.borrowed || kind == ExportKind.repaymentIn;
}

/// Rows for an export, read on the phone (FR-C2). Nothing is uploaded.
class ExportRepository {
  ExportRepository(this.db, this.userId);

  final AppDatabase db;
  final String userId;

  /// Every row from [from] to [to] (India dates, inclusive), oldest first.
  Future<List<ExportRow>> rows(LocalDate from, LocalDate to) async {
    final start = Ist.instantOf(from);
    final end = Ist.instantOf(to.addDays(1));
    final vars = [Variable<String>(userId), Variable<DateTime>(start), Variable<DateTime>(end)];
    final txns = await db.customSelect(
      'SELECT kind, amount, occurred_at, payment_mode, online_method, title, category_id, note, source FROM transactions '
      'WHERE user_id = ?1 AND deleted_at IS NULL AND occurred_at >= ?2 AND occurred_at < ?3',
      variables: vars,
      readsFrom: {db.transactions},
    ).get();
    final debts = await db.customSelect(
      'SELECT direction, amount, occurred_at, payment_mode, online_method, person_id, note FROM debts '
      'WHERE user_id = ?1 AND deleted_at IS NULL AND occurred_at >= ?2 AND occurred_at < ?3',
      variables: vars,
      readsFrom: {db.debts},
    ).get();
    final pays = await db.customSelect(
      'SELECT d.direction AS direction, p.amount AS amount, p.occurred_at AS occurred_at, p.payment_mode AS payment_mode, '
      'p.online_method AS online_method, d.person_id AS person_id FROM debt_payments p JOIN debts d ON d.id = p.debt_id '
      'WHERE p.user_id = ?1 AND p.deleted_at IS NULL AND d.deleted_at IS NULL AND p.occurred_at >= ?2 AND p.occurred_at < ?3',
      variables: vars,
      readsFrom: {db.debtPayments, db.debts},
    ).get();
    final out = <ExportRow>[
      for (final r in txns)
        () {
          final source = r.read<String>('source');
          final income = r.read<String>('kind') == 'income';
          return ExportRow(
            group: source == 'emi' || source == 'bill' ? ExportGroup.emiBills : ExportGroup.incomeExpense,
            kind: source == 'emi' ? ExportKind.emi : (source == 'bill' ? ExportKind.bill : (income ? ExportKind.income : ExportKind.expense)),
            at: r.read<DateTime>('occurred_at'),
            amount: r.read<int>('amount'),
            paymentMode: r.read<String>('payment_mode'),
            onlineMethod: r.readNullable<String>('online_method'),
            title: r.readNullable<String>('title'),
            categoryId: r.readNullable<String>('category_id'),
            note: r.readNullable<String>('note'),
          );
        }(),
      for (final r in debts)
        ExportRow(
          group: ExportGroup.udhar,
          kind: r.read<String>('direction') == 'lent' ? ExportKind.lent : ExportKind.borrowed,
          at: r.read<DateTime>('occurred_at'),
          amount: r.read<int>('amount'),
          paymentMode: r.read<String>('payment_mode'),
          onlineMethod: r.readNullable<String>('online_method'),
          personId: r.read<String>('person_id'),
          note: r.readNullable<String>('note'),
        ),
      for (final r in pays)
        ExportRow(
          group: ExportGroup.udhar,
          kind: r.read<String>('direction') == 'lent' ? ExportKind.repaymentIn : ExportKind.repaymentOut,
          at: r.read<DateTime>('occurred_at'),
          amount: r.read<int>('amount'),
          paymentMode: r.read<String>('payment_mode'),
          onlineMethod: r.readNullable<String>('online_method'),
          personId: r.read<String>('person_id'),
        ),
    ]..sort((a, b) => a.at.compareTo(b.at));
    return out;
  }
}

final exportRepositoryProvider = Provider<ExportRepository>((ref) => ExportRepository(ref.watch(databaseProvider), ref.watch(userIdProvider)));
