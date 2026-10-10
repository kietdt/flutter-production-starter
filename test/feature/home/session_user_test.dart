// Regression tests for spec #14 — the signed-in user is global app state.
//
// Runs the whole app with only the HTTP adapter faked: logging in must put the
// user into AppAuthCubit (Home greets them), reopening the app must restore
// that user from storage without the network, and logging out must forget it.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_production_starter/app/di/di.dart';
import 'package:flutter_production_starter/core/error/exceptions.dart';
import 'package:flutter_production_starter/core/network/network_client.dart';
import 'package:flutter_production_starter/data/datasource/local/auth_local_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/session_prefs.dart';

/// Login succeeds with a user; every other request fails as offline.
FakeHttpAdapter _backend() => FakeHttpAdapter(
      respond: (options) async {
        if (options.path == '/auth/login') {
          return jsonResponse(200, {
            'accessToken': 'access',
            'refreshToken': 'refresh',
            'user': {
              'id': '7',
              'email': 'kiet@example.com',
              'userName': 'Kiet',
            },
          });
        }
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'offline',
        );
      },
    );

Future<void> _login(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).at(0), 'kiet@example.com');
  await tester.enterText(find.byType(TextField).at(1), 'password123');
  await tester.pump();
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => sl.reset());

  testWidgets('Home greets the user who just logged in', (tester) async {
    await pumpApp(tester, prefs: {}, httpAdapter: _backend());
    await _login(tester);

    expect(find.text('Hello, Kiet'), findsOneWidget);
  });

  testWidgets('reopening the app restores the user without the network',
      (tester) async {
    await pumpApp(tester, prefs: {}, httpAdapter: _backend());
    await _login(tester);

    final FakeHttpAdapter adapter = _backend();
    await pumpApp(tester, httpAdapter: adapter); // restart: keeps storage

    expect(find.text('Hello, Kiet'), findsOneWidget);
    expect(adapter.paths, isEmpty);
  });

  testWidgets('logging out forgets the user, also after a restart',
      (tester) async {
    await pumpApp(tester, prefs: {}, httpAdapter: _backend());
    await _login(tester);

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsWidgets);

    await pumpApp(tester, httpAdapter: _backend());
    expect(find.text('Hello, Kiet'), findsNothing);
    expect(find.text('Login'), findsWidgets);
  });

  testWidgets('a failed token refresh logs out and forgets the user',
      (tester) async {
    await pumpApp(
      tester,
      prefs: signedInPrefs,
      httpAdapter: FakeHttpAdapter(respond: (_) async => jsonResponse(401, {})),
    );
    expect(find.text('Hello, Tester'), findsOneWidget);

    // Any protected call: 401 → refresh → 401 → onUnauthorized → logout.
    // Not awaited directly: under the fake clock only pumping drives Dio.
    Object? error;
    unawaited(sl<NetworkClient>()
        .get<dynamic>('/me')
        .then<void>((_) {}, onError: (Object e) => error = e));
    await tester.pumpAndSettle();

    expect(error, isA<ServerException>());
    expect(find.text('Email'), findsOneWidget);
    expect(sl<AuthLocalDataSource>().cachedUser, isNull);
  });
}
