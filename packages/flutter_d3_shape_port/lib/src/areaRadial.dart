// Ported from d3-shape v3.2.0 src/areaRadial.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/areaRadial.js` of d3-shape 3.2.0: [AreaRadial] and
/// [areaRadial].
library;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/area.dart';
import 'package:flutter_d3_shape_port/src/curve.dart';
import 'package:flutter_d3_shape_port/src/curve/linear.dart';
import 'package:flutter_d3_shape_port/src/curve/radial.dart';
import 'package:flutter_d3_shape_port/src/line.dart';
import 'package:flutter_d3_shape_port/src/lineRadial.dart';

/// `areaRadial.js:5` `areaRadial`: radial area generator mapping polar
/// `(angle, radius)` coordinates to Cartesian `(x, y)`.
// DIVERGES(d3-shape): adapt-shape-typed-api, typed generic AreaRadial class.
final class AreaRadial<T>() {
  /// Creates a default radial area generator.
  this;

  final Area<T> _area = Area<T>()..curve = curveRadialLinear.call;
  CurveFactory _innerCurve = curveLinear;

  /// Generates the radial area for [data].
  String? call(Iterable<T> data) => _area(data);

  /// Current `startAngle` accessor.
  PointAccessor<T> get angle => _area.x;

  /// Sets `startAngle` to [fn] and clears `endAngle` to `null`.
  set angle(PointAccessor<T> fn) => _area.x = fn;

  /// Sets a constant `startAngle` and clears `endAngle`.
  void angleConst(double value) => _area.xConst(value);

  /// Current `startAngle` accessor.
  PointAccessor<T> get startAngle => _area.x0;

  /// Sets `startAngle`.
  set startAngle(PointAccessor<T> fn) => _area.x0 = fn;

  /// Sets a constant `startAngle`.
  void startAngleConst(double value) => _area.x0Const(value);

  /// Current `endAngle` accessor (`null` reuses `startAngle`).
  PointAccessor<T>? get endAngle => _area.x1;

  /// Sets `endAngle`.
  set endAngle(PointAccessor<T>? fn) => _area.x1 = fn;

  /// Sets a constant `endAngle`.
  void endAngleConst(double value) => _area.x1Const(value);

  /// Current `innerRadius` accessor.
  PointAccessor<T> get radius => _area.y;

  /// Sets `innerRadius` to [fn] and clears `outerRadius` to `null`.
  set radius(PointAccessor<T> fn) => _area.y = fn;

  /// Sets a constant `innerRadius` and clears `outerRadius`.
  void radiusConst(double value) => _area.yConst(value);

  /// Current `innerRadius` accessor.
  PointAccessor<T> get innerRadius => _area.y0;

  /// Sets `innerRadius`.
  set innerRadius(PointAccessor<T> fn) => _area.y0 = fn;

  /// Sets a constant `innerRadius`.
  void innerRadiusConst(double value) => _area.y0Const(value);

  /// Current `outerRadius` accessor (`null` reuses `innerRadius`).
  PointAccessor<T>? get outerRadius => _area.y1;

  /// Sets `outerRadius`.
  set outerRadius(PointAccessor<T>? fn) => _area.y1 = fn;

  /// Sets a constant `outerRadius`.
  void outerRadiusConst(double value) => _area.y1Const(value);

  /// Returns a [LineRadial] derived from `startAngle` and `innerRadius`.
  LineRadial<T> lineStartAngle() =>
      LineRadial<T>.fromLine(_area.lineX0(), _innerCurve);

  /// Returns a [LineRadial] derived from `endAngle` and `innerRadius`.
  LineRadial<T> lineEndAngle() =>
      LineRadial<T>.fromLine(_area.lineX1(), _innerCurve);

  /// Returns a [LineRadial] derived from `startAngle` and `innerRadius`.
  LineRadial<T> lineInnerRadius() =>
      LineRadial<T>.fromLine(_area.lineY0(), _innerCurve);

  /// Returns a [LineRadial] derived from `startAngle` and `outerRadius`.
  LineRadial<T> lineOuterRadius() =>
      LineRadial<T>.fromLine(_area.lineY1(), _innerCurve);

  /// Current defined predicate accessor.
  DefinedAccessor<T> get defined => _area.defined;

  /// Sets the defined predicate accessor.
  set defined(DefinedAccessor<T> fn) => _area.defined = fn;

  /// Sets a constant defined boolean.
  void definedConst(bool value) => _area.definedConst(value);

  /// Current unwrapped Cartesian curve factory (defaults to [curveLinear]).
  CurveFactory get curve => _innerCurve;

  /// Sets the Cartesian curve factory (wrapped internally with [curveRadial]).
  set curve(CurveFactory value) {
    _innerCurve = value;
    _area.curve = curveRadial(value).call;
  }

  /// Current rendering [CanvasPath] context.
  CanvasPath? get context => _area.context;

  /// Sets the rendering [CanvasPath] context.
  set context(CanvasPath? value) => _area.context = value;

  /// Maximum fractional digits for SVG path strings (`3` by default).
  int? get digits => _area.digits;

  /// Sets the maximum fractional digits for SVG path strings.
  set digits(int? value) => _area.digits = value;
}

/// `areaRadial.js:5` default export: creates a new [AreaRadial] generator.
AreaRadial<T> areaRadial<T>() => AreaRadial<T>();

/// `index.js:5` `radialArea`: deprecated alias for [areaRadial].
@Deprecated('Use areaRadial.')
AreaRadial<T> radialArea<T>() => areaRadial<T>();
