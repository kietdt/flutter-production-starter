import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecase/check_session_usecase.dart';
import '../../domain/usecase/logout_usecase.dart';

part 'app_auth_state.dart';

class AppAuthCubit extends Cubit<AppAuthState> {
  final CheckSessionUseCase checkSessionUseCase;
  final LogoutUseCase logoutUseCase;

  AppAuthCubit({
    required this.checkSessionUseCase,
    required this.logoutUseCase,
  }) : super(const AppAuthState());

  void checkAuth() {
    if (checkSessionUseCase.execute()) {
      emit(state.copyWith(status: AppAuthStatus.authenticated));
    } else {
      emit(state.copyWith(status: AppAuthStatus.unauthenticated));
    }
  }

  void loggedIn() {
    emit(state.copyWith(status: AppAuthStatus.authenticated));
  }

  Future<void> logout() async {
    await logoutUseCase.execute();
    emit(state.copyWith(status: AppAuthStatus.unauthenticated));
  }
}
