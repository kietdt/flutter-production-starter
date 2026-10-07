import 'package:flutter/foundation.dart';

import '../utils/app_logger.dart';

/// Routes errors nobody caught into [AppLogger] (and its ErrorReporter).
class GlobalErrorHandler {
  GlobalErrorHandler._();

  /// Call once in `bootstrap()`, right after `ensureInitialized()`.
  static void install() {
    // Errors thrown by the framework (build, layout, paint, gestures…).
    FlutterError.onError = (FlutterErrorDetails details) {
      // Keep Flutter's default console dump for debugging.
      FlutterError.presentError(details);
      AppLogger.error(
        'Uncaught Flutter error',
        error: details.exception,
        stackTrace: details.stack,
        name: 'FlutterError',
        fatal: true,
      );
    };

    // Uncaught async errors outside the framework (futures, timers, isolates
    // messages…).
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      AppLogger.error(
        'Uncaught async error',
        error: error,
        stackTrace: stack,
        name: 'PlatformDispatcher',
        fatal: true,
      );
      return true;
    };
  }
}
