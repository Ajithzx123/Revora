import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/accent_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/revora_theme_colors.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'appearance_settings_screen.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final revora = context.revoraColors;
    final accent = ref.watch(accentProvider);
    final user = ref.watch(authControllerProvider).user;
    final fullName = user?.fullName ?? 'Rahul Verma';
    final email = user?.email ?? 'buyer@revora.com';
    final phone = user?.phone ?? '+91 98201 12345';
    final initials = fullName.isNotEmpty
        ? fullName
            .trim()
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((e) => e[0])
            .take(2)
            .join()
            .toUpperCase()
        : 'RV';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Account & Settings',
                  subtitle:
                      'Manage your profile, preferences, and contact details',
                ),

                // User card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: revora.cardBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: revora.cardBorder, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: accent.color,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$phone • $email',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: revora.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: revora.cardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                        ),
                        child: const Text('Edit'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Preferences section
                Container(
                  decoration: BoxDecoration(
                    color: revora.cardBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: revora.cardBorder, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        context: context,
                        icon: Icons.palette_outlined,
                        title: 'Appearance & Theme',
                        subtitle: '${accent.label} accent • Theme mode & colors',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: accent.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            const Icon(Icons.chevron_right, size: 20),
                          ],
                        ),
                        onTap: () => AppearanceSettingsSheet.show(context),
                      ),
                      Divider(height: 1, color: revora.divider),
                      _buildSettingsTile(
                        context: context,
                        icon: Icons.location_on_outlined,
                        title: 'Preferred City',
                        subtitle: 'Mumbai (MMR)',
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () {},
                      ),
                      Divider(height: 1, color: revora.divider),
                      _buildSettingsTile(
                        context: context,
                        icon: Icons.notifications_none_outlined,
                        title: 'Quote Alerts & WhatsApp Updates',
                        subtitle:
                            'Receive quotes immediately when dealers respond',
                        trailing: Switch(
                          value: true,
                          onChanged: (_) {},
                          activeThumbColor: accent.color,
                        ),
                        onTap: () {},
                      ),
                      Divider(height: 1, color: revora.divider),
                      _buildSettingsTile(
                        context: context,
                        icon: Icons.security_outlined,
                        title: 'Privacy & Security',
                        subtitle: 'Control who sees your contact details',
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () {},
                      ),
                      Divider(height: 1, color: revora.divider),
                      _buildSettingsTile(
                        context: context,
                        icon: Icons.help_outline,
                        title: 'Help & Marketplace Support',
                        subtitle: 'FAQ and concierge assistance',
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Logout button
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    icon: const Icon(
                      Icons.logout,
                      color: AppColors.error,
                      size: 18,
                    ),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final revora = context.revoraColors;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.secondary),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: revora.textMuted,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
