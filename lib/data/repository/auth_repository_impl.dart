/// Data Repository Module
/// Responsibility: Implementation of domain layer repository interfaces.
/// 
/// Coordinates data from remote and local datasources.

import '../../domain/entity/user_entity.dart';
import '../../domain/repository/auth_repository.dart';
import '../datasource/remote/auth_remote_datasource.dart';
import '../model/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserEntity> login(String email, String password) async {
    final response = await remoteDataSource.login(email, password);
    final userModel = UserModel.fromJson(response);
    return userModel.toEntity();
  }
}
