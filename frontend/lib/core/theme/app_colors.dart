import 'package:flutter/material.dart';

/// Internal palette used to configure [AppTheme] and [RevoraThemeColors].
/// Widgets should access theme colors via [Theme.of(context).colorScheme]
/// or [context.revoraColors] instead of referencing this directly.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0F172A); // Deep Executive Navy
  static const Color primaryLight = Color(0xFF1E293B);
  static const Color primaryDark = Color(0xFF000000);
  static const Color accent = Color(0xFF4F6EF7); // Default Accent (Indigo)

  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF2E7D32); // Added success for offers
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorBg = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFED6C02);
  static const Color warningBg = Color(0xFFFFF4E5);
  static const Color info = Color(0xFF0288D1);
  static const Color infoBg = Color(0xFFE1F5FE);

  static const Color accentLight = Color(0xFFFFECE0);
  static const Color primarySubtle = Color(0xFFF1F5F9);

  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color icon = Color(0xFF9CA3AF);

  // Dark Mode colors
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceContainerDark = Color(0xFF252528);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFFD1D5DB);
  static const Color textMutedDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF262626);
  static const Color borderLightDark = Color(0xFF1E1E1E);
  static const Color successDark = Color(0xFF4CAF50);
  static const Color iconDark = Color(0xFF94A3B8);

  static const Color accentLightDark = Color(0xFF382313);
  static const Color primarySubtleDark = Color(0xFF242E3D);
  static const Color chipBackgroundDark = Color(0xFF262E3D);
  static const Color chipBorderDark = Color(0xFF262626);
  static const Color iconBgDark = Color(0xFF262E3D);

  static const Color successBgDark = Color(0xFF132B1A);
  static const Color errorBgDark = Color(0xFF331418);
  static const Color warningBgDark = Color(0xFF362412);
  static const Color infoBgDark = Color(0xFF112536);
}
