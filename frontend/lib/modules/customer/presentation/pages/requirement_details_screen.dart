import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/price_formatter.dart';
import '../widgets/customer_quote_card.dart';
import '../providers/customer_providers.dart';

class RequirementDetailsScreen extends ConsumerWidget {
  final String requirementId;

  const RequirementDetailsScreen({
    super.key,
    required this.requirementId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allRequirements = ref.watch(customerRequirementsProvider);
    final req = allRequirements.firstWhere(
      (r) => r.id == requirementId,
      orElse: () => allRequirements.first,
    );

    final quotes = ref.watch(customerQuotesProvider(requirementId));
    final displayQuotes = quotes.isNotEmpty
        ? quotes
        : ref.watch(allCustomerQuotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotes Received'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Requirement: ${req.minYear}+ ${req.make} ${req.model}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          req.status.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Budget: ${PriceFormatter.formatRange(req.minBudget, req.maxBudget)}  •  ${req.preferredCity}  •  ${req.fuelType}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dealer Quotes (${displayQuotes.length})',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (displayQuotes.length > 1)
                  TextButton.icon(
                    onPressed: () {
                      context.push('/customer/compare/$requirementId');
                    },
                    icon: const Icon(Icons.compare_arrows,
                        color: AppColors.accent),
                    label: const Text(
                      'Compare All',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (displayQuotes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 40, color: AppColors.textMuted),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'No quotes received yet. Verified dealers in your area have been notified.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 700 ? 2 : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.76,
                    ),
                    itemCount: displayQuotes.length,
                    itemBuilder: (context, index) {
                      final quote = displayQuotes[index];
                      return CustomerQuoteCard(
                        quote: quote,
                        onContact: () => context.push('/chat/${quote.dealerId}'),
                        onAccept: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Accepted quote from ${quote.dealerName}!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
