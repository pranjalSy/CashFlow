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
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../shared/widgets/amount_text.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/charts.dart';
import '../../shared/widgets/month_pill.dart';
import '../../shared/widgets/motion.dart';
import '../../shared/widgets/number_pad.dart';
import '../../shared/widgets/overlays.dart';
import '../emi/emi_lock.dart';
import 'charts_controller.dart';
import 'charts_screen.dart';

/// Budget (FR-BG1–BG5, screen 21): monthly limit with a ring and per-day left, category limits.
/// Only expenses count. Alerts at 80% / 100% come with notifications (T19); the switch is saved now.
class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final premium = ref.watch(isPremiumProvider).value ?? false;
    final m = ref.watch(chartsMonthProvider);
    final budget = ref.watch(budgetProvider).value;
    final limits = ref.watch(budgetLimitsProvider).value ?? const <BudgetCategoryLimit>[];
    final spend = ref.watch(budgetSpendProvider((year: m.year, month: m.month))).value;
    final cats = ref.watch(categoriesByIdProvider).value ?? const <String, Category>{};

    return AppPage(
      child: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, AppSpacing.xl), children: [
          Row(children: [
            IconButton(onPressed: () => context.pop(), icon: Icon(LucideIcons.arrowLeft, color: c.text), tooltip: l.back),
            Expanded(child: Text(l.budget, style: t.titleLarge)),
            MonthPill(year: m.year, month: m.month, onShift: ref.read(chartsMonthProvider.notifier).shift),
          ]),
          const SizedBox(height: AppSpacing.sm),
          if (!premium)
            const EmiLockCard()
          else ...[
            FadeSlideIn(
              child: budget == null
                  ? AppCard(
                      onTap: () => showLimitSheet(context, average: spend?.overallAverage ?? 0),
                      child: ListRowTile(
                        leading: IconTile(icon: LucideIcons.target, color: c.brandText, tint: c.brandTint),
                        title: l.setMonthlyBudget,
                        subtitle: (spend?.overallAverage ?? 0) > 0 ? l.budgetSuggestion(Money.format(spend!.overallAverage)) : null,
                        trailing: Icon(LucideIcons.chevronRight, color: c.textMuted),
                      ),
                    )
                  : _Overview(year: m.year, month: m.month, limit: budget.monthlyLimit, spent: spend?.overall ?? 0, onTap: () {
                      showLimitSheet(context, current: budget.monthlyLimit, alert: budget.alertEnabled, average: spend?.overallAverage ?? 0);
                    }),
            ),
            SectionLabel(l.categoryLimits),
            for (final (i, lim) in limits.indexed)
              if (cats[lim.categoryId] != null)
                FadeSlideIn(
                  key: ValueKey(lim.id),
                  index: i + 1,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: _CategoryLimitRow(
                      category: cats[lim.categoryId]!,
                      limit: lim.limitAmount,
                      spent: spend?.byCategory[lim.categoryId] ?? 0,
                      onTap: () => showLimitSheet(context, category: cats[lim.categoryId], current: lim.limitAmount, alert: lim.alertEnabled),
                    ),
                  ),
                ),
            AppCard(
              radius: AppRadii.md,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              onTap: () async {
                final taken = {for (final x in limits) x.categoryId};
                final picked = await _pickCategory(context, ref, taken);
                if (picked != null && context.mounted) showLimitSheet(context, category: picked);
              },
              child: ListRowTile(
                leading: IconTile(icon: LucideIcons.plus, color: c.brandText, tint: c.brandTint, size: 34),
                title: l.addCategoryLimit,
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Future<Category?> _pickCategory(BuildContext context, WidgetRef ref, Set<String> taken) async {
    final all = await ref.read(categoryRepositoryProvider).ofKind('expense');
    if (!context.mounted) return null;
    final free = all.where((c) => !taken.contains(c.id)).toList();
    return showAppSheet<Category>(context, builder: (context) {
      final l = context.l10n;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.pickCategory, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Flexible(
            child: ListView(shrinkWrap: true, children: [
              for (final cat in free)
                ListRowTile(
                  leading: IconTile(icon: categoryIcon(cat.icon), color: Color(cat.color), tint: Color(cat.color).withValues(alpha: 0.16), size: 36),
                  title: categoryName(l, cat),
                  onTap: () => Navigator.pop(context, cat),
                ),
            ]),
          ),
        ]),
      );
    });
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.year, required this.month, required this.limit, required this.spent, required this.onTap});

  final int year;
  final int month;
  final int limit;
  final int spent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final band = budgetBand(spent, limit);
    final color = bandColor(context, band);
    final pct = limit == 0 ? 0 : (spent * 100 / limit).round();
    final today = Ist.today();
    final current = today.year == year && today.month == month;
    final left = limit - spent;
    final daysLeft = LocalDate.daysInMonth(year, month) - today.day + 1;
    final String footer;
    if (left < 0) {
      footer = l.amountOver(Money.format(-left));
    } else if (current) {
      footer = l.leftDaysPerDay(Money.format(left), daysLeft, Money.format(left ~/ daysLeft ~/ 100 * 100)); // whole rupees, rounded down
    } else {
      footer = l.amountLeft(Money.format(left));
    }
    return AppCard(
      onTap: onTap,
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(monthName(context, year, month), style: t.labelMedium),
            Text(l.spentThisMonth, style: t.bodySmall),
            CountUpAmount(paise: spent, size: 26),
            Text(l.ofLimit(Money.format(limit)), style: t.bodySmall),
            const SizedBox(height: 6),
            Text(footer, style: t.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
          ]),
        ),
        ProgressRing(
          key: ValueKey('$year-$month-$limit'),
          fraction: limit == 0 ? 0 : spent / limit,
          color: color,
          center: Text(l.percentOf(pct), style: t.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }
}

class _CategoryLimitRow extends StatelessWidget {
  const _CategoryLimitRow({required this.category, required this.limit, required this.spent, required this.onTap});

  final Category category;
  final int limit;
  final int spent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final color = bandColor(context, budgetBand(spent, limit));
    final left = limit - spent;
    final pct = limit == 0 ? 0 : (spent * 100 / limit).round();
    return AppCard(
      radius: AppRadii.md,
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: onTap,
      child: Row(children: [
        IconTile(icon: categoryIcon(category.icon), color: Color(category.color), tint: Color(category.color).withValues(alpha: 0.16), size: 36),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(categoryName(l, category), maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall)),
              Text(l.percentOf(pct), style: t.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
            ]),
            Text(l.budgetOfLimit(Money.format(spent), Money.format(limit)), style: t.bodySmall),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: limit == 0 ? 0 : (spent / limit).clamp(0, 1), minHeight: 5, color: color, backgroundColor: c.raised),
            ),
            const SizedBox(height: 4),
            Text(left < 0 ? l.amountOver(Money.format(-left)) : l.amountLeft(Money.format(left)), style: t.labelSmall?.copyWith(color: color)),
          ]),
        ),
      ]),
    );
  }
}

/// Limit sheet (FR-BG4): amount on a number pad, suggestions (3-month average and round numbers),
/// Alert me, Remove, Save. [category] null = the overall monthly budget.
Future<void> showLimitSheet(BuildContext context, {Category? category, int? current, bool alert = true, int average = 0}) {
  return showAppSheet<void>(context, builder: (_) => _LimitSheet(category: category, current: current, alert: alert, average: average));
}

class _LimitSheet extends ConsumerStatefulWidget {
  const _LimitSheet({this.category, this.current, required this.alert, required this.average});

  final Category? category;
  final int? current;
  final bool alert;
  final int average;

  @override
  ConsumerState<_LimitSheet> createState() => _LimitSheetState();
}

class _LimitSheetState extends ConsumerState<_LimitSheet> {
  late String _typed = widget.current == null ? '' : AmountTyping.fromPaise(widget.current!);
  late bool _alert = widget.alert;
  int _average = 0;
  bool _tried = false;

  @override
  void initState() {
    super.initState();
    _average = widget.average;
    final cat = widget.category;
    if (cat != null) {
      final m = ref.read(chartsMonthProvider);
      ref.read(chartsAverageProvider((categoryId: cat.id, year: m.year, month: m.month)).future).then((v) {
        if (mounted) setState(() => _average = v);
      });
    }
  }

  int get _paise => Money.parse(_typed) ?? 0;

  Future<void> _save() async {
    if (_paise <= 0) {
      setState(() => _tried = true);
      return;
    }
    final repo = ref.read(budgetRepositoryProvider);
    final cat = widget.category;
    cat == null ? await repo.setMonthly(_paise, alert: _alert) : await repo.setCategory(cat.id, _paise, alert: _alert);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _remove() async {
    final repo = ref.read(budgetRepositoryProvider);
    final cat = widget.category;
    cat == null ? await repo.removeMonthly() : await repo.removeCategory(cat.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final cat = widget.category;
    final title = cat == null ? l.monthlyBudgetTitle : l.categoryLimitTitle(categoryName(l, cat));
    final suggestions = limitSuggestions(_average);
    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, style: t.titleLarge),
        Text(l.everyMonth, style: t.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        AmountText('₹${Money.formatTyping(_typed)}', size: 36, color: c.text, alignment: Alignment.center),
        if (_tried && _paise <= 0) Text(l.enterAmount, textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: c.expense, fontWeight: FontWeight.w600)),
        if (_average > 0) Text(l.avgThreeMonths(Money.format(_average)), textAlign: TextAlign.center, style: t.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        if (suggestions.isNotEmpty)
          Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
            for (final s in suggestions)
              AppChip(label: Money.format(s), selected: _paise == s, onTap: () => setState(() => _typed = AmountTyping.fromPaise(s))),
          ]),
        const SizedBox(height: AppSpacing.xs),
        ListRowTile(
          leading: Icon(LucideIcons.bell, color: c.textSecondary),
          title: l.alertMe,
          subtitle: l.alertAt,
          trailing: AppToggle(value: _alert, onChanged: (v) => setState(() => _alert = v)),
        ),
        NumberPad(
          keyHeight: 42,
          onDigit: (d) => setState(() => _typed = AmountTyping.press(_typed, d)),
          onBackspace: () => setState(() => _typed = AmountTyping.backspace(_typed)),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          if (widget.current != null) ...[
            Expanded(child: AppButton(label: l.removeLabel, kind: AppButtonKind.secondary, onPressed: _remove)),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(flex: 2, child: AppButton(label: l.saveLimit, onPressed: _save)),
        ]),
      ]),
    );
  }
}
