# flutter_d3_path_port

A native Dart port of [d3-path](https://github.com/d3/d3-path) **3.1.0** for Dart and Flutter:
serialize Canvas 2D path commands to SVG path data strings (`Path`, `path`, `pathRound`), plus a
native Flutter `dart:ui.Path` builder (`UiPathContext`) implementing the same `CanvasPath`
interface — with zero JavaScript runtime and zero WebView.

```dart
import 'dart:math' as math;
import 'package:flutter_d3_path_port/flutter_d3_path_port.dart';

void drawShape(CanvasPath context) {
  context
    ..moveTo(0, 0)
    ..lineTo(100, 0)
    ..arc(100, 50, 50, -math.pi / 2, math.pi / 2)
    ..closePath();
}

// 1. Serialize to SVG path data (pure Dart)
final svg = path();
drawShape(svg);
print(svg); // M0,0L100,0A50,50,0,1,1,100,100Z

final rounded = pathRound(2)..moveTo(math.pi, math.e);
print(rounded); // M3.14,2.72

// 2. Build a native Flutter dart:ui.Path directly (zero SVG parsing)
final uiCtx = uiPathContext();
drawShape(uiCtx);
final uiPath = uiCtx.path;
```

## Installing

```sh
flutter pub add flutter_d3_path_port
```

```dart
import 'package:flutter_d3_path_port/flutter_d3_path_port.dart' as d3;
```

`package:flutter_d3_path_port/d3_path.dart` exports the pure Dart API (`CanvasPath`, `Path`,
`path`, `pathRound`, `d3PathVersion`) with no Flutter import, so it compiles for the Dart VM,
JavaScript and WebAssembly without the Flutter engine.

## API

- **`CanvasPath`**: pure interface with all 8 Canvas 2D methods used by D3 generators (`moveTo`,
  `closePath`, `lineTo`, `quadraticCurveTo`, `bezierCurveTo`, `arcTo`, `arc`, `rect`).
- **`Path([int? digits])` / `path()` / `pathRound([int digits = 3])`**: implements `CanvasPath`
  and serializes commands to an SVG `d="..."` string via `toString()`.
- **`UiPathContext([ui.Path? path])` / `uiPathContext([ui.Path? path])`** (Flutter layer):
  implements `CanvasPath` directly on `dart:ui.Path` with full Canvas 2D arc/arcTo/rect/empty-path
  semantics and `reset()` for zero-allocation frame reuse.

## Performance

Benchmarked on Apple M3 Max (Node.js v24.22.1, macOS CLI/Flutter AOT, Chrome 158, Firefox 161,
Safari 27), iPhone 17 Pro (iOS 27.2 AOT release), and Pixel 8a (Android 17 AOT release, Mobile
Chrome 157, Mobile Firefox 160). All values are median **ns/op** (lower is better; see
[doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_path_port/doc/performance.md)
for the complete 22-case breakdown including baseline vs optimized).

On native AOT and Wasm, `Path` writes ASCII bytes directly into a growable `Uint8List` buffer
using multiply-shift integer / `pathRound(0..6)` decimal emission and a clean-room 30-bit-limb
Ryū binary64 shortest-decimal formatter — cutting `pathRound(3)` by **7.9–15.2×** on AOT
(**3.6–5.7× faster than Node.js**) and full-precision paths by **2.9–4.4×**.

### SVG path serialization (`Path` / `pathRound`, ns/op)

| Case | Node.js upstream | macOS AOT | iPhone 17 Pro iOS | Pixel 8a Android | Chrome (js / wasm) | Safari (js / wasm) | Firefox (js / wasm) | Pixel Chrome (js / wasm) | Pixel Firefox (js / wasm) |
|---|---:|---:|---:|---:|---|---|---|---|---|
| `polyline100.full` | 5,145 | 7,368 | 9,804 | 23,316 | **2,344** / 10,157 | **3,418** / 42,969 | 14,648 / 19,531 | **5,176** / 17,971 | 21,484 / 35,156 |
| `polyline100.round3` | 7,760 | **2,112** | **4,382** | **4,758** | 4,980 / **4,249** | **5,859** / 8,789 | 15,625 / **5,859** | 10,841 / **6,299** | 19,531 / **12,695** |
| `polyline100.int` | 4,780 | **1,381** | **1,781** | **3,006** | 2,759 / **2,661** | **3,174** / 5,371 | 4,883 / **3,662** | 9,766 / **4,639** | 9,277 / 7,812 |
| `bezier50.full` | 8,251 | 10,633 | 16,070 | 28,629 | **3,955** / 15,236 | **5,371** / 31,250 | 21,484 / 29,297 | **7,909** / 26,758 | 31,250 / 54,688 |
| `bezier50.round3` | 12,040 | **3,041** | **4,977** | **5,481** | 7,373 / **6,348** | **9,766** / 12,695 | 21,484 / **8,789** | 16,406 / **9,570** | 27,344 / **17,578** |
| `quad50.full` | 5,309 | 7,418 | 11,767 | 19,108 | **2,539** / 10,254 | **3,174** / 19,531 | 13,672 / 19,531 | **5,029** / 17,385 | 21,484 / 35,156 |
| `quad50.round3` | 7,520 | **2,010** | **3,221** | **3,429** | 4,590 / **4,248** | **5,371** / 7,324 | 13,672 / **5,859** | 9,961 / **6,201** | 17,578 / **11,719** |
| `arc20.full` | 5,125 | **4,692** | 7,651 | 12,064 | **2,637** / 6,885 | **3,174** / 13,672 | 8,301 / 11,719 | **4,834** / 11,621 | 12,695 / 23,438 |
| `arc20.round3` | 6,184 | **1,725** | **2,823** | **3,354** | 3,906 / **3,101** | **3,906** / 6,836 | 7,812 / **3,906** | 7,520 / **5,176** | 10,742 / **8,789** |
| `arcTo20.full` | 10,830 | **6,268** | **7,181** | 12,700 | **4,981** / 7,421 | **6,348** / 14,648 | 9,766 / 12,695 | **8,691** / 11,719 | 13,672 / 23,438 |
| `arcTo20.round3` | 9,014 | **2,299** | **2,188** | **3,897** | 5,078 / **3,565** | **6,348** / 6,836 | 8,789 / **4,395** | 9,472 / **5,176** | 11,719 / **9,766** |
| `rect50.full` | 13,880 | **8,747** | **11,898** | 24,320 | **5,665** / 12,695 | **6,836** / 27,344 | 17,578 / 23,438 | **10,547** / 22,461 | 27,344 / 46,875 |
| `rect50.round3` | 14,251 | **2,483** | **3,508** | **4,406** | 7,080 / **5,127** | 9,766 / **8,789** | 17,578 / **6,836** | 15,039 / **8,008** | 23,438 / **16,602** |
| `mixed.full` | 1,442 | **1,360** | 1,981 | 3,192 | **781** / 1,770 | **1,099** / 3,418 | 2,441 / 3,418 | **1,428** / 3,027 | 4,150 / 7,324 |
| `mixed.round3` | 1,920 | **450** | **652** | **944** | 1,074 / **769** | **1,465** / **1,465** | 2,197 / **1,099** | 2,100 / **1,221** | 3,174 / **2,197** |

### Direct Flutter `UiPathContext` (`dart:ui.Path`, zero SVG strings, ns/op)

| Case | macOS M3 Max AOT | iPhone 17 Pro iOS AOT | Pixel 8a Android AOT |
|---|---:|---:|---:|
| `ui.polyline100` | **1,585** | **1,923** | **5,879** |
| `ui.bezier50` | **1,218** | **1,429** | **2,593** |
| `ui.quad50` | **1,003** | **914** | **2,169** |
| `ui.arc20` | **3,294** | **2,452** | **5,345** |
| `ui.arcTo20` | **4,086** | **4,502** | **6,115** |
| `ui.rect50` | **2,932** | **4,210** | **5,673** |
| `ui.mixed` | **707** | **905** | **1,209** |

## Upstream

- Upstream: [d3/d3-path](https://github.com/d3/d3-path) `v3.1.0` (`d3PathVersion`).
- Differences from upstream: [doc/differences.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_path_port/doc/differences.md).
- Full benchmark report: [doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_path_port/doc/performance.md).

## License

ISC, matching upstream `d3-path`. See [LICENSE](LICENSE). This project is not affiliated with the D3 project.
