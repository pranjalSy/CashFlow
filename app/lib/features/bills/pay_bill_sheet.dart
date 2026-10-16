import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/ui/labels.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../data/local/database.dart';
import '../../data/repositories/bill_repository.dart';
import '../../data/repositories/entry_repository.dart';
import '../../shared/widgets/amount_text.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/number_pad.dart';
import '../../shared/widgets/overlays.dart';
import '../../shared/widgets/payment_picker.dart';
import 'bill_labels.dart';

/// "Yes, paid" (FR-B4, screen 20 step 4): last 3 bill amounts as chips (newest chosen), or "Other
/// amount" on a number pad; Paid via required (last choice pre-selected). Save = Bills expense + next date.
Future<void> showPayBillSheet(BuildContext context, {required Bill bill}) {
  return showAppSheet<void>(context, builder: (_) => _PayBillSheet(bill: bill));
}

class _PayBillSheet extends ConsumerStatefulWidget {
  const _PayBillSheet({required this.bill});

  final Bill bill;

  @override
  ConsumerState<_PayBillSheet> createState() => _PayBillSheetState();
}

class _PayBillSheetState extends ConsumerState<_PayBillSheet> {
  List<BillSuggestion>? _suggestions;
  int? _chosen; // index into suggestions; null = other amount
  String _other = '';
  String? _mode;
  String? _method;
  bool _tried = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ref.read(billRepositoryProvider).suggestions(widget.bill.id).then((s) {
      if (mounted) {
        setState(() {
          _suggestions = s;
          _chosen = s.isEmpty ? null : 0;
        });
      }
    });
    ref.read(entryRepositoryProvider).lastPayment('expense').then((p) {
      if (p != null && mounted && _mode == null) {
        setState(() {
          _mode = p.$1;
          _method = p.$2;
        });
      }
    });
  }

  int get _amount => _chosen != null ? _suggestions![_chosen!].amount : (Money.parse(_other) ?? 0);

  Future<void> _save() async {
    if (_busy) return;
    if (_amount <= 0 || _mode == null) {
      setState(() => _tried = true);
      return;
    }
    _busy = true;
    await ref.read(billRepositoryProvider).markPaid(widget.bill.id, amount: _amount, paidAt: DateTime.now(), paymentMode: _mode!, onlineMethod: _method);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final b = widget.bill;
    final s = _suggestions;
    final other = s != null && _chosen == null;
    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        BillHeader(bill: b),
        const SizedBox(height: AppSpacing.sm),
        Text(l.howMuchWasIt, style: t.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        if (s != null)
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final (i, x) in s.indexed)
              _AmountChip(
                amount: Money.format(x.amount),
                caption: x.dueDate == null ? l.usualLabel : l.monthBill(monthShort(context, x.dueDate!.year, x.dueDate!.month).split(' ').first),
                selected: _chosen == i,
                onTap: () => setState(() => _chosen = i),
              ),
            _AmountChip(amount: l.otherAmount, selected: other, onTap: () => setState(() => _chosen = null)),
          ]),
        if (other) ...[
          const SizedBox(height: AppSpacing.xs),
          AmountText('₹${Money.formatTyping(_other)}', size: 34, color: c.expense, alignment: Alignment.center),
          if (_tried && _amount <= 0)
            Text(l.enterAmount, textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: c.expense, fontWeight: FontWeight.w600)),
          NumberPad(
            keyHeight: 42,
            onDigit: (d) => setState(() => _other = AmountTyping.press(_other, d)),
            onBackspace: () => setState(() => _other = AmountTyping.backspace(_other)),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        PaymentPicker(
          label: l.paidVia,
          mode: _mode,
          method: _method,
          accent: c.expense,
          accentTint: c.expenseTint,
          errorText: _tried && _mode == null ? l.choosePayment : null,
          onChanged: (m, method) => setState(() {
            _mode = m;
            _method = method;
          }),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(label: l.saveAmount(Money.format(_amount)), kind: AppButtonKind.success, onPressed: _save),
        const SizedBox(height: 6),
        Text(l.addedToCategory(l.catBills), textAlign: TextAlign.center, style: t.bodySmall),
      ]),
    );
  }
}

/// Icon, "Bill due today", name and "Due 15 Nov · every 2 months" (popup and pay sheet).
class BillHeader extends StatelessWidget {
  const BillHeader({super.key, required this.bill, this.showDueLabel = true});

  final Bill bill;
  final bool showDueLabel;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final (fg, bg) = billColors(context, bill.billType);
    final due = LocalDate.parse(bill.nextDueDate);
    final late = Ist.today().daysUntil(due) < 0;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      IconTile(icon: billIcon(bill.billType), color: fg, tint: bg, size: 56),
      const SizedBox(height: AppSpacing.xs),
      if (showDueLabel)
        Text(late ? l.overdueDays(-Ist.today().daysUntil(due)) : l.billDueToday,
            style: t.labelMedium?.copyWith(color: late ? c.expense : c.dueSoon, fontWeight: FontWeight.w700)),
      Text('${billTypeName(l, bill.billType)} · ${bill.name}', textAlign: TextAlign.center, style: t.titleLarge),
      Text(l.billDueInfo(shortDate(context, due), l.everyNMonths(bill.everyMonths)), textAlign: TextAlign.center, style: t.bodySmall),
    ]);
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({required this.amount, this.caption, required this.selected, required this.onTap});

  final String amount;
  final String? caption;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final shape = AppShapes.squircle(AppRadii.md, side: BorderSide(color: selected ? c.expense : c.border, width: selected ? 2 : 1));
    return Material(
      color: selected ? c.expenseTint : c.card,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52, minWidth: 92),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(amount, style: t.titleSmall?.copyWith(color: selected ? c.expense : c.text)),
              if (caption != null) Text(caption!, style: t.labelSmall),
            ]),
          ),
        ),
      ),
    );
  }
}
