import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/ui/labels.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../data/local/database.dart';
import '../../data/repositories/emi_repository.dart';
import '../../data/repositories/entry_repository.dart';
import '../../shared/widgets/amount_text.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/overlays.dart';
import '../../shared/widgets/payment_picker.dart';

/// Mark paid (FR-E11, screen 19): amount, Paid on (today), Paid via required with the last choice
/// pre-selected. Saves installment + EMI expense in one action, then a 5 s Undo snackbar.
/// Used from EMI detail and from the "Paid or not?" popup (FR-E7).
Future<void> showMarkPaidSheet(BuildContext context, {required EmiLoan emi, required EmiInstallment installment, required int total}) {
  return showAppSheet<void>(context, builder: (_) => _MarkPaidSheet(emi: emi, installment: installment, total: total));
}

class _MarkPaidSheet extends ConsumerStatefulWidget {
  const _MarkPaidSheet({required this.emi, required this.installment, required this.total});

  final EmiLoan emi;
  final EmiInstallment installment;
  final int total;

  @override
  ConsumerState<_MarkPaidSheet> createState() => _MarkPaidSheetState();
}

class _MarkPaidSheetState extends ConsumerState<_MarkPaidSheet> {
  LocalDate _paidOn = Ist.today();
  String? _mode;
  String? _method;
  bool _tried = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ref.read(entryRepositoryProvider).lastPayment('expense').then((p) {
      if (p != null && mounted && _mode == null) {
        setState(() {
          _mode = p.$1;
          _method = p.$2;
        });
      }
    });
  }

  Future<void> _save() async {
    if (_busy) return;
    if (_mode == null) {
      setState(() => _tried = true);
      return;
    }
    _busy = true;
    final l = context.l10n;
    final repo = ref.read(emiRepositoryProvider);
    final inst = widget.installment;
    final now = DateTime.now();
    final paidAt = _paidOn == Ist.today() ? now : Ist.instantOf(_paidOn, hour: 12);
    final batch = await repo.markPaid(inst.id, paidAt: paidAt, paymentMode: _mode!, onlineMethod: _method);
    if (!mounted) return;
    final nav = Navigator.of(context);
    CompactSnackbar.show(
      context,
      message: l.installmentPaid(inst.seq),
      detail: l.expenseAddedLeft(widget.total - inst.seq),
      actionLabel: l.undo,
      onAction: () => repo.undoMarkPaid(inst.id, batch),
    );
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final inst = widget.installment;
    final amount = Money.format(inst.amount);
    final today = Ist.today();
    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          IconTile(icon: emiIcon(widget.emi.icon), color: c.brandText, tint: c.brandTint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.markAsPaid, style: t.titleLarge),
              Text(l.installmentOf(inst.seq, widget.total, shortDate(context, LocalDate.parse(inst.dueDate))), style: t.bodySmall),
            ]),
          ),
        ]),
        const SizedBox(height: AppSpacing.sm),
        AmountText(amount, size: 36, color: c.expense, alignment: Alignment.center),
        const SizedBox(height: AppSpacing.sm),
        Material(
          color: c.raised,
          shape: AppShapes.squircle(AppRadii.md),
          child: InkWell(
            customBorder: AppShapes.squircle(AppRadii.md),
            onTap: () async {
              final now = DateTime.now();
              final d = await showDatePicker(context: context, initialDate: DateTime(_paidOn.year, _paidOn.month, _paidOn.day), firstDate: DateTime(2000), lastDate: now);
              if (d != null) setState(() => _paidOn = LocalDate(d.year, d.month, d.day));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                IconTile(icon: LucideIcons.calendar, color: c.textSecondary, tint: c.card, size: 34),
                const SizedBox(width: 12),
                // Small label above, the date below (screen 19).
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.paidOn, style: t.labelSmall),
                    Text(_paidOn == today ? '${l.today}, ${shortDate(context, _paidOn)}' : longDate(context, _paidOn), style: t.titleSmall),
                  ]),
                ),
                Icon(LucideIcons.chevronRight, color: c.textMuted),
              ]),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        PaymentPicker(
          label: l.paidVia,
          mode: _mode,
          method: _method,
          accent: c.income,
          accentTint: c.incomeTint,
          onlineIcon: LucideIcons.landmark,
          errorText: _tried && _mode == null ? l.choosePayment : null,
          onChanged: (m, method) => setState(() {
            _mode = m;
            _method = method;
          }),
        ),
        const SizedBox(height: AppSpacing.sm),
        _BoldWord(text: l.expenseAddedIn(amount, l.catEmi), bold: l.catEmi, style: t.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        AppButton(label: l.markPaid, icon: LucideIcons.check, kind: AppButtonKind.success, onPressed: _save),
      ]),
    );
  }
}

/// A paid installment opened from EMI detail: details, and "Mark as unpaid" on the last paid one.
Future<void> showPaidInstallmentSheet(BuildContext context, WidgetRef ref, {required EmiInstallment installment, required bool canUndo}) {
  return showAppSheet<void>(context, builder: (context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final paidOn = installment.paidAt == null ? null : Ist.dateOf(installment.paidAt!);
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(longDate(context, LocalDate.parse(installment.dueDate)), style: t.titleLarge),
      if (paidOn != null) Text(l.paidOnDate(longDate(context, paidOn)), style: t.bodySmall?.copyWith(color: c.income, fontWeight: FontWeight.w600)),
      const SizedBox(height: AppSpacing.sm),
      AmountText(Money.format(installment.amount), size: 32, alignment: Alignment.center),
      Center(child: Text(l.inclInterest(Money.format(installment.interestPart)), style: t.bodySmall)),
      const SizedBox(height: AppSpacing.md),
      if (canUndo)
        AppButton(
          label: l.markUnpaid,
          kind: AppButtonKind.secondary,
          onPressed: () async {
            await ref.read(emiRepositoryProvider).markUnpaid(installment.id);
            if (context.mounted) Navigator.pop(context);
          },
        )
      else
        AppButton(label: l.close, kind: AppButtonKind.secondary, onPressed: () => Navigator.pop(context)),
    ]);
  });
}

/// A centred sentence with one word in bold ("added in **EMI** category", screen 19).
class _BoldWord extends StatelessWidget {
  const _BoldWord({required this.text, required this.bold, this.style});

  final String text;
  final String bold;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final at = text.indexOf(bold);
    if (at < 0) return Text(text, textAlign: TextAlign.center, style: style);
    return Text.rich(
      TextSpan(style: style, children: [
        TextSpan(text: text.substring(0, at)),
        TextSpan(text: bold, style: TextStyle(fontWeight: FontWeight.w800, color: context.colors.text)),
        TextSpan(text: text.substring(at + bold.length)),
      ]),
      textAlign: TextAlign.center,
    );
  }
}
