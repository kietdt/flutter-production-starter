import '../../core/utils/map_ext.dart';
import 'user_model.dart';

class AuthResponseModel {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<dynamic, dynamic> json) {
    return AuthResponseModel(
      accessToken: json.parseString('accessToken'),
      refreshToken: json.parseString('refreshToken'),
      user: UserModel.fromJson(json.parseMap('user')),
    );
  }
}
