import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/config/app_config.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/utils/storage_helper.dart';
import '../../data/repositories/mock_auth_repository.dart';
import '../models/user_model.dart';

/// Thrown after sign-up when the project requires the user to confirm their
/// email before a session exists. Not an error: the UI shows "check your email".
class EmailConfirmationRequired implements Exception {
  final String email;
  const EmailConfirmationRequired(this.email);

  @override
  String toString() => 'Please confirm your email address ($email) to continue.';
}

abstract class AuthRepository {
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  });

  /// [businessName] and [city] are required when [role] is [UserRole.dealer].
  Future<UserModel> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? businessName,
    String? city,
  });

  Future<void> signOut();

  Future<UserModel?> getCurrentUser();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.instance.useMockData) {
    return MockAuthRepository();
  }
  return SupabaseAuthRepository(ref.watch(dioProvider));
});

/// Supabase handles identity (passwords, email confirmation, tokens). The Revora
/// backend owns the profile and, above all, the role: it is read from `/me` and
/// never from client-editable token metadata.
class SupabaseAuthRepository implements AuthRepository {
  final Dio _dio;
  final SupabaseService _supabase = SupabaseService.instance;

  SupabaseAuthRepository(this._dio);

  sb.SupabaseClient get _client {
    final client = _supabase.client;
    if (client == null) {
      throw Exception('Sign-in is unavailable right now. Please try again later.');
    }
    return client;
  }

  @override
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(email: email, password: password);
      final user = res.user;
      if (user == null) {
        throw Exception('Authentication returned no user details.');
      }
      final profile = await _ensureProfile(user);
      await _persistSession(profile);
      return profile;
    } on sb.AuthException catch (e) {
      throw Exception(_friendlyAuthMessage(e));
    }
  }

  @override
  Future<UserModel> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? businessName,
    String? city,
  }) async {
    // Self-service signup can only create customers or dealer applicants.
    if (role == UserRole.admin) {
      throw Exception('This account type cannot be created from the app.');
    }
    if (role == UserRole.dealer &&
        ((businessName ?? '').trim().isEmpty || (city ?? '').trim().isEmpty)) {
      throw Exception('Business name and city are required for dealers.');
    }
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        // Only used to create the profile after the first sign-in. The backend
        // decides the real role.
        data: {
          'full_name': fullName,
          'account_type': role == UserRole.dealer ? 'DEALER' : 'CUSTOMER',
          if (businessName != null) 'business_name': businessName.trim(),
          if (city != null) 'city': city.trim(),
        },
      );
      final user = res.user;
      if (user == null) {
        throw Exception('Registration succeeded, but no user returned.');
      }
      if (res.session == null) {
        throw EmailConfirmationRequired(email);
      }
      final profile = await _ensureProfile(user);
      await _persistSession(profile);
      return profile;
    } on sb.AuthException catch (e) {
      throw Exception(_friendlyAuthMessage(e));
    }
  }

  @override
  Future<void> signOut() async {
    final client = _supabase.client;
    if (client != null) {
      try {
        await client.auth.signOut();
      } catch (e) {
        debugPrint('[AuthRepository] Supabase signOut error: $e');
      }
    }
    await StorageHelper.remove(AppConstants.keyUserSession);
    await StorageHelper.clearTokens();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final session = _supabase.client?.auth.currentSession;
    if (session == null) {
      await StorageHelper.remove(AppConstants.keyUserSession);
      return null;
    }
    try {
      final profile = await _ensureProfile(session.user);
      await _persistSession(profile);
      return profile;
    } on DioException catch (e) {
      // Offline or backend down: fall back to the cached profile for display only.
      // The API enforces permissions on every call regardless.
      debugPrint('[AuthRepository] Profile refresh failed: ${e.message}');
      final cached = StorageHelper.getString(AppConstants.keyUserSession);
      if (cached != null) {
        try {
          return UserModel.fromJson(jsonDecode(cached) as Map<String, dynamic>);
        } catch (_) {}
      }
      return null;
    }
  }

  /// GET /me; on first login ("Profile not created") create it from the sign-up data.
  Future<UserModel> _ensureProfile(sb.User user) async {
    try {
      final res = await _dio.get('/me');
      return UserModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail = (e.response?.data is Map) ? e.response?.data['detail'] : null;
      if (e.response?.statusCode == 403 && detail == 'Profile not created') {
        final meta = user.userMetadata ?? {};
        final fullName = (meta['full_name'] as String?)?.trim();
        final res = await _dio.post('/profile', data: {
          'name': (fullName == null || fullName.isEmpty) ? (user.email ?? 'User').split('@').first : fullName,
          'account_type': meta['account_type'] == 'DEALER' ? 'DEALER' : 'CUSTOMER',
          if (meta['business_name'] != null) 'business_name': meta['business_name'],
          if (meta['city'] != null) 'city': meta['city'],
        });
        return UserModel.fromJson(res.data as Map<String, dynamic>);
      }
      rethrow;
    }
  }

  String _friendlyAuthMessage(sb.AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('email not confirmed')) {
      return 'Please confirm your email first. Check your inbox for the link.';
    }
    if (msg.contains('invalid login')) {
      return 'Incorrect email or password.';
    }
    if (msg.contains('already registered')) {
      return 'An account with this email already exists. Try signing in.';
    }
    return e.message;
  }

  Future<void> _persistSession(UserModel user) async {
    await StorageHelper.setString(
      AppConstants.keyUserSession,
      jsonEncode(user.toJson()),
    );
  }
}
