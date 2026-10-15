import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import 'glass.dart';

class NavItem {
  const NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Floating glass pill with 4 tabs + separate "+" button (DESIGN_DECISIONS D1, FR-U6).
/// The active tab shows its name. "+" turns into "×" while its menu is open.
class GlassNavBar extends StatelessWidget {
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < items.length; i++)
                        if (i == index)
                          // Only the active tab shows its name; it shrinks on narrow phones.
                          Flexible(child: _Tab(item: items[i], selected: true, onTap: () => onTap(i)))
                        else
                          _Tab(item: items[i], selected: false, onTap: () => onTap(i)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _PlusButton(open: plusOpen, onTap: onPlus, label: plusLabel),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.selected, required this.onTap});

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final pill = selected ? (dark ? Colors.white.withValues(alpha: 0.14) : c.card) : Colors.transparent;
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          height: 48,
          constraints: const BoxConstraints(minWidth: 44),
          padding: EdgeInsets.symmetric(horizontal: selected ? 12 : 10),
          decoration: ShapeDecoration(color: pill, shape: AppShapes.squircle(AppRadii.pill)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 21, color: selected ? c.text : c.textSecondary),
              if (selected) ...[
                const SizedBox(width: 7),
                Flexible(
                  child: Text(item.label, maxLines: 1, overflow: TextOverflow.fade, softWrap: false, style: Theme.of(context).textTheme.titleSmall),
                ),
              ],
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
