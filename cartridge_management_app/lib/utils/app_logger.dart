import 'package:flutter/foundation.dart';

/// A centralized logging utility for consistent log formatting and control
class AppLogger {
  static bool _initialized = false;
  static final DateTime _startTime = DateTime.now();

  /// Initialize the logger
  static void init() {
    _initialized = true;
    if (kDebugMode) {
      debug('Logger initialized');
    }
  }

  /// Log a debug message (only in debug mode)
  static void debug(String message) {
    if (!_initialized || !kDebugMode) return;

    _log('DEBUG', message);
  }

  /// Log an informational message
  static void info(String message) {
    if (!_initialized) return;

    _log('INFO', message);
  }

  /// Log a warning message
  static void warning(String message) {
    if (!_initialized) return;

    _log('WARNING', message);
  }

  /// Log an error message with optional error object and stack trace
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (!_initialized) return;

    _log('ERROR', message);

    if (error != null) {
      _log('ERROR', '└─ Error: $error');

      if (stackTrace != null && kDebugMode) {
        _log('ERROR', '└─ Stack: $stackTrace');
      }
    }
  }

  /// Internal logging helper
  static void _log(String level, String message) {
    final timeOffset =
        DateTime.now().difference(_startTime).toString().split('.').first;
    final formattedMessage = '[$timeOffset][$level] $message';

    if (kDebugMode) {
      print(formattedMessage);
    }

    // In production, could send logs to a service like Firebase Crashlytics
    // or another remote logging service
  }
}
