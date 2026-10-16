import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/utils/dates.dart';
import '../../data/local/database.dart';
import '../../data/repositories/bill_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/overlays.dart';
import 'pay_bill_sheet.dart';

/// On app open, "Did you pay this bill?" for each bill that is due (FR-B2). Yes, paid opens the pay
/// sheet; Not yet asks again tomorrow. Premium only; paused bills never ask.
Future<void> askDueBills(BuildContext context, WidgetRef ref) async {
  if (!await ref.read(planRepositoryProvider).isPremium()) return;
  final repo = ref.read(billRepositoryProvider);
  final due = await repo.dueToAsk(Ist.today());
  for (final b in due) {
    if (!context.mounted) return;
    final paid = await showAppPopup<bool>(context, builder: (_) => BillDuePopup(bill: b));
    if (!context.mounted) return;
    if (paid == true) {
      await showPayBillSheet(context, bill: b);
    } else {
      await repo.askAgainTomorrow(b.id, Ist.today());
    }
  }
}

class BillDuePopup extends StatelessWidget {
  const BillDuePopup({super.key, required this.bill});

  final Bill bill;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      BillHeader(bill: bill),
      const SizedBox(height: AppSpacing.sm),
      Text(l.didYouPayBill, textAlign: TextAlign.center, style: t.titleMedium),
      const SizedBox(height: AppSpacing.sm),
      AppButton(label: l.yesPaid, kind: AppButtonKind.success, onPressed: () => Navigator.pop(context, true)),
      const SizedBox(height: AppSpacing.xs),
      AppButton(label: l.notYet, kind: AppButtonKind.secondary, onPressed: () => Navigator.pop(context, false)),
      const SizedBox(height: 6),
      Text(l.notYetTomorrow, textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: c.textMuted)),
    ]);
  }
}
