import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_production_starter/core/error/failures.dart';
import 'package:flutter_production_starter/core/localization/app_language.dart';
import 'package:flutter_production_starter/core/localization/failure_message.dart';
import 'package:flutter_production_starter/core/utils/app_logger.dart';
import 'package:flutter_production_starter/core/utils/feature_status.dart';
import 'package:flutter_production_starter/core/utils/nullable.dart';
import 'package:flutter_production_starter/domain/entity/user_entity.dart';
import 'package:flutter_production_starter/domain/usecase/login_usecase.dart';
import 'package:flutter_production_starter/feature/login/form/email_input.dart';
import 'package:flutter_production_starter/feature/login/form/password_input.dart';
import 'package:formz/formz.dart';

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

    // Drop the previous attempt's failure so it can't resurface on this one.
    emit(state.copyWith(
      status: FeatureStatus.loading,
      failure: const Nullable(null),
    ));

    try {
      final user = await loginUseCase.execute(
        state.email.value,
        state.password.value,
      );
      AppLogger.info('Login success for user: ${user.email}',
          name: 'LoginCubit');
      emit(state.copyWith(status: FeatureStatus.success, user: Nullable(user)));
    } on Failure catch (e) {
      _logFailure(e);
      emit(state.copyWith(status: FeatureStatus.failure, failure: Nullable(e)));
    } catch (e, st) {
      // Repositories map every error to a Failure; anything else is a bug.
      final UnknownFailure failure = UnknownFailure(cause: e, stackTrace: st);
      _logFailure(failure);
      emit(state.copyWith(
        status: FeatureStatus.failure,
        failure: Nullable(failure),
      ));
    }
  }

  /// Expected failures (offline, wrong password, server errors) are only
  /// logged; unexpected ones go to crash reporting with their root cause.
  void _logFailure(Failure failure) {
    switch (failure) {
      case UnknownFailure(:final cause, :final stackTrace):
        AppLogger.error(
          'Login failed unexpectedly',
          error: cause ?? failure,
          stackTrace: stackTrace,
          name: 'LoginCubit',
        );
      case NetworkFailure() ||
            UnauthorizedFailure() ||
            ServerFailure() ||
            CancelledFailure():
        AppLogger.info('Login failed: $failure', name: 'LoginCubit');
    }
  }
}
