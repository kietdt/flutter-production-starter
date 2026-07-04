// Feature Widget Module
// Responsibility: Reusable UI components specific to this feature.
//
// Form state lives in LoginCubit (formz inputs); fields are stateless and only
// rebuild for their own slice of state (see .cursor/rules/bloc-optimization.mdc).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/localization/app_language.dart';
import '../cubit/login_cubit.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _EmailField(),
          Gap(16),
          _PasswordField(),
          Gap(16),
          _SubmitButton(),
        ],
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) => previous.email != current.email,
      builder: (context, state) {
        return TextField(
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) => context.read<LoginCubit>().emailChanged(value),
          decoration: InputDecoration(
            labelText: AppLanguage.current.emailLabel,
            prefixIcon: const Icon(Icons.email_outlined),
            errorText: state.email.errorText,
          ),
        );
      },
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) => previous.password != current.password,
      builder: (context, state) {
        return TextField(
          obscureText: true,
          onChanged: (value) =>
              context.read<LoginCubit>().passwordChanged(value),
          decoration: InputDecoration(
            labelText: AppLanguage.current.passwordLabel,
            prefixIcon: const Icon(Icons.lock_outline),
            errorText: state.password.errorText,
          ),
        );
      },
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) =>
          previous.isValid != current.isValid ||
          previous.status != current.status,
      builder: (context, state) {
        final isLoading = state.status.isLoading;
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state.isValid && !isLoading
                ? () => context.read<LoginCubit>().login()
                : null,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(AppLanguage.current.loginButton),
          ),
        );
      },
    );
  }
}
