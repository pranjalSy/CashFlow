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
  const SegmentedSwitch({super.key, required this.options, required this.index, required this.onChanged, this.activeColors});

  final List<String> options;
  final int index;
  final ValueChanged<int> onChanged;

  /// Colour per option when selected (for example red for Expense, green for Income); default white pill.
  final List<Color>? activeColors;

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
      final segment = box.maxWidth.isFinite && w * options.length > box.maxWidth - 8 ? (box.maxWidth - 8) / options.length : w;
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
                decoration: ShapeDecoration(color: active, shape: AppShapes.squircle(AppRadii.pill)),
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
