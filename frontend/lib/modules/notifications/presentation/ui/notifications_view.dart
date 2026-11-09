import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notifications_providers.dart';

/// The notification centre. Both the customer and dealer Activity tabs show this.
/// [requestRoute] is where a tap on a request-related notification goes for that role.
class NotificationsView extends ConsumerWidget {
  final String Function(String requestId) requestRoute;
  const NotificationsView({super.key, required this.requestRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(notificationsProvider.future),
        child: feed.when(
          loading: () => const _Skeleton(),
          error: (e, _) => ListView(
            children: [
              SizedBox(
                height: 360,
                child: AppErrorWidget(
                  message: apiErrorMessage(e),
                  onRetry: () => ref.invalidate(notificationsProvider),
                ),
              ),
            ],
          ),
          data: (page) => _Feed(page: page, requestRoute: requestRoute),
        ),
      ),
    );
  }
}

class _Feed extends ConsumerWidget {
  final NotificationPage page;
  final String Function(String requestId) requestRoute;
  const _Feed({required this.page, required this.requestRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(notificationsProvider.notifier);
    final header = SectionHeader(
      title: 'Notifications',
      subtitle: page.unreadCount == 0
          ? 'You are all caught up'
          : '${page.unreadCount} unread',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: page.unreadCount == 0 ? null : notifier.markAllRead,
            child: const Text('Mark all read'),
          ),
          IconButton(
            tooltip: 'Notification settings',
            icon: const Icon(Icons.tune),
            onPressed: () => context.push('/notifications/preferences'),
          ),
        ],
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          // header + tiles (or the empty state) + the "load more" row
          itemCount: 1 + (page.items.isEmpty ? 1 : page.items.length) + 1,
          itemBuilder: (context, i) {
            if (i == 0) return header;
            if (page.items.isEmpty) {
              return i == 1
                  ? const SizedBox(
                      height: 320,
                      child: EmptyStateWidget(
                        icon: Icons.notifications_none,
                        title: 'No notifications yet',
                        description:
                            'Quotes, counter-offers and account updates will show up here.',
                      ),
                    )
                  : const SizedBox.shrink();
            }
            if (i == page.items.length + 1) {
              return page.hasMore
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: OutlinedButton(
                        onPressed: notifier.loadMore,
                        child: const Text('Load more'),
                      ),
                    )
                  : const SizedBox.shrink();
            }
            final n = page.items[i - 1];
            return _Tile(
              notification: n,
              onTap: () async {
                await notifier.markRead(n);
                if (!context.mounted) return;
                if (n.entityType == 'buy_requirement' && n.entityId != null) {
                  context.push(requestRoute(n.entityId!));
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  const _Tile({required this.notification, required this.onTap});

  static IconData _icon(String category) => switch (category) {
    'QUOTES' => Icons.local_offer_outlined,
    'LEADS' => Icons.person_search_outlined,
    'DEALS' => Icons.handshake_outlined,
    'ACCOUNT' => Icons.verified_user_outlined,
    _ => Icons.notifications_none,
  };

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        button: true,
        label: '${n.read ? '' : 'Unread. '}${n.title}. ${n.body}',
        excludeSemantics: true,
        child: Material(
          color: n.read ? AppColors.surface : AppColors.accentLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_icon(n.category), color: AppColors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.title,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: n.read
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(n.body, style: AppTextStyles.bodySmall),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.sm,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              Helpers.timeAgo(n.createdAt),
                              style: AppTextStyles.bodySmall,
                            ),
                            if (n.critical)
                              const Text(
                                'Important',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            if (!n.read)
                              const Text(
                                'New',
                                style: TextStyle(
                                  color: AppColors.accentDeep,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 5,
      itemBuilder: (_, _) => Container(
        height: 76,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.borderLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }
}
