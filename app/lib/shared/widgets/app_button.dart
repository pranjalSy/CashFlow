import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import 'motion.dart';

enum AppButtonKind { primary, success, danger, premium, secondary, soft }

/// Pill button. It is never disabled (DESIGN_DECISIONS F4): screens validate on press instead.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = AppButtonKind.primary,
    this.icon,
    this.expand = true,
    this.height = 52,
    this.color,
  });

  final String label;
  final VoidCallback onPressed;

  /// Fill colour instead of the kind's (Lent blue / Borrowed pink save button, screen 15).
  final Color? color;
  final AppButtonKind kind;
  final IconData? icon;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg0, fg) = switch (kind) {
      AppButtonKind.primary => (c.brandButton, c.onButton),
      AppButtonKind.success => (c.incomeButton, c.onButton),
      AppButtonKind.danger => (c.expenseButton, c.onButton),
      AppButtonKind.premium => (c.premiumButton, c.onButton),
      AppButtonKind.secondary => (c.raised, c.text),
      AppButtonKind.soft => (c.expenseTint, c.expense),
    };
    final bg = color ?? bg0;
    final coloured = kind != AppButtonKind.secondary && kind != AppButtonKind.soft;
    final shape = AppShapes.squircle(AppRadii.pill);
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg),
    );
    final row = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 6)],
        Flexible(child: text),
      ],
    );
    // Its own button for TalkBack, even inside a card (phone test, 16 Oct).
    return Semantics(
      container: true,
      button: true,
      child: Pressable(
        haptic: coloured,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height < 48 ? 48 : height, minWidth: 48),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: bg,
              shape: shape,
              shadows: coloured ? [BoxShadow(color: bg.withValues(alpha: 0.55), blurRadius: 22, offset: const Offset(0, 10), spreadRadius: -8)] : null,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onPressed,
                customBorder: shape,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Center(widthFactor: 1, heightFactor: 1, child: row),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
