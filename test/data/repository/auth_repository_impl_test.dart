// #11 — AuthRepositoryImpl reads/writes tokens through the injected
// AuthLocalDataSource (no TokenManagement singleton).

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_production_starter/data/datasource/local/auth_local_datasource.dart';
import 'package:flutter_production_starter/data/datasource/remote/auth_remote_datasource.dart';
import 'package:flutter_production_starter/data/model/auth_response_model.dart';
import 'package:flutter_production_starter/data/model/user_model.dart';
import 'package:flutter_production_starter/data/repository/auth_repository_impl.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

class _MockLocal extends Mock implements AuthLocalDataSource {}

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
  });

  test('login saves the returned tokens locally', () async {
    when(() => remote.login(any(), any())).thenAnswer(
      (_) async => const AuthResponseModel(
        accessToken: 'a',
        refreshToken: 'r',
        user: UserModel(id: '1', email: 'e@x.com', userName: 'u'),
      ),
    );

    final user = await repository.login('e@x.com', 'pw');

    expect(user.email, 'e@x.com');
    verify(() => local.saveTokens(accessToken: 'a', refreshToken: 'r'))
        .called(1);
  });

  test('logout revokes the refresh token remotely and clears it locally',
      () async {
    when(() => local.refreshToken).thenReturn('r');
    when(() => remote.logout(any())).thenAnswer((_) async {});

    await repository.logout();

    verify(() => remote.logout('r')).called(1);
    verify(() => local.clearTokens()).called(1);
  });

  test('logout still clears locally when there is no refresh token', () async {
    when(() => local.refreshToken).thenReturn(null);

    await repository.logout();

    verifyNever(() => remote.logout(any()));
    verify(() => local.clearTokens()).called(1);
  });

  group('hasSession', () {
    test('is true when an access token is stored', () {
      when(() => local.accessToken).thenReturn('a');
      expect(repository.hasSession(), isTrue);
    });

    test('is false when the access token is missing or empty', () {
      when(() => local.accessToken).thenReturn(null);
      expect(repository.hasSession(), isFalse);

      when(() => local.accessToken).thenReturn('');
      expect(repository.hasSession(), isFalse);
    });
  });
}
