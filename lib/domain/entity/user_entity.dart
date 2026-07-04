// Domain Entity Module
// Responsibility: Core business logic objects. Independent of any other layer.

class UserEntity {
  final String id;
  final String email;
  final String userName;

  const UserEntity({
    required this.id,
    required this.email,
    required this.userName,
  });
}
