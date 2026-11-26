// Ported from d3-shape v3.2.0 test/curve/catmullRomOpen-test.js (ISC, Mike Bostock).
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
  test('line.curve(curveCatmullRomOpen)(data) generates the expected path', () {
    final l = line<List<double>>()..curve = curveCatmullRomOpen.call;
    expect(l([]), isNull);
    expect(l(_pts.sublist(0, 1)), isNull);
    expect(l(_pts.sublist(0, 2)), isNull);
    assertPathEqual(l(_pts.sublist(0, 3)), 'M1,3Z');
    assertPathEqual(l(_pts), 'M1,3C1.333333,3,1.666667,1,2,1');
  });

  test('line.curve(curveCatmullRomOpen.alpha(1))(data) generates the expected '
      'path', () {
    final l = line<List<double>>()..curve = curveCatmullRomOpen.alpha(1).call;
    expect(l([]), isNull);
    expect(l(_pts.sublist(0, 1)), isNull);
    expect(l(_pts.sublist(0, 2)), isNull);
    assertPathEqual(l(_pts.sublist(0, 3)), 'M1,3Z');
    assertPathEqual(l(_pts), 'M1,3C1.333333,3,1.666667,1,2,1');
  });

  test(
    'line.curve(curveCatmullRomOpen) uses a default alpha of 0.5 (centripetal)',
    () {
      final l = line<List<double>>()
        ..curve = curveCatmullRomOpen.alpha(0.5).call;
      expect(
        (line<List<double>>()..curve = curveCatmullRomOpen.call)(_pts),
        l(_pts),
      );
    },
  );

  test(
    'line.curve(curveCatmullRomOpen.alpha(alpha)) coerces the specified alpha '
    'to a number',
    () {},
    skip: 'diverges: adapt-shape-typed-api',
  );

  test(
    'area.curve(curveCatmullRomOpen.alpha(0.5))(data) generates the expected '
    'path',
    () {
      final a = area<List<double>>()
        ..curve = curveCatmullRomOpen.alpha(0.5).call;
      expect(a([]), isNull);
      expect(a(_pts.sublist(0, 1)), isNull);
      expect(a(_pts.sublist(0, 2)), isNull);
      assertPathEqual(a(_pts.sublist(0, 3)), 'M1,3L1,0Z');
      assertPathEqual(
        a(_pts),
        'M1,3C1.333333,3,1.666667,1,2,1L2,0C1.666667,0,1.333333,0,1,0Z',
      );
    },
  );

  test(
    'area.curve(curveCatmullRomOpen) uses a default alpha of 0.5 (centripetal)',
    () {
      final a = area<List<double>>()
        ..curve = curveCatmullRomOpen.alpha(0.5).call;
      expect(
        (area<List<double>>()..curve = curveCatmullRomOpen.call)(_pts),
        a(_pts),
      );
    },
  );

  test(
    'area.curve(curveCatmullRomOpen.alpha(alpha)) coerces the specified alpha '
    'to a number',
    () {},
    skip: 'diverges: adapt-shape-typed-api',
  );
}
