import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/price_formatter.dart';
import '../../../../../shared/widgets/offer_card.dart';
import '../providers/customer_providers.dart';

class ListingDetailsScreen extends ConsumerWidget {
  final String listingId;

  const ListingDetailsScreen({
    super.key,
    required this.listingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellPosts = ref.watch(customerSellPostsProvider);
    final post = sellPosts.firstWhere(
      (p) => p.id == listingId,
      orElse: () => sellPosts.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offers Received'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${post.year} ${post.make} ${post.model} ${post.variant}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          post.status.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Asking: ${PriceFormatter.formatINR(post.expectedPrice)}  •  ${PriceFormatter.formatKm(post.mileage)}  •  ${post.fuelType}  •  ${post.city}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Dealer Offers (${post.offersCount})',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            OfferCard(
              dealerName: 'City Pre-owned',
              dealerRating: 4.8,
              isVerified: true,
              offerPrice: (post.expectedPrice * 1.02).round(),
              askingPrice: post.expectedPrice,
              onChatPressed: () {
                context.push('/chat/DLR-01');
              },
              onAcceptPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Offer accepted! Dealer notified.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            OfferCard(
              dealerName: 'Fast Deals Cars',
              dealerRating: 4.5,
              isVerified: false,
              offerPrice: (post.expectedPrice * 0.95).round(),
              askingPrice: post.expectedPrice,
              onChatPressed: () {
                context.push('/chat/DLR-02');
              },
              onAcceptPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Offer accepted! Dealer notified.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
