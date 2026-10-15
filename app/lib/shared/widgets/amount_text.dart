import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';

/// Money amount that never wraps or gets cut: it scales down to fit (FR-U4).
/// Takes an already formatted string (formatting lives in core/utils/money.dart).
class AmountText extends StatelessWidget {
  const AmountText(
    this.text, {
    super.key,
    this.size = 15,
    this.color,
    this.weight = FontWeight.w700,
    this.alignment = Alignment.centerLeft,
  });

  final String text;
  final double size;
  final Color? color;
  final FontWeight weight;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: AppTypography.amount(size, weight: weight, color: color ?? DefaultTextStyle.of(context).style.color),
      ),
    );
  }
}
