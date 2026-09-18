enum Environment {
  dev,
  staging,
  prod;

  String get baseUrl {
    switch (this) {
      case Environment.dev:
        // Adjust port or host depending on local setup.
        // For Android Emulators, 10.0.2.2 usually maps to localhost.
        return 'http://localhost:8000/api';
      case Environment.staging:
        return 'https://staging.revora.com/api';
      case Environment.prod:
        return 'https://revora.com/api';
    }
  }

  bool get logEnabled {
    return this == Environment.dev;
  }

  String get supabaseUrl {
    switch (this) {
      case Environment.dev:
      case Environment.staging:
      case Environment.prod:
        return const String.fromEnvironment(
          'SUPABASE_URL',
          defaultValue: 'https://hjvzirkdnoaqahzusdbj.supabase.co',
        );
    }
  }

  String get supabaseAnonKey {
    switch (this) {
      case Environment.dev:
      case Environment.staging:
      case Environment.prod:
        return const String.fromEnvironment(
          'SUPABASE_ANON_KEY',
          defaultValue: 'sb_publishable_BE2NU_1zqFot3VSNCwfEiA_bRSmUNHF',
        );
    }
  }
}
