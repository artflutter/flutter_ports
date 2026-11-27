# flutter_d3_chord_port

A native, fully statically typed Dart port of
[d3-chord](https://github.com/d3/d3-chord) **3.0.1** for Dart and Flutter: circular chord layouts
(`chord`, `chordDirected`, `chordTranspose`) and ribbon path generators (`ribbon`, `ribbonArrow`,
`ribbonBy`, `ribbonArrowBy`), generating SVG path strings or drawing directly onto Flutter
`Canvas` via `UiPathContext` from `flutter_d3_path_port` — with **zero `dynamic`**, zero `Object?`
escape hatches where generics apply, and zero JavaScript runtime.

```dart
import 'package:flutter_d3_chord_port/flutter_d3_chord_port.dart';
import 'package:flutter_d3_path_port/flutter_d3_path_port.dart';

const matrix = <List<double>>[
  [11975, 5871, 8916, 2868],
  [1951, 10048, 2060, 6171],
  [8010, 16145, 8090, 8045],
  [1013, 990, 940, 6907],
];

// 1. Undirected chord layout with padding & descending subgroup sort
final layout = chord(padAngle: 0.05, sortSubgroups: (a, b) => b - a);
final chords = layout(matrix); // Chords extends ListBase<Chord> with .groups

// 2. Emit SVG path strings (pure Dart, zero Flutter import via d3_chord.dart)
final rib = ribbon(radius: 240);
final svgPath = rib(chords.first);

// 3. Draw directed arrow ribbons straight into Flutter dart:ui.Path
final directed = chordDirected(padAngle: 0.04)(matrix);
final arrow = ribbonArrow(sourceRadius: 200, targetRadius: 192, headRadius: 12);
final ctx = uiPathContext();
for (final c in directed) {
  ctx.reset();
  arrow.drawToUiPath(c, ctx); // zero SVG string allocation
}
```

## Installing

```sh
flutter pub add flutter_d3_chord_port
```

- **Pure Dart (`package:flutter_d3_chord_port/d3_chord.dart`):** zero Flutter imports; compiles for
  the Dart VM, AOT, JavaScript (`dart2js`), and WebAssembly (`dart2wasm`).
- **Flutter (`package:flutter_d3_chord_port/flutter_d3_chord_port.dart`):** re-exports
  `d3_chord.dart` plus direct `dart:ui.Path` helpers (`RibbonUiPath.toUiPath`,
  `RibbonUiPath.drawToUiPath`) backed by `UiPathContext`.

## API

- **Typed data models:** `ChordSubgroup` (`index`, `startAngle`, `endAngle`, `value`), `Chord`
  (`source`, `target`), `ChordGroup` (`index`, `startAngle`, `endAngle`, `value`), and
  `Chords extends ListBase<Chord>` carrying `final List<ChordGroup> groups`.
- **Chord layouts:** `ChordLayout` (`padAngle`, `sortGroups`, `sortSubgroups`, `sortChords`,
  `call(List<List<num>> matrix) -> Chords`) via `chord()`, `chordDirected()`, and
  `chordTranspose()`.
- **Ribbon generators:** `RibbonGenerator<T, S>` (`source`, `target`, `radius`, `sourceRadius`,
  `targetRadius`, `startAngle`, `endAngle`, `padAngle`, `headRadius`, `context`, `*Const` setters,
  `call(T d) -> String?`, and zero-allocation `draw(T d, CanvasPath context)`) via `ribbon()`,
  `ribbonArrow()`, `ribbonBy<T, S>()`, and `ribbonArrowBy<T, S>()`.
- **Flutter Canvas helpers:** `RibbonUiPath` (`toUiPath`, `drawToUiPath`) drawing directly into
  `UiPathContext` with zero SVG formatting or parsing.

## Performance

Benchmarked on Apple M3 Max (Node.js v24.22.1, macOS CLI/Flutter AOT, Chrome 157, Firefox 160,
Safari 27.0.1), iOS 27.2 (`ios-arm64` Flutter AOT release), and Pixel 8a (Android 17 AOT release,
Mobile Chrome 157, Mobile Firefox 160). All values are median **ns/op** (lower is better; see
[doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_chord_port/doc/performance.md)
for the complete 12-case + `UiPathContext` breakdown including baseline vs optimized).

- **Native AOT:** beats Node.js `d3-chord` on **12/12** workloads on macOS M3 Max (up to **5.75×
  faster**) and **12/12** on iOS 27.2 AOT (up to **8.34× faster**); direct `UiPathContext` builds
  all 136/180 native `dart:ui.Path` ribbons **2.45×–4.37× faster** than Node.js SVG formatting.
- **Web (`dart2wasm` & `dart2js`):** best Dart target beats upstream JS on **12/12** cases across
  every tested desktop and mobile browser (up to **11.29× faster** in Mobile Chrome Wasm).

### Native AOT vs Node.js (ns/op)

| Case | Node.js upstream | macOS AOT | iOS 27.2 AOT | Pixel 8a Android AOT |
|---|---:|---:|---:|---:|
| `chord.4x4` | 2,032 | **378** | **244** | **501** |
| `chord.16x16` | 18,860 | **4,557** | **3,246** | **5,974** |
| `chord.32x32` | 91,649 | **17,847** | **13,102** | **24,077** |
| `chord.32x32_sorted` | 212,296 | **111,423** | **92,719** | **167,224** |
| `chordDirected.16x16` | 29,879 | **5,490** | **4,280** | **7,396** |
| `chordDirected.32x32_sorted` | 439,872 | **236,498** | **200,416** | **398,192** |
| `chordTranspose.16x16` | 19,422 | **4,408** | **3,406** | **5,838** |
| `ribbon.svg_136` | 101,616 | **72,406** | **56,722** | 144,581 |
| `ribbon.padded_136` | 100,566 | **66,651** | **52,473** | 134,596 |
| `ribbonArrow.svg_180` | 138,370 | **109,062** | **88,081** | 229,244 |
| `ribbon.canvas_136` | 19,524 | **4,922** | **4,095** | **7,733** |
| `ribbonArrow.canvas_180` | 31,860 | **8,917** | **8,173** | **16,138** |
| **`ui.ribbon.136`** | — | 41,473 | **28,011** | 67,829 |
| **`ui.ribbonArrow.180`** | — | 44,861 | **31,630** | 76,728 |

### Desktop & Mobile Browsers (ns/op, `upstream / dart2js / dart2wasm`)

| Case | Chrome 157 | Firefox 160 | Safari 27.0.1 | Pixel Chrome 157 | Pixel Firefox 160 |
|---|---|---|---|---|---|
| `chord.4x4` | 1,815 / 319 / **229** | 989 / 838 / **390** | 684 / 570 / **310** | 4,403 / 1,405 / **405** | 1,807 / 1,678 / **630** |
| `chord.32x32` | 63,351 / 13,555 / **9,916** | 35,735 / 33,408 / **19,520** | 38,343 / 32,633 / **16,704** | 153,827 / 62,259 / **16,471** | 67,669 / 65,266 / **32,626** |
| `chord.32x32_sorted` | 156,989 / **41,695** / 66,488 | 164,063 / **62,245** / 185,410 | 103,691 / **48,996** / 116,279 | 328,192 / **119,581** / 168,571 | 260,870 / **125,000** / 320,856 |
| `chordDirected.16x16` | 25,533 / 4,716 / **3,145** | 13,202 / 12,939 / **5,708** | 12,200 / 11,475 / **4,801** | 57,787 / 21,190 / **5,196** | 25,946 / 21,441 / **11,230** |
| `ribbon.svg_136` | 83,750 / **47,891** / 95,783 | 131,250 / **123,047** / 164,063 | 120,654 / **55,659** / 174,286 | 158,005 / **100,496** / 157,292 | 209,460 / **191,824** / 341,041 |
| `ribbonArrow.svg_180` | 119,141 / **70,376** / 148,007 | 209,460 / **191,951** / 250,000 | 174,286 / **86,066** / 248,996 | 274,453 / **176,347** / 239,760 | 342,697 / **299,065** / 535,088 |
| `ribbon.canvas_136` | 17,357 / 6,619 / **4,665** | 21,840 / **5,046** / 6,001 | 14,848 / **2,820** / 8,190 | 32,904 / 16,562 / **8,286** | 39,630 / **9,666** / 11,962 |
| `ribbonArrow.canvas_180` | 28,632 / 12,841 / **11,296** | 32,038 / **9,521** / 11,762 | 21,890 / **5,762** / 18,229 | 51,546 / 31,823 / **20,573** | 61,413 / **17,601** / 23,828 |

## Upstream

- Upstream: [d3/d3-chord](https://github.com/d3/d3-chord) `v3.0.1` (`d3ChordVersion`).
- Differences from upstream:
  [doc/differences.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_chord_port/doc/differences.md).
- Full benchmark report:
  [doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_chord_port/doc/performance.md).

## License

ISC, matching upstream `d3-chord`. See [LICENSE](LICENSE). This project is not affiliated with
the D3 project.
