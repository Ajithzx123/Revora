import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/car_card.dart';
import '../../../../shared/widgets/responsive_card_grid.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../domain/entities/sell_lead.dart';
import '../../domain/repositories/buy_leads_repository.dart';
import '../../domain/repositories/dealer_offers_repository.dart';
import '../providers/dealer_providers.dart';
import '../widgets/buy_lead_card.dart';
import '../widgets/my_offers_view.dart';
import '../widgets/my_quotes_view.dart';

/// Two lists a dealer works from: buyers who want a car (send a quote) and
/// owners who want to sell one (make an offer).
class DealerLeadsScreen extends ConsumerStatefulWidget {
  const DealerLeadsScreen({super.key});

  @override
  ConsumerState<DealerLeadsScreen> createState() => _DealerLeadsScreenState();
}

class _DealerLeadsScreenState extends ConsumerState<DealerLeadsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _dismiss(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(buyLeadsRepositoryProvider).dismiss(id);
      ref.invalidate(buyLeadsProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Removed from your list')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not remove it. Try again.')),
      );
    }
  }

  Widget _tab(String label, int count) => Tab(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: AppSpacing.sm),
        Badge(
          label: Text('$count'),
          backgroundColor: AppColors.primarySubtle,
          textColor: AppColors.textPrimary,
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final buyLeads = ref.watch(dealerBuyLeadsProvider);
    final sellLeads = ref.watch(dealerSellLeadsProvider);

    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              _tab('Buyer requests', buyLeads.length),
              _tab('Cars to buy', sellLeads.length),
              const Tab(text: 'My quotes'),
              const Tab(text: 'My offers'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _page(
                  header: const SectionHeader(
                    title: 'Buyers want these cars',
                    subtitle:
                        'Quote a match from your inventory to win the deal',
                  ),
                  child: buyLeads.isEmpty
                      ? const _EmptyLeads()
                      : ResponsiveCardGrid(
                          children: [
                            for (final lead in buyLeads)
                              BuyLeadCard(
                                lead: lead,
                                onSendQuote: () => context.push(
                                  '/dealer/send-quote/${lead.id}',
                                ),
                                onDismiss: () => _dismiss(lead.id),
                              ),
                          ],
                        ),
                ),
                _SellLeadsPage(page: _page),
                const MyQuotesView(),
                const MyOffersView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _page({required Widget header, required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
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
  }
}

class _EmptyLeads extends StatelessWidget {
  const _EmptyLeads();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 44,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'No buyer requests for you yet',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Add cars to your inventory, or list the makes you can source on your profile. '
              'Matching buyers will show up here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Cars matched to this dealer: loading, empty and error states, then one card per car.
class _SellLeadsPage extends ConsumerWidget {
  final Widget Function({required Widget header, required Widget child}) page;
  const _SellLeadsPage({required this.page});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leads = ref.watch(sellLeadsProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(sellLeadsProvider.future),
      child: page(
        header: const SectionHeader(
          title: 'Owners selling their cars',
          subtitle: 'Make an offer to add stock directly from the owner',
        ),
        child: leads.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SizedBox(
            height: 260,
            child: AppErrorWidget(
              message: apiErrorMessage(e),
              onRetry: () => ref.invalidate(sellLeadsProvider),
            ),
          ),
          data: (list) => list.isEmpty
              ? const _EmptySellLeads()
              : ResponsiveCardGrid(
                  children: [
                    for (final lead in list) _SellLeadCard(lead: lead),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SellLeadCard extends StatelessWidget {
  final SellLead lead;
  const _SellLeadCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    final car = lead.listing;
    final offered = lead.myOfferStatus != null;
    return CarCard(
      imageUrl: car.imageUrls.isNotEmpty ? car.imageUrls.first : '',
      title: car.title,
      // City only; the seller's name and phone unlock after they accept an offer.
      location: car.city,
      priceText: PriceFormatter.formatINR(car.expectedPrice),
      priceLabel: 'Asking',
      imageHeight: 130,
      showFavorite: false,
      specs: [
        CarSpecItem(
          icon: Icons.speed,
          label: '${(car.mileage / 1000).toStringAsFixed(0)}k km',
        ),
        CarSpecItem(
          icon: Icons.local_gas_station_outlined,
          label: car.fuelType,
        ),
        CarSpecItem(icon: Icons.tune, label: car.transmission),
        if (car.loanOutstanding)
          const CarSpecItem(
            icon: Icons.account_balance_outlined,
            label: 'Loan running',
          ),
      ],
      primaryAction: FilledButton(
        onPressed: offered
            ? null
            : () => context.push('/dealer/make-offer/${lead.id}'),
        child: Text(offered ? 'Offer sent' : 'Make an offer'),
      ),
    );
  }
}

class _EmptySellLeads extends StatelessWidget {
  const _EmptySellLeads();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.directions_car_outlined,
              size: 44,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('No cars to buy yet', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Choose the makes you buy on your dealership profile. Sellers nearby who list one of them show up here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
