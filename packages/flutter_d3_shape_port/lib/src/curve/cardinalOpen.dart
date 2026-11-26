// Ported from d3-shape v3.2.0 src/curve/cardinalOpen.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/curve/cardinalOpen.js` of d3-shape 3.2.0:
/// [CardinalOpenCurve], [CurveCardinalOpenFactory], and [curveCardinalOpen].
library;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/curve.dart';
import 'package:flutter_d3_shape_port/src/curve/cardinal.dart';

/// `curve/cardinalOpen.js:3` `CardinalOpen`: open cubic cardinal spline curve.
class CardinalOpenCurve(final CanvasPath _context, double tension)
    implements Curve {
  /// Creates an open cardinal spline curve writing into [_context] with
  /// [tension].
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
        if (_line == 1) {
          _context.lineTo(_x2, _y2);
        } else {
          _context.moveTo(_x2, _y2);
        }
      case 3:
        _point = 4;
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

/// `curve/cardinalOpen.js:38` callable open cardinal curve factory with
/// configurable [tension].
// DIVERGES(d3-shape): adapt-shape-typed-api, const callable factory class.
final class const CurveCardinalOpenFactory._(final double _tension) {
  /// Creates an open cardinal curve factory with [_tension].
  this;

  /// Creates a [Curve] for [context].
  Curve call(CanvasPath context) => CardinalOpenCurve(context, _tension);

  /// Returns an open cardinal curve factory with the specified [tension].
  CurveCardinalOpenFactory tension(double tension) =>
      CurveCardinalOpenFactory._(tension);
}

/// `curve/cardinalOpen.js:38` default export: open cubic cardinal spline with
/// default `tension = 0`.
const CurveCardinalOpenFactory curveCardinalOpen = CurveCardinalOpenFactory._(
  0,
);
