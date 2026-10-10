import 'package:flutter_production_starter/core/error/error_reporter.dart';

/// One call to [ErrorReporter.report], captured for assertions.
class ReportedError {
  final Object error;
  final StackTrace? stackTrace;
  final String message;
  final bool fatal;

  const ReportedError({
    required this.error,
    required this.stackTrace,
    required this.message,
    required this.fatal,
  });
}

/// Records every report; throws [throwOnReport] instead when it is set.
class FakeErrorReporter implements ErrorReporter {
  final Exception? throwOnReport;
  final List<ReportedError> reports = [];

  FakeErrorReporter({this.throwOnReport});

  @override
  void report({
    required Object error,
    StackTrace? stackTrace,
    required String message,
    required bool fatal,
  }) {
    if (throwOnReport != null) throw throwOnReport!;
    reports.add(ReportedError(
      error: error,
      stackTrace: stackTrace,
      message: message,
      fatal: fatal,
    ));
  }
}
