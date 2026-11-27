# flutter_d3_contour_port

A native, fully statically typed, pure-Dart port of [d3-contour](https://github.com/d3/d3-contour)
**4.0.2** for Dart and Flutter: marching-squares contour polygons (`contours`, `Contours`,
`ContourMultiPolygon`) and 2D kernel density estimation (`contourDensity`, `contourDensityPoints`,
`ContourDensity<T>`, `DensityContours`) — with **zero `dynamic`**, zero Flutter dependency, and
zero JavaScript runtime.

```dart
import 'dart:typed_data';
import 'package:flutter_d3_contour_port/flutter_d3_contour_port.dart';

// 1. Marching-squares contours over a 2D scalar grid
const n = 32;
final grid = Float64List(n * n);
for (var y = 0; y < n; ++y) {
  for (var x = 0; x < n; ++x) {
    final dx = x - 15.5;
    final dy = y - 15.5;
    grid[y * n + x] = 100.0 - (dx * dx + dy * dy);
  }
}
final iso = contours(size: (n, n), thresholdsCount: 10);
final List<ContourMultiPolygon> bands = iso(grid);
final ContourMultiPolygon level50 = iso.contour(grid, 50);

// 2. 2D kernel density estimation over typed point data
typedef Sample = ({double x, double y, double weight});
final density = contourDensity<Sample>(
  x: (d) => d.x,
  y: (d) => d.y,
  weight: (d) => d.weight,
  size: (640, 400),
  bandwidth: 20,
  cellSize: 4,
  thresholdsCount: 12,
);
final List<ContourMultiPolygon> densityBands = density(samples);

// Or precompute the blurred density grid once and query arbitrary levels:
final DensityContours evaluator = density.contours(samples);
final ContourMultiPolygon halfPeak = evaluator(evaluator.max * 0.5);
```

## Installing

```sh
dart pub add flutter_d3_contour_port
```

```dart
import 'package:flutter_d3_contour_port/flutter_d3_contour_port.dart' as d3;
```

`package:flutter_d3_contour_port/d3_contour.dart` and
`package:flutter_d3_contour_port/flutter_d3_contour_port.dart` are both pure Dart libraries
depending only on `flutter_d3_array_port`, compiling cleanly for the Dart VM, AOT, JavaScript
(`dart2js`), and WebAssembly (`dart2wasm`).

## API

- **Geometry:** `ContourMultiPolygon` (`type`, `value`, `coordinates: List<List<List<(double,
  double)>>>`, `toGeoJson()`), plus typedefs `ContourPoint`, `ContourRing`, and `ContourPolygon`.
- **Marching squares:** `contours(...)` / `Contours` (`size`, `smooth`, `thresholdsCount`,
  `thresholdsValues`, `thresholdsGenerator`, `thresholdsCountGenerator`, `call(List<double>)`,
  `contour(List<double>, double)`).
- **2D kernel density:** `contourDensity<T>(x:, y:, ...)` / `contourDensityPoints(...)` /
  `ContourDensity<T>` (`x`/`xIndexed`/`xConst`, `y`/`yIndexed`/`yConst`,
  `weight`/`weightIndexed`/`weightConst`, `size`, `cellSize`, `bandwidth`, `thresholdsCount`,
  `thresholdsValues`, `thresholdsGenerator`, `thresholdsCountGenerator`, `call(Iterable<T>)`,
  `contours(Iterable<T>) -> DensityContours` with `.max` and `call(double)`).
- **Helpers:** `contourRingArea`, `contourContains`, `contourAscending`, `contourArraySlice`,
  `contourConstant`, `contourNoop`, `d3ContourVersion`.

## Performance

Benchmarked on Apple M3 Max (Node.js v24.22.1, macOS CLI/Flutter AOT, Chrome 158, Firefox 161,
Safari 27.0.1), iOS 27.2 (`ios-arm64` Flutter AOT release), and Pixel 8a (Android 17 AOT release,
Mobile Chrome 157, Mobile Firefox 160). All values are median **µs/op** (lower is better; see
[doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_contour_port/doc/performance.md)
for the complete baseline vs optimized breakdown).

- **Native AOT:** beats Node.js `d3-contour` on **12/12** workloads across macOS M3 Max (up to
  **5.4× faster**), iOS 27.2 (up to **5.65× faster**), and Pixel 8a Android (12/12 faster than
  desktop M3 Max Node.js).
- **Web (`dart2wasm` & `dart2js`):** beats upstream JS on **12/12** workloads in every tested
  browser — Desktop Chrome 158, Desktop Firefox 161, Desktop Safari 27.0.1, Mobile Chrome 157
  (up to **4.7× faster** via `dart2wasm`), and Mobile Firefox 160 (up to **4.2× faster**).

### Native AOT vs Node.js (µs/op)

| Case | Node.js upstream | macOS AOT | iOS 27.2 AOT | Pixel 8a Android AOT |
|---|---:|---:|---:|---:|
| `contours.peaks_64x64_10` | 731.6 | **196.3** | **153.2** | **291.8** |
| `contours.peaks_64x64_raw` | 741.8 | **179.9** | **164.1** | **276.2** |
| `contours.peaks_128x128_10` | 2,137.9 | **616.0** | **534.3** | **964.9** |
| `contours.single_128x128` | 148.7 | **48.9** | **44.0** | **78.9** |
| `contours.holes_64x64` | 1,810.4 | **388.8** | **374.5** | **710.3** |
| `contours.goldstein_96x96_12` | 2,339.3 | **435.1** | **413.9** | **712.1** |
| `density.faithful_bw30` | 4,714.5 | **2,220.5** | **2,115.6** | **4,206.6** |
| `density.clusters_2000_cs4` | 3,091.7 | **1,120.6** | **1,010.9** | **1,803.1** |
| `density.clusters_2000_cs2` | 6,002.4 | **2,884.4** | **2,774.5** | **5,885.3** |
| `density.clusters_10000_cs4` | 1,689.7 | **720.0** | **672.1** | **1,197.6** |
| `density.weighted_2000` | 2,745.0 | **1,042.5** | **1,000.4** | **1,728.8** |
| `density.contours_query5` | 1,500.4 | **575.6** | **513.5** | **946.1** |

### Desktop & Mobile Browsers (µs/op, `upstream / dart2js / dart2wasm`)

| Case | Chrome 158 | Firefox 161 | Safari 27.0.1 | Pixel Chrome 157 | Pixel Firefox 160 |
|---|---|---|---|---|---|
| `contours.peaks_64x64_10` | 578.1 / 175.0 / **145.3** | 718.8 / 250.0 / **234.4** | 593.8 / 171.9 / **156.3** | 1,075.0 / 465.6 / **228.1** | 1,437.5 / 500.0 / **406.3** |
| `contours.peaks_128x128_10` | 1,606.2 / 543.8 / **456.3** | 2,125.0 / 718.8 / **656.3** | 1,625.0 / 500.0 / **468.8** | 2,962.5 / 1,418.8 / **696.9** | 3,750.0 / **1,250.0** / **1,250.0** |
| `contours.holes_64x64` | 1,262.5 / **275.0** / 309.4 | 1,625.0 / **406.3** / 500.0 | 1,000.0 / **281.3** / 328.1 | 2,812.5 / 1,050.0 / **596.9** | 3,375.0 / **812.5** / 937.5 |
| `contours.goldstein_96x96_12` | 1,562.5 / 428.1 / **367.2** | 1,875.0 / **593.8** / **593.8** | 1,437.5 / 406.3 / **390.6** | 2,800.0 / 1,131.3 / **634.4** | 3,625.0 / 1,125.0 / **1,062.5** |
| `density.faithful_bw30` | 4,375.0 / 2,012.5 / **1,531.3** | 5,250.0 / 2,625.0 / **2,000.0** | 4,500.0 / **1,625.0** / 1,750.0 | 7,950.0 / 4,450.0 / **2,225.0** | 10,500.0 / 4,500.0 / **3,500.0** |
| `density.clusters_2000_cs4` | 2,525.0 / 1,125.0 / **906.3** | 3,125.0 / 1,437.5 / **1,125.0** | 2,625.0 / **1,000.0** / **1,000.0** | 4,550.0 / 2,612.5 / **1,299.9** | 6,000.0 / 2,625.0 / **2,125.0** |
| `density.clusters_2000_cs2` | 5,425.0 / 2,825.0 / **2,262.6** | 7,000.0 / 3,750.0 / **2,625.0** | 6,000.0 / **2,375.0** / 2,625.0 | 10,150.0 / 6,200.0 / **3,225.0** | 13,000.0 / 6,250.0 / **4,750.0** |
| `density.clusters_10000_cs4` | 1,525.0 / 812.5 / **690.6** | 1,875.0 / 1,062.5 / **875.0** | 1,625.0 / **687.5** / 843.8 | 2,850.0 / 2,037.5 / **950.0** | 3,625.0 / 1,750.0 / **1,562.5** |

## Upstream

- Upstream: [d3/d3-contour](https://github.com/d3/d3-contour) `v4.0.2` (`d3ContourVersion`).
- Differences from upstream: [doc/differences.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_contour_port/doc/differences.md).
- Full benchmark report: [doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_contour_port/doc/performance.md).

## License

ISC, matching upstream `d3-contour`. See [LICENSE](LICENSE). This project is not affiliated with the D3 project.
