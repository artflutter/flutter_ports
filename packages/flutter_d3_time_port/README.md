# flutter_d3_time_port

A native, pure-Dart, fully statically typed port of
[d3-time](https://github.com/d3/d3-time) **3.1.0**: calendar time intervals (`TimeInterval` and
`CountableTimeInterval`) over immutable native Dart `DateTime` values (local and UTC), DST-aware
local calendar stepping, `floor` / `ceil` / `round` / `offset` / `range` / `filter` / `count` /
`every`, and automatic calendar-aligned axis ticks (`timeTicks`, `utcTicks`, `timeTickInterval`,
`utcTickInterval`) — with **zero `dynamic`**, zero Flutter import, and zero JavaScript runtime.

```dart
import 'package:flutter_d3_time_port/d3_time.dart';

// 1. Floor, ceil, round, offset, and count on UTC or local DateTime values
final now = DateTime.utc(2024, 6, 15, 14, 37, 22);
final startOfDay = utcDay.floor(now); // 2024-06-15T00:00:00.000Z
final nextHour = utcHour.ceil(now); // 2024-06-15T15:00:00.000Z
final twoWeeksLater = utcWeek.offset(now, 2);
final daysInYear = utcDay.count(DateTime.utc(2024), DateTime.utc(2025)); // 366

// 2. Ranges, periodic sub-intervals, and custom filters
final quarters = utcMonth.every(3)!.range(
  DateTime.utc(2024),
  DateTime.utc(2025),
); // [2024-01-01Z, 2024-04-01Z, 2024-07-01Z, 2024-10-01Z]

final mondays = timeMondays(DateTime(2024, 3), DateTime(2024, 4));
final leapDays = utcDay.filter((d) => d.month == 2 && d.day == 29);

// 3. Automatic calendar-aligned axis ticks
final ticks = utcTicks(DateTime.utc(2024), DateTime.utc(2024, 7), 6);
final chosen = utcTickInterval(DateTime.utc(2024), DateTime.utc(2024, 7), 6);
```

## Installing

```sh
dart pub add flutter_d3_time_port
```

- **Pure Dart (zero Flutter import):**
  `import 'package:flutter_d3_time_port/d3_time.dart';`
  (or `import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';`)
  Compiles cleanly for Dart VM, native AOT, JavaScript (`dart2js`), and WebAssembly (`dart2wasm`).

## API

- **Interval types & factories:** `TimeInterval` (`call([DateTime?])`, `floor`, `ceil`, `round`,
  `offset(date, [step])`, `range(start, stop, [step])`, `filter(test)`), `CountableTimeInterval`
  (`count(start, end)`, `every(step)`), `timeInterval(floor, offset, [count, field])`,
  `countableTimeInterval(floor, offset, count, [field])`.
- **Local intervals & range aliases:** `timeMillisecond` / `timeMilliseconds`, `timeSecond` /
  `timeSeconds`, `timeMinute` / `timeMinutes`, `timeHour` / `timeHours`, `timeDay` / `timeDays`,
  `timeWeek` / `timeWeeks`, `timeSunday`..`timeSaturday` / `timeSundays`..`timeSaturdays`,
  `timeMonth` / `timeMonths`, `timeYear` / `timeYears`.
- **UTC & Unix-epoch intervals & range aliases:** `utcMillisecond` / `utcMilliseconds`,
  `utcSecond` / `utcSeconds`, `utcMinute` / `utcMinutes`, `utcHour` / `utcHours`, `utcDay` /
  `utcDays`, `unixDay` / `unixDays` (plus `timeUnixDay` / `timeUnixDays` aliases), `utcWeek` /
  `utcWeeks`, `utcSunday`..`utcSaturday` / `utcSundays`..`utcSaturdays`, `utcMonth` / `utcMonths`,
  `utcYear` / `utcYears`.
- **Ticks:** `timeTicks`, `timeTicksWith`, `timeTickInterval`, `utcTicks`, `utcTicksWith`,
  `utcTickInterval`.

## Performance

Benchmarked on Apple M3 Max (Node.js v24.22.1, macOS CLI/Flutter AOT, Chrome 157, Firefox 160,
Safari 27.0.1), iOS 27.2 (`ios-arm64` Flutter AOT `--release`), and Pixel 8a (Android 17 AOT
`--release`, Mobile Chrome 157, Mobile Firefox 160). All values are median **ns/op** (lower is
better; see
[doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_time_port/doc/performance.md)
for the complete 14-case breakdown including baseline vs optimized).

- **Native AOT:** macOS AOT, iOS 27.2 AOT, and Pixel 8a Android AOT all beat desktop Apple M3 Max
  Node.js `d3-time` on **all 14/14 workloads** — up to **117.74× faster** on macOS CLI AOT,
  **74.23× faster** on iOS 27.2 Flutter AOT, **71.76× faster** on macOS Flutter AOT, and **32.44×
  faster** on Pixel 8a Android AOT (up to **58.75× faster** than Mobile Chrome upstream JS on the
  same Pixel 8a).
- **Web (`dart2wasm` & `dart2js`):** Both `dart2js` and `dart2wasm` beat upstream JS `d3-time` on
  **all 14/14 workloads in every tested browser** — up to **191.72× faster** in Desktop Chrome,
  **41.93× faster** in Desktop Firefox, **98.13× faster** in Desktop Safari, **128.53× faster** in
  Mobile Chrome, and **22.40× faster** in Mobile Firefox.

### Native AOT vs Node.js (ns/op)

| Case | Node.js upstream | macOS AOT | iOS 27.2 AOT | Pixel 8a Android AOT |
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

### Desktop & Mobile Browsers (ns/op, `upstream / dart2js / dart2wasm`)

| Case | Chrome 157 | Firefox 160 | Safari 27.0.1 | Pixel Chrome 157 | Pixel Firefox 160 |
|---|---|---|---|---|---|
| `utcDay.fcr_1000` | 1,100,000 / 18,261 / **13,037** | 195,313 / 52,734 / **13,672** | 687,500 / **7,324** / 15,625 | 1,893,750 / 114,457 / **27,734** | 265,625 / 105,469 / **26,367** |
| `utcWeek.fcr_1000` | 1,531,250 / 20,703 / **15,820** | 437,500 / 70,313 / **14,160** | 875,000 / **12,695** / 18,555 | 2,475,000 / 121,875 / **33,010** | 562,500 / 121,094 / **27,344** |
| `utcDay.range_366` | 78,906 / **940** / 983 | 78,125 / 3,662 / **2,441** | 82,031 / **1,709** / 2,441 | 167,188 / 8,447 / **2,527** | 132,813 / 7,324 / **6,836** |
| `utcMinute.range_1440` | 332,813 / **3,711** / 3,857 | 281,250 / 13,672 / **8,789** | 328,125 / **6,104** / 8,789 | 715,625 / 32,424 / **12,158** | 500,000 / 44,922 / **26,367** |
| `utcMonth.range_600` | 223,438 / 13,525 / **7,422** | 171,875 / 21,484 / **11,230** | 156,250 / 24,414 / **10,742** | 390,625 / 42,385 / **15,528** | 242,188 / 37,109 / **23,438** |
| `timeDay.range_366` | 112,500 / **13,525** / 15,625 | 89,844 / 16,602 / **15,137** | 78,125 / **12,695** / 16,602 | 227,344 / 43,750 / **29,785** | 179,688 / 37,109 / **31,250** |
| `utc.count_offset_1000` | 2,162,500 / 19,628 / **11,279** | 179,688 / 31,250 / **17,578** | 625,000 / 74,219 / **12,207** | 3,000,000 / 52,734 / **23,341** | 250,000 / 60,547 / **27,344** |
| `utcTicks.batch_16` | 88,672 / 3,418 / **2,405** | 62,500 / 5,127 / **3,418** | 85,938 / 3,540 / **3,052** | 196,094 / 9,863 / **4,272** | 117,188 / 9,277 / **6,348** |
| `timeTicks.batch_16` | 99,609 / **12,598** / 20,215 | 82,031 / **14,160** / 22,461 | 109,375 / **8,789** / 21,484 | 219,531 / **27,929** / 34,180 | 171,875 / **28,320** / 39,063 |

## Upstream

- Upstream: [d3/d3-time](https://github.com/d3/d3-time) `v3.1.0` (`d3TimeVersion`).
- Differences from upstream:
  [doc/differences.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_time_port/doc/differences.md).
- Full benchmark report:
  [doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_time_port/doc/performance.md).

## License

ISC (matching upstream `d3-time`). See [LICENSE](LICENSE). This project is not affiliated with the
D3 project or Observable.
