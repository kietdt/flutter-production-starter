/// Core Error Module
/// Responsibility: Define data-level exceptions.
///
/// These are thrown by datasources and caught by repositories to be converted into Failures.

class ServerException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? error;

  ServerException({
    this.message = 'Server Exception',
    this.code,
    this.error,
  });
}

enum NetworkErrorCode {
  timeout,
  badResponse,
  cancelled,
  connectionError,
  unknown,
  unexpectedError;

  String get errorCode {
    switch (this) {
      case NetworkErrorCode.timeout:
        return 'timeout';
      case NetworkErrorCode.badResponse:
        return 'bad_response';
      case NetworkErrorCode.cancelled:
        return 'cancelled';
      case NetworkErrorCode.connectionError:
        return 'connection_error';
      case NetworkErrorCode.unknown:
        return 'unknown';
      case NetworkErrorCode.unexpectedError:
        return 'unexpected_error';
    }
  }
}
