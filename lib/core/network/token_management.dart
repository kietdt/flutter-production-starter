import 'dart:async';
import '../local_storage/shared_prefs_manager.dart';
import '../di/di.dart';
import 'network_client.dart';

class TokenManagement {
  static final TokenManagement _instance = TokenManagement._internal();
  static TokenManagement get instance => _instance;

  TokenManagement._internal();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  Completer<String?>? _refreshTokenCompleter;

  bool get isRefreshing => _refreshTokenCompleter != null;

  /// Gets the token. If a refresh is currently in progress, it will wait
  /// until the refresh is complete and return the new token unless [force] is true.
  Future<String?> getToken({bool force = false}) async {
    if (!force && _refreshTokenCompleter != null) {
      return _refreshTokenCompleter!.future;
    }
    return SharedPrefsManager.instance.getString(_accessTokenKey);
  }

  String? getAccessTokenSync() {
    return SharedPrefsManager.instance.getString(_accessTokenKey);
  }

  String? getRefreshTokenSync() {
    return SharedPrefsManager.instance.getString(_refreshTokenKey);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await SharedPrefsManager.instance.setString(_accessTokenKey, accessToken);
    await SharedPrefsManager.instance.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> clearTokens() async {
    await SharedPrefsManager.instance.remove(_accessTokenKey);
    await SharedPrefsManager.instance.remove(_refreshTokenKey);
  }

  /// Mark the start of a refresh token process.
  void startRefreshToken() {
    if (_refreshTokenCompleter == null || _refreshTokenCompleter!.isCompleted) {
      _refreshTokenCompleter = Completer<String?>();
    }
  }

  /// Mark the end of a refresh token process, successfully or not.
  void finishRefreshToken(String? newAccessToken) {
    if (_refreshTokenCompleter != null &&
        !_refreshTokenCompleter!.isCompleted) {
      _refreshTokenCompleter!.complete(newAccessToken);
    }
    _refreshTokenCompleter = null;
  }

  Future<String?> refreshToken() async {
    TokenManagement.instance.startRefreshToken();

    final refreshToken = getRefreshTokenSync();
    if (refreshToken == null || refreshToken.isEmpty) {
      finishRefreshToken(null);
      return null;
    }

    try {
      final networkClient = sl<NetworkClient>();
      final response = await networkClient.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        requiresAuth: false, // IMPORTANT: Bypass auth to prevent deadlock
      );

      final data = response;
      final newAccessToken = data['accessToken'] as String? ?? '';
      final newRefreshToken = data['refreshToken'] as String? ?? '';

      if (newAccessToken.isEmpty) {
        throw Exception('Refresh token failed: No access token returned');
      }

      // MUST save tokens BEFORE finishing refresh, otherwise concurrent
      // requests might read the old token from SharedPreferences.
      await saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      finishRefreshToken(newAccessToken);
      return newAccessToken;
    } catch (e) {
      finishRefreshToken(null);
      rethrow;
    }
  }
}
