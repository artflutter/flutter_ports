// Original code, not ported from d3-interpolate: the pure library.
/// d3-interpolate 3.0.1 in native Dart, with no Flutter import (D3 ADR 0008
/// §6).
///
/// Import it with a prefix, as `import
/// 'package:flutter_d3_interpolate_port/d3_interpolate.dart' as d3;`. Then
/// the code reads `d3.interpolateNumber(0, 10)` and `d3.interpolateRgb(a,
/// b)`. The library compiles for the VM, for JavaScript and for WebAssembly
/// with no Flutter engine.
library;

export 'src/index.dart';
export 'src/upstream.dart';
