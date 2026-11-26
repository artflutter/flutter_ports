// Ported from d3-shape v3.2.0 src/curve/basis.js (ISC, Mike Bostock).

/// Port of `src/curve/basis.js` of d3-shape 3.2.0: [BasisCurve], [basisPoint],
/// and [curveBasis].
library;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/curve.dart';

/// `curve/basis.js:1` `point`: emits a cubic B-spline segment to [context].
@pragma('vm:prefer-inline')
void basisPoint(
  CanvasPath context,
  double x0,
  double y0,
  double x1,
  double y1,
  double x,
  double y,
) {
  context.bezierCurveTo(
    (2 * x0 + x1) / 3,
    (2 * y0 + y1) / 3,
    (x0 + 2 * x1) / 3,
    (y0 + 2 * y1) / 3,
    (x0 + 4 * x1 + x) / 6,
    (y0 + 4 * y1 + y) / 6,
  );
}

/// `curve/basis.js:12` `Basis`: cubic basis spline curve.
class BasisCurve(final CanvasPath _context) implements Curve {
  /// Creates a basis spline curve writing into [_context].
  this;

  int _line = -1;
  int _point = 0;
  double _x0 = double.nan;
  double _x1 = double.nan;
  double _y0 = double.nan;
  double _y1 = double.nan;

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
    _x0 = _x1 = _y0 = _y1 = double.nan;
    _point = 0;
  }

  @override
  void lineEnd() {
    switch (_point) {
      case 3:
        basisPoint(_context, _x0, _y0, _x1, _y1, _x1, _y1);
        _context.lineTo(_x1, _y1);
      case 2:
        _context.lineTo(_x1, _y1);
    }
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
      case 2:
        _point = 3;
        _context.lineTo((5 * _x0 + _x1) / 6, (5 * _y0 + _y1) / 6);
        basisPoint(_context, _x0, _y0, _x1, _y1, x, y);
      default:
        basisPoint(_context, _x0, _y0, _x1, _y1, x, y);
    }
    _x0 = _x1;
    _x1 = x;
    _y0 = _y1;
    _y1 = y;
  }
}

/// `curve/basis.js:49` default export: produces a cubic basis spline.
Curve curveBasis(CanvasPath context) => BasisCurve(context);
