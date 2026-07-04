// Production flavor entry point (production backend).
// Run: flutter run -t lib/main_prod.dart

import 'core/config/app_config.dart';
import 'main.dart';

Future<void> main() => bootstrap(Flavor.prod);
