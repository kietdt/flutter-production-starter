// #5 — LoggingInterceptor is opt-in and always runs after AuthInterceptor, so
// it sees the final (Authorization-carrying) headers and redacts them.

import 'package:dio/dio.dart';
import 'package:flutter_production_starter/core/network/interceptors/auth_interceptor.dart';
import 'package:flutter_production_starter/core/network/interceptors/logging_interceptor.dart';
import 'package:flutter_production_starter/core/network/network_client.dart';
import 'package:flutter_production_starter/core/network/token_management.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/in_memory_token_storage.dart';

void main() {
  List<Interceptor> interceptorsOf({required bool enableLogging}) {
    final NetworkClient client = NetworkClient(
      baseUrl: 'https://api.test',
      tokenManagement: TokenManagement(
        storage: InMemoryTokenStorage(),
        refresher: (_) => throw UnimplementedError(),
      ),
      onUnauthorized: () {},
      enableLogging: enableLogging,
    );
    // Dio always prepends its internal ImplyContentTypeInterceptor; ignore it.
    return client.dio.interceptors
        .where((i) => i is AuthInterceptor || i is LoggingInterceptor)
        .toList();
  }

  test('does not add LoggingInterceptor when logging is disabled', () {
    expect(
      interceptorsOf(enableLogging: false),
      [isA<AuthInterceptor>()],
    );
  });

  test('adds LoggingInterceptor after AuthInterceptor when enabled', () {
    expect(
      interceptorsOf(enableLogging: true),
      [isA<AuthInterceptor>(), isA<LoggingInterceptor>()],
    );
  });
}
