import 'package:dio/dio.dart';
import 'package:flutter_production_starter/core/network/log_redactor.dart';
import 'package:flutter_production_starter/core/utils/app_logger.dart';

/// Logs requests, responses and errors with secrets masked by [LogRedactor].
///
/// Register it AFTER [AuthInterceptor] so the logged headers are the ones
/// actually sent (including `Authorization`, which is redacted).
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.debug(
      'REQUEST[${options.method}] => PATH: ${options.path}',
      name: 'NetworkClient',
    );
    AppLogger.debug('HEADERS: ${LogRedactor.redact(options.headers)}',
        name: 'NetworkClient');
    if (options.queryParameters.isNotEmpty) {
      AppLogger.debug(
          'QUERY PARAMETERS: ${LogRedactor.redact(options.queryParameters)}',
          name: 'NetworkClient');
    }
    if (options.data != null) {
      AppLogger.debug('BODY: ${LogRedactor.redact(options.data)}',
          name: 'NetworkClient');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(
      Response<dynamic> response, ResponseInterceptorHandler handler) {
    AppLogger.info(
      'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
      name: 'NetworkClient',
    );
    AppLogger.debug('DATA: ${LogRedactor.redact(response.data)}',
        name: 'NetworkClient');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.error(
      'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
      error: err.message,
      name: 'NetworkClient',
    );
    if (err.response?.data != null) {
      AppLogger.debug('ERROR DATA: ${LogRedactor.redact(err.response?.data)}',
          name: 'NetworkClient');
    }
    super.onError(err, handler);
  }
}
