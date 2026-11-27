// Ported from d3-geo v3.1.1 src/pointEqual.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/pointEqual.js` of d3-geo 3.1.1.
library;

import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/math.dart';

/// `pointEqual.js:3` default export: returns `true` when [a] and [b] agree
/// within [geoEpsilon] in both coordinates.
// DIVERGES(d3-geo): adapt-geo-typed-api, typed GeoPosition record parameters.
@pragma('vm:prefer-inline')
bool geoPointEqual(GeoPosition a, GeoPosition b) =>
    (a.$1 - b.$1).abs() < geoEpsilon && (a.$2 - b.$2).abs() < geoEpsilon;
