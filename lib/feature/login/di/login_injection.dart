import 'package:flutter_production_starter/domain/repository/auth_repository.dart';
import 'package:flutter_production_starter/domain/usecase/login_usecase.dart';
import 'package:get_it/get_it.dart';

/// Registers what only the login feature needs. Shared auth pieces
/// (`AuthRepository`, …) come from the app composition root (`initDI`).
abstract final class LoginInjection {
  static void setup(GetIt sl) {
    if (sl.isRegistered<LoginUseCase>()) return;
    sl.registerLazySingleton(
      () => LoginUseCase(repository: sl<AuthRepository>()),
    );
  }
}
