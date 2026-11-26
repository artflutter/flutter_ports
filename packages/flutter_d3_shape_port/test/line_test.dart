// Ported from d3-shape v3.2.0 test/line-test.js (ISC, Mike Bostock).

import 'dart:math' as math;

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('line() returns a default line shape', () {
    final l = line<List<double>>();
    expect(l.x([42, 34], 0, const []), 42);
    expect(l.y([42, 34], 0, const []), 34);
    expect(l.defined([42, 34], 0, const []), isTrue);
    expect(l.curve, curveLinear);
    expect(l.context, isNull);
    assertPathEqual(
      l([
        [0, 1],
        [2, 3],
        [4, 5],
      ]),
      'M0,1L2,3L4,5',
    );
  });

  test('line(x, y) sets x and y', () {
    double x(String d, int i, List<String> data) => 0;
    double y(String d, int i, List<String> data) => 0;
    expect(line<String>(x).x, x);
    expect(line<String>(x, y).y, y);
    final c = line<String>()
      ..xConst(3)
      ..yConst(2);
    expect(c.x('aa', 0, const []), 3);
    expect(c.y('aa', 0, const []), 2);
  });

  test('line.x(f)(data) passes d, i and data to the specified function f', () {
    final data = ['a', 'b'];
    final actual = <(String, int, List<String>)>[];
    (line<String>()
      ..x = (d, i, all) {
        actual.add((d, i, all));
        return 0;
      }
      ..yConst(0))(data);
    expect(actual, [('a', 0, data), ('b', 1, data)]);
  });

  test('line.y(f)(data) passes d, i and data to the specified function f', () {
    final data = ['a', 'b'];
    final actual = <(String, int, List<String>)>[];
    (line<String>()
      ..xConst(0)
      ..y = (d, i, all) {
        actual.add((d, i, all));
        return 0;
      })(data);
    expect(actual, [('a', 0, data), ('b', 1, data)]);
  });

  test(
    'line.defined(f)(data) passes d, i and data to the specified function f',
    () {
      final data = ['a', 'b'];
      final actual = <(String, int, List<String>)>[];
      (line<String>()
        ..xConst(0)
        ..yConst(0)
        ..defined = (d, i, all) {
          actual.add((d, i, all));
          return false;
        })(data);
      expect(actual, [('a', 0, data), ('b', 1, data)]);
    },
  );

  test('line.x(x)(data) observes the specified function', () {
    final l = line<({double x, double y})>()
      ..x = ((d, _, _) => d.x)
      ..y = ((d, _, _) => d.y);
    assertPathEqual(
      l([(x: 0, y: 1), (x: 2, y: 3), (x: 4, y: 5)]),
      'M0,1L2,3L4,5',
    );
  });

  test('line.x(x)(data) observes the specified constant', () {
    final l = line<double>()
      ..xConst(0)
      ..y = (d, _, _) => d;
    assertPathEqual(l([1, 3, 5]), 'M0,1L0,3L0,5');
  });

  test('line.y(y)(data) observes the specified function', () {
    final l = line<({double x, double y})>()
      ..x = ((d, _, _) => d.x)
      ..y = ((d, _, _) => d.y);
    assertPathEqual(
      l([(x: 0, y: 1), (x: 2, y: 3), (x: 4, y: 5)]),
      'M0,1L2,3L4,5',
    );
  });

  test('line.y(y)(data) observes the specified constant', () {
    final l = line<double>()
      ..x = ((d, _, _) => d)
      ..yConst(0);
    assertPathEqual(l([0, 2, 4]), 'M0,0L2,0L4,0');
  });

  test('line.curve(curve) sets the curve method', () {
    final l = line<List<double>>()..curve = curveLinearClosed;
    expect(l([]), isNull);
    assertPathEqual(
      l([
        [0, 1],
        [2, 3],
      ]),
      'M0,1L2,3Z',
    );
  });

  test('line.digits(digits) sets the maximum fractional digits', () {
    const points = <(double, double)>[(0, math.pi), (math.e, 4)];
    final l = line<(double, double)>();
    expect(l.digits, 3);
    expect(l(points), 'M0,3.142L2.718,4');
    l.digits = 6;
    expect(l.digits, 6);
    expect(l(points), 'M0,3.141593L2.718282,4');
    expect(line<(double, double)>()(points), 'M0,3.142L2.718,4');
    l.digits = null;
    expect(l.digits, isNull);
    expect(l(points), 'M0,3.141592653589793L2.718281828459045,4');
    expect(line<(double, double)>()(points), 'M0,3.142L2.718,4');
    l.digits = 3;
    expect(l.digits, 3);
    expect(l(points), 'M0,3.142L2.718,4');
  });
}
