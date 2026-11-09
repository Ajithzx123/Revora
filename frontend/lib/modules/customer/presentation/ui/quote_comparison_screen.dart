import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../domain/entities/quote.dart';
import '../../domain/repositories/quotes_repository.dart';
import '../widgets/quote_actions.dart';

/// Live quotes side by side, cheapest first. Closed quotes are left out; they can still
/// be seen on the request page.
class QuoteComparisonScreen extends ConsumerWidget {
  final String requirementId;

  const QuoteComparisonScreen({super.key, required this.requirementId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(requirementQuotesProvider(requirementId));
    return Scaffold(
      appBar: AppBar(title: const Text('Compare quotes')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load the quotes.'),
              TextButton(
                onPressed: () =>
                    ref.invalidate(requirementQuotesProvider(requirementId)),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (all) {
          final quotes = all.where((q) => q.isLive || q.isAccepted).toList();
          if (quotes.isEmpty) {
            return const Center(
              child: Text(
                'No open quotes to compare.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          final cheapest = quotes
              .map((q) => q.quotedPrice)
              .reduce((a, b) => a < b ? a : b);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final q in quotes)
                  _Column(
                    quote: q,
                    isCheapest: q.quotedPrice == cheapest && quotes.length > 1,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Column extends ConsumerWidget {
  final Quote quote;
  final bool isCheapest;
  const _Column({required this.quote, required this.isCheapest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final actions = QuoteActions(context, ref);
    final open = quote.openRound;
    final dealerCountered = open != null && open.by == 'DEALER';

    Widget row(String label, String value, {bool strong = false}) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value.isEmpty ? '—' : value,
            style: strong
                ? t.titleLarge?.copyWith(color: AppColors.accentDeep)
                : t.bodyLarge,
          ),
        ],
      ),
    );

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: isCheapest ? AppColors.success : AppColors.border,
          width: isCheapest ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCheapest)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                'LOWEST PRICE',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          Text(quote.dealerName, style: t.titleLarge),
          if (quote.dealerRating > 0)
            Text(
              'Rated ${quote.dealerRating.toStringAsFixed(1)}',
              style: t.bodySmall,
            ),
          const Divider(height: 28),
          row(
            'Total price',
            PriceFormatter.formatINR(quote.quotedPrice),
            strong: true,
          ),
          row('Car', quote.carTitle),
          row('Availability', quote.kindLabel),
          row(
            'Driven',
            quote.carMileage > 0
                ? PriceFormatter.formatKm(quote.carMileage)
                : '',
          ),
          row(
            'Delivery',
            quote.deliveryDays == null
                ? ''
                : 'Within ${quote.deliveryDays} days',
          ),
          row(
            'Warranty',
            quote.warrantyMonths == null || quote.warrantyMonths == 0
                ? ''
                : '${quote.warrantyMonths} months',
          ),
          row('Price holds', quote.validityLabel ?? ''),
          row('Dealer note', quote.comment),
          if (quote.isAccepted)
            const Text(
              'You accepted this quote.',
              style: TextStyle(color: AppColors.success),
            )
          else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => dealerCountered
                    ? actions.respond(quote, 'ACCEPT')
                    : actions.accept(quote),
                child: Text(
                  dealerCountered
                      ? 'Take ${PriceFormatter.formatINR(open.price)}'
                      : 'Accept deal',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => actions.counter(quote),
                child: const Text('Counter-offer'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
