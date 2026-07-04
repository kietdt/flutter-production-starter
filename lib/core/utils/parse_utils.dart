import 'package:intl/intl.dart';

class Parse {
  static double asDouble(dynamic value, {double defaultValue = 0.0}) {
    return asDoubleOrNull(value) ?? defaultValue;
  }

  static double? asDoubleOrNull(dynamic value) {
    try {
      if (value == null) {
        return null;
      }
      if (value is int) {
        return value.toDouble();
      }
      if (value is num) {
        return value.toDouble();
      }
      return double.tryParse(value.toString());
    } catch (e) {
      return null;
    }
  }

  static String asString(dynamic value, {String defaultValue = ""}) {
    return asStringOrNull(value) ?? defaultValue;
  }

  static String? asStringOrNull(dynamic value) {
    try {
      if (value == null) return null;
      if (value is String) {
        return value;
      }
      return value.toString();
    } catch (e) {
      return null;
    }
  }

  static bool asBool(dynamic value, {bool defaultValue = false}) {
    return asBoolOrNull(value) ?? defaultValue;
  }

  static bool? asBoolOrNull(dynamic value) {
    try {
      if (value is bool) {
        return value;
      }
      if (value is String) {
        if (value == 'true') {
          return true;
        } else if (value == 'false') {
          return false;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static int asInt(dynamic value, {int defaultValue = 0}) {
    return asIntOrNull(value) ?? defaultValue;
  }

  static int? asIntOrNull(dynamic value) {
    try {
      if (value == null) {
        return null;
      }
      if (value is double) {
        return value.toInt();
      }
      if (value is num) {
        return value.toInt();
      }
      return int.tryParse(value.toString());
    } catch (e) {
      return null;
    }
  }

  static DateTime? asSecondToDate(dynamic value,
      {bool isUtc = false, DateTime? defaultValue}) {
    try {
      var valueInt = asIntOrNull(value);
      if (valueInt == null) {
        return defaultValue;
      }
      return DateTime.fromMillisecondsSinceEpoch(valueInt * 1000, isUtc: isUtc);
    } catch (e) {
      return defaultValue;
    }
  }

  static DateTime? asDateISO8601(dynamic value, {DateTime? defaultValue}) {
    // parse kiểu string 2020-02-17T20:44:34.000Z sang date
    try {
      if (value == null) return defaultValue;
      final valueStr = value.toString();
      if (valueStr.isEmpty) {
        return defaultValue;
      }
      return DateTime.parse(valueStr);
    } catch (e) {
      return defaultValue;
    }
  }

  static DateTime? asTimestampToDate(num? value, {bool? isMilliseconds}) {
    if (value == null) return null;
    final valueInt = value.toInt();
    if (valueInt <= 0) return null;

    if (isMilliseconds != null) {
      return isMilliseconds
          ? DateTime.fromMillisecondsSinceEpoch(valueInt)
          : DateTime.fromMillisecondsSinceEpoch(valueInt * 1000);
    }

    // Logic heuristic
    if (valueInt < 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(valueInt * 1000);
    } else {
      return DateTime.fromMillisecondsSinceEpoch(valueInt);
    }
  }

  /// Trình phân tích cú pháp [dynamic] thành [DateTime].
  /// Hỗ trợ:
  /// 1. Đối tượng [DateTime]
  /// 2. Timestamp [num] (Giây hoặc Miligiây)
  /// 3. Chuỗi ISO 8601 (yyyy-MM-dd...)
  /// 4. Các định dạng chuỗi phổ biến: dd/MM/yyyy, dd-MM-yyyy, ...
  ///
  /// Nếu [isMilliseconds] được truyền vào, tham số này sẽ được dùng làm quyết định cuối cùng
  /// cho việc parse timestamp dạng số. Nếu null, hàm sẽ dùng logic heuristic tự động đoán.
  static const List<String> _dateFormats = [
    // Ưu tiên các định dạng có Giờ:Phút:Giây trước
    'dd/MM/yyyy HH:mm:ss',
    'dd-MM-yyyy HH:mm:ss',
    'yyyy/MM/dd HH:mm:ss',
    'yyyy-MM-dd HH:mm:ss',
    // Các định dạng chỉ có Giờ:Phút (Rất hay gặp)
    'dd/MM/yyyy HH:mm',
    'dd-MM-yyyy HH:mm',
    'yyyy/MM/dd HH:mm',
    'yyyy-MM-dd HH:mm',
    // Các định dạng chỉ có Ngày
    'dd/MM/yyyy',
    'dd-MM-yyyy',
    'yyyy/MM/dd',
    'yyyy-MM-dd',
  ];

  static DateTime? asDate(
    dynamic value, {
    DateTime? defaultValue,
    bool? isMilliseconds,
  }) {
    if (value == null) return defaultValue;
    if (value is DateTime) return value;

    if (value is num) {
      return asTimestampToDate(value, isMilliseconds: isMilliseconds) ??
          defaultValue;
    }

    final valueStr = value.toString();
    if (valueStr.isEmpty) return defaultValue;

    // Thử parse nếu chuỗi là số (timestamp)
    final numValue = num.tryParse(valueStr);
    if (numValue != null) {
      return asDate(
        numValue,
        defaultValue: defaultValue,
        isMilliseconds: isMilliseconds,
      );
    }

    // 1. Thử parse ISO (YYYY-MM-DD...)
    final iso = DateTime.tryParse(valueStr);
    if (iso != null) return iso;

    // 2. Thử các định dạng khác
    for (final format in _dateFormats) {
      try {
        return DateFormat(format).parse(valueStr);
      } catch (_) {}
    }

    return defaultValue;
  }

  static Map<String, dynamic> asMap(
    dynamic value, {
    Map<String, dynamic> defaultValue = const {},
  }) {
    return asMapOrNull(value) ?? defaultValue;
  }

  static Map<String, dynamic>? asMapOrNull(dynamic value) {
    return _convertToMapOrNull(value);
  }

  static Map<String, dynamic>? _convertToMapOrNull(dynamic value) {
    try {
      if (value is Map<String, dynamic>) {
        return Map<String, dynamic>.from(value);
      }
      if (value is Map<dynamic, dynamic>) {
        return <String, dynamic>{
          for (final key in value.keys)
            if (key is String)
              key: value[key]
            else if (key != null)
              key.toString(): value[key]
        };
      }
      return value as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  static List<Map<String, dynamic>> asListMap(dynamic value,
      {List<Map<String, dynamic>> defaultValue = const []}) {
    return asList<Map<String, dynamic>>(
      value,
      defaultValue: defaultValue,
      converter: (value) {
        return asMap(value);
      },
    );
  }

  static List<Map<String, dynamic>>? asListMapOrNull(dynamic value) {
    return asListOrNull<Map<String, dynamic>>(
      value,
      converter: (value) {
        return asMap(value);
      },
    );
  }

  static List<String> asListString(
    dynamic value, {
    List<String> defaultValue = const [],
  }) {
    return asList<String>(
      value,
      defaultValue: defaultValue,
      converter: (value) => value.toString(),
    );
  }

  static List<String>? asListStringOrNull(dynamic value) {
    return asListOrNull<String>(
      value,
      converter: (value) => value.toString(),
    );
  }

  static List<T> asList<T>(
    dynamic value, {
    List<T> defaultValue = const [],
    T Function(dynamic)? converter,
  }) {
    return asListOrNull<T>(value, converter: converter) ?? defaultValue;
  }

  static List<T>? asListOrNull<T>(
    dynamic value, {
    T Function(dynamic)? converter,
  }) {
    try {
      if (value is List<T>) {
        return List<T>.from(value);
      }
      if (value is List<dynamic>) {
        try {
          final result = List<T>.from(value);
          return result;
        } catch (_) {}

        if (converter != null) {
          return value.map(
            (e) {
              if (e is T) {
                return e;
              }

              return converter(e);
            },
          ).toList();
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static T? asRaw<T>(dynamic value, {T? defaultValue}) {
    try {
      return value as T;
    } catch (e) {
      return defaultValue;
    }
  }
}
