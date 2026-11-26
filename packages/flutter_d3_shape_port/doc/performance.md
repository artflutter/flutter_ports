# d3-shape port performance

This file records the speed figures of `flutter_d3_shape_port` against upstream `d3-shape` v3.2.0
across Node.js, macOS native AOT, Flutter release builds on macOS and Android, desktop browsers
(Chrome, Firefox, Safari) and mobile Chrome on Android. Each faster form has a row in
[differences.md](differences.md) and a twin test in `test/port/faster_forms_test.dart`.

## 1. Test bed

- Apple M3 Max, macOS 27.0.1, on AC power (2026-11-26).
- Flutter `master` (3.51.0-1.0.pre-31, Dart 3.15.0), Node.js v24.22.1 (V8 13.6.233.17-node.58,
  darwin-arm64).
- Pixel 8a, Android 17 (API 37) — Flutter AOT release APK (`android-arm64`) + Mobile Chrome 157.
- Desktop browsers on macOS: HeadlessChrome 158, Firefox 160, Safari 27.
- Instrument: `tool/bench/d3_shape_bench.dart` and `tool/bench/d3_shape_bench.mjs` run 20 identical
  seeded cases (`ns/op`, median, lower is better). Native Flutter release builds also measure 7
  `UiPathContext` cases (`ui.*`) writing directly into a reusable `dart:ui.Path` with zero SVG
  string formatting.

## 2. Baseline vs optimized (macOS CLI: Node.js, AOT, dart2js, dart2wasm)

Optimizations applied (row `adapt-shape-fast-forms`):

1. **Unboxed `Float64List`/`Int32List` + inline stable insertion sort (`n <= 32`) + constant
   accessors in `Pie` (`lib/src/pie.dart`):** eliminates closure-comparator sorting and double
   list allocation, speeding up `pie.20` by **3.44×** on AOT (**1.8× faster than Node.js**),
   **2.06×** on dart2js, and **4.00×** on dart2wasm.
2. **O(n·m) prefix-sum `stackOffsetWiggle` + single-pass `stackOrderInsideOut` + cached constant
   keys (`lib/src/offset/wiggle.dart`, `lib/src/order/insideOut.dart`, `lib/src/stack.dart`):**
   replaces the O(n²·m) inner `k` loop with a running prefix sum and fuses `sums` + `peaks` in
   `stackOrderInsideOut`, cutting `stack.wiggle` by **1.93×** on AOT (**1.73× faster than
   Node.js**), **1.81×** on dart2js, and **2.27×** on dart2wasm.
3. **Fused X/Y tridiagonal solve with `Float64List` in `NaturalCurve`
   (`lib/src/curve/natural.dart`):** shares the diagonal `b` and forward multipliers across `x` and
   `y` without allocating separate second-control-point arrays, speeding up `line.natural100` by
   **1.55×** on AOT (**4.95× faster than Node.js**) and **1.65×** on Wasm.
4. **Precomputed pentagram trig constants in `SymbolStar` (`lib/src/symbol/star.dart`):**
   eliminates 8 `sin`/`cos` calls per star, cutting `symbol.star50` by **1.43×** on AOT (**7.9×
   faster than Node.js**) and **1.37×** on Wasm.
5. **Direct bump emission in `Link`, inline 2-trig `BumpRadial`, `sqrt`/identity fast paths for
   `CatmullRom` (`alpha = 0.5 / 1.0`), constant-accessor fast paths in `Arc`/`ShapeSymbol`, and
   always-defined tight loops + `Float64List` in `Line`/`Area`:** 1.05–1.17× faster across all
   curves, arcs, links, and areas.
6. **Rejected:** fusing default `stackOrderNone` + `stackOffsetNone` into `Stack.call`'s
   `List.generate` closure regressed AOT `stack.none` from 5,010 ns to 6,252 ns due to branching
   inside the generic allocation loop; reverted to keep the monomorphic `List.generate` loop
   (4,911 ns on AOT).

| Case | Node.js | AOT base → opt | AOT / Node | dart2js base → opt | dart2wasm base → opt |
|---|---:|---|---:|---|---|
| `arc.plain20` | 14,817 | 4,422 → **4,132** (1.07×) | **0.28×** | 10,348 → 10,133 (1.02×) | 6,906 → **6,464** (1.07×) |
| `arc.roundedPad20` | 35,063 | 12,142 → **11,101** (1.09×) | **0.32×** | 26,610 → 25,296 (1.05×) | 15,635 → **15,295** (1.02×) |
| `pie.20` | 878 | 1,681 → **489** (3.44×) | **0.56×** | 1,270 → **615** (2.06×) | 1,785 → **446** (4.00×) |
| `line.linear100` | 5,751 | 2,488 → **2,353** (1.06×) | **0.41×** | 4,779 → **4,309** (1.11×) | 3,926 → **3,404** (1.15×) |
| `line.basis100` | 30,600 | 6,366 → **6,147** (1.04×) | **0.20×** | 30,078 → 28,979 (1.04×) | 10,893 → **9,578** (1.14×) |
| `line.cardinal100` | 30,707 | 6,341 → **5,903** (1.07×) | **0.19×** | 28,847 → 27,975 (1.03×) | 9,843 → **9,401** (1.05×) |
| `line.catmullRom100` | 26,451 | 7,914 → **7,161** (1.11×) | **0.27×** | 24,336 → 23,603 (1.03×) | 12,196 → **10,900** (1.12×) |
| `line.monotoneX100` | 29,647 | 7,009 → **6,610** (1.06×) | **0.22×** | 28,323 → 27,065 (1.05×) | 11,240 → **9,808** (1.15×) |
| `line.natural100` | 34,924 | 10,957 → **7,052** (1.55×) | **0.20×** | 32,566 → 31,533 (1.03×) | 17,070 → **10,338** (1.65×) |
| `line.step100` | 12,401 | 4,266 → **4,074** (1.05×) | **0.33×** | 10,740 → **9,529** (1.13×) | 6,599 → **5,744** (1.15×) |
| `area.linear100` | 13,053 | 5,238 → **4,584** (1.14×) | **0.35×** | 11,202 → 11,104 (1.01×) | 6,883 → **5,906** (1.17×) |
| `area.monotoneX100` | 62,229 | 13,926 → **12,711** (1.10×) | **0.20×** | 57,623 → 55,434 (1.04×) | 20,379 → **19,528** (1.04×) |
| `area.basis100` | 73,829 | 13,687 → **11,807** (1.16×) | **0.16×** | 71,859 → 68,875 (1.04×) | 20,837 → **18,667** (1.12×) |
| `lineRadial.100` | 12,765 | 4,222 → **3,864** (1.09×) | **0.30×** | 11,160 → **9,741** (1.15×) | 6,892 → **6,033** (1.14×) |
| `linkHorizontal.50` | 20,689 | 6,464 → **5,981** (1.08×) | **0.29×** | 16,304 → 16,600 (0.98×) | 13,960 → **12,923** (1.08×) |
| `linkRadial.50` | 36,161 | 7,640 → **7,292** (1.05×) | **0.20×** | 26,788 → 25,597 (1.05×) | 15,476 → **14,853** (1.04×) |
| `symbol.circle50` | 25,973 | 5,607 → **5,518** (1.02×) | **0.21×** | 18,306 → 19,189 (0.95×) | 8,974 → **8,246** (1.09×) |
| `symbol.star50` | 77,880 | 14,077 → **9,844** (1.43×) | **0.13×** | 63,992 → 59,994 (1.07×) | 21,073 → **15,396** (1.37×) |
| `stack.none` | 4,045 | 5,010 → **4,911** (1.02×) | 1.21× | 6,801 → **5,913** (1.15×) | 6,509 → **6,392** (1.02×) |
| `stack.wiggle` | 12,221 | 13,589 → **7,052** (1.93×) | **0.58×** | 13,020 → **7,177** (1.81×) | 21,988 → **9,701** (2.27×) |

## 3. Native Flutter Release Builds: macOS & Android (ns/op)

`ui.*` measure `UiPathContext` building a reusable native `dart:ui.Path` (including `reset()` and
`path.getBounds().right`), bypassing SVG string formatting completely.

| Case | macOS M3 Max AOT | Pixel 8a Android AOT |
|---|---:|---:|
| `arc.plain20` | 4,438 | 8,242 |
| `arc.roundedPad20` | 12,470 | 20,506 |
| `pie.20` | 512 | 714 |
| `line.linear100` | 2,544 | 4,092 |
| `line.basis100` | 6,501 | 12,055 |
| `line.cardinal100` | 6,376 | 10,722 |
| `line.catmullRom100` | 7,757 | 12,757 |
| `line.monotoneX100` | 6,995 | 11,652 |
| `line.natural100` | 7,597 | 13,352 |
| `line.step100` | 4,319 | 7,350 |
| `area.linear100` | 4,958 | 7,999 |
| `area.monotoneX100` | 13,903 | 22,637 |
| `area.basis100` | 12,805 | 22,400 |
| `lineRadial.100` | 4,190 | 6,399 |
| `linkHorizontal.50` | 6,244 | 10,306 |
| `linkRadial.50` | 7,982 | 11,867 |
| `symbol.circle50` | 6,029 | 11,238 |
| `symbol.star50` | 11,095 | 15,923 |
| `stack.none` | 5,240 | 9,608 |
| `stack.wiggle` | 7,514 | 13,617 |
| **`ui.arc.roundedPad20`** | **17,744** | **29,043** |
| **`ui.line.linear100`** | **2,216** | **5,825** |
| **`ui.line.monotoneX100`** | **3,896** | **7,287** |
| **`ui.line.catmullRom100`** | **4,049** | **8,045** |
| **`ui.area.monotoneX100`** | **7,317** | **13,662** |
| **`ui.linkHorizontal.50`** | **3,238** | **9,042** |
| **`ui.symbol.star50`** | **8,169** | **13,906** |

## 4. Desktop & Mobile Browsers (ns/op)

Each cell shows `upstream JS / dart2js / dart2wasm`.

| Case | Chrome 158 (up / js / wasm) | Firefox 160 (up / js / wasm) | Safari 27 (up / js / wasm) | Pixel Chrome 157 (up / js / wasm) |
|---|---|---|---|---|
| `arc.plain20` | 12,988 / 8,594 / **6,104** | 15,625 / 13,672 / **9,277** | 14,648 / **7,813** / 16,602 | 23,047 / 16,991 / **11,327** |
| `arc.roundedPad20` | 30,859 / 22,268 / **15,723** | 29,297 / 29,297 / **19,531** | 33,203 / **23,438** / 27,344 | 57,422 / 43,750 / **25,779** |
| `pie.20` | 824 / 696 / **381** | 732 / **580** / 641 | 732 / **244** / 488 | 1,880 / 2,808 / **610** |
| `line.linear100` | 4,761 / 4,345 / **3,149** | 8,789 / 9,766 / **4,883** | 7,324 / **5,859** / 6,348 | 10,303 / 10,938 / **4,981** |
| `line.basis100` | 24,805 / 19,921 / **9,423** | 35,156 / 37,109 / **14,648** | 31,250 / 27,344 / **23,438** | 48,828 / 41,016 / **16,309** |
| `line.cardinal100` | 23,340 / 20,311 / **9,472** | 35,156 / 35,156 / **13,672** | 29,297 / 25,391 / **23,438** | 41,211 / 39,453 / **16,015** |
| `line.catmullRom100` | 23,438 / 20,705 / **10,742** | 35,156 / 37,109 / **15,625** | 29,297 / 25,391 / **21,484** | 40,234 / 37,500 / **16,895** |
| `line.monotoneX100` | 21,289 / 17,675 / **10,352** | 33,203 / 35,156 / **14,648** | 27,344 / **21,484** / **21,484** | 37,500 / 35,545 / **16,113** |
| `line.natural100` | 27,148 / 25,193 / **10,449** | 37,109 / 37,109 / **15,625** | 31,250 / 25,391 / **23,438** | 45,508 / 46,484 / **17,970** |
| `line.step100` | 9,424 / 9,082 / **5,761** | 16,602 / 18,555 / **8,789** | 14,648 / **8,301** / 11,719 | 20,020 / 20,702 / **9,717** |
| `area.linear100` | 11,475 / 11,915 / **5,859** | 18,555 / 19,531 / **9,277** | 17,578 / 15,625 / **10,742** | 23,340 / 27,344 / **9,620** |
| `area.monotoneX100` | 47,266 / 40,621 / **20,703** | 66,406 / 74,219 / **29,297** | 58,594 / 46,875 / **42,969** | 82,813 / 78,516 / **31,447** |
| `area.basis100` | 53,125 / 42,969 / **19,043** | 66,406 / 74,219 / **27,344** | 62,500 / 54,688 / **42,969** | 91,406 / 89,070 / **32,227** |
| `lineRadial.100` | 13,086 / 9,960 / **5,664** | 13,672 / 14,648 / **7,813** | 13,672 / 13,672 / **9,766** | 21,680 / 17,578 / **9,229** |
| `linkHorizontal.50` | 19,043 / 14,160 / **11,034** | 33,203 / 33,203 / **18,555** | 21,484 / **13,672** / 18,555 | 36,523 / 31,053 / **19,140** |
| `linkRadial.50` | 30,664 / 21,096 / **12,403** | 37,109 / 33,203 / **19,531** | 31,250 / 23,438 / **19,531** | 57,031 / 44,141 / **22,264** |
| `symbol.circle50` | 18,164 / 11,230 / **8,154** | 20,508 / 16,602 / **15,625** | 22,461 / **14,648** / 31,250 | 36,328 / 24,414 / **17,383** |
| `symbol.star50` | 47,461 / 34,961 / **15,430** | 66,406 / 62,500 / **25,391** | 58,594 / 39,063 / **23,438** | 87,109 / 64,059 / **25,588** |
| `stack.none` | **3,320** / 4,492 / 4,761 | **5,615** / 9,277 / 6,836 | 6,348 / **5,371** / 5,859 | 12,891 / 21,096 / **9,570** |
| `stack.wiggle` | 10,254 / **6,446** / 6,788 | 14,648 / 11,719 / **10,742** | 12,695 / **6,836** / 7,813 | 28,125 / 25,781 / **13,575** |
