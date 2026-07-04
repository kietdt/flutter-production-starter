// Unit tests for LoginCubit — formz validation (GĐ 2.4) + emission sequences
// via bloc_test (GĐ 3.1).

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_production_starter/core/error/failures.dart';
import 'package:flutter_production_starter/core/utils/feature_status.dart';
import 'package:flutter_production_starter/domain/entity/user_entity.dart';
import 'package:flutter_production_starter/domain/repository/auth_repository.dart';
import 'package:flutter_production_starter/domain/usecase/login_usecase.dart';
import 'package:flutter_production_starter/feature/login/cubit/login_cubit.dart';

class _FakeRepository implements AuthRepository {
  @override
  Future<UserEntity> login(String email, String password) async =>
      const UserEntity(id: '1', email: 'a@b.com', userName: 'test');

  @override
  Future<void> logout() async {}
}

class _MockRepository extends Mock implements AuthRepository {}

LoginCubit _buildCubit() =>
    LoginCubit(loginUseCase: LoginUseCase(repository: _FakeRepository()));

/// Seeds a cubit whose form is already valid, so blocTest can focus purely on
/// the login() emission sequence.
LoginCubit _validCubit(AuthRepository repository) =>
    LoginCubit(loginUseCase: LoginUseCase(repository: repository))
      ..emailChanged('user@example.com')
      ..passwordChanged('password123');

void main() {
  test('initial state is pure and invalid, with no error text', () {
    final cubit = _buildCubit();
    expect(cubit.state.isValid, isFalse);
    expect(cubit.state.email.errorText, isNull);
    expect(cubit.state.password.errorText, isNull);
    expect(cubit.state.status, FeatureStatus.init);
  });

  test('invalid email surfaces a friendly error and keeps form invalid', () {
    final cubit = _buildCubit();
    cubit.emailChanged('not-an-email');
    expect(cubit.state.email.errorText, 'Enter a valid email address');
    expect(cubit.state.isValid, isFalse);
  });

  test('short password surfaces a friendly error', () {
    final cubit = _buildCubit();
    cubit.passwordChanged('123');
    expect(cubit.state.password.errorText,
        'Password must be at least 6 characters');
    expect(cubit.state.isValid, isFalse);
  });

  test('valid email + password makes the form valid', () {
    final cubit = _buildCubit();
    cubit.emailChanged('user@example.com');
    cubit.passwordChanged('password123');
    expect(cubit.state.email.errorText, isNull);
    expect(cubit.state.password.errorText, isNull);
    expect(cubit.state.isValid, isTrue);
  });

  test('login() is a no-op while the form is invalid', () async {
    final cubit = _buildCubit();
    await cubit.login();
    expect(cubit.state.status, FeatureStatus.init);
  });

  test('login() succeeds when the form is valid', () async {
    final cubit = _buildCubit();
    cubit.emailChanged('user@example.com');
    cubit.passwordChanged('password123');
    await cubit.login();
    expect(cubit.state.status, FeatureStatus.success);
    expect(cubit.state.user, isNotNull);
  });

  group('login() emission sequence', () {
    late AuthRepository repository;

    setUp(() => repository = _MockRepository());

    blocTest<LoginCubit, LoginState>(
      'emits [loading, success] with the user on a successful login',
      build: () => _validCubit(repository),
      setUp: () => when(() => repository.login(any(), any())).thenAnswer(
        (_) async =>
            const UserEntity(id: '1', email: 'user@example.com', userName: 'u'),
      ),
      act: (cubit) => cubit.login(),
      expect: () => [
        isA<LoginState>()
            .having((s) => s.status, 'status', FeatureStatus.loading),
        isA<LoginState>()
            .having((s) => s.status, 'status', FeatureStatus.success)
            .having((s) => s.user?.email, 'user.email', 'user@example.com'),
      ],
      verify: (_) =>
          verify(() => repository.login('user@example.com', 'password123'))
              .called(1),
    );

    blocTest<LoginCubit, LoginState>(
      'emits [loading, failure] with the Failure message on a failed login',
      build: () => _validCubit(repository),
      setUp: () => when(() => repository.login(any(), any())).thenAnswer(
        (_) async =>
            throw const ServerFailure(message: 'No internet connection'),
      ),
      act: (cubit) => cubit.login(),
      expect: () => [
        isA<LoginState>()
            .having((s) => s.status, 'status', FeatureStatus.loading),
        isA<LoginState>()
            .having((s) => s.status, 'status', FeatureStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage',
                'No internet connection'),
      ],
    );
  });
}
