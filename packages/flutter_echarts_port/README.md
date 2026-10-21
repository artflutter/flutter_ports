# flutter_echarts_port

A native Dart port of [Apache ECharts](https://echarts.apache.org) for Flutter. The port
translates the ECharts modules and its renderer [zrender](https://github.com/ecomfe/zrender) to
Dart: the option model, the data store, the coordinate systems, the series, the components and the
layouts. Flutter draws the charts with its own canvas. The package uses no WebView, no JavaScript
and no network access at runtime. The goal is one code base for every Flutter platform, also for
web builds that compile to WebAssembly.

> **Status:** phase 0, scaffold and design. The package has no ported code. It is not published.
> The plan, the roadmap and the decisions are in
> [doc/README.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_echarts_port/doc/README.md).

This package is not [`flutter_echarts`](https://pub.dev/packages/flutter_echarts). That package
runs the JavaScript ECharts in a WebView. For the ECharts packages that exist now and how they
work, see the
[prior-art survey](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_echarts_port/doc/prior-art/README.md).

## Upstream

The port tracks Apache ECharts **6.1.0** (`echartsVersion`) and zrender **6.1.0**
(`zrenderVersion`), the zrender version that the ECharts 6.1.0 `package.json` requires. Git
submodules under `third_party/` pin both repositories at their release tags.
[tool/port_sources.yaml](tool/port_sources.yaml) lists the pins with their licenses and holders.

## License

Apache-2.0, the license of Apache ECharts. [LICENSE](LICENSE) has the license text. [NOTICE](NOTICE)
keeps the notice of Apache ECharts. zrender is BSD-3-Clause (Baidu Inc.). Five ECharts files embed
d3 code under BSD-3-Clause: the four files of the ECharts `LICENSE` and `src/scale/Time.ts`.
zrender holds code of node-timsort (MIT), jsdiff (BSD-3-Clause) and tween.js (MIT). One zrender
file holds Apache ECharts code (Apache-2.0).
[ECharts ADR 0001](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_echarts_port/doc/adr/0001-upstream-sources.md)
item 12 lists these license components. Each notice goes into [LICENSE](LICENSE) and
[REUSE.toml](https://github.com/artflutter/flutter_ports/blob/main/REUSE.toml) when the port of
its code starts. This project is not affiliated with the Apache Software Foundation, the Apache
ECharts project or Baidu. Apache ECharts and ECharts are trademarks of the Apache Software
Foundation.
