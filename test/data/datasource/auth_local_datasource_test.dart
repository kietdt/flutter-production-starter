// #11 — AuthLocalDataSource is the single owner of persisted tokens. It keeps
// the historical SharedPreferences keys so existing sessions survive updates.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_production_starter/core/local_storage/shared_prefs_manager.dart';
import 'package:flutter_production_starter/data/datasource/local/auth_local_datasource.dart';

Future<AuthLocalDataSourceImpl> _build(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return AuthLocalDataSourceImpl(prefs: await SharedPrefsManager.create());
}

void main() {
  test('reads tokens stored under the existing keys', () async {
    final AuthLocalDataSourceImpl local = await _build({
      'access_token': 'a',
      'refresh_token': 'r',
    });

    expect(local.accessToken, 'a');
    expect(local.refreshToken, 'r');
  });

  test('saveTokens persists both tokens', () async {
    final AuthLocalDataSourceImpl local = await _build({});

    await local.saveTokens(accessToken: 'a', refreshToken: 'r');

    final SharedPreferences raw = await SharedPreferences.getInstance();
    expect(raw.getString('access_token'), 'a');
    expect(raw.getString('refresh_token'), 'r');
  });

  test('clearTokens removes both tokens', () async {
    final AuthLocalDataSourceImpl local = await _build({
      'access_token': 'a',
      'refresh_token': 'r',
    });

    await local.clearTokens();

    expect(local.accessToken, isNull);
    expect(local.refreshToken, isNull);
  });
}
