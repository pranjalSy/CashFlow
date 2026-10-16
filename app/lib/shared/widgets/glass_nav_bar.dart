import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
  static const _idle = 48.0; // a tab showing only its icon (48 dp tap target)
  static const _activeExtra = 21.0 + 7.0 + 24.0; // icon + gap + side padding next to the name

  late final AnimationController _move = AnimationController(vsync: this, duration: const Duration(milliseconds: 340), value: 1);

  /// The tab the pill is leaving. Only this tab and the new one change; the others never grow.
  late int _from = widget.index;

  @override
  void didUpdateWidget(GlassNavBar old) {
    super.didUpdateWidget(old);
    if (old.index == widget.index) return;
    _from = old.index;
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
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: LayoutBuilder(
                    builder: (context, box) => RepaintBoundary(
                      child: AnimatedBuilder(animation: _move, builder: (context, _) => _tabs(context, box.maxWidth)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          _PlusButton(open: widget.plusOpen, onTap: widget.onPlus, label: widget.plusLabel),
        ],
      ),
    );
  }

  /// The old name fades out quickly; the new one fades in as the pill arrives.
  double _nameOpacity(int i, double p) {
    if (i == widget.index) return ((p - 0.45) / 0.55).clamp(0.0, 1.0);
    if (i == _from) return (1 - p / 0.35).clamp(0.0, 1.0);
    return 0;
  }

  Widget _tabs(BuildContext context, double width) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final style = Theme.of(context).textTheme.titleSmall;
    final scaler = MediaQuery.textScalerOf(context);
    final items = widget.items;
    final n = items.length;
    final to = widget.index;

    // Layout moves once, smoothly (no bounce); the pill alone overshoots a little.
    final p = Curves.easeOutCubic.transform(_move.value);
    final q = const Cubic(0.3, 1.25, 0.6, 1).transform(_move.value); // gentle bounce at the end

    // Icon-only tabs keep their width; the old tab shrinks while the new one grows to icon + name.
    final maxActive = math.max(_idle, width - _idle * (n - 1));
    double full(int i) {
      final name = TextPainter(text: TextSpan(text: items[i].label, style: style), textScaler: scaler, maxLines: 1, textDirection: TextDirection.ltr)..layout();
      final w = (_activeExtra + name.width).clamp(_idle, maxActive);
      name.dispose();
      return w;
    }

    double shown(int i) => i == to ? p : (i == _from ? 1 - p : 0);
    final widths = [for (var i = 0; i < n; i++) _idle + (shown(i) == 0 ? 0 : (full(i) - _idle) * shown(i))];
    final gap = n < 2 ? 0.0 : math.max(0.0, (width - widths.fold(0.0, (a, w) => a + w)) / (n - 1));
    final lefts = <double>[];
    var x = 0.0;
    for (final w in widths) {
      lefts.add(x);
      x += w + gap;
    }

    // The pill travels from the old tab to the new one: longer and a bit flatter mid-way.
    final mid = _move.isAnimating ? math.sin(q.clamp(0.0, 1.0) * math.pi) : 0.0;
    final stretch = 18 * mid;
    final height = 48 - 6 * mid;
    final pillWidth = widths[_from] + (widths[to] - widths[_from]) * q.clamp(0.0, 1.0) + stretch;
    final left = (lefts[_from] + (lefts[to] - lefts[_from]) * q - stretch / 2).clamp(0.0, math.max(0.0, width - pillWidth)).toDouble(); // stays inside the bar

    return Stack(children: [
      Positioned(
        left: left,
        width: pillWidth,
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
          child: _Tab(item: items[i], selected: i == to, on: shown(i), name: _nameOpacity(i, p), pop: i == to && _move.isAnimating ? math.sin(p * math.pi) : 0, onTap: () => _tap(i)),
        ),
    ]);
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.selected, required this.on, required this.name, required this.pop, required this.onTap});

  final NavItem item;
  final bool selected;

  /// 0 = icon only, 1 = the pill is here and the name shows.
  final double on;

  /// Opacity of the name.
  final double name;

  /// 0…1 while the new tab's icon pops once.
  final double pop;
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
          // Equal padding on both sides, so icon + name sit in the middle of the pill. A long name
          // (Contacts, Hindi, big text) gets a little smaller instead of touching the pill's edges.
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12 * on),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: 1 + 0.12 * pop,
                  child: Icon(item.icon, size: 21, color: Color.lerp(c.textSecondary, c.text, on)),
                ),
                if (on > 0.02 && name > 0)
                  Flexible(
                    child: Opacity(
                      opacity: name,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 7),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(item.label, maxLines: 1, softWrap: false, style: Theme.of(context).textTheme.titleSmall),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
            child: Icon(LucideIcons.plus, size: 30, color: c.onButton),
          ),
        ),
      ),
    );
  }
}
