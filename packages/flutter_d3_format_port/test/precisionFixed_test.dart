// Ported from d3-format v3.1.2 test/precisionFixed-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_format_port/d3_format.dart';
import 'package:test/test.dart';

void main() {
  test('precisionFixed(number) returns the expected value', () {
    expect(precisionFixed(8.9), 0);
    expect(precisionFixed(1.1), 0);
    expect(precisionFixed(0.89), 1);
    expect(precisionFixed(0.11), 1);
    expect(precisionFixed(0.089), 2);
    expect(precisionFixed(0.011), 2);
  });

  // DIVERGES(d3-format): adapt-format-typed-api, null instead of NaN
  test('precisionFixed(0) returns NaN', () {
    expect(precisionFixed(0), isNull);
  });

  test('precisionFixed(NaN) returns NaN', () {
    expect(precisionFixed(double.nan), isNull);
  });

  test('precisionFixed(Infinity) returns NaN', () {
    expect(precisionFixed(double.infinity), isNull);
    expect(precisionFixed(double.negativeInfinity), isNull);
  });
}
