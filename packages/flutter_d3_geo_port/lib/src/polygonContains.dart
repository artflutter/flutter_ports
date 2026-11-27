// Ported from d3-geo v3.1.1 src/polygonContains.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/polygonContains.js` of d3-geo 3.1.1.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/math.dart';

// Reusable Shewchuk expansion scratch buffer (synchronous leaf calls only).
final Float64List _partials = Float64List(32);

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

@pragma('vm:prefer-inline')
double _wrapLon(double lon) => lon.abs() <= geoPi
    ? lon
    : geoSign(lon) * ((lon.abs() + geoPi).remainder(geoTau) - geoPi);

/// Unboxed meridian-crossing winding increment for edge `(l0, p0) -> (l1, p1)`.
@pragma('vm:prefer-inline')
int _crossingWinding(
  double l0,
  double p0,
  double l1,
  double p1,
  double nx,
  double ny,
  double phi,
  bool antimeridian,
  double delta,
) {
  final cp0 = math.cos(p0);
  final ax = cp0 * math.cos(l0);
  final ay = cp0 * math.sin(l0);
  final az = math.sin(p0);
  final cp1 = math.cos(p1);
  final bx = cp1 * math.cos(l1);
  final by = cp1 * math.sin(l1);
  final bz = math.sin(p1);

  // arc = normalize(a x b)
  var cx = ay * bz - az * by;
  var cy = az * bx - ax * bz;
  var cz = ax * by - ay * bx;
  final cm = math.sqrt(cx * cx + cy * cy + cz * cz);
  cx /= cm;
  cy /= cm;
  cz /= cm;

  // intersection = normalize(normal x arc), where normal = (nx, ny, 0)
  final ix = ny * cz;
  final iy = -nx * cz;
  final iz = nx * cy - ny * cx;
  final im = math.sqrt(ix * ix + iy * iy + iz * iz);
  final izn = iz / im;

  final rev = antimeridian != (delta >= 0);
  final phiArc = (rev ? -1.0 : 1.0) * geoAsin(izn);
  if (phi > phiArc || (phi == phiArc && (cx != 0 || cy != 0))) {
    return rev ? 1 : -1;
  }
  return 0;
}

/// `polygonContains.js:9` default export: tests whether spherical [polygon]
/// (open rings in radians) contains spherical [point] `(lambda, phi)` in
/// radians.
// DIVERGES(d3-geo): adapt-geo-typed-api, returns bool instead of JS 0/1 int.
// DIVERGES(d3-geo): adapt-geo-fast-forms, uses unboxed Cartesian math and
// reusable Shewchuk scratch buffer.
bool geoPolygonContains(List<List<GeoPosition>> polygon, GeoPosition point) {
  final lambda = _wrapLon(point.$1);
  var phi = point.$2;
  final sinPhi = math.sin(phi);
  final nx = math.sin(lambda);
  final ny = -math.cos(lambda);
  var angle = 0.0;
  var winding = 0;

  final p = _partials;
  var pn = 0;

  if (sinPhi == 1) {
    phi = geoHalfPi + geoEpsilon;
  } else if (sinPhi == -1) {
    phi = -geoHalfPi - geoEpsilon;
  }

  for (var i = 0, n = polygon.length; i < n; ++i) {
    final ring = polygon[i];
    final m = ring.length;
    if (m == 0) continue;

    final last = ring[m - 1];
    var rawL0 = last.$1;
    var rawP0 = last.$2;
    var lambda0 = _wrapLon(rawL0);
    final phi0 = rawP0 / 2 + geoQuarterPi;
    var sinPhi0 = math.sin(phi0);
    var cosPhi0 = math.cos(phi0);

    for (var j = 0; j < m; ++j) {
      final pt = ring[j];
      final rawL1 = pt.$1;
      final rawP1 = pt.$2;
      final lambda1 = _wrapLon(rawL1);
      final phi1 = rawP1 / 2 + geoQuarterPi;
      final sinPhi1 = math.sin(phi1);
      final cosPhi1 = math.cos(phi1);
      final delta = lambda1 - lambda0;
      final sign = delta >= 0 ? 1.0 : -1.0;
      final absDelta = sign * delta;
      final antimeridian = absDelta > geoPi;
      final k = sinPhi0 * sinPhi1;

      pn = _shewchukAdd(
        p,
        pn,
        math.atan2(
          k * sign * math.sin(absDelta),
          cosPhi0 * cosPhi1 + k * math.cos(absDelta),
        ),
      );
      angle += antimeridian ? delta + sign * geoTau : delta;

      if ((antimeridian != (lambda0 >= lambda)) != (lambda1 >= lambda)) {
        winding += _crossingWinding(
          rawL0,
          rawP0,
          rawL1,
          rawP1,
          nx,
          ny,
          phi,
          antimeridian,
          delta,
        );
      }

      lambda0 = lambda1;
      sinPhi0 = sinPhi1;
      cosPhi0 = cosPhi1;
      rawL0 = rawL1;
      rawP0 = rawP1;
    }
  }

  return (angle < -geoEpsilon ||
          (angle < geoEpsilon && _shewchukValue(p, pn) < -geoEpsilon2)) !=
      ((winding & 1) != 0);
}

/// Zero-allocation spherical containment test directly over closed GeoJSON
/// rings in degrees (avoids allocating radian ring copies in `geoContains`).
// DIVERGES(d3-geo): adapt-geo-fast-forms, converts degree rings inline without
// intermediate List<List<GeoPosition>> allocation.
bool geoPolygonContainsDegrees(
  List<List<GeoPosition>> polygon,
  double lonDeg,
  double latDeg,
) {
  final lambda = _wrapLon(lonDeg * geoRadians);
  var phi = latDeg * geoRadians;
  final sinPhi = math.sin(phi);
  final nx = math.sin(lambda);
  final ny = -math.cos(lambda);
  var angle = 0.0;
  var winding = 0;

  final p = _partials;
  var pn = 0;

  if (sinPhi == 1) {
    phi = geoHalfPi + geoEpsilon;
  } else if (sinPhi == -1) {
    phi = -geoHalfPi - geoEpsilon;
  }

  for (var i = 0, n = polygon.length; i < n; ++i) {
    final ring = polygon[i];
    final m = ring.length - 1;
    if (m <= 0) continue;

    final last = ring[m - 1];
    var rawL0 = last.$1 * geoRadians;
    var rawP0 = last.$2 * geoRadians;
    var lambda0 = _wrapLon(rawL0);
    final phi0 = rawP0 / 2 + geoQuarterPi;
    var sinPhi0 = math.sin(phi0);
    var cosPhi0 = math.cos(phi0);

    for (var j = 0; j < m; ++j) {
      final pt = ring[j];
      final rawL1 = pt.$1 * geoRadians;
      final rawP1 = pt.$2 * geoRadians;
      final lambda1 = _wrapLon(rawL1);
      final phi1 = rawP1 / 2 + geoQuarterPi;
      final sinPhi1 = math.sin(phi1);
      final cosPhi1 = math.cos(phi1);
      final delta = lambda1 - lambda0;
      final sign = delta >= 0 ? 1.0 : -1.0;
      final absDelta = sign * delta;
      final antimeridian = absDelta > geoPi;
      final k = sinPhi0 * sinPhi1;

      pn = _shewchukAdd(
        p,
        pn,
        math.atan2(
          k * sign * math.sin(absDelta),
          cosPhi0 * cosPhi1 + k * math.cos(absDelta),
        ),
      );
      angle += antimeridian ? delta + sign * geoTau : delta;

      if ((antimeridian != (lambda0 >= lambda)) != (lambda1 >= lambda)) {
        winding += _crossingWinding(
          rawL0,
          rawP0,
          rawL1,
          rawP1,
          nx,
          ny,
          phi,
          antimeridian,
          delta,
        );
      }

      lambda0 = lambda1;
      sinPhi0 = sinPhi1;
      cosPhi0 = cosPhi1;
      rawL0 = rawL1;
      rawP0 = rawP1;
    }
  }

  return (angle < -geoEpsilon ||
          (angle < geoEpsilon && _shewchukValue(p, pn) < -geoEpsilon2)) !=
      ((winding & 1) != 0);
}

/// Zero-allocation spherical containment test over flat interleaved
/// `[lambda0, phi0, lambda1, phi1, ...]` radian rings used by `geoClip`.
// DIVERGES(d3-geo): adapt-geo-fast-forms, avoids boxing ring vertices into
// GeoPosition records inside spherical clippers.
bool geoPolygonContainsFlat(
  List<Float64List> rings,
  List<int> ringCounts,
  int numRings,
  double pointLambda,
  double pointPhi,
) {
  final lambda = _wrapLon(pointLambda);
  var phi = pointPhi;
  final sinPhi = math.sin(phi);
  final nx = math.sin(lambda);
  final ny = -math.cos(lambda);
  var angle = 0.0;
  var winding = 0;

  final p = _partials;
  var pn = 0;

  if (sinPhi == 1) {
    phi = geoHalfPi + geoEpsilon;
  } else if (sinPhi == -1) {
    phi = -geoHalfPi - geoEpsilon;
  }

  for (var i = 0; i < numRings; ++i) {
    final ring = rings[i];
    final m2 = ringCounts[i];
    if (m2 == 0) continue;

    var rawL0 = ring[m2 - 2];
    var rawP0 = ring[m2 - 1];
    var lambda0 = _wrapLon(rawL0);
    final phi0 = rawP0 / 2 + geoQuarterPi;
    var sinPhi0 = math.sin(phi0);
    var cosPhi0 = math.cos(phi0);

    for (var j = 0; j < m2; j += 2) {
      final rawL1 = ring[j];
      final rawP1 = ring[j + 1];
      final lambda1 = _wrapLon(rawL1);
      final phi1 = rawP1 / 2 + geoQuarterPi;
      final sinPhi1 = math.sin(phi1);
      final cosPhi1 = math.cos(phi1);
      final delta = lambda1 - lambda0;
      final sign = delta >= 0 ? 1.0 : -1.0;
      final absDelta = sign * delta;
      final antimeridian = absDelta > geoPi;
      final k = sinPhi0 * sinPhi1;

      pn = _shewchukAdd(
        p,
        pn,
        math.atan2(
          k * sign * math.sin(absDelta),
          cosPhi0 * cosPhi1 + k * math.cos(absDelta),
        ),
      );
      angle += antimeridian ? delta + sign * geoTau : delta;

      if ((antimeridian != (lambda0 >= lambda)) != (lambda1 >= lambda)) {
        winding += _crossingWinding(
          rawL0,
          rawP0,
          rawL1,
          rawP1,
          nx,
          ny,
          phi,
          antimeridian,
          delta,
        );
      }

      lambda0 = lambda1;
      sinPhi0 = sinPhi1;
      cosPhi0 = cosPhi1;
      rawL0 = rawL1;
      rawP0 = rawP1;
    }
  }

  return (angle < -geoEpsilon ||
          (angle < geoEpsilon && _shewchukValue(p, pn) < -geoEpsilon2)) !=
      ((winding & 1) != 0);
}
