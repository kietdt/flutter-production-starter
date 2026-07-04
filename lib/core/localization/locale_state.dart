part of 'locale_cubit.dart';

class LocaleState {
  final AppLocale locale;

  const LocaleState({
    this.locale = AppLocale.en,
  });

  LocaleState copyWith({
    AppLocale? locale,
  }) {
    return LocaleState(
      locale: locale ?? this.locale,
    );
  }
}
