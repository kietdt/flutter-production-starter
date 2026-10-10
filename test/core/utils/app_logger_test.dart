// #6 — AppLogger forwards errors to a pluggable ErrorReporter (Crashlytics,
// Sentry…), so call sites never change when a crash backend is added.

import 'package:flutter_production_starter/core/utils/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_error_reporter.dart';

void main() {
  tearDown(() => AppLogger.setReporter(null));

  test('error() forwards the error, stack trace and message to the reporter',
      () {
    final FakeErrorReporter reporter = FakeErrorReporter();
    AppLogger.setReporter(reporter);
    final StateError error = StateError('boom');
    final StackTrace stackTrace = StackTrace.current;

    AppLogger.error('Something failed', error: error, stackTrace: stackTrace);

    expect(reporter.reports, hasLength(1));
    final ReportedError report = reporter.reports.single;
    expect(report.error, same(error));
    expect(report.stackTrace, same(stackTrace));
    expect(report.message, 'Something failed');
    expect(report.fatal, isFalse);
  });

  test('error() passes the fatal flag through', () {
    final FakeErrorReporter reporter = FakeErrorReporter();
    AppLogger.setReporter(reporter);

    AppLogger.error('Crash', error: StateError('boom'), fatal: true);

    expect(reporter.reports.single.fatal, isTrue);
  });

  test('error() without an error object is logged only, not reported', () {
    final FakeErrorReporter reporter = FakeErrorReporter();
    AppLogger.setReporter(reporter);

    AppLogger.error('Just a message');

    expect(reporter.reports, isEmpty);
  });

  test('info() and debug() are never reported', () {
    final FakeErrorReporter reporter = FakeErrorReporter();
    AppLogger.setReporter(reporter);

    AppLogger.info('info');
    AppLogger.debug('debug');

    expect(reporter.reports, isEmpty);
  });

  test('a failing reporter does not break the caller', () {
    AppLogger.setReporter(FakeErrorReporter(throwOnReport: Exception('down')));

    expect(
      () => AppLogger.error('Something failed', error: StateError('boom')),
      returnsNormally,
    );
  });

  test('setReporter(null) detaches the reporter', () {
    final FakeErrorReporter reporter = FakeErrorReporter();
    AppLogger.setReporter(reporter);
    AppLogger.setReporter(null);

    AppLogger.error('Something failed', error: StateError('boom'));

    expect(reporter.reports, isEmpty);
  });
}
