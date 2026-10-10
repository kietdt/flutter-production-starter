// Dev flavor entry point (local backend).
// Run: flutter run -t lib/main_dev.dart

import 'package:flutter_production_starter/app/bootstrap.dart';
import 'package:flutter_production_starter/core/config/app_config.dart';

Future<void> main() => bootstrap(Flavor.dev);
