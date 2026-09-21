import 'environment.dart';

class AppConfig {
  AppConfig._();

  static final AppConfig instance = AppConfig._();

  Environment _environment = Environment.dev;

  void initialize(Environment environment) {
    _environment = environment;
  }

  Environment get environment => _environment;
  String get baseUrl => _environment.baseUrl;
  bool get logEnabled => _environment.logEnabled;
  String get supabaseUrl => _environment.supabaseUrl;
  String get supabaseAnonKey => _environment.supabaseAnonKey;
  bool get useMockData => _environment.useMockData;

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
