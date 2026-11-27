// Ported from d3-array v3.2.4 test/deviation-test.js (ISC, Mike Bostock).

import 'dart:math' as math;

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

({T value}) _box<T>(T value) => (value: value);

T _unbox<T>(({T value}) box) => box.value;

void main() {
  test(
    'deviation(array) returns the standard deviation of the specified numbers',
    () {
      expect(deviation([1, 1, 1, 1, 1]), 0);
      expect(deviation([5, 1, 2, 3, 4]), math.sqrt(2.5));
      expect(deviation([20, 3]), math.sqrt(144.5));
      expect(deviation([3, 20]), math.sqrt(144.5));
    },
  );

  test('deviation(array) ignores null, undefined and NaN', () {
    expect(deviation([double.nan, 1, 2, 3, 4, 5]), math.sqrt(2.5));
    expect(deviation([1, 2, 3, 4, 5, double.nan]), math.sqrt(2.5));
    expect(deviation([10, null, 3, null, 5, double.nan]), math.sqrt(13));
  });

  test('deviation(array) can handle large numbers without overflowing', () {
    expect(deviation([double.maxFinite, double.maxFinite]), 0);
    expect(deviation([-double.maxFinite, -double.maxFinite]), 0);
  });

  test('deviation(array) returns undefined if the array '
      'has fewer than two numbers', () {
    expect(deviation([1]), isNull);
    expect(deviation([]), isNull);
    expect(deviation([null]), isNull);
    expect(deviation([double.nan]), isNull);
    expect(deviation([double.nan, double.nan]), isNull);
  });

  test(
    'deviation(array, f) returns the deviation of the specified numbers',
    () {
      expect(deviationBy([5, 1, 2, 3, 4].map(_box), _unbox), math.sqrt(2.5));
      expect(deviationBy([20, 3].map(_box), _unbox), math.sqrt(144.5));
      expect(deviationBy([3, 20].map(_box), _unbox), math.sqrt(144.5));
    },
  );

  test('deviation(array, f) ignores null, undefined and NaN', () {
    expect(
      deviationBy<({num? value})>(
        [double.nan, 1, 2, 3, 4, 5].map(_box),
        _unbox,
      ),
      math.sqrt(2.5),
    );
    expect(
      deviationBy<({num? value})>(
        [1, 2, 3, 4, 5, double.nan].map(_box),
        _unbox,
      ),
      math.sqrt(2.5),
    );
    expect(
      deviationBy<({num? value})>(
        [10, null, 3, null, 5, double.nan].map(_box),
        _unbox,
      ),
      math.sqrt(13),
    );
  });

  test('deviation(array, f) can handle large numbers without overflowing', () {
    expect(
      deviationBy([double.maxFinite, double.maxFinite].map(_box), _unbox),
      0,
    );
    expect(
      deviationBy([-double.maxFinite, -double.maxFinite].map(_box), _unbox),
      0,
    );
  });

  test('deviation(array, f) returns undefined if the array '
      'has fewer than two numbers', () {
    expect(deviationBy([1].map(_box), _unbox), isNull);
    expect(deviationBy<({num? value})>(<num?>[].map(_box), _unbox), isNull);
    expect(deviationBy<({num? value})>(<num?>[null].map(_box), _unbox), isNull);
    expect(
      deviationBy<({num? value})>(<num?>[double.nan].map(_box), _unbox),
      isNull,
    );
    expect(
      deviationBy<({num? value})>(
        <num?>[double.nan, double.nan].map(_box),
        _unbox,
      ),
      isNull,
    );
  });
}
