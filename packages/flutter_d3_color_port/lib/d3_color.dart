// Original code, not ported from d3-color: the pure library of the package.
/// d3-color 3.1.0 in native Dart, with no Flutter import (ADR 0011).
///
/// The library exports each file of the port that does not import Flutter:
/// the names of `src/index.js`, the helpers of the modules and the version.
/// The code reads `color('steelblue')` and `Rgb(70, 130, 180)`. The library
/// compiles for the VM, for JavaScript and for WebAssembly with no Flutter
/// engine.
library;

export 'package:flutter_d3_color_port/src/color.dart';
export 'package:flutter_d3_color_port/src/cubehelix.dart';
export 'package:flutter_d3_color_port/src/index.dart';
export 'package:flutter_d3_color_port/src/lab.dart';
export 'package:flutter_d3_color_port/src/math.dart';
export 'package:flutter_d3_color_port/src/upstream.dart';
