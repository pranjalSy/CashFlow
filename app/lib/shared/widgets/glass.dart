import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';

/// "Reduce glass effects" (Settings, PRD 6.13). When on, every glass surface paints solid.
/// Persisted with the other UI preferences in T14; defaults to off.
final reduceGlassProvider = NotifierProvider<ReduceGlass, bool>(ReduceGlass.new);

class ReduceGlass extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

/// Whether glass cards should be frosted here: only in dark mode, and only if not reduced
/// by the user or by the system (reduce motion / high contrast).
bool useGlassCards(BuildContext context, WidgetRef ref) {
  final media = MediaQuery.of(context);
  return Theme.of(context).brightness == Brightness.dark &&
      !ref.watch(reduceGlassProvider) &&
      !media.disableAnimations &&
      !media.highContrast;
}

/// Frosted surface: blur behind + translucent fill. Falls back to [solid] when glass is off.
class GlassSurface extends ConsumerWidget {
  const GlassSurface({
    super.key,
    required this.shape,
    required this.child,
    this.blur = 18,
    this.fill,
    this.edge,
    this.solid,
    this.alwaysGlass = false,
  });

  final ShapeBorder shape;
  final Widget child;
  final double blur;

  /// Glass fill; defaults to the theme's glass card colour.
  final Color? fill;

  /// 1 px edge colour of the glass.
  final Color? edge;

  /// Colour used when glass is off; defaults to the theme's card colour.
  final Color? solid;

  /// Bottom bar and language bar are glass in light mode too (DESIGN_DECISIONS B1).
  final bool alwaysGlass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final media = MediaQuery.of(context);
    final glass = alwaysGlass
        ? !ref.watch(reduceGlassProvider) && !media.highContrast
        : useGlassCards(context, ref);
    if (!glass) {
      return DecoratedBox(
        decoration: ShapeDecoration(color: solid ?? c.card, shape: shape),
        child: child,
      );
    }
    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: fill,
            // Cards: the mockup's 160° sheen, brighter at the top left (.085 → .035).
            gradient: fill == null
                ? LinearGradient(
                    begin: const Alignment(-0.35, -1),
                    end: const Alignment(0.35, 1),
                    colors: [c.glassCard, c.glassCard.withValues(alpha: 0.035)],
                  )
                : null,
            shape: _withEdge(shape, edge ?? c.glassEdge),
          ),
          child: child,
        ),
      ),
    );
  }

  static ShapeBorder _withEdge(ShapeBorder shape, Color edge) {
    // Keep an outline the caller asked for (for example the orange next-due border).
    if (shape is OutlinedBorder && shape.side == BorderSide.none) return shape.copyWith(side: BorderSide(color: edge));
    return shape;
  }
}
