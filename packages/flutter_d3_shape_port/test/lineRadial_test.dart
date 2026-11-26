// Ported from d3-shape v3.2.0 test/lineRadial-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('lineRadial() returns a default radial line shape', () {
    final l = lineRadial<List<double>>();
    expect(l.angle([42, 34], 0, const []), 42);
    expect(l.radius([42, 34], 0, const []), 34);
    expect(l.defined([42, 34], 0, const []), isTrue);
    expect(l.curve, curveLinear);
    expect(l.context, isNull);
    assertPathEqual(
      l([
        [0, 1],
        [2, 3],
        [4, 5],
      ]),
      'M0,-1L2.727892,1.248441L-3.784012,3.268218',
    );
  });
}
