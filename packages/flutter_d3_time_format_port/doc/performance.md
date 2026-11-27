# d3-time-format port performance

This file records the speed figures of `flutter_d3_time_format_port` against upstream
`d3-time-format` v4.1.0 across Node.js, macOS native AOT, Flutter `--release` builds on macOS and
Android, desktop browsers (Chrome, Firefox, Safari), and mobile browsers (Chrome and Firefox on
Android). Each faster form is recorded under row `adapt-time-format-fast-forms` in
[differences.md](differences.md) and verified against literal upstream algorithms and Node.js
reference vectors by `test/port/faster_forms_test.dart`, `test/port/reference_test.dart`,
`test/port/locales_test.dart`, and `test/port/tz_test.dart`.

## 1. Test bed

- Apple M3 Max, macOS 27.0.1, on AC power (2026-11-27).
- Flutter `master` (3.51.0-1.0.pre-31, Dart 3.15.0), Node.js v24.22.1 (`darwin-arm64`).
- Pixel 8a, Android 17 (API 37) — Flutter AOT `--release` APK (`android-arm64`), Mobile Chrome 157,
  and Mobile Firefox 160. *(Physical iOS device was unavailable/disconnected during this capture.)*
- Desktop browsers on macOS: Chrome 157, Firefox 161, Safari 27.0.1.
- Instrument: `tool/bench/d3_time_format_bench.dart` and `tool/bench/d3_time_format_bench.mjs` run
  14 identical seeded Park-Miller LCG workloads (`ns/op`, median across 9 timed CLI/native batches
  and 7 browser batches after warmup, lower is better) over 1,000 timestamps spanning `1970–2050`:
  - Formatting (1,000 calls per op): `utcFormat.iso_1000` (`%Y-%m-%dT%H:%M:%S.%LZ`),
    `utcFormat.ymd_1000` (`%Y-%m-%d`), `utcFormat.locale_c_1000` (`%c`), `utcFormat.words_1000`
    (`%A, %B %e, %Y`), `utcFormat.weeks_doy_1000` (`%G-W%V-%u %j %U %W`), `timeFormat.local_1000`
    (`%Y-%m-%d %H:%M:%S %Z`), and `isoFormat.1000`.
  - Parsing (1,000 calls per op): `utcParse.iso_1000` (`%Y-%m-%dT%H:%M:%S.%LZ`),
    `utcParse.ymd_1000` (`%Y-%m-%d`), `utcParse.zone_1000` (`%Y-%m-%d %H:%M:%S %Z` with `+05:30`,
    `-0800`, `Z`, `+02`, `-0430`), `utcParse.words_1000` (`%a, %d %b %Y %H:%M:%S`),
    `utcParse.locale_c_1000` (`%c`), `utcParse.fr_words_1000` (`fr-FR` `%A %e %B %Y à %X`), and
    `isoParse.1000`.

## 2. Baseline vs optimized (macOS CLI: Node.js, AOT, dart2js, dart2wasm)

Optimizations applied (row `adapt-time-format-fast-forms`):

1. **Precompiled flat directive instruction lists (`lib/src/locale.dart`):** expands recursive
   `%c`/`%x`/`%X` specifiers and merges adjacent literal segments once when `format`/`parse` is
   constructed, avoiding runtime specifier re-scanning and tracking a `_fieldMask` so date-only
   specifiers skip time extraction and vice versa.
2. **Direct UTF-16/Latin-1 code-unit formatting & O(1) Hinnant calendar math
   (`lib/src/locale.dart`):** computes civil calendar fields, day-of-year (`%j`), Sunday/Monday
   weeks (`%U`/`%W`), and ISO 8601 week/year (`%V`/`%g`/`%G`) in O(1) integer arithmetic from a
   single epoch/offset lookup (zero intermediate `DateTime` allocations), writing directly into
   reusable `Uint8List`/`Uint16List` buffers on AOT & Wasm and 2-digit lookup tables +
   `StringBuffer` on `dart2js`. Speeds up `utcFormat.weeks_doy_1000` by **7.51×** on AOT
   (**23.70× faster than Node.js**), **5.22×** on `dart2js`, and **9.07×** on `dart2wasm`
   (**21.70× faster than Node.js**).
3. **Zero-`RegExp` direct code-unit numeric & `%Z` parsing + Hinnant `days_from_civil`
   (`lib/src/locale.dart`):** replaces per-directive `RegExp` execution and `String.substring`
   slicing with inline UTF-16 code-unit scanning, stack-allocated parser state (zero `_ParsedDate`
   heap object), and O(1) civil-to-epoch millisecond conversion. Speeds up `utcParse.iso_1000` by
   **6.40×** on AOT, **8.66×** on `dart2js`, and **14.58×** on `dart2wasm` (**7.57× faster than
   Node.js**).
4. **Pre-indexed case-insensitive locale lookup tables (`_NameMatcher` in `lib/src/locale.dart`):**
   buckets weekday, month, and period names by folded first code unit while preserving exact
   upstream left-to-right alternation order, eliminating `RegExp` and `toLowerCase()` allocations on
   ASCII and exact-cased Unicode inputs. Speeds up `utcParse.words_1000` by **6.38×** on AOT,
   **7.67×** on `dart2js`, and **8.36×** on `dart2wasm`, and `utcParse.fr_words_1000` by **6.10×**
   on AOT, **6.20×** on `dart2js`, and **6.46×** on `dart2wasm`.
5. **Fast direct `isoFormat` and `isoParse` (`lib/src/isoFormat.dart`, `lib/src/isoParse.dart`):**
   direct fixed-buffer ISO 8601 formatting and direct code-unit ISO 8601 parsing with Hinnant civil
   math. Speeds up `isoFormat.1000` by **8.98×** on AOT (**21.52× faster than Node.js**) and
   `isoParse.1000` by **35.31×** on AOT (**11.04× faster than Node.js**), **12.59×** on `dart2js`,
   and **16.76×** on `dart2wasm`.

On macOS CLI benchmarks, **macOS AOT, `dart2js`, and `dart2wasm` each beat Node.js on all 14/14
workloads** (up to **23.70× faster** on AOT, **21.70× faster** on `dart2wasm`, and **11.08×
faster** on `dart2js`).

| Case | Node.js | AOT base → opt | AOT / Node | dart2js base → opt | dart2wasm base → opt |
|---|---:|---|---:|---|---|
| `utcFormat.iso_1000` | 540,743 | 566,500 → **112,688** (5.03×) | **0.21×** | 502,500 → **254,625** (1.97×) | 719,469 → **119,113** (6.04×) |
| `utcFormat.ymd_1000` | 266,462 | 274,234 → **66,863** (4.10×) | **0.25×** | 248,688 → **121,344** (2.05×) | 310,328 → **59,457** (5.22×) |
| `utcFormat.locale_c_1000` | 754,096 | 779,906 → **113,785** (6.85×) | **0.15×** | 825,844 → **202,281** (4.08×) | 982,438 → **119,305** (8.23×) |
| `utcFormat.words_1000` | 290,079 | 311,953 → **91,793** (3.40×) | **0.32×** | 391,516 → **128,453** (3.05×) | 397,281 → **110,762** (3.59×) |
| `utcFormat.weeks_doy_1000` | 2,335,844 | 740,219 → **98,543** (7.51×) | **0.04×** | 1,100,813 → **210,898** (5.22×) | 976,125 → **107,656** (9.07×) |
| `timeFormat.local_1000` | 714,327 | 804,219 → **242,109** (3.32×) | **0.34×** | 666,563 → **467,969** (1.42×) | 1,012,938 → **356,938** (2.84×) |
| `isoFormat.1000` | 603,151 | 251,703 → **28,028** (8.98×) | **0.05×** | 251,813 → **151,578** (1.66×) | 226,531 → **55,439** (4.09×) |
| `utcParse.iso_1000` | 614,734 | 1,164,625 → **182,047** (6.40×) | **0.30×** | 871,625 → **100,613** (8.66×) | 1,183,813 → **81,191** (14.58×) |
| `utcParse.ymd_1000` | 312,547 | 520,219 → **78,840** (6.60×) | **0.25×** | 405,391 → **54,258** (7.47×) | 500,281 → **38,408** (13.03×) |
| `utcParse.zone_1000` | 660,577 | 1,303,250 → **169,469** (7.69×) | **0.26×** | 907,938 → **122,047** (7.44×) | 1,287,063 → **102,121** (12.60×) |
| `utcParse.words_1000` | 632,016 | 1,223,625 → **191,742** (6.38×) | **0.30×** | 909,875 → **118,586** (7.67×) | 1,265,188 → **151,406** (8.36×) |
| `utcParse.locale_c_1000` | 662,901 | 1,218,438 → **180,711** (6.74×) | **0.27×** | 978,500 → **114,027** (8.58×) | 1,398,313 → **112,910** (12.38×) |
| `utcParse.fr_words_1000` | 698,372 | 1,263,000 → **207,164** (6.10×) | **0.30×** | 956,500 → **154,289** (6.20×) | 1,328,688 → **205,820** (6.46×) |
| `isoParse.1000` | 199,110 | 637,156 → **18,043** (35.31×) | **0.09×** | 497,625 → **39,512** (12.59×) | 492,969 → **29,418** (16.76×) |

## 3. Native Flutter Release Builds: macOS & Android (ns/op)

Measured in standalone Flutter `--release` builds (`darwin-arm64` and `android-arm64`; physical iOS
device was not connected during this run). Both native Flutter AOT targets beat desktop Apple M3
Max Node.js on **all 14/14 workloads**:

- **macOS M3 Max Flutter AOT:** beats desktop M3 Max Node.js on **14/14** workloads — up to
  **23.36× faster** (`utcFormat.weeks_doy_1000`), **21.49× faster** (`isoFormat.1000`), and
  **10.62× faster** (`isoParse.1000`).
- **Pixel 8a Android 17 AOT:** beats desktop M3 Max Node.js on **14/14** workloads (up to **12.98×
  faster** on `utcFormat.weeks_doy_1000` and **7.89× faster** on `isoFormat.1000`), and runs
  **1.90×–35.64× faster** than Mobile Chrome upstream JS on the same Pixel 8a across **all 14/14**
  workloads.

| Case | Node.js upstream | macOS M3 Max Flutter AOT | Pixel 8a Android AOT |
|---|---:|---:|---:|
| `utcFormat.iso_1000` | 540,743 | **113,965** | 207,227 |
| `utcFormat.ymd_1000` | 266,462 | **68,563** | 125,359 |
| `utcFormat.locale_c_1000` | 754,096 | **115,852** | 203,617 |
| `utcFormat.words_1000` | 290,079 | **98,492** | 156,891 |
| `utcFormat.weeks_doy_1000` | 2,335,844 | **99,996** | 179,984 |
| `timeFormat.local_1000` | 714,327 | **253,766** | 400,547 |
| `isoFormat.1000` | 603,151 | **28,072** | 76,402 |
| `utcParse.iso_1000` | 614,734 | **180,625** | 289,969 |
| `utcParse.ymd_1000` | 312,547 | **80,313** | 133,750 |
| `utcParse.zone_1000` | 660,577 | **172,164** | 276,109 |
| `utcParse.words_1000` | 632,016 | **193,563** | 314,578 |
| `utcParse.locale_c_1000` | 662,901 | **182,984** | 295,031 |
| `utcParse.fr_words_1000` | 698,372 | **213,367** | 333,078 |
| `isoParse.1000` | 199,110 | **18,741** | 35,268 |

## 4. Desktop & Mobile Browsers (ns/op)

Each cell shows `upstream JS / dart2js / dart2wasm` (fastest highlighted in bold):

- **Desktop Chrome 157:** both `dart2wasm` and `dart2js` beat upstream JS on **14/14** workloads —
  `dart2wasm` up to **39.13× faster** (`utcFormat.weeks_doy_1000`), **14.09× faster**
  (`isoParse.1000`), and **12.29× faster** (`utcParse.ymd_1000`); `dart2js` up to **26.07× faster**.
- **Desktop Safari 27.0.1:** `dart2js` beats upstream JS on **14/14** workloads (up to **14.72×
  faster** on `utcFormat.weeks_doy_1000` and **5.68× faster** on `isoParse.1000`); `dart2wasm`
  beats upstream on **12/14** (up to **15.62× faster**).
- **Desktop Firefox 161:** `dart2js` beats upstream JS on **12/14** workloads (every
  `strftime`/`strptime` workload, up to **4.63× faster**; SpiderMonkey's native C++
  `Date.prototype.toISOString()` and `new Date(iso)` win the two native-builtin ISO cases);
  `dart2wasm` beats upstream on **11/14** (up to **7.36× faster** on `utcFormat.weeks_doy_1000`).
- **Mobile Chrome 157 (Pixel 8a):** both `dart2wasm` and `dart2js` beat upstream JS on **14/14**
  workloads — `dart2wasm` up to **35.14× faster** (`utcFormat.weeks_doy_1000`), **13.85× faster**
  (`utcParse.ymd_1000`), and **12.66× faster** (`isoParse.1000`); `dart2js` up to **19.20× faster**.
- **Mobile Firefox 160 (Pixel 8a):** `dart2js` beats upstream JS on **12/14** workloads (every
  `strftime`/`strptime` workload, up to **4.21× faster**); `dart2wasm` beats upstream on **11/14**
  (up to **3.71× faster**).

| Case | Chrome 157 (up / js / wasm) | Firefox 161 (up / js / wasm) | Safari 27.0.1 (up / js / wasm) | Pixel Chrome 157 (up / js / wasm) | Pixel Firefox 160 (up / js / wasm) |
|---|---|---|---|---|---|
| `utcFormat.iso_1000` | 375,781 / 201,344 / **125,625** | 371,250 / 268,438 / **187,500** | 409,375 / 189,063 / **180,313** | 540,313 / 342,656 / **194,078** | 646,250 / 451,250 / **424,375** |
| `utcFormat.ymd_1000` | 180,664 / 98,867 / **63,246** | 191,875 / 172,969 / **97,500** | 186,875 / 99,531 / **95,078** | 258,438 / 174,844 / **93,430** | 310,625 / **286,250** / 291,875 |
| `utcFormat.locale_c_1000` | 569,063 / 166,438 / **131,016** | 509,375 / 262,500 / **191,250** | 507,500 / **178,438** / 204,375 | 805,000 / 331,172 / **188,891** | 937,500 / **381,875** / 445,000 |
| `utcFormat.words_1000` | 207,188 / **100,820** / 124,063 | 211,875 / **188,750** / 220,313 | 198,750 / **135,156** / 250,938 | 298,359 / 230,625 / **172,852** | 375,625 / **278,125** / 481,250 |
| `utcFormat.weeks_doy_1000` | 4,601,250 / 176,523 / **117,578** | 1,212,500 / 261,875 / **164,844** | 2,450,000 / 166,406 / **156,875** | 6,413,750 / 333,984 / **182,500** | 1,627,500 / **386,250** / 438,438 |
| `timeFormat.local_1000` | 539,219 / 411,719 / **375,781** | 385,000 / 290,000 / **274,688** | 444,375 / **213,438** / 467,500 | 772,187 / 637,469 / **546,875** | 685,625 / **463,125** / 626,250 |
| `isoFormat.1000` | 572,500 / 118,320 / **64,824** | **25,742** / 115,625 / 80,234 | 113,750 / 101,406 / **71,250** | 766,563 / 197,969 / **85,176** | **57,344** / 167,031 / 225,469 |
| `utcParse.iso_1000` | 748,437 / 100,547 / **77,930** | 392,500 / **141,250** / 206,875 | 381,250 / **74,609** / 325,313 | 1,271,250 / 256,188 / **129,336** | 746,250 / **240,625** / 341,875 |
| `utcParse.ymd_1000` | 472,813 / 60,355 / **38,469** | 211,250 / **82,422** / 101,094 | 207,188 / **39,492** / 142,969 | 811,875 / 143,867 / **58,613** | 403,125 / **132,969** / 155,156 |
| `utcParse.zone_1000` | 766,875 / 120,625 / **100,898** | 429,375 / **147,344** / 206,563 | 416,250 / **77,891** / 311,875 | 1,392,188 / 276,031 / **157,883** | 795,000 / **238,438** / 342,188 |
| `utcParse.words_1000` | 803,438 / **116,398** / 121,055 | 404,375 / **205,938** / 279,688 | 451,250 / **105,313** / 390,000 | 1,408,125 / 334,375 / **188,828** | 816,250 / **389,406** / 498,125 |
| `utcParse.locale_c_1000` | 788,125 / 109,258 / **100,477** | 458,125 / **192,813** / 234,375 | 481,250 / **91,563** / 352,188 | 1,454,375 / 308,828 / **161,563** | 878,750 / **347,813** / 410,000 |
| `utcParse.fr_words_1000` | 873,437 / **141,367** / 162,180 | 456,875 / **222,500** / 358,125 | 511,250 / **120,617** / 478,750 | 1,515,000 / 367,188 / **237,109** | 877,500 / **405,625** / 641,875 |
| `isoParse.1000` | 356,875 / 42,354 / **25,324** | **18,828** / 61,328 / 119,063 | 225,313 / **39,648** / 165,625 | 538,594 / 94,227 / **42,537** | **38,047** / 107,969 / 453,750 |
