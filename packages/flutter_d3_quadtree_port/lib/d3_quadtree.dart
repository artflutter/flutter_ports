// Original code, not ported from d3-quadtree: the pure library of the package.

/// d3-quadtree 3.0.1 in native, fully statically typed Dart with no Flutter
/// import (ADR 0011, D3 ADR 0019).
///
/// Exports every pure library of the port without `show`/`hide` combinators so
/// it compiles for the Dart VM, AOT, JavaScript, and WebAssembly with zero
/// runtime dependencies.
library;

export 'package:flutter_d3_quadtree_port/src/index.dart';
export 'package:flutter_d3_quadtree_port/src/quad.dart';
export 'package:flutter_d3_quadtree_port/src/quadtree.dart';
export 'package:flutter_d3_quadtree_port/src/upstream.dart';
