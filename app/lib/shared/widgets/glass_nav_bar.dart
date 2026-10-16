import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import 'glass.dart';

class NavItem {
  const NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Floating glass pill with 4 tabs + separate "+" button (DESIGN_DECISIONS D1, FR-U6).
/// The active tab shows its name. One selection pill slides to the tapped tab and stretches a
/// little on the way, like liquid glass (owner, 16 Oct 2026; FR-U7). "+" turns into "×" while
/// its menu is open. With the system "remove animations" setting the pill jumps.
class GlassNavBar extends StatefulWidget {
  const GlassNavBar({
    super.key,
    required this.items,
    required this.index,
    required this.onTap,
    required this.onPlus,
    required this.plusLabel,
    this.plusOpen = false,
  });

  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onPlus;
  final String plusLabel;
  final bool plusOpen;

  @override
  State<GlassNavBar> createState() => _GlassNavBarState();
}

class _GlassNavBarState extends State<GlassNavBar> with SingleTickerProviderStateMixin {
  static const _idle = 52.0; // a tab showing only its icon
  static const _activeExtra = 21.0 + 7.0 + 24.0; // icon + gap + side padding next to the name

  late final AnimationController _move = AnimationController(vsync: this, duration: const Duration(milliseconds: 340), value: 1);
  late double _from = widget.index.toDouble();
  late double _now = widget.index.toDouble();

  /// Where the pill is, as a tab position (1.4 = between tabs 1 and 2). Overshoots a little at the end.
  double get _t => _from + (widget.index - _from) * Curves.easeOutBack.transform(_move.value);

  @override
  void didUpdateWidget(GlassNavBar old) {
    super.didUpdateWidget(old);
    if (old.index == widget.index) return;
    _from = _now;
    if (MediaQuery.disableAnimationsOf(context)) {
      _move.value = 1;
    } else {
      _move.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  void _tap(int i) {
    if (i != widget.index) HapticFeedback.selectionClick();
    widget.onTap(i);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, 18 + bottom),
      child: Row(
        children: [
          Expanded(
            child: GlassSurface(
              alwaysGlass: true,
              blur: 22,
              fill: c.navGlass,
              edge: c.navGlassEdge,
              solid: c.sheet,
              shape: AppShapes.squircle(AppRadii.pill),
              child: SizedBox(
                height: 62,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: LayoutBuilder(
                    builder: (context, box) => RepaintBoundary(
                      child: AnimatedBuilder(animation: _move, builder: (context, _) => _tabs(context, box.maxWidth)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _PlusButton(open: widget.plusOpen, onTap: widget.onPlus, label: widget.plusLabel),
        ],
      ),
    );
  }

  Widget _tabs(BuildContext context, double width) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final style = Theme.of(context).textTheme.titleSmall;
    final scaler = MediaQuery.textScalerOf(context);
    final items = widget.items;
    final n = items.length;
    final t = _t;
    _now = t;
    final at = t.clamp(0.0, n - 1.0);
    double on(int i) => (1 - (at - i).abs()).clamp(0.0, 1.0);

    // Each tab grows from icon-only to icon + name as the pill arrives; it shrinks on narrow phones.
    final maxActive = math.max(_idle, width - _idle * (n - 1));
    final widths = [
      for (var i = 0; i < n; i++)
        () {
          final name = TextPainter(text: TextSpan(text: items[i].label, style: style), textScaler: scaler, maxLines: 1, textDirection: TextDirection.ltr)..layout();
          final full = (_activeExtra + name.width).clamp(_idle, maxActive);
          name.dispose();
          return _idle + (full - _idle) * on(i);
        }(),
    ];
    final gap = n < 2 ? 0.0 : math.max(0.0, (width - widths.fold(0.0, (a, w) => a + w)) / (n - 1));
    final lefts = <double>[];
    var x = 0.0;
    for (final w in widths) {
      lefts.add(x);
      x += w + gap;
    }

    // The pill sits between the two tabs it is passing: longer and a bit flatter mid-way.
    final k = at.floor().clamp(0, n - 1);
    final next = math.min(k + 1, n - 1);
    final f = at - k;
    final mid = _move.isAnimating ? math.sin(f * math.pi) : 0.0;
    final stretch = 18 * mid;
    final height = 48 - 6 * mid;
    final left = lefts[k] + (lefts[next] - lefts[k]) * f - stretch / 2 + (t - at) * 40;

    return Stack(children: [
      Positioned(
        left: left,
        width: widths[k] + (widths[next] - widths[k]) * f + stretch,
        top: (62 - height) / 2,
        height: height,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: dark ? Colors.white.withValues(alpha: 0.14) : c.card,
            shape: AppShapes.squircle(AppRadii.pill),
            shadows: dark ? null : [BoxShadow(color: c.text.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 4), spreadRadius: -4)],
          ),
        ),
      ),
      for (var i = 0; i < n; i++)
        Positioned(
          left: lefts[i],
          width: widths[i],
          top: 7,
          height: 48,
          child: _Tab(item: items[i], selected: i == widget.index, on: on(i), onTap: () => _tap(i)),
        ),
    ]);
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.selected, required this.on, required this.onTap});

  final NavItem item;
  final bool selected;

  /// 0 = icon only, 1 = the pill is here and the name shows.
  final double on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ClipRect(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // A small pop while the pill passes over the icon.
              Transform.scale(
                scale: 1 + 0.32 * on * (1 - on),
                child: Icon(item.icon, size: 21, color: Color.lerp(c.textSecondary, c.text, on)),
              ),
              if (on > 0.02)
                Flexible(
                  child: Opacity(
                    opacity: on,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 7),
                      child: Text(item.label, maxLines: 1, overflow: TextOverflow.fade, softWrap: false, style: Theme.of(context).textTheme.titleSmall),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlusButton extends StatelessWidget {
  const _PlusButton({required this.open, required this.onTap, required this.label});

  final bool open;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = open ? (dark ? c.raised : c.text) : c.brandButton;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg,
            gradient: !open && dark ? const LinearGradient(colors: [Color(0xFF7C93FF), Color(0xFF4263EB)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
            boxShadow: open ? null : [BoxShadow(color: c.brandButton.withValues(alpha: 0.65), blurRadius: 26, offset: const Offset(0, 12), spreadRadius: -8)],
          ),
          child: AnimatedRotation(
            turns: open ? 0.125 : 0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: Icon(Icons.add_rounded, size: 30, color: c.onButton),
          ),
        ),
      ),
    );
  }
}
