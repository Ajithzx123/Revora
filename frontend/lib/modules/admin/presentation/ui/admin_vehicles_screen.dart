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

/// Every car in dealer stock (real data, read-only). The dealer's private minimum price is never shown.
class AdminVehiclesScreen extends ConsumerWidget {
  const AdminVehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(adminVehiclesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminVehiclesProvider.future),
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
                    title: 'Vehicle inventory',
                    subtitle: 'Cars listed by verified dealerships',
                    trailing: vehicles.maybeWhen(
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
                  vehicles.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => SizedBox(
                      height: 300,
                      child: AppErrorWidget(
                        message: apiErrorMessage(e),
                        onRetry: () => ref.invalidate(adminVehiclesProvider),
                      ),
                    ),
                    data: (page) => page.items.isEmpty
                        ? const SizedBox(
                            height: 300,
                            child: EmptyStateWidget(
                              icon: Icons.directions_car_outlined,
                              title: 'No cars listed yet',
                              description:
                                  'Stock dealers add will appear here.',
                            ),
                          )
                        : ResponsiveDataTable<AdminVehicleRow>(
                            columns: const [
                              'Vehicle',
                              'Registration',
                              'Dealer',
                              'Price',
                              'Specs',
                              'City',
                              'Status',
                            ],
                            items: page.items,
                            rowBuilder: (v) => [
                              Text(
                                v.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                v.registrationNo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(v.dealerName),
                              Text(
                                PriceFormatter.formatINR(v.price),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentDeep,
                                ),
                              ),
                              Text(
                                '${PriceFormatter.formatKm(v.km)} · ${v.fuel}',
                              ),
                              Text(v.city),
                              StatusChip.fromStatus(v.status),
                            ],
                            cardBuilder: (v) => Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSm,
                                ),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          v.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      StatusChip.fromStatus(v.status),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    '${PriceFormatter.formatINR(v.price)} · ${v.dealerName}',
                                    style: const TextStyle(
                                      color: AppColors.accentDeep,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    '${v.registrationNo} · ${v.city}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
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
