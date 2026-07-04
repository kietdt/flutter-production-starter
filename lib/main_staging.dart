// Staging flavor entry point (staging backend).
// Run: flutter run -t lib/main_staging.dart

import 'core/config/app_config.dart';
import 'main.dart';

Future<void> main() => bootstrap(Flavor.staging);
