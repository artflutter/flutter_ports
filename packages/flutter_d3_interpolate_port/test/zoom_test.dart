// Ported from d3-interpolate v3.0.1 test/zoom-test.js (ISC, Mike Bostock).
import 'dart:math' as math;

import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('interpolateZoom(a, b) handles nearly-coincident points', () {
    expect(
      interpolateZoom(
        (324.68721096803614, 59.43501602433761, 1.8827137399562621),
        (324.6872108946794, 59.43501601062763, 7.399052110984391),
      )(0.5),
      (324.68721093135775, 59.43501601748262, 3.7323313186268305),
    );
  });

  test('interpolateZoom returns the expected duration', () {
    assertInDelta(interpolateZoom((0, 0, 1), (0, 0, 1.1)).duration, 67.0, 1);
    assertInDelta(interpolateZoom((0, 0, 1), (0, 0, 2)).duration, 490.0, 1);
    assertInDelta(interpolateZoom((0, 0, 1), (10, 0, 8)).duration, 2872.5, 1);
  });

  test('interpolateZoom parameter rho() defaults to sqrt(2)', () {
    assertInDelta(
      interpolateZoom((0, 0, 1), (10, 10, 5))(0.5),
      interpolateZoom.rho(math.sqrt(2))((0, 0, 1), (10, 10, 5))(0.5),
    );
  });

  test('interpolateZoom.rho(0) is (almost) linear', () {
    final interp = interpolateZoom.rho(0)((0, 0, 1), (10, 0, 8));
    assertInDelta(interp(0.5), (1.111, 0.0, math.sqrt(8)), 1e-3);
    expect(interp.duration.round(), 1470);
  });

  test('interpolateZoom parameter rho(2) has a high curvature and takes more '
      'time', () {
    final interp = interpolateZoom.rho(2)((0, 0, 1), (10, 0, 8));
    assertInDelta(interp(0.5), (1.111, 0.0, 12.885), 1e-3);
    expect(interp.duration.round(), 3775);
  });
}
