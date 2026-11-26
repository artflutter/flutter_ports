// Ported from d3-shape v3.2.0 src/curve/radial.js (ISC, Mike Bostock).

/// Port of `src/curve/radial.js` of d3-shape 3.2.0: [RadialCurve],
/// [CurveRadialFactory], [curveRadial], and [curveRadialLinear].
library;

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/curve.dart';
import 'package:flutter_d3_shape_port/src/curve/linear.dart';

/// `curve/radial.js:5` `Radial`: wraps a Cartesian [Curve], projecting polar
/// `(angle, radius)` points into `(r * sin(a), r * -cos(a))`.
class RadialCurve(final Curve _curve) implements Curve {
  /// Creates a radial curve wrapping [_curve].
  this;

  @override
  void areaStart() => _curve.areaStart();

  @override
  void areaEnd() => _curve.areaEnd();

  @override
  void lineStart() => _curve.lineStart();

  @override
  void lineEnd() => _curve.lineEnd();

  @override
  void point(double a, double r) =>
      _curve.point(r * math.sin(a), r * -math.cos(a));
}

/// `curve/radial.js:27` callable radial curve factory preserving [innerCurve].
// DIVERGES(d3-shape): adapt-shape-typed-api, callable factory class.
final class const CurveRadialFactory(
  /// The wrapped Cartesian curve factory.
  final CurveFactory innerCurve,
) {
  /// Creates a radial curve factory wrapping [innerCurve].
  this;

  /// Creates a [RadialCurve] writing into [context].
  Curve call(CanvasPath context) => RadialCurve(innerCurve(context));
}

/// `curve/radial.js:27` default export: wraps [curve] in polar coordinates.
CurveRadialFactory curveRadial(CurveFactory curve) => CurveRadialFactory(curve);

/// `curve/radial.js:3` `curveRadialLinear`: radial wrapper around
/// [curveLinear].
const CurveRadialFactory curveRadialLinear = CurveRadialFactory(curveLinear);
