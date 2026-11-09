import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../domain/entities/admin_ops.dart';
import '../providers/admin_ops_providers.dart';

/// Every quote on the platform. Admins can read prices and void a live quote with a
/// reason; they cannot change a price or a message.
class AdminQuotesScreen extends ConsumerWidget {
  const AdminQuotesScreen({super.key});

  static const _filters = {
    null: 'All',
    'PENDING': 'Live',
    'ACCEPTED': 'Accepted',
    'VOID_ADMIN': 'Voided',
    'WITHDRAWN': 'Withdrawn',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotes = ref.watch(adminQuotesProvider);
    final filter = ref.watch(adminQuoteStatusFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Quote monitor',
                  subtitle:
                      'Watch quotes across the marketplace and void a live one when needed.',
                ),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final f in _filters.entries)
                      ChoiceChip(
                        label: Text(f.value),
                        selected: filter == f.key,
                        onSelected: (_) =>
                            ref
                                .read(adminQuoteStatusFilterProvider.notifier)
                                .state = f
                                .key,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: quotes.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => AppErrorWidget(
                      message: apiErrorMessage(e),
                      onRetry: () => ref.invalidate(adminQuotesProvider),
                    ),
                    data: (page) => page.items.isEmpty
                        ? const EmptyStateWidget(
                            icon: Icons.local_offer_outlined,
                            title: 'No quotes',
                            description: 'No quotes match this filter.',
                          )
                        : ListView.builder(
                            itemCount:
                                page.items.length + (page.hasMore ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (i == page.items.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.md,
                                  ),
                                  child: OutlinedButton(
                                    onPressed: () => ref
                                        .read(adminQuotesProvider.notifier)
                                        .loadMore(),
                                    child: const Text('Load more'),
                                  ),
                                );
                              }
                              return _QuoteTile(quote: page.items[i]);
                            },
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

class _QuoteTile extends ConsumerWidget {
  final AdminQuote quote;
  const _QuoteTile({required this.quote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${quote.dealerName} · ${quote.requestTitle}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${PriceFormatter.formatINR(quote.quotedPrice)} · revision ${quote.revision}',
                    style: AppTextStyles.bodySmall,
                  ),
                  if (quote.statusReason != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(quote.statusReason!, style: AppTextStyles.bodySmall),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  StatusChip.fromStatus(quote.status),
                ],
              ),
            ),
            if (quote.canVoid)
              TextButton(
                onPressed: () => _confirmVoid(context, ref),
                child: const Text('Void'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmVoid(BuildContext context, WidgetRef ref) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _VoidDialog(quote: quote),
    );
    if (reason == null || !context.mounted) return;
    try {
      await ref.read(adminQuotesProvider.notifier).voidQuote(quote.id, reason);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Quote voided')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    }
  }
}

class _VoidDialog extends StatefulWidget {
  final AdminQuote quote;
  const _VoidDialog({required this.quote});

  @override
  State<_VoidDialog> createState() => _VoidDialogState();
}

class _VoidDialogState extends State<_VoidDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valid = _reason.text.trim().length >= 5;
    return AlertDialog(
      title: const Text('Void this quote?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The buyer and dealer will be told. The price stays as it is and the action is recorded in the audit log.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _reason,
            autofocus: true,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason (required)',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: valid
              ? () => Navigator.pop(context, _reason.text.trim())
              : null,
          child: const Text('Void quote'),
        ),
      ],
    );
  }
}
