// Ported from d3-geo v3.1.1 test/snapshot-test.js (ISC, Mike Bostock).

// DIVERGES(d3-geo): adapt-geo-snapshot-numerical, verifies projected geometry
// numerically (area, bounds, centroid, measure, graticule measure, sphere area)
// against Node.js d3-geo v3.1.1 reference values across VM, JS, and Wasm.

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

import 'asserts.dart';
import 'port/d3_geo_reference.dart';
import 'snapshots.dart';

void main() {
  final graticule10 = geoGraticule10();

  for (final entry in geoSnapshots.entries) {
    final name = entry.key;
    final (makeProjection, getLand) = entry.value;
    test('snapshot $name', () {
      final proj = makeProjection();
      final land = getLand();
      final pathGen = geoPath(proj);
      final (
        expArea,
        expBounds,
        expCentroid,
        expMeasure,
        expGratMeasure,
        expSphereArea,
      ) = refSnapshots[name]!;

      assertInDelta(pathGen.area(land), expArea, 1e-4);
      assertExtentInDelta(pathGen.bounds(land), expBounds, 1e-4);
      assertPositionInDelta(pathGen.centroid(land), expCentroid, 1e-4);
      assertInDelta(pathGen.measure(land), expMeasure, 1e-4);
      assertInDelta(pathGen.measure(graticule10), expGratMeasure, 1e-3);
      assertInDelta(pathGen.area(const GeoSphere()), expSphereArea, 1e-4);
      expect(pathGen(land), isNotEmpty);
    });
  }
}
