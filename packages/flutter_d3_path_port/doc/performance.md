# d3-path port performance

This file records the speed figures of `flutter_d3_path_port` against upstream `d3-path` v3.1.0
across Node.js, macOS native AOT, Flutter release builds on macOS, iOS and Android, desktop
browsers (Chrome, Firefox, Safari) and mobile browsers (Android Chrome, Android Firefox).
Each faster form has a row in [differences.md](differences.md) and a twin test in
`test/port/faster_forms_test.dart`.

## 1. Test bed

- Apple M3 Max, macOS 27.0.1, on AC power (2026-11-26).
- Flutter `master` (3.51.0-1.0.pre-31, Dart 3.15.0), Node.js v24.22.1 (V8 13.6.233.17-node.58,
  darwin-arm64).
- iPhone 17 Pro (`Home_26+`), iOS 27.2 — signed Flutter AOT release build.
- Pixel 8a, Android 17 (API 37) — Flutter AOT release APK (`android-arm64`) + Chrome 157 +
  Firefox 160.
- Desktop browsers on macOS: HeadlessChrome 158, Firefox 161, Safari 27.
- Instrument: `tool/bench/d3_path_bench.dart` and `tool/bench/d3_path_bench.mjs` run 15 identical
  seeded `Path` serialization cases (`ns/op`, median, lower is better). Native Flutter release
  builds also measure 7 `UiPathContext` cases (`ui.*`) writing directly into `dart:ui.Path` with
  zero SVG string formatting.

## 2. Baseline vs optimized (macOS CLI: Node.js, AOT, dart2js, dart2wasm)

Optimizations applied (row `adapt-path-fast-forms`):

1. **Growable `Uint8List` ASCII buffer (`lib/src/path.dart`):** on native AOT and Wasm, `Path`
   writes command bytes and number digits directly into a `Uint8List(256)` and converts once in
   `toString()` via `String.fromCharCodes(_buf, 0, _len)`, avoiding per-coordinate `String`
   allocations.
2. **Direct integer & `pathRound(0..6)` decimal emission with multiply-shift + 2-digit table:**
   emits exact integers (`|x| <= 2^53`) and `pathRound(0..6)` coordinates (`|q| < 1e15`) directly
   into `_buf` without calling `double.toString()`, using multiply-shift for 4-digit/8-digit chunks
   and the 3 fractional digits of `pathRound(3)`. Cuts `*.round3` by **7.9–15.2×** on AOT (3.6–5.7×
   faster than Node.js) and **2.3–3.4×** on Wasm.
3. **Clean-room 30-bit-limb Ryū binary64 shortest-decimal emitter (hot/cold split):** replaces Dart
   VM's C++ `double.toString()` boundary call on full-precision floats with pure-Dart 64-bit integer
   Ryū (`e2 < 0` hot path inlined, `e2 >= 0` cold helper, lazily computed `BigInt` power-of-5 limb
   tables) writing directly into `_buf`. Cuts `*.full` by **2.9–4.4×** on AOT (beating Node.js on
   `arc20.full`, `arcTo20.full`, `rect50.full`, `mixed.full`).
4. **Zero `late` fields and shared dummy buffers on `dart2js`:** eliminates sentinel checks and
   typed-array allocations when compiling to JavaScript, keeping `StringBuffer` with JS's native
   Dragonbox `double.toString()` (beating Node.js on all 15 cases).
5. **Rejected:** routing Wasm full-precision floats through `v.toString()` + char-code copy into
   `_buf` regressed Wasm `polyline100.full` from 10.7 µs to 13.2 µs and `arcTo20.full` from 7.4 µs
   to 17.2 µs; kept pure-Dart Ryū on both AOT and Wasm.

| Case | Node.js | AOT base → opt | AOT / Node | dart2js base → opt | dart2wasm base → opt |
|---|---:|---|---:|---|---|
| `polyline100.full` | 5,145 | 31,936 → **7,368** (4.3×) | 1.43× | 3,743 → **3,600** (1.04×) | 9,730 → 10,677 (0.91×) |
| `polyline100.round3` | 7,760 | 30,346 → **2,112** (14.4×) | **0.27×** | 4,789 → 5,829 (0.82×) | 10,202 → **4,394** (2.32×) |
| `polyline100.int` | 4,780 | 8,711 → **1,381** (6.3×) | **0.29×** | 3,893 → **3,022** (1.29×) | 4,595 → **2,880** (1.60×) |
| `bezier50.full` | 8,251 | 46,748 → **10,633** (4.4×) | 1.29× | 6,880 → **6,134** (1.12×) | 14,734 → 16,253 (0.91×) |
| `bezier50.round3` | 12,040 | 45,379 → **3,041** (14.9×) | **0.25×** | 10,301 → **9,694** (1.06×) | 16,115 → **6,377** (2.53×) |
| `quad50.full` | 5,309 | 31,082 → **7,418** (4.2×) | 1.40× | 4,430 → **3,780** (1.17×) | 9,251 → 10,783 (0.86×) |
| `quad50.round3` | 7,520 | 30,619 → **2,010** (15.2×) | **0.27×** | 6,379 → **5,873** (1.09×) | 10,232 → **4,176** (2.45×) |
| `arc20.full` | 5,125 | 19,389 → **4,692** (4.1×) | **0.92×** | 4,121 → **3,802** (1.08×) | 6,780 → 7,086 (0.96×) |
| `arc20.round3` | 6,184 | 18,260 → **1,725** (10.6×) | **0.28×** | 4,974 → 5,107 (0.97×) | 7,447 → **3,241** (2.30×) |
| `arcTo20.full` | 10,830 | 17,949 → **6,268** (2.9×) | **0.58×** | 10,433 → 10,448 (1.00×) | 14,472 → **7,387** (1.96×) |
| `arcTo20.round3` | 9,014 | 18,068 → **2,299** (7.9×) | **0.26×** | 8,067 → **7,822** (1.03×) | 10,885 → **3,637** (2.99×) |
| `rect50.full` | 13,880 | 35,301 → **8,747** (4.0×) | **0.63×** | 12,236 → **11,690** (1.05×) | 18,251 → **13,448** (1.36×) |
| `rect50.round3` | 14,251 | 33,576 → **2,483** (13.5×) | **0.17×** | 13,398 → **12,550** (1.07×) | 17,913 → **5,261** (3.40×) |
| `mixed.full` | 1,442 | 4,189 → **1,360** (3.1×) | **0.94×** | 1,208 → **1,110** (1.09×) | 1,797 → **1,789** (1.00×) |
| `mixed.round3` | 1,920 | 4,052 → **450** (9.0×) | **0.23×** | 1,717 → 1,730 (0.99×) | 2,296 → **801** (2.87×) |

## 3. Native Flutter Release Builds: macOS, iOS & Android (ns/op)

`ui.*` measure `UiPathContext` building a reusable native `dart:ui.Path` (including `reset()` and
`path.getBounds().right`), bypassing SVG string serialization completely.

| Case | macOS M3 Max AOT | iPhone 17 Pro iOS AOT | Pixel 8a Android AOT |
|---|---:|---:|---:|
| `polyline100.full` | 7,656 | 9,804 | 23,316 |
| `polyline100.round3` | 2,149 | 4,382 | 4,758 |
| `polyline100.int` | 1,449 | 1,781 | 3,006 |
| `bezier50.full` | 11,024 | 16,070 | 28,629 |
| `bezier50.round3` | 3,153 | 4,977 | 5,481 |
| `quad50.full` | 7,831 | 11,767 | 19,108 |
| `quad50.round3` | 2,116 | 3,221 | 3,429 |
| `arc20.full` | 5,223 | 7,651 | 12,064 |
| `arc20.round3` | 1,794 | 2,823 | 3,354 |
| `arcTo20.full` | 6,841 | 7,181 | 12,700 |
| `arcTo20.round3` | 2,435 | 2,188 | 3,897 |
| `rect50.full` | 9,594 | 11,898 | 24,320 |
| `rect50.round3` | 2,679 | 3,508 | 4,406 |
| `mixed.full` | 1,407 | 1,981 | 3,192 |
| `mixed.round3` | 467 | 652 | 944 |
| **`ui.polyline100`** | **1,585** | **1,923** | **5,879** |
| **`ui.bezier50`** | **1,218** | **1,429** | **2,593** |
| **`ui.quad50`** | **1,003** | **914** | **2,169** |
| **`ui.arc20`** | **3,294** | **2,452** | **5,345** |
| **`ui.arcTo20`** | **4,086** | **4,502** | **6,115** |
| **`ui.rect50`** | **2,932** | **4,210** | **5,673** |
| **`ui.mixed`** | **707** | **905** | **1,209** |

## 4. Desktop Browsers on macOS (ns/op)

Each cell shows `upstream JS / dart2js / dart2wasm`.

| Case | Chrome 158 (up / js / wasm) | Firefox 161 (up / js / wasm) | Safari 27 (up / js / wasm) |
|---|---|---|---|
| `polyline100.full` | 3,857 / **2,344** / 10,157 | 12,695 / 14,648 / 19,531 | 8,301 / **3,418** / 42,969 |
| `polyline100.round3` | 6,689 / 4,980 / **4,249** | 12,695 / 15,625 / **5,859** | 9,766 / **5,859** / 8,789 |
| `polyline100.int` | 3,857 / 2,759 / **2,661** | 3,906 / 4,883 / **3,662** | 6,348 / **3,174** / 5,371 |
| `bezier50.full` | 5,762 / **3,955** / 15,236 | 19,531 / 21,484 / 29,297 | 9,766 / **5,371** / 31,250 |
| `bezier50.round3` | 10,547 / 7,373 / **6,348** | 17,578 / 21,484 / **8,789** | 13,672 / **9,766** / 12,695 |
| `quad50.full` | 3,662 / **2,539** / 10,254 | 12,695 / 13,672 / 19,531 | 5,859 / **3,174** / 19,531 |
| `quad50.round3` | 6,104 / 4,590 / **4,248** | 12,695 / 13,672 / **5,859** | 8,789 / **5,371** / 7,324 |
| `arc20.full` | 3,613 / **2,637** / 6,885 | 7,812 / 8,301 / 11,719 | 5,859 / **3,174** / 13,672 |
| `arc20.round3` | 5,127 / 3,906 / **3,101** | 7,324 / 7,812 / **3,906** | 6,836 / **3,906** / 6,836 |
| `arcTo20.full` | 5,859 / **4,981** / 7,421 | 8,789 / 9,766 / 12,695 | 8,789 / **6,348** / 14,648 |
| `arcTo20.round3` | 6,055 / 5,078 / **3,565** | 7,812 / 8,789 / **4,395** | 8,789 / **6,348** / 6,836 |
| `rect50.full` | 7,520 / **5,665** / 12,695 | 15,625 / 17,578 / 23,438 | 10,742 / **6,836** / 27,344 |
| `rect50.round3` | 9,473 / 7,080 / **5,127** | 15,625 / 17,578 / **6,836** | 11,719 / 9,766 / **8,789** |
| `mixed.full` | 1,025 / **781** / 1,770 | 1,953 / 2,441 / 3,418 | 1,587 / **1,099** / 3,418 |
| `mixed.round3` | 1,245 / 1,074 / **769** | 1,953 / 2,197 / **1,099** | 1,831 / **1,465** / **1,465** |

## 5. Mobile Browsers on Pixel 8a (ns/op)

Each cell shows `upstream JS / dart2js / dart2wasm`.

| Case | Pixel Chrome 157 (up / js / wasm) | Pixel Firefox 160 (up / js / wasm) |
|---|---|---|
| `polyline100.full` | 8,105 / **5,176** / 17,971 | 19,531 / 21,484 / 35,156 |
| `polyline100.round3` | 12,402 / 10,841 / **6,299** | 16,602 / 19,531 / **12,695** |
| `polyline100.int` | 7,324 / 9,766 / **4,639** | 5,859 / 9,277 / 7,812 |
| `bezier50.full` | 11,426 / **7,909** / 26,758 | 27,344 / 31,250 / 54,688 |
| `bezier50.round3` | 18,945 / 16,406 / **9,570** | 25,391 / 27,344 / **17,578** |
| `quad50.full` | 7,471 / **5,029** / 17,385 | 17,578 / 21,484 / 35,156 |
| `quad50.round3` | 11,816 / 9,961 / **6,201** | 16,602 / 17,578 / **11,719** |
| `arc20.full` | 6,885 / **4,834** / 11,621 | 11,719 / 12,695 / 23,438 |
| `arc20.round3` | 8,887 / 7,520 / **5,176** | 10,742 / 10,742 / **8,789** |
| `arcTo20.full` | 10,449 / **8,691** / 11,719 | 11,719 / 13,672 / 23,438 |
| `arcTo20.round3` | 10,254 / 9,472 / **5,176** | 10,742 / 11,719 / **9,766** |
| `rect50.full` | 13,672 / **10,547** / 22,461 | 21,484 / 27,344 / 46,875 |
| `rect50.round3` | 16,016 / 15,039 / **8,008** | 19,531 / 23,438 / **16,602** |
| `mixed.full` | 1,953 / **1,428** / 3,027 | 3,174 / 4,150 / 7,324 |
| `mixed.round3` | 2,246 / 2,100 / **1,221** | 2,930 / 3,174 / **2,197** |
