// Ported from d3-shape v3.2.0 test/areaRadial-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('areaRadial() returns a default radial area shape', () {
    final a = areaRadial<List<double>>();
    expect(a.startAngle([42, 34], 0, const []), 42);
    expect(a.endAngle, isNull);
    expect(a.innerRadius([42, 34], 0, const []), 0);
    expect(a.outerRadius!([42, 34], 0, const []), 34);
    expect(a.defined([42, 34], 0, const []), isTrue);
    expect(a.curve, curveLinear);
    expect(a.context, isNull);
    assertPathEqual(
      a([
        [0, 1],
        [2, 3],
        [4, 5],
      ]),
      'M0,-1L2.727892,1.248441L-3.784012,3.268218L0,0L0,0L0,0Z',
    );
  });

  test('areaRadial.lineStartAngle() returns a line derived from the area', () {
    bool defined(Object? d, int i, List<Object?> _) => true;
    final curve = curveCardinal.call;
    final context = path();
    double startAngle(Object? d, int i, List<Object?> _) => 0;
    double endAngle(Object? d, int i, List<Object?> _) => 0;
    double radius(Object? d, int i, List<Object?> _) => 0;
    final a = areaRadial<Object?>()
      ..defined = defined
      ..curve = curve
      ..context = context
      ..radius = radius
      ..startAngle = startAngle
      ..endAngle = endAngle;
    final l = a.lineStartAngle();
    expect(l.defined, defined);
    expect(l.curve, curve);
    expect(l.context, context);
    expect(l.angle, startAngle);
    expect(l.radius, radius);
  });

  test('areaRadial.lineEndAngle() returns a line derived from the area', () {
    bool defined(Object? d, int i, List<Object?> _) => true;
    final curve = curveCardinal.call;
    final context = path();
    double startAngle(Object? d, int i, List<Object?> _) => 0;
    double endAngle(Object? d, int i, List<Object?> _) => 0;
    double radius(Object? d, int i, List<Object?> _) => 0;
    final a = areaRadial<Object?>()
      ..defined = defined
      ..curve = curve
      ..context = context
      ..radius = radius
      ..startAngle = startAngle
      ..endAngle = endAngle;
    final l = a.lineEndAngle();
    expect(l.defined, defined);
    expect(l.curve, curve);
    expect(l.context, context);
    expect(l.angle, endAngle);
    expect(l.radius, radius);
  });

  test('areaRadial.lineInnerRadius() returns a line derived from the area', () {
    bool defined(Object? d, int i, List<Object?> _) => true;
    final curve = curveCardinal.call;
    final context = path();
    double angle(Object? d, int i, List<Object?> _) => 0;
    double innerRadius(Object? d, int i, List<Object?> _) => 0;
    double outerRadius(Object? d, int i, List<Object?> _) => 0;
    final a = areaRadial<Object?>()
      ..defined = defined
      ..curve = curve
      ..context = context
      ..angle = angle
      ..innerRadius = innerRadius
      ..outerRadius = outerRadius;
    final l = a.lineInnerRadius();
    expect(l.defined, defined);
    expect(l.curve, curve);
    expect(l.context, context);
    expect(l.angle, angle);
    expect(l.radius, innerRadius);
  });

  test('areaRadial.lineOuterRadius() returns a line derived from the area', () {
    bool defined(Object? d, int i, List<Object?> _) => true;
    final curve = curveCardinal.call;
    final context = path();
    double angle(Object? d, int i, List<Object?> _) => 0;
    double innerRadius(Object? d, int i, List<Object?> _) => 0;
    double outerRadius(Object? d, int i, List<Object?> _) => 0;
    final a = areaRadial<Object?>()
      ..defined = defined
      ..curve = curve
      ..context = context
      ..angle = angle
      ..innerRadius = innerRadius
      ..outerRadius = outerRadius;
    final l = a.lineOuterRadius();
    expect(l.defined, defined);
    expect(l.curve, curve);
    expect(l.context, context);
    expect(l.angle, angle);
    expect(l.radius, outerRadius);
  });
}
