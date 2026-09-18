import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SupabaseClient? get client => _isInitialized ? Supabase.instance.client : null;

  /// Initializes Supabase. If credentials are empty or placeholder, it degrades gracefully
  /// so the app can continue operating in local/mock mode.
  Future<void> initialize({
    required String supabaseUrl,
    required String anonKey,
  }) async {
    if (supabaseUrl.isEmpty || anonKey.isEmpty || supabaseUrl.contains('YOUR_')) {
      debugPrint('[SupabaseService] Credentials not provided or placeholder. Running in local/mock mode.');
      _isInitialized = false;
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: anonKey,
      );
      _isInitialized = true;
      debugPrint('[SupabaseService] Initialized successfully.');
    } catch (e) {
      debugPrint('[SupabaseService] Failed to initialize: $e');
      _isInitialized = false;
    }
  }
}
