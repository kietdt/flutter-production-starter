import 'package:dio/dio.dart';
import '../error/exceptions.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Core Network Module
/// Responsibility: Handle HTTP requests, interceptors, and network configuration.
class NetworkClient {
  late final Dio _dio;

  NetworkClient({
    required String baseUrl,
    required void Function() onUnauthorized,
    int connectionTimeout = 30000,
    int receiveTimeout = 30000,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(milliseconds: connectionTimeout),
        receiveTimeout: Duration(milliseconds: receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(
        dio: _dio,
        onUnauthorized: onUnauthorized,
      ),
      LoggingInterceptor(),
    ]);
  }

  /// Expose dio if direct access is needed (e.g. for FormData)
  Dio get dio => _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool requiresAuth = true,
  }) async {
    final mergedOptions = options ?? Options();
    mergedOptions.extra = {
      ...?mergedOptions.extra,
      'requiresAuth': requiresAuth,
    };

    return _request(
      () => _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: mergedOptions,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool requiresAuth = true,
  }) async {
    final mergedOptions = options ?? Options();
    mergedOptions.extra = {
      ...?mergedOptions.extra,
      'requiresAuth': requiresAuth,
    };

    return _request(
      () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: mergedOptions,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool requiresAuth = true,
  }) async {
    final mergedOptions = options ?? Options();
    mergedOptions.extra = {
      ...?mergedOptions.extra,
      'requiresAuth': requiresAuth,
    };

    return _request(
      () => _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: mergedOptions,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool requiresAuth = true,
  }) async {
    final mergedOptions = options ?? Options();
    mergedOptions.extra = {
      ...?mergedOptions.extra,
      'requiresAuth': requiresAuth,
    };

    return _request(
      () => _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: mergedOptions,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<T> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool requiresAuth = true,
  }) async {
    final mergedOptions = options ?? Options();
    mergedOptions.extra = {
      ...?mergedOptions.extra,
      'requiresAuth': requiresAuth,
    };

    return _request(
      () => _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: mergedOptions,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<T> _request<T>(Future<Response<T>> Function() requestFunc) async {
    try {
      final response = await requestFunc();
      return response.data as T;
    } on DioException catch (e) {
      throw _mapException(e);
    } catch (e) {
      throw ServerException(
        message: 'Unexpected error occurred: $e',
        code: NetworkErrorCode.unexpectedError.errorCode,
      );
    }
  }

  Exception _mapException(DioException exception) {
    final statusCode = exception.response?.statusCode?.toString();
    final responseData = exception.response?.data;
    final Map<String, dynamic>? errorData =
        responseData is Map<String, dynamic> ? responseData : null;

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ServerException(
          message: 'Connection timed out',
          code: NetworkErrorCode.timeout.errorCode,
        );
      case DioExceptionType.badResponse:
        final message = errorData?['message'] ?? 'Bad response from server';
        final code = errorData?['code']?.toString() ??
            statusCode ??
            NetworkErrorCode.badResponse.errorCode;
        return ServerException(
          message: '[$statusCode] $message',
          code: code,
          error: errorData,
        );
      case DioExceptionType.cancel:
        return ServerException(
          message: 'Request was cancelled',
          code: NetworkErrorCode.cancelled.errorCode,
        );
      case DioExceptionType.connectionError:
        return ServerException(
          message: 'No internet connection',
          code: NetworkErrorCode.connectionError.errorCode,
        );
      case DioExceptionType.unknown:
      default:
        return ServerException(
          message: exception.message ?? 'Unknown network error',
          code: NetworkErrorCode.unknown.errorCode,
        );
    }
  }
}
