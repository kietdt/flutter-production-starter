import 'package:dio/dio.dart';
import 'package:flutter_production_starter/core/network/request_extra_keys.dart';
import 'package:flutter_production_starter/core/network/token_management.dart';
import 'package:flutter_production_starter/core/utils/app_logger.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  final TokenManagement tokenManagement;
  final void Function() onUnauthorized;

  AuthInterceptor({
    required this.dio,
    required this.tokenManagement,
    required this.onUnauthorized,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Bypass auth for endpoints that don't need it (e.g. login, refresh token)
    if (options.extra[RequestExtraKeys.requiresAuth] == false) {
      return super.onRequest(options, handler);
    }

    final token = await tokenManagement.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Unauthenticated endpoints (login, refresh, logout) never enter the refresh
    // flow: a 401 from /auth/refresh would otherwise wait on its own refresh
    // and hang forever, and a wrong-password 401 on login is not an expiry.
    if (err.requestOptions.extra[RequestExtraKeys.requiresAuth] == false) {
      return handler.next(err);
    }

    if (err.response?.statusCode == 401) {
      // If this request was already retried and still got 401, don't retry again (prevents infinite loop)
      if (err.requestOptions.extra[RequestExtraKeys.isRetry] == true) {
        return super.onError(err, handler);
      }

      // If we don't have a refresh token, we cannot refresh.
      final currentRefreshToken = tokenManagement.getRefreshTokenSync();
      if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
        return super.onError(err, handler);
      }

      AppLogger.info('Token expired, handling 401...', name: 'AuthInterceptor');

      // Check if token was already refreshed while this request was in flight.
      // Read synchronously: no await may sit between the `isRefreshing` check
      // below and refreshToken(), or concurrent 401s could both start one.
      final requestToken = err.requestOptions.headers['Authorization']
          ?.toString()
          .replaceFirst('Bearer ', '');
      final currentToken = tokenManagement.getAccessTokenSync();

      if (currentToken != null &&
          currentToken.isNotEmpty &&
          currentToken != requestToken) {
        AppLogger.info(
          'Token already refreshed by another request, retrying...',
          name: 'AuthInterceptor',
        );
        return _retryRequest(err, currentToken, handler);
      }

      // refreshToken() is idempotent: the first 401 starts the refresh, later
      // ones join it. Only the starter ends the session on failure, so
      // onUnauthorized fires once no matter how many requests were waiting.
      final startsRefresh = !tokenManagement.isRefreshing;
      String? newToken;
      try {
        AppLogger.info(
          startsRefresh
              ? 'Attempting refresh token...'
              : 'Waiting for ongoing token refresh...',
          name: 'AuthInterceptor',
        );
        newToken = await tokenManagement.refreshToken();
      } catch (e) {
        AppLogger.error(
          'Token refresh failed',
          error: e,
          name: 'AuthInterceptor',
        );
      }

      if (newToken != null && newToken.isNotEmpty) {
        return _retryRequest(err, newToken, handler);
      }
      if (startsRefresh) {
        await tokenManagement.clearTokens();
        onUnauthorized();
      }
      return handler.next(err);
    }
    return super.onError(err, handler);
  }

  Future<void> _retryRequest(
    DioException err,
    String newToken,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;

    // Flag this request as a retry so we don't get stuck in an infinite 401 loop
    options.extra[RequestExtraKeys.isRetry] = true;

    try {
      // Use the existing dio instance. The onRequest interceptor will automatically
      // pick up the new token from TokenManagement, so we don't need to manually
      // set the Authorization header here.
      final response = await dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } catch (e) {
      if (e is DioException) {
        return handler.next(e);
      } else {
        return handler.next(
          DioException(
            requestOptions: options,
            error: e,
          ),
        );
      }
    }
  }
}
