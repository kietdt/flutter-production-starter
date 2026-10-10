import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_production_starter/core/error/exceptions.dart';
import 'package:flutter_production_starter/core/network/interceptors/auth_interceptor.dart';
import 'package:flutter_production_starter/core/network/interceptors/logging_interceptor.dart';
import 'package:flutter_production_starter/core/network/request_extra_keys.dart';
import 'package:flutter_production_starter/core/network/token_management.dart';
import 'package:flutter_production_starter/core/utils/map_ext.dart';

/// Typed HTTP client: every call goes through [_request], so failures always
/// surface as a [ServerException] (see `_mapException`).
class NetworkClient {
  late final Dio _dio;

  NetworkClient({
    required String baseUrl,
    required TokenManagement tokenManagement,
    required void Function() onUnauthorized,
    bool enableLogging = false,
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(
        dio: _dio,
        tokenManagement: tokenManagement,
        onUnauthorized: onUnauthorized,
      ),
      // After AuthInterceptor so the final headers are logged (redacted).
      if (enableLogging) LoggingInterceptor(),
    ]);
  }

  /// The underlying Dio, for tests (e.g. swapping `httpClientAdapter`).
  /// App code must use the typed methods: calling Dio directly skips the
  /// `DioException → ServerException` mapping. Add a method here (e.g.
  /// `upload`) instead of reaching for this.
  @visibleForTesting
  Dio get dio => _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool requiresAuth = true,
  }) {
    return _request(
      () => _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: _withAuth(options, requiresAuth: requiresAuth),
        cancelToken: cancelToken,
      ),
    );
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool requiresAuth = true,
  }) {
    return _request(
      () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _withAuth(options, requiresAuth: requiresAuth),
        cancelToken: cancelToken,
      ),
    );
  }

  Future<T> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool requiresAuth = true,
  }) {
    return _request(
      () => _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _withAuth(options, requiresAuth: requiresAuth),
        cancelToken: cancelToken,
      ),
    );
  }

  Future<T> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool requiresAuth = true,
  }) {
    return _request(
      () => _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _withAuth(options, requiresAuth: requiresAuth),
        cancelToken: cancelToken,
      ),
    );
  }

  Future<T> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool requiresAuth = true,
  }) {
    return _request(
      () => _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _withAuth(options, requiresAuth: requiresAuth),
        cancelToken: cancelToken,
      ),
    );
  }

  /// A copy of [options] flagged for [AuthInterceptor]. Never mutates the
  /// caller's instance, so an `Options` can be reused across requests.
  Options _withAuth(Options? options, {required bool requiresAuth}) {
    final Map<String, dynamic> extra = {
      ...?options?.extra,
      RequestExtraKeys.requiresAuth: requiresAuth,
    };
    return options?.copyWith(extra: extra) ?? Options(extra: extra);
  }

  Future<T> _request<T>(Future<Response<T>> Function() requestFunc) async {
    try {
      final response = await requestFunc();
      return response.data as T;
    } on DioException catch (e, st) {
      // Keep the original stack trace for logging / crash reporting.
      Error.throwWithStackTrace(_mapException(e), st);
    } catch (e, st) {
      Error.throwWithStackTrace(
        ServerException(type: NetworkErrorCode.unknown, cause: e),
        st,
      );
    }
  }

  ServerException _mapException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return ServerException(
          type: NetworkErrorCode.timeout,
          cause: exception,
        );
      case DioExceptionType.badCertificate:
        return ServerException(
          type: NetworkErrorCode.badCertificate,
          cause: exception,
        );
      case DioExceptionType.badResponse:
        final ({String? code, String? message}) body =
            _parseErrorBody(exception.response?.data);
        return ServerException(
          type: NetworkErrorCode.badResponse,
          statusCode: exception.response?.statusCode,
          serverCode: body.code,
          serverMessage: body.message,
          cause: exception,
        );
      case DioExceptionType.cancel:
        return ServerException(
          type: NetworkErrorCode.cancelled,
          cause: exception,
        );
      case DioExceptionType.connectionError:
        return ServerException(
          type: NetworkErrorCode.connectionError,
          cause: exception,
        );
      case DioExceptionType.unknown:
        return ServerException(
          type: NetworkErrorCode.unknown,
          cause: exception,
        );
    }
  }

  /// Reads the business error code + message out of an error response body.
  ///
  /// PROJECT HOOK: the one place that knows the backend's error format. The
  /// default reads `{"code": ..., "message": ...}`; adapt it for shapes like
  /// `{"error": {...}}` or `{"errors": [...]}`.
  ({String? code, String? message}) _parseErrorBody(Object? data) {
    if (data is! Map) return (code: null, message: null);
    return (
      code: data.parseStringOrNull('code'),
      message: data.parseStringOrNull('message'),
    );
  }
}
