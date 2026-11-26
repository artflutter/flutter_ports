// Ported from d3-shape v3.2.0 test/curve/bumpX-test.js (ISC, Mike Bostock).
// Expected SVG path literals exceed 80 chars and filename mirrors upstream.
// ignore_for_file: file_names, lines_longer_than_80_chars

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

import '../asserts.dart';

void main() {
  test('line.curve(curveBumpX)(data) generates the expected path', () {
    final l = line<List<double>>()..curve = curveBumpX;
    expect(l([]), isNull);
    assertPathEqual(
      l([
        [0, 1],
      ]),
      'M0,1Z',
    );
    assertPathEqual(
      l([
        [0, 1],
        [1, 3],
      ]),
      'M0,1C0.500000,1,0.500000,3,1,3',
    );
    assertPathEqual(
      l([
        [0, 1],
        [1, 3],
        [2, 1],
      ]),
      'M0,1C0.500000,1,0.500000,3,1,3C1.500000,3,1.500000,1,2,1',
    );
  });

  test('area.curve(curveBumpX)(data) generates the expected path', () {
    final a = area<List<double>>()..curve = curveBumpX;
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
      'M0,1C0.500000,1,0.500000,3,1,3L1,0C0.500000,0,0.500000,0,0,0Z',
    );
    assertPathEqual(
      a([
        [0, 1],
        [1, 3],
        [2, 1],
      ]),
      'M0,1C0.500000,1,0.500000,3,1,3C1.500000,3,1.500000,1,2,1L2,0C1.500000,0,1.500000,0,1,0C0.500000,0,0.500000,0,0,0Z',
    );
  });
}
