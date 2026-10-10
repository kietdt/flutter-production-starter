// Core Localization — English
// Responsibility: English values for the AppLanguage contract.

import 'package:flutter_production_starter/core/localization/app_language.dart';

class EnLanguage extends AppLanguage {
  const EnLanguage();

  @override
  AppLocale get locale => AppLocale.en;

  @override
  String get appTitle => 'Flutter Production Starter';

  @override
  String get loginTitle => 'Login';

  @override
  String get loginButton => 'Login';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Enter a valid email address';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String passwordTooShort(int min) =>
      'Password must be at least $min characters';

  @override
  String get homeTitle => 'Home';

  @override
  String get navigation => 'Navigation';

  @override
  String get toggleTheme => 'Toggle theme';

  @override
  String get errorTimeout => 'The connection timed out. Please try again.';

  @override
  String get errorNoConnection =>
      'No internet connection. Please check your network and try again.';

  @override
  String get errorUnauthorized =>
      'Your session has expired. Please log in again.';

  @override
  String get errorServer => 'Something went wrong. Please try again.';

  @override
  String get errorCancelled => 'The request was cancelled.';

  @override
  String get errorUnknown => 'An unexpected error occurred. Please try again.';

  @override
  String get loginInvalidCredentials => 'Incorrect email or password.';

  @override
  String homeGreeting(String name) => 'Hello, $name';
}
