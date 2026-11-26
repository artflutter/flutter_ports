// Ported from d3-shape v3.2.0 src/curve/cardinalClosed.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/curve/cardinalClosed.js` of d3-shape 3.2.0:
/// [CardinalClosedCurve], [CurveCardinalClosedFactory], and
/// [curveCardinalClosed].
library;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/curve.dart';
import 'package:flutter_d3_shape_port/src/curve/cardinal.dart';

/// `curve/cardinalClosed.js:4` `CardinalClosed`: closed cubic cardinal spline
/// curve.
class CardinalClosedCurve(final CanvasPath _context, double tension)
    implements Curve {
  /// Creates a closed cardinal spline curve writing into [_context] with
  /// [tension].
  this;

  final double _k = (1 - tension) / 6;
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

  @override
  void areaStart() {}

  @override
  void areaEnd() {}

  @override
  void lineStart() {
    _x0 = _x1 = _x2 = _x3 = _x4 = _x5 = _y0 = _y1 = _y2 = _y3 = _y4 = _y5 =
        double.nan;
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

/// `curve/cardinalClosed.js:50` callable closed cardinal curve factory with
/// configurable [tension].
// DIVERGES(d3-shape): adapt-shape-typed-api, const callable factory class.
final class const CurveCardinalClosedFactory._(final double _tension) {
  /// Creates a closed cardinal curve factory with [_tension].
  this;

  /// Creates a [Curve] for [context].
  Curve call(CanvasPath context) => CardinalClosedCurve(context, _tension);

  /// Returns a closed cardinal curve factory with the specified [tension].
  CurveCardinalClosedFactory tension(double tension) =>
      CurveCardinalClosedFactory._(tension);
}

/// `curve/cardinalClosed.js:50` default export: closed cubic cardinal spline
/// with default `tension = 0`.
const CurveCardinalClosedFactory curveCardinalClosed =
    CurveCardinalClosedFactory._(0);
