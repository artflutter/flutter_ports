// Ported from d3-shape v3.2.0 src/symbol/diamond2.js (ISC, Mike Bostock).

/// Port of `src/symbol/diamond2.js` of d3-shape 3.2.0.
library;

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/symbol_type.dart';

/// `symbol/diamond2.js`: stroked rotated-square diamond symbol type.
final class const SymbolDiamond2() implements SymbolType {
  /// Creates the stroked diamond symbol type.
  this;

  @override
  void draw(CanvasPath context, double size) {
    final r = math.sqrt(size) * 0.62625;
    context
      ..moveTo(0, -r)
      ..lineTo(r, 0)
      ..lineTo(0, r)
      ..lineTo(-r, 0)
      ..closePath();
  }
}

/// `symbol/diamond2.js` default export: stroked diamond symbol.
const SymbolType symbolDiamond2 = SymbolDiamond2();
