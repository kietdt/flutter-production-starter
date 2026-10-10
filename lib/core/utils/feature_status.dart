enum FeatureStatus {
  init,
  loading,
  success,
  failure,
  empty,
  ;

  bool get isInit => this == init;
  bool get isLoading => this == loading;
  bool get isSuccess => this == success;
  bool get isFailure => this == failure;
  bool get isEmpty => this == empty;
}
