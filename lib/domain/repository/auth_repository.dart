import 'package:flutter_production_starter/domain/entity/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<void> logout();

  /// The user of the locally stored session, or `null` when there is none.
  /// A session needs both an access token and the cached user.
  UserEntity? currentUser();
}
