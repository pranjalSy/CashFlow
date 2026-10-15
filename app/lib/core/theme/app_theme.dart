import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_shapes.dart';
import 'app_typography.dart';

/// Light and dark `ThemeData` built from one token set (TRD 14).
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light, AppColors.light);

  static ThemeData dark() => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors c) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.brandButton,
      onPrimary: c.onButton,
      secondary: c.brandText,
      onSecondary: c.onButton,
      error: c.expenseButton,
      onError: c.onButton,
      surface: c.card,
      onSurface: c.text,
      onSurfaceVariant: c.textSecondary,
      outline: c.border,
      outlineVariant: c.border,
      scrim: c.scrim,
    );
    final text = AppTypography.textTheme(c.text, c.textSecondary);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.page,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFallback,
      textTheme: text,
      extensions: [c],
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      cardTheme: CardThemeData(
        color: c.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: AppShapes.squircle(AppRadii.md),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.sheet,
        modalBackgroundColor: c.sheet,
        modalBarrierColor: c.scrim,
        shape: AppShapes.squircle(AppRadii.xl),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.sheet,
        barrierColor: c.scrim,
        shape: AppShapes.squircle(AppRadii.xl),
      ),
    );
  }
}
