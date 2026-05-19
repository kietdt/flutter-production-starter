import 'package:dio/dio.dart';
import '../../utils/app_logger.dart';
import '../token_management.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  final void Function() onUnauthorized;

  AuthInterceptor({
    required this.dio,
    required this.onUnauthorized,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Bypass auth for endpoints that don't need it (e.g. login, refresh token)
    if (options.extra['requiresAuth'] == false) {
      return super.onRequest(options, handler);
    }

    final token = await TokenManagement.instance.getToken();
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
    if (err.response?.statusCode == 401) {
      // If this request was already retried and still got 401, don't retry again (prevents infinite loop)
      if (err.requestOptions.extra['isRetry'] == true) {
        return super.onError(err, handler);
      }

      // If we don't have a refresh token, we cannot refresh.
      final currentRefreshToken =
          TokenManagement.instance.getRefreshTokenSync();
      if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
        return super.onError(err, handler);
      }

      AppLogger.info('Token expired, handling 401...', name: 'AuthInterceptor');

      // If a refresh is already in progress, wait for it
      if (TokenManagement.instance.isRefreshing) {
        AppLogger.info(
          'Waiting for ongoing token refresh...',
          name: 'AuthInterceptor',
        );
        final newToken = await TokenManagement.instance.getToken();

        if (newToken != null && newToken.isNotEmpty) {
          return _retryRequest(err, newToken, handler);
        } else {
          return handler.next(err);
        }
      }

      // Check if token was already refreshed while this request was in flight
      final requestToken = err.requestOptions.headers['Authorization']
          ?.toString()
          .replaceFirst('Bearer ', '');
      final currentToken = await TokenManagement.instance.getToken();

      if (currentToken != null &&
          currentToken.isNotEmpty &&
          currentToken != requestToken) {
        AppLogger.info(
          'Token already refreshed by another request, retrying...',
          name: 'AuthInterceptor',
        );
        return _retryRequest(err, currentToken, handler);
      }

      try {
        AppLogger.info('Attempting refresh token...', name: 'AuthInterceptor');
        final newToken = await TokenManagement.instance.refreshToken();

        if (newToken != null && newToken.isNotEmpty) {
          return _retryRequest(err, newToken, handler);
        } else {
          await TokenManagement.instance.clearTokens();
          onUnauthorized();
          return handler.next(err);
        }
      } catch (e) {
        await TokenManagement.instance.clearTokens();
        onUnauthorized();
        return handler.next(err);
      }
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
    options.extra['isRetry'] = true;

    try {
      // Use the existing dio instance. The onRequest interceptor will automatically
      // pick up the new token from TokenManagement, so we don't need to manually
      // set the Authorization header here.
      final response = await dio.fetch(options);
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
