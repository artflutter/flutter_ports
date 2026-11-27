# d3-chord port performance

This file records the speed figures of `flutter_d3_chord_port` against upstream `d3-chord` v3.0.1
across Node.js, macOS native AOT, Flutter release builds on macOS, iOS, and Android, desktop
browsers (Chrome, Firefox, Safari), and mobile browsers (Chrome and Firefox on Android). Each
faster form is recorded under row `adapt-chord-fast-forms` in [differences.md](differences.md)
and verified bit-for-bit against literal upstream algorithms and Node.js reference vectors by
`test/port/faster_forms_test.dart` and `test/port/reference_test.dart`.

## 1. Test bed

- Apple M3 Max, macOS 27.0.1 (Build 26A434), on AC power (2026-11-27).
- Flutter `master` (3.51.0-1.0.pre-31, Dart 3.15.0), Node.js v24.22.1 (darwin-arm64).
- iOS 27.2 device (Build 24B119, `ios-arm64`) — Flutter AOT release build.
- Pixel 8a, Android 17 (API 37, Build `CP3A.261005.005`) — Flutter AOT release APK
  (`android-arm64`), Mobile Chrome 157, and Mobile Firefox 160.
- Desktop browsers on macOS: Chrome 157, Firefox 160, Safari 27.0.1.
- Instrument: `tool/bench/d3_chord_bench.dart` and `tool/bench/d3_chord_bench.mjs` run 12
  identical seeded Park-Miller LCG workloads (`ns/op`, median across 9 timed 60 ms batches after
  250 ms warmup, lower is better): undirected `chord` (`4×4` Circos, `16×16`, `32×32`, and fully
  sorted `32×32` with `sortGroups` + `sortSubgroups` + `sortChords`), `chordDirected` (`16×16`
  sparse and `32×32` sorted), `chordTranspose` (`16×16`), SVG path generation (`ribbon.svg_136`,
  `ribbon.padded_136`, `ribbonArrow.svg_180`), and direct zero-allocation `CanvasPath` geometry
  emission (`ribbon.canvas_136`, `ribbonArrow.canvas_180`). Native Flutter release builds also
  measure `ui.ribbon.136` and `ui.ribbonArrow.180` building a reusable native `dart:ui.Path` via
  `UiPathContext` (including `reset()` and `path.getBounds().right`).

## 2. Baseline vs optimized (macOS CLI: Node.js, AOT, dart2js, dart2wasm)

Optimizations applied (row `adapt-chord-fast-forms`):

1. **Unboxed typed-data buffers and slot-free `ChordLayout` (`lib/src/chord.dart`):**
   reuses `Float64List` / `Int32List` scratch buffers (`_flat`, `_groupSums`, `_groupIndex`,
   `_subIdx`, `_subVals`, `_tmpIdx`, `_tmpVals`) across layout calls, eliminates integer division
   and modulo during matrix flattening, replaces per-chord `_ChordSlot` heap wrappers with flat
   `sources`/`targets` arrays, and replaces per-group `Map` tie-break sorts with an unboxed stable
   insertion (`n <= 12`) + iterative bottom-up merge sort (`run = 8`). Cuts `chord.32x32_sorted`
   by **2.24×** on AOT, **4.05×** on dart2js (**5.22× faster than Node.js**), and **3.22×** on
   dart2wasm; cuts `chordDirected.32x32_sorted` by **2.25×** on AOT, **4.64×** on dart2js, and
   **2.89×** on dart2wasm; cuts `chord.4x4` to **285 ns** on dart2wasm (**7.12× faster than
   Node.js**) and **354 ns** on AOT (**5.75× faster than Node.js**).
2. **Zero-closure constant fast paths and reused start-point trig in `RibbonGenerator`
   (`lib/src/ribbon.dart`):** caches unboxed constant radii/angles/headRadius, reads
   `Chord`/`ChordSubgroup` fields directly on the default path without closure indirection, reuses
   start-point `(sx0, sy0)` coordinates across `moveTo` and the closing `quadraticCurveTo`
   (eliminating 2 `sin`/`cos` calls per ribbon), and emits geometry directly into any `CanvasPath`
   or `UiPathContext` via `draw(d, context)` with zero intermediate SVG string allocation.
   `ribbon.canvas_136` runs in **4,076 ns** on AOT (**4.79× faster than Node.js**, **17× faster
   than SVG string formatting**).

On macOS CLI benchmarks, **macOS AOT beats Node.js on 12/12** workloads (up to **5.75× faster**),
**`dart2js` beats Node.js on 12/12** workloads (up to **6.35× faster**), and **`dart2wasm` beats
Node.js on 11/12** workloads (up to **8.23× faster**).

| Case | Node.js | AOT base → opt | AOT / Node | dart2js base → opt | dart2wasm base → opt |
|---|---:|---|---:|---|---|
| `chord.4x4` | 2,032 | 570 → **354** (1.61×) | **0.17×** | 606 → **348** (1.74×) | 511 → **285** (1.79×) |
| `chord.16x16` | 18,860 | 7,035 → **4,812** (1.46×) | **0.26×** | 6,347 → **3,703** (1.71×) | 6,092 → **3,114** (1.96×) |
| `chord.32x32` | 91,649 | 28,393 → **16,920** (1.68×) | **0.18×** | 24,775 → **14,432** (1.72×) | 21,773 → **12,278** (1.77×) |
| `chord.32x32_sorted` | 212,296 | 237,688 → **106,342** (2.24×) | **0.50×** | 164,914 → **40,690** (4.05×) | 398,569 → **123,658** (3.22×) |
| `chordDirected.16x16` | 29,879 | 8,879 → **5,305** (1.67×) | **0.18×** | 8,020 → **5,027** (1.60×) | 6,674 → **3,632** (1.84×) |
| `chordDirected.32x32_sorted` | 439,872 | 505,702 → **224,622** (2.25×) | **0.51×** | 480,956 → **103,712** (4.64×) | 844,278 → **291,874** (2.89×) |
| `chordTranspose.16x16` | 19,422 | 7,031 → **4,282** (1.64×) | **0.22×** | 6,512 → **4,178** (1.56×) | 6,432 → **3,281** (1.96×) |
| `ribbon.svg_136` | 101,616 | 73,641 → **69,500** (1.06×) | **0.68×** | 61,685 → **62,555** (0.99×) | 96,986 → **97,486** (0.99×) |
| `ribbon.padded_136` | 100,566 | 65,733 → **64,207** (1.02×) | **0.64×** | 63,869 → **62,299** (1.03×) | 91,880 → **90,824** (1.01×) |
| `ribbonArrow.svg_180` | 138,370 | 111,931 → **106,020** (1.06×) | **0.77×** | 89,543 → **86,532** (1.03×) | 149,506 → 147,658 (1.01×) |
| `ribbon.canvas_136` | 19,524 | 4,481 → **4,076** (1.10×) | **0.21×** | 7,442 → **7,105** (1.05×) | 7,065 → **6,232** (1.13×) |
| `ribbonArrow.canvas_180` | 31,860 | 8,358 → **8,266** (1.01×) | **0.26×** | 17,868 → **17,729** (1.01×) | 15,119 → **12,853** (1.18×) |

## 3. Native Flutter Release Builds: macOS, iOS & Android (ns/op)

Measured in standalone Flutter `--release` builds (`darwin-arm64`, `ios-arm64`, and `android-arm64`).
`ui.*` measure `UiPathContext` building a reusable native `dart:ui.Path` (including `reset()` and
`path.getBounds().right`), bypassing SVG string formatting completely.

- **iOS 27.2 AOT** beats desktop M3 Max Node.js on **12/12** workloads (up to **8.34× faster**),
  and builds all 136 native `dart:ui.Path` ribbons in **28.0 µs** (**3.63× faster** than Node.js
  SVG output) and 180 arrow ribbons in **31.6 µs** (**4.37× faster** than Node.js SVG output).
- **macOS M3 Max Flutter AOT** beats Node.js on **12/12** workloads (up to **5.37× faster**).
- **Pixel 8a Android 17 AOT** beats desktop M3 Max Node.js on **9/12** workloads (up to **4.06×
  faster**) and builds all 136/180 native `dart:ui.Path` ribbons **1.50×–1.80× faster** than
  desktop M3 Max Node.js SVG formatting.

| Case | macOS M3 Max AOT | iOS 27.2 AOT | Pixel 8a Android AOT |
|---|---:|---:|---:|
| `chord.4x4` | 378 | **244** | 501 |
| `chord.16x16` | 4,557 | **3,246** | 5,974 |
| `chord.32x32` | 17,847 | **13,102** | 24,077 |
| `chord.32x32_sorted` | 111,423 | **92,719** | 167,224 |
| `chordDirected.16x16` | 5,490 | **4,280** | 7,396 |
| `chordDirected.32x32_sorted` | 236,498 | **200,416** | 398,192 |
| `chordTranspose.16x16` | 4,408 | **3,406** | 5,838 |
| `ribbon.svg_136` | 72,406 | **56,722** | 144,581 |
| `ribbon.padded_136` | 66,651 | **52,473** | 134,596 |
| `ribbonArrow.svg_180` | 109,062 | **88,081** | 229,244 |
| `ribbon.canvas_136` | 4,922 | **4,095** | 7,733 |
| `ribbonArrow.canvas_180` | 8,917 | **8,173** | 16,138 |
| **`ui.ribbon.136`** | 41,473 | **28,011** | 67,829 |
| **`ui.ribbonArrow.180`** | 44,861 | **31,630** | 76,728 |

## 4. Desktop & Mobile Browsers (ns/op)

Each cell shows `upstream JS / dart2js / dart2wasm` (fastest highlighted in bold).

- **Desktop Chrome 157:** `dart2js` beats upstream on **12/12**, `dart2wasm` beats upstream on
  **9/12** (up to **8.12× faster**), best Dart target beats upstream on **12/12**.
- **Desktop Firefox 160:** `dart2js` beats upstream on **11/12**, `dart2wasm` beats upstream on
  **7/12** (up to **3.64× faster**), best Dart target beats upstream on **12/12**.
- **Desktop Safari 27.0.1:** `dart2js` beats upstream on **12/12** (up to **5.27× faster**),
  `dart2wasm` beats upstream on **8/12**, best Dart target beats upstream on **12/12**.
- **Mobile Chrome 157 (Pixel 8a):** `dart2js` beats upstream on **12/12**, `dart2wasm` beats
  upstream on **12/12** (up to **11.29× faster**), best Dart target beats upstream on **12/12**.
- **Mobile Firefox 160 (Pixel 8a):** `dart2js` beats upstream on **11/12**, `dart2wasm` beats
  upstream on **7/12**, best Dart target beats upstream on **12/12**.

| Case | Chrome 157 (up / js / wasm) | Firefox 160 (up / js / wasm) | Safari 27.0.1 (up / js / wasm) | Pixel Chrome 157 (up / js / wasm) | Pixel Firefox 160 (up / js / wasm) |
|---|---|---|---|---|---|
| `chord.4x4` | 1,815 / 319 / **229** | 989 / 838 / **390** | 684 / 570 / **310** | 4,403 / 1,405 / **405** | 1,807 / 1,678 / **630** |
| `chord.16x16` | 18,080 / 3,456 / **2,523** | 9,666 / 8,642 / **4,700** | 9,797 / 8,402 / **3,971** | 46,513 / 15,747 / **4,121** | 19,200 / 16,695 / **8,158** |
| `chord.32x32` | 63,351 / 13,555 / **9,916** | 35,735 / 33,408 / **19,520** | 38,343 / 32,633 / **16,704** | 153,827 / 62,259 / **16,471** | 67,669 / 65,266 / **32,626** |
| `chord.32x32_sorted` | 156,989 / **41,695** / 66,488 | 164,063 / **62,245** / 185,410 | 103,691 / **48,996** / 116,279 | 328,192 / **119,581** / 168,571 | 260,870 / **125,000** / 320,856 |
| `chordDirected.16x16` | 25,533 / 4,716 / **3,145** | 13,202 / 12,939 / **5,708** | 12,200 / 11,475 / **4,801** | 57,787 / 21,190 / **5,196** | 25,946 / 21,441 / **11,230** |
| `chordDirected.32x32_sorted` | 410,417 / **95,185** / 140,749 | 370,370 / **315,271** / 396,104 | 281,437 / **97,222** / 273,913 | 737,805 / 519,658 / **411,046** | 614,583 / **539,823** / 709,302 |
| `chordTranspose.16x16` | 16,844 / 3,612 / **3,135** | 8,733 / 9,441 / **5,371** | 9,674 / 8,642 / **4,150** | 45,735 / 15,703 / **8,374** | 17,575 / 17,868 / **8,438** |
| `ribbon.svg_136` | 83,750 / **47,891** / 95,783 | 131,250 / **123,047** / 164,063 | 120,654 / **55,659** / 174,286 | 158,005 / **100,496** / 157,292 | 209,460 / **191,824** / 341,041 |
| `ribbon.padded_136` | 84,767 / **50,956** / 90,717 | 124,473 / **115,163** / 155,779 | 120,388 / **56,285** / 164,063 | 160,743 / **102,734** / 147,070 | 199,324 / **185,714** / 326,316 |
| `ribbonArrow.svg_180` | 119,141 / **70,376** / 148,007 | 209,460 / **191,951** / 250,000 | 174,286 / **86,066** / 248,996 | 274,453 / **176,347** / 239,760 | 342,697 / **299,065** / 535,088 |
| `ribbon.canvas_136` | 17,357 / 6,619 / **4,665** | 21,840 / **5,046** / 6,001 | 14,848 / **2,820** / 8,190 | 32,904 / 16,562 / **8,286** | 39,630 / **9,666** / 11,962 |
| `ribbonArrow.canvas_180` | 28,632 / 12,841 / **11,296** | 32,038 / **9,521** / 11,762 | 21,890 / **5,762** / 18,229 | 51,546 / 31,823 / **20,573** | 61,413 / **17,601** / 23,828 |
