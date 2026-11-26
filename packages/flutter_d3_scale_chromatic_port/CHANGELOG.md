## 0.2.0

- **Breaking:** Upgrade `flutter_d3_color_port` and `flutter_d3_interpolate_port` to `^0.2.0`
  (immutable `const` color classes, D3 ADR 0013).
- `interpolateViridis`, `interpolateMagma`, `interpolateInferno`, and `interpolatePlasma` now index
  compile-time `const List<Rgb>` tables and return shared `const Rgb` entries directly with zero
  allocation (`call.viridis`: **6.98 → 1.56 ns** in AOT, 4.47× faster and 1.55× faster than
  Node.js; `5.84 → 2.80 ns` in dart2js; `2.25 → 2.04 ns` in dart2wasm).
- All 11 categorical palettes and 27 ColorBrewer discrete schemes are now compile-time `const`
  lists (`const List<Rgb>` / `const List<List<Rgb>?>`), eliminating startup hex decoding and
  allowing use in `const` Flutter widgets.

## 0.1.1

- `LICENSE`: include the full Apache License 2.0 text for the ColorBrewer
  component alongside the ISC license so pub.dev (`pana`) recognizes both
  `ISC` and `Apache-2.0`.

## 0.1.0

- A native Dart port of d3-scale-chromatic 3.1.0, with no JavaScript runtime
  (D3 ADRs 0007, 0008, 0010, 0011 and 0012).
- All categorical, diverging, sequential single-hue, sequential multi-hue and
  cyclical color schemes and interpolators returning typed `flutter_d3_color_port`
  `Rgb` and `Cubehelix` values.
- The Flutter layer: `toUiColors()` on a `List<Color>` and
  `toUiColorInterpolator()` on a `Color Function(double t)`.
