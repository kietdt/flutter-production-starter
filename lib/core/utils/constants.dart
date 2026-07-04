// Core Utils Module
// Responsibility: Shared constants, helper functions, and extensions.

class AppConstants {
  /// Local backend used by the `dev` flavor. Per-environment base URLs are
  /// resolved in `core/config/app_config.dart` (`AppConfig.fromFlavor`).
  static const String devApiBaseUrl = 'http://localhost:8080';
}

/// Keys used with [SharedPrefsManager]. Centralized to avoid typos and
/// accidental collisions across features.
class StorageKeys {
  StorageKeys._();

  /// Persisted [ThemeMode] index selected by the user.
  static const String themeMode = 'theme_mode';

  /// Persisted locale code (e.g. 'en', 'vi') selected by the user.
  static const String locale = 'locale';
}
