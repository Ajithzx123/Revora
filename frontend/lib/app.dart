import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/accent_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'init/route_initializer.dart';

class RevoraApp extends ConsumerWidget {
  const RevoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final accent = ref.watch(accentProvider);

    return MaterialApp.router(
      title: 'Revora',
      theme: AppTheme.buildLight(accent.color, accent.subtle),
      darkTheme: AppTheme.buildDark(accent.color, accent.subtleDark),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
