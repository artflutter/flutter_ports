// Ported from d3-shape v3.2.0 src/curve/catmullRomClosed.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/curve/catmullRomClosed.js` of d3-shape 3.2.0:
/// [CatmullRomClosedCurve], [CurveCatmullRomClosedFactory], and
/// [curveCatmullRomClosed].
library;

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/curve.dart';
import 'package:flutter_d3_shape_port/src/curve/cardinalClosed.dart';
import 'package:flutter_d3_shape_port/src/curve/catmullRom.dart';

/// `curve/catmullRomClosed.js:5` `CatmullRomClosed`: closed cubic Catmull-Rom
/// spline curve.
class CatmullRomClosedCurve(final CanvasPath _context, final double _alpha)
    implements Curve {
  /// Creates a closed Catmull-Rom spline curve writing into [_context] with
  /// [_alpha].
  this;

  final int _alphaKind = catmullRomAlphaKind(_alpha);
  int _point = 0;
  double _x0 = double.nan;
  double _x1 = double.nan;
  double _x2 = double.nan;
  double _x3 = double.nan;
  double _x4 = double.nan;
  double _x5 = double.nan;
  double _y0 = double.nan;
  double _y1 = double.nan;
  double _y2 = double.nan;
  double _y3 = double.nan;
  double _y4 = double.nan;
  double _y5 = double.nan;
  double _l01a = 0;
  double _l12a = 0;
  double _l23a = 0;
  double _l012a = 0;
  double _l122a = 0;
  double _l232a = 0;

  @override
  void areaStart() {}

  @override
  void areaEnd() {}

  @override
  void lineStart() {
    _x0 = _x1 = _x2 = _x3 = _x4 = _x5 = _y0 = _y1 = _y2 = _y3 = _y4 = _y5 =
        double.nan;
    _l01a = _l12a = _l23a = _l012a = _l122a = _l232a = 0;
    _point = 0;
  }

  @override
  void lineEnd() {
    switch (_point) {
      case 1:
        _context
          ..moveTo(_x3, _y3)
          ..closePath();
      case 2:
        _context
          ..lineTo(_x3, _y3)
          ..closePath();
      case 3:
        point(_x3, _y3);
        point(_x4, _y4);
        point(_x5, _y5);
    }
  }

  @override
  void point(double x, double y) {
    if (_point != 0) {
      final x23 = _x2 - x;
      final y23 = _y2 - y;
      _l232a = catmullRomPow(x23 * x23 + y23 * y23, _alpha, _alphaKind);
      _l23a = math.sqrt(_l232a);
    }

    switch (_point) {
      case 0:
        _point = 1;
        _x3 = x;
        _y3 = y;
      case 1:
        _point = 2;
        _x4 = x;
        _y4 = y;
        _context.moveTo(x, y);
      case 2:
        _point = 3;
        _x5 = x;
        _y5 = y;
      default:
        catmullRomPoint(
          _context,
          _x0,
          _y0,
          _x1,
          _y1,
          _x2,
          _y2,
          x,
          y,
          _l01a,
          _l12a,
          _l23a,
          _l012a,
          _l122a,
          _l232a,
        );
    }

    _l01a = _l12a;
    _l12a = _l23a;
    _l012a = _l122a;
    _l122a = _l232a;
    _x0 = _x1;
    _x1 = _x2;
    _x2 = x;
    _y0 = _y1;
    _y1 = _y2;
    _y2 = y;
  }
}

/// `curve/catmullRomClosed.js:63` callable closed Catmull-Rom curve factory
/// with configurable [alpha].
// DIVERGES(d3-shape): adapt-shape-typed-api, const callable factory class.
final class const CurveCatmullRomClosedFactory._(final double _alpha) {
  /// Creates a closed Catmull-Rom curve factory with [_alpha].
  this;

  /// Creates a [Curve] for [context].
  Curve call(CanvasPath context) => _alpha != 0 && !_alpha.isNaN
      ? CatmullRomClosedCurve(context, _alpha)
      : CardinalClosedCurve(context, 0);

  /// Returns a closed Catmull-Rom curve factory with the specified [alpha].
  CurveCatmullRomClosedFactory alpha(double alpha) =>
      CurveCatmullRomClosedFactory._(alpha);
}

/// `curve/catmullRomClosed.js:63` default export: closed centripetal
/// Catmull-Rom spline with default `alpha = 0.5`.
const CurveCatmullRomClosedFactory curveCatmullRomClosed =
    CurveCatmullRomClosedFactory._(0.5);
