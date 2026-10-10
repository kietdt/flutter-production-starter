// Core Logger Module
// Responsibility: Provide a unified logging interface for the entire application.
//
// Replaces the default print() and developer.log().

import 'dart:developer' as developer;

import 'package:flutter_production_starter/core/error/error_reporter.dart';

class AppLogger {
  static ErrorReporter? _reporter;

  /// Attaches a crash-reporting backend; `null` detaches it.
  static void setReporter(ErrorReporter? reporter) => _reporter = reporter;

  static void info(String message, {String name = 'AppInfo'}) {
    developer.log(message, name: name);
  }

  /// Logs [message]; when an [error] object is given it is also forwarded to
  /// the [ErrorReporter] (if any). [fatal] marks uncaught errors.
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String name = 'AppError',
    bool fatal = false,
  }) {
    developer.log(message, name: name, error: error, stackTrace: stackTrace);
    if (error == null) return;
    try {
      _reporter?.report(
        error: error,
        stackTrace: stackTrace,
        message: message,
        fatal: fatal,
      );
    } catch (e, st) {
      // A broken reporter must never crash the app or recurse into itself.
      developer.log('ErrorReporter failed',
          name: name, error: e, stackTrace: st);
    }
  }

  static void debug(String message, {String name = 'AppDebug'}) {
    developer.log(message, name: name);
  }
}
