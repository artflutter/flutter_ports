// Ported from d3-shape v3.2.0 src/curve/natural.js (ISC, Mike Bostock).

/// Port of `src/curve/natural.js` of d3-shape 3.2.0: [NaturalCurve] and
/// [curveNatural].
library;

import 'dart:typed_data';

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/curve.dart';

/// `curve/natural.js:1` `Natural`: natural cubic spline with second derivative
/// equal to zero at the endpoints.
// DIVERGES(d3-shape): adapt-shape-fast-forms, unboxed Float64List point buffers
// and fused X/Y tridiagonal solve sharing the diagonal vector b.
class NaturalCurve(final CanvasPath _context) implements Curve {
  /// Creates a natural cubic spline writing into [_context].
  this;

  int _line = -1;
  Float64List _x = Float64List(32);
  Float64List _y = Float64List(32);
  int _len = 0;

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
    _len = 0;
  }

  @override
  void lineEnd() {
    final x = _x;
    final y = _y;
    final n = _len;

    if (n != 0) {
      if (_line == 1) {
        _context.lineTo(x[0], y[0]);
      } else {
        _context.moveTo(x[0], y[0]);
      }
      if (n == 2) {
        _context.lineTo(x[1], y[1]);
      } else if (n > 2) {
        _emitControlPoints(_context, x, y, n);
      }
    }

    if (_line == 1 || (_line != 0 && n == 1)) _context.closePath();
    if (_line >= 0) _line = 1 - _line;
    _len = 0;
  }

  @override
  void point(double x, double y) {
    final i = _len;
    if (i == _x.length) {
      final cap = i << 1;
      final nx = Float64List(cap)..setRange(0, i, _x);
      final ny = Float64List(cap)..setRange(0, i, _y);
      _x = nx;
      _y = ny;
    }
    _x[i] = x;
    _y[i] = y;
    _len = i + 1;
  }
}

// See https://www.particleincell.com/2012/bezier-splines/ for derivation.
// Solves X and Y simultaneously sharing the tridiagonal diagonal `b`.
void _emitControlPoints(
  CanvasPath context,
  Float64List x,
  Float64List y,
  int count,
) {
  final n = count - 1;
  final b = Float64List(n);
  final rx = Float64List(n);
  final ry = Float64List(n);

  b[0] = 2;
  rx[0] = x[0] + 2 * x[1];
  ry[0] = y[0] + 2 * y[1];

  final last = n - 1;
  for (var i = 1; i < last; ++i) {
    final m = 1.0 / b[i - 1];
    b[i] = 4.0 - m;
    rx[i] = 4 * x[i] + 2 * x[i + 1] - m * rx[i - 1];
    ry[i] = 4 * y[i] + 2 * y[i + 1] - m * ry[i - 1];
  }
  final mLast = 2.0 / b[last - 1];
  b[last] = 7.0 - mLast;
  rx[last] = 8 * x[last] + x[n] - mLast * rx[last - 1];
  ry[last] = 8 * y[last] + y[n] - mLast * ry[last - 1];

  // Back-substitution in-place into rx/ry (now holding first control points a).
  rx[last] = rx[last] / b[last];
  ry[last] = ry[last] / b[last];
  for (var i = n - 2; i >= 0; --i) {
    final bi = b[i];
    rx[i] = (rx[i] - rx[i + 1]) / bi;
    ry[i] = (ry[i] - ry[i + 1]) / bi;
  }

  // Emit segments directly without allocating separate second control arrays.
  for (var i0 = 0; i0 < last; ++i0) {
    final i1 = i0 + 1;
    final x1 = x[i1];
    final y1 = y[i1];
    context.bezierCurveTo(
      rx[i0],
      ry[i0],
      2 * x1 - rx[i1],
      2 * y1 - ry[i1],
      x1,
      y1,
    );
  }
  final xn = x[n];
  final yn = y[n];
  context.bezierCurveTo(
    rx[last],
    ry[last],
    (xn + rx[last]) / 2,
    (yn + ry[last]) / 2,
    xn,
    yn,
  );
}

/// `curve/natural.js:63` default export: produces a natural cubic spline.
Curve curveNatural(CanvasPath context) => NaturalCurve(context);
