import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/section_header.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_sell_post_card.dart';

class CustomerSellScreen extends ConsumerWidget {
  const CustomerSellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellPosts = ref.watch(customerSellPostsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Callout banner: How Selling on Revora works
                _buildHowItWorksBanner(context),
                const SizedBox(height: AppSpacing.xxl),

                SectionHeader(
                  title: 'My Listed Cars',
                  subtitle: 'Cars you put up for verified dealers to bid on',
                  trailing: ElevatedButton.icon(
                    onPressed: () => context.push('/sell-car'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Sell Another Car'),
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
                          AppSpacing.radiusSm,
                        ),
                      ),
                    ),
                  ),
                ),

                if (sellPosts.isEmpty)
                  _buildEmptyState(context)
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 700 ? 2 : 1;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: sellPosts.length,
                        itemBuilder: (context, index) {
                          return CustomerSellPostCard(
                            post: sellPosts[index],
                            onViewOffers: () {
                              // TODO: Navigate to offers
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
    );
  }

  Widget _buildHowItWorksBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: AppColors.accent,
                size: 20,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'How Selling Works on Revora',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            '1. Post your car details & upload photos\n2. Verified dealers evaluate & submit direct purchase bids\n3. Compare bids and pick the highest offer with no hidden cuts',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.directions_car_outlined,
              size: 48,
              color: AppColors.icon,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'No cars listed for sale yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Sell directly to network dealers at the best market price',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => context.push('/sell-car'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Post Car for Sale'),
            ),
          ],
        ),
      ),
    );
  }
}
