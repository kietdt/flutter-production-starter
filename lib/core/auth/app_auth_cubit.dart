import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecase/logout_usecase.dart';
import '../network/token_management.dart';

part 'app_auth_state.dart';

class AppAuthCubit extends Cubit<AppAuthState> {
  final LogoutUseCase logoutUseCase;

  AppAuthCubit({required this.logoutUseCase}) : super(const AppAuthState());

  void checkAuth() {
    final token = TokenManagement.instance.getAccessTokenSync();
    if (token != null && token.isNotEmpty) {
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
