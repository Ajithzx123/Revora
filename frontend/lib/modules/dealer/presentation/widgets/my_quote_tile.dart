import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../domain/entities/my_quote.dart';

/// A quote the dealer sent, with what the buyer has done about it and what the dealer can do next.
class MyQuoteTile extends StatelessWidget {
  final MyQuote item;
  final VoidCallback onRevise;
  final VoidCallback onWithdraw;
  final VoidCallback onAcceptCounter;
  final VoidCallback onDeclineCounter;
  final VoidCallback onCounterBack;

  const MyQuoteTile({
    super.key,
    required this.item,
    required this.onRevise,
    required this.onWithdraw,
    required this.onAcceptCounter,
    required this.onDeclineCounter,
    required this.onCounterBack,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final q = item.quote;
    final open = q.openRound;
    final buyerCountered = open != null && open.by == 'CUSTOMER';
    final live = q.isLive || q.status.toUpperCase() == 'REQUOTE_REQUESTED';

    final (label, color) = switch (q.status.toUpperCase()) {
      'ACCEPTED' => ('Accepted', AppColors.success),
      'PENDING' => ('Open', AppColors.info),
      'REQUOTE_REQUESTED' => ('Update your price', AppColors.warning),
      'NOT_SELECTED' => ('Buyer chose another dealer', AppColors.textSecondary),
      'REJECTED' => ('Turned down', AppColors.error),
      'WITHDRAWN' => ('Withdrawn', AppColors.textSecondary),
      'EXPIRED' => ('Expired', AppColors.textSecondary),
      'UNAVAILABLE' => ('Car sold', AppColors.textSecondary),
      _ => ('Closed', AppColors.textSecondary),
    };

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
            children: [
              Expanded(child: Text(item.requestTitle, style: t.titleMedium)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: t.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            [
              item.buyerFirstName,
              if (item.requestCity.isNotEmpty) item.requestCity,
              q.kindLabel,
            ].join(' · '),
            style: t.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(PriceFormatter.formatINR(q.quotedPrice), style: t.titleLarge),
          if (q.validityLabel != null)
            Text(q.validityLabel!, style: t.bodySmall),
          if (q.revision > 1)
            Text('Revision ${q.revision}', style: t.bodySmall),
          if (q.statusReason != null && !live)
            Text(q.statusReason!, style: t.bodySmall),
          if (buyerCountered) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                'Buyer offers ${PriceFormatter.formatINR(open.price)}. Reply within 24 hours.',
                style: t.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton(
                  onPressed: onAcceptCounter,
                  child: const Text('Accept offer'),
                ),
                OutlinedButton(
                  onPressed: onCounterBack,
                  child: const Text('Counter'),
                ),
                TextButton(
                  onPressed: onDeclineCounter,
                  child: const Text('Decline'),
                ),
              ],
            ),
          ],
          if (q.isAccepted && item.buyerName != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Buyer: ${item.buyerName}${item.buyerPhone == null ? '' : ' · ${item.buyerPhone}'}',
              style: t.bodyMedium,
            ),
          ],
          if (live && !buyerCountered) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                OutlinedButton(
                  onPressed: onRevise,
                  child: const Text('Revise price'),
                ),
                TextButton(
                  onPressed: onWithdraw,
                  child: const Text('Withdraw'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
