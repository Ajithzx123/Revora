import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../../shared/widgets/responsive_data_table.dart';
import '../../../../shared/domain/entities/vehicle.dart';
import '../providers/admin_providers.dart';

class AdminVehiclesScreen extends ConsumerWidget {
  const AdminVehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(platformVehiclesProvider);

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
                  title: 'Platform Vehicle Registry',
                  subtitle:
                      'All vehicles registered and listed across verified dealerships',
                  trailing: Text(
                    '${vehicles.length} Active Listings',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                ResponsiveDataTable<Vehicle>(
                  columns: const [
                    'Car ID',
                    'Vehicle',
                    'Listed By Dealer',
                    'Price',
                    'Specs',
                    'City',
                    'Verified',
                    'Status',
                  ],
                  items: vehicles,
                  rowBuilder: (car) => [
                    Text(
                      car.id,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      car.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(car.dealerName ?? 'Direct Seller'),
                    Text(
                      '₹${(car.price / 100000).toStringAsFixed(2)} Lakh',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                    Text('${car.mileage} km • ${car.fuelType}'),
                    Text(car.city),
                    Icon(
                      car.isVerified ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: car.isVerified
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                    StatusChip.fromStatus(car.status),
                  ],
                  cardBuilder: (car) => Container(
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
                              car.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            StatusChip.fromStatus(car.status),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '₹${(car.price / 100000).toStringAsFixed(2)} Lakh • ${car.dealerName}',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
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
