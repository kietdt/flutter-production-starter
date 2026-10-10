// Core Localization Module
// Responsibility: Resolve the active `AppLanguage` from the widget tree.

import 'package:flutter/widgets.dart';

import 'package:flutter_production_starter/core/localization/app_language.dart';

extension AppLanguageContext on BuildContext {
  /// Strings in the language of the nearest [Localizations] (driven by
  /// `MaterialApp.locale`, i.e. `LocaleCubit`).
  ///
  /// Reading through the context registers a dependency, so the calling
  /// widget rebuilds when the locale changes — even inside a `const` subtree.
  /// Usage: `context.l10n.loginButton`.
  AppLanguage get l10n {
    final languageCode = Localizations.localeOf(this).languageCode;
    return AppLanguage.of(AppLocale.fromCode(languageCode));
  }
}
