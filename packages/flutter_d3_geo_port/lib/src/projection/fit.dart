// Ported from d3-geo v3.1.1 src/projection/fit.js (ISC, Mike Bostock).

/// Port of `src/projection/fit.js` of d3-geo 3.1.1: [GeoProjector],
/// [geoFitExtent], [geoFitSize], [geoFitWidth], and [geoFitHeight].
library;

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/path/bounds.dart';
import 'package:flutter_d3_geo_port/src/stream.dart';

/// Common interface implemented by all projections (`GeoProjection`,
/// `GeoIdentityProjection`, `GeoAlbersUsaProjection`) (D3 ADR 0024).
abstract interface class GeoProjector() implements GeoStreamable {
  /// Projects [coordinates] forward, or returns `null` if clipped/outside.
  GeoPosition? call(GeoPosition coordinates);

  /// Whether this projection supports [invert].
  bool get canInvert;

  /// Inverts planar [point] back to geographic coordinates, or returns `null`.
  GeoPosition? invert(GeoPosition point);

  /// Projection scale factor.
  double get scale;
  set scale(double value);

  /// Projection translation offset `(tx, ty)`.
  GeoPosition get translate;
  set translate(GeoPosition value);

  /// Whether this projection supports a configurable [clipExtent].
  bool get hasClipExtent;

  /// Optional viewport clip extent `((x0, y0), (x1, y1))`.
  GeoExtent? get clipExtent;
  set clipExtent(GeoExtent? value);

  /// Sets [scale] and [translate] to fit [object] inside [extent].
  void fitExtent(GeoExtent extent, GeoJsonObject object);

  /// Sets [scale] and [translate] to fit [object] inside `((0, 0), size)`.
  void fitSize(GeoPosition size, GeoJsonObject object);

  /// Sets [scale] and [translate] to fit [object] to [width].
  void fitWidth(double width, GeoJsonObject object);

  /// Sets [scale] and [translate] to fit [object] to [height].
  void fitHeight(double height, GeoJsonObject object);
}

void _fit(
  GeoProjector projection,
  void Function(GeoExtent bounds) fitBounds,
  GeoJsonObject object,
) {
  final clip = projection.hasClipExtent ? projection.clipExtent : null;
  projection
    ..scale = 150
    ..translate = const (0, 0);
  if (clip != null) projection.clipExtent = null;
  final boundsStream = GeoPathBoundsStream();
  geoStream(object, projection.stream(boundsStream));
  fitBounds(boundsStream.result());
  if (clip != null) projection.clipExtent = clip;
}

/// `projection/fit.js:14` `fitExtent(projection, extent, object)`.
void geoFitExtent(
  GeoProjector projection,
  GeoExtent extent,
  GeoJsonObject object,
) {
  _fit(projection, (b) {
    final w = extent.$2.$1 - extent.$1.$1;
    final h = extent.$2.$2 - extent.$1.$2;
    final k = math.min(w / (b.$2.$1 - b.$1.$1), h / (b.$2.$2 - b.$1.$2));
    final x = extent.$1.$1 + (w - k * (b.$2.$1 + b.$1.$1)) / 2;
    final y = extent.$1.$2 + (h - k * (b.$2.$2 + b.$1.$2)) / 2;
    projection
      ..scale = 150 * k
      ..translate = (x, y);
  }, object);
}

/// `projection/fit.js:25` `fitSize(projection, size, object)`.
void geoFitSize(
  GeoProjector projection,
  GeoPosition size,
  GeoJsonObject object,
) {
  geoFitExtent(projection, (const (0, 0), size), object);
}

/// `projection/fit.js:29` `fitWidth(projection, width, object)`.
void geoFitWidth(GeoProjector projection, double width, GeoJsonObject object) {
  _fit(projection, (b) {
    final k = width / (b.$2.$1 - b.$1.$1);
    final x = (width - k * (b.$2.$1 + b.$1.$1)) / 2;
    final y = -k * b.$1.$2;
    projection
      ..scale = 150 * k
      ..translate = (x, y);
  }, object);
}

/// `projection/fit.js:39` `fitHeight(projection, height, object)`.
void geoFitHeight(
  GeoProjector projection,
  double height,
  GeoJsonObject object,
) {
  _fit(projection, (b) {
    final k = height / (b.$2.$2 - b.$1.$2);
    final x = -k * b.$1.$1;
    final y = (height - k * (b.$2.$2 + b.$1.$2)) / 2;
    projection
      ..scale = 150 * k
      ..translate = (x, y);
  }, object);
}
