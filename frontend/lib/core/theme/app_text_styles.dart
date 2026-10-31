import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Sora for headlines and prices (geometric, confident); DM Sans for everything
/// you read (warm, very legible). Two families, three weights.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _head(double size, FontWeight weight, Color color,
          {double height = 1.2, double spacing = -0.3}) =>
      GoogleFonts.sora(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: spacing,
      );

  static TextStyle _body(double size, FontWeight weight, Color color,
          {double height = 1.45, double spacing = 0}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: spacing,
      );

  // ---- Light ----
  static TextStyle get displayLarge => _head(34, FontWeight.w700, AppColors.textPrimary, height: 1.1, spacing: -0.8);
  static TextStyle get headlineLarge => _head(28, FontWeight.w700, AppColors.textPrimary, height: 1.15, spacing: -0.6);
  static TextStyle get headlineMedium => _head(22, FontWeight.w600, AppColors.textPrimary, height: 1.2);
  static TextStyle get titleLarge => _head(18, FontWeight.w600, AppColors.textPrimary, height: 1.25, spacing: -0.2);
  static TextStyle get bodyLarge => _body(16, FontWeight.w400, AppColors.textPrimary, height: 1.5);
  static TextStyle get bodyMedium => _body(15, FontWeight.w400, AppColors.textSecondary);
  static TextStyle get bodySmall => _body(13, FontWeight.w400, AppColors.textSecondary, height: 1.4);
  static TextStyle get labelLarge => _body(15, FontWeight.w700, AppColors.textPrimary, height: 1.3);
  static TextStyle get labelMedium => _body(13, FontWeight.w600, AppColors.textPrimary, height: 1.3);
  static TextStyle get labelSmall => _body(11.5, FontWeight.w600, AppColors.textSecondary, height: 1.3, spacing: 0.2);

  /// Prices and big numbers: tabular figures so columns of prices line up.
  static TextStyle get price => _head(22, FontWeight.w700, AppColors.textPrimary, height: 1.1, spacing: -0.4)
      .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// Small caps-style section label.
  static TextStyle get overline => _body(11, FontWeight.w700, AppColors.textSecondary, height: 1.3, spacing: 1.1);

  // ---- Dark ----
  static TextStyle get displayLargeDark => displayLarge.copyWith(color: AppColors.textPrimaryDark);
  static TextStyle get headlineLargeDark => headlineLarge.copyWith(color: AppColors.textPrimaryDark);
  static TextStyle get headlineMediumDark => headlineMedium.copyWith(color: AppColors.textPrimaryDark);
  static TextStyle get titleLargeDark => titleLarge.copyWith(color: AppColors.textPrimaryDark);
  static TextStyle get bodyLargeDark => bodyLarge.copyWith(color: AppColors.textPrimaryDark);
  static TextStyle get bodyMediumDark => bodyMedium.copyWith(color: AppColors.textSecondaryDark);
  static TextStyle get bodySmallDark => bodySmall.copyWith(color: AppColors.textSecondaryDark);
  static TextStyle get labelLargeDark => labelLarge.copyWith(color: AppColors.textPrimaryDark);
  static TextStyle get labelMediumDark => labelMedium.copyWith(color: AppColors.textPrimaryDark);
  static TextStyle get labelSmallDark => labelSmall.copyWith(color: AppColors.textSecondaryDark);
}
