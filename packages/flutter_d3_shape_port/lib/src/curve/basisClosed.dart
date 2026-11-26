// Ported from d3-shape v3.2.0 src/curve/basisClosed.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/curve/basisClosed.js` of d3-shape 3.2.0: [BasisClosedCurve]
/// and [curveBasisClosed].
library;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/curve.dart';
import 'package:flutter_d3_shape_port/src/curve/basis.dart';

/// `curve/basisClosed.js:4` `BasisClosed`: closed cubic basis spline curve.
class BasisClosedCurve(final CanvasPath _context) implements Curve {
  /// Creates a closed basis spline curve writing into [_context].
  this;

  int _point = 0;
  double _x0 = double.nan;
  double _x1 = double.nan;
  double _x2 = double.nan;
  double _x3 = double.nan;
  double _x4 = double.nan;
  double _y0 = double.nan;
  double _y1 = double.nan;
  double _y2 = double.nan;
  double _y3 = double.nan;
  double _y4 = double.nan;

  @override
  void areaStart() {}

  @override
  void areaEnd() {}

  @override
  void lineStart() {
    _x0 = _x1 = _x2 = _x3 = _x4 = _y0 = _y1 = _y2 = _y3 = _y4 = double.nan;
    _point = 0;
  }

  @override
  void lineEnd() {
    switch (_point) {
      case 1:
        _context
          ..moveTo(_x2, _y2)
          ..closePath();
      case 2:
        _context
          ..moveTo((_x2 + 2 * _x3) / 3, (_y2 + 2 * _y3) / 3)
          ..lineTo((_x3 + 2 * _x2) / 3, (_y3 + 2 * _y2) / 3)
          ..closePath();
      case 3:
        point(_x2, _y2);
        point(_x3, _y3);
        point(_x4, _y4);
    }
  }

  @override
  void point(double x, double y) {
    switch (_point) {
      case 0:
        _point = 1;
        _x2 = x;
        _y2 = y;
      case 1:
        _point = 2;
        _x3 = x;
        _y3 = y;
      case 2:
        _point = 3;
        _x4 = x;
        _y4 = y;
        _context.moveTo((_x0 + 4 * _x1 + x) / 6, (_y0 + 4 * _y1 + y) / 6);
      default:
        basisPoint(_context, _x0, _y0, _x1, _y1, x, y);
    }
    _x0 = _x1;
    _x1 = x;
    _y0 = _y1;
    _y1 = y;
  }
}

/// `curve/basisClosed.js:50` default export: produces a closed cubic basis
/// spline.
Curve curveBasisClosed(CanvasPath context) => BasisClosedCurve(context);
