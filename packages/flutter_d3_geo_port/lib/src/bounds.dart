// Ported from d3-geo v3.1.1 src/bounds.js (ISC, Mike Bostock).

/// Port of `src/bounds.js` of d3-geo 3.1.1: [geoBounds].
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_geo_port/src/area.dart';
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

final class _LonRange(double start, double end) {
  double start = start;
  double end = end;
}

@pragma('vm:prefer-inline')
double _angle(double lambda0, double lambda1) {
  final d = lambda1 - lambda0;
  return d < 0 ? d + 360 : d;
}

int _rangeCompare(_LonRange a, _LonRange b) => a.start.compareTo(b.start);

@pragma('vm:prefer-inline')
bool _rangeContains(_LonRange range, double x) => range.start <= range.end
    ? range.start <= x && x <= range.end
    : x < range.start || range.end < x;

// DIVERGES(d3-geo): adapt-geo-fast-forms, unboxes all 3D Cartesian vectors and
// delays inflection latitude asin/sqrt until the inflection longitude lies
// inside the edge interval; reuses a single scratch _BoundsStream instance.
final class _BoundsStream() extends GeoStream {
  final GeoAreaStream _areaStream = GeoAreaStream();
  final Float64List _deltaPartials = Float64List(32);
  int _deltaN = 0;

  double _lambda0 = double.infinity;
  double _phi0 = double.infinity;
  double _lambda1 = double.negativeInfinity;
  double _phi1 = double.negativeInfinity;

  double _lambda2 = 0;
  double _lambda00 = 0;
  double _phi00 = 0;
  bool _hasP0 = false;
  double _p0x = 0;
  double _p0y = 0;
  double _p0z = 0;

  final List<_LonRange> _ranges = <_LonRange>[];
  _LonRange? _range;

  // 0 = boundsPoint, 1 = linePoint, 2 = boundsRingPoint
  int _pointMode = 0;
  bool _inPolygon = false;

  void reset() {
    _areaStream.reset();
    _deltaN = 0;
    _lambda0 = double.infinity;
    _phi0 = double.infinity;
    _lambda1 = double.negativeInfinity;
    _phi1 = double.negativeInfinity;
    _lambda2 = 0;
    _lambda00 = 0;
    _phi00 = 0;
    _hasP0 = false;
    _ranges.clear();
    _range = null;
    _pointMode = 0;
    _inPolygon = false;
  }

  @override
  void point(double x, double y, [double? z]) {
    if (_pointMode == 2) {
      _boundsRingPoint(x, y);
    } else if (_pointMode == 1) {
      _linePoint(x, y);
    } else {
      _boundsPoint(x, y);
    }
  }

  @override
  void lineStart() {
    if (_inPolygon) {
      _areaStream.lineStart();
    } else {
      _pointMode = 1;
    }
  }

  @override
  void lineEnd() {
    if (_inPolygon) {
      _boundsRingPoint(_lambda00, _phi00);
      _areaStream.lineEnd();
      if (_shewchukValue(_deltaPartials, _deltaN).abs() > geoEpsilon) {
        _lambda0 = -(_lambda1 = 180);
      }
      final r = _range;
      if (r != null) {
        r
          ..start = _lambda0
          ..end = _lambda1;
      }
      _hasP0 = false;
    } else {
      final r = _range;
      if (r != null) {
        r
          ..start = _lambda0
          ..end = _lambda1;
      }
      _pointMode = 0;
      _hasP0 = false;
    }
  }

  @override
  void polygonStart() {
    _inPolygon = true;
    _pointMode = 2;
    _deltaN = 0;
    _areaStream.polygonStart();
  }

  @override
  void polygonEnd() {
    _areaStream.polygonEnd();
    _inPolygon = false;
    _pointMode = 0;
    if (_areaStream.areaRingSum < 0) {
      _lambda0 = -(_lambda1 = 180);
      _phi0 = -(_phi1 = 90);
    } else {
      final dVal = _shewchukValue(_deltaPartials, _deltaN);
      if (dVal > geoEpsilon) {
        _phi1 = 90;
      } else if (dVal < -geoEpsilon) {
        _phi0 = -90;
      }
    }
    final r = _range;
    if (r != null) {
      r
        ..start = _lambda0
        ..end = _lambda1;
    }
  }

  @override
  void sphere() {
    _lambda0 = -(_lambda1 = 180);
    _phi0 = -(_phi1 = 90);
  }

  void _boundsPoint(double lambda, double phi) {
    final r = _LonRange(_lambda0 = lambda, _lambda1 = lambda);
    _range = r;
    _ranges.add(r);
    if (phi < _phi0) _phi0 = phi;
    if (phi > _phi1) _phi1 = phi;
  }

  void _linePoint(double lambda, double phi) {
    final lRad = lambda * geoRadians;
    final pRad = phi * geoRadians;
    final cosP = math.cos(pRad);
    final px = cosP * math.cos(lRad);
    final py = cosP * math.sin(lRad);
    final pz = math.sin(pRad);

    if (_hasP0) {
      // normal = p0 x p
      final nx = _p0y * pz - _p0z * py;
      final ny = _p0z * px - _p0x * pz;
      final nz = _p0x * py - _p0y * px;
      // equatorial = (ny, -nx, 0);
      // equatorial x normal = (-nx*nz, -ny*nz, nx^2 + ny^2)
      final ix = -nx * nz;
      final iy = -ny * nz;
      final iz = nx * nx + ny * ny;

      final delta = lambda - _lambda2;
      final sign = delta > 0 ? 1.0 : -1.0;
      var lambdai = math.atan2(iy, ix) * geoDegrees * sign;
      final antimeridian = delta.abs() > 180;
      if (antimeridian !=
          (sign * _lambda2 < lambdai && lambdai < sign * lambda)) {
        final mag = math.sqrt(ix * ix + iy * iy + iz * iz);
        final phii = geoAsin(iz / mag) * geoDegrees;
        if (phii > _phi1) _phi1 = phii;
      } else {
        lambdai = (lambdai + 360).remainder(360) - 180;
        if (antimeridian !=
            (sign * _lambda2 < lambdai && lambdai < sign * lambda)) {
          final mag = math.sqrt(ix * ix + iy * iy + iz * iz);
          final phii = -geoAsin(iz / mag) * geoDegrees;
          if (phii < _phi0) _phi0 = phii;
        } else {
          if (phi < _phi0) _phi0 = phi;
          if (phi > _phi1) _phi1 = phi;
        }
      }
      if (antimeridian) {
        if (lambda < _lambda2) {
          if (_angle(_lambda0, lambda) > _angle(_lambda0, _lambda1)) {
            _lambda1 = lambda;
          }
        } else {
          if (_angle(lambda, _lambda1) > _angle(_lambda0, _lambda1)) {
            _lambda0 = lambda;
          }
        }
      } else {
        if (_lambda1 >= _lambda0) {
          if (lambda < _lambda0) _lambda0 = lambda;
          if (lambda > _lambda1) _lambda1 = lambda;
        } else {
          if (lambda > _lambda2) {
            if (_angle(_lambda0, lambda) > _angle(_lambda0, _lambda1)) {
              _lambda1 = lambda;
            }
          } else {
            if (_angle(lambda, _lambda1) > _angle(_lambda0, _lambda1)) {
              _lambda0 = lambda;
            }
          }
        }
      }
    } else {
      final r = _LonRange(_lambda0 = lambda, _lambda1 = lambda);
      _range = r;
      _ranges.add(r);
      _hasP0 = true;
    }
    if (phi < _phi0) _phi0 = phi;
    if (phi > _phi1) _phi1 = phi;
    _p0x = px;
    _p0y = py;
    _p0z = pz;
    _lambda2 = lambda;
  }

  void _boundsRingPoint(double lambda, double phi) {
    if (_hasP0) {
      final delta = lambda - _lambda2;
      _deltaN = _shewchukAdd(
        _deltaPartials,
        _deltaN,
        delta.abs() > 180 ? delta + (delta > 0 ? 360 : -360) : delta,
      );
    } else {
      _lambda00 = lambda;
      _phi00 = phi;
    }
    _areaStream.point(lambda, phi);
    _linePoint(lambda, phi);
  }

  GeoExtent finish() {
    final n = _ranges.length;
    if (n > 0) {
      _ranges.sort(_rangeCompare);

      var a = _ranges[0];
      final merged = <_LonRange>[a];
      for (var i = 1; i < n; ++i) {
        final b = _ranges[i];
        if (_rangeContains(a, b.start) || _rangeContains(a, b.end)) {
          if (_angle(a.start, b.end) > _angle(a.start, a.end)) a.end = b.end;
          if (_angle(b.start, a.end) > _angle(a.start, a.end)) {
            a.start = b.start;
          }
        } else {
          merged.add(a = b);
        }
      }

      var deltaMax = double.negativeInfinity;
      final last = merged.length - 1;
      a = merged[last];
      for (var i = 0; i <= last; ++i) {
        final b = merged[i];
        final delta = _angle(a.end, b.start);
        if (delta > deltaMax) {
          deltaMax = delta;
          _lambda0 = b.start;
          _lambda1 = a.end;
        }
        a = b;
      }
    }

    return _lambda0 == double.infinity || _phi0 == double.infinity
        ? ((double.nan, double.nan), (double.nan, double.nan))
        : ((_lambda0, _phi0), (_lambda1, _phi1));
  }
}

final _BoundsStream _sharedBoundsStream = _BoundsStream();

/// `bounds.js:144` `geoBounds(object)`: returns the spherical bounding box
/// `((lon0, lat0), (lon1, lat1))` in degrees for the specified GeoJSON
/// [object].
// DIVERGES(d3-geo): adapt-geo-typed-api, returns typed GeoExtent record.
GeoExtent geoBounds(GeoJsonObject? object) {
  final stream = _sharedBoundsStream..reset();
  geoStream(object, stream);
  return stream.finish();
}
