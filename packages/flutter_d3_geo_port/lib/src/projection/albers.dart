// Ported from d3-geo v3.1.1 src/projection/albers.js (ISC, Mike Bostock).

/// Port of `src/projection/albers.js` of d3-geo 3.1.1: [geoAlbers].
library;

import 'package:flutter_d3_geo_port/src/projection/conic.dart';
import 'package:flutter_d3_geo_port/src/projection/conicEqualArea.dart';

/// `projection/albers.js:3` `geoAlbers()`: United States-centric Albers
/// equal-area conic projection.
GeoConicProjection geoAlbers() => geoConicEqualArea()
  ..parallels = const (29.5, 45.5)
  ..scale = 1070
  ..translate = const (480, 250)
  ..rotate = const (96, 0, 0)
  ..center = const (-0.6, 38.7);
