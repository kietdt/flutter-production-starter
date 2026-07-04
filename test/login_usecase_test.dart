// Unit tests for LoginUseCase (GĐ 3.1).
//
// The use case is a thin orchestration layer: it must delegate to the repository
// with the exact arguments it received and pass through both the returned entity
// and any thrown Failure untouched. We mock the repository with mocktail so no
// real datasource/network is involved.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_production_starter/core/error/failures.dart';
import 'package:flutter_production_starter/domain/entity/user_entity.dart';
import 'package:flutter_production_starter/domain/repository/auth_repository.dart';
import 'package:flutter_production_starter/domain/usecase/login_usecase.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late LoginUseCase useCase;

  const user = UserEntity(id: '1', email: 'user@example.com', userName: 'user');
  const email = 'user@example.com';
  const password = 'password123';

  setUp(() {
    repository = _MockAuthRepository();
    useCase = LoginUseCase(repository: repository);
  });

  test('delegates to repository.login with the same email and password',
      () async {
    when(() => repository.login(any(), any())).thenAnswer((_) async => user);

    final result = await useCase.execute(email, password);

    expect(result, same(user));
    verify(() => repository.login(email, password)).called(1);
    verifyNoMoreInteractions(repository);
  });

  test('propagates a Failure thrown by the repository untouched', () async {
    const failure = ServerFailure(message: 'No internet connection');
    when(() => repository.login(any(), any())).thenThrow(failure);

    expect(
      () => useCase.execute(email, password),
      throwsA(same(failure)),
    );
  });
}
