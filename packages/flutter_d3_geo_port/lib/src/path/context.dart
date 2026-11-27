// Ported from d3-geo v3.1.1 src/path/context.js (ISC, Mike Bostock).

/// Port of `src/path/context.js` of d3-geo 3.1.1: [GeoPathSink] and
/// [GeoPathContext].
library;

import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/stream.dart';
import 'package:flutter_d3_path_port/d3_path.dart';

/// Base stream sink shared by [GeoPathContext] and `GeoPathString`.
abstract class GeoPathSink() extends GeoStream {
  /// Creates a [GeoPathSink].
  this;

  /// Sets the radius used when rendering `Point` and `MultiPoint` geometries.
  void setPointRadius(double radius);

  /// Finalizes rendering and returns the SVG path string (or `null` for
  /// `CanvasPath` sinks or empty paths).
  String? result();
}

/// `path/context.js:4` `PathContext`: streams projected path geometry directly
/// into a [CanvasPath] (such as `Path` or Flutter `UiPathContext`).
final class GeoPathContext(final CanvasPath _context) extends GeoPathSink {
  /// Creates a [GeoPathContext] targeting [_context].
  this;

  double _radius = 4.5;
  int _line = -1;
  int _point = -1;

  @override
  void setPointRadius(double radius) {
    _radius = radius;
  }

  @override
  void polygonStart() {
    _line = 0;
  }

  @override
  void polygonEnd() {
    _line = -1;
  }

  @override
  void lineStart() {
    _point = 0;
  }

  @override
  void lineEnd() {
    if (_line == 0) _context.closePath();
    _point = -1;
  }

  @override
  void point(double x, double y, [double? z]) {
    if (_point == 0) {
      _context.moveTo(x, y);
      _point = 1;
    } else if (_point == 1) {
      _context.lineTo(x, y);
    } else {
      _context
        ..moveTo(x + _radius, y)
        ..arc(x, y, _radius, 0, geoTau);
    }
  }

  @override
  String? result() => null;
}
