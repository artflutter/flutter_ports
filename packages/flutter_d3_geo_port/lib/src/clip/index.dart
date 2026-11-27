// Ported from d3-geo v3.1.1 src/clip/index.js (ISC, Mike Bostock).

/// Port of `src/clip/index.js` of d3-geo 3.1.1: generic spherical clip stream
/// builder [geoClip] and [GeoClipLineStream].
library;

import 'dart:typed_data';

import 'package:flutter_d3_geo_port/src/clip/buffer.dart';
import 'package:flutter_d3_geo_port/src/clip/rejoin.dart';
import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/polygonContains.dart';
import 'package:flutter_d3_geo_port/src/stream.dart';

/// A line-clipping stream used by spherical clippers (`geoClipAntimeridian`,
/// `geoClipCircle`) that also reports a `clean` bitmask after `lineEnd`.
abstract class GeoClipLineStream() extends GeoStream {
  /// Creates a [GeoClipLineStream].
  this;

  /// Returns the clean-ness bitmask for the last clipped ring:
  /// bit 0 (`1`) = no intersections, bit 1 (`2`) = rejoin first & last
  /// segments.
  int clean();
}

int _compareIntersection(GeoClipIntersection a, GeoClipIntersection b) {
  final ax = a.x;
  final bx = b.x;
  final va = ax.x < 0 ? ax.y - geoHalfPi - geoEpsilon : geoHalfPi - ax.y;
  final vb = bx.x < 0 ? bx.y - geoHalfPi - geoEpsilon : geoHalfPi - bx.y;
  final d = va - vb;
  return d < 0 ? -1 : (d > 0 ? 1 : 0);
}

/// `clip/index.js:7` default export: builds a spherical [GeoStreamTransformer]
/// from [pointVisible], [clipLine], [interpolate], and boundary [start] point.
GeoStreamTransformer geoClip(
  bool Function(double lambda, double phi) pointVisible,
  GeoClipLineStream Function(GeoStream sink) clipLine,
  GeoClipInterpolate interpolate,
  GeoPosition start,
) =>
    (sink) => _ClipStream(sink, pointVisible, clipLine, interpolate, start);

// DIVERGES(d3-geo): adapt-geo-fast-forms, buffers polygon rings in reusable
// flat Float64Lists and avoids allocating flatSegments when all rings are
// clean.
final class _ClipStream(
  final GeoStream _sink,
  final bool Function(double lambda, double phi) _pointVisible,
  GeoClipLineStream Function(GeoStream sink) clipLine,
  final GeoClipInterpolate _interpolate,
  GeoPosition start,
) extends GeoStream {
  this {
    _ringSink = clipLine(_ringBuffer);
  }

  final GeoClipLineStream _line = clipLine(_sink);
  final GeoClipBuffer _ringBuffer = geoClipBuffer();
  late final GeoClipLineStream _ringSink;
  final double _startLon = start.$1;
  final double _startLat = start.$2;

  bool _polygonStarted = false;
  final List<Float64List> _rings = <Float64List>[];
  final List<int> _ringCounts = <int>[];
  int _numRings = 0;

  Float64List _curRing = Float64List(0);
  int _curLen = 0;

  final List<List<GeoClipPoint>> _flatSegments = <List<GeoClipPoint>>[];

  // 0 = point, 1 = pointLine, 2 = pointRing
  int _mode = 0;
  bool _inPolygon = false;

  @override
  void point(double x, double y, [double? z]) {
    if (_mode == 2) {
      _pointRing(x, y);
    } else if (_mode == 1) {
      _line.point(x, y);
    } else if (_pointVisible(x, y)) {
      _sink.point(x, y);
    }
  }

  @override
  void lineStart() {
    if (_inPolygon) {
      _ringSink.lineStart();
      if (_numRings < _rings.length) {
        _curRing = _rings[_numRings];
      } else {
        _curRing = Float64List(64);
        _rings.add(_curRing);
        _ringCounts.add(0);
      }
      _curLen = 0;
    } else {
      _mode = 1;
      _line.lineStart();
    }
  }

  @override
  void lineEnd() {
    if (_inPolygon) {
      _ringEnd();
    } else {
      _mode = 0;
      _line.lineEnd();
    }
  }

  @override
  void polygonStart() {
    _inPolygon = true;
    _mode = 2;
    _numRings = 0;
    _flatSegments.clear();
  }

  @override
  void polygonEnd() {
    _inPolygon = false;
    _mode = 0;
    final startInside = geoPolygonContainsFlat(
      _rings,
      _ringCounts,
      _numRings,
      _startLon,
      _startLat,
    );
    if (_flatSegments.isNotEmpty) {
      if (!_polygonStarted) {
        _sink.polygonStart();
        _polygonStarted = true;
      }
      geoClipRejoin(
        _flatSegments,
        _compareIntersection,
        startInside,
        _interpolate,
        _sink,
      );
      _flatSegments.clear();
    } else if (startInside) {
      if (!_polygonStarted) {
        _sink.polygonStart();
        _polygonStarted = true;
      }
      _sink.lineStart();
      _interpolate(null, null, 1, _sink);
      _sink.lineEnd();
    }
    if (_polygonStarted) {
      _sink.polygonEnd();
      _polygonStarted = false;
    }
    _numRings = 0;
  }

  @override
  void sphere() {
    _sink
      ..polygonStart()
      ..lineStart();
    _interpolate(null, null, 1, _sink);
    _sink
      ..lineEnd()
      ..polygonEnd();
  }

  void _pointRing(double lambda, double phi) {
    final len = _curLen;
    var ring = _curRing;
    if (len + 2 > ring.length) {
      final grown = Float64List(ring.length * 2)..setRange(0, len, ring);
      ring = grown;
      _curRing = grown;
      _rings[_numRings] = grown;
    }
    ring[len] = lambda;
    ring[len + 1] = phi;
    _curLen = len + 2;
    _ringSink.point(lambda, phi);
  }

  void _ringEnd() {
    final len = _curLen;
    if (len > 0) {
      _pointRing(_curRing[0], _curRing[1]);
    }
    _ringSink.lineEnd();

    final clean = _ringSink.clean();
    final ringSegments = _ringBuffer.result();
    final n = ringSegments.length;

    // Pop duplicated closing vertex from flat ring buffer.
    _ringCounts[_numRings] = len;
    _numRings++;

    if (n == 0) return;

    if ((clean & 1) != 0) {
      final segment = ringSegments[0];
      final m = segment.length - 1;
      if (m > 0) {
        if (!_polygonStarted) {
          _sink.polygonStart();
          _polygonStarted = true;
        }
        _sink.lineStart();
        for (var i = 0; i < m; ++i) {
          final pt = segment[i];
          _sink.point(pt.x, pt.y);
        }
        _sink.lineEnd();
      }
      return;
    }

    if (n > 1 && (clean & 2) != 0) {
      final last = ringSegments.removeLast();
      final first = ringSegments.removeAt(0);
      last.addAll(first);
      ringSegments.add(last);
    }

    for (var i = 0, len = ringSegments.length; i < len; ++i) {
      final seg = ringSegments[i];
      if (seg.length > 1) _flatSegments.add(seg);
    }
  }
}
