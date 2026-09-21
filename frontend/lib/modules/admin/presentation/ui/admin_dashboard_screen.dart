import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/kpi_tile.dart';
import '../../../../shared/widgets/activity_tile.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../providers/admin_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(adminKPIsProvider);
    final pendingVerifications = ref.watch(pendingVerificationsProvider);
    final activities = ref.watch(adminActivitiesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Marketplace Performance KPIs
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 900
                        ? 4
                        : constraints.maxWidth > 600
                        ? 2
                        : 2;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: constraints.maxWidth > 600 ? 1.6 : 1.3,
                      children: [
                        KpiTile(
                          title: 'Verified Dealers',
                          value: '${kpis.totalDealers}',
                          icon: Icons.business,
                          iconColor: AppColors.info,
                          iconBgColor: AppColors.infoBg,
                          trend: '+12 this month',
                          isPositiveTrend: true,
                          onTap: () {
                            ref
                                    .read(adminActiveNavIndexProvider.notifier)
                                    .state =
                                1;
                          },
                        ),
                        KpiTile(
                          title: 'Pending Verifications',
                          value: '${pendingVerifications.length}',
                          icon: Icons.pending_actions,
                          iconColor: AppColors.warning,
                          iconBgColor: AppColors.warningBg,
                          trend: 'Action required',
                          isPositiveTrend: false,
                          onTap: () {
                            ref
                                    .read(adminActiveNavIndexProvider.notifier)
                                    .state =
                                1;
                          },
                        ),
                        KpiTile(
                          title: 'Active Requirements',
                          value: '${kpis.activeRequirements}',
                          icon: Icons.assignment_outlined,
                          iconColor: AppColors.accent,
                          iconBgColor: AppColors.accentLight,
                          trend: '+45 today',
                          isPositiveTrend: true,
                          onTap: () {
                            ref
                                    .read(adminActiveNavIndexProvider.notifier)
                                    .state =
                                2;
                          },
                        ),
                        KpiTile(
                          title: 'Marketplace GMV',
                          value: kpis.formattedGmv,
                          icon: Icons.currency_rupee,
                          iconColor: AppColors.success,
                          iconBgColor: AppColors.successBg,
                          trend: '${kpis.monthlyDealsCompleted} deals',
                          isPositiveTrend: true,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xxl),

                // 2. Pending Verifications Quick Actions
                SectionHeader(
                  title: 'Pending Dealer Approvals',
                  subtitle: 'KYC & Trade License verification queue',
                  actionLabel: 'View Queue',
                  onActionTap: () {
                    ref.read(adminActiveNavIndexProvider.notifier).state = 1;
                  },
                ),
                if (pendingVerifications.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    child: const Center(
                      child: Text(
                        'All dealer applications are reviewed and up to date!',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pendingVerifications.take(3).length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final v = pendingVerifications[index];
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: Border.all(
                            color: AppColors.border,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primarySubtle,
                              child: Text(
                                v.businessName[0],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
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
                                      Text(
                                        v.businessName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      StatusChip.fromStatus(v.status),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Owner: ${v.ownerName} • ${v.city} • GST: ${v.gstin}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    ref
                                        .read(adminRepositoryProvider)
                                        .rejectDealer(v.id);
                                    ref
                                        .read(
                                          pendingVerificationsProvider.notifier,
                                        )
                                        .state = ref
                                        .read(adminRepositoryProvider)
                                        .getPendingVerifications();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Application rejected'),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    side: const BorderSide(
                                      color: AppColors.error,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.xs,
                                    ),
                                  ),
                                  child: const Text('Reject'),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                ElevatedButton(
                                  onPressed: () {
                                    ref
                                        .read(adminRepositoryProvider)
                                        .approveDealer(v.id);
                                    ref
                                        .read(
                                          pendingVerificationsProvider.notifier,
                                        )
                                        .state = ref
                                        .read(adminRepositoryProvider)
                                        .getPendingVerifications();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Dealer approved & verified!',
                                        ),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.xs,
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text('Verify & Approve'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: AppSpacing.xxl),

                // 3. Platform Activity Feed
                const SectionHeader(
                  title: 'Platform Audit & Activity Trail',
                  subtitle: 'Recent system events across customers and dealers',
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: activities.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppColors.borderLight),
                    itemBuilder: (context, index) {
                      final act = activities[index];
                      return ActivityTile(
                        title: act.title,
                        subtitle: act.subtitle,
                        time: act.time,
                        icon: act.type == 'flagged'
                            ? Icons.warning_amber_rounded
                            : act.type == 'deal'
                            ? Icons.verified_outlined
                            : Icons.business_outlined,
                        iconColor: act.type == 'flagged'
                            ? AppColors.error
                            : act.type == 'deal'
                            ? AppColors.success
                            : AppColors.info,
                        iconBgColor: act.type == 'flagged'
                            ? AppColors.errorBg
                            : act.type == 'deal'
                            ? AppColors.successBg
                            : AppColors.infoBg,
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
