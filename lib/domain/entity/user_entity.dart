/// Domain Entity Module
/// Responsibility: Core business logic objects. Independent of any other layer.

class UserEntity {
  final String id;
  final String email;

  const UserEntity({
    required this.id,
    required this.email,
  });
}
