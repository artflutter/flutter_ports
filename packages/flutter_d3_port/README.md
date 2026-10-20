# flutter_d3_port

A native Dart port of [D3](https://d3js.org) for Flutter. The port translates the D3 modules to
Dart: arrays, scales, shapes, paths, colors, time, geography, layouts and more. Flutter draws the
results with its own canvas. The package uses no WebView, no JavaScript and no network access at
runtime. The goal is one code base for every Flutter platform, also for web builds that compile to
WebAssembly.

> **Status:** phase 0, scaffold and design. The package has no ported code. It is not published.
> The plan, the roadmap and the decisions are in
> [doc/README.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_port/doc/README.md).

This package is not [`d3`](https://pub.dev/packages/d3). That package wraps the JavaScript D3 3.5.10
for Dart 1 web apps. This package is also not the [`d4`](https://pub.dev/packages/d4) family of
packages. For the D3 packages that exist now and how they work, see the
[prior-art survey](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_port/doc/prior-art/README.md).

## Upstream

The port tracks D3 **7.9.0** (`d3Version`). Git submodules under `third_party/` pin the d3 bundle
and 33 other repositories: the 30 D3 modules, internmap, delaunator and robust-predicates. Each of
these repositories is at the newest release tag in the ranges of the d3 7.9.0 `package.json`.
[tool/port_sources.yaml](tool/port_sources.yaml) lists the 34 pins with their licenses and holders.

## License

ISC, the license of D3. [LICENSE](LICENSE) keeps the D3 notice of Mike Bostock. Some D3 modules
use other licenses or name other holders. Their notices go into [LICENSE](LICENSE) and
[REUSE.toml](https://github.com/artflutter/flutter_ports/blob/main/REUSE.toml) when the port of
their code starts. This project is not affiliated with the D3 project.
