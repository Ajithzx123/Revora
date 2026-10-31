import 'package:flutter_test/flutter_test.dart';
import 'package:revora/init/route_initializer.dart';
import 'package:revora/modules/auth/domain/models/user_model.dart';
import 'package:revora/modules/auth/presentation/controllers/auth_controller.dart';

AuthState _signedIn(UserRole role) => AuthState(
      isInitialized: true,
      user: UserModel(
        id: '1',
        email: 'a@b.com',
        fullName: 'Test',
        role: role,
      ),
    );

void main() {
  const signedOut = AuthState(isInitialized: true);

  group('guardRoute', () {
    test('signed-out users are sent to login from protected pages', () {
      expect(guardRoute(signedOut, '/customer/home'), '/login');
      expect(guardRoute(signedOut, '/dealer/home'), '/login');
      expect(guardRoute(signedOut, '/admin/dashboard'), '/login');
      expect(guardRoute(signedOut, '/chat'), '/login');
    });

    test('public pages stay reachable when signed out', () {
      expect(guardRoute(signedOut, '/login'), isNull);
      expect(guardRoute(signedOut, '/register'), isNull);
      expect(guardRoute(signedOut, '/splash'), isNull);
    });

    test('protected pages wait on splash while the session is restored', () {
      expect(guardRoute(const AuthState(), '/customer/home'), '/splash');
    });

    test('signed-in users skip login and land on their own home', () {
      expect(guardRoute(_signedIn(UserRole.customer), '/login'), '/customer/home');
      expect(guardRoute(_signedIn(UserRole.dealer), '/register'), '/dealer/home');
      expect(guardRoute(_signedIn(UserRole.admin), '/login'), '/admin/dashboard');
    });

    test('each role is kept out of the other roles\' areas', () {
      expect(guardRoute(_signedIn(UserRole.customer), '/dealer/home'), '/customer/home');
      expect(guardRoute(_signedIn(UserRole.customer), '/admin/dashboard'), '/customer/home');
      expect(guardRoute(_signedIn(UserRole.dealer), '/customer/post-buy'), '/dealer/home');
      expect(guardRoute(_signedIn(UserRole.dealer), '/admin/dashboard'), '/dealer/home');
      expect(guardRoute(_signedIn(UserRole.admin), '/dealer/add-car'), '/admin/dashboard');
    });

    test('allowed pages are not redirected', () {
      expect(guardRoute(_signedIn(UserRole.customer), '/customer/post-buy'), isNull);
      expect(guardRoute(_signedIn(UserRole.dealer), '/dealer/send-quote/5'), isNull);
      expect(guardRoute(_signedIn(UserRole.customer), '/chat/abc'), isNull);
    });
  });
}
