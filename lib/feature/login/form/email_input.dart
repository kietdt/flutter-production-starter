// Login Form Input
// Responsibility: formz-validated email field with a UI-safe error message.

import 'package:formz/formz.dart';

import '../../../core/localization/app_language.dart';

enum EmailValidationError {
  empty,
  invalid;

  /// UI-safe message in the caller's language (pass `context.l10n`).
  String message(AppLanguage l10n) {
    switch (this) {
      case EmailValidationError.empty:
        return l10n.emailRequired;
      case EmailValidationError.invalid:
        return l10n.emailInvalid;
    }
  }
}

class EmailInput extends FormzInput<String, EmailValidationError> {
  const EmailInput.pure() : super.pure('');
  const EmailInput.dirty([super.value = '']) : super.dirty();

  static final RegExp _emailRegExp = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  @override
  EmailValidationError? validator(String value) {
    if (value.isEmpty) return EmailValidationError.empty;
    if (!_emailRegExp.hasMatch(value)) return EmailValidationError.invalid;
    return null;
  }

  /// Message to show under the field — null while the input is still pure
  /// (untouched) so we don't flag errors before the user types.
  String? errorText(AppLanguage l10n) => displayError?.message(l10n);
}
