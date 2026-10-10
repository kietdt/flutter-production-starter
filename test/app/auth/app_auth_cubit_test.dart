// #11 / #14 — AppAuthCubit decides the start screen through
// CheckSessionUseCase and holds the signed-in user as global state.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_production_starter/app/auth/cubit/app_auth_cubit.dart';
import 'package:flutter_production_starter/domain/entity/user_entity.dart';
import 'package:flutter_production_starter/domain/repository/auth_repository.dart';
import 'package:flutter_production_starter/domain/usecase/check_session_usecase.dart';
import 'package:flutter_production_starter/domain/usecase/logout_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _user = UserEntity(id: '1', email: 'kiet@example.com', userName: 'Kiet');

void main() {
  late _MockAuthRepository repository;

  AppAuthCubit build() => AppAuthCubit(
        checkSessionUseCase: CheckSessionUseCase(repository: repository),
        logoutUseCase: LogoutUseCase(repository: repository),
      );

  setUp(() => repository = _MockAuthRepository());

  blocTest<AppAuthCubit, AppAuthState>(
    'checkAuth restores the stored user as authenticated',
    build: build,
    setUp: () => when(() => repository.currentUser()).thenReturn(_user),
    act: (cubit) => cubit.checkAuth(),
    expect: () => [
      isA<AppAuthState>()
          .having((s) => s.status, 'status', AppAuthStatus.authenticated)
          .having((s) => s.user, 'user', _user),
    ],
  );

  blocTest<AppAuthCubit, AppAuthState>(
    'checkAuth emits unauthenticated without a user when there is no session',
    build: build,
    setUp: () => when(() => repository.currentUser()).thenReturn(null),
    act: (cubit) => cubit.checkAuth(),
    expect: () => [
      isA<AppAuthState>()
          .having((s) => s.status, 'status', AppAuthStatus.unauthenticated)
          .having((s) => s.user, 'user', isNull),
    ],
  );

  blocTest<AppAuthCubit, AppAuthState>(
    'loggedIn stores the user and emits authenticated',
    build: build,
    act: (cubit) => cubit.loggedIn(user: _user),
    expect: () => [
      isA<AppAuthState>()
          .having((s) => s.status, 'status', AppAuthStatus.authenticated)
          .having((s) => s.user, 'user', _user),
    ],
  );

  blocTest<AppAuthCubit, AppAuthState>(
    'logout ends the session, clears the user and emits unauthenticated',
    build: build,
    seed: () => const AppAuthState(
      status: AppAuthStatus.authenticated,
      user: _user,
    ),
    setUp: () => when(() => repository.logout()).thenAnswer((_) async {}),
    act: (cubit) => cubit.logout(),
    expect: () => [
      isA<AppAuthState>()
          .having((s) => s.status, 'status', AppAuthStatus.unauthenticated)
          .having((s) => s.user, 'user', isNull),
    ],
    verify: (_) => verify(() => repository.logout()).called(1),
  );
}
