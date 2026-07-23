import 'package:flutter/foundation.dart';

/// Thin wrapper over [defaultTargetPlatform] so features never check the raw
/// platform enum inline. Web is reported through [kIsWeb] first, so the mobile
/// getters stay false on web builds even when the underlying host is a phone.
class PlatformUtils {
  const PlatformUtils._();

  /// Running on the web (no native platform).
  static bool get isWeb => kIsWeb;

  /// Native iOS (never true on web).
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Native Android (never true on web).
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Native macOS (never true on web).
  static bool get isMacOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  /// Apple platforms (iOS or macOS), where Apple sign-in is offered.
  static bool get isApple => isIOS || isMacOS;
}
