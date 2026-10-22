# Prior art: Chart.js in Dart and Flutter

Survey date: **2026-10-16**. Numbers that change over time (versions, downloads, likes) are as of
that date.

**Question.** Does a native Dart/Flutter port of [Chart.js](https://www.chartjs.org) already exist,
or are the existing packages wrappers around the JavaScript library? How does each one work?

**Answer.** No maintained native port exists. There is one historical port, [`chart`](chartjs-packages.md#pkg-chart)
(2013-2015). It translated Chart.js **0.2** (pre-1.0), Line and Bar only, to Dart 1 on `dart:html`,
and it can't be used today. Every other Chart.js package runs the real Chart.js JavaScript in one of
three ways:

- in a WebView;
- in a DOM `<canvas>` inside an `HtmlElementView` on Flutter web;
- through JS interop in plain Dart web apps (not Flutter).

## At a glance

| Package | Kind | How it renders | Chart.js | Works on | Status |
|---|---|---|---|---|---|
| [`chart`](chartjs-packages.md#pkg-chart) | **native port** (historical) | its own Dart drawing code on a `dart:html` canvas | 0.2 | browsers, Dart 1 only | last release 2015-03-06; source repo gone |
| [`chartjs_flutter`](chartjs-packages.md#pkg-chartjs_flutter) | Flutter wrapper | WebView with a bundled Chart.js (Android/iOS); `HtmlElementView` + CDN script + `eval` (web) | 4.5.1 (bundled), latest from CDN (web) | Android/iOS only if the app copies the package's assets; web JS builds. macOS, Windows, Linux and `--wasm` do not render | 1.0.0, 2025-11-11 |
| [`js_widget`](chartjs-packages.md#pkg-js_widget) | generic "JS library as a widget" | WebView (Android/iOS); `HtmlElementView` + `eval` (web) | whatever the host loads; the README uses an unpinned CDN URL | Android, iOS, web JS builds. macOS, Windows, Linux and `--wasm` do not render | 1.0.4, 2025-08-12 |
| [`flutter_web_chartjs`](chartjs-packages.md#pkg-flutter_web_chartjs) | Flutter-web wrapper | `HtmlElementView` canvas + JS glue | 2.9.3 | nothing current (pre-null-safety Dart 2) | discontinued; GPL-3.0 |
| [`chart_engine`](chartjs-packages.md#pkg-chart_engine) | JS interop, plain Dart web | bundled Chart.js loaded as a script + JS glue; also ApexCharts | 2.9.4 | browsers (no Flutter integration) | 3.0.0, 2026-10-07 |
| [`chartjs`](chartjs-packages.md#pkg-chartjs) (Google) | JS-interop bindings | generated typings; the host page loads Chart.js | 2.6 | browsers via dart2js/DDC (no Flutter integration) | discontinued; repo archived |
| [`chartjs2`](chartjs-packages.md#pkg-chartjs2) | fork of `chartjs` | same as `chartjs` | 2.6 | same as `chartjs` | one release, 2023-04-11 |
| [`pakhyunw/flutter_chartjs`](chartjs-packages.md#pkg-pakhyunw_flutter_chartjs) | Flutter wrapper, GitHub only | WebView (native); `HtmlElementView` (web) | CDN: 3.9.1, later unpinned | — | never published; dormant |
| [4 GitHub copies](chartjs-packages.md#pkg-chartjs_dart_copies) of `google/chartjs.dart` | copies | same as `chartjs` | 2.x | — | abandoned |

The [completeness pass](chartjs-packages.md#pkg-completeness) found these as well. None is a port:

| Package | Kind | Chart.js | Status |
|---|---|---|---|
| [`ensemble`](chartjs-packages.md#pkg-ensemble) | low-code runtime; its `ChartJs` widget uses a WebView (native) or `js_widget` (web) | v4 from an unpinned CDN | maintained |
| [`URBAN-CONNECTIONS/chartjs_flutter`](chartjs-packages.md#pkg-urban_chartjs_flutter) | Flutter-web `<iframe>` wrapper, GitHub only (its name is taken on pub.dev) | latest from CDN | unpublished; stale |
| [`json_render`](chartjs-packages.md#pkg-json_render) | JSON-to-DOM renderer, web only; charts via `chart_engine` 2.1.x | 2.9.4 | stale since 2024-02-15 |
| [`pyrlyn/bindsmith`](chartjs-packages.md#pkg-bindsmith) | generated `dart:js_interop` bindings for a small 4.x subset (example) | 4.4.7 | unpublished; work in progress |
| [`dash_panel`](chartjs-packages.md#pkg-dash_panel) | Jaspr server-rendered admin panel; Dart builds the config, the browser runs Chart.js | 4.4.1 | stale |
| [`stream_chat_flutter_ai`](chartjs-packages.md#pkg-stream_chat_flutter_ai) | AI-chat UI kit that reads a small subset of Chart.js JSON and draws it with fl_chart | none (no JS) | new (2026-09-24) |
| [`modern_charts`](chartjs-packages.md#pkg-modern_charts) | independent `dart:html` canvas library; its easing table derives from `chart` | none | archived; Dart 2 only |

Six more leads (a fork, a mirror, two apps, a demo and Dart 1-era typings) are
[listed but were not inspected](chartjs-packages.md#pkg-leads).

[Ruled out](chartjs-packages.md#pkg-ruleouts) after inspection:
- `highchartjs` wraps Highcharts.
- `m4d_spa` is single-page-app plumbing; only a sample app in it uses Chart.js bindings.
- `reactspring/flutter_js_chart` is a renamed copy of fl_chart.
- `js_widget_runtime` is a JS-to-Flutter-widgets runtime whose charts are fl_chart.
- `tyto` is a benchmarking library that writes an HTML report using Chart.js.

## Pages

- [Chart.js packages](chartjs-packages.md): every package above, from the Dart API down to the
  pixels: where Chart.js comes from, the bridge, the API, and limitations.
- [Running real Chart.js without a WebView](js-runtimes.md): WebF, Kraken, flutter_fjs and other
  JS engines embedded in Flutter. None ships or demos Chart.js. Their Canvas 2D implementations
  are useful prior art.
- [Other JavaScript chart libraries](../../../../docs/prior-art/other-chart-libraries.md): ECharts, Highcharts, Plotly, Vega and
  others are wrapped too. Native ports exist only for ApexCharts (`apexcharts_flutter`), Recharts
  (GitHub only) and D3 building blocks (`d4_*`).
- [forui theming](forui-theming.md): how forui builds, finds, overrides and animates its theme,
  and which ideas the chart theme takes.

## How the survey was done

1. **pub.dev search.** 12 queries (`chartjs`, `chart.js`, `"chart.js"`, `chartjs flutter`,
   `chartjs webview`, `chartjs port`, …), each also run with `is:unlisted` and `show:discontinued`.
   That gave about 260 candidate names, mostly icon packs and unrelated chart libraries. Their
   pub.dev pages were then searched for Chart.js mentions, which left 10 packages. Two of those
   turned out unrelated: `highchartjs` (Highcharts) and `sate_ai` (a CLI that writes HTML reports).
   One more, `js_widget_runtime`, surfaced through search alone and was inspected too.
2. **GitHub.** Repository search (Dart) for Chart.js terms, plus code search in Dart files for
   identifiers that only a port of Chart.js internals would contain. The repository search found
   the GitHub-only candidates (`pakhyunw/flutter_chartjs`, the `google/chartjs.dart` copies,
   `reactspring/flutter_js_chart`). The code search covered `LinearScaleBase`,
   `DatasetController`, `PolarAreaController`, `DoughnutController`, `RadialLinearScale`,
   `resolveDataElementOptions`, `TimeSeriesScale`, `getRelativePosition`, `alignPixel`. The hits
   were JS-interop typings and unrelated app code (for example `DatasetController` classes in
   apps). No Dart re-implementation of Chart.js turned up.
3. **Source inspection.** For every candidate, the published archive (or repository) was downloaded
   and read statically, tracing the public API to the pixels on each platform. A second,
   independent pass then tried to refute each finding, and its corrections are applied here
   (for example, macOS turned out to be broken in both current Flutter wrappers).
4. **Completeness pass.** A separate search, deliberately using different methods:
   - pub.dev reverse dependencies, sort orders past the 100-result cap, topics, and about 80
     probed names;
   - GitHub search without a language filter, topics, code search for Chart.js option names,
     internals, CDN and bundle markers and attribution strings;
   - all 57 forks of `google/chartjs.dart`, and archived repositories;
   - GitLab, Codeberg and Gitee, Hacker News, Stack Exchange, and web search (including
     non-English queries).

   It found 14 more leads. Eight were inspected and re-verified as in step 3; six are listed as
   not inspected. None is a native port.
5. **Landscape.** JS runtimes embedded in Flutter and the other popular JS chart libraries got a
   lighter, single-pass check.

## What it means for `flutter_chartjs_port`

- **There is no competition.** Every Chart.js option usable from Flutter today is a WebView or
  platform view with a JSON-only bridge. That means no Dart callbacks or scriptable options, few
  or no events, no Flutter goldens or theming, and broken WebAssembly builds. That is the case
  for a native port ([ADR 0001](../../../../docs/adr/0001-native-ports-not-wrappers.md)).
- **Nothing to fork.** No package contains reusable Dart implementations of Chart.js scales,
  layout, controllers or elements. The port is translated from upstream v4.5.1 directly.
- **Raw Chart.js configs are worth accepting.** Several packages take an untyped Chart.js config,
  and one draws Chart.js JSON natively: `stream_chat_flutter_ai`, for charts in AI chat, but only
  a small subset of it. A native port that accepts raw Chart.js JSON alongside a typed Dart API
  covers that case completely.
- **Worth studying:**
  - the Canvas 2D-on-`dart:ui` code in flutter_fjs (MIT) and Kraken (Apache-2.0). WebF's newer
    canvas code is GPL-3.0, so ideas only;
  - `chart_engine`'s Dart implementation of the Chart.js date-adapter contract (Apache-2.0);
  - `chartjs_flutter`'s WebView harness running Chart.js 4.5.1, as a reference renderer for visual
    comparisons.
- **Names.** `chart`, `chartjs`, `chartjs2` and `chartjs_flutter` are taken
  ([ADR 0003](../../../../docs/adr/0003-package-names.md)).
