// Data Repository Module
// Responsibility: Implementation of domain layer repository interfaces.
//
// Coordinates data from remote and local datasources.

import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../domain/entity/user_entity.dart';
import '../../domain/repository/auth_repository.dart';
import '../datasource/local/auth_local_datasource.dart';
import '../datasource/remote/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<UserEntity> login(String email, String password) async {
    try {
      final authResponse = await remoteDataSource.login(email, password);

      if (authResponse.accessToken.isNotEmpty &&
          authResponse.refreshToken.isNotEmpty) {
        await localDataSource.saveTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
        );
      }

      return authResponse.user.toEntity();
    } on ServerException catch (e) {
      // Map data-layer exception → domain failure (UI never sees raw detail).
      throw e.toFailure();
    } catch (_) {
      throw const UnknownFailure();
    }
  }

  @override
  Future<void> logout() async {
    final String? refreshToken = localDataSource.refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await remoteDataSource.logout(refreshToken);
      } catch (_) {
        // Ignore logout errors
      }
    }
    await localDataSource.clearTokens();
  }

  @override
  bool hasSession() {
    final String? token = localDataSource.accessToken;
    return token != null && token.isNotEmpty;
  }
}
