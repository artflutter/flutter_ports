# d3-delaunay port performance

This file records the speed figures of `flutter_d3_delaunay_port` against upstream `d3-delaunay`
v6.0.4 (with `delaunator` v5.1.0 and `robust-predicates` v3.0.3 `orient2d`) across Node.js, macOS
native AOT, Flutter release builds on macOS, iOS, and Android, desktop browsers (Chrome, Firefox,
Safari), and mobile browsers (Chrome and Firefox on Android). Each faster form is recorded under
row `adapt-delaunay-fast-forms` in [differences.md](differences.md) and verified against literal
upstream algorithms and Node.js reference vectors by `test/port/faster_forms_test.dart` and
`test/port/reference_test.dart`.

## 1. Test bed

- Apple M3 Max, macOS 27.0.1, on AC power (2026-11-27).
- Flutter `master` (3.51.0-1.0.pre-31, Dart 3.15.0), Node.js v24.22.1 (darwin-arm64).
- iOS 27.2 device (`ios-arm64`) — Flutter AOT release build.
- Pixel 8a, Android 17 (API 37) — Flutter AOT release APK (`android-arm64`), Mobile Chrome 157,
  and Mobile Firefox 160.
- Desktop browsers on macOS: Chrome 157, Firefox 160, Safari 27.0.1.
- Instrument: `tool/bench/d3_delaunay_bench.dart` and `tool/bench/d3_delaunay_bench.mjs` run 14
  identical seeded Park-Miller LCG workloads (`ns/op`, median across 9 timed batches after warmup,
  lower is better): 10,000 exact Shewchuk `orient2d` calls (90% general position, 10%
  near-collinear adaptive fallback); `Delaunator` triangulation on 1,000 and 5,000 uniform points,
  2,000 Gaussian-clustered points, and in-place `update()` on 1,000 points; `Delaunay.fromCoords`
  and `Delaunay.update()` on 1,000 points; 512 nearest-neighbor `Delaunay.find` queries on a
  5,000-point mesh; iterating `Delaunay.neighbors` across all 1,000 sites; `Voronoi` construction
  and in-place `update()` on 1,000 sites; materializing all 1,000 clipped `cellPolygons`; and
  rendering all 1,000 Voronoi cells to SVG (`renderToSvg`) and directly to a `CanvasPath`
  (`render`).

## 2. Baseline vs optimized (macOS CLI: Node.js, AOT, dart2js, dart2wasm)

Optimizations applied (row `adapt-delaunay-fast-forms`):

1. **Modulo-free half-edge and hash arithmetic (`lib/src/delaunator/index.dart`,
   `lib/src/delaunay.dart`, `lib/src/voronoi.dart`):** replaces Dart `% 3`, `% hashSize`, and
   `% hullLen` (which lower to `$mod` helper calls on `dart2js`) with branchless / simple
   arithmetic (`e - 3 * (e ~/ 3)` or conditional wrap) and pre-sized power-of-two/direct indexing.
   Speeds up `dart2js` triangulation and updates by **5.55×–7.43×** (`delaunator.clustered_2000`
   2,134,125 → **287,297 ns/op**, **1.39× faster than Node.js**), and improves `dart2wasm` by
   **1.22×–1.59×**.
2. **Split hot/cold `orient2d` (`lib/src/robust_predicates/orient2d.dart`):** separates the
   Shewchuk floating-point filter (`@pragma('vm:prefer-inline')`, `@pragma('wasm:prefer-inline')`,
   `@pragma('dart2js:tryInline')`) from the exact adaptive expansion (`_orient2dAdapt`, marked
   `never-inline` with unrolled 4-term estimate), keeping triangulation inner loops lean and
   register-friendly across all targets (cuts `dart2wasm` `orient2d.exact_10k` by **1.36×**).
3. **Custom zero-generator `_DelaunayNeighborsIterable` / `_DelaunayNeighborsIterator`
   (`lib/src/delaunay.dart`):** replaces `sync*` with a lightweight stateful `Iterator<int>` over
   `inedges`, `halfedges`, `triangles`, and `hull`. Cuts `delaunay.neighbors_1000` by **4.24×** on
   AOT (**2.33× faster than Node.js**), **4.91×** on dart2js (**2.40× faster than Node.js**), and
   **1.86×** on dart2wasm (**2.10× faster than Node.js**).
4. **Unrolled-by-3 `Delaunay._init()` and hoisted typed-array `Delaunay.find()`
   (`lib/src/delaunay.dart`):** unrolls triangle half-edge scanning in `_init()` with single-pass
   coincident tracking and replaces `math.pow` with direct `dx * dx + dy * dy` multiplication in
   `_step()`. Cuts `delaunay.find_512` by **3.36×** on dart2js and speeds up `delaunay.from_1000`
   by **1.21×** on AOT, **6.19×** on dart2js, and **1.55×** on dart2wasm.
5. **Reusable `Float64List` clip/work/cell scratch buffers in `Voronoi` (`lib/src/voronoi.dart`):**
   eliminates per-cell list allocations in `_clipFinite`, `_clipInfinite`, `_clipSegmentInto`,
   `_projectInto`, and `_simplifyInPlace`. Cuts `voronoi.cellPolygons_1000` by **1.96×** on AOT
   (**1.11× faster than Node.js**), **2.01×** on dart2js (**1.14× faster than Node.js**), and
   **1.67×** on dart2wasm, and speeds up `voronoi.renderCanvas_1000` by **2.43×** on dart2js
   (**1.17× faster than Node.js**).
6. **Direct `d3_path.Path` delegation for SVG serialization (`lib/src/path.dart`):** delegates
   `DelaunayPath` directly to `flutter_d3_path_port`'s optimized `Path` buffer when building SVG
   strings, cutting `voronoi.renderSvg_1000` by **2.53×** on AOT.

On macOS CLI benchmarks, **macOS AOT beats Node.js on 9/14** workloads (up to **2.33× faster**),
**dart2js beats Node.js on 10/14** workloads (up to **2.40× faster**), and **dart2wasm beats
Node.js on 6/14** workloads (up to **2.10× faster**).

| Case | Node.js | AOT base → opt | AOT / Node | dart2js base → opt | dart2wasm base → opt |
|---|---:|---|---:|---|---|
| `orient2d.exact_10k` | 24,205 | 27,516 → 26,906 (1.02×) | 1.11× | 27,552 → 26,916 (1.02×) | 41,551 → 30,568 (1.36×) |
| `delaunator.uniform_1000` | 175,092 | 130,102 → **112,063** (1.16×) | **0.64×** | 841,250 → **123,359** (6.82×) | 223,570 → **147,906** (1.51×) |
| `delaunator.uniform_5000` | 1,156,294 | 1,089,375 → 1,201,813 (0.91×) | 1.04× | 5,915,750 → **1,066,000** (5.55×) | 1,418,438 → 1,165,438 (1.22×) |
| `delaunator.clustered_2000` | 399,823 | 333,953 → **345,047** (0.97×) | **0.86×** | 2,134,125 → **287,297** (7.43×) | 513,344 → **323,875** (1.59×) |
| `delaunator.update_1000` | 168,672 | 127,695 → **112,961** (1.13×) | **0.67×** | 792,688 → **122,250** (6.48×) | 228,617 → **150,445** (1.52×) |
| `delaunay.from_1000` | 188,323 | 149,516 → **124,012** (1.21×) | **0.66×** | 834,000 → **134,711** (6.19×) | 245,766 → **158,164** (1.55×) |
| `delaunay.update_1000` | 176,769 | 137,180 → **119,758** (1.15×) | **0.68×** | 919,313 → **127,898** (7.19×) | 247,234 → **158,195** (1.56×) |
| `delaunay.find_512` | 667,546 | 773,313 → 751,656 (1.03×) | 1.13× | 3,287,625 → 978,188 (3.36×) | 1,140,938 → 966,531 (1.18×) |
| `delaunay.neighbors_1000` | 109,862 | 199,570 → **47,090** (4.24×) | **0.43×** | 225,023 → **45,830** (4.91×) | 97,211 → **52,240** (1.86×) |
| `voronoi.build_1000` | 11,944 | 12,766 → 13,060 (0.98×) | 1.09× | 13,249 → 12,654 (1.05×) | 14,415 → 17,830 (0.81×) |
| `voronoi.update_1000` | 182,407 | 146,602 → **131,219** (1.12×) | **0.72×** | 902,063 → **136,805** (6.59×) | 258,672 → 182,594 (1.42×) |
| `voronoi.cellPolygons_1000` | 156,215 | 275,609 → **140,578** (1.96×) | **0.90×** | 275,453 → **137,109** (2.01×) | 351,641 → 210,227 (1.67×) |
| `voronoi.renderSvg_1000` | 223,380 | 1,436,813 → 567,781 (2.53×) | 2.54× | 389,734 → 361,750 (1.08×) | 656,625 → 777,469 (0.84×) |
| `voronoi.renderCanvas_1000` | 38,850 | 42,838 → **37,645** (1.14×) | **0.97×** | 80,543 → **33,082** (2.43×) | 43,100 → 41,559 (1.04×) |

## 3. Native Flutter Release Builds: macOS, iOS & Android (ns/op)

Measured in standalone Flutter `--release` builds (`darwin-arm64`, `ios-arm64`, and `android-arm64`).
iOS 27.2 AOT is the fastest native target across **all 14/14** workloads and beats desktop Apple
M3 Max Node.js on **13/14** workloads (up to **3.23× faster** on `delaunay.neighbors_1000`,
**2.23× faster** on `delaunator.uniform_1000`, and **2.20× faster** on `delaunator.clustered_2000`).
macOS M3 Max Flutter AOT beats Node.js on **9/14** workloads (up to **2.24× faster**), and Pixel 8a
Android AOT beats desktop M3 Max Node.js on `delaunay.neighbors_1000` (**1.80× faster**) while
running **1.35×–3.54× faster** than Mobile Chrome upstream JS on the same Pixel 8a across **13/14**
workloads.

| Case | macOS M3 Max AOT | iOS 27.2 AOT | Pixel 8a Android AOT |
|---|---:|---:|---:|
| `orient2d.exact_10k` | 27,749 | **20,232** | 42,611 |
| `delaunator.uniform_1000` | 105,926 | **78,578** | 220,742 |
| `delaunator.uniform_5000` | 1,032,500 | **703,813** | 1,771,875 |
| `delaunator.clustered_2000` | 246,344 | **181,430** | 622,156 |
| `delaunator.update_1000` | 100,422 | **80,008** | 212,227 |
| `delaunay.from_1000` | 119,578 | **90,891** | 243,344 |
| `delaunay.update_1000` | 113,473 | **87,594** | 236,039 |
| `delaunay.find_512` | 780,344 | **456,281** | 1,181,688 |
| `delaunay.neighbors_1000` | 49,072 | **33,963** | 60,934 |
| `voronoi.build_1000` | 13,519 | **9,771** | 21,938 |
| `voronoi.update_1000` | 125,320 | **97,457** | 267,656 |
| `voronoi.cellPolygons_1000` | 142,719 | **124,922** | 234,945 |
| `voronoi.renderSvg_1000` | 614,563 | **458,219** | 1,445,375 |
| `voronoi.renderCanvas_1000` | 39,148 | **32,357** | 66,461 |

## 4. Desktop & Mobile Browsers (ns/op)

Each cell shows `upstream JS / dart2js / dart2wasm` (fastest highlighted in bold).

- **Desktop Chrome 157:** `dart2js` beats upstream on **11/14**, `dart2wasm` beats upstream on
  **7/14**, best Dart target beats upstream on **11/14** (up to **2.39× faster** on
  `delaunay.neighbors_1000`).
- **Desktop Firefox 160:** `dart2wasm` beats upstream on **12/14**, `dart2js` beats upstream on
  **7/14**, best Dart target beats upstream on **12/14** (up to **3.00× faster** on
  `delaunay.neighbors_1000` and **2.25× faster** on `orient2d.exact_10k`).
- **Desktop Safari 27.0.1:** `dart2js` beats upstream on **12/14**, `dart2wasm` beats upstream on
  **3/14**, best Dart target beats upstream on **12/14** (up to **2.88× faster** on
  `voronoi.renderCanvas_1000` and **2.30× faster** on `delaunay.neighbors_1000`).
- **Mobile Chrome 157 (Pixel 8a):** `dart2wasm` beats upstream on **12/14**, `dart2js` beats
  upstream on **6/14**, best Dart target beats upstream on **12/14** (up to **3.20× faster** on
  `delaunay.neighbors_1000`, **2.60× faster** on `voronoi.build_1000`, and **2.49× faster** on
  `voronoi.renderCanvas_1000`).
- **Mobile Firefox 160 (Pixel 8a):** `dart2wasm` beats upstream on **12/14**, `dart2js` beats
  upstream on **10/14**, best Dart target beats upstream on **12/14** (up to **3.80× faster** on
  `delaunay.neighbors_1000`).

| Case | Chrome 157 (up / js / wasm) | Firefox 160 (up / js / wasm) | Safari 27.0.1 (up / js / wasm) | Pixel Chrome 157 (up / js / wasm) | Pixel Firefox 160 (up / js / wasm) |
|---|---|---|---|---|---|
| `orient2d.exact_10k` | 28,418 / 28,027 / **27,930** | 70,313 / 62,500 / **31,250** | 42,969 / 39,063 / **29,297** | **63,672** / 116,406 / 68,164 | 121,094 / 167,969 / **82,031** |
| `delaunator.uniform_1000` | 142,188 / **126,563** / 134,375 | 265,625 / 265,625 / **171,875** | 125,000 / **109,375** / 164,063 | 401,563 / 415,625 / **227,344** | 531,250 / 468,750 / **359,375** |
| `delaunator.uniform_5000` | 1,012,500 / 1,006,250 / **918,750** | 1,812,500 / 1,812,500 / **1,187,500** | 937,500 / **812,500** / 1,062,500 | 2,550,000 / 2,712,625 / **1,762,563** | 3,250,000 / 2,875,000 / **2,375,000** |
| `delaunator.clustered_2000` | 350,000 / **290,625** / 300,000 | 625,000 / 593,750 / **359,375** | 312,500 / **234,375** / 375,000 | 928,125 / 937,500 / **587,500** | 1,187,500 / 1,125,000 / **875,000** |
| `delaunator.update_1000` | 131,250 / **119,141** / 137,500 | 265,625 / 250,000 / **156,250** | 109,375 / **105,469** / 156,250 | 346,875 / 321,875 / **239,078** | 484,375 / 468,750 / **359,375** |
| `delaunay.from_1000` | 180,469 / **135,938** / 139,844 | 281,250 / 265,625 / **164,063** | 125,000 / **117,188** / 179,688 | 500,000 / 392,188 / **245,297** | 562,500 / 531,250 / **390,625** |
| `delaunay.update_1000` | 149,219 / **123,438** / 152,344 | 265,625 / 265,625 / **164,063** | 117,188 / **109,375** / 164,063 | 373,438 / 337,500 / **259,375** | 531,250 / 484,375 / **375,000** |
| `delaunay.find_512` | **831,250** / 834,375 / 893,750 | 1,062,500 / 1,125,000 / **875,000** | 781,250 / **718,750** / 906,250 | 1,962,500 / 1,462,500 / **1,312,500** | 1,500,000 / 1,500,000 / **1,375,000** |
| `delaunay.neighbors_1000` | 98,438 / **41,211** / 50,781 | 164,063 / 93,750 / **54,688** | 89,844 / **39,063** / 54,688 | 202,344 / 129,688 / **63,277** | 296,875 / 171,875 / **78,125** |
| `voronoi.build_1000` | **14,307** / 16,406 / 16,211 | **13,672** / 21,484 / 15,625 | **8,301** / 11,230 / 19,531 | 77,734 / 82,031 / **29,884** | **29,297** / 33,203 / 31,250 |
| `voronoi.update_1000` | 148,438 / **132,813** / 159,375 | 281,250 / 281,250 / **179,688** | 125,000 / **117,188** / 187,500 | 393,750 / 376,578 / **287,500** | 562,500 / 531,250 / **421,875** |
| `voronoi.cellPolygons_1000` | 139,063 / **132,813** / 185,938 | 375,000 / **234,375** / 250,000 | 179,688 / **125,000** / 210,938 | 318,750 / 364,063 / **298,438** | 687,500 / **437,500** / **437,500** |
| `voronoi.renderSvg_1000` | **191,406** / 221,094 / 612,500 | **750,000** / 875,000 / 1,062,500 | **226,563** / 265,625 / 1,000,000 | **409,375** / 531,250 / 1,018,750 | **1,125,000** / 1,375,000 / 2,250,000 |
| `voronoi.renderCanvas_1000` | 38,281 / 31,055 / **28,613** | 89,844 / 58,594 / **44,922** | 70,313 / **24,414** / 42,969 | 111,719 / 131,250 / **44,922** | 164,063 / 101,563 / **97,656** |
