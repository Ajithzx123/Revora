import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/utils/storage_helper.dart';
import '../../data/repositories/mock_auth_repository.dart';
import '../models/user_model.dart';

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

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseService _supabase = SupabaseService.instance;

  @override
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    // If Supabase is configured and initialized
    if (_supabase.isInitialized && _supabase.client != null) {
      try {
        final res = await _supabase.client!.auth.signInWithPassword(
          email: email,
          password: password,
        );

        final user = res.user;
        if (user == null) {
          throw Exception('Authentication returned no user details.');
        }

        // Check user_metadata for role, full_name, etc.
        final metadata = user.userMetadata ?? {};
        final roleStr = metadata['role'] as String? ?? 'customer';
        final fullName = metadata['full_name'] as String? ?? email.split('@').first;

        final userModel = UserModel(
          id: user.id,
          email: user.email ?? email,
          fullName: fullName,
          role: UserRole.fromString(roleStr),
          phone: user.phone,
        );

        await _persistSession(userModel);
        return userModel;
      } catch (e) {
        debugPrint('[AuthRepository] Supabase sign in error: $e');
        rethrow;
      }
    }

    // Fallback / Demo mode if Supabase isn't active or credentials are mock
    await Future.delayed(const Duration(milliseconds: 600));

    // Simple demo role detection by email
    UserRole detectedRole = UserRole.customer;
    if (email.contains('dealer')) {
      detectedRole = UserRole.dealer;
    } else if (email.contains('admin')) {
      detectedRole = UserRole.admin;
    }

    final mockUser = UserModel(
      id: 'demo-user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      fullName: email.split('@').first.toUpperCase(),
      role: detectedRole,
    );

    await _persistSession(mockUser);
    return mockUser;
  }

  @override
  Future<UserModel> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    if (_supabase.isInitialized && _supabase.client != null) {
      try {
        final res = await _supabase.client!.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': fullName,
            'role': role.name,
          },
        );

        final user = res.user;
        if (user == null) {
          throw Exception('Registration succeeded, but no user returned.');
        }

        final userModel = UserModel(
          id: user.id,
          email: user.email ?? email,
          fullName: fullName,
          role: role,
        );

        await _persistSession(userModel);
        return userModel;
      } catch (e) {
        debugPrint('[AuthRepository] Supabase sign up error: $e');
        rethrow;
      }
    }

    // Demo Mode signup
    await Future.delayed(const Duration(milliseconds: 600));
    final mockUser = UserModel(
      id: 'demo-user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      fullName: fullName.isEmpty ? email.split('@').first : fullName,
      role: role,
    );

    await _persistSession(mockUser);
    return mockUser;
  }

  @override
  Future<void> signOut() async {
    if (_supabase.isInitialized && _supabase.client != null) {
      try {
        await _supabase.client!.auth.signOut();
      } catch (e) {
        debugPrint('[AuthRepository] Supabase signOut error: $e');
      }
    }

    await StorageHelper.remove(AppConstants.keyUserSession);
    await StorageHelper.clearTokens();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final savedData = StorageHelper.getString(AppConstants.keyUserSession);
    if (savedData != null) {
      try {
        final map = jsonDecode(savedData) as Map<String, dynamic>;
        return UserModel.fromJson(map);
      } catch (e) {
        debugPrint('[AuthRepository] Failed to parse cached session: $e');
      }
    }

    if (_supabase.isInitialized && _supabase.client != null) {
      final session = _supabase.client!.auth.currentSession;
      final user = session?.user;
      if (user != null) {
        final metadata = user.userMetadata ?? {};
        final roleStr = metadata['role'] as String? ?? 'customer';
        final fullName = metadata['full_name'] as String? ?? user.email ?? 'User';

        final userModel = UserModel(
          id: user.id,
          email: user.email ?? '',
          fullName: fullName,
          role: UserRole.fromString(roleStr),
        );
        await _persistSession(userModel);
        return userModel;
      }
    }

    return null;
  }

  Future<void> _persistSession(UserModel user) async {
    await StorageHelper.setString(
      AppConstants.keyUserSession,
      jsonEncode(user.toJson()),
    );
  }
}
