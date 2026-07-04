// Unit tests for GĐ 2.5 — manual (no codegen) localization.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_production_starter/core/local_storage/shared_prefs_manager.dart';
import 'package:flutter_production_starter/core/localization/app_language.dart';
import 'package:flutter_production_starter/core/localization/languages/en_language.dart';
import 'package:flutter_production_starter/core/localization/languages/vi_language.dart';
import 'package:flutter_production_starter/core/localization/locale_cubit.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefsManager.instance.init();
    AppLanguage.setCurrent(AppLocale.en); // reset between tests
  });

  group('AppLanguage', () {
    test('of() returns the matching implementation', () {
      expect(AppLanguage.of(AppLocale.en), isA<EnLanguage>());
      expect(AppLanguage.of(AppLocale.vi), isA<ViLanguage>());
    });

    test('current reflects setCurrent', () {
      AppLanguage.setCurrent(AppLocale.vi);
      expect(AppLanguage.current, isA<ViLanguage>());
      expect(AppLanguage.current.loginButton, 'Đăng nhập');
    });

    test('AppLocale.fromCode maps codes and defaults to en', () {
      expect(AppLocale.fromCode('vi'), AppLocale.vi);
      expect(AppLocale.fromCode('en'), AppLocale.en);
      expect(AppLocale.fromCode(null), AppLocale.en);
      expect(AppLocale.fromCode('xx'), AppLocale.en);
    });
  });

  group('LocaleCubit', () {
    LocaleCubit build() => LocaleCubit(prefs: SharedPrefsManager.instance);

    test('setLocale updates state, AppLanguage.current and persists', () async {
      final cubit = build();

      await cubit.setLocale(AppLocale.vi);

      expect(cubit.state.locale, AppLocale.vi);
      expect(AppLanguage.current, isA<ViLanguage>());
      expect(SharedPrefsManager.instance.getString('locale'), 'vi');
    });

    test('toggleLocale flips en <-> vi', () async {
      final cubit = build();
      expect(cubit.state.locale, AppLocale.en);

      await cubit.toggleLocale();
      expect(cubit.state.locale, AppLocale.vi);
      expect(AppLanguage.current.homeTitle, 'Trang chủ');

      await cubit.toggleLocale();
      expect(cubit.state.locale, AppLocale.en);
      expect(AppLanguage.current.homeTitle, 'Home');
    });

    test('loadLocale restores the persisted locale', () async {
      await SharedPrefsManager.instance.setString('locale', 'vi');

      final cubit = build()..loadLocale();

      expect(cubit.state.locale, AppLocale.vi);
      expect(AppLanguage.current, isA<ViLanguage>());
    });
  });
}
