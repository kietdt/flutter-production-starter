// #6 — Uncaught framework and async errors are routed to AppLogger (and from
// there to the ErrorReporter) instead of being lost.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_production_starter/core/error/global_error_handler.dart';
import 'package:flutter_production_starter/core/utils/app_logger.dart';

import '../../helpers/fake_error_reporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeErrorReporter reporter;
  late FlutterExceptionHandler? originalOnError;
  late ErrorCallback? originalPlatformOnError;
  late FlutterExceptionHandler originalPresentError;
  late List<FlutterErrorDetails> presented;

  setUp(() {
    originalOnError = FlutterError.onError;
    originalPlatformOnError = PlatformDispatcher.instance.onError;
    originalPresentError = FlutterError.presentError;
    presented = [];
    FlutterError.presentError = presented.add;

    reporter = FakeErrorReporter();
    AppLogger.setReporter(reporter);
    GlobalErrorHandler.install();
  });

  tearDown(() {
    FlutterError.onError = originalOnError;
    PlatformDispatcher.instance.onError = originalPlatformOnError;
    FlutterError.presentError = originalPresentError;
    AppLogger.setReporter(null);
  });

  test('framework errors are reported as fatal and still presented', () {
    final StateError error = StateError('build failed');
    final StackTrace stackTrace = StackTrace.current;
    final FlutterErrorDetails details =
        FlutterErrorDetails(exception: error, stack: stackTrace);

    FlutterError.onError!(details);

    expect(reporter.reports, hasLength(1));
    expect(reporter.reports.single.error, same(error));
    expect(reporter.reports.single.stackTrace, same(stackTrace));
    expect(reporter.reports.single.fatal, isTrue);
    expect(presented, [same(details)]);
  });

  test('uncaught async errors are reported as fatal and marked handled', () {
    final StateError error = StateError('async failed');
    final StackTrace stackTrace = StackTrace.current;

    final bool handled =
        PlatformDispatcher.instance.onError!(error, stackTrace);

    expect(handled, isTrue);
    expect(reporter.reports, hasLength(1));
    expect(reporter.reports.single.error, same(error));
    expect(reporter.reports.single.stackTrace, same(stackTrace));
    expect(reporter.reports.single.fatal, isTrue);
  });
}
