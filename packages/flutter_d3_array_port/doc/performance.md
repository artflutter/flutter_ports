# d3-array port performance

This file records the speed figures of `flutter_d3_array_port` against upstream `d3-array` v3.2.4
across Node.js, macOS native AOT, Flutter release builds on macOS, iOS, and Android, desktop
browsers (Chrome, Firefox, Safari), and mobile browsers (Chrome and Firefox on Android). Each
faster form is recorded under row `adapt-array-fast-forms` in [differences.md](differences.md) and
verified against literal upstream algorithms and Node.js reference vectors by
`test/port/faster_forms_test.dart` and `test/port/reference_test.dart`.

## 1. Test bed

- Apple M3 Max, macOS 27.0.1, on AC power (2026-11-27).
- Flutter `master` (3.51.0-1.0.pre-31, Dart 3.15.0), Node.js v24.22.1 (darwin-arm64).
- iOS 27.2 device (`ios-arm64`) — Flutter AOT release build.
- Pixel 8a, Android 17 (API 37) — Flutter AOT release APK (`android-arm64`), Mobile Chrome 157,
  and Mobile Firefox 160.
- Desktop browsers on macOS: Chrome 157, Firefox 160, Safari 27.0.1.
- Instrument: `tool/bench/d3_array_bench.dart` and `tool/bench/d3_array_bench.mjs` run 20 identical
  seeded Park-Miller LCG workloads (`ns/op`, median across timed batches after warmup, lower is
  better): 1,024-element `Float64List`/`List<double>` statistics (`sum`, `fsum`, `min`/`max`/
  `extent`, `mean`, `variance`/`deviation`, `cumsum`, `quickselect`, 3-point `quantile`), 64×3
  bisection lookups (`bisect`), Sturges and Freedman-Diaconis histogramming (`bin`), 32-domain
  `ticks` + `nice`, 1,024 + 200-element `range`, 1D integer/fractional `blur` and 64×64 `blur2`,
  1,024-element `sort`, 512-element `rank` with ties, 512-row `group` + `rollup`, and 1,024-element
  `shuffler`.

## 2. Baseline vs optimized (macOS CLI: Node.js, AOT, dart2js, dart2wasm)

Optimizations applied (row `adapt-array-fast-forms`):

1. **Unboxed typed-data fast paths (`sum`, `fsum`, `cumsum`, `min`, `max`, `extent`, `mean`,
   `variance`, `deviation`, `count`, `quickselect`, `quantile`, `bisect`, `shuffle`):** specialized
   indexed loops for `Float64List`, `List<double>`, `List<int>`, and `List<num>` avoid per-element
   iterator/closure boxing and produce **7.9×** faster `sum`, **45.2×** faster `cumsum`, **19.7×**
   faster `quantile`, **6.8×** faster `min`/`max`/`extent`, **5.7×** faster `quickselect`, and
   **7.0×** faster `shuffle` than Node.js on macOS AOT.
2. **Inline unboxed 3-way quicksort for `sort` and `rank` (`lib/src/sort.dart`, `lib/src/rank.dart`):**
   replaces generic closure-backed `List.sort` on `Float64List`/`List<double>` with an unboxed
   3-way quicksort + insertion sort (and a `Uint32List` index sort for `rank`), cutting
   `sort.f64_1024` by **8.95×** on AOT (**9.1× faster than Node.js**), **7.70×** on dart2js, and
   **10.96×** on dart2wasm, and cutting `rank.f64_512` by **16.56×** on AOT (**10.3× faster than
   Node.js**), **18.53×** on dart2js, and **51.53×** on dart2wasm (**10.5× faster than Node.js**).
3. **Precomputed `pow10` binary search and non-recursive `_tickSpec` (`lib/src/ticks.dart`,
   `lib/src/range.dart`):** replaces transcendental `math.log` calls with a 6-step binary search in
   an exact `1e-22..1e22` lookup table, converts tail recursion into an inlineable loop, and writes
   unboxed `Float64List` outputs in `ticks` and `range`. Cuts `ticks.batch32` by **1.98×** on AOT
   (**1.11× faster than Node.js**) and **3.09×** on dart2wasm, and cuts `range.1024` by **4.29×**
   on AOT and **3.87×** on dart2wasm.
4. **Direct `Float64List` binning and bucket-list accumulation (`lib/src/bin.dart`):** skips the
   nullable intermediate copy and `Bin<T>.add` wrapper indirection when binning numeric lists with
   the default identity accessor, cutting `bin.sturges_1024` by **1.48×** on AOT and **2.52×** on
   dart2wasm, and cutting `bin.fd_1024` by **1.82×** on AOT (**5.5× faster than Node.js**) and
   **2.21×** on dart2wasm (**4.1× faster than Node.js**).
5. **Inline Shewchuk summation (`lib/src/fsum.dart`) and branch-split `Float64List` sliding windows
   (`lib/src/blur.dart`):** eliminates per-element wrapper calls in `fsum` (speeding up dart2js by
   **1.78×**) and splits the leading/interior/trailing window loops in `blur`/`blur2` while keeping
   exact IEEE-754 `sum / w` rounding, beating Node.js on all three blur workloads across AOT,
   dart2js, and dart2wasm.

On macOS CLI benchmarks, **macOS AOT beats Node.js on 19/20** workloads (up to **45.2× faster**),
**dart2wasm beats Node.js on 17/20** workloads (up to **42.6× faster**), and **dart2js beats
Node.js on 16/20** workloads (up to **33.1× faster**).

| Case | Node.js | AOT base → opt | AOT / Node | dart2js base → opt | dart2wasm base → opt |
|---|---:|---|---:|---|---|
| `sum.f64_1024` | 4,693 | 604 → **594** (1.02×) | **0.13×** | 613 → **607** (1.01×) | 1,385 → **1,414** (0.98×) |
| `fsum.f64_1024` | 10,703 | 8,288 → **9,208** (0.90×) | **0.86×** | 15,148 → **8,511** (1.78×) | 7,881 → **7,797** (1.01×) |
| `minmax.f64_1024` | 14,098 | 2,073 → **2,071** (1.00×) | **0.15×** | 1,800 → **1,829** (0.98×) | 5,924 → **6,144** (0.96×) |
| `mean.f64_1024` | 4,774 | 674 → **683** (0.99×) | **0.14×** | 911 → **919** (0.99×) | 648 → **643** (1.01×) |
| `variance.f64_1024` | 9,601 | 8,567 → **8,573** (1.00×) | **0.89×** | 8,575 → **8,589** (1.00×) | 8,515 → **8,520** (1.00×) |
| `cumsum.f64_1024` | 40,898 | 921 → **904** (1.02×) | **0.02×** | 1,377 → **1,235** (1.11×) | 942 → **961** (0.98×) |
| `quickselect.f64_1024` | 22,423 | 3,973 → **3,934** (1.01×) | **0.18×** | 5,379 → **5,406** (1.00×) | 3,515 → **3,462** (1.02×) |
| `quantile.f64_1024` | 216,304 | 10,861 → **10,979** (0.99×) | **0.05×** | 11,914 → **11,837** (1.01×) | 24,121 → **23,865** (1.01×) |
| `bisect.f64_1024` | 12,107 | 2,822 → **2,837** (0.99×) | **0.23×** | 4,210 → **4,039** (1.04×) | 1,757 → **1,825** (0.96×) |
| `bin.sturges_1024` | 14,092 | 22,832 → 15,454 (1.48×) | 1.10× | 18,125 → 14,207 (1.28×) | 48,203 → 19,099 (2.52×) |
| `bin.fd_1024` | 157,709 | 52,480 → **28,844** (1.82×) | **0.18×** | 32,736 → **29,019** (1.13×) | 84,891 → **38,332** (2.21×) |
| `ticks.batch32` | 2,910 | 5,216 → **2,630** (1.98×) | **0.90×** | 5,668 → 4,031 (1.41×) | 9,435 → 3,052 (3.09×) |
| `range.1024` | 865 | 3,628 → **847** (4.29×) | **0.98×** | 1,352 → 1,333 (1.01×) | 2,998 → **775** (3.87×) |
| `blur1.1024_r3` | 4,572 | 4,974 → **4,241** (1.17×) | **0.93×** | 5,250 → **4,448** (1.18×) | 5,097 → **4,446** (1.15×) |
| `blur1.1024_r2_5` | 8,836 | 5,300 → **4,996** (1.06×) | **0.57×** | 6,416 → **6,042** (1.06×) | 6,082 → **5,681** (1.07×) |
| `blur2.64x64_r2` | 47,193 | 32,352 → **31,010** (1.04×) | **0.66×** | 38,182 → **34,596** (1.10×) | 35,594 → **31,248** (1.14×) |
| `sort.f64_1024` | 125,700 | 123,484 → **13,792** (8.95×) | **0.11×** | 130,273 → **16,914** (7.70×) | 165,125 → **15,064** (10.96×) |
| `rank.f64_512` | 70,984 | 113,719 → **6,866** (16.56×) | **0.10×** | 139,977 → **7,555** (18.53×) | 348,359 → **6,761** (51.53×) |
| `group.rollup_512` | 26,995 | 22,624 → **22,313** (1.01×) | **0.83×** | 12,340 → **12,482** (0.99×) | 37,168 → 36,387 (1.02×) |
| `shuffle.1024` | 31,948 | 4,967 → **4,551** (1.09×) | **0.14×** | 35,584 → 36,160 (0.98×) | 7,763 → **7,872** (0.99×) |

## 3. Native Flutter Release Builds: macOS, iOS & Android (ns/op)

Measured in standalone Flutter `--release` builds (`darwin-arm64`, `ios-arm64`, and `android-arm64`).
iOS 27.2 AOT beats Node.js on **20/20** workloads (up to **48.9× faster**), macOS M3 Max Flutter AOT
beats Node.js on **19/20** workloads, and Pixel 8a Android AOT beats desktop M3 Max Node.js on
**13/20** workloads.

| Case | macOS M3 Max AOT | iOS 27.2 AOT | Pixel 8a Android AOT |
|---|---:|---:|---:|
| `sum.f64_1024` | **601** | 642 | 1,791 |
| `fsum.f64_1024` | 9,297 | **5,476** | 8,442 |
| `minmax.f64_1024` | 2,276 | **1,464** | 2,355 |
| `mean.f64_1024` | 675 | **653** | 1,765 |
| `variance.f64_1024` | 8,425 | **6,965** | 14,019 |
| `cumsum.f64_1024` | 926 | **837** | 2,301 |
| `quickselect.f64_1024` | 3,926 | **2,390** | 4,663 |
| `quantile.f64_1024` | 10,730 | **9,043** | 14,358 |
| `bisect.f64_1024` | 2,767 | **1,947** | 3,010 |
| `bin.sturges_1024` | 15,237 | **12,450** | 23,001 |
| `bin.fd_1024` | 29,061 | **23,989** | 41,057 |
| `ticks.batch32` | 2,687 | **2,181** | 4,262 |
| `range.1024` | 843 | **681** | 1,110 |
| `blur1.1024_r3` | 4,143 | **3,859** | 5,313 |
| `blur1.1024_r2_5` | 4,823 | **4,136** | 8,233 |
| `blur2.64x64_r2` | 30,580 | **25,578** | 60,012 |
| `sort.f64_1024` | 13,250 | **10,884** | 19,151 |
| `rank.f64_512` | 6,688 | **5,713** | 9,489 |
| `group.rollup_512` | 22,385 | **20,269** | 31,854 |
| `shuffle.1024` | **4,882** | 5,192 | 6,519 |

## 4. Desktop & Mobile Browsers (ns/op)

Each cell shows `upstream JS / dart2js / dart2wasm` (fastest highlighted in bold).

- **Desktop Chrome 157:** `dart2js` beats upstream on **15/20**, `dart2wasm` beats upstream on
  **16/20**, best Dart target beats upstream on **17/20**.
- **Desktop Firefox 160:** `dart2js` beats upstream on **16/20**, `dart2wasm` beats upstream on
  **16/20**, best Dart target beats upstream on **16/20** (plus a tie on `group.rollup_512`).
- **Desktop Safari 27.0.1:** `dart2js` beats upstream on **16/20**, `dart2wasm` beats upstream on
  **16/20**, best Dart target beats upstream on **18/20** (plus a tie on `blur2.64x64_r2`).
- **Mobile Chrome 157 (Pixel 8a):** `dart2js` beats upstream on **15/20**, `dart2wasm` beats
  upstream on **18/20**, best Dart target beats upstream on **18/20**.
- **Mobile Firefox 160 (Pixel 8a):** `dart2js` beats upstream on **17/20**, `dart2wasm` beats
  upstream on **16/20**, best Dart target beats upstream on **17/20**.

| Case | Chrome 157 (up / js / wasm) | Firefox 160 (up / js / wasm) | Safari 27.0.1 (up / js / wasm) | Pixel Chrome 157 (up / js / wasm) | Pixel Firefox 160 (up / js / wasm) |
|---|---|---|---|---|---|
| `sum.f64_1024` | 4,932 / **580** / 1,392 | 3,418 / **732** / 1,465 | 5,859 / **549** / 1,465 | 14,063 / 2,490 / **1,770** | 9,277 / **1,221** / 1,831 |
| `fsum.f64_1024` | 11,621 / 9,181 / **7,813** | 17,578 / 9,766 / **7,813** | 15,625 / **6,836** / 8,789 | 29,102 / 15,037 / **8,593** | 62,500 / 11,719 / **9,766** |
| `minmax.f64_1024` | 13,867 / **1,624** / 2,002 | 11,719 / **3,174** / 6,348 | 17,578 / **1,343** / 4,395 | 42,188 / 7,666 / **3,198** | 21,484 / **4,150** / 9,766 |
| `mean.f64_1024` | 4,883 / 922 / **665** | 3,418 / 732 / **671** | 5,371 / **671** / **671** | 13,770 / 2,466 / **830** | 6,836 / 1,343 / **1,099** |
| `variance.f64_1024` | 9,473 / 9,962 / **8,496** | 8,789 / **7,813** / 8,789 | 11,719 / **8,789** / **8,789** | 29,102 / 14,258 / **12,305** | 14,648 / **11,719** / 12,695 |
| `cumsum.f64_1024` | 35,937 / 1,526 / **1,087** | 9,766 / **732** / 1,221 | 16,602 / **977** / 1,587 | 85,938 / 10,010 / **1,428** | 15,625 / 2,441 / **1,953** |
| `quickselect.f64_1024` | 21,289 / 5,273 / **3,467** | 16,602 / 12,695 / **3,418** | 3,418 / 5,371 / **2,441** | 28,711 / 7,910 / **4,493** | 25,391 / 19,531 / **6,348** |
| `quantile.f64_1024` | 204,687 / 13,085 / **10,742** | 125,000 / **19,531** / 23,438 | 85,938 / **7,813** / 21,484 | 521,875 / 37,500 / **15,430** | 250,000 / **29,297** / 46,875 |
| `bisect.f64_1024` | 10,059 / 3,662 / **1,514** | 12,695 / 5,859 / **2,686** | 4,883 / **1,953** / **1,953** | 15,625 / 6,933 / **1,721** | 21,484 / 8,789 / **3,906** |
| `bin.sturges_1024` | 15,332 / **12,988** / 13,379 | **12,695** / 16,602 / 25,391 | **12,695** / 25,391 / 13,672 | 25,000 / 50,391 / **24,219** | **23,438** / 42,969 / 42,969 |
| `bin.fd_1024` | 151,562 / **28,320** / 33,594 | 101,563 / **39,063** / 46,875 | 54,688 / 46,875 / **31,250** | 312,500 / 107,023 / **57,035** | 187,500 / **78,125** / **78,125** |
| `ticks.batch32` | **2,197** / 4,639 / 2,881 | **3,906** / 4,883 / 4,883 | 5,859 / **2,686** / 3,662 | 5,859 / 15,234 / **4,883** | **5,859** / 8,789 / 8,789 |
| `range.1024` | **867** / 1,501 / 1,880 | 2,686 / **854** / 1,099 | 1,282 / **916** / 3,906 | **2,075** / 9,717 / 2,808 | 3,906 / **2,197** / **2,197** |
| `blur1.1024_r3` | 4,980 / 4,980 / **4,443** | 6,348 / 5,859 / **4,395** | 4,883 / **4,395** / 4,883 | 14,258 / 19,238 / **5,957** | 11,719 / 9,766 / **6,836** |
| `blur1.1024_r2_5` | 9,277 / 6,933 / **5,664** | 9,766 / 8,301 / **5,371** | 6,836 / **5,371** / 5,859 | 18,750 / 15,234 / **8,594** | 17,578 / 14,648 / **10,742** |
| `blur2.64x64_r2` | 39,453 / 39,453 / **30,863** | 58,594 / 50,781 / **31,250** | **35,156** / **35,156** / **35,156** | 87,500 / 84,375 / **42,969** | 85,938 / 78,125 / **54,688** |
| `sort.f64_1024` | 117,188 / 16,408 / **14,160** | 85,938 / 21,484 / **17,578** | 109,375 / **12,695** / 17,578 | 184,375 / 38,281 / **22,852** | 132,813 / 39,063 / **33,203** |
| `rank.f64_512` | 71,094 / 8,301 / **6,641** | 54,688 / 8,789 / **7,813** | 42,969 / **5,859** / 7,813 | 125,781 / 18,555 / **10,448** | 101,563 / 14,648 / **11,719** |
| `group.rollup_512` | 23,828 / **11,133** / 28,125 | **21,484** / **21,484** / 54,688 | 12,695 / **9,766** / 35,156 | 60,938 / **28,906** / 48,828 | 42,969 / **39,063** / 101,563 |
| `shuffle.1024` | **6,494** / 7,422 / 8,008 | **13,672** / 16,602 / 17,578 | 31,250 / 35,156 / **7,813** | **12,988** / 17,385 / 16,602 | **10,742** / 29,297 / 31,250 |
