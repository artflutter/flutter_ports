// Original code, not ported from d3-path: the pure library of the package.

/// d3-path 3.1.0 in native Dart, with no Flutter import (ADR 0011).
///
/// The library exports each file of the port that does not import Flutter:
/// `Path`, `path`, `pathRound`, the `CanvasPath` interface, and the version
/// constant. It compiles for the VM, JavaScript and WebAssembly with no
/// Flutter engine.
library;

export 'package:flutter_d3_path_port/src/canvas_path.dart';
export 'package:flutter_d3_path_port/src/index.dart';
export 'package:flutter_d3_path_port/src/path.dart';
export 'package:flutter_d3_path_port/src/upstream.dart';
