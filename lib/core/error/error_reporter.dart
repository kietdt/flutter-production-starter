/// Sends errors to a crash-reporting backend (Crashlytics, Sentry…).
///
/// Plug one in with `AppLogger.setReporter(...)` in `bootstrap()`; every
/// `AppLogger.error(..., error: e)` call is then forwarded without touching
/// call sites.
abstract interface class ErrorReporter {
  /// [fatal] is `true` for uncaught errors (framework / async), `false` for
  /// errors the app caught and logged itself.
  void report({
    required Object error,
    StackTrace? stackTrace,
    required String message,
    required bool fatal,
  });
}
