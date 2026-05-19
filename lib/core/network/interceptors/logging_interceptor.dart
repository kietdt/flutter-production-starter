import 'package:dio/dio.dart';
import '../../utils/app_logger.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.debug(
      'REQUEST[${options.method}] => PATH: ${options.path}',
      name: 'NetworkClient',
    );
    if (options.queryParameters.isNotEmpty) {
      AppLogger.debug('QUERY PARAMETERS: ${options.queryParameters}',
          name: 'NetworkClient');
    }
    if (options.data != null) {
      AppLogger.debug('BODY: ${options.data}', name: 'NetworkClient');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.info(
      'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
      name: 'NetworkClient',
    );
    AppLogger.debug('DATA: ${response.data}', name: 'NetworkClient');
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
      AppLogger.debug('ERROR DATA: ${err.response?.data}',
          name: 'NetworkClient');
    }
    super.onError(err, handler);
  }
}
