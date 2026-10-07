import 'package:flutter_bloc/flutter_bloc.dart';

import '../utils/app_logger.dart';

/// Global [BlocObserver]: logs (and reports) every error added to a Cubit/Bloc.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    AppLogger.error(
      'Unhandled error in ${bloc.runtimeType}',
      error: error,
      stackTrace: stackTrace,
      name: 'BlocObserver',
    );
    super.onError(bloc, error, stackTrace);
  }
}
