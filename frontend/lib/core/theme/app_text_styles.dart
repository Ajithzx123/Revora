import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLarge => GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );

  static TextStyle get headlineLarge => GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );

  static TextStyle get headlineMedium => GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get titleLarge => GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get bodyLarge => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  static TextStyle get bodyMedium => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  static TextStyle get bodySmall => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );

  static TextStyle get labelLarge => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get labelMedium => GoogleFonts.outfit(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get labelSmall => GoogleFonts.outfit(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  // Backward-compatibility aliases during migration
  static TextStyle get displayLargeDark => displayLarge;
  static TextStyle get headlineLargeDark => headlineLarge;
  static TextStyle get headlineMediumDark => headlineMedium;
  static TextStyle get titleLargeDark => titleLarge;
  static TextStyle get bodyLargeDark => bodyLarge;
  static TextStyle get bodyMediumDark => bodyMedium;
  static TextStyle get bodySmallDark => bodySmall;
  static TextStyle get labelLargeDark => labelLarge;
  static TextStyle get labelMediumDark => labelMedium;
  static TextStyle get labelSmallDark => labelSmall;

  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLarge,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    titleLarge: titleLarge,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );

  static TextTheme get lightTextTheme => textTheme;
  static TextTheme get darkTextTheme => textTheme;
}
