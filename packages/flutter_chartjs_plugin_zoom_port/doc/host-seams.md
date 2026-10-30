# Host seams: chartjs-plugin-zoom on the Chart.js port

This file lists each place where chartjs-plugin-zoom uses its host: the `chart.js` library and the
DOM of the browser. For each use, it gives the state of `flutter_chartjs_port` and the next step.
[Zoom ADR 0003](adr/0003-host-connection.md) gives the rules. [ADR 0009](../../../docs/adr/0009-add-on-ports.md)
gives the rule for all add-on ports.

- Upstream: chartjs-plugin-zoom `v2.2.0+fb81d331`, the paths of `third_party/chartjs-plugin-zoom/`.
- Host: `flutter_chartjs_port` at commit `62b5477` (2026-10-30), the paths of
  `packages/flutter_chartjs_port/`.
- A person writes this file. Each change that closes a seam updates its row in the same commit.

States:

- `connects`: the public libraries of the host give the use now. A test of the zoom port pins it
  when its module lands.
- `zoom-side`: the zoom port uses a Dart form. The host needs no change. An `adapt` row of
  [differences.md](differences.md) records each form that changes upstream lines.
- `gap`: the host needs a change, with a Chart.js ADR (Zoom ADR 0003 item 2).
- `examine`: the state is not known. A test must show it.

## Summary

| State | Seams |
|---|---|
| `connects` | H1, H14, H15, H16, H20, H21, H22 |
| `zoom-side` | H9, H10, H11, H12 |
| `gap` | H2, H3, H4, H5, H6, H7, H8, H13, H18, H19, H23 |
| `examine` | H17, H24 |

The value imports of `chart.js` and `chart.js/helpers` connect, except one hidden helper (H2). The
chart, scale and plugin APIs connect (H14 to H16, H20 to H22). The gaps are in four places: the DOM
input path (H3 to H8), the JS runtime (H13), the typed API and the theme (H18, H19), and the test
helpers that depend on the input path (H23). The most serious gap is H8: on a touch screen, the
host cancels the pointers after the slop limit, and the zoom pan and pinch stop.

## Imports

| Id | Upstream use | Host port | State | Next step |
|---|---|---|---|---|
| H1 | Value imports of `chart.js/helpers`: `getRelativePosition` (`src/gestures.ts:1`, `src/handlers.ts:3`), `isNumber` and `sign` (`src/core.ts:1`), `almostEquals`, `isNullOrUndef`, `isNumber` and `valueOrDefault` (`src/scale.types.ts:1`). Type imports of `chart.js`: `Chart`, `Scale`, `TimeScale`, `TimeUnit`, `ChartArea`, `ChartEvent`, `UpdateMode`, `Color`, `ChartType`, `ChartTypeRegistry`. | `lib/helpers.dart` exports the six helpers (`doc/public_api.txt`). `lib/chartjs.dart` exports `Chart`, `Scale`, `TimeScale`, `TimeUnit`, `ChartArea` and `ChartEvent`. `UpdateMode`, `Color`, `ChartType` and `ChartTypeRegistry` are TypeScript types only: the Dart forms are `Object?` and `String`. `getRelativePosition(Object event, Chart chart)` is at `lib/src/helpers/helpers.dom.dart:128`. | `connects` | none |
| H2 | `_isPointInArea(point, chart.legend)` (`src/handlers.ts:3`, `:90`): a press on the legend starts no drag. | `isPointInArea` exists (`lib/src/helpers/helpers.canvas.dart:507`). `lib/helpers.dart` hides the 47 `_` names of `chart.js/helpers` (Chart.js ADR 0048 §6, Open 4). | `gap` | Export `isPointInArea` (Zoom ADR 0003 item 3). |

## Input path

| Id | Upstream use | Host port | State | Next step |
|---|---|---|---|---|
| H3 | `canvas.addEventListener` and `removeEventListener` for `pointerdown` (`src/gestures.ts:209`, `:216`), `wheel` and `mousedown` (`src/handlers.ts:41`, `:16`, `:299`, `:305`). The specs call `node.dispatchEvent(event)` (`test/index.js:36`, `:53`, `:60`). | `addCanvasEventListener`, `removeCanvasEventListener` and `dispatchCanvasEvent` (`lib/src/platform/chart_host.dart:112-157`) and `NativeEvent` (`lib/src/platform/native_event.dart`) are not public. `HTMLCanvasElement` has no listener member (`lib/src/canvas/canvas.dart:333-378`). | `gap` | Export the four names from `lib/chartjs.dart` (Zoom ADR 0003 item 4). |
| H4 | `canvas.ownerDocument` listeners: `pointermove`, `pointerup` and `pointercancel` (`src/gestures.ts:195`, `:210-212`), `mousemove` (`src/handlers.ts:109`) and `mouseup` (`:306`). They follow a drag outside the canvas. | No document target. A mouse move or up outside the box gives no event (`chart_host.dart:880-903`). Flutter routes the moves of a pressed pointer to the host also outside its box, so the host has the data. | `gap` | A document target for each canvas (Zoom ADR 0003 item 6). |
| H5 | `window.document` listener `keydown`: the key Escape cancels a drag (`src/handlers.ts:53-63`, `:110`). | No window target. The keyboard of `ChartView` sends key events to the canvas only when `options.events` lists them (Chart.js ADR 0051 §5). | `gap` | `keydown` and `keyup` on the document target (Zoom ADR 0003 item 6). |
| H6 | DOM event fields: `button` (`src/handlers.ts:97`, `src/gestures.ts:269`), `pointerId` (`src/gestures.ts:277`, `:300-352`), `pointerType` (`:53`, `:263`, `:269`), `clientX` and `clientY` (`src/handlers.ts:69-70`, `:270-271`, `src/gestures.ts:38`, `:65-66`), `deltaY` (`src/handlers.ts:263`), `key` (`src/handlers.ts:55`), `ctrlKey`, `altKey`, `shiftKey` and `metaKey` (`src/utils.ts:5-12`), `cancelable` and `preventDefault()` of the wheel event (`src/handlers.ts:235-236`). | `NativeEvent` has only `type`, `offsetX`, `offsetY`, `touches`, `target` and `source` (`native_event.dart:52-82`). `source` is the Flutter event as an opaque value. | `gap` | Add the fields (Zoom ADR 0003 item 5). |
| H7 | `getBoundingClientRect()` of the canvas or of `event.target` (`src/handlers.ts:67`, `:262`, `src/gestures.ts:86`, `:143`, `test/index.js:24`, `:41`, `:84`, `:102`), to turn `clientX` and `clientY` into canvas positions. | `HTMLCanvasElement` has no such member. | `gap` | `getBoundingClientRect()` with the global box of the host (Zoom ADR 0003 item 5). |
| H8 | `canvas.style.touchAction = 'none'`, `userSelect = 'none'` and `setProperty('-webkit-user-select', 'none')`, restored at stop (`src/gestures.ts:200-207`, `:220-222`). The browser then sends all pointer moves to the page and does not scroll. | `CSSStyleDeclaration` has `getPropertyValue`, `getPropertyPriority` and `setProperty` (`canvas.dart:308-326`), no `removeProperty`. `UiCanvasElement` keeps any property, with no effect. The host copies the default `touch-action: auto`: after the touch slop, `pointercancel`, then only `touch*` events (`chart_host.dart:63-67`). It claims nothing in the gesture arena (`:58-60`). Thus the zoom pan and pinch get `pointercancel` at the first long move and stop. | `gap` | The host reads `touch-action` (Zoom ADR 0003 item 7). The zoom port writes `setProperty('touch-action', 'none')` and removes a property with `setProperty(name, null)` (an `adapt` row). |

## Runtime

| Id | Upstream use | Host port | State | Next step |
|---|---|---|---|---|
| H9 | Ten methods on the chart object (`src/plugin.ts:51-62`), declared on `Chart` (`src/index.ts:19-34`). | `Chart` has no access by name. Dart adds no method at run time. | `zoom-side` | The extension `ZoomChart on Chart` (Zoom ADR 0003 item 9). |
| H10 | `new WeakMap<Chart, State>()` (`src/state.ts:43`). | The plugins of the host use an `Expando` (Chart.js ADR 0038 §5). | `zoom-side` | `Expando<State>`. |
| H11 | `setTimeout` and `clearTimeout` of `debounce` (`src/utils.ts:37-44`): `onZoomComplete` 250 ms after the last wheel event (`src/handlers.ts:281-289`, `:300`). | Not a host matter. | `zoom-side` | A `Timer` of `dart:async`. |
| H12 | `console.warn` for the removed options `zoom.enabled` and `overScaleMode` (`src/plugin.ts:74-88`). | The host writes `console.warn` as `print` (`lib/src/core/core.config.dart:872-875`). | `zoom-side` | `print`. |
| H13 | `Math.round` (`src/scale.types.ts:188`, `:225`, `src/core.ts:183`), `Math.log10` and `Math.pow` (`src/scale.types.ts:52-61`), `Math.sign` (`src/handlers.ts:263`), `Math.hypot` (`src/gestures.ts:38`, `:258`), `isNaN` (`src/scale.types.ts:188`). The results reach the scale range: protected sites of Chart.js ADR 0034. | `jsRound` and `jsLog10` exist (`lib/src/js/js_math.dart:45`, `:130`). `lib/src/js/` is not public. | `gap` | `js_semantics` of ADR 0008 (Zoom ADR 0003 item 8). |

## Chart, scale and plugin APIs

| Id | Upstream use | Host port | State | Next step |
|---|---|---|---|---|
| H14 | Writes of the zoomed range into the scale options: `scaleOpts.min = ...` (`src/scale.types.ts:162-163`), `delete scaleOptions.min` (`src/core.ts:151-152`), reads of `scale.options.min` (`src/core.ts:40-41`) and `scale.options.time?.round` (`src/scale.types.ts:256`). | `Scale.options` is the resolver Map (`lib/src/core/core.scale.dart:943`) with the `set` trap (`operator []=`) and the `deleteProperty` trap (`remove`) (`lib/src/helpers/helpers.config.dart:149-231`). | `connects` | A phase 2 test pins the write into the user scale options. |
| H15 | `chart.update(transition)` with the modes `'none'`, `'default'` and the plugin mode `'zoom'` (`src/core.ts:90`, `:120`, `:136`, `:156`, `:233`, `src/handlers.ts:275`). | `Chart.update([Object? mode])` (`lib/src/core/core.controller.dart:1303`) takes any mode. The options `transitions.zoom` resolve by name. | `connects` | none |
| H16 | The plugin object (`src/plugin.ts:64-151`): `id`, `version`, `defaults`, the hooks `start`, `beforeEvent`, `beforeUpdate`, `beforeDatasetsDraw`, `afterDatasetsDraw`, `beforeDraw`, `afterDraw` and `stop`, and `panFunctions`, `zoomFunctions` and `zoomRectFunctions`. `beforeEvent` gives `false` to stop an event. `Chart.register(Zoom)` (`src/index.umd.ts:4`). | Plugin objects are Maps with upstream hook arities (Chart.js ADR 0038). `Chart.register(List)` is public (`core.controller.dart:715`). `core.plugins.dart` notifies `start` and `stop` (`:119`, `:235-236`). | `connects` | none |
| H17 | `Object.prototype.hasOwnProperty.call(options.zoom, 'enabled')` on the plugin options (`src/plugin.ts:74`, `:82-83`). Upstream gets a resolver proxy. `hasOwnProperty` calls its `getOwnPropertyDescriptor` trap. | The resolver is a Map. The Dart form of `hasOwnProperty` on a resolver is not known yet. | `examine` | A phase 4 test with `zoom.enabled` in the options. |
| H20 | An app calls `chart.resetZoom()`, `chart.zoom(...)` and the other methods of H9. | `ChartView` gives the chart through `onChartCreated` (`lib/src/widgets/chart_view.dart:175`). | `connects` | The gallery page. The reconcile of a new `ChartView` config with the `min` and `max` that zoom wrote into the scale options is part of H24. |
| H21 | Scale reads: `id`, `type`, `axis`, `chart`, `min`, `max`, `left`, `top`, `right`, `bottom`, `width`, `height`, `isHorizontal()`, `getValueForPixel()`, `getPixelForValue()`, `parse()`, `getLabels()` (`src/scale.types.ts`, `src/core.ts`, `src/utils.ts`). | All are members of `Scale` (`core.scale.dart:683-798`, `:980`, `:1087`, `:1692`, `:1878`, `:1893`). `getValueForPixel` gives `double?`: the upstream `?? scale.min` (`src/scale.types.ts:90-91`) has the same form. | `connects` | none |
| H22 | Chart reads: `scales`, `chartArea`, `canvas`, `ctx`, `legend`, `draw()` (`src/core.ts`, `src/handlers.ts`, `src/plugin.ts:23-49`). | All are members of `Chart` (`core.controller.dart:772`, `:817`, `:847`, `:898`, `:1588`). `legend` is `types.LegendElement?`. | `connects` | none |

## App surface and tests

| Id | Upstream use | Host port | State | Next step |
|---|---|---|---|---|
| H18 | TypeScript apps type the options with `PluginOptionsByType.zoom` (`src/index.ts:10-12`). | `ChartConfig` (Chart.js ADR 0052, proposed) has no typed slot for the options of a third-party plugin. `ChartConfig.extra` merges Maps deeply (`lib/src/typed/config.dart:176-184`, `lib/src/typed/lower.dart:470-486`). Thus `extra: {'plugins': {'zoom': {...}}}` works now. | `gap` | A typed slot for third-party plugin options in the host (Zoom ADR 0003 item 11). |
| H19 | The drag box colors `'rgba(225,225,225,0.3)'` and `'rgba(225,225,225)'` (`src/plugin.ts:40`, `:45`). | The theme gives no value for `plugins.<id>.*` of a third-party plugin. `theming.md` §5.2 plans `ChartThemeExtension<T>` for "the first ported third-party plugin". | `gap` | The theme extension (Zoom ADR 0003 item 11). |
| H23 | The spec helpers build DOM `WheelEvent`, `MouseEvent` and `PointerEvent` objects with `clientX`, `clientY`, `button`, `ctrlKey`, `pointerId`, `pointerType` and `deltaY`, and dispatch them on the canvas (`test/index.js:22-130`). The other helpers come from chartjs-test-utils (`test/index.js:1-8`). | `chartjs_test_utils` gives `acquireChart`, `releaseChart`, `releaseCharts`, `specsFromFixtures`, `triggerMouseEvent` and the matchers. The DOM event objects need H3, H6 and H7. | `gap` | Closes with H3, H6 and H7. |
| H24 | The 12 fixtures run wheel, drag and pan steps in `options.run` and compare a PNG image (`test/fixtures/zoom/*.js`, `test/fixtures/pan/*.js`). | The fixture runner of the host compares no image (Chart.js ADR 0029, Chart.js ADR 0034 §4). The scale ranges after the steps are the behavior to compare. | `examine` | A reference generator for the scale ranges after each fixture run, in zoom phase 4. |
