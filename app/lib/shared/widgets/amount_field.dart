import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/utils/money.dart';
import 'amount_text.dart';

/// A tappable money field showing what is typed on the number pad ("₹1,20,000.5").
class AmountField extends StatelessWidget {
  const AmountField({super.key, required this.label, required this.typed, required this.active, required this.onTap, this.icon, this.error = false});

  final String label;
  final String typed;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final border = error ? c.expense : (active ? c.brandButton : c.border);
    final shape = AppShapes.squircle(AppRadii.md, side: BorderSide(color: border, width: active || error ? 2 : 1));
    return Material(
      color: c.card,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            if (icon != null) ...[Icon(icon, color: c.textSecondary, size: 20), const SizedBox(width: 10)],
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: t.labelMedium),
                AmountText('₹${Money.formatTyping(typed)}', size: 22, color: typed.isEmpty ? c.textMuted : c.text),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
