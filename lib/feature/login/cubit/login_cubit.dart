import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import '../../../core/error/failures.dart';
import '../../../domain/entity/user_entity.dart';
import '../../../domain/usecase/login_usecase.dart';
import '../../../core/utils/feature_status.dart';
import '../../../core/utils/app_logger.dart';
import '../form/email_input.dart';
import '../form/password_input.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final LoginUseCase loginUseCase;

  LoginCubit({
    required this.loginUseCase,
  }) : super(const LoginState());

  void emailChanged(String value) {
    final email = EmailInput.dirty(value);
    emit(state.copyWith(
      email: email,
      isValid: Formz.validate([email, state.password]),
    ));
  }

  void passwordChanged(String value) {
    final password = PasswordInput.dirty(value);
    emit(state.copyWith(
      password: password,
      isValid: Formz.validate([state.email, password]),
    ));
  }

  Future<void> login() async {
    if (!state.isValid) return;

    emit(state.copyWith(status: FeatureStatus.loading));

    try {
      final user = await loginUseCase.execute(
        state.email.value,
        state.password.value,
      );
      AppLogger.info('Login success for user: ${user.email}',
          name: 'LoginCubit');
      emit(state.copyWith(status: FeatureStatus.success, user: user));
    } on Failure catch (e) {
      // Repository maps every error to a Failure carrying a UI-safe message.
      AppLogger.error('Login failed', error: e, name: 'LoginCubit');
      emit(state.copyWith(
          status: FeatureStatus.failure, errorMessage: e.message));
    } catch (e) {
      AppLogger.error('Login failed (unexpected)',
          error: e, name: 'LoginCubit');
      emit(state.copyWith(
          status: FeatureStatus.failure,
          errorMessage: const UnknownFailure().message));
    }
  }
}
