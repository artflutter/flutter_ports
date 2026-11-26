// Ported from d3-shape v3.2.0 test/curve/catmullRomClosed-test.js (ISC, Mike Bostock).
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
  test(
    'line.curve(curveCatmullRomClosed)(data) generates the expected path',
    () {
      final l = line<List<double>>()..curve = curveCatmullRomClosed.call;
      expect(l([]), isNull);
      assertPathEqual(l(_pts.sublist(0, 1)), 'M0,1Z');
      assertPathEqual(l(_pts.sublist(0, 2)), 'M1,3L0,1Z');
      assertPathEqual(
        l(_pts.sublist(0, 3)),
        'M1,3C1.333333,3,2.200267,1.324038,2,1C1.810600,0.693544,0.189400,0.693544,0,1C-0.200267,1.324038,0.666667,3,1,3',
      );
      assertPathEqual(
        l(_pts),
        'M1,3C1.333333,3,1.666667,1,2,1C2.333333,1,3.160469,2.858341,3,3C2.796233,3.179882,0.203767,0.820118,0,1C-0.160469,1.141659,0.666667,3,1,3',
      );
    },
  );

  test(
    'line.curve(curveCatmullRomClosed.alpha(0))(data) generates the expected '
    'path',
    () {
      final l = line<List<double>>()
        ..curve = curveCatmullRomClosed.alpha(0).call;
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
    },
  );

  test(
    'line.curve(curveCatmullRomClosed.alpha(1))(data) generates the expected '
    'path',
    () {
      final l = line<List<double>>()
        ..curve = curveCatmullRomClosed.alpha(1).call;
      expect(l([]), isNull);
      assertPathEqual(l(_pts.sublist(0, 1)), 'M0,1Z');
      assertPathEqual(l(_pts.sublist(0, 2)), 'M1,3L0,1Z');
      assertPathEqual(
        l(_pts.sublist(0, 3)),
        'M1,3C1.333333,3,2.236068,1.314757,2,1C1.788854,0.718473,0.211146,0.718473,0,1C-0.236068,1.314757,0.666667,3,1,3',
      );
      assertPathEqual(
        l(_pts),
        'M1,3C1.333333,3,1.666667,1,2,1C2.333333,1,3.031652,2.746782,3,3C2.948962,3.408301,0.051038,0.591699,0,1C-0.031652,1.253218,0.666667,3,1,3',
      );
    },
  );

  test('line.curve(curveCatmullRomClosed) uses a default alpha of 0.5 '
      '(centripetal)', () {
    final l = line<List<double>>()
      ..curve = curveCatmullRomClosed.alpha(0.5).call;
    expect(
      (line<List<double>>()..curve = curveCatmullRomClosed.call)(_pts),
      l(_pts),
    );
  });

  test(
    'line.curve(curveCatmullRomClosed.alpha(alpha)) coerces the specified '
    'alpha to a number',
    () {},
    skip: 'diverges: adapt-shape-typed-api',
  );

  test(
    'area.curve(curveCatmullRomClosed.alpha(alpha)) coerces the specified '
    'alpha to a number',
    () {},
    skip: 'diverges: adapt-shape-typed-api',
  );
}
