/// Feature State Management Module (Cubit/Bloc)
/// Responsibility: Manage state for the specific feature.
///
/// Calls usecases and updates states accordingly.

// import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entity/user_entity.dart';
import '../../../domain/usecase/login_usecase.dart';
import '../../../core/utils/feature_status.dart';
import '../../../core/utils/app_logger.dart';

part 'auth_state.dart';

// Assuming flutter_bloc is used
class AuthCubit /* extends Cubit<AuthState> */ {
  final LoginUseCase loginUseCase;

  AuthCubit({required this.loginUseCase}) /* : super(const AuthState()) */;

  Future<void> login(String email, String password) async {
    // emit(state.copyWith(status: FeatureStatus.loading));
    try {
      final user = await loginUseCase.execute(email, password);
      AppLogger.info('Login success for user: ${user.email}',
          name: 'AuthCubit');
      // emit(state.copyWith(status: FeatureStatus.success, user: user));
    } catch (e) {
      AppLogger.error('Login failed', error: e, name: 'AuthCubit');
      // emit(state.copyWith(status: FeatureStatus.failure, errorMessage: e.toString()));
    }
  }
}
