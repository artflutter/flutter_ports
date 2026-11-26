// Ported from d3-shape v3.2.0 src/curve/cardinal.js (ISC, Mike Bostock).

/// Port of `src/curve/cardinal.js` of d3-shape 3.2.0: [CardinalCurve],
/// [cardinalPoint], [CurveCardinalFactory], and [curveCardinal].
library;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/curve.dart';

/// `curve/cardinal.js:1` `point`: emits a cubic cardinal spline segment to
/// [context].
@pragma('vm:prefer-inline')
void cardinalPoint(
  CanvasPath context,
  double k,
  double x0,
  double y0,
  double x1,
  double y1,
  double x2,
  double y2,
  double x,
  double y,
) {
  context.bezierCurveTo(
    x1 + k * (x2 - x0),
    y1 + k * (y2 - y0),
    x2 + k * (x1 - x),
    y2 + k * (y1 - y),
    x2,
    y2,
  );
}

/// `curve/cardinal.js:12` `Cardinal`: cubic cardinal spline curve.
class CardinalCurve(final CanvasPath _context, double tension)
    implements Curve {
  /// Creates a cardinal spline curve writing into [_context] with [tension].
  this;

  final double _k = (1 - tension) / 6;
  int _line = -1;
  int _point = 0;
  double _x0 = double.nan;
  double _x1 = double.nan;
  double _x2 = double.nan;
  double _y0 = double.nan;
  double _y1 = double.nan;
  double _y2 = double.nan;

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
    _point = 0;
  }

  @override
  void lineEnd() {
    switch (_point) {
      case 2:
        _context.lineTo(_x2, _y2);
      case 3:
        cardinalPoint(_context, _k, _x0, _y0, _x1, _y1, _x2, _y2, _x1, _y1);
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
        _x1 = x;
        _y1 = y;
      case 2:
        _point = 3;
        cardinalPoint(_context, _k, _x0, _y0, _x1, _y1, _x2, _y2, x, y);
      default:
        cardinalPoint(_context, _k, _x0, _y0, _x1, _y1, _x2, _y2, x, y);
    }
    _x0 = _x1;
    _x1 = _x2;
    _x2 = x;
    _y0 = _y1;
    _y1 = _y2;
    _y2 = y;
  }
}

/// `curve/cardinal.js:50` callable cardinal curve factory with configurable
/// [tension].
// DIVERGES(d3-shape): adapt-shape-typed-api, const callable factory class.
final class const CurveCardinalFactory._(final double _tension) {
  /// Creates a cardinal curve factory with [_tension].
  this;

  /// Creates a [Curve] for [context].
  Curve call(CanvasPath context) => CardinalCurve(context, _tension);

  /// Returns a cardinal curve factory with the specified [tension] in `[0, 1]`.
  CurveCardinalFactory tension(double tension) =>
      CurveCardinalFactory._(tension);
}

/// `curve/cardinal.js:50` default export: cubic cardinal spline with default
/// `tension = 0`.
const CurveCardinalFactory curveCardinal = CurveCardinalFactory._(0);
