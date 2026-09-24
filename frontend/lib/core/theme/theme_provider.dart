import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../utils/storage_helper.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_getInitialTheme());

  static ThemeMode _getInitialTheme() {
    try {
      final saved = StorageHelper.getString(AppConstants.prefThemeMode);
      if (saved == 'dark') return ThemeMode.dark;
      if (saved == 'light') return ThemeMode.light;
      if (saved == 'system') return ThemeMode.system;
    } catch (_) {
      // Fallback gracefully if called during tests without storage init
    }
    return ThemeMode.system;
  }

  void toggleTheme() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(next);
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    try {
      StorageHelper.setString(AppConstants.prefThemeMode, mode.name)
          .catchError((_) => false);
    } catch (_) {
      // Fallback gracefully in testing environments
    }
  }
}
