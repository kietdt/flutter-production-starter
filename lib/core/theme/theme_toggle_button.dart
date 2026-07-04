// Core Theme Module
// Responsibility: Reusable AppBar action that cycles the app ThemeMode.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../localization/app_language.dart';
import 'theme_cubit.dart';

/// An [IconButton] that toggles `system → light → dark` via the global
/// [ThemeCubit]. Drop it into any AppBar's `actions`.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      buildWhen: (previous, current) => previous.themeMode != current.themeMode,
      builder: (context, state) {
        return IconButton(
          tooltip:
              '${AppLanguage.current.toggleTheme} (${state.themeMode.name})',
          icon: Icon(_iconFor(state.themeMode)),
          onPressed: () => context.read<ThemeCubit>().toggleTheme(),
        );
      },
    );
  }

  IconData _iconFor(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => Icons.brightness_auto,
      ThemeMode.light => Icons.light_mode,
      ThemeMode.dark => Icons.dark_mode,
    };
  }
}
