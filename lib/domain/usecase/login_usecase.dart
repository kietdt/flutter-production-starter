/// Domain Usecase Module
/// Responsibility: Orchestrate business rules. Contains specific actions requested by the user.

import '../entity/user_entity.dart';
import '../repository/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<UserEntity> execute(String email, String password) {
    return repository.login(email, password);
  }
}
