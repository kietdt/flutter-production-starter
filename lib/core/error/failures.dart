/// Core Error Module
/// Responsibility: Define domain-level failure models.
///
/// These are returned by repositories (often via Either<Failure, Type>).

abstract class Failure {
  final String message;
  const Failure({
    required this.message,
  });
}

class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
  });
}
