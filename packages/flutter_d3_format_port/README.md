# flutter_d3_format_port

A native, pure-Dart port of [d3-format](https://github.com/d3/d3-format) **3.1.2** for Dart and
Flutter: Python-style numeric format specifiers (`[[fill]align][sign][symbol][0][width][,][.precision][~][type]`),
SI prefixes (`y`–`Y`), fixed/rounded/scientific/binary/octal/hex/percent/currency/accounting
formats, precision helpers, and all **59** built-in upstream locale definitions as compile-time
`const` Dart objects — with zero runtime dependencies and zero JavaScript runtime.

```dart
import 'package:flutter_d3_format_port/flutter_d3_format_port.dart';

// 1. Common formats
format('.2f')(3.14159); // '3.14'
format(',.2f')(1234567.89); // '1,234,567.89'
format(r'$,.2f')(1234.5); // '$1,234.50'
format('(,.2f')(-1234.5); // '(1,234.50)'
format('.1%')(0.1234); // '12.3%'
format('~s')(42000000); // '42M'
format('#x')(48879); // '0xbeef'

// 2. Fixed SI-prefix scale (ideal for consistent chart axis ticks)
final fM = formatPrefix(',.1', 1e6);
fM(1200000); // '1.2M'
fM(2500000); // '2.5M'

// 3. Built-in locales (all 59 upstream locales available as const definitions)
final fr = formatLocale(localeFrFr);
fr.format(r'$,.2f')(1234567.89); // '1\u00a0234\u00a0567,89\u00a0€'

final ar = formatLocale(formatLocales['ar-AE']!);
ar.format(',.2f')(12345.67); // '١٢٬٣٤٥٫٦٧'

// 4. Precision helpers for axis ticks
final p = precisionFixed(0.05); // 2
format('.${p}f')(1.25); // '1.25'
```

## Installing

```sh
dart pub add flutter_d3_format_port
```

```dart
import 'package:flutter_d3_format_port/flutter_d3_format_port.dart' as d3;
```

`package:flutter_d3_format_port/d3_format.dart` and
`package:flutter_d3_format_port/flutter_d3_format_port.dart` are both pure Dart libraries with zero
Flutter dependency, compiling cleanly for the Dart VM, AOT, JavaScript (`dart2js`), and WebAssembly
(`dart2wasm`).

## API

- **Formatting:** `format(specifier)`, `formatPrefix(specifier, value)`, `NumberFormat` (callable
  with `call(num)`, plus `formatChar(String)` for non-numeric `'c'` strings and `toString()`).
- **Specifiers:** `formatSpecifier(specifier)`, `FormatSpecifier` (mutable typed specifier fields:
  `fill`, `align`, `sign`, `symbol`, `zero`, `width`, `comma`, `precision`, `trim`, `type`).
- **Locales:** `formatLocale(definition)`, `formatDefaultLocale(definition)`, `FormatLocale`,
  `FormatLocaleDefinition`, plus all 59 `const` locale definitions (`localeEnUs`, `localeFrFr`,
  `localeDeDe`, `localeEnIn`, `localeArAe`, `localeJaJp`, …) and the `formatLocales` lookup map
  keyed by BCP-47 tag (e.g. `'en-US'`, `'fr-FR'`, `'ar-AE'`).
- **Precision helpers:** `precisionFixed(step)`, `precisionPrefix(step, value)`,
  `precisionRound(step, max)` (returning `int?`, with `null` where JS returns `NaN`).

## Performance

Benchmarked on Apple M3 Max (Node.js v24.22.1, macOS CLI/Flutter AOT, Chrome 157, Firefox 160,
Safari 27.0.1), iOS 27.2 (`ios-arm64` Flutter AOT release), and Pixel 8a (Android 17 AOT release,
Mobile Chrome 157, Mobile Firefox 160). All values are median **ns/op** (lower is better; see
[doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_format_port/doc/performance.md)
for the complete 20-case breakdown including baseline vs optimized).

- **Native AOT:** beats Node.js `d3-format` on **16/20** workloads on macOS M3 Max (up to **5.3×
  faster**) and **20/20** workloads on iOS AOT (up to **6.9× faster**).
- **Web (`dart2wasm` & `dart2js`):** `dart2wasm` beats Node.js on **20/20** CLI workloads (up to
  **7.2× faster**); in browsers, Dart beats upstream JS on **20/20** cases in Desktop Chrome,
  Desktop Safari, and Mobile Chrome, **18/20** in Desktop Firefox, and **16/20** in Mobile Firefox.

### Native AOT vs Node.js (ns/op)

| Case | Node.js upstream | macOS AOT | iOS 27.2 AOT | Pixel 8a Android AOT |
|---|---:|---:|---:|---:|
| `parse.specifier16` | 1,308 | **333** | **221** | **349** |
| `compile.format16` | 3,326 | **2,561** | **1,575** | 4,426 |
| `d.plain64` | 3,039 | 3,065 | **1,905** | 5,712 |
| `d.grouped64` | 8,700 | **3,828** | **2,004** | **5,734** |
| `d.zeroPadGroup64` | 14,586 | **7,405** | **5,228** | **11,570** |
| `f.fixed2_64` | 7,103 | **3,392** | **2,233** | **5,798** |
| `f.currency64` | 14,936 | **3,600** | **2,452** | **6,096** |
| `f.accounting64` | 14,007 | **3,395** | **2,444** | **5,511** |
| `e.exp64` | 6,338 | 6,814 | **4,700** | 9,548 |
| `e.trim64` | 11,500 | 12,562 | **7,232** | 14,177 |
| `g.general64` | 6,497 | 6,959 | **4,935** | 9,917 |
| `none.default64` | 16,889 | **11,248** | **7,328** | **13,910** |
| `s.siPrefix64` | 12,966 | **9,888** | **6,875** | 13,128 |
| `s.siTrim64` | 18,002 | **10,957** | **7,412** | **13,936** |
| `prefix.fixedM64` | 9,671 | **2,769** | **2,035** | **4,160** |
| `pct.percent64` | 6,998 | **2,830** | **1,964** | **3,939** |
| `hex.prefix64` | 10,312 | **4,209** | **3,221** | **8,878** |
| `locale.frFR64` | 18,296 | **6,639** | **4,995** | **11,543** |
| `locale.enIN64` | 17,963 | **6,672** | **4,850** | **11,302** |
| `locale.arAE64` | 40,353 | **7,558** | **5,844** | **12,526** |

### Desktop & Mobile Browsers (ns/op, `upstream / dart2js / dart2wasm`)

| Case | Chrome 157 | Firefox 160 | Safari 27.0.1 | Pixel Chrome 157 | Pixel Firefox 160 |
|---|---|---|---|---|---|
| `parse.specifier16` | 1,196 / **320** / 412 | 1,587 / **641** / 1,221 | 977 / **366** / 1,709 | 2,332 / 1,117 / **671** | 2,075 / **1,038** / 4,150 |
| `compile.format16` | 3,247 / **781** / 1,282 | 5,371 / **1,953** / 3,174 | 3,174 / **1,038** / 4,150 | 10,059 / 4,004 / **2,075** | 8,301 / **2,930** / 5,859 |
| `d.grouped64` | 6,494 / 4,687 / **3,662** | 7,813 / 7,324 / **4,883** | 7,813 / 6,348 / **4,883** | 9,229 / 8,740 / **6,250** | 10,742 / 12,695 / **9,766** |
| `f.currency64` | 11,914 / 8,691 / **4,810** | 12,695 / 11,719 / **6,348** | 18,555 / 10,742 / **5,859** | 20,508 / 18,653 / **7,813** | 19,531 / 19,531 / **12,695** |
| `f.accounting64` | 11,914 / 8,936 / **4,809** | 12,695 / 11,719 / **6,348** | 18,555 / 9,766 / **5,859** | 20,410 / 18,749 / **7,715** | 19,531 / 19,531 / **11,719** |
| `s.siPrefix64` | 9,863 / 7,714 / **6,787** | 14,648 / **11,719** / 16,602 | 16,602 / **11,719** / 13,672 | 14,844 / 14,356 / **10,646** | **13,672** / 19,531 / 31,250 |
| `prefix.fixedM64` | 7,471 / 5,957 / **3,125** | 7,324 / 7,324 / **4,883** | 13,672 / 8,301 / **4,639** | 14,160 / 12,305 / **4,785** | 10,742 / 11,719 / **8,301** |
| `pct.percent64` | 5,371 / 3,491 / **2,613** | 5,859 / **3,418** / 4,883 | 8,301 / 4,883 / **4,150** | 10,645 / 7,959 / **3,931** | 7,324 / **4,883** / 8,301 |
| `locale.frFR64` | 12,012 / 9,131 / **4,883** | 22,461 / 11,719 / **6,836** | 21,484 / 10,742 / **6,836** | 21,484 / 20,116 / **8,251** | 19,531 / 18,555 / **12,695** |
| `locale.arAE64` | 31,055 / 17,969 / **5,665** | 31,250 / 25,391 / **8,789** | 42,969 / 19,531 / **9,277** | 53,125 / 38,086 / **9,473** | 46,875 / 46,875 / **16,602** |

## Upstream

- Upstream: [d3/d3-format](https://github.com/d3/d3-format) `v3.1.2` (`d3FormatVersion`).
- Differences from upstream: [doc/differences.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_format_port/doc/differences.md).
- Full benchmark report: [doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_format_port/doc/performance.md).

## License

ISC, matching upstream `d3-format`. See [LICENSE](LICENSE). This project is not affiliated with the D3 project.
