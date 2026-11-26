// Ported from d3-shape v3.2.0 test/area-test.js (ISC, Mike Bostock).
// Expected SVG path literals stay on single lines for readability.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('area() returns a default area shape', () {
    final a = area<List<double>>();
    expect(a.x0([42, 34], 0, const []), 42);
    expect(a.x1, isNull);
    expect(a.y0([42, 34], 0, const []), 0);
    expect(a.y1!([42, 34], 0, const []), 34);
    expect(a.defined([42, 34], 0, const []), isTrue);
    expect(a.curve, curveLinear);
    expect(a.context, isNull);
    assertPathEqual(
      a([
        [0, 1],
        [2, 3],
        [4, 5],
      ]),
      'M0,1L2,3L4,5L4,0L2,0L0,0Z',
    );
  });

  test('area(x, y0, y1) sets x0, y0 and y1', () {
    double x(String d, int i, List<String> data) => 0;
    double y(String d, int i, List<String> data) => 0;
    expect(area<String>(x).x0, x);
    expect(area<String>(x, y).y0, y);
    expect(area<String>(x, (_, _, _) => 0, y).y1, y);
    final c = area<String>()
      ..x0Const(3)
      ..y0Const(2)
      ..y1Const(1);
    expect(c.x0('aa', 0, const []), 3);
    expect(c.y0('aa', 0, const []), 2);
    expect(c.y1!('aa', 0, const []), 1);
  });

  test('area.x(f)(data) passes d, i and data to the specified function f', () {
    final data = ['a', 'b'];
    final actual = <(String, int, List<String>)>[];
    (area<String>()
      ..x = (d, i, all) {
        actual.add((d, i, all));
        return 0;
      }
      ..y0Const(0)
      ..y1Const(0))(data);
    expect(actual, [('a', 0, data), ('b', 1, data)]);
  });

  test('area.x0(f)(data) passes d, i and data to the specified function f', () {
    final data = ['a', 'b'];
    final actual = <(String, int, List<String>)>[];
    (area<String>()
      ..x0 = (d, i, all) {
        actual.add((d, i, all));
        return 0;
      }
      ..y0Const(0)
      ..y1Const(0))(data);
    expect(actual, [('a', 0, data), ('b', 1, data)]);
  });

  test('area.x1(f)(data) passes d, i and data to the specified function f', () {
    final data = ['a', 'b'];
    final actual = <(String, int, List<String>)>[];
    (area<String>()
      ..x0Const(0)
      ..x1 = (d, i, all) {
        actual.add((d, i, all));
        return 0;
      }
      ..y0Const(0)
      ..y1Const(0))(data);
    expect(actual, [('a', 0, data), ('b', 1, data)]);
  });

  test('area.y(f)(data) passes d, i and data to the specified function f', () {
    final data = ['a', 'b'];
    final actual = <(String, int, List<String>)>[];
    (area<String>()
      ..x0Const(0)
      ..y = (d, i, all) {
        actual.add((d, i, all));
        return 0;
      })(data);
    expect(actual, [('a', 0, data), ('b', 1, data)]);
  });

  test('area.y0(f)(data) passes d, i and data to the specified function f', () {
    final data = ['a', 'b'];
    final actual = <(String, int, List<String>)>[];
    (area<String>()
      ..x0Const(0)
      ..y0 = (d, i, all) {
        actual.add((d, i, all));
        return 0;
      }
      ..y1Const(0))(data);
    expect(actual, [('a', 0, data), ('b', 1, data)]);
  });

  test('area.y1(f)(data) passes d, i and data to the specified function f', () {
    final data = ['a', 'b'];
    final actual = <(String, int, List<String>)>[];
    (area<String>()
      ..x0Const(0)
      ..y1 = (d, i, all) {
        actual.add((d, i, all));
        return 0;
      })(data);
    expect(actual, [('a', 0, data), ('b', 1, data)]);
  });

  test(
    'area.defined(f)(data) passes d, i and data to the specified function f',
    () {
      final data = ['a', 'b'];
      final actual = <(String, int, List<String>)>[];
      (area<String>()
        ..x0Const(0)
        ..y0Const(0)
        ..y1Const(0)
        ..defined = (d, i, all) {
          actual.add((d, i, all));
          return false;
        })(data);
      expect(actual, [('a', 0, data), ('b', 1, data)]);
    },
  );

  test('area.x(x)(data) observes the specified function', () {
    double x(({double x, double y}) d, int i, List<({double x, double y})> _) =>
        d.x;
    final a = area<({double x, double y})>()
      ..x = x
      ..y1 = (d, _, _) => d.y;
    expect(a.x, x);
    expect(a.x0, x);
    expect(a.x1, isNull);
    assertPathEqual(
      a([(x: 0, y: 1), (x: 2, y: 3), (x: 4, y: 5)]),
      'M0,1L2,3L4,5L4,0L2,0L0,0Z',
    );
  });

  test('area.x(x)(data) observes the specified constant', () {
    final a = area<double>()
      ..xConst(0)
      ..y1 = (d, _, _) => d;
    expect(a.x(0, 0, const []), 0);
    expect(a.x0(0, 0, const []), 0);
    expect(a.x1, isNull);
    assertPathEqual(a([1, 3, 5]), 'M0,1L0,3L0,5L0,0L0,0L0,0Z');
  });

  test('area.y(y)(data) observes the specified function', () {
    double y(({double x, double y}) d, int i, List<({double x, double y})> _) =>
        d.y;
    final a = area<({double x, double y})>()
      ..x0 = ((d, _, _) => d.x)
      ..y = y;
    expect(a.y, y);
    expect(a.y0, y);
    expect(a.y1, isNull);
    assertPathEqual(
      a([(x: 0, y: 1), (x: 2, y: 3), (x: 4, y: 5)]),
      'M0,1L2,3L4,5L4,5L2,3L0,1Z',
    );
  });

  test('area.y(y)(data) observes the specified constant', () {
    final a = area<double>()
      ..x0 = ((d, _, _) => d)
      ..yConst(0);
    expect(a.y(0, 0, const []), 0);
    expect(a.y0(0, 0, const []), 0);
    expect(a.y1, isNull);
    assertPathEqual(a([0, 2, 4]), 'M0,0L2,0L4,0L4,0L2,0L0,0Z');
  });

  test('area.curve(curve) sets the curve method', () {
    final a = area<List<double>>()..curve = curveCardinal.call;
    assertPathEqual(
      a([
        [0, 1],
        [1, 3],
        [2, 1],
        [3, 3],
      ]),
      'M0,1C0,1,0.666667,3,1,3C1.333333,3,1.666667,1,2,1C2.333333,1,3,3,3,3L3,0C3,0,2.333333,0,2,0C1.666667,0,1.333333,0,1,0C0.666667,0,0,0,0,0Z',
    );
  });

  test('area.curve(curveCardinal.tension(tension)) sets the cardinal spline tension', () {
    final a = area<List<double>>()..curve = curveCardinal.tension(0.1).call;
    expect(a([]), isNull);
    assertPathEqual(
      a([
        [0, 1],
      ]),
      'M0,1L0,0Z',
    );
    assertPathEqual(
      a([
        [0, 1],
        [1, 3],
      ]),
      'M0,1L1,3L1,0L0,0Z',
    );
    assertPathEqual(
      a([
        [0, 1],
        [1, 3],
        [2, 1],
      ]),
      'M0,1C0,1,0.700000,3,1,3C1.300000,3,2,1,2,1L2,0C2,0,1.300000,0,1,0C0.700000,0,0,0,0,0Z',
    );
    assertPathEqual(
      a([
        [0, 1],
        [1, 3],
        [2, 1],
        [3, 3],
      ]),
      'M0,1C0,1,0.700000,3,1,3C1.300000,3,1.700000,1,2,1C2.300000,1,3,3,3,3L3,0C3,0,2.300000,0,2,0C1.700000,0,1.300000,0,1,0C0.700000,0,0,0,0,0Z',
    );
  });

  test(
    'area.curve(curveCardinal.tension(tension)) coerces the specified tension '
    'to a number',
    () {},
    skip: 'diverges: adapt-shape-typed-api',
  );

  test('area.lineX0() returns a line derived from the area', () {
    bool defined(Object? d, int i, List<Object?> _) => true;
    final curve = curveCardinal.call;
    final context = path();
    double x0(Object? d, int i, List<Object?> _) => 0;
    double x1(Object? d, int i, List<Object?> _) => 0;
    double y(Object? d, int i, List<Object?> _) => 0;
    final a = area<Object?>()
      ..defined = defined
      ..curve = curve
      ..context = context
      ..y = y
      ..x0 = x0
      ..x1 = x1;
    final l = a.lineX0();
    expect(l.defined, defined);
    expect(l.curve, curve);
    expect(l.context, context);
    expect(l.x, x0);
    expect(l.y, y);
  });

  test('area.lineX1() returns a line derived from the area', () {
    bool defined(Object? d, int i, List<Object?> _) => true;
    final curve = curveCardinal.call;
    final context = path();
    double x0(Object? d, int i, List<Object?> _) => 0;
    double x1(Object? d, int i, List<Object?> _) => 0;
    double y(Object? d, int i, List<Object?> _) => 0;
    final a = area<Object?>()
      ..defined = defined
      ..curve = curve
      ..context = context
      ..y = y
      ..x0 = x0
      ..x1 = x1;
    final l = a.lineX1();
    expect(l.defined, defined);
    expect(l.curve, curve);
    expect(l.context, context);
    expect(l.x, x1);
    expect(l.y, y);
  });

  test('area.lineY0() returns a line derived from the area', () {
    bool defined(Object? d, int i, List<Object?> _) => true;
    final curve = curveCardinal.call;
    final context = path();
    double x(Object? d, int i, List<Object?> _) => 0;
    double y0(Object? d, int i, List<Object?> _) => 0;
    double y1(Object? d, int i, List<Object?> _) => 0;
    final a = area<Object?>()
      ..defined = defined
      ..curve = curve
      ..context = context
      ..x = x
      ..y0 = y0
      ..y1 = y1;
    final l = a.lineY0();
    expect(l.defined, defined);
    expect(l.curve, curve);
    expect(l.context, context);
    expect(l.x, x);
    expect(l.y, y0);
  });

  test('area.lineY1() returns a line derived from the area', () {
    bool defined(Object? d, int i, List<Object?> _) => true;
    final curve = curveCardinal.call;
    final context = path();
    double x(Object? d, int i, List<Object?> _) => 0;
    double y0(Object? d, int i, List<Object?> _) => 0;
    double y1(Object? d, int i, List<Object?> _) => 0;
    final a = area<Object?>()
      ..defined = defined
      ..curve = curve
      ..context = context
      ..x = x
      ..y0 = y0
      ..y1 = y1;
    final l = a.lineY1();
    expect(l.defined, defined);
    expect(l.curve, curve);
    expect(l.context, context);
    expect(l.x, x);
    expect(l.y, y1);
  });
}
