// Ported from d3-array v3.2.4 test/greatest-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

typedef _Box = ({int value, int index});

List<_Box> _boxAll(List<int> values) => [
  for (var i = 0; i < values.length; ++i) (value: values[i], index: i),
];

int _ascendingValue(_Box a, _Box b) => a.value - b.value;
int _descendingValue(_Box a, _Box b) => b.value - a.value;

void main() {
  test('greatest(array) compares using natural order', () {
    expect(greatest([0, 1]), 1);
    expect(greatest([1, 0]), 1);
    expect(greatest(['10', '2']), '2');
    expect(greatest(['2', '10']), '2');
    expect(greatest([2, double.nan, 10]), 10);
    expect(greatest([10, 2, double.nan]), 10);
    expect(greatest([double.nan, 10, 2]), 10);
  });

  test(
    'greatest(array, compare) compares using the specified compare function',
    () {
      const a = (name: 'a');
      const b = (name: 'b');
      expect(greatestWith([a, b], (a, b) => a.name.compareTo(b.name)), (
        name: 'b',
      ));
      expect(greatest([1, 0], descending), 0);
      expect(greatest(['2', '10'], descending), '10');
      expect(greatest([2, double.nan, 10], descending), 2);
    },
  );

  test('greatest(array, accessor) uses the specified accessor function', () {
    const a = (name: 'a', v: 42.0);
    const b = (name: 'b', v: 0.42);
    expect(greatestBy([a, b], (d) => d.name), b);
    expect(greatestBy([a, b], (d) => d.v), a);
  });

  test('greatest(array) returns undefined if the array is empty', () {
    expect(greatest<num>(const []), isNull);
  });

  test(
    'greatest(array) returns undefined if the array contains only incomparable '
    'values',
    () {
      expect(greatest<double>([double.nan, null]), isNull);
      expect(
        greatestWith<double>([double.nan, double.nan], (a, b) => a - b),
        isNull,
      );
    },
  );

  test('greatest(array) returns the first of equal values', () {
    expect(
      greatestWith(_boxAll([2, 2, 1, 1, 0, 0, 0, 3, 0]), _descendingValue),
      (value: 0, index: 4),
    );
    expect(
      greatestWith(_boxAll([3, 2, 2, 1, 1, 0, 0, 0, 3, 0]), _ascendingValue),
      (value: 3, index: 0),
    );
  });

  test('greatest(array) ignores null and undefined', () {
    expect(greatest<num>([null, -2, null]), -2);
  });

  test('greatest(array, accessor) ignores null and undefined', () {
    expect(greatestBy<num?, num>([null, -2, null], (d) => d), -2);
  });
}
