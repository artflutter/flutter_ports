# flutter_d3_shape_port

A native Dart port of [d3-shape](https://github.com/d3/d3-shape) **3.2.0** for Dart and Flutter:
arcs, pies, lines, areas, radial lines/areas, links, all 13 built-in symbols, all 18 curve
interpolators, and streamgraph/stacked layouts (5 offsets × 6 orders) — rendering either SVG path
strings or directly onto Flutter `Canvas` via `UiPathContext` with zero JavaScript runtime and
zero WebView.

```dart
import 'package:flutter_d3_shape_port/flutter_d3_shape_port.dart';

// 1. Smooth monotone curve directly to a Flutter dart:ui.Path (zero SVG parsing)
final points = [(0.0, 40.0), (50.0, 10.0), (100.0, 60.0), (150.0, 20.0)];
final curveGen = line<(double, double)>()
  ..x = ((p, _, _) => p.$1)
  ..y = ((p, _, _) => p.$2)
  ..curve = curveMonotoneX;

final uiPath = curveGen.toUiPath(points); // draw directly with canvas.drawPath
final svg = curveGen(points); // or serialize SVG d="..."

// 2. Donut chart via pie() + arc()
final slices = (pie<double>()..padAngleConst(0.03))([30, 20, 15, 35]);
final donut = arc<PieArc<double>>()
  ..innerRadiusConst(40)
  ..outerRadiusConst(100)
  ..cornerRadiusConst(8);
for (final s in slices) {
  final slicePath = donut.toUiPath(s);
  final (cx, cy) = donut.centroid(s);
}

// 3. Streamgraph layout via stack()
final stacked = (stack<Map<String, double>, String>()
  ..keysConst(['a', 'b', 'c'])
  ..order = stackOrderInsideOut
  ..offset = stackOffsetWiggle)(rows);
```

## Installing

```sh
flutter pub add flutter_d3_shape_port
```

```dart
import 'package:flutter_d3_shape_port/flutter_d3_shape_port.dart' as d3;
```

`package:flutter_d3_shape_port/d3_shape.dart` exports the pure Dart API with no Flutter import, so
it compiles for the Dart VM, JavaScript and WebAssembly without the Flutter engine.

## API

- **Arcs & Pies:** `arc()`, `Arc<T>`, `ArcDatum`, `ArcData`, `pie()`, `Pie<T>`, `PieArc<T>`.
- **Lines & Areas:** `line()`, `Line<T>`, `lineRadial()`, `LineRadial<T>`, `area()`, `Area<T>`,
  `areaRadial()`, `AreaRadial<T>`, `pointRadial(angle, radius)`.
- **Links:** `link(curve)`, `linkHorizontal()`, `linkVertical()`, `linkRadial()`, `Link<L, N>`,
  `LinkRadial<L, N>`, `LinkDatum<N>`, `LinkData<N>`.
- **Symbols:** `symbol([type, size])`, `ShapeSymbol<T>`, `SymbolType`, `symbolsFill`,
  `symbolsStroke`, and all 13 built-in symbol types (`symbolCircle`, `symbolCross`,
  `symbolDiamond`, `symbolSquare`, `symbolStar`, `symbolTriangle`, `symbolWye`, `symbolTimes`,
  `symbolPlus`, `symbolAsterisk`, `symbolDiamond2`, `symbolSquare2`, `symbolTriangle2`).
- **Curves (all 18):** `curveLinear`, `curveLinearClosed`, `curveBasis`, `curveBasisClosed`,
  `curveBasisOpen`, `curveBundle`, `curveBumpX`, `curveBumpY`, `curveCardinal`,
  `curveCardinalClosed`, `curveCardinalOpen`, `curveCatmullRom`, `curveCatmullRomClosed`,
  `curveCatmullRomOpen`, `curveMonotoneX`, `curveMonotoneY`, `curveNatural`, `curveStep`,
  `curveStepBefore`, `curveStepAfter`, plus `curveRadial` / `curveRadialLinear`.
- **Stacks:** `stack()`, `Stack<D, K>`, `StackSeries<D, K>`, `StackPoint<D>`, offsets
  (`stackOffsetNone`, `stackOffsetExpand`, `stackOffsetDiverging`, `stackOffsetSilhouette`,
  `stackOffsetWiggle`), and orders (`stackOrderNone`, `stackOrderAscending`,
  `stackOrderDescending`, `stackOrderAppearance`, `stackOrderInsideOut`, `stackOrderReverse`).
- **Flutter layer (`flutter_d3_shape_port.dart`):** `.toUiPath(...)` extensions on every
  path-emitting generator (`Arc`, `Line`, `LineRadial`, `Area`, `AreaRadial`, `Link`,
  `LinkRadial`, `ShapeSymbol`) writing directly into `UiPathContext` (`dart:ui.Path`) with zero
  SVG serialization or parsing.

## Performance

Benchmarked on Apple M3 Max (Node.js v24.22.1, macOS CLI/Flutter AOT, Chrome 158, Firefox 160,
Safari 27) and Pixel 8a (Android 17 AOT release, Mobile Chrome 157). All values are median
**ns/op** (lower is better; see
[doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_shape_port/doc/performance.md)
for the complete 27-case breakdown including baseline vs optimized).

On native AOT, `flutter_d3_shape_port` outperforms upstream Node.js `d3-shape` on **19 of 20**
workloads — **3.1–7.9× faster** on curves, arcs, links, and symbols, **1.8× faster** on `pie`,
and **1.7× faster** on streamgraph `stackOffsetWiggle` — and writing straight to `dart:ui.Path`
via `UiPathContext` cuts curve/area/link latency another **1.7–2×** by skipping SVG strings
entirely.

### Shape generators (SVG output & layouts, ns/op)

| Case | Node.js upstream | macOS AOT | Pixel 8a Android AOT | Chrome 158 (js / wasm) | Firefox 160 (js / wasm) | Safari 27 (js / wasm) | Pixel Chrome 157 (js / wasm) |
|---|---:|---:|---:|---|---|---|---|
| `arc.plain20` | 14,817 | **4,132** | **8,242** | 8,594 / **6,104** | 13,672 / **9,277** | **7,813** / 16,602 | 16,991 / **11,327** |
| `arc.roundedPad20` | 35,063 | **11,101** | **20,506** | 22,268 / **15,723** | 29,297 / **19,531** | **23,438** / 27,344 | 43,750 / **25,779** |
| `pie.20` | 878 | **489** | **714** | 696 / **381** | **580** / 641 | **244** / 488 | 2,808 / **610** |
| `line.linear100` | 5,751 | **2,353** | **4,092** | 4,345 / **3,149** | 9,766 / **4,883** | **5,859** / 6,348 | 10,938 / **4,981** |
| `line.basis100` | 30,600 | **6,147** | **12,055** | 19,921 / **9,423** | 37,109 / **14,648** | 27,344 / **23,438** | 41,016 / **16,309** |
| `line.cardinal100` | 30,707 | **5,903** | **10,722** | 20,311 / **9,472** | 35,156 / **13,672** | 25,391 / **23,438** | 39,453 / **16,015** |
| `line.catmullRom100` | 26,451 | **7,161** | **12,757** | 20,705 / **10,742** | 37,109 / **15,625** | 25,391 / **21,484** | 37,500 / **16,895** |
| `line.monotoneX100` | 29,647 | **6,610** | **11,652** | 17,675 / **10,352** | 35,156 / **14,648** | **21,484** / **21,484** | 35,545 / **16,113** |
| `line.natural100` | 34,924 | **7,052** | **13,352** | 25,193 / **10,449** | 37,109 / **15,625** | 25,391 / **23,438** | 46,484 / **17,970** |
| `line.step100` | 12,401 | **4,074** | **7,350** | 9,082 / **5,761** | 18,555 / **8,789** | **8,301** / 11,719 | 20,702 / **9,717** |
| `area.linear100` | 13,053 | **4,584** | **7,999** | 11,915 / **5,859** | 19,531 / **9,277** | 15,625 / **10,742** | 27,344 / **9,620** |
| `area.monotoneX100` | 62,229 | **12,711** | **22,637** | 40,621 / **20,703** | 74,219 / **29,297** | 46,875 / **42,969** | 78,516 / **31,447** |
| `area.basis100` | 73,829 | **11,807** | **22,400** | 42,969 / **19,043** | 74,219 / **27,344** | 54,688 / **42,969** | 89,070 / **32,227** |
| `lineRadial.100` | 12,765 | **3,864** | **6,399** | 9,960 / **5,664** | 14,648 / **7,813** | 13,672 / **9,766** | 17,578 / **9,229** |
| `linkHorizontal.50` | 20,689 | **5,981** | **10,306** | 14,160 / **11,034** | 33,203 / **18,555** | **13,672** / 18,555 | 31,053 / **19,140** |
| `linkRadial.50` | 36,161 | **7,292** | **11,867** | 21,096 / **12,403** | 33,203 / **19,531** | 23,438 / **19,531** | 44,141 / **22,264** |
| `symbol.circle50` | 25,973 | **5,518** | **11,238** | 11,230 / **8,154** | 16,602 / **15,625** | **14,648** / 31,250 | 24,414 / **17,383** |
| `symbol.star50` | 77,880 | **9,844** | **15,923** | 34,961 / **15,430** | 62,500 / **25,391** | 39,063 / **23,438** | 64,059 / **25,588** |
| `stack.none` | 4,045 | 4,911 | 9,608 | 4,492 / 4,761 | 9,277 / 6,836 | **5,371** / 5,859 | 21,096 / **9,570** |
| `stack.wiggle` | 12,221 | **7,052** | 13,617 | **6,446** / 6,788 | 11,719 / **10,742** | **6,836** / 7,813 | 25,781 / **13,575** |

### Direct Flutter `UiPathContext` (`dart:ui.Path`, zero SVG strings, ns/op)

| Case | macOS M3 Max AOT | Pixel 8a Android AOT |
|---|---:|---:|
| `ui.arc.roundedPad20` | **17,744** | **29,043** |
| `ui.line.linear100` | **2,216** | **5,825** |
| `ui.line.monotoneX100` | **3,896** | **7,287** |
| `ui.line.catmullRom100` | **4,049** | **8,045** |
| `ui.area.monotoneX100` | **7,317** | **13,662** |
| `ui.linkHorizontal.50` | **3,238** | **9,042** |
| `ui.symbol.star50` | **8,169** | **13,906** |

## Upstream

- Upstream: [d3/d3-shape](https://github.com/d3/d3-shape) `v3.2.0` (`d3ShapeVersion`).
- Differences from upstream: [doc/differences.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_shape_port/doc/differences.md).
- Full benchmark report: [doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_shape_port/doc/performance.md).

## License

ISC, matching upstream `d3-shape`. See [LICENSE](LICENSE). This project is not affiliated with the D3 project.
