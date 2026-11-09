import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/responsive_card_grid.dart';
import '../../../../shared/widgets/section_header.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_sell_post_card.dart';

class CustomerSellScreen extends ConsumerWidget {
  const CustomerSellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellPosts = ref.watch(customerSellPostsProvider);
    final t = Theme.of(context).textTheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag:
            null, // several tabs each have a "+" button; a shared tag breaks navigation
        onPressed: () => context.push('/customer/post-sell'),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Sell a car'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          96,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HowItWorks(),
                const SizedBox(height: AppSpacing.xxl),
                const SectionHeader(
                  title: 'Your listed cars',
                  subtitle: 'Verified dealers bid on these',
                ),
                if (sellPosts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.directions_car_outlined,
                          size: 44,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text('No cars listed yet', style: t.titleMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'List your car once and dealers compete to buy it.',
                          textAlign: TextAlign.center,
                          style: t.bodySmall,
                        ),
                      ],
                    ),
                  )
                else
                  ResponsiveCardGrid(
                    children: [
                      for (final post in sellPosts)
                        CustomerSellPostCard(
                          post: post,
                          onViewOffers: () =>
                              context.push('/customer/listing/${post.id}'),
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

/// Three steps, shown as a row of numbered tiles on wide screens and a column on phones.
class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  static const _steps = [
    ('Post your car', 'Add details and photos in a couple of minutes.'),
    ('Dealers bid', 'Verified dealers send itemised purchase offers.'),
    ('You choose', 'Compare offers and accept the best one.'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 640;
          final tiles = [
            for (var i = 0; i < _steps.length; i++)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: t.labelLarge?.copyWith(color: AppColors.onAccent),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _steps[i].$1,
                          style: t.titleSmall?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _steps[i].$2,
                          style: t.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ];
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  Expanded(child: tiles[i]),
                  if (i < tiles.length - 1)
                    const SizedBox(width: AppSpacing.xl),
                ],
              ],
            );
          }
          return Column(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                tiles[i],
                if (i < tiles.length - 1) const SizedBox(height: AppSpacing.lg),
              ],
            ],
          );
        },
      ),
    );
  }
}
