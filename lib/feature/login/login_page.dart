import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_production_starter/app/auth/cubit/app_auth_cubit.dart';
import 'package:flutter_production_starter/app/di/di.dart';
import 'package:flutter_production_starter/core/localization/app_language_context.dart';
import 'package:flutter_production_starter/core/localization/language_toggle_button.dart';
import 'package:flutter_production_starter/core/theme/theme_toggle_button.dart';
import 'package:flutter_production_starter/domain/entity/user_entity.dart';
import 'package:flutter_production_starter/domain/usecase/login_usecase.dart';
import 'package:flutter_production_starter/feature/login/cubit/login_cubit.dart';
import 'package:flutter_production_starter/feature/login/di/login_injection.dart';
import 'package:flutter_production_starter/feature/login/widget/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage._();

  /// Registers the feature's dependencies, then builds the screen with its
  /// own [LoginCubit] (rule `screen-newinstance-injection`).
  static Widget newInstance() {
    LoginInjection.setup(sl);
    return BlocProvider(
      create: (_) => LoginCubit(loginUseCase: sl<LoginUseCase>()),
      child: const LoginPage._(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.loginTitle),
        actions: const [LanguageToggleButton(), ThemeToggleButton()],
      ),
      body: BlocListener<LoginCubit, LoginState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          final UserEntity? user = state.user;
          if (state.status.isSuccess && user != null) {
            context.read<AppAuthCubit>().loggedIn(user: user);
          } else if (state.status.isFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failureMessage(context.l10n)),
              ),
            );
          }
        },
        child: const Center(
          child: LoginForm(),
        ),
      ),
    );
  }
}
