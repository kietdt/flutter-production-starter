import 'package:flutter_production_starter/core/utils/constants.dart';

/// SharedPreferences values of a stored, signed-in session. Since #14 a
/// session needs both an access token and the cached user.
const Map<String, Object> signedInPrefs = {
  StorageKeys.accessToken: 'valid-token',
  StorageKeys.refreshToken: 'valid-refresh',
  StorageKeys.cachedUser:
      '{"id": "1", "email": "user@example.com", "userName": "Tester"}',
};
