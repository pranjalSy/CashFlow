import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';

/// Solid number pad (DESIGN_DECISIONS B2). Emits '0'–'9', '.' and backspace.
class NumberPad extends StatelessWidget {
  const NumberPad({super.key, required this.onDigit, required this.onBackspace, this.showDot = true, this.keyHeight = 52});

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final bool showDot;
  final double keyHeight;

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
        for (final row in rows) _row([for (final k in row) _Key(label: k, height: keyHeight, onTap: () => onDigit(k))]),
        _row([
          showDot ? _Key(label: '.', height: keyHeight, onTap: () => onDigit('.')) : const SizedBox.shrink(),
          _Key(label: '0', height: keyHeight, onTap: () => onDigit('0')),
          _Key(icon: Icons.backspace_outlined, height: keyHeight, onTap: onBackspace, plain: true, semanticLabel: 'Backspace'),
        ]),
      ],
    );
  }

  Widget _row(List<Widget> keys) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Row(
          children: [
            for (var i = 0; i < keys.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.xs),
              Expanded(child: keys[i]),
            ],
          ],
        ),
      );
}

class _Key extends StatelessWidget {
  const _Key({this.label, this.icon, required this.height, required this.onTap, this.plain = false, this.semanticLabel});

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
      child: Material(
        color: plain ? Colors.transparent : c.raised,
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
                  ? Text(label!, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600))
                  : Icon(icon, color: c.text, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
