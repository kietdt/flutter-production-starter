/// Feature Dependency Injection Module
/// Responsibility: Register feature-specific dependencies (usecases, repositories, cubits).
/// 
/// Useful when using packages like get_it.

class AuthDI {
  static void init() {
    // Example:
    // sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl());
    // sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(remoteDataSource: sl()));
    // sl.registerLazySingleton(() => LoginUseCase(sl()));
    // sl.registerFactory(() => AuthCubit(loginUseCase: sl()));
  }
}
