import 'package:flutter/material.dart';
import '../../core/theme/revora_theme_colors.dart';
import '../../core/utils/price_formatter.dart';
import 'custom_card.dart';
import 'custom_button.dart';

class OfferCard extends StatelessWidget {
  final String dealerName;
  final double dealerRating;
  final bool isVerified;
  final num offerPrice;
  final num askingPrice;
  final VoidCallback? onChatPressed;
  final VoidCallback? onAcceptPressed;

  const OfferCard({
    super.key,
    required this.dealerName,
    required this.dealerRating,
    required this.isVerified,
    required this.offerPrice,
    required this.askingPrice,
    this.onChatPressed,
    this.onAcceptPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final colors = context.revoraColors;
    final difference = offerPrice - askingPrice;
    final isPositive = difference >= 0;
    final positiveColor = colors.statusSuccessFg;
    final negativeColor = colors.statusErrorFg;

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: cs.primary.withValues(alpha: 0.12),
                child: Text(
                  dealerName.isNotEmpty
                      ? dealerName.substring(0, 1).toUpperCase()
                      : 'D',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            dealerName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            color: colors.statusSuccessFg,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: cs.secondary, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          dealerRating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    PriceFormatter.formatINR(offerPrice),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isPositive ? positiveColor : negativeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${isPositive ? '+' : ''}${PriceFormatter.formatINR(difference)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isPositive ? positiveColor : negativeColor,
                    ),
                  ),
                ],
              ),
            ],
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
                  text: 'Accept Offer',
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
