// Core Localization — Vietnamese
// Responsibility: Vietnamese values for the AppLanguage contract.

import '../app_language.dart';

class ViLanguage extends AppLanguage {
  const ViLanguage();

  @override
  AppLocale get locale => AppLocale.vi;

  @override
  String get appTitle => 'Flutter Production Starter';

  @override
  String get loginTitle => 'Đăng nhập';

  @override
  String get loginButton => 'Đăng nhập';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Mật khẩu';

  @override
  String get loginFailed => 'Đăng nhập thất bại';

  @override
  String get emailRequired => 'Vui lòng nhập email';

  @override
  String get emailInvalid => 'Email không hợp lệ';

  @override
  String get passwordRequired => 'Vui lòng nhập mật khẩu';

  @override
  String passwordTooShort(int min) => 'Mật khẩu phải có ít nhất $min ký tự';

  @override
  String get homeTitle => 'Trang chủ';

  @override
  String get navigation => 'Điều hướng';

  @override
  String get toggleTheme => 'Đổi giao diện';
}
