import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/notifications/push_registration.dart';
import 'core/theme/app_theme.dart';
import 'init/route_initializer.dart';

class RevoraApp extends ConsumerWidget {
  const RevoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    ref.watch(
      pushRegistrationProvider,
    ); // keeps this device's push token in step with sign-in

    return MaterialApp.router(
      title: 'Revora',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode
          .light, // light-first; dark follows once screens stop hard-coding colours
      routerConfig: router,
    );
  }
}
