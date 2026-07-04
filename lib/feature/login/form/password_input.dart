// Login Form Input
// Responsibility: formz-validated password field with a UI-safe error message.

import 'package:formz/formz.dart';

import '../../../core/localization/app_language.dart';

enum PasswordValidationError { empty, tooShort }

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
  String? get errorText {
    switch (displayError) {
      case PasswordValidationError.empty:
        return AppLanguage.current.passwordRequired;
      case PasswordValidationError.tooShort:
        return AppLanguage.current.passwordTooShort(minLength);
      case null:
        return null;
    }
  }
}
