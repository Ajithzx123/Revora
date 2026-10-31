import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/responsive_card_grid.dart';
import '../widgets/buy_lead_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/kpi_tile.dart';
import '../providers/dealer_providers.dart';

class DealerHomeScreen extends ConsumerWidget {
  const DealerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(dealerKPIsProvider);
    final buyLeads = ref.watch(dealerBuyLeadsProvider);
    final inventory = ref.watch(dealerInventoryProvider);

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
                // 1. Dealer Metrics Grid
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
                          title: 'Active Inventory',
                          value: '${kpis.activeInventory}',
                          icon: Icons.directions_car,
                          iconColor: AppColors.accent,
                          iconBgColor: AppColors.accentLight,
                          trend: '+3 this week',
                          isPositiveTrend: true,
                        ),
                        KpiTile(
                          title: 'Matching Buy Leads',
                          value: '${kpis.buyLeadsMatching}',
                          icon: Icons.bolt,
                          iconColor: AppColors.info,
                          iconBgColor: AppColors.infoBg,
                          trend: 'High demand',
                          isPositiveTrend: true,
                        ),
                        KpiTile(
                          title: 'Quotes Sent',
                          value: '${kpis.quotesSent}',
                          icon: Icons.send_outlined,
                          iconColor: AppColors.warning,
                          iconBgColor: AppColors.warningBg,
                          trend: '${kpis.quotesAccepted} accepted',
                          isPositiveTrend: true,
                        ),
                        KpiTile(
                          title: 'Revenue Generated',
                          value: kpis.formattedRevenue,
                          icon: Icons.currency_rupee,
                          iconColor: AppColors.success,
                          iconBgColor: AppColors.successBg,
                          trend: '${kpis.carsSold} cars sold',
                          isPositiveTrend: true,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xxl),

                // 2. High-Match Customer Requirements Section
                SectionHeader(
                  title: 'High-Match Customer Leads',
                  subtitle:
                      'Direct customer requests matched with your available vehicles',
                  actionLabel: 'View All Leads',
                  onActionTap: () {
                    ref.read(dealerActiveTabProvider.notifier).state = 1;
                  },
                ),
                ResponsiveCardGrid(
                  children: [
                    for (final lead in buyLeads.take(3))
                      BuyLeadCard(
                        lead: lead,
                        onSendQuote: () => context.push('/dealer/send-quote/${lead.id}'),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // 3. Quick Inventory Snapshot
                SectionHeader(
                  title: 'Active Vehicle Inventory',
                  subtitle: '${inventory.length} cars available for quoting',
                  actionLabel: 'Manage All',
                  onActionTap: () {
                    ref.read(dealerActiveTabProvider.notifier).state = 2;
                  },
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 900
                        ? 4
                        : constraints.maxWidth > 600
                        ? 2
                        : 1;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: inventory.length,
                      itemBuilder: (context, index) {
                        final car = inventory[index];
                        return Container(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppSpacing.radiusMd),
                                ),
                                child: Image.network(
                                  car.imageUrl,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    height: 120,
                                    color: AppColors.primarySubtle,
                                    child: const Icon(
                                      Icons.directions_car,
                                      color: AppColors.icon,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      car.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(
                                      '₹${(car.price / 100000).toStringAsFixed(2)} Lakh',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      '${car.mileage} km • ${car.fuelType} • ${car.transmission}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
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
