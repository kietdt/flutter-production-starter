import 'package:flutter_production_starter/core/error/exceptions.dart';
import 'package:flutter_production_starter/core/error/failures.dart';
import 'package:flutter_production_starter/data/datasource/local/auth_local_datasource.dart';
import 'package:flutter_production_starter/data/datasource/remote/auth_remote_datasource.dart';
import 'package:flutter_production_starter/domain/entity/user_entity.dart';
import 'package:flutter_production_starter/domain/repository/auth_repository.dart';

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
        // Cached so the next app start restores the user without the network.
        await localDataSource.saveUser(authResponse.user);
      }

      return authResponse.user.toEntity();
    } on ServerException catch (e, st) {
      // Map data-layer exception → domain failure (UI never sees raw detail).
      throw e.toFailure(stackTrace: st);
    } catch (e, st) {
      // Parse errors, bugs… keep the root cause for crash reporting.
      throw UnknownFailure(cause: e, stackTrace: st);
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
    await localDataSource.clearUser();
  }

  @override
  UserEntity? currentUser() {
    final String? token = localDataSource.accessToken;
    if (token == null || token.isEmpty) return null;
    // A token without a cached user (e.g. an install from before users were
    // cached) is treated as no session; the next login overwrites the token.
    return localDataSource.cachedUser?.toEntity();
  }
}
