import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/match_badge.dart';
import '../../../../shared/widgets/spec_chip.dart';
import '../providers/dealer_providers.dart';

class DealerLeadsScreen extends ConsumerStatefulWidget {
  const DealerLeadsScreen({super.key});

  @override
  ConsumerState<DealerLeadsScreen> createState() => _DealerLeadsScreenState();
}

class _DealerLeadsScreenState extends ConsumerState<DealerLeadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buyLeads = ref.watch(dealerBuyLeadsProvider);
    final sellLeads = ref.watch(dealerSellLeadsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Customer Buy Demands'),
                      const SizedBox(width: AppSpacing.xs),
                      Badge(
                        label: Text('${buyLeads.length}'),
                        backgroundColor: AppColors.accentLight,
                        textColor: AppColors.accent,
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Cars for Sale (Acquisition)'),
                      const SizedBox(width: AppSpacing.xs),
                      Badge(
                        label: Text('${sellLeads.length}'),
                        backgroundColor: AppColors.primarySubtle,
                        textColor: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Buy Demands Tab (Send quotes)
                SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: 'Active Customer Requirements',
                            subtitle:
                                'Quote matching cars from your inventory to win deals',
                          ),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: buyLeads.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final lead = buyLeads[index];
                              return Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.radiusMd),
                                  border: Border.all(
                                      color: AppColors.border, width: 0.8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              lead.title,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(
                                                width: AppSpacing.sm),
                                            MatchBadge(
                                                percentage:
                                                    lead.matchPercentage),
                                          ],
                                        ),
                                        Text(
                                          lead.budgetRange,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'Customer: ${lead.customerName} • Preferred: ${lead.customerCity}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Wrap(
                                      spacing: AppSpacing.xs,
                                      runSpacing: AppSpacing.xxs,
                                      children: [
                                        SpecChip(
                                          icon:
                                              Icons.local_gas_station_outlined,
                                          label: lead.fuelType,
                                        ),
                                        SpecChip(
                                          icon: Icons.tune,
                                          label: lead.transmission,
                                        ),
                                        SpecChip(
                                          icon: Icons.chat_bubble_outline,
                                          label:
                                              '${lead.quotesCount} quotes sent',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () => context.push(
                                              '/send-quote/${lead.id}'),
                                          icon:
                                              const Icon(Icons.send, size: 16),
                                          label: const Text('Send Quote'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.accent,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.lg,
                                              vertical: AppSpacing.sm,
                                            ),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppSpacing.radiusSm),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Sell Demands Tab (Dealer acquisition bids)
                SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: 'Customer Cars For Sale',
                            subtitle:
                                'Bid on customer cars to acquire inventory directly',
                          ),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sellLeads.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final lead = sellLeads[index];
                              return Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.radiusMd),
                                  border: Border.all(
                                      color: AppColors.border, width: 0.8),
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusSm),
                                      child: Image.network(
                                        lead.imageUrl,
                                        width: 110,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            Container(
                                          width: 110,
                                          height: 80,
                                          color: AppColors.primarySubtle,
                                          child: const Icon(
                                            Icons.directions_car,
                                            color: AppColors.icon,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  lead.title,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                lead.formattedPrice,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.accent,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: AppSpacing.xxs),
                                          Text(
                                            'Seller: ${lead.customerName} • ${lead.customerCity}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: AppSpacing.xs),
                                          Wrap(
                                            spacing: AppSpacing.xs,
                                            runSpacing: AppSpacing.xxs,
                                            children: [
                                              SpecChip(
                                                icon: Icons.speed,
                                                label:
                                                    '${(lead.mileage / 1000).toStringAsFixed(0)}k km',
                                              ),
                                              SpecChip(
                                                icon: Icons
                                                    .local_gas_station_outlined,
                                                label: lead.fuelType,
                                              ),
                                              SpecChip(
                                                icon: Icons.tune,
                                                label: lead.transmission,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              ElevatedButton(
                                                onPressed: () {
                                                  ScaffoldMessenger.of(
                                                          context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Offer modal opened'),
                                                    ),
                                                  );
                                                },
                                                style:
                                                    ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.accent,
                                                  foregroundColor:
                                                      Colors.white,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: AppSpacing.md,
                                                    vertical: AppSpacing.xs,
                                                  ),
                                                  elevation: 0,
                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            AppSpacing
                                                                .radiusSm),
                                                  ),
                                                ),
                                                child: const Text('Make Offer'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
