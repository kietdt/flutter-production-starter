import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/auth/app_auth_cubit.dart';
import 'core/config/app_config.dart';
import 'core/di/di.dart';
import 'core/local_storage/shared_prefs_manager.dart';
import 'core/localization/app_language.dart';
import 'core/localization/locale_cubit.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';

/// Default entry point — equivalent to the dev flavor, so `flutter run` works
/// without a target. Flavor-specific entry points live in `main_dev.dart`,
/// `main_staging.dart`, and `main_prod.dart`.
Future<void> main() => bootstrap(Flavor.dev);

/// Shared bootstrap for every flavor: pins the active [AppConfig] (which the
/// network client reads for its base URL) before wiring up DI and the app.
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.init(AppConfig.fromFlavor(flavor));
  await initApp();
  runApp(const MyApp());
}

Future<void> initApp() async {
  await SharedPrefsManager.instance.init();
  initDI();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Built once: the same AppAuthCubit instance drives the AuthGate, so
  // login/logout consistently swap the top-level screen.
  late final AppAuthCubit _authCubit = sl<AppAuthCubit>()..checkAuth();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authCubit),
        BlocProvider(
          create: (context) => sl<ThemeCubit>()..loadTheme(),
        ),
        BlocProvider(
          create: (context) => sl<LocaleCubit>()..loadLocale(),
        ),
      ],
      child: BlocBuilder<LocaleCubit, LocaleState>(
        buildWhen: (previous, current) => previous.locale != current.locale,
        builder: (context, localeState) {
          return BlocBuilder<ThemeCubit, ThemeState>(
            buildWhen: (previous, current) =>
                previous.themeMode != current.themeMode,
            builder: (context, themeState) {
              return MaterialApp(
                title: AppLanguage.current.appTitle,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeState.themeMode,
                locale: localeState.locale.flutterLocale,
                supportedLocales:
                    AppLocale.values.map((l) => l.flutterLocale).toList(),
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: const AuthGate(),
              );
            },
          );
        },
      ),
    );
  }
}
