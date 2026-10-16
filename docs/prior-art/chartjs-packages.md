# Chart.js packages for Dart and Flutter

How each Chart.js-related package on pub.dev and GitHub works, from the Dart API it exposes down
to where the pixels come from. Part of the [prior-art survey](README.md) of 2026-10-16. Facts that
change (versions, downloads, likes, stars) are as of that date.

Each package was inspected from its published archive or repository (static reading, nothing
executed), and a second, independent pass tried to refute every finding. Where the two disagreed,
the corrected version is given. Evidence lines cite `path:line` inside the inspected package.

Terms used below:

- **Native port**: Chart.js logic re-implemented in Dart; no Chart.js JavaScript runs.
- **JS interop**: Dart bindings that call the real Chart.js in a browser page.
- **Platform view**: a DOM element (canvas, div, iframe) hosted in Flutter web through `HtmlElementView`.
- **WebView**: an HTML page running real Chart.js inside a native WebView on Android/iOS/desktop.

Packages: [`chart`](#pkg-chart) · [`chartjs_flutter`](#pkg-chartjs_flutter) · [`js_widget`](#pkg-js_widget) ·
[`flutter_web_chartjs`](#pkg-flutter_web_chartjs) · [`chart_engine`](#pkg-chart_engine) ·
[`chartjs`](#pkg-chartjs) · [`chartjs2`](#pkg-chartjs2) · [`pakhyunw/flutter_chartjs`](#pkg-pakhyunw_flutter_chartjs) ·
[copies of `google/chartjs.dart`](#pkg-chartjs_dart_copies) · [ruled out](#pkg-ruleouts)

<a id="pkg-chart"></a>

## `chart`: partial native port of Chart.js 0.2 to Dart 1 / dart:html, unusable today

| | |
|---|---|
| Where | [pub.dev/packages/chart](https://pub.dev/packages/chart), by Symcon GmbH (Tim Rasim); the listed Bitbucket repository returns HTTP 404 |
| Inspected | 1.0.8, published 2015-03-06 (0.1.0, 0.3.7 and 1.0.0 also checked) |
| Status | Legacy, abandoned: 34 versions from 2013-05-13 to 2015-03-06, none since (as of 2026-10-16); pub.dev labels it "Dart 1 only" |
| Approach | Web: native Dart port drawing on dart:html `CanvasRenderingContext2D`, no JS interop. Flutter, Dart VM, dart2wasm: none |
| Chart.js | 0.2, pre-1.0 (commit 7a55a16, 2013-04-12). No Chart.js JS is bundled, fetched or required; the archive's only JS file is dart2js output of the port |
| Works on | Nothing current: it ran in browsers on Dart 1; on Dart 2 and 3 it neither resolves nor compiles |
| License | MIT: Chart.js's license (Nick Downie) verbatim, with a Symcon copyright notice prepended; pub.dev shows `license:unknown` (file not recognised) |
| Adoption (2026-10-16) | 0 likes, 5/160 pub points, 153 downloads in 30 days; no GitHub repository |

### How it renders

1. `new Line(data, config)` (or `Bar`, `Bool`) runs the abstract `DartChart` constructor, which creates a visible `CanvasElement` and three offscreen layer canvases with 2D contexts.
2. `show(parent)` sizes the canvases once from the parent and appends the visible one.
3. `setScale()` measures labels (`calculateDrawingSizes`), picks a 1-2-5 scale (`calculateScaling`) and formats ticks (`populateLabels`); `calculateXAxisSize()` sets the axis geometry.
4. `animationLoop()` runs on `window.requestAnimationFrame`. Each `animateFrame()` eases progress, clears, and redraws the layers through `drawChart(pct)` (`Line.drawLines`, `Bar.drawBars`, `Bool.drawBoolLines`), `drawScale()` and `drawTitle()`.
5. `drawImage(layer, 0, 0)` composites the layers in `scaleOverlay` order; the browser's Canvas 2D implementation produces the pixels.

### What was ported

`lib/` holds 1,987 lines. Roughly 850-900 of them, a little under half, translate parts of the 1,426-line Chart.js v0.2.0 file:

- **Translated:** `calculateOffset` and `CapValue` (line for line), `calculateDrawingSizes`, Bar's width and offset geometry, the HiDPI block, the animation loop, most 0.2 defaults, all 31 Penner easings, and (modified) Line's `drawScale`.
- **Symcon's own:** the tick algorithm (`calculateScaling`, `getNiceMinValue`, `calculateStepSize`), most of Line's axis sizing, a path engine for `null` gaps and sub-points, the layer canvases, titles, and the Bool step chart (401 lines).
- **Not ported:** Pie, Doughnut, PolarArea, Radar and the templating.

0.1.0 (2013-05-13) was a literal transliteration; by 0.3.x Symcon had replaced the scale code, and 1.0.0 (2014-11-03) added Bool.

### Bridge

None: no Chart.js JS runs, and `data`/`config` are Dart `Map`s. Nothing comes back: no mouse or touch handling, tooltips or hover, and `onAnimationComplete` is never called. The one working callback is `scaleLabel`, a Dart closure for y-axis tick text that replaces upstream's `<%=value%>` template.

### API

Untyped `Map`s mirroring 0.2: `new Line(Map data, Map config)`, then `show(Element parent)`/`hide()`; no `update()`, `destroy()` or resize. `data` keeps the 0.2 shape (`labels`, `datasets` with `fillColor`, `strokeColor`, `data`). `config` uses 0.2 option names, with the step keys swapped for `scaleMinValue`, `scaleMaxValue` and others, plus title keys; unknown keys only print a warning. Coverage: Line and Bar (2 of 0.2's 6 types) plus Bool; against v4, negligible.

### Limitations

- **No current SDK can use it.** No version declares an SDK constraint, so pub treats it as Dart 1 only and pana on Dart 3.13.5 cannot resolve it. The code lacks null safety, uses APIs absent from Dart 3 (`double.NEGATIVE_INFINITY`, `math.PI`, `new List()`), and needs the discontinued `browser` package (SDK <2.0.0).
- **Browser-only via dart:html**, deprecated in favour of package:web and unsupported by dart2wasm; no Flutter code.
- **Pre-1.0 architecture:** none of v4's controllers, elements, scale classes, layout boxes or plugins.
- **No interactivity, legend (Bool aside), resizing or updates.**
- **Bugs:** x-labels never rotate (the computed angle is discarded); offscreen layers skip HiDPI scaling, so output blurs on HiDPI screens; `easeInBounce` runs `easeInBack`.
- **No source repository:** the Bitbucket repository is deleted and the uploader is unverified.

### Takeaways for flutter_chartjs

- Little is reusable: Dart 1 code in 0.2's single-file design. Its overlap with v4 (Penner easings, nice-number ticks) is better ported from v4's `helpers.easing.ts` and `niceNum`/`generateTicks`.
- MIT, but copies must keep both the Nick Downie and Symcon notices; porting v4.5.1 (MIT) directly is cleaner.
- The rotation bug is a transliteration hazard to test for: upstream's shared closure variable became a shadowing parameter.
- The pub.dev name `chart` is taken.

Evidence: `lib/src/base.dart:4` (port header), `lib/src/base.dart:420` (translated `calculateOffset`), `lib/src/base.dart:492` (frame drawing), `pubspec.yaml:9` (no SDK constraint)

<a id="pkg-chartjs_flutter"></a>

## `chartjs_flutter`: WebView and HtmlElementView wrapper around Chart.js (ships 4.5.1), not a port

| | |
|---|---|
| Where | [pub.dev](https://pub.dev/packages/chartjs_flutter) (publisher digia.tech), [GitHub](https://github.com/Digia-Technology-Private-Limited/chartjs_flutter) |
| Inspected | 1.0.0, the only release (2025-11-11, commit `3db859ea7b`), and unreleased `main` at `aa612e19cf` (2025-12-26) |
| Status | Stale: no commits since 2025-12-26; issue #3 (opened 2026-04-08) unanswered as of 2026-10-16. Not discontinued or unlisted. |
| Approach | Web (dart2js): platform view (`HtmlElementView`) plus one `@JS('eval')` binding. `dart.library.io` targets: WebView (`webview_flutter`). dart2wasm: stub. No Dart chart logic. |
| Chart.js | Ships the official v4.5.1 `chart.umd.min.js` (reformatted only; includes @kurkle/color 0.3.2) but never reads it: Android/iOS load app-level `assets/...` keys, i.e. the app's own copies; web injects the unpinned `https://cdn.jsdelivr.net/npm/chart.js` (4.5.1 as of 2026-10-16). |
| Works on | Without setup, only web (dart2js) with jsDelivr reachable. Android/iOS: only after the app copies both asset files into its own `assets/` (else an endless spinner). macOS: never renders. Wasm output: stub (dart2js fallback works). Windows/Linux: no official WebView backend. pub.dev's `platform:macos` and `is:wasm-ready` tags reflect imports only. |
| License | MIT (2025 Tinkerbox Technology Private Limited) since `3db859ea7b`; earlier commits had no license file, then BUSL-1.1. Bundled Chart.js and @kurkle/color: MIT. |
| Adoption (2026-10-16) | pub.dev: 5 likes, 160/160 points, 53 downloads/30 days. GitHub: 3 stars, 1 fork. Main dependent: the publisher's `digia_ui` (338 downloads/30 days). |

### How it renders

1. A conditional export in `lib/chartjs_flutter.dart` resolves `ChartJsWidget(chartConfig: {...})` to the web implementation (`dart.library.html`), the WebView one (`dart.library.io`) or a stub.
2. Web (dart2js):
   - `initState` registers a `platformViewRegistry` factory that creates an `HTMLCanvasElement`, and `loadScript()` appends the CDN `<script>`.
   - After a fixed 500 ms delay, `_renderChart()` runs `new Chart(ctx, <jsonEncode(chartConfig)>)` through `eval`, keeping the instance on `window`.
   - `HtmlElementView` shows the canvas Chart.js draws into; the browser composites it with Flutter's output.
3. Android/iOS:
   - `_initWebView()` loads `assets/chart_template.html` (a `<canvas>`, `createChart()`, `isChartAvailable()`) via `WebViewController.loadHtmlString`.
   - `onPageFinished` injects `assets/chart.umd.min.js` with `runJavaScript`; `_createChart()` polls `isChartAvailable()` (up to 30 times, 200 ms apart), then calls `createChart(<json>)`.
   - Android WebView or WKWebView draws inside a `WebViewWidget` platform view, covered by a spinner until loaded.
   - macOS takes this path, but `setBackgroundColor` throws `UnimplementedError` synchronously before `loadHtmlString`, so nothing loads.

### Bridge

One-way JSON from Dart to JS: spliced into `eval`ed source on web, passed to `createChart()` on mobile. Only the polled `isChartAvailable()` result comes back. With no `JavaScriptChannel` or `toJS` callback, clicks, hover and legend events never reach Dart, and JS errors only reach the console (mobile) or surface as uncaught async errors or Flutter build errors (web). `jsonEncode` rejects closures and string-encoded functions are not revived, so per-chart scriptable options and callbacks are impossible.

### API

One widget, `ChartJsWidget({Key? key, required Map<String, dynamic> chartConfig})`, forwarding an untyped Chart.js config: no typed models, validation, controller, imperative methods (`update`, `destroy`, `toBase64Image`), events or theming. The UMD build registers all 8 chart types, 6 scales and the core plugins, but includes no date adapter, so `time`/`timeseries` axes fail; adapters and plugins can be added only globally (`web/index.html`, the app's copied assets), never per chart. The raw-Map shape serves `digia_ui`, which forwards server-driven JSON.

### Limitations

- Not a port: Chart.js JavaScript does all layout and drawing in a browser or WebView; charts are platform views, so no `flutter_test` goldens, Flutter theming or semantics.
- Out of the box only web (dart2js) renders: Android/iOS read asset keys without the `packages/chartjs_flutter/` prefix (the README's `packages/...` pubspec entries break the build, issue #3), and Wasm misses its branch because the export tests `dart.library.html`, not `dart.library.js_interop`.
- By default, web depends on jsDelivr, a CSP allowing it and `'unsafe-eval'`, and an unpinned version; a fixed 500 ms wait with no onload handling or retry leaves the chart blank on a slow CDN.
- One-way bridge: no events, and no per-chart callbacks, scriptable options or plugins.
- 1.0.0 compares the config `Map` by identity: each new Map destroys and recreates the chart (no animated update), and in-place mutation is ignored. Unreleased HEAD adds `chart.update()` but corrupts the template's `<canvas>` tag.
- No `dispose()`: on web, `window.chartInstance_*` globals and view factories persist.

### Takeaways for flutter_chartjs

- Accept a raw Chart.js config as `Map<String, dynamic>` next to typed models, so existing and server-driven configs work unchanged.
- Its harness pattern (`HtmlElementView` or WebView running `createChart(json)`) with the official 4.5.1 build, our target, can serve as a reference renderer for pixel-diff tests, and its README/example configs as test inputs. Only commits from `3db859ea7b` on are MIT; keep the attribution.
- A native port must cover what a JSON bridge cannot: Dart closures for scriptable options and callbacks, synchronous in-process rendering, no dependence on network, CSP or Wasm flags, events in Dart, and golden tests.
- Gate web-only code on `dart.library.js_interop`, and load package assets through `packages/<name>/...` keys.

Evidence: `lib/chartjs_flutter.dart:40`, `lib/src/web/chart_js_widget_web.dart:115`, `lib/src/mobile/chart_js_widget_mobile.dart:120`, `lib/src/mobile/chart_js_widget_mobile.dart:130`

<a id="pkg-js_widget"></a>

## `js_widget`: Generic "any JS library as a widget" host from EnsembleUI; Chart.js is the README example

| | |
|---|---|
| Where | [pub.dev/packages/js_widget](https://pub.dev/packages/js_widget); source in [EnsembleUI/ensemble `packages/js_widget`](https://github.com/EnsembleUI/ensemble/tree/main/packages/js_widget) (moved from `modules/js_widget` on 2026-06-29; the repository link on pub.dev is a 404) |
| Inspected | 1.0.4 (2025-08-12); upstream `main` differs only in a comment, the repository URL and READMEs |
| Status | Stale: no release since 2025-08-12, not discontinued. Still used by Ensemble's ChartJs widget on web |
| Approach | Web (dart2js/DDC): platform view (`HtmlElementView`) plus global `eval`. Android/iOS: WebView (webview_flutter). Desktop and wasm: none. Generalized from the Highcharts wrapper high_chart |
| Chart.js | Not bundled or versioned; effectively v4 (UMD global `Chart`). Android/iOS: `<script src>` tags from `scripts`; README and example use the unpinned `https://cdn.jsdelivr.net/npm/chart.js` (4.5.1 on 2026-10-16). Web: `scripts` is ignored; the host page must load Chart.js (Ensemble vendors 4.4.7) |
| Works on | Android, iOS; web JS builds whose `index.html` loads Chart.js (the package's own example does not). Fails at runtime on macOS (webview_flutter_wkwebview's `setOpaque` throws `UnimplementedError`) and Windows/Linux (no webview_flutter implementation by default); the wasm variant of web builds shows "JsWidget: UnSupported Platform" |
| License | BSD-3-Clause (the README says MIT); Chart.js, loaded at runtime, is MIT |
| Adoption (2026-10-16) | 0 likes, 160/160 points, 929 downloads (30 days); host monorepo EnsembleUI/ensemble: 152 stars |

### How it renders

1. The app builds `JsWidget(id, createHtmlTag, data, scriptToInstantiate, size, ...)`, which `lib/js_widget.dart` exports conditionally: web (`dart.library.html`), mobile (`dart.library.io`) or a stub.
2. Web (dart2js/DDC):
   - `initState()` calls `ui_web.platformViewRegistry.registerViewFactory(id, ...)`, whose factory returns `html.Element.html(createHtmlTag())`; `build()` returns `HtmlElementView(viewType: id)` in a `SizedBox(size)`.
   - After a fixed 250 ms delay, `eval(scriptToInstantiate(data))` (a `@JS('eval')` binding) runs the caller's `new Chart(...)` in the global scope; Chart.js draws on the DOM `<canvas>`, composited by the browser.
3. Android/iOS:
   - `instantiateController()` creates a `WebViewController` and calls `loadHtmlString(getHtmlContent())`: the markup plus a `<script src>` per `scripts` entry.
   - `onPageFinished` triggers `runJavaScript(scriptToInstantiate(data))`; Chart.js draws in the native WebView, shown by `WebViewWidget`.
4. Desktop takes the mobile branch and fails in `initState()`; dart2wasm gets the `Text` stub.

### Bridge

- **Dart to JS:** the caller's `scriptToInstantiate` splices the opaque `data` string, unescaped, into JS source, so scriptable options and callbacks work, but only as JS functions. `evalScript(String)` runs raw JS on web and has been a no-op on mobile since 1.0.0+1; no handle to the `Chart` instance is kept.
- **JS to Dart:** web only: `window.handleMessage(id, msg)` passes fire-and-forget strings to `listener`. Mobile has no `JavaScriptChannel`.
- **Ensemble's ChartJs widget** uses `JsWidget` on web, managing the chart in a JS global itself and sending click payloads through `handleMessage`; on mobile it uses webview_flutter directly, with its own `messageHandler` channel.

### API

- One untyped widget, `JsWidget({id, createHtmlTag, data, scriptToInstantiate, size, loader, scripts, listener, preCreateScript})`, plus `evalScript`. There is no model of chart types, datasets, scales, plugins or options.
- `createHtmlTag` and `scriptToInstantiate` are bare `Function`s called dynamically, so errors surface at runtime: the README's zero-argument `scriptToInstantiate` throws `NoSuchMethodError`. `example/lib/main.dart` shows the working contract (full markup with a `<canvas id>`, one-argument closure).
- `size` is fixed, ignoring parent constraints. The web constructor is not `const`, so `const JsWidget(...)` fails only on web.

### Limitations

- Not a port: Chart.js draws on a DOM canvas or in a native WebView per chart, with no Flutter theming, semantics or golden tests, plus platform-view cost and z-order/gesture issues.
- Desktop fails at runtime, although the README says it shows an "unsupported platform message"; wasm shows only the stub despite pub.dev's `is:wasm-ready` tag.
- Web: caller strings are `eval`'d in the app's origin (an XSS risk with untrusted data), and `Element.html` strips `<script>` and inline `style` from the markup.
- Web: the 250 ms delay races view insertion, with no ready or error signal; any `data`, `size`, `scripts` or `loader` change (lists and widgets by identity) re-runs the script, and Chart.js v3+ throws "Canvas is already in use" unless the script destroyed the old chart (`dispose()` never does).
- Mobile: `listener` and `preCreateScript` do nothing; a `data` or `size` change reloads the page and its scripts.
- Mobile: unpinned CDN (network needed, version drift), possibly out-of-order scripts (`async="false"` is still async), and Android WebView debugging on in release builds.

### Takeaways for flutter_chartjs

- Nothing to reuse: `lib/` is 392 lines of Dart that assemble HTML/JS strings.
- Ensemble's ChartJs widget shows the minimum API real users need: imperative `addLabels`/`addData`/`setData`/`update` and tap events (`label`, `value`, `datasetLabel`, `datasetIndex`, `index`, `x`, `y`, `chartType`). It also loads chartjs-plugin-annotation.
- Real Chart.js 4.5.1 hosted this way can render reference images for pixel-diff tests of the Dart port.
- Pitfalls to avoid: untyped `Function`/`String` config, fixed-delay init, string-built JS, no chart lifecycle, an unpinned CDN.

Evidence: `lib/js_widget.dart:1`, `lib/src/web/js_widget.dart:111`, `lib/src/web/js_widget.dart:133`, `lib/src/mobile/js_widget.dart:72`

<a id="pkg-flutter_web_chartjs"></a>

## `flutter_web_chartjs`: Discontinued Flutter-web `HtmlElementView` wrapper around Chart.js 2.9.3 (GPL-3.0)

| | |
|---|---|
| Where | [pub.dev/packages/flutter_web_chartjs](https://pub.dev/packages/flutter_web_chartjs), [github.com/vramosx/flutter_web_chartjs](https://github.com/vramosx/flutter_web_chartjs) |
| Inspected | 0.2.5 (latest stable), published 2020-03-20. The 0.2.6-beta prerelease (2020-05-22) has the same `lib/` and Chart.js; besides pubspec metadata, the CHANGELOG and a removed `main-bck.dart`, only the JS glue changed. |
| Status | Discontinued on pub.dev, no replacement named; no release or code commit since 2020-05-22. The repo is not archived; its last push (2022-11-10) added a README banner with the author's reason: "Flutter Web is currently fast enough to handle charts natively, so maintaining this package no longer makes sense." |
| Approach | Web: platform view (`HtmlElementView`) plus JS interop (`package:js`) to a hand-written JS glue class. Android, iOS, desktop: no implementation. Not a native port. |
| Chart.js | 2.9.3 (UMD). A byte-identical copy of the npm build ships as `js/chart.min.js` but is never loaded: the app adds `<script>` tags, which the README points at the author's repo via jsDelivr, pinned to git tag `v0.2.5-alpha` (the example uses unpinned `@master`). |
| Works on | Web only, and in practice only with the HTML renderer up to Flutter 2.2.x. Charts do not render under CanvasKit (the `auto` default on desktop browsers since Flutter 2.0), and Flutter 2.5 removed the shadow root the glue searches (both read from engine source, not executed). Not on Dart 3, WASM or native targets. |
| License | GPL-3.0 (package). Bundled `js/chart.min.js`: Chart.js, MIT. |
| Adoption (Oct 2026) | pub.dev: 6 likes, 40/160 points, 33 downloads in 30 days. GitHub: 7 stars, 4 forks, 2 open issues. |

### How it renders

1. The app's `web/index.html` loads Chart.js and the glue `chartjs.wrapper.utils.min.js`; the plugin registrar `FlutterWebChartjsPlugin.registerWith` is empty.
2. For `ChartJS(id:, config: ChartConfig(...))`, `_ChartJSState.build()` (via `registerContent()`) registers a `dart:html` `<div><canvas id=...>` with `ui.platformViewRegistry.registerViewFactory('ChartJS-<id>', ...)` and returns `HtmlElementView(viewType: 'ChartJS-<id>')`.
3. After the first frame, and whenever a new `ChartConfig` instance arrives, `updateChart()` JSON-encodes the config and calls `showChart` on the `@JS('chartJSWrapperPlugin')` binding.
4. The glue polls every 500 ms for a `<flt-platform-view>`, then for `#<id>` in each one's `shadowRoot`, destroys any previous instance and runs `new Chart(ctx, config)`.
5. Stock Chart.js does all layout, scales, drawing, animation and hit-testing on that canvas; the browser composites it as a platform view. No Dart code computes or paints chart geometry.

### Bridge

- Dart to JS: the whole config as one JSON string per update (`Color` as `rgba()`, enums as strings). The glue converts two markers: a `LinearGradient` becomes a `CanvasGradient` fixed at 0-400 px vertically, and `ticks.format` `'{value}'` templates become `ticks.callback`. Apart from that template and the label callback below, there are no scriptable options.
- Every update destroys and re-creates the chart, replaying the animation. `ChartConfig` has no `==` and the README builds it in `build()`, so every parent rebuild is an update.
- JS to Dart: only `tooltips.callbacks.label`, which gets the tooltip item as JSON and returns the user's string synchronously. No click, hover or legend events, and no chart handle in the API (instances sit in the global `window.chartJSObjects`).

### API

A typed, pre-null-safety model in `lib/chartjs.models.dart` (18 classes, 11 enums) covers a small slice of the Chart.js 2.9 config, though the README says "every configuration of ChartJS exists in this package". Datasets have only `data`, colors, `label` and `fill`; options cover legend, title, `responsive`, scales, padding, animation and tooltips. There is no `borderWidth`, point styling, tension, `onClick`, plugins, scatter type, or `display` on ticks and axes (open issue #10).

### Limitations

- Does not resolve on Dart 3 (Flutter 3.10+): the SDK lower bound is below 2.12, so pana fails (40/160 points). No WASM.
- Web only, and tied to Flutter web DOM internals that later changed (see Works on).
- Emits Chart.js 2 option shapes (`xAxes`/`yAxes`, `gridLines`, root-level `tooltips`/`legend`/`title`) that Chart.js 3 and 4 renamed or moved.
- Scripts load from the author's repo via jsDelivr. In issue #7 the author advised switching the glue URL to `@master`; the README's `@v0.2.5-alpha` pin lacks PR #9's Edge Legacy/Safari fix, and the README's setup never mentions the moment.js that time axes need.
- No `dispose()`, so chart instances are never destroyed when the widget leaves the tree; each `showChart` call also leaves a never-ending 500 ms poll in every other platform view. A changed `width`/`height` never reaches the canvas.
- Serialization bugs: exact `runtimeType` color checks make `Colors.redAccent` throw as `backgroundColor`; a gradient `borderColor` is read from `backgroundColor`.
- Without a label callback, dart2js release builds likely throw in `js.allowInterop(null)` (inferred, not executed; consistent with open issue #11 about production builds, but not confirmed as its cause).

### Takeaways for flutter_chartjs

- The author's reason (see Status) and the breakage when Flutter web changed how it hosts platform views both argue for a native port.
- The headline feature, a Dart tooltip-label callback, needed a JSON round trip. In a native port, callbacks and scriptable options are plain Dart closures and should be first-class.
- No code to reuse: Dart holds no rendering or layout logic, the model uses v2 option names, and GPL-3.0 rules out copying it into a permissively licensed port. Ideas such as enums for string-literal options and mapping `Color`/`LinearGradient` to canvas styles carry over.

Evidence: `lib/chartjs.wrapper.dart:132`, `lib/chartjs.wrapper.dart:104`, `js/chartjs.wrapper.utils.js:42`, `js/chart.min.js:2`

<a id="pkg-chart_engine"></a>

## `chart_engine`: JS-interop wrapper for plain Dart web apps (not Flutter) over bundled Chart.js 2.9.4 and ApexCharts 3.26.0

| | |
|---|---|
| Where | [pub.dev/packages/chart_engine](https://pub.dev/packages/chart_engine), [github.com/Colossus-Services/chart_engine](https://github.com/Colossus-Services/chart_engine) |
| Inspected | 3.0.0, published 2026-10-07; its files match GitHub master HEAD (tag v3.0.0), pushed the same day |
| Status | Maintained on the Dart side: 3.0.0 on 2026-10-07 (package:web migration), earlier releases in February 2025 and on 2024-02-15. Stale on the Chart.js side: 2.9.4, an October 2020 release, unchanged since 2021-05-28. |
| Approach | Plain Dart web: JS interop (`dart:js_interop`, package:web) calling bundled JS glue that runs Chart.js on a DOM `<canvas>`. Flutter web: no widget or HtmlElementView. Android, iOS, desktop, VM: unsupported. |
| Chart.js | 2.9.4, bundled (byte-identical to npm `chart.js@2.9.4`). amdjs loads `packages/chart_engine/chartjs-2.9.4/Chart.min.js` at runtime through RequireJS or an injected `<script>`; no CDN or host-page tag. |
| Works on | Browser builds of plain Dart web apps: dart2js, DDC and dart2wasm when `onClick` is unset (CI's browser tests use dart2js only). With `onClick`, only DDC works: dart2js throws on click, dart2wasm before rendering. Nothing for Flutter, the VM or native targets. |
| License | Apache-2.0 for its own Dart and JS glue (unfilled LICENSE template); bundled Chart.js 2.9.4, chartjs-chart-financial (v2 build) and ApexCharts 3.26.0 are MIT |
| Adoption (2026-10-16) | 50 likes, 160/160 pub points, 1,625 downloads (30 days); 23 GitHub stars |

### How it renders

Only the browser has a code path.

1. `load()`, scheduled by the `ChartEngineChartJS()` constructor, runs once per page and calls `AMDJS.require('chartjs', ...)`, which uses RequireJS if present and otherwise appends an async `<script>` to `<head>`.
2. It then loads `chart_engine_wrapper.js`, which defines `window.__ChartEngine_Wrapper_ChartJS__`, registers a vertical-line plugin and, without moment.js, overrides `Chart._adapters._date`. Dart reads the wrapper with `globalContext[...]`.
3. `renderLineChart(HTMLElement, ChartSeries)` reuses or appends a package:web `HTMLCanvasElement` and calls `callMethodVarArgs('renderLine'.toJS, args.map((e) => e.toJSDeep))`.
4. JS `renderLine` builds a v2 config (`configure('line', ...)`) and calls `new Chart(ctx, config)`.
5. Unmodified Chart.js 2.9.4 lays out and draws on the 2D context; glue plugins add vertical lines and the gauge's center text.
6. The chart returns as an opaque `JSObject` in `RenderedChartJS`; `refresh()` calls `chart.update()`.

Other chart types take the same path. `ChartEngineApexCharts` renders SVG into a `<div>` with `new ApexCharts(div, options).render()`, and `ChartEngineSwitchable` delegates to the selected engine.

### Bridge

- **Dart to JS:** positional arguments (canvas, titles, data with dates as epoch ms, colors, the onClick closure) are converted by `toJSDeep`; the glue builds the whole Chart.js config.
- **JS to Dart, dates:** the overridden adapter calls `Function.toJS` closures over the Dart `DateAdapter`. This works on all compilers.
- **JS to Dart, clicks:** the glue maps v2 element internals (`_datasetIndex`, `_index`) to `{datasetIndex, index, value, label}` and calls the Dart closure. That closure crosses through `jsify()` without `.toJS` or `allowInterop`, hence the compiler-specific failures.
- **Scriptable options:** none; the only config functions are hard-coded in the glue.

### API

Engine-agnostic and imperative, with a typed data model instead of a Chart.js config model. The abstract `ChartEngine` has `render(HTMLElement, ChartData)` and eight `render*Chart` methods (line, time series, bar, horizontal bar, gauge, scatter, timed scatter, financial), all but the financial one with `*Async` variants. Data comes as `ChartSeries`, `ChartSeriesPair`, `ChartTimeSeries` or `ChartSet`, with about a dozen options (axis bounds, vertical lines, onClick, line styles). `RenderedChartJS` offers `refresh()`, `addDateValue` and `addOHLC`. Datasets, scales, plugins, animation, legend, tooltips and non-click events are not reachable.

### Limitations

- Browser-only: no widget or platform view, unconditional web imports, and JS served from `packages/chart_engine/...` with no Flutter assets. The maintainer knows no way to use it in a Flutter widget (issue #10, 2022-03-14).
- Frozen at Chart.js 2.9.4; the glue uses v2-only APIs and internals (`xAxes`/`yAxes`, `horizontalBar`, `Chart.plugins.register`, `_model`/`_index`), so v3 or v4 would need a rewrite.
- Seven presets only: no pie, radar, polar, bubble or mixed charts.
- `onClick` works only under DDC. The one test that sets it never clicks and runs only on dart2js, and pub.dev's `is:wasm-ready` is a static import check.
- `renderScatterChart` passes 10 arguments to an 11-parameter JS function, so a non-null onClick forces a time x-axis and is lost; `renderBar` ignores onClick.
- `addDateValue` drops the date; `addData_tohlc` never compares the last element, so re-sending the latest candle duplicates it.
- In script mode the bundled UMD overwrites any `window.Chart` already on the page.
- About 4.7 MB of JS/CSS ships, including unused bundles.

### Takeaways for flutter_chartjs

- Nothing to reuse for rendering: no Dart layout, scale or drawing code exists, and the bundled JS is plain upstream 2.9.4. The port should work from upstream Chart.js v4.5.1.
- `DateAdapter` (`lib/src/chart_engine_date.dart`, Apache-2.0) implements the v2 date-adapter contract on intl (every member except `formats`, which is a JS constant), with a moment-to-intl format-token translator. v4.5.1 adds `init(chartOptions)` and drops `_create`, so it is a reference only; copied code needs attribution.
- The data classes (flexible x/y pair parsing, time-series normalization) could inform an optional convenience layer over a config-faithful core.
- Run CI on every compiler we claim and drive callbacks with real input; DOM-presence tests missed the broken onClick.

Evidence: `lib/src/chart_engine_base.dart:39`, `lib/src/chart_engine_chartjs.dart:67`, `lib/src/chart_engine_chartjs.dart:270`, `lib/chartjs-2.9.4/chart_engine_wrapper.js:432`

<a id="pkg-chartjs"></a>

## `chartjs`: Google's archived `package:js` bindings for Chart.js 2.6, generated from DefinitelyTyped typings

| | |
|---|---|
| Where | [pub.dev/packages/chartjs](https://pub.dev/packages/chartjs), [github.com/google/chartjs.dart](https://github.com/google/chartjs.dart) |
| Inspected | 0.6.0 (published 2021-09-21) and all 13 earlier releases; repo `master` (pushed 2022-11-29) |
| Status | Discontinued and unlisted on pub.dev; repo archived. Released 2015-11-16 to 2021-09-21; the one later commit adds an "ARCHIVED" README notice. 18 issues/PRs open. |
| Approach | Web (dart2js/DDC): JS interop via legacy `package:js` and `dart:html`. Flutter web: the same, with no widget or `HtmlElementView`. Other platforms: unsupported. |
| Chart.js | 2.6, not bundled: the host page loads it (the example pins cdnjs `Chart.js/2.6.0/Chart.js`, a build without moment.js). Older releases targeted 1.0.2 (0.1.x-0.2.x) and 2.3.0/2.4.0 (0.3.x-0.4.x). |
| Works on | Browser builds via dart2js/DDC. Off the web it does not compile (unconditional `dart:html` import, no stubs); dart2wasm supports neither `dart:html` nor legacy non-static `@JS` classes. Time scales also need moment.js on the page. |
| License | BSD-3-Clause, plus Chart.js's MIT notice in LICENSE (no Chart.js code is bundled); the bindings derive from DefinitelyTyped typings (MIT) |
| Adoption (2026-10-16) | 17 likes, 110/160 points, 480 downloads/30 days; 142 GitHub stars |

### How it renders

1. The host page's `<script>` tag defines the global `Chart` (Chart.js 2.6.0 also sets `Chart.Chart = Chart`).
2. Dart builds the config from `@anonymous` classes such as `ChartConfiguration(type: 'line', data: LinearChartData(...), options: ChartOptions(...))`; their `external factory` constructors compile to JS object literals.
3. `Chart(querySelector('#canvas') as CanvasElement, config)` is an `external factory` in a library annotated `@JS('Chart')`, so it compiles to `new Chart.Chart(canvas, config)`.
4. Chart.js 2.x JavaScript does everything else (scales, layout, controllers, drawing, animation, tooltips) on the browser's `CanvasRenderingContext2D`.

No release contains Dart code that computes or draws anything. On Flutter web the app must register its own view factory for a `CanvasElement` and add the script to `web/index.html`.

### Bridge

- **Dart to JS:** no serialization. Under dart2js/DDC the config is a live JS object passed by reference. `DateTime` is not converted to JS `Date` (issue #14).
- **JS to Dart:** events reach Dart only through function-valued options (`onClick`, legend `generateLabels`, tooltip `filter`, ticks `callback`, ...). The package never calls `allowInterop`, so unwrapped closures fail at runtime (issue #48). `ChartOptions.onClick` and `ChartHoverOptions.onHover` declare one parameter, which receives the event instead of the active elements; `ChartTooltipCallback` methods return `void`, though Chart.js uses the result.
- **Scriptable options:** none; Chart.js 2.6 predates them (they appear in 2.7.0).

### API

45 classes in `lib/chartjs.dart` (1,307 lines, every member `external`) mirror the Chart.js 2.6 object model under its JS names; enums are `String`s. The base was generated by `dart_js_facade_gen` in 2017; many factories (axes, `ChartOptions`, legend, hover, tooltip, ticks) were hand-written between 2018 and 2021. Gaps: no factories for `ChartTooltipCallback`, `ChartAnimationOptions`, `PluginServiceRegistrationOptions` or `PointLabelOptions`, so tooltip callbacks, animation callbacks and plugin hooks cannot be built from typed Dart; the `ChartOptions` factory omits `layout`, `spanGaps` and others; there is no `scale` option, so radar and polar-area axes cannot be configured through the typed API; tick factories take only `min`/`max`. Helpers, controllers and scale classes are not bound.

### Limitations

- Web only, and only with JS compilers.
- Chart.js 2.6 config shape only (`scales.xAxes`/`yAxes`, root-level `legend`/`tooltips`, `gridLines`, and `Chart.pluginService`, already deprecated in 2.6.0); a request for 3.6.2 support (#56) is unanswered.
- Discontinued and archived; no tests.
- Chart.js is not shipped and its version is not checked; no Flutter widget.
- Callbacks must be wrapped in `allowInterop` by hand.
- Binding errors and mismatches. In the 2017 generated code: `toBase64` (Chart.js has `toBase64Image`) and `fullWdith` (for `fullWidth`). In hand-written factories: `ChartTooltipOptions` takes `backdropColor` instead of `backgroundColor` (PR #43, shipped in 0.5.2), and the `ChartYAxe` factory accepts `categoryPercentage`, `barPercentage` and `time`, which the class does not declare.
- Weak typing: `dynamic` unions and `Chart.defaults`, `update`/`render` as bare `Function`, `autoSkipPadding` typed `bool` (it is a number), and non-nullable getters that can return `null` for unset options.

### Takeaways for flutter_chartjs

- No charting logic to reuse: every release is an interop facade.
- Its option names follow Chart.js 2.6; a v4.5.1 config model should come from Chart.js v4.5.1's own TypeScript declarations (MIT).
- Errors crept into both the generated code and the hand-written factories, so a typed options layer needs tests against Chart.js itself, however it is produced.

Evidence: `README.md:1`, `lib/chartjs.dart:8`, `lib/chartjs.dart:14`, `example/index.html:5`

<a id="pkg-chartjs2"></a>

## `chartjs2`: Renamed, code-identical republish of `chartjs` 0.6.0, a web-only JS-interop wrapper for Chart.js 2.6

| | |
|---|---|
| Where | [pub.dev/packages/chartjs2](https://pub.dev/packages/chartjs2); source [insinfo/chartjs.dart](https://github.com/insinfo/chartjs.dart), a GitHub fork of [google/chartjs.dart](https://github.com/google/chartjs.dart) |
| Inspected | 2.0.0, the only version (as of 2026-10-16), published 2023-04-11; fork last pushed the same day. `lib/` last changed upstream on 2021-09-21. |
| Status | Stale: one release (2023-04-11), no activity since. Listed and not marked discontinued on pub.dev (as of 2026-10-16), while upstream `chartjs` is discontinued and unlisted and its repository archived (notice added 2022-11-29). |
| Approach | Renamed fork of `chartjs` 0.6.0. Web (`dart:html` apps): JS interop via legacy `package:js`. Flutter web: the same interop, with no widget or `HtmlElementView`. Android/iOS/desktop: unsupported. |
| Chart.js | 2.x, bindings generated from the DefinitelyTyped Chart.js 2.6 typings. Not bundled or version-checked: the host page adds the `<script>`; the example loads `https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.6.0/Chart.js` (pinned). |
| Works on | Web via dart2js/DDC only; not WASM-compatible (`package:js` imports `dart:js`). Flutter web only with app-side glue (own canvas element, Chart.js in `web/index.html`), not under `--wasm`. The Dart VM and Flutter mobile/desktop cannot compile it (unconditional `dart:html` and `package:js` imports). |
| License | BSD-3-Clause (Copyright (c) 2015, Google) for the bindings, with the Chart.js MIT notice appended to LICENSE. pana: BSD-3-Clause + MIT; GitHub: NOASSERTION. |
| Adoption (2026-10-16) | pub.dev: 3 likes, 110/160 points, 28 downloads in 30 days, no verified publisher. GitHub: 1 star, 0 forks. Upstream `chartjs`: 17 likes, 480 downloads in 30 days, 142 stars. |

**What the fork changed.** Packaging only. With CRLF line endings normalized, `lib/chartjs.dart` and `lib/src/func.dart` are byte-identical to `chartjs` 0.6.0, and the fork's HEAD matches the published 2.0.0. Its 3 commits ahead of google/chartjs.dart (0 behind) touch only `pubspec.yaml` (name, version 0.6.0 to 2.0.0, homepage), `CHANGELOG.md` ("fork from https://github.com/google/chartjs.dart"), `README.md` (upstream's "ARCHIVED" notice and "This is not an official Google product." removed) and the example's import.

### How it renders
Identical to `chartjs` (see above); only the import becomes `package:chartjs2/chartjs.dart`.

1. `@anonymous` external factories (`ChartConfiguration`, `ChartDataSets`, `ChartOptions`, ...) compile to plain JS object literals.
2. `Chart(canvasElement, config)`, an external factory on `@JS() class Chart` under `@JS('Chart')`, runs `new window.Chart.Chart(canvas, config)` against the Chart.js 2.x that the host page loaded.
3. Chart.js paints the `<canvas>` through `CanvasRenderingContext2D`; no Dart code draws.

### Bridge
Unchanged from `chartjs`: config is passed by reference with no JSON step; updates mutate `chart.data`, then call `chart.update`. Dart is called back only through function-valued options (`onClick`, legend `generateLabels`, tooltip `filter`/`itemSort`, `TimeScale.parser`), each of which the caller must wrap in `allowInterop`; `getElementAtEvent`-style queries return opaque JS objects. No scriptable options: Chart.js 2.6.0 has no resolver for them.

### API
The same 45-class typed facade (693 `external` members; pana: 1.3% of 447 API elements documented), generated from the 2.6 typings and hand-edited upstream until 2021. One hand edit binds `ChartLegendOptions.align`, a Chart.js 2.9.0 option that 2.6.0 ignores. It covers the v2 option tree (`scales.xAxes`/`yAxes`, root-level `legend`/`tooltips`/`title`) and `Chart.pluginService`, but not `Chart.helpers`, the extension API, `getElementsAtEventForMode` or v3/v4.

### Limitations
- Web only (deprecated `dart:html`, discontinued `js ^0.6.3`): no Flutter widget, mobile/desktop or WASM support.
- Chart.js 2.x API only; upstream issue #56 (Chart.js 3.6.2 support, 2021-12-16) is still open.
- Callbacks fail after dart2js unless wrapped in `allowInterop` (upstream #24, #48); `DateTime` x-values can leave the time axis blank (#14, open).
- Every binding gap and error of `chartjs` 0.6.0 carries over (see above): 7 classes without factories, `{min, max}`-only tick factories, an unsettable tick-label `callback`, `toBase64` and `fullWdith` from the typings, the tooltip factory's `backdropColor` from hand-written upstream PR #43, and `autoSkipPadding` typed `bool`.
- Chart.js is not bundled; time scales also need Moment.js, which the example page does not load.
- The single release changes no code, so none of these is fixed.

### Takeaways for flutter_chartjs
- Nothing algorithmic to reuse: no rendering, scale, layout, interaction or animation code.
- As with `chartjs`, the names map the Chart.js 2.6 option tree, which is obsolete in v4 (`xAxes`/`yAxes` became `scales.{id}`, `tooltips` became `plugins.tooltip`, `gridLines` became `grid`); a v4 config model is better generated from Chart.js 4.5.1's MIT-licensed TypeScript types.
- No native-rendering prior art in the google/chartjs.dart lineage: of its 52 forks, only `chartjs2` was republished under a new name, and none adds drawing code.

Evidence: `CHANGELOG.md:1`, `lib/chartjs.dart:14`, `lib/chartjs.dart:26`, `example/index.html:5`

<a id="pkg-pakhyunw_flutter_chartjs"></a>

## `pakhyunw/flutter_chartjs`: Unpublished WebView wrapper around CDN-loaded Chart.js, adapted from the `high_chart` Highcharts wrapper

| | |
|---|---|
| Where | [github.com/pakhyunw/flutter_chartjs](https://github.com/pakhyunw/flutter_chartjs); GitHub only, never published to pub.dev (pubspec name `chartjs`) |
| Inspected | pubspec 0.0.1, `main` at `214c6a697e`, pushed 2025-07-01 |
| Status | Dormant, not archived. 18 commits: code work 2024-02-23 to 2024-03-14; later only dependency bumps, a `flutter_js` swap reverted within 19 minutes (2024-12-02), and `onReady` plus the unpinned Chart.js URL (2025-07-01). No issues, PRs or releases. |
| Approach | Android/iOS: WebView (`webview_flutter`). Web (dart2js): platform view (`HtmlElementView`) plus `package:js` `eval`. Desktop reuses the WebView branch; other targets (e.g. dart2wasm) get a stub. The library code started as [`high_chart`](https://pub.dev/packages/high_chart) 2.1.0 with HighCharts-to-ChartJs renames; commit `66716a3586` (2024-02-26) replaced the Highcharts-style `ChartJs.chart(...)` call with `new Chart(...)` and, on mobile only, the `<div>` with a `<canvas>`. |
| Chart.js | Nothing bundled; the app passes CDN URLs. The example pinned cdnjs Chart.js 3.9.1 from the first commit (2024-02-23) until 2025-07-01, and its config was written for v3 (with v2 leftovers). Since `671c28709e` (2025-07-01) it loads the unpinned `https://cdn.jsdelivr.net/npm/chart.js` (4.5.1 as of 2026-10-16). On web the host page supplies Chart.js; the example's URL there returns 404. |
| Works on | Android and iOS: the only branch that can render (needs network). Web draws nothing and does not compile on Flutter 3.32+ (`dart:ui` `platformViewRegistry` removed). macOS throws in `initState` (`setBackgroundColor` reaches `setOpaque`, unimplemented on macOS in `webview_flutter_wkwebview` 3.22.0). Windows/Linux have no `webview_flutter` implementation. WASM hits a stub with a null-safety compile error. |
| License | MIT (`Copyright (c) 2021 SENTHIL NASA`, inherited from `high_chart`); nothing third-party bundled |
| Adoption (2026-10-16) | GitHub: 1 star, 0 forks. Not on pub.dev, where `chartjs` belongs to google/chartjs.dart 0.6.0 (discontinued), so it works only as a git or path dependency. |

### How it renders

1. The app builds a `ChartJs` widget; `lib/chartjs.dart` conditionally exports a mobile (`dart.library.io`), web (`dart.library.html`) or stub implementation.
2. Mobile:
   1. `ChartJsState.initState` creates a `WebViewController` and calls `loadHtmlString(_htmlContent(widget.size.height))`: one `<script src>` per `scripts` entry, a `<canvas id="chartJs">` and `function chart(a){ eval(a); return true;}`.
   2. The WebView fetches the scripts from the CDNs; `onPageFinished` runs `_loadData()`, which calls `` runJavaScriptReturningResult("chart(`new Chart('chartJs', $chartData)`);") ``.
   3. Chart.js lays out and draws on the HTML canvas; Flutter shows it as a platform view (`WebViewWidget` in a `SizedBox(size)`).
   4. When `data`, `size` or `scripts` change, `didUpdateWidget` reloads the whole page.
3. Web:
   1. `build()` registers a `ui.platformViewRegistry` factory returning a `DivElement`, shown with `HtmlElementView`.
   2. After a fixed 250 ms delay, `_load()` calls `eval("new Chart('$_chartJsId',${widget.data});")`.
   3. Chart.js cannot get a 2D context from a `<div>` (a Highcharts leftover), logs "Failed to create chart: can't acquire context from the given item" and draws nothing.
4. Elsewhere the stub would show `Text('ChartJs: UnSupported Platform')`, but any build that selects it fails to compile.

### Bridge

- Dart to JS: one `String` config (JS object literal or `jsonEncode` output) spliced into JS source and `eval`'d without escaping. Backticks, `${` or backslashes break or alter it, a code-injection risk with untrusted data.
- JS to Dart: nothing. No channel, chart handle or events; on mobile the result Future is never awaited, so JS errors become unhandled async errors.
- Scriptable options: only JS source inside the string, plus one hardcoded swap of `"callback":"toFixed"` for a function. Since 2024-02-28 that pattern has not matched the example's `'callback': 'toFixed'`, so under Chart.js 4.5.1 the example's y axes have no tick labels.
- `onReady` (mobile only) is a JS string run after a reload, never on first load.

### API

One untyped widget: `ChartJs({required String data, required Size size, String? onReady, Widget loader, List<String> scripts})` (the web constructor has no `onReady`). No typed config, Map API, or chart, dataset, scale or plugin classes; coverage is whatever the loaded scripts support. No update, destroy, resize, export or event API.

### Limitations

- Not a port: Chart.js JavaScript draws inside a WebView, Dart computes no chart geometry, and only Android and iOS can render.
- Needs the network on every load; the example's release Android manifest lacks the INTERNET permission. The floating CDN URL runs a config written for 3.9.1 on whatever jsDelivr serves.
- One-way, unescaped string bridge: no events or callbacks, and JS failures never reach the widget.
- Any change to `data`, `size` or `scripts` reloads the page and re-downloads the scripts instead of calling `chart.update()`. `scripts` is compared by identity, so a non-const list built in the parent's `build()` reloads the page on every rebuild.
- Leftover docs and tests: Highcharts dartdoc, Chart.js's own README, `high_chart`'s CHANGELOG, template test stubs.

### Takeaways for flutter_chartjs

- Nothing to reuse: about 540 lines of WebView and `HtmlElementView` plumbing, no chart logic.
- A compact case study of the "eval a config string in a WebView" pattern and its costs (escaping, no events, full reloads, network dependency, untyped API), useful when explaining what a native port fixes.
- The example config (time x-axis, dual y-axes via `yAxisID`, zoom/pan, annotation lines) is a realistic acceptance scenario.

Evidence: `lib/chartjs.dart:3`, `lib/src/mobile/chartjs.dart:222`, `lib/src/web/chartjs.dart:130`, `example/lib/main.dart:56`

<a id="pkg-chartjs_dart_copies"></a>

## Copies of google/chartjs.dart on GitHub

This survey found four GitHub repositories that copy Google's `chartjs` package (its GitHub repo is archived; the package is discontinued and unlisted on pub.dev). As of 2026-10-16 none is a GitHub fork or on pub.dev, each has 0 stars, and each keeps Google's pubspec name `chartjs`, so none can be published. All are web-only `package:js` facades over Chart.js 2.x: `Chart(canvas, config)` is an `external factory` into the Chart.js script the host page loads from a pinned cdnjs URL, and Chart.js does all layout and drawing. None has a Flutter chart widget, resolves on Dart 3 or compiles to WASM.

| Repo | What it is | Base version | Chart.js | Notable changes |
|---|---|---|---|---|
| [ramnim/chartjs](https://github.com/ramnim/chartjs) | Verbatim library copy; 2 commits, 2020-10-08 | 0.5.2 (Dart 2, not null-safe) | 2.6.0 | README build notes; example interop experiments |
| [AnantaPodder/chartjs.dart](https://github.com/AnantaPodder/chartjs.dart) | Modified copy; 6 commits, 2024-03-18/19 | Commit 7b9f81ddeb, 2019-03-20, after 0.5.1 (Dart 2, not null-safe) | 2.8.0 | About 360 added lines typing options up to 2.8; `toBase64Image` binding fixed |
| [FarHard112/chartjs.dart](https://github.com/FarHard112/chartjs.dart) | Modified copy; 5 commits, 2024-09-06 to 09-25 | 0.5.0-dev, 2017-11-03 (Dart 1 only) | 2.6.0 | 8 narrow factories added; about 87 plain Dart fields in 7 interop classes; 5 tooltip members removed |
| [ariscybertech/aris_chartjs](https://github.com/ariscybertech/aris_chartjs) | Verbatim library copy beside an unrelated `flutter create` counter app; 1 commit, 2021-12-27 | v0.3.1, 2016-12-20 (Dart 1 only) | 2.4.0 | None to the library |

- **ramnim**: its GitHub description is "javascript to dart", yet `lib/chartjs.dart` is byte-identical to upstream 0.5.2.
- **AnantaPodder**: some additions are inconsistent (getter-only members, incomplete factories); the example passes Dart closures without `allowInterop`, which upstream issue #24 reports failing under dart2js.
- **FarHard112**: the plain fields are Dart-side storage, not JS bindings, so in those 7 classes only the external factories reliably reach Chart.js.
- **aris_chartjs**: the Flutter app renders no chart, and the project does not build as committed (Dart 1 pubspec, no Flutter dependency).

License: ramnim, AnantaPodder and FarHard112 keep upstream's LICENSE verbatim (BSD-3-Clause plus the Chart.js MIT notice); aris_chartjs omits the LICENSE file its source headers cite.

**Takeaways for flutter_chartjs:** none contains layout, scale or drawing code, so nothing is reusable for rendering. The typings follow the Chart.js v2 option tree (`xAxes`/`yAxes`, `gridLines`, root-level `tooltips`); the v4.5.1 config model should come from Chart.js v4's own `types/index.d.ts`.

Evidence: `lib/chartjs.dart:27` (ramnim), `lib/chartjs.dart:957` (AnantaPodder), `lib/chartjs.dart:390` (FarHard112), `lib/main.dart:1` (aris_chartjs).

<a id="pkg-ruleouts"></a>

## Ruled out

Three candidates matched on name but are not Chart.js ports or wrappers. Status is as of 2026-10-16.

### `highchartjs`: a Highcharts wrapper

[pub.dev](https://pub.dev/packages/highchartjs) · [GitHub](https://github.com/iamarifdev/highchartjs) · inspected 0.0.3 (2024-11-27, also the last commit)

- **What it is:** an MIT-licensed wrapper for Highcharts, derived from `high_chart`, another Highcharts wrapper. On web it shows a `div` through `HtmlElementView` and injects a `<script>` that calls `Highcharts.chart()`. On Android, iOS and macOS it loads a generated HTML page into `webview_flutter`; by default that page's `<script>` tags pull Highcharts from unpinned code.highcharts.com URLs. Highcharts is licensed separately and requires a license for commercial use.
- **Why it surfaced:** the name contains "chartjs". Apart from the name, no published version (0.0.1 to 0.0.3) mentions Chart.js.
- **Evidence:** `pubspec.yaml:2`, `lib/src/web/highchartjs.dart:136`, `lib/src/mobile/highchartjs.dart:22`, `lib/src/mobile/highchartjs.dart:104`

### `m4d_spa`: single-page-app components, no charts

[pub.dev](https://pub.dev/packages/m4d_spa) · [GitHub](https://github.com/MikeMitterer/m4d_spa) · inspected 0.1.12 (2018-12-19; last commit 2019-01-17)

- **What it is:** components that load HTML views into the page over XHR, for Material Design 4 Dart. It is built on `dart:html`, not Flutter, and `lib/` has no chart code. Dart 2 only and not null-safe; pub.dev marks it Dart 3 incompatible.
- **Why it surfaced:** it ships an example app, [`samples/m4d_chartjs`](https://github.com/MikeMitterer/m4d_spa/tree/master/samples/m4d_chartjs), and the README links a demo site of that name. `m4d_chartjs` was never published to pub.dev and has no repository of its own. The sample drives Chart.js 2.7.3, loaded by its host page from a pinned cdnjs URL, through the separate `chartjs` package (`package:js` bindings typed for Chart.js 2.6).
- **Evidence:** `pubspec.yaml:2`, `lib/spa/ViewFactory.dart:72`, `samples/m4d_chartjs/web/main.dart:16`, `samples/m4d_chartjs/web/index.html:15`

### `reactspring/flutter_js_chart`: fl_chart 0.62.0, renamed

[GitHub](https://github.com/reactspring/flutter_js_chart) (not on pub.dev) · inspected `master` at `8c607cb` (2023-08-18)

- **What it is:** [fl_chart](https://github.com/imaNNeo/fl_chart) 0.62.0 renamed to `flutter_js_chart` 0.62.1. It is pure Flutter: `RenderBox` painters draw on the `dart:ui` canvas, with no JavaScript, JS interop or WebView. Apart from the rename, 4 of 56 `lib/` files differ from fl_chart 0.62.0 and all 57 test files match; the only functional change is a work-in-progress triangle marker for scatter spots. The pubspec sets `publish_to: none`, and the repository has two commits, both from 2023-08-18. Its one-line LICENSE replaces fl_chart's MIT notice, so fl_chart code or patterns should come from upstream, under upstream's notice.
- **Why it surfaced:** the name contains "js_chart". Nothing in the repository relates to JS or Chart.js.
- **Evidence:** `pubspec.yaml:1`, `lib/src/chart/line_chart/line_chart_renderer.dart:93`, `lib/src/utils/canvas_wrapper.dart:73`, `LICENSE:1`

### `js_widget_runtime`: a JavaScript-widget runtime, charts drawn by fl_chart and CustomPainter

[pub.dev](https://pub.dev/packages/js_widget_runtime) · [GitHub](https://github.com/IstiN/flutter_js_widget_runtime) · inspected 0.4.171 (2026-10-15, also the last commit, `77378c4`)

- **What it is:** an MIT-licensed runtime that turns JavaScript widgets into Flutter UI. Widget code runs by default in flutter_js (QuickJS, or JavaScriptCore on Apple) on the VM or in a Web Worker on the web, and `jsr.render(tree)` sends Dart the UI tree as JSON. `JsonWidgetRenderer` maps the `flChart` node onto fl_chart's line, bar, pie, radar and scatter charts, and draws the `chart` node (sparkline or bar) with two small `CustomPainter`s of its own. Coverage is minimal: no axis titles or legend, single-series bars, index-only x on line charts, and no scriptable options, because functions cannot cross the JSON bridge. Active: 159 versions since 2026-07-18, mostly automated patch bumps. As of 2026-10-16: 0 likes, 0 GitHub stars, 17,619 downloads in 30 days. The README claims Android, iOS, macOS and web, and a web demo is live, but pana finds 0 of 6 platforms supported. Unrelated to `js_widget` (EnsembleUI).
- **Why it surfaced:** a "chart.js webview" search. Its webview support is a generic `webView` node that embeds a URL through a host-supplied `JsWebViewHost` (a placeholder if none is set). Messages go only from page to widget, so a page running Chart.js could get data only through its URL. None of the 603 published files bundles, loads or references Chart.js.
- **Takeaway for flutter_chartjs:** nothing Chart.js-specific to reuse (no scales, layout, dataset controllers or elements). It is a worked example of running JS in QuickJS/JavaScriptCore or a Web Worker with timer and `requestAnimationFrame` shims over a JSON bridge, relevant only to a "run real Chart.js" fallback, and it has no Canvas 2D shim or way to show JS-drawn pixels.
- **Evidence:** `lib/src/runtime/js_widget_bootstrap.dart:137`, `lib/src/renderer/json_widget_renderer.dart:386`, `lib/src/renderer/nodes/js_chart_nodes.dart:21`, `lib/src/renderer/json_widget_renderer.dart:585`
