part of 'login_cubit.dart';

class LoginState {
  final FeatureStatus status;
  final EmailInput email;
  final PasswordInput password;
  final bool isValid;
  final UserEntity? user;
  final String? errorMessage;

  const LoginState({
    this.status = FeatureStatus.init,
    this.email = const EmailInput.pure(),
    this.password = const PasswordInput.pure(),
    this.isValid = false,
    this.user,
    this.errorMessage,
  });

  LoginState copyWith({
    FeatureStatus? status,
    EmailInput? email,
    PasswordInput? password,
    bool? isValid,
    UserEntity? user,
    String? errorMessage,
  }) {
    return LoginState(
      status: status ?? this.status,
      email: email ?? this.email,
      password: password ?? this.password,
      isValid: isValid ?? this.isValid,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
