# Other JavaScript chart libraries in Dart/Flutter

This page extends the [Chart.js prior-art survey](../../packages/flutter_chartjs/doc/prior-art/README.md)
to other libraries.

This page lists what exists in Dart and Flutter for JavaScript chart libraries other than Chart.js, as background for future ports in this repository. It draws on 35 pub.dev search queries, per-package lookups and GitHub search; each package in the tables was classified from its source code. Versions, dates and status are as of 2026-10-16.

Approaches: **WebView** (the JS library runs in a platform WebView), **HTML view** (on Flutter web, an `HtmlElementView` hosts a DOM element, such as a `<div>` or `<iframe>`, running it), **JS interop** (Dart bindings call the JS library loaded by the page) and **native port** (logic reimplemented in Dart; no JS runs).

## Packages by library family

### ECharts

| Package | Approach | Status |
|---|---|---|
| `flutter_echarts` | WebView (Android, iOS, macOS); ECharts 5.4.3 | Archived 2025-08-11; README recommends `graphic` |
| `fl_echarts` | WebView (Android, iOS, macOS, Windows), HTML view on web; ECharts 6.0.0 | Low activity; 0.3.0, 2026-03-19 |
| `echarts_flutter_plus` | JS interop with HTML view, web only; ECharts 5.5.0 | Low activity; 0.0.8, 2025-12-24 |
| `graphify` | WebView (Android, iOS, macOS), HTML view on web; ECharts 5.5.0 | Archived; 1.2.1, 2025-09-03 |
| `universal_echarts` | `flutter_echarts` on mobile, HTML view on web | Abandoned; 1.0.0+4, 2021-03-30 |

No native ECharts or zrender port was found. `flutter_echart` is a native pie chart that only borrows the name.

### Highcharts

| Package | Approach | Status |
|---|---|---|
| `high_chart` | WebView (Android, iOS, macOS, Windows), HTML view on web; generated typed options | Active; 2.8.1, 2026-08-02 |
| `highcharts_flutter` (official) | WebView (Android, iOS), HTML view on web; Highcharts 13.1.1; typed options | Active; 1.3.0, 2026-09-21 |
| `rikulo_highcharts` | JS interop, plain Dart web | Maintained occasionally; 4.0.0+12, 2025-08-06 |
| `highchartjs` | WebView (Android, iOS), HTML view on web | Stale; 0.0.3, 2024-11-27 |
| `highcharts`, `highcharts4dart`, `highcharts_options` | JS interop or option classes, Dart 1 web | Legacy; last released 2014-2016 |

Highcharts JS is commercial. The search found no native port: only wrappers, typings and two GitHub-only generators (`built_highcharts`, `highcharts_api_gen`).

### ApexCharts

| Package | Approach | Status |
|---|---|---|
| `apexcharts_flutter` | Native port of ApexCharts.js v4.7.0; MIT | Active, early; 0.1.2, 2026-06-04 |
| `dart_apex_charts` | JS interop, Dart 2 web; ApexCharts 3.15.3 | Abandoned; 0.2.7, 2020-01-28 |

Two more wrappers turned up: `apex_dart` (discontinued) and `chart_engine` (bundles ApexCharts 3.26.0 and Chart.js 2.9.4).

### Plotly

| Package | Approach | Status |
|---|---|---|
| `plotly_js` | JS interop, web; plotly.js 1.44.3 | Abandoned; 0.0.2, 2019-09-16 |
| `plotly` | JS interop, Dart 1 web; plotly.js 1.26.1 | Legacy; 0.7.3, 2017-04-25 |

No native port was found; `grizzly_plotly`, `thumbert/plotly_dart` and `flutter_web_plotly` also use JS interop or JSON specs.

### Vega

| Package | Approach | Status |
|---|---|---|
| `vega_embed_flutter` | JS interop with HTML view on web, WebView on Android and iOS; Vega 5 from a CDN | Abandoned, pre-null-safety; 0.6.3, 2020-08-27 |

### Dygraphs

| Package | Approach | Status |
|---|---|---|
| `dygraph` | JS interop, plain Dart web | Stale; 1.0.0, 2021-10-09 |

### D3 and D3-module ports

| Package | Approach | Status |
|---|---|---|
| `d4`, `d4_*` | Native port of D3 v7 modules; no widget; ISC | Stale since December 2024 |
| `charted` (Google) | Native partial D3 v3 reimplementation plus a chart layer; SVG DOM, web only | Archived; 0.6.1, 2018-07-17 |
| `sankey_flutter` | Native port of d3-sankey | Low activity; 0.0.3, 2025-12-29 |
| `flex_org_chart` | Native port of d3-org-chart and d3-flextree | Active; 0.5.1, 2026-09-04 |
| `d3_force_flutter` (GitHub only) | Native port of d3-force | Archived; last push 2023-12-15 |
| `d3` (rwl) | JS interop over bundled D3 3.5.10, Dart 1 web | Legacy; 0.2.0, 2015-12-15 |

The [D3 prior-art survey](../../packages/flutter_d3_port/doc/prior-art/README.md) of 2026-10-20
examines these packages and more in depth. It found no formal or complete D3 port for Flutter.
[AGENTS.md](../../AGENTS.md) rule 1 forbids a port from `d4` or from any other Dart library. For
the D3 port, `d4` is prior art only: it is neither a source nor a dependency. Thus the `d4_*`
item under [Conclusions for flutter_ports](#conclusions-for-flutter_ports) does not apply to the
D3 port.

### Recharts

| Package | Approach | Status |
|---|---|---|
| `rlch/recharts-flutter` (GitHub only) | Native port; no license file | Experimental; last push 2026-04-14 |
| `shadcn_chart` | WebView with prebuilt React and Recharts bundles | New; 0.1.0, 2026-06-13 |

### Google Charts

| Package | Approach | Status |
|---|---|---|
| `google_charts` | JS interop, Dart 1 web | Legacy; 0.2.1, 2016-05-18 |

Google's `charts_flutter`/`charts_common` and their forks (`community_charts_*`, `nimble_charts`) are independent native libraries, not ports of Google Charts.

### FusionCharts

| Package | Approach | Status |
|---|---|---|
| `flutter_fusioncharts` (official) | WebView (Android, iOS); FusionCharts 4.2.2, commercial | Active; 2.0.0, 2026-09-11 |

### LightningChart

| Package | Approach | Status |
|---|---|---|
| `lightning_chart_flutter` | WebView served by a loopback HTTP server (Android, iOS, macOS), HTML view on web; proprietary | New; 0.0.0, 2026-09-02 |

### graphic

| Package | Approach | Status |
|---|---|---|
| `graphic` | Independent native Dart library (grammar of graphics), not a port; MIT | Active; 2.7.0, 2026-02-25; about 42.7k downloads in 30 days |

### Other search results

Nothing was found in Dart for uPlot, Nivo or billboard.js. From pubspecs and descriptions only: `trading_view_flutter` and `chart_iq` are wrappers, `trading_chart_flutter` is pure Dart with a Lightweight Charts-style API (not a port), and `kroki` renders Vega and other diagrams server-side via kroki.io.

## Native ports that exist

- **`apexcharts_flutter`**: a manual port of ApexCharts.js v4.7.0, the last MIT release: 6,856 Dart lines in 34 files whose doc comments cite upstream files such as `Scales.js`. It draws with `CustomPaint` on all six platforms, runs no JS, covers 13 chart types with partial option support and has one maintainer.
- **`rlch/recharts-flutter`** (GitHub only): about 14.5k Dart lines; widgets mirror Recharts components and Riverpod replaces Recharts' Redux slices. With no license file, the code is not reusable.
- **`d4_*`**: ISC-licensed pure-Dart ports of D3 v7 modules, including a line-for-line port of d3-array's `tickSpec`. They compute scales, shapes and paths; the caller paints them.
- **`charted`**: Google's archived `dart:html` toolkit, about 17.3k lines covering a D3 v3 subset and SVG chart renderers. It is not compatible with Dart 3.
- **D3 layout ports**: `sankey_flutter` (d3-sankey) and `flex_org_chart` (d3-org-chart and d3-flextree) are BSD-3-Clause; the GitHub-only `d3_force_flutter` (d3-force) is MIT.

## Conclusions for flutter_ports

- No package on this page contains Chart.js logic in Dart. The only native ports of a full chart library, rather than building blocks such as the D3 modules, are `apexcharts_flutter` and `recharts-flutter`.
- Every ECharts, Highcharts, Plotly, Vega, Dygraphs, Google Charts, FusionCharts and LightningChart package found wraps the JS library or only models its options. Common limits are missing platforms (no Linux in `flutter_echarts`, `fl_echarts` or `high_chart`; no desktop in `highcharts_flutter`), scripts loaded from CDNs and `eval`-based option injection. A search cannot prove absence: private repositories, non-English descriptions and repositories without matching keywords would be missed.
- `apexcharts_flutter` (MIT) is the best methodology template found for the Chart.js 4.5.1 port: an `AGENTS.md` rule of "transpilation, not reinvention", the pinned upstream source vendored and cited per function, goldens compared with Puppeteer renders of the real library using per-channel thresholds (SVG and Skia anti-alias differently), and a bundled font for deterministic text.
- The `high_chart` repository (not the published package) has `tool/generate_options`, an MIT pure-Dart `.d.ts` parser and emitter that generates typed option classes. The same approach could generate a typed config model from Chart.js 4.5.1's `dist/types/*.d.ts`.
- `d4_*` can serve as a reference or optional dependency for generic helpers (color, interpolation, formatting, time). Chart.js's own algorithms (`LinearScaleBase` tick generation via `generateTicks`/`niceNum`, `splineCurveMonotone`) differ from D3's, so a faithful port should port those.
- Licenses differ: ApexCharts v4.7.0 is its last MIT release; Highcharts, FusionCharts and LightningChart JS are commercial or proprietary; `recharts-flutter` has no license.
