# Chart.js ADR 0051: Input events and interaction state

- Status: proposed
- Date: 2026-10-29
- Related: [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md) (the input path: sections
  9, 11, 14, 16 and 17, and Open 4, which this ADR takes),
  [Chart.js ADR 0016](0016-frame-scheduling.md) (the throttle, the `setState` rule of the layout),
  [Chart.js ADR 0022](0022-chart-test-harness.md) §5 (`triggerMouseEvent`),
  [Chart.js ADR 0034](0034-no-display-only-js-exactness.md) (the protected behavior),
  [Chart.js ADR 0049](0049-chart-view-widget.md) (the widget `ChartView`, its update callback and
  its `setState` table), [Chart.js ADR 0050](0050-public-theme-api.md) (the theme API and the
  inline plugin of the widget),
  [theming.md](../theming.md) §6 (a focus ring is a port-only plugin),
  [porting-flow.md](../porting-flow.md) §1.1 (the performance rule)

## Context

Chart.js ADR 0037 §16 says: "Keyboard events and semantics are port-only and come in phase 9."
theming.md §6 says that a focus ring is a port-only plugin of this ADR. Chart.js ADR 0037 Open 4
gives a mouse and a touch screen on one device to phase 9. The phase 9 design panel B
(2026-10-29) decided these items. This ADR states the decision. It adds to Chart.js ADR 0037 and
changes no section of it. The upstream citations are at the pin `v4.6.1`. I checked each cited
line at `v4.6.1` and in Flutter 3.47.7 (`F/` is `packages/flutter/lib/src/` of the SDK).

### Upstream reads

- Chart.js has no keyboard code. `bindUserEvents` adds one platform listener for each type of
  `options.events` (`src/core/core.controller.js@v4.6.1:976-992`). A `keydown` reaches a chart
  only when the canvas has the focus and `events` lists the type.
- A `KeyboardEvent` has no `offsetX`. `getCanvasPosition` then reads `clientX - rect.left`, which
  is NaN (`src/helpers/helpers.dom.ts@v4.6.1:65-95`). A NaN position is outside the chart area.
  Thus `_handleEvent` keeps the active elements and sets `_lastEvent` to null
  (`core.controller.js:93-101, 1215`). The legend reads only `mousemove`, `mouseout`, `click` and
  `mouseup` (`src/plugins/plugin.legend.js@v4.6.1:528-531, 582-590`).
- `setActiveElements` sets only the given items (`core.controller.js:1096-1117`). It calls no
  `onHover` and sets `_lastEvent` to null. The upstream sample calls it and
  `tooltip.setActiveElements`, then `update()` (`docs/samples/advanced/programmatic-events.md:5-46`).
  In the mode `'index'` it shows one item where a mouse shows all datasets.
- The harness puts a mouse event at `el.getCenterPoint()`
  (`third_party/chartjs-test-utils/src/utils.js:151-161`). The legend specs click the center of a
  hit box (`test/specs/plugin.legend.tests.js:1093-1097`).
- Upstream leaves accessibility to the author: `role="img"` and `aria-label` on the canvas
  (`docs/general/accessibility.md:3-17`).

### The port

- `dispatchCanvasEvent` calls the canvas listeners of `event.type`
  (`lib/src/platform/chart_host.dart:146-157`). The listener of a chart is the throttled proxy of
  `platform.flutter.dart` (Chart.js ADR 0037 §11). `triggerMouseEvent` of the harness enters the
  path there (`packages/chartjs_test_utils/lib/src/utils.dart:350`). The host is a repaint
  boundary (`chart_host.dart:591`).
- The compatibility mouse of touch is one static owner for each isolate. Its global route returns
  for a mouse-like kind (`chart_host.dart:1174-1180`). A real mouse keeps the `MouseTracker`
  path. No device row of Chart.js ADR 0037 used a mouse (its Open 1).

### Flutter

- `Focus.onKeyEvent` that returns `ignored` gives the key to the ancestors. A `Shortcuts` action
  that is disabled gives `ignored` or `skipRemainingHandlers`
  (`F/widgets/shortcuts.dart:922-938`). Probe J1b: with a disabled action and with
  `consumesKey` false the focus stays in the chart; with `Focus.onKeyEvent` that returns `ignored`
  the focus moves. `CallbackShortcuts` handles each bound key (`:1221-1231`).
- The default shortcuts of `WidgetsApp`: the arrows are `DirectionalFocusIntent` on the native
  platforms (`F/widgets/app.dart:1263-1282`) and `ScrollIntent` on the web (`:1308-1331`). Enter
  and Space are `ActivateIntent` (on the web `ButtonActivateIntent` and `PrioritizedIntents`).
  Escape is `DismissIntent`.
- `Image` builds `Semantics(container: semanticLabel != null, image: true, label: semanticLabel
  ?? '')` (`F/widgets/image.dart:1424-1429`). Probe J1a: with `container: false` the image flag
  and the focus flags of an inner `Focus` merge into the node of an ancestor; with
  `container: true` the chart has its own node. The web gives an image node with no tap action
  `role="img"` and `aria-label` (`engine/src/flutter/lib/web_ui/lib/src/engine/semantics/image.dart:59-73`,
  `semantics.dart:1788`).
- A semantics `value` with the actions `increase` and `decrease` needs `increasedValue` and
  `decreasedValue` (`F/semantics/semantics.dart:3788-3795`).
- `markNeedsSemanticsUpdate` returns at once when no semantics owner exists
  (`F/rendering/object.dart:3921-3927`).

### The oracle

The three drafts of the panel tested their key path against one oracle: the state of a mouse at
the target point. The virtual mouse gives the hover set, the tooltip, `mouseout` and the legend
toggle (probe S-PR1). A path through `setActiveElements` fails the oracle in the mode `'index'`.
A path that computes the mode sets itself calls no `onHover` and has no replay of `_lastEvent`
(`core.controller.js:529-531`).

## Decision

### 1. The focus stop

`ChartView` (Chart.js ADR 0049) is one focus stop by default, as the Flutter controls are. Two
parameters are new:

```dart
/// The focus node of the chart. Null: the widget owns one. The chart is one
/// focus stop: the arrow keys move a virtual mouse over the legend items and
/// the data elements, Enter and Space click there, Escape clears the hover.
/// Wrap the chart in ExcludeFocus to remove the stop.
final FocusNode? focusNode;

/// Whether the chart takes the focus at its first build.
final bool autofocus;
```

The widget builds one `Focus` with `onKeyEvent` around the host. It uses no `Shortcuts`, no
`Actions` and no `CallbackShortcuts`. Thus a key that the chart does not use goes on to the
ancestors: Tab, the focus traversal of the arrows at an end, the page scroll of the web and a
`DismissIntent` of a dialog.

### 2. The targets

At each key, the widget computes the targets from the chart:
1. The legend group: the hit boxes of `chart.legend` (`legendHitBoxes`, `plugin.legend.js:52`)
   in their order, when the legend has hit boxes. The widget reads them through the new
   port-only member `legendHitBoxes` of `types.LegendElement`, so it imports no plugin (Chart.js
   ADR 0048 §3). The target point is the
   center of the hit box.
2. A data group for each visible dataset (`isDatasetVisible`) in index order: each element of
   `getDatasetMeta(i).data` with a finite `getCenterPoint(true)` and a visible data index
   (`getDataVisibility`). The target point is that center.

The widget keeps the target as a group index and an item index. An index past the end of its group
takes the last item. A group that is gone clears the target.

### 3. The keys

The handler reads `KeyDownEvent` and `KeyRepeatEvent`:

| Key | No target | With a target |
|---|---|---|
| Right, Left | first target / ignored | next / previous target of the group; ignored at the ends |
| Down, Up | first target of the first group / ignored | the same index in the next / previous group (the last item when the group is shorter); ignored at the ends |
| Home, End | ignored | first / last target of the group |
| Enter, Space (down only) | ignored | `mousedown`, `mouseup`, `click` at the target |
| Escape (down only) | ignored (an ancestor `DismissIntent` acts) | `mouseout` at (-1, -1), outside the canvas; the target clears |
| focus loss | nothing | `mouseout` at (-1, -1), outside the canvas; the target clears |

A repeat of Enter, Space or Escape gives `handled` with no event when a target exists, else
`ignored`. A `KeyUpEvent` gives `ignored`. The table has no key with a modifier: a key with
Shift, Control, Alt or Meta gives `ignored`, so that the shortcuts of the app and of the browser
keep it.

Escape and a focus loss send the `mouseout` at (-1, -1), a point outside the canvas. A real mouse
gives its `mouseout` where it leaves the canvas, outside each legend item. At the target point, the
legend keeps its hovered item and calls no `onLeave` (`plugin.legend.js:537-544`).

### 4. The virtual mouse

A move to a target sends a `mousemove` `NativeEvent` at the target point through
`dispatchCanvasEvent`, with `source` the `KeyEvent`. The keys enter the ported input path where
the harness enters it. Thus:
- `options.events` filters the keys as it filters the mouse: with `events: ['click']`, a move gives
  no active element.
- The hover mode, the tooltip mode, `onHover`, `onClick`, the legend `onHover`, `onLeave` and
  `onClick` and the replay of `_lastEvent` at the next `update` give the mouse result at that
  point.
- The throttle and the frame order of Chart.js ADR 0037 §11 apply: the chart gets the event in the
  next frame callback.
- The compatibility mouse route of Chart.js ADR 0037 §9 does not see these events.

The widget has no hit test and no mode logic of its own. The keys change no ported file.

### 5. The key events of `options.events`

Each key event of the focused chart also goes to the canvas listeners, before the action of
section 3, as a DOM `keydown` goes to a focused canvas before its default action:
- `KeyDownEvent` and `KeyRepeatEvent` give `keydown`, and then `keypress` when the event has a
  `character`.
- `KeyUpEvent` gives `keyup`.
- The `NativeEvent` has NaN offsets and no touches. The widget sends it only when
  `hasCanvasEventListener` is true for the type, thus only when `options.events` lists it.

A `keydown` sets `_lastEvent` to null upstream. The widget sends the `keydown` before the
`mousemove` of the same key. In a frame with no earlier mouse event, the `keydown` proxy thus runs
first (Chart.js ADR 0037 §11), and the final state is the state of the mouse.

### 6. The focus ring

The widget adds one internal inline plugin to the `plugins` of its root config, after the inline
plugins of the app. Its id is `$chartView`. It also records the palette keys of the theme switch
(Chart.js ADR 0050). It draws the ring in `afterDraw`:
- with a legend target: a 2 px `strokeRect` 2 px outside the hit box
  (`strokeRect(left - 3, top - 3, width + 6, height + 6)`, `lineWidth` 2);
- with the focus and no target: a 2 px `strokeRect` 1 px inside the canvas box
  (`strokeRect(1, 1, width - 2, height - 2)`);
- with a data target: no ring. The upstream hover style and the tooltip show the target.

The color is the resolved `chart.options.color` (the `color` token, else `'#666'`). The ring draws
only while the chart has the focus and `FocusManager.instance.highlightMode` is
`FocusHighlightMode.traditional`. A change of the focus, of the highlight mode or of the ring
rectangle calls `chart.render()`. The ring is in the canvas: the host is a repaint boundary, so a
Flutter painter outside the host does not follow the chart frames.

### 7. When the hooks run

The key handler runs in the key dispatch of Flutter, outside the build and the layout. It only
dispatches. The chart hooks of a key (`onHover`, `onClick`, the legend callbacks, plugin
`beforeEvent` and `afterEvent`) run in the throttled frame callback, where `setState` is allowed,
as for a mouse event (the table of Chart.js ADR 0049). The `render()` of a focus change runs
`afterRender` and `onComplete` after the focus change, outside the build.

### 8. Semantics

The chart is one semantics node, as the upstream canvas with `role="img"` and `aria-label`:

```dart
/// The text alternative of the chart, as the aria-label of a Chart.js
/// canvas with role="img" (docs/general/accessibility.md). Give one for
/// each chart.
final String? semanticLabel;

/// Whether the chart has no semantics node. [semanticLabel] then has no effect.
final bool excludeFromSemantics;
```

- The build is `Semantics(container: true, image: true, label: semanticLabel ?? '', child:
  Focus(..., child: host))`. The node is a container also without a label, because the chart is
  focusable (J1a): an unlabeled chart never merges into the node of an ancestor.
- `excludeFromSemantics: true` wraps the `Focus` in `ExcludeSemantics`.
- 0.1.0 has no summary of the datasets, no `value`, no node for each element and no node for each
  legend item. The node does not change at a data update or in an animation frame.
- The next step is a `value` with the text of the keyboard target and `liveRegion`, or the form of
  a `Slider` with `increasedValue` and `decreasedValue`. Its trigger is an accessibility review or
  a user report. It adds no public name.

### 9. A mouse and a touch screen on one device

Chart.js ADR 0037 §9 stays in 0.1.0: the real mouse keeps the `MouseTracker` path, and the route
of the compatibility mouse ignores the mouse-like kinds. A browser has one compatibility mouse
for both (Chart.js ADR 0037:85-87). The port thus differs for these rows: after a touch tap on
chart A, a mouse over chart B gives B its hover, and A keeps its tooltip.

This ADR takes Chart.js ADR 0037 Open 4:
- Owner: the porting lead.
- Gate: a device round on the Pixel 8a with a USB mouse. The reference is the pinned Chart.js build
  in Chrome with two charts. The port is the gallery with two `ChartView`s of the same configs.
  The rows:
  - MT1: a tap on A, then the mouse moves over B.
  - MT2: the mouse over B, a tap on A, then a mouse move of 1 px.
  - MT3: the mouse over B, then a tap outside the charts.
  - MT4: the mouse over A, then a tap on A.
  - MT5: a tap on A, then the mouse moves inside A, then outside the charts.
  Each row records the DOM events of each canvas, the active elements and the tooltip of each
  chart.
- Result: when each row gives the active sets and the tooltips of Chrome, Open 4 closes with the
  rows. A row with another active set or another tooltip starts a new ADR that supersedes Chart.js
  ADR 0037 and states its complete decision with §9 changed. The prepared form: a tap that makes a
  host the owner gives `mouseout` and `mouseleave` to another host under the real mouse, and a real
  mouse move or hover outside the owner gives the owner `mouseout` and `mouseleave` and ends the
  owner, in the existing global route.

### 10. Tests, rows and records

- No `differences.md` row is new. The keys, the ring and the semantics are in port-only files.
  "A port-only file is not a row" (`differences.md`, introduction).
- The key tests, for a bar, a line, a doughnut and a radar chart: each key move gives the active
  elements, the tooltip items and the legend callbacks of `triggerMouseEvent` at the same point;
  the mode `'index'`; Enter on a legend item toggles its dataset (doughnut: its data index); a
  custom legend `onClick` gets the item; Enter on an element calls the chart `onClick`;
  `events: ['click']` gives no active element on a move; Escape and the focus loss clear the hover
  and the tooltip; Escape without a target reaches an ancestor `DismissIntent`; an arrow at the
  last target moves the focus; with `events` that lists `keydown`, a `beforeEvent` plugin gets it
  with NaN `x` and `y`; without it, no `NativeEvent`; the ring draw calls appear only with the
  keyboard focus; `ExcludeFocus` gives no stop.
- The semantics tests (`tester.ensureSemantics()` and `matchesSemantics` of flutter_test; the
  `SemanticsTester` of the Flutter repository is not a public API): the node has the label, the
  image flag and the focus flags; a null label gives an unlabeled node of its own (J1a as a pin); `excludeFromSemantics`
  removes it; a data update and an animation give no semantics update (a listener on the
  semantics owner).
- A pin of today in `test/port/platform/chart_host_test.dart`: a touch tap on host A, then a mouse
  hover on host B; A keeps its tooltip, and B gets the mouse events.
- The night series B-N1 (semantics on and off) of the phase 9 spec measures the cost of the
  semantics node. The key path is the mouse path, which the case `tooltip.hover` of
  [performance.md](../performance.md) §6 measures.
- The gate of this ADR: the decision is implemented, the tests above pass, and B-N1 passes its
  rule. The device round of section 9 is not a gate: its result closes Open 4 or starts the
  superseding ADR of Chart.js ADR 0037.

### 11. Scope of later phases

- Typed Flutter callbacks for the events, a chart controller object and the semantics `value`
  come later as additions.
- `dblclick`, `contextmenu`, `auxclick`, the pointer capture events and trackpad pan and zoom keep
  no mapping (Chart.js ADR 0037 §16).

## Alternatives considered

| Option | Chosen | Reason |
|---|---|---|
| Keys call `setActiveElements`, `tooltip.setActiveElements` and `render()` (the upstream sample) | no | No hit test: the mode `'index'` shows one item where the mouse shows all datasets. No `onHover` and no `events` filter |
| Keys compute the mode sets with `getElementsAtEventForMode` and set them | no | No `onHover`, no legend `onHover` and `onLeave`, and `_lastEvent` is null, so no replay |
| A virtual mouse through `dispatchCanvasEvent` | yes | It gives the mouse result by construction, with no mode logic |
| The chart opt-in (`canRequestFocus: false` by default) | no | The Flutter controls are focus stops. `ExcludeFocus` removes the stop |
| `Shortcuts` and `Actions` with public intents, or `CallbackShortcuts` | no | Public intent names. `CallbackShortcuts` handles each bound key, so the arrows never leave the chart |
| "At the row end the action does not consume the key, so the focus leaves" (a draft) | wrong | J1b: with a disabled action the focus stays in the chart |
| A keyboard state inside a plugin of every chart (theming.md §6) | no | The plugin list of each chart. The widget plugin draws only the ring |
| A ring as a Flutter painter outside the host | no | The host is a repaint boundary: the painter does not follow the chart frames |
| A ring around a data element | no | The upstream hover style and the tooltip show it |
| `Semantics(container: semanticLabel != null)`, the `Image` form unchanged | no | J1a: an unlabeled focusable chart marks the node of an ancestor as a focusable image |
| A summary of the datasets, a node for each legend item, a "current item" node with `liveRegion` | not in 0.1.0 | Each adds later with no public change. One static node costs nothing in a frame |
| One compatibility mouse for the mouse and the touch now (rules 1-5 of a draft) | no | No device row shows the Chrome sequence. A rule without its rows can make a new difference |

## Consequences

- A focused chart is one Tab stop. The arrows move inside it. At an end, a native app moves the
  focus and a web page scrolls.
- A key move and a real mouse act on the same chart state. The next real mouse move sets the hover
  again. Escape and the focus loss clear the hover also when the real mouse is over the chart.
- A key costs one throttled mouse event, the cost of the mouse path: about 214 µs at 10000 points
  on JIT for the hover and the tooltip hit tests (Chart.js ADR 0037, Consequences).
- A focus change calls `render()`: one draw, and `afterRender` and `onComplete` run.
- An app gives one label for each chart. The node has no other text in 0.1.0.
- The known model difference of section 9 stays until the device round.
- The live mentions of "ADR: Input events and interaction state" move to this ADR: theming.md §6
  and §11, Chart.js ADR 0050, and the `///` lines of `lib/`.

## Open

1. **The device round of section 9** (Chart.js ADR 0037 Open 4). Owner: the porting lead.
2. **Several views.** The keys reach the focused view only. A multi-view app is not checked
   (Chart.js ADR 0037 Open 5).
3. **A key during an animation.** The target point is the final center (`getCenterPoint(true)`).
   The hit test of the event reads the current positions. Thus a key during an entry animation can
   miss the element. No test pins it.

## Evidence

The probes are working files of the phase 9 design panel B in `.handover/phase9/panel/probes/`,
not committed. Dart is 3.13.5 and Flutter 3.47.7, on the VM. No probe was a timed run.

| Probe | Files | Result |
|---|---|---|
| J1a | `b-judge/j1_semantics_keys_test.dart`, `j1_out.txt` | `container: false`: `flags: [isImage, isFocusable]` and the label of the parent on one node. `container: true`: the chart has its own node |
| J1b | the same files | A disabled action and `consumesKey` false keep the focus in the chart; `Focus.onKeyEvent` with `ignored` moves it |
| S-PR1 | `b-simplicity/probe_b_simplicity_test.dart.txt`, `probe_output.txt` | The virtual mouse: the targets, the hover set and the tooltip at a target, `mouseout`, the legend toggle (`visible1=false`) |
| S-PR4 | the same files | A semantics `value` needs `increasedValue` and `decreasedValue` with the actions |
| Pf-B9 | `b-performance/b9_key_path_test.dart.txt`, `b9_key_path.out.txt` | `setActiveElements` at the item in the mode `'nearest'` only |
