// Regression test for spec #3 — switching the language must update text that
// is already on screen, including widgets under the const AuthGate subtree.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_production_starter/core/di/di.dart';
import 'package:flutter_production_starter/main.dart';

Future<void> _boot(WidgetTester tester, Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  await initDI();
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();
}

String? _appBarTitle(WidgetTester tester) {
  final title = tester.widget<AppBar>(find.byType(AppBar)).title;
  return (title as Text?)?.data;
}

void main() {
  tearDown(() => sl.reset());

  testWidgets('toggling EN -> VI re-renders the visible LoginPage',
      (tester) async {
    await _boot(tester, {});
    expect(_appBarTitle(tester), 'Login');

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    expect(_appBarTitle(tester), 'Đăng nhập');
    expect(find.text('Mật khẩu'), findsOneWidget);
  });

  testWidgets('a field error already shown switches language too',
      (tester) async {
    await _boot(tester, {});
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
    await _boot(tester, {'access_token': 'valid-token'});
    expect(_appBarTitle(tester), 'Home');

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    expect(_appBarTitle(tester), 'Trang chủ');
  });
}
