/// Data Model Module
/// Responsibility: Data transfer objects. Contains JSON serialization/deserialization.
///
/// Extends domain entities to bridge the data and domain layers.

import '../../domain/entity/user_entity.dart';

class UserModel {
  final String id;
  final String email;

  const UserModel({
    required this.id,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
    );
  }
}
