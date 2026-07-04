part of 'app_auth_cubit.dart';

enum AppAuthStatus {
  initial,
  authenticated,
  unauthenticated;

  bool get isInitial => this == AppAuthStatus.initial;
  bool get isAuthenticated => this == AppAuthStatus.authenticated;
  bool get isUnauthenticated => this == AppAuthStatus.unauthenticated;
}

class AppAuthState {
  final AppAuthStatus status;

  const AppAuthState({
    this.status = AppAuthStatus.initial,
  });

  AppAuthState copyWith({
    AppAuthStatus? status,
  }) {
    return AppAuthState(
      status: status ?? this.status,
    );
  }
}
