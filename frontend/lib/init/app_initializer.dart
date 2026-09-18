import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../core/config/environment.dart';
import '../core/utils/storage_helper.dart';
import '../core/supabase/supabase_service.dart';

class AppInitializer {
  AppInitializer._();

  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize secure/normal local storage
    await StorageHelper.init();

    // Default environment config to development mode
    AppConfig.instance.initialize(Environment.dev);

    // Initialize Supabase with graceful fallback
    await SupabaseService.instance.initialize(
      supabaseUrl: AppConfig.instance.supabaseUrl,
      anonKey: AppConfig.instance.supabaseAnonKey,
    );
  }
}
