# d3-hierarchy port performance

This file records the speed figures of `flutter_d3_hierarchy_port` against upstream `d3-hierarchy`
v3.1.2 across Node.js, macOS native AOT, Flutter release builds on macOS, iOS, and Android, desktop
browsers (Chrome, Firefox, Safari), and mobile browsers (Chrome and Firefox on Android). Each
faster form is recorded under row `adapt-hierarchy-fast-forms` in [differences.md](differences.md)
and verified against literal upstream algorithms and Node.js reference vectors by
`test/port/faster_forms_test.dart` and `test/port/reference_test.dart`.

## 1. Test bed

- Apple M3 Max, macOS 27.0.1, on AC power (2026-11-27).
- Flutter `master` (3.51.0-1.0.pre-31, Dart 3.15.0), Node.js v24.22.1 (darwin-arm64).
- iOS 27.2 device (`ios-arm64`) — Flutter AOT release build.
- Pixel 8a, Android 17 (API 37) — Flutter AOT release APK (`android-arm64`), Mobile Chrome 157,
  and Mobile Firefox 160.
- Desktop browsers on macOS: Chrome 158, Firefox 161, Safari 27.0.1.
- Instrument: `tool/bench/d3_hierarchy_bench.dart` and `tool/bench/d3_hierarchy_bench.mjs` run 17
  identical seeded Park-Miller LCG workloads (`ns/op`, median across 9 timed 60 ms batches after
  250 ms warmup, lower is better): 252-node `hierarchy` construction, 252-row `stratify` by
  `id`/`parentId` and by slash-delimited `path` (with internal node imputation), 1,000-node
  traversals (`eachBefore`, `eachAfter`, breadth-first `each`, `descendants` + `leaves`),
  1,000-node `sum` + `count` and bidirectional `sort`, 252-node `treemap` (`squarify`, `binary`,
  and 4-aspect `resquarify`), `partition`, `pack`, 64-circle `packSiblings` + `packEnclose`,
  Reingold-Tilford `tree`, and `cluster`.

## 2. Baseline vs optimized (macOS CLI: Node.js, AOT, dart2js, dart2wasm)

Optimizations applied (row `adapt-hierarchy-fast-forms`):

1. **Single-pass `hierarchy` and cast-free traversals/aggregations (`lib/src/hierarchy/*.dart`):**
   single-pass recursive tree construction computing `depth` on descent and `height` on ascent
   without a queue or second `eachBefore(computeHeight)` pass; allocation-free recursive
   `eachBefore`/`eachAfter`/`sum`/`count` for trees of height ≤ 512 (with iterative fallback);
   index-pointer BFS queue (`addAll`) for `each`/`descendants`/`leaves`; base-type fast paths
   (`*Base`) eliminating per-node generic `as N` casts on `HierarchyNode<T>`; and iterative
   bottom-up merge/insertion sort for `sort`. Cuts `traverse.bfs_each_1k` by **5.61×** on AOT,
   **6.20×** on dart2js, and **10.25×** on dart2wasm; cuts `traverse.desc_leaves_1k` by **4.73×**
   on AOT and **8.13×** on dart2wasm (**4.39× faster than Node.js**); cuts `aggregate.sum_count_1k`
   by **4.37×** on AOT and **6.19×** on dart2wasm.
2. **HashMap indexing and integer-indexed `stratify` (`lib/src/stratify.dart`):** uses unordered
   `HashMap` (avoiding `LinkedHashMap` insertion-order overhead), single-pass BFS/reverse-BFS
   `depth`/`height` assignment + cycle check, `Int32List` first-child table for path stratification,
   and `codeUnitAt` path scanning. Cuts `stratify.id_252` by **1.62×** on AOT and **2.12×** on
   dart2wasm, and `stratify.path_252` by **1.60×** on AOT and **2.02×** on dart2wasm.
3. **Unboxed flat-buffer `treemap` and `partition` (`lib/src/treemap/*.dart`,
   `lib/src/partition.dart`):** reuses typed scratch `Float64List` buffers (`paddingStack` in
   `treemap`, prefix `sums` in `treemapBinary`, direct recursive `positionNode` without per-call
   closures in `treemap` and `partition`, and in-place row math in `treemapSquarify` /
   `treemapResquarify`). Cuts `treemap.squarify_252` by **3.46×** on AOT (**6.55× faster than
   Node.js**), `treemap.resquarify_252` by **2.45×** on AOT (**6.01× faster than Node.js**), and
   `partition.252` by **4.19×** on AOT (**5.07× faster than Node.js**).
4. **Unboxed typed-data front-chain & Welzl enclosure (`lib/src/pack/*.dart`):** replaces linked
   front-chain objects in `packSiblings` with reusable parallel `Float64List` / `Int32List` arrays
   (zero per-circle node allocations) and avoids `List` copies in `packEnclose` (`encloseBasis1/2/3`
   with inline scalar math), plus recursive post-order/pre-order in `pack`. Cuts `packSiblings.64`
   by **4.26×** on AOT (**3.29× faster than Node.js**) and **8.26×** on dart2wasm; cuts `pack.252`
   by **3.67×** on AOT and **6.58×** on dart2wasm (**2.26× faster than Node.js**).
5. **Flat parallel typed-array Reingold-Tilford `tree` and recursive `cluster` (`lib/src/tree.dart`,
   `lib/src/cluster.dart`):** eliminates temporary `_TreeNode` wrapper objects and per-node closures
   in `tree` using reusable `Int32List` / `Float64List` arrays for `prelim`, `mod`, `shift`,
   `change`, `thread`, and `ancestor`, and uses single-pass recursive layout in `cluster`. Cuts
   `tree.252` by **3.07×** on AOT and **3.88×** on dart2wasm (**1.81× faster than Node.js**), and
   `cluster.252` by **4.28×** on AOT (**2.82× faster than Node.js**) and **3.98×** on dart2wasm.

On macOS CLI benchmarks, **`dart2wasm` beats Node.js on 17/17** workloads (up to **4.39× faster**),
**macOS AOT beats Node.js on 15/17** workloads (up to **6.55× faster**), and **`dart2js` beats
Node.js on 12/17** workloads (up to **4.70× faster**).

| Case | Node.js | AOT base → opt | AOT / Node | dart2js base → opt | dart2wasm base → opt |
|---|---:|---|---:|---|---|
| `hierarchy.build_252` | 5,718 | 12,575 → 7,457 (1.69×) | 1.30× | 11,229 → 9,296 (1.21×) | 20,665 → **5,533** (3.73×) |
| `stratify.id_252` | 20,364 | 28,811 → **17,763** (1.62×) | **0.87×** | 30,492 → 21,214 (1.44×) | 36,120 → **17,059** (2.12×) |
| `stratify.path_252` | 42,462 | 47,563 → **29,681** (1.60×) | **0.70×** | 59,342 → **33,997** (1.75×) | 66,639 → **32,954** (2.02×) |
| `traverse.eachBefore_1k` | 5,461 | 16,512 → 6,295 (2.62×) | 1.15× | 23,521 → **4,467** (5.27×) | 27,241 → **5,084** (5.36×) |
| `traverse.eachAfter_1k` | 11,555 | 25,300 → **7,058** (3.58×) | **0.61×** | 19,516 → **4,976** (3.92×) | 35,681 → **5,229** (6.82×) |
| `traverse.bfs_each_1k` | 17,949 | 50,324 → **8,973** (5.61×) | **0.50×** | 28,881 → **4,658** (6.20×) | 61,327 → **5,983** (10.25×) |
| `traverse.desc_leaves_1k` | 52,335 | 78,808 → **16,673** (4.73×) | **0.32×** | 73,384 → **13,897** (5.28×) | 96,919 → **11,915** (8.13×) |
| `aggregate.sum_count_1k` | 51,850 | 70,999 → **16,237** (4.37×) | **0.31×** | 53,390 → **11,037** (4.84×) | 116,565 → **18,841** (6.19×) |
| `aggregate.sort_1k` | 91,149 | 119,411 → **69,529** (1.72×) | **0.76×** | 140,238 → **34,779** (4.03×) | 265,021 → **52,062** (5.09×) |
| `treemap.squarify_252` | 27,683 | 14,622 → **4,225** (3.46×) | **0.15×** | 23,902 → **8,493** (2.81×) | 23,890 → **7,460** (3.20×) |
| `treemap.binary_252` | 19,079 | 11,846 → **4,706** (2.52×) | **0.25×** | 20,258 → **12,727** (1.59×) | 18,255 → **8,731** (2.09×) |
| `treemap.resquarify_252` | 95,831 | 39,098 → **15,945** (2.45×) | **0.17×** | 69,530 → **37,334** (1.86×) | 64,818 → **31,201** (2.08×) |
| `partition.252` | 8,739 | 7,214 → **1,723** (4.19×) | **0.20×** | 12,089 → **3,466** (3.49×) | 11,496 → **2,744** (4.19×) |
| `pack.252` | 87,055 | 142,819 → **38,900** (3.67×) | **0.45×** | 120,885 → 98,183 (1.23×) | 253,454 → **38,546** (6.58×) |
| `packSiblings.64` | 27,960 | 36,244 → **8,508** (4.26×) | **0.30×** | 26,825 → **15,410** (1.74×) | 74,677 → **9,042** (8.26×) |
| `tree.252` | 19,467 | 34,664 → **11,274** (3.07×) | **0.58×** | 48,998 → 26,258 (1.87×) | 41,623 → **10,736** (3.88×) |
| `cluster.252` | 12,386 | 18,765 → **4,387** (4.28×) | **0.35×** | 31,225 → 17,433 (1.79×) | 26,071 → **6,556** (3.98×) |

## 3. Native Flutter Release Builds: macOS, iOS & Android (ns/op)

Measured in standalone Flutter `--release` builds (`darwin-arm64`, `ios-arm64`, and `android-arm64`).
iOS 27.2 AOT beats desktop M3 Max Node.js on **15/17** workloads (up to **6.91× faster**, and within
3% on the remaining two), macOS M3 Max Flutter AOT beats Node.js on **15/17** workloads (up to
**6.42× faster**), and Pixel 8a Android AOT beats desktop M3 Max Node.js on **13/17** workloads.

| Case | macOS M3 Max AOT | iOS 27.2 AOT | Pixel 8a Android AOT |
|---|---:|---:|---:|
| `hierarchy.build_252` | 7,369 | **5,736** | 8,996 |
| `stratify.id_252` | 18,900 | **15,772** | 24,963 |
| `stratify.path_252` | 30,238 | **24,843** | 41,262 |
| `traverse.eachBefore_1k` | 6,271 | **5,623** | 9,915 |
| `traverse.eachAfter_1k` | 6,708 | **5,834** | 10,255 |
| `traverse.bfs_each_1k` | 11,603 | **10,237** | 16,168 |
| `traverse.desc_leaves_1k` | 19,209 | **16,847** | 26,886 |
| `aggregate.sum_count_1k` | 16,797 | **15,054** | 21,354 |
| `aggregate.sort_1k` | 75,158 | **67,779** | 114,048 |
| `treemap.squarify_252` | 4,314 | **4,008** | 7,478 |
| `treemap.binary_252` | 4,895 | **4,737** | 7,670 |
| `treemap.resquarify_252` | 16,664 | **15,413** | 30,593 |
| `partition.252` | 1,801 | **1,498** | 2,802 |
| `pack.252` | 39,998 | **34,121** | 65,409 |
| `packSiblings.64` | 8,991 | **7,653** | 15,012 |
| `tree.252` | 12,081 | **10,779** | 19,459 |
| `cluster.252` | 4,702 | **4,280** | 7,712 |

## 4. Desktop & Mobile Browsers (ns/op)

Each cell shows `upstream JS / dart2js / dart2wasm` (fastest highlighted in bold).

- **Desktop Chrome 158:** `dart2js` beats upstream on **12/17**, `dart2wasm` beats upstream on
  **17/17**, best Dart target beats upstream on **17/17**.
- **Desktop Firefox 161:** `dart2js` beats upstream on **13/17**, `dart2wasm` beats upstream on
  **16/17**, best Dart target beats upstream on **17/17**.
- **Desktop Safari 27.0.1:** `dart2js` beats upstream on **12/17**, `dart2wasm` beats upstream on
  **14/17**, best Dart target beats upstream on **14/17**.
- **Mobile Chrome 157 (Pixel 8a):** `dart2js` beats upstream on **11/17**, `dart2wasm` beats
  upstream on **17/17**, best Dart target beats upstream on **17/17**.
- **Mobile Firefox 160 (Pixel 8a):** `dart2js` beats upstream on **12/17** (plus 1 tie), `dart2wasm`
  beats upstream on **15/17**, best Dart target beats upstream on **16/17**.

| Case | Chrome 158 (up / js / wasm) | Firefox 161 (up / js / wasm) | Safari 27.0.1 (up / js / wasm) | Pixel Chrome 157 (up / js / wasm) | Pixel Firefox 160 (up / js / wasm) |
|---|---|---|---|---|---|
| `hierarchy.build_252` | 4,388 / 7,549 / **4,351** | 8,878 / 17,448 / **5,917** | **4,961** / 7,441 / 5,127 | 12,135 / 29,112 / **7,732** | 17,868 / 47,244 / **11,230** |
| `stratify.id_252` | 12,267 / 17,868 / **11,351** | 28,285 / 40,328 / **23,405** | **10,741** / 20,182 / 18,229 | 29,840 / 40,807 / **20,345** | **36,487** / 90,253 / 38,961 |
| `stratify.path_252` | 31,620 / **23,750** / 25,313 | 64,769 / **44,510** / 55,606 | **24,530** / 27,790 / 53,734 | 64,309 / 59,625 / **43,236** | 83,333 / **82,031** / 140,625 |
| `traverse.eachBefore_1k` | 4,577 / 3,651 / **2,842** | 15,646 / **6,307** / 7,552 | 4,333 / **2,780** / 3,707 | 8,544 / 7,702 / **5,323** | 25,381 / 13,155 / **12,193** |
| `traverse.eachAfter_1k` | 7,594 / 3,742 / **3,301** | 13,636 / **7,170** / 7,525 | 7,080 / **2,881** / 4,883 | 13,995 / 8,021 / **5,830** | 21,997 / 14,648 / **11,410** |
| `traverse.bfs_each_1k` | 15,452 / **3,555** / 4,997 | 24,609 / **7,198** / 10,322 | 10,985 / **6,205** / 7,446 | 34,334 / **7,703** / 7,917 | 41,016 / **13,192** / 17,889 |
| `traverse.desc_leaves_1k` | 37,454 / 10,584 / **7,972** | 41,494 / **13,620** / 15,625 | 18,880 / **9,911** / 12,612 | 48,730 / 23,179 / **13,291** | 72,104 / 25,000 / **24,737** |
| `aggregate.sum_count_1k` | 27,044 / **8,789** / 13,762 | 56,180 / **14,343** / 27,919 | 34,564 / **7,921** / 13,426 | 49,837 / **16,416** / 22,556 | 88,323 / **34,292** / 47,656 |
| `aggregate.sort_1k` | 60,329 / 34,010 / **27,272** | 74,119 / **58,358** / 82,818 | 40,291 / **17,575** / 37,106 | 73,472 / 70,842 / **46,932** | 122,736 / 116,412 / **91,743** |
| `treemap.squarify_252` | 23,385 / 8,021 / **6,205** | 20,067 / 14,592 / **11,099** | 9,521 / **6,307** / 7,324 | 34,453 / 18,746 / **10,458** | 32,813 / 28,246 / **17,188** |
| `treemap.binary_252` | 17,600 / 13,605 / **6,690** | 19,692 / 15,102 / **12,940** | 9,045 / **7,846** / 8,727 | 25,402 / 30,616 / **11,685** | 31,250 / 31,250 / **21,482** |
| `treemap.resquarify_252` | 85,836 / 32,854 / **21,840** | 73,406 / 44,107 / **39,063** | 57,915 / **19,195** / 28,805 | 126,283 / 72,104 / **39,909** | 116,505 / 97,289 / **62,500** |
| `partition.252` | 8,489 / 3,052 / **2,314** | 9,032 / 6,137 / **4,162** | 4,395 / 3,879 / **2,930** | 11,144 / 9,537 / **3,997** | 13,921 / 12,205 / **7,177** |
| `pack.252` | 76,770 / 80,191 / **32,083** | 126,953 / 103,215 / **50,448** | 78,125 / 59,570 / **46,083** | 185,449 / 220,949 / **62,916** | 221,818 / 195,440 / **96,875** |
| `packSiblings.64` | 25,909 / 14,030 / **7,556** | 31,250 / 20,211 / **9,977** | 24,530 / 11,666 / **10,981** | 66,890 / 37,058 / **14,100** | 53,715 / 32,813 / **19,857** |
| `tree.252` | 14,070 / 26,328 / **9,111** | 26,837 / 33,978 / **15,105** | 16,016 / 20,766 / **14,136** | 38,724 / 75,207 / **16,485** | 51,814 / 81,967 / **29,785** |
| `cluster.252` | 7,979 / 14,624 / **4,116** | 14,404 / 20,182 / **7,690** | 7,682 / 15,885 / **6,134** | 19,449 / 40,169 / **7,446** | 25,000 / 45,313 / **14,841** |
