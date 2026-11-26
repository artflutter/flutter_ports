// Ported from d3-shape v3.2.0 src/symbol/square.js (ISC, Mike Bostock).

/// Port of `src/symbol/square.js` of d3-shape 3.2.0.
library;

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/symbol_type.dart';

/// `symbol/square.js`: filled square symbol type.
final class const SymbolSquare() implements SymbolType {
  /// Creates the square symbol type.
  this;

  @override
  void draw(CanvasPath context, double size) {
    final w = math.sqrt(size);
    final x = -w / 2;
    context.rect(x, x, w, w);
  }
}

/// `symbol/square.js` default export: filled square symbol.
const SymbolType symbolSquare = SymbolSquare();
