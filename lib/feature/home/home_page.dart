import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_production_starter/app/auth/cubit/app_auth_cubit.dart';
import 'package:flutter_production_starter/app/coordinator/coordinator.dart';
import 'package:flutter_production_starter/core/config/app_config.dart';
import 'package:flutter_production_starter/core/localization/app_language_context.dart';
import 'package:flutter_production_starter/core/localization/language_toggle_button.dart';
import 'package:flutter_production_starter/core/theme/theme_toggle_button.dart';
import 'package:flutter_production_starter/domain/entity/user_entity.dart';

/// Signed-in landing screen. Shows the global user from [AppAuthCubit]; it has
/// no screen-level state, so it needs no Cubit of its own.
class HomePage extends StatelessWidget {
  const HomePage._();

  static Widget newInstance() => const HomePage._();

  @override
  Widget build(BuildContext context) {
    final UserEntity? user =
        context.select((AppAuthCubit cubit) => cubit.state.user);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.homeTitle),
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
            child: Text(context.l10n.homeTitle),
          ),
          if (user != null) Text(context.l10n.homeGreeting(user.displayName)),
          // Static per-flavor flag, so the entry is simply not built in prod.
          if (AppConfig.instance.showDevTools)
            InkWell(
              onTap: () => Coordinator.openDevTools(context),
              child: Text(context.l10n.navigation),
            ),
        ],
      ),
    );
  }
}
