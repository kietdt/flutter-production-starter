// Data Model Module
// Responsibility: Token pair returned by `/auth/refresh` (no `user` object,
// unlike the login response).

import 'package:flutter_production_starter/core/network/token_pair.dart';
import 'package:flutter_production_starter/core/utils/map_ext.dart';

class TokenPairModel {
  final String accessToken;
  final String refreshToken;

  const TokenPairModel({
    required this.accessToken,
    required this.refreshToken,
  });

  factory TokenPairModel.fromJson(Map<dynamic, dynamic> json) {
    return TokenPairModel(
      accessToken: json.parseString('accessToken'),
      refreshToken: json.parseString('refreshToken'),
    );
  }

  TokenPair toEntity() {
    return TokenPair(accessToken: accessToken, refreshToken: refreshToken);
  }
}
