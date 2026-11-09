import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../providers/notifications_providers.dart';

/// Push on/off per category. The in-app list always keeps everything, and account
/// and deal-critical alerts cannot be switched off.
class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  static const _labels = {
    'LEADS': (
      'New buyer requests',
      'Dealers: requests that match your stock or sourcing.',
    ),
    'QUOTES': (
      'Quotes and counter-offers',
      'New prices, revisions and replies.',
    ),
    'DEALS': ('Deal updates', 'Accepted and not-selected quotes.'),
    'MARKETING': ('Tips and offers', 'Product news. Never required.'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPrefsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notification settings')),
      body: prefs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: apiErrorMessage(e),
          onRetry: () => ref.invalidate(notificationPrefsProvider),
        ),
        data: (values) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    'Choose which alerts reach your phone. Everything still appears in your notification list. '
                    'Account and deal-critical alerts, like verification decisions and accepted quotes, are always sent.',
                  ),
                ),
                for (final c in _labels.keys)
                  SwitchListTile(
                    // Disabled while a change is saving so a second tap cannot race the first.
                    value: values[c] ?? true,
                    onChanged: prefs.isLoading
                        ? null
                        : (v) => ref
                              .read(notificationPrefsProvider.notifier)
                              .setPush(c, v),
                    title: Text(_labels[c]!.$1),
                    subtitle: Text(_labels[c]!.$2),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
