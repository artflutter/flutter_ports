// Ported from d3-shape v3.2.0 test/curve/basisOpen-test.js (ISC, Mike Bostock).
// Expected SVG path literals exceed 80 chars and filename mirrors upstream.
// ignore_for_file: file_names, lines_longer_than_80_chars

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

import '../asserts.dart';

void main() {
  test('line.curve(curveBasisOpen)(data) generates the expected path', () {
    final l = line<List<double>>()..curve = curveBasisOpen;
    expect(l([]), isNull);
    expect(
      l([
        [0, 0],
      ]),
      isNull,
    );
    expect(
      l([
        [0, 0],
        [0, 10],
      ]),
      isNull,
    );
    assertPathEqual(
      l([
        [0, 0],
        [0, 10],
        [10, 10],
      ]),
      'M1.666667,8.333333Z',
    );
    assertPathEqual(
      l([
        [0, 0],
        [0, 10],
        [10, 10],
        [10, 0],
      ]),
      'M1.666667,8.333333C3.333333,10,6.666667,10,8.333333,8.333333',
    );
    assertPathEqual(
      l([
        [0, 0],
        [0, 10],
        [10, 10],
        [10, 0],
        [0, 0],
      ]),
      'M1.666667,8.333333C3.333333,10,6.666667,10,8.333333,8.333333C10,6.666667,10,3.333333,8.333333,1.666667',
    );
  });

  test('area.curve(curveBasisOpen)(data) generates the expected path', () {
    final a = area<List<double>>()..curve = curveBasisOpen;
    expect(a([]), isNull);
    expect(
      a([
        [0, 1],
      ]),
      isNull,
    );
    expect(
      a([
        [0, 1],
        [1, 3],
      ]),
      isNull,
    );
    assertPathEqual(
      a([
        [0, 0],
        [0, 10],
        [10, 10],
      ]),
      'M1.666667,8.333333L1.666667,0Z',
    );
    assertPathEqual(
      a([
        [0, 0],
        [0, 10],
        [10, 10],
        [10, 0],
      ]),
      'M1.666667,8.333333C3.333333,10,6.666667,10,8.333333,8.333333L8.333333,0C6.666667,0,3.333333,0,1.666667,0Z',
    );
    assertPathEqual(
      a([
        [0, 0],
        [0, 10],
        [10, 10],
        [10, 0],
        [0, 0],
      ]),
      'M1.666667,8.333333C3.333333,10,6.666667,10,8.333333,8.333333C10,6.666667,10,3.333333,8.333333,1.666667L8.333333,0C10,0,10,0,8.333333,0C6.666667,0,3.333333,0,1.666667,0Z',
    );
  });
}
