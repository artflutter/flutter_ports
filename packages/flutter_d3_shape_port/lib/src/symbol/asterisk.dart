// Ported from d3-shape v3.2.0 src/symbol/asterisk.js (ISC, Mike Bostock).

/// Port of `src/symbol/asterisk.js` of d3-shape 3.2.0.
library;

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/symbol_type.dart';

final double _sqrt3 = math.sqrt(3);

/// `symbol/asterisk.js`: stroked asterisk symbol type.
final class const SymbolAsterisk() implements SymbolType {
  /// Creates the asterisk symbol type.
  this;

  @override
  void draw(CanvasPath context, double size) {
    final r = math.sqrt(size + math.min(size / 28, 0.75)) * 0.59436;
    final t = r / 2;
    final u = t * _sqrt3;
    context
      ..moveTo(0, r)
      ..lineTo(0, -r)
      ..moveTo(-u, -t)
      ..lineTo(u, t)
      ..moveTo(-u, t)
      ..lineTo(u, -t);
  }
}

/// `symbol/asterisk.js` default export: stroked asterisk symbol.
const SymbolType symbolAsterisk = SymbolAsterisk();
