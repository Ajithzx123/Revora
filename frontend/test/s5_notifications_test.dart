import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:revora/core/notifications/push_registration.dart';
import 'package:revora/modules/admin/domain/entities/admin_ops.dart';
import 'package:revora/modules/admin/domain/repositories/admin_ops_repository.dart';
import 'package:revora/modules/admin/presentation/ui/admin_audit_screen.dart';
import 'package:revora/modules/admin/presentation/ui/admin_quotes_screen.dart';
import 'package:revora/modules/notifications/domain/entities/app_notification.dart';
import 'package:revora/modules/notifications/domain/repositories/notifications_repository.dart';
import 'package:revora/modules/notifications/presentation/ui/notification_preferences_screen.dart';
import 'package:revora/modules/notifications/presentation/ui/notifications_view.dart';

Map<String, dynamic> notificationJson({
  String id = 'n1',
  bool read = false,
  bool critical = false,
  String? entityType,
  String? entityId,
}) => {
  'id': id,
  'type': 'QUOTE_RECEIVED',
  'category': 'QUOTES',
  'title': 'New quote received',
  'body': 'A dealer quoted ₹6.50 lakh for your Hyundai i20.',
  'entity_type': entityType,
  'entity_id': entityId,
  'critical': critical,
  'read': read,
  'created_at': '2026-11-02T10:00:00',
};

/// Records what the screen asks for; the feed it serves can be swapped per test.
class FakeNotifications extends MockNotificationsRepository {
  final List<String> calls = [];
  Object? failWith;
  Completer<void>? holdPreference;

  @override
  Future<NotificationPage> list({
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    if (failWith != null) throw failWith!;
    return super.list(limit: limit, offset: offset, unreadOnly: unreadOnly);
  }

  @override
  Future<void> markRead({List<String>? ids}) async {
    calls.add('markRead:${ids?.join(',') ?? 'all'}');
    await super.markRead(ids: ids);
  }

  @override
  Future<Map<String, bool>> setPreference(String c, bool v) async {
    calls.add('pref:$c=$v');
    await holdPreference?.future;
    return super.setPreference(c, v);
  }

  @override
  Future<void> registerDevice(String token, String platform) async =>
      calls.add('register:$token');

  @override
  Future<void> removeDevice(String token) async => calls.add('remove:$token');
}

Widget app(Widget home, List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(home: home),
);

void main() {
  group('notification model', () {
    test('parses the API shape and treats the timestamp as UTC', () {
      final n = AppNotification.fromJson(
        notificationJson(entityType: 'dealer_quote', entityId: 'q1'),
      );
      expect(n.title, 'New quote received');
      expect(n.read, isFalse);
      expect(n.createdAt.toUtc(), DateTime.utc(2026, 11, 2, 10));
      expect(n.asRead().read, isTrue);
    });

    test('a page knows whether more remain', () {
      final page = NotificationPage.fromJson({
        'items': [notificationJson()],
        'total': 3,
        'unread_count': 1,
      });
      expect(page.hasMore, isTrue);
      expect(page.unreadCount, 1);
    });
  });

  group('notification centre', () {
    testWidgets('shows the feed with unread state and marks all read', (
      tester,
    ) async {
      final repo = FakeNotifications();
      await tester.pumpWidget(
        app(NotificationsView(requestRoute: (id) => '/r/$id'), [
          notificationsRepositoryProvider.overrideWithValue(repo),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('New quote received'), findsOneWidget);
      expect(find.text('1 unread'), findsOneWidget);
      expect(find.text('New'), findsOneWidget); // not colour-only
      expect(find.byTooltip('Notification settings'), findsOneWidget);

      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['markRead:all']);
      expect(find.text('You are all caught up'), findsOneWidget);
      expect(find.text('New'), findsNothing);
    });

    testWidgets('an empty feed explains itself', (tester) async {
      final empty = _EmptyNotifications();
      await tester.pumpWidget(
        app(NotificationsView(requestRoute: (id) => '/r/$id'), [
          notificationsRepositoryProvider.overrideWithValue(empty),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.text('No notifications yet'), findsOneWidget);
    });

    testWidgets('an error offers a retry that recovers', (tester) async {
      final repo = FakeNotifications()..failWith = StateError('offline');
      await tester.pumpWidget(
        app(NotificationsView(requestRoute: (id) => '/r/$id'), [
          notificationsRepositoryProvider.overrideWithValue(repo),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);

      repo.failWith = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('New quote received'), findsOneWidget);
    });

    testWidgets(
      'tapping a request notification marks it read and opens the request',
      (tester) async {
        final repo = FakeNotifications();
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) =>
                  NotificationsView(requestRoute: (id) => '/r/$id'),
            ),
            GoRoute(
              path: '/r/:id',
              builder: (_, s) => Text('request ${s.pathParameters['id']}'),
            ),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              notificationsRepositoryProvider.overrideWithValue(repo),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Dealers have been notified'));
        await tester.pumpAndSettle();
        expect(find.text('request r1'), findsOneWidget);
      },
    );
  });

  group('notification settings', () {
    testWidgets('lists the optional categories and saves a change', (
      tester,
    ) async {
      final repo = FakeNotifications();
      await tester.pumpWidget(
        app(const NotificationPreferencesScreen(), [
          notificationsRepositoryProvider.overrideWithValue(repo),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quotes and counter-offers'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNWidgets(4));
      await tester.tap(find.text('Quotes and counter-offers'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['pref:QUOTES=false']);
      expect(
        tester
            .widget<SwitchListTile>(
              find.widgetWithText(SwitchListTile, 'Quotes and counter-offers'),
            )
            .value,
        isFalse,
      );
    });

    testWidgets('switches are disabled while a change is saving', (
      tester,
    ) async {
      final repo = FakeNotifications()..holdPreference = Completer<void>();
      await tester.pumpWidget(
        app(const NotificationPreferencesScreen(), [
          notificationsRepositoryProvider.overrideWithValue(repo),
        ]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Deal updates'));
      await tester.pump();
      await tester.tap(
        find.text('Deal updates'),
      ); // a second tap must not send a second request
      await tester.pump();
      expect(repo.calls, ['pref:DEALS=false']);

      repo.holdPreference!.complete();
      await tester.pumpAndSettle();
    });
  });

  group('push registration', () {
    ProviderContainer container(FakeNotifications repo, String? token) =>
        ProviderContainer(
          overrides: [
            notificationsRepositoryProvider.overrideWithValue(repo),
            pushTokenSourceProvider.overrideWithValue(_FixedToken(token)),
          ],
        );

    test('registers a token once and removes it before sign-out', () async {
      final repo = FakeNotifications();
      final c = container(repo, 'fcm-token-123456');
      addTearDown(c.dispose);
      final reg = PushRegistration(c.read(pushRegistrationHolder));

      await reg.onUserChanged('u1');
      await reg.onUserChanged('u1'); // same token: no second request
      expect(repo.calls, ['register:fcm-token-123456']);

      await reg.removeCurrent();
      await reg.removeCurrent(); // nothing left to remove
      expect(repo.calls, [
        'register:fcm-token-123456',
        'remove:fcm-token-123456',
      ]);
    });

    test('does nothing when push is not set up on this build', () async {
      final repo = FakeNotifications();
      final c = container(repo, null);
      addTearDown(c.dispose);
      final reg = PushRegistration(c.read(pushRegistrationHolder));
      await reg.onUserChanged('u1');
      await reg.removeCurrent();
      expect(repo.calls, isEmpty);
    });
  });

  group('admin audit and quote monitor', () {
    test('parse the API shapes', () {
      final e = AuditEntry.fromJson({
        'id': 'a1',
        'actor_name': 'Admin',
        'actor_role': 'ADMIN',
        'action': 'DEALER_SUSPENDED',
        'entity_type': 'dealer',
        'entity_id': 'd1',
        'reason': 'Fraud report',
        'before': {'status': 'APPROVED'},
        'after': {'status': 'SUSPENDED'},
        'created_at': '2026-11-02T10:00:00',
      });
      expect(e.after, {'status': 'SUSPENDED'});
      final q = AdminQuote.fromJson({
        'id': 'q1',
        'request_title': 'Hyundai i20',
        'dealer_name': 'Apex',
        'quoted_price': 650000,
        'status': 'ACCEPTED',
        'kind': 'IN_STOCK',
        'revision': 1,
        'created_at': '2026-11-02T10:00:00',
      });
      expect(q.canVoid, isFalse); // an accepted deal cannot be voided
      expect(
        AdminQuote.fromJson({
          ...{
            'id': 'q2',
            'quoted_price': 1,
            'status': 'PENDING',
            'created_at': '2026-11-02T10:00:00',
          },
        }).canVoid,
        isTrue,
      );
    });

    testWidgets('audit log shows who, why and what changed', (tester) async {
      await tester.pumpWidget(
        app(const AdminAuditScreen(), [
          adminOpsRepositoryProvider.overrideWithValue(
            MockAdminOpsRepository(),
          ),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dealer Suspended'), findsOneWidget);
      expect(
        find.textContaining('Reason: Customer fraud report'),
        findsOneWidget,
      );
      expect(find.textContaining('APPROVED → SUSPENDED'), findsOneWidget);
    });

    testWidgets('voiding needs a reason of at least five characters', (
      tester,
    ) async {
      final repo = MockAdminOpsRepository();
      await tester.pumpWidget(
        app(const AdminQuotesScreen(), [
          adminOpsRepositoryProvider.overrideWithValue(repo),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Apex Motors'), findsOneWidget);

      await tester.tap(find.text('Void'));
      await tester.pumpAndSettle();
      FilledButton confirm() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Void quote'),
      );
      expect(confirm().onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'bad');
      await tester.pump();
      expect(confirm().onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'Price looks fraudulent');
      await tester.pump();
      expect(confirm().onPressed, isNotNull);
      await tester.tap(find.widgetWithText(FilledButton, 'Void quote'));
      await tester.pumpAndSettle();

      final voided = (await repo.quotes()).items.single;
      expect(voided.status, 'VOID_ADMIN');
      expect(voided.quotedPrice, 650000); // the price is never touched
      expect(find.text('Void'), findsNothing); // no longer voidable
    });
  });
}

class _EmptyNotifications extends MockNotificationsRepository {
  @override
  Future<NotificationPage> list({
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
  }) async => const NotificationPage(items: [], total: 0, unreadCount: 0);
}

class _FixedToken implements PushTokenSource {
  final String? value;
  _FixedToken(this.value);
  @override
  Future<String?> token() async => value;
}

/// PushRegistration only needs a Ref; this provider hands one to the test.
final pushRegistrationHolder = Provider<Ref>((ref) => ref);
