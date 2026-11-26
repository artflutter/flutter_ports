// Ported from d3-shape v3.2.0 src/arc.js (ISC, Mike Bostock).

/// Port of `src/arc.js` of d3-shape 3.2.0: [Arc], [ArcDatum], [ArcData], and
/// [arc].
library;

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/math.dart';
import 'package:flutter_d3_shape_port/src/path.dart';

/// Numeric accessor for [Arc].
typedef ArcAccessor<T> = double Function(T d);

/// Interface implemented by arc data objects (such as [ArcData] and `PieArc`).
// DIVERGES(d3-shape): adapt-shape-typed-api, typed ArcDatum interface.
abstract interface class ArcDatum() {
  /// Inner radius in pixels.
  double get innerRadius;

  /// Outer radius in pixels.
  double get outerRadius;

  /// Start angle in radians (0 at 12 o'clock, clockwise).
  double get startAngle;

  /// End angle in radians (0 at 12 o'clock, clockwise).
  double get endAngle;

  /// Pad angle in radians between adjacent arcs.
  double get padAngle;
}

/// Immutable value object implementing [ArcDatum].
// DIVERGES(d3-shape): adapt-shape-typed-api, const ArcData value class.
final class const ArcData({
  @override final double innerRadius = 0,
  @override final double outerRadius = 0,
  @override final double startAngle = 0,
  @override final double endAngle = 0,
  @override final double padAngle = 0,
}) implements ArcDatum {
  /// Creates an [ArcData] record.
  this;
}

double _arcInnerRadius<T>(T d) => (d as ArcDatum).innerRadius;
double _arcOuterRadius<T>(T d) => (d as ArcDatum).outerRadius;
double _arcStartAngle<T>(T d) => (d as ArcDatum).startAngle;
double _arcEndAngle<T>(T d) => (d as ArcDatum).endAngle;
double _arcPadAngle<T>(T d) => d is ArcDatum ? d.padAngle : 0;

(double, double)? _intersect(
  double x0,
  double y0,
  double x1,
  double y1,
  double x2,
  double y2,
  double x3,
  double y3,
) {
  final x10 = x1 - x0;
  final y10 = y1 - y0;
  final x32 = x3 - x2;
  final y32 = y3 - y2;
  var t = y32 * x10 - x32 * y10;
  if (t * t < shapeEpsilon) return null;
  t = (x32 * (y0 - y2) - y32 * (x0 - x2)) / t;
  return (x0 + t * x10, y0 + t * y10);
}

// Compute perpendicular offset line of length rc.
// http://mathworld.wolfram.com/Circle-LineIntersection.html
({double cx, double cy, double x01, double y01, double x11, double y11})
_cornerTangents(
  double x0,
  double y0,
  double x1,
  double y1,
  double r1,
  double rc,
  bool cw,
) {
  final x01 = x0 - x1;
  final y01 = y0 - y1;
  final lo = (cw ? rc : -rc) / math.sqrt(x01 * x01 + y01 * y01);
  final ox = lo * y01;
  final oy = -lo * x01;
  final x11 = x0 + ox;
  final y11 = y0 + oy;
  final x10 = x1 + ox;
  final y10 = y1 + oy;
  final x00 = (x11 + x10) / 2;
  final y00 = (y11 + y10) / 2;
  final dx = x10 - x11;
  final dy = y10 - y11;
  final d2 = dx * dx + dy * dy;
  final r = r1 - rc;
  final bigD = x11 * y10 - x10 * y11;
  final disc = math.max<double>(0, r * r * d2 - bigD * bigD);
  final d = (dy < 0 ? -1 : 1) * math.sqrt(disc);
  var cx0 = (bigD * dy - dx * d) / d2;
  var cy0 = (-bigD * dx - dy * d) / d2;
  final cx1 = (bigD * dy + dx * d) / d2;
  final cy1 = (-bigD * dx + dy * d) / d2;
  final dx0 = cx0 - x00;
  final dy0 = cy0 - y00;
  final dx1 = cx1 - x00;
  final dy1 = cy1 - y00;

  if (dx0 * dx0 + dy0 * dy0 > dx1 * dx1 + dy1 * dy1) {
    cx0 = cx1;
    cy0 = cy1;
  }

  return (
    cx: cx0,
    cy: cy0,
    x01: -ox,
    y01: -oy,
    x11: cx0 * (r1 / r - 1),
    y11: cy0 * (r1 / r - 1),
  );
}

double _zeroArc<T>(T _) => 0;

/// `arc.js:78` `arc`: circular or annular sector generator (pie/donut charts).
// DIVERGES(d3-shape): adapt-shape-typed-api, typed generic Arc class.
// DIVERGES(d3-shape): adapt-shape-fast-forms, constant-accessor fast paths
// skip closure indirection for configured constant radii and angles.
final class Arc<T>() with ShapePathMixin {
  /// Creates an arc generator with default [ArcDatum] accessors.
  this;

  ArcAccessor<T> _innerRadius = _arcInnerRadius;
  double? _innerRadiusConst;

  ArcAccessor<T> _outerRadius = _arcOuterRadius;
  double? _outerRadiusConst;

  ArcAccessor<T> _cornerRadius = _zeroArc;
  double? _cornerRadiusConst = 0;

  ArcAccessor<T>? _padRadius;
  double? _padRadiusConst;

  ArcAccessor<T> _startAngle = _arcStartAngle;
  double? _startAngleConst;

  ArcAccessor<T> _endAngle = _arcEndAngle;
  double? _endAngleConst;

  ArcAccessor<T> _padAngle = _arcPadAngle;
  double? _padAngleConst;

  /// Rendering [CanvasPath] context (`null` emits an SVG string).
  CanvasPath? context;

  /// Generates the arc for [d]. Returns an SVG path string when [context] is
  /// `null`, or writes directly into [context] and returns `null`.
  String? call([T? d]) {
    final datum = d as T;
    var r0 = _innerRadiusConst ?? _innerRadius(datum);
    var r1 = _outerRadiusConst ?? _outerRadius(datum);
    final a0 = (_startAngleConst ?? _startAngle(datum)) - shapeHalfPi;
    final a1 = (_endAngleConst ?? _endAngle(datum)) - shapeHalfPi;
    final da = (a1 - a0).abs();
    final cw = a1 > a0;

    Path? buffer;
    final ctx = context ?? (buffer = createShapePath());

    // Ensure that the outer radius is always larger than the inner radius.
    if (r1 < r0) {
      final r = r1;
      r1 = r0;
      r0 = r;
    }

    // Is it a point?
    if (!(r1 > shapeEpsilon)) {
      ctx.moveTo(0, 0);
    }
    // Or is it a circle or annulus?
    else if (da > shapeTau - shapeEpsilon) {
      ctx
        ..moveTo(r1 * math.cos(a0), r1 * math.sin(a0))
        ..arc(0, 0, r1, a0, a1, !cw);
      if (r0 > shapeEpsilon) {
        ctx
          ..moveTo(r0 * math.cos(a1), r0 * math.sin(a1))
          ..arc(0, 0, r0, a1, a0, cw);
      }
    }
    // Or is it a circular or annular sector?
    else {
      var a01 = a0;
      var a11 = a1;
      var a00 = a0;
      var a10 = a1;
      var da0 = da;
      var da1 = da;
      final ap = (_padAngleConst ?? _padAngle(datum)) / 2;
      final padR = _padRadius;
      final rp = ap > shapeEpsilon
          ? (_padRadiusConst ??
                (padR != null ? padR(datum) : math.sqrt(r0 * r0 + r1 * r1)))
          : 0.0;
      final rcVal = _cornerRadiusConst ?? _cornerRadius(datum);
      final rc = rcVal > 0 ? math.min((r1 - r0).abs() / 2, rcVal) : 0.0;
      var rc0 = rc;
      var rc1 = rc;

      // Apply padding? Note that since r1 >= r0, da1 >= da0.
      if (rp > shapeEpsilon) {
        var p0 = shapeAsin(rp / r0 * math.sin(ap));
        var p1 = shapeAsin(rp / r1 * math.sin(ap));
        if ((da0 -= p0 * 2) > shapeEpsilon) {
          p0 *= cw ? 1 : -1;
          a00 += p0;
          a10 -= p0;
        } else {
          da0 = 0;
          a00 = a10 = (a0 + a1) / 2;
        }
        if ((da1 -= p1 * 2) > shapeEpsilon) {
          p1 *= cw ? 1 : -1;
          a01 += p1;
          a11 -= p1;
        } else {
          da1 = 0;
          a01 = a11 = (a0 + a1) / 2;
        }
      }

      final x01 = r1 * math.cos(a01);
      final y01 = r1 * math.sin(a01);
      final x10 = r0 * math.cos(a10);
      final y10 = r0 * math.sin(a10);

      var x11 = 0.0;
      var y11 = 0.0;
      var x00 = 0.0;
      var y00 = 0.0;

      // Apply rounded corners?
      if (rc > shapeEpsilon) {
        x11 = r1 * math.cos(a11);
        y11 = r1 * math.sin(a11);
        x00 = r0 * math.cos(a00);
        y00 = r0 * math.sin(a00);

        if (da < shapePi) {
          final oc = _intersect(x01, y01, x00, y00, x11, y11, x10, y10);
          if (oc != null) {
            final (ocx, ocy) = oc;
            final ax = x01 - ocx;
            final ay = y01 - ocy;
            final bx = x11 - ocx;
            final by = y11 - ocy;
            final kc =
                1 /
                math.sin(
                  shapeAcos(
                        (ax * bx + ay * by) /
                            (math.sqrt(ax * ax + ay * ay) *
                                math.sqrt(bx * bx + by * by)),
                      ) /
                      2,
                );
            final lc = math.sqrt(ocx * ocx + ocy * ocy);
            rc0 = math.min(rc, (r0 - lc) / (kc - 1));
            rc1 = math.min(rc, (r1 - lc) / (kc + 1));
          } else {
            rc0 = rc1 = 0;
          }
        }
      }

      // Is the sector collapsed to a line?
      if (!(da1 > shapeEpsilon)) {
        ctx.moveTo(x01, y01);
      }
      // Does the sector's outer ring have rounded corners?
      else if (rc1 > shapeEpsilon) {
        final t0 = _cornerTangents(x00, y00, x01, y01, r1, rc1, cw);
        final t1 = _cornerTangents(x11, y11, x10, y10, r1, rc1, cw);

        ctx.moveTo(t0.cx + t0.x01, t0.cy + t0.y01);

        // Have the corners merged?
        if (rc1 < rc) {
          ctx.arc(
            t0.cx,
            t0.cy,
            rc1,
            math.atan2(t0.y01, t0.x01),
            math.atan2(t1.y01, t1.x01),
            !cw,
          );
        }
        // Otherwise, draw the two corners and the ring.
        else {
          ctx
            ..arc(
              t0.cx,
              t0.cy,
              rc1,
              math.atan2(t0.y01, t0.x01),
              math.atan2(t0.y11, t0.x11),
              !cw,
            )
            ..arc(
              0,
              0,
              r1,
              math.atan2(t0.cy + t0.y11, t0.cx + t0.x11),
              math.atan2(t1.cy + t1.y11, t1.cx + t1.x11),
              !cw,
            )
            ..arc(
              t1.cx,
              t1.cy,
              rc1,
              math.atan2(t1.y11, t1.x11),
              math.atan2(t1.y01, t1.x01),
              !cw,
            );
        }
      }
      // Or is the outer ring just a circular arc?
      else {
        ctx
          ..moveTo(x01, y01)
          ..arc(0, 0, r1, a01, a11, !cw);
      }

      // Is there no inner ring, and it's a circular sector?
      // Or perhaps it's an annular sector collapsed due to padding?
      if (!(r0 > shapeEpsilon) || !(da0 > shapeEpsilon)) {
        ctx.lineTo(x10, y10);
      }
      // Does the sector's inner ring have rounded corners?
      else if (rc0 > shapeEpsilon) {
        final t0 = _cornerTangents(x10, y10, x11, y11, r0, -rc0, cw);
        final t1 = _cornerTangents(x01, y01, x00, y00, r0, -rc0, cw);

        ctx.lineTo(t0.cx + t0.x01, t0.cy + t0.y01);

        // Have the corners merged?
        if (rc0 < rc) {
          ctx.arc(
            t0.cx,
            t0.cy,
            rc0,
            math.atan2(t0.y01, t0.x01),
            math.atan2(t1.y01, t1.x01),
            !cw,
          );
        }
        // Otherwise, draw the two corners and the ring.
        else {
          ctx
            ..arc(
              t0.cx,
              t0.cy,
              rc0,
              math.atan2(t0.y01, t0.x01),
              math.atan2(t0.y11, t0.x11),
              !cw,
            )
            ..arc(
              0,
              0,
              r0,
              math.atan2(t0.cy + t0.y11, t0.cx + t0.x11),
              math.atan2(t1.cy + t1.y11, t1.cx + t1.x11),
              cw,
            )
            ..arc(
              t1.cx,
              t1.cy,
              rc0,
              math.atan2(t1.y11, t1.x11),
              math.atan2(t1.y01, t1.x01),
              !cw,
            );
        }
      }
      // Or is the inner ring just a circular arc?
      else {
        ctx.arc(0, 0, r0, a10, a00, cw);
      }
    }

    ctx.closePath();

    if (buffer != null) {
      final result = buffer.toString();
      return result.isEmpty ? null : result;
    }
    return null;
  }

  /// `arc.js:230` `centroid`: computes the midpoint `(x, y)` of the center
  /// line of the arc.
  (double, double) centroid([T? d]) {
    final datum = d as T;
    final r =
        ((_innerRadiusConst ?? _innerRadius(datum)) +
            (_outerRadiusConst ?? _outerRadius(datum))) /
        2;
    final a =
        ((_startAngleConst ?? _startAngle(datum)) +
                (_endAngleConst ?? _endAngle(datum))) /
            2 -
        shapeHalfPi;
    return (math.cos(a) * r, math.sin(a) * r);
  }

  /// Current inner radius accessor.
  ArcAccessor<T> get innerRadius => _innerRadius;

  /// Sets the inner radius accessor.
  set innerRadius(ArcAccessor<T> fn) {
    _innerRadius = fn;
    _innerRadiusConst = null;
  }

  /// Sets a constant inner radius.
  void innerRadiusConst(double value) {
    _innerRadius = (_) => value;
    _innerRadiusConst = value;
  }

  /// Current outer radius accessor.
  ArcAccessor<T> get outerRadius => _outerRadius;

  /// Sets the outer radius accessor.
  set outerRadius(ArcAccessor<T> fn) {
    _outerRadius = fn;
    _outerRadiusConst = null;
  }

  /// Sets a constant outer radius.
  void outerRadiusConst(double value) {
    _outerRadius = (_) => value;
    _outerRadiusConst = value;
  }

  /// Current corner radius accessor.
  ArcAccessor<T> get cornerRadius => _cornerRadius;

  /// Sets the corner radius accessor.
  set cornerRadius(ArcAccessor<T> fn) {
    _cornerRadius = fn;
    _cornerRadiusConst = null;
  }

  /// Sets a constant corner radius.
  void cornerRadiusConst(double value) {
    _cornerRadius = (_) => value;
    _cornerRadiusConst = value;
  }

  /// Current pad radius accessor (`null` computes `sqrt(r0^2 + r1^2)`).
  ArcAccessor<T>? get padRadius => _padRadius;

  /// Sets the pad radius accessor.
  set padRadius(ArcAccessor<T>? fn) {
    _padRadius = fn;
    _padRadiusConst = null;
  }

  /// Sets a constant pad radius.
  void padRadiusConst(double value) {
    _padRadius = (_) => value;
    _padRadiusConst = value;
  }

  /// Current start angle accessor.
  ArcAccessor<T> get startAngle => _startAngle;

  /// Sets the start angle accessor.
  set startAngle(ArcAccessor<T> fn) {
    _startAngle = fn;
    _startAngleConst = null;
  }

  /// Sets a constant start angle.
  void startAngleConst(double value) {
    _startAngle = (_) => value;
    _startAngleConst = value;
  }

  /// Current end angle accessor.
  ArcAccessor<T> get endAngle => _endAngle;

  /// Sets the end angle accessor.
  set endAngle(ArcAccessor<T> fn) {
    _endAngle = fn;
    _endAngleConst = null;
  }

  /// Sets a constant end angle.
  void endAngleConst(double value) {
    _endAngle = (_) => value;
    _endAngleConst = value;
  }

  /// Current pad angle accessor.
  ArcAccessor<T> get padAngle => _padAngle;

  /// Sets the pad angle accessor.
  set padAngle(ArcAccessor<T> fn) {
    _padAngle = fn;
    _padAngleConst = null;
  }

  /// Sets a constant pad angle.
  void padAngleConst(double value) {
    _padAngle = (_) => value;
    _padAngleConst = value;
  }
}

/// `arc.js:78` default export: creates a new [Arc] generator with optional
/// constant defaults.
Arc<T> arc<T>({
  double? innerRadius,
  double? outerRadius,
  double? cornerRadius,
  double? padRadius,
  double? startAngle,
  double? endAngle,
  double? padAngle,
  CanvasPath? context,
  int? digits = 3,
}) {
  final a = Arc<T>()..digits = digits;
  if (innerRadius != null) a.innerRadiusConst(innerRadius);
  if (outerRadius != null) a.outerRadiusConst(outerRadius);
  if (cornerRadius != null) a.cornerRadiusConst(cornerRadius);
  if (padRadius != null) a.padRadiusConst(padRadius);
  if (startAngle != null) a.startAngleConst(startAngle);
  if (endAngle != null) a.endAngleConst(endAngle);
  if (padAngle != null) a.padAngleConst(padAngle);
  if (context != null) a.context = context;
  return a;
}
