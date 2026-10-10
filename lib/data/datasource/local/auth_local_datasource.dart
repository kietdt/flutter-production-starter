// Data Local Datasource Module
// Responsibility: Persist the session — tokens and the signed-in user.
// Implements core's TokenStorage so the network layer (TokenManagement) and
// AuthRepository share one source.

import 'dart:convert';

import 'package:flutter_production_starter/core/local_storage/shared_prefs_manager.dart';
import 'package:flutter_production_starter/core/network/token_storage.dart';
import 'package:flutter_production_starter/core/utils/app_logger.dart';
import 'package:flutter_production_starter/core/utils/constants.dart';
import 'package:flutter_production_starter/data/model/user_model.dart';

abstract interface class AuthLocalDataSource implements TokenStorage {
  /// The user saved at login, or `null` when none is stored (or it can't be
  /// read back).
  UserModel? get cachedUser;

  Future<void> saveUser(UserModel user);

  Future<void> clearUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPrefsManager prefs;

  AuthLocalDataSourceImpl({required this.prefs});

  @override
  String? get accessToken => prefs.getString(StorageKeys.accessToken);

  @override
  String? get refreshToken => prefs.getString(StorageKeys.refreshToken);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await prefs.setString(StorageKeys.accessToken, accessToken);
    await prefs.setString(StorageKeys.refreshToken, refreshToken);
  }

  @override
  Future<void> clearTokens() async {
    await prefs.remove(StorageKeys.accessToken);
    await prefs.remove(StorageKeys.refreshToken);
  }

  @override
  UserModel? get cachedUser {
    final String? raw = prefs.getString(StorageKeys.cachedUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      return decoded is Map ? UserModel.fromJson(decoded) : null;
    } on FormatException catch (e) {
      // Corrupt entry: treat as "no user" so the app falls back to login.
      AppLogger.info('Ignoring unreadable cached user: $e',
          name: 'AuthLocalDataSource');
      return null;
    }
  }

  @override
  Future<void> saveUser(UserModel user) async {
    await prefs.setString(StorageKeys.cachedUser, jsonEncode(user.toJson()));
  }

  @override
  Future<void> clearUser() async {
    await prefs.remove(StorageKeys.cachedUser);
  }
}
