// Login Form Input
// Responsibility: formz-validated password field with a UI-safe error message.

import 'package:flutter_production_starter/core/localization/app_language.dart';
import 'package:formz/formz.dart';

enum PasswordValidationError {
  empty,
  tooShort;

  /// UI-safe message in the caller's language (pass `context.l10n`).
  String message(AppLanguage l10n) {
    switch (this) {
      case PasswordValidationError.empty:
        return l10n.passwordRequired;
      case PasswordValidationError.tooShort:
        return l10n.passwordTooShort(PasswordInput.minLength);
    }
  }
}

class PasswordInput extends FormzInput<String, PasswordValidationError> {
  const PasswordInput.pure() : super.pure('');
  const PasswordInput.dirty([super.value = '']) : super.dirty();

  static const int minLength = 6;

  @override
  PasswordValidationError? validator(String value) {
    if (value.isEmpty) return PasswordValidationError.empty;
    if (value.length < minLength) return PasswordValidationError.tooShort;
    return null;
  }

  /// Message to show under the field — null while the input is still pure.
  String? errorText(AppLanguage l10n) => displayError?.message(l10n);
}
