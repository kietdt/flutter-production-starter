part of 'login_cubit.dart';

class LoginState extends Equatable {
  final FeatureStatus status;
  final EmailInput email;
  final PasswordInput password;
  final bool isValid;
  final UserEntity? user;
  final Failure? failure;

  const LoginState({
    this.status = FeatureStatus.init,
    this.email = const EmailInput.pure(),
    this.password = const PasswordInput.pure(),
    this.isValid = false,
    this.user,
    this.failure,
  });

  /// Text for the failure SnackBar. On the login screen a 401 means wrong
  /// credentials, not an expired session; everything else uses the shared
  /// [FailureMessage] mapping.
  String failureMessage(AppLanguage l10n) {
    final Failure? failure = this.failure;
    switch (failure) {
      case null:
        return l10n.loginFailed;
      case UnauthorizedFailure():
        return l10n.loginInvalidCredentials;
      case final Failure other:
        return other.message(l10n);
    }
  }

  /// Nullable fields take a [Nullable] so they can be cleared:
  /// omit to keep, `const Nullable(null)` to clear, `Nullable(v)` to replace.
  LoginState copyWith({
    FeatureStatus? status,
    EmailInput? email,
    PasswordInput? password,
    bool? isValid,
    Nullable<UserEntity?>? user,
    Nullable<Failure?>? failure,
  }) {
    return LoginState(
      status: status ?? this.status,
      email: email ?? this.email,
      password: password ?? this.password,
      isValid: isValid ?? this.isValid,
      user: user != null ? user.value : this.user,
      failure: failure != null ? failure.value : this.failure,
    );
  }

  @override
  List<Object?> get props => [status, email, password, isValid, user, failure];
}
