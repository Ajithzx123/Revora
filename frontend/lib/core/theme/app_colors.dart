import 'package:flutter/material.dart';

/// Revora "Showroom" palette. Named by role, not by hue.
///
/// Warm canvas + deep ink surfaces, with one ignition-orange accent and a
/// signal green reserved for savings and success. Contrast notes:
///  - [textPrimary]/[textSecondary] on [surface]/[background] pass 4.5:1.
///  - White on [accent] is only ~3.6:1: use [onAccent] (ink) for text on orange,
///    and [accentDeep] for orange text on light backgrounds.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF0B1324); // ink
  static const Color primaryLight = Color(0xFF1B2740);
  static const Color primaryDark = Color(0xFF050A14);
  static const Color accent = Color(0xFFF2650C); // ignition orange
  static const Color accentDeep = Color(0xFFB9480A); // orange for small text on light
  static const Color onAccent = Color(0xFF0B1324); // text/icons on orange
  static const Color accentLight = Color(0xFFFFE9DA);

  // Surfaces
  static const Color background = Color(0xFFF5F3EE); // warm canvas
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primarySubtle = Color(0xFFEEEBE4); // quiet fills, inputs, chips
  static const Color border = Color(0xFFE4E0D7);
  static const Color borderLight = Color(0xFFEFECE5);

  // Text
  static const Color textPrimary = Color(0xFF0B1324);
  static const Color textSecondary = Color(0xFF475060);
  static const Color textMuted = Color(0xFF7B8494); // decorative / non-essential only
  static const Color icon = Color(0xFF7B8494);

  // Status (each has a tint for backgrounds)
  static const Color success = Color(0xFF0B7A55); // signal green: savings, approved
  static const Color successBg = Color(0xFFE3F4EC);
  static const Color warning = Color(0xFFB45309);
  static const Color warningBg = Color(0xFFFDF0DC);
  static const Color error = Color(0xFFC62F2F);
  static const Color errorBg = Color(0xFFFCE8E6);
  static const Color info = Color(0xFF1D5FD1);
  static const Color infoBg = Color(0xFFE6EEFC);

  // Dark theme (kept in step with the light palette; the app ships light-first)
  static const Color backgroundDark = Color(0xFF0A101D);
  static const Color surfaceDark = Color(0xFF131C2E);
  static const Color textPrimaryDark = Color(0xFFF3F1EC);
  static const Color textSecondaryDark = Color(0xFFB4BBC8);
  static const Color borderDark = Color(0xFF263149);
  static const Color successDark = Color(0xFF34C48B);
}
