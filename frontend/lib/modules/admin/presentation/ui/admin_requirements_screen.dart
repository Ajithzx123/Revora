import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/responsive_data_table.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../domain/entities/admin_ops.dart';
import '../providers/admin_ops_providers.dart';

/// Every buy request on the platform (real data, read-only): how many dealers saw it and quoted.
class AdminRequirementsScreen extends ConsumerWidget {
  const AdminRequirementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requirements = ref.watch(adminRequirementsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminRequirementsProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Buy requirements',
                    subtitle:
                        'Customer demand and how many dealers have responded',
                    trailing: requirements.maybeWhen(
                      data: (p) => Text(
                        p.hasMore
                            ? 'Showing ${p.items.length} of ${p.total}'
                            : '${p.total} total',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      orElse: () => null,
                    ),
                  ),
                  requirements.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => SizedBox(
                      height: 300,
                      child: AppErrorWidget(
                        message: apiErrorMessage(e),
                        onRetry: () =>
                            ref.invalidate(adminRequirementsProvider),
                      ),
                    ),
                    data: (page) => page.items.isEmpty
                        ? const SizedBox(
                            height: 300,
                            child: EmptyStateWidget(
                              icon: Icons.assignment_outlined,
                              title: 'No requirements yet',
                              description:
                                  'Requests customers post will appear here.',
                            ),
                          )
                        : ResponsiveDataTable<AdminRequirementRow>(
                            columns: const [
                              'Request',
                              'Customer',
                              'Budget',
                              'City',
                              'Dealers shown',
                              'Quotes',
                              'Status',
                            ],
                            items: page.items,
                            rowBuilder: (r) => [
                              Text(
                                r.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(r.customerName),
                              Text(
                                PriceFormatter.formatRange(
                                  r.budgetMin,
                                  r.budgetMax,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentDeep,
                                ),
                              ),
                              Text(r.city),
                              Text('${r.matchesCount}'),
                              Text(
                                '${r.quotesCount}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              StatusChip.fromStatus(r.status),
                            ],
                            cardBuilder: (r) => _Card(
                              title: r.title,
                              status: r.status,
                              line1: PriceFormatter.formatRange(
                                r.budgetMin,
                                r.budgetMax,
                              ),
                              line2:
                                  '${r.city} · ${r.matchesCount} dealers shown · ${r.quotesCount} quotes',
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String status;
  final String line1;
  final String line2;
  const _Card({
    required this.title,
    required this.status,
    required this.line1,
    required this.line2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              StatusChip.fromStatus(status),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            line1,
            style: const TextStyle(
              color: AppColors.accentDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            line2,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
