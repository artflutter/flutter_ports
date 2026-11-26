// Ported from d3-shape v3.2.0 src/symbol/square2.js (ISC, Mike Bostock).

/// Port of `src/symbol/square2.js` of d3-shape 3.2.0.
library;

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/symbol_type.dart';

/// `symbol/square2.js`: stroked square symbol type.
final class const SymbolSquare2() implements SymbolType {
  /// Creates the stroked square symbol type.
  this;

  @override
  void draw(CanvasPath context, double size) {
    final r = math.sqrt(size) * 0.4431;
    context
      ..moveTo(r, r)
      ..lineTo(r, -r)
      ..lineTo(-r, -r)
      ..lineTo(-r, r)
      ..closePath();
  }
}

/// `symbol/square2.js` default export: stroked square symbol.
const SymbolType symbolSquare2 = SymbolSquare2();
