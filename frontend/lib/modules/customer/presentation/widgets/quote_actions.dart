import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../domain/entities/quote.dart';
import '../../domain/repositories/quotes_repository.dart';
import '../providers/requirements_provider.dart';

/// The buyer's decisions on a quote. Each one asks first when it cannot be undone, then
/// reloads the quotes so the screen shows what the server now says.
class QuoteActions {
  final BuildContext context;
  final WidgetRef ref;
  QuoteActions(this.context, this.ref);

  void _refresh(Quote q) {
    ref.invalidate(requirementQuotesProvider(q.requirementId));
    ref.invalidate(requirementsProvider);
  }

  Future<void> _run(Quote q, Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
    _refresh(q);
  }

  Future<void> accept(Quote q) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Accept ${PriceFormatter.formatINR(q.quotedPrice)}?'),
        content: Text(
          '${q.dealerName} will be told you chose them. Every other quote on this request is closed '
          'and cannot be reopened.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not yet')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Accept deal')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _run(q, () async {
      await ref.read(quotesRepositoryProvider).accept(q.id, expectedPrice: q.price);
    }, 'Deal accepted. ${q.dealerName} will be in touch.');
  }

  Future<void> reject(Quote q) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Turn this quote down?'),
        content: Text('${q.dealerName} will no longer see it as open.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep it')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Turn down')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _run(q, () async {
      await ref.read(quotesRepositoryProvider).reject(q.id);
    }, 'Quote turned down.');
  }

  Future<void> counter(Quote q) async {
    final price = await askPrice(
      context,
      title: 'Your counter-offer',
      help: 'Quoted at ${PriceFormatter.formatINR(q.quotedPrice)}. The dealer has 24 hours to reply.',
      maxExclusive: q.price,
    );
    if (price == null || !context.mounted) return;
    await _run(q, () async {
      await ref.read(quotesRepositoryProvider).counter(q.id, price: price);
    }, 'Counter-offer sent.');
  }

  Future<void> respond(Quote q, String action) => _run(q, () async {
        await ref.read(quotesRepositoryProvider).respond(q.id, action);
      }, action == 'ACCEPT' ? 'New price agreed. You can accept the deal now.' : 'Counter-offer declined.');
}

/// Asks for a rupee amount. Returns null if cancelled.
Future<int?> askPrice(
  BuildContext context, {
  required String title,
  String? help,
  int? maxExclusive,
  int? minExclusive,
  int? initial,
}) {
  final controller = TextEditingController(text: initial?.toString() ?? '');
  String? error;
  return showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (help != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(help)),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Amount in ₹', errorText: error),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(controller.text.replaceAll(',', '').trim());
              if (v == null || v <= 0) {
                setState(() => error = 'Enter an amount');
              } else if (maxExclusive != null && v >= maxExclusive) {
                setState(() => error = 'Must be lower than ${PriceFormatter.formatINR(maxExclusive)}');
              } else if (minExclusive != null && v <= minExclusive) {
                setState(() => error = 'Must be higher than ${PriceFormatter.formatINR(minExclusive)}');
              } else {
                Navigator.pop(ctx, v);
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    ),
  );
}
