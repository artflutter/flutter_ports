// Ported from d3-array v3.2.4 test/threshold/scott-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

void main() {
  test('thresholdScott(values, min, max) returns the expected result', () {
    expect(thresholdScott(<num>[4, 3, 2, 1, double.nan], 1, 4), 2);
  });

  test(
    'thresholdScott(values, min, max) handles values with zero deviation',
    () {
      expect(thresholdScott(<num>[1, 1, 1, 1], 1, 4), 1);
    },
  );

  test('thresholdScott(values, min, max) handles single-value arrays', () {
    expect(thresholdScott(<num>[1], 1, 4), 1);
  });

  test('thresholdScott(values, min, max) handles empty arrays', () {
    expect(thresholdScott(<num>[], 1, 4), 1);
  });
}
