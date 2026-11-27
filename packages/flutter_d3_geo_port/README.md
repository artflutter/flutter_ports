# flutter_d3_geo_port

A native, fully statically typed Dart port of
[d3-geo](https://github.com/d3/d3-geo) **3.1.1** for Dart and Flutter: sealed GeoJSON geometry
models, spherical math (`geoArea`, `geoBounds`, `geoCentroid`, `geoContains`, `geoDistance`,
`geoInterpolate`, `geoLength`, `geoRotation`, `geoStream`), generators (`geoGraticule`,
`geoGraticule10`, `geoCircle`), spherical & planar clipping (`geoClipAntimeridian`,
`geoClipCircle`, `geoClipRectangle`), all 15 built-in map projections (and `*Raw` functions),
and `geoPath` generating SVG path strings or drawing directly onto Flutter `Canvas` via
`UiPathContext` from `flutter_d3_path_port` — with **zero `dynamic`**, zero `Object?` escape
hatches where generics apply, and zero JavaScript runtime.

```dart
import 'package:flutter_d3_geo_port/flutter_d3_geo_port.dart';
import 'package:flutter_d3_path_port/flutter_d3_path_port.dart';

// 1. Configure an Orthographic 3D globe projection
final globe = geoOrthographic()
  ..rotate = const (-10, -25, 0)
  ..translate = const (480, 250)
  ..scale = 240;

// 2. Emit SVG path strings (pure Dart, zero Flutter import via d3_geo.dart)
final pathGen = geoPath(globe);
final graticuleSvg = pathGen(geoGraticule10());

// 3. Draw directly into a native Flutter dart:ui.Path with zero SVG allocation
final ctx = uiPathContext();
pathGen.drawToUiPath(const GeoSphere(), ctx);
pathGen.drawToUiPath(geoCircle(center: const (-122.4, 37.8), radius: 15)(), ctx);

// 4. Spherical distance & great-circle interpolation
const sf = (-122.4194, 37.7749);
const tokyo = (139.6917, 35.6895);
final radians = geoDistance(sf, tokyo);
final midpoint = geoInterpolate(sf, tokyo)(0.5);
```

## Installing

```sh
flutter pub add flutter_d3_geo_port
```

- **Pure Dart (`package:flutter_d3_geo_port/d3_geo.dart`):** zero Flutter imports; compiles for
  the Dart VM, AOT, JavaScript (`dart2js`), and WebAssembly (`dart2wasm`).
- **Flutter (`package:flutter_d3_geo_port/flutter_d3_geo_port.dart`):** re-exports `d3_geo.dart`
  plus direct `dart:ui.Path` helpers (`GeoPathUiPath.toUiPath`, `GeoPathUiPath.drawToUiPath`)
  backed by `UiPathContext`.

## API

- **Sealed GeoJSON hierarchy:** `sealed class GeoJsonObject`, `sealed class GeoGeometry`,
  `GeoSphere`, `GeoPoint`, `GeoMultiPoint`, `GeoLineString`, `GeoMultiLineString`, `GeoPolygon`,
  `GeoMultiPolygon`, `GeoGeometryCollection`, `GeoFeature<P>`, `GeoFeatureCollection<P>` (with
  typed `fromJson`/`toJson` on `Map<String, Object?>`), `GeoPosition = (double lon, double lat)`,
  and `GeoExtent = (GeoPosition min, GeoPosition max)`.
- **Spherical geometry & streams:** `GeoStream`, `GeoStreamCallbacks`, `geoStream`, `geoArea`,
  `geoBounds`, `geoCentroid`, `geoContains`, `geoDistance`, `geoInterpolate`, `geoLength`,
  `geoRotation` / `GeoRotation`, `geoTransform` / `GeoTransform`, `geoIdentity` /
  `GeoIdentityTransform`.
- **Generators & clipping:** `geoGraticule` / `GeoGraticuleGenerator`, `geoGraticule10`,
  `geoCircle` / `GeoCircleGenerator`, `geoClipAntimeridian`, `geoClipCircle`, `geoClipRectangle`,
  `geoClipExtent`.
- **Projections (`GeoProjection`, `GeoConicProjection`, `GeoRawProjection`, `geoProjection`,
  `geoProjectionMutator`):** `geoAlbers`, `geoAlbersUsa`, `geoAzimuthalEqualArea`,
  `geoAzimuthalEquidistant`, `geoConicConformal`, `geoConicEqualArea`, `geoConicEquidistant`,
  `geoEqualEarth`, `geoEquirectangular`, `geoGnomonic`, `geoMercator`, `geoNaturalEarth1`,
  `geoOrthographic`, `geoStereographic`, `geoTransverseMercator`, plus every `*Raw` projection.
- **Paths & Flutter Canvas:** `geoPath` / `GeoPath` (`call`, `draw`, `area`, `bounds`, `centroid`,
  `measure`, `pointRadius`, `pointRadiusAccessor`, `digits`, `projection`, `context`) and
  `GeoPathUiPath` (`toUiPath`, `drawToUiPath`).

## Performance

Benchmarked on Apple M3 Max (Node.js v24.22.1, macOS CLI/Flutter AOT, Chrome 157, Firefox 160,
Safari 27.0.1) and Pixel 8a (Android 17 AOT release, Mobile Chrome 158, Mobile Firefox 160). All
values are median **ns/op** (lower is better; see
[doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_geo_port/doc/performance.md)
for the full 12-case + `UiPathContext` breakdown including baseline vs optimized).

- **Native AOT:** macOS M3 Max Flutter AOT beats Node.js `d3-geo` on **12/12** workloads (up to
  **5.42× faster**), and Pixel 8a Android AOT beats desktop M3 Max Node.js on **12/12** workloads
  (up to **2.41× faster**); direct `UiPathContext` builds a full world + graticule `dart:ui.Path`
  in **497–549 µs** on macOS and **806–876 µs** on Pixel 8a.
- **Web (`dart2wasm` & `dart2js`):** best Dart target beats upstream JS on **12/12** cases in
  Chrome 157, Safari 27.0.1, Pixel Chrome 158, and Pixel Firefox 160, and **11/12** in Firefox 160
  (up to **2.63× faster** in Mobile Chrome Wasm).

### Native AOT vs Node.js (ns/op)

| Case | Node.js upstream | macOS AOT | Pixel 8a Android AOT |
|---|---:|---:|---:|
| `project.orthographic_1k` | 132,234 | **49,814** | **94,633** |
| `project.mercator_1k` | 76,318 | **14,079** | **31,661** |
| `project.equalEarth_1k` | 188,286 | **110,991** | **175,701** |
| `project.naturalEarth1_1k` | 123,976 | **59,538** | **96,811** |
| `project.albersUsa_1k` | 92,569 | **35,276** | **55,768** |
| `path.ortho_canvas` | 854,658 | **456,602** | **784,040** |
| `path.mercator_canvas` | 1,207,688 | **546,883** | **935,938** |
| `path.naturalEarth1_svg` | 527,720 | **186,979** | **331,829** |
| `path.equalEarth_canvas` | 1,151,208 | **590,050** | **945,857** |
| `geoArea.world` | 78,670 | **44,917** | **71,922** |
| `geoBounds.world` | 227,412 | **95,650** | **204,118** |
| `geoContains.500` | 11,301,813 | **4,152,786** | **7,891,571** |
| **`ui.ortho_world`** | — | **548,613** | 876,029 |
| **`ui.naturalEarth1_world`** | — | **497,197** | 805,760 |

### Desktop & Mobile Browsers (ns/op, `upstream / dart2js / dart2wasm`)

| Case | Chrome 157 | Firefox 160 | Safari 27.0.1 | Pixel Chrome 158 | Pixel Firefox 160 |
|---|---|---|---|---|---|
| `project.orthographic_1k` | 115,270 / 94,833 / **83,564** | 93,272 / **62,500** / 79,427 | 117,257 / **60,417** / 140,625 | 200,000 / 148,815 / **141,298** | 148,515 / **116,667** / 130,556 |
| `project.mercator_1k` | 57,804 / 26,418 / **22,922** | 68,337 / **39,063** / 39,844 | 41,758 / **22,135** / 42,969 | 101,634 / 49,167 / **38,654** | 100,977 / 69,010 / **55,990** |
| `project.albersUsa_1k` | 93,023 / 46,904 / **42,938** | 60,545 / **45,537** / 48,270 | 77,411 / **32,552** / 61,458 | 186,810 / 94,063 / **74,591** | 130,531 / **80,729** / 85,938 |
| `path.ortho_canvas` | 897,015 / 637,805 / **599,989** | 622,449 / **525,000** / 604,167 | 710,843 / **487,500** / 875,000 | 1,758,824 / 1,134,000 / **990,323** | 1,132,076 / **923,077** / 1,037,037 |
| `path.mercator_canvas` | 1,094,340 / 701,266 / **615,306** | 939,394 / **782,609** / 825,000 | 837,838 / **600,000** / 884,058 | 2,064,286 / 1,271,111 / **1,030,303** | 1,500,000 / **1,277,778** / 1,325,000 |
| `path.naturalEarth1_svg` | 454,887 / 350,000 / **239,457** | 382,166 / 384,058 / **302,083** | 376,623 / **296,875** / 317,708 | 975,472 / 643,750 / **404,211** | 682,353 / 637,500 / **521,739** |
| `geoArea.world` | 108,556 / **55,952** / 60,041 | 62,299 / **51,913** / 63,802 | 51,960 / **47,359** / 91,075 | 171,633 / 97,808 / **92,571** | 99,831 / **78,125** / 93,677 |
| `geoBounds.world` | 275,556 / 178,834 / **153,383** | 177,650 / 158,854 / **145,833** | 157,333 / **140,625** / 247,664 | 465,649 / 276,768 / **252,143** | 299,492 / 260,684 / **246,377** |
| `geoContains.500` | 6,488,889 / **5,437,500** / 6,050,167 | 5,900,000 / **4,833,333** / 6,428,571 | 4,833,333 / **4,222,222** / 7,600,000 | 13,550,000 / 11,450,000 / **10,225,000** | 10,000,000 / **8,200,000** / 9,750,000 |

## Upstream

- Upstream: [d3/d3-geo](https://github.com/d3/d3-geo) `v3.1.1` (`d3GeoVersion`).
- Differences from upstream:
  [doc/differences.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_geo_port/doc/differences.md).
- Full benchmark report:
  [doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_geo_port/doc/performance.md).

## License

ISC (with MIT portions from Charles Karney's GeographicLib), matching upstream `d3-geo`
([LICENSE](LICENSE)).
