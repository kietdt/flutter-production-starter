// Regression tests for AuthInterceptor's 401 handling.
//
// #1 — Requests flagged `requiresAuth: false` (login, refresh, logout) must
// never enter the refresh flow. Otherwise a 401 from `/auth/refresh` itself
// waits on the very refresh it belongs to and the request hangs forever.
//
// #2 — Concurrent 401s must share ONE refresh round-trip. With refresh-token
// rotation a second refresh call would present an already-rotated token, fail,
// and log the user out for no reason.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_production_starter/core/error/exceptions.dart';
import 'package:flutter_production_starter/core/network/network_client.dart';
import 'package:flutter_production_starter/core/network/token_management.dart';
import 'package:flutter_production_starter/data/datasource/remote/auth_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/in_memory_token_storage.dart';

const _refreshPath = '/auth/refresh';

/// Fails fast instead of hanging the test runner when a deadlock regresses.
const _hangTimeout = Duration(seconds: 2);

/// The original request's 401, surfaced with its status code (#13).
final _unauthorized = isA<ServerException>()
    .having((e) => e.type, 'type', NetworkErrorCode.badResponse)
    .having((e) => e.statusCode, 'statusCode', 401);

void main() {
  late NetworkClient client;
  late InMemoryTokenStorage storage;
  late TokenManagement tokens;
  late int unauthorizedCalls;

  /// Wires the real graph by hand, as `initDI()` does: seeded storage →
  /// TokenManagement (refreshing through the real AuthRemoteDataSource) →
  /// NetworkClient with real interceptors, backed by [adapter].
  Future<void> setUpClient(FakeHttpAdapter adapter) async {
    storage = InMemoryTokenStorage(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
    );
    unauthorizedCalls = 0;
    tokens = TokenManagement(
      storage: storage,
      refresher: (refreshToken) async =>
          (await AuthRemoteDataSourceImpl(networkClient: client)
                  .refresh(refreshToken))
              .toEntity(),
    );
    client = NetworkClient(
      baseUrl: 'https://api.test',
      tokenManagement: tokens,
      onUnauthorized: () => unauthorizedCalls++,
    );
    client.dio.httpClientAdapter = adapter;
  }

  /// Holds each protected 401 until [count] of them have arrived, so their
  /// error handlers run interleaved — the window the #2 race lives in.
  Future<ResponseBody> Function() released401s({required int count}) {
    var arrived = 0;
    final allArrived = Completer<void>();
    return () async {
      if (++arrived == count) allArrived.complete();
      await allArrived.future;
      return jsonResponse(401, {'message': 'token expired'});
    };
  }

  group('requiresAuth:false requests (#1)', () {
    late FakeHttpAdapter adapter;

    setUp(() async {
      adapter = FakeHttpAdapter(
        respond: (_) async => jsonResponse(401, {'message': 'unauthorized'}),
      );
      await setUpClient(adapter);
    });

    test(
        'a 401 from /auth/refresh fails the original request instead of '
        'hanging, clears the session and notifies onUnauthorized once',
        () async {
      await expectLater(
        client.get<dynamic>('/me').timeout(_hangTimeout),
        throwsA(_unauthorized),
      );

      expect(adapter.paths, ['/me', _refreshPath]);
      expect(unauthorizedCalls, 1);
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(tokens.isRefreshing, isFalse);
    });

    test(
        'a 401 on a requiresAuth:false request (wrong password on login) is '
        'returned as-is without attempting a refresh', () async {
      await expectLater(
        client
            .post<dynamic>(
              '/auth/login',
              data: {'email': 'a@b.co', 'password': 'wrong-password'},
              requiresAuth: false,
            )
            .timeout(_hangTimeout),
        throwsA(_unauthorized),
      );

      expect(adapter.paths, ['/auth/login']);
      expect(unauthorizedCalls, 0);
      expect(storage.refreshToken, 'old-refresh');
    });
  });

  group('refresh response (#12)', () {
    test(
        'a refresh response without an access token ends the session instead '
        'of retrying with an empty token', () async {
      final adapter = FakeHttpAdapter(
        respond: (options) async {
          if (options.path == _refreshPath) {
            return jsonResponse(200, {'refreshToken': 'new-refresh'});
          }
          return jsonResponse(401, {'message': 'token expired'});
        },
      );
      await setUpClient(adapter);

      await expectLater(
        client.get<dynamic>('/me').timeout(_hangTimeout),
        throwsA(_unauthorized),
      );

      expect(adapter.paths, ['/me', _refreshPath]);
      expect(unauthorizedCalls, 1);
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(tokens.isRefreshing, isFalse);
    });
  });

  group('concurrent 401s (#2)', () {
    test('share a single refresh round-trip and all retry with the new token',
        () async {
      final expired401 = released401s(count: 3);
      final adapter = FakeHttpAdapter(
        respond: (options) async {
          if (options.path == _refreshPath) {
            return jsonResponse(200, {
              'accessToken': 'new-access',
              'refreshToken': 'new-refresh',
            });
          }
          if (options.headers['Authorization'] == 'Bearer new-access') {
            return jsonResponse(200, {'path': options.path});
          }
          return expired401();
        },
      );
      await setUpClient(adapter);

      final results = await Future.wait([
        client.get<Map<String, dynamic>>('/a'),
        client.get<Map<String, dynamic>>('/b'),
        client.get<Map<String, dynamic>>('/c'),
      ]).timeout(_hangTimeout);

      expect(results.map((r) => r['path']), ['/a', '/b', '/c']);
      expect(adapter.callsTo(_refreshPath), 1);
      expect(unauthorizedCalls, 0);
      expect(storage.accessToken, 'new-access');
      expect(storage.refreshToken, 'new-refresh');
      expect(tokens.isRefreshing, isFalse);
    });

    test('a failed shared refresh fails every request but logs out only once',
        () async {
      final expired401 = released401s(count: 3);
      final adapter = FakeHttpAdapter(
        respond: (options) async {
          if (options.path == _refreshPath) {
            return jsonResponse(401, {'message': 'refresh token expired'});
          }
          return expired401();
        },
      );
      await setUpClient(adapter);

      final outcomes = await Future.wait([
        for (final path in ['/a', '/b', '/c'])
          client
              .get<dynamic>(path)
              .then<Object?>((_) => 'ok', onError: (Object e) => e),
      ]).timeout(_hangTimeout);

      expect(outcomes, everyElement(_unauthorized));
      expect(adapter.callsTo(_refreshPath), 1);
      expect(unauthorizedCalls, 1);
      expect(storage.accessToken, isNull);
      expect(tokens.isRefreshing, isFalse);
    });

    test(
        'a 401 for a token another request already rotated retries with the '
        'stored token without refreshing again', () async {
      final adapter = FakeHttpAdapter(
        respond: (options) async {
          if (options.headers['Authorization'] == 'Bearer new-access') {
            return jsonResponse(200, {'path': options.path});
          }
          // Another request rotated the tokens while this one was in flight.
          await storage.saveTokens(
            accessToken: 'new-access',
            refreshToken: 'new-refresh',
          );
          return jsonResponse(401, {'message': 'token expired'});
        },
      );
      await setUpClient(adapter);

      final result =
          await client.get<Map<String, dynamic>>('/a').timeout(_hangTimeout);

      expect(result['path'], '/a');
      expect(adapter.paths, ['/a', '/a']);
      expect(unauthorizedCalls, 0);
    });
  });
}
