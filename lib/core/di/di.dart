import 'package:get_it/get_it.dart';

import '../auth/app_auth_cubit.dart';
import '../config/app_config.dart';
import '../local_storage/shared_prefs_manager.dart';
import '../localization/locale_cubit.dart';
import '../network/network_client.dart';
import '../theme/theme_cubit.dart';
import '../../data/datasource/remote/auth_remote_datasource.dart';
import '../../data/repository/auth_repository_impl.dart';
import '../../domain/repository/auth_repository.dart';
import '../../domain/usecase/login_usecase.dart';
import '../../domain/usecase/logout_usecase.dart';

final sl = GetIt.instance;

void initDI() {
  // Core Network
  sl.registerLazySingleton<NetworkClient>(() => NetworkClient(
        baseUrl: AppConfig.instance.baseUrl,
        onUnauthorized: () {
          if (sl.isRegistered<AppAuthCubit>()) {
            sl<AppAuthCubit>().logout();
          }
        },
      ));

  // Global Auth Dependencies
  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(networkClient: sl()));
  sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remoteDataSource: sl()));
  sl.registerLazySingleton(() => LoginUseCase(repository: sl()));
  sl.registerLazySingleton(() => LogoutUseCase(repository: sl()));

  // Global AppAuthCubit
  sl.registerLazySingleton(() => AppAuthCubit(logoutUseCase: sl()));

  // Global ThemeCubit (persists ThemeMode via SharedPrefsManager)
  sl.registerLazySingleton(
      () => ThemeCubit(prefs: SharedPrefsManager.instance));

  // Global LocaleCubit (persists locale via SharedPrefsManager)
  sl.registerLazySingleton(
      () => LocaleCubit(prefs: SharedPrefsManager.instance));
}
