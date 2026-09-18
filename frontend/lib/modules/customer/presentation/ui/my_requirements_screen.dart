import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/custom_card.dart';

class MyRequirementsScreen extends StatelessWidget {
  const MyRequirementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for UI purposes
    final requirements = [
      {
        'id': 'REQ-123',
        'title': '2020+ Toyota Innova Crysta Diesel',
        'status': 'Collecting Quotes',
        'quotesCount': 3,
        'date': 'Oct 15, 2026',
        'type': 'buy',
      },
      {
        'id': 'LST-456',
        'title': '2019 Hyundai Creta SX(O)',
        'status': 'Offers Received',
        'quotesCount': 2,
        'date': 'Oct 14, 2026',
        'type': 'sell',
      }
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Activity'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: requirements.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final item = requirements[index];
          final isBuy = item['type'] == 'buy';
          return CustomCard(
            onTap: () {
              if (isBuy) {
                context.push('/customer/requirement/${item['id']}');
              } else {
                context.push('/customer/listing/${item['id']}');
              }
            },
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isBuy ? AppColors.primary.withValues(alpha: 0.1) : AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isBuy ? 'BUY' : 'SELL',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isBuy ? AppColors.primary : AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Text(
                      item['date'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item['title'] as String,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item['quotesCount']} ${isBuy ? 'Quotes' : 'Offers'}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        item['status'] as String,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
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
    );
  }
}
