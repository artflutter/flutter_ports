// Ported from d3-shape v3.2.0 src/curve/catmullRom.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/curve/catmullRom.js` of d3-shape 3.2.0: [CatmullRomCurve],
/// [catmullRomPoint], [CurveCatmullRomFactory], and [curveCatmullRom].
library;

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/curve.dart';
import 'package:flutter_d3_shape_port/src/curve/cardinal.dart';
import 'package:flutter_d3_shape_port/src/math.dart';

/// `curve/catmullRom.js:4` `point`: emits a cubic Catmull-Rom spline segment
/// to [context].
@pragma('vm:prefer-inline')
void catmullRomPoint(
  CanvasPath context,
  double x0,
  double y0,
  double x1Init,
  double y1Init,
  double x2Init,
  double y2Init,
  double x,
  double y,
  double l01a,
  double l12a,
  double l23a,
  double l012a,
  double l122a,
  double l232a,
) {
  var x1 = x1Init;
  var y1 = y1Init;
  var x2 = x2Init;
  var y2 = y2Init;

  if (l01a > shapeEpsilon) {
    final a = 2 * l012a + 3 * l01a * l12a + l122a;
    final n = 3 * l01a * (l01a + l12a);
    x1 = (x1 * a - x0 * l122a + x2Init * l012a) / n;
    y1 = (y1 * a - y0 * l122a + y2Init * l012a) / n;
  }

  if (l23a > shapeEpsilon) {
    final b = 2 * l232a + 3 * l23a * l12a + l122a;
    final m = 3 * l23a * (l23a + l12a);
    x2 = (x2 * b + x1Init * l232a - x * l122a) / m;
    y2 = (y2 * b + y1Init * l232a - y * l122a) / m;
  }

  context.bezierCurveTo(x1, y1, x2, y2, x2Init, y2Init);
}

/// Fast `d2^alpha` helper avoiding C++ `math.pow` for centripetal (`0.5`) and
/// chordal (`1.0`) Catmull-Rom curves.
// DIVERGES(d3-shape): adapt-shape-fast-forms, sqrt/identity fast paths for
// alpha == 0.5 and alpha == 1.0.
@pragma('vm:prefer-inline')
double catmullRomPow(double d2, double alpha, int kind) {
  if (kind == 1) return math.sqrt(d2);
  if (kind == 2) return d2;
  return math.pow(d2, alpha).toDouble();
}

/// Classifies [alpha] into `1` (`0.5`), `2` (`1.0`), or `0` (general).
int catmullRomAlphaKind(double alpha) =>
    alpha == 0.5 ? 1 : (alpha == 1.0 ? 2 : 0);

/// `curve/catmullRom.js:27` `CatmullRom`: cubic Catmull-Rom spline curve.
class CatmullRomCurve(final CanvasPath _context, final double _alpha)
    implements Curve {
  /// Creates a Catmull-Rom spline curve writing into [_context] with [_alpha].
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
    switch (_point) {
      case 2:
        _context.lineTo(_x2, _y2);
      case 3:
        point(_x2, _y2);
    }
    if (_line == 1 || (_line != 0 && _point == 1)) _context.closePath();
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
        if (_line == 1) {
          _context.lineTo(x, y);
        } else {
          _context.moveTo(x, y);
        }
      case 1:
        _point = 2;
      case 2:
        _point = 3;
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

/// `curve/catmullRom.js:77` callable Catmull-Rom curve factory with
/// configurable [alpha].
// DIVERGES(d3-shape): adapt-shape-typed-api, const callable factory class.
final class const CurveCatmullRomFactory._(final double _alpha) {
  /// Creates a Catmull-Rom curve factory with [_alpha].
  this;

  /// Creates a [Curve] for [context].
  Curve call(CanvasPath context) => _alpha != 0 && !_alpha.isNaN
      ? CatmullRomCurve(context, _alpha)
      : CardinalCurve(context, 0);

  /// Returns a Catmull-Rom curve factory with the specified [alpha] in
  /// `[0, 1]`.
  CurveCatmullRomFactory alpha(double alpha) => CurveCatmullRomFactory._(alpha);
}

/// `curve/catmullRom.js:77` default export: centripetal Catmull-Rom spline
/// with default `alpha = 0.5`.
const CurveCatmullRomFactory curveCatmullRom = CurveCatmullRomFactory._(0.5);
