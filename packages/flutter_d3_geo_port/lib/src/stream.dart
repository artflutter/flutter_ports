// Ported from d3-geo v3.1.1 src/stream.js (ISC, Mike Bostock).

/// Port of `src/stream.js` of d3-geo 3.1.1: [GeoStream], [GeoStreamCallbacks],
/// [GeoStreamable], [GeoStreamTransformer], and [geoStream].
library;

import 'package:flutter_d3_geo_port/src/geojson.dart';

/// A geographic geometry stream listener (D3 ADR 0024).
///
/// Subclasses override any subset of the six GeoJSON stream events; default
/// implementations are no-ops.
// DIVERGES(d3-geo): adapt-geo-typed-api, abstract base class GeoStream with
// typed double coordinates replaces untyped JS stream objects.
abstract class const GeoStream() {
  /// Creates a [GeoStream].
  this;

  /// Receives a vertex `(x, y)` with optional third coordinate [z].
  void point(double x, double y, [double? z]) {}

  /// Begins a line or polygon ring.
  void lineStart() {}

  /// Ends a line or polygon ring.
  void lineEnd() {}

  /// Begins a polygon.
  void polygonStart() {}

  /// Ends a polygon.
  void polygonEnd() {}

  /// Indicates the whole sphere.
  void sphere() {}
}

/// A [GeoStream] backed by optional typed callback closures.
final class GeoStreamCallbacks({
  void Function(double x, double y, [double? z])? point,
  void Function()? lineStart,
  void Function()? lineEnd,
  void Function()? polygonStart,
  void Function()? polygonEnd,
  void Function()? sphere,
}) extends GeoStream {
  /// Creates a [GeoStreamCallbacks] dispatching to the supplied handlers.
  this;

  final void Function(double x, double y, [double? z])? _point = point;
  final void Function()? _lineStart = lineStart;
  final void Function()? _lineEnd = lineEnd;
  final void Function()? _polygonStart = polygonStart;
  final void Function()? _polygonEnd = polygonEnd;
  final void Function()? _sphere = sphere;

  @override
  void point(double x, double y, [double? z]) => _point?.call(x, y, z);

  @override
  void lineStart() => _lineStart?.call();

  @override
  void lineEnd() => _lineEnd?.call();

  @override
  void polygonStart() => _polygonStart?.call();

  @override
  void polygonEnd() => _polygonEnd?.call();

  @override
  void sphere() => _sphere?.call();
}

/// An object (projection, transform, or clip extent) that wraps a downstream
/// [GeoStream] sink.
abstract interface class GeoStreamable() {
  /// Returns a [GeoStream] that transforms events into [sink].
  GeoStream stream(GeoStream sink);
}

/// A function that wraps a downstream [GeoStream] sink.
typedef GeoStreamTransformer = GeoStream Function(GeoStream sink);

/// Identity [GeoStreamTransformer] returning [sink] unchanged.
@pragma('vm:prefer-inline')
GeoStream geoStreamIdentity(GeoStream sink) => sink;

void _streamLine(
  List<GeoPosition> coordinates,
  List<double?>? elevations,
  GeoStream stream,
  int closed,
) {
  final n = coordinates.length - closed;
  stream.lineStart();
  if (elevations == null) {
    for (var i = 0; i < n; ++i) {
      final c = coordinates[i];
      stream.point(c.$1, c.$2);
    }
  } else {
    final zn = elevations.length;
    for (var i = 0; i < n; ++i) {
      final c = coordinates[i];
      stream.point(c.$1, c.$2, i < zn ? elevations[i] : null);
    }
  }
  stream.lineEnd();
}

void _streamPolygon(
  List<List<GeoPosition>> coordinates,
  List<List<double?>?>? elevations,
  GeoStream stream,
) {
  final n = coordinates.length;
  stream.polygonStart();
  if (elevations == null) {
    for (var i = 0; i < n; ++i) {
      _streamLine(coordinates[i], null, stream, 1);
    }
  } else {
    final zn = elevations.length;
    for (var i = 0; i < n; ++i) {
      _streamLine(coordinates[i], i < zn ? elevations[i] : null, stream, 1);
    }
  }
  stream.polygonEnd();
}

void _streamGeometry(GeoGeometry? geometry, GeoStream stream) {
  if (geometry == null) return;
  switch (geometry) {
    case GeoSphere():
      stream.sphere();
    case GeoPoint(:final coordinates, :final elevation):
      stream.point(coordinates.$1, coordinates.$2, elevation);
    case GeoMultiPoint(:final coordinates, :final elevations):
      final n = coordinates.length;
      if (elevations == null) {
        for (var i = 0; i < n; ++i) {
          final c = coordinates[i];
          stream.point(c.$1, c.$2);
        }
      } else {
        final zn = elevations.length;
        for (var i = 0; i < n; ++i) {
          final c = coordinates[i];
          stream.point(c.$1, c.$2, i < zn ? elevations[i] : null);
        }
      }
    case GeoLineString(:final coordinates, :final elevations):
      _streamLine(coordinates, elevations, stream, 0);
    case GeoMultiLineString(:final coordinates, :final elevations):
      final n = coordinates.length;
      if (elevations == null) {
        for (var i = 0; i < n; ++i) {
          _streamLine(coordinates[i], null, stream, 0);
        }
      } else {
        final zn = elevations.length;
        for (var i = 0; i < n; ++i) {
          _streamLine(coordinates[i], i < zn ? elevations[i] : null, stream, 0);
        }
      }
    case GeoPolygon(:final coordinates, :final elevations):
      _streamPolygon(coordinates, elevations, stream);
    case GeoMultiPolygon(:final coordinates, :final elevations):
      final n = coordinates.length;
      if (elevations == null) {
        for (var i = 0; i < n; ++i) {
          _streamPolygon(coordinates[i], null, stream);
        }
      } else {
        final zn = elevations.length;
        for (var i = 0; i < n; ++i) {
          _streamPolygon(coordinates[i], i < zn ? elevations[i] : null, stream);
        }
      }
    case GeoGeometryCollection(:final geometries):
      final n = geometries.length;
      for (var i = 0; i < n; ++i) {
        _streamGeometry(geometries[i], stream);
      }
  }
}

/// `stream.js:63` `geoStream(object, stream)`: streams the specified GeoJSON
/// [object] to the specified [stream] listener.
void geoStream(GeoJsonObject? object, GeoStream stream) {
  if (object == null) return;
  switch (object) {
    case GeoFeature<Object?>(:final geometry):
      _streamGeometry(geometry, stream);
    case GeoFeatureCollection<Object?>(:final features):
      final n = features.length;
      for (var i = 0; i < n; ++i) {
        _streamGeometry(features[i].geometry, stream);
      }
    case final GeoGeometry geometry:
      _streamGeometry(geometry, stream);
  }
}
