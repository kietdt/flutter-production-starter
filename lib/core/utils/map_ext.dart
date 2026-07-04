import 'dart:core';

import 'parse_utils.dart';

extension MapParser on Map<dynamic, dynamic> {
  double parseDouble(String key, {double defaultValue = 0.0}) {
    return Parse.asDouble(this[key], defaultValue: defaultValue);
  }

  double? parseDoubleOrNull(String key) {
    return Parse.asDoubleOrNull(this[key]);
  }

  String parseString(String key, {String defaultValue = ""}) {
    return Parse.asString(this[key], defaultValue: defaultValue);
  }

  String? parseStringOrNull(String key) {
    return Parse.asStringOrNull(this[key]);
  }

  DateTime? parseSecondToDate(String key, {bool isUtc = false}) {
    return Parse.asSecondToDate(this[key], isUtc: isUtc);
  }

  bool parseBool(String key, {bool defaultValue = false}) {
    return Parse.asBool(this[key], defaultValue: defaultValue);
  }

  bool? parseBoolOrNull(String key) {
    return Parse.asBoolOrNull(this[key]);
  }

  DateTime? parseDateISO8601(String key) {
    return Parse.asDateISO8601(this[key]);
  }

  DateTime? parseDate(String key) {
    return Parse.asDate(this[key]);
  }

  int parseInt(String key, {int defaultValue = 0}) {
    return Parse.asInt(this[key], defaultValue: defaultValue);
  }

  int? parseIntOrNull(String key) {
    return Parse.asIntOrNull(this[key]);
  }

  Map<String, dynamic> parseMap(String key,
      {Map<String, dynamic>? defaultValue}) {
    return Parse.asMap(this[key],
        defaultValue: defaultValue ?? <String, dynamic>{});
  }

  Map<String, dynamic>? parseMapOrNull(String key) {
    return Parse.asMapOrNull(this[key]);
  }

  List<Map<String, dynamic>> parseListMap(String key,
      {List<Map<String, dynamic>>? defaultValue}) {
    return Parse.asListMap(this[key],
        defaultValue: defaultValue ?? <Map<String, dynamic>>[]);
  }

  List<Map<String, dynamic>>? parseListMapOrNull(String key) {
    return Parse.asListMapOrNull(this[key]);
  }

  List<String> parseListString(String key, {List<String>? defaultValue}) {
    return Parse.asListString(this[key],
        defaultValue: defaultValue ?? <String>[]);
  }

  List<String>? parseListStringOrNull(String key) {
    return Parse.asListStringOrNull(this[key]);
  }

  List<T> parseList<T>(
    String key, {
    List<T>? defaultValue,
    T Function(dynamic)? converter,
  }) {
    return Parse.asList<T>(
      this[key],
      defaultValue: defaultValue ?? <T>[],
      converter: converter,
    );
  }

  List<T>? parseListOrNull<T>(
    String key, {
    T Function(dynamic)? converter,
  }) {
    return Parse.asListOrNull<T>(this[key], converter: converter);
  }

  T? tryParseRaw<T>(String key, {T? defaultValue}) {
    return Parse.asRaw<T>(this[key], defaultValue: defaultValue);
  }
}
