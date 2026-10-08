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

  /// Nullable fields take a [Nullable] so they can be cleared:
  /// omit to keep, `const Nullable(null)` to clear, `Nullable(v)` to replace.
  LoginState copyWith({
    FeatureStatus? status,
    EmailInput? email,
    PasswordInput? password,
    bool? isValid,
    Nullable<UserEntity?>? user,
    Nullable<String?>? errorMessage,
  }) {
    return LoginState(
      status: status ?? this.status,
      email: email ?? this.email,
      password: password ?? this.password,
      isValid: isValid ?? this.isValid,
      user: user != null ? user.value : this.user,
      errorMessage:
          errorMessage != null ? errorMessage.value : this.errorMessage,
    );
  }
}
