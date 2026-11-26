// Ported from d3-shape v3.2.0 src/symbol/triangle.js (ISC, Mike Bostock).

/// Port of `src/symbol/triangle.js` of d3-shape 3.2.0.
library;

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/symbol_type.dart';

final double _sqrt3 = math.sqrt(3);

/// `symbol/triangle.js`: filled upward-pointing triangle symbol type.
final class const SymbolTriangle() implements SymbolType {
  /// Creates the triangle symbol type.
  this;

  @override
  void draw(CanvasPath context, double size) {
    final y = -math.sqrt(size / (_sqrt3 * 3));
    context
      ..moveTo(0, y * 2)
      ..lineTo(-_sqrt3 * y, -y)
      ..lineTo(_sqrt3 * y, -y)
      ..closePath();
  }
}

/// `symbol/triangle.js` default export: filled triangle symbol.
const SymbolType symbolTriangle = SymbolTriangle();
