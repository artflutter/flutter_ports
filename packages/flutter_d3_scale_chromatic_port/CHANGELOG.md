## 0.1.0

- A native Dart port of d3-scale-chromatic 3.1.0, with no JavaScript runtime
  (D3 ADRs 0007, 0008, 0010, 0011 and 0012).
- All categorical, diverging, sequential single-hue, sequential multi-hue and
  cyclical color schemes and interpolators returning typed `flutter_d3_color_port`
  `Rgb` and `Cubehelix` values.
- The Flutter layer: `toUiColors()` on a `List<Color>` and
  `toUiColorInterpolator()` on a `Color Function(double t)`.
