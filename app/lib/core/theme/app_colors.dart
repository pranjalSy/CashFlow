import 'package:flutter/material.dart';

/// Colour tokens for light and dark themes (PRD FR-U1, FR-U10; DESIGN_DECISIONS A2, A3, K1–K3).
///
/// Screens never use raw colours; they read these through `context.colors`.
/// "Button" colours carry white text, "text" colours sit on cards and pages.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.page,
    required this.card,
    required this.glassCard,
    required this.glassEdge,
    required this.sheet,
    required this.raised,
    required this.border,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
    required this.onButton,
    required this.brandButton,
    required this.brandText,
    required this.brandTint,
    required this.income,
    required this.incomeButton,
    required this.incomeTint,
    required this.expense,
    required this.expenseButton,
    required this.expenseTint,
    required this.lent,
    required this.lentTint,
    required this.borrowed,
    required this.borrowedTint,
    required this.dueSoon,
    required this.dueSoonTint,
    required this.premium,
    required this.premiumButton,
    required this.premiumTint,
    required this.navGlass,
    required this.navGlassEdge,
    required this.scrim,
  });

  /// Screen background.
  final Color page;

  /// Solid card (light cards; dark fallback when glass is reduced).
  final Color card;

  /// Frosted card fill (dark mode glass; equals [card] in light mode).
  final Color glassCard;

  /// 1 px light edge of glass cards.
  final Color glassEdge;

  /// Bottom sheets, popups, number pads, menus: always solid.
  final Color sheet;

  /// Number keys, unselected chips.
  final Color raised;

  /// Lines and outlines.
  final Color border;

  final Color text;
  final Color textSecondary;
  final Color textMuted;

  /// Text and icons on coloured buttons.
  final Color onButton;

  final Color brandButton;
  final Color brandText;
  final Color brandTint;

  final Color income;
  final Color incomeButton;
  final Color incomeTint;

  final Color expense;
  final Color expenseButton;
  final Color expenseTint;

  final Color lent;
  final Color lentTint;

  final Color borrowed;
  final Color borrowedTint;

  final Color dueSoon;
  final Color dueSoonTint;

  final Color premium;
  final Color premiumButton;
  final Color premiumTint;

  /// Bottom navigation pill (frosted, blurred behind).
  final Color navGlass;
  final Color navGlassEdge;

  /// Overlay behind sheets and popups.
  final Color scrim;

  static const light = AppColors(
    page: Color(0xFFF2F8FC),
    card: Color(0xFFFFFFFF),
    glassCard: Color(0xFFFFFFFF),
    glassEdge: Color(0x00FFFFFF),
    sheet: Color(0xFFFFFFFF),
    raised: Color(0xFFF2F5FA),
    border: Color(0xFFE6EBF3),
    text: Color(0xFF1F2A37),
    textSecondary: Color(0xFF5B6B7F),
    textMuted: Color(0xFF808EA0), // design #8A97A8 darkened to reach 3:1 on the page
    onButton: Color(0xFFFFFFFF),
    brandButton: Color(0xFF3B5BDB),
    brandText: Color(0xFF3B5BDB),
    brandTint: Color(0xFFEDF1FD),
    income: Color(0xFF15803D),
    incomeButton: Color(0xFF15803D),
    incomeTint: Color(0xFFEAF6EF),
    expense: Color(0xFFC62828),
    expenseButton: Color(0xFFC62828),
    expenseTint: Color(0xFFFDEEEE),
    lent: Color(0xFF2B4BC7),
    lentTint: Color(0xFFEDF1FD),
    borrowed: Color(0xFFA3165A),
    borrowedTint: Color(0xFFFCEDF3),
    dueSoon: Color(0xFFC2410C),
    dueSoonTint: Color(0xFFFFF1E6),
    premium: Color(0xFFB45309),
    premiumButton: Color(0xFFB45309),
    premiumTint: Color(0xFFFFF8EB),
    navGlass: Color(0xB8FFFFFF), // rgba(255,255,255,.72)
    navGlassEdge: Color(0xD9FFFFFF), // rgba(255,255,255,.85)
    scrim: Color(0x6B111827), // rgba(17,24,39,.42)
  );

  static const dark = AppColors(
    page: Color(0xFF000000),
    card: Color(0xFF111114),
    glassCard: Color(0x16FFFFFF), // rgba(255,255,255,.085)
    glassEdge: Color(0x17FFFFFF), // rgba(255,255,255,.09)
    sheet: Color(0xFF141418),
    raised: Color(0xFF1C1C21),
    border: Color(0xFF26262D),
    text: Color(0xFFE8EDF5),
    textSecondary: Color(0xFFA3B1C4),
    textMuted: Color(0xFF7D8BA0),
    onButton: Color(0xFFFFFFFF),
    brandButton: Color(0xFF4263EB),
    brandText: Color(0xFF7C93FF),
    brandTint: Color(0xFF1E2A55),
    income: Color(0xFF4ADE80),
    incomeButton: Color(0xFF15803D),
    incomeTint: Color(0xFF15301F),
    expense: Color(0xFFF87171),
    expenseButton: Color(0xFFDC2626),
    expenseTint: Color(0xFF3A1D22),
    lent: Color(0xFF8EA2FF),
    lentTint: Color(0xFF1E2A55),
    borrowed: Color(0xFFF472B6),
    borrowedTint: Color(0xFF3A1A2E),
    dueSoon: Color(0xFFFB923C),
    dueSoonTint: Color(0xFF3A2516),
    premium: Color(0xFFFBBF24),
    premiumButton: Color(0xFFB45309),
    premiumTint: Color(0xFF33260F),
    navGlass: Color(0x8C1C1C22), // rgba(28,28,34,.55)
    navGlassEdge: Color(0x24FFFFFF), // rgba(255,255,255,.14)
    scrim: Color(0x99000000), // rgba(0,0,0,.6)
  );

  @override
  AppColors copyWith() => this;

  /// Theme switches are instant (no colour animation between light and dark).
  @override
  AppColors lerp(AppColors? other, double t) => t < 0.5 ? this : (other ?? this);
}

extension AppColorsContext on BuildContext {
  /// The current theme's colour tokens.
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
