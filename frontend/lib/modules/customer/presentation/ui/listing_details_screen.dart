import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/offer_card.dart';

class ListingDetailsScreen extends StatelessWidget {
  final String listingId;

  const ListingDetailsScreen({
    super.key,
    required this.listingId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offers Received'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Listing: 2019 Hyundai Creta SX(O)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Expected: ₹10 Lakh  |  65,000km', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Dealer Offers (2)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            OfferCard(
              dealerName: 'City Pre-owned',
              dealerRating: 4.5,
              isVerified: true,
              offerPrice: 1020000,
              askingPrice: 1000000,
              onChatPressed: () {
                context.push('/chat/chat-4');
              },
              onAcceptPressed: () {},
            ),
            const SizedBox(height: 16),
            OfferCard(
              dealerName: 'Fast Deals Cars',
              dealerRating: 4.1,
              isVerified: false,
              offerPrice: 950000,
              askingPrice: 1000000,
              onChatPressed: () {
                context.push('/chat/chat-5');
              },
              onAcceptPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
