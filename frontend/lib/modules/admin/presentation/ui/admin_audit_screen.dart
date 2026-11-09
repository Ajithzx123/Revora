import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/entities/admin_ops.dart';
import '../providers/admin_ops_providers.dart';

/// Read-only history of sensitive actions: who did what, why, and what changed.
class AdminAuditScreen extends ConsumerWidget {
  const AdminAuditScreen({super.key});

  static const _filters = {
    null: 'All',
    'dealer': 'Dealers',
    'dealer_quote': 'Quotes',
    'dealer_document': 'Documents',
    'user': 'Customers',
  };

  static String _label(String action) => action
      .split('_')
      .map((w) => w.isEmpty ? w : w[0] + w.substring(1).toLowerCase())
      .join(' ');

  static String _change(
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
  ) {
    if (before == null && after == null) return '';
    final keys = {...?before?.keys, ...?after?.keys};
    return keys
        .map((k) => '$k: ${before?[k] ?? '–'} → ${after?[k] ?? '–'}')
        .join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(adminAuditProvider);
    final filter = ref.watch(adminAuditFilterProvider);

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
                  title: 'Audit log',
                  subtitle:
                      'Every admin action and decision, newest first. Entries cannot be edited.',
                ),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final f in _filters.entries)
                      ChoiceChip(
                        label: Text(f.value),
                        selected: filter == f.key,
                        onSelected: (_) =>
                            ref.read(adminAuditFilterProvider.notifier).state =
                                f.key,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: log.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => AppErrorWidget(
                      message: apiErrorMessage(e),
                      onRetry: () => ref.invalidate(adminAuditProvider),
                    ),
                    data: (page) => page.items.isEmpty
                        ? const EmptyStateWidget(
                            icon: Icons.history,
                            title: 'Nothing logged',
                            description: 'No actions match this filter.',
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
                                        .read(adminAuditProvider.notifier)
                                        .loadMore(),
                                    child: const Text('Load more'),
                                  ),
                                );
                              }
                              return _AuditTile(entry: page.items[i]);
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

class _AuditTile extends StatelessWidget {
  final AuditEntry entry;
  const _AuditTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final change = AdminAuditScreen._change(entry.before, entry.after);
    final who = entry.actorName == null
        ? 'System'
        : '${entry.actorName} (${(entry.actorRole ?? '').toLowerCase()})';
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AdminAuditScreen._label(entry.action),
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '$who · ${Helpers.timeAgo(entry.createdAt)} · ${entry.entityType} ${entry.entityId.length > 8 ? entry.entityId.substring(0, 8) : entry.entityId}',
              style: AppTextStyles.bodySmall,
            ),
            if (entry.reason != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('Reason: ${entry.reason}', style: AppTextStyles.bodyMedium),
            ],
            if (change.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(change, style: AppTextStyles.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
