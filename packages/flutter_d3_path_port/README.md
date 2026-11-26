# flutter_d3_path_port

A native Dart port of [d3-path](https://github.com/d3/d3-path) **3.1.0** for Flutter:
serialize Canvas 2D path commands to SVG path data strings (`Path`, `path`, `pathRound`),
plus a native Flutter `dart:ui.Path` builder (`UiPathContext`) implementing the same
`CanvasPath` interface — with zero JavaScript and zero WebView.

## Usage

### Pure Dart (SVG path string)

```dart
import 'dart:math' as math;
import 'package:flutter_d3_path_port/d3_path.dart';

void main() {
  final p = path()
    ..moveTo(0, 0)
    ..lineTo(100, 0)
    ..arc(100, 50, 50, -math.pi / 2, math.pi / 2)
    ..closePath();
  print(p); // M0,0L100,0A50,50,0,1,1,100,100Z

  final rounded = pathRound(2)
    ..moveTo(math.pi, math.e);
  print(rounded); // M3.14,2.72
}
```

### Flutter (`dart:ui.Path` without SVG strings)

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

// Draw directly into a native dart:ui.Path:
final uiCtx = uiPathContext();
drawShape(uiCtx);
final uiPath = uiCtx.path;
```

## Upstream

- Upstream: [d3/d3-path](https://github.com/d3/d3-path) `v3.1.0` (`d3PathVersion`).
- Differences from upstream: [doc/differences.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_path_port/doc/differences.md).
- Cross-platform benchmarks: [doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_path_port/doc/performance.md).

## License

ISC, matching upstream `d3-path`. See [LICENSE](LICENSE). This project is not affiliated with the D3 project.
