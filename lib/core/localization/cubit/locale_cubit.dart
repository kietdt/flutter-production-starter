// Core Localization Module
// Responsibility: Manage the active locale and persist it. `MaterialApp.locale`
// follows this state; widgets read strings via `context.l10n`.

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_production_starter/core/local_storage/shared_prefs_manager.dart';
import 'package:flutter_production_starter/core/localization/app_language.dart';
import 'package:flutter_production_starter/core/utils/constants.dart';

part 'locale_state.dart';

class LocaleCubit extends Cubit<LocaleState> {
  final SharedPrefsManager prefs;

  LocaleCubit({required this.prefs}) : super(const LocaleState());

  /// Restores the persisted locale. Call once at startup.
  void loadLocale() {
    final locale = AppLocale.fromCode(prefs.getString(StorageKeys.locale));
    _apply(locale);
  }

  /// Toggles between the supported locales (en ⇄ vi) and persists the choice.
  Future<void> toggleLocale() async {
    final next = state.locale == AppLocale.en ? AppLocale.vi : AppLocale.en;
    await setLocale(next);
  }

  /// Applies and persists an explicit [AppLocale].
  Future<void> setLocale(AppLocale locale) async {
    _apply(locale);
    await prefs.setString(StorageKeys.locale, locale.code);
  }

  void _apply(AppLocale locale) {
    emit(state.copyWith(locale: locale));
  }
}
