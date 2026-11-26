// Ported from d3-format v3.1.2 test/precisionRound-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_format_port/d3_format.dart';
import 'package:test/test.dart';

void main() {
  test('precisionRound(step, max) returns the expected value', () {
    expect(precisionRound(0.1, 1.1), 2); // "1.0", "1.1"
    expect(precisionRound(0.01, 0.99), 2); // "0.98", "0.99"
    expect(precisionRound(0.01, 1.00), 2); // "0.99", "1.0"
    expect(precisionRound(0.01, 1.01), 3); // "1.00", "1.01"
  });

  // DIVERGES(d3-format): adapt-format-typed-api, null instead of NaN
  test('precisionRound(0, max) returns NaN', () {
    expect(precisionRound(0, 1), isNull);
  });

  test('precisionRound(NaN, max) returns NaN', () {
    expect(precisionRound(double.nan, 1), isNull);
  });

  test('precisionRound(Infinity, max) returns NaN', () {
    expect(precisionRound(double.infinity, 1), isNull);
    expect(precisionRound(double.negativeInfinity, 1), isNull);
  });
}
