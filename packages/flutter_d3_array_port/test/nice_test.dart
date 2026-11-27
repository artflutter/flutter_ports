// Ported from d3-array v3.2.4 test/nice-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

void _expectPair((double, double) actual, (double, double) expected) {
  if (expected.$1.isNaN) {
    expect(actual.$1.isNaN, isTrue);
  } else {
    expect(actual.$1, expected.$1);
  }
  if (expected.$2.isNaN) {
    expect(actual.$2.isNaN, isTrue);
  } else {
    expect(actual.$2, expected.$2);
  }
}

void main() {
  test(
    'nice(start, stop, count) returns [start, stop] if any argument is NaN',
    () {
      _expectPair(nice(double.nan, 1, 1), (double.nan, 1));
      _expectPair(nice(0, double.nan, 1), (0, double.nan));
      _expectPair(nice(0, 1, double.nan), (0, 1));
      _expectPair(nice(double.nan, double.nan, 1), (double.nan, double.nan));
      _expectPair(nice(0, double.nan, double.nan), (0, double.nan));
      _expectPair(nice(double.nan, 1, double.nan), (double.nan, 1));
      _expectPair(nice(double.nan, double.nan, double.nan), (
        double.nan,
        double.nan,
      ));
    },
  );

  test('nice(start, stop, count) returns [start, stop] if start === stop', () {
    expect(nice(1, 1, -1), (1.0, 1.0));
    expect(nice(1, 1, 0), (1.0, 1.0));
    expect(nice(1, 1, double.nan), (1.0, 1.0));
    expect(nice(1, 1, 1), (1.0, 1.0));
    expect(nice(1, 1, 10), (1.0, 1.0));
  });

  test(
    'nice(start, stop, count) returns [start, stop] if count is not positive',
    () {
      expect(nice(0, 1, -1), (0.0, 1.0));
      expect(nice(0, 1, 0), (0.0, 1.0));
    },
  );

  test(
    'nice(start, stop, count) returns [start, stop] if count is infinity',
    () {
      expect(nice(0, 1, double.infinity), (0.0, 1.0));
    },
  );

  test('nice(start, stop, count) returns the expected values', () {
    expect(nice(0.132, 0.876, 1000), (0.132, 0.876));
    expect(nice(0.132, 0.876, 100), (0.13, 0.88));
    expect(nice(0.132, 0.876, 30), (0.12, 0.88));
    expect(nice(0.132, 0.876, 10), (0.1, 0.9));
    expect(nice(0.132, 0.876, 6), (0.1, 0.9));
    expect(nice(0.132, 0.876, 5), (0.0, 1.0));
    expect(nice(0.132, 0.876, 1), (0.0, 1.0));
    expect(nice(132, 876, 1000), (132.0, 876.0));
    expect(nice(132, 876, 100), (130.0, 880.0));
    expect(nice(132, 876, 30), (120.0, 880.0));
    expect(nice(132, 876, 10), (100.0, 900.0));
    expect(nice(132, 876, 6), (100.0, 900.0));
    expect(nice(132, 876, 5), (0.0, 1000.0));
    expect(nice(132, 876, 1), (0.0, 1000.0));
  });
}
