// Ported from d3-shape v3.2.0 test/curve/catmullRom-test.js (ISC, Mike Bostock).
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
  test('line.curve(curveCatmullRom)(data) generates the expected path', () {
    final l = line<List<double>>()..curve = curveCatmullRom.call;
    expect(l([]), isNull);
    assertPathEqual(l(_pts.sublist(0, 1)), 'M0,1Z');
    assertPathEqual(l(_pts.sublist(0, 2)), 'M0,1L1,3');
    assertPathEqual(
      l(_pts.sublist(0, 3)),
      'M0,1C0,1,0.666667,3,1,3C1.333333,3,2,1,2,1',
    );
    assertPathEqual(
      l(_pts),
      'M0,1C0,1,0.666667,3,1,3C1.333333,3,1.666667,1,2,1C2.333333,1,3,3,3,3',
    );
  });

  test(
    'line.curve(curveCatmullRom.alpha(1))(data) generates the expected path',
    () {
      final l = line<List<double>>()..curve = curveCatmullRom.alpha(1).call;
      expect(l([]), isNull);
      assertPathEqual(l(_pts.sublist(0, 1)), 'M0,1Z');
      assertPathEqual(l(_pts.sublist(0, 2)), 'M0,1L1,3');
      assertPathEqual(
        l(_pts.sublist(0, 3)),
        'M0,1C0,1,0.666667,3,1,3C1.333333,3,2,1,2,1',
      );
      assertPathEqual(
        l(_pts),
        'M0,1C0,1,0.666667,3,1,3C1.333333,3,1.666667,1,2,1C2.333333,1,3,3,3,3',
      );
    },
  );

  test(
    'line.curve(curveCatmullRom) uses a default alpha of 0.5 (centripetal)',
    () {
      final l = line<List<double>>()..curve = curveCatmullRom.alpha(0.5).call;
      expect(
        (line<List<double>>()..curve = curveCatmullRom.call)(_pts),
        l(_pts),
      );
    },
  );

  test(
    'line.curve(curveCatmullRom.alpha(alpha)) coerces the specified alpha to '
    'a number',
    () {},
    skip: 'diverges: adapt-shape-typed-api',
  );

  test(
    'area.curve(curveCatmullRom.alpha(0))(data) generates the expected path',
    () {
      final a = area<List<double>>()..curve = curveCatmullRom.alpha(0).call;
      expect(a([]), isNull);
      assertPathEqual(a(_pts.sublist(0, 1)), 'M0,1L0,0Z');
      assertPathEqual(a(_pts.sublist(0, 2)), 'M0,1L1,3L1,0L0,0Z');
      assertPathEqual(
        a(_pts.sublist(0, 3)),
        'M0,1C0,1,0.666667,3,1,3C1.333333,3,2,1,2,1L2,0C2,0,1.333333,0,1,0C0.666667,0,0,0,0,0Z',
      );
      assertPathEqual(
        a(_pts),
        'M0,1C0,1,0.666667,3,1,3C1.333333,3,1.666667,1,2,1C2.333333,1,3,3,3,3L3,0C3,0,2.333333,0,2,0C1.666667,0,1.333333,0,1,0C0.666667,0,0,0,0,0Z',
      );
    },
  );

  test(
    'area.curve(curveCatmullRom) uses a default alpha of 0.5 (centripetal)',
    () {
      final a = area<List<double>>()..curve = curveCatmullRom.alpha(0.5).call;
      expect(
        (area<List<double>>()..curve = curveCatmullRom.call)(_pts),
        a(_pts),
      );
    },
  );

  test(
    'area.curve(curveCatmullRom.alpha(alpha)) coerces the specified alpha to '
    'a number',
    () {},
    skip: 'diverges: adapt-shape-typed-api',
  );
}
