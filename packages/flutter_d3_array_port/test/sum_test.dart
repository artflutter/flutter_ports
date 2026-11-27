// Ported from d3-array v3.2.4 test/sum-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

({T value}) _box<T>(T value) => (value: value);

T _unbox<T>(({T value}) box) => box.value;

void main() {
  test('sum(array) returns the sum of the specified numbers', () {
    expect(sum([1]), 1);
    expect(sum([5, 1, 2, 3, 4]), 15);
    expect(sum([20, 3]), 23);
    expect(sum([3, 20]), 23);
  });

  test(
    'sum(array) observes values that can be coerced to numbers',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'sum(array) ignores non-numeric values',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('sum(array) ignores null, undefined and NaN', () {
    expect(sum([double.nan, 1, 2, 3, 4, 5]), 15);
    expect(sum([1, 2, 3, 4, 5, double.nan]), 15);
    expect(sum([10, null, 3, null, 5, double.nan]), 18);
  });

  test('sum(array) returns zero if there are no numbers', () {
    expect(sum([]), 0);
    expect(sum([double.nan]), 0);
    expect(sum([null]), 0);
    expect(sum([null, double.nan]), 0);
    // Non-numeric {} omitted: adapt-array-typed-api.
  });

  test('sum(array, f) returns the sum of the specified numbers', () {
    expect(sumBy([1].map(_box), _unbox), 1);
    expect(sumBy([5, 1, 2, 3, 4].map(_box), _unbox), 15);
    expect(sumBy([20, 3].map(_box), _unbox), 23);
    expect(sumBy([3, 20].map(_box), _unbox), 23);
  });

  test(
    'sum(array, f) observes values that can be coerced to numbers',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'sum(array, f) ignores non-numeric values',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('sum(array, f) ignores null, undefined and NaN', () {
    expect(
      sumBy<({num? value})>([double.nan, 1, 2, 3, 4, 5].map(_box), _unbox),
      15,
    );
    expect(
      sumBy<({num? value})>([1, 2, 3, 4, 5, double.nan].map(_box), _unbox),
      15,
    );
    expect(
      sumBy<({num? value})>(
        [10, null, 3, null, 5, double.nan].map(_box),
        _unbox,
      ),
      18,
    );
  });

  test('sum(array, f) returns zero if there are no numbers', () {
    expect(sumBy<({num? value})>(<num?>[].map(_box), _unbox), 0);
    expect(sumBy<({num? value})>(<num?>[double.nan].map(_box), _unbox), 0);
    expect(sumBy<({num? value})>(<num?>[null].map(_box), _unbox), 0);
    expect(
      sumBy<({num? value})>(<num?>[null, double.nan].map(_box), _unbox),
      0,
    );
    // Non-numeric {} omitted: adapt-array-typed-api.
  });

  test('sum(array, f) passes the accessor d, i, and array', () {
    final results = <(String, int, Iterable<String>)>[];
    const array = ['a', 'b', 'c'];
    sumByIndexed(array, (d, i, a) {
      results.add((d, i, a));
      return null;
    });
    expect(results, [('a', 0, array), ('b', 1, array), ('c', 2, array)]);
  });

  test(
    'sum(array, f) uses the undefined context',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );
}
