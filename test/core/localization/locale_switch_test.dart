// Regression test for spec #3 — switching the language must update text that
// is already on screen, including widgets under the const AuthGate subtree.

import 'package:flutter/material.dart';
import 'package:flutter_production_starter/app/di/di.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/session_prefs.dart';

String? _appBarTitle(WidgetTester tester) {
  final title = tester.widget<AppBar>(find.byType(AppBar)).title;
  return (title as Text?)?.data;
}

void main() {
  tearDown(() => sl.reset());

  testWidgets('toggling EN -> VI re-renders the visible LoginPage',
      (tester) async {
    await pumpApp(tester, prefs: {});
    expect(_appBarTitle(tester), 'Login');

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    expect(_appBarTitle(tester), 'Đăng nhập');
    expect(find.text('Mật khẩu'), findsOneWidget);
  });

  testWidgets('a field error already shown switches language too',
      (tester) async {
    await pumpApp(tester, prefs: {});
    await tester.enterText(find.byType(TextField).first, 'not-an-email');
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address'), findsNothing);
    expect(find.text('Email không hợp lệ'), findsOneWidget);
  });

  testWidgets('toggling the language re-renders the visible HomePage',
      (tester) async {
    await pumpApp(tester, prefs: signedInPrefs);
    expect(_appBarTitle(tester), 'Home');

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    expect(_appBarTitle(tester), 'Trang chủ');
  });
}
