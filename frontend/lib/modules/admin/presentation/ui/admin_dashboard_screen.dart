import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../shared/widgets/activity_tile.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/kpi_tile.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/entities/admin_ops.dart';
import '../providers/admin_dealer_review_providers.dart';
import '../providers/admin_ops_providers.dart';
import '../providers/admin_providers.dart';
import 'admin_dealer_detail_screen.dart';

/// Overview: every number is counted by the server, and the activity trail is the real audit log.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(adminKpisProvider);
    final activity = ref.watch(adminRecentActivityProvider);
    String value(String Function(AdminKpis k) pick) =>
        kpis.maybeWhen(data: pick, orElse: () => '—');
    void goTo(int index) =>
        ref.read(adminActiveNavIndexProvider.notifier).state = index;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminKpisProvider);
          ref.invalidate(adminRecentActivityProvider);
          ref.invalidate(adminPendingDealersProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (kpis.hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _Notice(
                        message:
                            'Could not load the numbers. ${apiErrorMessage(kpis.error!)}',
                        onRetry: () => ref.invalidate(adminKpisProvider),
                      ),
                    ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        childAspectRatio: constraints.maxWidth > 600
                            ? 1.6
                            : 1.3,
                        children: [
                          KpiTile(
                            title: 'Verified Dealers',
                            value: value((k) => '${k.activeDealers}'),
                            icon: Icons.business,
                            iconColor: AppColors.info,
                            iconBgColor: AppColors.infoBg,
                            onTap: () => goTo(1),
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
                            onTap: () => goTo(1),
                          ),
                          KpiTile(
                            title: 'Open Requirements',
                            value: value((k) => '${k.openRequirements}'),
                            icon: Icons.assignment_outlined,
                            iconColor: AppColors.accent,
                            iconBgColor: AppColors.accentLight,
                            onTap: () => goTo(2),
                          ),
                          KpiTile(
                            title: 'Deal value (30 days)',
                            value: value(
                              (k) => PriceFormatter.formatINR(
                                k.dealValueLast30Days,
                              ),
                            ),
                            icon: Icons.currency_rupee,
                            iconColor: AppColors.success,
                            iconBgColor: AppColors.successBg,
                            trend: kpis.maybeWhen(
                              data: (k) =>
                                  '${k.dealsLast30Days} ${k.dealsLast30Days == 1 ? 'deal' : 'deals'}',
                              orElse: () => null,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  SectionHeader(
                    title: 'Pending Dealer Approvals',
                    subtitle: 'KYC & Trade License verification queue',
                    actionLabel: 'View Queue',
                    onActionTap: () => goTo(1),
                  ),
                  const _PendingDealersPreview(),
                  const SizedBox(height: AppSpacing.xxl),
                  SectionHeader(
                    title: 'Recent activity',
                    subtitle: 'The latest entries from the audit log',
                    actionLabel: 'Full log',
                    onActionTap: () => goTo(5),
                  ),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    child: activity.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => SizedBox(
                        height: 200,
                        child: AppErrorWidget(
                          message: apiErrorMessage(e),
                          onRetry: () =>
                              ref.invalidate(adminRecentActivityProvider),
                        ),
                      ),
                      data: (items) => items.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(AppSpacing.xl),
                              child: Text('Nothing has happened yet.'),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              itemCount: items.length,
                              separatorBuilder: (_, _) => const Divider(
                                height: 1,
                                color: AppColors.borderLight,
                              ),
                              itemBuilder: (context, index) =>
                                  _activityTile(items[index]),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _activityTile(AuditEntry e) {
    final a = e.action;
    final warn =
        a.contains('VOID') ||
        a.contains('SUSPEND') ||
        a.contains('FROZEN') ||
        a.contains('LARGE_DROP');
    final good =
        a.contains('ACCEPTED') ||
        a.contains('APPROVED') ||
        a.contains('REACTIVATED');
    final who = e.actorName == null ? 'System' : e.actorName!;
    return ActivityTile(
      title: humanizeAction(a),
      subtitle: [who, if (e.reason != null) e.reason!].join(' · '),
      time: Helpers.timeAgo(e.createdAt),
      icon: warn
          ? Icons.warning_amber_rounded
          : good
          ? Icons.verified_outlined
          : Icons.history,
      iconColor: warn
          ? AppColors.error
          : good
          ? AppColors.success
          : AppColors.info,
      iconBgColor: warn
          ? AppColors.errorBg
          : good
          ? AppColors.successBg
          : AppColors.infoBg,
    );
  }
}

class _Notice extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _Notice({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
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
