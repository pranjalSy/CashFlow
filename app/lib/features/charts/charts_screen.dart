import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/ui/labels.dart';
import '../../core/utils/money.dart';
import '../../data/local/database.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/charts_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../shared/widgets/amount_text.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/charts.dart';
import '../../shared/widgets/month_pill.dart';
import '../../shared/widgets/motion.dart';
import '../../shared/widgets/overlays.dart';
import '../../shared/widgets/states.dart';
import '../../shared/widgets/tab_page.dart';
import 'charts_controller.dart';

/// Charts (FR-C1, screen 16): Spending | Trends. Premium; Free users see the locked card.
class ChartsScreen extends ConsumerStatefulWidget {
  const ChartsScreen({super.key});

  @override
  ConsumerState<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends ConsumerState<ChartsScreen> {
  int _tab = 0;
  bool _udhar = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final premium = ref.watch(isPremiumProvider).value ?? false;
    final m = ref.watch(chartsMonthProvider);
    return TabPage(
      header: Padding(
        padding: const EdgeInsets.only(top: 6, bottom: AppSpacing.sm),
        child: Row(children: [
          Expanded(child: Text(l.navCharts, style: t.displaySmall)),
          MonthPill(year: m.year, month: m.month, onShift: ref.read(chartsMonthProvider.notifier).shift),
        ]),
      ),
      children: [
        SegmentedSwitch(options: [l.spending, l.trends], index: _tab, onChanged: (i) => setState(() => _tab = i)),
        const SizedBox(height: AppSpacing.md),
        if (!premium)
          PremiumLockCard(
            title: l.chartsLockTitle,
            message: l.chartsLockBody,
            buttonLabel: l.premiumTryButton,
            fineprint: l.premiumFineprint,
            onTry: () => CompactSnackbar.show(context, message: l.premiumComingLater),
          )
        else if (_tab == 0)
          _Spending(year: m.year, month: m.month, udhar: _udhar, onUdhar: (v) => setState(() => _udhar = v))
        else
          _Trends(year: m.year, month: m.month),
      ],
    );
  }
}

class _Spending extends ConsumerWidget {
  const _Spending({required this.year, required this.month, required this.udhar, required this.onUdhar});

  final int year;
  final int month;
  final bool udhar;
  final ValueChanged<bool> onUdhar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final data = ref.watch(spendingProvider((year: year, month: month, udhar: udhar))).value;
    final cats = ref.watch(categoriesByIdProvider).value ?? const <String, Category>{};
    if (data == null) return const SizedBox(height: 200);
    final monthLabel = monthShort(context, year, month).split(' ').first;
    final prev = monthShort(context, month == 1 ? year - 1 : year, month == 1 ? 12 : month - 1).split(' ').first;
    Color colorOf(SpendSlice s) => s.isUdhar ? c.lent : (s.categoryId != null && cats[s.categoryId] != null ? Color(cats[s.categoryId]!.color) : c.textSecondary);
    String nameOf(SpendSlice s) => s.isUdhar ? l.lent : (s.categoryId != null && cats[s.categoryId] != null ? categoryName(l, cats[s.categoryId]!) : l.catOthers);
    IconData iconOf(SpendSlice s) => s.isUdhar ? LucideIcons.arrowRight : categoryIcon(cats[s.categoryId]?.icon ?? '');

    final change = data.previousTotal == 0 ? null : ((data.total - data.previousTotal) * 100 / data.previousTotal).round();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FadeSlideIn(child: _BudgetCard(year: year, month: month)),
      const SizedBox(height: AppSpacing.sm),
      FadeSlideIn(
        index: 1,
        child: AppCard(
          child: Column(children: [
            DonutChart(
              key: ValueKey('$year-$month-$udhar-${data.total}'),
              values: [for (final s in data.slices) s.amount],
              colors: [for (final s in data.slices) colorOf(s)],
              center: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(l.spentIn(monthLabel), textAlign: TextAlign.center, style: t.bodySmall),
                CountUpAmount(paise: data.total, size: 22, color: c.text, alignment: Alignment.center),
                if (change != null && change != 0)
                  Text(
                    change < 0 ? l.vsMonthDown(-change, prev) : l.vsMonthUp(change, prev),
                    textAlign: TextAlign.center,
                    style: t.labelSmall?.copyWith(color: change < 0 ? c.income : c.expense, fontWeight: FontWeight.w700),
                  ),
              ]),
            ),
            const SizedBox(height: AppSpacing.sm),
            ListRowTile(
              leading: Icon(LucideIcons.handshake, color: c.textSecondary),
              title: l.includeUdhar,
              trailing: AppToggle(value: udhar, onChanged: onUdhar),
            ),
          ]),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      if (data.slices.isEmpty) AppCard(child: EmptyState(icon: LucideIcons.chartPie, title: l.noSpendingTitle, message: l.noSpendingBody)),
      for (final (i, s) in data.slices.indexed)
        FadeSlideIn(
          key: ValueKey('${s.categoryId}-${s.isUdhar}'),
          index: i + 2,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _ShareRow(
              icon: iconOf(s),
              color: colorOf(s),
              name: nameOf(s),
              amount: s.amount,
              fraction: data.total == 0 ? 0 : s.amount / data.total,
            ),
          ),
        ),
    ]);
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({required this.icon, required this.color, required this.name, required this.amount, required this.fraction});

  final IconData icon;
  final Color color;
  final String name;
  final int amount;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return AppCard(
      radius: AppRadii.md,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(children: [
        IconTile(icon: icon, color: color, tint: color.withValues(alpha: 0.16), size: 36),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall)),
              AmountText(Money.format(amount), size: 14, alignment: Alignment.centerRight),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: fraction),
                    duration: Motion.off(context) ? Duration.zero : const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => LinearProgressIndicator(value: v, minHeight: 5, color: color, backgroundColor: c.raised),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(l.percentOf((fraction * 100).round()), style: t.labelSmall),
            ]),
          ]),
        ),
      ]),
    );
  }
}

/// Small Budget card on top of Spending (FR-BG5); tap = Budget screen.
class _BudgetCard extends ConsumerWidget {
  const _BudgetCard({required this.year, required this.month});

  final int year;
  final int month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final budget = ref.watch(budgetProvider).value;
    final spend = ref.watch(budgetSpendProvider((year: year, month: month))).value;
    final limit = budget?.monthlyLimit;
    final spent = spend?.overall ?? 0;
    final band = limit == null ? BudgetBand.ok : budgetBand(spent, limit);
    final color = bandColor(context, band);
    return AppCard(
      radius: AppRadii.md,
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: () => context.push('/budget'),
      child: Row(children: [
        IconTile(icon: LucideIcons.target, color: color, tint: color.withValues(alpha: 0.16), size: 36),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.budget, style: t.labelMedium),
            Text(
              limit == null ? l.setMonthlyBudget : l.budgetOfLimit(Money.format(spent), Money.format(limit)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.titleSmall,
            ),
          ]),
        ),
        if (limit != null && limit > 0) Text(l.percentOf((spent * 100 / limit).round()), style: t.titleSmall?.copyWith(color: color)),
        Icon(LucideIcons.chevronRight, color: c.textMuted),
      ]),
    );
  }
}

/// Green / orange / red for a budget band (FR-BG3).
Color bandColor(BuildContext context, BudgetBand band) {
  final c = context.colors;
  return switch (band) {
    BudgetBand.ok => c.income,
    BudgetBand.near => c.dueSoon,
    BudgetBand.over => c.expense,
  };
}

final budgetProvider = StreamProvider<Budget?>((ref) => ref.watch(budgetRepositoryProvider).watchBudget());
final budgetLimitsProvider = StreamProvider<List<BudgetCategoryLimit>>((ref) => ref.watch(budgetRepositoryProvider).watchLimits());

class _Trends extends ConsumerStatefulWidget {
  const _Trends({required this.year, required this.month});

  final int year;
  final int month;

  @override
  ConsumerState<_Trends> createState() => _TrendsState();
}

class _TrendsState extends ConsumerState<_Trends> {
  int _selected = 5;

  @override
  void didUpdateWidget(_Trends old) {
    super.didUpdateWidget(old);
    if (old.year != widget.year || old.month != widget.month) _selected = 5;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final months = ref.watch(trendProvider((year: widget.year, month: widget.month))).value;
    if (months == null) return const SizedBox(height: 200);
    final sel = months[_selected];
    final avgIncome = (months.fold(0, (a, m) => a + m.income) / months.length).round();
    final avgExpense = (months.fold(0, (a, m) => a + m.expense) / months.length).round();
    final best = months.map((m) => m.saved).fold(0, (a, b) => a > b ? a : b);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FadeSlideIn(
        child: AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(l.lastSixMonths, style: t.titleSmall)),
              _Legend(color: c.incomeButton, label: l.income),
              const SizedBox(width: 10),
              _Legend(color: c.expenseButton, label: l.expense),
            ]),
            const SizedBox(height: AppSpacing.sm),
            IncomeExpenseBars(
              key: ValueKey('${widget.year}-${widget.month}'),
              income: [for (final m in months) m.income],
              expense: [for (final m in months) m.expense],
              labels: [for (final m in months) monthShort(context, m.year, m.month).split(' ').first],
              selected: _selected,
              onSelect: (i) => setState(() => _selected = i),
            ),
          ]),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      FadeSlideIn(
        index: 1,
        child: Row(children: [
          Expanded(child: _Stat(label: l.avgIncome, amount: avgIncome, color: c.income)),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: _Stat(label: l.avgExpense, amount: avgExpense, color: c.expense)),
        ]),
      ),
      const SizedBox(height: AppSpacing.sm),
      FadeSlideIn(
        index: 2,
        child: AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(monthName(context, sel.year, sel.month), style: t.titleMedium),
            if (sel.saved > 0 && sel.saved == best) Text(l.bestMonthSaving, style: t.labelMedium?.copyWith(color: c.income)),
            const SizedBox(height: AppSpacing.xs),
            _Line(label: l.income, amount: Money.format(sel.income, showPlus: true), color: c.income),
            _Line(label: l.expense, amount: Money.format(-sel.expense), color: c.expense),
            Divider(height: 16, color: c.border),
            _Line(label: l.savedLabel, amount: Money.format(sel.saved), color: sel.saved >= 0 ? c.income : c.expense, bold: true),
          ]),
        ),
      ),
    ]);
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ]);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.amount, required this.color});

  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) => AppCard(
        radius: AppRadii.md,
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          CountUpAmount(paise: amount, color: color),
        ]),
      );
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.amount, required this.color, this.bold = false});

  final String label;
  final String amount;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(child: Text(label, style: bold ? t.titleSmall : t.bodyMedium)),
        AmountText(amount, size: bold ? 16 : 14, color: color, alignment: Alignment.centerRight),
      ]),
    );
  }
}
