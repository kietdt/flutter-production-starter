// Core Error Module
// Responsibility: Define data-level exceptions.
//
// Thrown by NetworkClient/datasources and caught by repositories, which map
// them to a `Failure` (see failures.dart). Holds no user-facing text: the UI
// maps failures to strings through `context.l10n`.

/// What went wrong at the transport level. One value per `DioExceptionType`
/// family, so `NetworkClient._mapException` stays an exhaustive switch.
enum NetworkErrorCode {
  timeout,
  connectionError,
  badCertificate,
  badResponse,
  cancelled,
  unknown,
}

class ServerException implements Exception {
  final NetworkErrorCode type;

  /// HTTP status code; only set for [NetworkErrorCode.badResponse].
  final int? statusCode;

  /// Business error code from the error body (e.g. `'OTP_EXPIRED'`).
  final String? serverCode;

  /// Message from the error body. Logged; shown to users only when
  /// `AppConfig.useServerErrorMessage` is on.
  final String? serverMessage;

  /// The original error, kept for logging / crash reporting.
  final Object? cause;

  const ServerException({
    required this.type,
    this.statusCode,
    this.serverCode,
    this.serverMessage,
    this.cause,
  });

  @override
  String toString() => 'ServerException(type: ${type.name}, '
      'statusCode: $statusCode, serverCode: $serverCode, '
      'serverMessage: $serverMessage, cause: $cause)';
}
