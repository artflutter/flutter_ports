// Ported from d3-geo v3.1.1 src/clip/buffer.js (ISC, Mike Bostock).

/// Port of `src/clip/buffer.js` of d3-geo 3.1.1: [GeoClipPoint] and
/// [GeoClipBuffer].
library;

import 'package:flutter_d3_geo_port/src/stream.dart';

/// A buffered vertex `(x, y)` with optional clip marker [m] (`0`, `1`, `2`,
/// or `3`) used by polygon clipping and rejoining.
// DIVERGES(d3-geo): adapt-geo-typed-api, typed GeoClipPoint replaces 3-element
// JS array `[x, y, m]`.
final class GeoClipPoint(double x, double y, [int m = 0]) {
  /// Creates a [GeoClipPoint] at `([x], [y])` with clip marker [m].
  this;

  /// X or longitude coordinate.
  double x = x;

  /// Y or latitude coordinate.
  double y = y;

  /// Clip intersection marker (`0` if unmarked).
  int m = m;
}

/// `clip/buffer.js:3` default export: a [GeoStream] that buffers clipped line
/// segments as `List<List<GeoClipPoint>>`.
final class GeoClipBuffer() extends GeoStream {
  /// Creates an empty [GeoClipBuffer].
  this;

  List<List<GeoClipPoint>> _lines = <List<GeoClipPoint>>[];
  List<GeoClipPoint>? _line;

  @override
  void point(double x, double y, [double? z]) {
    _line!.add(GeoClipPoint(x, y, z == null ? 0 : z.toInt()));
  }

  @override
  void lineStart() {
    final next = <GeoClipPoint>[];
    _line = next;
    _lines.add(next);
  }

  /// Rejoins the last and first segments when a closed ring crossed the clip
  /// boundary and remained visible at the closure seam.
  void rejoin() {
    if (_lines.length > 1) {
      final last = _lines.removeLast();
      final first = _lines.removeAt(0);
      last.addAll(first);
      _lines.add(last);
    }
  }

  /// Returns the buffered segments and resets the buffer.
  List<List<GeoClipPoint>> result() {
    final res = _lines;
    _lines = <List<GeoClipPoint>>[];
    _line = null;
    return res;
  }
}

/// Creates a new [GeoClipBuffer].
GeoClipBuffer geoClipBuffer() => GeoClipBuffer();
