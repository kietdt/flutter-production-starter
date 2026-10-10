part of 'locale_cubit.dart';

class LocaleState extends Equatable {
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

  @override
  List<Object?> get props => [locale];
}
