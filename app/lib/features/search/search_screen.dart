import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/ui/labels.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../data/local/database.dart';
import '../../data/repositories/calculations.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/people_repository.dart';
import '../../data/repositories/search_repository.dart';
import '../../shared/widgets/amount_text.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/motion.dart';
import '../../shared/widgets/person_avatar.dart';
import '../../shared/widgets/states.dart';
import '../contacts/contacts_controller.dart';

enum _Filter { all, expense, income, udhar, people }

/// Search (FR-C3, screen 23): entries and people, as you type, fully offline. People first, then
/// entries newest first, matches highlighted; filters; last 4 searches.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _text = TextEditingController();
  Timer? _debounce;
  String _q = '';
  _Filter _filter = _Filter.all;
  List<PeopleData> _people = const [];
  List<SearchHit> _hits = const [];
  List<String> _recent = const [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final r = await ref.read(searchRepositoryProvider).recent();
    if (mounted) setState(() => _recent = r);
  }

  void _changed(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () => _run(v));
  }

  Future<void> _run(String v) async {
    final q = v.trim();
    if (q.isEmpty) {
      setState(() {
        _q = '';
        _people = const [];
        _hits = const [];
      });
      return;
    }
    final l = context.l10n;
    final repo = ref.read(searchRepositoryProvider);
    final lower = q.toLowerCase();
    final cats = ref.read(categoriesByIdProvider).value ?? const <String, Category>{};
    final catIds = {
      for (final c in cats.values)
        if (categoryName(l, c).toLowerCase().contains(lower)) c.id,
    };
    final modes = {
      if (l.cash.toLowerCase().contains(lower)) 'cash',
      if (l.online.toLowerCase().contains(lower)) 'online',
      for (final m in const ['upi', 'card', 'bank'])
        if (m.contains(lower)) m,
    };
    final people = await repo.people(q);
    final hits = await repo.entries(q, categoryIds: catIds, modes: modes, personIds: {for (final p in people) p.id});
    if (!mounted || _text.text.trim() != q) return;
    setState(() {
      _q = q;
      _people = people;
      _hits = hits;
    });
    unawaited(repo.remember(q));
  }

  void _use(String q) {
    _text.text = q;
    _text.selection = TextSelection.collapsed(offset: q.length);
    _run(q);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final people = _filter == _Filter.all || _filter == _Filter.people ? _people : const <PeopleData>[];
    final hits = switch (_filter) {
      _Filter.all => _hits,
      _Filter.expense => _hits.where((h) => h.kind == SearchKind.expense).toList(),
      _Filter.income => _hits.where((h) => h.kind == SearchKind.income).toList(),
      _Filter.udhar => _hits.where((h) => h.isUdhar).toList(),
      _Filter.people => const <SearchHit>[],
    };
    final empty = _q.isNotEmpty && people.isEmpty && hits.isEmpty;

    return AppPage(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      autofocus: true,
                      onChanged: _changed,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: l.searchHint,
                        prefixIcon: const Icon(LucideIcons.search),
                        filled: true,
                        fillColor: c.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          borderSide: BorderSide(color: c.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          borderSide: BorderSide(color: c.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          borderSide: BorderSide(color: c.brandButton, width: 1.6),
                        ),
                      ),
                    ),
                  ),
                  TextButton(onPressed: () => context.pop(), child: Text(l.cancel)),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 4),
              child: Row(
                children: [
                  for (final f in _Filter.values) ...[
                    AppChip(
                      label: switch (f) {
                        _Filter.all => l.filterAll,
                        _Filter.expense => l.expense,
                        _Filter.income => l.income,
                        _Filter.udhar => l.udhar,
                        _Filter.people => l.filterPeople,
                      },
                      selected: _filter == f,
                      onTap: () => setState(() => _filter = f),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xl),
                children: [
                  if (_q.isEmpty) ...[
                    if (_recent.isNotEmpty) ...[
                      SectionLabel(l.recentSearches),
                      AppCard(
                        radius: AppRadii.lg,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        child: Column(
                          children: [
                            for (final r in _recent)
                              ListRowTile(
                                leading: Icon(LucideIcons.history, color: c.textMuted),
                                title: r,
                                onTap: () => _use(r),
                                trailing: IconButton(
                                  tooltip: l.close,
                                  icon: Icon(LucideIcons.x, size: 18, color: c.textMuted),
                                  onPressed: () async {
                                    await ref.read(searchRepositoryProvider).forget(r);
                                    _loadRecent();
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    // Tips card (screen 23).
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: ShapeDecoration(color: c.brandTint, shape: AppShapes.squircle(AppRadii.lg)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.trySearching,
                            style: t.titleSmall?.copyWith(color: c.brandText, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          for (final line in [l.tipName, l.tipNote, l.tipAmount])
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(line, style: t.bodySmall?.copyWith(color: c.text)),
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (empty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.lg),
                      child: Column(
                        children: [
                          EmptyState(icon: LucideIcons.searchX, title: l.noResultsFor(_q), message: l.noResultsBody),
                          if (_filter != _Filter.all) TextButton(onPressed: () => setState(() => _filter = _Filter.all), child: Text(l.searchInAll)),
                        ],
                      ),
                    ),
                  if (people.isNotEmpty) ...[
                    SectionLabel(l.peopleCount(people.length)),
                    for (final (i, p) in people.indexed)
                      FadeSlideIn(
                        key: ValueKey('p${p.id}'),
                        index: i,
                        child: _PersonHit(person: p, q: _q),
                      ),
                  ],
                  if (hits.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(l.entriesCount(hits.length), style: t.labelLarge?.copyWith(color: c.textSecondary)),
                          ),
                          Text(l.allTime, style: t.labelSmall),
                        ],
                      ),
                    ),
                    for (final (i, h) in hits.indexed)
                      FadeSlideIn(
                        key: ValueKey('e${h.kind.name}${h.id}${h.occurredAt}'),
                        index: i,
                        child: _EntryHit(hit: h, q: _q),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Text with every case-insensitive match of [q] highlighted (screen 23: matched word in yellow).
Widget highlighted(BuildContext context, String text, String q, TextStyle? style, {int maxLines = 1}) {
  final c = context.colors;
  final spans = <TextSpan>[];
  final lower = text.toLowerCase();
  final needle = q.toLowerCase();
  var i = 0;
  while (needle.isNotEmpty) {
    final at = lower.indexOf(needle, i);
    if (at < 0) break;
    if (at > i) spans.add(TextSpan(text: text.substring(i, at)));
    spans.add(
      TextSpan(
        text: text.substring(at, at + needle.length),
        style: TextStyle(backgroundColor: c.dueSoonTint, color: c.text, fontWeight: FontWeight.w700),
      ),
    );
    i = at + needle.length;
  }
  if (i < text.length) spans.add(TextSpan(text: text.substring(i)));
  return Text.rich(
    TextSpan(style: style, children: spans),
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
  );
}

class _PersonHit extends ConsumerWidget {
  const _PersonHit({required this.person, required this.q});

  final PeopleData person;
  final String q;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final PersonBalance? b = ref.watch(personBalancesProvider).value?[person.id];
    final net = b?.net ?? 0;
    final color = net == 0 ? c.textSecondary : (net > 0 ? c.lent : c.borrowed);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppCard(
        radius: AppRadii.md,
        padding: const EdgeInsets.all(AppSpacing.sm),
        onTap: () => context.push(Uri(path: '/person/${person.id}', queryParameters: {'name': person.name}).toString()),
        child: Row(
          children: [
            PersonAvatar(name: person.name, color: net < 0 ? c.borrowed : c.lent, tint: net < 0 ? c.borrowedTint : c.lentTint, circle: true),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  highlighted(context, person.name, q, t.titleSmall),
                  if (person.phoneNormalized != null) Text(person.phoneNormalized!, style: t.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AmountText(Money.format(net.abs()), size: 14, color: color, alignment: Alignment.centerRight),
                Text(net == 0 ? l.allClear : (net > 0 ? l.toReceiveLabel : l.toPayLabel), style: t.labelSmall?.copyWith(color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryHit extends ConsumerWidget {
  const _EntryHit({required this.hit, required this.q});

  final SearchHit hit;
  final String q;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final cats = ref.watch(categoriesByIdProvider).value ?? const <String, Category>{};
    final people = ref.watch(peopleByIdProvider).value ?? const <String, PeopleData>{};
    final cat = hit.categoryId == null ? null : cats[hit.categoryId];
    final person = hit.personId == null ? null : people[hit.personId]?.name ?? '';
    final (String title, String what, Color color, String sign) = switch (hit.kind) {
      SearchKind.income => (hit.title ?? (cat == null ? l.income : categoryName(l, cat)), cat == null ? l.income : categoryName(l, cat), c.income, '+'),
      SearchKind.expense => (
        hit.title ?? (cat == null ? l.catOthers : categoryName(l, cat)),
        cat == null ? l.catOthers : categoryName(l, cat),
        c.expense,
        Money.minus,
      ),
      SearchKind.lent => ('${l.lent} · $person', l.udhar, c.lent, ''),
      SearchKind.borrowed => ('${l.borrowed} · $person', l.udhar, c.borrowed, ''),
      SearchKind.repayment => (l.repaymentWith(person ?? ''), l.udhar, hit.lent ? c.income : c.expense, hit.lent ? '+' : Money.minus),
    };
    final meta = [shortDate(context, Ist.dateOf(hit.occurredAt)), what, paymentLabel(l, hit.paymentMode, hit.onlineMethod)].join(' · ');
    final icon = switch (hit.kind) {
      SearchKind.income || SearchKind.expense => categoryIcon(cat?.icon ?? ''),
      SearchKind.lent => LucideIcons.arrowRight,
      SearchKind.borrowed => LucideIcons.arrowLeft,
      SearchKind.repayment => LucideIcons.refreshCw,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppCard(
        radius: AppRadii.md,
        padding: const EdgeInsets.all(AppSpacing.sm),
        onTap: () => hit.isUdhar ? context.push('/person/${hit.personId}') : context.push('/entry/${hit.id}'),
        child: Row(
          children: [
            IconTile(icon: icon, color: cat == null ? color : Color(cat.color), tint: (cat == null ? color : Color(cat.color)).withValues(alpha: 0.16)),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [highlighted(context, title, q, t.titleSmall), highlighted(context, hit.note == null ? meta : '$meta · ${hit.note}', q, t.bodySmall)],
              ),
            ),
            AmountText('$sign${Money.format(hit.amount)}', size: 14, color: color, alignment: Alignment.centerRight),
          ],
        ),
      ),
    );
  }
}
