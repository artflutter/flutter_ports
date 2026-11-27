// Ported from d3-array v3.2.4 test/threshold/freedmanDiaconic-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

void main() {
  test(
    'thresholdFreedmanDiaconis(values, min, max) returns the expected result',
    () {
      expect(thresholdFreedmanDiaconis(<num>[4, 3, 2, 1, double.nan], 1, 4), 2);
    },
  );

  test('thresholdFreedmanDiaconis(values, min, max) handles values with zero '
      'deviation', () {
    expect(thresholdFreedmanDiaconis(<num>[1, 1, 1, 1], 1, 4), 1);
  });

  test(
    'thresholdFreedmanDiaconis(values, min, max) handles single-value arrays',
    () {
      expect(thresholdFreedmanDiaconis(<num>[1], 1, 4), 1);
    },
  );

  test('thresholdFreedmanDiaconis(values, min, max) handles empty arrays', () {
    expect(thresholdFreedmanDiaconis(<num>[], 1, 4), 1);
  });
}
