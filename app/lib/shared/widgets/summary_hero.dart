import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import 'motion.dart';

/// Coloured summary card on top of a tab (screens 17, 19): label, big amount, a line below and a
/// small frosted icon box on the right, with a soft glow of the card colour.
class SummaryHero extends StatelessWidget {
  const SummaryHero({super.key, required this.color, required this.label, required this.paise, this.subtitle, this.icon, this.whole = true});

  final Color color;
  final String label;
  final int paise;
  final String? subtitle;
  final IconData? icon;

  /// Show whole rupees (screen 17 "₹12,895").
  final bool whole;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final on = c.onButton;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: color,
        shape: AppShapes.squircle(AppRadii.lg),
        shadows: dark ? null : [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 24, offset: const Offset(0, 10), spreadRadius: -10)],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: t.bodySmall?.copyWith(color: on.withValues(alpha: 0.9))),
              const SizedBox(height: 4),
              CountUpAmount(paise: whole ? (paise / 100).round() * 100 : paise, size: 28, color: on),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: t.bodySmall?.copyWith(color: on.withValues(alpha: 0.88))),
              ],
            ]),
          ),
          if (icon != null)
            Container(
              width: 44,
              height: 44,
              decoration: ShapeDecoration(color: on.withValues(alpha: 0.18), shape: AppShapes.squircle(AppRadii.sm)),
              child: Icon(icon, color: on, size: 20),
            ),
        ]),
      ),
    );
  }
}
