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
import '../../data/repositories/bill_repository.dart';
import '../../shared/widgets/amount_text.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/motion.dart';
import '../../shared/widgets/states.dart';
import '../../shared/widgets/summary_hero.dart';
import '../emi/emi_bills_screen.dart';
import 'bill_labels.dart';
import 'pay_bill_sheet.dart';

final billListProvider = StreamProvider<List<BillWithPayments>>((ref) => ref.watch(billRepositoryProvider).watchAll());

/// Bills on the EMI & Bills tab (FR-B7, screen 17): summary, "This month", "Later".
class BillsList extends ConsumerWidget {
  const BillsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final list = ref.watch(billListProvider).value;
    if (list == null) return const SizedBox.shrink();
    if (list.isEmpty) return EmptyState(icon: billIcon('electricity'), title: l.noBillsTitle, message: l.noBillsBody, actionLabel: l.addBill, onAction: () => context.push('/bills/new'));
    final today = Ist.today();
    final end = LocalDate(today.year, today.month, LocalDate.daysInMonth(today.year, today.month));
    bool thisMonth(BillWithPayments b) => !b.nextDue.isAfter(end) || b.paidIn(today);
    final now = list.where(thisMonth).toList();
    final later = list.where((b) => !thisMonth(b)).toList();
    var i = 0;
    Widget card(BillWithPayments b) => FadeSlideIn(
          key: ValueKey(b.bill.id),
          index: ++i,
          child: Padding(padding: const EdgeInsets.only(bottom: AppSpacing.xs), child: BillCard(item: b)),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const FadeSlideIn(child: _Summary()),
      if (now.isNotEmpty) ...[SectionLabel(l.thisMonth), for (final b in now) card(b)],
      if (later.isNotEmpty) ...[SectionLabel(l.later), for (final b in later) card(b)],
    ]);
  }
}

class _Summary extends ConsumerWidget {
  const _Summary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    return StreamBuilder<BillSummary>(
      stream: ref.watch(billRepositoryProvider).watchSummary(Ist.today()),
      builder: (context, snap) {
        final s = snap.data;
        return SummaryHero(
          color: c.borrowed,
          label: l.billsThisMonth,
          paise: s?.total ?? 0,
          subtitle: l.billsPaidLeft(s?.paid ?? 0, s?.left ?? 0),
          icon: LucideIcons.zap,
        );
      },
    );
  }
}

/// One bill: icon, type and provider, gap, last amount and a tag (Due today / Due in X days / Paid / Paused).
class BillCard extends StatelessWidget {
  const BillCard({super.key, required this.item});

  final BillWithPayments item;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final b = item.bill;
    final (fg, bg) = billColors(context, b.billType);
    final today = Ist.today();
    final amount = item.lastAmount;
    final dueToday = !b.paused && !item.nextDue.isAfter(today);
    final paidNow = item.paidIn(today) && item.nextDue.isAfter(LocalDate(today.year, today.month, LocalDate.daysInMonth(today.year, today.month)));
    // FR-B7 tags: Due today (orange solid), Due in X days / Due 20 Oct (plain), Paid (green).
    final Widget tag;
    if (b.paused) {
      tag = EmiTag(text: l.pausedTag, color: c.textSecondary, tint: c.raised);
    } else if (paidNow) {
      tag = EmiTag(text: l.paid, color: c.income, tint: c.incomeTint, icon: LucideIcons.check);
    } else if (dueToday) {
      final late = today.daysUntil(item.nextDue) < 0;
      tag = EmiTag(text: late ? l.overdueDays(-today.daysUntil(item.nextDue)) : l.dueInDays(0), color: c.onButton, tint: late ? c.expenseButton : c.dueSoon);
    } else {
      final days = today.daysUntil(item.nextDue);
      tag = EmiTag(text: days == 1 ? l.dueInDays(1) : l.dueOnDate(shortDate(context, item.nextDue)), color: c.textSecondary, tint: c.raised, icon: LucideIcons.calendar);
    }
    return AppCard(
      radius: AppRadii.lg,
      padding: const EdgeInsets.all(14),
      // A bill due today opens "How much was it?" straight away ("tap Paid to confirm").
      onTap: () => dueToday ? showPayBillSheet(context, bill: b) : context.push('/bills/${b.id}'),
      child: Row(children: [
        IconTile(icon: billIcon(b.billType), color: fg, tint: bg),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(billTypeName(l, b.billType), maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall),
            Text('${b.name} · ${l.everyNMonths(b.everyMonths)}', maxLines: 2, overflow: TextOverflow.ellipsis, style: t.bodySmall),
            if (dueToday && amount != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(l.billTapPaid(Money.format(amount)), style: t.bodySmall?.copyWith(color: c.dueSoon, fontWeight: FontWeight.w600)),
              ),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
          if (amount != null) AmountText(Money.format(amount), size: 15, alignment: Alignment.centerRight),
          const SizedBox(height: 4),
          tag,
        ]),
      ]),
    );
  }
}
