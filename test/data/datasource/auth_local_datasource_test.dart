// #11 / #14 — AuthLocalDataSource is the single owner of the persisted session
// (tokens + cached user). It keeps the historical SharedPreferences token keys
// so existing sessions survive updates.

import 'package:flutter_production_starter/core/local_storage/shared_prefs_manager.dart';
import 'package:flutter_production_starter/data/datasource/local/auth_local_datasource.dart';
import 'package:flutter_production_starter/data/model/user_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  test('saveUser round-trips the user through cachedUser', () async {
    final AuthLocalDataSourceImpl local = await _build({});

    await local.saveUser(
      const UserModel(id: '7', email: 'kiet@example.com', userName: 'Kiet'),
    );

    final UserModel? cached = local.cachedUser;
    expect(cached?.id, '7');
    expect(cached?.email, 'kiet@example.com');
    expect(cached?.userName, 'Kiet');
  });

  test('cachedUser is null when nothing or something unreadable is stored',
      () async {
    expect((await _build({})).cachedUser, isNull);
    expect((await _build({'cached_user': '{not json'})).cachedUser, isNull);
    expect((await _build({'cached_user': '[1, 2]'})).cachedUser, isNull);
  });

  test('clearUser removes the cached user', () async {
    final AuthLocalDataSourceImpl local = await _build({
      'cached_user': '{"id": "7", "email": "e@x.com", "userName": "u"}',
    });
    expect(local.cachedUser, isNotNull);

    await local.clearUser();

    expect(local.cachedUser, isNull);
  });
}
