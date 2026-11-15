import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../domain/entities/sell_offer.dart';

/// One dealer's offer as the seller reads it: price against what they asked, the conditions,
/// and how long it holds. Accept / turn down only show while the offer is live.
class SellOfferCard extends StatelessWidget {
  final SellOffer offer;
  final int askingPrice;
  final bool best;
  final bool canAct;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onCounter;

  /// Answer the dealer's counter-offer: ACCEPT or DECLINE.
  final ValueChanged<String>? onAnswerCounter;

  /// Answer the dealer's lowered price after inspection: ACCEPT or DECLINE.
  final ValueChanged<String>? onAnswerFinal;

  const SellOfferCard({
    super.key,
    required this.offer,
    required this.askingPrice,
    this.best = false,
    this.canAct = true,
    this.onAccept,
    this.onReject,
    this.onCounter,
    this.onAnswerCounter,
    this.onAnswerFinal,
  });

  static String left(DateTime until) {
    final d = until.difference(DateTime.now());
    if (d.isNegative) return 'Expired';
    if (d.inHours >= 24) return '${d.inDays}d ${d.inHours % 24}h left';
    if (d.inHours >= 1) return '${d.inHours}h left';
    return '${d.inMinutes.clamp(1, 59)}m left';
  }

  static String statusLabel(String s) => switch (s) {
    'PENDING' => 'Open',
    'ACCEPTED' => 'Accepted',
    'REJECTED' => 'Turned down',
    'NOT_SELECTED' => 'Not selected',
    'WITHDRAWN' => 'Withdrawn',
    'EXPIRED' => 'Expired',
    'VOID_ADMIN' => 'Closed by admin',
    _ => s,
  };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final diff = offer.price - askingPrice;
    final vsAsk = diff == 0
        ? 'Matches your asking price'
        : diff > 0
        ? '${PriceFormatter.formatINR(diff)} above your asking price'
        : '${PriceFormatter.formatINR(-diff)} below your asking price';

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
          color: best ? AppColors.success : AppColors.border,
          width: best ? 1.5 : 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    offer.dealerName,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (best && offer.isLive)
                  const Text(
                    'Highest offer',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            if (offer.dealerRating != null)
              Text(
                'Rated ${offer.dealerRating!.toStringAsFixed(1)}',
                style: t.bodySmall,
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              PriceFormatter.formatINR(offer.price),
              style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(vsAsk, style: t.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _Chip(statusLabel(offer.status)),
                if (offer.inspectionRequired)
                  const _Chip('Subject to inspection'),
                if (offer.loanSettlementRequired)
                  const _Chip('Loan settlement needed'),
                if (offer.pickupDays != null)
                  _Chip(
                    offer.pickupDays == 0
                        ? 'Pickup today'
                        : 'Pickup in ${offer.pickupDays} days',
                  ),
                if (offer.revision > 1) _Chip('Revised ${offer.revision - 1}×'),
                if (offer.isLive && offer.validUntil != null)
                  _Chip(left(offer.validUntil!)),
              ],
            ),
            if ((offer.message ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(offer.message!, style: t.bodyMedium),
            ],
            if (offer.statusReason != null && !offer.isLive) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(offer.statusReason!, style: t.bodySmall),
            ],
            if (offer.isLive && canAct) ..._liveActions(context),
            if (offer.awaitingInspection) ...[
              const SizedBox(height: AppSpacing.md),
              _Note(
                'Accepted. The dealer inspects the car, then confirms the final price. '
                'If it comes back lower you can decline for free.',
              ),
            ],
            if (offer.finalAwaitingSeller) ..._finalPanel(context),
            if (offer.finalStatus == 'ACCEPTED') ...[
              const SizedBox(height: AppSpacing.md),
              _Note(
                offer.finalPrice == offer.price
                    ? 'Final price confirmed after inspection: ${PriceFormatter.formatINR(offer.price)}.'
                    : 'You accepted the final price of ${PriceFormatter.formatINR(offer.finalPrice ?? offer.price)}.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

extension on SellOfferCard {
  /// Accept / counter / turn down, or the answer buttons when the dealer countered.
  List<Widget> _liveActions(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final open = offer.openRound;
    if (open != null && open.by == 'DEALER') {
      return [
        const SizedBox(height: AppSpacing.md),
        Text(
          'The dealer countered at ${PriceFormatter.formatINR(open.price)} · ${SellOfferCard.left(open.validUntil)}',
          style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        ActionBar(
          primary: FilledButton(
            onPressed: () => onAnswerCounter?.call('ACCEPT'),
            child: Text('Take ${PriceFormatter.formatINR(open.price)}'),
          ),
          secondary: [
            OutlinedButton(
              onPressed: () => onAnswerCounter?.call('DECLINE'),
              child: const Text('Decline'),
            ),
          ],
        ),
      ];
    }
    return [
      if (open != null) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(
          'You asked ${PriceFormatter.formatINR(open.price)}. Waiting for the dealer · ${SellOfferCard.left(open.validUntil)}',
          style: t.bodySmall,
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      ActionBar(
        primary: FilledButton(
          onPressed: onAccept,
          child: const Text('Accept offer'),
        ),
        secondary: [
          if (open == null && onCounter != null)
            OutlinedButton(
              onPressed: onCounter,
              child: const Text('Ask for more'),
            ),
          OutlinedButton(onPressed: onReject, child: const Text('Turn down')),
        ],
      ),
    ];
  }

  /// The dealer's lowered price after inspection, with the reason and evidence, and a free decline.
  List<Widget> _finalPanel(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lower = (offer.finalPrice ?? offer.price);
    final drop = offer.price - lower;
    return [
      const SizedBox(height: AppSpacing.md),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.warningBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Final offer after inspection: ${PriceFormatter.formatINR(lower)}',
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              '${PriceFormatter.formatINR(drop)} lower (${(offer.finalDropPercent ?? 0).toStringAsFixed(1)}%)',
              style: t.bodyMedium,
            ),
            if (offer.finalReasonCode != null)
              Text(
                'Reason: ${offer.finalReasonCode!.replaceAll('_', ' ').toLowerCase()}',
                style: t.bodyMedium,
              ),
            if ((offer.finalReasonNote ?? '').isNotEmpty)
              Text(offer.finalReasonNote!, style: t.bodySmall),
            for (final link in offer.finalEvidence)
              SelectableText('Evidence: $link', style: t.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Declining is free. Your listing reopens and other valid offers come back.',
              style: t.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            ActionBar(
              primary: FilledButton(
                onPressed: () => onAnswerFinal?.call('ACCEPT'),
                child: Text('Accept ${PriceFormatter.formatINR(lower)}'),
              ),
              secondary: [
                OutlinedButton(
                  onPressed: () => onAnswerFinal?.call('DECLINE'),
                  child: const Text('Decline'),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }
}

/// A primary button with its alternatives. On a wide card they share one row; on a phone the
/// primary button takes the full width and the others wrap below it, so none is ever squeezed
/// into a sliver (three buttons side by side do not fit in 375px).
class ActionBar extends StatelessWidget {
  final Widget primary;
  final List<Widget> secondary;
  const ActionBar({
    super.key,
    required this.primary,
    this.secondary = const [],
  });

  /// Below this width the buttons stack.
  static const double sideBySideFrom = 460;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= sideBySideFrom) {
          return Row(
            children: [
              Expanded(child: primary),
              for (final w in secondary) ...[
                const SizedBox(width: AppSpacing.sm),
                w,
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            primary,
            if (secondary.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: secondary,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Note extends StatelessWidget {
  final String text;
  const _Note(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.bodySmall);
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySubtle,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
