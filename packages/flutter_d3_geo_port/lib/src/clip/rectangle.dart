// Ported from d3-geo v3.1.1 src/clip/rectangle.js (ISC, Mike Bostock).

/// Port of `src/clip/rectangle.js` of d3-geo 3.1.1: [geoClipRectangle].
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_geo_port/src/clip/buffer.dart';
import 'package:flutter_d3_geo_port/src/clip/line.dart';
import 'package:flutter_d3_geo_port/src/clip/rejoin.dart';
import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/stream.dart';

const double _clipMax = 1000000000;
const double _clipMin = -_clipMax;

/// `clip/rectangle.js:12` `geoClipRectangle(x0, y0, x1, y1)`: returns a planar
/// axis-aligned rectangle clipping [GeoStreamTransformer].
GeoStreamTransformer geoClipRectangle(
  double x0,
  double y0,
  double x1,
  double y1,
) {
  int corner(double px, double py, double direction) {
    if ((px - x0).abs() < geoEpsilon) return direction > 0 ? 0 : 3;
    if ((px - x1).abs() < geoEpsilon) return direction > 0 ? 2 : 1;
    if ((py - y0).abs() < geoEpsilon) return direction > 0 ? 1 : 0;
    return direction > 0 ? 3 : 2;
  }

  double comparePointCoords(double ax, double ay, double bx, double by) {
    final ca = corner(ax, ay, 1);
    final cb = corner(bx, by, 1);
    if (ca != cb) return (ca - cb).toDouble();
    return switch (ca) {
      0 => by - ay,
      1 => ax - bx,
      2 => ay - by,
      _ => bx - ax,
    };
  }

  int compareIntersection(GeoClipIntersection a, GeoClipIntersection b) {
    final d = comparePointCoords(a.x.x, a.x.y, b.x.x, b.x.y);
    return d < 0 ? -1 : (d > 0 ? 1 : 0);
  }

  void interpolate(
    GeoPosition? from,
    GeoPosition? to,
    double direction,
    GeoStream stream,
  ) {
    var a = 0;
    var a1 = 0;
    final dirInt = direction > 0 ? 1 : -1;
    if (from == null ||
        (a = corner(from.$1, from.$2, direction)) !=
            (a1 = corner(to!.$1, to.$2, direction)) ||
        (comparePointCoords(from.$1, from.$2, to.$1, to.$2) < 0) !=
            (direction > 0)) {
      do {
        stream.point(a == 0 || a == 3 ? x0 : x1, a > 1 ? y1 : y0);
      } while ((a = (a + dirInt + 4) % 4) != a1);
    } else {
      stream.point(to.$1, to.$2);
    }
  }

  return (stream) => _ClipRectangleStream(
    stream,
    x0: x0,
    y0: y0,
    x1: x1,
    y1: y1,
    compareIntersection: compareIntersection,
    interpolate: interpolate,
  );
}

// DIVERGES(d3-geo): adapt-geo-fast-forms, buffers polygon rings in reusable
// flat Float64Lists and reuses scratch GeoClipPoint endpoints in _linePoint.
final class _ClipRectangleStream(
  final GeoStream _stream, {
  required final double x0,
  required final double y0,
  required final double x1,
  required final double y1,
  required final int Function(GeoClipIntersection a, GeoClipIntersection b)
  compareIntersection,
  required final GeoClipInterpolate interpolate,
}) extends GeoStream {
  GeoStream _activeStream = _stream;
  final GeoClipBuffer _bufferStream = geoClipBuffer();
  final List<List<GeoClipPoint>> _flatSegments = <List<GeoClipPoint>>[];
  final List<Float64List> _rings = <Float64List>[];
  final List<int> _ringCounts = <int>[];
  int _numRings = 0;
  Float64List _curRing = Float64List(0);
  int _curLen = 0;
  bool _inPolygon = false;

  final GeoClipPoint _segA = GeoClipPoint(0, 0);
  final GeoClipPoint _segB = GeoClipPoint(0, 0);

  double _x00 = 0;
  double _y00 = 0;
  bool _v00 = false;
  double _xPrev = double.nan;
  double _yPrev = double.nan;
  bool _vPrev = false;
  bool _first = true;
  bool _clean = true;
  bool _inLine = false;

  @pragma('vm:prefer-inline')
  bool _visible(double x, double y) => x0 <= x && x <= x1 && y0 <= y && y <= y1;

  @override
  void point(double x, double y, [double? z]) {
    if (_inLine) {
      _linePoint(x, y);
    } else if (_visible(x, y)) {
      _activeStream.point(x, y);
    }
  }

  int _polygonInside() {
    var winding = 0;
    for (var i = 0; i < _numRings; ++i) {
      final ring = _rings[i];
      final m2 = _ringCounts[i];
      if (m2 == 0) continue;
      var b0 = ring[0];
      var b1 = ring[1];
      for (var j = 2; j < m2; j += 2) {
        final a0 = b0;
        final a1 = b1;
        b0 = ring[j];
        b1 = ring[j + 1];
        if (a1 <= y1) {
          if (b1 > y1 && (b0 - a0) * (y1 - a1) > (b1 - a1) * (x0 - a0)) {
            ++winding;
          }
        } else {
          if (b1 <= y1 && (b0 - a0) * (y1 - a1) < (b1 - a1) * (x0 - a0)) {
            --winding;
          }
        }
      }
    }
    return winding;
  }

  @override
  void polygonStart() {
    _activeStream = _bufferStream;
    _inPolygon = true;
    _numRings = 0;
    _flatSegments.clear();
    _clean = true;
  }

  @override
  void polygonEnd() {
    final startInside = _polygonInside() != 0;
    final cleanInside = _clean && startInside;
    final hasVisible = _flatSegments.isNotEmpty;
    if (cleanInside || hasVisible) {
      _stream.polygonStart();
      if (cleanInside) {
        _stream.lineStart();
        interpolate(null, null, 1, _stream);
        _stream.lineEnd();
      }
      if (hasVisible) {
        geoClipRejoin(
          _flatSegments,
          compareIntersection,
          startInside,
          interpolate,
          _stream,
        );
      }
      _stream.polygonEnd();
    }
    _activeStream = _stream;
    _inPolygon = false;
    _numRings = 0;
    _flatSegments.clear();
  }

  @override
  void lineStart() {
    _inLine = true;
    if (_inPolygon) {
      if (_numRings < _rings.length) {
        _curRing = _rings[_numRings];
      } else {
        _curRing = Float64List(64);
        _rings.add(_curRing);
        _ringCounts.add(0);
      }
      _curLen = 0;
    }
    _first = true;
    _vPrev = false;
    _xPrev = double.nan;
    _yPrev = double.nan;
  }

  @override
  void lineEnd() {
    if (_inPolygon) {
      _linePoint(_x00, _y00);
      if (_v00 && _vPrev) _bufferStream.rejoin();
      final res = _bufferStream.result();
      for (var i = 0, n = res.length; i < n; ++i) {
        _flatSegments.add(res[i]);
      }
      _ringCounts[_numRings] = _curLen;
      _numRings++;
    }
    _inLine = false;
    if (_vPrev) _activeStream.lineEnd();
  }

  void _linePoint(double x, double y) {
    final v = _visible(x, y);
    if (_inPolygon) {
      final len = _curLen;
      var ring = _curRing;
      if (len + 2 > ring.length) {
        final grown = Float64List(ring.length * 2)..setRange(0, len, ring);
        ring = grown;
        _curRing = grown;
        _rings[_numRings] = grown;
      }
      ring[len] = x;
      ring[len + 1] = y;
      _curLen = len + 2;
    }
    if (_first) {
      _x00 = x;
      _y00 = y;
      _v00 = v;
      _first = false;
      if (v) {
        _activeStream
          ..lineStart()
          ..point(x, y);
      }
    } else {
      if (v && _vPrev) {
        _activeStream.point(x, y);
      } else {
        _xPrev = math.max(_clipMin, math.min(_clipMax, _xPrev));
        _yPrev = math.max(_clipMin, math.min(_clipMax, _yPrev));
        final cx = math.max(_clipMin, math.min(_clipMax, x));
        final cy = math.max(_clipMin, math.min(_clipMax, y));
        final a = _segA
          ..x = _xPrev
          ..y = _yPrev;
        final b = _segB
          ..x = cx
          ..y = cy;
        if (geoClipLineSegment(a, b, x0, y0, x1, y1)) {
          if (!_vPrev) {
            _activeStream
              ..lineStart()
              ..point(a.x, a.y);
          }
          _activeStream.point(b.x, b.y);
          if (!v) _activeStream.lineEnd();
          _clean = false;
        } else if (v) {
          _activeStream
            ..lineStart()
            ..point(cx, cy);
          _clean = false;
        }
        _xPrev = cx;
        _yPrev = cy;
        _vPrev = v;
        return;
      }
    }
    _xPrev = x;
    _yPrev = y;
    _vPrev = v;
  }
}
