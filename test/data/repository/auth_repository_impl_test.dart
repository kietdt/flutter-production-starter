// #11 / #14 — AuthRepositoryImpl reads/writes the session (tokens + cached
// user) through the injected AuthLocalDataSource.

import 'package:flutter_production_starter/data/datasource/local/auth_local_datasource.dart';
import 'package:flutter_production_starter/data/datasource/remote/auth_remote_datasource.dart';
import 'package:flutter_production_starter/data/model/auth_response_model.dart';
import 'package:flutter_production_starter/data/model/user_model.dart';
import 'package:flutter_production_starter/data/repository/auth_repository_impl.dart';
import 'package:flutter_production_starter/domain/entity/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

class _MockLocal extends Mock implements AuthLocalDataSource {}

const _userModel = UserModel(id: '1', email: 'e@x.com', userName: 'u');

void main() {
  late _MockRemote remote;
  late _MockLocal local;
  late AuthRepositoryImpl repository;

  setUp(() {
    remote = _MockRemote();
    local = _MockLocal();
    repository =
        AuthRepositoryImpl(remoteDataSource: remote, localDataSource: local);
    when(() => local.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        )).thenAnswer((_) async {});
    when(() => local.clearTokens()).thenAnswer((_) async {});
    when(() => local.saveUser(any())).thenAnswer((_) async {});
    when(() => local.clearUser()).thenAnswer((_) async {});
  });

  setUpAll(() => registerFallbackValue(_userModel));

  test('login saves the returned tokens and user locally', () async {
    when(() => remote.login(any(), any())).thenAnswer(
      (_) async => const AuthResponseModel(
        accessToken: 'a',
        refreshToken: 'r',
        user: _userModel,
      ),
    );

    final user = await repository.login('e@x.com', 'pw');

    expect(user.email, 'e@x.com');
    verify(() => local.saveTokens(accessToken: 'a', refreshToken: 'r'))
        .called(1);
    verify(() => local.saveUser(_userModel)).called(1);
  });

  test('logout revokes the refresh token remotely and clears it locally',
      () async {
    when(() => local.refreshToken).thenReturn('r');
    when(() => remote.logout(any())).thenAnswer((_) async {});

    await repository.logout();

    verify(() => remote.logout('r')).called(1);
    verify(() => local.clearTokens()).called(1);
    verify(() => local.clearUser()).called(1);
  });

  test('logout still clears locally when there is no refresh token', () async {
    when(() => local.refreshToken).thenReturn(null);

    await repository.logout();

    verifyNever(() => remote.logout(any()));
    verify(() => local.clearTokens()).called(1);
    verify(() => local.clearUser()).called(1);
  });

  group('currentUser', () {
    test('returns the cached user when an access token is stored', () {
      when(() => local.accessToken).thenReturn('a');
      when(() => local.cachedUser).thenReturn(_userModel);

      expect(
        repository.currentUser(),
        const UserEntity(id: '1', email: 'e@x.com', userName: 'u'),
      );
    });

    test('is null when the access token is missing or empty', () {
      when(() => local.cachedUser).thenReturn(_userModel);

      when(() => local.accessToken).thenReturn(null);
      expect(repository.currentUser(), isNull);

      when(() => local.accessToken).thenReturn('');
      expect(repository.currentUser(), isNull);
    });

    test('is null when a token exists but no user was cached', () {
      when(() => local.accessToken).thenReturn('a');
      when(() => local.cachedUser).thenReturn(null);

      expect(repository.currentUser(), isNull);
    });
  });
}
