import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Screen background (FR-U10): Marble page in light; proper black with a soft brand glow in dark.
class AppPage extends StatelessWidget {
  const AppPage({super.key, required this.child, this.bottomNavigationBar, this.floating});

  final Widget child;

  /// Floating bar laid over the content (for example the glass bottom navigation).
  final Widget? bottomNavigationBar;

  /// Extra overlay above everything (menus, snackbars).
  final Widget? floating;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: context.colors.page,
      extendBody: true,
      body: Stack(
        children: [
          if (dark) const Positioned.fill(child: IgnorePointer(child: _DarkGlow())),
          Positioned.fill(child: child),
          if (bottomNavigationBar != null)
            Positioned(left: 0, right: 0, bottom: 0, child: bottomNavigationBar!),
          if (floating != null) Positioned.fill(child: floating!),
        ],
      ),
    );
  }
}

class _DarkGlow extends StatelessWidget {
  const _DarkGlow();

  static const _blue = Color(0x8C4263EB); // rgba(66,99,235,.55)
  static const _purple = Color(0x6B8B5CF6); // rgba(139,92,246,.42)
  static const _pink = Color(0x33EC4899); // rgba(236,72,153,.20)
  static const _bottom = Color(0x474263EB); // rgba(66,99,235,.28)

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        _Glow(alignment: Alignment(-0.8, -1.05), color: _blue, radius: 0.9),
        _Glow(alignment: Alignment(1.0, -0.8), color: _purple, radius: 0.8),
        _Glow(alignment: Alignment(0.2, -0.15), color: _pink, radius: 0.7),
        _Glow(alignment: Alignment(0.0, 1.15), color: _bottom, radius: 0.9),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.alignment, required this.color, required this.radius});

  final Alignment alignment;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: alignment,
          radius: radius,
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
