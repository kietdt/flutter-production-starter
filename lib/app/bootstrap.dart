import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_production_starter/app/app.dart';
import 'package:flutter_production_starter/app/di/di.dart';
import 'package:flutter_production_starter/core/config/app_config.dart';
import 'package:flutter_production_starter/core/error/app_bloc_observer.dart';
import 'package:flutter_production_starter/core/error/global_error_handler.dart';

/// Shared bootstrap for every flavor: installs global error handling, pins
/// the active [AppConfig] (which the network client reads for its base URL)
/// before wiring up DI and the app.
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Plug a crash backend here, e.g. AppLogger.setReporter(SentryReporter()).
  GlobalErrorHandler.install();
  Bloc.observer = const AppBlocObserver();
  AppConfig.init(AppConfig.fromFlavor(flavor));
  await initApp();
  runApp(const MyApp());
}

Future<void> initApp() async {
  await initDI();
}
