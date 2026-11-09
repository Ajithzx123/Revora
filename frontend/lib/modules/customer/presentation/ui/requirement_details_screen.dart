import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../shared/widgets/responsive_card_grid.dart';
import '../../domain/entities/buy_requirement.dart';
import '../providers/requirements_provider.dart';
import '../../domain/entities/quote.dart';
import '../../domain/repositories/quotes_repository.dart';
import '../widgets/customer_quote_card.dart';
import '../widgets/quote_actions.dart';

/// One request: what was asked for, its status, the actions the buyer can take
/// (edit, pause, close), and the quotes that came back.
class RequirementDetailsScreen extends ConsumerStatefulWidget {
  final String requirementId;

  const RequirementDetailsScreen({super.key, required this.requirementId});

  @override
  ConsumerState<RequirementDetailsScreen> createState() =>
      _RequirementDetailsScreenState();
}

class _RequirementDetailsScreenState
    extends ConsumerState<RequirementDetailsScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String done) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) _toast(done);
    } catch (e) {
      if (mounted) _toast(apiErrorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.error : null,
        ),
      );
  }

  Future<void> _confirmClose(BuyRequirement req) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close this request?'),
        content: const Text(
          'Dealers will stop seeing it and any open quotes will be closed. You cannot reopen it, but you can post a new one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Close request'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _run(
        () async => ref.read(requirementsProvider.notifier).cancel(req.id),
        'Request closed.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final requirements = ref.watch(requirementsProvider);
    final notifier = ref.read(requirementsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Your request')),
      body: requirements.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(apiErrorMessage(e)),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: notifier.refresh,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (items) {
          final match = items.where((r) => r.id == widget.requirementId);
          if (match.isEmpty) {
            return const Center(child: Text('This request no longer exists.'));
          }
          return _body(match.first, notifier);
        },
      ),
    );
  }

  Widget _body(BuyRequirement req, RequirementsNotifier notifier) {
    final t = Theme.of(context).textTheme;
    final quotesAsync = ref.watch(requirementQuotesProvider(req.id));
    final quotes = quotesAsync.valueOrNull ?? const <Quote>[];
    final actions = QuoteActions(context, ref);
    final canManage = req.isEditable && !_busy;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryCard(req: req),
              const SizedBox(height: AppSpacing.lg),
              if (req.isEditable)
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    OutlinedButton.icon(
                      onPressed: canManage
                          ? () => context.push(
                              '/customer/edit-requirement/${req.id}',
                            )
                          : null,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                    OutlinedButton.icon(
                      onPressed: canManage
                          ? () => _run(
                              () async => req.isPaused
                                  ? notifier.resume(req.id)
                                  : notifier.pause(req.id),
                              req.isPaused
                                  ? 'Request is open again.'
                                  : 'Request paused. Dealers will not see it.',
                            )
                          : null,
                      icon: Icon(
                        req.isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        size: 20,
                      ),
                      label: Text(req.isPaused ? 'Resume' : 'Pause'),
                    ),
                    OutlinedButton.icon(
                      onPressed: canManage ? () => _confirmClose(req) : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      label: const Text('Close'),
                    ),
                  ],
                ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Dealer quotes (${quotes.length})',
                      style: t.titleLarge,
                    ),
                  ),
                  if (quotes.length > 1)
                    TextButton.icon(
                      onPressed: () =>
                          context.push('/customer/compare/${req.id}'),
                      icon: const Icon(Icons.compare_arrows_rounded),
                      label: const Text('Compare'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (quotesAsync.isLoading && quotes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (quotesAsync.hasError && quotes.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Text('Could not load the quotes.'),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(requirementQuotesProvider(req.id)),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                )
              else if (quotes.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.inbox_outlined,
                        size: 40,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        req.isOpen
                            ? (req.dealersNotified == 0
                                  ? 'We are finding dealers for this request. Quotes will appear here.'
                                  : '${req.dealersNotified} dealer${req.dealersNotified == 1 ? '' : 's'} notified. '
                                        'Quotes usually arrive within a few hours.')
                            : req.isPaused
                            ? 'This request is paused. Resume it to receive quotes.'
                            : 'This request is closed.',
                        textAlign: TextAlign.center,
                        style: t.bodyMedium,
                      ),
                    ],
                  ),
                )
              else
                ResponsiveCardGrid(
                  children: [
                    for (final quote in quotes)
                      CustomerQuoteCard(
                        quote: quote,
                        onAccept: () => actions.accept(quote),
                        onCounter: () => actions.counter(quote),
                        onReject: () => actions.reject(quote),
                        onTakeCounter: () => actions.respond(quote, 'ACCEPT'),
                        onDeclineCounter: () =>
                            actions.respond(quote, 'DECLINE'),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final BuyRequirement req;
  const _SummaryCard({required this.req});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final statusColor = req.isOpen
        ? AppColors.success
        : req.isPaused
        ? AppColors.warning
        : AppColors.textSecondary;
    final facts = <String>[
      if (req.fuelType != 'Any') req.fuelType,
      if (req.transmission != 'Any') req.transmission,
      if (req.bodyType != null) req.bodyType!,
      if (req.maxKm != null) 'Under ${PriceFormatter.formatKm(req.maxKm!)}',
      if (req.maxOwners != null)
        req.maxOwners == 1 ? 'First owner' : 'Up to ${req.maxOwners} owners',
      req.urgencyLabel,
      if (req.needsFinance) 'Needs a loan',
      if (req.hasExchange) 'Exchange',
    ];
    final expires = req.expiresAt;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  req.statusLabel.toUpperCase(),
                  style: t.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              if (expires != null && req.isEditable)
                Text(
                  'Open until ${expires.day}/${expires.month}/${expires.year}',
                  style: t.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(req.title, style: t.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${PriceFormatter.formatRange(req.minBudget, req.maxBudget)}  ·  ${req.preferredCity}, within ${req.radiusKm} km',
            style: t.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final f in facts)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(f, style: t.labelMedium),
                ),
            ],
          ),
          if (req.mustHave.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Must-haves: ${req.mustHave.map((m) => m.replaceAll('_', ' ')).join(', ')}',
              style: t.bodySmall,
            ),
          ],
          if ((req.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              '"${req.notes}"',
              style: t.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}
