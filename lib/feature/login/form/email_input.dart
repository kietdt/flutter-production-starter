// Login Form Input
// Responsibility: formz-validated email field with a UI-safe error message.

import 'package:formz/formz.dart';

import '../../../core/localization/app_language.dart';

enum EmailValidationError { empty, invalid }

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
  String? get errorText {
    switch (displayError) {
      case EmailValidationError.empty:
        return AppLanguage.current.emailRequired;
      case EmailValidationError.invalid:
        return AppLanguage.current.emailInvalid;
      case null:
        return null;
    }
  }
}
