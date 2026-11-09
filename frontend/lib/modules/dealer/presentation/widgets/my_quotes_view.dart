import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../customer/presentation/widgets/quote_actions.dart';
import '../../domain/entities/my_quote.dart';
import '../../domain/repositories/dealer_quotes_repository.dart';
import 'my_quote_tile.dart';

/// The dealer's sent quotes with loading, empty and error states and every follow-up action.
class MyQuotesView extends ConsumerWidget {
  const MyQuotesView({super.key});

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
    ref.invalidate(myQuotesProvider);
  }

  Future<void> _revise(BuildContext context, WidgetRef ref, MyQuote m) async {
    final price = await askPrice(
      context,
      title: 'Revise your price',
      help: 'The buyer sees the new total. A quote can be revised three times.',
      initial: m.quote.price,
    );
    if (price == null || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref
          .read(dealerQuotesRepositoryProvider)
          .revise(m.quote.id, price: price),
      'Price updated.',
    );
  }

  Future<void> _withdraw(BuildContext context, WidgetRef ref, MyQuote m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw this quote?'),
        content: const Text(
          'The buyer will no longer see it as open. You can send a new quote only if the buyer asks.',
        ),
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
      () => ref.read(dealerQuotesRepositoryProvider).withdraw(m.quote.id),
      'Quote withdrawn.',
    );
  }

  Future<void> _counterBack(
    BuildContext context,
    WidgetRef ref,
    MyQuote m,
  ) async {
    final open = m.quote.openRound!;
    final price = await askPrice(
      context,
      title: 'Your counter',
      help: 'Must be above the buyer\'s ₹${open.price} and below your quote.',
      minExclusive: open.price,
      maxExclusive: m.quote.price,
    );
    if (price == null || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref
          .read(dealerQuotesRepositoryProvider)
          .reply(m.quote.id, 'COUNTER', price: price),
      'Counter sent.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myQuotesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not load your quotes.'),
            TextButton(
              onPressed: () => ref.invalidate(myQuotesProvider),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.xxxl),
            child: Center(
              child: Text(
                'You have not sent any quotes yet. Quote a buyer request and it will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(myQuotesProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              final m = items[i];
              final repo = ref.read(dealerQuotesRepositoryProvider);
              return MyQuoteTile(
                item: m,
                onRevise: () => _revise(context, ref, m),
                onWithdraw: () => _withdraw(context, ref, m),
                onAcceptCounter: () => _run(
                  context,
                  ref,
                  () => repo.reply(m.quote.id, 'ACCEPT'),
                  'Price agreed.',
                ),
                onDeclineCounter: () => _run(
                  context,
                  ref,
                  () => repo.reply(m.quote.id, 'DECLINE'),
                  'Offer declined.',
                ),
                onCounterBack: () => _counterBack(context, ref, m),
              );
            },
          ),
        );
      },
    );
  }
}
