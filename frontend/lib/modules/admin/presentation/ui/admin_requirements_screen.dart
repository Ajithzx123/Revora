import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:revora/shared/widgets/section_header.dart';
import 'package:revora/shared/widgets/status_chip.dart';
import 'package:revora/shared/widgets/responsive_data_table.dart';
import 'package:revora/modules/customer/domain/entities/buy_requirement.dart';
import '../providers/admin_providers.dart';

class AdminRequirementsScreen extends ConsumerWidget {
  const AdminRequirementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requirements = ref.watch(platformRequirementsProvider);

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
                SectionHeader(
                  title: 'Marketplace Buy Requirements',
                  subtitle:
                      'Customer demand stream broadcasted to verified network dealers',
                  trailing: Text(
                    '${requirements.length} Active Records',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                ResponsiveDataTable<BuyRequirement>(
                  columns: const [
                    'Req ID',
                    'Requirement',
                    'Budget Range',
                    'Specs',
                    'City',
                    'Quotes',
                    'Status',
                  ],
                  items: requirements,
                  rowBuilder: (req) => [
                    Text(
                      req.id,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      req.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      req.budgetRange,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                    Text('${req.fuelType} • ${req.transmission}'),
                    Text(req.preferredCity),
                    Text(
                      '${req.quotesReceived}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    StatusChip.fromStatus(req.status),
                  ],
                  cardBuilder: (req) => Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              req.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            StatusChip.fromStatus(req.status),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          req.budgetRange,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${req.preferredCity} • ${req.quotesReceived} quotes received',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
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
}
