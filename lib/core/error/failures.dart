// Core Error Module
// Responsibility: Define domain-level failure models + map data-layer
// exceptions onto them.
//
// Repositories catch `ServerException` (data layer) and throw a `Failure`, so
// the domain/UI layers only ever deal with friendly, technical-detail-free
// messages — never a raw `e.toString()`.

import 'exceptions.dart';

abstract class Failure {
  /// User-friendly message safe to show in the UI.
  final String message;

  /// Optional machine code (e.g. `NetworkErrorCode.errorCode`) for branching.
  final String? code;

  const Failure({
    required this.message,
    this.code,
  });
}

/// A failure originating from the server / network layer.
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
  });
}

/// Fallback for anything not modeled as a [ServerFailure].
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred. Please try again.',
  });
}

extension ServerExceptionMapper on ServerException {
  /// Converts a data-layer [ServerException] into a UI-safe [ServerFailure],
  /// deriving the message from the error code (drops status-code prefixes,
  /// stack traces, etc.).
  ServerFailure toFailure() {
    final errorCode = NetworkErrorCode.fromCode(code);
    return ServerFailure(message: errorCode.message, code: errorCode.errorCode);
  }
}
