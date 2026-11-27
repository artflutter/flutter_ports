// Original code, not ported from d3-geo: the public library of the package.

/// A native Dart port of [d3-geo](https://github.com/d3/d3-geo) 3.1.1 for
/// Flutter.
///
/// Exports the pure Dart `d3_geo.dart` library (spherical geometry,
/// projections, clipping, graticules, circles, and `geoPath`) plus direct
/// Flutter `dart:ui.Path` helpers (`lib/src/ui/geo_ui.dart`) powered by
/// `UiPathContext` from `flutter_d3_path_port` (ADR 0011, D3 ADR 0024).
library;

export 'package:flutter_d3_geo_port/d3_geo.dart';
export 'package:flutter_d3_geo_port/src/ui/geo_ui.dart';
