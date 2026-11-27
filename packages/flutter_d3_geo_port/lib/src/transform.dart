// Ported from d3-geo v3.1.1 src/transform.js (ISC, Mike Bostock).

/// Port of `src/transform.js` of d3-geo 3.1.1: [GeoTransform],
/// [GeoTransformStream], [geoTransform], and [geoTransformer].
library;

import 'package:flutter_d3_geo_port/src/stream.dart';

/// Base class for a [GeoStream] that forwards events to a downstream [stream].
// DIVERGES(d3-geo): adapt-geo-typed-api, typed GeoTransformStream and
// GeoTransform replace JS prototype-copying transformer(methods).
class GeoTransformStream(
  /// Downstream sink stream.
  final GeoStream stream,
) extends GeoStream {
  /// Creates a [GeoTransformStream] forwarding to [stream].
  this;

  @override
  void point(double x, double y, [double? z]) => stream.point(x, y, z);

  @override
  void sphere() => stream.sphere();

  @override
  void lineStart() => stream.lineStart();

  @override
  void lineEnd() => stream.lineEnd();

  @override
  void polygonStart() => stream.polygonStart();

  @override
  void polygonEnd() => stream.polygonEnd();
}

/// A custom stream transform created by [geoTransform].
final class GeoTransform(final GeoStreamTransformer _transformer)
    implements GeoStreamable {
  /// Creates a [GeoTransform] wrapping [_transformer].
  this;

  @override
  GeoStream stream(GeoStream sink) => _transformer(sink);
}

/// `transform.js:7` `transformer(methods)`: creates a [GeoStreamTransformer]
/// from optional typed stream event overrides.
GeoStreamTransformer geoTransformer({
  void Function(GeoStream stream, double x, double y, [double? z])? point,
  void Function(GeoStream stream)? sphere,
  void Function(GeoStream stream)? lineStart,
  void Function(GeoStream stream)? lineEnd,
  void Function(GeoStream stream)? polygonStart,
  void Function(GeoStream stream)? polygonEnd,
}) =>
    (sink) => _CallbackTransformStream(
      sink,
      point: point,
      sphere: sphere,
      lineStart: lineStart,
      lineEnd: lineEnd,
      polygonStart: polygonStart,
      polygonEnd: polygonEnd,
    );

/// `transform.js:1` `geoTransform(methods)`: defines a custom [GeoTransform]
/// suitable for `geoPath(projection: ...)` and stream pipelines.
GeoTransform geoTransform({
  void Function(GeoStream stream, double x, double y, [double? z])? point,
  void Function(GeoStream stream)? sphere,
  void Function(GeoStream stream)? lineStart,
  void Function(GeoStream stream)? lineEnd,
  void Function(GeoStream stream)? polygonStart,
  void Function(GeoStream stream)? polygonEnd,
}) => GeoTransform(
  geoTransformer(
    point: point,
    sphere: sphere,
    lineStart: lineStart,
    lineEnd: lineEnd,
    polygonStart: polygonStart,
    polygonEnd: polygonEnd,
  ),
);

final class _CallbackTransformStream(
  super.stream, {
  void Function(GeoStream stream, double x, double y, [double? z])? point,
  void Function(GeoStream stream)? sphere,
  void Function(GeoStream stream)? lineStart,
  void Function(GeoStream stream)? lineEnd,
  void Function(GeoStream stream)? polygonStart,
  void Function(GeoStream stream)? polygonEnd,
}) extends GeoTransformStream {
  final void Function(GeoStream stream, double x, double y, [double? z])?
  _point = point;
  final void Function(GeoStream stream)? _sphere = sphere;
  final void Function(GeoStream stream)? _lineStart = lineStart;
  final void Function(GeoStream stream)? _lineEnd = lineEnd;
  final void Function(GeoStream stream)? _polygonStart = polygonStart;
  final void Function(GeoStream stream)? _polygonEnd = polygonEnd;

  @override
  void point(double x, double y, [double? z]) {
    final fn = _point;
    if (fn != null) {
      fn(stream, x, y, z);
    } else {
      stream.point(x, y, z);
    }
  }

  @override
  void sphere() {
    final fn = _sphere;
    if (fn != null) {
      fn(stream);
    } else {
      stream.sphere();
    }
  }

  @override
  void lineStart() {
    final fn = _lineStart;
    if (fn != null) {
      fn(stream);
    } else {
      stream.lineStart();
    }
  }

  @override
  void lineEnd() {
    final fn = _lineEnd;
    if (fn != null) {
      fn(stream);
    } else {
      stream.lineEnd();
    }
  }

  @override
  void polygonStart() {
    final fn = _polygonStart;
    if (fn != null) {
      fn(stream);
    } else {
      stream.polygonStart();
    }
  }

  @override
  void polygonEnd() {
    final fn = _polygonEnd;
    if (fn != null) {
      fn(stream);
    } else {
      stream.polygonEnd();
    }
  }
}
