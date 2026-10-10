// Core Error Module
// Responsibility: Domain-level failure model + the ServerException → Failure
// mapping.
//
// Repositories catch data-layer errors and throw a `Failure`, so the domain and
// UI layers only ever branch on these types. Failures carry no user-facing
// text — widgets map them with `failure.message(context.l10n)`
// (core/localization/failure_message.dart).
//
// `Failure` is sealed so every `switch` over it is checked for exhaustiveness;
// that requires all subtypes in this library — a deliberate exception to the
// one-class-per-file rule. Business errors (OTP_EXPIRED, …) are NOT new
// subtypes: projects read them from `ServerFailure.serverCode`.

import 'package:flutter_production_starter/core/error/exceptions.dart';

/// Why a [NetworkFailure] happened.
enum NetworkFailureReason {
  timeout,
  noConnection,
}

sealed class Failure implements Exception {
  const Failure();
}

/// The request never got a usable answer (timeout, offline, TLS failure).
final class NetworkFailure extends Failure {
  final NetworkFailureReason reason;

  const NetworkFailure({required this.reason});

  @override
  String toString() => 'NetworkFailure(reason: ${reason.name})';
}

/// The server answered 401: wrong credentials on login, or a session the
/// refresh flow could not recover.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure();

  @override
  String toString() => 'UnauthorizedFailure()';
}

/// Any other error response (4xx/5xx).
final class ServerFailure extends Failure {
  final int? statusCode;
  final String? serverCode;
  final String? serverMessage;

  const ServerFailure({
    this.statusCode,
    this.serverCode,
    this.serverMessage,
  });

  @override
  String toString() => 'ServerFailure(statusCode: $statusCode, '
      'serverCode: $serverCode, serverMessage: $serverMessage)';
}

/// The request was cancelled on purpose (e.g. a `CancelToken` on dispose);
/// usually not worth showing.
final class CancelledFailure extends Failure {
  const CancelledFailure();

  @override
  String toString() => 'CancelledFailure()';
}

/// Anything unexpected (parse errors, bugs). Keeps the root [cause] and
/// [stackTrace] so crash reporting sees the real error.
final class UnknownFailure extends Failure {
  final Object? cause;
  final StackTrace? stackTrace;

  const UnknownFailure({
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() => 'UnknownFailure(cause: $cause)';
}

extension ServerExceptionMapper on ServerException {
  /// Maps this data-layer exception onto a [Failure]. [stackTrace] is kept on
  /// an [UnknownFailure] for crash reporting.
  Failure toFailure({StackTrace? stackTrace}) {
    switch (type) {
      case NetworkErrorCode.timeout:
        return const NetworkFailure(reason: NetworkFailureReason.timeout);
      case NetworkErrorCode.connectionError:
      case NetworkErrorCode.badCertificate:
        return const NetworkFailure(reason: NetworkFailureReason.noConnection);
      case NetworkErrorCode.badResponse:
        if (statusCode == 401) return const UnauthorizedFailure();
        return ServerFailure(
          statusCode: statusCode,
          serverCode: serverCode,
          serverMessage: serverMessage,
        );
      case NetworkErrorCode.cancelled:
        return const CancelledFailure();
      case NetworkErrorCode.unknown:
        return UnknownFailure(cause: cause ?? this, stackTrace: stackTrace);
    }
  }
}
