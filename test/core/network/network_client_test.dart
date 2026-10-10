// #16 — NetworkClient flags each request for AuthInterceptor without mutating
// the Options the caller passed in.

import 'package:dio/dio.dart';
import 'package:flutter_production_starter/core/network/network_client.dart';
import 'package:flutter_production_starter/core/network/request_extra_keys.dart';
import 'package:flutter_production_starter/core/network/token_management.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/in_memory_token_storage.dart';

void main() {
  late FakeHttpAdapter adapter;
  late NetworkClient client;

  setUp(() {
    adapter = FakeHttpAdapter(
      respond: (_) async => jsonResponse(200, {'ok': true}),
    );
    client = NetworkClient(
      baseUrl: 'https://api.test',
      tokenManagement: TokenManagement(
        storage: InMemoryTokenStorage(),
        refresher: (_) => throw UnimplementedError(),
      ),
      onUnauthorized: () {},
    );
    client.dio.httpClientAdapter = adapter;
  });

  test('flags every request with requiresAuth, keeping caller extras',
      () async {
    final Options options = Options(extra: {'trace': 'abc'});

    await client.get<Map<String, dynamic>>('/a', options: options);
    await client.post<Map<String, dynamic>>(
      '/b',
      options: options,
      requiresAuth: false,
    );

    expect(adapter.requests[0].extra[RequestExtraKeys.requiresAuth], isTrue);
    expect(adapter.requests[0].extra['trace'], 'abc');
    expect(adapter.requests[1].extra[RequestExtraKeys.requiresAuth], isFalse);
    expect(adapter.requests[1].extra['trace'], 'abc');
  });

  test('does not mutate the Options the caller passed in', () async {
    final Options options = Options(extra: {'trace': 'abc'});

    await client.get<Map<String, dynamic>>('/a', options: options);

    expect(options.extra, {'trace': 'abc'});
  });
}
