import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      backgroundColor: AppColors.background,
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
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.accent,
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
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$phone • $email',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
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
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        icon: Icons.location_on_outlined,
                        title: 'Preferred City',
                        subtitle: 'Mumbai (MMR)',
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () {},
                      ),
                      const Divider(height: 1, color: AppColors.borderLight),
                      _buildSettingsTile(
                        icon: Icons.notifications_none_outlined,
                        title: 'Quote Alerts & WhatsApp Updates',
                        subtitle:
                            'Receive quotes immediately when dealers respond',
                        trailing: Switch(
                          value: true,
                          onChanged: (_) {},
                          activeThumbColor: AppColors.accent,
                        ),
                        onTap: () {},
                      ),
                      const Divider(height: 1, color: AppColors.borderLight),
                      _buildSettingsTile(
                        icon: Icons.security_outlined,
                        title: 'Privacy & Security',
                        subtitle: 'Control who sees your contact details',
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () {},
                      ),
                      const Divider(height: 1, color: AppColors.borderLight),
                      _buildSettingsTile(
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
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
