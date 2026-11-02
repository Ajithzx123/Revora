import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/responsive_card_grid.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../core/network/api_error.dart';
import '../providers/customer_providers.dart';
import '../providers/requirements_provider.dart';
import '../widgets/customer_quote_card.dart';
import '../widgets/requirement_summary_card.dart';

/// Everything about buying: the requests you posted and the quotes dealers sent back.
class CustomerBuyScreen extends ConsumerStatefulWidget {
  const CustomerBuyScreen({super.key});

  @override
  ConsumerState<CustomerBuyScreen> createState() => _CustomerBuyScreenState();
}

class _CustomerBuyScreenState extends ConsumerState<CustomerBuyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _tab(String label, int count, {bool highlight = false}) => Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: AppSpacing.sm),
            Badge(
              label: Text('$count'),
              backgroundColor: highlight ? AppColors.accent : AppColors.primarySubtle,
              textColor: highlight ? AppColors.onAccent : AppColors.textPrimary,
            ),
          ],
        ),
      );

  Widget _empty(String title, String body) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 40, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(body, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );

  Widget _page({required Widget header, required Widget child}) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [header, child],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final requirementsAsync = ref.watch(requirementsProvider);
    final requirements = requirementsAsync.valueOrNull ?? const [];
    final allQuotes = ref.watch(allCustomerQuotesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/customer/post-buy'),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New request'),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              _tab('My requests', requirements.length),
              _tab('Quotes', allQuotes.length, highlight: allQuotes.isNotEmpty),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _page(
                  header: const SectionHeader(
                    title: 'Cars you want',
                    subtitle: 'Verified dealers can see these and send quotes',
                  ),
                  child: requirementsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppSpacing.xxxl),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => _empty('Could not load your requests', apiErrorMessage(e)),
                    data: (items) => items.isEmpty
                        ? _empty('No requests yet', 'Tap "New request" and tell us what you are looking for.')
                        : ResponsiveCardGrid(
                            children: [
                              for (final r in items)
                                RequirementSummaryCard(
                                  requirement: r,
                                  onTap: () => context.push('/customer/requirement/${r.id}'),
                                  onViewQuotes: () => context.push('/customer/requirement/${r.id}'),
                                ),
                            ],
                          ),
                  ),
                ),
                _page(
                  header: const SectionHeader(
                    title: 'Compare dealer quotes',
                    subtitle: 'Review the car, the price and the dealer, then choose',
                  ),
                  child: allQuotes.isEmpty
                      ? _empty('No quotes yet', 'Dealers usually reply within a few hours of you posting a request.')
                      : ResponsiveCardGrid(
                          children: [
                            for (final q in allQuotes)
                              CustomerQuoteCard(
                                quote: q,
                                onContact: () => context.push('/chat'),
                                onAccept: () => ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Quote accepted. The dealer has been notified.')),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
