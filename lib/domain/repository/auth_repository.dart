// Domain Repository Module
// Responsibility: Abstract interfaces for data operations.
//
// Implementation belongs in the data layer.

import '../entity/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<void> logout();
}
