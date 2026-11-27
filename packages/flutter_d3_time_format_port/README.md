# flutter_d3_time_format_port

A native, pure-Dart, fully statically typed port of
[d3-time-format](https://github.com/d3/d3-time-format) **4.1.0**: locale-aware `strftime` /
`strptime` date formatting and parsing over immutable native Dart `DateTime` values (local and
UTC), all 32 directives (`%a`–`%Z`, `%f`, `%g`, `%G`, `%L`, `%q`, `%Q`, `%s`, `%u`, `%U`, `%V`,
`%W`, `%x`, `%X`, `%c`, `%%`) with pad modifiers (`-`, `_`, `0`), `isoFormat` / `isoParse`, and
all **34** built-in upstream locales as `const` Dart objects — with **zero `dynamic`**, zero
Flutter import, and zero JavaScript runtime.

```dart
import 'package:flutter_d3_time_format_port/d3_time_format.dart';

// 1. Format and parse UTC or local DateTime values
final formatDate = utcFormat('%B %-d, %Y at %H:%M:%S.%L UTC');
final text = formatDate(DateTime.utc(2024, 6, 15, 14, 37, 22, 432));
// 'June 15, 2024 at 14:37:22.432 UTC'

final parsed = utcParse('%Y-%m-%d %H:%M:%S %Z')('2024-06-15 14:37:22 +05:30');
// 2024-06-15 09:07:22.000Z

// 2. Fast ISO 8601 formatting and parsing
final iso = isoFormat(DateTime.utc(2024, 6, 15, 14, 37, 22, 432));
// '2024-06-15T14:37:22.432Z'
final dt = isoParse(iso); // 2024-06-15 14:37:22.432Z

// 3. Built-in const locales (all 34 upstream locales, zero filesystem I/O)
final fr = timeFormatLocale(timeLocaleFrFR);
final french = fr.utcFormat('%c')(DateTime.utc(2024, 6, 15, 14, 37, 22));
// 'samedi 15 juin 2024 à 14:37:22'
final def = timeFormatLocales['ja-JP']!; // lookup by BCP-47 tag
```

## Installing

```sh
dart pub add flutter_d3_time_format_port
```

- **Pure Dart (zero Flutter import):**
  `import 'package:flutter_d3_time_format_port/d3_time_format.dart';`
  (or `import 'package:flutter_d3_time_format_port/flutter_d3_time_format_port.dart';`)
  Compiles cleanly for Dart VM, native AOT, JavaScript (`dart2js`), and WebAssembly (`dart2wasm`).

## API

- **Types:** `TimeLocaleDefinition` (`const` data class + `fromJson`), `TimeLocale` (`format`,
  `parse`, `utcFormat`, `utcParse`), callable `TimeFormat` (`String call(DateTime)` + `specifier` /
  `toString()`), callable `TimeParse` (`DateTime? call(String)` + `specifier` / `toString()`).
- **Default locale & factories:** `timeFormat`, `timeParse`, `utcFormat`, `utcParse`,
  `timeFormatLocale`, `timeFormatDefaultLocale`, `defaultTimeLocale`.
- **ISO 8601:** `isoFormat`, `isoParse`, `isoSpecifier`.
- **34 built-in `const` locales:** `timeLocaleArEG`..`timeLocaleZhTW` and
  `const Map<String, TimeLocaleDefinition> timeFormatLocales` keyed by BCP-47 tag.

## Performance

Benchmarked on Apple M3 Max (Node.js v24.22.1, macOS CLI & Flutter AOT `--release`, Chrome 157,
Firefox 161, Safari 27.0.1) and Pixel 8a (Android 17 Flutter AOT `--release`, Mobile Chrome 157,
Mobile Firefox 160). All values are median **ns/op** across 1,000 timestamps per op (lower is
better; see
[doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_time_format_port/doc/performance.md)
for the complete 14-case breakdown including baseline vs optimized).

- **Native AOT:** macOS CLI AOT, macOS Flutter AOT, and Pixel 8a Android AOT all beat desktop Apple
  M3 Max Node.js `d3-time-format` on **all 14/14 workloads** — up to **23.70× faster** on macOS CLI
  AOT, **23.36× faster** on macOS Flutter AOT, and **12.98× faster** on Pixel 8a Android AOT
  (**1.90×–35.64× faster** than Mobile Chrome upstream JS on the same Pixel 8a).
- **Web (`dart2wasm` & `dart2js`):** Both `dart2wasm` and `dart2js` beat upstream JS on **14/14
  workloads** in Desktop Chrome (up to **39.13× faster**) and Mobile Chrome (up to **35.14×
  faster**); `dart2js` beats upstream on **14/14** in Desktop Safari (up to **14.72× faster**) and
  all **12/12 `strftime`/`strptime`** workloads in Desktop & Mobile Firefox.

### Native AOT vs Node.js (ns/op)

| Case | Node.js upstream | macOS CLI AOT | macOS Flutter AOT | Pixel 8a Android AOT |
|---|---:|---:|---:|---:|
| `utcFormat.iso_1000` | 540,743 | **112,688** | 113,965 | 207,227 |
| `utcFormat.ymd_1000` | 266,462 | **66,863** | 68,563 | 125,359 |
| `utcFormat.locale_c_1000` | 754,096 | **113,785** | 115,852 | 203,617 |
| `utcFormat.words_1000` | 290,079 | **91,793** | 98,492 | 156,891 |
| `utcFormat.weeks_doy_1000` | 2,335,844 | **98,543** | 99,996 | 179,984 |
| `timeFormat.local_1000` | 714,327 | **242,109** | 253,766 | 400,547 |
| `isoFormat.1000` | 603,151 | **28,028** | 28,072 | 76,402 |
| `utcParse.iso_1000` | 614,734 | 182,047 | **180,625** | 289,969 |
| `utcParse.ymd_1000` | 312,547 | **78,840** | 80,313 | 133,750 |
| `utcParse.zone_1000` | 660,577 | **169,469** | 172,164 | 276,109 |
| `utcParse.words_1000` | 632,016 | **191,742** | 193,563 | 314,578 |
| `utcParse.locale_c_1000` | 662,901 | **180,711** | 182,984 | 295,031 |
| `utcParse.fr_words_1000` | 698,372 | **207,164** | 213,367 | 333,078 |
| `isoParse.1000` | 199,110 | **18,043** | 18,741 | 35,268 |

### Desktop & Mobile Browsers (ns/op, `upstream / dart2js / dart2wasm`)

| Case | Chrome 157 | Firefox 161 | Safari 27.0.1 | Pixel Chrome 157 | Pixel Firefox 160 |
|---|---|---|---|---|---|
| `utcFormat.iso_1000` | 375,781 / 201,344 / **125,625** | 371,250 / 268,438 / **187,500** | 409,375 / 189,063 / **180,313** | 540,313 / 342,656 / **194,078** | 646,250 / 451,250 / **424,375** |
| `utcFormat.locale_c_1000` | 569,063 / 166,438 / **131,016** | 509,375 / 262,500 / **191,250** | 507,500 / **178,438** / 204,375 | 805,000 / 331,172 / **188,891** | 937,500 / **381,875** / 445,000 |
| `utcFormat.weeks_doy_1000` | 4,601,250 / 176,523 / **117,578** | 1,212,500 / 261,875 / **164,844** | 2,450,000 / 166,406 / **156,875** | 6,413,750 / 333,984 / **182,500** | 1,627,500 / **386,250** / 438,438 |
| `isoFormat.1000` | 572,500 / 118,320 / **64,824** | **25,742** / 115,625 / 80,234 | 113,750 / 101,406 / **71,250** | 766,563 / 197,969 / **85,176** | **57,344** / 167,031 / 225,469 |
| `utcParse.iso_1000` | 748,437 / 100,547 / **77,930** | 392,500 / **141,250** / 206,875 | 381,250 / **74,609** / 325,313 | 1,271,250 / 256,188 / **129,336** | 746,250 / **240,625** / 341,875 |
| `utcParse.zone_1000` | 766,875 / 120,625 / **100,898** | 429,375 / **147,344** / 206,563 | 416,250 / **77,891** / 311,875 | 1,392,188 / 276,031 / **157,883** | 795,000 / **238,438** / 342,188 |
| `utcParse.words_1000` | 803,438 / **116,398** / 121,055 | 404,375 / **205,938** / 279,688 | 451,250 / **105,313** / 390,000 | 1,408,125 / 334,375 / **188,828** | 816,250 / **389,406** / 498,125 |
| `utcParse.fr_words_1000` | 873,437 / **141,367** / 162,180 | 456,875 / **222,500** / 358,125 | 511,250 / **120,617** / 478,750 | 1,515,000 / 367,188 / **237,109** | 877,500 / **405,625** / 641,875 |
| `isoParse.1000` | 356,875 / 42,354 / **25,324** | **18,828** / 61,328 / 119,063 | 225,313 / **39,648** / 165,625 | 538,594 / 94,227 / **42,537** | **38,047** / 107,969 / 453,750 |

## Upstream

- Upstream: [d3/d3-time-format](https://github.com/d3/d3-time-format) `v4.1.0`
  (`d3TimeFormatVersion`).
- Differences from upstream:
  [doc/differences.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_time_format_port/doc/differences.md).
- Full benchmark report:
  [doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_time_format_port/doc/performance.md).

## License

ISC (matching upstream `d3-time-format`). See [LICENSE](LICENSE). This project is not affiliated
with the D3 project or Observable.
