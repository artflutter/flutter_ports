// Ported from d3-array v3.2.4 test/fcumsum-test.js (ISC, Mike Bostock).

import 'dart:typed_data';

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

({T value}) _box<T>(T value) => (value: value);

T _unbox<T>(({T value}) box) => box.value;

double _lastc(Iterable<num?> values) {
  final array = fcumsum(values);
  return array[array.length - 1];
}

double _lastcBy<T>(Iterable<T> values, num? Function(T value) valueof) {
  final array = fcumsumBy(values, valueof);
  return array[array.length - 1];
}

void main() {
  test('fcumsum(array) returns a Float64Array of the expected length', () {
    const a = [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1];
    final r = fcumsum(a);
    expect(r, isA<Float64List>());
    expect(r.length, a.length);
  });

  test('fcumsum(array) is an exact cumsum', () {
    expect(_lastc([0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1]), 1);
    expect(
      _lastc([
        0.3,
        0.3,
        0.3,
        0.3,
        0.3,
        0.3,
        0.3,
        0.3,
        0.3,
        0.3,
        -0.3,
        -0.3,
        -0.3,
        -0.3,
        -0.3,
        -0.3,
        -0.3,
        -0.3,
        -0.3,
        -0.3,
      ]),
      0,
    );
    // String coercion ["20", "3"] omitted: adapt-array-typed-api.
    expect(_lastcBy([20, 3].map(_box), _unbox), 23);
  });

  test('fcumsum(array) returns the fsum of the specified numbers', () {
    expect(_lastc([1]), 1);
    expect(_lastc([5, 1, 2, 3, 4]), 15);
    expect(_lastc([20, 3]), 23);
    expect(_lastc([3, 20]), 23);
  });

  test(
    'fcumsum(array) observes values that can be coerced to numbers',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'fcumsum(array) ignores non-numeric values',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('fcumsum(array) ignores null, undefined and NaN', () {
    expect(_lastc([double.nan, 1, 2, 3, 4, 5]), 15);
    expect(_lastc([1, 2, 3, 4, 5, double.nan]), 15);
    expect(_lastc([10, null, 3, null, 5, double.nan]), 18);
  });

  test('fcumsum(array) returns an array of zeros if there are no numbers', () {
    expect(fcumsum([]), isEmpty);
    expect(fcumsum([double.nan]), [0]);
    expect(fcumsum([null]), [0]);
    expect(fcumsum([null, double.nan]), [0, 0]);
    // Non-numeric {} omitted: adapt-array-typed-api.
  });

  test('fcumsum(array, f) returns the fsum of the specified numbers', () {
    expect(_lastcBy([1].map(_box), _unbox), 1);
    expect(_lastcBy([5, 1, 2, 3, 4].map(_box), _unbox), 15);
    expect(_lastcBy([20, 3].map(_box), _unbox), 23);
    expect(_lastcBy([3, 20].map(_box), _unbox), 23);
  });

  test(
    'fcumsum(array, f) observes values that can be coerced to numbers',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'fcumsum(array, f) ignores non-numeric values',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('fcumsum(array, f) ignores null, undefined and NaN', () {
    expect(
      _lastcBy<({num? value})>([double.nan, 1, 2, 3, 4, 5].map(_box), _unbox),
      15,
    );
    expect(
      _lastcBy<({num? value})>([1, 2, 3, 4, 5, double.nan].map(_box), _unbox),
      15,
    );
    expect(
      _lastcBy<({num? value})>(
        [10, null, 3, null, 5, double.nan].map(_box),
        _unbox,
      ),
      18,
    );
  });

  test('fcumsum(array, f) returns zero if there are no numbers', () {
    expect(fcumsumBy<({num? value})>(<num?>[].map(_box), _unbox), isEmpty);
    expect(fcumsumBy<({num? value})>(<num?>[double.nan].map(_box), _unbox), [
      0,
    ]);
    expect(fcumsumBy<({num? value})>(<num?>[null].map(_box), _unbox), [0]);
    expect(
      fcumsumBy<({num? value})>(<num?>[null, double.nan].map(_box), _unbox),
      [0, 0],
    );
    // Non-numeric {} omitted: adapt-array-typed-api.
  });

  test('fcumsum(array, f) passes the accessor d, i, and array', () {
    final results = <(String, int, Iterable<String>)>[];
    const array = ['a', 'b', 'c'];
    fcumsumByIndexed(array, (d, i, a) {
      results.add((d, i, a));
      return null;
    });
    expect(results, [('a', 0, array), ('b', 1, array), ('c', 2, array)]);
  });

  test(
    'fcumsum(array, f) uses the undefined context',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );
}
