// Data Repository Module
// Responsibility: Implementation of domain layer repository interfaces.
//
// Coordinates data from remote and local datasources.

import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/network/token_management.dart';
import '../../domain/entity/user_entity.dart';
import '../../domain/repository/auth_repository.dart';
import '../datasource/remote/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<UserEntity> login(String email, String password) async {
    try {
      final authResponse = await remoteDataSource.login(email, password);

      if (authResponse.accessToken.isNotEmpty &&
          authResponse.refreshToken.isNotEmpty) {
        await TokenManagement.instance.saveTokens(
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
    final refreshToken = TokenManagement.instance.getRefreshTokenSync();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await remoteDataSource.logout(refreshToken);
      } catch (_) {
        // Ignore logout errors
      }
    }
    await TokenManagement.instance.clearTokens();
  }
}
