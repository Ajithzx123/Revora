import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/custom_card.dart';
import '../../../../../shared/widgets/custom_button.dart';
import '../../../../../core/utils/price_formatter.dart';

class SellLeadsTab extends StatelessWidget {
  const SellLeadsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock cars customers want to sell in dealer's city
    final sellLeads = [
      {
        'id': 'LST-456',
        'title': '2019 Hyundai Creta SX(O)',
        'askingPrice': 1000000,
        'km': 65000,
        'location': 'Bengaluru',
        'time': '1 hour ago',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sell Leads (Cars for Sale)'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sellLeads.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final lead = sellLeads[index];
          return CustomCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lead['location'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    Text(
                      lead['time'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  lead['title'] as String,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${PriceFormatter.formatKm(lead['km'] as num)} driven',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Asking Price: ${PriceFormatter.formatINR(lead['askingPrice'] as num)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Make Purchase Offer',
                  onPressed: () {
                    context.push('/dealer/make-offer/${lead['id']}');
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
