// Ported from d3-shape v3.2.0 test/curve/cardinalOpen-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

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
  test('line.curve(curveCardinalOpen)(data) generates the expected path', () {
    final l = line<List<double>>()..curve = curveCardinalOpen.call;
    expect(l([]), isNull);
    expect(l(_pts.sublist(0, 1)), isNull);
    expect(l(_pts.sublist(0, 2)), isNull);
    assertPathEqual(l(_pts.sublist(0, 3)), 'M1,3Z');
    assertPathEqual(l(_pts), 'M1,3C1.333333,3,1.666667,1,2,1');
  });

  test('line.curve(curveCardinalOpen) uses a default tension of zero', () {
    final l = line<List<double>>()..curve = curveCardinalOpen.tension(0).call;
    expect(
      (line<List<double>>()..curve = curveCardinalOpen.call)(_pts),
      l(_pts),
    );
  });

  test(
    'line.curve(curveCardinalOpen.tension(tension)) uses the specified tension',
    () {
      assertPathEqual(
        (line<List<double>>()
          ..curve = curveCardinalOpen.tension(0.5).call)(_pts),
        'M1,3C1.166667,3,1.833333,1,2,1',
      );
    },
  );

  test(
    'line.curve(curveCardinalOpen.tension(tension)) coerces the specified '
    'tension to a number',
    () {},
    skip: 'diverges: adapt-shape-typed-api',
  );

  test('area.curve(curveCardinalOpen)(data) generates the expected path', () {
    final a = area<List<double>>()..curve = curveCardinalOpen.call;
    expect(a([]), isNull);
    expect(a(_pts.sublist(0, 1)), isNull);
    expect(a(_pts.sublist(0, 2)), isNull);
    assertPathEqual(a(_pts.sublist(0, 3)), 'M1,3L1,0Z');
    assertPathEqual(
      a(_pts),
      'M1,3C1.333333,3,1.666667,1,2,1L2,0C1.666667,0,1.333333,0,1,0Z',
    );
  });

  test('area.curve(curveCardinalOpen) uses a default tension of zero', () {
    final a = area<List<double>>()..curve = curveCardinalOpen.tension(0).call;
    expect(
      (area<List<double>>()..curve = curveCardinalOpen.call)(_pts),
      a(_pts),
    );
  });

  test(
    'area.curve(curveCardinalOpen.tension(tension)) uses the specified tension',
    () {
      assertPathEqual(
        (area<List<double>>()
          ..curve = curveCardinalOpen.tension(0.5).call)(_pts),
        'M1,3C1.166667,3,1.833333,1,2,1L2,0C1.833333,0,1.166667,0,1,0Z',
      );
    },
  );

  test(
    'area.curve(curveCardinalOpen.tension(tension)) coerces the specified '
    'tension to a number',
    () {},
    skip: 'diverges: adapt-shape-typed-api',
  );
}
