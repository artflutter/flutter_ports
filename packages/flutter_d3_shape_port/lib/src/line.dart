// Ported from d3-shape v3.2.0 src/line.js (ISC, Mike Bostock).

/// Port of `src/line.js` of d3-shape 3.2.0: [Line] and [line].
library;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/array.dart';
import 'package:flutter_d3_shape_port/src/curve.dart';
import 'package:flutter_d3_shape_port/src/curve/linear.dart';
import 'package:flutter_d3_shape_port/src/path.dart';
import 'package:flutter_d3_shape_port/src/point.dart';

/// Coordinate accessor for series generators ([Line], `LineRadial`, `Area`,
/// `AreaRadial`).
typedef PointAccessor<T> = double Function(T d, int i, List<T> data);

/// Defined predicate accessor for series generators.
typedef DefinedAccessor<T> = bool Function(T d, int i, List<T> data);

double _defaultX<T>(T d, int i, List<T> data) => pointX(d);
double _defaultY<T>(T d, int i, List<T> data) => pointY(d);
bool _defaultDefined<T>(T d, int i, List<T> data) => true;

/// `line.js:7` `line`: polyline/spline generator for a sequence of data points.
// DIVERGES(d3-shape): adapt-shape-typed-api, typed generic Line class.
// DIVERGES(d3-shape): adapt-shape-fast-forms, tight loop when all points are
// defined (default) skips per-point defined closure calls.
final class Line<T>([PointAccessor<T>? x, PointAccessor<T>? y])
    with ShapePathMixin {
  /// Creates a line generator with optional [x] and [y] accessors.
  this;

  /// X-coordinate accessor.
  PointAccessor<T> x = x ?? _defaultX;

  /// Y-coordinate accessor.
  PointAccessor<T> y = y ?? _defaultY;

  DefinedAccessor<T> _defined = _defaultDefined;
  bool _alwaysDefined = true;

  CanvasPath? _context;
  CurveFactory _curve = curveLinear;
  Curve? _output;

  /// Generates the line for [data]. Returns an SVG path string when [context]
  /// is `null`, or writes directly into [context] and returns `null`.
  String? call(Iterable<T> data) {
    final list = shapeArray(data);
    final n = list.length;
    Path? buffer;
    late final Curve output;

    if (_context == null) {
      buffer = createShapePath();
      output = _curve(buffer);
    } else {
      output = _output!;
    }

    final xFn = x;
    final yFn = y;
    if (_alwaysDefined) {
      if (n > 0) {
        output.lineStart();
        for (var i = 0; i < n; ++i) {
          final datum = list[i];
          output.point(xFn(datum, i, list), yFn(datum, i, list));
        }
        output.lineEnd();
      }
    } else {
      final defFn = _defined;
      var defined0 = false;
      T? d;
      for (var i = 0; i <= n; ++i) {
        final isDefined = i < n && defFn(d = list[i], i, list);
        if (!isDefined == defined0) {
          defined0 = !defined0;
          if (defined0) {
            output.lineStart();
          } else {
            output.lineEnd();
          }
        }
        if (defined0) {
          final datum = d as T;
          output.point(xFn(datum, i, list), yFn(datum, i, list));
        }
      }
    }

    if (buffer != null) {
      final result = buffer.toString();
      return result.isEmpty ? null : result;
    }
    return null;
  }

  /// Sets a constant x-coordinate.
  void xConst(double value) {
    x = (_, _, _) => value;
  }

  /// Sets a constant y-coordinate.
  void yConst(double value) {
    y = (_, _, _) => value;
  }

  /// Current defined predicate accessor.
  DefinedAccessor<T> get defined => _defined;

  /// Sets the defined predicate accessor.
  set defined(DefinedAccessor<T> fn) {
    _defined = fn;
    _alwaysDefined = identical(fn, _defaultDefined);
  }

  /// Sets a constant defined boolean.
  void definedConst(bool value) {
    _defined = (_, _, _) => value;
    _alwaysDefined = value;
  }

  /// Current curve factory (defaults to [curveLinear]).
  CurveFactory get curve => _curve;

  /// Sets the curve factory.
  set curve(CurveFactory value) {
    _curve = value;
    final ctx = _context;
    if (ctx != null) _output = value(ctx);
  }

  /// Current rendering [CanvasPath] context (`null` emits an SVG string).
  CanvasPath? get context => _context;

  /// Sets the rendering [CanvasPath] context.
  set context(CanvasPath? value) {
    if (value == null) {
      _context = null;
      _output = null;
    } else {
      _context = value;
      _output = _curve(value);
    }
  }
}

/// `line.js:7` default export: creates a new [Line] generator.
Line<T> line<T>([PointAccessor<T>? x, PointAccessor<T>? y]) => Line<T>(x, y);
