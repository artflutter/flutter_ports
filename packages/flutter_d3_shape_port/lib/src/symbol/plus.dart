// Ported from d3-shape v3.2.0 src/symbol/plus.js (ISC, Mike Bostock).

/// Port of `src/symbol/plus.js` of d3-shape 3.2.0.
library;

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/symbol_type.dart';

/// `symbol/plus.js`: stroked plus symbol type.
final class const SymbolPlus() implements SymbolType {
  /// Creates the plus symbol type.
  this;

  @override
  void draw(CanvasPath context, double size) {
    final r = math.sqrt(size - math.min(size / 7, 2)) * 0.87559;
    context
      ..moveTo(-r, 0)
      ..lineTo(r, 0)
      ..moveTo(0, r)
      ..lineTo(0, -r);
  }
}

/// `symbol/plus.js` default export: stroked plus symbol.
const SymbolType symbolPlus = SymbolPlus();
