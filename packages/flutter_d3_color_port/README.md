# flutter_d3_color_port

A native Dart port of [d3-color](https://github.com/d3/d3-color) 3.1.0, the color module of
[D3](https://d3js.org) ([`d3-color`](https://www.npmjs.com/package/d3-color) on npm). It parses
CSS colors and converts them between the RGB, HSL, CIELAB, HCL (CIELCh) and Cubehelix color spaces.
The package runs no JavaScript: each color is a Dart class with `double` channels. It converts
to and from the Flutter `Color`.

> **Status:** 0.1.0, not published. It is part of the D3 port of
> [flutter_ports](https://github.com/artflutter/flutter_ports). `flutter_d3_port`, the D3
> bundle, re-exports it.

## Use

```dart
import 'package:flutter_d3_color_port/flutter_d3_color_port.dart' as d3;

final steel = d3.Rgb.parse('steelblue'); // rgb(70, 130, 180)
final lighter = d3.Hcl.from(steel).brighter(); // brighter in CIELAB lightness
final css = lighter.formatHex(); // a CSS text
final paint = lighter.toUiColor(); // a Flutter Color
```

The upstream factories overload on their argument count. In Dart, each form has its own
constructor:

| d3-color | Dart |
|---|---|
| `d3.color("steelblue")` | `d3.color('steelblue')`, a `Color?` (null for a text that is not a color) |
| `d3.rgb(70, 130, 180)`, `d3.rgb(70, 130, 180, 0.5)` | `d3.Rgb(70, 130, 180)`, `d3.Rgb(70, 130, 180, 0.5)` |
| `d3.rgb("steelblue")` | `d3.Rgb.parse('steelblue')` |
| `d3.rgb(color)` | `d3.Rgb.from(color)` |
| `d3.hsl(…)`, `d3.lab(…)`, `d3.hcl(…)`, `d3.cubehelix(…)` | `d3.Hsl`, `d3.Lab`, `d3.Hcl`, `d3.Cubehelix`, with the same three forms |
| `d3.lch(l, c, h)`, `d3.gray(l)` | `d3.lch(l, c, h)`, `d3.gray(l)` |
| `color.copy({opacity: 0.5})` | `color.copy(opacity: 0.5)` |
| `color + ""` | `color.toString()` |

A channel is a mutable `double` field, as upstream: an interpolator can write it and print the
color again. NaN is an undefined channel, as upstream. A string channel such as `rgb("12", …)` does
not compile. `package:flutter_d3_color_port/d3_color.dart` is the same API with no Flutter import,
for code that runs without the Flutter engine.

## Upstream

The port tracks d3-color **3.1.0** (`d3ColorVersion`). The git submodule `third_party/d3-color`
of the repository pins the tag `v3.1.0`. Each file of `lib/src/` ports the file of `src/` with
the same name. The 8 upstream test files are in `test/`. The differences from upstream are in
[doc/differences.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_color_port/doc/differences.md),
and the speed figures against upstream in Node.js are in
[doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_color_port/doc/performance.md).
The decisions are D3 ADRs 0007 to 0010 of `packages/flutter_d3_port/doc/adr/`.

## License

ISC, the license of d3-color. [LICENSE](LICENSE) keeps the notice of Mike Bostock. This project is
not affiliated with the D3 project.
