import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import 'motion.dart';

/// Solid number pad (DESIGN_DECISIONS B2). Emits '0'–'9', '.' and backspace.
class NumberPad extends StatelessWidget {
  const NumberPad({super.key, required this.onDigit, required this.onBackspace, this.showDot = true, this.keyHeight = 52, this.phoneStyle = false});

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final bool showDot;
  final double keyHeight;

  /// PIN pads (screens 06, lock): white keys with a soft shadow and phone letters (ABC) under the digits.
  final bool phoneStyle;

  static const _letters = {'2': 'ABC', '3': 'DEF', '4': 'GHI', '5': 'JKL', '6': 'MNO', '7': 'PQRS', '8': 'TUV', '9': 'WXYZ'};

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          _row([for (final k in row) _Key(label: k, sub: phoneStyle ? _letters[k] : null, white: phoneStyle, height: keyHeight, onTap: () => onDigit(k))]),
        _row([
          showDot ? _Key(label: '.', height: keyHeight, onTap: () => onDigit('.')) : const SizedBox.shrink(),
          _Key(label: '0', white: phoneStyle, height: keyHeight, onTap: () => onDigit('0')),
          _Key(icon: LucideIcons.delete, height: keyHeight, onTap: onBackspace, plain: true, semanticLabel: 'Backspace'),
        ]),
      ],
    );
  }

  Widget _row(List<Widget> keys) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Row(
      children: [
        for (var i = 0; i < keys.length; i++) ...[if (i > 0) const SizedBox(width: AppSpacing.xs), Expanded(child: keys[i])],
      ],
    ),
  );
}

class _Key extends StatelessWidget {
  const _Key({this.label, this.icon, required this.height, required this.onTap, this.plain = false, this.semanticLabel, this.sub, this.white = false});

  final String? sub;
  final bool white;

  final String? label;
  final IconData? icon;
  final double height;
  final VoidCallback onTap;
  final bool plain;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = AppShapes.squircle(AppRadii.sm);
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: Pressable(
        scale: 0.93,
        child: DecoratedBox(
          // Soft lift under white PIN keys in light mode (screen 06).
          decoration: ShapeDecoration(
            shape: shape,
            shadows: white && !plain && Theme.of(context).brightness == Brightness.light
                ? [BoxShadow(color: c.text.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3), spreadRadius: -2)]
                : null,
          ),
          child: Material(
            color: plain ? Colors.transparent : (white ? c.card : c.raised),
            shape: shape,

            child: InkWell(
              customBorder: shape,
              onTap: () {
                HapticFeedback.selectionClick();
                onTap();
              },
              child: SizedBox(
                height: height < 48 ? 48 : height,
                child: Center(
                  child: label != null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(label!, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600, height: 1.1)),
                            if (sub != null)
                              Text(sub!, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8.5, letterSpacing: 1.4, color: c.textMuted)),
                          ],
                        )
                      : Icon(icon, color: c.text, size: 22),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
