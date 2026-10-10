// Core Localization Module
// Responsibility: Manual (no codegen) i18n. `AppLanguage` is the abstract
// contract of every user-facing string; `EnLanguage`/`ViLanguage` implement it.
//
// Usage from widgets: `context.l10n.loginButton` (see app_language_context.dart).
// The active locale comes from `MaterialApp.locale`, driven by `LocaleCubit`.

import 'package:flutter/widgets.dart';

import 'package:flutter_production_starter/core/localization/languages/en_language.dart';
import 'package:flutter_production_starter/core/localization/languages/vi_language.dart';

/// Supported locales. Drives persistence, the Flutter `Locale`, and the
/// `AppLanguage` implementation lookup.
enum AppLocale {
  en,
  vi;

  String get code {
    switch (this) {
      case AppLocale.en:
        return 'en';
      case AppLocale.vi:
        return 'vi';
    }
  }

  /// Short label for a language switcher (e.g. an AppBar button).
  String get label {
    switch (this) {
      case AppLocale.en:
        return 'EN';
      case AppLocale.vi:
        return 'VI';
    }
  }

  Locale get flutterLocale => Locale(code);

  static AppLocale fromCode(String? code) {
    switch (code) {
      case 'vi':
        return AppLocale.vi;
      case 'en':
      default:
        return AppLocale.en;
    }
  }
}

abstract class AppLanguage {
  const AppLanguage();

  AppLocale get locale;

  // --- App ---
  String get appTitle;

  // --- Login ---
  String get loginTitle;
  String get loginButton;
  String get emailLabel;
  String get passwordLabel;
  String get loginFailed;

  // --- Login form validation ---
  String get emailRequired;
  String get emailInvalid;
  String get passwordRequired;
  String passwordTooShort(int min);

  // --- Home ---
  String get homeTitle;
  String get navigation;

  // --- Shared ---
  String get toggleTheme;

  // --- Errors (mapped from Failure, see failure_message.dart) ---
  String get errorTimeout;
  String get errorNoConnection;
  String get errorUnauthorized;
  String get errorServer;
  String get errorCancelled;
  String get errorUnknown;
  String get loginInvalidCredentials;

  // --- Home (user) ---
  String homeGreeting(String name);

  /// Resolves the implementation for a given [AppLocale].
  static AppLanguage of(AppLocale locale) {
    switch (locale) {
      case AppLocale.en:
        return const EnLanguage();
      case AppLocale.vi:
        return const ViLanguage();
    }
  }
}
