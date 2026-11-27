// Ported from d3-geo v3.1.1 src/path/bounds.js (ISC, Mike Bostock).

/// Port of `src/path/bounds.js` of d3-geo 3.1.1: [GeoPathBoundsStream].
library;

import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/stream.dart';

/// `path/bounds.js:8` `boundsStream`: computes the projected planar bounding
/// box `((x0, y0), (x1, y1))`.
final class GeoPathBoundsStream() extends GeoStream {
  /// Creates a [GeoPathBoundsStream].
  this;

  double _x0 = double.infinity;
  double _y0 = double.infinity;
  double _x1 = double.negativeInfinity;
  double _y1 = double.negativeInfinity;

  @override
  void point(double x, double y, [double? z]) {
    if (x < _x0) _x0 = x;
    if (x > _x1) _x1 = x;
    if (y < _y0) _y0 = y;
    if (y > _y1) _y1 = y;
  }

  /// Returns the accumulated planar bounding box and resets to empty bounds.
  GeoExtent result() {
    final bounds = ((_x0, _y0), (_x1, _y1));
    _x0 = _y0 = double.infinity;
    _x1 = _y1 = double.negativeInfinity;
    return bounds;
  }
}
