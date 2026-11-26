// Ported from d3-format v3.1.2 test/precisionPrefix-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_format_port/d3_format.dart';
import 'package:test/test.dart';

void main() {
  // A generalization from µ to all prefixes:
  // expect(precisionPrefix(1e-6, 1e-6), 0); // 1µ
  // expect(precisionPrefix(1e-6, 1e-7), 0); // 10µ
  // expect(precisionPrefix(1e-6, 1e-8), 0); // 100µ
  test(
    'precisionPrefix(step, value) returns zero if step has the same units as '
    'value',
    () {
      for (var i = -24; i <= 24; i += 3) {
        for (var j = i; j < i + 3; ++j) {
          expect(
            precisionPrefix(double.parse('1e$i'), double.parse('1e$j')),
            0,
          );
        }
      }
    },
  );

  // A generalization from µ to all prefixes:
  // expect(precisionPrefix(1e-9, 1e-6), 3); // 0.001µ
  // expect(precisionPrefix(1e-8, 1e-6), 2); // 0.01µ
  // expect(precisionPrefix(1e-7, 1e-6), 1); // 0.1µ
  test('precisionPrefix(step, value) returns greater than zero if fractional '
      'digits are needed', () {
    for (var i = -24; i <= 24; i += 3) {
      for (var j = i - 4; j < i; ++j) {
        expect(
          precisionPrefix(double.parse('1e$j'), double.parse('1e$i')),
          i - j,
        );
      }
    }
  });

  test(
    'precisionPrefix(step, value) returns the expected precision when value is '
    'less than one yocto',
    () {
      expect(precisionPrefix(1e-24, 1e-24), 0); // 1y
      expect(precisionPrefix(1e-25, 1e-25), 1); // 0.1y
      expect(precisionPrefix(1e-26, 1e-26), 2); // 0.01y
      expect(precisionPrefix(1e-27, 1e-27), 3); // 0.001y
      expect(precisionPrefix(1e-28, 1e-28), 4); // 0.0001y
    },
  );

  test(
    'precisionPrefix(step, value) returns the expected precision when value is '
    'greater than than one yotta',
    () {
      expect(precisionPrefix(1e24, 1e24), 0); // 1Y
      expect(precisionPrefix(1e24, 1e25), 0); // 10Y
      expect(precisionPrefix(1e24, 1e26), 0); // 100Y
      expect(precisionPrefix(1e24, 1e27), 0); // 1000Y
      expect(precisionPrefix(1e23, 1e27), 1); // 1000.0Y
    },
  );

  // DIVERGES(d3-format): adapt-format-typed-api, null instead of NaN
  test('precisionPrefix(0, value) returns NaN', () {
    expect(precisionPrefix(0, 1), isNull);
  });

  test('precisionPrefix(NaN, value) returns NaN', () {
    expect(precisionPrefix(double.nan, 1), isNull);
  });

  test('precisionPrefix(Infinity, value) returns NaN', () {
    expect(precisionPrefix(double.infinity, 1), isNull);
    expect(precisionPrefix(double.negativeInfinity, 1), isNull);
  });
}
