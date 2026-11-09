import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/kpi_tile.dart';
import '../../../../shared/widgets/activity_tile.dart';
import '../../../../core/network/api_error.dart';
import '../providers/admin_dealer_review_providers.dart';
import '../providers/admin_providers.dart';
import 'admin_dealer_detail_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(adminKPIsProvider);
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
                          value: ref
                              .watch(adminPendingDealersProvider)
                              .maybeWhen(
                                data: (items) => '${items.length}',
                                orElse: () => '—',
                              ),
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
                const _PendingDealersPreview(),
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

/// The first few dealer applications waiting for review (real data).
class _PendingDealersPreview extends ConsumerWidget {
  const _PendingDealersPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(adminPendingDealersProvider);

    Widget box(Widget child) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: child,
    );

    return pending.when(
      loading: () => box(const Center(child: CircularProgressIndicator())),
      error: (e, _) => box(
        Text(
          apiErrorMessage(e),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
      data: (items) => items.isEmpty
          ? box(
              const Center(
                child: Text(
                  'No dealer applications are waiting for review.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          : Column(
              children: [
                for (final d in items.take(3)) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.businessName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                d.city,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdminDealerDetailScreen(dealerId: d.id),
                            ),
                          ),
                          child: const Text('Review'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
    );
  }
}
