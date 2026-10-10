// Widget tests for LoginPage (GĐ 3.1).
//
// Covers what a user actually sees and does: fields render, the submit button
// gates on validation, a successful login notifies AppAuthCubit, and a failure
// surfaces a friendly SnackBar (never a raw exception string).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_production_starter/app/auth/cubit/app_auth_cubit.dart';
import 'package:flutter_production_starter/app/di/di.dart';
import 'package:flutter_production_starter/core/error/failures.dart';
import 'package:flutter_production_starter/core/local_storage/shared_prefs_manager.dart';
import 'package:flutter_production_starter/core/localization/cubit/locale_cubit.dart';
import 'package:flutter_production_starter/core/theme/cubit/theme_cubit.dart';
import 'package:flutter_production_starter/domain/entity/user_entity.dart';
import 'package:flutter_production_starter/domain/repository/auth_repository.dart';
import 'package:flutter_production_starter/domain/usecase/check_session_usecase.dart';
import 'package:flutter_production_starter/domain/usecase/login_usecase.dart';
import 'package:flutter_production_starter/domain/usecase/logout_usecase.dart';
import 'package:flutter_production_starter/feature/login/login_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

late AuthRepository repository;
late AppAuthCubit authCubit;
late SharedPrefsManager prefs;

Future<void> _pumpLoginPage(WidgetTester tester) async {
  // LoginPage's AppBar hosts the shared Theme/Language toggle buttons, so those
  // cubits must be in scope too.
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authCubit),
        BlocProvider(create: (_) => ThemeCubit(prefs: prefs)),
        BlocProvider(create: (_) => LocaleCubit(prefs: prefs)),
      ],
      child: MaterialApp(home: LoginPage.newInstance()),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPrefsManager.create();
    repository = _MockAuthRepository();
    // LoginPage builds its LoginCubit from the service locator.
    sl.registerLazySingleton(() => LoginUseCase(repository: repository));
    authCubit = AppAuthCubit(
      checkSessionUseCase: CheckSessionUseCase(repository: repository),
      logoutUseCase: LogoutUseCase(repository: repository),
    );
  });

  tearDown(() async {
    await authCubit.close();
    await sl.reset();
  });

  testWidgets('renders both fields and a disabled submit button initially',
      (tester) async {
    await _pumpLoginPage(tester);

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('shows a friendly error when the email is invalid',
      (tester) async {
    await _pumpLoginPage(tester);

    await tester.enterText(find.byType(TextField).first, 'not-an-email');
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('enables the submit button once both inputs are valid',
      (tester) async {
    await _pumpLoginPage(tester);

    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.pump();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets(
      'a successful login flips AppAuthCubit to authenticated with the user',
      (tester) async {
    const UserEntity user =
        UserEntity(id: '1', email: 'user@example.com', userName: 'u');
    when(() => repository.login(any(), any())).thenAnswer((_) async => user);

    await _pumpLoginPage(tester);
    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.pump();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(authCubit.state.status, AppAuthStatus.authenticated);
    expect(authCubit.state.user, user);
  });

  testWidgets('a failed login shows the failure message in a SnackBar',
      (tester) async {
    when(() => repository.login(any(), any())).thenAnswer(
      (_) async => throw const NetworkFailure(
        reason: NetworkFailureReason.noConnection,
      ),
    );

    await _pumpLoginPage(tester);
    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.pump();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // start async login
    await tester.pump(); // let the SnackBar appear

    expect(
      find.widgetWithText(
        SnackBar,
        'No internet connection. Please check your network and try again.',
      ),
      findsOneWidget,
    );
    expect(authCubit.state.status, AppAuthStatus.initial);
  });
}
