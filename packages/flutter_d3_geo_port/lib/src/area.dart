// Ported from d3-geo v3.1.1 src/area.js (ISC, Mike Bostock).

/// Port of `src/area.js` of d3-geo 3.1.1: [geoArea] and [GeoAreaStream].
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/stream.dart';

@pragma('vm:prefer-inline')
int _shewchukAdd(Float64List p, int n, double x) {
  final limit = n < 32 ? n : 32;
  var i = 0;
  var cur = x;
  for (var j = 0; j < limit; ++j) {
    final y = p[j];
    final hi = cur + y;
    final lo = cur.abs() < y.abs() ? cur - (hi - y) : y - (hi - cur);
    if (lo != 0) p[i++] = lo;
    cur = hi;
  }
  if (i < 32) {
    p[i] = cur;
    return i + 1;
  }
  return 32;
}

@pragma('vm:prefer-inline')
double _shewchukValue(Float64List p, int count) {
  var n = count;
  var hi = 0.0;
  if (n > 0) {
    hi = p[--n];
    var lo = 0.0;
    while (n > 0) {
      final x = hi;
      final y = p[--n];
      hi = x + y;
      lo = y - (hi - x);
      if (lo != 0) break;
    }
    if (n > 0 && ((lo < 0 && p[n - 1] < 0) || (lo > 0 && p[n - 1] > 0))) {
      final y = lo * 2.0;
      final x = hi + y;
      if (y == x - hi) hi = x;
    }
  }
  return hi;
}

/// Stream listener implementing spherical polygon area computation (Cagnoli's
/// theorem, `area.js:17`).
// DIVERGES(d3-geo): adapt-geo-typed-api, encapsulates areaStream state in a
// typed GeoStream class rather than module-level mutable JS globals.
// DIVERGES(d3-geo): adapt-geo-fast-forms, reuses fixed Float64List Shewchuk
// buffers across polygons to avoid per-polygon Adder allocations.
final class GeoAreaStream() extends GeoStream {
  /// Creates a [GeoAreaStream].
  this;

  final Float64List _sumPartials = Float64List(32);
  int _sumN = 0;
  final Float64List _ringPartials = Float64List(32);
  int _ringN = 0;

  double _lambda00 = 0;
  double _phi00 = 0;
  double _lambda0 = 0;
  double _cosPhi0 = 0;
  double _sinPhi0 = 0;

  // 0 = noop, 1 = first ring point, 2 = subsequent ring points.
  int _pointMode = 0;
  bool _inPolygon = false;

  /// The current ring sum value (used by `bounds.dart` after `polygonEnd`).
  double get areaRingSum => _shewchukValue(_ringPartials, _ringN);

  /// Resets the accumulated state for reuse.
  void reset() {
    _sumN = 0;
    _ringN = 0;
    _pointMode = 0;
    _inPolygon = false;
  }

  /// Returns the accumulated spherical area in steradians and resets the sum.
  double result() {
    final area = _shewchukValue(_sumPartials, _sumN) * 2;
    _sumN = 0;
    return area;
  }

  @override
  void point(double x, double y, [double? z]) {
    if (_pointMode == 2) {
      _areaPoint(x, y);
    } else if (_pointMode == 1) {
      _areaPointFirst(x, y);
    }
  }

  @override
  void lineStart() {
    if (_inPolygon) {
      _pointMode = 1;
    }
  }

  @override
  void lineEnd() {
    if (_inPolygon) {
      _areaPoint(_lambda00, _phi00);
    }
  }

  @override
  void polygonStart() {
    _ringN = 0;
    _inPolygon = true;
  }

  @override
  void polygonEnd() {
    final areaRing = _shewchukValue(_ringPartials, _ringN);
    _sumN = _shewchukAdd(
      _sumPartials,
      _sumN,
      areaRing < 0 ? geoTau + areaRing : areaRing,
    );
    _inPolygon = false;
    _pointMode = 0;
  }

  @override
  void sphere() {
    _sumN = _shewchukAdd(_sumPartials, _sumN, geoTau);
  }

  void _areaPointFirst(double lambda, double phi) {
    _pointMode = 2;
    _lambda00 = lambda;
    _phi00 = phi;
    final l = lambda * geoRadians;
    final p = phi * geoRadians / 2 + geoQuarterPi;
    _lambda0 = l;
    _cosPhi0 = math.cos(p);
    _sinPhi0 = math.sin(p);
  }

  void _areaPoint(double lambda, double phi) {
    final l = lambda * geoRadians;
    final p = phi * geoRadians / 2 + geoQuarterPi;
    final dLambda = l - _lambda0;
    final sdLambda = dLambda >= 0 ? 1.0 : -1.0;
    final adLambda = sdLambda * dLambda;
    final cosPhi = math.cos(p);
    final sinPhi = math.sin(p);
    final k = _sinPhi0 * sinPhi;
    final u = _cosPhi0 * cosPhi + k * math.cos(adLambda);
    final v = k * sdLambda * math.sin(adLambda);
    _ringN = _shewchukAdd(_ringPartials, _ringN, math.atan2(v, u));
    _lambda0 = l;
    _cosPhi0 = cosPhi;
    _sinPhi0 = sinPhi;
  }
}

// Reusable scratch buffers for direct unboxed geoArea fast paths.
final Float64List _directSum = Float64List(32);
final Float64List _directRing = Float64List(32);

int _accumulatePolygon(List<List<GeoPosition>> rings, int sumN) {
  final ringP = _directRing;
  var ringN = 0;
  for (var r = 0, rn = rings.length; r < rn; ++r) {
    final ring = rings[r];
    final m = ring.length - 1;
    if (m <= 0) continue;
    final first = ring[0];
    final l00 = first.$1 * geoRadians;
    final p00 = first.$2 * geoRadians / 2 + geoQuarterPi;
    final cos00 = math.cos(p00);
    final sin00 = math.sin(p00);
    var l0 = l00;
    var cos0 = cos00;
    var sin0 = sin00;
    for (var i = 1; i < m; ++i) {
      final pt = ring[i];
      final l = pt.$1 * geoRadians;
      final p = pt.$2 * geoRadians / 2 + geoQuarterPi;
      final dLambda = l - l0;
      final sdLambda = dLambda >= 0 ? 1.0 : -1.0;
      final adLambda = sdLambda * dLambda;
      final cosPhi = math.cos(p);
      final sinPhi = math.sin(p);
      final k = sin0 * sinPhi;
      final u = cos0 * cosPhi + k * math.cos(adLambda);
      final v = k * sdLambda * math.sin(adLambda);
      ringN = _shewchukAdd(ringP, ringN, math.atan2(v, u));
      l0 = l;
      cos0 = cosPhi;
      sin0 = sinPhi;
    }
    // Close ring back to first point (reusing cos00/sin00/l00).
    final dLambda = l00 - l0;
    final sdLambda = dLambda >= 0 ? 1.0 : -1.0;
    final adLambda = sdLambda * dLambda;
    final k = sin0 * sin00;
    final u = cos0 * cos00 + k * math.cos(adLambda);
    final v = k * sdLambda * math.sin(adLambda);
    ringN = _shewchukAdd(ringP, ringN, math.atan2(v, u));
  }
  final areaRing = _shewchukValue(ringP, ringN);
  return _shewchukAdd(
    _directSum,
    sumN,
    areaRing < 0 ? geoTau + areaRing : areaRing,
  );
}

int _accumulateGeometry(GeoGeometry? geometry, int sumN) {
  if (geometry == null) return sumN;
  switch (geometry) {
    case GeoSphere():
      return _shewchukAdd(_directSum, sumN, geoTau);
    case GeoPolygon(:final coordinates):
      return _accumulatePolygon(coordinates, sumN);
    case GeoMultiPolygon(:final coordinates):
      var n = sumN;
      for (var i = 0, len = coordinates.length; i < len; ++i) {
        n = _accumulatePolygon(coordinates[i], n);
      }
      return n;
    case GeoGeometryCollection(:final geometries):
      var n = sumN;
      for (var i = 0, len = geometries.length; i < len; ++i) {
        n = _accumulateGeometry(geometries[i], n);
      }
      return n;
    case GeoPoint() ||
        GeoMultiPoint() ||
        GeoLineString() ||
        GeoMultiLineString():
      return sumN;
  }
}

/// `area.js:72` `geoArea(object)`: returns the spherical area of the specified
/// GeoJSON [object] in steradians.
// DIVERGES(d3-geo): adapt-geo-fast-forms, walks GeoJSON polygon rings directly
// with unboxed Shewchuk accumulators and zero stream/Adder heap allocations.
double geoArea(GeoJsonObject? object) {
  if (object == null) return 0;
  var sumN = 0;
  switch (object) {
    case GeoFeature<Object?>(:final geometry):
      sumN = _accumulateGeometry(geometry, sumN);
    case GeoFeatureCollection<Object?>(:final features):
      for (var i = 0, len = features.length; i < len; ++i) {
        sumN = _accumulateGeometry(features[i].geometry, sumN);
      }
    case final GeoGeometry geometry:
      sumN = _accumulateGeometry(geometry, sumN);
  }
  return _shewchukValue(_directSum, sumN) * 2;
}
