import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/price_formatter.dart';
import '../../../../../shared/widgets/custom_button.dart';
import '../../domain/entities/quote.dart';
import '../providers/customer_providers.dart';

class QuoteComparisonScreen extends ConsumerWidget {
  final String requirementId;

  const QuoteComparisonScreen({
    super.key,
    required this.requirementId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotes = ref.watch(customerQuotesProvider(requirementId));
    final displayQuotes = quotes.isNotEmpty
        ? quotes
        : ref.watch(allCustomerQuotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Quotes'),
      ),
      body: displayQuotes.isEmpty
          ? const Center(
              child: Text(
                'No quotes available to compare.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: displayQuotes
                    .map((quote) => _buildComparisonColumn(context, quote))
                    .toList(),
              ),
            ),
    );
  }

  Widget _buildComparisonColumn(BuildContext context, Quote quote) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusLg - 1),
              ),
            ),
            child: Column(
              children: [
                Text(
                  quote.dealerName,
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
                      '${quote.dealerRating}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${quote.matchPercentage}% Match',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRow('Car', quote.carTitle, context),
                const Divider(height: 24, color: AppColors.borderLight),
                _buildRow('Quoted Price',
                    PriceFormatter.formatINR(quote.quotedPrice), context,
                    isHighlight: true),
                const Divider(height: 24, color: AppColors.borderLight),
                _buildRow('Km Driven',
                    PriceFormatter.formatKm(quote.carMileage), context),
                const Divider(height: 24, color: AppColors.borderLight),
                _buildRow('Fuel & Year',
                    '${quote.carFuel}  •  ${quote.carYear}', context),
                const Divider(height: 24, color: AppColors.borderLight),
                _buildRow('Dealer Notes', quote.comment, context),
                const SizedBox(height: AppSpacing.xl),
                CustomButton(
                  text: 'Chat with Dealer',
                  onPressed: () {
                    context.push('/chat/${quote.dealerId}');
                  },
                  variant: ButtonVariant.outline,
                ),
                const SizedBox(height: AppSpacing.sm),
                CustomButton(
                  text: 'Accept Quote',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Accepted quote from ${quote.dealerName}!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, BuildContext context,
      {bool isHighlight = false}) {
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
                fontWeight:
                    isHighlight ? FontWeight.bold : FontWeight.normal,
                color:
                    isHighlight ? AppColors.accent : AppColors.textPrimary,
                fontSize: isHighlight ? 20 : 15,
              ),
        ),
      ],
    );
  }
}
