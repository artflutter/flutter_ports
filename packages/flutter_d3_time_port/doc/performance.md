# d3-time port performance

This file records the speed figures of `flutter_d3_time_port` against upstream `d3-time` v3.1.0
across Node.js, macOS native AOT, Flutter release builds on macOS, iOS, and Android, desktop
browsers (Chrome, Firefox, Safari), and mobile browsers (Chrome and Firefox on Android). Each
faster form is recorded under row `adapt-time-fast-forms` in [differences.md](differences.md) and
verified against literal upstream interval definitions and Node.js reference vectors by
`test/port/faster_forms_test.dart`, `test/port/reference_test.dart`, and
`test/test_time_zones_test.dart`.

## 1. Test bed

- Apple M3 Max, macOS 27.0.1, on AC power (2026-11-27).
- Flutter `master` (3.51.0-1.0.pre-31, Dart 3.15.0), Node.js v24.22.1 (`darwin-arm64`).
- iOS 27.2 device (`ios-arm64`) — Flutter AOT `--release` build.
- Pixel 8a, Android 17 (API 37) — Flutter AOT `--release` APK (`android-arm64`), Mobile Chrome 157,
  and Mobile Firefox 160.
- Desktop browsers on macOS: Chrome 157, Firefox 160, Safari 27.0.1.
- Instrument: `tool/bench/d3_time_bench.dart` and `tool/bench/d3_time_bench.mjs` run 14 identical
  seeded Park-Miller LCG workloads (`ns/op`, median across 9 timed batches after warmup, lower is
  better): 1,000 `floor` + `ceil` + `round` calls each on `utcSecond`, `utcMinute`, `utcHour`,
  `utcDay`, and `utcWeek` across an 80-year span (`1970–2050`); full-year `utcDay.range` (366
  dates), month-long `utcHour.range` (744 dates), day-long `utcMinute.range` (1,440 dates),
  10-year `utcWeek.range` (522 dates), 50-year `utcMonth.range` (600 dates), and full-year
  DST-crossing `timeDay.range` (366 dates); 1,000 paired `utcDay.count` + `utcWeek.count` +
  `utcHour.offset` calls; and 16-span tick generation batches (`1s` to `225yr`, ascending and
  descending) for both `utcTicks` and `timeTicks`.

## 2. Baseline vs optimized (macOS CLI: Node.js, AOT, dart2js, dart2wasm)

Optimizations applied (row `adapt-time-fast-forms`):

1. **O(1) epoch-millisecond Euclidean arithmetic for fixed-period intervals
   (`FixedPeriodTimeInterval` / `FixedEveryTimeInterval` in `lib/src/interval.dart`,
   `millisecond.dart`, `second.dart`, `minute.dart`, `hour.dart`, `day.dart`, `week.dart`):**
   computes `floor`, `ceil`, `round`, `offset`, `count` (zero intermediate `DateTime` allocations),
   pre-sized `List<DateTime>.generate` `range`, and dividing `every(k)` sub-intervals directly from
   `millisecondsSinceEpoch` using Dart's Euclidean `%` operator. Speeds up `utcDay.fcr_1000` by
   **37.87×** on AOT, `utcWeek.fcr_1000` by **40.69×** on AOT and **25.72×** on `dart2wasm`, and
   `utcWeek.range_522` by **69.16×** on `dart2js` (**87.89× faster than Node.js**).
2. **Pre-sized calendar stepping for month & year intervals (`lib/src/month.dart`,
   `lib/src/year.dart`):** computes exact list counts up front for `timeMonth`, `utcMonth`,
   `timeYear`, `utcYear`, and dividing `every(k)` views (such as quarterly `every(3)` and
   multi-year ticks), cutting `utcMonth.range_600` by **6.83×** on AOT, **8.56×** on `dart2js`,
   and **8.70×** on `dart2wasm`.
3. **Single-lookup `timeZoneOffset` stepping for local DST-aware intervals (`lib/src/minute.dart`,
   `lib/src/hour.dart`, `lib/src/day.dart`):** replaces repeated per-field OS `localtime_r`/`mktime`
   calls with a single `timeZoneOffset` check per step, falling back to full calendar `DateTime`
   reconstruction only on actual DST transition boundaries (at most twice per year). Cuts
   `timeDay.range_366` by **7.33×** on AOT (**2.54× faster than Node.js**), **9.39×** on `dart2js`
   (**10.08× faster than Node.js**), and **11.44×** on `dart2wasm` (**8.68× faster than Node.js**).
4. **Precomputed tick tables & inline binary search (`lib/src/ticks.dart`):** caches standard
   `every(k)` tick intervals, replaces bisector closures with an inline binary search over `const
   List<int> _tickDurations`, and reverses descending tick domains in place. Cuts
   `utcTicks.batch_16` by **17.81×** on AOT (**36.28× faster than Node.js**), **20.77×** on
   `dart2js`, and **22.30×** on `dart2wasm`, and cuts `timeTicks.batch_16` by **4.88×** on AOT
   (**2.47× faster than Node.js**), **6.67×** on `dart2js`, and **6.47×** on `dart2wasm`.

On macOS CLI benchmarks, **macOS AOT, `dart2js`, and `dart2wasm` each beat Node.js on all 14/14
workloads** (up to **117.74× faster** on AOT, **87.89× faster** on `dart2js`, and **64.07× faster**
on `dart2wasm`).

| Case | Node.js | AOT base → opt | AOT / Node | dart2js base → opt | dart2wasm base → opt |
|---|---:|---|---:|---|---|
| `utcSecond.fcr_1000` | 1,361,318 | 58,559 → **11,563** (5.06×) | **0.01×** | 212,875 → **130,563** (1.63×) | 82,367 → **21,246** (3.88×) |
| `utcMinute.fcr_1000` | 701,527 | 327,906 → **12,268** (26.73×) | **0.02×** | 632,906 → **105,453** (6.00×) | 410,609 → **21,374** (19.21×) |
| `utcHour.fcr_1000` | 667,531 | 322,172 → **10,539** (30.57×) | **0.02×** | 563,531 → **86,211** (6.54×) | 393,234 → **21,092** (18.64×) |
| `utcDay.fcr_1000` | 677,979 | 417,016 → **11,013** (37.87×) | **0.02×** | 773,563 → **59,494** (13.00×) | 526,094 → **21,335** (24.66×) |
| `utcWeek.fcr_1000` | 941,000 | 443,969 → **10,912** (40.69×) | **0.01×** | 1,035,938 → **66,551** (15.57×) | 551,313 → **21,437** (25.72×) |
| `utcDay.range_366` | 92,990 | 38,475 → **1,501** (25.63×) | **0.02×** | 78,156 → **1,191** (65.64×) | 50,121 → **1,869** (26.82×) |
| `utcHour.range_744` | 191,500 | 43,129 → **3,066** (14.07×) | **0.02×** | 75,734 → **2,464** (30.73×) | 58,090 → **3,636** (15.98×) |
| `utcMinute.range_1440` | 384,811 | 89,055 → **5,889** (15.12×) | **0.02×** | 154,984 → **4,605** (33.66×) | 116,098 → **6,996** (16.60×) |
| `utcWeek.range_522` | 156,147 | 70,164 → **2,187** (32.08×) | **0.01×** | 122,867 → **1,777** (69.16×) | 78,133 → **2,625** (29.76×) |
| `utcMonth.range_600` | 179,394 | 75,324 → **11,036** (6.83×) | **0.06×** | 132,078 → **15,435** (8.56×) | 84,984 → **9,766** (8.70×) |
| `timeDay.range_366` | 143,904 | 415,484 → **56,670** (7.33×) | **0.39×** | 134,070 → **14,272** (9.39×) | 189,633 → **16,574** (11.44×) |
| `utc.count_offset_1000` | 609,428 | 104,582 → **7,731** (13.53×) | **0.01×** | 435,453 → **64,000** (6.80×) | 107,121 → **15,565** (6.88×) |
| `utcTicks.batch_16` | 86,236 | 42,344 → **2,377** (17.81×) | **0.03×** | 72,082 → **3,471** (20.77×) | 57,250 → **2,567** (22.30×) |
| `timeTicks.batch_16` | 123,877 | 244,547 → **50,137** (4.88×) | **0.40×** | 96,707 → **14,504** (6.67×) | 149,773 → **23,161** (6.47×) |

## 3. Native Flutter Release Builds: macOS, iOS & Android (ns/op)

Measured in standalone Flutter `--release` builds (`darwin-arm64`, `ios-arm64`, and `android-arm64`).
All three native AOT targets beat desktop Apple M3 Max Node.js on **all 14/14** workloads:

- **iOS 27.2 AOT:** fastest native target on **12/14** workloads; beats desktop M3 Max Node.js by up
  to **74.23×** (`utc.count_offset_1000`), **72.79×** (`utcSecond.fcr_1000`), and **46.63×**
  (`utcDay.range_366`).
- **macOS M3 Max Flutter AOT:** beats desktop M3 Max Node.js on **14/14** workloads (up to **71.76×
  faster** on `utc.count_offset_1000`).
- **Pixel 8a Android 17 AOT:** beats desktop M3 Max Node.js on **14/14** workloads (up to **32.44×
  faster** on `utcWeek.range_522`), and runs **3.12×–58.75× faster** than Mobile Chrome upstream JS
  on the same Pixel 8a across **all 14/14** workloads.

| Case | Node.js upstream | macOS M3 Max AOT | iOS 27.2 AOT | Pixel 8a Android AOT |
|---|---:|---:|---:|---:|
| `utcSecond.fcr_1000` | 1,361,318 | 22,246 | **18,701** | 52,789 |
| `utcMinute.fcr_1000` | 701,527 | 21,718 | **19,124** | 51,283 |
| `utcHour.fcr_1000` | 667,531 | 22,026 | **19,904** | 49,461 |
| `utcDay.fcr_1000` | 677,979 | 21,649 | **19,692** | 48,072 |
| `utcWeek.fcr_1000` | 941,000 | 22,424 | **20,579** | 49,146 |
| `utcDay.range_366` | 92,990 | 2,073 | **1,994** | 3,417 |
| `utcHour.range_744` | 191,500 | 4,215 | **4,170** | 6,761 |
| `utcMinute.range_1440` | 384,811 | **7,949** | 7,970 | 13,064 |
| `utcWeek.range_522` | 156,147 | **2,935** | 2,989 | 4,814 |
| `utcMonth.range_600` | 179,394 | 11,738 | **8,055** | 17,570 |
| `timeDay.range_366` | 143,904 | 58,426 | **32,330** | 72,973 |
| `utc.count_offset_1000` | 609,428 | 8,493 | **8,210** | 53,432 |
| `utcTicks.batch_16` | 86,236 | 2,800 | **2,088** | 5,599 |
| `timeTicks.batch_16` | 123,877 | 51,348 | **29,826** | 65,172 |

## 4. Desktop & Mobile Browsers (ns/op)

Each cell shows `upstream JS / dart2js / dart2wasm` (fastest highlighted in bold). Both `dart2js`
and `dart2wasm` beat upstream JavaScript `d3-time` on **all 14/14 workloads in every single tested
browser**:

- **Desktop Chrome 157:** `dart2wasm` beats upstream on **14/14** (up to **191.72× faster** on
  `utc.count_offset_1000`), `dart2js` beats upstream on **14/14** (up to **110.17× faster**).
- **Desktop Firefox 160:** `dart2wasm` beats upstream on **14/14** (up to **41.93× faster** on
  `utcWeek.range_522`), `dart2js` beats upstream on **14/14** (up to **28.95× faster**).
- **Desktop Safari 27.0.1:** `dart2js` beats upstream on **14/14** (up to **98.13× faster** on
  `utcHour.fcr_1000`), `dart2wasm` beats upstream on **14/14** (up to **51.20× faster** on
  `utc.count_offset_1000`).
- **Mobile Chrome 157 (Pixel 8a):** `dart2wasm` beats upstream on **14/14** (up to **128.53× faster**
  on `utc.count_offset_1000`), `dart2js` beats upstream on **14/14** (up to **56.89× faster**).
- **Mobile Firefox 160 (Pixel 8a):** `dart2wasm` beats upstream on **14/14** (up to **22.40× faster**
  on `utcWeek.range_522`), `dart2js` beats upstream on **14/14** (up to **20.36× faster**).

| Case | Chrome 157 (up / js / wasm) | Firefox 160 (up / js / wasm) | Safari 27.0.1 (up / js / wasm) | Pixel Chrome 157 (up / js / wasm) | Pixel Firefox 160 (up / js / wasm) |
|---|---|---|---|---|---|
| `utcSecond.fcr_1000` | 1,231,250 / 17,090 / **12,989** | 148,438 / 54,688 / **14,160** | 687,500 / **7,324** / 15,625 | 2,162,500 / 113,672 / **28,320** | 164,063 / 105,469 / **27,344** |
| `utcMinute.fcr_1000` | 1,162,500 / 18,457 / **13,135** | 164,063 / 54,688 / **13,672** | 718,750 / **7,568** / 16,602 | 1,962,500 / 114,066 / **28,223** | 226,563 / 105,469 / **26,367** |
| `utcHour.fcr_1000` | 1,150,000 / 18,457 / **13,037** | 171,875 / 54,688 / **14,160** | 718,750 / **7,324** / 15,625 | 1,950,000 / 114,063 / **28,124** | 226,563 / 105,469 / **26,367** |
| `utcDay.fcr_1000` | 1,100,000 / 18,261 / **13,037** | 195,313 / 52,734 / **13,672** | 687,500 / **7,324** / 15,625 | 1,893,750 / 114,457 / **27,734** | 265,625 / 105,469 / **26,367** |
| `utcWeek.fcr_1000` | 1,531,250 / 20,703 / **15,820** | 437,500 / 70,313 / **14,160** | 875,000 / **12,695** / 18,555 | 2,475,000 / 121,875 / **33,010** | 562,500 / 121,094 / **27,344** |
| `utcDay.range_366` | 78,906 / **940** / 983 | 78,125 / 3,662 / **2,441** | 82,031 / **1,709** / 2,441 | 167,188 / 8,447 / **2,527** | 132,813 / 7,324 / **6,836** |
| `utcHour.range_744` | 171,094 / **1,929** / 2,039 | 164,063 / 7,324 / **4,639** | 187,500 / **3,540** / 4,639 | 367,188 / 16,798 / **4,932** | 250,000 / 24,414 / **13,672** |
| `utcMinute.range_1440` | 332,813 / **3,711** / 3,857 | 281,250 / 13,672 / **8,789** | 328,125 / **6,104** / 8,789 | 715,625 / 32,424 / **12,158** | 500,000 / 44,922 / **26,367** |
| `utcWeek.range_522` | 147,656 / **1,349** / 1,471 | 148,438 / 5,127 / **3,540** | 125,000 / **2,563** / 3,296 | 282,813 / 11,817 / **3,516** | 218,750 / 10,742 / **9,766** |
| `utcMonth.range_600` | 223,438 / 13,525 / **7,422** | 171,875 / 21,484 / **11,230** | 156,250 / 24,414 / **10,742** | 390,625 / 42,385 / **15,528** | 242,188 / 37,109 / **23,438** |
| `timeDay.range_366` | 112,500 / **13,525** / 15,625 | 89,844 / 16,602 / **15,137** | 78,125 / **12,695** / 16,602 | 227,344 / 43,750 / **29,785** | 179,688 / 37,109 / **31,250** |
| `utc.count_offset_1000` | 2,162,500 / 19,628 / **11,279** | 179,688 / 31,250 / **17,578** | 625,000 / 74,219 / **12,207** | 3,000,000 / 52,734 / **23,341** | 250,000 / 60,547 / **27,344** |
| `utcTicks.batch_16` | 88,672 / 3,418 / **2,405** | 62,500 / 5,127 / **3,418** | 85,938 / 3,540 / **3,052** | 196,094 / 9,863 / **4,272** | 117,188 / 9,277 / **6,348** |
| `timeTicks.batch_16` | 99,609 / **12,598** / 20,215 | 82,031 / **14,160** / 22,461 | 109,375 / **8,789** / 21,484 | 219,531 / **27,929** / 34,180 | 171,875 / **28,320** / 39,063 |
