import 'package:flutter/painting.dart';

/// Corner radii for smooth continuous (squircle) corners (PRD FR-U3).
abstract final class AppRadii {
  static const double xs = 12;
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 28;

  /// Pills: chips, segmented controls, full-width buttons.
  static const double pill = 999;
}

/// Spacing scale used for padding and gaps.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 40;

  /// Side gutter of every screen.
  static const double screen = 16;
}

abstract final class AppShapes {
  /// Apple-style smooth corner with the given radius.
  static RoundedSuperellipseBorder squircle(double radius, {BorderSide side = BorderSide.none}) =>
      RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(radius), side: side);
}
