/// Feature State Module
/// Responsibility: Define the possible states for the feature.

part of 'auth_cubit.dart';

class AuthState {
  final FeatureStatus status;
  final UserEntity? user;
  final String? errorMessage;

  const AuthState({
    this.status = FeatureStatus.init,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    FeatureStatus? status,
    UserEntity? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
