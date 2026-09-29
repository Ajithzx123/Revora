import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../data/repositories/mock_auth_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<UserModel> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  });

  Future<void> signOut();

  Future<UserModel?> getCurrentUser();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.instance.useMockData) {
    return MockAuthRepository();
  }
  return SupabaseAuthRepository();
});
