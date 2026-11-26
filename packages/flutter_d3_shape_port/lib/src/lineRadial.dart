// Ported from d3-shape v3.2.0 src/lineRadial.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/lineRadial.js` of d3-shape 3.2.0: [LineRadial] and
/// [lineRadial].
library;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/curve.dart';
import 'package:flutter_d3_shape_port/src/curve/linear.dart';
import 'package:flutter_d3_shape_port/src/curve/radial.dart';
import 'package:flutter_d3_shape_port/src/line.dart';

/// `lineRadial.js:4` `lineRadial`: radial line generator mapping polar
/// `(angle, radius)` coordinates to Cartesian `(x, y)`.
// DIVERGES(d3-shape): adapt-shape-typed-api, typed generic LineRadial class.
final class LineRadial<T>._(final Line<T> _line, CurveFactory innerCurve) {
  /// Creates a radial line wrapping an existing [_line] and [innerCurve].
  this;

  /// Creates a default radial line generator.
  factory() =>
      LineRadial<T>._(Line<T>()..curve = curveRadialLinear.call, curveLinear);

  /// Wraps a derived [Line] whose curve is already radial.
  factory fromLine(Line<T> line, CurveFactory innerCurve) =>
      LineRadial<T>._(line, innerCurve);

  CurveFactory _innerCurve = innerCurve;

  /// Generates the radial line for [data].
  String? call(Iterable<T> data) => _line(data);

  /// Current angle accessor (radians, 0 at 12 o'clock).
  PointAccessor<T> get angle => _line.x;

  /// Sets the angle accessor.
  set angle(PointAccessor<T> fn) => _line.x = fn;

  /// Sets a constant angle.
  void angleConst(double value) => _line.xConst(value);

  /// Current radius accessor.
  PointAccessor<T> get radius => _line.y;

  /// Sets the radius accessor.
  set radius(PointAccessor<T> fn) => _line.y = fn;

  /// Sets a constant radius.
  void radiusConst(double value) => _line.yConst(value);

  /// Current defined predicate accessor.
  DefinedAccessor<T> get defined => _line.defined;

  /// Sets the defined predicate accessor.
  set defined(DefinedAccessor<T> fn) => _line.defined = fn;

  /// Sets a constant defined boolean.
  void definedConst(bool value) => _line.definedConst(value);

  /// Current unwrapped Cartesian curve factory (defaults to [curveLinear]).
  CurveFactory get curve => _innerCurve;

  /// Sets the Cartesian curve factory (wrapped internally with [curveRadial]).
  set curve(CurveFactory value) {
    _innerCurve = value;
    _line.curve = curveRadial(value).call;
  }

  /// Current rendering [CanvasPath] context.
  CanvasPath? get context => _line.context;

  /// Sets the rendering [CanvasPath] context.
  set context(CanvasPath? value) => _line.context = value;

  /// Maximum fractional digits for SVG path strings (`3` by default).
  int? get digits => _line.digits;

  /// Sets the maximum fractional digits for SVG path strings.
  set digits(int? value) => _line.digits = value;
}

/// `lineRadial.js:17` default export: creates a new [LineRadial] generator.
LineRadial<T> lineRadial<T>() => LineRadial<T>();

/// `index.js:6` `radialLine`: deprecated alias for [lineRadial].
@Deprecated('Use lineRadial.')
LineRadial<T> radialLine<T>() => lineRadial<T>();
