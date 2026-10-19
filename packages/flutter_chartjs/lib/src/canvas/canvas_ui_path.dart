// Original code, not ported from Chart.js: the dart:ui canvas paths.

/// The current transform and the path builder of the `dart:ui` canvas
/// context (Chart.js ADR 0013, porting-flow.md 2.2).
///
/// Canvas 2D has path semantics that `dart:ui` lacks. This library keeps
/// those that change behavior:
/// - The transform applies when a point is added: [UiPathBuilder] writes
///   each point in the space of the canvas bitmap, through the transform
///   that is current at that call.
/// - A path method with a non-finite argument does nothing. With a
///   transform that is not invertible, a path method does nothing (as
///   Chromium does).
/// - `lineTo`, `quadraticCurveTo`, `bezierCurveTo` and `arcTo` on a path
///   with no subpath start a subpath at their first point. `dart:ui` would
///   start it at the origin.
/// - `arc` connects to the current point with a line (`ui.Path.arcTo` with
///   `forceMoveTo: false`). A sweep of 2π or more draws a full circle.
///   `ui.Path.arcTo` draws nothing for a sweep of 2π, thus the builder adds
///   two half arcs.
/// - `arc` with a negative radius throws a [RangeError] (the DOM
///   `IndexSizeError`).
///
/// The arc and ellipse curves are `dart:ui` arcs when the transform keeps
/// them circular or axis-aligned, else cubic Bézier curves. The layer has no
/// Chromium-exact arc math (Chart.js ADR 0009).
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_chartjs/src/canvas/canvas.dart';

const double _tau = 2 * math.pi;

/// The current transformation matrix of a canvas state: the DOM matrix
/// `[a c e; b d f; 0 0 1]`.
///
/// The derived flags tell the fast paths of the context when they apply.
final class UiTransform {
  /// The identity transform.
  UiTransform();

  /// The matrix component `a` (x scale).
  double a = 1;

  /// The matrix component `b` (y skew).
  double b = 0;

  /// The matrix component `c` (x skew).
  double c = 0;

  /// The matrix component `d` (y scale).
  double d = 1;

  /// The matrix component `e` (x translation).
  double e = 0;

  /// The matrix component `f` (y translation).
  double f = 0;

  /// `b == 0 && c == 0`: the transform maps rectangles to rectangles.
  bool isAxisAligned = true;

  /// The transform is a translation, a rotation, a reflection and one
  /// uniform scale: circles stay circles and line widths scale by
  /// [scaleFactor].
  bool isSimilarity = true;

  /// The uniform scale of a [isSimilarity] transform.
  double scaleFactor = 1;

  /// The rotation of a [isSimilarity] transform, in radians.
  double angle = 0;

  /// The determinant is negative: the transform mirrors.
  bool isReflected = false;

  /// The determinant is finite and not 0.
  bool isInvertible = true;

  /// `a == 1, b == 0, c == 0, d == 1`: the transform translates only.
  bool isTranslation = true;

  /// Copies the matrix and the flags of [other].
  void copyFrom(UiTransform other) {
    a = other.a;
    b = other.b;
    c = other.c;
    d = other.d;
    e = other.e;
    f = other.f;
    isAxisAligned = other.isAxisAligned;
    isSimilarity = other.isSimilarity;
    scaleFactor = other.scaleFactor;
    angle = other.angle;
    isReflected = other.isReflected;
    isInvertible = other.isInvertible;
    isTranslation = other.isTranslation;
  }

  /// `setTransform(a, b, c, d, e, f)`.
  void setValues(
    double a,
    double b,
    double c,
    double d,
    double e,
    double f,
  ) {
    this.a = a;
    this.b = b;
    this.c = c;
    this.d = d;
    this.e = e;
    this.f = f;
    _update();
  }

  /// `resetTransform()`.
  void reset() => setValues(1, 0, 0, 1, 0, 0);

  /// `translate(x, y)`: this matrix times the translation.
  void translate(double x, double y) {
    e += a * x + c * y;
    f += b * x + d * y;
  }

  /// `scale(x, y)`: this matrix times the scale.
  void scale(double x, double y) {
    a *= x;
    b *= x;
    c *= y;
    d *= y;
    _update();
  }

  /// `rotate(angle)`: this matrix times the rotation.
  void rotate(double radians) {
    final cos = math.cos(radians);
    final sin = math.sin(radians);
    final na = a * cos + c * sin;
    final nb = b * cos + d * sin;
    final nc = c * cos - a * sin;
    final nd = d * cos - b * sin;
    a = na;
    b = nb;
    c = nc;
    d = nd;
    _update();
  }

  /// `transform(a, b, c, d, e, f)`: this matrix times the given one.
  void multiply(
    double ma,
    double mb,
    double mc,
    double md,
    double me,
    double mf,
  ) {
    final na = a * ma + c * mb;
    final nb = b * ma + d * mb;
    final nc = a * mc + c * md;
    final nd = b * mc + d * md;
    final ne = a * me + c * mf + e;
    final nf = b * me + d * mf + f;
    a = na;
    b = nb;
    c = nc;
    d = nd;
    e = ne;
    f = nf;
    _update();
  }

  /// The x of the point (x, y) after the transform.
  double mapX(double x, double y) => a * x + c * y + e;

  /// The y of the point (x, y) after the transform.
  double mapY(double x, double y) => b * x + d * y + f;

  /// The determinant of the linear part.
  double get determinant => a * d - b * c;

  /// Writes the matrix as a column-major 4 x 4 matrix into [m] (16 values).
  Float64List writeMatrix4(Float64List m) {
    m
      ..fillRange(0, 16, 0)
      ..[0] = a
      ..[1] = b
      ..[4] = c
      ..[5] = d
      ..[10] = 1
      ..[12] = e
      ..[13] = f
      ..[15] = 1;
    return m;
  }

  /// Writes the inverse matrix as a column-major 4 x 4 matrix into [m]. The
  /// transform must be [isInvertible].
  Float64List writeInverseMatrix4(Float64List m) {
    final det = determinant;
    m
      ..fillRange(0, 16, 0)
      ..[0] = d / det
      ..[1] = -b / det
      ..[4] = -c / det
      ..[5] = a / det
      ..[10] = 1
      ..[12] = (c * f - d * e) / det
      ..[13] = (b * e - a * f) / det
      ..[15] = 1;
    return m;
  }

  void _update() {
    isAxisAligned = b == 0 && c == 0;
    isTranslation = isAxisAligned && a == 1 && d == 1;
    final det = determinant;
    isInvertible = det != 0 && det.isFinite;
    isReflected = det < 0;
    final col1 = a * a + b * b;
    final col2 = c * c + d * d;
    final tolerance = 1e-9 * (col1 + col2);
    isSimilarity =
        isInvertible &&
        (col1 - col2).abs() <= tolerance &&
        (a * c + b * d).abs() <= tolerance;
    if (isSimilarity) {
      scaleFactor = math.sqrt(col1);
      angle = isAxisAligned && a > 0 ? 0 : math.atan2(b, a);
    }
  }
}

/// The sweep of `arc(x, y, r, startAngle, endAngle, counterclockwise)`, as
/// Chromium canonicalizes the end angle (`AdjustEndAngle`): a sweep of 2π
/// or more is a full circle, else the sweep goes the given way round.
// The DOM argument order.
// ignore: avoid_positional_boolean_parameters
double canvasArcSweep(double startAngle, double endAngle, bool ccw) {
  if (!ccw && endAngle - startAngle >= _tau) return _tau;
  if (ccw && startAngle - endAngle >= _tau) return -_tau;
  if (!ccw && startAngle > endAngle) {
    return _tau - (startAngle - endAngle) % _tau;
  }
  if (ccw && startAngle < endAngle) {
    return -(_tau - (endAngle - startAngle) % _tau);
  }
  return endAngle - startAngle;
}

/// A [CanvasPath] that builds a `ui.Path` in the space of the canvas bitmap,
/// through [transform].
///
/// The context keeps one builder for its current path. A [Path2D] replays
/// into a builder with the identity transform, which gives a path in user
/// space.
final class UiPathBuilder implements CanvasPath {
  /// A builder that maps its points through [transform].
  UiPathBuilder(this.transform);

  /// The transform that maps the added points. The context points it at
  /// the transform of its current state.
  UiTransform transform;

  final ui.Path _path = ui.Path();

  /// The built path.
  ///
  /// A pending full circle (see [singleCircle]) becomes part of the path at
  /// the first read.
  ui.Path get path {
    if (_circle) _materializeCircle();
    return _path;
  }

  // A full circle that `arc` added to an empty path, in bitmap space. It
  // stays out of [_path] until another command or a read of [path] needs
  // it, so that the context can draw it with `drawCircle`: a chart draws
  // most points as one full circle (`drawPointLegend`,
  // helpers.canvas.ts:200-207).
  bool _circle = false;
  bool _circleClosed = false;
  double _circleX = 0;
  double _circleY = 0;
  double _circleR = 0;
  double _circleStart = 0;
  double _circleSweep = 0;

  /// The path has a subpath: a current point exists.
  bool hasSubpath = false;

  double _lastX = 0;
  double _lastY = 0;
  double _startX = 0;
  double _startY = 0;
  int _ops = 0;
  ui.Rect? _rect;

  /// The path has no command.
  bool get isEmpty => _ops == 0;

  /// The rectangle of the path, when the path is one `rect` that an
  /// axis-aligned transform mapped. The context fills and clips it with
  /// `drawRect` and `clipRect`.
  ui.Rect? get singleRect => _ops == 1 ? _rect : null;

  /// The circle of the path in bitmap space, when the path is one full
  /// circle that a similarity transform mapped, with or without a
  /// `closePath`. The context fills and strokes it with `drawCircle`.
  ({double x, double y, double radius})? get singleCircle =>
      _circle ? (x: _circleX, y: _circleY, radius: _circleR) : null;

  /// `beginPath()`: empties the path.
  void reset() {
    _path.reset();
    hasSubpath = false;
    _ops = 0;
    _rect = null;
    _circle = false;
  }

  /// Adds the pending circle to [_path], as [_nativeArc] adds a full sweep.
  void _materializeCircle() {
    _circle = false;
    final oval = ui.Rect.fromCircle(
      center: ui.Offset(_circleX, _circleY),
      radius: _circleR,
    );
    final half = _circleSweep / 2;
    _path
      ..arcTo(oval, _circleStart, half, true)
      ..arcTo(oval, _circleStart + half, half, false);
    if (_circleClosed) _path.close();
  }

  void _moveToMapped(double px, double py) {
    path.moveTo(px, py);
    _startX = _lastX = px;
    _startY = _lastY = py;
    hasSubpath = true;
  }

  void _lineToMapped(double px, double py) {
    path.lineTo(px, py);
    _lastX = px;
    _lastY = py;
  }

  /// A line to the user point (x, y), or a move to it when the path has no
  /// subpath.
  void _lineOrMove(double x, double y) {
    final t = transform;
    final px = t.mapX(x, y);
    final py = t.mapY(x, y);
    if (hasSubpath) {
      _lineToMapped(px, py);
    } else {
      _moveToMapped(px, py);
    }
  }

  @override
  void closePath() {
    if (!hasSubpath) return;
    if (_circle && !_circleClosed) {
      _circleClosed = true;
    } else {
      path.close();
    }
    _lastX = _startX;
    _lastY = _startY;
    _ops++;
  }

  @override
  void moveTo(double x, double y) {
    if (!x.isFinite || !y.isFinite || !transform.isInvertible) return;
    final t = transform;
    _moveToMapped(t.mapX(x, y), t.mapY(x, y));
    _ops++;
  }

  @override
  void lineTo(double x, double y) {
    if (!x.isFinite || !y.isFinite || !transform.isInvertible) return;
    _lineOrMove(x, y);
    _ops++;
  }

  @override
  void quadraticCurveTo(double cpx, double cpy, double x, double y) {
    if (!cpx.isFinite ||
        !cpy.isFinite ||
        !x.isFinite ||
        !y.isFinite ||
        !transform.isInvertible) {
      return;
    }
    final t = transform;
    final pcx = t.mapX(cpx, cpy);
    final pcy = t.mapY(cpx, cpy);
    if (!hasSubpath) _moveToMapped(pcx, pcy);
    final px = t.mapX(x, y);
    final py = t.mapY(x, y);
    path.quadraticBezierTo(pcx, pcy, px, py);
    _lastX = px;
    _lastY = py;
    _ops++;
  }

  @override
  void bezierCurveTo(
    double cp1x,
    double cp1y,
    double cp2x,
    double cp2y,
    double x,
    double y,
  ) {
    if (!cp1x.isFinite ||
        !cp1y.isFinite ||
        !cp2x.isFinite ||
        !cp2y.isFinite ||
        !x.isFinite ||
        !y.isFinite ||
        !transform.isInvertible) {
      return;
    }
    final t = transform;
    final p1x = t.mapX(cp1x, cp1y);
    final p1y = t.mapY(cp1x, cp1y);
    if (!hasSubpath) _moveToMapped(p1x, p1y);
    final px = t.mapX(x, y);
    final py = t.mapY(x, y);
    path.cubicTo(p1x, p1y, t.mapX(cp2x, cp2y), t.mapY(cp2x, cp2y), px, py);
    _lastX = px;
    _lastY = py;
    _ops++;
  }

  @override
  void rect(double x, double y, double w, double h) {
    if (!x.isFinite ||
        !y.isFinite ||
        !w.isFinite ||
        !h.isFinite ||
        !transform.isInvertible) {
      return;
    }
    final t = transform;
    final x0 = t.mapX(x, y);
    final y0 = t.mapY(x, y);
    final x2 = t.mapX(x + w, y + h);
    final y2 = t.mapY(x + w, y + h);
    _moveToMapped(x0, y0);
    // The DOM order of the corners: the direction counts for the nonzero
    // rule when rectangles overlap.
    path
      ..lineTo(t.mapX(x + w, y), t.mapY(x + w, y))
      ..lineTo(x2, y2)
      ..lineTo(t.mapX(x, y + h), t.mapY(x, y + h))
      ..close();
    _rect = t.isAxisAligned
        ? ui.Rect.fromLTRB(
            math.min(x0, x2),
            math.min(y0, y2),
            math.max(x0, x2),
            math.max(y0, y2),
          )
        : null;
    _ops++;
  }

  @override
  void arc(
    double x,
    double y,
    double radius,
    double startAngle,
    double endAngle, [
    bool counterclockwise = false,
  ]) {
    if (!x.isFinite ||
        !y.isFinite ||
        !radius.isFinite ||
        !startAngle.isFinite ||
        !endAngle.isFinite) {
      return;
    }
    if (radius < 0) {
      throw RangeError.value(radius, 'radius', 'The radius is negative');
    }
    if (!transform.isInvertible) return;
    final sweep = canvasArcSweep(startAngle, endAngle, counterclockwise);
    final t = transform;
    if (_ops == 0 && radius > 0 && t.isSimilarity && sweep.abs() >= _tau) {
      // A full circle on an empty path: keep it pending (see [_circle]).
      // The angles are those of [_addArc] for a similarity transform.
      final pcx = t.mapX(x, y);
      final pcy = t.mapY(x, y);
      final r = radius * t.scaleFactor;
      final a0 = t.isReflected ? t.angle - startAngle : t.angle + startAngle;
      _circle = true;
      _circleClosed = false;
      _circleX = pcx;
      _circleY = pcy;
      _circleR = r;
      _circleStart = a0;
      _circleSweep = t.isReflected ? -sweep : sweep;
      final end = a0 + _circleSweep;
      _startX = pcx + r * math.cos(a0);
      _startY = pcy + r * math.sin(a0);
      _lastX = pcx + r * math.cos(end);
      _lastY = pcy + r * math.sin(end);
      hasSubpath = true;
      _ops++;
      return;
    }
    _addArc(x, y, radius, radius, 0, startAngle, sweep);
    _ops++;
  }

  @override
  void ellipse(
    double x,
    double y,
    double radiusX,
    double radiusY,
    double rotation,
    double startAngle,
    double endAngle, [
    bool counterclockwise = false,
  ]) {
    if (!x.isFinite ||
        !y.isFinite ||
        !radiusX.isFinite ||
        !radiusY.isFinite ||
        !rotation.isFinite ||
        !startAngle.isFinite ||
        !endAngle.isFinite) {
      return;
    }
    if (radiusX < 0 || radiusY < 0) {
      throw RangeError('The radius is negative');
    }
    if (!transform.isInvertible) return;
    final sweep = canvasArcSweep(startAngle, endAngle, counterclockwise);
    _addArc(x, y, radiusX, radiusY, rotation, startAngle, sweep);
    _ops++;
  }

  @override
  void arcTo(double x1, double y1, double x2, double y2, double radius) {
    if (!x1.isFinite ||
        !y1.isFinite ||
        !x2.isFinite ||
        !y2.isFinite ||
        !radius.isFinite) {
      return;
    }
    if (radius < 0) {
      throw RangeError.value(radius, 'radius', 'The radius is negative');
    }
    final t = transform;
    if (!t.isInvertible) return;
    _ops++;
    if (!hasSubpath) {
      _moveToMapped(t.mapX(x1, y1), t.mapY(x1, y1));
    }
    // The current point, back in user space.
    final det = t.determinant;
    final lx = _lastX - t.e;
    final ly = _lastY - t.f;
    final x0 = (t.d * lx - t.c * ly) / det;
    final y0 = (t.a * ly - t.b * lx) / det;
    final v1x = x0 - x1;
    final v1y = y0 - y1;
    final v2x = x2 - x1;
    final v2y = y2 - y1;
    final len1 = math.sqrt(v1x * v1x + v1y * v1y);
    final len2 = math.sqrt(v2x * v2x + v2y * v2y);
    final cross = v1x * v2y - v1y * v2x;
    if (len1 == 0 ||
        len2 == 0 ||
        radius == 0 ||
        cross.abs() <= 1e-12 * len1 * len2) {
      _lineOrMove(x1, y1);
      return;
    }
    final u1x = v1x / len1;
    final u1y = v1y / len1;
    final u2x = v2x / len2;
    final u2y = v2y / len2;
    // The angle between the two lines at (x1, y1).
    final cos = (u1x * u2x + u1y * u2y).clamp(-1.0, 1.0);
    final half = math.acos(cos) / 2;
    final tangent = radius / math.tan(half);
    final t1x = x1 + u1x * tangent;
    final t1y = y1 + u1y * tangent;
    final t2x = x1 + u2x * tangent;
    final t2y = y1 + u2y * tangent;
    var bx = u1x + u2x;
    var by = u1y + u2y;
    final blen = math.sqrt(bx * bx + by * by);
    bx /= blen;
    by /= blen;
    final centerDistance = radius / math.sin(half);
    final cx = x1 + bx * centerDistance;
    final cy = y1 + by * centerDistance;
    final start = math.atan2(t1y - cy, t1x - cx);
    var sweep = math.atan2(t2y - cy, t2x - cx) - start;
    if (sweep > math.pi) sweep -= _tau;
    if (sweep < -math.pi) sweep += _tau;
    _addArc(cx, cy, radius, radius, 0, start, sweep);
  }

  /// Adds the arc of the ellipse at (cx, cy) with the radii rx and ry,
  /// rotated by [rotation], from the parametric angle [start] over [sweep]
  /// radians, all in user space. A line connects the current point to the
  /// start of the arc.
  void _addArc(
    double cx,
    double cy,
    double rx,
    double ry,
    double rotation,
    double start,
    double sweep,
  ) {
    final t = transform;
    if (rx == 0 && ry == 0) {
      _lineOrMove(cx, cy);
      return;
    }
    if (rx == ry && t.isSimilarity) {
      final pcx = t.mapX(cx, cy);
      final pcy = t.mapY(cx, cy);
      final r = rx * t.scaleFactor;
      final a0 = t.isReflected
          ? t.angle - (start + rotation)
          : t.angle + start + rotation;
      _nativeArc(
        ui.Rect.fromCircle(center: ui.Offset(pcx, pcy), radius: r),
        pcx,
        pcy,
        r,
        r,
        a0,
        t.isReflected ? -sweep : sweep,
      );
      return;
    }
    if (rotation == 0 && t.isAxisAligned) {
      final pcx = t.mapX(cx, cy);
      final pcy = t.mapY(cx, cy);
      final hx = rx * t.a.abs();
      final hy = ry * t.d.abs();
      double a0;
      double sw;
      if (t.a < 0 && t.d < 0) {
        a0 = start + math.pi;
        sw = sweep;
      } else if (t.a < 0) {
        a0 = math.pi - start;
        sw = -sweep;
      } else if (t.d < 0) {
        a0 = -start;
        sw = -sweep;
      } else {
        a0 = start;
        sw = sweep;
      }
      _nativeArc(
        ui.Rect.fromLTRB(pcx - hx, pcy - hy, pcx + hx, pcy + hy),
        pcx,
        pcy,
        hx,
        hy,
        a0,
        sw,
      );
      return;
    }
    _bezierArc(cx, cy, rx, ry, rotation, start, sweep);
  }

  /// A `ui.Path.arcTo` in bitmap space. A sweep of more than half a turn
  /// is two half arcs: `arcTo` takes the sweep in float degrees, and a
  /// sweep that rounds to 360 degrees adds only a point. Chromium draws a
  /// circle for it.
  void _nativeArc(
    ui.Rect oval,
    double cx,
    double cy,
    double rx,
    double ry,
    double start,
    double sweep,
  ) {
    final sx = cx + rx * math.cos(start);
    final sy = cy + ry * math.sin(start);
    if (sweep == 0) {
      if (hasSubpath) {
        _lineToMapped(sx, sy);
      } else {
        _moveToMapped(sx, sy);
      }
      return;
    }
    final forceMoveTo = !hasSubpath;
    if (forceMoveTo) {
      _startX = sx;
      _startY = sy;
      hasSubpath = true;
    }
    if (sweep.abs() > math.pi) {
      final half = sweep / 2;
      path
        ..arcTo(oval, start, half, forceMoveTo)
        ..arcTo(oval, start + half, half, false);
    } else {
      path.arcTo(oval, start, sweep, forceMoveTo);
    }
    final end = start + sweep;
    _lastX = cx + rx * math.cos(end);
    _lastY = cy + ry * math.sin(end);
  }

  /// The arc as cubic Bézier curves of at most 90 degrees each, for a
  /// transform that skews or scales unevenly, or a rotated ellipse.
  void _bezierArc(
    double cx,
    double cy,
    double rx,
    double ry,
    double rotation,
    double start,
    double sweep,
  ) {
    final t = transform;
    final cosR = math.cos(rotation);
    final sinR = math.sin(rotation);
    final segments = math.max(1, (sweep.abs() / (math.pi / 2) - 1e-9).ceil());
    final delta = sweep / segments;
    final k = 4 / 3 * math.tan(delta / 4);
    var cosP = math.cos(start);
    var sinP = math.sin(start);
    var x0 = cx + rx * cosP * cosR - ry * sinP * sinR;
    var y0 = cy + rx * cosP * sinR + ry * sinP * cosR;
    _lineOrMove(x0, y0);
    for (var i = 1; i <= segments; i++) {
      final phi = start + delta * i;
      final cos1 = math.cos(phi);
      final sin1 = math.sin(phi);
      final x1 = cx + rx * cos1 * cosR - ry * sin1 * sinR;
      final y1 = cy + rx * cos1 * sinR + ry * sin1 * cosR;
      final d0x = -rx * sinP * cosR - ry * cosP * sinR;
      final d0y = -rx * sinP * sinR + ry * cosP * cosR;
      final d1x = -rx * sin1 * cosR - ry * cos1 * sinR;
      final d1y = -rx * sin1 * sinR + ry * cos1 * cosR;
      final c1x = x0 + k * d0x;
      final c1y = y0 + k * d0y;
      final c2x = x1 - k * d1x;
      final c2y = y1 - k * d1y;
      final px = t.mapX(x1, y1);
      final py = t.mapY(x1, y1);
      path.cubicTo(
        t.mapX(c1x, c1y),
        t.mapY(c1x, c1y),
        t.mapX(c2x, c2y),
        t.mapY(c2x, c2y),
        px,
        py,
      );
      _lastX = px;
      _lastY = py;
      x0 = x1;
      y0 = y1;
      cosP = cos1;
      sinP = sin1;
    }
  }
}

/// The `ui.Path` of a [Path2D], in user space, kept in [Path2D.cache].
final class _CachedPath {
  _CachedPath(this.version, this.path);

  final int version;
  final ui.Path path;
}

final UiTransform _identity = UiTransform();

/// The `ui.Path` of [path2d] in user space. The result is cached on the
/// path while [Path2D.version] does not change.
ui.Path uiPathOf(Path2D path2d) {
  final cache = path2d.cache;
  if (cache is _CachedPath && cache.version == path2d.version) {
    return cache.path;
  }
  final builder = UiPathBuilder(_identity);
  path2d
    ..replay(builder)
    ..cache = _CachedPath(path2d.version, builder.path);
  return builder.path;
}
