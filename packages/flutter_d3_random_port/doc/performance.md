# d3-random port performance

This file records the speed figures of `flutter_d3_random_port` against upstream `d3-random` v3.0.1
across Node.js, macOS native AOT, Flutter release builds on macOS and Android, desktop browsers
(Chrome, Firefox, Safari), and mobile browsers (Chrome and Firefox on Android). Each faster form is
recorded under row `adapt-random-fast-forms` in [differences.md](differences.md) and verified
bit-for-bit against literal upstream implementations and Node.js reference vectors by
`test/port/faster_forms_test.dart` and `test/port/reference_test.dart`.

## 1. Test bed

- Apple M3 Max, macOS 27.0.1, on AC power (2026-11-27).
- Flutter `master` (3.51.0-1.0.pre-31, Dart 3.15.0), Node.js v24.22.1 (`darwin-arm64`).
- Pixel 8a, Android 17 (API 37) — Flutter AOT `--release` APK (`android-arm64`), Mobile Chrome 157,
  and Mobile Firefox 160.
- Physical iOS device was unavailable during this capture (`devicectl` reported offline/locked);
  macOS and Android AOT figures were recorded directly on hardware.
- Desktop browsers on macOS: Chrome 157, Firefox 160, Safari 27.0.1.
- Instrument: `tool/bench/d3_random_bench.dart` and `tool/bench/d3_random_bench.mjs` run 16
  identical seeded `randomLcg(0.42)` workloads (`ns/op`, median across 9 timed CLI/native batches
  or 7 timed browser batches after warmup, lower is better): 10,000 draws each of `randomLcg`,
  `randomUniform(-5, 10)`, `randomInt(10, 42)`, `randomNormal(100, 15)`, `randomLogNormal(1.5, 0.5)`,
  `randomBates(10)`, `randomExponential(0.25)`, `randomPareto(3)`, `randomBernoulli(0.35)`,
  `randomGeometric(0.25)`, `randomGamma(5, 1.5)`, `randomBeta(2.7, 0.3)`, and
  `randomWeibull(3, 1, 2)`; 2,000 draws each of `randomBinomial(200, 0.37)` and
  `randomPoisson(250)`; and a 10,000-element `Float64List` batch fill (`normal.fill_10000`).

## 2. Baseline vs optimized (macOS CLI: Node.js, AOT, dart2js, dart2wasm)

Optimizations applied (row `adapt-random-fast-forms`):

1. **Unboxed 32-bit unsigned LCG state (`lib/src/lcg.dart`):** stores the 32-bit state as an
   unboxed `int` field in `_LcgState` and computes `(_mul * _state + _inc) & 0xffffffff`, safe
   across both 64-bit native integers and 53-bit IEEE 754 JS doubles (`0x19660D * 0xffffffff +
   0x3C6EF35F < 2^53`). Speeds up `lcg.draw_10000` by **5.55×** on AOT (**4.21× faster than
   Node.js**) and **1.94×** on `dart2js` (**6.47× faster than Node.js** on `dart2wasm`).
2. **Unboxed Marsaglia polar state with cached scale (`lib/src/normal.dart`, `logNormal.dart`):**
   replaces nullable `double? x` closure capture with unboxed `double` fields and caches
   `sqrt(-2 * log(r) / r)` across the paired draw, halving `log`/`sqrt` evaluations while staying
   bit-exact. Cuts `normal.draw_10000` by **2.23×** on AOT (**1.98× faster than Node.js**) and
   **1.76×** on `dart2wasm`.
3. **Zero-allocation compound draws (`lib/src/gamma.dart`, `beta.dart`, `binomial.dart`,
   `poisson.dart`):** invokes `NormalPolarState.nextStandard()` directly inside Marsaglia-Tsang,
   eliminates per-draw `multiplier` and `outerFunc` closures (`gamma.dart`, `weibull.dart`), and
   adds zero-allocation `sampleOne` entry points so `binomial` and `poisson` never allocate
   intermediate beta/gamma/geometric closures per iteration. Cuts `gamma.draw_10000` by **1.85×**,
   `beta.draw_10000` by **1.68×**, `binomial.draw_2000` by **2.00×**, and `poisson.draw_2000` by
   **1.77×** on AOT.
4. **Specialized `randomLog1m` and typed batch `fill`/`sample` (`lib/src/defaultSource.dart`,
   `lib/src/*.dart`):** eliminates NaN/Infinity guards and skips Kahan division whenever
   `1.0 - (1.0 - u) == u`, and fills `Float64List`/`Int32List` directly in tight paired/monomorphic
   loops (`normal.fill_10000` is **2.07× faster than Node.js** on AOT and **1.93× faster** on
   `dart2wasm`).

On macOS CLI benchmarks, **`dart2wasm` beats Node.js on 15/16 workloads** (up to **6.47× faster**),
**macOS AOT beats Node.js on 12/16 workloads** (up to **4.21× faster**), and **`dart2js` beats
Node.js on 11/16 workloads**.

| Case | Node.js | AOT base → opt | AOT / Node | dart2js base → opt | dart2wasm base → opt |
|---|---:|---|---:|---|---|
| `lcg.draw_10000` | 70,588 | 93,082 → **16,759** (5.55×) | **0.24×** | 128,828 → **66,250** (1.94×) | 11,543 → **10,906** (1.06×) |
| `uniform.draw_10000` | 77,065 | 126,109 → 96,914 (1.30×) | 1.26× | 112,773 → **64,457** (1.75×) | 53,416 → **28,164** (1.90×) |
| `int.draw_10000` | 70,823 | 50,170 → **44,432** (1.13×) | **0.63×** | 134,031 → **63,961** (2.10×) | 39,242 → **28,900** (1.36×) |
| `normal.draw_10000` | 221,092 | 248,594 → **111,426** (2.23×) | **0.50×** | 309,313 → **219,672** (1.41×) | 258,070 → **146,969** (1.76×) |
| `logNormal.draw_10000` | 379,900 | 337,203 → **212,258** (1.59×) | **0.56×** | 434,359 → **372,156** (1.17×) | 415,375 → **307,516** (1.35×) |
| `bates.draw_10000` | 732,609 | 841,656 → 775,156 (1.09×) | 1.06× | 1,131,688 → 750,844 (1.51×) | 346,359 → **288,078** (1.20×) |
| `exponential.draw_10000` | 116,981 | 127,758 → 124,148 (1.03×) | 1.06× | 163,164 → 191,938 (0.85×) | 116,160 → **109,793** (1.06×) |
| `pareto.draw_10000` | 155,604 | 175,086 → 167,773 (1.04×) | 1.08× | 161,984 → 162,445 (1.00×) | 129,969 → **129,328** (1.00×) |
| `bernoulli.draw_10000` | 70,463 | 47,387 → **45,709** (1.04×) | **0.65×** | 130,422 → **70,340** (1.85×) | 30,652 → **26,533** (1.16×) |
| `geometric.draw_10000` | 141,009 | 112,641 → **101,035** (1.11×) | **0.72×** | 165,742 → 173,453 (0.96×) | 153,625 → 144,328 (1.06×) |
| `gamma.draw_10000` | 424,518 | 540,625 → **292,594** (1.85×) | **0.69×** | 447,500 → **399,469** (1.12×) | 411,141 → **301,453** (1.36×) |
| `beta.draw_10000` | 1,183,643 | 1,312,813 → **783,094** (1.68×) | **0.66×** | 1,215,813 → **1,046,250** (1.16×) | 1,139,313 → **774,500** (1.47×) |
| `weibull.draw_10000` | 293,246 | 289,063 → **230,273** (1.26×) | **0.79×** | 271,734 → 361,750 (0.75×) | 261,750 → **275,172** (0.95×) |
| `binomial.draw_2000` | 622,159 | 671,688 → **335,359** (2.00×) | **0.54×** | 648,406 → **511,094** (1.27×) | 609,844 → **383,406** (1.59×) |
| `poisson.draw_2000` | 542,660 | 529,219 → **299,703** (1.77×) | **0.55×** | 589,969 → **505,406** (1.17×) | 545,375 → **372,391** (1.46×) |
| `normal.fill_10000` | 224,637 | 199,320 → **108,410** (1.84×) | **0.48×** | 310,328 → **177,516** (1.75×) | 167,055 → **116,297** (1.44×) |

## 3. Native Flutter Release Builds: macOS & Android (ns/op)

Measured in standalone Flutter `--release` builds (`darwin-arm64` and `android-arm64`):

- **macOS M3 Max Flutter AOT:** beats desktop M3 Max Node.js on **12/16 workloads** (up to **4.11×
  faster** on `lcg.draw_10000`, **2.11× faster** on `normal.fill_10000`, **1.90× faster** on
  `normal.draw_10000`, and **1.88× faster** on `binomial.draw_2000`).
- **Pixel 8a Android 17 AOT:** beats desktop M3 Max Node.js on **6/16 workloads** (`lcg`, `normal`,
  `logNormal`, `binomial`, `poisson`, `normal.fill`), and beats Mobile Chrome upstream JS on the
  same Pixel 8a on **14/16 workloads** (up to **3.83× faster** on `lcg.draw_10000`, **2.79× faster**
  on `normal.fill_10000`, and **2.46× faster** on `binomial.draw_2000`).

| Case | Node.js upstream | macOS M3 Max AOT | Pixel 8a Android AOT | Pixel Chrome upstream | Android AOT vs Pixel JS |
|---|---:|---:|---:|---:|---:|
| `lcg.draw_10000` | 70,588 | **17,160** | **34,455** | 132,031 | **3.83× faster** |
| `uniform.draw_10000` | 77,065 | 98,223 | 156,508 | 133,594 | 0.85× |
| `int.draw_10000` | 70,823 | **50,686** | 97,469 | 157,813 | **1.62× faster** |
| `normal.draw_10000` | 221,092 | **116,105** | **169,109** | 389,063 | **2.30× faster** |
| `logNormal.draw_10000` | 379,900 | **225,641** | **358,781** | 603,125 | **1.68× faster** |
| `bates.draw_10000` | 732,609 | 800,906 | 1,267,438 | 1,375,000 | **1.08× faster** |
| `exponential.draw_10000` | 116,981 | 125,477 | 222,813 | 260,938 | **1.17× faster** |
| `pareto.draw_10000` | 155,604 | 184,742 | 293,750 | 284,375 | 0.97× |
| `bernoulli.draw_10000` | 70,463 | **48,650** | 95,160 | 160,156 | **1.68× faster** |
| `geometric.draw_10000` | 141,009 | **102,152** | 196,086 | 251,563 | **1.28× faster** |
| `gamma.draw_10000` | 424,518 | **290,781** | 496,469 | 781,250 | **1.57× faster** |
| `beta.draw_10000` | 1,183,643 | **783,469** | 1,190,938 | 1,875,000 | **1.57× faster** |
| `weibull.draw_10000` | 293,246 | **233,164** | 374,656 | 459,375 | **1.23× faster** |
| `binomial.draw_2000` | 622,159 | **331,781** | **432,703** | 1,062,500 | **2.46× faster** |
| `poisson.draw_2000` | 542,660 | **335,453** | **426,516** | 975,000 | **2.29× faster** |
| `normal.fill_10000` | 224,637 | **106,551** | **144,938** | 404,688 | **2.79× faster** |

## 4. Desktop & Mobile Browsers (ns/op)

Each cell shows `upstream JS / dart2js / dart2wasm` (fastest highlighted in bold):

- **Desktop Chrome 157:** `dart2wasm` beats upstream JS on **all 16/16 workloads** (up to **10.63×
  faster** on `lcg.draw_10000`, **10.60× faster** on `uniform.draw_10000`, **9.23× faster** on
  `bates.draw_10000`, and **3.84× faster** on `normal.fill_10000`); `dart2js` beats upstream JS on
  **14/16 workloads** (up to **1.83× faster**).
- **Pixel 8a Mobile Chrome 157:** both `dart2wasm` and `dart2js` beat upstream JS on **all 16/16
  workloads** (`dart2wasm` up to **7.64× faster** on `lcg.draw_10000`, **6.62× faster** on
  `bates.draw_10000`, and **4.08× faster** on `normal.fill_10000`; `dart2js` up to **3.22× faster**).
- **Desktop Firefox 160:** `dart2wasm` beats upstream JS on **12/16 workloads** (up to **2.00×
  faster** on `lcg.draw_10000` and **1.55× faster** on `normal.fill_10000`); `dart2js` beats
  upstream JS on **9/16 workloads** (up to **1.42× faster**).
- **Pixel 8a Mobile Firefox 160:** `dart2js` beats upstream JS on **8/16 workloads** (up to **2.24×
  faster** on `normal.fill_10000`), and `dart2wasm` beats upstream JS on **7/16 workloads** (up to
  **1.75× faster** on `normal.fill_10000`).
- **Desktop Safari 27.0.1:** `dart2wasm` beats upstream JS on `lcg.draw_10000` (**1.57× faster**),
  `normal.fill_10000` (**1.07× faster**), and `binomial.draw_2000` (**1.04× faster**), while
  JavaScriptCore's FTL JIT aggressively specializes upstream simple closures.

| Case | Chrome 157 (up / js / wasm) | Firefox 160 (up / js / wasm) | Safari 27.0.1 (up / js / wasm) | Pixel Chrome 157 (up / js / wasm) | Pixel Firefox 160 (up / js / wasm) |
|---|---|---|---|---|---|
| `lcg.draw_10000` | 118,359 / 67,574 / **11,132** | 66,406 / 105,469 / **33,203** | 17,578 / 132,813 / **11,230** | 132,031 / 64,840 / **17,285** | 62,500 / 66,406 / **60,547** |
| `uniform.draw_10000` | 117,969 / 66,406 / **11,132** | 66,406 / 101,563 / **62,500** | **11,230** / 125,000 / 35,156 | 133,594 / 89,063 / **27,734** | **62,500** / 66,406 / 125,000 |
| `int.draw_10000` | 119,531 / 65,238 / **11,425** | 66,406 / 101,563 / **62,500** | **12,207** / 125,000 / 33,203 | 157,813 / 83,594 / **28,516** | **66,406** / 113,281 / 125,000 |
| `normal.draw_10000` | 189,844 / 166,414 / **84,371** | 234,375 / 226,563 / **203,125** | **97,656** / 210,938 / 117,188 | 389,063 / 230,469 / **135,156** | 296,875 / **265,625** / 343,750 |
| `logNormal.draw_10000` | 306,250 / 254,672 / **146,867** | 421,875 / **343,750** / **343,750** | **140,625** / 234,375 / 218,750 | 603,125 / 409,391 / **239,063** | 625,000 / **500,000** / 531,250 |
| `bates.draw_10000` | 1,075,000 / 903,125 / **116,410** | 656,250 / 1,000,000 / **562,500** | **97,656** / 1,375,000 / 296,875 | 1,375,000 / 637,500 / **207,813** | **656,250** / 812,500 / 1,125,000 |
| `exponential.draw_10000` | 122,266 / 124,211 / **44,727** | **117,188** / 148,438 / 164,063 | **58,594** / 171,875 / 109,375 | 260,938 / 176,563 / **136,719** | **156,250** / 195,313 / 250,000 |
| `pareto.draw_10000` | 168,750 / 160,938 / **100,395** | **125,000** / **125,000** / 195,313 | **89,844** / 171,875 / 179,688 | 284,375 / 222,656 / **155,469** | **164,063** / 210,938 / 281,250 |
| `bernoulli.draw_10000` | 115,625 / 90,234 / **11,084** | 66,406 / 101,563 / **62,500** | **11,230** / 140,625 / 33,203 | 160,156 / 76,563 / **32,813** | **66,406** / 113,281 / 101,563 |
| `geometric.draw_10000` | 146,094 / 107,809 / **50,584** | **128,906** / 179,688 / 203,125 | **66,406** / 171,875 / 140,625 | 251,563 / 177,344 / **98,824** | **164,063** / 281,250 / 296,875 |
| `gamma.draw_10000` | 404,687 / 334,375 / **177,344** | 500,000 / 468,750 / **437,500** | **218,750** / 421,875 / 265,625 | 781,250 / 470,328 / **239,078** | 656,250 / 593,750 / **562,500** |
| `beta.draw_10000` | 1,206,250 / 787,531 / **506,281** | 1,312,500 / **1,000,000** / 1,062,500 | **562,500** / 1,062,500 / 718,750 | 1,875,000 / 1,187,500 / **715,625** | 1,875,000 / **1,437,500** / 1,562,500 |
| `weibull.draw_10000` | 228,125 / 253,141 / **166,398** | 265,625 / **250,000** / 375,000 | **156,250** / 234,375 / 312,500 | 459,375 / 337,500 / **265,625** | 390,625 / **375,000** / 515,625 |
| `binomial.draw_2000` | 621,875 / 387,516 / **256,250** | 718,750 / 593,750 / **531,250** | 390,625 / 453,125 / **375,000** | 1,062,500 / 678,094 / **348,453** | 1,000,000 / 781,250 / **718,750** |
| `poisson.draw_2000` | 500,000 / 362,500 / **237,500** | 656,250 / 562,500 / **531,250** | **343,750** / 468,750 / 359,375 | 975,000 / 521,844 / **334,391** | 812,500 / **687,500** / 781,250 |
| `normal.fill_10000` | 229,688 / 149,227 / **59,770** | 265,625 / 187,500 / **171,875** | 117,188 / 210,938 / **109,375** | 404,688 / 125,781 / **99,215** | 437,500 / **195,313** / 250,000 |
