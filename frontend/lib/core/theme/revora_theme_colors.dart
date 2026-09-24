import 'package:flutter/material.dart';
import 'app_colors.dart';

@immutable
class RevoraThemeColors extends ThemeExtension<RevoraThemeColors> {
  final Color cardBg;
  final Color cardBorder;
  final Color cardHoverBorder;
  final Color chipBg;
  final Color chipBorder;
  final Color subtleBg;
  final Color iconBg;
  final Color textMuted;
  final Color divider;
  final Color placeholderBg;
  final Color placeholderIcon;

  // Status colors
  final Color statusSuccessBg;
  final Color statusSuccessFg;
  final Color statusErrorBg;
  final Color statusErrorFg;
  final Color statusWarningBg;
  final Color statusWarningFg;
  final Color statusInfoBg;
  final Color statusInfoFg;

  // Favorite button
  final Color heartLikedBg;
  final Color heartLikedFg;
  final Color heartUnlikedBg;
  final Color heartUnlikedFg;
  final Color heartUnlikedBorder;

  // Sidebar tokens (dark navy brand preserved)
  final Color sidebarBg;
  final Color sidebarBorder;
  final Color sidebarText;
  final Color sidebarTextMuted;
  final Color sidebarSelectedBg;

  // Disabled states
  final Color disabledBg;
  final Color disabledFg;

  // Search & inputs
  final Color searchBg;
  final Color searchBorder;

  // Indicators & accents
  final Color progressBg;
  final Color gradientStart;
  final Color gradientEnd;
  final Color accentSubtle;

  const RevoraThemeColors({
    required this.cardBg,
    required this.cardBorder,
    required this.cardHoverBorder,
    required this.chipBg,
    required this.chipBorder,
    required this.subtleBg,
    required this.iconBg,
    required this.textMuted,
    required this.divider,
    required this.placeholderBg,
    required this.placeholderIcon,
    required this.statusSuccessBg,
    required this.statusSuccessFg,
    required this.statusErrorBg,
    required this.statusErrorFg,
    required this.statusWarningBg,
    required this.statusWarningFg,
    required this.statusInfoBg,
    required this.statusInfoFg,
    required this.heartLikedBg,
    required this.heartLikedFg,
    required this.heartUnlikedBg,
    required this.heartUnlikedFg,
    required this.heartUnlikedBorder,
    required this.sidebarBg,
    required this.sidebarBorder,
    required this.sidebarText,
    required this.sidebarTextMuted,
    required this.sidebarSelectedBg,
    required this.disabledBg,
    required this.disabledFg,
    required this.searchBg,
    required this.searchBorder,
    required this.progressBg,
    required this.gradientStart,
    required this.gradientEnd,
    required this.accentSubtle,
  });

  static RevoraThemeColors buildLight({
    required Color accent,
    required Color accentSubtle,
  }) {
    return RevoraThemeColors(
      cardBg: AppColors.surface,
      cardBorder: const Color(0xFFE2E8F0),
      cardHoverBorder: const Color(0x381F2937),
      chipBg: const Color(0xFFF8FAFC),
      chipBorder: const Color(0xFFE2E8F0),
      subtleBg: AppColors.primarySubtle,
      iconBg: const Color(0xFFF1F5F9),
      textMuted: AppColors.textMuted,
      divider: AppColors.border,
      placeholderBg: const Color(0xFFF8FAFC),
      placeholderIcon: const Color(0xFF94A3B8),
      statusSuccessBg: AppColors.successBg,
      statusSuccessFg: AppColors.success,
      statusErrorBg: AppColors.errorBg,
      statusErrorFg: AppColors.error,
      statusWarningBg: AppColors.warningBg,
      statusWarningFg: AppColors.warning,
      statusInfoBg: AppColors.infoBg,
      statusInfoFg: AppColors.info,
      heartLikedBg: const Color(0xFFFFECEE),
      heartLikedFg: const Color(0xFFEF4444),
      heartUnlikedBg: const Color(0xFFF1F5F9),
      heartUnlikedFg: AppColors.textSecondary,
      heartUnlikedBorder: const Color(0xFFE2E8F0),
      sidebarBg: const Color(0xFF1E293B),
      sidebarBorder: const Color(0xFF334155),
      sidebarText: Colors.white,
      sidebarTextMuted: const Color(0xFF94A3B8),
      sidebarSelectedBg: accentSubtle,
      disabledBg: const Color(0xFFE2E8F0),
      disabledFg: const Color(0xFF94A3B8),
      searchBg: const Color(0xFFF8FAFC),
      searchBorder: const Color(0xFFE2E8F0),
      progressBg: const Color(0xFFE2E8F0),
      gradientStart: AppColors.primary,
      gradientEnd: const Color(0xFF2C3E50),
      accentSubtle: accentSubtle,
    );
  }

  static RevoraThemeColors buildDark({
    required Color accent,
    required Color accentSubtle,
  }) {
    return RevoraThemeColors(
      cardBg: AppColors.surfaceDark,
      cardBorder: AppColors.borderDark,
      cardHoverBorder: const Color(0x7794A3B8),
      chipBg: AppColors.chipBackgroundDark,
      chipBorder: AppColors.chipBorderDark,
      subtleBg: AppColors.primarySubtleDark,
      iconBg: AppColors.iconBgDark,
      textMuted: AppColors.textMutedDark,
      divider: AppColors.borderDark,
      placeholderBg: const Color(0xFF1E2633),
      placeholderIcon: const Color(0xFF64748B),
      statusSuccessBg: AppColors.successBgDark,
      statusSuccessFg: AppColors.successDark,
      statusErrorBg: AppColors.errorBgDark,
      statusErrorFg: const Color(0xFFF87171),
      statusWarningBg: AppColors.warningBgDark,
      statusWarningFg: const Color(0xFFFBBF24),
      statusInfoBg: AppColors.infoBgDark,
      statusInfoFg: const Color(0xFF38BDF8),
      heartLikedBg: const Color(0xFF3A181C),
      heartLikedFg: const Color(0xFFF87171),
      heartUnlikedBg: const Color(0xFF262E3D),
      heartUnlikedFg: const Color(0xFF94A3B8),
      heartUnlikedBorder: const Color(0xFF374558),
      sidebarBg: const Color(0xFF0F172A),
      sidebarBorder: const Color(0xFF1E293B),
      sidebarText: Colors.white,
      sidebarTextMuted: const Color(0xFF64748B),
      sidebarSelectedBg: accentSubtle,
      disabledBg: const Color(0xFF334155),
      disabledFg: const Color(0xFF64748B),
      searchBg: const Color(0xFF1E2633),
      searchBorder: const Color(0xFF374558),
      progressBg: const Color(0xFF334155),
      gradientStart: const Color(0xFF1E2633),
      gradientEnd: const Color(0xFF0F172A),
      accentSubtle: accentSubtle,
    );
  }

  static const RevoraThemeColors light = RevoraThemeColors(
    cardBg: AppColors.surface,
    cardBorder: Color(0xFFE2E8F0),
    cardHoverBorder: Color(0x381F2937),
    chipBg: Color(0xFFF8FAFC),
    chipBorder: Color(0xFFE2E8F0),
    subtleBg: AppColors.primarySubtle,
    iconBg: Color(0xFFF1F5F9),
    textMuted: AppColors.textMuted,
    divider: AppColors.border,
    placeholderBg: Color(0xFFF8FAFC),
    placeholderIcon: Color(0xFF94A3B8),
    statusSuccessBg: AppColors.successBg,
    statusSuccessFg: AppColors.success,
    statusErrorBg: AppColors.errorBg,
    statusErrorFg: AppColors.error,
    statusWarningBg: AppColors.warningBg,
    statusWarningFg: AppColors.warning,
    statusInfoBg: AppColors.infoBg,
    statusInfoFg: AppColors.info,
    heartLikedBg: Color(0xFFFFECEE),
    heartLikedFg: Color(0xFFEF4444),
    heartUnlikedBg: Color(0xFFF1F5F9),
    heartUnlikedFg: AppColors.textSecondary,
    heartUnlikedBorder: Color(0xFFE2E8F0),
    sidebarBg: Color(0xFF1E293B),
    sidebarBorder: Color(0xFF334155),
    sidebarText: Colors.white,
    sidebarTextMuted: Color(0xFF94A3B8),
    sidebarSelectedBg: Color(0x1A4F6EF7),
    disabledBg: Color(0xFFE2E8F0),
    disabledFg: Color(0xFF94A3B8),
    searchBg: Color(0xFFF8FAFC),
    searchBorder: Color(0xFFE2E8F0),
    progressBg: Color(0xFFE2E8F0),
    gradientStart: AppColors.primary,
    gradientEnd: Color(0xFF2C3E50),
    accentSubtle: Color(0x1A4F6EF7),
  );

  static const RevoraThemeColors dark = RevoraThemeColors(
    cardBg: AppColors.surfaceDark,
    cardBorder: AppColors.borderDark,
    cardHoverBorder: Color(0x7794A3B8),
    chipBg: AppColors.chipBackgroundDark,
    chipBorder: AppColors.chipBorderDark,
    subtleBg: AppColors.primarySubtleDark,
    iconBg: AppColors.iconBgDark,
    textMuted: AppColors.textMutedDark,
    divider: AppColors.borderDark,
    placeholderBg: Color(0xFF1E2633),
    placeholderIcon: Color(0xFF64748B),
    statusSuccessBg: AppColors.successBgDark,
    statusSuccessFg: AppColors.successDark,
    statusErrorBg: AppColors.errorBgDark,
    statusErrorFg: Color(0xFFF87171),
    statusWarningBg: AppColors.warningBgDark,
    statusWarningFg: Color(0xFFFBBF24),
    statusInfoBg: AppColors.infoBgDark,
    statusInfoFg: Color(0xFF38BDF8),
    heartLikedBg: Color(0xFF3A181C),
    heartLikedFg: Color(0xFFF87171),
    heartUnlikedBg: Color(0xFF262E3D),
    heartUnlikedFg: Color(0xFF94A3B8),
    heartUnlikedBorder: Color(0xFF374558),
    sidebarBg: Color(0xFF0F172A),
    sidebarBorder: Color(0xFF1E293B),
    sidebarText: Colors.white,
    sidebarTextMuted: Color(0xFF64748B),
    sidebarSelectedBg: Color(0x264F6EF7),
    disabledBg: Color(0xFF334155),
    disabledFg: Color(0xFF64748B),
    searchBg: Color(0xFF1E2633),
    searchBorder: Color(0xFF374558),
    progressBg: Color(0xFF334155),
    gradientStart: Color(0xFF1E2633),
    gradientEnd: Color(0xFF0F172A),
    accentSubtle: Color(0x264F6EF7),
  );

  @override
  ThemeExtension<RevoraThemeColors> copyWith({
    Color? cardBg,
    Color? cardBorder,
    Color? cardHoverBorder,
    Color? chipBg,
    Color? chipBorder,
    Color? subtleBg,
    Color? iconBg,
    Color? textMuted,
    Color? divider,
    Color? placeholderBg,
    Color? placeholderIcon,
    Color? statusSuccessBg,
    Color? statusSuccessFg,
    Color? statusErrorBg,
    Color? statusErrorFg,
    Color? statusWarningBg,
    Color? statusWarningFg,
    Color? statusInfoBg,
    Color? statusInfoFg,
    Color? heartLikedBg,
    Color? heartLikedFg,
    Color? heartUnlikedBg,
    Color? heartUnlikedFg,
    Color? heartUnlikedBorder,
    Color? sidebarBg,
    Color? sidebarBorder,
    Color? sidebarText,
    Color? sidebarTextMuted,
    Color? sidebarSelectedBg,
    Color? disabledBg,
    Color? disabledFg,
    Color? searchBg,
    Color? searchBorder,
    Color? progressBg,
    Color? gradientStart,
    Color? gradientEnd,
    Color? accentSubtle,
  }) {
    return RevoraThemeColors(
      cardBg: cardBg ?? this.cardBg,
      cardBorder: cardBorder ?? this.cardBorder,
      cardHoverBorder: cardHoverBorder ?? this.cardHoverBorder,
      chipBg: chipBg ?? this.chipBg,
      chipBorder: chipBorder ?? this.chipBorder,
      subtleBg: subtleBg ?? this.subtleBg,
      iconBg: iconBg ?? this.iconBg,
      textMuted: textMuted ?? this.textMuted,
      divider: divider ?? this.divider,
      placeholderBg: placeholderBg ?? this.placeholderBg,
      placeholderIcon: placeholderIcon ?? this.placeholderIcon,
      statusSuccessBg: statusSuccessBg ?? this.statusSuccessBg,
      statusSuccessFg: statusSuccessFg ?? this.statusSuccessFg,
      statusErrorBg: statusErrorBg ?? this.statusErrorBg,
      statusErrorFg: statusErrorFg ?? this.statusErrorFg,
      statusWarningBg: statusWarningBg ?? this.statusWarningBg,
      statusWarningFg: statusWarningFg ?? this.statusWarningFg,
      statusInfoBg: statusInfoBg ?? this.statusInfoBg,
      statusInfoFg: statusInfoFg ?? this.statusInfoFg,
      heartLikedBg: heartLikedBg ?? this.heartLikedBg,
      heartLikedFg: heartLikedFg ?? this.heartLikedFg,
      heartUnlikedBg: heartUnlikedBg ?? this.heartUnlikedBg,
      heartUnlikedFg: heartUnlikedFg ?? this.heartUnlikedFg,
      heartUnlikedBorder: heartUnlikedBorder ?? this.heartUnlikedBorder,
      sidebarBg: sidebarBg ?? this.sidebarBg,
      sidebarBorder: sidebarBorder ?? this.sidebarBorder,
      sidebarText: sidebarText ?? this.sidebarText,
      sidebarTextMuted: sidebarTextMuted ?? this.sidebarTextMuted,
      sidebarSelectedBg: sidebarSelectedBg ?? this.sidebarSelectedBg,
      disabledBg: disabledBg ?? this.disabledBg,
      disabledFg: disabledFg ?? this.disabledFg,
      searchBg: searchBg ?? this.searchBg,
      searchBorder: searchBorder ?? this.searchBorder,
      progressBg: progressBg ?? this.progressBg,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      accentSubtle: accentSubtle ?? this.accentSubtle,
    );
  }

  @override
  ThemeExtension<RevoraThemeColors> lerp(
    covariant ThemeExtension<RevoraThemeColors>? other,
    double t,
  ) {
    if (other is! RevoraThemeColors) return this;

    return RevoraThemeColors(
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      cardHoverBorder: Color.lerp(cardHoverBorder, other.cardHoverBorder, t)!,
      chipBg: Color.lerp(chipBg, other.chipBg, t)!,
      chipBorder: Color.lerp(chipBorder, other.chipBorder, t)!,
      subtleBg: Color.lerp(subtleBg, other.subtleBg, t)!,
      iconBg: Color.lerp(iconBg, other.iconBg, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      placeholderBg: Color.lerp(placeholderBg, other.placeholderBg, t)!,
      placeholderIcon: Color.lerp(placeholderIcon, other.placeholderIcon, t)!,
      statusSuccessBg: Color.lerp(statusSuccessBg, other.statusSuccessBg, t)!,
      statusSuccessFg: Color.lerp(statusSuccessFg, other.statusSuccessFg, t)!,
      statusErrorBg: Color.lerp(statusErrorBg, other.statusErrorBg, t)!,
      statusErrorFg: Color.lerp(statusErrorFg, other.statusErrorFg, t)!,
      statusWarningBg: Color.lerp(statusWarningBg, other.statusWarningBg, t)!,
      statusWarningFg: Color.lerp(statusWarningFg, other.statusWarningFg, t)!,
      statusInfoBg: Color.lerp(statusInfoBg, other.statusInfoBg, t)!,
      statusInfoFg: Color.lerp(statusInfoFg, other.statusInfoFg, t)!,
      heartLikedBg: Color.lerp(heartLikedBg, other.heartLikedBg, t)!,
      heartLikedFg: Color.lerp(heartLikedFg, other.heartLikedFg, t)!,
      heartUnlikedBg: Color.lerp(heartUnlikedBg, other.heartUnlikedBg, t)!,
      heartUnlikedFg: Color.lerp(heartUnlikedFg, other.heartUnlikedFg, t)!,
      heartUnlikedBorder: Color.lerp(
        heartUnlikedBorder,
        other.heartUnlikedBorder,
        t,
      )!,
      sidebarBg: Color.lerp(sidebarBg, other.sidebarBg, t)!,
      sidebarBorder: Color.lerp(sidebarBorder, other.sidebarBorder, t)!,
      sidebarText: Color.lerp(sidebarText, other.sidebarText, t)!,
      sidebarTextMuted: Color.lerp(
        sidebarTextMuted,
        other.sidebarTextMuted,
        t,
      )!,
      sidebarSelectedBg: Color.lerp(
        sidebarSelectedBg,
        other.sidebarSelectedBg,
        t,
      )!,
      disabledBg: Color.lerp(disabledBg, other.disabledBg, t)!,
      disabledFg: Color.lerp(disabledFg, other.disabledFg, t)!,
      searchBg: Color.lerp(searchBg, other.searchBg, t)!,
      searchBorder: Color.lerp(searchBorder, other.searchBorder, t)!,
      progressBg: Color.lerp(progressBg, other.progressBg, t)!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      accentSubtle: Color.lerp(accentSubtle, other.accentSubtle, t)!,
    );
  }
}

extension RevoraThemeExtension on BuildContext {
  RevoraThemeColors get revoraColors =>
      Theme.of(this).extension<RevoraThemeColors>() ?? RevoraThemeColors.light;
}
