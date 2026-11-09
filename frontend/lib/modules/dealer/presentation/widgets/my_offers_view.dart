import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../customer/presentation/widgets/quote_actions.dart'
    show askPrice;
import '../../../customer/presentation/widgets/sell_offer_card.dart';
import '../../domain/entities/my_offer.dart';
import '../../domain/repositories/dealer_offers_repository.dart';
import 'final_offer_dialog.dart';

/// The dealer's purchase offers with loading, empty and error states. A live offer can be
/// revised (three times) or withdrawn; the seller's contact appears only once they accept.
class MyOffersView extends ConsumerWidget {
  const MyOffersView({super.key});

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
    ref.invalidate(myOffersProvider);
  }

  Future<void> _revise(BuildContext context, WidgetRef ref, MyOffer m) async {
    final price = await askPrice(
      context,
      title: 'Revise your offer',
      help:
          'The seller sees the new price. An offer can be revised three times.',
      initial: m.offer.price,
    );
    if (price == null || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref
          .read(dealerOffersRepositoryProvider)
          .revise(m.offer.id, price: price),
      'Offer updated.',
    );
  }

  Future<void> _withdraw(BuildContext context, WidgetRef ref, MyOffer m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw this offer?'),
        content: const Text('The seller will no longer see it as open.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref.read(dealerOffersRepositoryProvider).withdraw(m.offer.id),
      'Offer withdrawn.',
    );
  }

  Future<void> _answerCounter(
    BuildContext context,
    WidgetRef ref,
    MyOffer m,
    String action,
  ) async {
    int? price;
    if (action == 'COUNTER') {
      final open = m.offer.openRound!;
      price = await askPrice(
        context,
        title: 'Your counter',
        help:
            'Between your offer (${PriceFormatter.formatINR(m.offer.price)}) and the seller\'s ask (${PriceFormatter.formatINR(open.price)}).',
        minExclusive: m.offer.price,
        maxExclusive: open.price,
      );
      if (price == null || !context.mounted) return;
    }
    await _run(
      context,
      ref,
      () => ref
          .read(dealerOffersRepositoryProvider)
          .reply(m.offer.id, action, price: price),
      switch (action) {
        'ACCEPT' => 'New price agreed. The seller can accept your offer now.',
        'DECLINE' => 'Counter-offer declined.',
        _ => 'Counter sent.',
      },
    );
  }

  Future<void> _sendFinal(
    BuildContext context,
    WidgetRef ref,
    MyOffer m,
  ) async {
    final draft = await FinalOfferDialog.show(context, m.offer.price);
    if (draft == null || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref
          .read(dealerOffersRepositoryProvider)
          .submitFinal(m.offer.id, draft),
      draft.price == m.offer.price
          ? 'Final price confirmed.'
          : 'Lower price sent. The seller can accept or decline it.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(myOffersProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(myOffersProvider.future),
      child: offers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: apiErrorMessage(e),
          onRetry: () => ref.invalidate(myOffersProvider),
        ),
        data: (list) => list.isEmpty
            ? ListView(
                children: const [
                  SizedBox(
                    height: 360,
                    child: EmptyStateWidget(
                      icon: Icons.handshake_outlined,
                      title: 'No offers yet',
                      description:
                          'Offers you make on cars to buy appear here.',
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: list.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: _Tile(
                        m: list[i],
                        onRevise: () => _revise(context, ref, list[i]),
                        onWithdraw: () => _withdraw(context, ref, list[i]),
                        onAnswerCounter: (a) =>
                            _answerCounter(context, ref, list[i], a),
                        onSendFinal: () => _sendFinal(context, ref, list[i]),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final MyOffer m;
  final VoidCallback onRevise;
  final VoidCallback onWithdraw;
  final ValueChanged<String> onAnswerCounter;
  final VoidCallback onSendFinal;
  const _Tile({
    required this.m,
    required this.onRevise,
    required this.onWithdraw,
    required this.onAnswerCounter,
    required this.onSendFinal,
  });

  @override
  Widget build(BuildContext context) {
    final o = m.offer;
    final t = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.listingTitle,
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(m.listingCity, style: t.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              PriceFormatter.formatINR(o.price),
              style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              '${SellOfferCard.statusLabel(o.status)}'
              '${o.revision > 1 ? ' · revised ${o.revision - 1}×' : ''}'
              '${o.isLive && o.validUntil != null ? ' · ${SellOfferCard.left(o.validUntil!)}' : ''}',
              style: t.bodySmall,
            ),
            if (o.statusReason != null && !o.isLive)
              Text(o.statusReason!, style: t.bodySmall),
            if (o.status == 'ACCEPTED') ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'Seller: ${m.sellerName ?? m.sellerFirstName}${m.sellerPhone == null ? '' : '\nPhone: ${m.sellerPhone}'}',
                ),
              ),
            ],
            if (o.isLive && o.openRound?.by == 'SELLER') ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'The seller asks ${PriceFormatter.formatINR(o.openRound!.price)} · ${SellOfferCard.left(o.openRound!.validUntil)}',
                style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilledButton(
                    onPressed: () => onAnswerCounter('ACCEPT'),
                    child: Text(
                      'Agree ${PriceFormatter.formatINR(o.openRound!.price)}',
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => onAnswerCounter('COUNTER'),
                    child: const Text('Counter'),
                  ),
                  TextButton(
                    onPressed: () => onAnswerCounter('DECLINE'),
                    child: const Text('Decline'),
                  ),
                ],
              ),
            ] else if (o.isLive && o.openRound?.by == 'DEALER') ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'You countered at ${PriceFormatter.formatINR(o.openRound!.price)}. Waiting for the seller · ${SellOfferCard.left(o.openRound!.validUntil)}',
                style: t.bodySmall,
              ),
            ],
            if (o.isLive) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: onRevise,
                    child: const Text('Revise price'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    onPressed: onWithdraw,
                    child: const Text('Withdraw'),
                  ),
                ],
              ),
            ],
            if (o.awaitingInspection) ...[
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Inspect the car, then confirm the price or lower it with a reason.',
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: onSendFinal,
                child: const Text('Send final offer'),
              ),
            ],
            if (o.finalAwaitingSeller) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Waiting for the seller to answer your final price of ${PriceFormatter.formatINR(o.finalPrice ?? o.price)}.',
                style: t.bodySmall,
              ),
            ],
            if (o.finalStatus == 'ACCEPTED')
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'Final price agreed: ${PriceFormatter.formatINR(o.finalPrice ?? o.price)}.',
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            if (o.finalStatus == 'DECLINED')
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'The seller declined the lower price. No penalty applies.',
                  style: t.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
