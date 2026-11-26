// Ported from d3-shape v3.2.0 src/curve/linear.js (ISC, Mike Bostock).

/// Port of `src/curve/linear.js` of d3-shape 3.2.0: [LinearCurve] and
/// [curveLinear].
library;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/curve.dart';

/// `curve/linear.js:1` `Linear`: piecewise linear curve.
class LinearCurve(final CanvasPath _context) implements Curve {
  /// Creates a linear curve writing into [_context].
  this;

  int _line = -1;
  int _point = 0;

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
        _context.lineTo(x, y);
      default:
        _context.lineTo(x, y);
    }
  }
}

/// `curve/linear.js:29` default export: produces a polyline through the
/// specified points.
Curve curveLinear(CanvasPath context) => LinearCurve(context);
