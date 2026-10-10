import 'package:flutter_production_starter/app/bootstrap.dart';
import 'package:flutter_production_starter/core/config/app_config.dart';

/// Default entry point — equivalent to the dev flavor, so `flutter run` works
/// without a target. Flavor-specific entry points live in `main_dev.dart`,
/// `main_staging.dart`, and `main_prod.dart`.
Future<void> main() => bootstrap(Flavor.dev);
