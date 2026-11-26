// Ported from d3-shape v3.2.0 test/curve/cardinalClosed-test.js (ISC, Mike Bostock).
// Expected SVG path literals exceed 80 chars and filename mirrors upstream.
// ignore_for_file: file_names, lines_longer_than_80_chars

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

import '../asserts.dart';

const _pts = <List<double>>[
  [0, 1],
  [1, 3],
  [2, 1],
  [3, 3],
];

void main() {
  test('line.curve(curveCardinalClosed)(data) generates the expected path', () {
    final l = line<List<double>>()..curve = curveCardinalClosed.call;
    expect(l([]), isNull);
    assertPathEqual(l(_pts.sublist(0, 1)), 'M0,1Z');
    assertPathEqual(l(_pts.sublist(0, 2)), 'M1,3L0,1Z');
    assertPathEqual(
      l(_pts.sublist(0, 3)),
      'M1,3C1.333333,3,2.166667,1.333333,2,1C1.833333,0.666667,0.166667,0.666667,0,1C-0.166667,1.333333,0.666667,3,1,3',
    );
    assertPathEqual(
      l(_pts),
      'M1,3C1.333333,3,1.666667,1,2,1C2.333333,1,3.333333,3,3,3C2.666667,3,0.333333,1,0,1C-0.333333,1,0.666667,3,1,3',
    );
  });

  test('line.curve(curveCardinalClosed) uses a default tension of zero', () {
    final l = line<List<double>>()..curve = curveCardinalClosed.tension(0).call;
    expect(
      (line<List<double>>()..curve = curveCardinalClosed.call)(_pts),
      l(_pts),
    );
  });

  test('line.curve(curveCardinalClosed.tension(tension)) uses the specified '
      'tension', () {
    assertPathEqual(
      (line<List<double>>()
        ..curve = curveCardinalClosed.tension(0.5).call)(_pts),
      'M1,3C1.166667,3,1.833333,1,2,1C2.166667,1,3.166667,3,3,3C2.833333,3,0.166667,1,0,1C-0.166667,1,0.833333,3,1,3',
    );
  });

  test(
    'line.curve(curveCardinalClosed.tension(tension)) coerces the specified '
    'tension to a number',
    () {},
    skip: 'diverges: adapt-shape-typed-api',
  );

  test('area.curve(curveCardinalClosed)(data) generates the expected path', () {
    final a = area<List<double>>()..curve = curveCardinalClosed.call;
    expect(a([]), isNull);
    expect(a(_pts.sublist(0, 1)), 'M0,1ZM0,0Z');
    expect(a(_pts.sublist(0, 2)), 'M1,3L0,1ZM0,0L1,0Z');
    assertPathEqual(
      a(_pts.sublist(0, 3)),
      'M1,3C1.333333,3,2.166667,1.333333,2,1C1.833333,0.666667,0.166667,0.666667,0,1C-0.166667,1.333333,0.666667,3,1,3M1,0C0.666667,0,-0.166667,0,0,0C0.166667,0,1.833333,0,2,0C2.166667,0,1.333333,0,1,0',
    );
    assertPathEqual(
      a(_pts),
      'M1,3C1.333333,3,1.666667,1,2,1C2.333333,1,3.333333,3,3,3C2.666667,3,0.333333,1,0,1C-0.333333,1,0.666667,3,1,3M2,0C1.666667,0,1.333333,0,1,0C0.666667,0,-0.333333,0,0,0C0.333333,0,2.666667,0,3,0C3.333333,0,2.333333,0,2,0',
    );
  });

  test('area.curve(curveCardinalClosed) uses a default tension of zero', () {
    final a = area<List<double>>()..curve = curveCardinalClosed.tension(0).call;
    expect(
      (area<List<double>>()..curve = curveCardinalClosed.call)(_pts),
      a(_pts),
    );
  });

  test('area.curve(curveCardinalClosed.tension(tension)) uses the specified '
      'tension', () {
    assertPathEqual(
      (area<List<double>>()
        ..curve = curveCardinalClosed.tension(0.5).call)(_pts),
      'M1,3C1.166667,3,1.833333,1,2,1C2.166667,1,3.166667,3,3,3C2.833333,3,0.166667,1,0,1C-0.166667,1,0.833333,3,1,3M2,0C1.833333,0,1.166667,0,1,0C0.833333,0,-0.166667,0,0,0C0.166667,0,2.833333,0,3,0C3.166667,0,2.166667,0,2,0',
    );
  });

  test(
    'area.curve(curveCardinalClosed.tension(tension)) coerces the specified '
    'tension to a number',
    () {},
    skip: 'diverges: adapt-shape-typed-api',
  );
}
