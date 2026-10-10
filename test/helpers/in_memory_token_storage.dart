import 'package:flutter_production_starter/core/network/token_storage.dart';

/// [TokenStorage] kept in memory, so token tests need no SharedPreferences.
class InMemoryTokenStorage implements TokenStorage {
  @override
  String? accessToken;

  @override
  String? refreshToken;

  InMemoryTokenStorage({this.accessToken, this.refreshToken});

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
  }
}
