import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// One builder for both brightnesses so the two themes cannot drift apart.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final background = isDark ? AppColors.backgroundDark : AppColors.background;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final text = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSoft = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final border = isDark ? AppColors.borderDark : AppColors.border;
    final fill = isDark ? const Color(0xFF1A2438) : AppColors.primarySubtle;
    final ink = isDark
        ? AppColors.textPrimaryDark
        : AppColors.primary; // primary buttons
    final onInk = isDark ? AppColors.primary : Colors.white;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: ink,
      onPrimary: onInk,
      primaryContainer: AppColors.accentLight,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      secondaryContainer: AppColors.accentLight,
      onSecondaryContainer: AppColors.primary,
      tertiary: AppColors.success,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: surface,
      onSurface: text,
      onSurfaceVariant: textSoft,
      surfaceContainerLowest: surface,
      surfaceContainerLow: surface,
      surfaceContainer: fill,
      surfaceContainerHigh: fill,
      surfaceContainerHighest: fill,
      outline: border,
      outlineVariant: isDark ? AppColors.borderDark : AppColors.borderLight,
      surfaceTint: Colors.transparent,
      shadow: Colors.black,
    );

    // DM Sans for reading, Sora for headlines.
    final base = GoogleFonts.dmSansTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).apply(bodyColor: text, displayColor: text);
    TextStyle sora(
      double size,
      FontWeight w, {
      double spacing = -0.3,
      double height = 1.2,
    }) => GoogleFonts.sora(
      fontSize: size,
      fontWeight: w,
      color: text,
      letterSpacing: spacing,
      height: height,
    );
    final textTheme = base.copyWith(
      displayLarge: sora(34, FontWeight.w700, spacing: -0.8, height: 1.1),
      displayMedium: sora(30, FontWeight.w700, spacing: -0.7, height: 1.1),
      displaySmall: sora(26, FontWeight.w700, spacing: -0.5, height: 1.15),
      headlineLarge: sora(28, FontWeight.w700, spacing: -0.6, height: 1.15),
      headlineMedium: sora(22, FontWeight.w600),
      headlineSmall: sora(20, FontWeight.w600),
      titleLarge: sora(18, FontWeight.w600, spacing: -0.2, height: 1.25),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 15, height: 1.45),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 13,
        color: textSoft,
        height: 1.4,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    );
    final buttonText = GoogleFonts.dmSans(
      fontSize: 15,
      fontWeight: FontWeight.w700,
    );
    const buttonSize = Size(64, 52); // 52dp: comfortable thumb target

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: sora(18, FontWeight.w700, spacing: -0.3),
        iconTheme: IconThemeData(color: text),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: onInk,
          disabledBackgroundColor: fill,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: onInk,
          disabledBackgroundColor: fill,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          minimumSize: buttonSize,
          shape: buttonShape,
          side: BorderSide(color: border, width: 1.4),
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppColors.accent : AppColors.accentDeep,
          minimumSize: const Size(48, 48),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: text,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: inputBorder(border),
        enabledBorder: inputBorder(border),
        disabledBorder: inputBorder(scheme.outlineVariant),
        focusedBorder: inputBorder(text, 1.8),
        errorBorder: inputBorder(AppColors.error),
        focusedErrorBorder: inputBorder(AppColors.error, 1.8),
        labelStyle: GoogleFonts.dmSans(fontSize: 15, color: textSoft),
        floatingLabelStyle: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        hintStyle: GoogleFonts.dmSans(fontSize: 15, color: AppColors.textMuted),
        errorStyle: GoogleFonts.dmSans(fontSize: 12.5, color: AppColors.error),
        prefixIconColor: textSoft,
        suffixIconColor: textSoft,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: ink,
        disabledColor: fill,
        side: BorderSide(color: border),
        labelStyle: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        secondaryLabelStyle: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: onInk,
        ),
        checkmarkColor: onInk,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.accent,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: text,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.onAccent
                : textSoft,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: text,
        unselectedLabelColor: textSoft,
        labelStyle: GoogleFonts.dmSans(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: UnderlineTabIndicator(
          borderSide: const BorderSide(color: AppColors.accent, width: 3),
          borderRadius: BorderRadius.circular(3),
        ),
        dividerColor: scheme.outlineVariant,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        titleTextStyle: sora(19, FontWeight.w700),
        contentTextStyle: GoogleFonts.dmSans(
          fontSize: 15,
          color: textSoft,
          height: 1.45,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        contentTextStyle: GoogleFonts.dmSans(
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.accent : border,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        textStyle: GoogleFonts.dmSans(fontSize: 12.5, color: Colors.white),
      ),
    );
  }
}
