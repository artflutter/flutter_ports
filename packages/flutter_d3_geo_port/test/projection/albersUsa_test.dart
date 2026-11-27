// Ported from d3-geo v3.1.1 test/projection/albersUsa-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test(
    'albersUsa(point) and albersUsa.invert(point) returns the expected result',
    () {
      final albersUsa = geoAlbersUsa();
      assertProjectionEqual(
        albersUsa,
        const (-122.4194, 37.7749),
        const (107.4, 214.1),
        0.1,
      ); // San Francisco, CA
      assertProjectionEqual(
        albersUsa,
        const (-74.0059, 40.7128),
        const (794.6, 176.5),
        0.1,
      ); // New York, NY
      assertProjectionEqual(
        albersUsa,
        const (-95.9928, 36.1540),
        const (488.8, 298.0),
        0.1,
      ); // Tulsa, OK
      assertProjectionEqual(
        albersUsa,
        const (-149.9003, 61.2181),
        const (171.2, 446.9),
        0.1,
      ); // Anchorage, AK
      assertProjectionEqual(
        albersUsa,
        const (-157.8583, 21.3069),
        const (298.5, 451.0),
        0.1,
      ); // Honolulu, HI
      expect(albersUsa(const (2.3522, 48.8566)), isNull); // Paris, France
    },
  );
}
