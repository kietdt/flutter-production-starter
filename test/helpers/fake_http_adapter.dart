import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Answers every Dio request with [respond] and records what was asked, so
/// tests drive the real NetworkClient + interceptors without a server.
class FakeHttpAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) respond;
  final List<RequestOptions> requests = [];

  FakeHttpAdapter({required this.respond});

  List<String> get paths => [for (final r in requests) r.path];

  int callsTo(String path) => paths.where((p) => p == path).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

/// A JSON response body with [statusCode].
ResponseBody jsonResponse(int statusCode, Map<String, dynamic> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
