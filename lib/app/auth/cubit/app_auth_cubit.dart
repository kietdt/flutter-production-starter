import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_production_starter/core/utils/nullable.dart';
import 'package:flutter_production_starter/domain/entity/user_entity.dart';
import 'package:flutter_production_starter/domain/usecase/check_session_usecase.dart';
import 'package:flutter_production_starter/domain/usecase/logout_usecase.dart';

part 'app_auth_state.dart';

class AppAuthCubit extends Cubit<AppAuthState> {
  final CheckSessionUseCase checkSessionUseCase;
  final LogoutUseCase logoutUseCase;

  AppAuthCubit({
    required this.checkSessionUseCase,
    required this.logoutUseCase,
  }) : super(const AppAuthState());

  /// Restores the stored session (synchronously, no network) on app start.
  void checkAuth() {
    final UserEntity? user = checkSessionUseCase.execute();
    if (user != null) {
      emit(state.copyWith(
        status: AppAuthStatus.authenticated,
        user: Nullable(user),
      ));
    } else {
      emit(state.copyWith(
        status: AppAuthStatus.unauthenticated,
        user: const Nullable(null),
      ));
    }
  }

  void loggedIn({required UserEntity user}) {
    emit(state.copyWith(
      status: AppAuthStatus.authenticated,
      user: Nullable(user),
    ));
  }

  Future<void> logout() async {
    await logoutUseCase.execute();
    emit(state.copyWith(
      status: AppAuthStatus.unauthenticated,
      user: const Nullable(null),
    ));
  }
}
