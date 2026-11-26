// Ported from d3-shape v3.2.0 src/curve/linearClosed.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/curve/linearClosed.js` of d3-shape 3.2.0: [LinearClosedCurve]
/// and [curveLinearClosed].
library;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/curve.dart';

/// `curve/linearClosed.js:3` `LinearClosed`: closed piecewise linear curve.
class LinearClosedCurve(final CanvasPath _context) implements Curve {
  /// Creates a closed linear curve writing into [_context].
  this;

  int _point = 0;

  @override
  void areaStart() {}

  @override
  void areaEnd() {}

  @override
  void lineStart() {
    _point = 0;
  }

  @override
  void lineEnd() {
    if (_point != 0) _context.closePath();
  }

  @override
  void point(double x, double y) {
    if (_point != 0) {
      _context.lineTo(x, y);
    } else {
      _point = 1;
      _context.moveTo(x, y);
    }
  }
}

/// `curve/linearClosed.js:23` default export: produces a closed polyline.
Curve curveLinearClosed(CanvasPath context) => LinearClosedCurve(context);
