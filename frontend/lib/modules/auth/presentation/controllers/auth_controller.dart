import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/notifications/push_registration.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;
  final bool isInitialized;

  /// Set after sign-up when the user must confirm their email before signing in.
  final String? pendingConfirmationEmail;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.isInitialized = false,
    this.pendingConfirmationEmail,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    bool? isInitialized,
    String? pendingConfirmationEmail,
    bool clearPendingConfirmation = false,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isInitialized: isInitialized ?? this.isInitialized,
      pendingConfirmationEmail: clearPendingConfirmation
          ? null
          : (pendingConfirmationEmail ?? this.pendingConfirmationEmail),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  /// Runs before the session ends (e.g. to unregister this device from push).
  final Future<void> Function()? _beforeSignOut;

  AuthController(this._repository, {Future<void> Function()? beforeSignOut})
    : _beforeSignOut = beforeSignOut,
      super(const AuthState()) {
    checkCurrentSession();
  }

  Future<void> checkCurrentSession() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.getCurrentUser();
      state = state.copyWith(user: user, isLoading: false, isInitialized: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.signInWithEmailPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      );
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? businessName,
    String? city,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearPendingConfirmation: true,
    );
    try {
      final user = await _repository.signUpWithEmailPassword(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        businessName: businessName,
        city: city,
      );
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } on EmailConfirmationRequired catch (e) {
      state = state.copyWith(
        isLoading: false,
        pendingConfirmationEmail: e.email,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      try {
        await _beforeSignOut?.call();
      } catch (_) {
        // never block signing out
      }
      await _repository.signOut();
      state = const AuthState(isInitialized: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final repo = ref.watch(authRepositoryProvider);
    return AuthController(
      repo,
      beforeSignOut: () => ref.read(pushRegistrationProvider).removeCurrent(),
    );
  },
);
