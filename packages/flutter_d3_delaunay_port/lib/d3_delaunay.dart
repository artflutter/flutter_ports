// Original code, not ported from d3-delaunay: the pure library of the package.

/// d3-delaunay 6.0.4 (with delaunator 5.1.0 and robust-predicates 3.0.3
/// `orient2d`) in native Dart, with no Flutter import (ADR 0011, D3 ADR 0022).
///
/// Exports every pure file of the port without `show`/`hide` combinators so it
/// compiles for the Dart VM, AOT, JavaScript (`dart2js`), and WebAssembly
/// (`dart2wasm`) without the Flutter engine.
library;

export 'package:flutter_d3_delaunay_port/src/delaunator/index.dart';
export 'package:flutter_d3_delaunay_port/src/delaunay.dart';
export 'package:flutter_d3_delaunay_port/src/index.dart';
export 'package:flutter_d3_delaunay_port/src/path.dart';
export 'package:flutter_d3_delaunay_port/src/polygon.dart';
export 'package:flutter_d3_delaunay_port/src/robust_predicates/orient2d.dart';
export 'package:flutter_d3_delaunay_port/src/robust_predicates/util.dart';
export 'package:flutter_d3_delaunay_port/src/upstream.dart';
export 'package:flutter_d3_delaunay_port/src/voronoi.dart';
