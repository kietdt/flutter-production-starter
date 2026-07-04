// Dev flavor entry point (local backend).
// Run: flutter run -t lib/main_dev.dart

import 'core/config/app_config.dart';
import 'main.dart';

Future<void> main() => bootstrap(Flavor.dev);
