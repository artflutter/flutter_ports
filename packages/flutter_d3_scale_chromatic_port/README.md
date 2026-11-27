# flutter_d3_scale_chromatic_port

A native Dart port of [d3-scale-chromatic](https://github.com/d3/d3-scale-chromatic) 3.1.0, the
color schemes module of D3, for Dart and Flutter. All 76 categorical, diverging, sequential and
cyclical palettes and interpolators run as pure typed Dart with no JavaScript runtime and no
WebView.

It depends on `flutter_d3_color_port` and `flutter_d3_interpolate_port`, returning typed `Rgb` and
`Cubehelix` values directly, with Flutter `Color` helpers (`toUiColors()` and
`toUiColorInterpolator()`).

```dart
import 'package:flutter_d3_scale_chromatic_port/flutter_d3_scale_chromatic_port.dart';

// Categorical palette (10 colors)
final palette = schemeCategory10.toUiColors();

// Diverging ColorBrewer palette (5 classes) and continuous interpolator
final fiveBrBG = schemeBrBG[5]!.toUiColors();
final midpoint = interpolateBrBG(0.5);

// Perceptually uniform sequential interpolator
final viridisUi = interpolateViridis.toUiColorInterpolator();
final colorAtHalf = viridisUi(0.5);
```

## Installing

```sh
flutter pub add flutter_d3_scale_chromatic_port
```

```dart
import 'package:flutter_d3_scale_chromatic_port/flutter_d3_scale_chromatic_port.dart' as d3;
```

`package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart` exports the same pure API with
no Flutter import, so it compiles for the Dart VM, JavaScript and WebAssembly without the Flutter
engine.

## Included schemes

- **Categorical (11):** `schemeCategory10`, `schemeAccent`, `schemeDark2`, `schemeObservable10`,
  `schemePaired`, `schemePastel1`, `schemePastel2`, `schemeSet1`, `schemeSet2`, `schemeSet3`,
  `schemeTableau10`.
- **Diverging (9 schemes + 9 interpolators):** `BrBG`, `PRGn`, `PiYG`, `PuOr`, `RdBu`, `RdGy`,
  `RdYlBu`, `RdYlGn`, `Spectral` (discrete palettes at indices `3..11`, `null` at `0..2`).
- **Sequential single-hue (6 schemes + 6 interpolators):** `Blues`, `Greens`, `Greys`, `Oranges`,
  `Purples`, `Reds` (discrete palettes at indices `3..9`, `null` at `0..2`).
- **Sequential multi-hue (12 ColorBrewer schemes + 18 interpolators):** `BuGn`, `BuPu`, `GnBu`,
  `OrRd`, `PuBu`, `PuBuGn`, `PuRd`, `RdPu`, `YlGn`, `YlGnBu`, `YlOrBr`, `YlOrRd`, plus
  `interpolateViridis`, `interpolateMagma`, `interpolateInferno`, `interpolatePlasma`,
  `interpolateCividis`, `interpolateTurbo`, `interpolateCubehelixDefault`, `interpolateWarm`,
  `interpolateCool`.
- **Cyclical (2 interpolators):** `interpolateRainbow`, `interpolateSinebow`.

## Flutter layer

Import `package:flutter_d3_scale_chromatic_port/flutter_d3_scale_chromatic_port.dart` for:

- `List<Color>.toUiColors()` — converts any palette to `List<ui.Color>`.
- `Color Function(double t).toUiColorInterpolator()` — wraps any interpolator to return `ui.Color`.

## Performance

Benchmarked on Apple M3 Max (Node.js v24.22.1, macOS CLI/Flutter AOT, Chrome 158, Firefox 160,
Safari 27) and Pixel 8a (Android AOT, Mobile Chrome 157, Mobile Firefox 160). All values are
median **ns/op** (lower is better; see `doc/performance.md` in the repository for the full 18-case
cross-browser breakdown).

With `v0.2.0` immutable `const` colors (D3 ADR 0013), `interpolateViridis` / `Magma` / `Inferno` /
`Plasma` return shared `const Rgb` entries with zero allocation: **`call.viridis` drops from
6.98 → 1.56 ns in macOS CLI AOT (4.47× faster, 1.55× faster than Node.js's 2.42 ns)**,
`5.84 → 2.80 ns` in dart2js (2.09×), and `2.25 → 2.04 ns` in dart2wasm, while all 38 discrete
palettes are compile-time `const` lists (0 ns startup).

| Case | Node.js upstream | macOS CLI AOT (v0.2.0) | macOS Flutter AOT (v0.1.x) | Pixel 8a AOT (v0.1.x) | Chrome Wasm (v0.1.x) | Safari Wasm (v0.1.x) | Firefox Wasm (v0.1.x) |
|---|---:|---:|---:|---:|---:|---:|---:|
| `call.viridis` | 2.42 | **1.56** | 7.23 | 13.17 | 2.28 | 3.10 | 9.06 |
| `call.magma` | 2.38 | **2.00** | 7.57 | 13.20 | 2.34 | 3.10 | 8.58 |
| `call.turbo` | 104.73 | **9.62** | 9.28 | 15.48 | 9.63 | 5.72 | 9.54 |
| `call.cividis` | 102.62 | **12.34** | 12.10 | 15.64 | 4.12 | 4.29 | 5.72 |
| `call.sinebow` | 161.91 | **7.84** | 7.98 | 15.15 | 14.11 | 22.89 | 12.40 |
| `call.rainbow` | 167.28 | **3.34** | 3.31 | 3.86 | 1.14 | 2.38 | 1.55 |
| `call.brBG` | 156.16 | **11.63** | 11.94 | 21.69 | 13.73 | 17.17 | 20.98 |
| `call.blues` | 157.37 | **11.33** | 11.98 | 21.16 | 13.07 | 17.17 | 20.98 |
| `text.viridis` | 2.37 | **14.93** | 20.22 | 39.76 | 25.56 | 41.96 | 61.04 |
| `text.brBG` | 157.92 | **41.26** | 45.24 | 62.05 | 50.73 | 91.55 | 72.48 |

## License

ISC (Mike Bostock), with Apache-2.0 notice for the ColorBrewer color schemes
(Cynthia Brewer, Mark Harrower, and The Pennsylvania State University). See [LICENSE](LICENSE).
