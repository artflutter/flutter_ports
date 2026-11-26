# d3-format port performance

This file records the speed figures of `flutter_d3_format_port` against upstream `d3-format` v3.1.2
across Node.js, macOS native AOT, Flutter release builds on macOS, iOS, and Android, desktop
browsers (Chrome, Firefox, Safari), and mobile browsers (Chrome and Firefox on Android). Each
faster form is recorded under row `adapt-format-fast-forms` in [differences.md](differences.md) and
verified against literal upstream algorithms by `test/port/faster_forms_test.dart`.

## 1. Test bed

- Apple M3 Max, macOS 27.0.1, on AC power (2026-11-26).
- Flutter `master` (3.51.0-1.0.pre-31, Dart 3.15.0), Node.js v24.22.1 (V8 13.6.233.17-node.58,
  darwin-arm64).
- iOS 27.2 device (`ios-arm64`) — Flutter AOT release build.
- Pixel 8a, Android 17 (API 37) — Flutter AOT release APK (`android-arm64`), Mobile Chrome 157,
  and Mobile Firefox 160.
- Desktop browsers on macOS: Chrome 157, Firefox 160, Safari 27.0.1.
- Instrument: `tool/bench/d3_format_bench.dart` and `tool/bench/d3_format_bench.mjs` run 20
  identical seeded workloads (`ns/op`, median across 7 timed batches after warmup, lower is better).
  `parse.specifier16` and `compile.format16` run 16 specifiers per op; all formatting workloads
  format 64 seeded values per op.

## 2. Baseline vs optimized (macOS CLI: Node.js, AOT, dart2js, dart2wasm)

Optimizations applied (row `adapt-format-fast-forms`):

1. **Single-pass UTF-16 code-unit `formatSpecifier` parser (`lib/src/formatSpecifier.dart`):**
   eliminates `RegExp` matching and capture-group allocations, cutting `parse.specifier16` by
   **24.58×** on AOT (**3.9× faster than Node.js**), **3.89×** on dart2js (**3.3× faster than
   Node.js**), and **14.81×** on dart2wasm (**2.7× faster than Node.js**).
2. **Concrete precomputed `NumberFormat` class (`lib/src/locale.dart`):** precomputes all
   specifier flags, currency/radix affixes, group/numeral transforms, and inline `formatPrefix`
   scale factors once at compile time without closure allocations, cutting `compile.format16` by
   **4.21×** on AOT, **2.04×** on dart2js, and **5.73×** on dart2wasm.
3. **Direct Latin-1/UTF-16 buffer emission for `d`, `f`, `%`, `b`, `o`, `x`, `X`, and fused SI
   prefix `s` (`lib/src/locale.dart`, `lib/src/formatDecimal.dart`, `lib/src/formatPrefixAuto.dart`):**
   on AOT and Wasm, writes sign, prefix, grouped integer digits, fractional digits, radix digits,
   and locale numerals directly into reusable scratch `Uint8List`/`Uint16List` buffers with a
   mathematically guarded half-up tie check (`|frac - 0.5| > 2e-4` for `|y| < 1e12`), skipping
   intermediate strings, `RegExp` calls, and global mutable `prefixExponent` state. This speeds up
   `f.currency64` and `f.accounting64` by **9.2–9.4×** on AOT (**4.1× faster than Node.js**) and
   `locale.arAE64` by **16.37×** on AOT (**5.3× faster than Node.js**) and **33.45×** on dart2wasm
   (**7.2× faster than Node.js**).
4. **Platform-aware dart2js string paths (`lib/src/locale.dart`, `lib/src/formatGroup.dart`,
   `lib/src/formatNumerals.dart`, `lib/src/formatTrim.dart`):** avoids `Uint16List` +
   `String.fromCharCodes` overhead on dart2js (which regressed JS targets 5–15× in early prototypes)
   by using compact direct string slicing and concatenation on JS while keeping zero-allocation
   typed-array buffers on AOT and Wasm.

On CLI benchmarks, **dart2wasm beats Node.js on 20/20** workloads (up to **7.2× faster**),
**dart2js beats Node.js on 19/20** workloads (up to **3.3× faster**), and **macOS AOT beats
Node.js on 16/20** workloads (up to **5.3× faster**; **1.9×–24.6× faster** than baseline AOT).

| Case | Node.js | AOT base → opt | AOT / Node | dart2js base → opt | dart2wasm base → opt |
|---|---:|---|---:|---|---|
| `parse.specifier16` | 1,308 | 8,173 → **333** (24.58×) | **0.25×** | 1,554 → **399** (3.89×) | 7,091 → **479** (14.81×) |
| `compile.format16` | 3,326 | 10,780 → **2,561** (4.21×) | **0.77×** | 2,125 → **1,043** (2.04×) | 8,751 → **1,527** (5.73×) |
| `d.plain64` | 3,039 | 10,638 → **3,065** (3.47×) | 1.01× | 2,722 → **1,209** (2.25×) | 5,419 → **2,915** (1.86×) |
| `d.grouped64` | 8,700 | 21,882 → **3,828** (5.72×) | **0.44×** | 7,235 → **5,951** (1.22×) | 10,747 → **3,740** (2.87×) |
| `d.zeroPadGroup64` | 14,586 | 29,126 → **7,405** (3.93×) | **0.51×** | 11,811 → **10,466** (1.13×) | 16,097 → **5,464** (2.95×) |
| `f.fixed2_64` | 7,103 | 20,854 → **3,392** (6.15×) | **0.48×** | 7,079 → **4,268** (1.66×) | 11,647 → **3,559** (3.27×) |
| `f.currency64` | 14,936 | 32,967 → **3,600** (9.16×) | **0.24×** | 13,860 → **11,859** (1.17×) | 17,516 → **4,705** (3.72×) |
| `f.accounting64` | 14,007 | 31,908 → **3,395** (9.40×) | **0.24×** | 12,339 → **10,768** (1.15×) | 16,485 → **4,696** (3.51×) |
| `e.exp64` | 6,338 | 20,974 → **6,814** (3.08×) | 1.08× | 6,446 → **3,210** (2.01×) | 10,495 → **3,960** (2.65×) |
| `e.trim64` | 11,500 | 23,446 → **12,562** (1.87×) | 1.09× | 11,202 → **8,751** (1.28×) | 15,124 → **9,538** (1.59×) |
| `g.general64` | 6,497 | 21,611 → **6,959** (3.11×) | 1.07× | 6,226 → **3,495** (1.78×) | 10,223 → **3,741** (2.73×) |
| `none.default64` | 16,889 | 24,604 → **11,248** (2.19×) | **0.67×** | 17,193 → **15,313** (1.12×) | 20,438 → **14,712** (1.39×) |
| `s.siPrefix64` | 12,966 | 25,731 → **9,888** (2.60×) | **0.76×** | 14,544 → **9,240** (1.57×) | 16,539 → **7,633** (2.17×) |
| `s.siTrim64` | 18,002 | 28,678 → **10,957** (2.62×) | **0.61×** | 19,636 → **14,805** (1.33×) | 22,613 → **12,723** (1.78×) |
| `prefix.fixedM64` | 9,671 | 23,779 → **2,769** (8.59×) | **0.29×** | 9,496 → **7,808** (1.22×) | 13,045 → **3,079** (4.24×) |
| `pct.percent64` | 6,998 | 19,196 → **2,830** (6.78×) | **0.40×** | 7,540 → **5,321** (1.42×) | 10,682 → **2,486** (4.30×) |
| `hex.prefix64` | 10,312 | 8,691 → **4,209** (2.07×) | **0.41×** | 11,446 → 11,993 (0.95×) | 5,941 → **2,770** (2.14×) |
| `locale.frFR64` | 18,296 | 39,639 → **6,639** (5.97×) | **0.36×** | 16,038 → **15,518** (1.03×) | 19,136 → **4,871** (3.93×) |
| `locale.enIN64` | 17,963 | 35,652 → **6,672** (5.34×) | **0.37×** | 14,937 → **14,906** (1.00×) | 18,491 → **4,573** (4.04×) |
| `locale.arAE64` | 40,353 | 123,734 → **7,558** (16.37×) | **0.19×** | 48,396 → **30,738** (1.57×) | 188,688 → **5,642** (33.45×) |

## 3. Native Flutter Release Builds: macOS, iOS & Android (ns/op)

Measured in standalone Flutter `--release` builds (`darwin-arm64`, `ios-arm64`, and `android-arm64`).

| Case | macOS M3 Max AOT | iOS 27.2 AOT | Pixel 8a Android AOT |
|---|---:|---:|---:|
| `parse.specifier16` | 331 | **221** | 349 |
| `compile.format16` | 2,763 | **1,575** | 4,426 |
| `d.plain64` | 3,060 | **1,905** | 5,712 |
| `d.grouped64` | 3,213 | **2,004** | 5,734 |
| `d.zeroPadGroup64` | 7,729 | **5,228** | 11,570 |
| `f.fixed2_64` | 3,389 | **2,233** | 5,798 |
| `f.currency64` | 3,728 | **2,452** | 6,096 |
| `f.accounting64` | 3,418 | **2,444** | 5,511 |
| `e.exp64` | 7,883 | **4,700** | 9,548 |
| `e.trim64` | 11,342 | **7,232** | 14,177 |
| `g.general64` | 7,975 | **4,935** | 9,917 |
| `none.default64` | 12,114 | **7,328** | 13,910 |
| `s.siPrefix64` | 11,153 | **6,875** | 13,128 |
| `s.siTrim64` | 11,871 | **7,412** | 13,936 |
| `prefix.fixedM64` | 2,975 | **2,035** | 4,160 |
| `pct.percent64` | 3,029 | **1,964** | 3,939 |
| `hex.prefix64` | 4,460 | **3,221** | 8,878 |
| `locale.frFR64` | 7,754 | **4,995** | 11,543 |
| `locale.enIN64` | 7,686 | **4,850** | 11,302 |
| `locale.arAE64` | 8,597 | **5,844** | 12,526 |

## 4. Desktop & Mobile Browsers (ns/op)

Each cell shows `upstream JS / dart2js / dart2wasm` (fastest highlighted in bold).

- **Desktop Chrome 157:** `dart2js` beats upstream on **19/20**, `dart2wasm` beats upstream on
  **19/20**, best Dart target beats upstream on **20/20**.
- **Desktop Firefox 160:** `dart2js` beats upstream on **17/20**, `dart2wasm` beats upstream on
  **12/20**, best Dart target beats upstream on **18/20**.
- **Desktop Safari 27.0.1:** `dart2js` beats upstream on **19/20**, `dart2wasm` beats upstream on
  **15/20**, best Dart target beats upstream on **20/20**.
- **Mobile Chrome 157 (Pixel 8a):** `dart2js` beats upstream on **19/20**, `dart2wasm` beats
  upstream on **19/20**, best Dart target beats upstream on **20/20**.
- **Mobile Firefox 160 (Pixel 8a):** `dart2js` beats upstream on **10/20**, `dart2wasm` beats
  upstream on **9/20**, best Dart target beats upstream on **16/20**.

| Case | Chrome 157 (up / js / wasm) | Firefox 160 (up / js / wasm) | Safari 27.0.1 (up / js / wasm) | Pixel Chrome 157 (up / js / wasm) | Pixel Firefox 160 (up / js / wasm) |
|---|---|---|---|---|---|
| `parse.specifier16` | 1,196 / **320** / 412 | 1,587 / **641** / 1,221 | 977 / **366** / 1,709 | 2,332 / 1,117 / **671** | 2,075 / **1,038** / 4,150 |
| `compile.format16` | 3,247 / **781** / 1,282 | 5,371 / **1,953** / 3,174 | 3,174 / **1,038** / 4,150 | 10,059 / 4,004 / **2,075** | 8,301 / **2,930** / 5,859 |
| `d.plain64` | 1,917 / **720** / 2,979 | 2,930 / **1,221** / 5,127 | 3,418 / **977** / 4,150 | 3,052 / **1,129** / 4,565 | 4,639 / **2,075** / 8,789 |
| `d.grouped64` | 6,494 / 4,687 / **3,662** | 7,813 / 7,324 / **4,883** | 7,813 / 6,348 / **4,883** | 9,229 / 8,740 / **6,250** | 10,742 / 12,695 / **9,766** |
| `d.zeroPadGroup64` | 10,254 / 7,617 / **5,103** | 12,695 / 10,254 / **7,813** | 19,531 / 9,766 / **7,324** | 16,016 / 14,453 / **8,398** | 19,531 / 18,555 / **15,625** |
| `f.fixed2_64` | 5,811 / **3,296** / 3,614 | 6,348 / **2,930** / 5,859 | 7,813 / **3,418** / 4,395 | 11,426 / 7,177 / **5,567** | 9,766 / **4,639** / 10,742 |
| `f.currency64` | 11,914 / 8,691 / **4,810** | 12,695 / 11,719 / **6,348** | 18,555 / 10,742 / **5,859** | 20,508 / 18,653 / **7,813** | 19,531 / 19,531 / **12,695** |
| `f.accounting64` | 11,914 / 8,936 / **4,809** | 12,695 / 11,719 / **6,348** | 18,555 / 9,766 / **5,859** | 20,410 / 18,749 / **7,715** | 19,531 / 19,531 / **11,719** |
| `e.exp64` | 5,078 / **2,710** / 3,174 | 6,348 / **2,930** / 7,813 | 7,813 / **3,906** / 4,639 | 7,129 / **4,297** / 5,005 | 7,324 / **4,395** / 14,648 |
| `e.trim64` | 10,254 / **7,764** / 8,789 | 8,789 / **6,836** / 12,695 | 11,719 / **7,324** / 11,719 | 14,746 / **11,425** / 12,304 | **10,742** / **10,742** / 25,391 |
| `g.general64` | 5,225 / **2,759** / 3,247 | 6,348 / **3,418** / 7,813 | 8,789 / **4,150** / 4,883 | 7,666 / **4,565** / 5,176 | 7,324 / **4,639** / 14,648 |
| `none.default64` | 15,625 / **13,281** / 14,063 | 9,766 / **8,301** / 14,648 | 14,648 / **9,766** / 16,602 | 20,703 / 18,458 / **18,261** | 12,695 / **11,719** / 27,344 |
| `s.siPrefix64` | 9,863 / 7,714 / **6,787** | 14,648 / **11,719** / 16,602 | 16,602 / **11,719** / 13,672 | 14,844 / 14,356 / **10,646** | **13,672** / 19,531 / 31,250 |
| `s.siTrim64` | 15,723 / 13,770 / **11,230** | **14,648** / **14,648** / 16,602 | 21,484 / **14,648** / 15,625 | 22,266 / 21,682 / **16,309** | **17,578** / 23,438 / 33,203 |
| `prefix.fixedM64` | 7,471 / 5,957 / **3,125** | 7,324 / 7,324 / **4,883** | 13,672 / 8,301 / **4,639** | 14,160 / 12,305 / **4,785** | 10,742 / 11,719 / **8,301** |
| `pct.percent64` | 5,371 / 3,491 / **2,613** | 5,859 / **3,418** / 4,883 | 8,301 / 4,883 / **4,150** | 10,645 / 7,959 / **3,931** | 7,324 / **4,883** / 8,301 |
| `hex.prefix64` | 12,793 / 13,672 / **2,856** | **4,150** / 4,883 / 5,371 | 6,348 / 6,348 / **4,883** | 14,063 / 15,918 / **4,761** | **6,836** / 8,789 / 9,766 |
| `locale.frFR64` | 12,012 / 9,131 / **4,883** | 22,461 / 11,719 / **6,836** | 21,484 / 10,742 / **6,836** | 21,484 / 20,116 / **8,251** | 19,531 / 18,555 / **12,695** |
| `locale.enIN64` | 12,598 / 9,424 / **4,809** | 13,672 / 11,719 / **6,836** | 21,484 / 11,719 / **6,348** | 21,484 / 21,094 / **8,203** | 20,508 / 21,484 / **11,719** |
| `locale.arAE64` | 31,055 / 17,969 / **5,665** | 31,250 / 25,391 / **8,789** | 42,969 / 19,531 / **9,277** | 53,125 / 38,086 / **9,473** | 46,875 / 46,875 / **16,602** |
