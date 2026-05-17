/// Core Logger Module
/// Responsibility: Provide a unified logging interface for the entire application.
///
/// Replaces the default print() and developer.log().

import 'dart:developer' as developer;

class AppLogger {
  static void info(String message, {String name = 'AppInfo'}) {
    developer.log(message, name: name);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String name = 'AppError',
  }) {
    developer.log(message, name: name, error: error, stackTrace: stackTrace);
  }

  static void debug(String message, {String name = 'AppDebug'}) {
    developer.log(message, name: name);
  }
}
