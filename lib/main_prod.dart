// Production flavor entry point (production backend).
// Run: flutter run -t lib/main_prod.dart

import 'package:flutter_production_starter/app/bootstrap.dart';
import 'package:flutter_production_starter/core/config/app_config.dart';

Future<void> main() => bootstrap(Flavor.prod);
