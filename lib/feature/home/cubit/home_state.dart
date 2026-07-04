part of 'home_cubit.dart';

class HomeState {
  final FeatureStatus status;

  const HomeState({
    this.status = FeatureStatus.init,
  });

  HomeState copyWith({
    FeatureStatus? status,
  }) {
    return HomeState(
      status: status ?? this.status,
    );
  }
}
