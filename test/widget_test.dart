// Smoke test for the application bootstrap + go_router auth guard.
//
// Verifies the redirect drives the start screen: no token -> LoginPage; a stored
// access token -> HomePage.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_production_starter/core/di/di.dart';
import 'package:flutter_production_starter/core/local_storage/shared_prefs_manager.dart';
import 'package:flutter_production_starter/main.dart';

Future<void> _boot(WidgetTester tester, Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  await SharedPrefsManager.instance.init();
  initDI();
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() {
    sl.reset();
  });

  testWidgets('redirects to LoginPage when unauthenticated', (tester) async {
    await _boot(tester, {});

    // LoginPage shows the login form fields and a Login action.
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
  });

  testWidgets('redirects to HomePage when an access token is present',
      (tester) async {
    await _boot(tester, {'access_token': 'valid-token'});

    // HomePage chrome is shown; the login form is gone.
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Navigation'), findsOneWidget);
    expect(find.text('Email'), findsNothing);
  });
}
