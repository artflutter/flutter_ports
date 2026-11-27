// Ported from d3-geo v3.1.1 test/projection/rotate-test.js (ISC, Mike Bostock).
// Upstream test titles exceed 80 chars.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

import '../asserts.dart';

void main() {
  test('a rotation of a degenerate polygon should not break', () {
    final projection = geoMercator()
      ..rotate = const (-134.300, 25.776, 0)
      ..scale = 750
      ..translate = const (0, 0);
    assertPathEqual(
      geoPath(projection)(
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[
            (125.67351590459046, -14.17673705310531),
            (125.67351590459046, -14.173276873687367),
            (125.67351590459046, -14.173276873687367),
            (125.67351590459046, -14.169816694269425),
            (125.67351590459046, -14.17673705310531),
          ],
        ]),
      ),
      'M-111.644162,-149.157654L-111.647235,-149.203744L-111.647235,-149.203744L-111.650307,-149.249835Z',
    );
  });
}
