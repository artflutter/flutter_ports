# Prior art: sankey diagrams for Chart.js in Dart and Flutter

Survey date: **2026-11-13**. Numbers that change over time (versions, dates, downloads, likes,
stars) are as of that date.

**Question.** Does a Dart or Flutter port of
[chartjs-chart-sankey](https://github.com/kurkle/chartjs-chart-sankey) exist? Which Dart and
Flutter packages draw a sankey diagram? Is each one native Dart code or a wrapper of a JavaScript
library? Where does each layout algorithm come from?

**Answer.** No Dart or Flutter port of chartjs-chart-sankey exists outside this package.

- GitHub code search gave no Dart file with the string `chartjs-chart-sankey`. It gave no Dart
  file with the upstream names `calculateYUsingPriority`, `nodePaddingMode`, `buildNodesFromData`
  or `getAllKeysForward`.
- The seven Chart.js wrappers on pub.dev do not load the module. Their archives have no string
  `sankey`.
- Two pub.dev packages draw only sankey diagrams. [`sankey_flutter`](#sankey_flutter) is a
  transcription of d3-sankey. [`sankey_diagram_flutter`](#sankey_diagram_flutter) has its own
  layout.
- Six multi-chart libraries on pub.dev have a native sankey chart with their own layout:
  `chartify`, `flutter_charts_kit`, `drafter`, `flutter_naveen_charts`, `ohlcv_chart` and `tenun`.
- [`fluent_2`](#fluent_2) and [`mermaid_core`](#mermaid) have line-cited or faithful ports of
  d3-sankey inside a larger port.
- No Dart layout follows chartjs-chart-sankey. Each native layout is a d3-sankey port, or a
  longest-path column layout with or without a relaxation.
- `fl_chart`, `graphic`, `syncfusion_flutter_charts`, `cristalyse` and the `d4` family draw no
  sankey. The old Google charts and their forks have a sankey renderer with no code in it.
- The wrappers show the sankey of ECharts, Highcharts, Plotly or Google Charts in JavaScript.
- Outside Dart, two projects port the layout of chartjs-chart-sankey:
  [`fulgur-chart`](#fulgur) (Rust) and [`sankey_mpl`](#sankey_mpl) (Python). Charba (Java) wraps
  the JavaScript module.

## At a glance

### chartjs-chart-sankey outside JavaScript

| Project | Language | Kind | Upstream version | License | State (2026-11-13) |
|---|---|---|---|---|---|
| `flutter_chartjs_chart_sankey_port` (this package) | Dart | native port, an add-on of `flutter_chartjs_port` | v0.19.1 | MIT | in progress |
| [`fulgur-rs/fulgur-chart`](#fulgur) | Rust | port of `lib/core.ts` and `lib/layout.ts` in a static renderer of Chart.js specs | not named. An older version by its code | MIT OR Apache-2.0 | crate 0.13.2, 2026-09-18 |
| [`nrrb/sankey_mpl`](#sankey_mpl) | Python | port of the layout for matplotlib, written from a specification | 0.15.0 | MIT. `NOTICE` keeps the upstream notice | PyPI 0.2.0, 2026-08-13 |
| [Charba](#charba) | Java (GWT, J2CL) | wrapper. It injects the JavaScript module | v0.12.0, bundled | Apache-2.0 | release 6.5, 2024-02-10 |

### Dedicated sankey packages in Dart

| Package | Kind | Layout origin | Draws with | License | Latest |
|---|---|---|---|---|---|
| [`sankey_flutter`](#sankey_flutter) (pub.dev) | native | transcription of d3-sankey | `CustomPaint`, gradient links | BSD-3-Clause. The d3-sankey text with another name | 0.0.3, 2025-12-29 |
| [`sankey_diagram_flutter`](#sankey_diagram_flutter) (pub.dev) | native | own. Manual columns, or longest path and a relaxation | `CustomPaint`, gradient links, arcs for circular links | MIT | 1.1.0, 2026-06-21 |
| [`dayat123123/flutter-sankey-diagram`](#github-dart) (GitHub) | native | own. Two columns only | `CustomPainter` | none. `LICENSE` is a template line | `main`, 2026-05-30 |

### A sankey chart inside a Dart chart library

| Package | Kind | Layout origin | License | Latest |
|---|---|---|---|---|
| [`fluent_2`](#fluent_2) | native port | d3-sankey, cited by line. The chart ports `SankeyChart.tsx` of `@fluentui/react-charts` | MIT. No d3-sankey notice | 0.0.7, 2026-09-25 |
| [`mermaid_core`, `mermaid_flutter`](#mermaid) | native port of mermaid.js | "a faithful port of d3-sankey" | MIT | 0.3.2, 2026-10-19 |
| [`pele_dart`](#mermaid) | native port of `obsidianmd/pele` | the `layout.ts` of pele: longest path, then a settle step | MIT | 1.13.0+1, 2026-11-06 |
| [`flutter_charts_kit`](#multi) | native | own. Longest path, 6 relaxation passes | MIT. The holder line is a template | 0.1.0, 2026-11-01 |
| [`ohlcv_chart`](#multi) | native | own. Longest path, no vertical relaxation | MIT | 3.2.0, 2026-10-15 |
| [`chartify`](#multi) | native | own. Recursive depth, no relaxation | Apache-2.0 | 1.0.2, 2026-02-16 |
| [`flutter_naveen_charts`](#multi) | native | own. Longest path, no relaxation | Apache-2.0 | 1.0.4, 2026-11-02 |
| [`tenun`](#multi) | native | own. Columns from the node or from a breadth-first search | Apache-2.0. `tenun_pro` is proprietary | 0.1.3, 2026-07-29 |
| [`drafter`](#multi) | native | none. The app gives the column of each node | Apache-2.0 | 0.3.0, 2026-06-28 |
| [`e_chart_ext`](#multi) | native port | d3-sankey (`master`, cited) | Apache-2.0. No d3-sankey notice | 0.0.1, 2023-05-10. Dart 2 only |
| [`community_charts_common`](#google-charts) and 4 relatives | native, not complete | none. The renderer has three `TODO` lines | Apache-2.0 | 1.0.4, 2024-05-15 |

### Wrappers that can show a sankey

| Package | JavaScript library | How | License | Latest |
|---|---|---|---|---|
| `flutter_echarts` | ECharts, bundled | WebView | BSD-2-Clause (ECharts survey). pub.dev shows unknown | 2.5.0, 2023-08-31 |
| `graphify` | ECharts, bundled | WebView and the web | MIT | 1.2.1, 2025-09-03 |
| `fl_echarts` | ECharts, bundled asset | WebView | MIT | 0.3.0, 2026-03-19 |
| `universal_echarts` | ECharts, bundled | WebView, and an iframe on the web | MIT | 1.0.0+4, 2021-03-30 |
| `highcharts_flutter` | Highcharts | WebView. A typed sankey series class | Highsoft integration license | 1.3.0, 2026-09-21 |
| `high_chart` | Highcharts | WebView. The option docs name sankey | MIT | 2.8.1, 2026-08-02 |
| `plotly_js` | Plotly, bundled | JS file for a web page | MIT | 0.0.2, 2019-09-16 |
| `google_charts` (unlisted) | Google Charts | `dart:js`. A `SankeyDiagram` class | BSD-3-Clause | 0.2.1, 2016-05-18 |

## chartjs-chart-sankey in Dart

The survey found none.

- `"chartjs-chart-sankey" language:Dart` gave 0 hits in GitHub code search. The same query with
  `extension:dart` gave 0 hits. `chartjs-chart-sankey filename:pubspec.yaml` gave 0 hits.
- `calculateYUsingPriority`, `nodePaddingMode`, `buildNodesFromData` and `getAllKeysForward` gave 0
  Dart hits. `returnsToNearerColumn` gave two hits in all languages. Both are upstream files.
- `sankey chartjs language:Dart` and `sankey "chart.js" language:Dart` gave 0 hits.
- The control query `SankeyDiagramWidget language:Dart` gave 10 hits. Thus the index has Dart
  sankey code.
- The archives of `chartjs_flutter` 1.0.0, `js_widget` 1.0.4, `ensemble` 1.3.2, `chart_engine`
  3.0.2, `flutter_web_chartjs` 0.2.5, `chartjs` 0.6.0 and `chartjs2` 2.0.0 have no string
  `sankey`. The [Chart.js survey](../../../flutter_chartjs_port/doc/prior-art/README.md) describes
  these wrappers.
- The pub.dev name list has two names with `sankey`: `sankey_flutter` and
  `sankey_diagram_flutter`. It has no name `d3_sankey` and no name `d4_sankey`.

## Dedicated sankey packages in Dart

<a id="sankey_flutter"></a>

### `sankey_flutter`: a transcription of d3-sankey

| | |
|---|---|
| Where | [pub.dev/packages/sankey_flutter](https://pub.dev/packages/sankey_flutter), [GitHub](https://github.com/Jason-Gregoire/sankey_flutter) |
| Examined | The archive of 0.0.3 (2025-12-29). GitHub `main` is at `fb71ea49f12a` of the same date |
| Adoption | 9 likes, 3,331 downloads in 30 days, 9 stars, 8 forks |
| Kind | Native Dart. The package depends only on Flutter. It has no WebView and no JS interop |
| License | BSD-3-Clause. `LICENSE:1` is "Copyright 2015, Jason Gregoire". The d3-sankey 0.12.3 `LICENSE:1` is "Copyright 2015, Mike Bostock" |
| More | The [D3 survey](../../../flutter_d3_port/doc/prior-art/d3-packages.md#pkg-sankey_flutter) lists five differences from d3-sankey 0.12.3 |

**How it works.**

1. `lib/sankey.dart` (526 lines) has the d3-sankey steps under the d3-sankey names:
   `_computeNodeLinks` (`:126`), `_computeNodeValues` (`:155`), `_computeNodeDepths` (`:174`),
   `_computeNodeHeights` (`:202`), `_computeNodeBreadths` (`:298`), `_relaxLeftToRight` (`:338`),
   `_relaxRightToLeft` (`:368`), `_resolveCollisions` (`:399`) and `_reorderNodeLinks` (`:445`).
2. The README says that the package "adapts the proven d3-sankey layout algorithm into Dart"
   (`README.md:6`). No file names the d3-sankey version.
3. `SankeyDiagramWidget` is a `GestureDetector` around a `CustomPaint`
   (`lib/sankey_helpers.dart:205-210`).
4. Each link is one `Path` with a `cubicTo` through the x midpoint
   (`lib/interactive_sankey_painter.dart:69`). A `LinearGradient` goes from the source color to
   the target color (`:56`).
5. Nodes are `drawRect` calls (`:94`). Labels are `TextPainter`s (`:126`).
6. `test/sankey_test.dart` has one layout test on the d3-sankey `energy.json` (`:83`). The D3
   survey shows that the expected files come from the port, not from d3-sankey.

<a id="sankey_diagram_flutter"></a>

### `sankey_diagram_flutter`: its own layout with two modes

| | |
|---|---|
| Where | [pub.dev/packages/sankey_diagram_flutter](https://pub.dev/packages/sankey_diagram_flutter), [GitHub](https://github.com/fanolans/sankey_diagram_flutter) |
| Examined | The archive of 1.1.0 (2026-06-21). GitHub `main` is at `606a5431eaac` of the same date |
| Adoption | 2 likes, 48 downloads in 30 days, 2 stars. Three versions, all of 2026-06-21 |
| Kind | Native Dart. The package depends only on Flutter |
| License | MIT, "Copyright (c) 2026 Farrel Nolan" (`LICENSE:3`) |

**How it works.**

1. `SankeyLayout.compute` (`lib/src/layout/sankey_layout.dart:40`, 532 lines) has two modes.
2. The default mode reads the column from `SankeyNode.column` or `SankeyNode.type`
   (`_assignColumnsManual`, `:146`). `autoLayout` is false by default
   (`lib/src/models/sankey_style.dart:125`).
3. With `autoLayout`, `_assignColumnsAuto` (`:168`) gives each node its longest-path depth.
   `_detectBackEdges` (`:281`) finds the links of a cycle. A relaxation moves the nodes
   (`:122`), with 6 iterations by default.
4. A comment says "matching d3-sankey behaviour" (`:34`). The function names and the code are not
   those of d3-sankey. The code is the work of the author.
5. `SankeyDiagram` wraps a `CustomPaint` in a `GestureDetector` and a `MouseRegion`
   (`lib/src/widgets/sankey_diagram.dart:362-374`). It has a tooltip, a legend and a controller.
6. A ribbon is a closed `Path` with two `cubicTo` calls
   (`lib/src/painter/bezier_helper.dart:25-27`). A circular link is an arc above the nodes
   (`:74-76`). The link paint is a linear gradient
   (`lib/src/painter/sankey_painter.dart:186`). Nodes are `drawRRect` calls (`:200`).
7. `test/layout/sankey_layout_test.dart` has 12 tests. No test compares with another library.

<a id="github-dart"></a>

### GitHub only

Each row is a repository with no pub.dev package. The survey read the named files through the
GitHub contents API.

| Repository | Kind | Layout origin | License | Last push |
|---|---|---|---|---|
| [`dayat123123/flutter-sankey-diagram`](https://github.com/dayat123123/flutter-sankey-diagram) | native package (`flutter_sankey_diagram` 0.0.1) | own. Source nodes with targets, and destination nodes (`lib/src/sankey_models.dart:49`, `:88`) | none. `LICENSE` is "TODO: Add your license here." | 2026-05-30 |
| [`rlch/recharts-flutter`](https://github.com/rlch/recharts-flutter) | native library, "ported from Recharts" (`README.md:3`), `publish_to: 'none'` | the Recharts sankey: 32 relaxation iterations (`lib/src/sankey/sankey_layout.dart:14`, `:211`, `:239`) | none | 2026-04-14 |
| [`mralifakbar/kumo_flutter`](https://github.com/mralifakbar/kumo_flutter) | native UI kit with `KumoSankeyChart` | "the d3/ECharts Sankey algorithm", 32 relaxation passes (`lib/src/charts/kumo_sankey_chart.dart:155-157`) | MIT | 2026-11-03 |
| [`stey-jp/stey-ui`](https://github.com/stey-jp/stey-ui) | native UI kit with `SteySankeyChart` | own. Depth columns with even spacing (`packages/stey_ui_modern/lib/src/chart.dart:417`) | MIT | 2026-10-22 |
| [`mozufu/pirc`](https://github.com/mozufu/pirc) (app) | native | "adapted from d3-sankey 0.12.3. Copyright 2015 Mike Bostock" (`apps/android/lib/rendering/mermaid/d3_sankey_layout.dart:2-3`) | **AGPL-3.0** | 2026-11-03 |
| [`dan63047/TetraStats`](https://github.com/dan63047/TetraStats) (app) | native | a copy of `sankey_flutter` (`lib/widgets/sankey_graph.dart:4`) | **GPL-3.0** | 2026-11-04 |
| [`Golden-Bit/financial_UI`](https://github.com/Golden-Bit/financial_UI) | wrapper, web only | ECharts 5 from jsDelivr through `dart:html` (`lib/other_elements/sankey_chart/sankey_chart.dart:1`, `:63`) | MIT | 2025-05-16 |
| [`FabricElements/fabric_flutter`](https://github.com/FabricElements/fabric_flutter) | wrapper options | Google Charts. `ChartType.Sankey` (`lib/serialized/chart_wrapper.dart:73`) | BSD-3-Clause | 2026-11-12 |

- The D3 survey names the pirc repository `iceice666/pirc`. That name now gives `mozufu/pirc`.
- `suyu610/journal-flutter` (MIT, 230 stars) is a user of `sankey_flutter`
  (`lib/pages/lab/sankey/view.dart:5-7`).
- The survey read only the first lines of the pirc file, of the TetraStats file and of
  `softradix/sankiy-graphs`. The last one shows a platform view with the title "Highcharts Sankey
  Diagram". It has no license.

## A sankey chart inside a Dart chart library

<a id="fluent_2"></a>

### `fluent_2`: a line-cited d3-sankey port under a port of the Fluent chart

| | |
|---|---|
| Where | [pub.dev/packages/fluent_2](https://pub.dev/packages/fluent_2), [GitHub](https://github.com/B1Digital/fluent_ui_2_flutter) |
| Examined | The archive of 0.0.7 (2026-09-25) |
| Adoption | 4 likes, 95 downloads in 30 days, 4 stars |
| License | MIT, "Copyright (c) 2026 ICITECH Teknoloji A.Ş." (`LICENSE:3`). `LICENSE` has no d3-sankey notice |
| More | The [D3 survey](../../../flutter_d3_port/doc/prior-art/d3-packages.md#pkg-fluent_2) describes the D3 part and gives the version d3-sankey 0.12.3 |

**How it works.**

- `lib/src/charts/internal/d3/sankey.dart` (626 lines) cites d3-sankey by file and line. Examples
  are "`d3-sankey/src/sankey.js:54-369`" (`:105`) and "`d3-sankey/src/align.js:15-17`" (`:97`).
- The defaults are those of d3-sankey: node width 24, padding 8, 6 iterations (`:134-141`).
- `stable_sort.dart` gives a stable sort for the d3-sankey comparators (D3 survey).
- `lib/src/charts/sankey_chart.dart` ports the React component. Its comments cite
  `SankeyChart.tsx` by line (`:29`, `:46`, `:85`). `FluentSankeyChartPainter` is a
  `CustomPainter` (`:373`).
- This is the nearest Dart example of the method of this port: a line-cited port of a JavaScript
  sankey chart. Its upstream is not Chart.js.

<a id="mermaid"></a>

### The mermaid ports: `mermaid_core`, `pele_dart`, `duskmoon_mermaid_renderer`

- **`mermaid_core` 0.3.2 and `mermaid_flutter` 0.3.2** (2026-10-19, MIT, "Copyright (c) 2026 Dominik
  Roszkowski"). `mermaid_core` has 18,333 downloads in 30 days. pub.dev shows `license:unknown`
  for it. `lib/src/diagrams/sankey/sankey.dart` (1,045 lines) says: "Layout is a faithful port of
  d3-sankey" (`:5-6`). The input is the mermaid `sankey` text (CSV lines). `mermaid_flutter`
  paints the scene with a `CustomPainter` (`lib/src/scene_painter.dart:13`).
- **`pele_dart` 1.13.0+1** (2026-11-06, MIT, "Copyright (c) 2026 Tony Kinnis" and "kepano
  (obsidianmd/pele)"). `lib/src/diagrams/sankey/layout.dart` (427 lines) names its source:
  "Upstream: src/diagrams/sankey/layout.ts" (`:1`). The layout places nodes by their longest
  distance from a source (`:147`). Then each column settles next to its neighbors (`:124-125`).
  The output is SVG.
- **`duskmoon_mermaid_renderer` 2.2.11** (2026-11-11, MIT). `buildSankeyDiagramScene`
  (`lib/src/scene/structured_diagram_scene.dart:93`) puts boxes of 112 x 40 in depth columns
  (`:134`). The box size does not follow the flow value.

<a id="multi"></a>

### Chart libraries with their own sankey layout

Each package is native Dart on a `CustomPainter`. The survey read the sankey file of each archive.

- **`flutter_charts_kit` 0.1.0** (2026-11-01, MIT, 847 downloads in 30 days). `LICENSE:3` keeps the
  template "[YOUR NAME OR ORGANIZATION]". `SankeyChart2D`
  (`lib/src/chart2d/sankey_chart.dart`, 426 lines) puts nodes "in columns by their longest path
  from a source, with end nodes pushed to the last column" (`:61-62`). It ignores the links of a
  cycle (`:62-63`). Six relaxation passes move each node toward its neighbors (`:257-275`).
  Ribbons use `cubicTo` (`:150-152`).
- **`ohlcv_chart` 3.2.0** (2026-10-15, MIT, "Copyright (c) 2026 Mohammad Zarif", 236 downloads).
  `lib/src/sankey/sankey_chart.dart` (836 lines) puts each node one column right of its furthest
  source (`:195-201`). It drops a link of a cycle (`:230-231`). The tallest column gives the
  scale (`:260`). It has no vertical relaxation. A `MouseRegion` and a `GestureDetector` wrap the
  `CustomPaint` (`:600-612`). `test/sankey_test.dart` has 181 lines.
- **`chartify` 1.0.2** (2026-02-16, Apache-2.0, "Copyright 2025 Sitharaj Seenivasan", 108
  downloads). `lib/src/charts/specialty/sankey/sankey_chart.dart` (740 lines) computes the depth
  of each node by recursion (`:436-447`). The height of a node is its share of the column flow
  (`:507-516`). It has no relaxation. Ribbons use `cubicTo` (`:632`, `:641`).
- **`flutter_naveen_charts` 1.0.4** (2026-11-02, Apache-2.0, "Copyright 2026 Naveen", 1,064
  downloads). `lib/src/sankey_chart.dart` (228 lines): "Columns are inferred from the links
  (longest path)" (`:22`). A loop raises the depth of each target (`:86-97`). It has no
  relaxation. The widget is a `StatelessWidget` with no hit test.
- **`tenun` 0.1.3** (2026-07-29, Apache-2.0, "Copyright 2026 Bhangun", 27 downloads).
  `lib/charts/sankey/sankey.dart` (615 lines) takes the column of a node from the config, or from
  a breadth-first search from the sources (`:130-136`). A second widget is in
  `simple_sankey_chart.dart` (1,192 lines). `lib/charts/alluvial/` has an alluvial chart.
  `tenun_pro` 0.1.2+2 has copies of the sankey files under a "Proprietary Commercial License".
- **`drafter` 0.3.0** (2026-06-28, Apache-2.0, 17 likes, 6,145 downloads).
  `lib/src/charts/sankey_chart.dart` (516 lines) has no column algorithm. `SankeyNode.column` is a
  required parameter (`:34-51`). The file header names "androidpoet (Ranbir Singh)".
- **`e_chart_ext` 0.0.1** (2023-05-10, Apache-2.0). `lib/src/sankey/layout.dart` (521 lines) cites
  `https://github.com/d3/d3-sankey/blob/master/src/sankey.js` (`:11`). The SDK constraint is
  `'>=2.19.4 <3.0.0'`. Thus the package does not resolve on Dart 3.

<a id="google-charts"></a>

### The old Google charts and their forks: a renderer with no code

- `community_charts_common` 1.0.4 (2024-05-15, Apache-2.0) has `SankeyChart`
  (`lib/src/chart/sankey/sankey_chart.dart`, 39 lines) and a `SankeyGraph` data class
  (`lib/src/data/sankey_graph.dart`, 256 lines).
- `SankeyRenderer` (`lib/src/chart/sankey/sankey_renderer.dart`, 83 lines) has three `TODO`
  lines in place of code: "Populate renderer elements" (`:51`), "Calculate node and link renderer
  element positions" (`:56`) and "Paint the renderer elements on the canvas" (`:61`).
- `community_charts_flutter` 1.0.4 has no string `sankey`. Thus no Flutter widget shows the chart.
- `charts_common` 0.12.0 (discontinued), `nimble_charts_common` 0.5.0-beta,
  `charts_common_maintained` 1.0.0 and `fcharts_common` 0.13.0 have the same three `TODO` lines.

### Chart packages with no sankey

- The archives of `fl_chart` 1.3.1 (2026-11-09), `graphic` 2.7.0 (2026-02-25) and
  `syncfusion_flutter_charts` 35.1.46 (2026-11-11) have no file with the string `sankey`.
- `cristalyse` 1.17.6 names sankey only as a later chart type (`README.md:1157`).
- The `d4` family has 17 `d4_*` packages. None is a sankey module. The archives of `d4` 0.6.0,
  `d4_hierarchy` 0.1.0 and `d4_shape` 1.1.0 have no string `sankey`.
- `data_visualization` 1.1.0, `dv_network` 1.1.0, `dv_shape` 1.1.0 and `duskmoon_visualization`
  2.2.11 have no string `sankey`.
- `community_charts_flutter2` 1.0.7 and `d_chart` 3.0.0 have no string `sankey`.
- `apexcharts_flutter` 0.1.2, `dart_apex_charts` 0.2.7, `plotly` 0.7.3 and `vega_embed_flutter`
  0.6.3 have no string `sankey`.

## Wrappers of JavaScript sankey charts

Each wrapper runs a JavaScript library. The sankey layout is the JavaScript of that library.

- **ECharts.** `flutter_echarts` 2.5.0, `graphify` 1.2.1, `fl_echarts` 0.3.0 and
  `universal_echarts` 1.0.0+4 bundle a minified ECharts. Each bundle has the series type
  `series.sankey` (`flutter_echarts/lib/echarts_script.dart`,
  `graphify/lib/src/resources/lib/echarts.min.dart`, `fl_echarts/assets/echarts.min.js`).
  `echarts_flutter_plus` 0.0.8 and `flutter_echarts_wrapper` 0.0.1 have no string `sankey` in the
  archive. The [ECharts survey](../../../flutter_echarts_port/doc/prior-art/README.md) describes
  these packages.
- **Highcharts.** `highcharts_flutter` 1.3.0 shows Highcharts in a WebView. It has 22 option files
  for the sankey series. `HighchartsSankeySeries` has the type `'sankey'`
  (`lib/options/highcharts_sankey_series.dart:90`). Its license is the Highsoft integration
  license. `high_chart` 2.8.1 (MIT) passes an option string to Highcharts in a WebView.
- **Plotly.** `plotly_js` 0.0.2 (2019-09-16, MIT) bundles Plotly. The bundle has the trace type
  `sankey`. pub.dev marks the package `is:dart3-incompatible`.
- **Google Charts.** `google_charts` 0.2.1 (2016-05-18, BSD-3-Clause, unlisted) has a
  `SankeyDiagram` class. It loads the Google Charts package `sankey` through `dart:js`
  (`lib/src/visualization/sankey_diagram.dart`). `google_visualization_api` 0.1.2+1 (2015) has a
  sankey example.
- No wrapper loads chartjs-chart-sankey.

## Upstream: chartjs-chart-sankey

- The repository is [kurkle/chartjs-chart-sankey](https://github.com/kurkle/chartjs-chart-sankey):
  MIT, "Copyright (c) 2019-2026 Jukka Kurkela" (`LICENSE:3` at the pin), 186 stars, 37 forks.
- The first npm version is `0.1.0-alpha` (2020-05-12). npm has 42 versions. The latest is 0.19.1
  (2026-09-12).
- The peer dependency is `chart.js >=3.3.0`. The package has no runtime dependency. It does not
  use d3-sankey.
- Recent versions: 0.12.0 (2022-11-22), 0.14.0 (2024-12-10), 0.15.0 (2026-07-13). The eight
  versions from 0.16.0 to 0.19.1 are all of 2026-09-12.
- The pin `v0.19.1` is the commit `90b638b1` (2026-09-12). On 2026-11-13, `main` is at `c0fa6c90`
  (2026-11-07), 19 commits after the tag. The comparison changes docs pages, a docs style file,
  the package files and the dependabot config. It changes no library source.
- The sources are TypeScript: `controller.ts` (622 lines), `flow.ts` (303), `labels.ts` (166),
  `types.ts` (183), `lib/core.ts` (111), `lib/helpers.ts` (30) and `lib/layout.ts` (662).
- **The layout is the work of the upstream author.** `layout` (`src/lib/layout.ts:642`) calls
  `calculateX` (`:90`), then `calculateY` (`:307`) or `calculateYUsingPriority` (`:318`), then
  `addPadding` (`:530`) and `sortFlows` (`:595`).
- `calculateX` fills one column at a time from a start column. The mode `edge` moves each node
  with no output to the last column (`:124-136`).
- `calculateY` starts at one node and follows the flows: `findStartNode`, `processFrom`,
  `processTo`, `processRest` and `fixTop` (`:307-316`). It has no relaxation loop. The vertical
  order comes from the traversal and from the 11 `sort` calls of `lib/`.
- The options `column` and `priority` let the app place nodes. `nodePadding`, `nodePaddingMode`,
  `nodeMinSize`, `modeX`, `size` and `orientation` change the layout (`src/types.ts`).
- **Drawing.** The controller has the id `sankey` (`src/controller.ts:240`). It draws each node
  with `fillRect` (`:579`) and each label with `drawLabel` (`:519`). The element `Flow` has the id
  `flow` (`src/flow.ts:134`). It draws a band with two `bezierCurveTo` calls (`:99-105`). The
  default `colorMode` is `gradient` (`:138`), a `createLinearGradient` paint (`:63-64`).
- **Tests.** `src/lib/layout.test.ts` has 22 test calls. `test/specs/` has 5 spec files.
  `test/fixtures/` has 88 files at the pin.

## Ports and wrappers outside Dart

<a id="fulgur"></a>

- **`fulgur-rs/fulgur-chart`** ([GitHub](https://github.com/fulgur-rs/fulgur-chart), Rust, 3 stars,
  `main` at `70504589fd2d` of 2026-11-01. Crate `fulgur-chart` 0.13.2 of 2026-09-18, MIT OR
  Apache-2.0). It renders Chart.js JSON specs to static SVG and PNG.
  - `crates/fulgur-chart/src/layout/sankey.rs` (1,443 lines) says in line 1, in Japanese, that it
    is a faithful port of chartjs-chart-sankey `lib/{core,layout}.ts`.
  - It keeps the upstream names. The column step has `build_nodes` (`:113`),
    `get_all_keys_forward` (`:205`), `start_column` (`:223`) and `calculate_x` (`:269`).
  - The vertical step has `process_from` (`:399`), `process_to` (`:417`), `process_rest` (`:445`),
    `fix_top` (`:518`), `find_start_node` (`:548`), `calculate_y` (`:572`) and
    `calculate_y_using_priority` (`:585`).
  - The last steps are `add_padding` (`:623`), `sort_flows` (`:679`) and `layout` (`:758`).
  - Its header gives three rules (`:3-7`). Nodes stay in insertion order. Each sort is stable, with
    the tie-breaks of upstream. A visited set for each traversal replaces the global counter
    `getCountId` and `_visited` of upstream.
  - No file names the upstream version. The plan is `docs/plans/2026-06-28-sankey-diagram.md`. The
    pin v0.19.1 has no `getCountId` and no `_visited`. The Rust file has no `orientation` and no
    `nodeMinSize`. Thus the Rust port follows an older upstream version.
  - The plan says that the port makes its own golden files. It does not compare bytes with
    QuickChart.
  - A code search for `kurkle` in the repository gave 0 hits. The crate has a `LICENSE-Chart.js`
    file with the Chart.js notice only.

<a id="sankey_mpl"></a>

- **`nrrb/sankey_mpl`** ([GitHub](https://github.com/nrrb/sankey_mpl), Python, MIT, `main` at
  `899773253c78` of 2026-08-13. PyPI `sankey-mpl` 0.2.0 of 2026-08-13). A sankey for matplotlib.
  - The README says: "The layout is a Python port of the algorithm in chartjs-chart-sankey 0.15.0
    (MIT, © Jukka Kurkela), reimplemented from a written specification of its behaviour"
    (`README.md:124-127`).
  - It also says: "this library reproduces that library's geometry, verified against golden data
    generated by running the original" (`README.md:127-128`).
  - `NOTICE` keeps the upstream MIT text with "Copyright (c) 2020 Jukka Kurkela". It says that the
    package includes no upstream source code.
  - The docstring of `src/sankey_mpl/layout.py` (668 lines) names two traits of the upstream
    layout. First: "Vertical order inside a column is not the result of a sort. It emerges from a
    traversal". Second: ties go through "subtree size, then degree, then flow, then *input
    order*".
  - The docstring says that the module "mirrors the original's sequence of in-place sorts rather
    than deriving one combined ordering key".

<a id="charba"></a>

- **Charba** ([pepstock-org/Charba](https://github.com/pepstock-org/Charba), Java for GWT and J2CL,
  Apache-2.0, release 6.5 on 2024-02-10). It bundles `resources/chartjs-chart-sankey.min.js`,
  whose header says "chartjs-chart-sankey v0.12.0". The package
  `src/org/pepstock/charba/client/sankey/` has typed classes: `SankeyChart`, `SankeyController`,
  `SankeyDataset`, `SankeyDataPoint`, `Column`, `Priority` and `Labels`. The layout runs in
  JavaScript.
- **Another Chart.js sankey plugin.** `larrymotalavigne/chartjs-sankey` (JavaScript, MIT, npm
  `@larrym/chartjs-plugin-sankey`, npm latest 3.0.0 of 2026-02-26). Its README says "Inspired by
  D3.js Sankey diagrams" and names chartjs-chart-sankey as an "Alternative Sankey
  implementation". The survey read only its README and `package.json`.
- **Users of the JavaScript module.** Code search for the string `chartjs-chart-sankey` found 2
  Java files (Charba) and 32 Python files. It found 3 Kotlin files and 3 Go files. It found none
  in Swift, Rust and C#. The survey read the file paths only. They are HTML report generators, a CDN list and the
  Python UI library `epykure/epyk-ui`. `nrrb/sankey_mpl` came from the repository search.
- **Swift.** A repository search found SwiftUI sankey libraries, for example `maxhumber/Sankey`
  (BSD-2-Clause, 66 stars) and `pkurzok/SankeyKit` (MIT, 32 stars). The survey did not read them.
  No description names Chart.js.

## Pages

- [Chart.js prior art](../../../flutter_chartjs_port/doc/prior-art/README.md): the survey of the
  host port, with the Chart.js wrappers.
- [chartjs-plugin-zoom prior art](../../../flutter_chartjs_plugin_zoom_port/doc/prior-art/README.md):
  the survey of the first add-on port.
- [D3 prior art](../../../flutter_d3_port/doc/prior-art/README.md): the d3-sankey ports in Dart
  (`sankey_flutter`, `fluent_2`, `e_chart_ext`, `mermaid_core`).
- [ECharts prior art](../../../flutter_echarts_port/doc/prior-art/README.md) and
  [other JavaScript chart libraries](../../../../docs/prior-art/other-chart-libraries.md): the
  Dart wrappers of other JavaScript chart libraries.

## How the survey was done

1. **pub.dev search.** The search API, three pages for each query. The queries were "sankey",
   "sankey diagram", "sankey chart", "flow diagram", "alluvial" and "energy flow". Also "chartjs
   sankey", "d3 sankey" and "d3_sankey". Also "sankey is:unlisted", "sankey show:discontinued" and
   "sankey show:hidden".
   - "alluvial" gave `tenun` and `tenun_pro`.
   - "flow diagram" gave node editors and flowchart packages, and `sankey_diagram_flutter`.
   - The other hits of "sankey" are icon fonts with a `sankey` icon name. Examples are
     `iconify_flutter`, `flutter_tabler_icons`, `tomeui` and `laamsui`.
2. **pub.dev names.** The name list `/api/package-names` had 95,432 names at 16:30 UTC on
   2026-11-13. The survey read the names with `sankey`, `alluvial`, `chartjs`, `d3`, `d4`,
   `echarts`, `mermaid`, `plotly` and `apex`.
3. **Archives.** 67 pub.dev archives, each in its own folder. The survey searched each archive for
   the string `sankey` without case. It read the sankey files of each hit. The sections above name
   each archive with its version.
4. **GitHub code search.** The queries of the section
   [chartjs-chart-sankey in Dart](#chartjs-chart-sankey-in-dart). Also `"d3-sankey" language:Dart`
   (15 hits), `type: 'sankey' language:Dart` (26 hits), and `sankey` with `webview`, `echarts`,
   `highcharts`, `plotly` and `apexcharts`. The survey read the files of each lead.
5. **GitHub repository search.** "sankey language:Dart" (3 repositories), "sankey flutter",
   "alluvial language:Dart", "chartjs-chart-sankey" (6 repositories), "chartjs sankey", and sankey
   repositories in Kotlin and Swift.
6. **Other registries.** The npm registry for chartjs-chart-sankey and
   `@larrym/chartjs-plugin-sankey`. crates.io for "chartjs sankey" and "sankey". PyPI for
   `sankey-mpl`.
7. **Upstream.** The submodule `third_party/chartjs-chart-sankey` at the pin, the GitHub releases
   and the comparison `v0.19.1...main`.
8. **Static examination only.** The survey ran no package code.

## Limits of the search

A search cannot prove that no port exists. These gaps stay open:

- GitHub code search reads only the default branch of each repository and skips many forks. A port
  under another name or in a fork can stay hidden.
- A port that renames each upstream function and does not name the upstream gives no hit.
- The survey did not search Gitee, GitLab, Codeberg, Maven Central or the Swift Package Index.
- The survey read only the latest archive of each pub.dev package.
- The survey read the sankey files of each package, not the whole package. It did not run a chart.
  Thus it does not compare the pictures or the speed of the packages.
- For these projects the survey read less than the source of the layout: the three repositories
  with first lines only, `larrymotalavigne/chartjs-sankey` (README), the Swift libraries
  (descriptions) and the users of the JavaScript module (file paths).
- The d3-sankey version of `fluent_2` and the five differences of `sankey_flutter` come from the
  D3 survey of 2026-10-20. This survey checked the files and the lines that it cites, not those
  claims.
- No second reader checked this page.

## Licenses

- chartjs-chart-sankey is MIT (Jukka Kurkela). This port is MIT and keeps the upstream notice.
- **Copyleft.** `mozufu/pirc` is AGPL-3.0, and `dan63047/TetraStats` is GPL-3.0. Never copy code
  from them. Both hold d3-sankey code, not code of this upstream.
- **Proprietary.** `tenun_pro`, Syncfusion and Highcharts have their own commercial terms. They are
  prior art for ideas only.
- **No license.** `dayat123123/flutter-sankey-diagram`, `rlch/recharts-flutter` and
  `softradix/sankiy-graphs` give no license. Do not copy code from them.
- `sankey_flutter` is BSD-3-Clause with a changed holder line. `fluent_2`, `e_chart_ext` and
  `mermaid_core` hold d3-sankey code without the d3-sankey notice. d3-sankey is BSD-3-Clause
  (Mike Bostock).
- `sankey_diagram_flutter`, `flutter_charts_kit`, `ohlcv_chart`, `pele_dart` and
  `duskmoon_mermaid_renderer` are MIT. `chartify`, `flutter_naveen_charts`, `tenun`, `drafter` and
  the Google charts forks are Apache-2.0.
- `fulgur-chart` is MIT OR Apache-2.0. `sankey_mpl` is MIT. Charba is Apache-2.0.
- [AGENTS.md](../../../../AGENTS.md) rule 1 applies: each project on this page is prior art only.
  It is neither a source nor a dependency of this port. This port translates only the pinned files
  of `third_party/chartjs-chart-sankey`.

## What the port takes from this

Each item gives facts first. "Opinion" marks the opinions of the author of this page.

1. **No Dart code to follow.**
   - Fact: no Dart project ports or wraps chartjs-chart-sankey.
   - Fact: each native Dart sankey has a d3-sankey layout or a longest-path layout. The upstream
     layout is neither.
   - Opinion: no Dart package can give this port a layout result to compare with. The reference
     values must come from the pinned JavaScript on the reference engine
     ([Chart.js ADR 0045](../../../flutter_chartjs_port/doc/adr/0045-reference-engine-arm64.md)).
2. **The order of the nodes is behavior.**
   - Fact: the upstream vertical order comes from a traversal and from in-place sorts. The Python
     port keeps "the original's sequence of in-place sorts". The Rust port keeps the insertion
     order of the nodes and uses only stable sorts.
   - Fact: JavaScript `Array.prototype.sort` is stable, and a JavaScript `Map` keeps its insertion
     order. The Dart docs do not call `List.sort` stable.
   - Fact: on the survey date, `lib/src/lib/core.dart` and `lib/src/lib/layout.dart` of this port
     call `jsSort`, the stable sort of the host runtime
     (`package:flutter_chartjs_port/js_semantics.dart`).
   - Opinion: the port must translate each upstream `sort` call in its place, with the stable
     sort. A combined sort key is a risk.
3. **Equal flows.**
   - Fact: the Python port says that data with equal flows depends on the input order of the
     links.
   - Opinion: the port-only tests must have cases with equal flows, with reference values from the
     pinned JavaScript.
4. **Parity fixtures.**
   - Fact: `sankey_flutter` compares its layout with files that the port itself made (D3 survey).
     The Rust port makes its own golden files. The Python port generates its golden data "by
     running the original".
   - Opinion: the Python method is the right one. It is the rule of this repository.
5. **The upstream version.**
   - Fact: the Rust port names no upstream version, and its code follows an older one. The Python
     port names 0.15.0. Charba bundles v0.12.0. The upstream made eight versions on 2026-09-12.
   - Opinion: a port without a pin cannot follow these changes. This port pins v0.19.1 and names
     the version in each file header.
6. **The notice.**
   - Fact: `sankey_flutter` replaced the holder in the d3-sankey license text. The Python port
     keeps the notice of Jukka Kurkela in `NOTICE`.
   - Fact: the `LICENSE` of this package has "Copyright (c) 2019-2026 Jukka Kurkela" and the line
     of the port author.
7. **The chart around the layout.**
   - Fact: each native Dart package has its own widget, hit test, tooltip and animation code
     around its layout. `fluent_2` ports those parts from the React chart.
   - Fact: the upstream is a Chart.js controller and an element. It takes the scales, the
     tooltip, the events and the animations from Chart.js.
   - Opinion: an add-on of `flutter_chartjs_port` gets these parts from the host. That is a clear
     difference from each package on this page.
8. **Features that the native packages share with the upstream.**
   - Fact: gradient links are in `sankey_flutter`, `sankey_diagram_flutter` and the upstream
     default.
   - Fact: manual columns are in `sankey_diagram_flutter`, `tenun`, `drafter` and the upstream
     option `column`.
   - Fact: `sankey_diagram_flutter` draws a circular link as an arc. `flutter_charts_kit` and
     `ohlcv_chart` drop the links of a cycle.
   - Opinion: the port must show what the pinned upstream does with a cycle, from the upstream
     tests and fixtures. It must not take the rule of a Dart package.
9. **Names.** On 2026-11-13 at 16:45 UTC, the pub.dev API gave HTTP 404 for
   `flutter_chartjs_chart_sankey_port`, `flutter_chartjs_chart_sankey`, `chartjs_chart_sankey` and
   `chartjs_sankey` ([ADR 0007](../../../../docs/adr/0007-package-names.md)). The name of this
   package is free.
