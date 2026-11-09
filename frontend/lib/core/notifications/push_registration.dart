import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../modules/auth/presentation/controllers/auth_controller.dart';
import '../../modules/notifications/domain/repositories/notifications_repository.dart';

/// Where the device's push token comes from. The real source is Firebase Cloud Messaging;
/// it returns null until Firebase is set up for this build (no google-services files yet).
abstract class PushTokenSource {
  Future<String?> token();
}

class _NoPushTokenSource implements PushTokenSource {
  @override
  Future<String?> token() async => null;
}

/// Replace with the FCM-backed source once Firebase is configured for the app.
final pushTokenSourceProvider = Provider<PushTokenSource>(
  (ref) => _NoPushTokenSource(),
);

String _platformName() {
  if (kIsWeb) return 'web';
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  return 'unknown';
}

/// Registers this device's push token for the signed-in user and removes it on sign-out,
/// so a shared phone never keeps delivering the previous user's alerts. Failures are
/// swallowed: push is best effort and must never block signing in or out.
class PushRegistration {
  final Ref _ref;
  String? _registered;
  PushRegistration(this._ref);

  Future<void> onUserChanged(String? userId) async {
    if (userId == null) {
      _registered =
          null; // already removed by [removeCurrent] while still signed in
      return;
    }
    try {
      final token = await _ref.read(pushTokenSourceProvider).token();
      if (token == null || token == _registered) return;
      await _ref
          .read(notificationsRepositoryProvider)
          .registerDevice(token, _platformName());
      _registered = token;
    } catch (_) {
      // best effort
    }
  }

  /// Called just before signing out, while the session can still authorise the request.
  Future<void> removeCurrent() async {
    final token = _registered;
    _registered = null;
    if (token == null) return;
    try {
      await _ref.read(notificationsRepositoryProvider).removeDevice(token);
    } catch (_) {
      // best effort: the next user to sign in on this device takes the token over
    }
  }
}

/// Watched once from the app root so it follows sign-in and sign-out.
final Provider<PushRegistration> pushRegistrationProvider =
    Provider<PushRegistration>((ref) {
      final registration = PushRegistration(ref);
      ref.listen<String?>(
        authControllerProvider.select((s) => s.user?.id),
        (_, userId) => registration.onUserChanged(userId),
        fireImmediately: true,
      );
      return registration;
    });
