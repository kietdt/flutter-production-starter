// Core Localization — English
// Responsibility: English values for the AppLanguage contract.

import '../app_language.dart';

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
}
