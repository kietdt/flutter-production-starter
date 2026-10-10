// Data Local Datasource Module
// Responsibility: Persist the session tokens. Implements core's TokenStorage so
// the network layer (TokenManagement) and AuthRepository share one source.

import '../../../core/local_storage/shared_prefs_manager.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/utils/constants.dart';

abstract interface class AuthLocalDataSource implements TokenStorage {}

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
}
