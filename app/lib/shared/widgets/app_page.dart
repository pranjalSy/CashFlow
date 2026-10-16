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

/// The dark page glow from the mockups (00_dark_tokens): flat ellipses near the top and a faint one
/// at the bottom, so the page stays black behind the cards. Painted once; no blur.
class _DarkGlow extends StatelessWidget {
  const _DarkGlow();

  @override
  Widget build(BuildContext context) => const RepaintBoundary(child: CustomPaint(painter: _GlowPainter()));
}

class _GlowPainter extends CustomPainter {
  const _GlowPainter();

  // (centre x, centre y, radius x, radius y) as fractions of the screen, and colour.
  static const _glows = [
    (0.10, 0.00, 0.70, 0.34, Color(0x8C4263EB)), // blue, top left
    (1.00, 0.10, 0.60, 0.30, Color(0x6B8B5CF6)), // purple, top right
    (0.60, 0.42, 0.55, 0.26, Color(0x33EC4899)), // pink, middle
    (0.50, 1.05, 0.70, 0.22, Color(0x474263EB)), // blue, bottom
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (x, y, rx, ry, color) in _glows) {
      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.scale(rx * size.width, ry * size.height);
      final paint = Paint()
        ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)], stops: const [0, 0.72])
            .createShader(Rect.fromCircle(center: Offset.zero, radius: 1));
      canvas.drawCircle(Offset.zero, 1, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_GlowPainter oldDelegate) => false;
}
