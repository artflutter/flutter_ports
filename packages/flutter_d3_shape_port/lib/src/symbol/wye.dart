// Ported from d3-shape v3.2.0 src/symbol/wye.js (ISC, Mike Bostock).

/// Port of `src/symbol/wye.js` of d3-shape 3.2.0.
library;

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/symbol_type.dart';

const double _c = -0.5;
final double _s = math.sqrt(3) / 2;
final double _k = 1 / math.sqrt(12);
final double _a = (_k / 2 + 1) * 3;

/// `symbol/wye.js`: filled Y-shaped wye symbol type.
final class const SymbolWye() implements SymbolType {
  /// Creates the wye symbol type.
  this;

  @override
  void draw(CanvasPath context, double size) {
    final r = math.sqrt(size / _a);
    final x0 = r / 2;
    final y0 = r * _k;
    final x1 = x0;
    final y1 = r * _k + r;
    final x2 = -x1;
    final y2 = y1;
    context
      ..moveTo(x0, y0)
      ..lineTo(x1, y1)
      ..lineTo(x2, y2)
      ..lineTo(_c * x0 - _s * y0, _s * x0 + _c * y0)
      ..lineTo(_c * x1 - _s * y1, _s * x1 + _c * y1)
      ..lineTo(_c * x2 - _s * y2, _s * x2 + _c * y2)
      ..lineTo(_c * x0 + _s * y0, _c * y0 - _s * x0)
      ..lineTo(_c * x1 + _s * y1, _c * y1 - _s * x1)
      ..lineTo(_c * x2 + _s * y2, _c * y2 - _s * x2)
      ..closePath();
  }
}

/// `symbol/wye.js` default export: filled wye symbol.
const SymbolType symbolWye = SymbolWye();
