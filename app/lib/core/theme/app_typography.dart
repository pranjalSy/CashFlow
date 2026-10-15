import 'package:flutter/material.dart';

/// Fonts and text styles (PRD FR-U9). Inter covers Latin, digits and ₹;
/// Hindi and Gujarati glyphs fall back to the bundled Noto fonts.
abstract final class AppTypography {
  static const fontFamily = 'Inter';
  static const fontFallback = ['NotoSansDevanagari', 'NotoSansGujarati'];

  /// Equal-width digits so amounts line up and never jump while typing.
  static const tabularFigures = [FontFeature.tabularFigures()];

  static TextTheme textTheme(Color text, Color secondary) => TextTheme(
        displaySmall: _style(30, FontWeight.w700, text, -0.8),
        headlineSmall: _style(22, FontWeight.w700, text, -0.4),
        titleLarge: _style(18, FontWeight.w700, text, -0.2),
        titleMedium: _style(15, FontWeight.w600, text, 0),
        titleSmall: _style(14, FontWeight.w600, text, 0),
        bodyLarge: _style(15, FontWeight.w400, text, 0),
        bodyMedium: _style(14, FontWeight.w400, text, 0),
        bodySmall: _style(12, FontWeight.w400, secondary, 0),
        labelLarge: _style(15, FontWeight.w700, text, 0),
        labelMedium: _style(13, FontWeight.w600, secondary, 0),
        labelSmall: _style(11, FontWeight.w600, secondary, 0.2),
      );

  /// Style for money amounts (tabular digits, tight tracking).
  static TextStyle amount(double size, {FontWeight weight = FontWeight.w700, Color? color}) =>
      _style(size, weight, color, size >= 28 ? -1.0 : -0.2).copyWith(fontFeatures: tabularFigures);

  static TextStyle _style(double size, FontWeight weight, Color? color, double letterSpacing) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallback,
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: 1.3,
      );
}
