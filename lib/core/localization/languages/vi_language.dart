// Core Localization — Vietnamese
// Responsibility: Vietnamese values for the AppLanguage contract.

import 'package:flutter_production_starter/core/localization/app_language.dart';

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

  @override
  String get errorTimeout => 'Kết nối quá thời gian. Vui lòng thử lại.';

  @override
  String get errorNoConnection =>
      'Không có kết nối mạng. Vui lòng kiểm tra mạng và thử lại.';

  @override
  String get errorUnauthorized =>
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';

  @override
  String get errorServer => 'Đã có lỗi xảy ra. Vui lòng thử lại.';

  @override
  String get errorCancelled => 'Yêu cầu đã bị huỷ.';

  @override
  String get errorUnknown => 'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.';

  @override
  String get loginInvalidCredentials => 'Email hoặc mật khẩu không đúng.';

  @override
  String homeGreeting(String name) => 'Xin chào, $name';
}
