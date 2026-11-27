// Ported from d3-geo v3.1.1 src/projection/naturalEarth1.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/projection/naturalEarth1.js` of d3-geo 3.1.1:
/// [geoNaturalEarth1] and [geoNaturalEarth1Raw].
library;

import 'package:flutter_d3_geo_port/src/compose.dart';
import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/projection/index.dart';

/// `projection/naturalEarth1.js:4` `naturalEarth1Raw`.
final GeoRawProjection geoNaturalEarth1Raw = geoRawProjection(
  (lambda, phi) {
    final phi2 = phi * phi;
    final phi4 = phi2 * phi2;
    return (
      lambda *
          (0.8707 -
              0.131979 * phi2 +
              phi4 * (-0.013791 + phi4 * (0.003971 * phi2 - 0.001529 * phi4))),
      phi *
          (1.007226 +
              phi2 *
                  (0.015085 +
                      phi4 * (-0.044475 + 0.028874 * phi2 - 0.005916 * phi4))),
    );
  },
  invert: (x, y) {
    var phi = y;
    var i = 25;
    double delta;
    do {
      final phi2 = phi * phi;
      final phi4 = phi2 * phi2;
      delta =
          (phi *
                  (1.007226 +
                      phi2 *
                          (0.015085 +
                              phi4 *
                                  (-0.044475 +
                                      0.028874 * phi2 -
                                      0.005916 * phi4))) -
              y) /
          (1.007226 +
              phi2 *
                  (0.015085 * 3 +
                      phi4 *
                          (-0.044475 * 7 +
                              0.028874 * 9 * phi2 -
                              0.005916 * 11 * phi4)));
      phi -= delta;
    } while (delta.abs() > geoEpsilon && --i > 0);
    final phi2 = phi * phi;
    return (
      x /
          (0.8707 +
              phi2 *
                  (-0.131979 +
                      phi2 *
                          (-0.013791 +
                              phi2 *
                                  phi2 *
                                  phi2 *
                                  (0.003971 - 0.001529 * phi2)))),
      phi,
    );
  },
);

/// `projection/naturalEarth1.js:25` `geoNaturalEarth1()`: Natural Earth
/// pseudocylindrical projection.
GeoProjection geoNaturalEarth1() =>
    geoProjection(geoNaturalEarth1Raw)..scale = 175.295;
