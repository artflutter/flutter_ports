// Ported from d3-shape v3.2.0 src/link.js (ISC, Mike Bostock).

/// Port of `src/link.js` of d3-shape 3.2.0: [Link], [LinkRadial], [LinkDatum],
/// [LinkData], [link], [linkHorizontal], [linkVertical], and [linkRadial].
library;

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/curve.dart';
import 'package:flutter_d3_shape_port/src/curve/bump.dart';
import 'package:flutter_d3_shape_port/src/math.dart';
import 'package:flutter_d3_shape_port/src/path.dart';
import 'package:flutter_d3_shape_port/src/point.dart';

/// Interface implemented by link datum objects (such as [LinkData]).
// DIVERGES(d3-shape): adapt-shape-typed-api, typed LinkDatum interface.
abstract interface class LinkDatum<N>() {
  /// Source node.
  N get source;

  /// Target node.
  N get target;
}

/// Immutable value object implementing [LinkDatum].
// DIVERGES(d3-shape): adapt-shape-typed-api, const LinkData value class.
final class const LinkData<N>({
  @override required final N source,
  @override required final N target,
}) implements LinkDatum<N> {
  /// Creates a link connecting [source] and [target].
  this;
}

/// Endpoint node accessor for [Link] and [LinkRadial].
typedef LinkNodeAccessor<L, N> = N Function(L d);

/// Coordinate accessor for [Link] and [LinkRadial].
typedef LinkCoordinateAccessor<N> = double Function(N node);

N _defaultLinkSource<L, N>(L d) => (d as LinkDatum<N>).source;
N _defaultLinkTarget<L, N>(L d) => (d as LinkDatum<N>).target;
double _defaultLinkX<N>(N p) => pointX(p);
double _defaultLinkY<N>(N p) => pointY(p);

int _bumpKindOf(CurveFactory curve) {
  if (identical(curve, curveBumpX)) return 1;
  if (identical(curve, curveBumpY)) return 2;
  if (identical(curve, curveBumpRadial)) return 3;
  return 0;
}

/// `link.js:15` `link`: smooth curve connecting a source and target point.
// DIVERGES(d3-shape): adapt-shape-typed-api, typed generic Link class.
// DIVERGES(d3-shape): adapt-shape-fast-forms, direct bump path emission without
// allocating a per-link Curve instance for built-in horizontal/vertical/radial
// links.
final class Link<L, N>(final CurveFactory _curve) with ShapePathMixin {
  /// Creates a link generator using [_curve].
  this;

  final int _bumpKind = _bumpKindOf(_curve);

  /// Source node accessor.
  LinkNodeAccessor<L, N> source = _defaultLinkSource;

  /// Target node accessor.
  LinkNodeAccessor<L, N> target = _defaultLinkTarget;

  /// X-coordinate accessor.
  LinkCoordinateAccessor<N> x = _defaultLinkX;

  /// Y-coordinate accessor.
  LinkCoordinateAccessor<N> y = _defaultLinkY;

  CanvasPath? _context;
  Curve? _output;

  /// Generates the link path for [d]. Returns an SVG path string when
  /// [context] is `null`, or writes directly into [context] and returns `null`.
  String? call(L d) {
    final s = source(d);
    final t = target(d);
    final x0 = x(s);
    final y0 = y(s);
    final x1 = x(t);
    final y1 = y(t);

    final kind = _bumpKind;
    if (kind != 0) {
      Path? buffer;
      final ctx = _context ?? (buffer = createShapePath());
      if (kind == 1) {
        final mx = (x0 + x1) / 2;
        ctx
          ..moveTo(x0, y0)
          ..bezierCurveTo(mx, y0, mx, y1, x1, y1);
      } else if (kind == 2) {
        final my = (y0 + y1) / 2;
        ctx
          ..moveTo(x0, y0)
          ..bezierCurveTo(x0, my, x1, my, x1, y1);
      } else {
        final a0 = x0 - shapeHalfPi;
        final c0 = math.cos(a0);
        final s0 = math.sin(a0);
        final a1 = x1 - shapeHalfPi;
        final c1 = math.cos(a1);
        final s1 = math.sin(a1);
        final midY = (y0 + y1) / 2;
        ctx
          ..moveTo(y0 * c0, y0 * s0)
          ..bezierCurveTo(
            midY * c0,
            midY * s0,
            midY * c1,
            midY * s1,
            y1 * c1,
            y1 * s1,
          );
      }
      if (buffer != null) {
        final result = buffer.toString();
        return result.isEmpty ? null : result;
      }
      return null;
    }

    Path? buffer;
    late final Curve output;
    if (_context == null) {
      buffer = createShapePath();
      output = _curve(buffer);
    } else {
      output = _output!;
    }
    output
      ..lineStart()
      ..point(x0, y0)
      ..point(x1, y1)
      ..lineEnd();
    if (buffer != null) {
      final result = buffer.toString();
      return result.isEmpty ? null : result;
    }
    return null;
  }

  /// Sets a constant x-coordinate.
  void xConst(double value) {
    x = (_) => value;
  }

  /// Sets a constant y-coordinate.
  void yConst(double value) {
    y = (_) => value;
  }

  /// Current rendering [CanvasPath] context.
  CanvasPath? get context => _context;

  /// Sets the rendering [CanvasPath] context.
  set context(CanvasPath? value) {
    if (value == null) {
      _context = null;
      _output = null;
    } else {
      _context = value;
      _output = _bumpKind == 0 ? _curve(value) : null;
    }
  }
}

/// `link.js:68` `linkRadial`: radial link generator with [angle] and [radius]
/// accessors.
// DIVERGES(d3-shape): adapt-shape-typed-api, typed generic LinkRadial class.
final class LinkRadial<L, N>() {
  /// Creates a radial link generator using [curveBumpRadial].
  this;

  final Link<L, N> _link = Link<L, N>(curveBumpRadial);

  /// Generates the radial link path for [d].
  String? call(L d) => _link(d);

  /// Current source node accessor.
  LinkNodeAccessor<L, N> get source => _link.source;

  /// Sets the source node accessor.
  set source(LinkNodeAccessor<L, N> fn) => _link.source = fn;

  /// Current target node accessor.
  LinkNodeAccessor<L, N> get target => _link.target;

  /// Sets the target node accessor.
  set target(LinkNodeAccessor<L, N> fn) => _link.target = fn;

  /// Current angle accessor (radians, 0 at 12 o'clock).
  LinkCoordinateAccessor<N> get angle => _link.x;

  /// Sets the angle accessor.
  set angle(LinkCoordinateAccessor<N> fn) => _link.x = fn;

  /// Sets a constant angle.
  void angleConst(double value) => _link.xConst(value);

  /// Current radius accessor.
  LinkCoordinateAccessor<N> get radius => _link.y;

  /// Sets the radius accessor.
  set radius(LinkCoordinateAccessor<N> fn) => _link.y = fn;

  /// Sets a constant radius.
  void radiusConst(double value) => _link.yConst(value);

  /// Current rendering [CanvasPath] context.
  CanvasPath? get context => _link.context;

  /// Sets the rendering [CanvasPath] context.
  set context(CanvasPath? value) => _link.context = value;

  /// Maximum fractional digits for SVG path strings (`3` by default).
  int? get digits => _link.digits;

  /// Sets the maximum fractional digits for SVG path strings.
  set digits(int? value) => _link.digits = value;
}

/// `link.js:15` `link`: creates a new [Link] generator with [curve].
Link<L, N> link<L, N>(CurveFactory curve) => Link<L, N>(curve);

/// `link.js:60` `linkHorizontal`: shorthand for `link(curveBumpX)`.
Link<L, N> linkHorizontal<L, N>() => Link<L, N>(curveBumpX);

/// `link.js:64` `linkVertical`: shorthand for `link(curveBumpY)`.
Link<L, N> linkVertical<L, N>() => Link<L, N>(curveBumpY);

/// `link.js:68` `linkRadial`: creates a new [LinkRadial] generator.
LinkRadial<L, N> linkRadial<L, N>() => LinkRadial<L, N>();
