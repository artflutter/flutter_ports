// Ported from d3-shape v3.2.0 src/curve/basisOpen.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/curve/basisOpen.js` of d3-shape 3.2.0: [BasisOpenCurve] and
/// [curveBasisOpen].
library;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/curve.dart';
import 'package:flutter_d3_shape_port/src/curve/basis.dart';

/// `curve/basisOpen.js:3` `BasisOpen`: open cubic basis spline curve.
class BasisOpenCurve(final CanvasPath _context) implements Curve {
  /// Creates an open basis spline curve writing into [_context].
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
    if (_line == 1 || (_line != 0 && _point == 3)) _context.closePath();
    if (_line >= 0) _line = 1 - _line;
  }

  @override
  void point(double x, double y) {
    switch (_point) {
      case 0:
        _point = 1;
      case 1:
        _point = 2;
      case 2:
        _point = 3;
        final x0 = (_x0 + 4 * _x1 + x) / 6;
        final y0 = (_y0 + 4 * _y1 + y) / 6;
        if (_line == 1) {
          _context.lineTo(x0, y0);
        } else {
          _context.moveTo(x0, y0);
        }
      case 3:
        _point = 4;
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

/// `curve/basisOpen.js:37` default export: produces an open cubic basis spline.
Curve curveBasisOpen(CanvasPath context) => BasisOpenCurve(context);
