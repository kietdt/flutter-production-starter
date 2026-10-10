// #6 — Errors added to any Cubit/Bloc are logged (and reported) centrally.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_production_starter/core/error/app_bloc_observer.dart';
import 'package:flutter_production_starter/core/utils/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_error_reporter.dart';

class _CounterCubit extends Cubit<int> {
  _CounterCubit() : super(0);

  void fail(Object error, StackTrace stackTrace) => addError(error, stackTrace);
}

void main() {
  late BlocObserver originalObserver;
  late FakeErrorReporter reporter;

  setUp(() {
    originalObserver = Bloc.observer;
    Bloc.observer = const AppBlocObserver();
    reporter = FakeErrorReporter();
    AppLogger.setReporter(reporter);
  });

  tearDown(() {
    Bloc.observer = originalObserver;
    AppLogger.setReporter(null);
  });

  test('an error added to a Cubit is reported as non-fatal', () async {
    final _CounterCubit cubit = _CounterCubit();
    final StateError error = StateError('cubit failed');
    final StackTrace stackTrace = StackTrace.current;

    cubit.fail(error, stackTrace);
    await cubit.close();

    expect(reporter.reports, hasLength(1));
    expect(reporter.reports.single.error, same(error));
    expect(reporter.reports.single.stackTrace, same(stackTrace));
    expect(reporter.reports.single.message, contains('_CounterCubit'));
    expect(reporter.reports.single.fatal, isFalse);
  });
}
