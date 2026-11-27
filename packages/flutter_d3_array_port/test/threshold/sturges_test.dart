// Ported from d3-array v3.2.4 test/threshold/sturges-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

void main() {
  test('thresholdSturges(values, min, max) returns the expected result', () {
    expect(thresholdSturges(<num>[4, 3, 2, 1, double.nan], 1, 4), 3);
    expect(thresholdSturges(<num>[1], 1, 4), 1);
  });

  test('thresholdSturges(values, min, max) handles empty arrays', () {
    expect(thresholdSturges(<num>[], 1, 4), 1);
  });
}
