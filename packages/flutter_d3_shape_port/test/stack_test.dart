// Ported from d3-shape v3.2.0 test/stack-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

double _round6(double x) => (x * 1e6).roundToDouble() / 1e6;

void _expectSeries<D, K>(
  StackSeries<D, K> actual,
  List<(double, double)> pairs,
  List<D> data,
  K key,
  int index,
) {
  expect(actual.key, key);
  expect(actual.index, index);
  expect(actual.length, pairs.length);
  for (var i = 0; i < pairs.length; ++i) {
    expect(actual[i].y0, pairs[i].$1);
    expect(actual[i].y1, pairs[i].$2);
    expect(actual[i].data, data[i]);
  }
}

void main() {
  test('stack() has the expected defaults', () {
    final s = stack<Map<String, double>, String>();
    expect(s.keys(const []), isEmpty);
    expect(s.value({'foo': 42}, 'foo', 0, const []), 42);
    expect(s.order, stackOrderNone);
    expect(s.offset, stackOffsetNone);
  });

  test('stack(data) computes the stacked series for the given data', () {
    final s = stack<List<double>, int>(keys: [0, 1, 2, 3]);
    final data = <List<double>>[
      [1, 3, 5, 1],
      [2, 4, 2, 3],
      [1, 2, 4, 2],
    ];
    final result = s(data);
    expect(result, hasLength(4));
    _expectSeries(result[0], [(0, 1), (0, 2), (0, 1)], data, 0, 0);
    _expectSeries(result[1], [(1, 4), (2, 6), (1, 3)], data, 1, 1);
    _expectSeries(result[2], [(4, 9), (6, 8), (3, 7)], data, 2, 2);
    _expectSeries(result[3], [(9, 10), (8, 11), (7, 9)], data, 3, 3);
  });

  test('stack.keys(array) sets the array of constant keys', () {
    final s = stack<Object?, String>()..keysConst(['0.0', '2.0', '4.0']);
    expect(s.keys(const []), ['0.0', '2.0', '4.0']);
  });

  test('stack.keys(function) sets the key accessor function', () {
    final s = stack<Object?, String>()..keys = (_) => ['a', 'b', 'c'];
    expect(s.keys(const []), ['a', 'b', 'c']);
  });

  test(
    'stack(data, arguments…) passes the key accessor any additional arguments',
    () {},
    skip: 'diverges: adapt-shape-typed-api',
  );

  test('stack.value(number) sets the constant value', () {
    final s = stack<Object?, String>()..valueConst(42);
    expect(s.value(null, '', 0, const []), 42);
  });

  test('stack.value(function) sets the value accessor function', () {
    double v(Object? d, String k, int i, List<Object?> data) => 42;
    final s = stack<Object?, String>()..value = v;
    expect(s.value, v);
  });

  test('stack(data) passes the value accessor datum, key, index and data', () {
    ({
      Map<String, double> datum,
      String key,
      int index,
      List<Map<String, double>> data,
    })?
    actual;
    double v(
      Map<String, double> d,
      String k,
      int i,
      List<Map<String, double>> all,
    ) {
      actual = (datum: d, key: k, index: i, data: all);
      return 2;
    }

    final s = stack<Map<String, double>, String>(keys: ['foo'])..value = v;
    final data = [
      {'foo': 1.0},
    ];
    final result = s(data);
    _expectSeries(result[0], [(0, 2)], data, 'foo', 0);
    expect(actual, (datum: data[0], key: 'foo', index: 0, data: data));
  });

  test(
    'stack(data) coerces the return value of the value accessor to a number',
    () {},
    skip: 'diverges: adapt-shape-typed-api',
  );

  test('stack.order(null) is equivalent to stack.order(stackOrderNone)', () {
    final s = stack<Object?, String>()..order = null;
    expect(s.order, stackOrderNone);
  });

  test('stack.order(function) sets the order function', () {
    final s = stack<List<double>, int>(
      keys: [0, 1, 2, 3],
      order: stackOrderReverse,
    );
    final data = <List<double>>[
      [1, 3, 5, 1],
      [2, 4, 2, 3],
      [1, 2, 4, 2],
    ];
    expect(s.order, stackOrderReverse);
    final result = s(data);
    _expectSeries(result[0], [(9, 10), (9, 11), (8, 9)], data, 0, 3);
    _expectSeries(result[1], [(6, 9), (5, 9), (6, 8)], data, 1, 2);
    _expectSeries(result[2], [(1, 6), (3, 5), (2, 6)], data, 2, 1);
    _expectSeries(result[3], [(0, 1), (0, 3), (0, 2)], data, 3, 0);
  });

  test('stack.offset(null) is equivalent to stack.offset(stackOffsetNone)', () {
    final s = stack<Object?, String>()..offset = null;
    expect(s.offset, stackOffsetNone);
  });

  test('stack.offset(function) sets the offset function', () {
    final s = stack<List<double>, int>(
      keys: [0, 1, 2, 3],
      offset: stackOffsetExpand,
    );
    final data = <List<double>>[
      [1, 3, 5, 1],
      [2, 4, 2, 3],
      [1, 2, 4, 2],
    ];
    expect(s.offset, stackOffsetExpand);
    final result = s(data)
        .map(
          (series) => [
            for (final pt in series.points) [_round6(pt.y0), _round6(pt.y1)],
          ],
        )
        .toList();
    expect(result, [
      [
        [_round6(0 / 10), _round6(1 / 10)],
        [_round6(0 / 11), _round6(2 / 11)],
        [_round6(0 / 9), _round6(1 / 9)],
      ],
      [
        [_round6(1 / 10), _round6(4 / 10)],
        [_round6(2 / 11), _round6(6 / 11)],
        [_round6(1 / 9), _round6(3 / 9)],
      ],
      [
        [_round6(4 / 10), _round6(9 / 10)],
        [_round6(6 / 11), _round6(8 / 11)],
        [_round6(3 / 9), _round6(7 / 9)],
      ],
      [
        [_round6(9 / 10), _round6(10 / 10)],
        [_round6(8 / 11), _round6(11 / 11)],
        [_round6(7 / 9), _round6(9 / 9)],
      ],
    ]);
  });
}
