class AppConstants {
  AppConstants._();

  static const String appName = 'Revora';

  // Secure Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserSession = 'user_session';

  // Shared Preferences Keys
  static const String prefThemeMode = 'theme_mode';
  static const String prefLocale = 'app_locale';
  static const String prefAccentColor = 'accent_color';

  // Pagination Constants
  static const int defaultPageSize = 20;

  // Cache & Network Config
  static const int maxImagesToUpload = 10;
}
