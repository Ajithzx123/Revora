/// One entry in the signed-in user's notification feed (a row of the backend's
/// `notificationevent`). Bodies are already safe to show: the server never puts contact
/// details or a competitor's price in them.
class AppNotification {
  final String id;
  final String type;
  final String category;
  final String title;
  final String body;
  final String? entityType;
  final String? entityId;
  final bool critical;
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.body,
    this.entityType,
    this.entityId,
    this.critical = false,
    this.read = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'] as String,
    type: j['type'] as String,
    category: j['category'] as String,
    title: j['title'] as String,
    body: j['body'] as String,
    entityType: j['entity_type'] as String?,
    entityId: j['entity_id'] as String?,
    critical: (j['critical'] as bool?) ?? false,
    read: (j['read'] as bool?) ?? false,
    // The API sends UTC without an offset.
    createdAt: DateTime.parse(
      (j['created_at'] as String).endsWith('Z')
          ? j['created_at'] as String
          : '${j['created_at']}Z',
    ).toLocal(),
  );

  AppNotification asRead() => AppNotification(
    id: id,
    type: type,
    category: category,
    title: title,
    body: body,
    entityType: entityType,
    entityId: entityId,
    critical: critical,
    read: true,
    createdAt: createdAt,
  );
}

class NotificationPage {
  final List<AppNotification> items;
  final int total;
  final int unreadCount;

  const NotificationPage({
    required this.items,
    required this.total,
    required this.unreadCount,
  });

  bool get hasMore => items.length < total;

  factory NotificationPage.fromJson(Map<String, dynamic> j) => NotificationPage(
    items: [
      for (final i in j['items'] as List)
        AppNotification.fromJson(i as Map<String, dynamic>),
    ],
    total: j['total'] as int,
    unreadCount: j['unread_count'] as int,
  );
}
