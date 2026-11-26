// Ported from d3-shape v3.2.0 src/symbol/star.js (ISC, Mike Bostock).

/// Port of `src/symbol/star.js` of d3-shape 3.2.0.
library;

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/math.dart';
import 'package:flutter_d3_shape_port/src/symbol_type.dart';

const double _ka = 0.89081309152928522810;
final double _kr = math.sin(shapePi / 10) / math.sin(7 * shapePi / 10);
final double _kx = math.sin(shapeTau / 10) * _kr;
final double _ky = -math.cos(shapeTau / 10) * _kr;

// Precomputed cos/sin of 2π*i/5 for i = 1..4 (eliminates 8 trig calls/star).
// DIVERGES(d3-shape): adapt-shape-fast-forms, precomputed pentagram trig.
final double _c1 = math.cos(shapeTau / 5);
final double _s1 = math.sin(shapeTau / 5);
final double _c2 = math.cos(shapeTau * 2 / 5);
final double _s2 = math.sin(shapeTau * 2 / 5);
final double _c3 = math.cos(shapeTau * 3 / 5);
final double _s3 = math.sin(shapeTau * 3 / 5);
final double _c4 = math.cos(shapeTau * 4 / 5);
final double _s4 = math.sin(shapeTau * 4 / 5);

/// `symbol/star.js`: filled five-pointed star symbol type.
final class const SymbolStar() implements SymbolType {
  /// Creates the star symbol type.
  this;

  @override
  void draw(CanvasPath context, double size) {
    final r = math.sqrt(size * _ka);
    final x = _kx * r;
    final y = _ky * r;
    context
      ..moveTo(0, -r)
      ..lineTo(x, y)
      ..lineTo(_s1 * r, -_c1 * r)
      ..lineTo(_c1 * x - _s1 * y, _s1 * x + _c1 * y)
      ..lineTo(_s2 * r, -_c2 * r)
      ..lineTo(_c2 * x - _s2 * y, _s2 * x + _c2 * y)
      ..lineTo(_s3 * r, -_c3 * r)
      ..lineTo(_c3 * x - _s3 * y, _s3 * x + _c3 * y)
      ..lineTo(_s4 * r, -_c4 * r)
      ..lineTo(_c4 * x - _s4 * y, _s4 * x + _c4 * y)
      ..closePath();
  }
}

/// `symbol/star.js` default export: filled star symbol.
const SymbolType symbolStar = SymbolStar();
