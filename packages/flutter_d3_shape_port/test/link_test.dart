// Ported from d3-shape v3.2.0 test/link-test.js (ISC, Mike Bostock).

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('link(curve) returns a default link with the given curve', () {
    final l = link<LinkData<List<double>>, List<double>>(curveLinear);
    expect(l.source(const LinkData(source: [42, 0], target: [0, 0])), [42, 0]);
    expect(l.target(const LinkData(source: [0, 0], target: [34, 0])), [34, 0]);
    expect(l.x([42, 34]), 42);
    expect(l.y([42, 34]), 34);
    expect(l.context, isNull);
    assertPathEqual(
      l(const LinkData(source: [0, 1], target: [2, 3])),
      'M0,1L2,3',
    );
  });

  test('link.source(source) sets source', () {
    final l = link<({List<double> x, List<double> target}), List<double>>(
      curveLinear,
    );
    List<double> x(({List<double> x, List<double> target}) d) => d.x;
    l
      ..source = x
      ..target = (d) => d.target;
    expect(l.source, x);
    assertPathEqual(l((x: [0, 1], target: [2, 3])), 'M0,1L2,3');
  });

  test('link.target(target) sets target', () {
    final l = link<({List<double> source, List<double> x}), List<double>>(
      curveLinear,
    );
    List<double> x(({List<double> source, List<double> x}) d) => d.x;
    l
      ..source = ((d) => d.source)
      ..target = x;
    expect(l.target, x);
    assertPathEqual(l((source: [0, 1], x: [2, 3])), 'M0,1L2,3');
  });

  test(
    'link.source(f)(..args) passes arguments to the specified function f',
    () {},
    skip: 'diverges: adapt-shape-typed-api',
  );

  test(
    'link.target(f)(..args) passes source and arguments to the specified '
    'function f',
    () {},
    skip: 'diverges: adapt-shape-typed-api',
  );

  test('link.x(x) sets x', () {
    final l = link<LinkData<({double x, double y})>, ({double x, double y})>(
      curveLinear,
    );
    double x(({double x, double y}) d) => d.x;
    l
      ..x = x
      ..y = (d) => d.y;
    expect(l.x, x);
    assertPathEqual(
      l(const LinkData(source: (x: 0, y: 1), target: (x: 2, y: 3))),
      'M0,1L2,3',
    );
  });

  test('link.y(y) sets y', () {
    final l = link<LinkData<({double x, double y})>, ({double x, double y})>(
      curveLinear,
    );
    double y(({double x, double y}) d) => d.y;
    l
      ..x = ((d) => d.x)
      ..y = y;
    expect(l.y, y);
    assertPathEqual(
      l(const LinkData(source: (x: 0, y: 1), target: (x: 2, y: 3))),
      'M0,1L2,3',
    );
  });

  test(
    'link.x(f)(..args) passes source and arguments to the specified function f',
    () {},
    skip: 'diverges: adapt-shape-typed-api',
  );

  test(
    'link.y(f)(..args) passes source and arguments to the specified function f',
    () {},
    skip: 'diverges: adapt-shape-typed-api',
  );

  test('linkHorizontal() is an alias for link(curveBumpX)', () {
    final l = linkHorizontal<LinkData<(double, double)>, (double, double)>();
    final l2 = link<LinkData<(double, double)>, (double, double)>(curveBumpX);
    expect(l.source, l2.source);
    expect(l.target, l2.target);
    expect(l.x, l2.x);
    expect(l.y, l2.y);
    expect(l.context, l2.context);
    assertPathEqual(
      l(const LinkData(source: (0, 1), target: (2, 3))),
      l2(const LinkData(source: (0, 1), target: (2, 3)))!,
    );
  });

  test('linkVertical() is an alias for link(curveBumpY)', () {
    final l = linkVertical<LinkData<(double, double)>, (double, double)>();
    final l2 = link<LinkData<(double, double)>, (double, double)>(curveBumpY);
    expect(l.source, l2.source);
    expect(l.target, l2.target);
    expect(l.x, l2.x);
    expect(l.y, l2.y);
    expect(l.context, l2.context);
    assertPathEqual(
      l(const LinkData(source: (0, 1), target: (2, 3))),
      l2(const LinkData(source: (0, 1), target: (2, 3)))!,
    );
  });

  test('link.context(context) sets the context', () {
    final p = pathRound(6);
    final l = link<LinkData<(double, double)>, (double, double)>(curveLinear)
      ..context = p;
    expect(
      l(const LinkData(source: (0, math.e), target: (math.pi, 3))),
      isNull,
    );
    expect('$p', 'M0,2.718282L3.141593,3');
  });

  test('linkRadial() works as expected', () {
    final l = linkRadial<LinkData<(double, double)>, (double, double)>();
    final l2 = link<LinkData<(double, double)>, (double, double)>(curveLinear);
    expect(l.source, l2.source);
    expect(l.target, l2.target);
    expect(l.angle, l2.x);
    expect(l.radius, l2.y);
    expect(l.context, l2.context);
    assertPathEqual(
      l(const LinkData(source: (0, 1), target: (math.pi / 2, 3))),
      'M0,-1C0,-2,2,0,3,0',
    );
  });
}
