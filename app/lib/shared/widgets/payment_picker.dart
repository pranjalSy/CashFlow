import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';

/// Paid via / Received in: Cash or Online → UPI / Card / Bank (F2). Required everywhere money moves.
class PaymentPicker extends StatelessWidget {
  const PaymentPicker({
    super.key,
    required this.label,
    required this.mode,
    required this.method,
    required this.onChanged,
    required this.accent,
    required this.accentTint,
    this.errorText,
  });

  final String label;

  /// `cash`, `online` or null (not chosen yet).
  final String? mode;
  final String? method;
  final void Function(String mode, String? method) onChanged;
  final Color accent;
  final Color accentTint;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final error = errorText != null;
    Widget option(String value, IconData icon, String text) {
      final on = mode == value;
      final shape = AppShapes.squircle(AppRadii.sm, side: BorderSide(color: on ? accent : (error ? c.expense : c.border), width: 1.5));
      return Expanded(
        child: Material(
          color: on ? accentTint : (error ? c.expenseTint : c.card),
          shape: shape,
          child: InkWell(
            customBorder: shape,
            onTap: () => onChanged(value, value == 'online' ? (method ?? 'upi') : null),
            child: SizedBox(
              height: 48,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 18, color: on ? accent : c.textSecondary),
                const SizedBox(width: 8),
                Text(text, style: t.titleSmall?.copyWith(color: on ? accent : c.textSecondary, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ),
      );
    }

    Widget sub(String value, String text) {
      final on = method == value;
      return Expanded(
        child: Material(
          color: on ? (Theme.of(context).brightness == Brightness.dark ? c.raised : c.text) : c.raised,
          shape: AppShapes.squircle(AppRadii.xs),
          child: InkWell(
            customBorder: AppShapes.squircle(AppRadii.xs),
            onTap: () => onChanged('online', value),
            child: SizedBox(
              height: 40,
              child: Center(
                child: Text(text, style: t.labelMedium?.copyWith(color: on ? (Theme.of(context).brightness == Brightness.dark ? c.text : c.card) : c.textSecondary, fontWeight: on ? FontWeight.w700 : FontWeight.w600)),
              ),
            ),
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Row(children: [
          Text(label, style: t.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: ShapeDecoration(color: c.raised, shape: AppShapes.squircle(AppRadii.pill)),
            child: Text(l.required, style: t.labelSmall?.copyWith(fontSize: 10)),
          ),
        ]),
      ),
      Row(children: [
        option('cash', Icons.payments_outlined, l.cash),
        const SizedBox(width: AppSpacing.xs),
        option('online', Icons.smartphone_outlined, l.online),
      ]),
      if (mode == 'online') ...[
        const SizedBox(height: AppSpacing.xs),
        Row(children: [
          sub('upi', l.upi),
          const SizedBox(width: 6),
          sub('card', l.card),
          const SizedBox(width: 6),
          sub('bank', l.bank),
        ]),
      ],
      if (error)
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 6),
          child: Text(errorText!, style: t.bodySmall?.copyWith(color: c.expense, fontWeight: FontWeight.w600)),
        ),
    ]);
  }
}
