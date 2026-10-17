import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'motion.dart';

/// Runs 0 → 1 once when first shown (600 ms, screen 16 note); 1 at once with "remove animations".
class _Reveal extends StatefulWidget {
  const _Reveal({required this.builder});

  final Widget Function(BuildContext context, double t) builder;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    Motion.off(context) ? _c.value = 1 : _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return RepaintBoundary(child: AnimatedBuilder(animation: a, builder: (context, _) => widget.builder(context, a.value)));
  }
}

/// Donut by category (FR-C1): fills by sweeping round on first show. [center] sits in the hole.
class DonutChart extends StatelessWidget {
  const DonutChart({super.key, required this.values, required this.colors, required this.center, this.size = 190, this.stroke = 22});

  final List<int> values;
  final List<Color> colors;
  final Widget center;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final track = context.colors.raised;
    return SizedBox.square(
      dimension: size,
      child: Stack(alignment: Alignment.center, children: [
        _Reveal(
          builder: (context, t) => CustomPaint(size: Size.square(size), painter: _DonutPainter(values, colors, track, stroke, t)),
        ),
        Padding(padding: EdgeInsets.all(stroke + 10), child: center),
      ]),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.values, this.colors, this.track, this.stroke, this.t);

  final List<int> values;
  final List<Color> colors;
  final Color track;
  final double stroke;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    canvas.drawArc(arc, 0, math.pi * 2, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track);
    final total = values.fold(0, (a, v) => a + v);
    if (total <= 0) return;
    const gap = 0.035; // small gap between slices
    var start = -math.pi / 2;
    final visible = math.pi * 2 * t;
    for (var i = 0; i < values.length; i++) {
      final sweep = math.pi * 2 * values[i] / total;
      final drawn = math.min(sweep, visible - (start + math.pi / 2));
      if (drawn <= 0) break;
      final g = values.length > 1 && sweep > gap * 2 ? gap : 0.0;
      canvas.drawArc(arc, start + g / 2, math.max(0, drawn - g), false, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..color = colors[i % colors.length]);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter o) => o.t != t || o.values != values || o.colors != colors;
}

/// Percent ring (Budget, FR-BG1). Fills on first show; colour from the budget band.
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.fraction, required this.color, required this.center, this.size = 92, this.stroke = 9});

  final double fraction;
  final Color color;
  final Widget center;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final track = context.colors.raised;
    return SizedBox.square(
      dimension: size,
      child: Stack(alignment: Alignment.center, children: [
        _Reveal(builder: (context, t) => CustomPaint(size: Size.square(size), painter: _RingPainter(fraction.clamp(0, 1) * t, color, track, stroke))),
        center,
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.f, this.color, this.track, this.stroke);

  final double f;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final arc = (Offset.zero & size).deflate(stroke / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arc, 0, math.pi * 2, false, p..color = track);
    if (f > 0) canvas.drawArc(arc, -math.pi / 2, math.pi * 2 * f, false, p..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.f != f || o.color != color;
}

/// Income vs expense bars for 6 months (FR-C1 Trends). Bars rise on first show; the chosen month is
/// full colour, the others faded. Tap a month to choose it.
class IncomeExpenseBars extends StatelessWidget {
  const IncomeExpenseBars({
    super.key,
    required this.income,
    required this.expense,
    required this.labels,
    required this.selected,
    required this.onSelect,
    this.height = 170,
  });

  final List<int> income;
  final List<int> expense;
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final top = [...income, ...expense].fold(0, math.max);
    return _Reveal(
      builder: (context, v) => SizedBox(
        height: height + 26,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(i),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Opacity(
                    opacity: i == selected ? 1 : 0.3,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                      _bar(top == 0 ? 0 : height * income[i] / top * v, c.incomeButton),
                      const SizedBox(width: 4),
                      _bar(top == 0 ? 0 : height * expense[i] / top * v, c.expenseButton),
                    ]),
                  ),
                  const SizedBox(height: 6),
                  Text(labels[i], style: t.labelSmall?.copyWith(color: i == selected ? c.text : c.textMuted, fontWeight: i == selected ? FontWeight.w800 : null)),
                ]),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _bar(double h, Color color) => Container(
        width: 14,
        height: math.max(h, 2),
        decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(5))),
      );
}
