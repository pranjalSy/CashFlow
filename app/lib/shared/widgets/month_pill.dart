import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/ui/labels.dart';

/// Compact month picker pill (Home, Charts, Budget): ‹ Oct 2026 ›.
class MonthPill extends StatelessWidget {
  const MonthPill({super.key, required this.year, required this.month, required this.onShift});

  final int year;
  final int month;

  /// −1 for the previous month, +1 for the next.
  final ValueChanged<int> onShift;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final loc = MaterialLocalizations.of(context);
    // Compact pill like the mockup. Two invisible halves over it (each about 60 × 48 dp) go to the
    // previous / next month, so the targets stay large while the pill stays small.
    return SizedBox(
      height: 48,
      child: Stack(alignment: Alignment.center, children: [
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: ShapeDecoration(color: c.card, shape: AppShapes.squircle(AppRadii.pill)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(LucideIcons.chevronLeft, size: 18, color: c.textSecondary),
            const SizedBox(width: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, a) => FadeTransition(opacity: a, child: child),
              child: Text(
                monthShort(context, year, month),
                key: ValueKey(year * 12 + month),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 6),
            Icon(LucideIcons.chevronRight, size: 18, color: c.textSecondary),
          ]),
        ),
        Positioned.fill(
          child: Row(children: [
            Expanded(child: _Half(label: loc.previousPageTooltip, onTap: () => onShift(-1))),
            Expanded(child: _Half(label: loc.nextPageTooltip, onTap: () => onShift(1))),
          ]),
        ),
      ]),
    );
  }
}

class _Half extends StatelessWidget {
  const _Half({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(onTap: onTap, customBorder: AppShapes.squircle(AppRadii.pill)),
      ),
    );
  }
}
