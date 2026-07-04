// Unit tests for AppConfig (GĐ 3.2) — per-flavor build configuration.

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_production_starter/core/config/app_config.dart';

void main() {
  test('fromFlavor maps each flavor to its own base URL', () {
    expect(
      AppConfig.fromFlavor(Flavor.dev).baseUrl,
      'http://localhost:8080',
    );
    expect(
      AppConfig.fromFlavor(Flavor.staging).baseUrl,
      'https://staging.api.example.com',
    );
    expect(
      AppConfig.fromFlavor(Flavor.prod).baseUrl,
      'https://api.example.com',
    );
  });

  test('isProd is true only for the prod flavor', () {
    expect(AppConfig.fromFlavor(Flavor.prod).isProd, isTrue);
    expect(AppConfig.fromFlavor(Flavor.dev).isProd, isFalse);
    expect(AppConfig.fromFlavor(Flavor.staging).isProd, isFalse);
  });

  test('instance defaults to the dev flavor when init was never called', () {
    // A fresh isolate runs this file, so no earlier init() has pinned a config.
    expect(AppConfig.instance.flavor, Flavor.dev);
  });

  test('init pins the active configuration', () {
    AppConfig.init(AppConfig.fromFlavor(Flavor.prod));
    expect(AppConfig.instance.flavor, Flavor.prod);
    expect(AppConfig.instance.baseUrl, 'https://api.example.com');
  });
}
