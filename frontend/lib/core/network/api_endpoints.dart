class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String verifyEmail = '/auth/verify-email';
  static const String sendVerificationEmail = '/auth/send-verification-email';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Placeholder endpoint listings (for later phases)
  static const String listings = '/listings';
  static const String categories = '/categories';
  static const String profile = '/profile';
  static const String chats = '/chats';
  static const String notifications = '/notifications';
}
