// Core Config Module
// Responsibility: Per-flavor build configuration — which backend to talk to and
// how the build identifies itself. Base URLs live here so pointing an
// environment at a different server is a one-line change.

import '../utils/constants.dart';

/// Build flavors. Each flavor has its own entry point (`main_<flavor>.dart`).
enum Flavor { dev, staging, prod }

class AppConfig {
  final Flavor flavor;
  final String baseUrl;
  final String appName;

  const AppConfig({
    required this.flavor,
    required this.baseUrl,
    required this.appName,
  });

  /// Resolves the configuration for a [flavor]. `switch` per `enum-mapping.mdc`.
  factory AppConfig.fromFlavor(Flavor flavor) {
    switch (flavor) {
      case Flavor.dev:
        return const AppConfig(
          flavor: Flavor.dev,
          baseUrl: AppConstants.devApiBaseUrl,
          appName: 'Starter (Dev)',
        );
      case Flavor.staging:
        return const AppConfig(
          flavor: Flavor.staging,
          baseUrl: 'https://staging.api.example.com',
          appName: 'Starter (Staging)',
        );
      case Flavor.prod:
        return const AppConfig(
          flavor: Flavor.prod,
          baseUrl: 'https://api.example.com',
          appName: 'Flutter Production Starter',
        );
    }
  }

  static AppConfig? _instance;

  /// The active configuration. Falls back to the dev flavor when [init] was
  /// never called (e.g. under `flutter test`), so tests need no extra setup.
  static AppConfig get instance =>
      _instance ??= AppConfig.fromFlavor(Flavor.dev);

  /// Sets the active configuration. Call once from a flavor entry point
  /// (`main_dev.dart` / `main_staging.dart` / `main_prod.dart`) BEFORE
  /// initializing DI, since the network client reads [baseUrl] from here.
  static void init(AppConfig config) => _instance = config;

  bool get isProd => flavor == Flavor.prod;
}
