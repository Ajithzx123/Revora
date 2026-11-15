import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../domain/entities/sell_offer.dart';
import '../../domain/entities/sell_post.dart';
import '../../domain/repositories/sell_repository.dart';
import '../widgets/quote_actions.dart' show askPrice;
import '../widgets/sell_offer_card.dart';

/// One listing and the offers on it, highest first. The seller accepts or turns down offers,
/// changes the asking price, or closes the listing.
class ListingDetailsScreen extends ConsumerWidget {
  final String listingId;

  const ListingDetailsScreen({super.key, required this.listingId});

  void _refresh(WidgetRef ref) {
    ref.invalidate(sellListingsProvider);
    ref.invalidate(listingOffersProvider(listingId));
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
    String done,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
    _refresh(ref);
  }

  Future<bool> _confirm(
    BuildContext context,
    String title,
    String body,
    String yes,
    String no,
  ) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(no),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(yes),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _accept(BuildContext context, WidgetRef ref, SellOffer o) async {
    final ok = await _confirm(
      context,
      'Accept ${PriceFormatter.formatINR(o.price)}?',
      '${o.dealerName} will be told you chose them and will get your contact details. '
          'Every other offer on this car is closed and cannot be reopened.',
      'Accept offer',
      'Not yet',
    );
    if (!ok || !context.mounted) return;
    await _run(
      context,
      ref,
      () =>
          ref.read(sellRepositoryProvider).accept(o.id, expectedPrice: o.price),
      'Offer accepted. ${o.dealerName} will be in touch.',
    );
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, SellOffer o) async {
    final ok = await _confirm(
      context,
      'Turn this offer down?',
      '${o.dealerName} will no longer see it as open.',
      'Turn down',
      'Keep it',
    );
    if (!ok || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref.read(sellRepositoryProvider).reject(o.id),
      'Offer turned down.',
    );
  }

  Future<void> _counter(
    BuildContext context,
    WidgetRef ref,
    SellOffer o,
  ) async {
    final price = await askPrice(
      context,
      title: 'Ask for more',
      help:
          'Offered ${PriceFormatter.formatINR(o.price)}. The dealer has 24 hours to answer.',
      minExclusive: o.price,
    );
    if (price == null || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref.read(sellRepositoryProvider).counter(o.id, price: price),
      'Counter-offer sent.',
    );
  }

  Future<void> _answerCounter(
    BuildContext context,
    WidgetRef ref,
    SellOffer o,
    String action,
  ) => _run(
    context,
    ref,
    () => ref.read(sellRepositoryProvider).respond(o.id, action),
    action == 'ACCEPT'
        ? 'New price agreed. You can accept the offer now.'
        : 'Counter-offer declined.',
  );

  Future<void> _answerFinal(
    BuildContext context,
    WidgetRef ref,
    SellOffer o,
    String action,
  ) async {
    final price = o.finalPrice ?? o.price;
    final accept = action == 'ACCEPT';
    final ok = await _confirm(
      context,
      accept
          ? 'Accept ${PriceFormatter.formatINR(price)}?'
          : 'Decline the lower price?',
      accept
          ? 'This becomes the final price for your car.'
          : 'Declining is free. Your listing reopens and other offers that are still valid come back.',
      accept ? 'Accept' : 'Decline',
      'Not yet',
    );
    if (!ok || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref.read(sellRepositoryProvider).respondFinal(o.id, action),
      accept
          ? 'Final price accepted.'
          : 'Declined. Your listing is open again.',
    );
  }

  Future<void> _changePrice(
    BuildContext context,
    WidgetRef ref,
    SellPost p,
  ) async {
    final price = await askPrice(
      context,
      title: 'Change your asking price',
      help: 'Offers already made stay valid. Those dealers are told.',
      initial: p.expectedPrice,
    );
    if (price == null || price == p.expectedPrice || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref.read(sellRepositoryProvider).changePrice(p.id, price),
      'Asking price updated.',
    );
  }

  Future<void> _close(
    BuildContext context,
    WidgetRef ref,
    SellPost p,
    bool soldElsewhere,
  ) async {
    final ok = await _confirm(
      context,
      soldElsewhere ? 'Sold it elsewhere?' : 'Stop selling this car?',
      'Every open offer is closed and dealers are told the listing is closed. This cannot be undone.',
      soldElsewhere ? 'Yes, sold' : 'Stop selling',
      'Keep listing',
    );
    if (!ok || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref
          .read(sellRepositoryProvider)
          .close(p.id, soldElsewhere: soldElsewhere),
      'Listing closed.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(sellListingsProvider);
    final offers = ref.watch(listingOffersProvider(listingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Your listing')),
      body: listings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: apiErrorMessage(e),
          onRetry: () => ref.invalidate(sellListingsProvider),
        ),
        data: (posts) {
          final matches = posts.where((p) => p.id == listingId);
          if (matches.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.directions_car_outlined,
              title: 'Listing not found',
              description: 'It may have been removed.',
            );
          }
          final post = matches.first;
          return RefreshIndicator(
            onRefresh: () async => _refresh(ref),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Summary(post: post),
                        const SizedBox(height: AppSpacing.md),
                        if (post.isOpen)
                          Wrap(
                            spacing: AppSpacing.sm,
                            children: [
                              OutlinedButton(
                                onPressed: () =>
                                    _changePrice(context, ref, post),
                                child: const Text('Change price'),
                              ),
                              OutlinedButton(
                                onPressed: () =>
                                    _close(context, ref, post, true),
                                child: const Text('Sold elsewhere'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    _close(context, ref, post, false),
                                child: const Text('Stop selling'),
                              ),
                            ],
                          ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Dealer offers',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        offers.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.all(AppSpacing.xl),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => SizedBox(
                            height: 220,
                            child: AppErrorWidget(
                              message: apiErrorMessage(e),
                              onRetry: () => ref.invalidate(
                                listingOffersProvider(listingId),
                              ),
                            ),
                          ),
                          data: (list) => list.isEmpty
                              ? const SizedBox(
                                  height: 240,
                                  child: EmptyStateWidget(
                                    icon: Icons.hourglass_empty,
                                    title: 'No offers yet',
                                    description:
                                        'Matching dealers have been told. Offers appear here as they arrive.',
                                  ),
                                )
                              : Column(
                                  children: [
                                    for (var i = 0; i < list.length; i++) ...[
                                      SellOfferCard(
                                        offer: list[i],
                                        askingPrice: post.expectedPrice,
                                        best: i == 0,
                                        canAct: post.isOpen,
                                        onAccept: () =>
                                            _accept(context, ref, list[i]),
                                        onReject: () =>
                                            _reject(context, ref, list[i]),
                                        onCounter: () =>
                                            _counter(context, ref, list[i]),
                                        onAnswerCounter: (a) => _answerCounter(
                                          context,
                                          ref,
                                          list[i],
                                          a,
                                        ),
                                        onAnswerFinal: (a) => _answerFinal(
                                          context,
                                          ref,
                                          list[i],
                                          a,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                    ],
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final SellPost post;
  const _Summary({required this.post});

  static String statusLabel(String s) => switch (s.toUpperCase()) {
    'ACTIVE' => 'Open for offers',
    'OFFER_ACCEPTED' => 'Offer accepted',
    'SOLD' => 'Sold',
    'CLOSED' => 'Closed',
    'EXPIRED' => 'Expired',
    'FROZEN' => 'On hold',
    _ => s,
  };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
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
          Text(
            post.title,
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Asking ${PriceFormatter.formatINR(post.expectedPrice)} · ${PriceFormatter.formatKm(post.mileage)} · ${post.fuelType} · ${post.city}',
            style: t.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            statusLabel(post.status) +
                (post.statusReason == null ? '' : ' (${post.statusReason})'),
            style: t.labelLarge,
          ),
          if (post.isOpen && post.expiresAt != null)
            Text('Offers close ${_when(post.expiresAt!)}', style: t.bodySmall),
          if (post.loanOutstanding)
            Text(
              'Loan running — dealers allow for settling it',
              style: t.bodySmall,
            ),
        ],
      ),
    );
  }

  static String _when(DateTime d) {
    final left = d.difference(DateTime.now());
    if (left.isNegative) return 'now';
    return left.inDays >= 1 ? 'in ${left.inDays} days' : 'in ${left.inHours}h';
  }
}
