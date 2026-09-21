import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:revora/core/utils/storage_helper.dart';
import 'package:revora/modules/auth/data/repositories/mock_auth_repository.dart';
import 'package:revora/modules/auth/domain/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository authRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageHelper.init();
    authRepo = MockAuthRepository();
  });

  group('MockAuthRepository Tests', () {
    test('Customer login succeeds with correct role and details', () async {
      final user = await authRepo.signInWithEmailPassword(
        email: 'buyer@revora.com',
        password: 'password123',
      );

      expect(user.role, UserRole.customer);
      expect(user.fullName, 'Rahul Verma');
      expect(user.email, 'buyer@revora.com');
    });

    test('Dealer login succeeds with correct role and details', () async {
      final user = await authRepo.signInWithEmailPassword(
        email: 'dealer@revora.com',
        password: 'password123',
      );

      expect(user.role, UserRole.dealer);
      expect(user.fullName, contains('Apex Motor Corp'));
      expect(user.email, 'dealer@revora.com');
    });

    test('Admin login succeeds with correct role and details', () async {
      final user = await authRepo.signInWithEmailPassword(
        email: 'admin@revora.com',
        password: 'password123',
      );

      expect(user.role, UserRole.admin);
      expect(user.fullName, 'Revora Platform Admin');
      expect(user.email, 'admin@revora.com');
    });

    test('Dynamic email authentication infers role properly', () async {
      final dealerUser = await authRepo.signInWithEmailPassword(
        email: 'dealer@something.com',
        password: 'pass',
      );
      expect(dealerUser.role, UserRole.dealer);

      final delarUser = await authRepo.signInWithEmailPassword(
        email: 'delar@something.com',
        password: '123',
      );
      expect(delarUser.role, UserRole.dealer);

      final adminUser = await authRepo.signInWithEmailPassword(
        email: 'admin@something.com',
        password: 'adminpass',
      );
      expect(adminUser.role, UserRole.admin);

      final customerUser = await authRepo.signInWithEmailPassword(
        email: 'customer@something.com',
        password: 'custpass',
      );
      expect(customerUser.role, UserRole.customer);
    });

    test('Sign up registers new user and retrieves from getCurrentUser', () async {
      final newUser = await authRepo.signUpWithEmailPassword(
        email: 'newuser@revora.com',
        password: 'mypassword',
        fullName: 'Aarav Patel',
        role: UserRole.dealer,
      );

      expect(newUser.email, 'newuser@revora.com');
      expect(newUser.fullName, 'Aarav Patel');
      expect(newUser.role, UserRole.dealer);

      final cachedUser = await authRepo.getCurrentUser();
      expect(cachedUser, isNotNull);
      expect(cachedUser!.email, 'newuser@revora.com');
    });

    test('Sign out clears the stored session', () async {
      await authRepo.signInWithEmailPassword(
        email: 'buyer@revora.com',
        password: 'password123',
      );

      expect(await authRepo.getCurrentUser(), isNotNull);

      await authRepo.signOut();
      expect(await authRepo.getCurrentUser(), isNull);
    });
  });
}
