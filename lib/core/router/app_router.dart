// Core Router
// Responsibility: The root auth gate. A single [AppAuthCubit] decides which
// top-level screen is shown — unauthenticated users see [LoginPage],
// authenticated users see [HomePage].
//
// Login/logout just flip the auth status (AppAuthCubit.loggedIn()/logout()) and
// this widget rebuilds onto the right screen — no manual navigation needed.
//
// Why plain widget swapping (instead of a declarative router): it keeps hot
// reload working and fits a mobile app's simple top-level flow. Imperative
// navigation (dev tools, detail pages) still goes through the Coordinator.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/app_auth_cubit.dart';
import '../../feature/home/home.dart';
import '../../feature/login/login_page.dart';

/// Shows the right top-level screen for the current auth state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppAuthCubit, AppAuthState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        if (state.status.isAuthenticated) {
          return const HomePage();
        }
        if (state.status.isUnauthenticated) {
          return const LoginPage();
        }
        // Initial: the auth check hasn't resolved yet.
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
