import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import 'glass.dart';

/// Card: solid white in light mode, frosted glass in dark mode (FR-U2, FR-U10).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadii.lg,
    this.onTap,
    this.color,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  /// Solid colour instead of card/glass (for example coloured summary cards).
  final Color? color;

  /// Outline, for example red on a form error or orange on the next due installment.
  final BorderSide? border;

  @override
  Widget build(BuildContext context) {
    final shape = AppShapes.squircle(radius, side: border ?? BorderSide.none);
    final content = Padding(padding: padding, child: child);
    final tappable = onTap == null
        ? content
        : Material(
            type: MaterialType.transparency,
            child: InkWell(onTap: onTap, customBorder: shape, child: content),
          );
    final light = Theme.of(context).brightness == Brightness.light;
    final surface = color != null
        ? DecoratedBox(decoration: ShapeDecoration(color: color, shape: shape), child: tappable)
        : GlassSurface(shape: shape, child: tappable);
    if (!light) return surface;
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: [
          BoxShadow(
            color: context.colors.text.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
            spreadRadius: -10,
          ),
        ],
      ),
      child: surface,
    );
  }
}
