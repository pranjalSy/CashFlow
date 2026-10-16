import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/ui/labels.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/emi_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../shared/widgets/motion.dart';
import '../../shared/widgets/amount_text.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/states.dart';
import '../../shared/widgets/summary_hero.dart';
import '../../shared/widgets/tab_page.dart';
import '../bills/bills_list.dart';
import 'emi_lock.dart';

final emiListProvider = StreamProvider<List<EmiWithInstallments>>((ref) => ref.watch(emiRepositoryProvider).watchAll());

/// EMI & Bills tab (screen 17): EMIs | Bills. Premium; Free users see the locked card.
class EmiBillsScreen extends ConsumerStatefulWidget {
  const EmiBillsScreen({super.key});

  @override
  ConsumerState<EmiBillsScreen> createState() => _EmiBillsScreenState();
}

class _EmiBillsScreenState extends ConsumerState<EmiBillsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final premium = ref.watch(isPremiumProvider).value ?? false;
    return TabPage(
      title: l.emiBillsTitle,
      children: [
        SegmentedSwitch(options: [l.emis, l.bills], index: _tab, expand: true, onChanged: (i) => setState(() => _tab = i)),
        const SizedBox(height: AppSpacing.md),
        if (!premium)
          const EmiLockCard()
        else if (_tab == 1)
          const BillsList()
        else
          const _EmiList(),
      ],
    );
  }
}

class _EmiList extends ConsumerWidget {
  const _EmiList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final list = ref.watch(emiListProvider).value;
    if (list == null) return const SizedBox.shrink();
    if (list.isEmpty) return AppCard(child: EmptyState(icon: LucideIcons.calendarSync, title: l.noEmisTitle, message: l.noEmisBody));
    final active = list.where((e) => !e.closed).toList();
    final closed = list.where((e) => e.closed).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FadeSlideIn(child: _Summary()),
        const SizedBox(height: AppSpacing.sm),
        for (final (i, e) in active.indexed)
          FadeSlideIn(
            key: ValueKey(e.emi.id),
            index: i + 1,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: EmiCard(item: e),
            ),
          ),
        if (closed.isNotEmpty) ...[
          SectionLabel(l.closed),
          for (final e in closed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: EmiCard(item: e),
            ),
        ],
      ],
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
        return StreamBuilder<EmiSummary>(
      stream: ref.watch(emiRepositoryProvider).watchSummary(Ist.today()),
      builder: (context, snap) {
        final s = snap.data;
        return SummaryHero(
          color: c.brandButton,
          label: l.dueThisMonth,
          paise: s?.dueThisMonth ?? 0,
          subtitle: s?.nextDue == null ? null : l.emiCountNext(s!.countThisMonth, shortDate(context, s.nextDue!)),
          icon: LucideIcons.bell,
        );
      },
    );
  }
}

/// One EMI on the list (FR-E5): name, lender, rate, EMI/month, progress, remaining, due tag.
class EmiCard extends ConsumerWidget {
  const EmiCard({super.key, required this.item});

  final EmiWithInstallments item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final e = item.emi;
    final rate = e.rateBp == 0 ? l.noCost : l.ratePerYear(rateText(e.rateBp));
    final sub = [?e.lender, rate].join(' · ');
    final progress = item.total == 0 ? 0.0 : item.paidCount / item.total;
    final next = item.nextDue;
    return AppCard(
      radius: AppRadii.lg,
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/emi/${e.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: emiIcon(e.icon), color: item.closed ? c.income : c.brandText, tint: item.closed ? c.incomeTint : c.brandTint),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall),
                    Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AmountText(Money.format(e.emiAmount), size: 15, alignment: Alignment.centerRight),
                  Text(l.perMonth, style: t.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: progress, minHeight: 6, color: item.closed ? c.incomeButton : c.brandButton, backgroundColor: c.raised),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: item.closed ? l.emiClosed : l.paidOfTotal(item.paidCount, item.total), style: t.bodySmall?.copyWith(color: c.text, fontWeight: FontWeight.w700)),
                    if (!item.closed) TextSpan(text: ' · ${l.leftCount(item.total - item.paidCount)}', style: t.bodySmall),
                  ]),
                ),
              ),
              if (item.closed)
                EmiTag(text: l.closed, color: c.income, tint: c.incomeTint, icon: LucideIcons.check)
              else if (next != null)
                dueTag(context, LocalDate.parse(next.dueDate), short: true),
            ],
          ),
          if (!item.closed)
            StreamBuilder<int>(
              stream: ref.watch(emiRepositoryProvider).watchRemaining(e.id),
              builder: (context, snap) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(l.remainingAmount(Money.formatWhole(snap.data ?? 0)), style: t.titleSmall?.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Due tag: orange under 7 days, red when late, plain otherwise (FR-E5).
/// [next]: the next installment on EMI detail is always orange (screen 19).
Widget dueTag(BuildContext context, LocalDate due, {bool short = false, bool next = false}) {
  final l = context.l10n;
  final c = context.colors;
  final days = Ist.today().daysUntil(due);
  if (days < 0) return EmiTag(text: l.overdueDays(-days), color: c.expense, tint: c.expenseTint, icon: LucideIcons.clock);
  final text = short && days > 1 ? l.dueOnDate(shortDate(context, due)) : l.dueInDays(days);
  if (days < 7 || next) return EmiTag(text: text, color: c.dueSoon, tint: c.dueSoonTint, icon: next ? null : LucideIcons.calendar);
  return EmiTag(text: text, color: c.textSecondary, tint: c.raised, icon: LucideIcons.calendar);
}

class EmiTag extends StatelessWidget {
  const EmiTag({super.key, required this.text, required this.color, required this.tint, this.icon});

  final String text;
  final Color color;
  final Color tint;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ShapeDecoration(color: tint, shape: AppShapes.squircle(AppRadii.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
