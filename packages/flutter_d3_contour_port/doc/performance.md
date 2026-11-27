# d3-contour port performance

This file records the speed figures of `flutter_d3_contour_port` against upstream `d3-contour`
v4.0.2 across Node.js, macOS native AOT, Flutter release builds on macOS, iOS, and Android,
desktop browsers (Chrome, Firefox, Safari), and mobile browsers (Chrome and Firefox on Android).
Each faster form is recorded under row `adapt-contour-fast-forms` in
[differences.md](differences.md) and verified against literal upstream marching-squares algorithms
and Node.js v4.0.2 reference vectors by `test/port/faster_forms_test.dart` and
`test/port/reference_test.dart`.

## 1. Test bed

- Apple M3 Max, macOS 27.0.1, on AC power (2026-11-27).
- Flutter `master` (Dart 3.15.0), Node.js v24.22.1 (`darwin-arm64`).
- iOS 27.2 device (`ios-arm64`) — Flutter AOT `--release` build.
- Pixel 8a, Android 17 (API 37) — Flutter AOT `--release` APK (`android-arm64`), Mobile Chrome 157,
  and Mobile Firefox 160.
- Desktop browsers on macOS: Chrome 158, Firefox 161, Safari 27.0.1.
- Instrument: `tool/bench/d3_contour_bench.dart` and `tool/bench/d3_contour_bench.mjs` run 12
  identical seeded workloads (`µs/op`, median across timed batches after warmup, lower is better):
  - `contours.peaks_64x64_10` / `contours.peaks_64x64_raw`: 64×64 multi-peak + crater topographic
    grid across 10 thresholds (smoothed vs unsmoothed).
  - `contours.peaks_128x128_10`: 128×128 topographic grid across 10 smooth thresholds.
  - `contours.single_128x128`: single-threshold `contour(values, 55)` on a 128×128 grid.
  - `contours.holes_64x64`: 64×64 concentric-rings grid with 16 tiled craters stressing fragment
    stitching and polygon hole containment (`contourContains`).
  - `contours.goldstein_96x96_12`: 96×96 Goldstein–Price surface across 12 log-spaced thresholds.
  - `density.faithful_bw30`: 272 bimodal points (`960×500`, `bandwidth: 30`, `cellSize: 4`, 20
    thresholds).
  - `density.clusters_2000_cs4` / `density.clusters_2000_cs2`: 2,000 3-cluster points (`640×400`,
    `bandwidth: 20`, `cellSize: 4` and `cellSize: 2`).
  - `density.clusters_10000_cs4`: 10,000 points (`640×400`, `bandwidth: 24`, `cellSize: 4`).
  - `density.weighted_2000`: 2,000 weighted points including `NaN` and zero weights.
  - `density.contours_query5`: reusable `contourDensity().contours(data)` precomputation followed by
    5 single-level queries (`contour(v)`).

## 2. Baseline vs optimized (macOS CLI: Node.js, AOT, dart2js, dart2wasm)

Optimizations applied (row `adapt-contour-fast-forms`):

1. **Flat-array 2-row frontier + pooled linked-list fragment stitcher (`lib/src/contours.dart`):**
   replaces upstream's two sparse maps (`fragmentByStart`/`fragmentByEnd`), per-segment vertex
   arrays, `_Fragment` heap objects, `O(n)` `insert(0)` prepends, and `concat` ring copies with a
   reusable `_StitchWorkspace` holding `2 * (dx + 1) + 2` frontier slots (`Int32List`) and pooled
   `Int32List` half-coordinate chains (`nodeHx`, `nodeHy`, `nodeNext`). Every append, prepend, and
   fragment merge runs in `O(1)` with zero heap allocations per segment, while emitting 100%
   bit-identical ring vertex order. Reused across all thresholds in a batch call.
2. **Unboxed `Float64List` grid scanning and integer-parity `smoothLinear` (`lib/src/contours.dart`):**
   specializes cell scanning directly on `Float64List`, skips empty (`mask == 0`) and filled
   (`mask == 15`) cells before switch dispatch, and checks `(hx & 1) == 0` / `(hy & 1) == 0`
   directly on half-integer coordinates while computing smoothed vertices, signed ring area, and
   axis-aligned bounding boxes in a single ring-materialization pass.
3. **Unboxed `Float64List` `contourDensity` splatting, `blur2` fast path, and fused affine ring
   transform (`lib/src/density.dart`, `lib/src/contours.dart`):** accumulates point splats into a
   `Float64List` with hoisted accessor fast paths and interior bounds folding so
   `flutter_d3_array_port`'s `blur2` hits its unboxed `Float64List` kernel (cutting Wasm density
   runtimes by up to **8.82×** vs baseline), and fuses `(x * 2^k - o)` directly into ring
   materialization so zero intermediate pre-transform rings are allocated.
4. **O(1) bounding-box hole pre-rejection and edge-box pre-filter (`lib/src/contours.dart`,
   `lib/src/contains.dart`, `lib/src/area.dart`):** rejects non-overlapping exterior polygons via
   exact axis-aligned bounding boxes before running `contourContains`, and guards collinearity and
   ray-casting divisions in `contourContains` with fast edge-box comparisons, cutting
   `contours.holes_64x64` by **5.13×** on AOT and **6.96×** on dart2js.

On macOS CLI benchmarks, **macOS AOT beats Node.js on 12/12** workloads (up to **5.4× faster** than
Node.js; **3.40×–5.55×** faster than baseline), **dart2js beats Node.js on 12/12** workloads (up to
**6.1× faster**), and **dart2wasm beats Node.js on 12/12** workloads (up to **5.8× faster** than
Node.js; **4.42×–8.82×** faster than baseline).

All values below are median **µs/op** (lower is better).

| Case | Node.js | AOT base → opt | AOT / Node | dart2js base → opt | dart2wasm base → opt |
|---|---:|---|---:|---|---|
| `contours.peaks_64x64_10` | 731.6 | 762.1 → **196.3** (3.88×) | **0.27×** | 797.5 → **176.5** (4.52×) | 970.9 → **169.7** (5.72×) |
| `contours.peaks_64x64_raw` | 741.8 | 706.3 → **179.9** (3.93×) | **0.24×** | 794.7 → **170.7** (4.66×) | 883.5 → **176.8** (5.00×) |
| `contours.peaks_128x128_10` | 2,137.9 | 2,584.5 → **616.0** (4.20×) | **0.29×** | 2,187.1 → **554.9** (3.94×) | 3,399.3 → **482.0** (7.05×) |
| `contours.single_128x128` | 148.7 | 166.5 → **48.9** (3.40×) | **0.33×** | 134.1 → **45.2** (2.96×) | 251.5 → **38.4** (6.54×) |
| `contours.holes_64x64` | 1,810.4 | 1,993.6 → **388.8** (5.13×) | **0.21×** | 2,061.1 → **296.0** (6.96×) | 1,739.1 → **393.4** (4.42×) |
| `contours.goldstein_96x96_12` | 2,339.3 | 2,416.0 → **435.1** (5.55×) | **0.19×** | 2,438.5 → **422.8** (5.77×) | 2,550.8 → **401.8** (6.35×) |
| `density.faithful_bw30` | 4,714.5 | 8,796.5 → **2,220.5** (3.96×) | **0.47×** | 4,338.3 → **1,927.1** (2.25×) | 14,088.0 → **1,688.6** (8.34×) |
| `density.clusters_2000_cs4` | 3,091.7 | 4,813.3 → **1,120.6** (4.30×) | **0.36×** | 2,692.3 → **1,074.2** (2.51×) | 7,742.5 → **988.0** (7.84×) |
| `density.clusters_2000_cs2` | 6,002.4 | 13,411.0 → **2,884.4** (4.65×) | **0.48×** | 5,597.8 → **2,654.5** (2.11×) | 21,875.0 → **2,480.1** (8.82×) |
| `density.clusters_10000_cs4` | 1,689.7 | 3,672.8 → **720.0** (5.10×) | **0.43×** | 1,565.8 → **765.9** (2.04×) | 5,810.5 → **772.0** (7.53×) |
| `density.weighted_2000` | 2,745.0 | 4,695.5 → **1,042.5** (4.50×) | **0.38×** | 2,474.3 → **1,027.8** (2.41×) | 7,361.8 → **959.3** (7.67×) |
| `density.contours_query5` | 1,500.4 | 2,966.5 → **575.6** (5.15×) | **0.38×** | 1,246.8 → **595.8** (2.09×) | 4,903.3 → **568.5** (8.62×) |

## 3. Native Flutter Release Builds: macOS, iOS & Android (µs/op)

Measured in standalone Flutter `--release` builds (`darwin-arm64`, `ios-arm64`, and
`android-arm64`). All three native targets — **macOS M3 Max Flutter AOT (12/12)**, **iOS 27.2 AOT
(12/12, up to 5.65× faster)**, and **Pixel 8a Android 17 AOT (12/12)** — beat desktop M3 Max
Node.js on every single workload. Fastest native build per row is highlighted in bold.

| Case | Node.js upstream | macOS M3 Max AOT | iOS 27.2 AOT | Pixel 8a Android AOT |
|---|---:|---:|---:|---:|
| `contours.peaks_64x64_10` | 731.6 | 202.3 | **153.2** | 291.8 |
| `contours.peaks_64x64_raw` | 741.8 | 189.5 | **164.1** | 276.2 |
| `contours.peaks_128x128_10` | 2,137.9 | 649.6 | **534.3** | 964.9 |
| `contours.single_128x128` | 148.7 | 53.2 | **44.0** | 78.9 |
| `contours.holes_64x64` | 1,810.4 | 434.8 | **374.5** | 710.3 |
| `contours.goldstein_96x96_12` | 2,339.3 | 480.1 | **413.9** | 712.1 |
| `density.faithful_bw30` | 4,714.5 | 2,363.3 | **2,115.6** | 4,206.6 |
| `density.clusters_2000_cs4` | 3,091.7 | 1,163.8 | **1,010.9** | 1,803.1 |
| `density.clusters_2000_cs2` | 6,002.4 | 3,253.9 | **2,774.5** | 5,885.3 |
| `density.clusters_10000_cs4` | 1,689.7 | 767.6 | **672.1** | 1,197.6 |
| `density.weighted_2000` | 2,745.0 | 1,108.9 | **1,000.4** | 1,728.8 |
| `density.contours_query5` | 1,500.4 | 597.1 | **513.5** | 946.1 |

## 4. Desktop & Mobile Browsers (µs/op)

Each cell shows `upstream JS / dart2js / dart2wasm` (fastest highlighted in bold).

- **Desktop Chrome 158:** `dart2js` beats upstream on **12/12**, `dart2wasm` beats upstream on
  **12/12**, best Dart target beats upstream on **12/12** (up to **4.6× faster**).
- **Desktop Firefox 161:** `dart2js` beats upstream on **12/12**, `dart2wasm` beats upstream on
  **12/12**, best Dart target beats upstream on **12/12** (up to **4.0× faster**).
- **Desktop Safari 27.0.1:** `dart2js` beats upstream on **12/12**, `dart2wasm` beats upstream on
  **12/12**, best Dart target beats upstream on **12/12** (up to **3.8× faster**).
- **Mobile Chrome 157 (Pixel 8a):** `dart2js` beats upstream on **12/12**, `dart2wasm` beats
  upstream on **12/12** (**12/12** won outright by `dart2wasm`, up to **4.7× faster**).
- **Mobile Firefox 160 (Pixel 8a):** `dart2js` beats upstream on **12/12**, `dart2wasm` beats
  upstream on **12/12**, best Dart target beats upstream on **12/12** (up to **4.2× faster**).

| Case | Chrome 158 (up / js / wasm) | Firefox 161 (up / js / wasm) | Safari 27.0.1 (up / js / wasm) | Pixel Chrome 157 (up / js / wasm) | Pixel Firefox 160 (up / js / wasm) |
|---|---|---|---|---|---|
| `contours.peaks_64x64_10` | 578.1 / 175.0 / **145.3** | 718.8 / 250.0 / **234.4** | 593.8 / 171.9 / **156.3** | 1,075.0 / 465.6 / **228.1** | 1,437.5 / 500.0 / **406.3** |
| `contours.peaks_64x64_raw` | 540.6 / 167.2 / **160.9** | 687.5 / **210.9** / 218.8 | 500.0 / **156.3** / 179.7 | 975.0 / 387.5 / **251.6** | 1,375.0 / **375.0** / 390.6 |
| `contours.peaks_128x128_10` | 1,606.2 / 543.8 / **456.3** | 2,125.0 / 718.8 / **656.3** | 1,625.0 / 500.0 / **468.8** | 2,962.5 / 1,418.8 / **696.9** | 3,750.0 / **1,250.0** / **1,250.0** |
| `contours.single_128x128` | 123.0 / 48.0 / **36.3** | 156.3 / 58.6 / **52.7** | 117.2 / 41.0 / **39.1** | 199.2 / 115.6 / **50.8** | 281.3 / 101.6 / **97.7** |
| `contours.holes_64x64` | 1,262.5 / **275.0** / 309.4 | 1,625.0 / **406.3** / 500.0 | 1,000.0 / **281.3** / 328.1 | 2,812.5 / 1,050.0 / **596.9** | 3,375.0 / **812.5** / 937.5 |
| `contours.goldstein_96x96_12` | 1,562.5 / 428.1 / **367.2** | 1,875.0 / **593.8** / **593.8** | 1,437.5 / 406.3 / **390.6** | 2,800.0 / 1,131.3 / **634.4** | 3,625.0 / 1,125.0 / **1,062.5** |
| `density.faithful_bw30` | 4,375.0 / 2,012.5 / **1,531.3** | 5,250.0 / 2,625.0 / **2,000.0** | 4,500.0 / **1,625.0** / 1,750.0 | 7,950.0 / 4,450.0 / **2,225.0** | 10,500.0 / 4,500.0 / **3,500.0** |
| `density.clusters_2000_cs4` | 2,525.0 / 1,125.0 / **906.3** | 3,125.0 / 1,437.5 / **1,125.0** | 2,625.0 / **1,000.0** / **1,000.0** | 4,550.0 / 2,612.5 / **1,299.9** | 6,000.0 / 2,625.0 / **2,125.0** |
| `density.clusters_2000_cs2` | 5,425.0 / 2,825.0 / **2,262.6** | 7,000.0 / 3,750.0 / **2,625.0** | 6,000.0 / **2,375.0** / 2,625.0 | 10,150.0 / 6,200.0 / **3,225.0** | 13,000.0 / 6,250.0 / **4,750.0** |
| `density.clusters_10000_cs4` | 1,525.0 / 812.5 / **690.6** | 1,875.0 / 1,062.5 / **875.0** | 1,625.0 / **687.5** / 843.8 | 2,850.0 / 2,037.5 / **950.0** | 3,625.0 / 1,750.0 / **1,562.5** |
| `density.weighted_2000` | 2,337.5 / 1,068.8 / **906.3** | 2,875.0 / 1,375.0 / **1,125.0** | 2,750.0 / **937.5** / **937.5** | 4,425.0 / 2,387.5 / **1,250.0** | 6,000.0 / 2,250.0 / **2,000.0** |
| `density.contours_query5` | 1,212.5 / 665.7 / **537.5** | 1,562.5 / 812.5 / **656.3** | 1,312.5 / **531.3** / 625.0 | 2,287.5 / 1,525.0 / **756.3** | 2,875.0 / 1,312.5 / **1,125.0** |
