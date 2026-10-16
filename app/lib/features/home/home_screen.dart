import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/ui/labels.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../data/local/database.dart';
import '../../data/repositories/calculations.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/entry_repository.dart';
import '../../data/repositories/people_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../shared/widgets/amount_text.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/overlays.dart';
import '../../shared/widgets/states.dart';
import '../../shared/widgets/swipe_row.dart';
import '../../shared/widgets/tab_page.dart';
import '../contacts/udhar_due_popup.dart';
import '../emi/emi_due_popup.dart';
import 'delete_entry.dart';
import 'entry_tile.dart';
import 'home_controller.dart';

/// Home (screen 10): month summary and every entry of the month, grouped by day.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(categoryRepositoryProvider).ensureDefaults();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _askDue();
    });
  }

  /// Due popups after unlock, one at a time (TRD 12): EMI first, then udhar.
  Future<void> _askDue() async {
    await askDueEmis(context, ref);
    if (mounted) await askDueUdhar(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final month = ref.watch(homeMonthProvider);
    final filter = ref.watch(homeFilterProvider);
    final summary = ref.watch(homeSummaryProvider).value;
    final entries = ref.watch(homeEntriesProvider).value ?? const <HomeEntry>[];
    final categories = ref.watch(categoriesByIdProvider).value ?? const {};
    final people = ref.watch(peopleByIdProvider).value ?? const {};
    final profile = ref.watch(profileProvider).value;
    final hide = profile?.hideAmounts ?? false;

    final shown = entries.where((e) => switch (filter) {
          HomeFilter.all => true,
          HomeFilter.expense => e.kind == EntryKind.expense,
          HomeFilter.income => e.kind == EntryKind.income,
          HomeFilter.udhar => e.isUdhar,
        }).toList();

    final groups = <LocalDate, List<HomeEntry>>{};
    for (final e in shown) {
      groups.putIfAbsent(Ist.dateOf(e.occurredAt), () => []).add(e);
    }

    return TabPage(
      header: _Header(month: month),
      children: [
        _SummaryCard(summary: summary, month: monthName(context, month.year, month.month), hide: hide),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final f in HomeFilter.values) ...[
              AppChip(
                label: switch (f) {
                  HomeFilter.all => l.filterAll,
                  HomeFilter.expense => l.expense,
                  HomeFilter.income => l.income,
                  HomeFilter.udhar => l.udhar,
                },
                selected: f == filter,
                selectedColor: switch (f) {
                  HomeFilter.expense => c.expenseButton,
                  HomeFilter.income => c.incomeButton,
                  _ => null,
                },
                onTap: () => ref.read(homeFilterProvider.notifier).set(f),
              ),
              const SizedBox(width: 6),
            ],
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, AppSpacing.md, 2, 0),
          child: Row(children: [
            Text(l.transactions, style: t.titleLarge),
            const SizedBox(width: 8),
            if (shown.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: ShapeDecoration(color: c.brandTint, shape: AppShapes.squircle(AppRadii.pill)),
                child: Text('${shown.length}', style: t.labelSmall?.copyWith(color: c.brandText)),
              ),
          ]),
        ),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: EmptyState(icon: Icons.currency_rupee_rounded, title: l.noEntriesTitle, message: entries.isEmpty ? '${l.noEntriesBody}\n${l.tapPlusToAdd}' : l.noEntriesBody),
          ),
        for (final day in groups.keys) ...[
          SectionLabel(dayLabel(context, day)),
          for (final e in groups[day]!)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _row(context, e, categories[e.categoryId], people[e.personId], hide),
            ),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, HomeEntry e, Category? category, PeopleData? person, bool hide) {
    final tile = EntryTile(
      entry: e,
      category: category,
      person: person,
      hideAmount: hide,
      onTap: () => e.isUdhar ? context.push('/person/${e.personId}') : context.push('/entry/${e.id}'),
    );
    if (e.isUdhar) return tile;
    final l = context.l10n;
    return SwipeActionRow(
      editLabel: l.edit,
      deleteLabel: l.delete,
      onEdit: () => context.push('/entry/${e.id}'),
      onDelete: () => confirmAndDeleteEntry(context, ref, e, category),
      child: tile,
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.month});

  final ({int year, int month}) month;

  String _greeting(AppLocalizations l) {
    final h = Ist.wall(DateTime.now()).hour;
    if (h < 12) return l.greetingMorning;
    if (h < 17) return l.greetingAfternoon;
    return l.greetingEvening;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.sm),
      child: Row(children: [
        Semantics(
          button: true,
          label: l.more,
          child: GestureDetector(
            onTap: () => context.push('/settings'),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.brandButton, border: Border.all(color: c.card, width: 2)),
              child: Icon(Icons.person_rounded, color: c.onButton, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(_greeting(l), maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleMedium)),
        _RoundButton(icon: Icons.search_rounded, label: l.search, onTap: () => CompactSnackbar.show(context, message: l.comingSoon)),
        const SizedBox(width: 6),
        _MonthPicker(month: month),
      ]),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: c.card,
        shape: const CircleBorder(),
        child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: SizedBox.square(dimension: 40, child: Icon(icon, size: 20, color: c.text))),
      ),
    );
  }
}

class _MonthPicker extends ConsumerWidget {
  const _MonthPicker({required this.month});

  final ({int year, int month}) month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final notifier = ref.read(homeMonthProvider.notifier);
    return Material(
      color: c.card,
      shape: AppShapes.squircle(AppRadii.pill),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(visualDensity: VisualDensity.compact, onPressed: () => notifier.shift(-1), icon: const Icon(Icons.chevron_left_rounded), tooltip: MaterialLocalizations.of(context).previousPageTooltip),
        Text(monthShort(context, month.year, month.month), style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 13)),
        IconButton(visualDensity: VisualDensity.compact, onPressed: () => notifier.shift(1), icon: const Icon(Icons.chevron_right_rounded), tooltip: MaterialLocalizations.of(context).nextPageTooltip),
      ]),
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({required this.summary, required this.month, required this.hide});

  final MonthSummary? summary;
  final String month;
  final bool hide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final s = summary;
    String m(int paise, {bool plus = false}) => hide ? '₹ •••••' : Money.format(paise, showPlus: plus);
    final net = s?.net ?? 0;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(l.balanceEndOf(month), style: t.labelMedium)),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: hide ? l.showAmounts : l.hideAmounts,
            onPressed: () => ref.read(profileRepositoryProvider).setHideAmounts(!hide),
            icon: Icon(hide ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: c.textMuted),
          ),
        ]),
        AmountText(m(s?.balance ?? 0), size: 36, color: c.text),
        const SizedBox(height: 4),
        Wrap(spacing: 14, children: [
          _Small(icon: Icons.payments_rounded, text: l.cashBalance(m(s?.cashBalance ?? 0))),
          _Small(icon: Icons.account_balance_rounded, text: l.onlineBalance(m(s?.onlineBalance ?? 0))),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          Expanded(child: _Tile(label: l.income, amount: m(s?.total.income ?? 0, plus: true), color: c.income, tint: c.incomeTint, icon: Icons.south_west_rounded)),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: _Tile(label: l.expense, amount: hide ? m(0) : '${Money.minus}${Money.format(s?.total.expense ?? 0)}', color: c.expense, tint: c.expenseTint, icon: Icons.north_east_rounded)),
        ]),
        const SizedBox(height: AppSpacing.xs),
        Row(children: [
          Expanded(child: _Tile(label: l.lent, amount: m(s?.total.lent ?? 0), color: c.lent, tint: c.lentTint, icon: Icons.east_rounded)),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: _Tile(label: l.borrowed, amount: m(s?.total.borrowed ?? 0), color: c.borrowed, tint: c.borrowedTint, icon: Icons.west_rounded)),
        ]),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Divider(color: c.border, height: 1),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          Expanded(child: Text(l.netThisMonth, style: t.bodyMedium?.copyWith(color: c.textSecondary))),
          AmountText(m(net, plus: true), size: 16, color: net >= 0 ? c.income : c.expense, alignment: Alignment.centerRight),
        ]),
      ]),
    );
  }
}

class _Small extends StatelessWidget {
  const _Small({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: c.textSecondary),
      const SizedBox(width: 5),
      Text(text, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.amount, required this.color, required this.tint, required this.icon});

  final String label;
  final String amount;
  final Color color;
  final Color tint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: ShapeDecoration(color: tint, shape: AppShapes.squircle(18)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(children: [
          IconTile(icon: icon, color: color, tint: c.card.withValues(alpha: 0.6), size: 30),
          const SizedBox(width: 9),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
              AmountText(amount, color: color),
            ]),
          ),
        ]),
      ),
    );
  }
}
