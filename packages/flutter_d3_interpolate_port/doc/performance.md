# d3-interpolate port performance

This file has the speed figures of the d3-interpolate port against upstream d3-interpolate in
Node.js. Each form of the port that is faster than the translation of the upstream lines has a row
in [differences.md](differences.md).

## 1. Test bed

- Apple M3 Max, macOS 27.0.1, on AC power, at night (2026-11-16). Other sessions ran on the machine:
  the load average was between 2 and 4.
- Dart 3.14.0-315.3.beta (Flutter 3.50.0-0.4.pre, the pin of `.fvmrc`). Node.js v24.22.1
  (arm64, V8 13.6.233.17-node.58).
- The instrument is `tool/bench/`: `d3_interpolate_bench.dart` (the port) and
  `d3_interpolate_bench.mjs` (upstream `third_party/d3-interpolate/src` at `v3.0.1`, with
  `third_party/d3-color/src`) have the same 37 cases on the same input pools of 1,024 items from a
  fixed seed. `run_bench.sh` runs the targets:
  - `node`: upstream d3-interpolate in Node.js, the reference speed.
  - `aot`: the port, `dart compile exe`.
  - `js`: the port, `dart compile js -O4`, run in Node.js. The runner gives dart2js
    `window.performance`, so its timer counts microseconds.
  - `wasm`: the port, `dart compile wasm -O2`, run in Node.js.
- "base" is the port before the faster forms (commit `19721cef`), and "final" the port with them.
  Both ran the same benchmark file on the library sources of their commit, in the same build
  steps as `run_bench.sh`.
- Each case warms up for 300 ms: the count of operations of a batch doubles until a batch takes 15
  ms. Then 9 batches of 15 to 30 ms run. A run gives the median time of one operation of the
  batches. Each figure is the mean of two full runs, in nanoseconds for one operation. Two runs are
  a weak interval: read a change below 10% as no change. A run of one case with `--filter` is not
  comparable with a full run on V8: the JIT of a case alone differs.
- `call.*` call an interpolator that exists before the timing, at another `t` for each operation.
  `create.*` make an interpolator and call it once; the interpolator of `create.number` escapes to
  a variable, so that no compiler removes its creation. `text.*` call a color interpolator and
  write the color as CSS text (`toString()` of d3-color), the result of upstream. A color
  interpolator of upstream returns that text, so its `call.*` and `text.*` figures are the same
  work, and each upstream color case writes a text.
- The number lists have 16 items, the splines 8 values, the palettes 8 colors and the piecewise
  interpolator 4 colors. `decompose` reads its six numbers from one typed array on both sides.
- `call.transform` and `create.transform` are not the same work on the two sides. Upstream
  `interpolateTransformCss` parses and decomposes two texts `matrix(a, b, c, d, e, f)` at the
  creation (with a small `DOMMatrix` of the benchmark, because Node.js has none), and returns a CSS
  text at each call. The port takes and returns `TransformParts`.

## 2. Baseline: the translation of the upstream lines

| Case | node | aot | js | wasm |
|---|---:|---:|---:|---:|
| `call.number` | 7.9 | 7.7 | 4.6 | 15 |
| `call.round` | 20 | 8.8 | 16 | 16 |
| `call.hue` | 24 | 13 | 21 | 20 |
| `call.basis` | 20 | 21 | 20 | 54 |
| `call.basisClosed` | 18 | 21 | 23 | 52 |
| `call.discrete` | 12 | 11 | 16 | 21 |
| `call.date` | 24 | 18 | 78 | 29 |
| `call.numberArray` | 34 | 184 | 25 | 509 |
| `call.array` | 64 | 93 | 36 | 204 |
| `call.rgb` | 112 | 21 | 15 | 28 |
| `call.rgbGamma` | 155 | 45 | 42 | 66 |
| `call.rgbBasis` | 123 | 49 | 49 | 131 |
| `call.hsl` | 134 | 20 | 15 | 28 |
| `call.hslLong` | 130 | 21 | 15 | 28 |
| `call.lab` | 148 | 20 | 14 | 28 |
| `call.hcl` | 181 | 20 | 15 | 28 |
| `call.hclLong` | 189 | 20 | 14 | 28 |
| `call.cubehelix` | 159 | 19 | 27 | 39 |
| `call.cubehelixGamma` | 162 | 19 | 27 | 39 |
| `call.piecewise` | 139 | 45 | 25 | 52 |
| `call.zoom` | 41 | 38 | 40 | 50 |
| `call.transform` | 395 | 46 | 33 | 109 |
| `text.rgb` | 112 | 47 | 33 | 51 |
| `text.hsl` | 131 | 60 | 54 | 68 |
| `text.lab` | 148 | 93 | 86 | 97 |
| `text.hcl` | 180 | 111 | 119 | 134 |
| `text.cubehelix` | 158 | 79 | 81 | 98 |
| `create.number` | 14 | 3.5 | 11 | 11 |
| `create.rgb` | 141 | 70 | 40 | 68 |
| `create.hcl` | 452 | 227 | 194 | 202 |
| `create.valueNumber` | 12 | 13 | 30 | 27 |
| `create.valueColor` | 164 | 74 | 72 | 75 |
| `create.valueArray` | 305 | 359 | 420 | 611 |
| `create.zoom` | 77 | 65 | 68 | 77 |
| `create.transform` | 2070 | 1468 | 161 | 224 |
| `decompose` | 26 | 21 | 40 | 22 |
| `quantize.rgb` | 852 | 185 | 103 | 301 |

On the VM, the base port was slower than upstream in four cases: `call.numberArray` (5.4 times),
`call.array` (46%), `create.valueArray` (18%) and `call.basisClosed` (14%). `create.transform`
took 1.5 µs on the VM, 9 times its dart2js figure.

## 3. The faster forms

Each form gives the bits of the upstream lines. `test/port/faster_forms_test.dart` writes out the
upstream lines and compares the bits, also for NaN, -0.0, infinities and `t` outside [0, 1]. The
figures are base to final, from sections 2 and 4. The rejected forms come from single runs of
their cases during the work.

1. The number lists (`numberArray.js`, row `adapt-interpolate-typed-loops`). The loop read `a[i]`
   and `b[i]` through `List<num>`: on the VM each read takes a dispatch, and each value a box. The
   port has one loop for each pair of a `Float64List` or a `Float32List` b and its a, with the
   static types of the lists. `call.numberArray`: 184 to 35 ns on the VM and 509 to 239 ns in
   WebAssembly. The loop reads `a` and `b` at each call, as upstream.
2. The lists of numbers (`array.js`, same row). For two `List<double>`, each item interpolator is
   `number(a[i], b[i])`, which keeps its two numbers. The port keeps the pairs in one `Float64List`
   and writes the line of `number.js` in one loop, with no closure for each item.
   `create.valueArray`: 360 to 154 ns on the VM, 420 to 236 ns with dart2js and 611 to 316 ns in
   WebAssembly. `call.array`: 93 to 57 ns on the VM. Rejected: two typed lists (one for each side)
   were slower to make with dart2js, and `List.of` with `take` was slower on each target.
3. The transform (`transform/index.js`, same row). The port kept `q` as a list of records
   `({int i, double Function(double t) x})`. On the VM, each `add` tests the type of the record with
   its function field. The port now keeps the two numbers of each item in the fields of a `_Steps`
   object, with one bit for each part, and `s` in the six fields of a `_Parts` object.
   `create.transform`: 1468 to 27 ns on the VM, 161 to 42 ns with dart2js and 224 to 52 ns in
   WebAssembly. `call.transform`: 46 to 14 ns on the VM. Rejected: one typed list of 18 doubles
   took about 190 ns to make with dart2js, because V8 keeps a typed list of more than 64 bytes
   outside its heap.
4. The zoom (`zoom.js`, row `adapt-interpolate-zoom-constants`). The interpolator computes
   `cosh(r0)`, `sinh(r0)`, `w0 / (rho2 * d1)` and `w0 * coshr0` at the creation, not at each call:
   two calls of `exp` for each call in place of four. `call.zoom`: 38 to 27 ns on the VM, 40 to 37
   ns with dart2js and 50 to 42 ns in WebAssembly. The creation takes 16 ns more on the VM, 31 ns
   with dart2js and 11 ns in WebAssembly. A zoom transition calls its interpolator at each frame:
   the sum is lower after about 2 calls on the VM and in WebAssembly, and after about 13 calls with
   dart2js (a transition of 250 ms has 15 frames at 60 Hz).
5. The splines (`basis.js`, `basisClosed.js`, row `adapt-interpolate-typed-loops`).
   `interpolateBasis` has the same lines for a `Float64List` with its static type, and the RGB
   splines keep their channels in `Float64List`s: `call.rgbBasis` 49 to 32 ns on the VM, but 49 to
   53 ns with dart2js and 131 to 149 ns in WebAssembly. The closed spline skips the `remainder` call
   (`fmod` on the VM) for `t` in (-1, 1), where the remainder is `t`: `call.basisClosed` 21 to 18 ns
   on the VM and 23 to 20 ns with dart2js. Rejected: `%` of an int in place of `remainder` was
   slower with dart2js, where `%` is a helper call.
6. The channels of a color (`color.js`, row `adapt-interpolate-channel-objects`). `nogamma`,
   `hue` and `gamma` returned a closure for each channel (`linear`, `exponential` or `constant`),
   so each call of a color interpolator made four indirect calls. They now return a `Channel`, one
   final class with `call(t)`: a direct call that the compilers inline. `call.rgb`: 21 to 13 ns on
   the VM and 28 to 16 ns in WebAssembly. `create.rgb`: 70 to 56 ns on the VM and 68 to 39 ns in
   WebAssembly. With dart2js a color call is 3 to 16% slower (`call.rgb` 15 to 17 ns), and
   `create.rgb` 29% slower (40 to 52 ns): V8 inlines the closures well. The gains on the VM and in
   WebAssembly are larger, so the port keeps the class.

## 4. Result (2026-11-16)

| Case | node | aot | js | wasm |
|---|---:|---:|---:|---:|
| `call.number` | 7.9 | 7.5 | 4.7 | 15 |
| `call.round` | 20 | 8.7 | 17 | 16 |
| `call.hue` | 24 | 9.9 | 21 | 17 |
| `call.basis` | 20 | 21 | 20 | 54 |
| `call.basisClosed` | 18 | 18 | 20 | 52 |
| `call.discrete` | 12 | 11 | 16 | 21 |
| `call.date` | 24 | 18 | 80 | 29 |
| `call.numberArray` | 34 | 34 | 25 | 239 |
| `call.array` | 64 | 57 | 26 | 166 |
| `call.rgb` | 112 | 13 | 17 | 16 |
| `call.rgbGamma` | 155 | 37 | 43 | 43 |
| `call.rgbBasis` | 123 | 32 | 53 | 148 |
| `call.hsl` | 134 | 13 | 16 | 16 |
| `call.hslLong` | 130 | 13 | 16 | 16 |
| `call.lab` | 148 | 13 | 16 | 17 |
| `call.hcl` | 181 | 13 | 16 | 16 |
| `call.hclLong` | 189 | 13 | 16 | 16 |
| `call.cubehelix` | 159 | 14 | 28 | 28 |
| `call.cubehelixGamma` | 162 | 14 | 29 | 28 |
| `call.piecewise` | 139 | 26 | 28 | 37 |
| `call.zoom` | 41 | 27 | 37 | 42 |
| `call.transform` | 395 | 14 | 21 | 27 |
| `text.rgb` | 112 | 40 | 34 | 39 |
| `text.hsl` | 131 | 55 | 60 | 58 |
| `text.lab` | 148 | 86 | 89 | 86 |
| `text.hcl` | 180 | 108 | 118 | 116 |
| `text.cubehelix` | 158 | 76 | 83 | 86 |
| `create.number` | 14 | 3.6 | 11 | 11 |
| `create.rgb` | 141 | 55 | 52 | 39 |
| `create.hcl` | 452 | 219 | 216 | 177 |
| `create.valueNumber` | 12 | 13 | 27 | 28 |
| `create.valueColor` | 164 | 60 | 82 | 54 |
| `create.valueArray` | 305 | 154 | 235 | 316 |
| `create.zoom` | 77 | 81 | 99 | 88 |
| `create.transform` | 2070 | 27 | 42 | 52 |
| `decompose` | 26 | 22 | 41 | 22 |
| `quantize.rgb` | 852 | 139 | 112 | 105 |

On the VM, the port is more than 10% faster than upstream in 30 of the 37 cases, and within 10%
in the other seven (`call.number`, `call.basis`, `call.basisClosed`, `call.discrete`,
`call.numberArray`, `create.valueNumber` and `create.zoom`). The color interpolators without a
gamma are 8 to 14 times faster on the VM, and the RGB gamma, the RGB spline and the piecewise
interpolator 4 to 5 times: they return a d3-color color, not a CSS text. With the text
(`text.*`), they are 1.7 to 2.8 times faster.

## 5. Phones (2026-11-16)

- Pixel 8a, Android 17, on AC power, with the screen on. "AOT" is a release build of a Flutter app
  (`flutter build apk --release`) that runs `d3_interpolate_bench.dart` with the sources of the
  package. Chrome 157 on the same Pixel runs upstream d3-interpolate ("upstream in Chrome") and the
  dart2js and dart2wasm builds of the benchmark.
- iPhone 17 Pro, iOS 27.2, a release build of the same app (`flutter build ios --release`).
- "base" is the port before the faster forms (commit `19721cef`). The other columns are the port
  with them. Each build ran two times, and the dart2js builds three times, in turn with the other
  builds. A phone does background work, so each figure is the lower result of the runs, in
  nanoseconds for one operation.

| Case | Pixel, upstream in Chrome | Pixel AOT base | Pixel AOT | Pixel dart2js base | Pixel dart2js | Pixel dart2wasm base | Pixel dart2wasm | iPhone AOT base | iPhone AOT |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `call.number` | 15 | 14 | 15 | 9 | 15 | 21 | 21 | 7 | 7 |
| `call.round` | 22 | 17 | 18 | 21 | 22 | 23 | 23 | 9 | 9 |
| `call.hue` | 30 | 24 | 19 | 21 | 27 | 26 | 24 | 13 | 11 |
| `call.basis` | 30 | 40 | 41 | 31 | 30 | 68 | 68 | 19 | 19 |
| `call.basisClosed` | 32 | 43 | 42 | 39 | 35 | 68 | 70 | 20 | 19 |
| `call.discrete` | 22 | 21 | 21 | 27 | 27 | 31 | 31 | 12 | 12 |
| `call.date` | 80 | 94 | 95 | 58 | 59 | 48 | 48 | 18 | 20 |
| `call.numberArray` | 64 | 356 | 63 | 41 | 42 | 336 | 157 | 244 | 36 |
| `call.array` | 97 | 195 | 123 | 53 | 43 | 632 | 423 | 92 | 64 |
| `call.rgb` | 173 | 43 | 26 | 27 | 30 | 41 | 24 | 22 | 13 |
| `call.rgbGamma` | 235 | 80 | 68 | 74 | 77 | 92 | 69 | 40 | 31 |
| `call.rgbBasis` | 199 | 93 | 63 | 71 | 71 | 167 | 154 | 46 | 33 |
| `call.hsl` | 195 | 44 | 26 | 28 | 29 | 39 | 24 | 22 | 13 |
| `call.hslLong` | 198 | 44 | 26 | 27 | 29 | 39 | 24 | 22 | 13 |
| `call.lab` | 237 | 45 | 26 | 26 | 29 | 33 | 24 | 22 | 14 |
| `call.hcl` | 276 | 45 | 26 | 27 | 29 | 32 | 24 | 22 | 14 |
| `call.hclLong` | 279 | 44 | 25 | 27 | 29 | 32 | 23 | 23 | 13 |
| `call.cubehelix` | 227 | 46 | 27 | 46 | 48 | 49 | 40 | 25 | 14 |
| `call.cubehelixGamma` | 235 | 46 | 27 | 46 | 49 | 48 | 39 | 25 | 14 |
| `call.piecewise` | 209 | 74 | 46 | 41 | 43 | 73 | 56 | 48 | 25 |
| `call.zoom` | 64 | 51 | 42 | 63 | 57 | 78 | 62 | 30 | 28 |
| `call.transform` | 513 | 86 | 31 | 43 | 36 | 172 | 44 | 46 | 15 |
| `text.rgb` | 175 | 77 | 64 | 39 | 53 | 76 | 60 | 47 | 39 |
| `text.hsl` | 219 | 91 | 81 | 73 | 78 | 101 | 78 | 51 | 49 |
| `text.lab` | 243 | 153 | 142 | 132 | 136 | 153 | 138 | 81 | 74 |
| `text.hcl` | 285 | 166 | 155 | 163 | 172 | 192 | 179 | 93 | 92 |
| `text.cubehelix` | 236 | 112 | 103 | 113 | 116 | 145 | 125 | 68 | 63 |
| `create.number` | 26 | 7 | 7 | 22 | 22 | 20 | 19 | 4 | 4 |
| `create.rgb` | 225 | 150 | 109 | 69 | 90 | 98 | 62 | 94 | 71 |
| `create.hcl` | 696 | 353 | 324 | 307 | 339 | 301 | 278 | 222 | 206 |
| `create.valueNumber` | 30 | 27 | 26 | 56 | 51 | 43 | 46 | 17 | 16 |
| `create.valueColor` | 279 | 160 | 118 | 146 | 160 | 118 | 88 | 96 | 73 |
| `create.valueArray` | 577 | 624 | 305 | 858 | 800 | 827 | 409 | 352 | 153 |
| `create.zoom` | 106 | 94 | 111 | 101 | 138 | 115 | 117 | 61 | 65 |
| `create.transform` | 3613 | 3734 | 57 | 134 | 70 | 304 | 80 | 1299 | 33 |
| `decompose` | 80 | 54 | 54 | 62 | 62 | 38 | 38 | 20 | 21 |
| `quantize.rgb` | 1233 | 359 | 261 | 188 | 205 | 333 | 185 | 217 | 151 |

- On both phones, the AOT figures follow the Mac: `create.transform` is 65 times faster on the
  Pixel (3734 to 57 ns) and 39 times on the iPhone, `call.numberArray` 5.7 and 6.8 times, and a
  color call 36 to 44% faster.
- With the faster forms, the AOT port on the Pixel is faster than upstream in Chrome on the same
  phone in each case except `call.number` (equal), `call.basis`, `call.basisClosed`,
  `call.date`, `call.array` and `create.zoom`. The color interpolators are 7 to 11 times faster.
- In Chrome on the Pixel, dart2wasm gains as on the Mac: the RGB, HSL, Lab and HCL calls take 23
  to 24 ns, from 32 to 41 ns. dart2js loses where the Mac showed it: `create.rgb` 69 to 90 ns,
  `text.rgb` 39 to 53 ns and `create.zoom` 101 to 138 ns.
- Chrome on the Pixel moves some cases between two speeds inside one run: in each run, the batches
  of dart2js `call.number` go from 9 to 18 ns, and a run of the base `create.transform` took 134
  ns where the two others took 760 and 833 ns. Read a dart2js difference below 2 times on the
  Pixel as no finding.

## 6. Open items

- dart2js: the `Channel` objects of the colors are 3 to 29% slower than the closures (item 6),
  and the zoom creation is 46% slower (item 4).
- WebAssembly: a read or a write of a typed list is a dispatch over the classes of `Float64List`
  in dart2wasm, so `call.numberArray` stays at 239 ns (16 items). The typed RGB channels are 14%
  slower there than a `List<double>` (149 against 131 ns), and 36% faster on the VM. The VM gain
  is larger, so the port keeps them.
- `call.basis` reads a growable `List<double>` at each call, as upstream reads its array: on the
  VM each read unboxes a double. A `Float64List` of values takes the typed path.
- `call.date` with dart2js: 80 ns against 24 ns in Node.js. The `DateTime` of dart2js checks its
  range at each creation. Upstream writes one `Date` again.
- `text.*`: the CSS text of d3-color is the larger part of the time. Its speed belongs to
  `flutter_d3_color_port`.
