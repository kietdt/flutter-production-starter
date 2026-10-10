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

  /// Session tokens. Values must not change: existing installs keep their
  /// session across app updates.
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';

  /// The signed-in user (JSON), restored on app start without the network.
  static const String cachedUser = 'cached_user';
}
