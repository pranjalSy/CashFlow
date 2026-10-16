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
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/motion.dart';
import '../../shared/widgets/overlays.dart';
import '../../shared/widgets/states.dart';
import '../emi/emi_bills_screen.dart';
import 'bill_labels.dart';
import 'pay_bill_sheet.dart';

/// Bill detail (FR-B7): next due, gap, Mark paid, payment history; ⋯ = Edit, Pause/Resume, Delete.
class BillDetailScreen extends ConsumerWidget {
  const BillDetailScreen({super.key, required this.billId});

  final String billId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ok = await showAppSheet<bool>(context, builder: (context) {
      final c = context.colors;
      final t = Theme.of(context).textTheme;
      return Column(mainAxisSize: MainAxisSize.min, children: [
        IconTile(icon: LucideIcons.trash2, color: c.expense, tint: c.expenseTint, size: 56),
        const SizedBox(height: AppSpacing.sm),
        Text(l.deleteBillTitle, textAlign: TextAlign.center, style: t.titleLarge),
        const SizedBox(height: 6),
        Text(l.deleteBillBody, textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: c.textSecondary)),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(child: AppButton(label: l.cancel, kind: AppButtonKind.secondary, onPressed: () => Navigator.pop(context, false))),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: AppButton(label: l.delete, kind: AppButtonKind.danger, onPressed: () => Navigator.pop(context, true))),
        ]),
      ]);
    });
    if (ok != true || !context.mounted) return;
    await ref.read(billRepositoryProvider).delete(billId);
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return AppPage(
      child: SafeArea(
        child: StreamBuilder<BillWithPayments?>(
          stream: ref.watch(billRepositoryProvider).watchOne(billId),
          builder: (context, snap) {
            final item = snap.data;
            if (item == null) return const SizedBox.shrink();
            final b = item.bill;
            final (fg, bg) = billColors(context, b.billType);
            return ListView(padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, AppSpacing.xl), children: [
              Row(children: [
                IconButton(onPressed: () => context.pop(), icon: Icon(LucideIcons.arrowLeft, color: c.text), tooltip: l.back),
                Expanded(child: Center(child: Text(billTypeName(l, b.billType), style: t.titleLarge))),
                PopupMenuButton<int>(
                  tooltip: l.more,
                  icon: Icon(LucideIcons.ellipsis, color: c.text),
                  color: c.sheet,
                  onSelected: (v) => switch (v) {
                    0 => context.push('/bills/${b.id}/edit'),
                    1 => ref.read(billRepositoryProvider).setPaused(b.id, !b.paused),
                    _ => _delete(context, ref),
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 0, child: Text(l.editBill)),
                    PopupMenuItem(value: 1, child: Text(b.paused ? l.resumeBill : l.pauseBill)),
                    PopupMenuItem(value: 2, child: Text(l.deleteBill, style: TextStyle(color: c.expense))),
                  ],
                ),
              ]),
              const SizedBox(height: AppSpacing.xs),
              FadeSlideIn(
                child: AppCard(
                  radius: AppRadii.lg,
                  child: Column(children: [
                    IconTile(icon: billIcon(b.billType), color: fg, tint: bg, size: 56),
                    const SizedBox(height: AppSpacing.xs),
                    Text(b.name, textAlign: TextAlign.center, style: t.titleLarge),
                    Text(
                      [l.everyNMonths(b.everyMonths), ?b.customerId].join(' · '),
                      textAlign: TextAlign.center,
                      style: t.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ListRowTile(
                      leading: IconTile(icon: LucideIcons.calendar, color: c.textSecondary, tint: c.raised, size: 34),
                      title: longDate(context, item.nextDue),
                      subtitle: l.nextDue,
                      trailing: b.paused ? null : dueTag(context, item.nextDue),
                    ),
                    if (b.paused) Text(l.billPausedNote, textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: c.textSecondary)),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(label: l.markPaid, kind: AppButtonKind.success, onPressed: () => showPayBillSheet(context, bill: b)),
                  ]),
                ),
              ),
              SectionLabel(l.payments),
              if (item.payments.isEmpty) AppCard(child: EmptyState(icon: LucideIcons.receipt, title: l.noPaymentsYet, message: l.addedToCategory(l.catBills))),
              for (final (i, p) in item.payments.indexed)
                FadeSlideIn(
                  index: i + 1,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: AppCard(
                      radius: AppRadii.md,
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Row(children: [
                        Icon(LucideIcons.circleCheck, color: c.income, size: 22),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(l.monthBill(monthName(context, LocalDate.parse(p.dueDate).year, LocalDate.parse(p.dueDate).month)), style: t.titleSmall),
                            Text(l.paidOnDate(shortDate(context, Ist.dateOf(p.paidAt))), style: t.bodySmall),
                          ]),
                        ),
                        AmountText('${Money.minus}${Money.format(p.amount)}', size: 14, color: c.expense, alignment: Alignment.centerRight),
                      ]),
                    ),
                  ),
                ),
            ]);
          },
        ),
      ),
    );
  }
}
