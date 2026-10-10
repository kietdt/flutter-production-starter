// Unit tests for LoginCubit — formz validation (GĐ 2.4) + emission sequences
// via bloc_test (GĐ 3.1).

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_production_starter/core/error/failures.dart';
import 'package:flutter_production_starter/core/localization/languages/en_language.dart';
import 'package:flutter_production_starter/core/utils/feature_status.dart';
import 'package:flutter_production_starter/core/utils/nullable.dart';
import 'package:flutter_production_starter/domain/entity/user_entity.dart';
import 'package:flutter_production_starter/domain/repository/auth_repository.dart';
import 'package:flutter_production_starter/domain/usecase/login_usecase.dart';
import 'package:flutter_production_starter/feature/login/cubit/login_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Form error messages are resolved per language; assert against English.
const _en = EnLanguage();

const _offline = NetworkFailure(reason: NetworkFailureReason.noConnection);

class _FakeRepository implements AuthRepository {
  @override
  Future<UserEntity> login(String email, String password) async =>
      const UserEntity(id: '1', email: 'a@b.com', userName: 'test');

  @override
  Future<void> logout() async {}

  @override
  UserEntity? currentUser() => null;
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
    expect(cubit.state.email.errorText(_en), isNull);
    expect(cubit.state.password.errorText(_en), isNull);
    expect(cubit.state.status, FeatureStatus.init);
  });

  test('invalid email surfaces a friendly error and keeps form invalid', () {
    final cubit = _buildCubit();
    cubit.emailChanged('not-an-email');
    expect(cubit.state.email.errorText(_en), 'Enter a valid email address');
    expect(cubit.state.isValid, isFalse);
  });

  test('short password surfaces a friendly error', () {
    final cubit = _buildCubit();
    cubit.passwordChanged('123');
    expect(cubit.state.password.errorText(_en),
        'Password must be at least 6 characters');
    expect(cubit.state.isValid, isFalse);
  });

  test('valid email + password makes the form valid', () {
    final cubit = _buildCubit();
    cubit.emailChanged('user@example.com');
    cubit.passwordChanged('password123');
    expect(cubit.state.email.errorText(_en), isNull);
    expect(cubit.state.password.errorText(_en), isNull);
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

  group('LoginState.copyWith nullable fields', () {
    const user = UserEntity(id: '1', email: 'a@b.com', userName: 'u');
    const filled = LoginState(user: user, failure: _offline);

    test('keeps nullable fields when they are omitted', () {
      final LoginState next = filled.copyWith(status: FeatureStatus.loading);
      expect(next.user, same(user));
      expect(next.failure, same(_offline));
    });

    test('clears nullable fields with Nullable(null)', () {
      final LoginState next = filled.copyWith(
          user: const Nullable(null), failure: const Nullable(null));
      expect(next.user, isNull);
      expect(next.failure, isNull);
    });

    test('replaces nullable fields with Nullable(value)', () {
      final LoginState next = const LoginState().copyWith(
        user: const Nullable(user),
        failure: const Nullable(_offline),
      );
      expect(next.user, same(user));
      expect(next.failure, same(_offline));
    });
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
      'emits [loading, failure] carrying the Failure on a failed login',
      build: () => _validCubit(repository),
      setUp: () => when(() => repository.login(any(), any()))
          .thenAnswer((_) async => throw _offline),
      act: (cubit) => cubit.login(),
      expect: () => [
        isA<LoginState>()
            .having((s) => s.status, 'status', FeatureStatus.loading),
        isA<LoginState>()
            .having((s) => s.status, 'status', FeatureStatus.failure)
            .having((s) => s.failure, 'failure', same(_offline)),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      'wraps a non-Failure error in an UnknownFailure that keeps the cause',
      build: () => _validCubit(repository),
      setUp: () => when(() => repository.login(any(), any()))
          .thenAnswer((_) async => throw StateError('bug')),
      act: (cubit) => cubit.login(),
      expect: () => [
        isA<LoginState>()
            .having((s) => s.status, 'status', FeatureStatus.loading),
        isA<LoginState>()
            .having((s) => s.status, 'status', FeatureStatus.failure)
            .having(
              (s) => s.failure,
              'failure',
              isA<UnknownFailure>()
                  .having((f) => f.cause, 'cause', isA<StateError>())
                  .having((f) => f.stackTrace, 'stackTrace', isNotNull),
            ),
      ],
    );

    // #9 — a stale error from the previous attempt must not survive a retry.
    blocTest<LoginCubit, LoginState>(
      'a retry after a failure clears the failure from loading onwards',
      build: () => _validCubit(repository),
      setUp: () {
        var calls = 0;
        when(() => repository.login(any(), any())).thenAnswer((_) async {
          if (++calls == 1) {
            throw _offline;
          }
          return const UserEntity(
              id: '1', email: 'user@example.com', userName: 'u');
        });
      },
      act: (cubit) async {
        await cubit.login();
        await cubit.login();
      },
      expect: () => [
        isA<LoginState>()
            .having((s) => s.status, 'status', FeatureStatus.loading),
        isA<LoginState>()
            .having((s) => s.status, 'status', FeatureStatus.failure)
            .having((s) => s.failure, 'failure', same(_offline)),
        isA<LoginState>()
            .having((s) => s.status, 'status', FeatureStatus.loading)
            .having((s) => s.failure, 'failure', isNull),
        isA<LoginState>()
            .having((s) => s.status, 'status', FeatureStatus.success)
            .having((s) => s.failure, 'failure', isNull),
      ],
    );
  });

  group('LoginState.failureMessage', () {
    test('a 401 on login reads as wrong credentials', () {
      const state = LoginState(failure: UnauthorizedFailure());
      expect(state.failureMessage(_en), _en.loginInvalidCredentials);
    });

    test('other failures use the shared localized mapping', () {
      const state = LoginState(failure: _offline);
      expect(state.failureMessage(_en), _en.errorNoConnection);
    });

    test('falls back to the generic text without a failure', () {
      expect(const LoginState().failureMessage(_en), _en.loginFailed);
    });
  });
}
