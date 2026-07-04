// Core Error Module
// Responsibility: Define data-level exceptions.
//
// These are thrown by datasources and caught by repositories to be converted into Failures.

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

  /// User-friendly message shown in the UI. Never exposes status codes,
  /// stack traces or other technical detail.
  String get message {
    switch (this) {
      case NetworkErrorCode.timeout:
        return 'The connection timed out. Please try again.';
      case NetworkErrorCode.badResponse:
        return 'Something went wrong. Please try again.';
      case NetworkErrorCode.cancelled:
        return 'The request was cancelled.';
      case NetworkErrorCode.connectionError:
        return 'No internet connection. Please check your network and try again.';
      case NetworkErrorCode.unknown:
      case NetworkErrorCode.unexpectedError:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Resolves the stored [errorCode] string back to a [NetworkErrorCode],
  /// defaulting to [unknown] for null/unrecognized values.
  static NetworkErrorCode fromCode(String? code) {
    switch (code) {
      case 'timeout':
        return NetworkErrorCode.timeout;
      case 'bad_response':
        return NetworkErrorCode.badResponse;
      case 'cancelled':
        return NetworkErrorCode.cancelled;
      case 'connection_error':
        return NetworkErrorCode.connectionError;
      case 'unexpected_error':
        return NetworkErrorCode.unexpectedError;
      case 'unknown':
      default:
        return NetworkErrorCode.unknown;
    }
  }
}
