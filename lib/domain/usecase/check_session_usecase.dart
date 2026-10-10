import 'package:flutter_production_starter/domain/entity/user_entity.dart';
import 'package:flutter_production_starter/domain/repository/auth_repository.dart';

/// The user of the stored session, or `null` when there is none — decides the
/// start screen.
class CheckSessionUseCase {
  final AuthRepository repository;

  CheckSessionUseCase({required this.repository});

  UserEntity? execute() {
    return repository.currentUser();
  }
}
