// Ported from d3-shape v3.2.0 src/symbol/triangle2.js (ISC, Mike Bostock).

/// Port of `src/symbol/triangle2.js` of d3-shape 3.2.0.
library;

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/symbol_type.dart';

final double _sqrt3 = math.sqrt(3);

/// `symbol/triangle2.js`: stroked upward-pointing triangle symbol type.
final class const SymbolTriangle2() implements SymbolType {
  /// Creates the stroked triangle symbol type.
  this;

  @override
  void draw(CanvasPath context, double size) {
    final s = math.sqrt(size) * 0.6824;
    final t = s / 2;
    final u = (s * _sqrt3) / 2; // cos(Math.PI / 6)
    context
      ..moveTo(0, -s)
      ..lineTo(u, t)
      ..lineTo(-u, t)
      ..closePath();
  }
}

/// `symbol/triangle2.js` default export: stroked triangle symbol.
const SymbolType symbolTriangle2 = SymbolTriangle2();
