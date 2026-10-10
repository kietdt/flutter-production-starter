// PlatformUtils maps the target platform onto simple getters.

import 'package:flutter/foundation.dart';
import 'package:flutter_production_starter/core/utils/platform_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('iOS is Apple, not Android', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    expect(PlatformUtils.isIOS, isTrue);
    expect(PlatformUtils.isAndroid, isFalse);
    expect(PlatformUtils.isMacOS, isFalse);
    expect(PlatformUtils.isApple, isTrue);
  });

  test('Android is neither iOS nor Apple', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    expect(PlatformUtils.isAndroid, isTrue);
    expect(PlatformUtils.isIOS, isFalse);
    expect(PlatformUtils.isApple, isFalse);
  });

  test('macOS is Apple', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    expect(PlatformUtils.isMacOS, isTrue);
    expect(PlatformUtils.isApple, isTrue);
  });

  test('native test runs are never web', () {
    expect(PlatformUtils.isWeb, isFalse);
  });
}
