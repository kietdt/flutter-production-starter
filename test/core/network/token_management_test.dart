// Unit tests for TokenManagement — the concurrency-safe token refresh.
//
// While a refresh is in flight, every concurrent `getToken()` / `refreshToken()`
// caller queues on a single `Completer` instead of firing its own refresh.
// Dependencies are injected (#11): an in-memory TokenStorage and a fake
// refresher, so no SharedPreferences or service locator is involved.

import 'dart:async';

import 'package:flutter_production_starter/core/network/token_management.dart';
import 'package:flutter_production_starter/core/network/token_pair.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/in_memory_token_storage.dart';

/// A refresher whose response the test releases by hand.
class _FakeRefresher {
  final List<String> calls = [];
  Completer<TokenPair> response = Completer<TokenPair>();

  Future<TokenPair> call(String refreshToken) {
    calls.add(refreshToken);
    return response.future;
  }
}

const _rotated =
    TokenPair(accessToken: 'new-access', refreshToken: 'new-refresh');

void main() {
  late InMemoryTokenStorage storage;
  late _FakeRefresher refresher;
  late TokenManagement tokens;

  setUp(() {
    storage = InMemoryTokenStorage();
    refresher = _FakeRefresher();
    tokens = TokenManagement(storage: storage, refresher: refresher.call);
  });

  group('refresh completer queue', () {
    test('getToken() returns the stored token when no refresh is running',
        () async {
      storage.accessToken = 'stored';

      expect(await tokens.getToken(), 'stored');
      expect(tokens.isRefreshing, isFalse);
    });

    test(
        'concurrent getToken() callers all resolve to the freshly refreshed '
        'token while the refresher is called only once', () async {
      storage.refreshToken = 'old-refresh';

      // Kick off the refresh but do NOT await it yet.
      final refreshFuture = tokens.refreshToken();
      expect(tokens.isRefreshing, isTrue);

      // Three requests arrive while the refresh is in flight -> they queue.
      final queued = Future.wait([
        tokens.getToken(),
        tokens.getToken(),
        tokens.getToken(),
      ]);

      refresher.response.complete(_rotated);

      expect(await refreshFuture, 'new-access');
      expect(await queued, ['new-access', 'new-access', 'new-access']);
      expect(refresher.calls, ['old-refresh']);

      // New tokens were persisted before the queue was released.
      expect(storage.accessToken, 'new-access');
      expect(storage.refreshToken, 'new-refresh');
      expect(tokens.isRefreshing, isFalse);
    });

    test(
        'concurrent refreshToken() callers join the in-flight refresh instead '
        'of each calling the refresher', () async {
      storage.refreshToken = 'old-refresh';

      final refreshes = Future.wait([
        tokens.refreshToken(),
        tokens.refreshToken(),
        tokens.refreshToken(),
      ]);
      refresher.response.complete(_rotated);

      expect(await refreshes, ['new-access', 'new-access', 'new-access']);
      expect(refresher.calls, ['old-refresh']);
      expect(tokens.isRefreshing, isFalse);
    });

    test('getToken(force: true) bypasses the queue and reads storage directly',
        () async {
      storage
        ..accessToken = 'stale-but-stored'
        ..refreshToken = 'r';

      final refreshFuture = tokens.refreshToken();
      expect(tokens.isRefreshing, isTrue);

      // Forced read does not wait on the completer.
      expect(await tokens.getToken(force: true), 'stale-but-stored');

      refresher.response.complete(_rotated);
      await refreshFuture;
    });
  });

  group('refresh response handling (#12)', () {
    test('keeps the current refresh token when the server does not rotate it',
        () async {
      storage.refreshToken = 'old-refresh';
      refresher.response.complete(
          const TokenPair(accessToken: 'new-access', refreshToken: ''));

      expect(await tokens.refreshToken(), 'new-access');
      expect(storage.accessToken, 'new-access');
      expect(storage.refreshToken, 'old-refresh');
    });

    test('a response without an access token is a failure and saves nothing',
        () async {
      storage
        ..accessToken = 'old-access'
        ..refreshToken = 'old-refresh';
      refresher.response
          .complete(const TokenPair(accessToken: '', refreshToken: 'r2'));

      await expectLater(tokens.refreshToken(), throwsA(isA<StateError>()));
      expect(storage.accessToken, 'old-access');
      expect(storage.refreshToken, 'old-refresh');
      expect(tokens.isRefreshing, isFalse);
    });
  });

  group('refresh failure paths', () {
    test('returns null immediately when there is no stored refresh token',
        () async {
      final result = await tokens.refreshToken();

      expect(result, isNull);
      expect(tokens.isRefreshing, isFalse);
      expect(refresher.calls, isEmpty);
    });

    test(
        'a refresher failure aborts pending callers (they resolve null) and '
        'rethrows', () async {
      storage.refreshToken = 'old-refresh';

      final refreshFuture = tokens.refreshToken();
      final queued = tokens.getToken();

      refresher.response.completeError(Exception('refresh endpoint down'));

      // The refresh call surfaces the error to its caller...
      await expectLater(refreshFuture, throwsA(isA<Exception>()));
      // ...but queued waiters are released with null rather than hanging.
      expect(await queued, isNull);
      expect(tokens.isRefreshing, isFalse);
    });

    test('clearTokens() wipes both tokens from storage', () async {
      storage
        ..accessToken = 'a'
        ..refreshToken = 'r';

      await tokens.clearTokens();

      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
    });
  });
}
