// Ported from d3-array v3.2.4 test/ascending-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

void main() {
  test('ascending(a, b) returns a negative number if a < b', () {
    expect(ascending<num>(0, 1), lessThan(0));
    expect(ascending('a', 'b'), lessThan(0));
  });

  test('ascending(a, b) returns a positive number if a > b', () {
    expect(ascending<num>(1, 0), greaterThan(0));
    expect(ascending('b', 'a'), greaterThan(0));
  });

  test('ascending(a, b) returns zero if a >= b and a <= b', () {
    expect(ascending<num>(0, 0), 0);
    expect(ascending('a', 'a'), 0);
    // Cross-type ("0", 0) and (0, "0") omitted: adapt-array-typed-api.
  });

  test('ascending(a, b) returns NaN if a and b are not comparable', () {
    expect(ascending<num>(0, null), isNaN);
    expect(ascending<num>(null, 0), isNaN);
    expect(ascending<num>(null, null), isNaN);
    expect(ascending<num>(0, double.nan), isNaN);
    expect(ascending<num>(double.nan, 0), isNaN);
    expect(ascending<num>(double.nan, double.nan), isNaN);
  });
}
