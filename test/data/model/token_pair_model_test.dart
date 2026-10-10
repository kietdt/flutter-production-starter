// #12 — the refresh response is parsed through MapParser into a TokenPairModel.

import 'package:flutter_production_starter/core/network/token_pair.dart';
import 'package:flutter_production_starter/data/model/token_pair_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson reads both tokens and toEntity maps them to a TokenPair', () {
    final TokenPair pair = TokenPairModel.fromJson({
      'accessToken': 'a',
      'refreshToken': 'r',
    }).toEntity();

    expect(pair.accessToken, 'a');
    expect(pair.refreshToken, 'r');
  });

  test('missing fields fall back to empty strings', () {
    final TokenPairModel model = TokenPairModel.fromJson({});

    expect(model.accessToken, '');
    expect(model.refreshToken, '');
  });
}
