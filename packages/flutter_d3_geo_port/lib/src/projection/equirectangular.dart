// Ported from d3-geo v3.1.1 src/projection/equirectangular.js (ISC, Mike Bostock).

/// Port of `src/projection/equirectangular.js` of d3-geo 3.1.1:
/// [geoEquirectangular] and [geoEquirectangularRaw].
library;

import 'package:flutter_d3_geo_port/src/compose.dart';
import 'package:flutter_d3_geo_port/src/projection/index.dart';

/// `projection/equirectangular.js:3` `equirectangularRaw`.
final GeoRawProjection geoEquirectangularRaw = geoRawProjection(
  (lambda, phi) => (lambda, phi),
  invert: (x, y) => (x, y),
);

/// `projection/equirectangular.js:9` `geoEquirectangular()`: plate carrée
/// equirectangular projection.
GeoProjection geoEquirectangular() =>
    geoProjection(geoEquirectangularRaw)..scale = 152.63;
