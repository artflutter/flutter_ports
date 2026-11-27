// Original code, not ported from d3-delaunay: the public package library.

/// A native, fully statically typed Dart/Flutter port of
/// [d3-delaunay](https://github.com/d3/d3-delaunay) 6.0.4 (bundling
/// [delaunator](https://github.com/mapbox/delaunator) 5.1.0 and
/// [robust-predicates](https://github.com/mourner/robust-predicates) 3.0.3
/// `orient2d`).
///
/// Exports the pure Dart `d3_delaunay.dart` library plus direct Flutter
/// `dart:ui.Path` helpers (`lib/src/ui/delaunay_ui.dart`) powered by
/// `UiPathContext` from `flutter_d3_path_port` (ADR 0011, D3 ADR 0022).
library;

export 'package:flutter_d3_delaunay_port/d3_delaunay.dart';
export 'package:flutter_d3_delaunay_port/src/ui/delaunay_ui.dart';
