// Core Localization Module
// Responsibility: Reusable AppBar action that toggles the app language (en ⇄ vi).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'locale_cubit.dart';

/// A text button showing the active language code (EN/VI); tapping toggles it.
class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, LocaleState>(
      buildWhen: (previous, current) => previous.locale != current.locale,
      builder: (context, state) {
        return TextButton(
          onPressed: () => context.read<LocaleCubit>().toggleLocale(),
          child: Text(state.locale.label),
        );
      },
    );
  }
}
