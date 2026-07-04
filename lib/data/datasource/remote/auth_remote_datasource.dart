// Data Remote Datasource Module
// Responsibility: Communicate with external APIs/services.

import '../../../core/network/network_client.dart';
import '../../model/auth_response_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(String email, String password);
  Future<AuthResponseModel> refresh(String refreshToken);
  Future<void> logout(String refreshToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final NetworkClient networkClient;

  AuthRemoteDataSourceImpl({
    required this.networkClient,
  });

  @override
  Future<AuthResponseModel> login(String email, String password) async {
    final response = await networkClient.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
      requiresAuth: false,
    );
    return AuthResponseModel.fromJson(response);
  }

  @override
  Future<AuthResponseModel> refresh(String refreshToken) async {
    final response = await networkClient.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {
        'refreshToken': refreshToken,
      },
      requiresAuth: false,
    );
    return AuthResponseModel.fromJson(response);
  }

  @override
  Future<void> logout(String refreshToken) async {
    await networkClient.post<Map<String, dynamic>>(
      '/auth/logout',
      data: {
        'refreshToken': refreshToken,
      },
      requiresAuth:
          false, // assuming logout doesn't strictly need interceptor token if we send refreshToken
    );
  }
}
