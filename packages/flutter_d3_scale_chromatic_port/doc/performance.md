# d3-scale-chromatic port performance

This file records the speed figures of `flutter_d3_scale_chromatic_port` against upstream
`d3-scale-chromatic` v3.1.0 across Node.js, macOS native AOT, Flutter macOS/Android release builds,
desktop browsers (Chrome, Firefox, Safari) and mobile browsers (Android Chrome, Android Firefox).
Each faster form has a row in [differences.md](differences.md) and a twin test in
`test/port/faster_forms_test.dart`.

## 1. Test bed

- Apple M3 Max, macOS, on AC power (2026-11-26).
- Flutter `master` (Dart 3.14+), Node.js v24.22.1 (arm64).
- Pixel 8a, Android 17 (AOT release APK + Chrome 157 + Firefox 160).
- Desktop browsers: HeadlessChrome 158, Firefox 160, Safari 27.0.1.
- iPhone Home_26+ (iOS): release build compiled, signed (`SU64687X4W`) and installed via
  `devicectl`; execution timed out while device screen was locked.
- Instrument: `tool/bench/d3_scale_chromatic_bench.dart` and
  `tool/bench/d3_scale_chromatic_bench.mjs` run 18 cases on identical 1,024-entry seeded `t` pools.
  All figures are median nanoseconds per operation (`ns/op`, lower is better).
- `call.*` return typed `Rgb` or `Cubehelix` in Dart (zero string allocation), whereas upstream JS
  always formats a CSS string (`#rrggbb` or `rgb(...)`). `text.*` include `.formatHex()` /
  `.toString()` in Dart for an exact string-to-string comparison.

## 2. Baseline vs optimized (macOS CLI: Node.js, AOT, dart2js, dart2wasm)

Optimizations applied (row `adapt-chromatic-fast-forms`):

1. **Fused cubic B-spline in `ramp()` (`lib/src/ramp.dart`):** computes the uniform B-spline weights
   once across all three channels over padded `Float64List` control tables (bit-identical to
   `interpolateRgbBasis(scheme.last!)`). Cuts `call.brBG` / `call.blues` by 2.1× on AOT, 4.5× on
   JS, and 2.5–3.6× on Wasm.
2. **Zero-copy code-unit hex decoder in `colors()` (`lib/src/colors.dart`):** decodes 6-hex-digit
   slices directly via `codeUnitAt` in a plain `for` loop (no `substring` allocations, no
   `int.parse`, no `List.generate` closure) wrapped in `UnmodifiableListView`. Cuts `parse.colors10`
   / `parse.colors256` by 2.1–2.2× on AOT, 7.1–8.8× on JS, and 5.6–6.5× on Wasm (beating Node.js on
   Wasm).
3. **Angle-addition identity in `interpolateSinebow` (`lib/src/sequential-multi/sinebow.dart`):**
   computes `sin(a)` + `cos(a)` once instead of three `sin()` calls. Cuts `call.sinebow` by 28% on
   AOT and 37% on JS/Wasm.
4. **Concrete fixed list + fast clamp in `viridis.dart`:** avoids `UnmodifiableListView` indirection
   and `floorToDouble()` on `(0, 1)`. Cuts `call.viridis` / `call.magma` by 11–15% on AOT.
5. **Rejected:** replacing `math.max`/`math.min` in `cividis.dart` and `turbo.dart` with ternary
   branch clamps regressed JS and Wasm by 2.1–2.4× due to branch mispredictions and `num` boxing;
   kept branchless `math.max<double>(0, math.min(..., ...))` with built-in `.roundToDouble()`.

| Case | node | aot base | aot opt | js base | js opt | wasm base | wasm opt |
|---|---:|---:|---:|---:|---:|---:|---:|
| `call.viridis` | 2.42 | 7.82 | 6.98 (0.89x) | 5.96 | 5.84 (0.98x) | 1.96 | 2.25 (1.15x) |
| `call.magma` | 2.38 | 8.08 | 6.89 (0.85x) | 5.89 | 6.05 (1.03x) | 1.97 | 2.26 (1.15x) |
| `call.turbo` | 104.73 | 9.70 | 9.47 (0.98x) | 5.91 | 5.91 (1.00x) | 10.19 | 9.82 (0.96x) |
| `call.cividis` | 102.62 | 12.27 | 11.94 (0.97x) | 5.95 | 5.90 (0.99x) | 4.48 | 4.42 (0.99x) |
| `call.sinebow` | 161.91 | 10.53 | 7.59 (0.72x) | 18.42 | 11.59 (0.63x) | 18.20 | 11.48 (0.63x) |
| `call.rainbow` | 167.28 | 3.33 | 3.30 (0.99x) | 1.91 | 1.90 (0.99x) | 1.20 | 1.23 (1.03x) |
| `call.rainbowWrap` | 173.42 | 3.32 | 3.33 (1.00x) | 1.45 | 1.44 (0.99x) | 1.50 | 1.51 (1.01x) |
| `call.warm` | 190.38 | 9.96 | 9.75 (0.98x) | 9.97 | 10.12 (1.02x) | 11.02 | 10.80 (0.98x) |
| `call.cubehelixDefault` | 187.02 | 10.37 | 10.29 (0.99x) | 9.26 | 9.36 (1.01x) | 10.70 | 10.73 (1.00x) |
| `call.brBG` | 156.16 | 23.66 | 11.55 (0.49x) | 25.72 | 5.82 (0.23x) | 38.93 | 15.44 (0.40x) |
| `call.blues` | 157.37 | 24.29 | 11.49 (0.47x) | 25.62 | 5.47 (0.21x) | 53.42 | 15.03 (0.28x) |
| `text.viridis` | 2.37 | 20.91 | 20.66 (0.99x) | 32.19 | 28.53 (0.89x) | 21.67 | 22.41 (1.03x) |
| `text.turbo` | 103.42 | 40.38 | 40.41 (1.00x) | 89.11 | 91.58 (1.03x) | 56.02 | 52.45 (0.94x) |
| `text.sinebow` | 159.72 | 46.29 | 47.68 (1.03x) | 89.79 | 86.42 (0.96x) | 66.76 | 64.02 (0.96x) |
| `text.rainbow` | 167.85 | 56.81 | 57.34 (1.01x) | 98.40 | 93.83 (0.95x) | 73.93 | 72.70 (0.98x) |
| `text.brBG` | 157.92 | 50.46 | 41.54 (0.82x) | 79.81 | 69.46 (0.87x) | 75.28 | 52.66 (0.70x) |
| `parse.colors10` | 109.05 | 399.51 | 180.97 (0.45x) | 939.21 | 133.21 (0.14x) | 498.50 | 89.05 (0.18x) |
| `parse.colors256` | 2487.34 | 9945.80 | 4647.22 (0.47x) | 26432.62 | 3019.41 (0.11x) | 11903.81 | 1838.13 (0.15x) |

## 2b. Immutable `const` colors upgrade (v0.2.0, D3 ADR 0013)

Making `flutter_d3_color_port`'s color classes immutable (`final` fields + `const` constructors)
eliminated the per-call `Rgb` allocation in `viridis.dart` (direct lookup from compile-time
`const List<Rgb>` tables) and eliminated startup hex parsing across all 38 discrete schemes:

| Case | Node.js | AOT v0.1 → v0.2 | AOT speedup | dart2js v0.1 → v0.2 | dart2wasm v0.1 → v0.2 |
|---|---:|---:|---:|---:|---:|
| `call.viridis` | 2.42 | 6.98 → **1.56** | **4.47×** *(1.55× faster than Node)* | 5.84 → **2.80** (2.09×) | 2.25 → **2.04** (1.10×) |
| `call.magma` | 2.38 | 6.89 → **2.00** | **3.44×** *(1.19× faster than Node)* | 6.05 → 6.04 (1.00×) | 2.26 → **2.05** (1.10×) |
| `text.viridis` | 2.37 | 20.66 → **14.93** | **1.38×** | 28.53 → **21.46** (1.33×) | 22.41 → 21.67 (1.03×) |

All other `call.*` and `text.*` cases remained within measurement noise of v0.1.x.

## 3. Native macOS Flutter AOT and Desktop Browsers (ns/op)

Each browser cell shows `upstream JS / dart2js / dart2wasm`.

| Case | macOS Flutter AOT | Chrome 158 (up/js/wasm) | Firefox 160 (up/js/wasm) | Safari 27 (up/js/wasm) |
|---|---:|---|---|---|
| `call.viridis` | 7.23 | 2.22 / 3.05 / 2.28 | 2.38 / 14.31 / 9.06 | 2.62 / 2.86 / 3.10 |
| `call.magma` | 7.57 | 2.24 / 3.03 / 2.34 | 2.38 / 15.26 / 8.58 | 2.62 / 2.86 / 3.10 |
| `call.turbo` | 9.28 | 72.10 / 6.77 / 9.63 | 38.15 / 19.07 / 9.54 | 68.66 / 6.20 / 5.72 |
| `call.cividis` | 12.10 | 73.62 / 6.72 / 4.12 | 53.41 / 10.49 / 5.72 | 61.04 / 14.31 / 4.29 |
| `call.sinebow` | 7.98 | 115.20 / 14.11 / 14.11 | 167.85 / 20.98 / 12.40 | 91.55 / 7.63 / 22.89 |
| `call.rainbow` | 3.31 | 116.73 / 1.91 / 1.14 | 190.73 / 12.40 / 1.55 | 106.81 / 0.89 / 2.38 |
| `call.rainbowWrap` | 3.29 | 125.12 / 1.38 / 1.49 | 183.11 / 13.35 / 1.67 | 122.07 / 1.55 / 2.38 |
| `call.warm` | 9.97 | 134.28 / 10.01 / 10.49 | 198.36 / 22.89 / 6.68 | 99.18 / 2.62 / 7.15 |
| `call.cubehelixDefault` | 10.86 | 141.14 / 9.16 / 10.68 | 198.36 / 22.89 / 6.68 | 106.81 / 2.62 / 7.15 |
| `call.brBG` | 11.94 | 119.02 / 6.06 / 13.73 | 167.85 / 20.98 / 20.98 | 91.55 / 13.35 / 17.17 |
| `call.blues` | 11.98 | 120.54 / 5.58 / 13.07 | 175.48 / 20.98 / 20.98 | 106.81 / 13.35 / 17.17 |
| `text.viridis` | 20.22 | 2.22 / 21.36 / 25.56 | 2.38 / 34.33 / 61.04 | 2.62 / 40.05 / 41.96 |
| `text.turbo` | 41.71 | 73.24 / 54.55 / 41.96 | 38.15 / 45.78 / 76.29 | 61.04 / 76.29 / 91.55 |
| `text.sinebow` | 49.73 | 114.44 / 67.90 / 57.22 | 167.85 / 53.41 / 76.29 | 91.55 / 83.92 / 106.81 |
| `text.rainbow` | 55.40 | 119.02 / 73.62 / 61.79 | 190.73 / 64.85 / 83.92 | 106.81 / 91.55 / 122.07 |
| `text.brBG` | 45.24 | 125.89 / 54.55 / 50.73 | 167.85 / 53.41 / 72.48 | 99.18 / 83.92 / 91.55 |
| `parse.colors10` | 175.51 | 97.66 / 109.10 / 70.96 | 99.18 / 335.69 / 366.21 | 68.66 / 99.18 / 335.69 |
| `parse.colors256` | 4552.49 | 2270.51 / 2233.89 / 1538.09 | 2075.20 / 7324.22 / 9765.63 | 1464.84 / 2197.27 / 7812.50 |

## 4. Mobile: Android Pixel 8a Native AOT & Mobile Browsers (ns/op)

| Case | Pixel 8a AOT | Pixel Chrome 157 (up/js/wasm) | Pixel Firefox 160 (up/js/wasm) |
|---|---:|---|---|
| `call.viridis` | 13.17 | 4.67 / 26.13 / 3.86 | 5.25 / 36.24 / 14.31 |
| `call.magma` | 13.20 | 4.63 / 33.00 / 3.93 | 5.25 / 36.24 / 16.21 |
| `call.turbo` | 15.48 | 204.47 / 41.20 / 19.64 | 61.04 / 38.15 / 16.21 |
| `call.cividis` | 15.64 | 181.58 / 27.08 / 8.06 | 68.66 / 20.03 / 11.44 |
| `call.sinebow` | 15.15 | 273.13 / 61.80 / 25.75 | 320.43 / 41.96 / 53.41 |
| `call.rainbow` | 3.86 | 321.96 / 31.66 / 2.05 | 335.69 / 22.89 / 5.25 |
| `call.rainbowWrap` | 4.06 | 328.06 / 33.95 / 2.26 | 350.95 / 28.61 / 6.20 |
| `call.warm` | 17.33 | 332.64 / 56.84 / 17.83 | 335.69 / 49.59 / 13.35 |
| `call.cubehelixDefault` | 17.17 | 344.85 / 57.60 / 17.26 | 381.47 / 49.59 / 13.35 |
| `call.brBG` | 21.69 | 268.55 / 45.78 / 23.08 | 320.43 / 45.78 / 30.52 |
| `call.blues` | 21.16 | 280.76 / 43.87 / 24.03 | 335.69 / 45.78 / 32.42 |
| `text.viridis` | 39.76 | 4.63 / 79.34 / 36.05 | 5.25 / 72.48 / 114.44 |
| `text.turbo` | 51.81 | 176.24 / 122.83 / 62.94 | 61.04 / 76.29 / 99.18 |
| `text.sinebow` | 55.02 | 270.08 / 140.39 / 82.40 | 305.18 / 83.92 / 114.44 |
| `text.rainbow` | 77.94 | 315.86 / 183.11 / 95.37 | 335.69 / 114.44 / 122.07 |
| `text.brBG` | 62.05 | 283.81 / 122.84 / 74.77 | 335.69 / 83.92 / 106.81 |
| `parse.colors10` | 289.83 | 141.14 / 546.30 / 120.54 | 244.14 / 854.49 / 671.39 |
| `parse.colors256` | 7359.62 | 3466.80 / 12500.00 / 2880.86 | 3417.97 / 12695.31 / 17578.13 |
