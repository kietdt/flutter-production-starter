import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper over [SharedPreferences]. Created once by `initDI()` and
/// injected where needed — there is no static instance.
class SharedPrefsManager {
  final SharedPreferences _prefs;

  SharedPrefsManager({required SharedPreferences prefs}) : _prefs = prefs;

  /// Loads the platform preferences. Await before registering in DI.
  static Future<SharedPrefsManager> create() async {
    return SharedPrefsManager(prefs: await SharedPreferences.getInstance());
  }

  Future<bool> setString(String key, String value) {
    return _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<bool> setInt(String key, int value) {
    return _prefs.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  Future<bool> setBool(String key, bool value) {
    return _prefs.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  Future<bool> remove(String key) {
    return _prefs.remove(key);
  }

  Future<bool> clear() {
    return _prefs.clear();
  }
}
