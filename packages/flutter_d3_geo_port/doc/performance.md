# d3-geo port performance

This file records the speed figures of `flutter_d3_geo_port` against upstream `d3-geo` v3.1.1
across Node.js, macOS native AOT, Flutter release builds on macOS and Android, desktop browsers
(Chrome, Firefox, Safari), and mobile browsers (Chrome and Firefox on Android). Each faster form is
recorded under row `adapt-geo-fast-forms` in [differences.md](differences.md) and verified against
literal upstream algorithms and Node.js reference vectors by `test/port/faster_forms_test.dart` and
`test/port/reference_test.dart`.

## 1. Test bed

- Apple M3 Max, macOS 27.0.1 (Build 26A434), on AC power (2026-11-27).
- Flutter `master` (3.51.0-1.0.pre-31, Dart 3.15.0), Node.js v24.22.1 (darwin-arm64).
- Pixel 8a, Android 17 (API 37) — Flutter AOT release APK (`android-arm64`), Mobile Chrome 158,
  and Mobile Firefox 160.
- Physical iOS device was offline/unavailable during this benchmark run (iOS Simulator only runs
  JIT debug builds, so no fabricated iOS release numbers are reported).
- Desktop browsers on macOS: Chrome 157, Firefox 160, Safari 27.0.1.
- Instrument: `tool/bench/d3_geo_bench.dart` and `tool/bench/d3_geo_bench.mjs` run 12 identical
  seeded Park-Miller LCG workloads (`ns/op`, median across 9 timed 60 ms batches after 250 ms
  warmup, lower is better):
  - Point projection (`1,000` points): `project.orthographic_1k`, `project.mercator_1k`,
    `project.equalEarth_1k` (forward + inverse), `project.naturalEarth1_1k` (forward + inverse),
    and `project.albersUsa_1k` (Lower 48 / Alaska / Hawaii / out-of-bounds mix).
  - Full stream + clip + adaptive resample + path emission on 20 synthetic landmass polygons
    (1,220 vertices) + `geoGraticule10()`: `path.ortho_canvas`, `path.mercator_canvas`,
    `path.equalEarth_canvas`, and `path.naturalEarth1_svg` (SVG path string).
  - Spherical geometry: `geoArea.world`, `geoBounds.world`, and `geoContains.500` (500 points
    against a 240-vertex spherical polygon with hole).
  - Native Flutter `--release` builds also measure `ui.ortho_world` and `ui.naturalEarth1_world`,
    drawing `worldPolys` + `graticule` straight into a reusable native `dart:ui.Path` via
    `UiPathContext` (including `path.reset()` and `path.getBounds().right`).

## 2. Baseline vs optimized (macOS CLI: Node.js, AOT, dart2js, dart2wasm)

Optimizations applied (row `adapt-geo-fast-forms`):

1. **Fused unboxed projection, rotation & adaptive resampling (`lib/src/projection/index.dart`,
   `lib/src/projection/resample.dart`, `lib/src/rotation.dart`,
   `lib/src/projection/conicEqualArea.dart`):** fuses degree-to-radian conversion and spherical
   rotation into a single `_TransformRadiansRotateStream`, fuses raw projection + affine
   scale/translate/rotate into `geoResampleAffine` with specialized unboxed `double` math for
   `geoOrthographicRaw`, `geoMercatorRaw`, `geoEqualEarthRaw`, `geoNaturalEarth1Raw`, and
   `GeoConicEqualAreaRaw`, reuses `cos(phi)`/`sin(phi)`/`sin(lambda)` across Cartesian coordinates
   and orthographic projection, and eliminates intermediate `(double, double)` record allocations
   in `GeoProjection.call` and `geoRotateRadians`. Cuts `project.mercator_1k` by **2.22×** on AOT
   (**5.61× faster than Node.js**) and **2.09×** on dart2wasm.
2. **Direct clipped point projection in `GeoAlbersUsaProjection` (`lib/src/projection/albersUsa.dart`):**
   replaces per-point 5-stage stream pipeline dispatch across Lower 48, Alaska, and Hawaii with
   unboxed `GeoProjection.projectClipped`, allocating zero records on a region miss. Cuts
   `project.albersUsa_1k` by **1.70×** on AOT (**2.89× faster than Node.js**), **1.67×** on
   dart2js, and **3.02×** on dart2wasm.
3. **Zero-allocation spherical & planar clipping (`lib/src/clip/circle.dart`,
   `lib/src/clip/index.dart`, `lib/src/clip/rectangle.dart`):** unboxes previous-point state and
   3D Cartesian circle-intersection math in `_ClipCircleLine`, buffers polygon rings in reusable
   flat `Float64List` arrays inside `_ClipStream` and `_ClipRectangleStream` with
   `geoPolygonContainsFlat`, and reuses scratch `GeoClipPoint` endpoints in Liang-Barsky segment
   clipping.
4. **Unboxed spherical calculators (`lib/src/area.dart`, `lib/src/bounds.dart`,
   `lib/src/contains.dart`, `lib/src/polygonContains.dart`, `lib/src/distance.dart`):** replaces
   per-polygon `Adder` allocations with reusable 32-slot Shewchuk `Float64List` accumulators,
   walks GeoJSON polygon rings directly in `geoArea`, unboxes all 6 Cartesian vector tuples per
   vertex in `geoBounds` (deferring `sqrt`/`asin` until an inflection longitude falls inside the
   edge), evaluates `geoContains` directly over degree rings via `geoPolygonContainsDegrees`
   without allocating radian copies, and computes `geoDistance` directly via unboxed Vincenty math.
5. **Direct ASCII byte emitter in `GeoPathString` & cached `GeoPath.draw` sink
   (`lib/src/path/string.dart`, `lib/src/path/index.dart`):** formats rounded SVG coordinates
   (`0 <= digits <= 6`, `|q| < 1e15`) directly into a reusable `Uint8List` with two-digit ASCII
   lookup tables on native AOT and Wasm (bypassing `double.toString()`), and caches the
   `GeoPathContext` wrapper in `GeoPath.draw(object, target)` so repeated frames hit
   `GeoProjection`'s stream cache. Cuts `path.naturalEarth1_svg` by **3.16×** on AOT (**2.95×
   faster than Node.js**) and **2.34×** on dart2wasm (**2.08× faster than Node.js**).

On macOS CLI benchmarks, **macOS AOT beats Node.js on 12/12** workloads (up to **5.61× faster**),
**`dart2js` beats Node.js on 12/12** workloads (up to **2.49× faster**), and **`dart2wasm` beats
Node.js on 11/12** workloads (up to **2.46× faster**, with `project.equalEarth_1k` at parity).

| Case | Node.js | AOT base → opt | AOT / Node | dart2js base → opt | dart2wasm base → opt |
|---|---:|---|---:|---|---|
| `project.orthographic_1k` | 132,234 | 68,881 → **47,437** (1.45×) | **0.36×** | 125,672 → **79,365** (1.58×) | 111,191 → **74,003** (1.50×) |
| `project.mercator_1k` | 76,318 | 30,120 → **13,593** (2.22×) | **0.18×** | 67,335 → **40,610** (1.66×) | 64,995 → **31,048** (2.09×) |
| `project.equalEarth_1k` | 188,286 | 125,917 → **109,937** (1.15×) | **0.58×** | 169,620 → **148,546** (1.14×) | 206,118 → 189,893 (1.09×) |
| `project.naturalEarth1_1k` | 123,976 | 79,282 → **64,463** (1.23×) | **0.52×** | 119,902 → **88,462** (1.36×) | 146,431 → **112,513** (1.30×) |
| `project.albersUsa_1k` | 92,569 | 54,538 → **32,027** (1.70×) | **0.35×** | 77,856 → **46,499** (1.67×) | 117,394 → **38,823** (3.02×) |
| `path.ortho_canvas` | 854,658 | 545,630 → **428,970** (1.27×) | **0.50×** | 793,109 → **590,619** (1.34×) | 820,103 → **565,500** (1.45×) |
| `path.mercator_canvas` | 1,207,688 | 603,226 → **516,105** (1.17×) | **0.43×** | 1,004,609 → **835,515** (1.20×) | 995,194 → **750,976** (1.33×) |
| `path.naturalEarth1_svg` | 527,720 | 564,762 → **178,945** (3.16×) | **0.34×** | 471,504 → **388,128** (1.21×) | 594,031 → **253,538** (2.34×) |
| `path.equalEarth_canvas` | 1,151,208 | 655,860 → **554,056** (1.18×) | **0.48×** | 987,377 → **864,652** (1.14×) | 929,875 → **781,250** (1.19×) |
| `geoArea.world` | 78,670 | 48,617 → **42,763** (1.14×) | **0.54×** | 51,092 → **45,468** (1.12×) | 51,514 → **49,412** (1.04×) |
| `geoBounds.world` | 227,412 | 116,504 → **88,397** (1.32×) | **0.39×** | 164,315 → **149,769** (1.10×) | 156,446 → **123,061** (1.27×) |
| `geoContains.500` | 11,301,813 | 4,859,308 → **3,998,313** (1.22×) | **0.35×** | 5,214,625 → **4,544,111** (1.15×) | 6,684,444 → **5,322,286** (1.26×) |

## 3. Native Flutter Release Builds: macOS & Android (ns/op)

Measured in standalone Flutter `--release` builds (`darwin-arm64` and `android-arm64`). `ui.*`
measure `UiPathContext` building a reusable native `dart:ui.Path` for both `worldPolys` (20
polygons, 1,220 vertices) and `geoGraticule10()` (including `path.reset()` and
`path.getBounds().right`), bypassing SVG string formatting completely.

- **macOS M3 Max Flutter AOT** beats Node.js on **12/12** workloads (up to **5.42× faster**), and
  builds a complete native `dart:ui.Path` world + graticule in **548.6 µs** (Orthographic) and
  **497.2 µs** (Natural Earth 1) — well under a 16.6 ms 60 fps frame budget (**30× headroom**).
- **Pixel 8a Android 17 Flutter AOT** beats desktop Apple M3 Max Node.js on **12/12** workloads
  (up to **2.41× faster** on `project.mercator_1k` and **1.59× faster** on
  `path.naturalEarth1_svg`), and builds native `dart:ui.Path` world + graticule geometry in
  **876.0 µs** (Orthographic) and **805.8 µs** (Natural Earth 1).

| Case | Node.js (M3 Max) | macOS M3 Max Flutter AOT | Pixel 8a Android AOT |
|---|---:|---:|---:|
| `project.orthographic_1k` | 132,234 | **49,814** | **94,633** |
| `project.mercator_1k` | 76,318 | **14,079** | **31,661** |
| `project.equalEarth_1k` | 188,286 | **110,991** | **175,701** |
| `project.naturalEarth1_1k` | 123,976 | **59,538** | **96,811** |
| `project.albersUsa_1k` | 92,569 | **35,276** | **55,768** |
| `path.ortho_canvas` | 854,658 | **456,602** | **784,040** |
| `path.mercator_canvas` | 1,207,688 | **546,883** | **935,938** |
| `path.naturalEarth1_svg` | 527,720 | **186,979** | **331,829** |
| `path.equalEarth_canvas` | 1,151,208 | **590,050** | **945,857** |
| `geoArea.world` | 78,670 | **44,917** | **71,922** |
| `geoBounds.world` | 227,412 | **95,650** | **204,118** |
| `geoContains.500` | 11,301,813 | **4,152,786** | **7,891,571** |
| **`ui.ortho_world`** | — | **548,613** | 876,029 |
| **`ui.naturalEarth1_world`** | — | **497,197** | 805,760 |

## 4. Desktop & Mobile Browsers (ns/op)

Each cell shows `upstream JS / dart2js / dart2wasm` (fastest highlighted in bold).

- **Desktop Chrome 157:** `dart2js` beats upstream on **12/12**, `dart2wasm` beats upstream on
  **12/12** (up to **2.52× faster**), best Dart target beats upstream on **12/12**.
- **Desktop Firefox 160:** `dart2js` beats upstream on **9/12**, `dart2wasm` beats upstream on
  **9/12**, best Dart target beats upstream on **11/12** (up to **1.75× faster**).
- **Desktop Safari 27.0.1:** `dart2js` beats upstream on **12/12** (up to **2.38× faster**),
  `dart2wasm` beats upstream on **3/12**, best Dart target beats upstream on **12/12**.
- **Mobile Chrome 158 (Pixel 8a):** `dart2js` beats upstream on **12/12**, `dart2wasm` beats
  upstream on **12/12** (and beats `dart2js` on **12/12**, up to **2.63× faster** than upstream).
- **Mobile Firefox 160 (Pixel 8a):** `dart2js` beats upstream on **10/12**, `dart2wasm` beats
  upstream on **12/12** (up to **1.80× faster**), best Dart target beats upstream on **12/12**.

| Case | Chrome 157 (up / js / wasm) | Firefox 160 (up / js / wasm) | Safari 27.0.1 (up / js / wasm) | Pixel Chrome 158 (up / js / wasm) | Pixel Firefox 160 (up / js / wasm) |
|---|---|---|---|---|---|
| `project.orthographic_1k` | 115,270 / 94,833 / **83,564** | 93,272 / **62,500** / 79,427 | 117,257 / **60,417** / 140,625 | 200,000 / 148,815 / **141,298** | 148,515 / **116,667** / 130,556 |
| `project.mercator_1k` | 57,804 / 26,418 / **22,922** | 68,337 / **39,063** / 39,844 | 41,758 / **22,135** / 42,969 | 101,634 / 49,167 / **38,654** | 100,977 / 69,010 / **55,990** |
| `project.equalEarth_1k` | 203,679 / **159,115** / 188,333 | **187,500** / 221,818 / 196,875 | 175,953 / **131,250** / 203,636 | 293,137 / 260,417 / **251,351** | 269,406 / 337,500 / **265,625** |
| `project.naturalEarth1_1k` | 109,725 / **76,361** / 77,005 | 129,167 / 132,813 / **102,004** | 109,290 / **74,219** / 90,625 | 195,960 / 134,711 / **119,204** | 203,390 / 225,455 / **162,500** |
| `project.albersUsa_1k` | 93,023 / 46,904 / **42,938** | 60,545 / **45,537** / 48,270 | 77,411 / **32,552** / 61,458 | 186,810 / 94,063 / **74,591** | 130,531 / **80,729** / 85,938 |
| `path.ortho_canvas` | 897,015 / 637,805 / **599,989** | 622,449 / **525,000** / 604,167 | 710,843 / **487,500** / 875,000 | 1,758,824 / 1,134,000 / **990,323** | 1,132,076 / **923,077** / 1,037,037 |
| `path.mercator_canvas` | 1,094,340 / 701,266 / **615,306** | 939,394 / **782,609** / 825,000 | 837,838 / **600,000** / 884,058 | 2,064,286 / 1,271,111 / **1,030,303** | 1,500,000 / **1,277,778** / 1,325,000 |
| `path.naturalEarth1_svg` | 454,887 / 350,000 / **239,457** | 382,166 / 384,058 / **302,083** | 376,623 / **296,875** / 317,708 | 975,472 / 643,750 / **404,211** | 682,353 / 637,500 / **521,739** |
| `path.equalEarth_canvas` | 1,300,000 / 921,650 / **793,590** | 893,939 / **729,167** / 762,500 | 964,286 / **826,087** / 1,104,167 | 2,075,000 / 1,504,546 / **1,255,556** | 1,500,000 / 1,300,000 / **1,229,167** |
| `geoArea.world` | 108,556 / **55,952** / 60,041 | 62,299 / **51,913** / 63,802 | 51,960 / **47,359** / 91,075 | 171,633 / 97,808 / **92,571** | 99,831 / **78,125** / 93,677 |
| `geoBounds.world` | 275,556 / 178,834 / **153,383** | 177,650 / 158,854 / **145,833** | 157,333 / **140,625** / 247,664 | 465,649 / 276,768 / **252,143** | 299,492 / 260,684 / **246,377** |
| `geoContains.500` | 6,488,889 / **5,437,500** / 6,050,167 | 5,900,000 / **4,833,333** / 6,428,571 | 4,833,333 / **4,222,222** / 7,600,000 | 13,550,000 / 11,450,000 / **10,225,000** | 10,000,000 / **8,200,000** / 9,750,000 |
