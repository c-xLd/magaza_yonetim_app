import 'package:logging/logging.dart';
import 'dart:developer' as developer;

/// A utility class for handling logging throughout the application
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  static Logger? _logger;

  factory AppLogger() {
    return _instance;
  }

  AppLogger._internal() {
    _initializeLogger();
  }

  void _initializeLogger() {
    Logger.root.level = Level.ALL; // Set the default log level
    Logger.root.onRecord.listen((record) {
      // Konsol çıktısının yanı sıra, Firebase Crashlytics veya diğer
      // uzak loglama servislerine log gönderebilirsiniz
      developer.log('${record.level.name}: ${record.time}: ${record.message}', 
          name: 'AppLogger');
      if (record.error != null) {
        developer.log('HATA: ${record.error}', 
            name: 'AppLogger', 
            error: record.error);
      }
      if (record.stackTrace != null) {
        developer.log('YIĞIN İZİ', 
            name: 'AppLogger', 
            stackTrace: record.stackTrace);
      }
    });
  }

  /// Get a logger for a specific class or component
  static Logger getLogger(String name) {
    _logger ??= Logger(name);
    return _logger!;
  }

  /// Log a debug message
  static void d(String message, [Object? error, StackTrace? stackTrace]) {
    getLogger('APP').fine(message, error, stackTrace);
  }

  /// Log an info message
  static void i(String message, [Object? error, StackTrace? stackTrace]) {
    getLogger('APP').info(message, error, stackTrace);
  }

  /// Log a warning message
  static void w(String message, [Object? error, StackTrace? stackTrace]) {
    getLogger('APP').warning(message, error, stackTrace);
  }

  /// Log an error message
  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    getLogger('APP').severe(message, error, stackTrace);
  }
}
