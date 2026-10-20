# flutter_ports

Native Dart/Flutter ports of popular JavaScript chart libraries. The upstream logic is
translated to Dart and drawn with Flutter's own canvas, so the charts are ordinary Flutter
widgets. There's no WebView and no JavaScript at runtime, and the same code runs on every
Flutter platform, including web builds compiled to WebAssembly.

Why ports instead of wrappers, and what already exists on pub.dev: [docs/prior-art](packages/flutter_chartjs/doc/prior-art/README.md).
For the D3 packages, see the [D3 prior-art survey](packages/flutter_d3_port/doc/prior-art/README.md).

> **Status:** early. The Chart.js port is scaffolded and nothing renders yet. Nothing is
> published to pub.dev yet.
> The D3 port is in phase 0: the package, the 34 pinned submodules and the design. It has no
> ported code.

## Ports

| Port | Upstream | Package | Progress |
|---|---|---|---|
| Chart.js | [chartjs/Chart.js](https://github.com/chartjs/Chart.js) v4.5.1 (MIT) | [`flutter_chartjs`](packages/flutter_chartjs) | [parity tracker](packages/flutter_chartjs/doc/parity.md) |
| D3 | [d3/d3](https://github.com/d3/d3) v7.9.0 with its 30 modules, internmap, delaunator and robust-predicates (ISC, with d3-ease BSD-3-Clause and robust-predicates Unlicense) | [`flutter_d3_port`](packages/flutter_d3_port) | [parity tracker](packages/flutter_d3_port/doc/parity.md) |

## Layout

```
packages/flutter_chartjs   the Chart.js port (library)
packages/flutter_d3_port   the D3 port (library, phase 0: no ported code yet)
apps/chartjs_gallery       gallery and visual test bed (Android, iOS, web, macOS)
third_party/Chart.js       pinned upstream source, git submodule (reference only, not shipped)
third_party/d3, d3-*, ...  pinned D3 sources: d3, the 30 d3-* modules, internmap, delaunator and
                           robust-predicates, 34 git submodules (reference only, not shipped)
docs/                      prior art, ADRs, per-port roadmap and parity tracker
```

## Getting started

Requires Flutter 3.44.9 (`.fvmrc`).

```sh
git clone https://github.com/artflutter/flutter_ports.git
cd flutter_ports
flutter pub get               # resolves the whole pub workspace
dart run melos run upstream   # optional: check out the pinned Chart.js and D3 sources
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
[packages/flutter_chartjs/LICENSE](packages/flutter_chartjs/LICENSE) and [REUSE.toml](REUSE.toml).
This project is not affiliated with or endorsed by the Chart.js project.

The D3 port is ISC, the license of D3. Its
[packages/flutter_d3_port/LICENSE](packages/flutter_d3_port/LICENSE) keeps the D3 notice of Mike
Bostock. This project is also not affiliated with or endorsed by the D3 project.
