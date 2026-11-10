# Chart.js ADR 0108: The input surface and exports for add-on plugins

- Status: accepted (2026-11-10). The host wave of the zoom port (`140f081..0b09600`) is on `main`,
  and the full pre-push list passed. The lead accepted it by the maintainer's rule of 2026-10-31: a
  record is accepted when its code passes the tests.
- Date: 2026-11-10
- Gate: the code and the tests of section 13 pass. The lead then accepts this ADR (the maintainer
  rule of 2026-10-31). The device check of `touch-action: none` (Open 1) is evidence, not a gate.
- Related: [ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) (the shared
  JS runtime), [ADR 0009](../../../../docs/adr/0009-add-on-ports.md) (add-on ports),
  [Zoom ADR 0003](../../../flutter_chartjs_plugin_zoom_port/doc/adr/0003-host-connection.md) (the
  host connection of chartjs-plugin-zoom),
  [host-seams.md](../../../flutter_chartjs_plugin_zoom_port/doc/host-seams.md) of the zoom port,
  Chart.js ADRs 0022, 0029, 0034, 0037, 0045, 0048, 0051, 0054, 0074 and 0098.
- Supersedes, in part: Chart.js ADR 0022 §3 and §6, Chart.js ADR 0037 §8, §10, §11 and Open 3,
  Chart.js ADR 0048 §5 and §6, Chart.js ADR 0051 §4 and §5, Chart.js ADR 0054 §12 and Open 2.
  Section 14 gives each part.

## Context

chartjs-plugin-zoom is the first add-on port (ADR 0009,
`packages/flutter_chartjs_plugin_zoom_port`). By ADR 0009 item 3 and Zoom ADR 0003, it imports only
the public libraries of this package. The
`host-seams.md` file of the zoom port lists each use of the host. At commit `140f081` (2026-11-10),
these uses had no public form:

- **`_isPointInArea`** of `chart.js/helpers` (`src/handlers.ts:3`, `:90` of the plugin): a press on
  the legend starts no drag. `lib/helpers.dart` hid `isPointInArea` with the other Dart names of the
  upstream `_` exports (Chart.js ADR 0048 §6). `types.LegendElement`, the type of `chart.legend`,
  was not a `TRBL`, so the call did not compile with the public types. Upstream, `LegendElement`
  extends `Element` and `LayoutItem`, and has the box edges.
- **The `EventTarget` of the canvas and of its document.** The plugin calls `addEventListener` with
  `{passive}` and `removeEventListener` on `chart.canvas`, on `canvas.ownerDocument` and on
  `window.document` (`src/handlers.ts:16`, `:41`, `:109-110`, `:306`, `src/gestures.ts:195`,
  `:209-219`). Its specs call `node.dispatchEvent(event)` and
  `document.documentElement.dispatchEvent(event)`. They need the bubble from the canvas to the
  document: the specs dispatch `mouseup`, `pointerup` and `pointercancel` on the canvas, and the
  plugin listens for them on the document (`test/index.js:22-130`, `test/specs/pan.spec.js:400`).
  The host had an internal registry in an `Expando` on the canvas (`addCanvasEventListener`,
  `dispatchCanvasEvent`, Chart.js ADR 0037 §11), with no `passive`, no bubble and no document.
- **The fields of the DOM event.** `NativeEvent` had `type`, `offsetX`, `offsetY`, `touches`,
  `target` and `source`. The plugin also reads `button`, `pointerId`, `pointerType`, `clientX`,
  `clientY`, `deltaY`, `key`, `ctrlKey`, `altKey`, `shiftKey`, `metaKey` and `cancelable`, and it
  calls `preventDefault()`. No public library exported `NativeEvent`, though `ChartEvent.native`
  has that type.
- **`getBoundingClientRect()`** of the canvas (`src/handlers.ts:67`, `:262`, `src/gestures.ts:86`,
  `:143`). The plugin turns `clientX` into a canvas position with `clientX - rect.left`.
- **A mouse outside the box.** A pressed mouse that leaves the box still reaches
  `RenderChartHost.handleEvent`: Flutter gives each event of a pointer that is down to the hit path
  of its down. The host dropped these events, because a mouse has no implicit capture (Chart.js
  ADR 0037 §6). The plugin ends a drag at the `mouseup` of the document.
- **Keys without the focus.** The plugin cancels a drag at an Escape `keydown` on the document
  (`src/handlers.ts:53-63`). A drag on the chart does not focus it. The keyboard of `ChartView`
  (Chart.js ADR 0051 §5) sends key events only to a focused canvas, and only for the types of
  `options.events`.
- **`touch-action`.** The plugin writes `canvas.style.touchAction = 'none'`, `style.userSelect`
  and `style.removeProperty(...)` (`src/gestures.ts:200-207`, `:220-222`) to get each pointer
  move of a pan or a pinch. The host copied the default `touch-action: auto`: past the slop limit,
  `pointercancel`, then only `touch*` events (Chart.js ADR 0037 §8). It claimed nothing in the
  gesture arena (§10). Thus a pan in a scrollable stopped at the first long move.
  `CSSStyleDeclaration` had no `touchAction`, `userSelect` or `removeProperty`.
- **The JS runtime.** The plugin computes the scale range with `Math.round`, `Math.min`,
  `Math.max`, `Math.hypot` and the JS conversions. The range reaches a scale, so Chart.js ADR 0034
  protects these sites. `lib/src/js/` was internal, and `Math.hypot` had no port. On the reference
  engine of Chart.js ADR 0045, `math.sqrt(a * a + b * b)` differs from `Math.hypot` on 123,918 of
  200,000 random pairs. The form that scales by the larger magnitude differs on none.
- **The plugin object.** The seven built-in plugins are typed `Plugin` objects (Chart.js ADR 0054
  §12), but `Plugin` stayed internal "until the typed public plugin API (Open 2)". An add-on could
  only give a Map plugin: an emulation of a JS object, with a JS-arity call for each hook. A Map
  plugin opts into `Chart.updateData` (Chart.js ADR 0074) only with an own key
  `supportsDataUpdates`, which upstream does not have. A registered plugin that does not opt in
  turns off the data-only updates of `ChartView` for each chart (Chart.js ADR 0098).

Two facts limit the form of the changes:

- `HTMLCanvasElement` has 14 implementers in the tests: 4 full fakes and 10 `noSuchMethod` fakes.
  `CSSStyleDeclaration` has 7. A new interface member breaks the full fakes, and it makes the
  `noSuchMethod` fakes throw where the `Expando` registry works with any canvas.
- The upstream lines of the plugin keep their form only when the Dart members have the DOM names:
  `canvas.addEventListener(type, listener)`, `canvas.getBoundingClientRect()`,
  `canvas.ownerDocument`, `style.touchAction = 'none'`.

## Decision

The behavior of a chart with no add-on does not change, except the four points of section 12.
The reference data of `chart_host_input_test.dart` stays byte-identical.

### 1. Four public libraries, and the JS runtime library

The package has four public libraries. The new one is the port-only `lib/js_semantics.dart`, the JS
runtime for add-on ports:

```dart
export 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
export 'package:flutter_chartjs_port/src/js/js_function.dart' show jsCall;
export 'package:flutter_chartjs_port/src/js/js_math.dart'
    show jsHypot, jsMax, jsMin, jsRound;
export 'package:flutter_chartjs_port/src/js/js_number.dart'
    show jsNumberToString, jsToNumber, jsToString, jsTruthy;
export 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
```

- The 11 functions keep their signatures.
- `chartjs.dart` and the app library do not export it. An app does not need it.
- When the package `js_semantics` of ADR 0008 exists, this library exports that package, and a
  later ADR retires the library. An add-on then changes one import line.
- `log10` of `helpers.dart` is already `jsLog10` (`helpers.math.dart`).

### 2. `jsHypot`

`lib/src/js/js_math.dart` (a pure layer) gets `double jsHypot(double a, double b)`, the V8 form of
`Math.hypot` with two operands:

1. +Infinity when an operand is infinite, also with a NaN operand.
2. Else NaN when an operand is NaN.
3. Else +0 when both magnitudes are 0.
4. Else `math.sqrt(p * p + q * q) * m`, with `m` the larger magnitude, `p = |a| / m` and
   `q = |b| / m`.

Each step is a correctly rounded IEEE operation. Thus the VM, dart2js and dart2wasm give the bits
of V8. With two operands, the Kahan compensation of the V8 builtin adds nothing.

`tool/reference/hypot_reference.mjs` writes `test/port/js/hypot_reference.dart`: 3,000 inputs
(each pair of 22 special values, Pythagorean triples scaled by powers of two, equal magnitudes,
pointer deltas of a pan or a pinch, small integers, subnormal operands and random operands) on
Node.js v24.22.1 darwin-arm64, V8 13.6.233.17-node.58. The plain form differs on 1,714 of them.

### 3. `isPointInArea` and `LegendElement`

- `lib/helpers.dart` exports `isPointInArea`. The rule: the Dart name of an upstream `_` export
  that a ported add-on imports is public. The list has one name: `isPointInArea` of
  `_isPointInArea`. The other Dart names of the upstream `_` exports stay hidden.
- `types.LegendElement` implements `TRBL`. `Legend` of `plugin.legend.dart` already has the four
  edges, as an `Element`, a `LayoutItem` and a `TRBL`. Thus the zoom line
  `isPointInArea(getRelativePosition(event, chart), legend)` compiles with the public types.

### 4. The typed plugin API

`lib/chartjs.dart` exports these names of `lib/src/types/plugin.dart`: `Plugin`,
`PluginHookFunction`, `PluginHookArgs`, `UpdateHookArgs`, `CancelableHookArgs`, `ResizeHookArgs`,
`DatasetUpdateHookArgs`, `DatasetDrawHookArgs`, `EventHookArgs` and `TooltipDrawHookArgs`.

- `Plugin({bool supportsDataUpdates = false, bool Function(Object options)? dataUpdateGuard})`
  makes a plugin with no own keys. The fields and the face (`jsWrite`) add the keys in the order of
  the writes, as upstream adds the keys of an object literal. A key that `Plugin` does not declare
  (for example `version` or `zoomFunctions` of the zoom plugin) is an extra of the face.
- `Plugin.hookValue` and `Plugin.invokeHook` get `@internal`: the plugin service calls them.
  `PluginHook` and `MapPlugin` stay internal.
- The hook type keeps the internal chart interface:
  `PluginHookFunction<A> = Object? Function(types.Chart chart, A args, Object options)`. A hook of
  an add-on declares its chart parameter as `Object`, a supertype, and casts it to `Chart` once:

  ```dart
  Object? _beforeEvent(Object chart, EventHookArgs args, Object options) {
    final c = chart as Chart;
    ...
  }

  final Plugin zoomPlugin = Plugin(supportsDataUpdates: true)
    ..id = 'zoom'
    ..jsWrite('version', chartjsPluginZoomPackageVersion)
    ..beforeEvent = _beforeEvent;
  ```

  `Chart` is the only implementer of `types.Chart` outside the tests. No new public name serves
  one cast.
- A plugin of the type `Plugin` sets `supportsDataUpdates` in its constructor (Chart.js ADR 0074),
  outside its JS own keys. Its hooks then run in a data-only update, and
  `ChartView.dataOnlyUpdates` stays on for its charts. `dataUpdateGuard` can decline an update for
  the resolved options of the plugin.
- Map plugins keep working, as before (`MapPlugin`, Chart.js ADR 0054 §12).

### 5. The event model

`lib/src/platform/native_event.dart` stays a pure layer. It has these public names:

```dart
typedef NativeTouch = ({int identifier, double x, double y});

typedef NativeEventListener = void Function(NativeEvent event);

abstract interface class NativeEventTarget {
  void addEventListener(String type, NativeEventListener listener, {bool? passive});
  void removeEventListener(String type, NativeEventListener listener);
  bool dispatchEvent(NativeEvent event);
}

@immutable
final class DOMRect {
  const DOMRect(this.x, this.y, this.width, this.height);
  static const DOMRect zero = DOMRect(0, 0, 0, 0);
  final double x, y, width, height;
  double get left;   // min(x, x + width)
  double get top;    // min(y, y + height)
  double get right;  // max(x, x + width)
  double get bottom; // max(y, y + height)
}

final class NativeEvent {
  NativeEvent({
    required String type,
    required double offsetX,
    required double offsetY,
    List<NativeTouch> touches = const [],
    Object? target,
    Object? source,
    bool bubbles = false,
    bool cancelable = false,
    double clientX = 0,
    double clientY = 0,
    int button = 0,
    int buttons = 0,
    int pointerId = 0,
    String pointerType = '',
    double deltaX = 0,
    double deltaY = 0,
    int deltaMode = 0,
    String key = '',
    bool ctrlKey = false,
    bool altKey = false,
    bool shiftKey = false,
    bool metaKey = false,
  });
  Object? get target;          // set by a dispatch
  bool get defaultPrevented;
  void preventDefault();       // only when cancelable, and not in a passive listener
  void stopPropagation();      // the dispatch ends after the current target
}
```

- Each optional field has the default of its DOM init dictionary (`EventInit`, `MouseEventInit`,
  `PointerEventInit`, `WheelEventInit`, `KeyboardEventInit`).
- One flat class stands for each DOM event interface. Thus a listener has one type for each event
  name, as the DOM registry keys the listeners by a string. Each field is a plain typed field.
- A listener is the same listener when it is `==`. Two tear-offs of one method of one object are
  `==`, so a method tear-off adds and removes as a JS function value does.
- A listener that the target already has for a type is not added again. The first `passive` value
  stays.
- `DOMRect` compares by value.
- Three `@internal` helpers serve the dispatch: `invokeNativeEventListener` (the passive flag),
  `setNativeEventTarget` (the target, and the stop flag cleared, as the DOM clears it after each
  dispatch) and `nativeEventStopped`.
- `deltaZ`, `isPrimary`, `repeat`, `code`, `screenX`, `screenY`, `currentTarget` and the capture
  phase are not added: no ported code and no zoom code reads them.

The host fills the fields of each event with the values of Chrome. It computes the fields of one
Flutter event once, and makes one `NativeEvent` for each type that has a listener:

| Field | Value |
|---|---|
| `clientX`, `clientY` | `PointerEvent.position`, the logical position in the view. The pan-begin cancels: (0, 0) (Chart.js ADR 0037 §6). The compatibility events of a tap or a long press: the position of the tap point. NaN where `offsetX` is NaN (`touch*` events and key events). |
| `button` | Mouse-like `pointerdown` and `mousedown`: the index of the pressed bit (1 gives 0, 4 gives 1, 2 gives 2, 8 gives 3, 16 gives 4). Mouse-like `pointerup` and `mouseup`: the index of the lowest bit of the last buttons of that pointer (Flutter sends one up when all buttons are up). `click`: 0. Touch-like `pointerdown` and `pointerup`: 0. Other `pointer*` events: -1 (no change). `mouse*`, `wheel`, `touch*` and key events: 0. |
| `buttons` | Mouse-like: `PointerEvent.buttons`, whose bits are the DOM bits. Touch-like in contact: 1, the stylus barrel 2, an inverted stylus 32 (the eraser bit); 0 at `pointerup`, `pointercancel`, `pointerout` and `pointerleave`. `touch*` events: 0 (a `TouchEvent` has no `buttons`). The compatibility events of a tap: `mousedown` 1, the others 0. Key events: 0. |
| `pointerId` | `pointer*` and `click`: a mouse-like pointer 1. A touch-like pointer: an id from a counter of the isolate that starts at 2, taken at the down and freed after the events of its up or cancel. Other events: 0. |
| `pointerType` | `pointer*` and `click`: `'mouse'` for a mouse and a trackpad, `'touch'`, `'pen'` for a stylus and an inverted stylus, `''` for an unknown kind. Other events: `''`. |
| `deltaX`, `deltaY`, `deltaMode` | `wheel`: `PointerScrollEvent.scrollDelta` in logical pixels (positive is down and right, as the DOM), `deltaMode` 0. Other events: 0. |
| `key` | Key events: the UI Events key value (`domKeyValue` of `chart_host.dart`). A table gives the named keys (`Escape`, `Enter`, `Tab`, `Backspace`, `Delete`, `Insert`, `Home`, `End`, `PageUp`, `PageDown`, the four arrows, `Shift`, `Control`, `Alt`, `Meta`, `CapsLock`, `ContextMenu`, `F1` to `F12`, `' '`). Else the character of a down or a repeat. A `KeyUpEvent` has no character in Flutter: it gives the character of the last down of its physical key. Else `'Unidentified'`. |
| `ctrlKey`, `altKey`, `shiftKey`, `metaKey` | `HardwareKeyboard.instance` when the host makes the event. Flutter updates the pressed keys before it calls the handlers, so the down of Control has `ctrlKey` true and its up false, as in the DOM. |
| `bubbles` | False for `pointerenter`, `pointerleave`, `mouseenter` and `mouseleave`, true for the other events. The key events of `ChartKeyboard`: false (section 7). |
| `cancelable` | False for `pointerenter`, `pointerleave`, `pointercancel`, `mouseenter`, `mouseleave`, `touchcancel`, and for a `touchmove` after the pan begin (Chrome sends uncancelable moves while it scrolls). True for the other events, `wheel` included. |
| `target` | Set by the dispatch: the canvas, or the document for an event of the document only. |

### 6. The canvas target and the document

`lib/src/platform/chart_host.dart` gives the DOM members of a canvas as extension members:

```dart
extension CanvasEventTarget on HTMLCanvasElement {
  void addEventListener(String type, NativeEventListener listener, {bool? passive});
  void removeEventListener(String type, NativeEventListener listener);
  bool dispatchEvent(NativeEvent event);
  NativeEventTarget get ownerDocument;
  NativeEventTarget get eventTarget;
  DOMRect getBoundingClientRect();
}
```

- An extension works on each `HTMLCanvasElement`, also on a fake of a test, and changes no
  implementer. The listeners stay on the canvas element in the `Expando` registry, also while no
  host shows it (Chart.js ADR 0037 §11).
- `addEventListener` with a Dart `null` `passive` takes the DOM default of an element: false.
- `dispatchEvent` sets the target to the canvas and calls the canvas listeners of `event.type` in
  the order of registration. Then, for a bubbling event that no listener stopped, it calls the
  listeners of the document, with the canvas as the target: the bubble phase of the DOM. It gives
  `!event.defaultPrevented`. A listener that a listener adds or removes takes effect with the next
  event of its target.
- `ownerDocument` is the one document of the isolate, as a page has one document and the isolate
  has one compatibility mouse (Chart.js ADR 0037 §9). The zoom line `window.document` becomes
  `chart.canvas.ownerDocument`.
- `eventTarget` is the canvas as a `NativeEventTarget`, so that one parameter type takes the canvas
  and the document (`addHandler` of the zoom plugin). An `Expando` keeps one object for each
  canvas: two reads are `==`, as two reads of a DOM element are `===`.
- `getBoundingClientRect()` gives `RenderChartHost.boundingClientRect` when an attached, laid-out
  host shows the canvas: the host origin and the display size of the canvas, through
  `getTransformTo(null)`, in the logical pixels of the view, the space of `clientX`. For a host
  with no transform, `clientX - rect.left` is `offsetX`. A rotated or scaled host gives the
  axis-aligned box of the transformed canvas, as the DOM does. Any other canvas gives
  `DOMRect.zero`, as a DOM element outside the document does.

The four top-level functions stay internal: `addCanvasEventListener` (now with `{bool passive =
false}`), `removeCanvasEventListener`, `hasCanvasEventListener` and `dispatchCanvasEvent`, which
gives a `bool` and runs the bubble phase. The ported platform and the keyboard of `ChartView` call
them.

The document is the internal class `CanvasDocument` (`CanvasDocument.instance`), a
`NativeEventTarget`:

- `addEventListener` with a Dart `null` `passive` takes the DOM default of the document: true for
  `wheel`, `mousewheel`, `touchstart` and `touchmove`, else false.
- `dispatchEvent` is the port of `document.documentElement.dispatchEvent`: it sets the target to
  the document and calls only the document listeners.
- `hasListener(type)`, and for tests `@visibleForTesting debugListenerCount` and `debugKeyBridge`.

The host sends these events to the listeners:

| Pointer | Inside the box | Outside the box |
|---|---|---|
| touch-like, down on the host | the canvas; a bubbling event then reaches the document | the same: the host already sends the moves and the up of a touch-like pointer outside the box to the canvas (the implicit capture of a touch) |
| mouse-like, down on the host | the canvas; a bubbling event then reaches the document | the document only, with the document as the target: `pointermove` and `mousemove`, `pointerup` and `mouseup`, then `click` when the click rule of Chart.js ADR 0037 §7 holds (the DOM sends that click to the common ancestor), and `pointercancel` |
| a hover of a mouse that is not down | the canvas, then the document | nothing: the host is not on the hit path of a hover |
| a pointer that went down elsewhere | nothing | nothing (Chart.js ADR 0037 Open 7) |

An event of the document only has the offsets in the coordinates of the host. A detach, a dispose
or a canvas swap ends the document events of a pointer. The canvas still gets no mouse event
outside the box (Chart.js ADR 0037 §6).

### 7. Keys

- While the document has a `keydown`, `keypress` or `keyup` listener, one `HardwareKeyboard`
  handler sends it each key of the app, whichever widget has the focus, as the DOM document gets
  each key of the page. The handler goes with the last key listener: no listener, no cost. Each new
  key listener removes and adds the handler again, because the test binding clears the keyboard
  handlers after each test.
- The mapping is that of Chart.js ADR 0051 §5: `KeyDownEvent` and `KeyRepeatEvent` give `keydown`,
  and then `keypress` for an event with a character; `KeyUpEvent` gives `keyup`. A prevented
  `keydown` gives no `keypress`, as in the DOM. Each event has NaN offsets and client point, `key`,
  the modifiers, `bubbles` and `cancelable` true and the `KeyEvent` as `source`.
- The handler gives true when a listener prevented the default. The event then does not reach the
  text input and the platform, as a prevented DOM key has no default action. The focus tree still
  gets the event.
- The `HardwareKeyboard` handlers run before the focus tree. Thus the document gets a key before
  the key listeners of a focused `ChartView`. The DOM order is the reverse (Open 8). No ported
  listener, no widget listener and no zoom listener depends on the order.
- The key events that `ChartKeyboard` sends to a focused canvas (Chart.js ADR 0051 §5) have
  `bubbles: false`, `cancelable: true`, NaN client point, `key` and the modifiers. Thus the
  document gets each key once, from its handler.
- The virtual mouse events of `ChartKeyboard` (Chart.js ADR 0051 §4) bubble, with the mouse
  fields: the client point from `canvas.getBoundingClientRect()`, `button` 0, `buttons` 1 for
  `mousedown`, the modifiers. Enter on a target sends `mousedown` and `mouseup`. The zoom plugin
  starts a drag at the `mousedown` of the canvas and ends it at the `mouseup` of the document.
  Without the bubble, the drag state stays, and the next arrow key makes the plugin block each
  chart event.

### 8. `touch-action` and the wheel

At a touch-like down that starts a touch sequence of the host (no touch-like pointer of the host
is down), the host reads `touch-action` of the canvas style. The value `none` (after trim, in
lower case) holds for the whole sequence, as Chrome fixes the touch action at the start of a
touch. A change in a sequence acts at the next sequence. Only the canvas style counts: the port
has no ancestor elements.

With `none`:
- The pan does not begin: no `pointercancel`, `pointerout` and `pointerleave` at the view origin.
  The `pointer*` and `touch*` events go on, and `touchmove` stays cancelable. The rule "more than
  2 touch-like pointers" does not begin a pan either.
- The tap candidate ends at its first move past the slop limit of Chart.js ADR 0037 §8: no `click`
  and no compatibility event for that pointer. Inside the limit, the candidate keeps the rule D1
  (`pointermove` only).
- The host claims its touch-like pointers in the gesture arena. It adds one arena member at the
  down of each touch-like pointer. It accepts the arena of a pointer that moves farther than
  `computeHitSlop(event.kind, gestureSettings)` from its down, and the arenas of all its
  touch-like pointers at a second touch-like down (a scale recognizer of an ancestor, for example
  `InteractiveViewer`, can accept on the change of the span before a finger passes the slop). The
  claim slop is the hit slop alone: it has no Chromium epsilon (the 0.05 of the slop limit of
  Chart.js ADR 0037 §8) and no stylus factor (the 1.5 of that limit). Thus a stylus claims at the
  hit slop, while its tap candidate ends at 1.5 times the touch slop; a case of
  `chart_host_test.dart` pins it. It
  rejects the arena of a pointer that lifts or cancels before an accept, before the sweep of
  `GestureBinding.handleEvent`. Thus an ancestor tap inside the slop still wins: the DOM click of a
  `touch-action: none` canvas still bubbles to its ancestors. A detach, a dispose and a canvas swap
  reject the open entries.
- The host sees the move before the recognizers: its entry of the hit path is deeper than the
  route of each recognizer, which runs in `GestureBinding.handleEvent`. Thus it wins a tie with a
  drag recognizer of a parent scrollable.

With any other value (`auto`, `pan-x`, `pan-y`, `manipulation`, `pinch-zoom`), Chart.js ADR 0037
§8 and §10 apply unchanged (Open 7). The mouse-like kinds need no claim: the default
`ScrollBehavior.dragDevices` has no mouse, and `touch-action` applies to touch and pen only.

A `wheel` whose dispatch gives false (a listener that is not passive prevented it) registers with
`GestureBinding.instance.pointerSignalResolver`, and the registered callback calls
`respond(allowPlatformDefault: false)` on the `PointerScrollEvent`. The host is deeper than each
`Scrollable`, so its `handleEvent` runs first, and the first registration wins. Thus no ancestor
scrolls, and on the web the page does not scroll. A `wheel` that no listener prevents changes
nothing (Chart.js ADR 0037 §10).

### 9. The style members

`lib/src/canvas/canvas.dart` (a pure layer) gives the CSSOM members that add-on plugins write, as
extension members over `getPropertyValue` and `setProperty`:

```dart
extension CssStyleProperties on CSSStyleDeclaration {
  String get touchAction;              // getPropertyValue('touch-action')
  set touchAction(String value);       // setProperty('touch-action', value); '' removes
  String get userSelect;               // getPropertyValue('user-select')
  set userSelect(String value);        // setProperty('user-select', value); '' removes
  String removeProperty(String property); // the old value, then setProperty(property, null)
}
```

The upstream lines `src/gestures.ts:200-207` and `:220-222` of the plugin keep their form.
`user-select` and `-webkit-user-select` have no effect: the canvas has no text to select (Open 10).
The names do not clash with the harness extension `CssProperties`.

### 10. The platform

`platform.flutter.dart` registers its listeners with `passive: true`, the port of
`eventListenerOptions` (`platform.dom.js:95`, `:100`). A Chart.js listener thus cannot cancel an
event, as upstream.

### 11. The harness

In `packages/chartjs_test_utils`:
- `triggerMouseEvent` builds its event with `bubbles: true`, `cancelable: true`,
  `clientX = rect.left + point.x` and `clientY = rect.top + point.y` (`utils.js:167-173`), with
  `rect = node.getBoundingClientRect()`, and calls `node.dispatchEvent(event)`. No Chart.js
  listener is on the document, so the Chart.js specs keep their results. The row
  `harness-trigger-mouse-event` of `differences.md` changes.
- The DOM stand-in reads `left` and `top` (px, also negative) of an element with `position:
  absolute`. They are measured from the padding box of the parent element, not from the nearest
  positioned ancestor: the parent stands for the containing block, also for `position: fixed`.
  Without one of them, that coordinate keeps the place of the element in the flow. They do not
  change the width. For the shape of the zoom specs (a wrapper that is a child of the body), the
  result is that of CSS. A spec of the zoom plugin moves its wrapper by 50 px
  (`test/specs/zoom.drag.spec.js:409-412`), and the spec has a meaning only when
  `getBoundingClientRect()` sees the move.
- `FixtureSource` takes the path of its submodule for the skip reason of a missing checkout. The
  source of the Chart.js fixtures keeps the reason of Chart.js ADR 0029 §11 item 5.

### 12. The public API

`doc/public_api.txt` (`PUBLIC_API_UPDATE=1 flutter test test/tool/public_api_test.dart`):

- `[lib/chartjs.dart]` and `[lib/flutter_chartjs_port.dart]` get 17 names each: the 10 names of
  section 4, and `NativeEvent`, `NativeTouch`, `NativeEventListener`, `NativeEventTarget`,
  `DOMRect`, `CanvasEventTarget` and `CssStyleProperties`. The app library exports `chartjs.dart`
  without `Animation` and `Element`, so it gets them with no change. None of the 17 names is a
  name of `package:flutter/widgets.dart`, `material.dart`, `material_ui.dart`, `cupertino.dart` or
  `dart:ui`: the public API test checks it.
- `[lib/helpers.dart]` gets `isPointInArea`.
- The new section `[lib/js_semantics.dart]` has the 11 names of section 1.
- These stay internal: `CanvasDocument`, `domKeyValue`, `debugCanvasEventListenerPassive`, the four
  registry functions of section 6, `PluginHook`, `MapPlugin`, `ChartHost` and `RenderChartHost`.

Four behavior changes reach a chart with no add-on:
- A `wheel` that a listener prevents no longer scrolls an ancestor. Chart.js registers passive
  listeners, so only user code can prevent it.
- A canvas with `touch-action: none` in its style claims its touch pointers (section 8). Chart.js
  sets no `touch-action`.
- `ChartKeyboard` sends bubbling virtual mouse events and non-bubbling key events. With no document
  listener, the chart gets the same events.
- The host sends events of a pressed mouse outside the box to the document. With no document
  listener, nothing changes.

### 13. Tests

| File | Cases |
|---|---|
| `test/port/js/js_math_hypot_test.dart` (pure, `package:test`) and `test/port/js/hypot_reference.dart` (generated) | each of the 3,000 inputs bit for bit; the Node.js version and the architecture of the data; the VM, JavaScript and WebAssembly |
| `test/tool/public_api_test.dart` | four libraries; `_addOnHelpers = {'_isPointInArea'}` with a check for a stale entry; no clash of the app library with Flutter |
| `test/port/core/core.plugins_typed_public_test.dart` | a plugin built from `chartjs.dart` and `js_semantics.dart` only: the key order of the zoom plugin with extras of `jsWrite`; hooks with `Object chart`; options merged over the plugin defaults; `start`, `beforeUpdate`, the draw hooks and `stop`; a `beforeEvent` that gives false cancels the event; a hook replaced through `jsWrite` (a typed spy, and a function with no parameters called with JS arity); `supportsDataUpdates` false and true with `Chart.updateData` |
| `test/port/plugins/plugin.legend_test.dart` | the legend tests with `LegendElement implements TRBL` |
| `test/port/platform/native_event_test.dart` (pure) | the DOM init defaults; `preventDefault` with and without `cancelable`, in a passive listener; `stopPropagation` and the target; the `DOMRect` edges with negative sizes; the VM, JavaScript and WebAssembly |
| `test/port/platform/chart_host_test.dart` | groups `canvas event target` (the bubble order, the types that do not bubble, `stopPropagation`, the `passive` default of the document, the result, the target, `ownerDocument` and `eventTarget` identity, listeners added in a dispatch), `events` (the fields of section 5 for each mapping row, the document side of a mouse up outside the box), `document target` (a mouse drag out and back, the end at a detach, the key bridge, the key values, a prevented `keydown`), `CssStyleProperties`, `getBoundingClientRect` (a translated host, a scaled host, the standby host and a detached host), `touch sequence` (section 8: no cancel past the slop, cancelable `touchmove`, no tap after a move past the slop, a parent `ListView` and a `PageView` that do not move, an ancestor tap that still wins, a second finger against `InteractiveViewer`, the style read at the sequence start, the pointer ids and the buttons of a touch) and the wheel cases (a prevented wheel does not scroll a parent `ListView`, a wheel that no listener prevents does) |
| `test/port/platform/platform.flutter_test.dart` | the `passive: true` registration; `ChartEvent.native` keeps the new fields |
| `test/port/helpers/helpers.dom_test.dart`, `test/specs/helpers.dom_test.dart` | an event with `clientX` still takes the offsets (`platform-relative-position`) |
| `test/port/widgets/chart_keyboard_test.dart` | group `the document of the canvas`: the virtual mouse events bubble once to the document with the mouse fields; a key reaches a document listener once, from the bridge; Enter, Enter with a document `mouseup` listener |
| `packages/chartjs_test_utils/test/utils_test.dart`, `dom_test.dart`, `fixture_test.dart` | `bubbles`, `cancelable` and the client point of `triggerMouseEvent`; `left` and `top` of an absolute element and the box of its canvas; the skip reason of another submodule |
| unchanged, green | `chart_host_input_test.dart` (its data stays byte-identical), `chart_view_live_mouse_test.dart`, `chart_view_test.dart`, `apps/chartjs_gallery/test/chart_types_test.dart`, the digests of the observation test |

`check:lib-imports` keeps `native_event.dart` and `canvas.dart` pure layers: `native_event.dart`
adds only `dart:math` and `package:meta`.

### 14. The superseded parts

This ADR supersedes these parts. The rest of each ADR stays.

- Chart.js ADR 0022 §3: the table of the CSS subset gets `left` and `top` (section 11). §6: the
  bullets "The event is `NativeEvent(type: type, offsetX: point.x, offsetY: point.y, target:
  canvas)`" and "`dispatchCanvasEvent(canvas, event)` ... replaces `node.dispatchEvent(event)`":
  the event has `bubbles`, `cancelable` and the client point, and the call is
  `node.dispatchEvent(event)` of section 6.
- Chart.js ADR 0037 §8: the pan begin, for a sequence with `touch-action: none` (section 8). §10:
  "with no claim in the gesture arena", "`wheel` does not claim the pointer signal" and "The host
  sends `pointercancel` at the pan begin also when no parent scrolls", for a `touch-action: none`
  sequence and for a prevented `wheel`. §11: the bullets "The listener options `{passive: true}`
  have no port" and "The host never claims a pointer for an event listener". Open 3: the sentence
  "Chart.js sets no `touch-action`, and the host always gives the default." The host now reads the
  property.
- Chart.js ADR 0048 §5: "The package has three public libraries", the export list of
  `chartjs.dart`, and in the internal list "the canvas event helpers of `chart_host.dart`" and
  "`lib/src/js/` except `JsClass` and `undefined`" (sections 1, 6 and 12). §6: the hide of
  `isPointInArea` (section 3).
- Chart.js ADR 0051 §4: the virtual mouse events bubble and have the mouse fields. §5: the key
  events of the canvas do not bubble, and have `key`, `cancelable` and the modifiers (section 7).
- Chart.js ADR 0054 §12: the sentence "`Plugin` stays internal (no public library exports it)
  until the typed public plugin API (Open 2)." Open 2: the item "Typed public plugin API" is done
  by section 4. The other items of Open 2 stay.

It adds to Chart.js ADR 0029 §11 item 5 (the skip reason of another fixture source) and to Chart.js
ADR 0037 §6 (the events of the document). No row of `differences.md` is new: the changed files of
the host are port-only. The row `harness-trigger-mouse-event` changes its text, and the row
`platform-relative-position` keeps its text: `getRelativePosition` still reads the offsets.

## Alternatives considered

- **Exported top-level functions** (`addCanvasEventListener` and the others, the form of the first
  draft of Zoom ADR 0003). Rejected. Each upstream call site becomes an `adapt` row, and the canvas
  and the document need different call forms.
- **Interface members on `HTMLCanvasElement` and `CSSStyleDeclaration`.** Rejected. They break the
  4 full fakes and make the 10 `noSuchMethod` fakes throw.
- **A dynamic form through `noSuchMethod`.** Rejected: no static types.
- **A sealed hierarchy of event classes** (mouse, pointer, wheel, keyboard). Rejected. Each zoom
  listener needs a cast, and `getRelativePosition` needs a type switch. The DOM keys the listeners
  by a string, and one flat class gives one listener type.
- **A public top-level `document`.** Rejected. `chartjs_test_utils` exports the harness `document`,
  and a zoom spec imports both. `canvas.ownerDocument` gives the document with the upstream form.
- **The `Focus` of `ChartView` for the keys of the document.** Rejected. A drag does not focus the
  chart, and the DOM document gets each key of the page.
- **An eager claim of the touch pointers** (`EagerGestureRecognizer`). Rejected. It also takes the
  taps of `GestureDetector`, `InkWell` and `ListTile` ancestors. In the DOM, `touch-action` stops
  only the pan and the zoom of the browser.
- **The runtime in `chartjs.dart`.** Rejected. `chartjs.dart` mirrors the `chart.js` entry, the app
  library would need a hide list of 11 names, and a separate library keeps the move to the package
  `js_semantics` to one import line.
- **`math.sqrt(a * a + b * b)` for `Math.hypot`.** Rejected. It differs from V8 for about one pair
  in three, overflows for `a = b = 1e200` and underflows for `a = b = 1e-200`.
- **Map plugins only for add-ons.** Rejected. A Map plugin is an emulation of a JS object, calls
  each hook with JS arity and opts into data-only updates only with an own key that upstream does
  not have. The built-in plugins are typed.
- **A public `types.Chart` for the hook type.** Rejected for now. `Object` and one cast serve the
  hook. A public chart interface is a larger change of the public API.

## Consequences

- An add-on port reaches the input path, the DOM fields, the box of the canvas, the document, the
  keys and `touch-action` through the public libraries, with the upstream line forms. The zoom
  seams H2 to H8, H13, H16 and H23 close (`host-seams.md` of the zoom port).
- The public API grows by 17 names in `chartjs.dart` and in the app library, 1 name in
  `helpers.dart`, and the library `js_semantics.dart` with 11 names. The release rule of the typed
  API holds: the new names are typed.
- `chart_host.dart` grows by the document, the field computation and the arena member. The
  ordinary chart pays one listener test of the document for each bubbling event type.
- A file that imported `NativeEvent` or `Plugin` from `lib/src/` next to a public library gets an
  `unnecessary_import` info. The change removes these imports.
- A device check of `touch-action: none` on Android Chrome against the port is evidence for this
  ADR (Open 1).

## Open

1. Device check of `touch-action: none` on Android Chrome (D1 inside the slop, the end of the tap
   candidate, `touchmove` cancelable) versus the port.
2. Blink pointer id numbering (mouse 1, others from 2) and the `button`/`buttons` of the boundary
   events of a touch down: verify at the Chromium version of Chart.js ADR 0037 Evidence.
3. Chorded mouse buttons: Flutter folds a second press or release into a `PointerMoveEvent`; the
   host gives no `mousedown`/`mouseup` for it (Chrome gives `pointermove` with `button` set and
   the mouse events).
4. Wheel: Chrome makes the later events of an unprevented scroll sequence uncancelable (scroll
   latching); the host gives `cancelable: true` to each. The pixel value of one wheel notch differs
   by embedder; zoom caps the delta at 24 (`src/handlers.ts:250` of the plugin). Measure on macOS,
   Windows and the web.
5. Trackpad: `PointerPanZoomStart/Update/End` and `PointerScaleEvent` still have no `wheel`
   mapping (Chart.js ADR 0037 §16). Chrome on macOS gives `wheel` for a two-finger scroll and a
   ctrl `wheel` for a pinch; a macOS desktop app with a trackpad gets no wheel zoom. A later ADR,
   with device evidence (a pan-zoom pointer also goes through the gesture arena, not the signal
   resolver).
6. `preventDefault` of `pointerdown`, `touchstart` and `touchmove` has no host effect.
7. `touch-action` values other than `none` and `auto` act as `auto`.
8. The document gets keys before the focused canvas (section 7); the DOM order is the reverse.
9. A mouse drag that starts outside the chart (Chart.js ADR 0037 Open 7) and hover moves outside
   the box do not reach the document.
10. A `SelectionArea` ancestor still starts a selection at a mouse drag on the chart, also with
    `user-select: none` (section 9).
11. A listener that throws stops the later listeners of that dispatch (the DOM reports and goes
    on); unchanged from today.
