// Regression tests for spec #13 — login errors shown to the user.
//
// Runs the real stack (NetworkClient → AuthRemoteDataSource → AuthRepository →
// LoginCubit → LoginPage); only the HTTP adapter is faked.
// - A network error must be shown in the active language (it used to be a
//   hard-coded English string carried by the Failure).
// - A 401 from /auth/login means wrong credentials (it used to fall through to
//   "An unexpected error occurred").

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_production_starter/app/di/di.dart';
import 'package:flutter_production_starter/core/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/pump_app.dart';

Future<void> _bootAndSubmit(
  WidgetTester tester, {
  required String locale,
  required Future<ResponseBody> Function(RequestOptions options) respond,
}) async {
  await pumpApp(
    tester,
    prefs: {StorageKeys.locale: locale},
    httpAdapter: FakeHttpAdapter(respond: respond),
  );

  await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
  await tester.enterText(find.byType(TextField).at(1), 'password123');
  await tester.pump();
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => sl.reset());

  testWidgets('a network error is shown in Vietnamese when the app is in VI',
      (tester) async {
    await _bootAndSubmit(
      tester,
      locale: 'vi',
      respond: (options) async => throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      ),
    );

    expect(
      find.widgetWithText(
        SnackBar,
        'Không có kết nối mạng. Vui lòng kiểm tra mạng và thử lại.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a 401 from /auth/login says the credentials are wrong',
      (tester) async {
    await _bootAndSubmit(
      tester,
      locale: 'en',
      respond: (_) async =>
          jsonResponse(401, {'message': 'Invalid credentials'}),
    );

    expect(
      find.widgetWithText(SnackBar, 'Incorrect email or password.'),
      findsOneWidget,
    );
  });
}
