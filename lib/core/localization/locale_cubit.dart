// Core Localization Module
// Responsibility: Manage the active locale, persist it, and keep
// `AppLanguage.current` in sync so widgets can read strings without a context.

import 'package:flutter_bloc/flutter_bloc.dart';

import '../local_storage/shared_prefs_manager.dart';
import '../utils/constants.dart';
import 'app_language.dart';

part 'locale_state.dart';

class LocaleCubit extends Cubit<LocaleState> {
  final SharedPrefsManager prefs;

  LocaleCubit({required this.prefs}) : super(const LocaleState()) {
    AppLanguage.setCurrent(state.locale);
  }

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

  // Update the static facade BEFORE emitting so the rebuild reads fresh strings.
  void _apply(AppLocale locale) {
    AppLanguage.setCurrent(locale);
    emit(state.copyWith(locale: locale));
  }
}
