import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/database.dart';
import '../providers.dart';

/// What a search result row is (FR-C3).
enum SearchKind { income, expense, lent, borrowed, repayment }

/// One entry found by search.
class SearchHit {
  const SearchHit({
    required this.kind,
    required this.id,
    required this.amount,
    required this.occurredAt,
    required this.paymentMode,
    this.onlineMethod,
    this.title,
    this.note,
    this.categoryId,
    this.personId,
    this.lent = false,
  });

  final SearchKind kind;

  /// Transaction id, debt id, or the debt id of a repayment.
  final String id;
  final int amount;
  final DateTime occurredAt;
  final String paymentMode;
  final String? onlineMethod;
  final String? title;
  final String? note;
  final String? categoryId;
  final String? personId;

  /// For a repayment: true when it was money you lent coming back.
  final bool lent;

  bool get isUdhar => kind == SearchKind.lent || kind == SearchKind.borrowed || kind == SearchKind.repayment;
}

/// Offline search over entries and people (FR-C3, TRD 6 search). Uses indexed LIKE on the phone
/// database: the data on one phone is small, so the TRD fallback is fast enough without FTS5.
/// Category and payment names are matched in the user's language by the caller, which passes ids/modes.
class SearchRepository {
  SearchRepository(this.db, this.userId);

  final AppDatabase db;
  final String userId;

  static String _like(String q) => '%${q.toLowerCase().replaceAll('%', '').replaceAll('_', '')}%';

  /// Amount typed as digits ("2000" or "2,000") → paise, else null.
  static int? amountOf(String q) {
    final digits = q.replaceAll(RegExp(r'[₹,\s]'), '');
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(digits)) return null;
    return (double.parse(digits) * 100).round();
  }

  Future<List<PeopleData>> people(String q) {
    final like = _like(q);
    final digits = q.replaceAll(RegExp(r'\D'), '');
    return (db.select(db.people)
          ..where((p) =>
              p.userId.equals(userId) &
              p.deletedAt.isNull() &
              (p.name.lower().like(like) | (digits.length >= 3 ? p.phoneNormalized.like('%$digits%') : const Constant(false))))
          ..orderBy([(p) => OrderingTerm.asc(p.name)])
          ..limit(30))
        .get();
  }

  /// Entries newest first. [categoryIds] and [modes] are the categories / payment modes whose names match
  /// in the user's language; [personIds] are the people found by name.
  Future<List<SearchHit>> entries(String q, {Set<String> categoryIds = const {}, Set<String> modes = const {}, Set<String> personIds = const {}}) async {
    final like = _like(q);
    final amount = amountOf(q);
    String inList(Iterable<String> v) => v.isEmpty ? "('')" : '(${v.map((e) => "'${e.replaceAll("'", "''")}'").join(',')})';
    final cats = inList(categoryIds);
    final ms = inList(modes);
    final ps = inList(personIds);
    final amt = amount == null ? '' : ' OR amount = $amount';

    final txns = await db.customSelect(
      'SELECT id, kind, amount, occurred_at, payment_mode, online_method, title, note, category_id FROM transactions '
      'WHERE user_id = ?1 AND deleted_at IS NULL AND (LOWER(COALESCE(title, \'\')) LIKE ?2 OR LOWER(COALESCE(note, \'\')) LIKE ?2 '
      'OR category_id IN $cats OR payment_mode IN $ms OR online_method IN $ms$amt) ORDER BY occurred_at DESC LIMIT 200',
      variables: [Variable<String>(userId), Variable<String>(like)],
      readsFrom: {db.transactions},
    ).get();
    final debts = await db.customSelect(
      'SELECT id, direction, amount, occurred_at, payment_mode, online_method, note, person_id FROM debts '
      'WHERE user_id = ?1 AND deleted_at IS NULL AND (person_id IN $ps OR LOWER(COALESCE(note, \'\')) LIKE ?2 '
      'OR payment_mode IN $ms OR online_method IN $ms$amt) ORDER BY occurred_at DESC LIMIT 200',
      variables: [Variable<String>(userId), Variable<String>(like)],
      readsFrom: {db.debts},
    ).get();
    final repaid = await db.customSelect(
      'SELECT d.id AS debt_id, d.direction AS direction, p.amount AS amount, p.occurred_at AS occurred_at, p.payment_mode AS payment_mode, '
      'p.online_method AS online_method, d.person_id AS person_id FROM debt_payments p JOIN debts d ON d.id = p.debt_id '
      'WHERE p.user_id = ?1 AND p.deleted_at IS NULL AND d.deleted_at IS NULL AND (d.person_id IN $ps '
      'OR p.payment_mode IN $ms OR p.online_method IN $ms${amount == null ? '' : ' OR p.amount = $amount'}) ORDER BY p.occurred_at DESC LIMIT 200',
      variables: [Variable<String>(userId)],
      readsFrom: {db.debtPayments, db.debts},
    ).get();

    final hits = <SearchHit>[
      for (final r in txns)
        SearchHit(
          kind: r.read<String>('kind') == 'income' ? SearchKind.income : SearchKind.expense,
          id: r.read<String>('id'),
          amount: r.read<int>('amount'),
          occurredAt: r.read<DateTime>('occurred_at'),
          paymentMode: r.read<String>('payment_mode'),
          onlineMethod: r.readNullable<String>('online_method'),
          title: r.readNullable<String>('title'),
          note: r.readNullable<String>('note'),
          categoryId: r.readNullable<String>('category_id'),
        ),
      for (final r in debts)
        SearchHit(
          kind: r.read<String>('direction') == 'lent' ? SearchKind.lent : SearchKind.borrowed,
          id: r.read<String>('id'),
          amount: r.read<int>('amount'),
          occurredAt: r.read<DateTime>('occurred_at'),
          paymentMode: r.read<String>('payment_mode'),
          onlineMethod: r.readNullable<String>('online_method'),
          note: r.readNullable<String>('note'),
          personId: r.read<String>('person_id'),
        ),
      for (final r in repaid)
        SearchHit(
          kind: SearchKind.repayment,
          id: r.read<String>('debt_id'),
          amount: r.read<int>('amount'),
          occurredAt: r.read<DateTime>('occurred_at'),
          paymentMode: r.read<String>('payment_mode'),
          onlineMethod: r.readNullable<String>('online_method'),
          personId: r.read<String>('person_id'),
          lent: r.read<String>('direction') == 'lent',
        ),
    ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return hits;
  }

  /// Last 4 searches, newest first (phone only).
  Future<List<String>> recent() async {
    final v = await db.flag('recent_searches');
    return v == null ? const [] : (jsonDecode(v) as List).cast<String>();
  }

  Future<void> remember(String q) async {
    final t = q.trim();
    if (t.isEmpty) return;
    final list = [t, ...(await recent()).where((x) => x.toLowerCase() != t.toLowerCase())].take(4).toList();
    await db.setFlag('recent_searches', jsonEncode(list));
  }

  Future<void> forget(String q) async {
    final list = (await recent()).where((x) => x != q).toList();
    await db.setFlag('recent_searches', jsonEncode(list));
  }
}

final searchRepositoryProvider = Provider<SearchRepository>((ref) => SearchRepository(ref.watch(databaseProvider), ref.watch(userIdProvider)));
