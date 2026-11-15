// Original code, not ported from d3-color: the pure library of the package.
/// d3-color 3.1.0 in native Dart, with no Flutter import (D3 ADR 0008 §6).
///
/// Import it with a prefix, as `import
/// 'package:flutter_d3_color_port/d3_color.dart' as d3;`. Then the code reads
/// `d3.color('steelblue')` and `d3.Rgb(70, 130, 180)`. The library compiles
/// for the VM, for JavaScript and for WebAssembly with no Flutter engine.
library;

export 'src/index.dart';
export 'src/upstream.dart';
