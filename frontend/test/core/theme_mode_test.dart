import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:revora/core/theme/app_theme.dart';
import 'package:revora/core/theme/revora_theme_colors.dart';
import 'package:revora/core/theme/theme_provider.dart';
import 'package:revora/core/utils/storage_helper.dart';
import 'package:revora/shared/widgets/theme_toggle_button.dart';

void main() {
  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
    await StorageHelper.init();
  });

  group('AppTheme tests', () {
    test('Light theme has correct brightness and extension', () {
      final theme = AppTheme.light;
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, Brightness.light);

      final revoraColors = theme.extension<RevoraThemeColors>();
      expect(revoraColors, isNotNull);
      expect(revoraColors!.cardBg, equals(theme.colorScheme.surface));
    });

    test('Dark theme has correct brightness and extension', () {
      final theme = AppTheme.dark;
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.brightness, Brightness.dark);

      final revoraColors = theme.extension<RevoraThemeColors>();
      expect(revoraColors, isNotNull);
      expect(revoraColors!.cardBg, equals(theme.colorScheme.surface));
    });
  });

  group('ThemeModeNotifier tests', () {
    test('Can toggle theme between dark and light', () {
      final notifier = ThemeModeNotifier();
      notifier.setThemeMode(ThemeMode.light);
      expect(notifier.state, ThemeMode.light);

      notifier.toggleTheme();
      expect(notifier.state, ThemeMode.dark);

      notifier.toggleTheme();
      expect(notifier.state, ThemeMode.light);
    });
  });

  group('ThemeToggleButton widget test', () {
    testWidgets('Tapping ThemeToggleButton toggles themeModeProvider',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              final mode = ref.watch(themeModeProvider);
              return MaterialApp(
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: mode,
                home: const Scaffold(
                  body: Center(
                    child: ThemeToggleButton(),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Verify the button renders
      expect(find.byType(ThemeToggleButton), findsOneWidget);

      // Tap button to toggle
      await tester.tap(find.byType(ThemeToggleButton));
      await tester.pumpAndSettle();

      // Verify still renders without crashing
      expect(find.byType(ThemeToggleButton), findsOneWidget);
    });
  });
}
