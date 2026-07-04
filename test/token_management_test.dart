// Unit tests for TokenManagement (GĐ 3.1) — the concurrency-safe token refresh.
//
// The key technical highlight of this starter: while a refresh is in flight,
// every concurrent `getToken()` caller queues on a single `Completer` instead of
// firing its own refresh. When the refresh finishes, all queued callers resolve
// with the freshly-saved access token. These tests exercise that queue directly.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_production_starter/core/di/di.dart';
import 'package:flutter_production_starter/core/local_storage/shared_prefs_manager.dart';
import 'package:flutter_production_starter/core/network/network_client.dart';
import 'package:flutter_production_starter/core/network/token_management.dart';

class _MockNetworkClient extends Mock implements NetworkClient {}

const _accessKey = 'access_token';
const _refreshKey = 'refresh_token';

void main() {
  late _MockNetworkClient network;
  final tokens = TokenManagement.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefsManager.instance.init();

    network = _MockNetworkClient();
    // TokenManagement.refreshToken resolves the client through the service
    // locator, so register the mock there.
    sl.registerLazySingleton<NetworkClient>(() => network);
  });

  tearDown(() async {
    await tokens.clearTokens();
    await sl.reset();
  });

  group('refresh completer queue', () {
    test('getToken() returns the persisted token when no refresh is running',
        () async {
      await tokens.saveTokens(accessToken: 'stored', refreshToken: 'r');

      expect(await tokens.getToken(), 'stored');
      expect(tokens.isRefreshing, isFalse);
    });

    test(
        'concurrent getToken() callers all resolve to the freshly refreshed token '
        'while the network is hit only once', () async {
      await SharedPrefsManager.instance.setString(_refreshKey, 'old-refresh');

      // Hold the network response open so we can pile up waiters mid-refresh.
      final serverResponse = Completer<Map<String, dynamic>>();
      when(() => network.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            requiresAuth: any(named: 'requiresAuth'),
          )).thenAnswer((_) => serverResponse.future);

      // Kick off the refresh but do NOT await it yet.
      final refreshFuture = tokens.refreshToken();
      expect(tokens.isRefreshing, isTrue);

      // Three requests arrive while the refresh is in flight -> they queue.
      final queued = Future.wait([
        tokens.getToken(),
        tokens.getToken(),
        tokens.getToken(),
      ]);

      // The server finally answers with rotated tokens.
      serverResponse.complete({
        'accessToken': 'new-access',
        'refreshToken': 'new-refresh',
      });

      expect(await refreshFuture, 'new-access');
      expect(await queued, ['new-access', 'new-access', 'new-access']);

      // Exactly one network round-trip served every queued caller.
      verify(() => network.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: {'refreshToken': 'old-refresh'},
            requiresAuth: false,
          )).called(1);

      // New tokens were persisted before the queue was released.
      expect(tokens.getAccessTokenSync(), 'new-access');
      expect(tokens.getRefreshTokenSync(), 'new-refresh');
      expect(tokens.isRefreshing, isFalse);
    });

    test('getToken(force: true) bypasses the queue and reads storage directly',
        () async {
      await SharedPrefsManager.instance
          .setString(_accessKey, 'stale-but-stored');
      await SharedPrefsManager.instance.setString(_refreshKey, 'r');

      final serverResponse = Completer<Map<String, dynamic>>();
      when(() => network.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            requiresAuth: any(named: 'requiresAuth'),
          )).thenAnswer((_) => serverResponse.future);

      final refreshFuture = tokens.refreshToken();
      expect(tokens.isRefreshing, isTrue);

      // Forced read does not wait on the completer.
      expect(await tokens.getToken(force: true), 'stale-but-stored');

      serverResponse.complete({
        'accessToken': 'new-access',
        'refreshToken': 'new-refresh',
      });
      await refreshFuture;
    });
  });

  group('refresh failure paths', () {
    test('returns null immediately when there is no stored refresh token',
        () async {
      final result = await tokens.refreshToken();

      expect(result, isNull);
      expect(tokens.isRefreshing, isFalse);
      verifyNever(() => network.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            requiresAuth: any(named: 'requiresAuth'),
          ));
    });

    test(
        'a network failure aborts pending callers (they resolve null) and rethrows',
        () async {
      await SharedPrefsManager.instance.setString(_refreshKey, 'old-refresh');

      final serverResponse = Completer<Map<String, dynamic>>();
      when(() => network.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            requiresAuth: any(named: 'requiresAuth'),
          )).thenAnswer((_) => serverResponse.future);

      final refreshFuture = tokens.refreshToken();
      final queued = tokens.getToken();

      serverResponse.completeError(Exception('refresh endpoint down'));

      // The refresh call surfaces the error to its caller...
      await expectLater(refreshFuture, throwsA(isA<Exception>()));
      // ...but queued waiters are released with null rather than hanging forever.
      expect(await queued, isNull);
      expect(tokens.isRefreshing, isFalse);
    });
  });
}
