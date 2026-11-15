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

## 4. Phones

- Pixel 8a, Android 17, a release build of a Flutter app that runs `d3_color_bench.dart`
  (`flutter build apk --release`, AOT), on USB power, screen on, battery at 26.5-27.5 °C.
- Chrome 157 on the same Pixel: "chrome upstream" is upstream d3-color, "chrome-js" and
  "chrome-wasm" are the port built with `dart compile js -O4` and `dart compile wasm -O2`, in
  one page served from the Mac.
- iPhone 17 Pro, iOS 27.2, a release build of the same app (`flutter build ios --release`).
- The app and the page are scratch instruments outside the package. Each figure is the mean of two
  runs, in nanoseconds for one operation. "base" is the code of §2, "r1" the code of §3, with the
  ratio r1 / base.

| Case | chrome upstream | pixel base | pixel r1 | chrome-js base | chrome-js r1 | chrome-wasm base | chrome-wasm r1 | iphone base | iphone r1 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `parse.hex6` | 112 | 335 | 48 (0.14x) | 200 | 45 (0.23x) | 308 | 55 (0.18x) | 169 | 19 (0.11x) |
| `parse.hex3` | 98 | 271 | 43 (0.16x) | 185 | 30 (0.16x) | 300 | 48 (0.16x) | 140 | 19 (0.14x) |
| `parse.named` | 122 | 662 | 66 (0.10x) | 184 | 53 (0.29x) | 291 | 95 (0.33x) | 295 | 29 (0.10x) |
| `parse.rgb` | 190 | 744 | 71 (0.10x) | 369 | 94 (0.25x) | 700 | 119 (0.17x) | 416 | 33 (0.08x) |
| `parse.rgbaPercent` | 418 | 1502 | 90 (0.06x) | 656 | 161 (0.24x) | 1062 | 164 (0.15x) | 829 | 44 (0.05x) |
| `parse.hsl` | 269 | 1315 | 67 (0.05x) | 482 | 108 (0.22x) | 801 | 112 (0.14x) | 729 | 33 (0.05x) |
| `parse.invalid` | 122 | 836 | 36 (0.04x) | 196 | 51 (0.26x) | 283 | 56 (0.20x) | 413 | 17 (0.04x) |
| `parse.mixed` | 217 | 857 | 66 (0.08x) | 388 | 98 (0.25x) | 610 | 108 (0.18x) | 468 | 33 (0.07x) |
| `rgb.parse` | 226 | 872 | 68 (0.08x) | 395 | 105 (0.26x) | 616 | 105 (0.17x) | 471 | 33 (0.07x) |
| `format.hex` | 73 | 347 | 32 (0.09x) | 85 | 31 (0.36x) | 111 | 55 (0.50x) | 136 | 13 (0.10x) |
| `format.hex8` | 94 | 459 | 45 (0.10x) | 118 | 36 (0.31x) | 183 | 69 (0.38x) | 187 | 22 (0.12x) |
| `format.rgb` | 69 | 274 | 42 (0.15x) | 76 | 56 (0.73x) | 205 | 90 (0.44x) | 143 | 18 (0.13x) |
| `format.hsl` | 197 | 638 | 152 (0.24x) | 220 | 118 (0.54x) | 420 | 178 (0.42x) | 334 | 77 (0.23x) |
| `format.rgbOfHsl` | 46 | 187 | 61 (0.33x) | 101 | 89 (0.87x) | 178 | 98 (0.55x) | 99 | 26 (0.26x) |
| `convert.rgbToHsl` | 35 | 21 | 21 (1.00x) | 34 | 35 (1.03x) | 20 | 17 (0.83x) | 9 | 9 (0.97x) |
| `convert.hslToRgb` | 28 | 33 | 20 (0.59x) | 34 | 32 (0.95x) | 67 | 30 (0.45x) | 19 | 9 (0.47x) |
| `convert.rgbToLab` | 148 | 131 | 129 (0.99x) | 143 | 143 (1.00x) | 168 | 99 (0.59x) | 62 | 60 (0.97x) |
| `convert.labToRgb` | 70 | 68 | 66 (0.97x) | 79 | 79 (1.00x) | 95 | 82 (0.86x) | 32 | 30 (0.94x) |
| `convert.rgbToHcl` | 204 | 172 | 165 (0.96x) | 193 | 186 (0.96x) | 187 | 175 (0.93x) | 107 | 91 (0.85x) |
| `convert.hclToRgb` | 105 | 94 | 87 (0.93x) | 111 | 109 (0.99x) | 118 | 109 (0.92x) | 51 | 42 (0.83x) |
| `convert.rgbToCubehelix` | 74 | 52 | 50 (0.97x) | 68 | 68 (1.00x) | 21 | 19 (0.91x) | 15 | 15 (0.99x) |
| `convert.cubehelixToRgb` | 45 | 37 | 36 (0.97x) | 55 | 55 (0.99x) | 67 | 41 (0.61x) | 20 | 19 (0.98x) |
| `op.brighterRgb` | 19 | 15 | 14 (0.98x) | 22 | 22 (1.00x) | 16 | 16 (0.99x) | 8 | 8 (0.96x) |
| `op.darkerHcl` | 17 | 14 | 14 (0.99x) | 23 | 23 (1.00x) | 16 | 15 (0.98x) | 8 | 8 (1.00x) |
| `pipe.hclTick` | 247 | 257 | 133 (0.52x) | 150 | 174 (1.17x) | 278 | 180 (0.65x) | 154 | 64 (0.42x) |
| `pipe.parseHex` | 278 | 1284 | 93 (0.07x) | 469 | 118 (0.25x) | 731 | 158 (0.22x) | 656 | 48 (0.07x) |

- In AOT on the phones, each parse and format case is 3 to 25 times faster than before. On the
  Pixel, the AOT port parses 1.8 to 4.6 times faster than upstream in Chrome on the same phone.
- In Chrome on the Pixel, the dart2js build parses 2.0 to 3.3 times faster than upstream, and the
  dart2wasm build 1.3 to 2.5 times. `format.rgbOfHsl` stays slower than upstream there (89 and
  98 ns against 46 ns). `pipe.hclTick` in dart2js went from 150 to 174 ns, still faster than
  upstream (247 ns).

## 5. Round two of 2026-11-15: the web formats

Four changes for dart2js and dart2wasm, with the row `adapt-color-format-locals` and the
updated row `adapt-color-format-units`:

- In JavaScript and WebAssembly, `Rgb.formatRgb` joins three texts of a table (four with an
  opacity): six joins of short strings cost about 44 ns in V8, three joins of whole texts about
  17 ns. dart2wasm compiles a string `+` to a direct concatenation, and an interpolation to a
  call with type checks.
- On the VM and in WebAssembly, `Hsl.formatRgb` and `Hcl.formatRgb` (and so `toString`)
  compute the RGB channels in locals and write the text with no temporary `Rgb`. Only an object
  of the exact class takes this form: a subclass formats the result of its own `rgb()`, as
  upstream.
- `clampt` tests NaN before the clamp, so that dart2wasm boxes no number there, and the other
  double expressions have double literals.
- The dart2js body of `Rgb.formatRgb` stays small enough for V8 to inline it into its callers.
  Before, the full case order of the bench put `pipe.hclTick` over the inlining budget of V8: in
  Chrome on the Pixel, that case went from 150 ns (§2) to 174 ns in round one.

The Mac figures, round one (§3) against round two:

| Case | node | aot r1 | js r1 | wasm r1 | aot r2 | js r2 | wasm r2 |
|---|---:|---:|---:|---:|---:|---:|---:|
| `parse.hex6` | 74 | 32 | 28 | 46 | 32 (1.00x) | 28 (1.00x) | 48 (1.04x) |
| `parse.hex3` | 64 | 25 | 25 | 38 | 25 (1.00x) | 25 (0.98x) | 37 (0.97x) |
| `parse.named` | 147 | 42 | 46 | 62 | 42 (1.00x) | 46 (1.00x) | 65 (1.06x) |
| `parse.rgb` | 148 | 47 | 69 | 80 | 47 (1.01x) | 71 (1.03x) | 78 (0.97x) |
| `parse.rgbaPercent` | 281 | 59 | 114 | 104 | 60 (1.01x) | 122 (1.07x) | 102 (0.98x) |
| `parse.hsl` | 222 | 44 | 76 | 70 | 44 (1.00x) | 76 (1.00x) | 71 (1.01x) |
| `parse.invalid` | 114 | 23 | 40 | 36 | 24 (1.03x) | 40 (1.00x) | 36 (1.00x) |
| `parse.mixed` | 176 | 45 | 76 | 72 | 45 (1.01x) | 76 (1.00x) | 72 (1.00x) |
| `rgb.parse` | 179 | 47 | 76 | 66 | 47 (1.01x) | 80 (1.05x) | 66 (1.00x) |
| `format.hex` | 46 | 13 | 17 | 31 | 13 (0.97x) | 16 (0.94x) | 31 (1.02x) |
| `format.hex8` | 57 | 23 | 23 | 39 | 20 (0.85x) | 23 (1.00x) | 40 (1.03x) |
| `format.rgb` | 54 | 25 | 40 | 54 | 25 (1.00x) | 33 (0.83x) | 31 (0.58x) |
| `format.hsl` | 196 | 97 | 107 | 124 | 97 (1.00x) | 105 (0.98x) | 115 (0.92x) |
| `format.rgbOfHsl` | 33 | 35 | 69 | 59 | 31 (0.89x) | 47 (0.68x) | 50 (0.84x) |
| `convert.rgbToHsl` | 20 | 10 | 26 | 9 | 10 (0.97x) | 25 (0.96x) | 9 (1.03x) |
| `convert.hslToRgb` | 17 | 11 | 24 | 18 | 11 (0.98x) | 23 (0.96x) | 18 (0.97x) |
| `convert.rgbToLab` | 88 | 80 | 88 | 64 | 79 (0.99x) | 88 (1.00x) | 64 (1.00x) |
| `convert.labToRgb` | 43 | 37 | 52 | 48 | 37 (1.00x) | 52 (1.00x) | 49 (1.02x) |
| `convert.rgbToHcl` | 129 | 108 | 122 | 115 | 108 (1.00x) | 122 (1.00x) | 115 (1.00x) |
| `convert.hclToRgb` | 73 | 54 | 76 | 74 | 55 (1.01x) | 78 (1.03x) | 75 (1.02x) |
| `convert.rgbToCubehelix` | 43 | 17 | 38 | 9 | 17 (1.00x) | 38 (1.00x) | 9 (1.00x) |
| `convert.cubehelixToRgb` | 38 | 20 | 41 | 33 | 20 (1.00x) | 41 (1.00x) | 32 (0.98x) |
| `op.brighterRgb` | 9 | 6 | 13 | 8 | 6 (1.00x) | 13 (0.98x) | 9 (1.01x) |
| `op.darkerHcl` | 9 | 6 | 13 | 9 | 6 (1.00x) | 13 (1.02x) | 9 (1.01x) |
| `pipe.hclTick` | 171 | 92 | 134 | 120 | 82 (0.90x) | 109 (0.81x) | 108 (0.90x) |
| `pipe.parseHex` | 222 | 61 | 84 | 96 | 61 (1.00x) | 84 (1.00x) | 97 (1.00x) |

## 6. Where the port stands

The Mac, the code of §2 ("base") against the code of §5 ("final"), with the ratio final / base:

| Case | node | aot base | js base | wasm base | aot final | js final | wasm final |
|---|---:|---:|---:|---:|---:|---:|---:|
| `parse.hex6` | 74 | 242 | 153 | 215 | 32 (0.13x) | 28 (0.18x) | 48 (0.22x) |
| `parse.hex3` | 65 | 187 | 111 | 191 | 25 (0.13x) | 25 (0.22x) | 37 (0.19x) |
| `parse.named` | 150 | 386 | 179 | 239 | 42 (0.11x) | 46 (0.26x) | 65 (0.27x) |
| `parse.rgb` | 147 | 569 | 244 | 429 | 47 (0.08x) | 71 (0.29x) | 78 (0.18x) |
| `parse.rgbaPercent` | 280 | 1113 | 412 | 647 | 60 (0.05x) | 122 (0.30x) | 102 (0.16x) |
| `parse.hsl` | 220 | 913 | 336 | 521 | 44 (0.05x) | 76 (0.23x) | 71 (0.14x) |
| `parse.invalid` | 120 | 536 | 160 | 204 | 24 (0.04x) | 40 (0.25x) | 36 (0.18x) |
| `parse.mixed` | 175 | 604 | 267 | 397 | 45 (0.07x) | 76 (0.29x) | 72 (0.18x) |
| `rgb.parse` | 182 | 617 | 275 | 394 | 47 (0.08x) | 80 (0.29x) | 66 (0.17x) |
| `format.hex` | 45 | 164 | 80 | 83 | 13 (0.08x) | 16 (0.20x) | 31 (0.38x) |
| `format.hex8` | 60 | 222 | 99 | 122 | 20 (0.09x) | 23 (0.23x) | 40 (0.33x) |
| `format.rgb` | 54 | 175 | 76 | 146 | 25 (0.14x) | 33 (0.44x) | 31 (0.22x) |
| `format.hsl` | 202 | 401 | 206 | 325 | 97 (0.24x) | 105 (0.51x) | 115 (0.35x) |
| `format.rgbOfHsl` | 33 | 115 | 84 | 133 | 31 (0.27x) | 47 (0.56x) | 50 (0.37x) |
| `convert.rgbToHsl` | 20 | 9 | 26 | 11 | 10 (1.16x) | 25 (0.96x) | 9 (0.84x) |
| `convert.hslToRgb` | 20 | 18 | 29 | 48 | 11 (0.59x) | 23 (0.82x) | 18 (0.37x) |
| `convert.rgbToLab` | 88 | 81 | 88 | 96 | 79 (0.98x) | 88 (1.00x) | 64 (0.67x) |
| `convert.labToRgb` | 43 | 38 | 52 | 59 | 37 (0.96x) | 52 (1.00x) | 49 (0.84x) |
| `convert.rgbToHcl` | 129 | 115 | 122 | 117 | 108 (0.94x) | 122 (1.00x) | 115 (0.98x) |
| `convert.hclToRgb` | 72 | 63 | 78 | 83 | 55 (0.87x) | 78 (1.00x) | 75 (0.91x) |
| `convert.rgbToCubehelix` | 43 | 17 | 38 | 10 | 17 (0.98x) | 38 (1.00x) | 9 (0.91x) |
| `convert.cubehelixToRgb` | 38 | 20 | 40 | 49 | 20 (1.00x) | 41 (1.02x) | 32 (0.65x) |
| `op.brighterRgb` | 9 | 6 | 14 | 9 | 6 (1.01x) | 13 (0.91x) | 9 (1.00x) |
| `op.darkerHcl` | 9 | 6 | 13 | 9 | 6 (0.99x) | 13 (1.02x) | 9 (0.97x) |
| `pipe.hclTick` | 175 | 174 | 141 | 192 | 82 (0.47x) | 109 (0.77x) | 108 (0.56x) |
| `pipe.parseHex` | 221 | 819 | 336 | 471 | 61 (0.07x) | 84 (0.25x) | 97 (0.21x) |

The phones, the same two versions:

| Case | chrome upstream | pixel base | pixel r2 | chrome-js base | chrome-js r2 | chrome-wasm base | chrome-wasm r2 | iphone base | iphone r2 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `parse.hex6` | 112 | 335 | 48 (0.14x) | 200 | 44 (0.22x) | 308 | 56 (0.18x) | 169 | 19 (0.11x) |
| `parse.hex3` | 98 | 271 | 44 (0.16x) | 185 | 39 (0.21x) | 300 | 48 (0.16x) | 140 | 19 (0.14x) |
| `parse.named` | 122 | 662 | 65 (0.10x) | 184 | 53 (0.29x) | 291 | 95 (0.33x) | 295 | 29 (0.10x) |
| `parse.rgb` | 190 | 744 | 71 (0.10x) | 369 | 93 (0.25x) | 700 | 119 (0.17x) | 416 | 34 (0.08x) |
| `parse.rgbaPercent` | 418 | 1502 | 90 (0.06x) | 656 | 160 (0.24x) | 1062 | 166 (0.16x) | 829 | 43 (0.05x) |
| `parse.hsl` | 269 | 1315 | 67 (0.05x) | 482 | 108 (0.22x) | 801 | 112 (0.14x) | 729 | 32 (0.04x) |
| `parse.invalid` | 122 | 836 | 36 (0.04x) | 196 | 51 (0.26x) | 283 | 56 (0.20x) | 413 | 17 (0.04x) |
| `parse.mixed` | 217 | 857 | 66 (0.08x) | 388 | 99 (0.26x) | 610 | 109 (0.18x) | 468 | 31 (0.07x) |
| `rgb.parse` | 226 | 872 | 69 (0.08x) | 395 | 105 (0.27x) | 616 | 107 (0.17x) | 471 | 33 (0.07x) |
| `format.hex` | 73 | 347 | 33 (0.09x) | 85 | 31 (0.36x) | 111 | 57 (0.51x) | 136 | 13 (0.10x) |
| `format.hex8` | 94 | 459 | 41 (0.09x) | 118 | 36 (0.31x) | 183 | 68 (0.37x) | 187 | 18 (0.10x) |
| `format.rgb` | 69 | 274 | 42 (0.15x) | 76 | 48 (0.63x) | 205 | 46 (0.23x) | 143 | 18 (0.12x) |
| `format.hsl` | 197 | 638 | 152 (0.24x) | 220 | 115 (0.52x) | 420 | 156 (0.37x) | 334 | 77 (0.23x) |
| `format.rgbOfHsl` | 46 | 187 | 56 (0.30x) | 101 | 63 (0.62x) | 178 | 69 (0.39x) | 99 | 22 (0.22x) |
| `convert.rgbToHsl` | 35 | 21 | 21 (1.01x) | 34 | 34 (0.99x) | 20 | 17 (0.84x) | 9 | 9 (0.96x) |
| `convert.hslToRgb` | 28 | 33 | 19 (0.58x) | 34 | 32 (0.95x) | 67 | 30 (0.45x) | 19 | 9 (0.47x) |
| `convert.rgbToLab` | 148 | 131 | 129 (0.99x) | 143 | 144 (1.01x) | 168 | 100 (0.59x) | 62 | 58 (0.94x) |
| `convert.labToRgb` | 70 | 68 | 65 (0.96x) | 79 | 79 (1.00x) | 95 | 80 (0.85x) | 32 | 29 (0.92x) |
| `convert.rgbToHcl` | 204 | 172 | 168 (0.97x) | 193 | 185 (0.96x) | 187 | 176 (0.94x) | 107 | 88 (0.82x) |
| `convert.hclToRgb` | 105 | 94 | 87 (0.92x) | 111 | 110 (0.99x) | 118 | 109 (0.92x) | 51 | 42 (0.82x) |
| `convert.rgbToCubehelix` | 74 | 52 | 51 (0.98x) | 68 | 68 (1.00x) | 21 | 19 (0.91x) | 15 | 15 (0.97x) |
| `convert.cubehelixToRgb` | 45 | 37 | 37 (0.99x) | 55 | 54 (0.98x) | 67 | 41 (0.61x) | 20 | 20 (1.01x) |
| `op.brighterRgb` | 19 | 15 | 14 (0.97x) | 22 | 22 (1.00x) | 16 | 16 (1.00x) | 8 | 8 (0.92x) |
| `op.darkerHcl` | 17 | 14 | 14 (0.99x) | 23 | 23 (0.99x) | 16 | 16 (0.98x) | 8 | 8 (1.00x) |
| `pipe.hclTick` | 247 | 257 | 128 (0.50x) | 150 | 146 (0.97x) | 278 | 154 (0.55x) | 154 | 54 (0.35x) |
| `pipe.parseHex` | 278 | 1284 | 93 (0.07x) | 469 | 117 (0.25x) | 731 | 158 (0.22x) | 656 | 47 (0.07x) |

- AOT on the Mac, the Pixel 8a and the iPhone: each parse and format case is 3 to 25 times faster
  than the translation of the upstream lines. Each of them is also faster than upstream d3-color
  in V8 on the same machine, except `format.rgbOfHsl` on the Pixel (56 ns against 46 ns in
  Chrome). The conversions through CIELAB keep `Math.pow`, `atan2`, `sin` and `cos`, and they are
  as fast as upstream or faster.
- dart2js and dart2wasm: each parse case is 1.3 to 3.3 times faster than upstream in the same
  engine. `format.rgbOfHsl` stays slower than upstream: 47 and 50 ns against 33 ns in Node.js,
  63 and 69 ns against 46 ns in Chrome on the Pixel. V8 inlines that upstream case and drops the
  unused string, so the benchmark measures the inlining of V8 there as much as the string work.
- In dart2js, the small conversions (`convert.rgbToHsl`, `convert.hslToRgb`, `convert.labToRgb`,
  `convert.cubehelixToRgb`) are up to 1.4 times slower than upstream. `op.brighterRgb` shows the
  same gap (13 ns against 9 ns in Node.js), so most of it is the cost of a call of a closure of
  the bench in dart2js, not of the conversion.
