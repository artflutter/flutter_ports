// Ported from d3-shape v3.2.0 src/curve/monotone.js (ISC, Mike Bostock).

/// Port of `src/curve/monotone.js` of d3-shape 3.2.0: [MonotoneXCurve],
/// [MonotoneYCurve], [curveMonotoneX], and [curveMonotoneY].
library;

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/curve.dart';

@pragma('vm:prefer-inline')
double _sign(double x) => x < 0 ? -1 : 1;

// Steffen, M. 1990. A Simple Method for Monotonic Interpolation in One
// Dimension. Astronomy and Astrophysics, Vol. 239, NO. NOV(II), P. 443, 1990.
@pragma('vm:prefer-inline')
double _slope3(
  double x0,
  double y0,
  double x1,
  double y1,
  double x2,
  double y2,
) {
  final h0 = x1 - x0;
  final h1 = x2 - x1;
  final d0 = h0 != 0 ? h0 : (h1 < 0 ? -0.0 : 0.0);
  final d1 = h1 != 0 ? h1 : (h0 < 0 ? -0.0 : 0.0);
  final s0 = (y1 - y0) / d0;
  final s1 = (y2 - y1) / d1;
  final p = (s0 * h1 + s1 * h0) / (h0 + h1);
  final m = math.min(math.min(s0.abs(), s1.abs()), 0.5 * p.abs());
  final r = (_sign(s0) + _sign(s1)) * m;
  return r.isNaN || r == 0 ? 0.0 : r;
}

@pragma('vm:prefer-inline')
double _slope2(double x0, double y0, double x1, double y1, double t) {
  final h = x1 - x0;
  return h != 0 && !h.isNaN ? (3 * (y1 - y0) / h - t) / 2 : t;
}

@pragma('vm:prefer-inline')
void _monotonePoint(
  CanvasPath context,
  double x0,
  double y0,
  double x1,
  double y1,
  double t0,
  double t1,
) {
  final dx = (x1 - x0) / 3;
  context.bezierCurveTo(x0 + dx, y0 + dx * t0, x1 - dx, y1 - dx * t1, x1, y1);
}

/// `curve/monotone.js:36` `MonotoneX`: cubic spline preserving monotonicity in
/// y, assuming monotonicity in x.
class MonotoneXCurve(final CanvasPath _context) implements Curve {
  /// Creates a monotone-in-x curve writing into [_context].
  this;

  int _line = -1;
  int _point = 0;
  double _x0 = double.nan;
  double _x1 = double.nan;
  double _y0 = double.nan;
  double _y1 = double.nan;
  double _t0 = double.nan;

  @override
  void areaStart() {
    _line = 0;
  }

  @override
  void areaEnd() {
    _line = -1;
  }

  @override
  void lineStart() {
    _x0 = _x1 = _y0 = _y1 = _t0 = double.nan;
    _point = 0;
  }

  @override
  void lineEnd() {
    switch (_point) {
      case 2:
        _context.lineTo(_x1, _y1);
      case 3:
        _monotonePoint(
          _context,
          _x0,
          _y0,
          _x1,
          _y1,
          _t0,
          _slope2(_x0, _y0, _x1, _y1, _t0),
        );
    }
    if (_line == 1 || (_line != 0 && _point == 1)) _context.closePath();
    if (_line >= 0) _line = 1 - _line;
  }

  @override
  void point(double x, double y) {
    var t1 = double.nan;

    if (x == _x1 && y == _y1) return; // Ignore coincident points.
    switch (_point) {
      case 0:
        _point = 1;
        if (_line == 1) {
          _context.lineTo(x, y);
        } else {
          _context.moveTo(x, y);
        }
      case 1:
        _point = 2;
      case 2:
        _point = 3;
        t1 = _slope3(_x0, _y0, _x1, _y1, x, y);
        _monotonePoint(
          _context,
          _x0,
          _y0,
          _x1,
          _y1,
          _slope2(_x0, _y0, _x1, _y1, t1),
          t1,
        );
      default:
        t1 = _slope3(_x0, _y0, _x1, _y1, x, y);
        _monotonePoint(_context, _x0, _y0, _x1, _y1, _t0, t1);
    }

    _x0 = _x1;
    _x1 = x;
    _y0 = _y1;
    _y1 = y;
    _t0 = t1;
  }
}

final class _ReflectContext(final CanvasPath _context) implements CanvasPath {
  @override
  void moveTo(double x, double y) => _context.moveTo(y, x);

  @override
  void closePath() => _context.closePath();

  @override
  void lineTo(double x, double y) => _context.lineTo(y, x);

  @override
  void quadraticCurveTo(double x1, double y1, double x, double y) =>
      _context.quadraticCurveTo(y1, x1, y, x);

  @override
  void bezierCurveTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x,
    double y,
  ) => _context.bezierCurveTo(y1, x1, y2, x2, y, x);

  @override
  void arcTo(double x1, double y1, double x2, double y2, double r) =>
      _context.arcTo(y1, x1, y2, x2, r);

  @override
  void arc(
    double x,
    double y,
    double r,
    double a0,
    double a1, [
    bool ccw = false,
  ]) => _context.arc(y, x, r, a0, a1, ccw);

  @override
  void rect(double x, double y, double w, double h) =>
      _context.rect(y, x, h, w);
}

/// `curve/monotone.js:79` `MonotoneY`: cubic spline preserving monotonicity in
/// x, assuming monotonicity in y.
class MonotoneYCurve(CanvasPath context) extends MonotoneXCurve {
  /// Creates a monotone-in-y curve writing into [context].
  this : super(_ReflectContext(context));

  @override
  void point(double x, double y) => super.point(y, x);
}

/// `curve/monotone.js:98` `monotoneX` (`curveMonotoneX`): monotone cubic
/// spline in y assuming monotonicity in x.
Curve curveMonotoneX(CanvasPath context) => MonotoneXCurve(context);

/// `curve/monotone.js:102` `monotoneY` (`curveMonotoneY`): monotone cubic
/// spline in x assuming monotonicity in y.
Curve curveMonotoneY(CanvasPath context) => MonotoneYCurve(context);
