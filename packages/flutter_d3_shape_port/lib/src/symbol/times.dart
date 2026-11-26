// Ported from d3-shape v3.2.0 src/symbol/times.js (ISC, Mike Bostock).

/// Port of `src/symbol/times.js` of d3-shape 3.2.0.
library;

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/symbol_type.dart';

/// `symbol/times.js`: stroked X (times) symbol type.
final class const SymbolTimes() implements SymbolType {
  /// Creates the times symbol type.
  this;

  @override
  void draw(CanvasPath context, double size) {
    final r = math.sqrt(size - math.min(size / 6, 1.7)) * 0.6189;
    context
      ..moveTo(-r, -r)
      ..lineTo(r, r)
      ..moveTo(-r, r)
      ..lineTo(r, -r);
  }
}

/// `symbol/times.js` default export: stroked X symbol.
const SymbolType symbolTimes = SymbolTimes();

/// `index.js:23` `symbolX`: alias for [symbolTimes].
const SymbolType symbolX = symbolTimes;
