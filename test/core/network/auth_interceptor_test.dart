// Regression tests for AuthInterceptor's 401 handling (spec #1).
//
// Requests flagged `requiresAuth: false` (login, refresh, logout) must never
// enter the refresh flow. Otherwise a 401 from `/auth/refresh` itself waits on
// the very refresh it belongs to and the request hangs forever.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_production_starter/core/di/di.dart';
import 'package:flutter_production_starter/core/error/exceptions.dart';
import 'package:flutter_production_starter/core/local_storage/shared_prefs_manager.dart';
import 'package:flutter_production_starter/core/network/network_client.dart';
import 'package:flutter_production_starter/core/network/token_management.dart';

const _accessKey = 'access_token';
const _refreshKey = 'refresh_token';

/// Fails fast instead of hanging the test runner when the deadlock regresses.
const _hangTimeout = Duration(seconds: 2);

/// Answers every request with 401 and records the paths it was asked for.
class _Always401Adapter implements HttpClientAdapter {
  final List<String> paths = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    return ResponseBody.fromString(
      jsonEncode({'message': 'unauthorized'}),
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Always401Adapter adapter;
  late NetworkClient client;
  late int unauthorizedCalls;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      _accessKey: 'expired-access',
      _refreshKey: 'expired-refresh',
    });
    await SharedPrefsManager.instance.init();

    unauthorizedCalls = 0;
    adapter = _Always401Adapter();
    client = NetworkClient(
      baseUrl: 'https://api.test',
      onUnauthorized: () => unauthorizedCalls++,
    );
    client.dio.httpClientAdapter = adapter;

    // TokenManagement.refreshToken resolves the client through the service
    // locator, so register this instance there.
    sl.registerSingleton<NetworkClient>(client);
  });

  tearDown(() async {
    await TokenManagement.instance.clearTokens();
    await sl.reset();
  });

  test(
      'a 401 from /auth/refresh fails the original request instead of hanging, '
      'clears the session and notifies onUnauthorized once', () async {
    await expectLater(
      client.get<dynamic>('/me').timeout(_hangTimeout),
      throwsA(isA<ServerException>()),
    );

    expect(adapter.paths, ['/me', '/auth/refresh']);
    expect(unauthorizedCalls, 1);
    expect(TokenManagement.instance.getAccessTokenSync(), isNull);
    expect(TokenManagement.instance.getRefreshTokenSync(), isNull);
    expect(TokenManagement.instance.isRefreshing, isFalse);
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
      throwsA(isA<ServerException>()),
    );

    expect(adapter.paths, ['/auth/login']);
    expect(unauthorizedCalls, 0);
    expect(TokenManagement.instance.getRefreshTokenSync(), 'expired-refresh');
  });
}
