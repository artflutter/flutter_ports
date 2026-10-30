# flutter_ports

Native Dart/Flutter ports of popular JavaScript chart libraries. The upstream logic is
translated to Dart and drawn with Flutter's own canvas, so the charts are ordinary Flutter
widgets. There's no WebView and no JavaScript at runtime, and the same code runs on every
Flutter platform, including web builds compiled to WebAssembly.

Why ports instead of wrappers, and what already exists on pub.dev: [docs/prior-art](packages/flutter_chartjs_port/doc/prior-art/README.md).
For the D3 packages, see the [D3 prior-art survey](packages/flutter_d3_port/doc/prior-art/README.md).
For the ECharts packages, see the [ECharts prior-art survey](packages/flutter_echarts_port/doc/prior-art/README.md).

> **Status:** The Chart.js port has the eight chart types, the six scales and the seven plugins of
> Chart.js v4.6.1, with the Flutter widget `ChartView`, a theme API, keyboard and semantics
> support, and reduced motion. Nothing is published to pub.dev yet.
> The D3 port is in phase 0: the package, the 34 pinned submodules and the design. It has no
> ported code.
> The ECharts port is in phase 0: the package, the two pinned submodules (Apache ECharts and
> zrender) and the design. It has no ported code.

## Ports

| Port | Upstream | Package | Progress |
|---|---|---|---|
| Chart.js | [chartjs/Chart.js](https://github.com/chartjs/Chart.js) v4.6.1 (MIT) | [`flutter_chartjs_port`](packages/flutter_chartjs_port) | [parity tracker](packages/flutter_chartjs_port/doc/parity.md) |
| D3 | [d3/d3](https://github.com/d3/d3) v7.9.0 with its 30 modules, internmap, delaunator and robust-predicates (ISC, with d3-ease BSD-3-Clause and robust-predicates Unlicense) | [`flutter_d3_port`](packages/flutter_d3_port) | [parity tracker](packages/flutter_d3_port/doc/parity.md) |
| Apache ECharts | [apache/echarts](https://github.com/apache/echarts) 6.1.0 (Apache-2.0) with its renderer [ecomfe/zrender](https://github.com/ecomfe/zrender) 6.1.0 (BSD-3-Clause) | [`flutter_echarts_port`](packages/flutter_echarts_port) | [parity tracker](packages/flutter_echarts_port/doc/parity.md) |

## Layout

```
packages/flutter_chartjs_port   the Chart.js port (library)
packages/flutter_d3_port   the D3 port (library, phase 0: no ported code yet)
packages/flutter_echarts_port
                           the Apache ECharts port (library, phase 0: no ported code yet)
apps/chartjs_gallery       gallery and visual test bed (Android, iOS, web, macOS)
third_party/Chart.js       pinned upstream source, git submodule (reference only, not shipped)
third_party/d3, d3-*, ...  pinned D3 sources: d3, the 30 d3-* modules, internmap, delaunator and
                           robust-predicates, 34 git submodules (reference only, not shipped)
third_party/echarts, zrender
                           pinned Apache ECharts and zrender sources, 2 git submodules
                           (reference only, not shipped)
docs/                      prior art, ADRs, per-port roadmap and parity tracker
```

## Getting started

Requires Flutter 3.47.7 with Dart 3.13.5 (`.fvmrc`).

```sh
git clone https://github.com/artflutter/flutter_ports.git
cd flutter_ports
flutter pub get               # resolves the whole pub workspace
dart run melos run upstream   # optional: check out the pinned Chart.js, D3 and ECharts sources
dart run melos run analyze
dart run melos run test --no-select
dart run melos run gallery          # Chrome
dart run melos run gallery:device   # Android/iOS device, emulator or simulator
```

`melos` is a dev dependency, so `dart run melos …` works without a global install. With a
global `melos` 8.x, plain `melos …` works too.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [AGENTS.md](AGENTS.md).

## License

MIT. Ported code also carries the upstream project's notice: see
[packages/flutter_chartjs_port/LICENSE](packages/flutter_chartjs_port/LICENSE) and [REUSE.toml](REUSE.toml).
This project is not affiliated with or endorsed by the Chart.js project.

The D3 port is ISC, the license of D3. Its
[packages/flutter_d3_port/LICENSE](packages/flutter_d3_port/LICENSE) keeps the D3 notice of Mike
Bostock. This project is also not affiliated with or endorsed by the D3 project.

The ECharts port is Apache-2.0, the license of Apache ECharts. Its
[packages/flutter_echarts_port/LICENSE](packages/flutter_echarts_port/LICENSE) has the license
text, and its [NOTICE](packages/flutter_echarts_port/NOTICE) keeps the notice of Apache ECharts.
zrender is BSD-3-Clause (Baidu Inc.). This project is also not affiliated with or endorsed by the
Apache Software Foundation, the Apache ECharts project or Baidu. Apache ECharts and ECharts are
trademarks of the Apache Software Foundation.
