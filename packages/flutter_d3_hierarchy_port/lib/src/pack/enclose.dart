// Ported from d3-hierarchy v3.1.2 src/pack/enclose.js (ISC, Mike Bostock).

/// Port of `src/pack/enclose.js` of d3-hierarchy 3.1.2: [PackCircle],
/// [packEnclose], [packEncloseRandom], and [packEncloseFloat64].
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_hierarchy_port/src/lcg.dart';

// DIVERGES(d3-hierarchy): adapt-hierarchy-typed-api, typed PackCircle class
// replacing untyped JS `{x, y, r}` plain objects.
// DIVERGES(d3-hierarchy): adapt-hierarchy-fast-forms, unboxed `Float64List`
// Matousek-Sharir-Welzl enclosing circle solver with zero per-iteration
// `PackCircle` or basis-`List` allocations.

/// A mutable circle with center ([x], [y]) and radius [r], used by
/// `packSiblings` and [packEnclose].
class PackCircle({
  /// Circle radius.
  required var double r,

  /// Center x-coordinate.
  var double x = 0,

  /// Center y-coordinate.
  var double y = 0,
}) {
  /// Creates a circle with radius [r] and optional center ([x], [y]).
  this;

  @override
  String toString() => 'PackCircle(x: $x, y: $y, r: $r)';
}

/// Computes the smallest circle that encloses all [circles], or `null` if
/// [circles] is empty.
PackCircle? packEnclose<C extends PackCircle>(Iterable<C> circles) =>
    packEncloseRandom<C>(circles, hierarchyLcg());

/// Computes the smallest circle that encloses all [circles] using the given
/// [random] generator, or `null` if [circles] is empty.
PackCircle? packEncloseRandom<C extends PackCircle>(
  Iterable<C> circles,
  double Function() random,
) {
  final list = circles is List<C> ? circles : List<C>.of(circles);
  final n = list.length;
  if (n == 0) return null;
  final xs = Float64List(n);
  final ys = Float64List(n);
  final rs = Float64List(n);
  for (var i = 0; i < n; ++i) {
    final c = list[i];
    xs[i] = c.x;
    ys[i] = c.y;
    rs[i] = c.r;
  }
  final (ex, ey, er) = packEncloseFloat64(xs, ys, rs, n, random);
  return PackCircle(x: ex, y: ey, r: er);
}

@pragma('vm:prefer-inline')
bool _enclosesNotVals(
  double ax,
  double ay,
  double ar,
  double bx,
  double by,
  double br,
) {
  final dr = ar - br;
  final dx = bx - ax;
  final dy = by - ay;
  return dr < 0 || dr * dr < dx * dx + dy * dy;
}

@pragma('vm:prefer-inline')
bool _enclosesWeakVals(
  double ax,
  double ay,
  double ar,
  double bx,
  double by,
  double br,
) {
  var maxR = ar > br ? ar : br;
  if (maxR < 1.0) maxR = 1.0;
  final dr = ar - br + maxR * 1e-9;
  final dx = bx - ax;
  final dy = by - ay;
  return dr > 0 && dr * dr > dx * dx + dy * dy;
}

@pragma('vm:prefer-inline')
(double, double, double) _enclose2(
  double x1,
  double y1,
  double r1,
  double x2,
  double y2,
  double r2,
) {
  final x21 = x2 - x1;
  final y21 = y2 - y1;
  final r21 = r2 - r1;
  final l = math.sqrt(x21 * x21 + y21 * y21);
  return (
    (x1 + x2 + x21 / l * r21) * 0.5,
    (y1 + y2 + y21 / l * r21) * 0.5,
    (l + r1 + r2) * 0.5,
  );
}

@pragma('vm:prefer-inline')
(double, double, double) _enclose3(
  double x1,
  double y1,
  double r1,
  double x2,
  double y2,
  double r2,
  double x3,
  double y3,
  double r3,
) {
  final a2 = x1 - x2;
  final a3 = x1 - x3;
  final b2 = y1 - y2;
  final b3 = y1 - y3;
  final c2 = r2 - r1;
  final c3 = r3 - r1;
  final d1 = x1 * x1 + y1 * y1 - r1 * r1;
  final d2 = d1 - x2 * x2 - y2 * y2 + r2 * r2;
  final d3 = d1 - x3 * x3 - y3 * y3 + r3 * r3;
  final ab = a3 * b2 - a2 * b3;
  final xa = (b2 * d3 - b3 * d2) / (ab * 2) - x1;
  final xb = (b3 * c2 - b2 * c3) / ab;
  final ya = (a3 * d2 - a2 * d3) / (ab * 2) - y1;
  final yb = (a2 * c3 - a3 * c2) / ab;
  final qa = xb * xb + yb * yb - 1;
  final qb = 2 * (r1 + xa * xb + ya * yb);
  final qc = xa * xa + ya * ya - r1 * r1;
  final r = -(qa.abs() > 1e-6
      ? (qb + math.sqrt(qb * qb - 4 * qa * qc)) / (2 * qa)
      : qc / qb);
  return (x1 + xa + xb * r, y1 + ya + yb * r, r);
}

/// Unboxed smallest enclosing circle over parallel `Float64List` buffers
/// `[0, n)` (shuffles in-place using [random]).
(double, double, double) packEncloseFloat64(
  Float64List xs,
  Float64List ys,
  Float64List rs,
  int n,
  double Function() random,
) {
  // Fisher-Yates shuffle matching upstream `hierarchyShuffle`.
  var m = n;
  while (m > 0) {
    final idx = (random() * m--).toInt();
    final tx = xs[m];
    xs[m] = xs[idx];
    xs[idx] = tx;
    final ty = ys[m];
    ys[m] = ys[idx];
    ys[idx] = ty;
    final tr = rs[m];
    rs[m] = rs[idx];
    rs[idx] = tr;
  }

  // Basis of at most 3 circles stored as scalar coordinates (zero allocations).
  var bLen = 0;
  var b0x = 0.0;
  var b0y = 0.0;
  var b0r = 0.0;
  var b1x = 0.0;
  var b1y = 0.0;
  var b1r = 0.0;
  var b2x = 0.0;
  var b2y = 0.0;
  var b2r = 0.0;

  var ex = 0.0;
  var ey = 0.0;
  var er = 0.0;
  var hasE = false;

  bool enclosesWeakBasis(double ax, double ay, double ar) {
    if (bLen >= 1 && !_enclosesWeakVals(ax, ay, ar, b0x, b0y, b0r)) {
      return false;
    }
    if (bLen >= 2 && !_enclosesWeakVals(ax, ay, ar, b1x, b1y, b1r)) {
      return false;
    }
    if (bLen >= 3 && !_enclosesWeakVals(ax, ay, ar, b2x, b2y, b2r)) {
      return false;
    }
    return true;
  }

  var i = 0;
  while (i < n) {
    final px = xs[i];
    final py = ys[i];
    final pr = rs[i];
    if (hasE && _enclosesWeakVals(ex, ey, er, px, py, pr)) {
      ++i;
      continue;
    }

    // Extend basis with p.
    if (enclosesWeakBasis(px, py, pr)) {
      bLen = 1;
      b0x = px;
      b0y = py;
      b0r = pr;
      ex = px;
      ey = py;
      er = pr;
      hasE = true;
      i = 0;
      continue;
    }

    var extended = false;
    // Try 2-element basis [B[u], p].
    for (var u = 0; u < bLen; ++u) {
      final ux = u == 0 ? b0x : (u == 1 ? b1x : b2x);
      final uy = u == 0 ? b0y : (u == 1 ? b1y : b2y);
      final ur = u == 0 ? b0r : (u == 1 ? b1r : b2r);
      if (_enclosesNotVals(px, py, pr, ux, uy, ur)) {
        final (cx, cy, cr) = _enclose2(ux, uy, ur, px, py, pr);
        if (enclosesWeakBasis(cx, cy, cr)) {
          bLen = 2;
          b0x = ux;
          b0y = uy;
          b0r = ur;
          b1x = px;
          b1y = py;
          b1r = pr;
          ex = cx;
          ey = cy;
          er = cr;
          hasE = true;
          extended = true;
          break;
        }
      }
    }
    if (extended) {
      i = 0;
      continue;
    }

    // Try 3-element basis [B[u], B[v], p].
    for (var u = 0; u < bLen - 1 && !extended; ++u) {
      final ux = u == 0 ? b0x : b1x;
      final uy = u == 0 ? b0y : b1y;
      final ur = u == 0 ? b0r : b1r;
      for (var v = u + 1; v < bLen; ++v) {
        final vx = v == 1 ? b1x : b2x;
        final vy = v == 1 ? b1y : b2y;
        final vr = v == 1 ? b1r : b2r;
        final (cuvX, cuvY, cuvR) = _enclose2(ux, uy, ur, vx, vy, vr);
        if (_enclosesNotVals(cuvX, cuvY, cuvR, px, py, pr)) {
          final (cupX, cupY, cupR) = _enclose2(ux, uy, ur, px, py, pr);
          if (_enclosesNotVals(cupX, cupY, cupR, vx, vy, vr)) {
            final (cvpX, cvpY, cvpR) = _enclose2(vx, vy, vr, px, py, pr);
            if (_enclosesNotVals(cvpX, cvpY, cvpR, ux, uy, ur)) {
              final (cx, cy, cr) = _enclose3(
                ux,
                uy,
                ur,
                vx,
                vy,
                vr,
                px,
                py,
                pr,
              );
              if (enclosesWeakBasis(cx, cy, cr)) {
                bLen = 3;
                b0x = ux;
                b0y = uy;
                b0r = ur;
                b1x = vx;
                b1y = vy;
                b1r = vr;
                b2x = px;
                b2y = py;
                b2r = pr;
                ex = cx;
                ey = cy;
                er = cr;
                hasE = true;
                extended = true;
                break;
              }
            }
          }
        }
      }
    }
    if (!extended) {
      throw StateError('Unable to extend enclosing circle basis');
    }
    i = 0;
  }

  return (ex, ey, er);
}
