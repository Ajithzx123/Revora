import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../entities/app_notification.dart';

/// Push categories a user may switch off. Account and deal-critical alerts are always on.
const notificationCategories = ['LEADS', 'QUOTES', 'DEALS', 'MARKETING'];

abstract class NotificationsRepository {
  Future<NotificationPage> list({
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
  });
  Future<int> unreadCount();

  /// Marks the given notifications read, or all of them when [ids] is null.
  Future<void> markRead({List<String>? ids});
  Future<Map<String, bool>> preferences();
  Future<Map<String, bool>> setPreference(String category, bool pushEnabled);
  Future<void> registerDevice(String token, String platform);
  Future<void> removeDevice(String token);
}

class ApiNotificationsRepository implements NotificationsRepository {
  final Dio _dio;
  ApiNotificationsRepository(this._dio);

  @override
  Future<NotificationPage> list({
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    final res = await _dio.get(
      '/notifications',
      queryParameters: {
        'limit': limit,
        'offset': offset,
        'unread_only': unreadOnly,
      },
    );
    return NotificationPage.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<int> unreadCount() async {
    final res = await _dio.get('/notifications/unread-count');
    return (res.data as Map<String, dynamic>)['unread_count'] as int;
  }

  @override
  Future<void> markRead({List<String>? ids}) async {
    await _dio.post('/notifications/mark-read', data: {'ids': ids});
  }

  Map<String, bool> _prefs(Object? data) => {
    for (final e in ((data as Map)['preferences'] as Map).entries)
      e.key as String: e.value as bool,
  };

  @override
  Future<Map<String, bool>> preferences() async =>
      _prefs((await _dio.get('/notifications/preferences')).data);

  @override
  Future<Map<String, bool>> setPreference(
    String category,
    bool pushEnabled,
  ) async => _prefs(
    (await _dio.put(
      '/notifications/preferences',
      data: {
        'preferences': {category: pushEnabled},
      },
    )).data,
  );

  @override
  Future<void> registerDevice(String token, String platform) async {
    await _dio.post(
      '/notifications/devices',
      data: {'token': token, 'platform': platform},
    );
  }

  @override
  Future<void> removeDevice(String token) async {
    await _dio.post(
      '/notifications/devices/remove',
      data: {'token': token, 'platform': 'unknown'},
    );
  }
}

class MockNotificationsRepository implements NotificationsRepository {
  final List<AppNotification> _items = [
    AppNotification(
      id: 'n1',
      type: 'QUOTE_RECEIVED',
      category: 'QUOTES',
      title: 'New quote received',
      body: 'A dealer quoted ₹6.50 lakh for your Hyundai i20.',
      entityType: 'dealer_quote',
      entityId: 'q1',
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    AppNotification(
      id: 'n2',
      type: 'MATCHES_FOUND',
      category: 'LEADS',
      title: 'Dealers have been notified',
      body: '5 verified dealers can see your request.',
      entityType: 'buy_requirement',
      entityId: 'r1',
      read: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];
  final Map<String, bool> _prefs = {
    for (final c in notificationCategories) c: true,
  };

  @override
  Future<NotificationPage> list({
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    final all = [
      for (final n in _items)
        if (!unreadOnly || !n.read) n,
    ];
    final page = all.skip(offset).take(limit).toList();
    return NotificationPage(
      items: page,
      total: all.length,
      unreadCount: _items.where((n) => !n.read).length,
    );
  }

  @override
  Future<int> unreadCount() async => _items.where((n) => !n.read).length;

  @override
  Future<void> markRead({List<String>? ids}) async {
    for (var i = 0; i < _items.length; i++) {
      if (ids == null || ids.contains(_items[i].id)) {
        _items[i] = _items[i].asRead();
      }
    }
  }

  @override
  Future<Map<String, bool>> preferences() async => Map.of(_prefs);

  @override
  Future<Map<String, bool>> setPreference(
    String category,
    bool pushEnabled,
  ) async {
    _prefs[category] = pushEnabled;
    return Map.of(_prefs);
  }

  @override
  Future<void> registerDevice(String token, String platform) async {}

  @override
  Future<void> removeDevice(String token) async {}
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  if (AppConfig.instance.useMockData) return MockNotificationsRepository();
  return ApiNotificationsRepository(ref.watch(dioProvider));
});
