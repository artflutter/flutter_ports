// Ported from d3-geo v3.1.1 src/path/index.js (ISC, Mike Bostock).

/// Port of `src/path/index.js` of d3-geo 3.1.1: [GeoPath] and [geoPath].
library;

import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/path/area.dart';
import 'package:flutter_d3_geo_port/src/path/bounds.dart';
import 'package:flutter_d3_geo_port/src/path/centroid.dart';
import 'package:flutter_d3_geo_port/src/path/context.dart';
import 'package:flutter_d3_geo_port/src/path/measure.dart';
import 'package:flutter_d3_geo_port/src/path/string.dart';
import 'package:flutter_d3_geo_port/src/stream.dart';
import 'package:flutter_d3_path_port/d3_path.dart';

/// Accessor computing the point radius for a rendered [GeoJsonObject].
typedef GeoPointRadiusAccessor = double Function(GeoJsonObject object);

/// `path/index.js:10` `geoPath`: geographic path generator and projected
/// planar geometry calculator (D3 ADR 0024).
// DIVERGES(d3-geo): adapt-geo-typed-api, typed GeoPath class with property
// getters/setters, typed pointRadiusAccessor, and direct draw(object, context).
// DIVERGES(d3-geo): adapt-geo-fast-forms, caches the GeoPathContext wrapper
// for draw(object, target) so repeated frames hit the projection stream cache.
final class GeoPath([
  GeoStreamable? initialProjection,
  CanvasPath? initialContext,
]) {
  /// Creates a [GeoPath] with optional [initialProjection] and
  /// [initialContext].
  this {
    projection = initialProjection;
    context = initialContext;
  }

  int? _digits = 3;
  double _pointRadius = 4.5;
  GeoPointRadiusAccessor? _pointRadiusAccessor;
  GeoStreamable? _projection;
  CanvasPath? _context;
  GeoStreamTransformer _projectionStream = geoStreamIdentity;
  late GeoPathSink _contextStream;

  CanvasPath? _lastDrawTarget;
  late GeoPathContext _lastDrawSink;

  final GeoPathAreaStream _areaStream = GeoPathAreaStream();
  final GeoPathMeasureStream _measureStream = GeoPathMeasureStream();
  final GeoPathBoundsStream _boundsStream = GeoPathBoundsStream();
  final GeoPathCentroidStream _centroidStream = GeoPathCentroidStream();

  /// Renders [object] into [context] (returning `null`), or returns an SVG
  /// path data string when [context] is `null` (returning `null` when empty or
  /// [object] is `null`).
  String? call([GeoJsonObject? object]) {
    if (object != null) {
      final fn = _pointRadiusAccessor;
      if (fn != null) _contextStream.setPointRadius(fn(object));
      geoStream(object, _projectionStream(_contextStream));
    }
    return _contextStream.result();
  }

  /// Renders [object] directly into [target] (such as a reusable
  /// `UiPathContext`) without mutating [context] and without SVG string
  /// allocation.
  void draw(GeoJsonObject? object, CanvasPath target) {
    if (object == null) return;
    final GeoPathContext sink;
    if (identical(_lastDrawTarget, target)) {
      sink = _lastDrawSink;
    } else {
      _lastDrawTarget = target;
      sink = _lastDrawSink = GeoPathContext(target);
    }
    final fn = _pointRadiusAccessor;
    sink.setPointRadius(fn != null ? fn(object) : _pointRadius);
    geoStream(object, _projectionStream(sink));
  }

  /// Computes the projected planar area of [object].
  double area(GeoJsonObject? object) {
    geoStream(object, _projectionStream(_areaStream));
    return _areaStream.result();
  }

  /// Computes the projected planar length (or polygon perimeter) of [object].
  double measure(GeoJsonObject? object) {
    geoStream(object, _projectionStream(_measureStream));
    return _measureStream.result();
  }

  /// Computes the projected planar bounding box `((x0, y0), (x1, y1))` of
  /// [object].
  GeoExtent bounds(GeoJsonObject? object) {
    geoStream(object, _projectionStream(_boundsStream));
    return _boundsStream.result();
  }

  /// Computes the projected planar centroid `(x, y)` of [object].
  GeoPosition centroid(GeoJsonObject? object) {
    geoStream(object, _projectionStream(_centroidStream));
    return _centroidStream.result();
  }

  /// Current projection or stream transform (`null` for identity).
  GeoStreamable? get projection => _projection;

  /// Sets the projection or stream transform (`null` resets to identity).
  set projection(GeoStreamable? value) {
    _projection = value;
    _projectionStream = value == null ? geoStreamIdentity : value.stream;
  }

  /// Current rendering [CanvasPath] context (`null` for SVG string output).
  CanvasPath? get context => _context;

  /// Sets the rendering [CanvasPath] context (`null` restores SVG output).
  set context(CanvasPath? value) {
    _context = value;
    _contextStream = value == null
        ? GeoPathString(_digits)
        : GeoPathContext(value);
    if (_pointRadiusAccessor == null) {
      _contextStream.setPointRadius(_pointRadius);
    }
  }

  /// Constant point display radius (default `4.5`).
  double get pointRadius => _pointRadius;

  /// Sets a constant point display radius and clears [pointRadiusAccessor].
  set pointRadius(double value) {
    _pointRadius = value;
    _pointRadiusAccessor = null;
    _contextStream.setPointRadius(value);
  }

  /// Optional per-object point radius accessor.
  GeoPointRadiusAccessor? get pointRadiusAccessor => _pointRadiusAccessor;

  /// Sets [pointRadiusAccessor].
  set pointRadiusAccessor(GeoPointRadiusAccessor? fn) {
    _pointRadiusAccessor = fn;
    if (fn == null) {
      _contextStream.setPointRadius(_pointRadius);
    }
  }

  /// Decimal digits used when formatting SVG path strings (default `3`, `null`
  /// for full precision).
  int? get digits => _digits;

  /// Sets decimal [digits] (`null` for full precision; negative throws
  /// [RangeError]).
  set digits(int? value) {
    if (value == null) {
      _digits = null;
    } else {
      if (value < 0) {
        throw RangeError.value(value, 'digits', 'invalid digits: $value');
      }
      _digits = value;
    }
    if (_context == null) {
      _contextStream = GeoPathString(_digits);
      if (_pointRadiusAccessor == null) {
        _contextStream.setPointRadius(_pointRadius);
      }
    }
  }
}

/// `path/index.js:10` `geoPath([projection, context])`: creates a new
/// [GeoPath] generator.
GeoPath geoPath([GeoStreamable? projection, CanvasPath? context]) =>
    GeoPath(projection, context);
