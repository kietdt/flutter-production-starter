// Unit tests for GĐ 2.3 — Exception → Failure mapping.
//
// Guarantees the UI never receives a raw `e.toString()`: data-layer
// ServerExceptions are converted to UI-safe Failures with friendly messages.

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_production_starter/core/error/exceptions.dart';
import 'package:flutter_production_starter/core/error/failures.dart';
import 'package:flutter_production_starter/data/datasource/remote/auth_remote_datasource.dart';
import 'package:flutter_production_starter/data/model/auth_response_model.dart';
import 'package:flutter_production_starter/data/repository/auth_repository_impl.dart';

/// Datasource that always fails login with the supplied exception.
class _ThrowingDataSource implements AuthRemoteDataSource {
  final Object error;
  _ThrowingDataSource(this.error);

  @override
  Future<AuthResponseModel> login(String email, String password) async =>
      throw error;

  @override
  Future<AuthResponseModel> refresh(String refreshToken) =>
      throw UnimplementedError();

  @override
  Future<void> logout(String refreshToken) => throw UnimplementedError();
}

void main() {
  group('NetworkErrorCode', () {
    test('fromCode resolves known codes and defaults to unknown', () {
      expect(NetworkErrorCode.fromCode('timeout'), NetworkErrorCode.timeout);
      expect(NetworkErrorCode.fromCode('connection_error'),
          NetworkErrorCode.connectionError);
      expect(NetworkErrorCode.fromCode(null), NetworkErrorCode.unknown);
      expect(NetworkErrorCode.fromCode('garbage'), NetworkErrorCode.unknown);
    });

    test('message is friendly and free of technical detail', () {
      expect(NetworkErrorCode.connectionError.message,
          contains('No internet connection'));
      expect(NetworkErrorCode.timeout.message, contains('timed out'));
    });
  });

  group('ServerException.toFailure', () {
    test('derives a ServerFailure from the code, not the raw message', () {
      final exception = ServerException(
        message: '[401] super technical detail you should never see',
        code: NetworkErrorCode.connectionError.errorCode,
      );

      final failure = exception.toFailure();

      expect(failure, isA<ServerFailure>());
      expect(failure.code, NetworkErrorCode.connectionError.errorCode);
      expect(failure.message, NetworkErrorCode.connectionError.message);
      expect(failure.message, isNot(contains('[401]')));
    });
  });

  group('AuthRepositoryImpl.login error mapping', () {
    test('maps ServerException to ServerFailure', () async {
      final repo = AuthRepositoryImpl(
        remoteDataSource: _ThrowingDataSource(
          ServerException(
            message: '[500] internal',
            code: NetworkErrorCode.timeout.errorCode,
          ),
        ),
      );

      expect(
        () => repo.login('a@b.com', 'pw'),
        throwsA(
          isA<ServerFailure>().having(
            (f) => f.message,
            'message',
            NetworkErrorCode.timeout.message,
          ),
        ),
      );
    });

    test('maps any other error to UnknownFailure', () async {
      final repo = AuthRepositoryImpl(
        remoteDataSource: _ThrowingDataSource(Exception('boom')),
      );

      expect(repo.login('a@b.com', 'pw'), throwsA(isA<UnknownFailure>()));
    });
  });
}
