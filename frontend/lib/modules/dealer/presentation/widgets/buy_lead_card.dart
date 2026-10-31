import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/match_badge.dart';
import '../../domain/entities/buy_lead.dart';

/// One buyer requirement a dealer can quote on. Layout is vertical so long
/// titles and budget ranges never fight for the same row on a phone.
/// Buyers are shown by first name and city only; full contact details are
/// released after a quote is accepted.
class BuyLeadCard extends StatelessWidget {
  final BuyLead lead;
  final VoidCallback onSendQuote;

  const BuyLeadCard({super.key, required this.lead, required this.onSendQuote});

  @override
  Widget build(BuildContext context) {
    final firstName = lead.customerName.trim().split(' ').first;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(lead.title, style: AppTextStyles.titleLarge.copyWith(fontSize: 17)),
              ),
              const SizedBox(width: AppSpacing.sm),
              MatchBadge(percentage: lead.matchPercentage),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('$firstName · ${lead.customerCity}', style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(lead.budgetRange, style: AppTextStyles.price),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('BUDGET', style: AppTextStyles.overline.copyWith(fontSize: 10)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Pill(icon: Icons.local_gas_station_outlined, label: lead.fuelType),
              _Pill(icon: Icons.tune, label: lead.transmission),
              _Pill(icon: Icons.forum_outlined, label: lead.quotesCount == 1 ? '1 quote so far' : '${lead.quotesCount} quotes so far'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSendQuote,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Send a quote'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primarySubtle,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(label, style: AppTextStyles.labelMedium.copyWith(fontSize: 12.5)),
        ],
      ),
    );
  }
}
