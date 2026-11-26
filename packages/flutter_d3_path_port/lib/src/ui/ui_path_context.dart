// Original code, not ported from d3-path: native Flutter dart:ui Path builder.

/// Flutter `dart:ui.Path` implementation of [CanvasPath] (D3 ADR 0014).
///
/// Draws Canvas 2D / D3 path commands directly into a `dart:ui.Path` without
/// formatting or parsing SVG path strings.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_d3_path_port/src/canvas_path.dart';

const double _pi = math.pi;
const double _tau = 2 * _pi;
const double _epsilon = 1e-6;
const double _tauEpsilon = _tau - _epsilon;

/// A [CanvasPath] that records commands directly into a Flutter [ui.Path].
///
/// Implements the Canvas 2D path semantics used by D3 generators:
/// - `arc` connects the current point to the arc start point and splits full
///   circles (sweep >= 2π) into two half-arcs so [ui.Path.arcTo] does not
///   collapse them.
/// - `arcTo` computes the tangent arc between `(current → p1)` and `(p1 → p2)`.
/// - Negative radii throw [RangeError].
/// - Non-finite arguments are ignored.
/// - `lineTo`, `quadraticCurveTo`, and `bezierCurveTo` on an empty path start
///   a subpath at their first point.
final class UiPathContext([ui.Path? path]) implements CanvasPath {
  /// Creates a [UiPathContext] writing into [path], or a fresh [ui.Path] if
  /// omitted.
  this;

  /// The underlying Flutter [ui.Path].
  final ui.Path path = path ?? ui.Path();

  double _x0 = 0;
  double _y0 = 0;
  double _x1 = 0;
  double _y1 = 0;
  bool _hasPoint = false;

  /// Resets the underlying [ui.Path] and current subpath tracking so this
  /// context can be reused across frames without allocation.
  void reset() {
    path.reset();
    _x0 = 0;
    _y0 = 0;
    _x1 = 0;
    _y1 = 0;
    _hasPoint = false;
  }

  @override
  void moveTo(double x, double y) {
    if (!x.isFinite || !y.isFinite) return;
    path.moveTo(x, y);
    _x0 = _x1 = x;
    _y0 = _y1 = y;
    _hasPoint = true;
  }

  @override
  void closePath() {
    if (!_hasPoint) return;
    path.close();
    _x1 = _x0;
    _y1 = _y0;
  }

  @override
  void lineTo(double x, double y) {
    if (!x.isFinite || !y.isFinite) return;
    if (!_hasPoint) {
      moveTo(x, y);
      return;
    }
    path.lineTo(x, y);
    _x1 = x;
    _y1 = y;
  }

  @override
  void quadraticCurveTo(double x1, double y1, double x, double y) {
    if (!x1.isFinite || !y1.isFinite || !x.isFinite || !y.isFinite) return;
    if (!_hasPoint) {
      moveTo(x1, y1);
    }
    path.quadraticBezierTo(x1, y1, x, y);
    _x1 = x;
    _y1 = y;
  }

  @override
  void bezierCurveTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x,
    double y,
  ) {
    if (!x1.isFinite ||
        !y1.isFinite ||
        !x2.isFinite ||
        !y2.isFinite ||
        !x.isFinite ||
        !y.isFinite) {
      return;
    }
    if (!_hasPoint) {
      moveTo(x1, y1);
    }
    path.cubicTo(x1, y1, x2, y2, x, y);
    _x1 = x;
    _y1 = y;
  }

  @override
  void arcTo(double x1, double y1, double x2, double y2, double r) {
    if (!x1.isFinite ||
        !y1.isFinite ||
        !x2.isFinite ||
        !y2.isFinite ||
        !r.isFinite) {
      return;
    }
    if (r < 0) {
      throw RangeError.value(r, 'r', 'negative radius: $r');
    }
    if (!_hasPoint) {
      moveTo(x1, y1);
      return;
    }

    final x0 = _x1;
    final y0 = _y1;
    final x21 = x2 - x1;
    final y21 = y2 - y1;
    final x01 = x0 - x1;
    final y01 = y0 - y1;
    final l01_2 = x01 * x01 + y01 * y01;

    if (!(l01_2 > _epsilon)) return;

    if (!((y01 * x21 - y21 * x01).abs() > _epsilon) || r == 0) {
      lineTo(x1, y1);
      return;
    }

    final x20 = x2 - x0;
    final y20 = y2 - y0;
    final l21_2 = x21 * x21 + y21 * y21;
    final l20_2 = x20 * x20 + y20 * y20;
    final l21 = math.sqrt(l21_2);
    final l01 = math.sqrt(l01_2);
    final rawCos = (l21_2 + l01_2 - l20_2) / (2 * l21 * l01);
    final cosAngle = rawCos < -1.0 ? -1.0 : (rawCos > 1.0 ? 1.0 : rawCos);
    final l = r * math.tan((_pi - math.acos(cosAngle)) / 2);
    final t01 = l / l01;
    final t21 = l / l21;

    if ((t01 - 1).abs() > _epsilon) {
      path.lineTo(x1 + t01 * x01, y1 + t01 * y01);
    }

    final ex = x1 + t21 * x21;
    final ey = y1 + t21 * y21;
    path.arcToPoint(
      ui.Offset(ex, ey),
      radius: ui.Radius.circular(r),
      clockwise: y01 * x20 > x01 * y20,
    );
    _x1 = ex;
    _y1 = ey;
  }

  @override
  void arc(
    double x,
    double y,
    double r,
    double a0,
    double a1, [
    bool ccw = false,
  ]) {
    if (!x.isFinite ||
        !y.isFinite ||
        !r.isFinite ||
        !a0.isFinite ||
        !a1.isFinite) {
      return;
    }
    if (r < 0) {
      throw RangeError.value(r, 'r', 'negative radius: $r');
    }

    final dx = r * math.cos(a0);
    final dy = r * math.sin(a0);
    final x0 = x + dx;
    final y0 = y + dy;
    var da = ccw ? a0 - a1 : a1 - a0;

    if (!_hasPoint) {
      path.moveTo(x0, y0);
      _x0 = _x1 = x0;
      _y0 = _y1 = y0;
      _hasPoint = true;
    } else if ((_x1 - x0).abs() > _epsilon || (_y1 - y0).abs() > _epsilon) {
      path.lineTo(x0, y0);
      _x1 = x0;
      _y1 = y0;
    }

    if (r == 0) return;

    if (da < 0) da = da.remainder(_tau) + _tau;

    final rect = ui.Rect.fromLTRB(x - r, y - r, x + r, y + r);
    if (da > _tauEpsilon) {
      final half = ccw ? -_pi : _pi;
      path
        ..arcTo(rect, a0, half, false)
        ..arcTo(rect, a0 + half, half, false);
      _x1 = x0;
      _y1 = y0;
    } else if (da > _epsilon) {
      path.arcTo(rect, a0, ccw ? -da : da, false);
      _x1 = x + r * math.cos(a1);
      _y1 = y + r * math.sin(a1);
    }
  }

  @override
  void rect(double x, double y, double w, double h) {
    if (!x.isFinite || !y.isFinite || !w.isFinite || !h.isFinite) return;
    path.addRect(ui.Rect.fromLTWH(x, y, w, h));
    _x0 = _x1 = x;
    _y0 = _y1 = y;
    _hasPoint = true;
  }
}

/// Constructs a new [UiPathContext] wrapping [path] (or a new [ui.Path]).
UiPathContext uiPathContext([ui.Path? path]) => UiPathContext(path);
