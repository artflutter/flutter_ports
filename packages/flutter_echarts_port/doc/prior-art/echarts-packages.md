# ECharts packages for Dart and Flutter

This page tells how each ECharts-related package and repository works, from its API to its output.
It is part of the [prior-art survey](README.md). The sweeps ran on 2026-10-20. Facts that change
(versions, dates, downloads, likes, stars) are as of 2026-10-21.

The survey put each archive or repository in its own directory and read it statically. It ran no
package code and no `pub get`. Evidence cites `path:line` inside the inspected package or
repository. Upstream evidence has the form `echarts@6.1.0 <path>:<line>` or
`zrender@6.1.0 <path>:<line>`. These are the pins of this port (`third_party/echarts` and
`third_party/zrender`).

<a id="terms"></a>

Terms:

- **Port**: ECharts or zrender logic translated into another language. No JavaScript runs.
- **Structural port**: a port that keeps the upstream file split and the upstream names.
- **Behavior port**: a port that keeps the upstream behavior but merges or splits the modules.
- **Native rewrite**: new code with the ECharts option names or concepts. No upstream function is
  translated.
- **Borrowed helper**: one upstream function translated into a package of other code.
- **WebView**: an HTML page that runs the JavaScript ECharts in a native WebView.
- **JS interop**: Dart bindings that call the JavaScript ECharts in a browser page, through an
  `HtmlElementView`.
- **Option model**: Dart classes that serialize an ECharts option to JSON for the JavaScript
  ECharts.
- **Lines**: the output of `wc -l` over the Dart files of `lib/`. These counts include blank lines
  and comments.

**Re-check marks.**

- The row **Re-check** of each facts table names the claims that the author of this page read
  again in the cited files on 2026-10-21.
- The mark *(no re-check)* follows a claim that comes from the survey of 2026-10-20 only. One
  sweep and, for the nearest candidates, one verifier read its evidence.
- The author read the dates, the versions and the adoption figures again from the pub.dev API and
  the GitHub API on 2026-10-21.

Packages: [`e_chart` and `e_chart_ext`](#pkg-e_chart) ·
[`slidable_line_chart`](#pkg-slidable_line_chart) · [`graphic`](#pkg-graphic) ·
[`flutter_echarts`](#pkg-flutter_echarts) · [`graphify`](#pkg-graphify) ·
[`fl_echarts`](#pkg-fl_echarts) · [`echarts_flutter_plus`](#pkg-echarts_flutter_plus) ·
[`universal_echarts`](#pkg-universal_echarts) · [wrappers and copies](#pkg-wrappers) ·
[option models](#pkg-options) · [`EChartsSwift`](#pkg-echartsswift) ·
[`yuecharts`](#pkg-yuecharts) · [`TyControls`](#pkg-tycontrols) ·
[other non-Dart projects](#pkg-other-languages) · [ruled out](#pkg-ruleouts)

<a id="pkg-e_chart"></a>

## `e_chart` and `e_chart_ext`: a native rewrite of the ECharts option model, abandoned since 2023-05-10

| | |
|---|---|
| Where | [pub.dev/packages/e_chart](https://pub.dev/packages/e_chart) and [pub.dev/packages/e_chart_ext](https://pub.dev/packages/e_chart_ext), by Go-oG. The homepages `github.com/Go-oG/xchart` and `github.com/Go-oG/xchart_ext` give HTTP 404. The Wayback Machine and Software Heritage have no copy *(no re-check)* |
| Inspected | `e_chart` 0.0.1 (2023-05-10) and `e_chart_ext` 0.0.1 (2023-05-10), the only versions. `e_chart` has 202 Dart files and 14,686 lines in `lib/`. `e_chart_ext` has 71 Dart files and 6,889 lines |
| Status | Abandoned. One release of each package. The source repositories are gone. The dependency `chart_xutil` 1.0.6 of the same author is discontinued and unlisted on pub.dev |
| Approach | Native rewrite. The folders and the option class follow the ECharts option model. The algorithms are the author's own. `e_chart_ext` adds layouts translated from d3 |
| ECharts version | None. The only ECharts reference is a link to the option docs (`lib/src/model/enums/chart_type.dart:1`) |
| Works on | Flutter, pure Dart, through `CustomPainter`. The SDK constraint is `>=2.19.4 <3.0.0`. Dart 3 reads this upper bound as `<4.0.0`, because the lower bound is at least 2.12. pub.dev gives the tag `has:error` and no tag `is:dart3-compatible`. Nobody ran a resolve or a build |
| License | Apache-2.0. The `LICENSE` keeps the template line "Copyright [yyyy] [name of copyright owner]" (`LICENSE:189`). Thus it names no holder. No file credits ECharts. `e_chart_ext` has d3 code without the d3 notice |
| Adoption (2026-10-21) | `e_chart`: 0 likes, 29 downloads in 30 days, 30/160 pub points. `e_chart_ext`: 0 likes, 28 downloads, 40/160 pub points |
| Re-check | The versions, the dates, the SDK constraint, the dependencies, the file and line counts, `chart_type.dart:1`, `ChartConfig`, `LICENSE:189`, the absence of `echarts`, `zrender`, `webview` and `js_interop` in `lib/` other than `chart_type.dart:1`, `lcg.dart` and `sankey/layout.dart:11`. The ECharts lines at the pin |

### How it renders

1. The user builds a `ChartConfig` (`lib/src/chart.dart:17`). Its fields copy the top-level
   ECharts option names: `title`, `legend`, `xAxisList`, `yAxisList`, `polarList`, `radarList`,
   `parallelList`, `calendarList`, `series`, `grid` and `toolTip` (`chart.dart:18-31`).
2. The coordinate systems are in `lib/src/coord/`: `grid`, `polar`, `radar`, `parallel`,
   `calendar` and `single`. The series are in `lib/src/charts/`: bar, boxplot, calendar,
   candlestick, funnel, heatmap, line, parallel, pie, point, radar and sunburst.
3. Each series has a layout class and a view class of its own. Flutter `Canvas` calls draw the
   result. The package has no zrender layer, no display list and no element tree
   *(no re-check)*.
4. `e_chart_ext` adds gauge, graph, pack, sankey, themeRiver, tree and treemap. Its graph layouts
   use `dart_dagre`, `ml_linalg` and `scidart`.

### What is ECharts and what is not

A verifier compared three algorithms with ECharts 5.5.1 on 2026-10-20 *(no re-check of the
`e_chart` lines)*. The author of this page found the same upstream functions at the pin:

- **Funnel.** `e_chart` sizes each layer as `data / max * width`, with a point list for each sort
  and alignment case (`lib/src/charts/funnel/layout.dart:20-98`). ECharts sorts with
  `getSortedIndices` (`echarts@6.1.0 src/chart/funnel/funnelLayout.ts:264`). It resolves
  `minSize` with `parsePercent` (`funnelLayout.ts:269`). It maps each value with `linearMap`
  (`funnelLayout.ts:294`).
- **Line curves.** `e_chart` uses a slope form with the smoothness 0.25
  (`lib/src/shape/line.dart:32`) and a second form with the ratio 0.2 (`line.dart:74`). ECharts
  uses `drawSegment` (`echarts@6.1.0 src/chart/line/poly.ts:36`). zrender uses `smoothBezier`
  (`zrender@6.1.0 src/graphic/helper/smoothBezier.ts:26`).
- **Ticks.** `e_chart` uses an extended Wilkinson search (`_niceAxis` at
  `lib/src/component/scale/nice_scale.dart:82`, `_simplicity` at `nice_scale.dart:229`). ECharts
  uses `intervalScaleNiceTicks` (`echarts@6.1.0 src/scale/helper.ts:93`) with `nice`
  (`echarts@6.1.0 src/util/number.ts:613`).
- **d3 in `e_chart_ext`.** `DefaultLCG` has the constants and the steps of the d3-force `lcg`
  (`lib/src/graph/layout/force/lcg.dart:7-15`). `lib/src/sankey/layout.dart:11` cites d3-sankey.
  The treemap tiles mirror d3-hierarchy *(no re-check)*. The
  [D3 survey](../../../flutter_d3_port/doc/prior-art/d3-packages.md#pkg-e_chart_ext) covers these
  ports.

### Limitations

- No upstream structure: the files do not follow `src/` of ECharts. No file names an upstream
  path. Thus nobody can diff it against an ECharts release.
- Other output than ECharts: the ticks, the curves and the funnel sizes differ from ECharts for
  the same option.
- No tests other than the template. The `README.md` is "# xchart". The `CHANGELOG.md` has a TODO
  *(no re-check)*.
- The option values are Dart objects and Dart functions. ECharts option JSON does not load as it
  is.
- The pub.dev analysis fails. The source repository is gone. Nobody can open an issue.

### Takeaways for flutter_echarts_port

- A rewrite with ECharts names does not give ECharts output. Port the scales, the layouts and the
  curves from the pinned source. Compare them with the JavaScript ECharts.
- It is the largest native ECharts-shaped Dart code found (about 21.5k lines). It stopped after one
  release without tests. A port needs specs and reference data from the first phase.
- ECharts embeds d3 code in five files (ECharts ADR 0001 item 12). A port of these files keeps
  the d3 notice. `e_chart_ext` did not keep it.

### Evidence

`lib/src/model/enums/chart_type.dart:1` (the only ECharts link), `lib/src/chart.dart:17-31`
(`ChartConfig`), `pubspec.yaml:7` (`sdk: '>=2.19.4 <3.0.0'`), `LICENSE:189` (template holder),
`e_chart_ext/lib/src/graph/layout/force/lcg.dart:7-15` (d3-force `lcg`),
`e_chart_ext/lib/src/sankey/layout.dart:11` (d3-sankey reference)

<a id="pkg-slidable_line_chart"></a>

## `slidable_line_chart`: an own line chart with one translated branch of `poly.ts`

| | |
|---|---|
| Where | [pub.dev/packages/slidable_line_chart](https://pub.dev/packages/slidable_line_chart), [github.com/moxiaov587/slidable_line_chart](https://github.com/moxiaov587/slidable_line_chart) |
| Inspected | The repository at its default branch on 2026-10-21. A verifier cloned it on 2026-10-20: 7 Dart files and 2,456 lines in `lib/` *(no re-check of the counts)* |
| Status | Maintained at a low rate. pub.dev has 1.4.0 of 2024-10-13. The last push to the repository was on 2026-09-01 |
| Approach | Native-inspired, with one borrowed helper. The package is an own `CustomPainter` line chart. The user drags its points up and down. About 95 lines translate one branch of `drawSegment` of ECharts |
| ECharts version | `master`, not pinned. The comment links `https://github.com/apache/echarts/blob/master/src/chart/line/poly.ts` |
| Works on | All Flutter platforms. pub.dev gives the tags of Android, iOS, Windows, Linux, macOS and web, and `is:wasm-ready`. The SDK constraint is `>=2.16.2 <4.0.0` |
| License | Apache-2.0, the full text. No `NOTICE` file. No ECharts copyright line other than the URL |
| Adoption (2026-10-21) | 8 likes, 15 downloads in 30 days, 150/160 pub points, 12 GitHub stars |
| Re-check | The comment at `lib/coordinate_system_painter.dart:393`, the version, the date, the license, the stars. The four upstream lines at the pin |

### What it translates

The code after `lib/coordinate_system_painter.dart:393` is the general branch of `drawSegment`
(`echarts@6.1.0 src/chart/line/poly.ts:36`), without `smoothMonotone`:

- the segment ratio `ratioNextSeg = lenNextSeg / (lenNextSeg + lenPrevSeg)` (`poly.ts:157`)
- the clamp "Smooth constraint between point and next point" (`poly.ts:166`)
- the new control point 1 from the adjusted control point 0 of the next segment (`poly.ts:172`)
- "Adjust next cp0 again" (`poly.ts:186`)

The Dart code uses `Offset.clamp` for the `mathMin` and `mathMax` pairs. It drops the
`smoothMonotone` branches, `connectNulls`, `isPointIllegal`, the flag `smoothConstraint` and the
segment length test *(no re-check)*. The rest of the package has no ECharts names, no option model
and no zrender.

### Limitations

- The source is `master`, not a release. The line numbers of the upstream file change over time.
- Only one curve branch. The curves differ from ECharts for `smoothMonotone` and for gaps.
- No ECharts notice.

### Takeaways for flutter_echarts_port

- The smooth-curve code of `poly.ts` is the first ECharts code that Dart authors copy. A spec and
  reference data for each branch of `drawSegment` find the cases that this copy drops.
- Pin the source. A link to `master` does not tell the reader which code was translated.

### Evidence

`lib/coordinate_system_painter.dart:393` (the `poly.ts` URL), `LICENSE` (Apache-2.0),
`echarts@6.1.0 src/chart/line/poly.ts:36,157,166,172,186`

<a id="pkg-graphic"></a>

## `graphic`: an independent grammar of graphics with one zrender helper

| | |
|---|---|
| Where | [pub.dev/packages/graphic](https://pub.dev/packages/graphic), [github.com/entronad/graphic](https://github.com/entronad/graphic). The author, LIN Chen (entronad), also wrote `flutter_echarts` |
| Inspected | The repository at its default branch on 2026-10-21. Verifiers read 2.7.0 at commit `3b6f31e` on 2026-10-20: 118 Dart files and 15,252 lines in `lib/` *(no re-check of the counts)* |
| Status | Maintained. 2.7.0 of 2026-02-25. 44 versions on pub.dev |
| Approach | Independent. The grammar of graphics follows AntV G2 and Vega, not the ECharts model of series, components and coordinate systems. One helper translates the zrender `smoothBezier`, by way of AntV F2 |
| ECharts version | None. `example/lib/pages/echarts.dart` rebuilds some ECharts gallery examples with the `graphic` API *(no re-check)* |
| Works on | All Flutter platforms, `is:wasm-ready`. SDK `>=2.13.0 <4.0.0`, Flutter `>=3.16.0` |
| License | MIT, "Copyright (c) 2024 LIN Chen" (`LICENSE:3`). `LICENSE_APPENDIX` names the projects that the package is "inspired or/and uses code of": AntV F2, AntV G2, Vega, Vega-Lite, google/charts, apache/echarts and d3. It does not name zrender |
| Adoption (2026-10-21) | 901 likes, 41,030 downloads in 30 days, 160/160 pub points, 1,793 GitHub stars, 185 forks |
| Re-check | `_getControlPoints` at `lib/src/util/path.dart:8`, the loop rotation at `path.dart:85`, the flag `hasConstraint` at `path.dart:12,27,73`. `LICENSE_APPENDIX:1,5,45,49`. The version, the date, the counts of likes, downloads, stars and forks. The zrender lines at the pin |

### What it translates

`_getControlPoints` (`lib/src/util/path.dart:8`) follows `smoothBezier`
(`zrender@6.1.0 src/graphic/helper/smoothBezier.ts:26`) step for step. Both build the box of the
points and the constraint. Both compute the control points from the neighbor points and their
distances. Both clamp the result to the box. Both rotate the closed list:
`cps.add(cps.removeAt(0))` (`path.dart:85`) against `cps.push(cps.shift())`
(`smoothBezier.ts:100`).

The name `hasConstraint` and the caller `getCubicControls` agree with AntV F-Engine
`packages/f-engine/src/shape/util/smooth.ts` more closely than with zrender *(no re-check)*. Thus
the direct source is AntV F2. F2 took it from zrender. The file has no attribution comment.

`lib/src/scale/util/nice_range.dart` ports a d3 tick function, not an ECharts one. The
[D3 survey](../../../flutter_d3_port/doc/prior-art/d3-packages.md#pkg-larger) covers it.

### Limitations

- It is not ECharts. It does not read ECharts options. Its marks and scales follow G2.
- The zrender code reaches it without the BSD-3-Clause notice of zrender.

### Takeaways for flutter_echarts_port

- `graphic` is the native chart library that the `flutter_echarts` README recommends. It sets the
  bar for quality and platform reach: wasm-ready and 160/160 points.
- zrender code travels through other ports (AntV F2) and loses its notice. This port translates
  zrender only from `third_party/zrender`. It keeps the BSD-3-Clause notice of Baidu Inc.

### Evidence

`lib/src/util/path.dart:8,12,27,73,85`, `LICENSE_APPENDIX:1,5,45,49`,
`zrender@6.1.0 src/graphic/helper/smoothBezier.ts:26,100`

<a id="pkg-flutter_echarts"></a>

## `flutter_echarts`: the JavaScript ECharts 5.4.3 in a WebView, archived

| | |
|---|---|
| Where | [pub.dev/packages/flutter_echarts](https://pub.dev/packages/flutter_echarts), [github.com/entronad/flutter_echarts](https://github.com/entronad/flutter_echarts) |
| Inspected | The archive of 2.5.0 (2023-08-31). The repository `LICENSE` |
| Status | Archived. The last push was on 2025-08-11. 33 versions on pub.dev. The README recommends `graphic` |
| Approach | WebView. The widget loads an HTML page into a `WebViewController` and runs the bundled ECharts script. The option is a JavaScript string |
| ECharts version | 5.4.3, bundled in `lib/echarts_script.dart` (`version="5.4.3"`) |
| Works on | Android, iOS and macOS (pub.dev tags). The only dependency is `webview_flutter ^4.2.4` |
| License | BSD-2-Clause, "Copyright (c) 2018-2020, LIN Chen" (repository `LICENSE`). pub.dev shows `license:unknown`. GitHub gives `NOASSERTION` |
| Adoption (2026-10-21) | 578 likes, 4,578 downloads in 30 days, 130/160 pub points, 762 GitHub stars, 175 forks |
| Re-check | The version, the date, the dependency, the ECharts version, the WebView lines, `README.md:19`, the license, the archive state, the counts |

### How it renders

1. `Echarts` builds a `WebViewController` (`lib/flutter_echarts.dart:69`) and a page with the
   bundled script.
2. It runs `echarts.init` in the page (`flutter_echarts.dart:102`). It passes the option string
   to `chart.setOption` (`flutter_echarts.dart:104`) through `runJavaScript`
   (`flutter_echarts.dart:99`).
3. The browser engine of the WebView draws the chart. Flutter shows the WebView as a platform
   view.

### Limitations

- The README says: "Since it is based on webview, this library has some inextricable instability
  and performance issues" (`README.md:19`).
- No Linux, no Windows and no web.
- The option is JavaScript source. A Dart value goes into the page as text.

### Takeaways for flutter_echarts_port

- `flutter_echarts` has the name, the likes and the downloads. Its own author archived it and
  points to a native library. This is the gap that a native port fills.
- Many repositories copy it (see [wrappers and copies](#pkg-wrappers)). In the 174 GitHub forks,
  no fork replaced the WebView *(no re-check)*. Dependents on pub.dev: `kommon` (it re-exports the
  package), `medha_boards_table`, `wapas_ui_kit` and `universal_echarts` *(no re-check)*.
- In apache/echarts issue #12213 (2020), a maintainer said that the ECharts team works on
  JavaScript only. The maintainer pointed to `flutter_echarts` *(no re-check)*.
  [awesome-echarts](https://github.com/ecomfe/awesome-echarts) lists only this package under
  Flutter and Dart *(no re-check)*.

### Evidence

`lib/flutter_echarts.dart:8` (`import 'package:webview_flutter/webview_flutter.dart'`),
`lib/flutter_echarts.dart:69,99,102,104`, `lib/echarts_script.dart` (`version="5.4.3"`),
`README.md:19`, `pubspec.yaml` (`webview_flutter: ^4.2.4`)

<a id="pkg-graphify"></a>

## `graphify`: the JavaScript ECharts 5.5.0 in a WebView and in a web view, archived

| | |
|---|---|
| Where | [pub.dev/packages/graphify](https://pub.dev/packages/graphify), [github.com/warioddly/graphify](https://github.com/warioddly/graphify) |
| Inspected | The archive of 1.2.1 (2025-09-03), 22 Dart files in `lib/` |
| Status | Archived. The last push was on 2025-09-03 |
| Approach | WebView on Android, iOS, macOS and Windows. JS interop with an `HtmlElementView` on the web. The JavaScript files of ECharts, ECharts GL and jQuery are Dart strings |
| ECharts version | 5.5.0, bundled in `lib/src/resources/lib/echarts.min.dart` |
| Works on | Android, iOS, macOS, Windows and web (pub.dev tags) |
| License | MIT |
| Adoption (2026-10-21) | 45 likes, 790 downloads in 30 days, 135/160 pub points, 97 GitHub stars |
| Re-check | The version, the date, the ECharts version, the three resource files, the lines below, the archive state |

### How it renders

- Mobile and desktop: `lib/src/view/implements/mobile.dart` creates a `WebViewController`
  (`mobile.dart:23`) and returns a `WebViewWidget` (`mobile.dart:51`).
- Web: `lib/src/view/implements/web.dart` imports `dart:js_interop`, `dart:ui_web` and
  `package:web` (`web.dart:1,2,9`). It registers a view factory (`web.dart:35`) and returns an
  `HtmlElementView` (`web.dart:44`).

### Limitations and takeaways

- Two hosts for one chart: a WebView and a browser page. Each has its own event and size path.
- About 1 MB of JavaScript in Dart strings for each app.
- The archive state leaves its users without updates. A native port removes the WebView and the
  script payload.

### Evidence

`lib/src/view/implements/mobile.dart:23,51`, `lib/src/view/implements/web.dart:1,2,9,35,44`,
`lib/src/resources/lib/echarts.min.dart` (`version="5.5.0"`)

<a id="pkg-fl_echarts"></a>

## `fl_echarts`: the JavaScript ECharts 6.0.0 in a WebView and an iframe

| | |
|---|---|
| Where | [pub.dev/packages/fl_echarts](https://pub.dev/packages/fl_echarts), [github.com/ayoubdar/fl_echarts](https://github.com/ayoubdar/fl_echarts) |
| Inspected | The archive of 0.3.0 (2026-03-19) |
| Status | Low activity. 4 versions. The last push was on 2026-03-19 |
| Approach | WebView through `webview_flutter` and `webview_windows`. An iframe in an `HtmlElementView` on the web |
| ECharts version | 6.0.0, bundled in `assets/echarts.min.js`. It is the only wrapper on ECharts 6 |
| Works on | Android, iOS, macOS, Windows and web (pub.dev tags). No Linux |
| License | MIT |
| Adoption (2026-10-21) | 1 like, 84 downloads in 30 days, 150/160 pub points, 0 GitHub stars |
| Re-check | The version, the date, the ECharts version, the lines below |

### How it renders

- Mobile: `lib/src/webview_impl_mobile.dart` loads an HTML string (`webview_impl_mobile.dart:35`)
  and runs scripts through `runJavaScript` (`webview_impl_mobile.dart:46`). It returns a
  `WebViewWidget` (`webview_impl_mobile.dart:52`).
- Web: `lib/src/webview_impl_web.dart` imports `dart:html` and `dart:ui_web`
  (`webview_impl_web.dart:8-9`). It creates an `IFrameElement` (`webview_impl_web.dart:17`),
  registers it (`webview_impl_web.dart:42`) and returns an `HtmlElementView`
  (`webview_impl_web.dart:86`).

### Limitations and takeaways

- `dart:html` does not compile with dart2wasm. Thus the web path does not run as WebAssembly. A
  native port runs on web WebAssembly ([ADR 0001](../../../../docs/adr/0001-native-ports-not-wrappers.md)).
- ECharts 6.0.0 reached Dart users only through this wrapper. The upstream 6.x line is current.

### Evidence

`assets/echarts.min.js` (`version="6.0.0"`), `lib/src/webview_impl_mobile.dart:35,46,52`,
`lib/src/webview_impl_web.dart:8,9,17,42,86`

<a id="pkg-echarts_flutter_plus"></a>

## `echarts_flutter_plus`: JS interop for the web, ECharts 5.5.0 from a CDN

| | |
|---|---|
| Where | [pub.dev/packages/echarts_flutter_plus](https://pub.dev/packages/echarts_flutter_plus), [github.com/noeljolly09/echarts_flutter_plus](https://github.com/noeljolly09/echarts_flutter_plus) |
| Inspected | The archive of 0.0.8 (2025-12-24) |
| Status | Low activity. 8 versions. The last push was on 2025-12-24 |
| Approach | JS interop. `@JS` bindings call `echarts.init` in the browser page. The widget is an `HtmlElementView`. A typed option API serializes to JSON *(no re-check of the option API)* |
| ECharts version | 5.5.0, loaded at runtime from `https://cdn.jsdelivr.net/npm/echarts@5.5.0/dist/echarts.min.js` |
| Works on | Web only (pub.dev tag), `is:wasm-ready` |
| License | MIT |
| Adoption (2026-10-21) | 4 likes, 225 downloads in 30 days, 160/160 pub points, 4 GitHub stars |
| Re-check | The version, the date, the CDN URL, the lines below |

### How it renders

`lib/src/echarts_web_view.dart` declares `@JS('echarts')` and `@JS('echarts.init')`
(`echarts_web_view.dart:24,27`). It loads the script from the CDN (`echarts_web_view.dart:153`).
It registers a view factory (`echarts_web_view.dart:207`) and returns an `HtmlElementView`
(`echarts_web_view.dart:344`).

### Limitations and takeaways

- Web only. The app needs network access to the CDN at runtime.
- `package:web` and `dart:js_interop` give a wasm-ready wrapper. The chart still runs in
  JavaScript.

### Evidence

`lib/src/echarts_web_view.dart:24,27,30,33,153,207,344`

<a id="pkg-universal_echarts"></a>

## `universal_echarts`: `flutter_echarts` on mobile and an iframe on the web, abandoned

| | |
|---|---|
| Where | [pub.dev/packages/universal_echarts](https://pub.dev/packages/universal_echarts), [github.com/AgamottoZ/universal_echarts](https://github.com/AgamottoZ/universal_echarts) |
| Inspected | The archive of 1.0.0+4 (2021-03-30) |
| Status | Abandoned since 2021-03-30. pub.dev gives the tag `has:error`. The SDK constraint is `>=2.12.0 <3.0.0` |
| Approach | A wrapper of wrappers. Mobile uses `flutter_echarts` (`lib/src/mobile.dart:2`). The web uses an `IFrameElement` in an `HtmlElementView` (`lib/src/web.dart:41,124,140`). Its description says "porting Echarts to Web and Mobile". It is not a port |
| ECharts version | 5.0.0, bundled in `lib/src/echarts_script.dart` |
| Works on | Android, iOS and web, on Dart 2 |
| License | MIT |
| Adoption (2026-10-21) | 3 likes, 1 download in 30 days, 70/160 pub points, 0 GitHub stars |
| Re-check | The version, the date, the tag, the lines in the row Approach, the ECharts version |

**Takeaways.** The word "port" in a package description does not make a port. The survey read the
code of each candidate.

<a id="pkg-wrappers"></a>

## Wrappers and copies on GitHub and other hosts

These repositories run the JavaScript ECharts. None of them is on pub.dev under its own name. The
rows come from the survey of 2026-10-20 *(no re-check)*. The author read the stars, the push
dates and the licenses of the GitHub rows again on 2026-10-21.

| Repository | Approach | ECharts | Evidence | License | Last push |
|---|---|---|---|---|---|
| [yu629/flutter_native_echarts](https://github.com/yu629/flutter_native_echarts) | WebView, despite "native" in the name | 4.8.0, bundled | `flutter_native_echart/lib/flutter_native_echart.dart` builds a `WebView` and calls `evaluateJavascript` | none | 2021-03-11 |
| [furuiCQ/flutter_echart](https://github.com/furuiCQ/flutter_echart) | own WebView platform views (`AndroidView`, `UiKitView`) | from an HTML asset | `lib/flutter_native_web.dart`, `android/.../FlutterWeb.java` | template "TODO: Add your license here." | 2021-04-01 |
| [duzeng/my_echarts](https://github.com/duzeng/my_echarts) | own WebView platform views | bundled `echart.min.js` | `lib/src/platform_native_web.dart` | `NOASSERTION` | 2022-05-25 |
| [wajipu/flutter_echart_laste_plus](https://github.com/wajipu/flutter_echart_laste_plus), also on Gitee | WebView, `webview_win_floating` on Windows | 5.4.3 bundled, 5.3.3 from bootcdn | `lib/source_windows_web/web_flutter.dart` | `NOASSERTION` | 2024-10-24 |
| [boomcx/echarts](https://github.com/boomcx/echarts) | copy of `flutter_echarts` | 5.4.1 | the description: "upgrade webview_flutter 3.0 to 4.0, and echarts.js to 5.4.1" | `NOASSERTION` | 2025-06-24 |
| [11os/flutter_echarts_web](https://github.com/11os/flutter_echarts_web) | JS interop through `package:js`, web only | not pinned, from a script tag | `lib/echarts_web/echarts_web.dart` | none | 2021-05-09 |
| [Golden-Bit/financial_UI](https://github.com/Golden-Bit/financial_UI) | JS interop in an app UI kit, web only | `echarts@5` from jsDelivr | `lib/other_elements/sankey_chart/sankey_chart.dart` | MIT | 2025-05-16 |
| lvsecoto/flutter_common, imfondof/Space, tanwanlanyue1/flutter_test_echarts, abdulkaderTarrabRefaee/echarts3d_surfce_flutter_js | copies of `flutter_echarts` inside apps. The last three come from the file tree only | as `flutter_echarts` | `lib/.../flutter_echarts.dart`, `echarts_script.dart` | various | 2022-2024 |
| `kommon` (pub.dev) | re-exports `flutter_echarts` | as `flutter_echarts` | `lib/kommon.dart:16` | BSD-3-Clause | 2023-09-03 |
| gitlab.com/duong.than/flutter_echarts | mirror of `flutter_echarts` 2.5.0 | as `flutter_echarts` | `pubspec.yaml` | none stated | 2024-03-12 |
| GitCode vae_0223nnz/flutter_echarts | fork of `flutter_echarts`, probably for OpenHarmony Flutter 3.22 | 6.0.0-rc.1 | the last commit "perf: echarts release 6.0.0 rc-1" | as `flutter_echarts` | 2025-09-23 |
| OliverVin/flutter_echarts | fork. Its `pubspec.yaml` drops `webview_flutter`, but `lib/flutter_echarts.dart:11` still imports it | as 2.3.0 | `lib/flutter_echarts.dart:11,160` | as `flutter_echarts` | 2021-11-16 |

About ten more demo apps depend on `flutter_echarts`. Gitee has several mirrors of it. The survey
did not list them one by one.

**Takeaways.** A WebView wrapper is easy to copy. Thus copies spread to Gitee, GitCode and
GitLab. No copy replaced the WebView.

<a id="pkg-options"></a>

## Option models: Dart classes for the JavaScript ECharts

| | |
|---|---|
| Where | [github.com/tomLadder/echarts_options_to_dart](https://github.com/tomLadder/echarts_options_to_dart) and `lib/widget/charts/e_charts/e_charts_bean.dart` of [github.com/yzpIOS/app_yl](https://github.com/yzpIOS/app_yl) |
| Inspected | Both repositories through the GitHub contents API on 2026-10-20 *(no re-check)* |
| Status | `echarts_options_to_dart`: one push on 2019-08-04. `app_yl`: app code |
| Approach | Option model. `echarts_options_to_dart` is a Node.js generator (`src/index.js`, `src/optionNode.js`). It reads `src/data/option.json` and writes `src/Output.dart`, about 15k lines of `json_serializable` classes: `EChartsOption`, `Title`, `Legend`, `Grid`, `XAxis` and more. `EChartsBean` of `app_yl` is a hand-written model with `dataZoom`, `tooltip`, `grid`, `legend`, `xAxis`, `yAxis` and `series` |
| ECharts version | 4.x (the `option.json` of 2019) for the generator. Not stated for `app_yl` |
| Works on | Nothing draws. The JSON goes to a WebView with the JavaScript ECharts |
| License | none |
| Adoption | 0 stars each |

**Takeaways.** The ECharts option schema can generate Dart classes. A typed option API is a later
design question for this port. The ported option model works on the raw option values first, as
upstream does.

<a id="pkg-echartsswift"></a>

## `andy-sheng/EChartsSwift`: a structural port of ECharts 6.1.0 and zrender 6.1.0 to Swift

| | |
|---|---|
| Where | [github.com/andy-sheng/EChartsSwift](https://github.com/andy-sheng/EChartsSwift). The products are `EChartsKit`, `ZRenderKit` and `NativePainter` |
| Inspected | The tree and the key files through the GitHub API on 2026-10-21. A verifier cloned it on 2026-10-20 |
| Status | Active. Created on 2026-06-28. The last push was on 2026-10-19 |
| Approach | Structural port. Each file keeps the upstream path and the upstream names. 489 of the 877 Swift files in `Sources/` have a "Ported from" header *(no re-check)*. `PORTING.md` gives the TypeScript-to-Swift rules. The repository has `.claude/` workflow files for the port *(no re-check of the content)* |
| ECharts version | `upstream/upstream.lock` pins echarts `20ecdf4cae568f31d350a1c547516d08cdcab9b0` and zrender `349111033fba0fa08cee745b72dd2ea66dc6fcaa`. It labels both "6.1.0". The echarts commit is of 2026-05-31, 20 commits after the tag `6.1.0` (`c5a48f5f`). The zrender commit is of 2026-05-26, 6 commits after the tag `6.1.0` (`32b66867`) |
| Works on | iOS 15 and macOS 12 with Core Graphics. Not Dart. The demo target `EChartsDemoCore` uses `WKWebView` for a side-by-side comparison with the JavaScript ECharts. The library does not *(no re-check)* |
| License | None. The repository has no `LICENSE` and no `NOTICE`. GitHub gives no license. Thus all rights stay with the author. The repository also does not carry the notices of ECharts and zrender |
| Adoption (2026-10-21) | 0 stars, 0 forks |
| Re-check | The lock file, the comparison of both pins with the tags, the blob counts (1,376 files. 435 Swift files in `Sources/EChartsKit`, 80 in `Sources/ZRenderKit`, 281 files in `Tests/`), the headers of `poly.swift` and `ZRender.swift`, `poly.swift:54,201`, the license state, the dates |

### How it renders

The verifier found this pipeline *(no re-check)*:

1. `EChartsKit` ports the option model, the data store, the coordinate systems, the components and
   23 chart folders, from bar to treemap.
2. `ZRenderKit` ports the zrender element tree, the storage, the painter and the animation.
   `ZRender.swift` has `refreshImmediately` and `flush`, as `zrender.ts` does.
3. `NativePainter` and `ApplePainterSupport` draw the display list with Core Graphics. They
   measure text with the native text system.
4. `Oracle/` has scripts that dump the display list and the geometry from the JavaScript
   ECharts. The tests compare the Swift output with these JSON fixtures.

### Evidence of the port

- `Sources/EChartsKit/chart/line/poly.swift:1` is
  "// Ported from echarts/src/chart/line/poly.ts — keep in sync with upstream".
- `poly.swift:54` is `private func drawSegment(`, as `echarts@6.1.0 src/chart/line/poly.ts:36`.
- `poly.swift:201` keeps the upstream typo "Reclaculate cp1 based on the adjusted cp0 of next
  seg." of `poly.ts:172`.
- `Sources/ZRenderKit/ZRender.swift:1` is
  "// Ported from zrender/src/zrender.ts — keep in sync with upstream".
- The verifier counted 288,845 Swift lines in `Sources/`: 169,509 in `EChartsKit` and 27,971 in
  `ZRenderKit` *(no re-check)*.

### Limitations

- No license. Its code cannot go into this repository. It is prior art for ideas only.
- The label "6.1.0" names a commit after the release. A reader cannot get the pinned files from
  the version alone.
- Apple platforms only.

### Takeaways for flutter_echarts_port

- A structural port of ECharts 6.1.0 with zrender is possible in about four months with LLM
  workflows. The size is about 200k lines of Swift for the library *(no re-check)*.
- Its method agrees with this repository: a pin file, a header on each file, the upstream names
  and fixtures from the JavaScript ECharts.
- Pin a release tag, or label a commit pin as `<last version>+<sha8>`. This port pins the tag
  commits `c5a48f5f` and `32b66867`.
- Keep the upstream notices from the first ported file.

<a id="pkg-yuecharts"></a>

## `OverflowCat/yuecharts`: an LLM-driven partial port of ECharts to MoonBit

| | |
|---|---|
| Where | [github.com/OverflowCat/yuecharts](https://github.com/OverflowCat/yuecharts) |
| Inspected | The tree, `README.md`, `chart/line.mbt` and `scale/linear.mbt` through the GitHub API on 2026-10-21 |
| Status | Created on 2026-04-17. The last push was on 2026-04-18 |
| Approach | Partial port with a loose structure. The README says: "This is an unofficial, LLM-driven port of ECharts" (`README.md:9`). Each file maps its parts to upstream files with `<=>` comments. No zrender layer and no interaction |
| ECharts version | Not stated in the files that the survey read |
| Works on | MoonBit native and wasm. "A static renderer: input JSON, output SVG." (`README.md:13`). Not Dart |
| License | Apache-2.0 |
| Adoption (2026-10-21) | 3 stars, 0 forks |
| Re-check | `README.md:9,13`, `chart/line.mbt:1,4,44,441`, `scale/linear.mbt:1`, the file counts (214 files, 88 `.mbt` files), the license, the dates |

### Evidence

- `chart/line.mbt:1` is "/// <=> echarts/src/chart/line/LineView.ts".
- `chart/line.mbt:4` is "/// <=> zrender/src/graphic/helper/smoothBezier.ts:smoothBezier".
- `chart/line.mbt:441` maps a function of `echarts/src/component/marker/MarkLineView.ts`.
- `scale/linear.mbt:1` is "// Corresponds to: echarts/src/scale/Interval.ts".
- The verifier found 22 series and the coordinate systems cartesian, polar, parallel, single,
  calendar, geo and matrix *(no re-check)*. The repository has scripts that compare its SVG with
  the JavaScript ECharts *(no re-check)*.

### Takeaways for flutter_echarts_port

- Comments that map a file to its upstream file help a reader. They do not replace the upstream
  file split. Several upstream files in one target file make a diff of an upstream release hard.
- A static SVG renderer covers the option model and the layouts only. This port also ports
  zrender, the interaction and the animation.

<a id="pkg-tycontrols"></a>

## `ACTom/TyControls`: a behavior port of ECharts 6.1.0 to Pascal

| | |
|---|---|
| Where | [github.com/ACTom/TyControls](https://github.com/ACTom/TyControls), the control `TTyAdvanceChart` |
| Inspected | The tree, `README.en.md`, `THIRD-PARTY-NOTICES.md`, `COPYING.modifiedLGPL.txt` and two units through the GitHub API on 2026-10-21 |
| Status | Very active. Created on 2026-06-20. The last push was on 2026-10-21 |
| Approach | Behavior port. 110 units `source/tyControls.AdvanceChart.*.pas` merge several upstream modules each. Unit headers name the upstream functions that they translate |
| ECharts version | 6.1.0 (`source/tyControls.AdvanceChart.LabelOpt.pas:10-11`) |
| Works on | Free Pascal and Lazarus on Windows, Linux and macOS. The controls draw with BGRABitmap (`README.en.md:3,60-64`). Not Dart |
| License | GitHub gives no license. The repository has `COPYING.LGPL.txt` and `COPYING.modifiedLGPL.txt`: LGPL 2.1 or later with a static-link exception. `THIRD-PARTY-NOTICES.md:113-114` credits the gallery options of apache/echarts-examples under Apache-2.0 |
| Adoption (2026-10-21) | 77 stars, 18 forks |
| Re-check | The unit count, `LabelOpt.pas:10-11`, `LinePath.pas:4-5,34`, `README.en.md:32,42,356,417`, the license files, the dates, the counts |

### How it works

- `TTyAdvanceChart` reads an ECharts option as it is (`README.en.md:42`).
- The example loads "the 244 options of the Apache ECharts example gallery". It lists the options
  that it cannot draw, with the reason (`README.en.md:417`).
- `source/tyControls.AdvanceChart.LabelOpt.pas:10-11`: "PORTED FROM echarts/src/label/labelStyle.ts
  (createTextConfig) and echarts/src/util/format.ts (formatTpl), 6.1.0."
- `source/tyControls.AdvanceChart.LinePath.pas:4-5` ports `drawSegment` of `poly.ts` with
  `smooth` and `smoothMonotone`. `TyDrawSegment` is at `LinePath.pas:34`.

### Takeaways for flutter_echarts_port

- The 244 gallery options of apache/echarts-examples are a good smoke corpus for the end of each
  phase. They are Apache-2.0. Their use needs the notice of apache/echarts-examples.
- A list of the options that the port cannot draw, with a reason for each, makes the gaps
  visible. This port keeps the same list in `parity.md` and `differences.md`.
- The LGPL code cannot go into this Apache-2.0 package. It is prior art for ideas only.

<a id="pkg-other-languages"></a>

## Other non-Dart projects

These projects are not ports to Dart. The rows come from the survey of 2026-10-20 *(no
re-check)*. The author read the stars, the push dates and the licenses again on 2026-10-21.

| Project | Language | Approach | License | State (2026-10-21) |
|---|---|---|---|---|
| [wuba/react-native-echarts](https://github.com/wuba/react-native-echarts) | TypeScript, React Native | runs the JavaScript ECharts. It replaces the zrender painter with a Skia or SVG painter. Not a port | Apache-2.0 | 972 stars. Last push 2026-07-06 |
| [Latias94/fret](https://github.com/Latias94/fret) (engine "delinea") | Rust | an engine "inspired" by ECharts, per `docs/adr/0190-delinea-headless-chart-engine.md` and `docs/adr/0192-delinea-axis-scales-and-coordinate-mapping.md`. The survey did not read the Rust source | Apache-2.0 | 5 stars. Last push 2026-07-12 |
| [vicanso/go-charts](https://github.com/vicanso/go-charts) | Go | reads a subset of the ECharts option JSON (`echarts.go:46-290`). Own tick algorithm (`range.go:55-99`). Draws SVG and PNG through `wcharczuk/go-chart` | MIT | archived. 279 stars. Last push 2024-08-15 |
| [ppaanngggg/KCharts](https://github.com/ppaanngggg/KCharts) | Kotlin, skiko | an option-shaped API with own code | GPL-3.0 | archived. 3 stars. Last push 2023-11-28 |
| pyecharts, go-echarts, ECharts-Java, EChartsNet, Blazor.ECharts, SwiftyEcharts, rust-echarts and others | various | option models that feed the JavaScript ECharts | various | not examined one by one |

**Takeaways.** `react-native-echarts` keeps the JavaScript engine and replaces only the painter.
This model needs a JavaScript runtime. [ADR 0001](../../../../docs/adr/0001-native-ports-not-wrappers.md)
and AGENTS.md rule 5 forbid it for this port. KCharts is GPL-3.0. Thus nobody can copy its code
into this repository.

<a id="pkg-ruleouts"></a>

## Ruled out

The survey read the code of these packages. They share a name or a keyword with ECharts or
zrender. They contain no ECharts code.

- **`flutter_echart`** (pub.dev, zhaolongs, 2.0.0 of 2022-04-29): own pie, bar and line charts
  with `CustomPainter` (`lib/src/pie/pie_chart.dart`). The only dependency is Flutter.
  BSD-2-Clause. pub.dev shows `license:unknown`. 11 likes, 69 downloads.
- **`echart_flutter`** (pub.dev, enechain, 0.1.0+2 of 2023-04-04): a native line chart. The "e"
  is the company enechain. MIT. 35 likes, 4 downloads.
- **`flutter_echarts_wrapper`** (pub.dev, tomLadder, 0.0.1 of 2019-08-04): the package template
  `Calculator.addOne` only. `is:dart3-incompatible`.
- **Haedge/E-Charts** (GitHub): painters for a baseball app.
- **lcultx/ZRenderNative** (GitHub, C++, 2016): an SDL game loop template without zrender code.
- **zflutter** (jamesblasco and forks): a port of Zdog. It matched "zrender" as a substring.
- **rlch/recharts-flutter** (GitHub): a native port of Recharts. It matched "echarts" as a
  substring. The [survey of other chart libraries](../../../../docs/prior-art/other-chart-libraries.md)
  covers it.
- **`apexcharts_flutter`** (pub.dev): a native port of ApexCharts 4.7.0, not ECharts.
- **`swm_chart`** (pub.dev, 0.5.0 of 2026-10-21): "a native Dart port of TradingView Lightweight
  Charts", not ECharts.
- **`shadcn_chart`** (a WebView over Recharts), **`nimble_charts`** (a fork of `charts_flutter`),
  **x3_charts_core** (Gitee, own painters) and **lingzipeng/echart** (`fl_chart`): no ECharts
  code.
- **mcxinyu/echarts-android** (Gitee, Kotlin): a WebView for Android, not Dart.
