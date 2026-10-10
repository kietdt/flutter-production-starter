import 'package:flutter_production_starter/data/datasource/local/auth_local_datasource.dart';
import 'package:flutter_production_starter/data/model/user_model.dart';

import 'in_memory_token_storage.dart';

/// [AuthLocalDataSource] kept in memory (tokens + cached user), so repository
/// tests need no SharedPreferences.
class InMemoryAuthLocalDataSource extends InMemoryTokenStorage
    implements AuthLocalDataSource {
  @override
  UserModel? cachedUser;

  InMemoryAuthLocalDataSource({
    super.accessToken,
    super.refreshToken,
    this.cachedUser,
  });

  @override
  Future<void> saveUser(UserModel user) async => cachedUser = user;

  @override
  Future<void> clearUser() async => cachedUser = null;
}
