// Smoke test for the Theme Gallery dev tool.
//
// Verifies the gallery renders one card per registered showcase, and that every
// showcase detail page builds and lays out without throwing.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_production_starter/core/local_storage/shared_prefs_manager.dart';
import 'package:flutter_production_starter/core/theme/app_theme.dart';
import 'package:flutter_production_starter/core/theme/theme_cubit.dart';
import 'package:flutter_production_starter/feature/dev_tools/dev_tools_gallery_page.dart';
import 'package:flutter_production_starter/feature/dev_tools/registry/showcase_registry.dart';

Widget _wrap(Widget child) {
  return BlocProvider(
    create: (_) => ThemeCubit(prefs: SharedPrefsManager.instance),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: child,
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefsManager.instance.init();
  });

  testWidgets('gallery renders one card per registered showcase',
      (tester) async {
    await tester.pumpWidget(_wrap(const DevToolsGalleryPage()));
    await tester.pumpAndSettle();

    expect(find.text('Theme Gallery'), findsOneWidget);
    for (final showcase in kShowcases) {
      expect(find.text(showcase.title), findsOneWidget,
          reason: 'missing card for ${showcase.title}');
    }
  });

  testWidgets('every showcase page builds without throwing', (tester) async {
    for (final showcase in kShowcases) {
      await tester.pumpWidget(_wrap(Builder(builder: showcase.pageBuilder)));
      // pump (not pumpAndSettle): some pages hold indeterminate progress
      // indicators that animate forever and would never settle.
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull,
          reason: '${showcase.title} threw while building');
      // Each showcase carries its title in its AppBar.
      expect(find.text(showcase.title), findsWidgets,
          reason: '${showcase.title} did not render its AppBar title');
    }
  });
}
