import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_production_starter/app/app.dart';
import 'package:flutter_production_starter/app/di/di.dart';
import 'package:flutter_production_starter/core/network/network_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Boots the real app like a cold start: DI from scratch, then [MyApp].
///
/// [prefs] seeds SharedPreferences; leave it null to keep what an earlier
/// launch in the same test stored (an app restart). [httpAdapter] replaces
/// the network. Pair with `tearDown(() => sl.reset())`.
Future<void> pumpApp(
  WidgetTester tester, {
  Map<String, Object>? prefs,
  HttpClientAdapter? httpAdapter,
}) async {
  if (prefs != null) SharedPreferences.setMockInitialValues(prefs);
  await sl.reset();
  await initDI();
  if (httpAdapter != null) {
    sl<NetworkClient>().dio.httpClientAdapter = httpAdapter;
  }
  // Unmount an earlier launch so this MyApp starts from fresh state.
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();
}
