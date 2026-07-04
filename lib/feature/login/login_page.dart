// Feature View Module
// Responsibility: The main screen/page for the feature.
//
// Glues together the state management and widgets.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/di.dart';
import '../../core/auth/app_auth_cubit.dart';
import '../../core/localization/app_language.dart';
import '../../core/localization/language_toggle_button.dart';
import '../../core/theme/theme_toggle_button.dart';
import 'cubit/login_cubit.dart';
import 'widget/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit(loginUseCase: sl()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLanguage.current.loginTitle),
          actions: const [LanguageToggleButton(), ThemeToggleButton()],
        ),
        body: BlocListener<LoginCubit, LoginState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.status.isSuccess) {
              context.read<AppAuthCubit>().loggedIn();
            } else if (state.status.isFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      state.errorMessage ?? AppLanguage.current.loginFailed),
                ),
              );
            }
          },
          child: const Center(
            child: LoginForm(),
          ),
        ),
      ),
    );
  }
}
