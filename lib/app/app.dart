import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter_production_starter/app/auth/cubit/app_auth_cubit.dart';
import 'package:flutter_production_starter/app/di/di.dart';
import 'package:flutter_production_starter/app/router/auth_gate.dart';
import 'package:flutter_production_starter/core/localization/app_language.dart';
import 'package:flutter_production_starter/core/localization/app_language_context.dart';
import 'package:flutter_production_starter/core/localization/cubit/locale_cubit.dart';
import 'package:flutter_production_starter/core/theme/app_theme.dart';
import 'package:flutter_production_starter/core/theme/cubit/theme_cubit.dart';

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
                onGenerateTitle: (context) => context.l10n.appTitle,
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
