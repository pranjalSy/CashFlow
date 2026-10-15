import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';

class PlusMenuItem {
  const PlusMenuItem({required this.label, required this.icon, required this.color, required this.tint, required this.onTap});

  final String label;
  final IconData icon;
  final Color color;
  final Color tint;
  final VoidCallback onTap;
}

/// Compact menu above the "+" button: separate solid buttons, 8 px apart, right side (D3).
/// Lay it over the page; tapping outside calls [onClose].
class PlusMenu extends StatelessWidget {
  const PlusMenu({super.key, required this.open, required this.items, required this.onClose});

  final bool open;
  final List<PlusMenuItem> items;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return IgnorePointer(
      ignoring: !open,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: onClose,
              child: AnimatedOpacity(
                opacity: open ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: ColoredBox(color: c.scrim),
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 92 + bottom,
            width: 178,
            child: AnimatedScale(
              scale: open ? 1 : 0.3,
              alignment: Alignment.bottomRight,
              duration: const Duration(milliseconds: 360),
              curve: open ? Curves.easeOutBack : Curves.easeIn,
              child: AnimatedOpacity(
                opacity: open ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _MenuButton(item: items[i]),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.item});

  final PlusMenuItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = AppShapes.squircle(22, side: BorderSide(color: c.border));
    return Material(
      color: c.sheet,
      shape: shape,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: InkWell(
        onTap: item.onTap,
        customBorder: shape,
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Row(
              children: [
                Expanded(child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium)),
                SizedBox.square(
                  dimension: 34,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(color: item.tint, shape: AppShapes.squircle(12)),
                    child: Icon(item.icon, size: 18, color: item.color),
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
