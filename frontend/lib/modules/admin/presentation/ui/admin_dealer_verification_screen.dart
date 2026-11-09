import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../dealer/domain/entities/dealer_application.dart';
import '../../domain/repositories/admin_dealer_review_repository.dart';
import '../providers/admin_dealer_review_providers.dart';
import 'admin_dealer_detail_screen.dart';

/// Queue of dealer applications. Open one to review its documents and decide.
class AdminDealerVerificationScreen extends ConsumerWidget {
  const AdminDealerVerificationScreen({super.key});

  static const _filters = <(String, DealerStatus?)>[
    ('Pending', DealerStatus.pending),
    ('Needs changes', DealerStatus.needsChanges),
    ('Approved', DealerStatus.approved),
    ('Suspended', DealerStatus.suspended),
    ('Rejected', DealerStatus.rejected),
    ('All', null),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(adminDealerStatusFilterProvider);
    final dealers = ref.watch(adminDealerListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(adminDealerListProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Dealer applications',
                      subtitle:
                          'Review documents, then approve, request changes or reject',
                    ),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final (label, status) in _filters)
                          ChoiceChip(
                            label: Text(label),
                            selected: selected == status,
                            onSelected: (_) =>
                                ref
                                        .read(
                                          adminDealerStatusFilterProvider
                                              .notifier,
                                        )
                                        .state =
                                    status,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    dealers.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSpacing.xxl),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => _Message(
                        icon: Icons.cloud_off_outlined,
                        text: apiErrorMessage(e),
                        action: OutlinedButton(
                          onPressed: () =>
                              ref.invalidate(adminDealerListProvider),
                          child: const Text('Try again'),
                        ),
                      ),
                      data: (items) => items.isEmpty
                          ? const _Message(
                              icon: Icons.inbox_outlined,
                              text: 'No dealer applications in this list.',
                            )
                          : Column(
                              children: [
                                for (final d in items) ...[
                                  _DealerCard(dealer: d),
                                  const SizedBox(height: AppSpacing.md),
                                ],
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;
  const _Message({required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }
}

class _DealerCard extends StatelessWidget {
  final DealerSummary dealer;
  const _DealerCard({required this.dealer});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = statusStyle(dealer.status);
    final submitted = dealer.submittedAt;
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdminDealerDetailScreen(dealerId: dealer.id),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                dealer.businessName.isEmpty
                    ? 'D'
                    : dealer.businessName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dealer.businessName, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    submitted == null
                        ? dealer.city
                        : '${dealer.city} · submitted ${submitted.day}/${submitted.month}/${submitted.year}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Label, text colour and tint for a dealer status (design system status vocabulary).
(String, Color, Color) statusStyle(DealerStatus status) => switch (status) {
  DealerStatus.draft => (
    'Draft',
    AppColors.textSecondary,
    AppColors.primarySubtle,
  ),
  DealerStatus.pending => ('Pending', AppColors.warning, AppColors.warningBg),
  DealerStatus.needsChanges => (
    'Needs changes',
    AppColors.warning,
    AppColors.warningBg,
  ),
  DealerStatus.approved => ('Approved', AppColors.success, AppColors.successBg),
  DealerStatus.rejected => ('Rejected', AppColors.error, AppColors.errorBg),
  DealerStatus.suspended => ('Suspended', AppColors.error, AppColors.errorBg),
};
