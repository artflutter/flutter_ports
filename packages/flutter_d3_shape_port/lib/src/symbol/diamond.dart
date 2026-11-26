// Ported from d3-shape v3.2.0 src/symbol/diamond.js (ISC, Mike Bostock).

/// Port of `src/symbol/diamond.js` of d3-shape 3.2.0.
library;

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/symbol_type.dart';

final double _tan30 = math.sqrt(1 / 3);
final double _tan30_2 = _tan30 * 2;

/// `symbol/diamond.js`: filled rhombus (diamond) symbol type.
final class const SymbolDiamond() implements SymbolType {
  /// Creates the diamond symbol type.
  this;

  @override
  void draw(CanvasPath context, double size) {
    final y = math.sqrt(size / _tan30_2);
    final x = y * _tan30;
    context
      ..moveTo(0, -y)
      ..lineTo(x, 0)
      ..lineTo(0, y)
      ..lineTo(-x, 0)
      ..closePath();
  }
}

/// `symbol/diamond.js` default export: filled diamond symbol.
const SymbolType symbolDiamond = SymbolDiamond();
