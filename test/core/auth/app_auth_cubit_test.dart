// #11 — AppAuthCubit decides the start screen through CheckSessionUseCase
// instead of reading tokens directly.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_production_starter/core/auth/app_auth_cubit.dart';
import 'package:flutter_production_starter/domain/repository/auth_repository.dart';
import 'package:flutter_production_starter/domain/usecase/check_session_usecase.dart';
import 'package:flutter_production_starter/domain/usecase/logout_usecase.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  AppAuthCubit build() => AppAuthCubit(
        checkSessionUseCase: CheckSessionUseCase(repository: repository),
        logoutUseCase: LogoutUseCase(repository: repository),
      );

  setUp(() => repository = _MockAuthRepository());

  blocTest<AppAuthCubit, AppAuthState>(
    'checkAuth emits authenticated when a session exists',
    build: build,
    setUp: () => when(() => repository.hasSession()).thenReturn(true),
    act: (cubit) => cubit.checkAuth(),
    expect: () => [
      isA<AppAuthState>()
          .having((s) => s.status, 'status', AppAuthStatus.authenticated),
    ],
  );

  blocTest<AppAuthCubit, AppAuthState>(
    'checkAuth emits unauthenticated when there is no session',
    build: build,
    setUp: () => when(() => repository.hasSession()).thenReturn(false),
    act: (cubit) => cubit.checkAuth(),
    expect: () => [
      isA<AppAuthState>()
          .having((s) => s.status, 'status', AppAuthStatus.unauthenticated),
    ],
  );

  blocTest<AppAuthCubit, AppAuthState>(
    'logout ends the session and emits unauthenticated',
    build: build,
    setUp: () => when(() => repository.logout()).thenAnswer((_) async {}),
    act: (cubit) => cubit.logout(),
    expect: () => [
      isA<AppAuthState>()
          .having((s) => s.status, 'status', AppAuthStatus.unauthenticated),
    ],
    verify: (_) => verify(() => repository.logout()).called(1),
  );
}
