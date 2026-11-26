// Ported from d3-shape v3.2.0 src/symbol/circle.js (ISC, Mike Bostock).

/// Port of `src/symbol/circle.js` of d3-shape 3.2.0.
library;

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/math.dart';
import 'package:flutter_d3_shape_port/src/symbol_type.dart';

/// `symbol/circle.js`: circle symbol type.
final class const SymbolCircle() implements SymbolType {
  /// Creates the circle symbol type.
  this;

  @override
  void draw(CanvasPath context, double size) {
    final r = math.sqrt(size / shapePi);
    context
      ..moveTo(r, 0)
      ..arc(0, 0, r, 0, shapeTau);
  }
}

/// `symbol/circle.js` default export: circle symbol.
const SymbolType symbolCircle = SymbolCircle();
