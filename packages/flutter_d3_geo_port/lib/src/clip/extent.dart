// Ported from d3-geo v3.1.1 src/clip/extent.js (ISC, Mike Bostock).

/// Port of `src/clip/extent.js` of d3-geo 3.1.1: [GeoClipExtent] and
/// [geoClipExtent].
library;

import 'package:flutter_d3_geo_port/src/clip/rectangle.dart';
import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/stream.dart';

/// Deprecated standalone rectangular clip extent streamable (prefer
/// `geoIdentity()..clipExtent = ...`).
// DIVERGES(d3-geo): adapt-geo-typed-api, typed GeoClipExtent class with
// GeoExtent property.
final class GeoClipExtent() implements GeoStreamable {
  /// Creates a [GeoClipExtent] with default extent `((0, 0), (960, 500))`.
  this;

  double _x0 = 0;
  double _y0 = 0;
  double _x1 = 960;
  double _y1 = 500;
  GeoStream? _cache;
  GeoStream? _cacheStream;

  /// Current clip extent `((x0, y0), (x1, y1))`.
  GeoExtent get extent => ((_x0, _y0), (_x1, _y1));

  /// Sets the clip extent.
  set extent(GeoExtent value) {
    _x0 = value.$1.$1;
    _y0 = value.$1.$2;
    _x1 = value.$2.$1;
    _y1 = value.$2.$2;
    _cache = null;
    _cacheStream = null;
  }

  @override
  GeoStream stream(GeoStream sink) {
    if (_cache != null && identical(_cacheStream, sink)) return _cache!;
    _cacheStream = sink;
    return _cache = geoClipRectangle(_x0, _y0, _x1, _y1)(sink);
  }
}

/// `clip/extent.js:3` `geoClipExtent()`: creates a [GeoClipExtent].
///
/// Upstream marks `geoClipExtent` deprecated in favor of
/// `geoIdentity()..clipExtent = ...`.
GeoClipExtent geoClipExtent() => GeoClipExtent();
