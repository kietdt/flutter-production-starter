part of 'app_auth_cubit.dart';

enum AppAuthStatus {
  initial,
  authenticated,
  unauthenticated;

  bool get isInitial => this == AppAuthStatus.initial;
  bool get isAuthenticated => this == AppAuthStatus.authenticated;
  bool get isUnauthenticated => this == AppAuthStatus.unauthenticated;
}

class AppAuthState extends Equatable {
  final AppAuthStatus status;

  /// The signed-in user; non-null exactly when [status] is authenticated.
  final UserEntity? user;

  const AppAuthState({
    this.status = AppAuthStatus.initial,
    this.user,
  });

  /// Nullable fields take a [Nullable] so they can be cleared:
  /// omit to keep, `const Nullable(null)` to clear, `Nullable(v)` to replace.
  AppAuthState copyWith({
    AppAuthStatus? status,
    Nullable<UserEntity?>? user,
  }) {
    return AppAuthState(
      status: status ?? this.status,
      user: user != null ? user.value : this.user,
    );
  }

  @override
  List<Object?> get props => [status, user];
}
