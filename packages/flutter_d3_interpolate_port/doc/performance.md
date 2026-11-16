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
  - `js`: the port, `dart compile js -O4`, run in Node.js.
  - `wasm`: the port, `dart compile wasm -O2`, run in Node.js.
- Each case warms up for 300 ms, then runs 9 batches of about 60 ms. A run gives the median time of
  one operation of the batches. Each figure is the mean of two runs, in nanoseconds for one
  operation. Two runs are a weak interval: read a change below 10% as no change. The `js` timer of
  Node.js counts whole milliseconds, so a `js` figure moves in steps of about 2%.
- `call.*` call an interpolator that exists before the timing, at another `t` for each operation.
  `create.*` make an interpolator and call it once. `text.*` call a color interpolator and write
  the color as CSS text (`toString()` of d3-color), the result of upstream. A color interpolator
  of upstream returns that text, so its `call.*` and `text.*` figures are the same work.
- The number lists have 16 items, the splines 8 values, the palettes 8 colors and the piecewise
  interpolator 4 colors. `call.transform` and `create.transform` time `interpolateTransformCss`
  upstream, with a small `DOMMatrix` of the text `matrix(a, b, c, d, e, f)` (Node.js has none): the
  parse of the text runs only at the creation. The port takes the `TransformParts` of `decompose`.

## 2. Baseline: the translation of the upstream lines (2026-11-16)

The port before any faster form.

| Case | node | aot | js | wasm |
|---|---:|---:|---:|---:|
| `call.number` | 8 | 8 | 5 | 15 |
| `call.round` | 21 | 9 | 17 | 16 |
| `call.hue` | 24 | 14 | 21 | 20 |
| `call.basis` | 20 | 22 | 21 | 55 |
| `call.basisClosed` | 18 | 21 | 24 | 55 |
| `call.discrete` | 13 | 12 | 17 | 21 |
| `call.date` | 25 | 19 | 80 | 30 |
| `call.numberArray` | 36 | 195 | 26 | 526 |
| `call.array` | 71 | 99 | 39 | 219 |
| `call.rgb` | 120 | 23 | 16 | 29 |
| `call.rgbGamma` | 165 | 48 | 44 | 68 |
| `call.rgbBasis` | 132 | 53 | 49 | 142 |
| `call.hsl` | 139 | 23 | 16 | 29 |
| `call.hslLong` | 139 | 23 | 15 | 29 |
| `call.lab` | 155 | 22 | 15 | 28 |
| `call.hcl` | 194 | 21 | 15 | 29 |
| `call.hclLong` | 198 | 21 | 15 | 29 |
| `call.cubehelix` | 169 | 22 | 29 | 42 |
| `call.cubehelixGamma` | 173 | 22 | 29 | 42 |
| `call.piecewise` | 150 | 48 | 27 | 58 |
| `call.zoom` | 41 | 39 | 42 | 52 |
| `call.transform` | 424 | 49 | 35 | 116 |
| `text.rgb` | 119 | 50 | 35 | 53 |
| `text.hsl` | 141 | 64 | 58 | 77 |
| `text.lab` | 154 | 97 | 92 | 103 |
| `text.hcl` | 193 | 115 | 122 | 141 |
| `text.cubehelix` | 170 | 82 | 84 | 105 |
| `create.number` | 13 | 4 | 12 | 13 |
| `create.rgb` | 158 | 75 | 44 | 71 |
| `create.hcl` | 480 | 241 | 206 | 216 |
| `create.valueNumber` | 13 | 13 | 33 | 28 |
| `create.valueColor` | 175 | 79 | 78 | 84 |
| `create.valueArray` | 335 | 394 | 458 | 664 |
| `create.zoom` | 82 | 67 | 72 | 85 |
| `create.transform` | 2328 | 1558 | 80 | 247 |
| `decompose` | 30 | 39 | 48 | 52 |
| `quantize.rgb` | 908 | 202 | 113 | 326 |

The port was slower than upstream on the VM in six cases: `call.numberArray` (5.4 times),
`call.array`, `create.valueArray`, `call.basis`, `call.basisClosed` and `decompose`.
`create.transform` took 1.6 µs on the VM, 20 times its JavaScript figure.

## 3. The faster forms

Each form gives the bits of the upstream lines. `test/port/faster_forms_test.dart` writes out the
upstream lines and compares the bits, also for `t` outside [0, 1].

1. The number lists (`numberArray.js`, row `adapt-interpolate-typed-loops`). The loop read `a[i]`
   and `b[i]` through `List<num>`: on the VM each read takes a dispatch, and each value a box. The
   port has one loop for each pair of a `Float64List` or a `Float32List` b and its a, with the
   static types of the lists. `call.numberArray` on the VM: 195 to 38 ns. The loop reads `a` and
   `b` at each call, as upstream.
2. The lists of numbers (`array.js`, same row). For two `List<double>`, each item interpolator is
   `number(a[i], b[i])`, which keeps its two numbers. The port keeps the pairs in one `Float64List`
   and writes the line of `number.js` in one loop, with no closure for each item. One list of pairs
   is faster than two lists in JavaScript. `create.valueArray`: 394 to 164 ns on the VM, 458 to 290
   ns in JavaScript and 664 to 340 ns in WebAssembly.
3. The transform (`transform/index.js`, same row). The port kept `q` as a list of records
   `({int i, double Function(double t) x})`. On the VM, each `add` tests the type of the record with
   its function field. The port now keeps the two numbers of each item in the fields of one object,
   with one bit for each part, and `s` in the six fields of another object. A typed list of 18
   doubles was 190 ns to make in JavaScript: V8 keeps a typed list of more than 64 bytes outside
   its heap. `create.transform`: 1558 to 29 ns on the VM, 80 to 45 ns in JavaScript and 247 to 54
   ns in WebAssembly. `call.transform`: 49 to 15 ns on the VM.
4. The zoom (`zoom.js`, row `adapt-interpolate-zoom-constants`). The interpolator computes
   `cosh(r0)`, `sinh(r0)`, `w0 / (rho2 * d1)` and `w0 * coshr0` at the creation, not at each call:
   two calls of `exp` for each call in place of four. `call.zoom`: 39 to 28 ns on the VM. The
   creation takes about 15 ns more (25 ns in JavaScript). A zoom transition calls its interpolator
   at each frame, so the sum is lower after two calls.
5. The splines (`basis.js`, `basisClosed.js`). `interpolateBasis` has the same lines for a
   `Float64List` with its static type, and the RGB splines keep their channels in `Float64List`s:
   `call.rgbBasis` 53 to 36 ns on the VM. The closed spline skips the `remainder` call (`fmod` on
   the VM) for `t` in (-1, 1), where the remainder is `t`: `call.basisClosed` 21 to 19 ns. Both use
   `toInt()` for `Math.floor` of a value that is not negative. `%` of an int was slower than
   `remainder` with dart2js (a helper call), so the port keeps `remainder`.

## 4. Result (2026-11-16)

| Case | node | aot | js | wasm |
|---|---:|---:|---:|---:|
| `call.number` | 8 | 8 | 5 | 15 |
| `call.round` | 21 | 9 | 17 | 16 |
| `call.hue` | 24 | 14 | 21 | 20 |
| `call.basis` | 20 | 22 | 21 | 54 |
| `call.basisClosed` | 18 | 19 | 22 | 51 |
| `call.discrete` | 13 | 12 | 16 | 22 |
| `call.date` | 25 | 19 | 84 | 30 |
| `call.numberArray` | 36 | 38 | 27 | 253 |
| `call.array` | 71 | 61 | 27 | 173 |
| `call.rgb` | 120 | 24 | 15 | 28 |
| `call.rgbGamma` | 165 | 49 | 44 | 69 |
| `call.rgbBasis` | 132 | 36 | 46 | 155 |
| `call.hsl` | 139 | 23 | 15 | 28 |
| `call.hslLong` | 139 | 23 | 16 | 28 |
| `call.lab` | 155 | 22 | 15 | 28 |
| `call.hcl` | 194 | 22 | 15 | 28 |
| `call.hclLong` | 198 | 22 | 15 | 29 |
| `call.cubehelix` | 169 | 23 | 29 | 42 |
| `call.cubehelixGamma` | 173 | 23 | 29 | 42 |
| `call.piecewise` | 150 | 51 | 27 | 59 |
| `call.zoom` | 41 | 28 | 38 | 41 |
| `call.transform` | 424 | 15 | 22 | 28 |
| `text.rgb` | 119 | 51 | 35 | 54 |
| `text.hsl` | 141 | 63 | 58 | 74 |
| `text.lab` | 154 | 97 | 88 | 102 |
| `text.hcl` | 193 | 118 | 122 | 140 |
| `text.cubehelix` | 170 | 82 | 84 | 104 |
| `create.number` | 13 | 4 | 12 | 13 |
| `create.rgb` | 158 | 77 | 45 | 70 |
| `create.hcl` | 480 | 244 | 206 | 211 |
| `create.valueNumber` | 13 | 13 | 27 | 28 |
| `create.valueColor` | 175 | 81 | 76 | 84 |
| `create.valueArray` | 335 | 164 | 290 | 340 |
| `create.zoom` | 82 | 82 | 101 | 91 |
| `create.transform` | 2328 | 29 | 45 | 54 |
| `decompose` | 30 | 40 | 47 | 51 |
| `quantize.rgb` | 908 | 205 | 113 | 263 |

On the VM, the port is more than 10% faster than upstream in 29 of the 37 cases. Seven cases are
within 10% (`call.number`, `call.basis`, `call.basisClosed`, `call.discrete`, `call.numberArray`,
`create.valueNumber` and `create.zoom`), and `decompose` is slower. The color interpolators are 5
to 9 times faster on the VM: they return a d3-color color, not a CSS text. With the text
(`text.*`), they are 1.6 to 2.3 times faster.

## 5. Open items

- `decompose`: 40 ns on the VM against 30 ns in Node.js. `atan2` and `atan` of `dart:math` are
  calls into the C library on the VM. D3 ADR 0007 keeps `dart:math` as it is.
- `call.basis` and `call.basisClosed` read a growable `List<double>` at each call, as upstream: each
  read on the VM unboxes a double. A `Float64List` of values takes the typed path.
- WebAssembly: a read or a write of a typed list is a dispatch over the classes of `Float64List`
  in dart2wasm, so `call.numberArray` stays at 253 ns (16 items). The typed RGB channels are about
  10% slower there than a `List<double>` (155 against 142 ns), and 32% faster on the VM. The VM
  gain is larger, so the port keeps them.
- `call.date` in JavaScript: 84 ns against 25 ns in Node.js. The `DateTime` of dart2js checks its
  range at each creation. Upstream writes one `Date` again.
- `text.*`: the CSS text of d3-color is the larger part of the time. Its speed belongs to
  `flutter_d3_color_port`.
