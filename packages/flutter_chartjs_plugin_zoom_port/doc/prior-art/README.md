# Prior art: zoom and pan for Chart.js in Dart and Flutter

Survey date: **2026-11-10**. Numbers that change over time (versions, dates, downloads, likes,
stars) are as of that date.

**Question.** Does a Dart or Flutter port of
[chartjs-plugin-zoom](https://github.com/chartjs/chartjs-plugin-zoom) exist? How do the Dart
wrappers of Chart.js and the native Flutter chart packages handle zoom and pan? This survey
examines the input (wheel, drag, pinch, pan) and the zoom state of each one.

**Answer.** No Dart or Flutter port of chartjs-plugin-zoom exists outside this package.

- Two Dart projects use the JavaScript plugin. Both are on GitHub only.
  [`pakhyunw/flutter_chartjs`](#pakhyunw) loads the plugin 2.0.1 from cdnjs and Hammer.js from
  `hammerjs.github.io` into a WebView. [`Hexer10/chartjs.dart`](#hexer10) has JS-interop bindings (2019) for the options of
  the plugin v0.6.
- The Chart.js wrappers on pub.dev that the survey examined (`chartjs_flutter`, `js_widget`,
  `ensemble`, `chart_engine`) do not load the plugin.
- The native Flutter chart packages have their own zoom code. Each package maps the Flutter
  gestures directly to its own zoom state. None has a DOM-like event surface or a port of a
  JavaScript input layer.
- Outside Dart, one project ports the plugin: [`keystone-chartjs-wrappers`](#keystone) has a
  TypeScript copy of v2.2.0, with Pointer Events in place of Hammer.js (2026-09). Charba (Java)
  wraps the JavaScript plugin. The survey found no port to another language.

## At a glance

### Chart.js zoom in Dart

| Project | Kind | Plugin | Input | Zoom state | License | State (2026-11-10) |
|---|---|---|---|---|---|---|
| [`pakhyunw/flutter_chartjs`](#pakhyunw) (GitHub) | WebView wrapper; the example loads the plugin | 2.0.1 from cdnjs, Hammer.js from `hammerjs.github.io` | Hammer.js in the WebView: pinch and pan. No wheel: only Android and iOS draw | In JavaScript. A new `data`, `size` or `scripts` reloads the page | MIT | dormant. `main` at `214c6a697e` (2025-07-01) |
| [`Hexer10/chartjs.dart`](#hexer10) (GitHub) | JS-interop bindings, a fork of `google/chartjs.dart` | the option form of v0.6 (root `pan` and `zoom`) | the host page must load Chart.js 2.x, the plugin and Hammer.js | In JavaScript. A `resetZoom` binding | BSD-3-Clause (Google) | 2 commits on 2019-09-09 |
| `flutter_chartjs_plugin_zoom_port` (this package) | native port | v2.2.0+fb81d331 | the DOM-like events of the host (Chart.js ADR 0108) | In Dart, in the scale options and the state of the plugin | MIT | zoom phases 1 to 4 done |

### Zoom and pan in native Flutter chart packages

| Package | Gesture model | Wheel | Limits | Reset | State across rebuilds | License |
|---|---|---|---|---|---|---|
| [`fl_chart`](#fl_chart) 1.3.1 | a copy of `InteractiveViewer`: `Listener.onPointerSignal` and `GestureDetector.onScale*` | scale `exp(-dy / 200)` at the cursor | `minScale` ≥ 1 (default 1), `maxScale` 2.5 | the `TransformationController` of the app | kept: the controller is in the `State` | MIT |
| [`syncfusion_flutter_charts`](#syncfusion) 35.1.43 | its own recognizers in `RenderBox.handleEvent`, with an arena team | a fixed step of 0.25 for each event, by the sign of the delta | `maximumZoomLevel` 0.01 (the smallest zoom factor) | `reset()`, `zoomIn()`, `zoomOut()`, `zoomByFactor()`, `zoomByRect()`, `panToDirection()` | kept in the axis controller until `initialZoomFactor` or `initialZoomPosition` changes | Syncfusion license (commercial or community) |
| [`graphic`](#graphic) 2.7.0 | `Listener.onPointerSignal` and `GestureDetector.onScale*`; range updaters of the coordinate | a fixed step: each end moves by 5% of the range, by the sign of the delta | none | a double tap gives the initial range | kept for new data; a new view at a changed specification | MIT |
| [`community_charts_flutter`](#community_charts) 1.0.4 | `GestureDetector.onScale*` | none | scale 1 to 5, fixed | none; the axis spec gives the initial viewport | kept for an equal axis spec; a new axis for another spec | Apache-2.0 |
| [`cristalyse`](#cristalyse) 1.17.6 | `Listener.onPointerSignal` and `GestureDetector.onScale*` | scale `exp(-dy × 0.0015)` in the plot area | scale 1 to 16 | `PanController.panReset()`; zoom buttons | reset at each new `data` List | MIT |

The [probe](#probe) below gives the results of wheel and trackpad events over fl_chart, graphic and
Syncfusion in a parent `ListView`.

## Chart.js zoom in Dart

<a id="pakhyunw"></a>

### `pakhyunw/flutter_chartjs`: the plugin in a WebView

| | |
|---|---|
| Where | [github.com/pakhyunw/flutter_chartjs](https://github.com/pakhyunw/flutter_chartjs). Not on pub.dev |
| Examined | `main` at `214c6a697e042f64a09a59276d24d52ee7bc3b63` (2025-07-01) |
| License | MIT (`Copyright (c) 2021 SENTHIL NASA`, from `high_chart`) |
| More | The [Chart.js survey](../../../flutter_chartjs_port/doc/prior-art/chartjs-packages.md#pkg-pakhyunw_flutter_chartjs) describes the wrapper |

**How it works.**

1. The example gives a list of script URLs to the `ChartJs` widget. The list has Chart.js (unpinned,
   jsDelivr), chartjs-plugin-annotation 2.2.1, `https://hammerjs.github.io/dist/hammer.min.js` and
   chartjs-plugin-zoom 2.0.1 from cdnjs (`example/lib/main.dart:55-59`).
2. The config enables `pan` with the mode `xy` and the `pinch` zoom with the mode `x`
   (`example/lib/main.dart:27-37`). It enables no wheel and no drag.
3. On Android and iOS, a WebView loads a page with the scripts. The wrapper turns off the page zoom
   of the WebView (`enableZoom(false)`, `lib/src/mobile/chartjs.dart:143`). Hammer.js in the page
   recognizes the pinch and the pan.
4. The `WebViewWidget` has no `gestureRecognizers` (`lib/src/mobile/chartjs.dart:190`). The
   webview_flutter docs say: with an empty list, the web view handles only the pointer events of
   gestures "that were not claimed by any other gesture recognizer".
5. The zoom state stays in JavaScript. The widget has no `resetZoom` method and no zoom callback. A
   change of `data`, `size` or `scripts` loads the page again (`didUpdateWidget`,
   `lib/src/mobile/chartjs.dart:166-177`). Thus the range goes.

**Platforms.** Only Android and iOS draw. The web branch draws nothing, and the desktop branches
fail (Chart.js survey).

<a id="hexer10"></a>

### `Hexer10/chartjs.dart`: JS-interop bindings for the plugin options

| | |
|---|---|
| Where | [github.com/Hexer10/chartjs.dart](https://github.com/Hexer10/chartjs.dart), a fork of `google/chartjs.dart` |
| Examined | `master` at `c04f883691` (2019-09-09) |
| License | BSD-3-Clause (`Copyright (c) 2015, Google`). GitHub shows `NOASSERTION` |
| Platforms | browsers through dart2js. `sdk: '>=2.0.0 <3.0.0'` |

**How it works.**

- Commit `7b772140ed` (2019-09-09, "Add support for chartjs-plugin-zoom") adds the `package:js`
  classes `ChartPanOptions` and `ChartZoomOptions` with `enabled`, `mode`, `rangeMin`, `rangeMax`,
  `drag` and `speed`. It adds `pan` and `zoom` to the root of `ChartOptions`.
- Commit `c04f883691` (2019-09-09) adds `resetZoom` as a `Function` getter on `Chart`.
- The root `pan` and `zoom` options are the form of the plugin v0.6 (`README.md` of `v0.6.6`).
  The plugin v0.7.0 (2019-03-16) moved them to `options.plugins.zoom`. Thus the bindings follow
  an older form than the plugin of their date.
- The browser page must load Chart.js, the plugin and Hammer.js. The example page loads only
  Chart.js 2.6.0 (`example/index.html:5`). The callbacks `onPan` and `onZoom` stay as `TODO`.
- The input and the zoom state are those of the plugin in the browser. Dart gets no event.

### The Chart.js wrappers on pub.dev

The archives of `chartjs_flutter` 1.0.0, `js_widget` 1.0.4, `ensemble` 1.2.60 and `chart_engine`
3.0.2 do not load chartjs-plugin-zoom:

- `chartjs_flutter` and `js_widget` have no string `zoom`.
- The Chart.js page of `ensemble` loads Chart.js and chartjs-plugin-annotation
  (`lib/util/chart_utils.dart:56`).
- In `chart_engine`, only the ApexCharts 3.26.0 files have the string `zoom`. ApexCharts has its
  own zoom in JavaScript.

The [Chart.js survey](../../../flutter_chartjs_port/doc/prior-art/README.md) of 2026-10-16
describes these packages.

## Zoom and pan in native Flutter chart packages

<a id="fl_chart"></a>

### `fl_chart`: a copy of `InteractiveViewer` over the chart rectangle

| | |
|---|---|
| Where | [pub.dev/packages/fl_chart](https://pub.dev/packages/fl_chart), [GitHub](https://github.com/imaNNeo/fl_chart) |
| Examined | 1.3.1 (2026-11-09). The zoom files are the same in 1.3.0, which the probe used |
| Adoption | 7,206 likes, 2,297,495 downloads in 30 days |
| License | MIT (`Copyright (c) 2022 Flutter 4 Fun`). `custom_interactive_viewer.dart` is a copy of the Flutter `InteractiveViewer` (BSD-3-Clause, The Flutter Authors) |
| History | 0.70.0 added the zoom and the pan of `LineChart`, `BarChart` and `ScatterChart` (`FlTransformationConfig`, issue #71). 0.70.1 added `panEnabled` and `scaleEnabled` (`CHANGELOG.md`) |

**How it works.**

1. `FlTransformationConfig` has `scaleAxis` (`horizontal`, `vertical`, `free`, `none`), `minScale`
   (default 1, an assert requires ≥ 1), `maxScale` (default 2.5), `panEnabled`, `scaleEnabled`,
   `trackpadScrollCausesScale` (default false) and an optional `transformationController`
   (`lib/src/chart/base/axis_chart/transformation_config.dart:5-17`).
2. `CustomInteractiveViewer` is the Flutter `InteractiveViewer` without the `Transform` of the
   child (`lib/src/chart/base/custom_interactive_viewer.dart:1-7`). It wraps a `GestureDetector`
   with `onScaleStart`, `onScaleUpdate` and `onScaleEnd` in a `Listener` with `onPointerSignal`
   (`:1027-1038`).
3. The scale recognizer takes the touch pan and pinch in the gesture arena. It also takes the
   pan-zoom events of a desktop trackpad.
4. `onPointerSignal` handles the wheel: the scale is `exp(-scrollDelta.dy / scaleFactor)` with
   `scaleFactor` 200, at the cursor (`:756-814`). A scroll event of the kind `trackpad` pans unless
   `trackpadScrollCausesScale` is true (`:759`). A `PointerScaleEvent` scales (`:815`).
5. The scaffold creates a `TransformationController` in `initState` unless the app gives one
   (`lib/src/chart/base/axis_chart/axis_chart_scaffold_widget.dart:79`). It computes a larger
   virtual rectangle from the inverse transform, and the chart lays out its data in it
   (`:142-163`, `:222-250`). The data bounds (`minX`, `maxX`) do not change.
6. A bar chart with the alignment `center`, `end` or `start` cannot scale horizontally (an assert,
   `lib/src/chart/bar_chart/bar_chart.dart:28-38`).

**Reset and state.** The app resets with its controller: the docs sample sets
`controller.value = Matrix4.identity()` (`example/lib/presentation/samples/line/line_chart_sample12.dart:382`).
The docs (`repo_files/documentations/handle_transformations.md`) say that a custom controller can
move the chart out of the screen. A rebuild keeps the controller: `didUpdateWidget` changes it only
when the controller that the app gives changes (`axis_chart_scaffold_widget.dart:97-129`).

<a id="syncfusion"></a>

### `syncfusion_flutter_charts`: `ZoomPanBehavior` on the axis zoom factor

| | |
|---|---|
| Where | [pub.dev/packages/syncfusion_flutter_charts](https://pub.dev/packages/syncfusion_flutter_charts), [docs](https://help.syncfusion.com/flutter/cartesian-charts/zoom-pan) |
| Examined | 35.1.43 (2026-11-03) |
| Adoption | 3,643 likes, 259,577 downloads in 30 days |
| License | The Syncfusion Community License or a commercial license (`LICENSE`, `README.md:22`). pub.dev shows `license:unknown`. Ideas only |

**How it works.**

1. `ZoomPanBehavior` has `enablePinching`, `enableDoubleTapZooming`, `enablePanning`,
   `enableSelectionZooming` and `enableMouseWheelZooming` (all false by default), `zoomMode`
   (default `xy`) and `maximumZoomLevel` (default 0.01)
   (`lib/src/charts/behaviors/zooming.dart:35-43`). It applies only to `SfCartesianChart`.
2. The chart area is a `RenderBox`. Its `handleEvent` adds each `PointerDownEvent` to its own tap,
   double tap (only when a double-tap feature is on), long press, horizontal drag, vertical drag
   and scale recognizers. At a move with more than one pointer, it rejects the drag recognizers
   and accepts the scale recognizer (`lib/src/charts/base.dart:501-529`). The drag recognizers get
   callbacks only for the axes of the zoom mode (`:233-292`).
3. The behavior reads `PointerScrollEvent` and `PointerPanZoomUpdateEvent` in `handleEvent`
   (`zooming.dart:428-432`). Each event zooms by 0.25 at the cursor, in the direction of the sign
   of `scrollDelta.dy` or `panDelta.dy` (`:661-671`). The size of the delta has no effect.
4. A long press and a drag select a rectangle to zoom (`enableSelectionZooming`, the docs).
5. The zoom state is `zoomFactor` and `zoomPosition` of each axis controller, in the render object
   of the axis. The axis sets them again only when `initialZoomFactor` or `initialZoomPosition`
   changes (`lib/src/charts/axis/axis.dart:1659-1686`).
6. `reset()` sets each zoom factor to 1 and each position to 0 (`zooming.dart:993`). The behavior
   also has `zoomIn()`, `zoomOut()`, `zoomByFactor()`, `zoomByRect()`, `zoomToSingleAxis()` and
   `panToDirection()` (`:876-992`).

The changelog of 20.4.43 (2023-01-10) says: "The issue with zooming and panning on the chart not
working properly on the macOS trackpad has been resolved" (`CHANGELOG.md:692`). The docs say that
the directional zoom "is intended for touch gestures and is ineffective with a mouse or track
pad-based interactions".

<a id="graphic"></a>

### `graphic`: range updaters of the coordinate

| | |
|---|---|
| Where | [pub.dev/packages/graphic](https://pub.dev/packages/graphic), [GitHub](https://github.com/entronad/graphic) |
| Examined | 2.7.0 (2026-02-25) |
| Adoption | 904 likes, 41,001 downloads in 30 days |
| License | MIT (`Copyright (c) 2024 LIN Chen`) |

**How it works.**

1. `RectCoord` has `horizontalRangeUpdater` and `verticalRangeUpdater`. The app gives
   `Defaults.horizontalRangeEvent` or another `EventUpdater<List<double>>`
   (`lib/src/coord/rect.dart:23-63`, `lib/src/common/defaults.dart:183-197`). The range is the
   ratio of the coordinate width to the width of the coordinate region. The default `[0, 1]` is
   the width of the region.
2. The chart wraps a `GestureDetector` in a `Listener` (`lib/src/chart/chart.dart:243-244`). The
   scale callbacks and `onPointerSignal` (only `PointerScrollEvent`, `:736`) send gesture events
   to the view.
3. The default updater pans when `pointerCount == 1` and zooms by the horizontal or vertical scale
   of a scale update (`defaults.dart:23-44`). Each scroll event moves each end of the range by 5%
   of the range width, by the sign of `scrollDelta.dy` (`:47-55`). The variants
   `horizontalRangeFocusEvent` and `verticalRangeFocusEvent` zoom at the cursor with fixed pixel
   offsets (`39.5` and `51` in the horizontal one, `5` and `25` in the vertical one, `:59-67`). A
   double tap gives the initial range (`:74-75`).
4. No updater clamps the range.
5. The app can listen to and add gesture events through `gestureStream` (`chart.dart:137`).
6. A new data List keeps the range. A changed specification (`equalSpecTo`) disposes the view and
   makes a new one (`chart.dart:225-236`). Thus the range starts again from the initial range.

<a id="community_charts"></a>

### `community_charts_flutter`: `PanAndZoomBehavior` of the old Google charts

| | |
|---|---|
| Where | [pub.dev/packages/community_charts_flutter](https://pub.dev/packages/community_charts_flutter), [GitHub](https://github.com/juliansteenbakker/community_charts). A fork of `google/charts` (`charts_flutter` 0.12.0, discontinued) |
| Examined | `community_charts_flutter` and `community_charts_common` 1.0.4 (2024-05-15) |
| Adoption | 223 likes, 58,454 downloads in 30 days. `d_chart` 3.0.0 uses another fork, `community_charts_flutter2` 1.0.7 |
| License | Apache-2.0 |

**How it works.**

- The chart has one `GestureDetector` with `onScaleStart`, `onScaleUpdate` and `onScaleEnd`
  (`community_charts_flutter/lib/src/chart_gesture_detector.dart:65-73`). It has no wheel
  handler.
- `PanAndZoomBehavior` changes the viewport of the domain axis only. It clamps the scale to 1 to 5
  with private constants
  (`community_charts_common/lib/src/chart/common/behavior/zoom/pan_and_zoom_behavior.dart:47`,
  `:53`).
- `panningCompletedCallback` reports the end of a pan or a zoom.
- `NumericAxisSpec.viewport` is the initial viewport. A domain axis spec that is not equal to the
  last one makes a new axis
  (`community_charts_common/lib/src/chart/cartesian/cartesian_chart.dart:203-205`). Thus the
  viewport starts again. There is no reset call.

<a id="cristalyse"></a>

### `cristalyse`: `ZoomConfig` and `PanConfig`

| | |
|---|---|
| Where | [pub.dev/packages/cristalyse](https://pub.dev/packages/cristalyse), [GitHub](https://github.com/rudi-q/cristalyse) |
| Examined | 1.17.6 (2026-04-04) |
| Adoption | 69 likes, 2,028 downloads in 30 days |
| License | MIT (`Copyright (c) 2025 Rudi K.`) |

**How it works.**

- `ZoomConfig` has `axes` (default x), `minScale` 1, `maxScale` 16, `wheelSensitivity` 0.0015 and
  zoom buttons (shown by default) (`lib/src/interaction/chart_interactions.dart:320-353`).
- The chart wraps a `GestureDetector` with the scale callbacks in a `Listener` with
  `onPointerSignal` (`lib/src/widgets/animated_chart_widget.dart:769-781`). A wheel event in the
  plot area scales by `exp(-dy × wheelSensitivity)` (`:535`).
- `PanController.panTo()` and `panReset()` move the visible range from the app
  (`chart_interactions.dart:221-232`).
- A new `data` List (not identical) or a new geometry list clears the pan and zoom domains
  (`animated_chart_widget.dart:148-153`).

### Others

- [`mp_chart`](https://pub.dev/packages/mp_chart) 0.3.1 (2020-10-30, Apache-2.0) translates
  MPAndroidChart to Dart. It keeps the view port of MPAndroidChart: the scale limits 1 to 1000 and
  `resetZoom` (`lib/mp/core/view_port.dart:19-28`, `:188`). It uses the package
  `optimized_gesture_detector` (`lib/mp/chart/chart.dart:82`). Its SDK range `>=2.1.0 <3.0.0`
  does not resolve on Dart 3. It also imports `dart:io` (`lib/mp/chart/chart.dart:1`).
- [`interactive_chart`](https://pub.dev/packages/interactive_chart) 0.3.6 (2025-06-09, MIT), a
  candlestick chart, uses the same `Listener` and `GestureDetector` pattern. The zoom is the candle
  width, clamped (`lib/src/interactive_chart.dart:198-243`).
- [`dv_zoom`](https://pub.dev/packages/dv_zoom) 1.1.0 (2026-01-27, MIT) is a generic `Zoom` widget
  of the `dv_*` family: a `Listener` with a wheel handler and a `GestureDetector`, a fixed factor
  for each wheel event, and `reset()` on its controller (`lib/src/zoom.dart:186-221`, `:317`).
- [`highcharts_flutter`](https://pub.dev/packages/highcharts_flutter) 1.3.0 shows Highcharts in a
  WebView. Its zoom runs in JavaScript (the option classes
  `highcharts_chart_zooming_options.dart` and `highcharts_chart_zooming_mouse_wheel_options.dart`).
  Its license is the Highsoft integration license.
- [`ar_charts`](https://pub.dev/packages/ar_charts) 0.2.6 shows MPAndroidChart and DGCharts in
  platform views on Android and iOS. Their zoom is native code.

<a id="probe"></a>

## Probe: wheel and trackpad in a parent `ListView`

One temporary widget test (not committed) put each chart in a `ListView` and sent synthetic events
on the flutter tester, Flutter 3.50.0-0.4.pre. The packages are those of
`apps/chart_benchmark_lab`: fl_chart 1.3.0, graphic 2.7.0 and syncfusion_flutter_charts 35.1.43.
Each chart had a horizontal zoom: fl_chart `FlScaleAxis.horizontal`, graphic
`Defaults.horizontalRangeEvent`, Syncfusion `enableMouseWheelZooming`, `enablePinching` and
`enablePanning` with `ZoomMode.x`. The list started at the offset 100.

| Event over the chart | fl_chart | graphic | Syncfusion |
|---|---|---|---|
| Mouse wheel, `scrollDelta.dy` −100 | zooms (scale 1.65), and the list scrolls to 0 | zooms (range −0.05 to 1.05), and the list scrolls to 0 | zooms (factor 0.8), and the list scrolls to 0 |
| Mouse wheel, `scrollDelta.dy` +100 | no change (scale at its minimum), and the list scrolls to 200 | zooms out (range 0.05 to 0.95), and the list scrolls to 200 | no change (factor at 1), and the list scrolls to 200 |
| Trackpad pinch (pan-zoom events, scale to 1.5) | zooms (scale 1.36). The list stays | zooms (range −0.18 to 1.18). The list stays | no change. The list stays |
| Trackpad vertical two-finger scroll (pan-zoom events, 100 px) | no change. The list scrolls by 80 | no change. The list scrolls by 80 | no change. The list scrolls by 100 |
| Trackpad horizontal two-finger scroll after a pinch | pans. The list stays | no pan | no change (the pinch did not zoom) |

- A wheel event over each chart zooms the chart and also scrolls the parent list. No package
  registers with `GestureBinding.instance.pointerSignalResolver`. The Flutter docs say that the
  resolver "Mediates disputes over which listener should handle pointer signal events". The Flutter
  `InteractiveViewer` of 3.50.0-0.4.pre does not register either.
- For this port, `test/port/handlers_test.dart` pins "a wheel over a ChartView in a ListView zooms
  and does not scroll the list" (`:139`), and "without wheel zoom, the wheel scrolls the list"
  (`:200`). The host registers a prevented `wheel` with the resolver
  ([Chart.js ADR 0108](../../../flutter_chartjs_port/doc/adr/0108-input-surface-and-exports-for-add-on-plugins.md)
  §8).
- Flutter 3.3 and later send the gestures of a desktop trackpad as `PointerPanZoom` events, not as
  scroll signals, where the platform gives enough data. On Windows, the support depends on the
  trackpad driver. On the web, "trackpad scrolling must still use the old `PointerScrollSignal`
  system" (the Flutter breaking-change page). The probe did not run on the web.

## Upstream: from Hammer.js to Pointer Events

- From the first release `0.1.0` (2016-05-04) to `v2.2.0` (2024-11-26), the `dependencies` of
  `package.json` have `hammerjs` `^2.0.8`. The npm latest is still 2.2.0, with `hammerjs`.
- Hammer.js (MIT) has the npm latest 2.0.8 (2016-04-22). The last commit of its `master` is from
  2019-05-28. The repository is not archived.
- At `v2.2.0`, `src/` is JavaScript. `src/plugin.js` imports Hammer.js and starts it only when it
  is present (`:1`, `:74-75`, `:138-139`). The wheel zoom and the drag zoom use DOM listeners with
  no Hammer.js. The README says "[Hammer.js](https://hammerjs.github.io/) is used for gesture
  recognition".
- Issues about Hammer.js: #133, #156 and #174 (2018) asked for docs or an optional Hammer.js. PR
  #270 (merged 2019-09-19) fixed a memory leak of the Hammer.js instance. Issue #917 (2025-01-03,
  open): "Hammer import crashes Rollup build (ESM version)".
- PR #907 (2024-12-04) moved the sources to TypeScript. PR #951 (2026-09-12) scales the wheel zoom
  by the scrolled distance, with the cap `MAX_DELTA = 24` (`src/handlers.ts:250` at the pin).
- PR #950 (opened 2026-09-09, merged 2026-09-16, `9870565676`) replaces Hammer.js with the DOM
  Pointer Events. `src/gestures.ts` has a `GestureManager` with the pan threshold, the modifier-key
  gate of the mouse, the pinch focal point, the cumulative pinch scale and the change from pinch to
  pan when a finger lifts. It sets `touch-action: none` while it is active, "as Hammer did". The
  specs use synthetic `PointerEvent`s (`simulatePan`, `simulatePinch`). micheljung opened the PR,
  and kurkle merged it. The PR text says that Claude Code wrote the change and that micheljung
  reviewed it.
- The pin `fb81d331` (2026-10-02) is 34 commits after `v2.2.0`. It is the head of `master` on
  2026-11-10 ([Zoom ADR 0001](../adr/0001-upstream-sources.md)).

## Ports and wrappers outside Dart

<a id="keystone"></a>

- **`gwinnem/keystone-chartjs-wrappers`** ([GitHub](https://github.com/gwinnem/keystone-chartjs-wrappers),
  TypeScript, MIT, created 2026-09-03, last push 2026-09-07 at `42bbf1611b`). Wrappers of Chart.js
  for Vue, React and Angular. `packages/core/src/plugins/zoom/zoomPlugin.ts` (1,227 lines) is a
  "Local port of `chartjs-plugin-zoom` (v2.2.0, MIT, chartjs-plugin-zoom Contributors)" from the
  dist file. `docs/ZOOM_PLUGIN_PORT_PLAN.md` gives its scope.
  - It drops Hammer.js. Pinch and touch pan use Pointer Events.
  - The pointer path returns at `pointerType === 'mouse'` (`:959`). Thus a mouse drag does not
    pan. Upstream at the pin pans with a mouse, behind its modifier-key gate
    (`src/gestures.ts:51-55`).
  - It calls `setPointerCapture` (`:989`). Upstream at the pin listens on `canvas.ownerDocument`
    (`src/gestures.ts:195-212`).
  - It sets `canvas.style.touchAction = 'none'` (`:1108`).
  - Its last push (2026-09-07) is two days before upstream opened PR #950, and nine days before
    the merge.
- **Charba** ([pepstock-org/Charba](https://github.com/pepstock-org/Charba), Java for GWT and J2CL,
  Apache-2.0, release 6.5 on 2024-02-10). It wraps Chart.js and bundles the plugin 2.0.1
  (`resources/chartjs-plugin-zoom.min.js`). `ZoomPlugin.enable` injects Hammer.js and the plugin
  (`src/org/pepstock/charba/client/zoom/ZoomPlugin.java:113-122`). The options are typed:
  `ZoomOptions extends AbstractPluginOptions` (`ZoomOptions.java:32`), and
  `Plugins.setOptions(T options)` stores them under the id of the plugin
  (`src/org/pepstock/charba/client/configuration/Plugins.java:137`, `:150`).
- **Packages of the JavaScript plugin.** CLJSJS (`nohaapav/chartjs-plugin-zoom`, 2020), WebJars
  (`org.webjars.npm:chartjs-plugin-zoom` 2.2.0), mvnpm (`org.mvnpm:chartjs-plugin-zoom` 2.0.1),
  the npm forks `@foxglove/chartjs-plugin-zoom` and `velo3d-chartjs-plugin-zoom`. The list
  `ohos-ports/ohos-compatible-packages` gives the npm package 2.2.0 as compatible with HarmonyOS.
  None of them is a port.
- crates.io gave no result for "chartjs zoom".

## Pages

- [Chart.js prior art](../../../flutter_chartjs_port/doc/prior-art/README.md): the survey of the
  host port. Its list of leads names `Hexer10/chartjs.dart` as "the only Chart.js plugin binding the
  search found in Dart".
- [D3 prior art](../../../flutter_d3_port/doc/prior-art/README.md): apps with the d3-zoom math in
  Dart.
- [ECharts prior art](../../../flutter_echarts_port/doc/prior-art/README.md) and
  [other JavaScript chart libraries](../../../../docs/prior-art/other-chart-libraries.md): the
  Dart wrappers of other JavaScript chart libraries, which run the library in JavaScript.

## How the survey was done

1. **pub.dev.** Eight queries of the search API ("chartjs-plugin-zoom", "chartjs zoom", "chart.js
   zoom", "chartjs pan", "chart zoom pan", "zoom pan chart", "pinch zoom chart", "chart zoom") and
   three queries sorted by date. The name list `/api/package-names` had 95,072 names at 06:00 UTC
   on 2026-11-10. No name has "zoom" with "chart", "graph" or "plot". The names with "chartjs" or
   "chart_js" are `chartjs`, `chartjs2`, `chartjs_flutter`, `flutter_web_chartjs` and
   `highchartjs`, all in the Chart.js survey.
2. **GitHub code search.** `"chartjs-plugin-zoom" language:dart` gave 38 hits. Each listed file is
   in this repository, except the example of `pakhyunw/flutter_chartjs`. `"plugin-zoom"
   language:dart` found the same example, and its other hits are in this repository.
   `"hammer.min.js" language:dart` found the same example and four files with no chart code
   (copies of a feature detector of `angular_components` and a page template). The upstream names `zoomRectFunctions`, `storeOriginalScaleLimits` and
   `computeDragRect` gave Dart hits only in this repository. Outside JavaScript, TypeScript and
   Dart, they gave the upstream docs and a copy of them, Charba, copies in `.pnpm-store` folders,
   the plan of `keystone-chartjs-wrappers`, the research note of an app that uses the plugin, and
   unrelated code with the generic name `computeDragRect`. None of these is a port.
3. **GitHub repositories and API.** Repository search for the plugin name. The releases of the
   plugin, the comparison `v2.2.0...fb81d331`, PR #950, the issues with "hammer" in the title, and
   the npm registry of `chartjs-plugin-zoom` and `hammerjs`.
4. **Archives.** 17 pub.dev archives, each in its own folder: `fl_chart` 1.3.1,
   `syncfusion_flutter_charts` and `syncfusion_flutter_core` 35.1.43, `graphic` 2.7.0,
   `community_charts_flutter` and `community_charts_common` 1.0.4, `cristalyse` 1.17.6,
   `interactive_chart` 0.3.6, `mp_chart` 0.3.1, `dv_zoom` 1.1.0, `highcharts_flutter` 1.3.0,
   `ar_charts` 0.2.6, `high_chart` 2.8.1, `chartjs_flutter` 1.0.0, `js_widget` 1.0.4, `ensemble`
   1.2.60 and `chart_engine` 3.0.2. The GitHub projects were read through the contents API.
5. **Static examination**, except the [probe](#probe). The survey ran no other package code.
6. **Other languages.** Web search, crates.io and Maven Central for ports of the plugin.

## Limits of the search

A search cannot prove that no port exists. These gaps stay open:

- GitHub code search reads only the default branch of each repository and skips many forks. A port
  under another name or in a fork can stay hidden.
- The survey did not search Gitee, GitLab, Codeberg, PyPI or the Swift Package Index.
- The probe sends synthetic events on the flutter tester. It is not a device run. It did not run
  the web, where a trackpad gives scroll signals.
- A second reader checked the claims against their sources on 2026-11-10, repeated the eight
  pub.dev queries and the GitHub code searches, and ran the probe again with the same results. It
  did not repeat the three pub.dev queries sorted by date, the repository search and the web
  search.
- The survey read only the latest archive of each pub.dev package, and fl_chart 1.3.0 for the
  probe.

## Licenses

- chartjs-plugin-zoom is MIT. Hammer.js is MIT. No Hammer.js code is in the pin.
- fl_chart, graphic, cristalyse, interactive_chart and dv_zoom are MIT. community_charts and
  mp_chart are Apache-2.0. The `CustomInteractiveViewer` of fl_chart keeps the BSD-3-Clause notice
  of The Flutter Authors.
- Syncfusion and Highcharts have their own commercial terms. They are prior art for ideas only.
- The wrappers: `pakhyunw/flutter_chartjs` is MIT, `Hexer10/chartjs.dart` is BSD-3-Clause (Google),
  Charba is Apache-2.0 and `keystone-chartjs-wrappers` is MIT.
- The survey found no GPL code.
- [AGENTS.md](../../../../AGENTS.md) rule 1 applies: each project on this page is prior art only.
  It is neither a source nor a dependency of this port. This port translates only the pinned files
  of `third_party/chartjs-plugin-zoom`.

## What the port takes from this

Each item gives facts first. "Opinion" marks the opinions of the author of this page.

1. **The DOM-like event surface (Chart.js ADR 0108) against a Flutter gesture model.**
   - Fact: each native package maps Flutter gestures directly to its own zoom state. It uses a
     `GestureDetector` or its own recognizers for touch. The wheel goes through
     `Listener.onPointerSignal` or `RenderBox.handleEvent`. No package ports a JavaScript input
     layer.
   - Fact: this port keeps the upstream lines of `src/handlers.ts` and `src/gestures.ts`. The host
     gives the DOM events (seams H3 to H8 of [host-seams.md](../host-seams.md)).
   - Fact: in the probe, a wheel event over fl_chart, graphic and Syncfusion also scrolls the parent
     list. In this port, a prevented `wheel` registers with `pointerSignalResolver`, and the list
     does not scroll (Chart.js ADR 0108 §8, `test/port/handlers_test.dart:139`).
   - Fact: upstream installs the wheel listener only when `zoom.wheel.enabled` is true, and
     prevents the default of a cancelable wheel (`src/handlers.ts:234-237`, `:298-299`). Thus a
     chart without the wheel zoom lets the page scroll (`test/port/handlers_test.dart:200`).
   - Opinion: the survey supports the decision. The DOM-like surface needs the host work of Chart.js
     ADR 0108, but it gives the upstream rules for the wheel and the touch claim with no change of
     the upstream lines. A Flutter-only model would need new code for each of these rules.
2. **Trackpad pan-zoom with no `wheel` event** (Chart.js ADR 0108 Open 5).
   - Fact: since Flutter 3.3, a desktop trackpad gives `PointerPanZoom` events, not scroll signals,
     where the platform gives enough data. The web still gives scroll signals.
   - Fact: in the probe, fl_chart and graphic zoom at a trackpad pinch through their
     `GestureDetector`. fl_chart also pans at a horizontal two-finger scroll. Syncfusion reads
     `PointerPanZoomUpdateEvent` but uses only the sign of `panDelta.dy` (`zooming.dart:666-667`),
     and a pinch with no pan did not zoom in.
   - Fact: the host of this port maps only `PointerScrollEvent` to `wheel`
     (`packages/flutter_chartjs_port/lib/src/platform/chart_host.dart:1709-1718`). A desktop
     trackpad pinch gives no zoom. Chart.js ADR 0108 Open 5 states that Chrome on macOS gives
     `wheel` for a two-finger scroll and a ctrl `wheel` for a pinch.
   - Opinion: the open item is a real gap. Two native packages already zoom at a trackpad pinch. A
     later host ADR can map the pan-zoom updates to `wheel` events in the form of Chrome (the pinch
     as a ctrl `wheel`). Then the upstream wheel code serves the trackpad with no zoom change. The
     ADR needs device evidence, because a pan-zoom pointer goes through the gesture arena, not the
     signal resolver.
3. **The typed plugin options slot** (seam H18, [Zoom ADR 0003](../adr/0003-host-connection.md)
   item 11).
   - Fact: each native package has a typed zoom config: `FlTransformationConfig`,
     `ZoomPanBehavior`, `ZoomConfig` and `PanConfig`, and the range updaters of `RectCoord`.
   - Fact: Charba types the options of a third-party plugin as a class with the id of the plugin
     (`ZoomOptions extends AbstractPluginOptions`) and stores them with `Plugins.setOptions`.
   - Fact: the bindings of `Hexer10/chartjs.dart` have the option form of v0.6, and the plugin
     v0.7.0 had moved the options six months before.
   - Opinion: the survey supports a slot keyed by the plugin id, as in Charba. The drift of the
     Hexer10 bindings shows that a typed options class must change with each bump of the pin.
4. **The zoom state across rebuilds** (seam H20).
   - Fact: fl_chart and Syncfusion keep the zoom across a rebuild. graphic keeps it for new data
     and loses it at a changed specification. community_charts loses it at another axis spec.
     cristalyse loses it at each new data List. The WebView wrapper loads its page again at new
     data.
   - Fact: this port keeps the range for an equal config and for a data-only change, and loses it
     for a changed option and at a theme switch (row `theme-switch-zoom-range` of
     [differences.md](../differences.md), `test/port/index_test.dart`).
   - Opinion: the rule of this port is in the range of the native packages. The callback
     trampolines of seam H18 matter: without them, a rebuild with new closures is a changed option
     and loses the range.
5. **The reset API.**
   - Fact: fl_chart resets through the controller of the app, Syncfusion through `reset()`,
     cristalyse through `PanController.panReset()`, graphic at a double tap. community_charts has no
     reset.
   - Fact: this port gives `chart.resetZoom()` of upstream through the extension `ZoomChart`, on
     the chart of `ChartView.onChartCreated` (seams H9 and H20).
6. **The size of a wheel step.**
   - Fact: upstream scales the zoom by the scrolled distance, with a cap of 24 px (PR #951).
     fl_chart and cristalyse scale by an exponent of the delta. graphic and Syncfusion use a fixed
     step for each event.
   - Fact: Chart.js ADR 0108 Open 4 states that the pixels of one wheel notch differ by embedder.
   - Opinion: the measurement of Open 4 on macOS, Windows and the web stays useful. The fixed steps
     of graphic and Syncfusion hide the difference, but upstream does not.
7. **No gesture library.**
   - Fact: the pin needs no Hammer.js. `keystone-chartjs-wrappers` made the same change by its own
     method before upstream opened PR #950 (2026-09-09). It uses `setPointerCapture` and no mouse
     pan, where upstream listens on the document and pans with a mouse.
   - Fact: this port follows the pin: the document listeners of seam H4 and the mouse pan behind
     the modifier-key gate.
8. **Names.** On 2026-11-10 at 06:00 UTC, the pub.dev API gave 404 for
   `flutter_chartjs_plugin_zoom_port`, `flutter_chartjs_plugin_zoom`, `chartjs_plugin_zoom` and
   `chartjs_zoom` ([ADR 0007](../../../../docs/adr/0007-package-names.md)).
