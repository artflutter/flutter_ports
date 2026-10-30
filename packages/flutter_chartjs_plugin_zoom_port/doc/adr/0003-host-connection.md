# Zoom ADR 0003: The connection to the host port

- Status: proposed
- Date: 2026-10-30
- Gate: zoom phase 1 (the host changes of items 3 to 7) and zoom phase 2 (the first ported module).
- Related: [ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) (the shared
  JS runtime), [ADR 0009](../../../../docs/adr/0009-add-on-ports.md) (add-on ports),
  [Chart.js ADR 0034](../../../flutter_chartjs_port/doc/adr/0034-no-display-only-js-exactness.md)
  (no display-only JS exactness),
  [Chart.js ADR 0037](../../../flutter_chartjs_port/doc/adr/0037-legend-and-tooltip-input-path.md)
  (the input path of the chart host),
  [Chart.js ADR 0038](../../../flutter_chartjs_port/doc/adr/0038-plugin-modules-class-values-and-interfaces.md)
  (plugin objects as Maps),
  [Chart.js ADR 0043](../../../flutter_chartjs_port/doc/adr/0043-options-representation-and-resolver.md)
  (the resolver),
  [Chart.js ADR 0048](../../../flutter_chartjs_port/doc/adr/0048-entry-points-and-public-library.md)
  (the public libraries and the hide rule of the `_` helpers),
  [Chart.js ADR 0050](../../../flutter_chartjs_port/doc/adr/0050-public-theme-api.md) (the theme),
  [Chart.js ADR 0052](../../../flutter_chartjs_port/doc/adr/0052-typed-public-api.md) (the typed
  API, proposed), [Zoom ADR 0001](0001-upstream-sources.md), [Zoom ADR 0002](0002-file-naming-and-layout.md)

## Context

chartjs-plugin-zoom reaches the host library in two ways. It imports public names of `chart.js`
and `chart.js/helpers`. It also uses the DOM of the browser directly: listeners on the canvas and
on the document, the fields of the DOM events, the canvas style, the bounding box of the canvas and
the timers. [host-seams.md](../host-seams.md) lists each use with its upstream lines and the
state of the host port on 2026-10-30. In summary:

- The public libraries of the Chart.js port give all value imports but one: `_isPointInArea`.
  `lib/helpers.dart` hides the 47 `_` names of `chart.js/helpers` (Chart.js ADR 0048 §6). The
  Dart function `isPointInArea` exists (`lib/src/helpers/helpers.canvas.dart:507`).
- The chart host has a DOM-like event target for the canvas: `addCanvasEventListener`,
  `removeCanvasEventListener` and `dispatchCanvasEvent` (`lib/src/platform/chart_host.dart:112-157`).
  `NativeEvent` is the DOM event (`lib/src/platform/native_event.dart`). No public library exports
  them.
- `NativeEvent` has `type`, `offsetX`, `offsetY`, `touches`, `target` and `source`. Zoom also
  reads `button`, `pointerId`, `pointerType`, `clientX`, `clientY`, `deltaX`, `deltaY`, `key`,
  `ctrlKey`, `altKey`, `shiftKey`, `metaKey`, `cancelable` and `preventDefault()`.
- The host has no document target. For a mouse, it sends no move and no up outside the box
  (`chart_host.dart:880-903`). Zoom listens on `canvas.ownerDocument` to follow a drag outside the
  canvas, and on `window.document` for the key Escape.
- The host copies the Chrome default `touch-action: auto`. The first touch move past the slop
  limit gives `pointercancel`, then only `touch*` events (`chart_host.dart:63-67`). The host
  claims nothing in the gesture arena. Zoom sets `touch-action: none` on the canvas
  (`src/gestures.ts:200-201`) to get all pointer moves. The host keeps the property without effect.
- Zoom adds ten methods to the chart object at run time (`src/plugin.ts:51-62`). The Dart `Chart`
  has no access by name and no run-time methods.
- Zoom writes the scale range into `scale.options` and deletes it (`src/scale.types.ts:162-163`,
  `src/core.ts:146-152`). The Dart `Scale.options` is the resolver Map, with the `set` and
  `deleteProperty` traps (`lib/src/helpers/helpers.config.dart:149-231`).
- Zoom computes the new scale range with `Math.round`, `Math.log10`, `Math.pow`, `Math.sign` and
  `Math.hypot`. The range reaches a scale. Thus Chart.js ADR 0034 protects these sites. The JS
  runtime of the Chart.js port (`jsRound`, `jsLog10`) is in `lib/src/js/`, not public.

## Decision

1. **Public libraries only** (ADR 0009 item 3). The library code of the zoom port imports
   `package:flutter_chartjs_port/chartjs.dart` and `package:flutter_chartjs_port/helpers.dart`,
   and Flutter. It never imports `package:flutter_chartjs_port/src/`. The tests import the public
   libraries and `package:chartjs_test_utils/flutter.dart`.
2. **Host changes first.** Each gap of items 3 to 8 is a change of `flutter_chartjs_port` with a
   Chart.js ADR. The zoom port does not work around a gap with a copy or a `src/` import. A gap
   that stays open blocks the zoom modules that need it. Their parity rows say
   `blocked: host <seam id>`, with the seam ids of [host-seams.md](../host-seams.md).
3. **The `_` helpers that an add-on imports.** The host exports `isPointInArea` from
   `lib/helpers.dart`. The Chart.js ADR of this change supersedes the hide rule of Chart.js ADR
   0048 §6 for the `_` names that a ported add-on imports. Seam H2.
4. **The canvas event target.** `lib/chartjs.dart` exports `NativeEvent`,
   `addCanvasEventListener`, `removeCanvasEventListener` and `dispatchCanvasEvent`. The zoom
   port calls `addCanvasEventListener(canvas, type, listener)` where upstream calls
   `canvas.addEventListener(type, listener)`. That call is an `adapt` row of
   [differences.md](../differences.md). Seam H3.
5. **The DOM event fields.** `NativeEvent` gets the fields that zoom reads, with the values that
   Chrome gives: `button`, `pointerId`, `pointerType`, `clientX`, `clientY`, `deltaX`, `deltaY`,
   `key`, the four modifier flags, `cancelable` and `preventDefault()`. It also gets `buttons`,
   `deltaMode` and `defaultPrevented`, the fields of the same DOM events that an app or a later
   plugin reads with them. The host fills them from the Flutter event and `HardwareKeyboard`.
   `clientX` and `clientY` are the global logical position of the pointer. The canvas gets
   `getBoundingClientRect()`: the global box of its host in logical pixels, or a zero box without a
   host. Thus the upstream lines `event.clientX - rect.left` stay as they are. Seams H6 and H7.
6. **The document target.** The host gives a document target for each canvas. It sends the moves,
   the ups and the cancels of the pointers that went down on the canvas, also outside the box, as
   the DOM document gets them. It also sends `keydown` and `keyup` while the target has a listener
   for them. The zoom port uses it where upstream uses `canvas.ownerDocument` and
   `window.document`. Seams H4 and H5.
7. **`touch-action`.** The host reads the `touch-action` property of the canvas style. With
   `none`, it does not start the browser pan: no `pointercancel` after the slop limit, and the
   `pointer*` events continue. It also claims the touch pointers in the gesture arena, so that a
   parent scrollable does not take them. With any other value, the behavior of Chart.js ADR 0037
   stays. Seam H8.
8. **The JS runtime.** The zoom port takes `jsRound`, `jsLog10` and the other JS math functions
   from `js_semantics` (ADR 0008, ADR 0009 item 4). The zoom phase that ports `scale.types` and
   `core` needs it. Thus that phase brings stage 1 of ADR 0008 forward, or waits for it. Seam H13.
9. **Zoom-side forms.** These uses need no host change:
   - The ten `Chart` methods become the Dart extension `ZoomChart on Chart`. Each method calls
     the top-level function of `src/core.ts`, for example `chart.resetZoom()`. `bindApi` has no
     Dart body. An `adapt` row records it. Seam H9.
   - The `WeakMap` of `src/state.ts:43` is an `Expando<State>`, as the plugins of the Chart.js port
     do (Chart.js ADR 0038 §5). Seam H10.
   - `setTimeout` and `clearTimeout` of `debounce` (`src/utils.ts:37-44`) are a `Timer` of
     `dart:async`. Seam H11.
   - `console.warn` is `print`, as `core.config.dart:872` of the host does. Seam H12.
   - The scale range writes go through `scale.options['min'] = value` and
     `scale.options.remove('min')`, the resolver traps. Seam H14.
   - The update mode `'zoom'` is the String `'zoom'`. `Chart.update` takes any mode. Seam H15.
   - The plugin object is a Map with the upstream keys in the upstream order, with the hooks of the
     upstream parameter counts (Chart.js ADR 0038). It keeps `panFunctions`, `zoomFunctions` and
     `zoomRectFunctions`, which an app extends for a custom scale. Seam H16.
10. **Time scales in tests.** The upstream time-scale specs use chartjs-adapter-date-fns. The Dart
    specs use the default date adapter of the host. A case whose result depends on the adapter
    gets `'diverges: <row id>'` with a row in [differences.md](../differences.md).
11. **Typed API and theme.** Until the host has a typed slot for the options of a third-party
    plugin, an app gives the zoom options through `ChartConfig.extra`
    (`extra: {'plugins': {'zoom': {...}}}`, a deep merge, `lib/src/typed/config.dart:176-184`). The
    zoom port offers a typed options class only after the host decides the slot (Chart.js ADR 0052,
    seam H18). The colors of the drag box come from the theme only after the host has the theme
    extension of `theming.md` §5.2 (`ChartThemeExtension`, seam H19).

## Alternatives considered

- **Imports of `src/` of the host.** Rejected by ADR 0009 item 3. The goal of the port is a test
  of the public API.
- **A `Listener` widget of the zoom port over the chart.** Rejected. It duplicates the input path
  of the host and the mapping of Chart.js ADR 0037. Upstream reads the DOM events of the canvas.
  The host already makes them.
- **`offsetX` in place of `clientX - rect.left`.** Rejected as the main form. It changes 6
  upstream sites and gives no position for a move outside the canvas. Item 5 keeps the lines.
- **Flutter `HardwareKeyboard` in the zoom port for Escape.** Rejected. It is a second keyboard
  path next to the keyboard of `ChartView` (Chart.js ADR 0051). The document target of item 6
  gives one path.
- **Run-time methods through `noSuchMethod`.** Rejected. Dart code calls typed members. An
  extension gives the upstream call form with static types.

## Consequences

- Zoom phase 1 is a set of host changes: items 3 to 7, each with a Chart.js ADR, tests in the host
  port and an update of `host-seams.md`.
- The public API list of the host (`doc/public_api.txt`) grows by the names of items 3 and 4.
- The `touch-action` rule of item 7 is new host behavior for every chart. Its default stays the
  behavior of Chart.js ADR 0037.
- The JS runtime need of item 8 is the first need of an add-on for ADR 0008.
