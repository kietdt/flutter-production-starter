// Staging flavor entry point (staging backend).
// Run: flutter run -t lib/main_staging.dart

import 'package:flutter_production_starter/app/bootstrap.dart';
import 'package:flutter_production_starter/core/config/app_config.dart';

Future<void> main() => bootstrap(Flavor.staging);
