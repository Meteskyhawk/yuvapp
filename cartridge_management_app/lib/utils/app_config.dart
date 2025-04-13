import 'package:flutter/foundation.dart';
import 'app_logger.dart';

/// Manages application configuration and environment-specific settings
class AppConfig {
  // API configuration
  String _apiBaseUrl = 'https://www.thecolorapi.com';
  String get apiBaseUrl => _apiBaseUrl;

  // Feature flags
  bool _enableOfflineMode = false;
  bool get enableOfflineMode => _enableOfflineMode;

  // User preferences
  final bool _enableAutoSync = true;
  bool get enableAutoSync => _enableAutoSync;

  // Environment info
  final bool isProduction = !kDebugMode;

  // Sync configuration
  final Duration syncInterval = const Duration(minutes: 15);

  /// Initialize configuration with proper environment settings
  Future<void> init() async {
    try {
      AppLogger.debug('Initializing app configuration');

      // In a real app, load config from secure storage, environment, or .env file
      // For demonstration purposes, we're using hardcoded values

      // Adjust settings based on environment
      if (kReleaseMode) {
        // Production settings
        _enableOfflineMode = true;
        // API URL is already set to production by default
      } else if (kDebugMode) {
        // Development settings
        _enableOfflineMode = false;
        // Uncomment to use staging API in debug mode
        // _apiBaseUrl = 'https://staging.thecolorapi.com';
      }

      AppLogger.info('App configuration initialized with API: $_apiBaseUrl');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize app configuration', e, stackTrace);
      // Fall back to default values in case of failure
    }
  }

  /// Get a configuration value with a fallback default
  T getValue<T>(String key, T defaultValue) {
    // In a real app, retrieve from secure storage
    return defaultValue;
  }

  /// Save a configuration value
  Future<void> setValue<T>(String key, T value) async {
    // In a real app, save to secure storage
    AppLogger.debug('Setting config: $key = $value');
  }
}
