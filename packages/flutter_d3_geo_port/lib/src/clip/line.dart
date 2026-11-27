// Ported from d3-geo v3.1.1 src/clip/line.js (ISC, Mike Bostock).

/// Port of `src/clip/line.js` of d3-geo 3.1.1: Liang-Barsky planar segment
/// clipping against an axis-aligned rectangle.
library;

import 'package:flutter_d3_geo_port/src/clip/buffer.dart';

/// `clip/line.js:1` default export: clips segment `[a, b]` in place to the
/// rectangle `[x0, x1] × [y0, y1]`, returning `true` if any portion is visible.
// DIVERGES(d3-geo): adapt-geo-typed-api, mutates typed GeoClipPoint endpoints
// and returns bool.
bool geoClipLineSegment(
  GeoClipPoint a,
  GeoClipPoint b,
  double x0,
  double y0,
  double x1,
  double y1,
) {
  final ax = a.x;
  final ay = a.y;
  final bx = b.x;
  final by = b.y;
  var t0 = 0.0;
  var t1 = 1.0;
  final dx = bx - ax;
  final dy = by - ay;

  var r = x0 - ax;
  if (dx == 0) {
    if (r > 0) return false;
  } else {
    r /= dx;
    if (dx < 0) {
      if (r < t0) return false;
      if (r < t1) t1 = r;
    } else {
      if (r > t1) return false;
      if (r > t0) t0 = r;
    }
  }

  r = x1 - ax;
  if (dx == 0) {
    if (r < 0) return false;
  } else {
    r /= dx;
    if (dx < 0) {
      if (r > t1) return false;
      if (r > t0) t0 = r;
    } else {
      if (r < t0) return false;
      if (r < t1) t1 = r;
    }
  }

  r = y0 - ay;
  if (dy == 0) {
    if (r > 0) return false;
  } else {
    r /= dy;
    if (dy < 0) {
      if (r < t0) return false;
      if (r < t1) t1 = r;
    } else {
      if (r > t1) return false;
      if (r > t0) t0 = r;
    }
  }

  r = y1 - ay;
  if (dy == 0) {
    if (r < 0) return false;
  } else {
    r /= dy;
    if (dy < 0) {
      if (r > t1) return false;
      if (r > t0) t0 = r;
    } else {
      if (r < t0) return false;
      if (r < t1) t1 = r;
    }
  }

  if (t0 > 0) {
    a
      ..x = ax + t0 * dx
      ..y = ay + t0 * dy;
  }
  if (t1 < 1) {
    b
      ..x = ax + t1 * dx
      ..y = ay + t1 * dy;
  }
  return true;
}
