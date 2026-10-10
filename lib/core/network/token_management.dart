import 'dart:async';

import 'package:flutter_production_starter/core/network/token_pair.dart';
import 'package:flutter_production_starter/core/network/token_storage.dart';

/// Exchanges a refresh token for a new [TokenPair] (the `/auth/refresh` call).
/// Wired in DI to `AuthRemoteDataSource.refresh`, keeping core free of data.
typedef TokenRefresher = Future<TokenPair> Function(String refreshToken);

class TokenManagement {
  final TokenStorage storage;
  final TokenRefresher refresher;

  TokenManagement({
    required this.storage,
    required this.refresher,
  });

  Completer<String?>? _refreshTokenCompleter;

  bool get isRefreshing => _refreshTokenCompleter != null;

  /// Gets the token. If a refresh is currently in progress, it will wait
  /// until the refresh is complete and return the new token unless [force] is true.
  Future<String?> getToken({bool force = false}) async {
    if (!force && _refreshTokenCompleter != null) {
      return _refreshTokenCompleter!.future;
    }
    return storage.accessToken;
  }

  String? getAccessTokenSync() => storage.accessToken;

  String? getRefreshTokenSync() => storage.refreshToken;

  Future<void> clearTokens() => storage.clearTokens();

  /// Mark the end of a refresh token process, successfully or not.
  void _finishRefreshToken(String? newAccessToken) {
    if (_refreshTokenCompleter != null &&
        !_refreshTokenCompleter!.isCompleted) {
      _refreshTokenCompleter!.complete(newAccessToken);
    }
    _refreshTokenCompleter = null;
  }

  /// Refreshes the access token. Idempotent: while a refresh is in flight,
  /// further callers join it instead of hitting the network again (with
  /// refresh-token rotation a second call would present a spent token).
  ///
  /// The caller that started the refresh gets the error rethrown on failure;
  /// callers that joined resolve with `null`.
  Future<String?> refreshToken() async {
    final inFlight = _refreshTokenCompleter;
    if (inFlight != null) return inFlight.future;
    // Set synchronously (before any await) so concurrent callers see it.
    _refreshTokenCompleter = Completer<String?>();

    final String? refreshToken = getRefreshTokenSync();
    if (refreshToken == null || refreshToken.isEmpty) {
      _finishRefreshToken(null);
      return null;
    }

    try {
      final TokenPair tokens = await refresher(refreshToken);
      if (tokens.accessToken.isEmpty) {
        throw StateError('Refresh token failed: no access token returned');
      }

      // MUST save tokens BEFORE finishing refresh, otherwise concurrent
      // requests might read the old token from storage. A server that does
      // not rotate refresh tokens omits it — keep the current one then.
      await storage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken:
            tokens.refreshToken.isNotEmpty ? tokens.refreshToken : refreshToken,
      );

      _finishRefreshToken(tokens.accessToken);
      return tokens.accessToken;
    } catch (e) {
      _finishRefreshToken(null);
      rethrow;
    }
  }
}
