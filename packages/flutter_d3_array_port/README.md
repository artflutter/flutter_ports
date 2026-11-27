# flutter_d3_array_port

A native, fully statically typed, pure-Dart port of [d3-array](https://github.com/d3/d3-array)
**3.2.4** for Dart and Flutter: descriptive statistics, Shewchuk exact floating-point summation
(`fsum`/`Adder`), Floyd-Rivest `quickselect` & `quantile`, histogram binning (`bin` + Sturges/
Scott/Freedman-Diaconis thresholds), axis `ticks`/`nice`/`range`, binary search (`bisect*`/
`bisector`), 1D/2D/RGBA box-blur (`blur`/`blur2`/`blurImage`), strongly typed multi-level grouping
& rollups (`group*`/`rollup*`/`index*`), stable `sort`/`rank`, transformations, and set operations
— with **zero `dynamic`**, zero runtime dependencies, and zero JavaScript runtime.

```dart
import 'package:flutter_d3_array_port/flutter_d3_array_port.dart';

// 1. Statistics & exact Shewchuk summation
final xs = <double>[1e16, 1.0, -1e16];
sum(xs); // 0.0 (catastrophic cancellation)
fsum(xs); // 1.0 (full precision via Adder)
extent(<double>[3, 1, 4, 1, 5, 9]); // (1.0, 9.0)
quantile(<double>[10, 20, 30, 40, 50], 0.5); // 30.0

// 2. Histogram binning with typed Bin<T>
final bins = bin<double>(thresholdsCount: thresholdFreedmanDiaconis)(
  <double>[12, 15, 19, 21, 22, 25, 31, 35, 42],
);
for (final b in bins) {
  print('[${b.x0}, ${b.x1}): ${b.length} items');
}

// 3. Axis ticks & nice domains
nice(0.123, 0.987, 5); // (0.0, 1.0)
ticks(0, 10, 5); // [0.0, 2.0, 4.0, 6.0, 8.0, 10.0]

// 4. Strongly typed multi-level grouping & rollup (native Map<K, V>)
typedef Sale = ({String region, String item, double amount});
const sales = <Sale>[
  (region: 'North', item: 'Tea', amount: 120),
  (region: 'North', item: 'Coffee', amount: 85),
  (region: 'South', item: 'Tea', amount: 95),
];
final totals = rollup<Sale, String, double>(
  sales,
  (rows) => sumBy(rows, (r) => r.amount),
  (r) => r.region,
); // {'North': 205.0, 'South': 95.0}

// 5. Typed 1D smoothing
final signal = <double>[0, 0, 10, 0, 0];
blur(signal, 1);
```

## Installing

```sh
dart pub add flutter_d3_array_port
```

```dart
import 'package:flutter_d3_array_port/flutter_d3_array_port.dart' as d3;
```

`package:flutter_d3_array_port/d3_array.dart` and
`package:flutter_d3_array_port/flutter_d3_array_port.dart` are both pure Dart libraries with zero
Flutter dependency, compiling cleanly for the Dart VM, AOT, JavaScript (`dart2js`), and WebAssembly
(`dart2wasm`).

## API

- **Statistics:** `min`, `max`, `extent` (`(T, T)?`), `minIndex`, `maxIndex`, `least`, `greatest`,
  `leastIndex`, `greatestIndex`, `sum`, `mean`, `median`, `medianIndex`, `cumsum`, `quantile`,
  `quantileIndex`, `quantileSorted`, `variance`, `deviation`, `mode`, `count`, `Adder`, `fsum`,
  `fcumsum` — plus typed `*By` (1-arg) and `*ByIndexed` (3-arg) variants.
- **Search & selection:** `bisect`, `bisectLeft`, `bisectRight`, `bisectCenter`, `bisector`
  (`Bisector<T, X>`), `quickselect`, `ascending`, `descending`.
- **Binning & ticks:** `bin`, `binBy`, `binByIndexed` (`BinGenerator<T>`, `Bin<T> extends
  ListBase<T>`), `thresholdSturges`, `thresholdScott`, `thresholdFreedmanDiaconis`, `ticks`,
  `tickIncrement`, `tickStep`, `nice` (`(double, double)`), `range`.
- **Grouping & indexing:** strongly typed fixed-arity `group`/`group2`/`group3`,
  `groups`/`groups2`, `rollup`/`rollup2`/`rollup3`, `rollups`/`rollups2`, `index`/`index2`/
  `index3`, `indexes`/`indexes2`, `flatGroup`/`flatGroup2`, `flatRollup`/`flatRollup2`,
  `groupSort`, plus typed `InternMap<K, V, I>` / `InternSet<T, I>` for custom key canonicalization.
- **Blurring:** `blur` (1D), `blur2` (`Blur2Data`), `blurImage` (`BlurImageData` over
  `Uint8ClampedList`).
- **Transformations & iterables:** `sort`/`sortBy`/`sortBy2`/`sortWith`, `rank`/`rankBy`/`rankWith`,
  `cross`/`cross2`/`cross3`, `pairs` (`List<(T, T)>`), `merge`, `permute`, `shuffle`, `shuffler`,
  `transpose`, `zip`, `every`, `some`, `filter`, `map`, `reduce`, `reverse`.
- **Sets:** `union`, `intersection`, `difference`, `disjoint`, `subset`, `superset`.

## Performance

Benchmarked on Apple M3 Max (Node.js v24.22.1, macOS CLI/Flutter AOT, Chrome 157, Firefox 160,
Safari 27.0.1), iOS 27.2 (`ios-arm64` Flutter AOT release), and Pixel 8a (Android 17 AOT release,
Mobile Chrome 157, Mobile Firefox 160). All values are median **ns/op** (lower is better; see
[doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_array_port/doc/performance.md)
for the complete 20-case breakdown including baseline vs optimized).

- **Native AOT:** beats Node.js `d3-array` on **19/20** workloads on macOS M3 Max (up to **45.2×
  faster**) and **20/20** workloads on iOS 27.2 AOT (up to **48.9× faster**).
- **Web (`dart2wasm` & `dart2js`):** `dart2wasm` beats Node.js on **17/20** CLI workloads (up to
  **42.6× faster**); in browsers, Dart beats upstream JS on **18/20** cases in Desktop Safari and
  Mobile Chrome, **17/20** in Desktop Chrome and Mobile Firefox, and **16/20** in Desktop Firefox.

### Native AOT vs Node.js (ns/op)

| Case | Node.js upstream | macOS AOT | iOS 27.2 AOT | Pixel 8a Android AOT |
|---|---:|---:|---:|---:|
| `sum.f64_1024` | 4,693 | **594** | **642** | **1,791** |
| `fsum.f64_1024` | 10,703 | **9,208** | **5,476** | **8,442** |
| `minmax.f64_1024` | 14,098 | **2,071** | **1,464** | **2,355** |
| `mean.f64_1024` | 4,774 | **683** | **653** | **1,765** |
| `variance.f64_1024` | 9,601 | **8,573** | **6,965** | 14,019 |
| `cumsum.f64_1024` | 40,898 | **904** | **837** | **2,301** |
| `quickselect.f64_1024` | 22,423 | **3,934** | **2,390** | **4,663** |
| `quantile.f64_1024` | 216,304 | **10,979** | **9,043** | **14,358** |
| `bisect.f64_1024` | 12,107 | **2,837** | **1,947** | **3,010** |
| `bin.sturges_1024` | 14,092 | 15,454 | **12,450** | 23,001 |
| `bin.fd_1024` | 157,709 | **28,844** | **23,989** | **41,057** |
| `ticks.batch32` | 2,910 | **2,630** | **2,181** | 4,262 |
| `range.1024` | 865 | **847** | **681** | 1,110 |
| `blur1.1024_r3` | 4,572 | **4,241** | **3,859** | 5,313 |
| `blur1.1024_r2_5` | 8,836 | **4,996** | **4,136** | **8,233** |
| `blur2.64x64_r2` | 47,193 | **31,010** | **25,578** | 60,012 |
| `sort.f64_1024` | 125,700 | **13,792** | **10,884** | **19,151** |
| `rank.f64_512` | 70,984 | **6,866** | **5,713** | **9,489** |
| `group.rollup_512` | 26,995 | **22,313** | **20,269** | 31,854 |
| `shuffle.1024` | 31,948 | **4,551** | **5,192** | **6,519** |

### Desktop & Mobile Browsers (ns/op, `upstream / dart2js / dart2wasm`)

| Case | Chrome 157 | Firefox 160 | Safari 27.0.1 | Pixel Chrome 157 | Pixel Firefox 160 |
|---|---|---|---|---|---|
| `sum.f64_1024` | 4,932 / **580** / 1,392 | 3,418 / **732** / 1,465 | 5,859 / **549** / 1,465 | 14,063 / 2,490 / **1,770** | 9,277 / **1,221** / 1,831 |
| `fsum.f64_1024` | 11,621 / 9,181 / **7,813** | 17,578 / 9,766 / **7,813** | 15,625 / **6,836** / 8,789 | 29,102 / 15,037 / **8,593** | 62,500 / 11,719 / **9,766** |
| `cumsum.f64_1024` | 35,937 / 1,526 / **1,087** | 9,766 / **732** / 1,221 | 16,602 / **977** / 1,587 | 85,938 / 10,010 / **1,428** | 15,625 / 2,441 / **1,953** |
| `quickselect.f64_1024` | 21,289 / 5,273 / **3,467** | 16,602 / 12,695 / **3,418** | 3,418 / 5,371 / **2,441** | 28,711 / 7,910 / **4,493** | 25,391 / 19,531 / **6,348** |
| `quantile.f64_1024` | 204,687 / 13,085 / **10,742** | 125,000 / **19,531** / 23,438 | 85,938 / **7,813** / 21,484 | 521,875 / 37,500 / **15,430** | 250,000 / **29,297** / 46,875 |
| `bisect.f64_1024` | 10,059 / 3,662 / **1,514** | 12,695 / 5,859 / **2,686** | 4,883 / **1,953** / **1,953** | 15,625 / 6,933 / **1,721** | 21,484 / 8,789 / **3,906** |
| `bin.fd_1024` | 151,562 / **28,320** / 33,594 | 101,563 / **39,063** / 46,875 | 54,688 / 46,875 / **31,250** | 312,500 / 107,023 / **57,035** | 187,500 / **78,125** / **78,125** |
| `blur2.64x64_r2` | 39,453 / 39,453 / **30,863** | 58,594 / 50,781 / **31,250** | **35,156** / **35,156** / **35,156** | 87,500 / 84,375 / **42,969** | 85,938 / 78,125 / **54,688** |
| `sort.f64_1024` | 117,188 / 16,408 / **14,160** | 85,938 / 21,484 / **17,578** | 109,375 / **12,695** / 17,578 | 184,375 / 38,281 / **22,852** | 132,813 / 39,063 / **33,203** |
| `rank.f64_512` | 71,094 / 8,301 / **6,641** | 54,688 / 8,789 / **7,813** | 42,969 / **5,859** / 7,813 | 125,781 / 18,555 / **10,448** | 101,563 / 14,648 / **11,719** |

## Upstream

- Upstream: [d3/d3-array](https://github.com/d3/d3-array) `v3.2.4` (`d3ArrayVersion`).
- Differences from upstream: [doc/differences.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_array_port/doc/differences.md).
- Full benchmark report: [doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_array_port/doc/performance.md).

## License

ISC, matching upstream `d3-array`. See [LICENSE](LICENSE). This project is not affiliated with the D3 project.
