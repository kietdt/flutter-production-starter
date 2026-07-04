import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/feature_status.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState());

  void loadData() {
    emit(state.copyWith(status: FeatureStatus.success));
  }
}
