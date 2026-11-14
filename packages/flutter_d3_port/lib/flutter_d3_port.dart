// Original code, not ported from D3: the public library of the package.
/// A native Dart port of [D3](https://d3js.org) for Flutter.
///
/// The library exports the D3 modules of `d3.dart` and the Flutter layer of
/// each module, for example the conversions between the d3-color classes
/// and the Flutter `Color`. The `doc/` folder of this package has the roadmap
/// and the parity tracker.
library;

export 'package:flutter_d3_color_port/flutter_d3_color_port.dart'
    show D3ColorToUi, UiColorToD3;

export 'd3.dart';
