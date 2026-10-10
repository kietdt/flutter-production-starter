import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String userName;

  const UserEntity({
    required this.id,
    required this.email,
    required this.userName,
  });

  /// Name to show in the UI; falls back to the email when no user name is set.
  String get displayName => userName.isNotEmpty ? userName : email;

  @override
  List<Object?> get props => [id, email, userName];
}
