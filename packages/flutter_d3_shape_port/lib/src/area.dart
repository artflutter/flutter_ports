// Ported from d3-shape v3.2.0 src/area.js (ISC, Mike Bostock).

/// Port of `src/area.js` of d3-shape 3.2.0: [Area] and [area].
library;

import 'dart:typed_data';

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/array.dart';
import 'package:flutter_d3_shape_port/src/curve.dart';
import 'package:flutter_d3_shape_port/src/curve/linear.dart';
import 'package:flutter_d3_shape_port/src/line.dart';
import 'package:flutter_d3_shape_port/src/path.dart';
import 'package:flutter_d3_shape_port/src/point.dart';

double _defaultAreaX0<T>(T d, int i, List<T> data) => pointX(d);
double _defaultAreaY0<T>(T d, int i, List<T> data) => 0;
double _defaultAreaY1<T>(T d, int i, List<T> data) => pointY(d);
bool _defaultAreaDefined<T>(T d, int i, List<T> data) => true;

/// `area.js:8` `area`: area generator bounded by a topline `(x1, y1)` and
/// baseline `(x0, y0)`.
// DIVERGES(d3-shape): adapt-shape-typed-api, typed generic Area class.
// DIVERGES(d3-shape): adapt-shape-fast-forms, unboxed Float64List baseline
// buffers and tight loop when all points are defined (default).
final class Area<T>([
  PointAccessor<T>? x0,
  PointAccessor<T>? y0,
  PointAccessor<T>? y1,
]) with ShapePathMixin {
  /// Creates an area generator with optional [x0], [y0], and [y1] accessors.
  this;

  /// `x0` accessor.
  PointAccessor<T> x0 = x0 ?? _defaultAreaX0;

  /// `x1` accessor (`null` reuses [x0]).
  PointAccessor<T>? x1;

  /// `y0` accessor.
  PointAccessor<T> y0 = y0 ?? _defaultAreaY0;

  /// `y1` accessor (`null` reuses [y0]).
  PointAccessor<T>? y1 = y1 ?? _defaultAreaY1;

  DefinedAccessor<T> _defined = _defaultAreaDefined;
  bool _alwaysDefined = true;

  CanvasPath? _context;
  CurveFactory _curve = curveLinear;
  Curve? _output;

  /// Generates the area for [data]. Returns an SVG path string when [context]
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

    final x0Fn = x0;
    final y0Fn = y0;
    final x1Fn = x1;
    final y1Fn = y1;

    if (_alwaysDefined) {
      if (n > 0) {
        final x0z = Float64List(n);
        final y0z = Float64List(n);
        output
          ..areaStart()
          ..lineStart();
        if (x1Fn == null && y1Fn != null) {
          for (var i = 0; i < n; ++i) {
            final datum = list[i];
            final xv0 = x0z[i] = x0Fn(datum, i, list);
            y0z[i] = y0Fn(datum, i, list);
            output.point(xv0, y1Fn(datum, i, list));
          }
        } else {
          for (var i = 0; i < n; ++i) {
            final datum = list[i];
            final xv0 = x0z[i] = x0Fn(datum, i, list);
            final yv0 = y0z[i] = y0Fn(datum, i, list);
            output.point(
              x1Fn != null ? x1Fn(datum, i, list) : xv0,
              y1Fn != null ? y1Fn(datum, i, list) : yv0,
            );
          }
        }
        output
          ..lineEnd()
          ..lineStart();
        for (var k = n - 1; k >= 0; --k) {
          output.point(x0z[k], y0z[k]);
        }
        output
          ..lineEnd()
          ..areaEnd();
      }
    } else {
      final defFn = _defined;
      final x0z = Float64List(n);
      final y0z = Float64List(n);
      var defined0 = false;
      var j = 0;
      T? d;
      for (var i = 0; i <= n; ++i) {
        final isDefined = i < n && defFn(d = list[i], i, list);
        if (!isDefined == defined0) {
          defined0 = !defined0;
          if (defined0) {
            j = i;
            output
              ..areaStart()
              ..lineStart();
          } else {
            output
              ..lineEnd()
              ..lineStart();
            for (var k = i - 1; k >= j; --k) {
              output.point(x0z[k], y0z[k]);
            }
            output
              ..lineEnd()
              ..areaEnd();
          }
        }
        if (defined0) {
          final datum = d as T;
          final xv0 = x0z[i] = x0Fn(datum, i, list);
          final yv0 = y0z[i] = y0Fn(datum, i, list);
          output.point(
            x1Fn != null ? x1Fn(datum, i, list) : xv0,
            y1Fn != null ? y1Fn(datum, i, list) : yv0,
          );
        }
      }
    }

    if (buffer != null) {
      final result = buffer.toString();
      return result.isEmpty ? null : result;
    }
    return null;
  }

  Line<T> _areaLine() => Line<T>()
    ..defined = _defined
    ..curve = _curve
    ..context = _context
    ..digits = digits;

  /// Current `x0` accessor.
  PointAccessor<T> get x => x0;

  /// Sets `x0` to [fn] and clears `x1` to `null`.
  set x(PointAccessor<T> fn) {
    x0 = fn;
    x1 = null;
  }

  /// Sets a constant `x0` and clears `x1`.
  void xConst(double value) {
    x0 = (_, _, _) => value;
    x1 = null;
  }

  /// Sets a constant `x0`.
  void x0Const(double value) {
    x0 = (_, _, _) => value;
  }

  /// Sets a constant `x1`.
  void x1Const(double value) {
    x1 = (_, _, _) => value;
  }

  /// Current `y0` accessor.
  PointAccessor<T> get y => y0;

  /// Sets `y0` to [fn] and clears `y1` to `null`.
  set y(PointAccessor<T> fn) {
    y0 = fn;
    y1 = null;
  }

  /// Sets a constant `y0` and clears `y1`.
  void yConst(double value) {
    y0 = (_, _, _) => value;
    y1 = null;
  }

  /// Sets a constant `y0`.
  void y0Const(double value) {
    y0 = (_, _, _) => value;
  }

  /// Sets a constant `y1`.
  void y1Const(double value) {
    y1 = (_, _, _) => value;
  }

  /// Returns a [Line] generator with this area's `defined`, `curve`, `context`,
  /// `x = x0`, and `y = y0`.
  Line<T> lineX0() => _areaLine()
    ..x = x0
    ..y = y0;

  /// Returns a [Line] generator with this area's `defined`, `curve`, `context`,
  /// `x = x0`, and `y = y0`.
  Line<T> lineY0() => lineX0();

  /// Returns a [Line] generator with this area's `defined`, `curve`, `context`,
  /// `x = x0`, and `y = y1` (or constant `0` if `y1` is `null`).
  Line<T> lineY1() {
    final l = _areaLine()..x = x0;
    final y1Fn = y1;
    if (y1Fn != null) {
      l.y = y1Fn;
    } else {
      l.yConst(0);
    }
    return l;
  }

  /// Returns a [Line] generator with this area's `defined`, `curve`, `context`,
  /// `x = x1` (or constant `0` if `x1` is `null`), and `y = y0`.
  Line<T> lineX1() {
    final l = _areaLine()..y = y0;
    final x1Fn = x1;
    if (x1Fn != null) {
      l.x = x1Fn;
    } else {
      l.xConst(0);
    }
    return l;
  }

  /// Current defined predicate accessor.
  DefinedAccessor<T> get defined => _defined;

  /// Sets the defined predicate accessor.
  set defined(DefinedAccessor<T> fn) {
    _defined = fn;
    _alwaysDefined = identical(fn, _defaultAreaDefined);
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

/// `area.js:8` default export: creates a new [Area] generator.
Area<T> area<T>([
  PointAccessor<T>? x0,
  PointAccessor<T>? y0,
  PointAccessor<T>? y1,
]) => Area<T>(x0, y0, y1);
