// Ported from d3-shape v3.2.0 src/curve/step.js (ISC, Mike Bostock).

/// Port of `src/curve/step.js` of d3-shape 3.2.0: [StepCurve], [curveStep],
/// [curveStepBefore], and [curveStepAfter].
library;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/curve.dart';

/// `curve/step.js:1` `Step`: piecewise constant (step) curve.
class StepCurve(final CanvasPath _context, double t) implements Curve {
  /// Creates a step curve writing into [_context] with step transition [t].
  this;

  double _t = t;
  int _line = -1;
  int _point = 0;
  double _x = double.nan;
  double _y = double.nan;

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
    _x = _y = double.nan;
    _point = 0;
  }

  @override
  void lineEnd() {
    if (0 < _t && _t < 1 && _point == 2) _context.lineTo(_x, _y);
    if (_line == 1 || (_line != 0 && _point == 1)) _context.closePath();
    if (_line >= 0) {
      _t = 1 - _t;
      _line = 1 - _line;
    }
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
        if (_t <= 0) {
          _context
            ..lineTo(_x, y)
            ..lineTo(x, y);
        } else {
          final x1 = _x * (1 - _t) + x * _t;
          _context
            ..lineTo(x1, _y)
            ..lineTo(x1, y);
        }
      default:
        if (_t <= 0) {
          _context
            ..lineTo(_x, y)
            ..lineTo(x, y);
        } else {
          final x1 = _x * (1 - _t) + x * _t;
          _context
            ..lineTo(x1, _y)
            ..lineTo(x1, y);
        }
    }
    _x = x;
    _y = y;
  }
}

/// `curve/step.js:43` default export: step function alternating at the midpoint.
Curve curveStep(CanvasPath context) => StepCurve(context, 0.5);

/// `curve/step.js:47` `stepBefore`: step function changing y before x.
Curve curveStepBefore(CanvasPath context) => StepCurve(context, 0);

/// `curve/step.js:51` `stepAfter`: step function changing y after x.
Curve curveStepAfter(CanvasPath context) => StepCurve(context, 1);
