// Independent of domain entities; exposes toEntity() to bridge the data and
// domain layers (see .cursor/rules/model-entity-separation.mdc).

import 'package:flutter_production_starter/core/utils/map_ext.dart';
import 'package:flutter_production_starter/domain/entity/user_entity.dart';

class UserModel {
  final String id;
  final String email;
  final String userName;

  const UserModel({
    required this.id,
    required this.email,
    required this.userName,
  });

  factory UserModel.fromJson(Map<dynamic, dynamic> json) {
    return UserModel(
      id: json.parseString('id'),
      email: json.parseString('email'),
      userName: json.parseString('userName'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'userName': userName,
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      userName: userName,
    );
  }
}
