# d3-quadtree port performance

This file records the speed figures of `flutter_d3_quadtree_port` against upstream `d3-quadtree`
v3.0.1 across Node.js, macOS native AOT, Flutter release builds on macOS, iOS, and Android, desktop
browsers (Chrome, Firefox, Safari), and mobile browsers (Chrome and Firefox on Android). Each faster
form is recorded under row `adapt-quadtree-fast-forms` in [differences.md](differences.md) and
verified against literal upstream algorithms and Node.js reference vectors by
`test/port/faster_forms_test.dart` and `test/port/reference_test.dart`.

## 1. Test bed

- Apple M3 Max, macOS 27.0.1, on AC power (2026-11-27).
- Flutter `master` (3.51.0-1.0.pre-31, Dart 3.15.0), Node.js v24.22.1 (darwin-arm64).
- iOS 27.2 device (`ios-arm64`) — Flutter AOT release build.
- Pixel 8a, Android 17 (API 37) — Flutter AOT release APK (`android-arm64`), Mobile Chrome 157,
  and Mobile Firefox 160.
- Desktop browsers on macOS: Chrome 157, Firefox 160, Safari 27.0.1.
- Instrument: `tool/bench/d3_quadtree_bench.dart` and `tool/bench/d3_quadtree_bench.mjs` run 14
  identical seeded Park-Miller LCG workloads (`ns/op`, median across timed batches after warmup,
  lower is better): bulk `addAll` on 1,000 and 5,000 uniform `(double, double)` points, 2,000
  clustered points (with coincident duplicates), and 1,000 custom typed objects; incremental `add`
  of 1,000 points; 256 nearest-neighbor `find` queries (unbounded, radius-constrained, and custom
  object); full 5,000-point `visit` and `visitAfter` traversals; 64 rectangular range queries via
  `visit` with quadrant pruning; deep `copy` of a 2,000-point tree; 500 dynamic `remove` + `add`
  updates; and `data` + `size` over 5,000 points.

## 2. Baseline vs optimized (macOS CLI: Node.js, AOT, dart2js, dart2wasm)

Optimizations applied (row `adapt-quadtree-fast-forms`):

1. **Concrete 4-field `QuadtreeInternalNode<T>` (`lib/src/quadtree.dart`):** stores the four
   quadrant children in fixed fields (`nw`, `ne`, `sw`, `se`) instead of allocating a per-node
   `List<QuadtreeNode<T>?>`, cutting tree construction and cloning overhead across all targets and
   keeping child dispatch monomorphic.
2. **Re-entrancy-safe pooled mutable `_QuadFrame<T>` stack (`lib/src/quad.dart`,
   `lib/src/visit.dart`, `lib/src/visitAfter.dart`, `lib/src/find.dart`):** eliminates per-step
   `Quad` object allocation during traversal and nearest-neighbor search while keeping iterative
   loops outside `try`/`finally` blocks (avoiding `dart2js` deoptimization). `visitAfter` uses a
   single O(depth) stack with a post-order `expanded` flag instead of allocating a second
   O(nodes) output list. Cuts `find.radius_256` by **3.83×** on AOT (**2.37× faster than Node.js**),
   **2.27×** on dart2js (**2.42× faster than Node.js**), and **2.89×** on dart2wasm, and cuts
   `visitAfter.full_5000` by **2.11×** on AOT, **2.22×** on dart2js (**2.21× faster than Node.js**),
   and **2.99×** on dart2wasm.
3. **Null-skipping pre-push bounds pruning in `find` (`lib/src/find.dart`):** skips empty child
   quadrants and quadrants outside the tightening search box before pushing frames while preserving
   exact upstream quadrant push order and tie-breaking (`<`, never `<=`).
4. **Zero-copy `(double, double)` default-accessor fast paths and `Float64List` batching
   (`lib/src/add.dart`, `lib/src/remove.dart`, `lib/src/find.dart`):** caches whether the tree uses
   the default `(double, double)` accessors to read `point.$1` / `point.$2` directly without closure
   dispatch or intermediate `Float64List` allocation, and batches custom-accessor coordinates in
   contiguous `Float64List` buffers during `addAll`. Cuts `addAll.uniform_1000` by **2.19×** on AOT,
   **2.80×** on dart2js, and **6.61×** on dart2wasm (**1.41× faster than Node.js**).
5. **Leaf-skip `cover` and direct depth-guarded `copy` / `data` / `size` (`lib/src/cover.dart`,
   `lib/src/quadtree.dart`, `lib/src/data.dart`, `lib/src/size.dart`):** avoids allocating wrapper
   internal nodes in `cover` when the root is a leaf, and walks trees directly in `copy`, `data`,
   and `size` with a 128-level depth guard that falls back to explicit stacks on adversarial trees.
   Cuts `copy.tree_2000` by **10.58×** on AOT and **12.89×** on dart2wasm (**1.67× faster than
   Node.js**), and cuts `data_size.5000` by **2.91×** on AOT (**2.12× faster than Node.js**),
   **2.09×** on dart2js (**2.59× faster than Node.js**), and **5.69×** on dart2wasm (**2.86× faster
   than Node.js**).

On macOS CLI benchmarks, **every case improved 1.49×–10.58× on AOT and 1.65×–12.89× on
dart2wasm**. **dart2wasm beats Node.js on 10/14** workloads (up to **2.86× faster**), **dart2js
beats Node.js on 10/14** workloads (up to **2.59× faster**), and **macOS CLI AOT beats Node.js on
5/14** workloads (up to **2.37× faster**, beating Node.js on all `find`, `update`, and `data`/`size`
queries).

| Case | Node.js | AOT base → opt | AOT / Node | dart2js base → opt | dart2wasm base → opt |
|---|---:|---|---:|---|---|
| `addAll.uniform_1000` | 43,465 | 102,301 → 46,768 (2.19×) | 1.08× | 104,543 → **37,297** (2.80×) | 204,008 → **30,875** (6.61×) |
| `addAll.uniform_5000` | 328,270 | 754,125 → 457,109 (1.65×) | 1.39× | 726,000 → **325,109** (2.23×) | 1,168,125 → **288,531** (4.05×) |
| `addAll.clustered_2000` | 98,712 | 257,016 → 135,555 (1.90×) | 1.37× | 230,867 → **86,332** (2.67×) | 473,328 → **78,129** (6.06×) |
| `addAll.custom_1000` | 41,917 | 131,195 → 62,104 (2.11×) | 1.48× | 105,789 → 78,531 (1.35×) | 204,492 → 73,844 (2.77×) |
| `add.incremental_1000` | 68,988 | 136,086 → 85,906 (1.58×) | 1.25× | 127,602 → 106,715 (1.20×) | 244,016 → 91,008 (2.68×) |
| `find.unbounded_256` | 149,483 | 265,344 → **93,492** (2.84×) | **0.63×** | 144,438 → **85,219** (1.69×) | 325,000 → **149,273** (2.18×) |
| `find.radius_256` | 166,622 | 269,031 → **70,180** (3.83×) | **0.42×** | 156,336 → **68,805** (2.27×) | 347,594 → **120,168** (2.89×) |
| `find.custom_256` | 131,620 | 258,234 → **88,379** (2.92×) | **0.67×** | 131,688 → **64,660** (2.04×) | 420,828 → **128,258** (3.28×) |
| `visit.full_5000` | 113,972 | 223,523 → 136,234 (1.64×) | 1.20× | 120,594 → **62,156** (1.94×) | 292,766 → 177,484 (1.65×) |
| `visit.range_64` | 190,716 | 353,125 → 227,375 (1.55×) | 1.19× | 236,531 → **151,383** (1.56×) | 494,906 → 276,625 (1.79×) |
| `visitAfter.full_5000` | 157,041 | 348,250 → 164,867 (2.11×) | 1.05× | 157,750 → **70,961** (2.22×) | 371,016 → **123,969** (2.99×) |
| `copy.tree_2000` | 23,574 | 346,141 → 32,730 (10.58×) | 1.39× | 64,641 → 45,293 (1.43×) | 181,688 → **14,097** (12.89×) |
| `update.remove_add_500` | 91,266 | 132,094 → **88,375** (1.49×) | **0.97×** | 179,508 → 174,938 (1.03×) | 202,992 → **72,844** (2.79×) |
| `data_size.5000` | 372,044 | 509,844 → **175,250** (2.91×) | **0.47×** | 299,313 → **143,398** (2.09×) | 740,719 → **130,234** (5.69×) |

## 3. Native Flutter Release Builds: macOS, iOS & Android (ns/op)

Measured in standalone Flutter `--release` builds (`darwin-arm64`, `ios-arm64`, and `android-arm64`).
iOS 27.2 AOT is the fastest native target across **13/14** workloads and beats desktop Apple
M3 Max Node.js on **9/14** workloads (up to **3.00× faster** on `find.radius_256` and **2.99×
faster** on `data_size.5000`). macOS M3 Max Flutter AOT beats Node.js on **5/14** workloads (up to
**2.43× faster**), and Pixel 8a Android AOT beats desktop M3 Max Node.js on **2/14** workloads
while running **2.2×–4.4× faster** than Mobile Chrome upstream JS on the same Pixel 8a on 13/14
workloads.

| Case | macOS M3 Max AOT | iOS 27.2 AOT | Pixel 8a Android AOT |
|---|---:|---:|---:|
| `addAll.uniform_1000` | 46,889 | **33,957** | 90,398 |
| `addAll.uniform_5000` | 428,609 | **321,625** | 712,250 |
| `addAll.clustered_2000` | 143,313 | **96,648** | 235,406 |
| `addAll.custom_1000` | 55,551 | **44,658** | 102,102 |
| `add.incremental_1000` | 80,246 | **58,461** | 112,570 |
| `find.unbounded_256` | 91,523 | **77,477** | 155,266 |
| `find.radius_256` | 68,656 | **55,564** | 119,980 |
| `find.custom_256` | 85,359 | **73,508** | 139,578 |
| `visit.full_5000` | 140,836 | **136,063** | 266,125 |
| `visit.range_64` | 223,641 | **191,547** | 388,406 |
| `visitAfter.full_5000` | **157,234** | 160,523 | 327,281 |
| `copy.tree_2000` | 33,160 | **24,120** | 45,766 |
| `update.remove_add_500` | 85,668 | **63,246** | 129,313 |
| `data_size.5000` | 180,258 | **124,508** | 299,563 |

## 4. Desktop & Mobile Browsers (ns/op)

Each cell shows `upstream JS / dart2js / dart2wasm` (fastest highlighted in bold).

- **Desktop Chrome 157:** `dart2js` beats upstream on **9/14**, `dart2wasm` beats upstream on
  **10/14**, best Dart target beats upstream on **12/14** (up to **3.10× faster**).
- **Desktop Firefox 160:** `dart2js` beats upstream on **10/14**, `dart2wasm` beats upstream on
  **7/14** (plus 1 tie), best Dart target beats upstream on **10/14** (up to **3.05× faster**).
- **Desktop Safari 27.0.1:** `dart2js` beats upstream on **10/14**, `dart2wasm` beats upstream on
  **9/14** (plus 3 ties), best Dart target beats upstream on **11/14** (plus 1 tie; up to **12.16×
  faster** on `visitAfter.full_5000` and **10.18× faster** on `visit.full_5000`).
- **Mobile Chrome 157 (Pixel 8a):** `dart2js` beats upstream on **10/14**, `dart2wasm` beats
  upstream on **14/14** workloads (up to **4.41× faster**), best Dart target beats upstream on
  **14/14**.
- **Mobile Firefox 160 (Pixel 8a):** `dart2js` beats upstream on **10/14**, `dart2wasm` beats
  upstream on **10/14** (plus 1 tie), best Dart target beats upstream on **11/14** (up to **2.50×
  faster**).

| Case | Chrome 157 (up / js / wasm) | Firefox 160 (up / js / wasm) | Safari 27.0.1 (up / js / wasm) | Pixel Chrome 157 (up / js / wasm) | Pixel Firefox 160 (up / js / wasm) |
|---|---|---|---|---|---|
| `addAll.uniform_1000` | 38,867 / 38,086 / **26,074** | 82,031 / **66,406** / 78,125 | 42,969 / 29,297 / **28,320** | 124,219 / 106,645 / **48,631** | 164,063 / 132,813 / **101,563** |
| `addAll.uniform_5000` | 320,313 / 326,547 / **160,938** | 625,000 / **531,250** / **531,250** | 343,750 / 265,625 / **179,688** | 859,375 / 762,500 / **531,250** | 1,125,000 / 968,750 / **875,000** |
| `addAll.clustered_2000` | 94,531 / 89,844 / **58,791** | 226,563 / **148,438** / 179,688 | 93,750 / 70,313 / **66,406** | 315,625 / 276,563 / **156,250** | 406,250 / 328,125 / **265,625** |
| `addAll.custom_1000` | **36,914** / 66,016 / 47,266 | **78,125** / 93,750 / 121,094 | **39,063** / 41,016 / 50,781 | 118,750 / 179,688 / **77,734** | **132,813** / 187,500 / 171,875 |
| `add.incremental_1000` | **51,172** / 101,953 / 68,754 | **97,656** / 109,375 / 156,250 | **52,734** / 54,688 / 58,594 | 119,531 / 175,781 / **118,363** | **148,438** / 218,750 / 203,125 |
| `find.unbounded_256` | 122,656 / **78,516** / 113,668 | 218,750 / **101,563** / 187,500 | 105,469 / **58,594** / 97,656 | 518,750 / **174,211** / 197,656 | 406,250 / **195,313** / 328,125 |
| `find.radius_256` | 121,094 / **60,547** / 83,984 | 218,750 / **74,219** / 148,438 | 109,375 / **48,828** / 74,219 | 528,125 / **132,813** / 146,094 | 390,625 / **156,250** / 250,000 |
| `find.custom_256` | 103,516 / **60,547** / 96,094 | 179,688 / **82,031** / 156,250 | 82,031 / **46,875** / 82,031 | 451,563 / **143,742** / 164,836 | 343,750 / **156,250** / 265,625 |
| `visit.full_5000` | 95,313 / **53,322** / 104,691 | 203,125 / **101,563** / 234,375 | 437,500 / **42,969** / 156,250 | 415,625 / **139,844** / 223,445 | 390,625 / **203,125** / 375,000 |
| `visit.range_64` | 157,813 / **130,469** / 200,000 | 281,250 / **234,375** / 343,750 | 250,000 / **82,031** / 250,000 | 693,750 / **398,438** / 399,984 | 562,500 / **453,125** / 562,500 |
| `visitAfter.full_5000` | 138,281 / **60,547** / 73,043 | 179,688 / **117,188** / 179,688 | 593,750 / **48,828** / 82,031 | 537,500 / 175,781 / **160,930** | 390,625 / **250,000** / **250,000** |
| `copy.tree_2000` | 18,262 / 30,273 / **10,254** | **42,969** / 93,750 / 48,828 | 28,320 / 42,969 / **17,578** | 40,625 / 167,195 / **20,606** | 93,750 / 164,063 / **44,922** |
| `update.remove_add_500` | 76,563 / 160,938 / **61,719** | **97,656** / 226,563 / 132,813 | **50,781** / 105,469 / **50,781** | 147,656 / 325,000 / **116,020** | **171,875** / 453,125 / 187,500 |
| `data_size.5000` | 340,625 / **109,762** / 118,355 | 453,125 / **148,438** / 187,500 | 359,375 / **97,656** / 156,250 | 1,000,000 / 342,172 / **226,563** | 843,750 / 406,250 / **375,000** |
