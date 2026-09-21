import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/utils/storage_helper.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../mock/auth_mock_data.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    // Simulate real-world network latency
    await Future.delayed(const Duration(milliseconds: 350));

    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      throw Exception('Please enter an email address.');
    }
    if (password.trim().isEmpty) {
      throw Exception('Please enter your password.');
    }

    final account = AuthMockData.findAccount(normalizedEmail);
    if (account != null) {
      await _persistSession(account.user);
      return account.user;
    }

    // Dynamic mock user for any other valid email
    if (!normalizedEmail.contains('@')) {
      throw Exception('Please enter a valid email address.');
    }

    final dynamicUser = AuthMockData.createDynamicUser(
      email: normalizedEmail,
      password: password,
    );

    await _persistSession(dynamicUser);
    return dynamicUser;
  }

  @override
  Future<UserModel> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw Exception('Please enter a valid email address.');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    final newUser = AuthMockData.createDynamicUser(
      email: normalizedEmail,
      password: password,
      fullName: fullName,
      role: role,
    );

    await _persistSession(newUser);
    return newUser;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      await StorageHelper.remove(AppConstants.keyUserSession);
      await StorageHelper.clearTokens();
    } catch (e) {
      debugPrint('[MockAuthRepository] SignOut error: $e');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final savedData = StorageHelper.getString(AppConstants.keyUserSession);
    if (savedData != null) {
      try {
        final map = jsonDecode(savedData) as Map<String, dynamic>;
        return UserModel.fromJson(map);
      } catch (e) {
        debugPrint('[MockAuthRepository] Failed to parse cached session: $e');
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
