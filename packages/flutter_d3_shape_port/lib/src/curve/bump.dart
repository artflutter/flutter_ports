// Ported from d3-shape v3.2.0 src/curve/bump.js (ISC, Mike Bostock).

/// Port of `src/curve/bump.js` of d3-shape 3.2.0: [BumpCurve],
/// [BumpRadialCurve], [curveBumpX], [curveBumpY], and [curveBumpRadial].
library;

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/curve.dart';
import 'package:flutter_d3_shape_port/src/math.dart';

/// `curve/bump.js:3` `Bump`: Bézier curve with horizontal (`_x == true`) or
/// vertical (`_x == false`) tangents at each point.
class BumpCurve(final CanvasPath _context, final bool _x) implements Curve {
  /// Creates a bump curve writing into [_context].
  this;

  int _line = -1;
  int _point = 0;
  double _x0 = 0;
  double _y0 = 0;

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
    _point = 0;
  }

  @override
  void lineEnd() {
    if (_line == 1 || (_line != 0 && _point == 1)) _context.closePath();
    if (_line >= 0) _line = 1 - _line;
  }

  @override
  void point(double x, double y) {
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
        if (_x) {
          _x0 = (_x0 + x) / 2;
          _context.bezierCurveTo(_x0, _y0, _x0, y, x, y);
        } else {
          _y0 = (_y0 + y) / 2;
          _context.bezierCurveTo(_x0, _y0, x, _y0, x, y);
        }
      default:
        if (_x) {
          _x0 = (_x0 + x) / 2;
          _context.bezierCurveTo(_x0, _y0, _x0, y, x, y);
        } else {
          _y0 = (_y0 + y) / 2;
          _context.bezierCurveTo(_x0, _y0, x, _y0, x, y);
        }
    }
    _x0 = x;
    _y0 = y;
  }
}

/// `curve/bump.js:41` `BumpRadial`: radial bump Bézier curve used by
/// `linkRadial`.
class BumpRadialCurve(final CanvasPath _context) implements Curve {
  /// Creates a radial bump curve writing into [_context].
  this;

  int _point = 0;
  double _x0 = 0;
  double _y0 = 0;

  @override
  void areaStart() {}

  @override
  void areaEnd() {}

  @override
  void lineStart() {
    _point = 0;
  }

  @override
  void lineEnd() {}

  @override
  // DIVERGES(d3-shape): adapt-shape-fast-forms, inline polar trig (2 sin/cos
  // pairs instead of 4 pointRadial record calls).
  void point(double x, double y) {
    if (_point == 0) {
      _point = 1;
    } else {
      final a0 = _x0 - shapeHalfPi;
      final c0 = math.cos(a0);
      final s0 = math.sin(a0);
      final a1 = x - shapeHalfPi;
      final c1 = math.cos(a1);
      final s1 = math.sin(a1);
      final midY = (_y0 + y) / 2;
      _context
        ..moveTo(_y0 * c0, _y0 * s0)
        ..bezierCurveTo(
          midY * c0,
          midY * s0,
          midY * c1,
          midY * s1,
          y * c1,
          y * s1,
        );
      _y0 = midY;
    }
    _x0 = x;
    _y0 = y;
  }
}

/// `curve/bump.js:65` `bumpX` (`curveBumpX`): horizontal bump curve.
Curve curveBumpX(CanvasPath context) => BumpCurve(context, true);

/// `curve/bump.js:69` `bumpY` (`curveBumpY`): vertical bump curve.
Curve curveBumpY(CanvasPath context) => BumpCurve(context, false);

/// `curve/bump.js:73` `bumpRadial`: radial bump curve for `linkRadial`.
Curve curveBumpRadial(CanvasPath context) => BumpRadialCurve(context);
