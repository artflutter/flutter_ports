// Ported from d3-shape v3.2.0 src/symbol/cross.js (ISC, Mike Bostock).

/// Port of `src/symbol/cross.js` of d3-shape 3.2.0.
library;

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/symbol_type.dart';

/// `symbol/cross.js`: filled Greek cross symbol type.
final class const SymbolCross() implements SymbolType {
  /// Creates the cross symbol type.
  this;

  @override
  void draw(CanvasPath context, double size) {
    final r = math.sqrt(size / 5) / 2;
    context
      ..moveTo(-3 * r, -r)
      ..lineTo(-r, -r)
      ..lineTo(-r, -3 * r)
      ..lineTo(r, -3 * r)
      ..lineTo(r, -r)
      ..lineTo(3 * r, -r)
      ..lineTo(3 * r, r)
      ..lineTo(r, r)
      ..lineTo(r, 3 * r)
      ..lineTo(-r, 3 * r)
      ..lineTo(-r, r)
      ..lineTo(-3 * r, r)
      ..closePath();
  }
}

/// `symbol/cross.js` default export: filled Greek cross symbol.
const SymbolType symbolCross = SymbolCross();
