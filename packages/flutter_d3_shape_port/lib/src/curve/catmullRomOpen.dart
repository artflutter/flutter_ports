// Ported from d3-shape v3.2.0 src/curve/catmullRomOpen.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/curve/catmullRomOpen.js` of d3-shape 3.2.0:
/// [CatmullRomOpenCurve], [CurveCatmullRomOpenFactory], and
/// [curveCatmullRomOpen].
library;

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/curve.dart';
import 'package:flutter_d3_shape_port/src/curve/cardinalOpen.dart';
import 'package:flutter_d3_shape_port/src/curve/catmullRom.dart';

/// `curve/catmullRomOpen.js:4` `CatmullRomOpen`: open cubic Catmull-Rom spline
/// curve.
class CatmullRomOpenCurve(final CanvasPath _context, final double _alpha)
    implements Curve {
  /// Creates an open Catmull-Rom spline curve writing into [_context] with
  /// [_alpha].
  this;

  final int _alphaKind = catmullRomAlphaKind(_alpha);
  int _line = -1;
  int _point = 0;
  double _x0 = double.nan;
  double _x1 = double.nan;
  double _x2 = double.nan;
  double _y0 = double.nan;
  double _y1 = double.nan;
  double _y2 = double.nan;
  double _l01a = 0;
  double _l12a = 0;
  double _l23a = 0;
  double _l012a = 0;
  double _l122a = 0;
  double _l232a = 0;

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
    _x0 = _x1 = _x2 = _y0 = _y1 = _y2 = double.nan;
    _l01a = _l12a = _l23a = _l012a = _l122a = _l232a = 0;
    _point = 0;
  }

  @override
  void lineEnd() {
    if (_line == 1 || (_line != 0 && _point == 3)) _context.closePath();
    if (_line >= 0) _line = 1 - _line;
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
      case 1:
        _point = 2;
      case 2:
        _point = 3;
        if (_line == 1) {
          _context.lineTo(_x2, _y2);
        } else {
          _context.moveTo(_x2, _y2);
        }
      case 3:
        _point = 4;
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

/// `curve/catmullRomOpen.js:51` callable open Catmull-Rom curve factory with
/// configurable [alpha].
// DIVERGES(d3-shape): adapt-shape-typed-api, const callable factory class.
final class const CurveCatmullRomOpenFactory._(final double _alpha) {
  /// Creates an open Catmull-Rom curve factory with [_alpha].
  this;

  /// Creates a [Curve] for [context].
  Curve call(CanvasPath context) => _alpha != 0 && !_alpha.isNaN
      ? CatmullRomOpenCurve(context, _alpha)
      : CardinalOpenCurve(context, 0);

  /// Returns an open Catmull-Rom curve factory with the specified [alpha].
  CurveCatmullRomOpenFactory alpha(double alpha) =>
      CurveCatmullRomOpenFactory._(alpha);
}

/// `curve/catmullRomOpen.js:51` default export: open centripetal Catmull-Rom
/// spline with default `alpha = 0.5`.
const CurveCatmullRomOpenFactory curveCatmullRomOpen =
    CurveCatmullRomOpenFactory._(0.5);
