## 0.1.0

- Initial native, fully statically typed Dart/Flutter port of `d3-delaunay` 6.0.4,
  bundling `delaunator` 5.1.0 and `robust-predicates` 3.0.3 (`orient2d` /
  `orient2dfast`).
- Pure Dart library `package:flutter_d3_delaunay_port/d3_delaunay.dart` (zero
  Flutter imports) and Flutter library
  `package:flutter_d3_delaunay_port/flutter_d3_delaunay_port.dart` with direct
  `dart:ui.Path` helpers via `UiPathContext`.
- Full upstream test suite, Node.js reference parity tests, and faster-form twin
  tests passing on Dart VM, Chrome JS, and Chrome Wasm.
