// #8 — The developer Theme Gallery must not be reachable in the prod flavor:
// no entry point on Home, and Coordinator.openDevTools is a no-op.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_production_starter/app/coordinator/coordinator.dart';
import 'package:flutter_production_starter/app/di/di.dart';
import 'package:flutter_production_starter/core/config/app_config.dart';
import 'package:flutter_production_starter/core/local_storage/shared_prefs_manager.dart';
import 'package:flutter_production_starter/core/theme/cubit/theme_cubit.dart';
import 'package:flutter_production_starter/feature/dev_tools/dev_tools_gallery_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/session_prefs.dart';

/// A bare app with one button that asks the Coordinator for the dev tools.
/// The gallery's ThemeToggleButton needs a ThemeCubit above the Navigator.
Future<Widget> _openDevToolsButton() async {
  SharedPreferences.setMockInitialValues({});
  final SharedPrefsManager prefs = await SharedPrefsManager.create();
  return BlocProvider(
    create: (_) => ThemeCubit(prefs: prefs),
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Coordinator.openDevTools(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  tearDown(() async {
    AppConfig.init(AppConfig.fromFlavor(Flavor.dev));
    await sl.reset();
  });

  test('showDevTools is false only for the prod flavor', () {
    expect(AppConfig.fromFlavor(Flavor.prod).showDevTools, isFalse);
    expect(AppConfig.fromFlavor(Flavor.staging).showDevTools, isTrue);
    expect(AppConfig.fromFlavor(Flavor.dev).showDevTools, isTrue);
  });

  group('Home entry point', () {
    testWidgets('is shown in the dev flavor', (tester) async {
      AppConfig.init(AppConfig.fromFlavor(Flavor.dev));
      await pumpApp(tester, prefs: signedInPrefs);

      expect(find.text('Navigation'), findsOneWidget);
    });

    testWidgets('is absent in the prod flavor', (tester) async {
      AppConfig.init(AppConfig.fromFlavor(Flavor.prod));
      await pumpApp(tester, prefs: signedInPrefs);

      expect(find.text('Home'), findsWidgets);
      expect(find.text('Navigation'), findsNothing);
    });
  });

  group('Coordinator.openDevTools', () {
    testWidgets('opens the gallery in the dev flavor', (tester) async {
      AppConfig.init(AppConfig.fromFlavor(Flavor.dev));
      await tester.pumpWidget(await _openDevToolsButton());

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(DevToolsGalleryPage), findsOneWidget);
    });

    testWidgets('does nothing in the prod flavor', (tester) async {
      AppConfig.init(AppConfig.fromFlavor(Flavor.prod));
      await tester.pumpWidget(await _openDevToolsButton());

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(DevToolsGalleryPage), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });
  });
}
