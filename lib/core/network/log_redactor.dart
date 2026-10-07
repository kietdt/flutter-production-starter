import 'package:dio/dio.dart';

/// Masks secrets (passwords, tokens, `Authorization`) before network data is
/// logged. Returns a redacted copy; the original data is never mutated.
class LogRedactor {
  LogRedactor._();

  static const String mask = '***';

  /// Keys are compared lowercased with `_` / `-` removed, so `accessToken`,
  /// `access_token` and `Access-Token` all match `accesstoken`.
  static const Set<String> _sensitiveKeys = {
    'password',
    'accesstoken',
    'refreshtoken',
    'token',
    'authorization',
  };

  /// Recursively redacts [data]: maps (headers, JSON bodies), lists and
  /// [FormData] fields. Any other value is returned unchanged.
  static Object? redact(Object? data) {
    if (data is Map) {
      return {
        for (final MapEntry<dynamic, dynamic> entry in data.entries)
          entry.key: _isSensitive(entry.key) ? mask : redact(entry.value),
      };
    }
    if (data is List) {
      return [for (final Object? item in data) redact(item)];
    }
    if (data is FormData) {
      return {
        for (final MapEntry<String, String> field in data.fields)
          field.key: _isSensitive(field.key) ? mask : field.value,
      };
    }
    return data;
  }

  static bool _isSensitive(Object? key) {
    if (key is! String) return false;
    final String normalized = key.toLowerCase().replaceAll(RegExp('[_-]'), '');
    return _sensitiveKeys.contains(normalized);
  }
}
