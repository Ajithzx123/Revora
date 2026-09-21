import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/dealer_match_card.dart';
import '../providers/customer_providers.dart';
import '../widgets/requirement_summary_card.dart';
import '../widgets/customer_quote_card.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requirements = ref.watch(customerRequirementsProvider);
    final allQuotes = ref.watch(allCustomerQuotesProvider);
    final topDealers = ref.watch(topDealersProvider);

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
                // 1. Hero Request Workflow Card
                _buildWorkflowHero(context, ref),
                const SizedBox(height: AppSpacing.xxl),

                // 2. Active Requirements Section
                SectionHeader(
                  title: 'Active Buy Requirements',
                  subtitle: 'Dealers are preparing quotes for your requests',
                  actionLabel: 'View All',
                  onActionTap: () {
                    ref.read(customerActiveTabProvider.notifier).state = 1;
                  },
                ),
                if (requirements.isEmpty)
                  _buildEmptyCard('No active requirements yet')
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: requirements.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final req = requirements[index];
                      return RequirementSummaryCard(
                        requirement: req,
                        onViewQuotes: () {
                          ref.read(customerActiveTabProvider.notifier).state =
                              1;
                        },
                      );
                    },
                  ),
                const SizedBox(height: AppSpacing.xxl),

                // 3. Recent Quotes Received
                SectionHeader(
                  title: 'Recent Quotes Received',
                  subtitle:
                      'Compare pricing, vehicle specs, and dealer ratings',
                  actionLabel: 'Compare All',
                  onActionTap: () {
                    ref.read(customerActiveTabProvider.notifier).state = 1;
                  },
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 900
                        ? 3
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
                      itemCount: allQuotes.length,
                      itemBuilder: (context, index) {
                        return CustomerQuoteCard(
                          quote: allQuotes[index],
                          onContact: () => context.push('/chat'),
                          onAccept: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Quote accepted! Dealer notified.',
                                ),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xxl),

                // 4. Verified Network Dealers
                SectionHeader(
                  title: 'Top Verified Dealers',
                  subtitle: 'Vetted dealerships matching in your area',
                ),
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: topDealers.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final dealer = topDealers[index];
                      return DealerMatchCard(
                        dealer: dealer,
                        onConnect: () => context.push('/chat'),
                        onViewProfile: () {},
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkflowHero(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: const Text(
                  'REQUEST-FIRST MARKETPLACE',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Tell dealers what car you want.\nLet them compete for your deal.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.25,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Skip infinite browsing. Post your requirements or list your car, and get competitive verified dealer quotes directly.',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              ElevatedButton.icon(
                onPressed: () => context.push('/post-requirement'),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Post Buy Requirement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  elevation: 0,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push('/sell-car'),
                icon: const Icon(Icons.sell_outlined, size: 18),
                label: const Text('Sell Your Car'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF475569)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
