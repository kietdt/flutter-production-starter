// Core Router
// Responsibility: Declarative routing for the main screens (login/home) with an
// auth guard. Dev tools navigation stays imperative in the Coordinator.
//
// The redirect drives the whole auth flow: logging in (AppAuthCubit.loggedIn)
// or out (logout) flips the auth status, refreshListenable re-runs the redirect,
// and the user lands on the right screen — no manual navigation needed.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/app_auth_cubit.dart';
import '../../feature/home/home.dart';
import '../../feature/login/login_page.dart';

/// Centralized route paths for the main screens.
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String login = '/login';
}

class AppRouter {
  final AppAuthCubit authCubit;

  AppRouter({required this.authCubit});

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: _redirect,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
    ],
  );

  /// Auth guard: unauthenticated users are forced to /login; authenticated
  /// users are kept away from /login.
  String? _redirect(BuildContext context, GoRouterState state) {
    final loggedIn = authCubit.state.status.isAuthenticated;
    final goingToLogin = state.matchedLocation == AppRoutes.login;

    if (!loggedIn) {
      return goingToLogin ? null : AppRoutes.login;
    }
    if (goingToLogin) {
      return AppRoutes.home;
    }
    return null;
  }
}

/// Bridges a [Stream] (e.g. a Cubit's state stream) to the [Listenable] that
/// `GoRouter.refreshListenable` expects, so the redirect re-runs on each emit.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (_) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
