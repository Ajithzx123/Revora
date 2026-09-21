import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/section_header.dart';
import '../providers/customer_providers.dart';
import '../widgets/requirement_summary_card.dart';
import '../widgets/customer_quote_card.dart';

class CustomerBuyScreen extends ConsumerStatefulWidget {
  const CustomerBuyScreen({super.key});

  @override
  ConsumerState<CustomerBuyScreen> createState() => _CustomerBuyScreenState();
}

class _CustomerBuyScreenState extends ConsumerState<CustomerBuyScreen>
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
    final requirements = ref.watch(customerRequirementsProvider);
    final allQuotes = ref.watch(allCustomerQuotesProvider);

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
                      const Text('My Requirements'),
                      const SizedBox(width: AppSpacing.xs),
                      Badge(
                        label: Text('${requirements.length}'),
                        backgroundColor: AppColors.primarySubtle,
                        textColor: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Quotes Received'),
                      const SizedBox(width: AppSpacing.xs),
                      Badge(
                        label: Text('${allQuotes.length}'),
                        backgroundColor: AppColors.accentLight,
                        textColor: AppColors.accent,
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
                // 1. My Requirements Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Active Requirements',
                            subtitle:
                                'Requirements you posted that are visible to verified dealers',
                            trailing: ElevatedButton.icon(
                              onPressed: () => context.push('/post-requirement'),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('New Requirement'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm),
                                ),
                              ),
                            ),
                          ),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount =
                                  constraints.maxWidth > 700 ? 2 : 1;

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: AppSpacing.md,
                                  mainAxisSpacing: AppSpacing.md,
                                  childAspectRatio: 0.72,
                                ),
                                itemCount: requirements.length,
                                itemBuilder: (context, index) {
                                  return RequirementSummaryCard(
                                    requirement: requirements[index],
                                    onViewQuotes: () {
                                      _tabController.animateTo(1);
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Quotes Received Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: 'Compare Dealer Quotes',
                            subtitle:
                                'Review cars, negotiate prices, and choose your dealer',
                          ),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount =
                                  constraints.maxWidth > 700 ? 2 : 1;

                              return GridView.builder(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: AppSpacing.md,
                                  mainAxisSpacing: AppSpacing.md,
                                  childAspectRatio: 0.72,
                                ),
                                itemCount: allQuotes.length,
                                itemBuilder: (context, index) {
                                  return CustomerQuoteCard(
                                    quote: allQuotes[index],
                                    onContact: () => context.push('/chat'),
                                    onAccept: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Quote accepted! Dealer notified.'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    },
                                  );
                                },
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
