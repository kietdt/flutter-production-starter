import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/auth/app_auth_cubit.dart';
import '../../core/coordinator/coordinator.dart';
import '../../core/localization/app_language.dart';
import '../../core/localization/language_toggle_button.dart';
import '../../core/theme/theme_toggle_button.dart';
import 'cubit/home_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit()..loadData(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLanguage.current.homeTitle),
          actions: [
            const LanguageToggleButton(),
            const ThemeToggleButton(),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AppAuthCubit>().logout();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Center(
              child: Text(AppLanguage.current.homeTitle),
            ),
            InkWell(
              onTap: () => Coordinator.openDevTools(context),
              child: Text(AppLanguage.current.navigation),
            ),
          ],
        ),
      ),
    );
  }
}
