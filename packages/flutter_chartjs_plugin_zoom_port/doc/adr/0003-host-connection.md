# Zoom ADR 0003: The connection to the host port

- Status: proposed
- Superseded in part by: [Zoom ADR 0004](0004-native-zoom-pan-callbacks.md) (2026-11-13)
- Date: 2026-10-30
- Revised: 2026-11-10, with the host change of Chart.js ADR 0108 and the design of the zoom
  modules (items 1, 3 to 9 and 12 to 14 are new or rewritten).
- Gate: zoom phase 1 (the host change of Chart.js ADR 0108) and zoom phase 2 (the first ported
  module).
- Related: [ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) (the shared
  JS runtime), [ADR 0009](../../../../docs/adr/0009-add-on-ports.md) (add-on ports),
  [Chart.js ADR 0034](../../../flutter_chartjs_port/doc/adr/0034-no-display-only-js-exactness.md)
  (no display-only JS exactness),
  [Chart.js ADR 0037](../../../flutter_chartjs_port/doc/adr/0037-legend-and-tooltip-input-path.md)
  (the input path of the chart host),
  [Chart.js ADR 0045](../../../flutter_chartjs_port/doc/adr/0045-reference-engine-arm64.md) (the
  JS numeric rules),
  [Chart.js ADR 0048](../../../flutter_chartjs_port/doc/adr/0048-entry-points-and-public-library.md)
  (the public libraries),
  [Chart.js ADR 0050](../../../flutter_chartjs_port/doc/adr/0050-public-theme-api.md) (the theme),
  [Chart.js ADR 0052](../../../flutter_chartjs_port/doc/adr/0052-typed-public-api.md) (the typed
  API), [Chart.js ADR 0054](../../../flutter_chartjs_port/doc/adr/0054-typed-internal-model.md)
  (the typed internal model and the typed plugins),
  [Chart.js ADR 0074](../../../flutter_chartjs_port/doc/adr/0074-incremental-data-updates.md) (the
  data-only updates),
  [Chart.js ADR 0108](../../../flutter_chartjs_port/doc/adr/0108-input-surface-and-exports-for-add-on-plugins.md)
  (the input surface and exports for add-on plugins),
  [Zoom ADR 0001](0001-upstream-sources.md), [Zoom ADR 0002](0002-file-naming-and-layout.md)

## Context

chartjs-plugin-zoom reaches the host library in two ways. It imports public names of `chart.js`
and `chart.js/helpers`. It also uses the DOM of the browser directly: listeners on the canvas and
on the document, the fields of the DOM events, the canvas style, the bounding box of the canvas and
the timers. [host-seams.md](../host-seams.md) lists each use with its upstream lines and the state
of the host port. At the host commit `140f081` (2026-11-10), before Chart.js ADR 0108:

- The public libraries of the Chart.js port gave all value imports but one: `_isPointInArea`.
  `lib/helpers.dart` hid the Dart names of the `_` exports of `chart.js/helpers` (Chart.js ADR
  0048 §6). The Dart function `isPointInArea(Point? point, TRBL? area, [double? margin])` exists
  (`lib/src/helpers/helpers.canvas.dart:523`). `Chart.legend` is a `types.LegendElement?`, which
  was not a `TRBL`.
- The chart host had an internal listener registry for the canvas: `addCanvasEventListener`,
  `removeCanvasEventListener` and `dispatchCanvasEvent` in an `Expando`
  (`lib/src/platform/chart_host.dart:107-160`), with no `passive`, no bubble and no document.
  `NativeEvent` (`lib/src/platform/native_event.dart`) had `type`, `offsetX`, `offsetY`,
  `touches`, `target` and `source`. Zoom also reads `button`, `pointerId`, `pointerType`,
  `clientX`, `clientY`, `deltaY`, `key`, `ctrlKey`, `altKey`, `shiftKey`, `metaKey`, `cancelable`
  and `preventDefault()`. No public library exported these names, and the canvas had no
  `getBoundingClientRect()`.
- A mouse move, up or cancel outside the box gave no event (`chart_host.dart:979-1031`). Zoom
  listens on `canvas.ownerDocument` to follow a drag outside the canvas, and on `window.document`
  for the key Escape. A drag does not focus the chart.
- The host copied the Chrome default `touch-action: auto`. The first touch move past the slop
  limit gave `pointercancel`, then only `touch*` events. The host claimed nothing in the gesture
  arena (`chart_host.dart:58-69`). Zoom sets `touch-action: none` on the canvas
  (`src/gestures.ts:200-201`) to get all pointer moves.
- Zoom adds ten methods to the chart object at run time (`src/plugin.ts:51-62`). The Dart `Chart`
  has no access by name and no run-time methods.
- Zoom writes the scale range into `scale.options` and deletes it (`src/scale.types.ts:163-164`,
  `src/core.ts:146-152`). `Scale.options` is a `CoreScaleOptions`, an extension type over the
  `OptionView` of the scale (Chart.js ADR 0054 §4, `lib/src/core/scale_options.dart:70`). Its face
  has `operator []=` (the `set` trap), `jsDelete` (the `deleteProperty` trap) and `jsHas`
  (`hasOwnProperty`) (`lib/src/helpers/helpers.config.dart:2086-2104`). The plugin options of a
  hook are an `OptionView` with `allKeys: true` too.
- Zoom computes the new scale range with `Math.round`, `Math.min`, `Math.max`, `Math.log10`,
  `Math.pow`, `Math.sign` and `Math.hypot`. The range reaches a scale. Thus Chart.js ADR 0034
  protects these sites. The JS runtime of the Chart.js port (`jsRound`, `jsLog10`) was in
  `lib/src/js/`, not public, and had no `Math.hypot`.
- The seven built-in plugins of the host are typed `Plugin` objects
  (`lib/src/types/plugin.dart:863`, Chart.js ADR 0054 §12), but `Plugin` was internal. A user
  plugin could be a Map, read through `MapPlugin` with a JS-arity call of each hook.

Chart.js ADR 0108 closes the host gaps of the input path, the runtime and the plugin object. This
ADR decides how the zoom port uses the host.

## Decision

1. **Public libraries only** (ADR 0009 item 3). The library code of the zoom port imports
   `package:flutter_chartjs_port/chartjs.dart`, `package:flutter_chartjs_port/helpers.dart`,
   `package:flutter_chartjs_port/js_semantics.dart`, the app library
   `package:flutter_chartjs_port/flutter_chartjs_port.dart`, and Flutter. The tests also import
   `package:chartjs_test_utils/flutter.dart` and `package:chartjs_test_utils/pure.dart`. No file
   of the zoom port imports `package:flutter_chartjs_port/src/` or
   `package:chartjs_test_utils/src/`. `check:lib-imports` fails on such an import.
2. **Host changes first.** Each gap of the host is a change of `flutter_chartjs_port` with a
   Chart.js ADR. The zoom port does not work around a gap with a copy or a `src/` import. A gap
   that stays open blocks the zoom modules that need it. Their parity rows say
   `blocked: host <seam id>`, with the seam ids of [host-seams.md](../host-seams.md).
3. **The `_` helpers that an add-on imports.** `lib/helpers.dart` exports `isPointInArea`
   (Chart.js ADR 0108 §3). `types.LegendElement` implements `TRBL`. Thus the upstream line
   `_isPointInArea(point, chart.legend)` (`src/handlers.ts:90`) is
   `isPointInArea(point, chart.legend)`. Seam H2.
4. **The canvas event target.** The host gives the DOM members of a canvas as the extension
   `CanvasEventTarget` of `chartjs.dart` (Chart.js ADR 0108 §6). The upstream lines keep their
   form: `canvas.addEventListener('pointerdown', onPointerDown)`,
   `canvas.removeEventListener(...)`, `canvas.getBoundingClientRect()`, `canvas.ownerDocument`.
   A listener is a `NativeEventListener`; a method tear-off adds and removes as a JS function
   value does. `addHandler` of `src/handlers.ts:25-42` takes one parameter type for the canvas and
   the document, a `NativeEventTarget`: the canvas passes `canvas.eventTarget` (one object for
   each canvas, so the test `targets[type] === target` of `:31` holds), and the line
   `window.document` (`:110`) becomes `chart.canvas.ownerDocument`. Row
   `adapt-canvas-event-target` of [differences.md](../differences.md). Seam H3.
5. **The DOM event fields.** `NativeEvent` has the fields that zoom reads, with the values that
   Chrome gives (Chart.js ADR 0108 §5): `button`, `buttons`, `pointerId`, `pointerType`,
   `clientX`, `clientY`, `deltaX`, `deltaY`, `deltaMode`, `key`, the four modifier flags,
   `bubbles`, `cancelable`, `defaultPrevented`, `preventDefault()` and `stopPropagation()`. A
   dispatch sets `target`. `clientX` and `clientY` are the logical position in the view.
   `canvas.getBoundingClientRect()` gives a `DOMRect`: the box of the canvas in the same space,
   or `DOMRect.zero` without a laid-out host. Thus the upstream lines `event.clientX - rect.left`
   stay as they are. Seams H6 and H7.
6. **The document target.** `canvas.ownerDocument` is the one document of the isolate. A bubbling
   event of the canvas reaches its listeners after the canvas listeners. The host also sends it
   the moves, the up, the click and the cancel of a mouse that went down on the canvas, while the
   mouse is outside the box. A `HardwareKeyboard` bridge of the host sends it `keydown`,
   `keypress` and `keyup` while it has a listener for them, whichever widget has the focus. The
   zoom port uses no keyboard path of its own. Seams H4 and H5.
7. **`touch-action`.** The host reads the `touch-action` property of the canvas style at the
   start of a touch sequence. With `none`, it does not start the browser pan: no `pointercancel`
   after the slop limit, and the `pointer*` events go on. It claims its touch pointers in the
   gesture arena past the slop or at a second finger, so that a parent scrollable does not take
   them, and a tap of an ancestor still wins inside the slop. A `wheel` that a listener prevents
   claims the pointer signal, so that no parent scrolls (Chart.js ADR 0108 §8). The extension
   `CssStyleProperties` gives `style.touchAction`, `style.userSelect` and
   `style.removeProperty(...)`. Thus the upstream lines `src/gestures.ts:200-207` and `:220-222`
   stay as they are. Seam H8.
8. **The JS runtime.** The zoom port takes `jsObjectKeys`, `jsCall`, `jsGet`, `jsHypot`, `jsMax`,
   `jsMin`, `jsRound`, `jsNumberToString`, `jsToNumber`, `jsToString` and `jsTruthy` from
   `package:flutter_chartjs_port/js_semantics.dart` (Chart.js ADR 0108 §1, ADR 0009 item 4), and
   `log10` (`jsLog10`) and `sign` from `helpers.dart`. When ADR 0008 makes the package
   `js_semantics`, the zoom port imports that package. `Math.hypot` is `jsHypot`. `Math.pow(10,
   x)` stays `math.pow(10.0, x)` with `// js-ok`, the rule of Chart.js ADR 0045: no pure Dart
   form gives the V8 bits on each platform, and a probe on the macOS arm64 VM gave the V8 bits for
   20,000 of 20,000 fractional exponents in [-20, 20]. Seam H13.
9. **Zoom-side forms.** These uses need no host change:
   - The ten `Chart` methods become the Dart extension `ZoomChart on Chart` in
     `lib/src/index.dart`. Each method calls the top-level function of `src/core.ts`, for example
     `chart.resetZoom()`. The file imports `core.dart` with the prefix `core`, because a member
     `zoom` hides the top-level `zoom`. `bindApi` has no Dart body. Row
     `adapt-chart-methods-extension`. Seam H9.
   - The `WeakMap` of `src/state.ts:43` is an `Expando<State>`, as the plugins of the Chart.js port
     do (Chart.js ADR 0038 §5). The gesture managers are an `Expando` too. Seam H10.
   - The zoom port ports its own `debounce` (`src/utils.ts:37-44`) on a `Timer` of `dart:async`.
     The `debounce` of the host helpers has another body. A spec with a wheel pumps 250 ms before
     its end. Seam H11.
   - `console.warn` is `print` with `// ignore: avoid_print`, as `core.config.dart` of the host
     does. Seam H12.
   - The scale range writes go through the face of the scale options:
     `scale.options['min'] = value` and `scale.options.jsDelete('min')`, the `set` and
     `deleteProperty` traps. A read is `scale.options.min`. Seam H14.
   - The update mode `'zoom'` is the String `'zoom'`. `Chart.update` takes any mode. Seam H15.
   - The plugin object is a typed `Plugin` of `chartjs.dart` (Chart.js ADR 0108 §4):
     `final Plugin zoomPlugin = Plugin(supportsDataUpdates: true)`, with the keys in the upstream
     order of `src/plugin.ts:64-151`. `id`, `defaults` and the hooks are fields. `version`,
     `panFunctions`, `zoomFunctions` and `zoomRectFunctions` are extras that `jsWrite` stores. Each
     hook is a private top-level function `(Object chart, <Args> args, Object options)` that casts
     `chart as Chart` once. Row `adapt-typed-plugin-object`. Seam H16.
   - The options are extension-type facades over the raw resolver value, in the form of the host
     `plugin_options.dart`: `ZoomPluginOptions(Object? raw)` and the facades of the upstream
     interfaces (`ZoomOptions`, `PanOptions`, `WheelOptions`, `DragOptions`, `PinchOptions`,
     `ScaleLimits`, `LimitOptions`). A getter gives the raw JS value or the facade of a nested
     value. A plain read `o.k` is `jsGet(o, k)`, and an optional read `o?.k` is
     `isNullOrUndef(o) ? undefined : jsGet(o, k)`. No copy into fields: each read stays live, as
     upstream reads the resolver at each use. `Object.prototype.hasOwnProperty.call(options.zoom,
     'enabled')` (`src/plugin.ts:74`) is `jsHas('enabled')` of the face, the
     `getOwnPropertyDescriptor` trap of upstream. Seam H17.
   - The `defaults` of the plugin are a mutable `Map<String, Object?>` with nested
     `Map<String, Object?>` values, the form that the registry merges. The public library does not
     export them: the name clashes with `defaults` of the host.
   - A user function (`mode`, `onZoom`, `onPanStart`, ...) gets a typed call when the value has the
     type of its typedef, else `jsCall` with JS arity. `null` and `undefined` skip the call, as
     upstream skips a missing callback. The callback contexts are records, for example
     `({Chart chart, ZoomTrigger trigger})`: they compare by value in a spec.
   - Key order: a loop over the scales iterates `jsObjectKeys(chart.scales)`. JS puts the array
     index keys first, and a Dart `Map` keeps the insertion order. Seam H26.
10. **Time scales in tests.** The upstream time-scale specs use chartjs-adapter-date-fns. The Dart
    specs use the default date adapter of the host. A case whose result depends on the adapter
    gets `'diverges: <row id>'` with a row in [differences.md](../differences.md).
11. **Typed API and theme.** Until the host has a typed slot for the options of a third-party
    plugin, an app gives the zoom options through `ChartConfig.extra`
    (`extra: {'plugins': {'zoom': {...}}}`, a deep merge). The zoom port offers a typed options
    class only after a Chart.js ADR decides the slot and how `ChartView` compares the callbacks of
    a third-party options class (seam H18). The colors of the drag box come from the theme only
    after the host has the theme extension of `theming.md` §5.2 (`ChartThemeExtension`, seam H19).
    Until then, the colors are `Color` constants (row `adapt-native-colors`).
12. **Limits are numbers.** `getLimit` of `src/scale.types.ts` converts a raw limit with
    `jsToNumber` and gives a `double`. `ScaleLimits.min` is `number | 'original'`
    (`src/options.ts:194-198`). A string limit is outside the type: upstream then joins strings
    (`'5' + 10`). The range arithmetic stays native. Row `js-semantics-numeric-limits`.
13. **The theme switch loses the range.** `ChartThemeSwitch` of the host writes the recorded user
    scales back into the options. Thus a theme switch loses the range that zoom wrote, as an
    upstream replacement of the options does. A rebuild of `ChartView` with an equal config or a
    data-only change keeps the range; a changed option field loses it, as upstream. The host does
    not change. Row `theme-switch-zoom-range`. Seam H20.
14. **Data-only updates.** The zoom plugin opts into `Chart.updateData`
    (`supportsDataUpdates: true`, Chart.js ADR 0074). Its `beforeUpdate` and its draw hooks change
    no config and no data. Without the opt-in, a global `Chart.register([zoomPlugin])` turns off
    `ChartView.dataOnlyUpdates` for each chart. A test of the zoom port pins the opt-in. If the
    test cannot pass, the plugin ships with the default (false), and `host-seams.md` records it.
    Seam H25.

## Alternatives considered

- **Imports of `src/` of the host.** Rejected by ADR 0009 item 3. The goal of the port is a test
  of the public API.
- **A `Listener` widget of the zoom port over the chart.** Rejected. It duplicates the input path
  of the host and the mapping of Chart.js ADR 0037. Upstream reads the DOM events of the canvas.
  The host already makes them.
- **Exported top-level functions** (`addCanvasEventListener(canvas, type, listener)`, the first
  form of item 4). Rejected. Each upstream call site becomes an `adapt` row, and the canvas and the
  document need different call forms. The extension keeps the upstream lines.
- **`offsetX` in place of `clientX - rect.left`.** Rejected as the main form. It changes 6
  upstream sites and gives no position for a move outside the canvas. Item 5 keeps the lines.
- **Flutter `HardwareKeyboard` in the zoom port for Escape.** Rejected. It is a second keyboard
  path next to the keyboard of `ChartView` (Chart.js ADR 0051). The document of item 6 gives one
  path in the host.
- **Run-time methods through `noSuchMethod`.** Rejected. Dart code calls typed members. An
  extension gives the upstream call form with static types.
- **A Map plugin.** Rejected. A Map emulates a JS object, and the host calls each hook of a Map
  plugin with JS arity. The built-in plugins of the host are typed `Plugin` objects.
- **The runtime in `chartjs.dart`.** Rejected by Chart.js ADR 0108 §1. `chartjs.dart` mirrors the
  `chart.js` entry, and a separate library keeps the move to the package `js_semantics` to one
  import line.
- **A copy of the options into typed fields.** Rejected. The resolver reads stay live, as
  upstream reads the options at each use, and a copy needs a refresh at each update.

## Consequences

- Zoom phase 1 is the host change of Chart.js ADR 0108, with host tests and an update of
  `host-seams.md`.
- The public API list of the host (`doc/public_api.txt`) grows by the names of items 3 to 8 and of
  the typed plugin API.
- The `touch-action` rule of item 7 is new host behavior for each chart whose canvas style has
  `touch-action: none`. Its default stays the behavior of Chart.js ADR 0037.
- The JS runtime need of item 8 is the first need of an add-on for ADR 0008. Until the package
  `js_semantics` exists, `js_semantics.dart` of the host serves it.
- The rows `adapt-canvas-event-target`, `adapt-chart-methods-extension`,
  `adapt-typed-plugin-object`, `adapt-native-colors`, `js-semantics-numeric-limits` and
  `theme-switch-zoom-range` come with the changes that port their hunks.
