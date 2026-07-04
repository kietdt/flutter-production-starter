// Core Theme Module
// Responsibility: Manage the active [ThemeMode] and persist it across launches.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../local_storage/shared_prefs_manager.dart';
import '../utils/constants.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  final SharedPrefsManager prefs;

  ThemeCubit({required this.prefs}) : super(const ThemeState());

  /// Restores the persisted [ThemeMode]. Call once at startup.
  void loadTheme() {
    final index = prefs.getInt(StorageKeys.themeMode);
    if (index == null || index < 0 || index >= ThemeMode.values.length) {
      return;
    }
    emit(state.copyWith(themeMode: ThemeMode.values[index]));
  }

  /// Cycles system → light → dark and persists the choice.
  Future<void> toggleTheme() async {
    final next = switch (state.themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    await setTheme(next);
  }

  /// Applies and persists an explicit [ThemeMode].
  Future<void> setTheme(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    await prefs.setInt(StorageKeys.themeMode, mode.index);
  }
}
