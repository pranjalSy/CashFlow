import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/ui/labels.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../data/local/database.dart';
import '../../data/repositories/emi_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/overlays.dart';
import 'mark_paid_sheet.dart';

/// On app open, "Paid or not?" for each EMI installment that is due (FR-E6, FR-E7, I4).
/// Paid opens the Mark paid sheet (Paid via is required); Not yet asks again next open.
Future<void> askDueEmis(BuildContext context, WidgetRef ref) async {
  if (!await ref.read(planRepositoryProvider).isPremium()) return;
  final due = await ref.read(emiRepositoryProvider).dueToAsk(Ist.today());
  for (final (emi, inst) in due) {
    if (!context.mounted) return;
    final paid = await showAppPopup<bool>(context, builder: (_) => EmiDuePopup(emi: emi, installment: inst));
    if (paid == true && context.mounted) await showMarkPaidSheet(context, emi: emi, installment: inst, total: emi.months);
  }
}

class EmiDuePopup extends StatelessWidget {
  const EmiDuePopup({super.key, required this.emi, required this.installment});

  final EmiLoan emi;
  final EmiInstallment installment;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final due = LocalDate.parse(installment.dueDate);
    final late = Ist.today().daysUntil(due) < 0;
    final info = [l.installmentOf(installment.seq, emi.months, shortDate(context, due)), ?emi.lender].join(' · ');
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Center(child: IconTile(icon: emiIcon(emi.icon), color: c.brandText, tint: c.brandTint, size: 56)),
      const SizedBox(height: AppSpacing.xs),
      Text(late ? l.overdueDays(-Ist.today().daysUntil(due)) : l.emiDueToday,
          textAlign: TextAlign.center, style: t.labelMedium?.copyWith(color: late ? c.expense : c.dueSoon, fontWeight: FontWeight.w700)),
      Text('${emi.name} · ${Money.format(installment.amount)}', textAlign: TextAlign.center, style: t.titleLarge),
      Text(info, textAlign: TextAlign.center, style: t.bodySmall),
      const SizedBox(height: AppSpacing.sm),
      Text(l.paidOrNot, textAlign: TextAlign.center, style: t.titleMedium),
      const SizedBox(height: AppSpacing.sm),
      Row(children: [
        Expanded(child: AppButton(label: l.notYet, kind: AppButtonKind.secondary, onPressed: () => Navigator.pop(context, false))),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: AppButton(label: l.paid, kind: AppButtonKind.success, onPressed: () => Navigator.pop(context, true))),
      ]),
      const SizedBox(height: AppSpacing.xs),
      DecoratedBox(
        decoration: ShapeDecoration(color: c.raised, shape: AppShapes.squircle(AppRadii.sm)),
        child: Padding(padding: const EdgeInsets.all(10), child: Text(l.paidAddsExpense, textAlign: TextAlign.center, style: t.bodySmall)),
      ),
    ]);
  }
}
