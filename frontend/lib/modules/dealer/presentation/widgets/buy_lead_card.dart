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
  final VoidCallback? onDismiss;

  const BuyLeadCard({super.key, required this.lead, required this.onSendQuote, this.onDismiss});

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
              if (lead.matchPercentage > 0) MatchBadge(percentage: lead.matchPercentage),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('$firstName · ${lead.customerCity}', style: AppTextStyles.bodySmall),
          if (lead.tierLabel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              lead.matchedVehicleTitle == null ? lead.tierLabel! : '${lead.tierLabel!}: ${lead.matchedVehicleTitle}',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.success),
            ),
          ],
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
              if (lead.fuelType != 'Any') _Pill(icon: Icons.local_gas_station_outlined, label: lead.fuelType),
              if (lead.transmission != 'Any') _Pill(icon: Icons.tune, label: lead.transmission),
              if (lead.bodyType != null) _Pill(icon: Icons.directions_car_outlined, label: lead.bodyType!),
              _Pill(icon: Icons.schedule_rounded, label: lead.urgencyLabel),
              if (lead.needsFinance) const _Pill(icon: Icons.account_balance_outlined, label: 'Needs a loan'),
              if (lead.hasExchange) const _Pill(icon: Icons.swap_horiz_rounded, label: 'Exchange'),
              _Pill(icon: Icons.forum_outlined, label: lead.quotesCount == 1 ? '1 quote so far' : '${lead.quotesCount} quotes so far'),
            ],
          ),
          if (lead.mustHave.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Must have: ${lead.mustHave.map((m) => m.replaceAll('_', ' ')).join(', ')}',
              style: AppTextStyles.bodySmall,
            ),
          ],
          if (lead.matchReasons.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Why you', style: AppTextStyles.overline.copyWith(fontSize: 10)),
            const SizedBox(height: 4),
            for (final reason in lead.matchReasons.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.check_rounded, size: 14, color: AppColors.success),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(reason, style: AppTextStyles.bodySmall)),
                  ],
                ),
              ),
          ],
          if (lead.deadlineLabel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _Pill(icon: Icons.timer_outlined, label: lead.deadlineLabel!),
          ],
          if ((lead.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('"${lead.notes}"', style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSendQuote,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Send a quote'),
            ),
          ),
          if (onDismiss != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onDismiss, child: const Text('Not for me')),
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
