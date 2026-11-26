// Original code, not ported from d3-shape: the SymbolType interface.

/// The pure [SymbolType] interface for shape symbols (D3 ADR 0015).
library;

import 'package:flutter_d3_path_port/d3_path.dart';

/// A symbol shape that draws itself into a [CanvasPath] with area `size`
/// (in square pixels).
abstract interface class SymbolType() {
  /// Draws this symbol centered at the origin with area [size] into [context].
  void draw(CanvasPath context, double size);
}
