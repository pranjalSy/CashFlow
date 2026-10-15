import 'package:cashflow/app/app.dart';
import 'package:cashflow/core/config/flavor.dart';
import 'package:cashflow/core/theme/app_colors.dart';
import 'package:cashflow/core/theme/app_shapes.dart';
import 'package:cashflow/core/theme/app_theme.dart';
import 'package:cashflow/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Colour [top] painted over opaque [bottom] (for translucent glass cards).
Color over(Color top, Color bottom) => Color.alphaBlend(top, bottom);

void main() {
  group('tokens match the approved design (DESIGN_DECISIONS A2, A3, K1–K3)', () {
    test('light', () {
      const c = AppColors.light;
      expect(c.page, const Color(0xFFF2F8FC));
      expect(c.card, const Color(0xFFFFFFFF));
      expect(c.text, const Color(0xFF1F2A37));
      expect(c.textSecondary, const Color(0xFF5B6B7F));
      expect(c.brandButton, const Color(0xFF3B5BDB));
      expect(c.income, const Color(0xFF15803D));
      expect(c.expense, const Color(0xFFC62828));
      expect(c.lent, const Color(0xFF2B4BC7));
      expect(c.borrowed, const Color(0xFFA3165A));
      expect(c.dueSoon, const Color(0xFFC2410C));
      expect(c.premium, const Color(0xFFB45309));
    });

    test('dark is proper black with bright amounts', () {
      const c = AppColors.dark;
      expect(c.page, const Color(0xFF000000));
      expect(c.sheet, const Color(0xFF141418));
      expect(c.text, const Color(0xFFE8EDF5));
      expect(c.brandButton, const Color(0xFF4263EB));
      expect(c.income, const Color(0xFF4ADE80));
      expect(c.expense, const Color(0xFFF87171));
      expect(c.lent, const Color(0xFF8EA2FF));
      expect(c.borrowed, const Color(0xFFF472B6));
      expect(c.incomeButton, const Color(0xFF15803D));
      expect(c.expenseButton, const Color(0xFFDC2626));
      expect(c.premiumButton, const Color(0xFFB45309));
    });
  });

  for (final entry in {'light': AppColors.light, 'dark': AppColors.dark}.entries) {
    final name = entry.key;
    final c = entry.value;
    group('$name contrast', () {
      test('white text on every button is at least 4.5', () {
        for (final button in [c.brandButton, c.incomeButton, c.expenseButton, c.premiumButton]) {
          expect(contrast(c.onButton, button), greaterThanOrEqualTo(4.5), reason: '$button');
        }
      });

      test('text and amounts are readable on cards, glass cards and pages', () {
        final surfaces = [c.page, c.card, over(c.glassCard, c.page), c.sheet];
        final readable = [c.text, c.textSecondary, c.brandText, c.income, c.expense, c.lent, c.borrowed, c.dueSoon, c.premium];
        for (final surface in surfaces) {
          for (final colour in readable) {
            expect(contrast(colour, surface), greaterThanOrEqualTo(4.5), reason: '$colour on $surface');
          }
        }
      });

      test('muted hints stay visible (at least 3.0)', () {
        for (final surface in [c.page, c.card, c.sheet]) {
          expect(contrast(c.textMuted, surface), greaterThanOrEqualTo(3.0), reason: '${c.textMuted} on $surface');
        }
      });

      test('meaning colours are readable on their own tints', () {
        final pairs = {c.income: c.incomeTint, c.expense: c.expenseTint, c.lent: c.lentTint, c.borrowed: c.borrowedTint, c.dueSoon: c.dueSoonTint};
        pairs.forEach((fg, tint) => expect(contrast(fg, tint), greaterThanOrEqualTo(4.5), reason: '$fg on $tint'));
      });
    });
  }

  group('ThemeData', () {
    test('light and dark build with tokens, Inter and Noto fallbacks', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final colors = theme.extension<AppColors>();
        expect(colors, isNotNull);
        expect(theme.scaffoldBackgroundColor, colors!.page);
        expect(theme.textTheme.bodyMedium?.fontFamily, AppTypography.fontFamily);
        expect(theme.textTheme.bodyMedium?.fontFamilyFallback, ['NotoSansDevanagari', 'NotoSansGujarati']);
        expect(theme.cardTheme.shape, isA<RoundedSuperellipseBorder>());
      }
      expect(AppTheme.light().brightness, Brightness.light);
      expect(AppTheme.dark().brightness, Brightness.dark);
      expect(AppTheme.dark().scaffoldBackgroundColor, const Color(0xFF000000));
    });

    test('amount style uses tabular digits', () {
      expect(AppTypography.amount(36).fontFeatures, AppTypography.tabularFigures);
    });

    test('squircle helper gives smooth corners', () {
      final shape = AppShapes.squircle(AppRadii.md);
      expect(shape.borderRadius, BorderRadius.circular(20));
    });
  });

  testWidgets('app follows dark mode and paints a black page', (tester) async {
    FlavorConfig.init(Flavor.dev);
    await tester.pumpWidget(const CashFlowApp(themeMode: ThemeMode.dark));
    final context = tester.element(find.text('CashFlow Dev'));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(context.colors.page, const Color(0xFF000000));
  });

  testWidgets('preview fits a small phone without overflow', (tester) async {
    FlavorConfig.init(Flavor.dev);
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const CashFlowApp(themeMode: ThemeMode.light));
    expect(tester.takeException(), isNull);
  });
}
