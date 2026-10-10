// Unit tests for LogRedactor (#5) — secrets must never reach the network log.

import 'package:dio/dio.dart';
import 'package:flutter_production_starter/core/network/log_redactor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mask = LogRedactor.mask;

  test('masks sensitive keys in a flat map and keeps the rest', () {
    final Object? result = LogRedactor.redact({
      'email': 'a@b.com',
      'password': 'secret',
      'accessToken': 'at',
      'refreshToken': 'rt',
      'token': 't',
    });

    expect(result, {
      'email': 'a@b.com',
      'password': mask,
      'accessToken': mask,
      'refreshToken': mask,
      'token': mask,
    });
  });

  test('matches keys case-insensitively and across snake/kebab case', () {
    final Object? result = LogRedactor.redact({
      'Authorization': 'Bearer at',
      'access_token': 'at',
      'REFRESH-TOKEN': 'rt',
      'Password': 'secret',
    });

    expect(result, {
      'Authorization': mask,
      'access_token': mask,
      'REFRESH-TOKEN': mask,
      'Password': mask,
    });
  });

  test('masks keys inside nested maps and lists', () {
    final Object? result = LogRedactor.redact({
      'data': {
        'user': {'id': 1, 'email': 'a@b.com'},
        'accessToken': 'at',
        'sessions': [
          {'refreshToken': 'rt1', 'device': 'ios'},
          {'refreshToken': 'rt2', 'device': 'android'},
        ],
      },
    });

    expect(result, {
      'data': {
        'user': {'id': 1, 'email': 'a@b.com'},
        'accessToken': mask,
        'sessions': [
          {'refreshToken': mask, 'device': 'ios'},
          {'refreshToken': mask, 'device': 'android'},
        ],
      },
    });
  });

  test('masks a sensitive key even when its value is a map or list', () {
    final Object? result = LogRedactor.redact({
      'token': {'value': 'at', 'expiresIn': 3600},
    });

    expect(result, {'token': mask});
  });

  test('redacts maps inside a top-level list', () {
    final Object? result = LogRedactor.redact([
      {'password': 'secret'},
      'plain',
      42,
    ]);

    expect(result, [
      {'password': mask},
      'plain',
      42,
    ]);
  });

  test('does not mutate the original data', () {
    final Map<String, dynamic> original = {
      'password': 'secret',
      'nested': {'token': 't'},
    };

    LogRedactor.redact(original);

    expect(original, {
      'password': 'secret',
      'nested': {'token': 't'},
    });
  });

  test('redacts FormData fields', () {
    final FormData form = FormData.fromMap({
      'email': 'a@b.com',
      'password': 'secret',
    });

    final Object? result = LogRedactor.redact(form);

    expect(result, {
      'email': 'a@b.com',
      'password': mask,
    });
  });

  test('passes through null and scalar values', () {
    expect(LogRedactor.redact(null), isNull);
    expect(LogRedactor.redact('plain text'), 'plain text');
    expect(LogRedactor.redact(42), 42);
  });
}
