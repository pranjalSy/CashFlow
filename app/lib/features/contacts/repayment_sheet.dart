import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/debt_repository.dart';
import '../../shared/widgets/amount_text.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/number_pad.dart';
import '../../shared/widgets/overlays.dart';
import '../../shared/widgets/payment_picker.dart';

/// Repayment (FR-D2, G5–G8). More than the remaining amount is allowed: the udhar is settled,
/// the sheet stays open showing "Payment saved", and a snackbar asks to add the extra.
Future<void> showRepaymentSheet(BuildContext context, {required String personName, required List<DebtWithPayments> debts, required bool premium}) {
  return showAppSheet<void>(context, builder: (_) => _RepaymentSheet(personName: personName, debts: debts, premium: premium));
}

class _RepaymentSheet extends ConsumerStatefulWidget {
  const _RepaymentSheet({required this.personName, required this.debts, required this.premium});

  final String personName;
  final List<DebtWithPayments> debts;
  final bool premium;

  @override
  ConsumerState<_RepaymentSheet> createState() => _RepaymentSheetState();
}

class _RepaymentSheetState extends ConsumerState<_RepaymentSheet> {
  late DebtWithPayments _debt = (widget.debts.toList()..sort((a, b) => a.debt.occurredAt.compareTo(b.debt.occurredAt))).first;
  String _amount = '';
  String? _mode;
  String? _method;
  bool _tried = false;
  bool _saved = false;

  int get _paise => Money.parse(_amount) ?? 0;

  Future<void> _save() async {
    if (_saved) return;
    if (_paise <= 0 || _mode == null) {
      setState(() => _tried = true);
      return;
    }
    final l = context.l10n;
    final repo = ref.read(debtRepositoryProvider);
    final r = await repo.recordRepayment(debtId: _debt.debt.id, amount: _paise, occurredAt: DateTime.now(), paymentMode: _mode!, onlineMethod: _method);
    if (!mounted) return;
    setState(() => _saved = true);
    if (r.extra > 0) {
      final extra = Money.format(r.extra);
      CompactSnackbar.show(
        context,
        message: _debt.lent ? l.extraAsBorrowed(extra) : l.extraAsLent(extra),
        actionLabel: l.yes,
        onAction: () => repo.addExtraAsDebt(_debt.debt.id, premium: widget.premium),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final remaining = _debt.remaining;
    final lent = _debt.lent;
    final over = _paise > remaining;
    final accent = lent ? c.income : c.expense;
    final short = MediaQuery.sizeOf(context).height < 720;
    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.repaymentTitle, style: t.titleLarge),
        Text(lent ? l.repaymentFrom(widget.personName) : l.repaymentTo(widget.personName), style: t.bodySmall),
        if (widget.debts.length > 1) ...[
          const SizedBox(height: AppSpacing.xs),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final d in widget.debts)
              AppChip(
                label: '${d.lent ? l.lent : l.borrowed} ${Money.format(d.debt.amount)}',
                selected: d.debt.id == _debt.debt.id,
                onTap: _saved ? () {} : () => setState(() => _debt = d),
              ),
          ]),
        ],
        const SizedBox(height: AppSpacing.sm),
        AmountText('₹${Money.formatTyping(_amount)}', size: 40, color: accent, alignment: Alignment.center),
        Center(child: Text(l.remainingNow(Money.format(remaining)), style: t.bodySmall)),
        if (_tried && _paise <= 0)
          Center(child: Text(l.enterAmount, style: t.bodySmall?.copyWith(color: c.expense, fontWeight: FontWeight.w600))),
        if (over) ...[
          const SizedBox(height: AppSpacing.xs),
          DecoratedBox(
            decoration: ShapeDecoration(color: c.raised, shape: AppShapes.squircle(AppRadii.sm)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(children: [
                _SumRow(label: l.udharRepaid, amount: Money.format(remaining)),
                _SumRow(label: l.extraAmount, amount: Money.format(_paise - remaining), color: c.brandText),
                Divider(height: 10, color: c.border),
                _SumRow(label: l.totalAmount, amount: Money.format(_paise), bold: true),
              ]),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        PaymentPicker(
          label: lent ? l.receivedIn : l.paidVia,
          mode: _mode,
          method: _method,
          accent: accent,
          accentTint: lent ? c.incomeTint : c.expenseTint,
          errorText: _tried && _mode == null ? (lent ? l.chooseReceived : l.choosePayment) : null,
          onChanged: (m, method) => setState(() {
            _mode = m;
            _method = method;
          }),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!_saved)
          NumberPad(
            keyHeight: short ? 42 : 48,
            onDigit: (d) => setState(() => _amount = AmountTyping.press(_amount, d)),
            onBackspace: () => setState(() => _amount = AmountTyping.backspace(_amount)),
          ),
        const SizedBox(height: AppSpacing.xs),
        AppButton(
          label: _saved ? l.paymentSaved : l.savePayment,
          icon: _saved ? LucideIcons.check : null,
          kind: AppButtonKind.success,
          onPressed: _saved ? () => Navigator.pop(context) : _save,
        ),
      ]),
    );
  }
}

class _SumRow extends StatelessWidget {
  const _SumRow({required this.label, required this.amount, this.color, this.bold = false});

  final String label;
  final String amount;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Expanded(child: Text(label, style: bold ? t.titleSmall : t.bodyMedium)),
        AmountText(amount, color: color, size: bold ? 15 : 14, alignment: Alignment.centerRight),
      ]),
    );
  }
}

