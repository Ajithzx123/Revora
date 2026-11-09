import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/bid_stack.dart';
import '../../../../shared/widgets/dealer_match_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_quote_card.dart';
import '../widgets/customer_sell_car_card.dart';
import '../widgets/requirement_summary_card.dart';

/// Customer home: greeting, the one idea of the product, a snapshot of what is
/// happening, then the lists. The two things a customer can do (buy, sell) are
/// the most prominent controls on the screen.
class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  static const double _cardHeight = 392;
  static const double _imageHeight = 124;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellPosts = ref.watch(customerSellPostsProvider);
    final requirements = ref.watch(customerRequirementsProvider);
    final allQuotes = ref.watch(allCustomerQuotesProvider);
    final topDealers = ref.watch(topDealersProvider);
    final name = ref.watch(
      authControllerProvider.select((s) => s.user?.fullName),
    );

    void goToTab(int index) =>
        ref.read(customerActiveTabProvider.notifier).state = index;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Greeting(name: name),
                const SizedBox(height: AppSpacing.lg),
                _HeroCard(
                  onBuy: () => context.push('/customer/post-buy'),
                  onSell: () => context.push('/customer/post-sell'),
                ),
                const SizedBox(height: AppSpacing.lg),
                _Snapshot(
                  quotes: allQuotes.length,
                  requests: requirements.length,
                  listings: sellPosts.length,
                  onQuotes: () => goToTab(1),
                  onRequests: () => goToTab(1),
                  onListings: () => goToTab(2),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                SectionHeader(
                  title: 'Quotes waiting for you',
                  subtitle: 'Compare price, car and dealer rating',
                  actionLabel: 'Compare all',
                  onActionTap: () => goToTab(1),
                ),
                _Carousel(
                  height: _cardHeight,
                  count: allQuotes.length,
                  emptyMessage:
                      'No quotes yet. Post a request and dealers will reply.',
                  itemBuilder: (context, i) => CustomerQuoteCard(
                    quote: allQuotes[i],
                    isHomeScreen: true,
                    imageHeight: _imageHeight,
                    onAccept: () => context.push(
                      '/customer/requirement/${allQuotes[i].requirementId}',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                SectionHeader(
                  title: 'Your requests',
                  subtitle: 'Dealers are preparing quotes',
                  actionLabel: 'View all',
                  onActionTap: () => goToTab(1),
                ),
                _Carousel(
                  height: _cardHeight,
                  count: requirements.length,
                  emptyMessage: 'You have no active requests.',
                  itemBuilder: (context, i) => RequirementSummaryCard(
                    requirement: requirements[i],
                    imageHeight: _imageHeight,
                    onViewQuotes: () => goToTab(1),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                SectionHeader(
                  title: 'Cars for sale',
                  subtitle: 'Recently listed by owners',
                  actionLabel: 'View all',
                  onActionTap: () => goToTab(2),
                ),
                _Carousel(
                  height: _cardHeight,
                  count: sellPosts.length,
                  emptyMessage: 'No cars listed for sale yet.',
                  itemBuilder: (context, i) => CustomerSellCarCard(
                    post: sellPosts[i],
                    imageHeight: _imageHeight,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                const SectionHeader(
                  title: 'Verified dealers near you',
                  subtitle: 'Every dealer is checked by the Revora team',
                ),
                SizedBox(
                  height: 190,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: topDealers.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.md),
                    itemBuilder: (context, i) => DealerMatchCard(
                      dealer: topDealers[i],
                      onConnect: () => context.push('/chat'),
                      onViewProfile: () {},
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

class _Greeting extends StatelessWidget {
  final String? name;
  const _Greeting({this.name});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final first = (name ?? '').trim().split(' ').first;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting(), style: t.bodySmall),
              Text(first.isEmpty ? 'Welcome' : first, style: t.headlineMedium),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Notifications',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.border),
          ),
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final VoidCallback onBuy;
  final VoidCallback onSell;
  const _HeroCard({required this.onBuy, required this.onSell});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 640;
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Post once.\nDealers compete.',
              style: t.displaySmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              'Tell us the car you want, or the one you are selling. '
              'Verified dealers send their best price.',
              style: t.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                FilledButton.icon(
                  onPressed: onBuy,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                  ),
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Buy a car'),
                ),
                OutlinedButton.icon(
                  onPressed: onSell,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 1.4,
                    ),
                  ),
                  icon: const Icon(Icons.sell_outlined),
                  label: const Text('Sell my car'),
                ),
              ],
            ),
          ],
        );

        return Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -80,
                top: -80,
                child: IgnorePointer(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.accent.withValues(alpha: 0.34),
                          AppColors.accent.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(flex: 5, child: copy),
                          const SizedBox(width: AppSpacing.xxl),
                          const Expanded(
                            flex: 4,
                            child: Center(child: BidStack(width: 300)),
                          ),
                        ],
                      )
                    : copy,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Three numbers that answer "what needs my attention?". One leads (quotes),
/// two support, so the eye has an order to follow.
class _Snapshot extends StatelessWidget {
  final int quotes;
  final int requests;
  final int listings;
  final VoidCallback onQuotes;
  final VoidCallback onRequests;
  final VoidCallback onListings;

  const _Snapshot({
    required this.quotes,
    required this.requests,
    required this.listings,
    required this.onQuotes,
    required this.onRequests,
    required this.onListings,
  });

  @override
  Widget build(BuildContext context) {
    final lead = _Tile(
      value: '$quotes',
      label: quotes == 1 ? 'quote to compare' : 'quotes to compare',
      icon: Icons.local_offer_outlined,
      background: AppColors.accentLight,
      onTap: onQuotes,
      large: true,
    );
    final a = _Tile(
      value: '$requests',
      label: 'active requests',
      icon: Icons.search_rounded,
      background: AppColors.surface,
      onTap: onRequests,
    );
    final b = _Tile(
      value: '$listings',
      label: 'cars listed',
      icon: Icons.sell_outlined,
      background: AppColors.surface,
      onTap: onListings,
    );

    return SizedBox(
      height: 168,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 5, child: lead),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Expanded(child: a),
                const SizedBox(height: AppSpacing.md),
                Expanded(child: b),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color background;
  final VoidCallback onTap;
  final bool large;

  const _Tile({
    required this.value,
    required this.label,
    required this.icon,
    required this.background,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$value $label',
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(large ? AppSpacing.lg : AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: large ? Colors.transparent : AppColors.border,
              ),
            ),
            child: large
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: AppColors.accentDeep),
                      const Spacer(),
                      Text(value, style: t.displayMedium),
                      Text(
                        label,
                        style: t.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Text(value, style: t.headlineMedium),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(label, style: t.bodySmall, maxLines: 2),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// A horizontal list of fixed-height cards with a friendly empty state.
class _Carousel extends StatelessWidget {
  final double height;
  final int count;
  final String emptyMessage;
  final IndexedWidgetBuilder itemBuilder;

  const _Carousel({
    required this.height,
    required this.count,
    required this.emptyMessage,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          emptyMessage,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final itemWidth = width >= 900
            ? (width - 2 * AppSpacing.md) / 3
            : width >= 600
            ? (width - AppSpacing.md) / 2
            : width * 0.8;
        return SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: count,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, i) =>
                SizedBox(width: itemWidth, child: itemBuilder(context, i)),
          ),
        );
      },
    );
  }
}
