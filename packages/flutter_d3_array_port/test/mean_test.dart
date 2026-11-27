// Ported from d3-array v3.2.4 test/mean-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

({T value}) _box<T>(T value) => (value: value);

T _unbox<T>(({T value}) box) => box.value;

void main() {
  test('mean(array) returns the mean value for numbers', () {
    expect(mean([1]), 1);
    expect(mean([5, 1, 2, 3, 4]), 3);
    expect(mean([20, 3]), 11.5);
    expect(mean([3, 20]), 11.5);
  });

  test('mean(array) ignores null, undefined and NaN', () {
    expect(mean([double.nan, 1, 2, 3, 4, 5]), 3);
    expect(mean([1, 2, 3, 4, 5, double.nan]), 3);
    expect(mean([10, null, 3, null, 5, double.nan]), 6);
  });

  test(
    'mean(array) returns undefined if the array contains no observed values',
    () {
      expect(mean([]), isNull);
      expect(mean([null]), isNull);
      expect(mean([double.nan]), isNull);
      expect(mean([double.nan, double.nan]), isNull);
    },
  );

  test(
    'mean(array) coerces values to numbers',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'mean(array) coerces values exactly once',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('mean(array, f) returns the mean value for numbers', () {
    expect(meanBy([1].map(_box), _unbox), 1);
    expect(meanBy([5, 1, 2, 3, 4].map(_box), _unbox), 3);
    expect(meanBy([20, 3].map(_box), _unbox), 11.5);
    expect(meanBy([3, 20].map(_box), _unbox), 11.5);
  });

  test('mean(array, f) ignores null, undefined and NaN', () {
    expect(
      meanBy<({num? value})>([double.nan, 1, 2, 3, 4, 5].map(_box), _unbox),
      3,
    );
    expect(
      meanBy<({num? value})>([1, 2, 3, 4, 5, double.nan].map(_box), _unbox),
      3,
    );
    expect(
      meanBy<({num? value})>(
        [10, null, 3, null, 5, double.nan].map(_box),
        _unbox,
      ),
      6,
    );
  });

  test(
    'mean(array, f) returns undefined if the array contains no observed values',
    () {
      expect(meanBy<({num? value})>(<num?>[].map(_box), _unbox), isNull);
      expect(meanBy<({num? value})>(<num?>[null].map(_box), _unbox), isNull);
      expect(
        meanBy<({num? value})>(<num?>[double.nan].map(_box), _unbox),
        isNull,
      );
      expect(
        meanBy<({num? value})>(
          <num?>[double.nan, double.nan].map(_box),
          _unbox,
        ),
        isNull,
      );
    },
  );

  test(
    'mean(array, f) coerces values to numbers',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'mean(array, f) coerces values exactly once',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('mean(array, f) passes the accessor d, i, and array', () {
    final results = <(String, int, Iterable<String>)>[];
    const strings = ['a', 'b', 'c'];
    meanByIndexed(strings, (d, i, array) {
      results.add((d, i, array));
      return null;
    });
    expect(results, [('a', 0, strings), ('b', 1, strings), ('c', 2, strings)]);
  });

  test(
    'mean(array, f) uses the undefined context',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );
}
