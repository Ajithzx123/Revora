import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/car_card.dart';
import '../../../../shared/widgets/responsive_card_grid.dart';
import '../../../../shared/widgets/section_header.dart';
import '../providers/dealer_providers.dart';

class DealerInventoryScreen extends ConsumerWidget {
  const DealerInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(dealerInventoryProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/dealer/add-car'),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add vehicle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Your inventory',
                  subtitle: '${inventory.length} cars in your showroom',
                ),
                if (inventory.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'No cars yet. Add your first vehicle so Revora can match it to buyers.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                else
                  ResponsiveCardGrid(
                    children: [
                      for (final car in inventory)
                        CarCard(
                          imageUrl: car.imageUrl,
                          title: car.title,
                          priceText: '₹${(car.price / 100000).toStringAsFixed(2)} Lakh',
                          priceLabel: 'Listed',
                          imageHeight: 140,
                          showFavorite: false,
                          badgeText: car.status.toUpperCase(),
                          badgeBgColor: car.status.toLowerCase() == 'active'
                              ? AppColors.successBg
                              : AppColors.primarySubtle,
                          badgeTextColor: car.status.toLowerCase() == 'active'
                              ? AppColors.success
                              : AppColors.textSecondary,
                          specs: [
                            CarSpecItem(
                              icon: Icons.speed,
                              label: '${(car.mileage / 1000).toStringAsFixed(0)}k km',
                            ),
                            CarSpecItem(icon: Icons.local_gas_station_outlined, label: car.fuelType),
                          ],
                          primaryAction: OutlinedButton(
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Editing vehicles arrives in the next update.')),
                            ),
                            child: const Text('Edit'),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
