// Smoke test for the application bootstrap + AuthGate.
//
// Verifies the auth gate drives the start screen: no session -> LoginPage; a
// stored session (access token + cached user, #14) -> HomePage.

import 'package:flutter_production_starter/app/di/di.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';
import '../helpers/session_prefs.dart';

void main() {
  tearDown(() {
    sl.reset();
  });

  testWidgets('redirects to LoginPage when unauthenticated', (tester) async {
    await pumpApp(tester, prefs: {});

    // LoginPage shows the login form fields and a Login action.
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
  });

  testWidgets('redirects to HomePage when a session is stored', (tester) async {
    await pumpApp(tester, prefs: signedInPrefs);

    // HomePage chrome is shown; the login form is gone.
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Navigation'), findsOneWidget);
    expect(find.text('Email'), findsNothing);
  });

  testWidgets('a token without a cached user is not a session (#14)',
      (tester) async {
    await pumpApp(tester, prefs: {'access_token': 'valid-token'});

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });
}
