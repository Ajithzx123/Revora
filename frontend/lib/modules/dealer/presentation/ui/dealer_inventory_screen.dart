import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/car_card.dart';
import '../../../../shared/widgets/responsive_card_grid.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../core/network/api_error.dart';
import '../providers/inventory_provider.dart';

class DealerInventoryScreen extends ConsumerWidget {
  const DealerInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryProvider);
    final inventory = inventoryAsync.valueOrNull ?? const [];

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
                inventoryAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.xxxl),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => _Message(
                    icon: Icons.cloud_off_outlined,
                    title: 'Could not load your cars',
                    body: apiErrorMessage(e),
                    action: OutlinedButton(
                      onPressed: () => ref.read(inventoryProvider.notifier).refresh(),
                      child: const Text('Try again'),
                    ),
                  ),
                  data: (items) => items.isEmpty
                      ? const _Message(
                          icon: Icons.directions_car_outlined,
                          title: 'No cars yet',
                          body: 'Add your first car so Revora can match it to buyers.',
                        )
                      : ResponsiveCardGrid(
                          children: [
                            for (final car in items)
                              CarCard(
                                imageUrl: car.imageUrl,
                                title: car.title,
                                priceText: '₹${(car.price / 100000).toStringAsFixed(2)} Lakh',
                                priceLabel: 'Listed',
                                imageHeight: 140,
                                showFavorite: false,
                                onTap: () => context.push('/dealer/edit-car/${car.id}'),
                                badgeText: car.statusLabel.toUpperCase(),
                                badgeBgColor: car.isAvailable ? AppColors.successBg : AppColors.primarySubtle,
                                badgeTextColor: car.isAvailable ? AppColors.success : AppColors.textSecondary,
                                specs: [
                                  CarSpecItem(icon: Icons.speed, label: '${(car.mileage / 1000).toStringAsFixed(0)}k km'),
                                  CarSpecItem(icon: Icons.local_gas_station_outlined, label: car.fuelType),
                                  if (car.images.length > 1)
                                    CarSpecItem(icon: Icons.photo_library_outlined, label: '${car.images.length} photos'),
                                ],
                                primaryAction: OutlinedButton(
                                  onPressed: () => context.push('/dealer/edit-car/${car.id}'),
                                  child: const Text('Edit'),
                                ),
                              ),
                          ],
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

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;
  const _Message({required this.icon, required this.title, required this.body, this.action});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: t.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(body, textAlign: TextAlign.center, style: t.bodySmall),
          if (action != null) ...[const SizedBox(height: AppSpacing.lg), action!],
        ],
      ),
    );
  }
}
