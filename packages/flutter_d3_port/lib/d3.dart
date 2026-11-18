// Original code, not ported from D3: the pure library of the port.
/// The D3 modules of the port, with no Flutter import (D3 ADR 0008).
///
/// Each module is a package of its own, for example `flutter_d3_color_port`,
/// and this library re-exports each of them, as the npm package `d3` does
/// (ADR 0011). The code reads `color('steelblue')` and `Rgb(70, 130, 180)`.
/// The library compiles for the VM, for JavaScript and for WebAssembly with
/// no Flutter engine.
library;

export 'package:flutter_d3_port/src/d3/index.dart';
export 'package:flutter_d3_port/src/upstream.dart';
