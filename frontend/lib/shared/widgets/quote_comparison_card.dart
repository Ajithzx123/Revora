import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/price_formatter.dart';
import 'custom_card.dart';
import 'custom_button.dart';

class QuoteComparisonCard extends StatelessWidget {
  final String dealerName;
  final double dealerRating;
  final bool isVerified;
  final String carDetails;
  final num quotedPrice;
  final VoidCallback? onChatPressed;
  final VoidCallback? onAcceptPressed;

  const QuoteComparisonCard({
    super.key,
    required this.dealerName,
    required this.dealerRating,
    required this.isVerified,
    required this.carDetails,
    required this.quotedPrice,
    this.onChatPressed,
    this.onAcceptPressed,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  dealerName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          dealerName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: AppColors.success, size: 16),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.accent, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          dealerRating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                PriceFormatter.formatINR(quotedPrice),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Car Offered: $carDetails',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Chat',
                  onPressed: onChatPressed ?? () {},
                  variant: ButtonVariant.outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Accept',
                  onPressed: onAcceptPressed ?? () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
