import '../repository/auth_repository.dart';

/// Whether a stored session exists — decides the start screen.
class CheckSessionUseCase {
  final AuthRepository repository;

  CheckSessionUseCase({required this.repository});

  bool execute() {
    return repository.hasSession();
  }
}
