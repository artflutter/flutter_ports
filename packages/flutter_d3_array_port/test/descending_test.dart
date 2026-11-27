// Ported from d3-array v3.2.4 test/descending-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

void main() {
  test('descending(a, b) returns a positive number if a < b', () {
    expect(descending<num>(0, 1), greaterThan(0));
    expect(descending('a', 'b'), greaterThan(0));
  });

  test('descending(a, b) returns a negative number if a > b', () {
    expect(descending<num>(1, 0), lessThan(0));
    expect(descending('b', 'a'), lessThan(0));
  });

  test('descending(a, b) returns zero if a >= b and a <= b', () {
    expect(descending<num>(0, 0), 0);
    expect(descending('a', 'a'), 0);
    // Cross-type ("0", 0) and (0, "0") omitted: adapt-array-typed-api.
  });

  test('descending(a, b) returns NaN if a and b are not comparable', () {
    expect(descending<num>(0, null), isNaN);
    expect(descending<num>(null, 0), isNaN);
    expect(descending<num>(null, null), isNaN);
    expect(descending<num>(0, double.nan), isNaN);
    expect(descending<num>(double.nan, 0), isNaN);
    expect(descending<num>(double.nan, double.nan), isNaN);
  });
}
