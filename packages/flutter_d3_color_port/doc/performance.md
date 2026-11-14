# d3-color port performance

This file has the speed figures of the d3-color port against upstream d3-color in Node.js. Each
form of the port that is faster than the translation of the upstream lines has a row in
[differences.md](differences.md).

## 1. Test bed

- Apple M3 Max, macOS 27.0.1, on AC power, at night,
  under `caffeinate -i`.
- Dart 3.14.0-315.3.beta (Flutter 3.50.0-0.4.pre, the pin of `.fvmrc`). Node.js v24.22.1
  (arm64, V8 13.6.233.17-node.58).
- The instrument is `tool/bench/`: `d3_color_bench.dart` (the port) and `d3_color_bench.mjs`
  (upstream `third_party/d3-color/src` at `v3.1.0`) have the same 26 cases on the same input
  pools of 1,024 items from a fixed seed. `run_bench.sh` runs the targets:
  - `node`: upstream d3-color in Node.js, the reference speed.
  - `aot`: the port, `dart compile exe`.
  - `js`: the port, `dart compile js -O4`, run in Node.js.
  - `wasm`: the port, `dart compile wasm -O2`, run in Node.js.
- Each case warms up for 300 ms, then runs 9 batches of about 60 ms. A run gives the median time of
  one operation of the batches. Each figure is the mean of two runs, in nanoseconds for one
  operation. Two runs are a weak interval: read a change below 10% as no change.
- `parse.*` call `color(text)`; `rgb.parse` is `Rgb.parse` (upstream `rgb(text)`); `format.*`
  call the format methods; `convert.*` call the conversions; `pipe.hclTick` writes the hue of an
  `Hcl` and prints the color, as one tick of an HCL interpolator; `pipe.parseHex` is
  `Rgb.parse(text).formatHex()`.

## 2. Baseline: the translation of the upstream lines (2026-11-15)

The port before any faster form: the six RegExps of upstream, `trim()` and `toLowerCase()`, string
interpolation and `toRadixString`.

| Case | node | aot | js | wasm |
|---|---:|---:|---:|---:|
| `parse.hex6` | 74 | 242 | 153 | 215 |
| `parse.hex3` | 65 | 187 | 111 | 191 |
| `parse.named` | 150 | 386 | 179 | 239 |
| `parse.rgb` | 147 | 569 | 244 | 429 |
| `parse.rgbaPercent` | 280 | 1113 | 412 | 647 |
| `parse.hsl` | 220 | 913 | 336 | 521 |
| `parse.invalid` | 120 | 536 | 160 | 204 |
| `parse.mixed` | 175 | 604 | 267 | 397 |
| `rgb.parse` | 182 | 617 | 275 | 394 |
| `format.hex` | 45 | 164 | 80 | 83 |
| `format.hex8` | 60 | 222 | 99 | 122 |
| `format.rgb` | 54 | 175 | 76 | 146 |
| `format.hsl` | 202 | 401 | 206 | 325 |
| `format.rgbOfHsl` | 33 | 115 | 84 | 133 |
| `convert.rgbToHsl` | 20 | 9 | 26 | 11 |
| `convert.hslToRgb` | 20 | 18 | 29 | 48 |
| `convert.rgbToLab` | 88 | 81 | 88 | 96 |
| `convert.labToRgb` | 43 | 38 | 52 | 59 |
| `convert.rgbToHcl` | 129 | 115 | 122 | 117 |
| `convert.hclToRgb` | 72 | 63 | 78 | 83 |
| `convert.rgbToCubehelix` | 43 | 17 | 38 | 10 |
| `convert.cubehelixToRgb` | 38 | 20 | 40 | 49 |
| `op.brighterRgb` | 9 | 6 | 14 | 9 |
| `op.darkerHcl` | 9 | 6 | 13 | 9 |
| `pipe.hclTick` | 175 | 174 | 141 | 192 |
| `pipe.parseHex` | 221 | 819 | 336 | 471 |

- The parse cases are 3 to 4 times slower than upstream in AOT. The VM runs a RegExp with an
  interpreter in AOT, and the parse runs up to six of them, after `trim()` and `toLowerCase()`.
- The format cases are 2 to 3 times slower than upstream in AOT: `toRadixString`, the string
  interpolation and `double.toString`.
- The conversions are as fast as upstream or faster on each target, except the HSL and
  Cubehelix to RGB conversions in WebAssembly.
