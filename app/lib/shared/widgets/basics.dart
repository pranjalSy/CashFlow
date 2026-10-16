import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import 'motion.dart';

/// Rounded icon box used in lists and tiles.
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, required this.color, required this.tint, this.size = 40});

  final IconData icon;
  final Color color;
  final Color tint;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: ShapeDecoration(color: tint, shape: AppShapes.squircle(size * 0.33)),
        child: Icon(icon, size: size * 0.5, color: color),
      ),
    );
  }
}

/// Small grey label above a group ("Today · 13 Oct", "Recent").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xxs, AppSpacing.sm, AppSpacing.xxs, AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(text, style: Theme.of(context).textTheme.labelMedium)),
          ?trailing,
        ],
      ),
    );
  }
}

/// Selectable pill chip (filters, reminder days, suggestions).
class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.label, required this.selected, required this.onTap, this.selectedColor});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bg = selected ? (selectedColor ?? c.brandButton) : c.card;
    final shape = AppShapes.squircle(AppRadii.pill, side: BorderSide(color: selected ? bg : c.border, width: 1.5));
    return Pressable(
      scale: 0.95,
      child: AnimatedContainer(
        duration: Motion.medium,
        curve: Motion.enter,
        constraints: const BoxConstraints(minHeight: 40),
        decoration: ShapeDecoration(color: bg, shape: shape),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () {
              if (!selected) HapticFeedback.selectionClick();
              onTap();
            },
            customBorder: shape,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: AnimatedDefaultTextStyle(
                duration: Motion.medium,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(color: selected ? c.onButton : c.textSecondary, fontWeight: FontWeight.w700),
                child: Text(label),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two or more options in a pill track (Expense | Income, EMIs | Bills).
class SegmentedSwitch extends StatelessWidget {
  const SegmentedSwitch({super.key, required this.options, required this.index, required this.onChanged, this.activeColors, this.expand = false});

  final List<String> options;
  final int index;
  final ValueChanged<int> onChanged;

  /// Colour per option when selected (for example red for Expense, green for Income); default white pill.
  final List<Color>? activeColors;

  /// Fill the row with equal halves (EMIs | Bills, Spending | Trends, screens 16–17).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final style = Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w700);
    final scaler = MediaQuery.textScalerOf(context);
    // Equal segments (the widest label decides) so one pill can slide between them, like the bottom bar.
    var w = 64.0;
    for (final o in options) {
      final tp = TextPainter(text: TextSpan(text: o, style: style), textScaler: scaler, maxLines: 1, textDirection: TextDirection.ltr)..layout();
      w = w < tp.width + 32 ? tp.width + 32 : w;
      tp.dispose();
    }
    final active = activeColors?[index] ?? c.card;
    return LayoutBuilder(builder: (context, box) {
      final full = box.maxWidth.isFinite ? (box.maxWidth - 8) / options.length : w;
      final segment = expand || (box.maxWidth.isFinite && w * options.length > box.maxWidth - 8) ? full : w;
      return _track(context, dark, segment, active, style);
    });
  }

  Widget _track(BuildContext context, bool dark, double w, Color active, TextStyle style) {
    final c = context.colors;
    return DecoratedBox(
      decoration: ShapeDecoration(color: dark ? c.raised : const Color(0xFFE6ECF6), shape: AppShapes.squircle(AppRadii.pill)),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          width: w * options.length,
          height: 40,
          child: Stack(children: [
            AnimatedPositioned(
              duration: Motion.off(context) ? Duration.zero : Motion.slow,
              curve: const Cubic(0.3, 1.25, 0.6, 1), // gentle bounce, same as the bottom bar
              left: w * index,
              top: 0,
              bottom: 0,
              width: w,
              child: AnimatedContainer(
                duration: Motion.medium,
                decoration: ShapeDecoration(
                  color: active,
                  shape: AppShapes.squircle(AppRadii.pill),
                  shadows: dark ? null : [BoxShadow(color: c.text.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 3), spreadRadius: -3)],
                ),
              ),
            ),
            Row(children: [
              for (var i = 0; i < options.length; i++)
                SizedBox(
                  width: w,
                  child: Semantics(
                    selected: i == index,
                    button: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (i != index) HapticFeedback.selectionClick();
                        onChanged(i);
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: Motion.medium,
                          style: style.copyWith(color: i == index ? (activeColors != null ? c.onButton : c.text) : c.textSecondary),
                          child: Text(options[i], maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// On/off switch styled like the mockups (44 × 26), with a 48 dp tap area.
class AppToggle extends StatelessWidget {
  const AppToggle({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 52,
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 26,
              padding: const EdgeInsets.all(3),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              decoration: ShapeDecoration(color: value ? c.brandButton : c.border, shape: AppShapes.squircle(AppRadii.pill)),
              child: const SizedBox.square(
                dimension: 20,
                child: DecoratedBox(decoration: ShapeDecoration(color: Colors.white, shape: CircleBorder())),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon + title + subtitle + trailing, used in lists and settings.
class ListRowTile extends StatelessWidget {
  const ListRowTile({super.key, required this.leading, required this.title, this.subtitle, this.trailing, this.onTap});

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              leading,
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall),
                    if (subtitle != null)
                      Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: AppSpacing.xs), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// White rounded-square icon button used in screen headers (back, more) - screens 19, 21.
class HeaderButton extends StatelessWidget {
  const HeaderButton({super.key, required this.icon, required this.tooltip, this.onTap});

  final IconData icon;
  final String tooltip;

  /// Null when a parent (for example a popup menu) handles the tap.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final box = Container(
      width: 44,
      height: 44,
      decoration: ShapeDecoration(
        color: c.card,
        shape: AppShapes.squircle(14),
        shadows: dark ? null : [BoxShadow(color: c.text.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4), spreadRadius: -4)],
      ),
      child: Icon(icon, size: 20, color: c.text),
    );
    final hit = SizedBox.square(dimension: 48, child: Center(child: box));
    if (onTap == null) return hit;
    return Tooltip(
      message: tooltip,
      child: Semantics(button: true, label: tooltip, excludeSemantics: true, child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: hit)),
    );
  }
}

/// Dashed rounded outline (the collapsed "earlier paid" row, screen 19).
class DashedOutline extends StatelessWidget {
  const DashedOutline({super.key, required this.child, required this.color, this.radius = 18});

  final Widget child;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) => CustomPaint(foregroundPainter: _DashPainter(color, radius), child: child);
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color, this.radius);

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius((Offset.zero & size).deflate(0.75), Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashPainter o) => o.color != color || o.radius != radius;
}
