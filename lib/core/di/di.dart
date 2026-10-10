import 'package:get_it/get_it.dart';

import '../auth/app_auth_cubit.dart';
import '../config/app_config.dart';
import '../local_storage/shared_prefs_manager.dart';
import '../localization/locale_cubit.dart';
import '../network/network_client.dart';
import '../network/token_management.dart';
import '../theme/theme_cubit.dart';
import '../../data/datasource/local/auth_local_datasource.dart';
import '../../data/datasource/remote/auth_remote_datasource.dart';
import '../../data/repository/auth_repository_impl.dart';
import '../../domain/repository/auth_repository.dart';
import '../../domain/usecase/check_session_usecase.dart';
import '../../domain/usecase/login_usecase.dart';
import '../../domain/usecase/logout_usecase.dart';

final sl = GetIt.instance;

/// Composition root: the ONLY place that reads from [sl] to build objects.
/// Everything else receives its dependencies through constructors.
Future<void> initDI() async {
  // Storage
  sl.registerSingleton<SharedPrefsManager>(await SharedPrefsManager.create());
  sl.registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(prefs: sl()));

  // Core Network
  sl.registerLazySingleton<TokenManagement>(() => TokenManagement(
        storage: sl<AuthLocalDataSource>(),
        // Resolved lazily at refresh time: AuthRemoteDataSource needs the
        // NetworkClient, which needs this TokenManagement.
        refresher: (refreshToken) async =>
            (await sl<AuthRemoteDataSource>().refresh(refreshToken)).toEntity(),
      ));
  sl.registerLazySingleton<NetworkClient>(() => NetworkClient(
        baseUrl: AppConfig.instance.baseUrl,
        tokenManagement: sl(),
        enableLogging: AppConfig.instance.enableNetworkLogging,
        onUnauthorized: () {
          if (sl.isRegistered<AppAuthCubit>()) {
            sl<AppAuthCubit>().logout();
          }
        },
      ));

  // Global Auth Dependencies
  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(networkClient: sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
      ));
  sl.registerLazySingleton(() => LoginUseCase(repository: sl()));
  sl.registerLazySingleton(() => LogoutUseCase(repository: sl()));
  sl.registerLazySingleton(() => CheckSessionUseCase(repository: sl()));

  // Global AppAuthCubit
  sl.registerLazySingleton(() => AppAuthCubit(
        checkSessionUseCase: sl(),
        logoutUseCase: sl(),
      ));

  // Global ThemeCubit (persists ThemeMode via SharedPrefsManager)
  sl.registerLazySingleton(() => ThemeCubit(prefs: sl()));

  // Global LocaleCubit (persists locale via SharedPrefsManager)
  sl.registerLazySingleton(() => LocaleCubit(prefs: sl()));
}
