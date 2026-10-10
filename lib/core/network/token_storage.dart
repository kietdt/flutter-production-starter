/// Where the session tokens are persisted. Implemented in the data layer
/// (`AuthLocalDataSource`) so core never depends on data.
abstract interface class TokenStorage {
  /// Read synchronously so the auth interceptor never awaits between checking
  /// and starting a refresh (see `TokenManagement.refreshToken`).
  String? get accessToken;
  String? get refreshToken;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<void> clearTokens();
}
