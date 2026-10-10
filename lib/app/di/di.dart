import 'package:flutter_production_starter/app/auth/cubit/app_auth_cubit.dart';
import 'package:flutter_production_starter/core/config/app_config.dart';
import 'package:flutter_production_starter/core/local_storage/shared_prefs_manager.dart';
import 'package:flutter_production_starter/core/localization/cubit/locale_cubit.dart';
import 'package:flutter_production_starter/core/network/network_client.dart';
import 'package:flutter_production_starter/core/network/token_management.dart';
import 'package:flutter_production_starter/core/theme/cubit/theme_cubit.dart';
import 'package:flutter_production_starter/data/datasource/local/auth_local_datasource.dart';
import 'package:flutter_production_starter/data/datasource/remote/auth_remote_datasource.dart';
import 'package:flutter_production_starter/data/repository/auth_repository_impl.dart';
import 'package:flutter_production_starter/domain/repository/auth_repository.dart';
import 'package:flutter_production_starter/domain/usecase/check_session_usecase.dart';
import 'package:flutter_production_starter/domain/usecase/logout_usecase.dart';
import 'package:get_it/get_it.dart';

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
