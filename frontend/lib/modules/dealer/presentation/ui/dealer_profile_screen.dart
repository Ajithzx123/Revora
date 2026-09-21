import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class DealerProfileScreen extends ConsumerWidget {
  const DealerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final fullName = user?.fullName ?? 'Apex Motor Corp (Vikram Malhotra)';
    final email = user?.email ?? 'dealer@revora.com';
    final phone = user?.phone ?? '+91 98205 99881';
    final initials = fullName.isNotEmpty
        ? fullName
            .trim()
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((e) => e[0])
            .take(2)
            .join()
            .toUpperCase()
        : 'AM';

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
                  title: 'Dealership Profile',
                  subtitle:
                      'Public profile, verification documents, and team members',
                ),

                // Dealership Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    fullName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                const Icon(
                                  Icons.verified,
                                  color: AppColors.info,
                                  size: 16,
                                ),
                              ],
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
                        child: const Text('Edit Profile'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Operational Settings
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
                        title: 'Operating Locations',
                        subtitle: 'Mumbai (Andheri, Bandra), Navi Mumbai',
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () {},
                      ),
                      const Divider(height: 1, color: AppColors.borderLight),
                      _buildSettingsTile(
                        icon: Icons.notifications_active_outlined,
                        title: 'Instant Lead Alerts',
                        subtitle:
                            'Receive high-match leads via WhatsApp immediately',
                        trailing: Switch(
                          value: true,
                          onChanged: (_) {},
                          activeThumbColor: AppColors.accent,
                        ),
                        onTap: () {},
                      ),
                      const Divider(height: 1, color: AppColors.borderLight),
                      _buildSettingsTile(
                        icon: Icons.document_scanner_outlined,
                        title: 'Compliance & Verification',
                        subtitle:
                            'Trade license, GST, Dealership registration verified',
                        trailing: const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 20,
                        ),
                        onTap: () {},
                      ),
                      const Divider(height: 1, color: AppColors.borderLight),
                      _buildSettingsTile(
                        icon: Icons.people_outline,
                        title: 'Sales Team Members',
                        subtitle: '3 active sales reps quoting leads',
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

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
                      'Log Out of Dealership Portal',
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
