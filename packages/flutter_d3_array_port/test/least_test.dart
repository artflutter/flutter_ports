// Ported from d3-array v3.2.4 test/least-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

typedef _Box = ({int value, int index});

List<_Box> _boxAll(List<int> values) => [
  for (var i = 0; i < values.length; ++i) (value: values[i], index: i),
];

int _ascendingValue(_Box a, _Box b) => a.value - b.value;
int _descendingValue(_Box a, _Box b) => b.value - a.value;

void main() {
  test('least(array) compares using natural order', () {
    expect(least([0, 1]), 0);
    expect(least([1, 0]), 0);
    expect(least(['10', '2']), '10');
    expect(least(['2', '10']), '10');
    expect(least([2, double.nan, 10]), 2);
    expect(least([10, 2, double.nan]), 2);
    expect(least([double.nan, 10, 2]), 2);
  });

  test(
    'least(array, compare) compares using the specified compare function',
    () {
      const a = (name: 'a');
      const b = (name: 'b');
      expect(leastWith([a, b], (a, b) => a.name.compareTo(b.name)), (
        name: 'a',
      ));
      expect(least([1, 0], descending), 1);
      expect(least(['2', '10'], descending), '2');
      expect(least([2, double.nan, 10], descending), 10);
    },
  );

  test('least(array, accessor) uses the specified accessor function', () {
    const a = (name: 'a', v: 42.0);
    const b = (name: 'b', v: 0.42);
    expect(leastBy([a, b], (d) => d.name), a);
    expect(leastBy([a, b], (d) => d.v), b);
  });

  test('least(array) returns undefined if the array is empty', () {
    expect(least<num>(const []), isNull);
  });

  test('least(array) returns undefined if the array contains only incomparable '
      'values', () {
    expect(least<double>([double.nan, null]), isNull);
    expect(
      leastWith<double>([double.nan, double.nan], (a, b) => a - b),
      isNull,
    );
  });

  test('least(array) returns the first of equal values', () {
    expect(leastWith(_boxAll([2, 2, 1, 1, 0, 0, 0, 3, 0]), _ascendingValue), (
      value: 0,
      index: 4,
    ));
    expect(
      leastWith(_boxAll([3, 2, 2, 1, 1, 0, 0, 0, 3, 0]), _descendingValue),
      (value: 3, index: 0),
    );
  });

  test('least(array) ignores null and undefined', () {
    expect(least<num>([null, 2, null]), 2);
  });

  test('least(array, accessor) ignores null and undefined', () {
    expect(leastBy<num?, num>([null, 2, null], (d) => d), 2);
  });
}
