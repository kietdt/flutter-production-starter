// Unit tests for the error model (spec #13): DioException → ServerException
// (NetworkClient), ServerException → Failure (repository), Failure → localized
// text (FailureMessage). Failures carry no user-facing strings.

import 'package:dio/dio.dart';
import 'package:flutter_production_starter/core/config/app_config.dart';
import 'package:flutter_production_starter/core/error/exceptions.dart';
import 'package:flutter_production_starter/core/error/failures.dart';
import 'package:flutter_production_starter/core/localization/failure_message.dart';
import 'package:flutter_production_starter/core/localization/languages/en_language.dart';
import 'package:flutter_production_starter/core/localization/languages/vi_language.dart';
import 'package:flutter_production_starter/core/network/network_client.dart';
import 'package:flutter_production_starter/core/network/token_management.dart';
import 'package:flutter_production_starter/data/datasource/remote/auth_remote_datasource.dart';
import 'package:flutter_production_starter/data/model/auth_response_model.dart';
import 'package:flutter_production_starter/data/model/token_pair_model.dart';
import 'package:flutter_production_starter/data/repository/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/in_memory_auth_local_datasource.dart';
import '../../helpers/in_memory_token_storage.dart';

const _en = EnLanguage();

/// Datasource whose login always fails with [error].
class _ThrowingDataSource implements AuthRemoteDataSource {
  final Exception error;
  _ThrowingDataSource({required this.error});

  @override
  Future<AuthResponseModel> login(String email, String password) async =>
      throw error;

  @override
  Future<TokenPairModel> refresh(String refreshToken) =>
      throw UnimplementedError();

  @override
  Future<void> logout(String refreshToken) => throw UnimplementedError();
}

/// A NetworkClient whose every request is answered by [respond].
NetworkClient _client(
  Future<ResponseBody> Function(RequestOptions options) respond,
) {
  final NetworkClient client = NetworkClient(
    baseUrl: 'https://api.test',
    tokenManagement: TokenManagement(
      storage: InMemoryTokenStorage(),
      refresher: (_) => throw UnimplementedError(),
    ),
    onUnauthorized: () {},
  );
  client.dio.httpClientAdapter = FakeHttpAdapter(respond: respond);
  return client;
}

Future<ServerException> _caught(NetworkClient client) async {
  try {
    await client.get<Map<String, dynamic>>('/x', requiresAuth: false);
  } on ServerException catch (e) {
    return e;
  }
  fail('expected a ServerException');
}

void main() {
  group('NetworkClient maps DioException → ServerException', () {
    test('an error response keeps statusCode, serverCode and serverMessage',
        () async {
      final ServerException e = await _caught(_client(
        (_) async =>
            jsonResponse(422, {'code': 1042, 'message': 'Email taken'}),
      ));

      expect(e.type, NetworkErrorCode.badResponse);
      expect(e.statusCode, 422);
      expect(e.serverCode, '1042');
      expect(e.serverMessage, 'Email taken');
    });

    test('a 401 keeps its status code', () async {
      final ServerException e =
          await _caught(_client((_) async => jsonResponse(401, {})));

      expect(e.type, NetworkErrorCode.badResponse);
      expect(e.statusCode, 401);
    });

    test('maps each DioExceptionType onto its own NetworkErrorCode', () async {
      final Map<NetworkErrorCode, DioException Function(RequestOptions)> cases =
          {
        NetworkErrorCode.timeout: (o) => DioException.connectionTimeout(
            timeout: Duration.zero, requestOptions: o),
        NetworkErrorCode.connectionError: (o) =>
            DioException.connectionError(requestOptions: o, reason: 'offline'),
        NetworkErrorCode.badCertificate: (o) =>
            DioException.badCertificate(requestOptions: o),
        NetworkErrorCode.cancelled: (o) =>
            DioException.requestCancelled(requestOptions: o, reason: 'bye'),
      };

      for (final MapEntry<NetworkErrorCode,
          DioException Function(RequestOptions)> entry in cases.entries) {
        final ServerException e = await _caught(
          _client((o) async => throw entry.value(o)),
        );
        expect(e.type, entry.key, reason: '$entry');
        expect(e.cause, isA<DioException>());
      }
    });

    test('every timeout type, incl. transformTimeout, maps to timeout',
        () async {
      for (final DioExceptionType type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.transformTimeout,
      ]) {
        final ServerException e = await _caught(
          _client(
              (o) async => throw DioException(requestOptions: o, type: type)),
        );
        expect(e.type, NetworkErrorCode.timeout, reason: '$type');
      }
    });
  });

  group('ServerException.toFailure', () {
    test('timeout → NetworkFailure(timeout)', () {
      expect(
        const ServerException(type: NetworkErrorCode.timeout).toFailure(),
        isA<NetworkFailure>()
            .having((f) => f.reason, 'reason', NetworkFailureReason.timeout),
      );
    });

    test('connectionError and badCertificate → NetworkFailure(noConnection)',
        () {
      for (final NetworkErrorCode type in [
        NetworkErrorCode.connectionError,
        NetworkErrorCode.badCertificate,
      ]) {
        expect(
          ServerException(type: type).toFailure(),
          isA<NetworkFailure>().having(
              (f) => f.reason, 'reason', NetworkFailureReason.noConnection),
        );
      }
    });

    test('badResponse 401 → UnauthorizedFailure', () {
      expect(
        const ServerException(
          type: NetworkErrorCode.badResponse,
          statusCode: 401,
        ).toFailure(),
        isA<UnauthorizedFailure>(),
      );
    });

    test('other badResponse → ServerFailure with the server details', () {
      expect(
        const ServerException(
          type: NetworkErrorCode.badResponse,
          statusCode: 500,
          serverCode: 'DB_DOWN',
          serverMessage: 'Database unavailable',
        ).toFailure(),
        isA<ServerFailure>()
            .having((f) => f.statusCode, 'statusCode', 500)
            .having((f) => f.serverCode, 'serverCode', 'DB_DOWN')
            .having((f) => f.serverMessage, 'serverMessage',
                'Database unavailable'),
      );
    });

    test('cancelled → CancelledFailure', () {
      expect(
        const ServerException(type: NetworkErrorCode.cancelled).toFailure(),
        isA<CancelledFailure>(),
      );
    });

    test('unknown → UnknownFailure keeping the cause and stack trace', () {
      final StackTrace stackTrace = StackTrace.current;
      final FormatException cause = const FormatException('bad json');

      expect(
        ServerException(type: NetworkErrorCode.unknown, cause: cause)
            .toFailure(stackTrace: stackTrace),
        isA<UnknownFailure>()
            .having((f) => f.cause, 'cause', same(cause))
            .having((f) => f.stackTrace, 'stackTrace', same(stackTrace)),
      );
    });
  });

  group('AuthRepositoryImpl.login error mapping', () {
    test('maps a ServerException to its Failure', () async {
      final AuthRepositoryImpl repo = AuthRepositoryImpl(
        remoteDataSource: _ThrowingDataSource(
          error: const ServerException(type: NetworkErrorCode.timeout),
        ),
        localDataSource: InMemoryAuthLocalDataSource(),
      );

      await expectLater(
        repo.login('a@b.com', 'pw'),
        throwsA(isA<NetworkFailure>()
            .having((f) => f.reason, 'reason', NetworkFailureReason.timeout)),
      );
    });

    test('maps any other error to an UnknownFailure that keeps the cause',
        () async {
      final Exception boom = Exception('boom');
      final AuthRepositoryImpl repo = AuthRepositoryImpl(
        remoteDataSource: _ThrowingDataSource(error: boom),
        localDataSource: InMemoryAuthLocalDataSource(),
      );

      await expectLater(
        repo.login('a@b.com', 'pw'),
        throwsA(isA<UnknownFailure>()
            .having((f) => f.cause, 'cause', same(boom))
            .having((f) => f.stackTrace, 'stackTrace', isNotNull)),
      );
    });
  });

  group('FailureMessage', () {
    tearDown(() => AppConfig.init(AppConfig.fromFlavor(Flavor.dev)));

    test('maps every failure to a localized string', () {
      expect(
        const NetworkFailure(reason: NetworkFailureReason.timeout).message(_en),
        _en.errorTimeout,
      );
      expect(
        const NetworkFailure(reason: NetworkFailureReason.noConnection)
            .message(_en),
        _en.errorNoConnection,
      );
      expect(const UnauthorizedFailure().message(_en), _en.errorUnauthorized);
      expect(
          const ServerFailure(statusCode: 500).message(_en), _en.errorServer);
      expect(const CancelledFailure().message(_en), _en.errorCancelled);
      expect(const UnknownFailure().message(_en), _en.errorUnknown);
    });

    test('follows the language it is given', () {
      const ViLanguage vi = ViLanguage();
      expect(
        const NetworkFailure(reason: NetworkFailureReason.noConnection)
            .message(vi),
        vi.errorNoConnection,
      );
    });

    test('hides the server message unless useServerErrorMessage is on', () {
      const ServerFailure failure =
          ServerFailure(statusCode: 409, serverMessage: 'Tài khoản đã tồn tại');

      expect(failure.message(_en), _en.errorServer);

      AppConfig.init(const AppConfig(
        flavor: Flavor.dev,
        baseUrl: 'https://api.test',
        appName: 'Test',
        useServerErrorMessage: true,
      ));
      expect(failure.message(_en), 'Tài khoản đã tồn tại');
      expect(
          const ServerFailure(serverMessage: '').message(_en), _en.errorServer);
    });
  });
}
