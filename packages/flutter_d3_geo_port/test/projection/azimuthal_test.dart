// Ported from d3-geo v3.1.1 test/projection/azimuthal-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

void main() {
  test("azimuthal projections don't crash on the antipode", () {
    for (final p in <GeoPosition?>[
      geoAzimuthalEqualArea()(const (180, 0)),
      geoAzimuthalEqualArea()(const (-180, 0)),
      geoAzimuthalEquidistant()(const (180, 0)),
    ]) {
      expect(p, isNotNull);
      expect(p!.$1.abs(), lessThan(double.infinity));
      expect(p.$2.abs(), lessThan(double.infinity));
    }
  });
}
