/// 4px-based spacing and a radius hierarchy: bigger, heavier objects get bigger radii.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double massive = 48.0;

  // Radius hierarchy
  static const double radiusXs = 6.0; // badges, tiny chips
  static const double radiusSm = 10.0; // chips, small icon tiles
  static const double radiusMd = 14.0; // buttons, inputs
  static const double radiusLg = 20.0; // cards
  static const double radiusXl = 28.0; // hero cards, sheets
  static const double radiusPill = 999.0;
}
