import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/quote_comparison_card.dart';

class RequirementDetailsScreen extends StatelessWidget {
  final String requirementId;

  const RequirementDetailsScreen({
    super.key,
    required this.requirementId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotes Received'),
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
                    'Requirement: 2020+ Toyota Innova Crysta Diesel',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Budget: ₹15 - ₹20 Lakh  |  Bengaluru', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dealer Quotes (3)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    context.push('/customer/compare/$requirementId');
                  },
                  icon: const Icon(Icons.compare_arrows, color: AppColors.primary),
                  label: const Text('Compare All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            QuoteComparisonCard(
              dealerName: 'Prime Motors',
              dealerRating: 4.8,
              isVerified: true,
              carDetails: '2021 Innova Crysta ZX 2.4 Diesel, 45,000km',
              quotedPrice: 1850000,
              onChatPressed: () {
                context.push('/chat/chat-1');
              },
              onAcceptPressed: () {},
            ),
            const SizedBox(height: 16),
            QuoteComparisonCard(
              dealerName: 'Value Autos',
              dealerRating: 4.2,
              isVerified: false,
              carDetails: '2020 Innova Crysta VX 2.4 Diesel, 60,000km',
              quotedPrice: 1700000,
              onChatPressed: () {
                context.push('/chat/chat-2');
              },
              onAcceptPressed: () {},
            ),
            const SizedBox(height: 16),
            QuoteComparisonCard(
              dealerName: 'Elite Car Hub',
              dealerRating: 4.9,
              isVerified: true,
              carDetails: '2022 Innova Crysta G 2.4 Diesel, 30,000km',
              quotedPrice: 1950000,
              onChatPressed: () {
                context.push('/chat/chat-3');
              },
              onAcceptPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
