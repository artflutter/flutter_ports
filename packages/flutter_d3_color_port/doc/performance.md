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

## 3. The faster forms of 2026-11-15

Three changes, each with its rows in [differences.md](differences.md) and a twin test in
`test/port/` that compares the fast form with the translation of the upstream lines, bit for bit:

- The parser (`adapt-color-parse-scan`, `adapt-color-parse-number`,
  `adapt-color-named-table`): one pass over the code units of an ASCII text with the grammar of
  the upstream patterns, an exact fast path for the decimal numbers, and a hash table of the names
  that compares the code units with no lowercase copy. A text with another code unit takes the
  upstream lines.
- The formats (`adapt-color-clamp-compare`, `adapt-color-hex-table`,
  `adapt-color-number-text`, `adapt-color-format-units`): on the VM and in WebAssembly, the
  formats write the code units into one buffer and make one string. In JavaScript, they keep the
  template texts, with tables of the hexadecimal and decimal texts. `clampi` compares with no
  `Math.round`, and the text of a number k / 100 comes from the digits of k.
- The conversions (`adapt-color-hsl-hue-wrap`, `adapt-color-convert-locals`,
  `adapt-color-lrgb-table`): no intermediate object in `labConvert`, `hclConvert`,
  `cubehelixConvert` and `Hcl.rgb`, no remainder for a hue in [0, 360), a table of
  `rgb2lrgb` for a whole channel, and double literals in the arithmetic, which dart2wasm compiled
  as boxed integers.

The figures: "base" is §2, "opt" is the code after the three changes, with the ratio opt / base.

| Case | node | aot base | js base | wasm base | aot opt | js opt | wasm opt |
|---|---:|---:|---:|---:|---:|---:|---:|
| `parse.hex6` | 74 | 242 | 153 | 215 | 32 (0.13x) | 28 (0.18x) | 46 (0.21x) |
| `parse.hex3` | 65 | 187 | 111 | 191 | 25 (0.13x) | 25 (0.23x) | 38 (0.20x) |
| `parse.named` | 150 | 386 | 179 | 239 | 42 (0.11x) | 46 (0.26x) | 62 (0.26x) |
| `parse.rgb` | 147 | 569 | 244 | 429 | 47 (0.08x) | 69 (0.28x) | 80 (0.19x) |
| `parse.rgbaPercent` | 280 | 1113 | 412 | 647 | 59 (0.05x) | 114 (0.28x) | 104 (0.16x) |
| `parse.hsl` | 220 | 913 | 336 | 521 | 44 (0.05x) | 76 (0.23x) | 70 (0.13x) |
| `parse.invalid` | 120 | 536 | 160 | 204 | 23 (0.04x) | 40 (0.25x) | 36 (0.18x) |
| `parse.mixed` | 175 | 604 | 267 | 397 | 45 (0.07x) | 76 (0.29x) | 72 (0.18x) |
| `rgb.parse` | 182 | 617 | 275 | 394 | 47 (0.08x) | 76 (0.28x) | 66 (0.17x) |
| `format.hex` | 45 | 164 | 80 | 83 | 13 (0.08x) | 17 (0.21x) | 31 (0.37x) |
| `format.hex8` | 60 | 222 | 99 | 122 | 23 (0.10x) | 23 (0.23x) | 39 (0.32x) |
| `format.rgb` | 54 | 175 | 76 | 146 | 25 (0.14x) | 40 (0.52x) | 54 (0.37x) |
| `format.hsl` | 202 | 401 | 206 | 325 | 97 (0.24x) | 107 (0.52x) | 124 (0.38x) |
| `format.rgbOfHsl` | 33 | 115 | 84 | 133 | 35 (0.31x) | 69 (0.82x) | 59 (0.44x) |
| `convert.rgbToHsl` | 20 | 9 | 26 | 11 | 10 (1.19x) | 26 (1.00x) | 9 (0.82x) |
| `convert.hslToRgb` | 20 | 18 | 29 | 48 | 11 (0.61x) | 24 (0.85x) | 18 (0.38x) |
| `convert.rgbToLab` | 88 | 81 | 88 | 96 | 80 (0.98x) | 88 (1.00x) | 64 (0.67x) |
| `convert.labToRgb` | 43 | 38 | 52 | 59 | 37 (0.96x) | 52 (1.00x) | 48 (0.82x) |
| `convert.rgbToHcl` | 129 | 115 | 122 | 117 | 108 (0.94x) | 122 (1.00x) | 115 (0.98x) |
| `convert.hclToRgb` | 72 | 63 | 78 | 83 | 54 (0.87x) | 76 (0.98x) | 74 (0.89x) |
| `convert.rgbToCubehelix` | 43 | 17 | 38 | 10 | 17 (0.99x) | 38 (1.00x) | 9 (0.92x) |
| `convert.cubehelixToRgb` | 38 | 20 | 40 | 49 | 20 (1.00x) | 41 (1.02x) | 33 (0.66x) |
| `op.brighterRgb` | 9 | 6 | 14 | 9 | 6 (1.01x) | 13 (0.93x) | 8 (0.98x) |
| `op.darkerHcl` | 9 | 6 | 13 | 9 | 6 (0.99x) | 13 (1.00x) | 9 (0.97x) |
| `pipe.hclTick` | 175 | 174 | 141 | 192 | 92 (0.53x) | 134 (0.95x) | 120 (0.62x) |
| `pipe.parseHex` | 221 | 819 | 336 | 471 | 61 (0.07x) | 84 (0.25x) | 96 (0.20x) |

- Each parse case is faster than upstream on each target: in AOT 3 to 5 times, in JavaScript and
  WebAssembly 1.5 to 3 times.
- The format cases are faster than upstream on each target, except `format.rgbOfHsl` in
  JavaScript and WebAssembly. That case is `Hsl.rgb()` and `formatRgb()`.
- The conversions through CIELAB are about as fast as upstream: `Math.pow`, `atan2`, `sin`
  and `cos` take most of their time, and the port keeps them as they are.
