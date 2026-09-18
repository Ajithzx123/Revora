import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/price_formatter.dart';
import '../../../../../shared/widgets/custom_button.dart';

class QuoteComparisonScreen extends StatelessWidget {
  final String requirementId;

  const QuoteComparisonScreen({
    super.key,
    required this.requirementId,
  });

  @override
  Widget build(BuildContext context) {
    // Mock data for side-by-side comparison
    final quotes = [
      {
        'dealer': 'Prime Motors',
        'rating': 4.8,
        'car': '2021 Innova Crysta ZX 2.4',
        'price': 1850000,
        'km': 45000,
        'perks': '1 Year Dealer Warranty',
      },
      {
        'dealer': 'Elite Car Hub',
        'rating': 4.9,
        'car': '2022 Innova Crysta G 2.4',
        'price': 1950000,
        'km': 30000,
        'perks': 'Free Service, Extended Warranty',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Quotes'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: quotes.map((quote) => _buildComparisonColumn(context, quote)).toList(),
        ),
      ),
    );
  }

  Widget _buildComparisonColumn(BuildContext context, Map<String, dynamic> quote) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Column(
              children: [
                Text(
                  quote['dealer'] as String,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: AppColors.accent, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${quote['rating']}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRow('Car', quote['car'] as String, context),
                const Divider(height: 24),
                _buildRow('Price', PriceFormatter.formatINR(quote['price'] as num), context, isHighlight: true),
                const Divider(height: 24),
                _buildRow('Km Driven', PriceFormatter.formatKm(quote['km'] as num), context),
                const Divider(height: 24),
                _buildRow('Perks', quote['perks'] as String, context),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Chat with Dealer',
                  onPressed: () {
                    context.push('/chat/chat-compare');
                  },
                  variant: ButtonVariant.outline,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Accept Quote',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, BuildContext context, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                color: isHighlight ? AppColors.accent : AppColors.textPrimary,
                fontSize: isHighlight ? 20 : 16,
              ),
        ),
      ],
    );
  }
}
