// Ported from d3-array v3.2.4 test/fsum-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

({T value}) _box<T>(T value) => (value: value);

T _unbox<T>(({T value}) box) => box.value;

void main() {
  test('new Adder() returns an Adder', () {
    final adder = Adder();
    expect(adder, isA<Adder>());
    expect(adder.add, isA<Adder Function(double)>());
    expect(adder.valueOf, isA<double Function()>());
  });

  test('+adder can be applied several times', () {
    final adder = Adder();
    for (var i = 0; i < 10; ++i) {
      adder.add(0.1);
    }
    expect(adder.valueOf(), 1);
    expect(adder.valueOf(), 1);
  });

  test('fsum(array) is an exact sum', () {
    expect(fsum([0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1]), 1);
    expect(
      fsum([
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
    expect(fsumBy([20, 3].map(_box), _unbox), 23);
  });

  test('fsum(array) returns the fsum of the specified numbers', () {
    expect(fsum([1]), 1);
    expect(fsum([5, 1, 2, 3, 4]), 15);
    expect(fsum([20, 3]), 23);
    expect(fsum([3, 20]), 23);
  });

  test(
    'fsum(array) observes values that can be coerced to numbers',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'fsum(array) ignores non-numeric values',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('fsum(array) ignores null, undefined and NaN', () {
    expect(fsum([double.nan, 1, 2, 3, 4, 5]), 15);
    expect(fsum([1, 2, 3, 4, 5, double.nan]), 15);
    expect(fsum([10, null, 3, null, 5, double.nan]), 18);
  });

  test('fsum(array) returns zero if there are no numbers', () {
    expect(fsum([]), 0);
    expect(fsum([double.nan]), 0);
    expect(fsum([null]), 0);
    expect(fsum([null, double.nan]), 0);
    // Non-numeric {} omitted: adapt-array-typed-api.
  });

  test('fsum(array, f) returns the fsum of the specified numbers', () {
    expect(fsumBy([1].map(_box), _unbox), 1);
    expect(fsumBy([5, 1, 2, 3, 4].map(_box), _unbox), 15);
    expect(fsumBy([20, 3].map(_box), _unbox), 23);
    expect(fsumBy([3, 20].map(_box), _unbox), 23);
  });

  test(
    'fsum(array, f) observes values that can be coerced to numbers',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'fsum(array, f) ignores non-numeric values',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('fsum(array, f) ignores null, undefined and NaN', () {
    expect(
      fsumBy<({num? value})>([double.nan, 1, 2, 3, 4, 5].map(_box), _unbox),
      15,
    );
    expect(
      fsumBy<({num? value})>([1, 2, 3, 4, 5, double.nan].map(_box), _unbox),
      15,
    );
    expect(
      fsumBy<({num? value})>(
        [10, null, 3, null, 5, double.nan].map(_box),
        _unbox,
      ),
      18,
    );
  });

  test('fsum(array, f) returns zero if there are no numbers', () {
    expect(fsumBy<({num? value})>(<num?>[].map(_box), _unbox), 0);
    expect(fsumBy<({num? value})>(<num?>[double.nan].map(_box), _unbox), 0);
    expect(fsumBy<({num? value})>(<num?>[null].map(_box), _unbox), 0);
    expect(
      fsumBy<({num? value})>(<num?>[null, double.nan].map(_box), _unbox),
      0,
    );
    // Non-numeric {} omitted: adapt-array-typed-api.
  });

  test('fsum(array, f) passes the accessor d, i, and array', () {
    final results = <(String, int, Iterable<String>)>[];
    const array = ['a', 'b', 'c'];
    fsumByIndexed(array, (d, i, a) {
      results.add((d, i, a));
      return null;
    });
    expect(results, [('a', 0, array), ('b', 1, array), ('c', 2, array)]);
  });

  test(
    'fsum(array, f) uses the undefined context',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );
}
