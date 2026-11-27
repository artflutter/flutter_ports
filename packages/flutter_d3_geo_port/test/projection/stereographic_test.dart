// Ported from d3-geo v3.1.1 test/projection/stereographic-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('stereographic(point) returns the expected result', () {
    final stereographic = geoStereographic()
      ..translate = const (0, 0)
      ..scale = 1;
    assertProjectionEqual(stereographic, const (0, 0), const (0, 0));
    assertProjectionEqual(stereographic, const (-90, 0), const (-1, 0));
    assertProjectionEqual(stereographic, const (90, 0), const (1, 0));
    assertProjectionEqual(stereographic, const (0, -90), const (0, 1));
    assertProjectionEqual(stereographic, const (0, 90), const (0, -1));
  });
}
