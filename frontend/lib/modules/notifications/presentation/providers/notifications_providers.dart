import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

/// Unread badge for the Activity tab. Refreshed whenever the feed changes.
final unreadNotificationsProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(notificationsRepositoryProvider).unreadCount();
});

/// The feed, newest first, loaded a page at a time.
class NotificationsNotifier extends AutoDisposeAsyncNotifier<NotificationPage> {
  static const _pageSize = 20;

  @override
  Future<NotificationPage> build() {
    return ref.watch(notificationsRepositoryProvider).list(limit: _pageSize);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || state.isLoading) return;
    final next = await ref
        .read(notificationsRepositoryProvider)
        .list(limit: _pageSize, offset: current.items.length);
    state = AsyncData(
      NotificationPage(
        items: [...current.items, ...next.items],
        total: next.total,
        unreadCount: next.unreadCount,
      ),
    );
  }

  Future<void> markRead(AppNotification n) async {
    final current = state.valueOrNull;
    if (current == null || n.read) return;
    await ref.read(notificationsRepositoryProvider).markRead(ids: [n.id]);
    state = AsyncData(
      NotificationPage(
        items: [for (final i in current.items) i.id == n.id ? i.asRead() : i],
        total: current.total,
        unreadCount: (current.unreadCount - 1).clamp(0, 1 << 30),
      ),
    );
    ref.invalidate(unreadNotificationsProvider);
  }

  Future<void> markAllRead() async {
    final current = state.valueOrNull;
    if (current == null) return;
    await ref.read(notificationsRepositoryProvider).markRead();
    state = AsyncData(
      NotificationPage(
        items: [for (final i in current.items) i.asRead()],
        total: current.total,
        unreadCount: 0,
      ),
    );
    ref.invalidate(unreadNotificationsProvider);
  }
}

final notificationsProvider =
    AsyncNotifierProvider.autoDispose<NotificationsNotifier, NotificationPage>(
      NotificationsNotifier.new,
    );

/// Push on/off per category. While a change is in flight the switches are disabled.
class NotificationPrefsNotifier
    extends AutoDisposeAsyncNotifier<Map<String, bool>> {
  @override
  Future<Map<String, bool>> build() {
    return ref.watch(notificationsRepositoryProvider).preferences();
  }

  Future<void> setPush(String category, bool enabled) async {
    state = const AsyncLoading<Map<String, bool>>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref
          .read(notificationsRepositoryProvider)
          .setPreference(category, enabled),
    );
  }
}

final notificationPrefsProvider =
    AsyncNotifierProvider.autoDispose<
      NotificationPrefsNotifier,
      Map<String, bool>
    >(NotificationPrefsNotifier.new);
