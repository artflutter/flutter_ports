# Chart.js ADR 0037: Legend and tooltip input path

- Status: accepted (2026-10-29)
- Date: 2026-10-22
- Revised: 2026-10-23, after the device check of Open 1 (Evidence E8 and E9); 2026-10-24, after
  the device re-check of the input fix (Evidence E10, row STN10); 2026-10-29, after the device
  round g1 (Evidence E11)
- Supersedes: [Chart.js ADR 0014](0014-input-events-and-chart-host.md)
- Related: [Chart.js ADR 0016](0016-frame-scheduling.md) (the scheduling of the host; it
  supersedes Chart.js ADR 0007),
  [Chart.js ADR 0013](0013-canvas-model.md) (the canvas layer),
  [Chart.js ADR 0012](0012-dart-file-naming.md) (the names),
  [Chart.js ADR 0022](0022-chart-test-harness.md) §5, §6 and §10 (`afterEvent`,
  `triggerMouseEvent`, the host changes of the harness),
  [Chart.js ADR 0032](0032-js-numeric-semantics.md) (`ToNumber`, the reference engine),
  [Chart.js ADR 0034](0034-no-display-only-js-exactness.md) (the protected behavior),
  [porting-flow.md](../porting-flow.md) §1.1 (the performance rule), §2.7 and §7 (the open
  question "Tooltip after touch lift"), [upstream-ledger.md](../upstream-ledger.md) (Signal
  #7738), [differences.md](../differences.md) rows `platform-detect-host`,
  `platform-relative-position` and `harness-trigger-mouse-event`

## Context

Phase 8 ports `plugin.legend.js` and `plugin.tooltip.js`. Both plugins read only the chart events
that `core.controller` gives to their `afterEvent` hook. The phase table of
[porting-flow.md](../porting-flow.md) §5 calls the path from Flutter input to these hooks the
"input adapter". No ADR defines it. [Chart.js ADR 0014](0014-input-events-and-chart-host.md)
holds the host and its event table. Its Open list gives the tooltip after a touch lift (#7738) to
phase 9. The phase 8 prompt gives #7738 to this ADR.

The line numbers of upstream files refer to Chart.js `v4.5.1+7169e651` (`third_party/Chart.js` at
`7169e65147a4`). I checked each cited line at that commit. The Flutter citations refer to Flutter
3.47.7.

### Upstream reads

- `src/core/core.defaults.js:47-53`: the default `events` are `mousemove`, `mouseout`, `click`,
  `touchstart` and `touchmove`. They have no `touchend`, no `mouseup` and no `pointer*` type.
- `src/core/core.controller.js:976-990` `bindUserEvents`: one platform listener for each type of
  `options.events`. A type that is not in the list never reaches the chart.
- `src/core/core.controller.js:1163-1186` `_eventHandler`: the plugin filter is
  `(plugin.options.events || this.options.events).includes(e.native.type)` (`:1170`). Thus the
  native type selects the plugins. The plugins read the mapped type in `e.type`. `afterEvent`
  runs after `_handleEvent` (`:1179`). `args.changed` asks for a `render()` (`:1181-1183`).
- `src/core/core.controller.js:93-102` `determineLastEvent` and `src/helpers/helpers.core.ts:414-416`
  `_isClickEvent`: a `mouseout` or an event outside the chart area clears `_lastEvent`. A
  `mouseup` or a `click` keeps the old one.
- `src/platform/platform.dom.js:21-31` `EVENT_TYPES`: `touchstart` and `pointerdown` give
  `mousedown`, `touchmove` and `pointermove` give `mousemove`, `touchend` and `pointerup` give
  `mouseup`, `pointerenter` gives `mouseenter`, `pointerleave` and `pointerout` give `mouseout`.
- `src/platform/platform.dom.js:93-101`: passive listeners. Chart.js cancels no event. Thus a
  browser sends its compatibility mouse events after each touch tap.
- `src/platform/platform.dom.js:109-119` `fromNativeEvent` and `:240-254` `createProxyAndListen`:
  one throttled proxy for each type, with the guard `chart.ctx !== null` (`:246`).
- `src/helpers/helpers.extras.ts:27-45` `throttled`: one `requestAnimationFrame` call for each
  proxy, with the latest arguments. The callbacks of one frame run in the order of their
  registration.
- `src/helpers/helpers.dom.ts:73-93` `getCanvasPosition` and `:111-131` `getRelativePosition`:
  `touches[0]`, else the event. A `touchend` after the last finger has no touches and no offsets.
  Its position is NaN. Both coordinates go through `Math.round` (`:127-130`).
- `src/plugins/plugin.legend.js:39` `itemsEqual`, `:503-522` `_getLegendItemAt(x, y)` (the
  legend box, then a linear scan of `legendHitBoxes` with `_isBetween`), `:528-554`
  `handleEvent`, `:582-590` `isListened` (`mousemove` and `mouseout` with `onHover` or `onLeave`,
  `click` and `mouseup` with `onClick`), `:630-634` `afterEvent` (no replay), `:645-656` the
  default `onClick`. Thus `click` always reaches the legend.
- `src/helpers/helpers.math.ts:205-207` `_isBetween`: the epsilon `1e-6`. JS `null >= n` reads
  `null` as 0. NaN is never between.
- `src/plugins/plugin.tooltip.js:1139-1172` `handleEvent`, `:1183-1208` `_getActiveElements`
  (`mouseout` gives `[]`, an event outside the chart area keeps the valid active elements, else a
  second hit test `chart.getElementsAtEventForMode` at `:1200`), `:1264-1272` `afterEvent`.

No upstream line hides the tooltip at a touch lift. A browser decides what a touch tap gives to
the canvas. Issue #7738 ("Tooltip on mobile should go away when I tap outside of canvas", open)
reports the results: Chrome and Firefox on Android hide the tooltip at a tap outside the canvas.
iOS Safari and the Firefox mobile emulation keep it. The upstream maintainer calls the Chrome
result the expected one. The workarounds in the issue dispatch a `mouseout` to the canvas.

### Browser rules

- Touch Events, "Interaction with Mouse Events and click": after a tap, the user agent sends
  `mousemove`, `mousedown`, `mouseup` and `click`, in this order, at the tap location. A drag or a
  canceled touch gives no compatibility event.
- Pointer Events 3 §4.2.3 and §4.2.6: a pointer that cannot hover gets `pointerover` and
  `pointerenter` before `pointerdown`, and `pointerout` and `pointerleave` after `pointerup`.
  These are MUST rules. §4.1.2: only a primary pointer makes compatibility mouse events. §11.1:
  the browser has one compatibility mouse. It moves between the targets with `mouseover`,
  `mouseout`, `mouseenter` and `mouseleave`.
- Chrome thus keeps the compatibility mouse over the canvas after a tap. A later tap on another
  element moves it: the canvas gets `mouseout` and `mouseleave`. `mouseout` is in the default
  `events`. This is why Chrome hides the tooltip.

### Chromium rules of a touch sequence

The device check of Open 1 (Evidence E8) compared Chrome on a Pixel 8a with the first text of this
ADR. It found five differences, D1 to D5. The Chromium source at the tag `155.0.8059.84`, the
Chrome of the check, gives the rules behind them (Evidence E9). The line numbers refer to that
tag.
- **The slop limit.** `ui/events/gesture_detection/gesture_detector.cc:480-493`: the slop limit is
  the slop plus `kSlopEpsilon`, 0.05 DIP. A move is past it when `distance^2 > limit^2`
  (`:667`). `gesture_configuration_android.cc:53-56` and `gesture_provider_config_helper.cc:33-34`:
  the touch slop is `ViewConfiguration.getTouchSlopInDips()`, and the stylus slop is 1.5 times
  the touch slop. `gesture_detector.cc:662-665`: the stylus slop applies only to the tool type
  stylus. An eraser has the touch slop. `kExpandSlopFactorForZeroTouchMajor` (`:657-667`) doubles
  the slop of a down with no touch major (Open 13).
- **The pan begin.** `gesture_detector.cc:328-347` and `:633-669`: a move begins the scroll when a
  pointer is farther than its slop limit from its own down, or when the sequence had more than 2
  pointers. The long press does not stop it (`:555-559`; `gesture_provider.cc:408-450`).
- **The suppression of `touchmove`.**
  `third_party/blink/renderer/core/input/touch_event_manager.cc:372-385` and `:492-497`, and
  `filtered_gesture_provider.cc:123-124`: after a `touchstart` of one touch that no listener
  cancels, Blink sends no `touchmove` until the pan begins. More than one touch, an up or a cancel
  ends the suppression (D1).
- **The cancel at the pan begin.**
  `third_party/blink/renderer/core/input/pointer_event_manager.cc:371-402`, `:616`, `:654-655` and
  `:850-851`: the pan begin cancels all pointers that do not hover with `pointercancel`,
  `pointerout` and `pointerleave`. Then Blink sends no pointer event of a touch or a pen until no
  touch is active. `pointer_event_factory.cc:429-452` (`CreatePointerCancelEvent`) gives that cancel
  no position: the client point is (0, 0) (D3). A platform cancel takes its position from the
  platform event (`:305-350`).
- **The move filter.** `components/input/passthrough_touch_event_queue.cc:33-46`, `:361-363` and
  `:490-506` (`HasPointChanged`): a move with no change of the position, the radii, the rotation
  angle, the force or the tilt is not sent (D2).
- **The tap position.** `gesture_detector.cc:400-417` and `gesture_provider.cc:693-700`: the tap
  gesture has the point of the up event. `gesture_provider.cc:168` and `:705-722`: the tap area of
  that gesture has its center at the down point. Blink
  `third_party/blink/renderer/core/input/event_handler.cc:2083-2148` applies the touch adjustment
  to the tap of a touch: the device rows of a finger (S04, S07 and SN08) give the down point (D4).
  `event_handler.cc:1788-1797`: a pen and an eraser get no touch adjustment. Thus their tap is at
  the up point (Evidence E10, row STN10). `gesture_manager.cc:219-465` (`HandleGestureTap`) sends
  the compatibility events and `click` at the point of the tap.
  `gesture_detector.cc:531`: the long press uses the down event, for each tool type (D4).
- **The stylus.** Chrome on Android gives a stylus contact the touch sequence, with the
  `pointerType` `pen` (D5). Its tap is at the up point (Evidence E10).

### The port before this ADR

[Chart.js ADR 0014](0014-input-events-and-chart-host.md) §6 gives a touch tap `pointerdown`,
`touchstart`, `pointerup`, `touchend` and a `click` from a `TapGestureRecognizer`. It gives no
touch boundary event and no compatibility mouse event. Its §7 adds the recognizer to the arena
only for a `click` listener and uses no global pointer route. A probe of the real host (Evidence
E3) and the Node.js probes of upstream (E2) give eleven rows. Eight of them differ:

| # | Gesture | Chrome with the pinned build | Port with ADR 0014 |
|---|---|---|---|
| S1 | Touch tap on a point, default `events` | `touchstart`, then the compatibility `mousemove` and `click`. The tooltip stays after the lift | `touchstart`, `click`. The tooltip stays |
| S2 | A tap outside the chart after S1 | The tooltip hides | The tooltip stays |
| S3 | `events: ['mousemove']`, touch tap | The tooltip shows | Nothing |
| S4 | Touch tap on a legend item, `onHover` set | `onHover`, then `onClick` | `onClick` only |
| S5 | A tap outside after S4 | `onLeave` | Nothing |
| S6 | `events` with `pointerout` or `pointerleave` and without `mousemove` and `click`, touch lift | The tooltip hides | Nothing |
| S7 | `events` with `pointerup`, tap on a legend item | `onClick` 2 times | Same |
| S8 | Mouse move and exit in one frame | `mousemove`, then `mouseout` with separate DOM events (E2). Chrome coalesces the moves of one frame: an exit to another element gives `mouseout` only (Open 10) | Same |
| S9 | Mouse exit inside a legend hit box | The hover stays | Same |
| S10 | Mouse click with a move of 19 px or more | `click` | No `click` |
| S11 | Chart with `click` inside `GestureDetector.onTap` | Both get the click | Only the chart |

Each difference changes a value that [Chart.js ADR 0034](0034-no-display-only-js-exactness.md)
protects: the active elements (a public return value), the tooltip opacity, the legend callbacks
that run and the dataset visibility (discrete decisions).

The cause of S10 is the recognizer of the host. It has no `gestureSettings`. Thus
`preAcceptSlopTolerance` falls back to 18 logical pixels (`gestures/recognizer.dart:640-652`,
`gestures/constants.dart:65`), also for a mouse. A DOM mouse click has no distance rule. The cause
of S11 is the arena: the recognizer wins the tap against a tappable ancestor. A DOM click bubbles
to the ancestor too. [Chart.js ADR 0014](0014-input-events-and-chart-host.md) Open names the
arena-free click as the alternative.

### Changes from Chart.js ADR 0014

This ADR states the complete decision of [Chart.js ADR 0014](0014-input-events-and-chart-host.md)
with these changes, and supersedes it:
1. The event table of §6 gets the touch boundary events, the compatibility mouse events of a
   tap, the long press and the `mouseout` of a tap outside (sections 6, 8 and 9).
2. §7 changes: the host claims nothing in the gesture arena. Its own click rule gives `click`
   (section 7). A global pointer route exists while the compatibility mouse is over a host
   (section 9).
3. The Open items of #7738, the compatibility mouse events and the arena-free click close.
4. New sections give the plugin input rules (section 14) and the harness and gallery rules
   (section 15).
5. Sections 3 and 4 state the host rules that [Chart.js ADR 0022](0022-chart-test-harness.md) §10
   added: the first resize notification at the next layout and the mutation checkpoint.
6. The touch rows apply to all touch-like kinds, also the stylus. They follow the Chromium rules
   of a touch sequence (sections 6 and 8): no event for a move with no change, no `touchmove`
   inside the slop, the cancel at the pan begin, and the compatibility events at the down
   position (at the up position for a stylus and an inverted stylus).

The other sections keep the decisions of Chart.js ADR 0014.

## Decision

### 1. Platform files

- `lib/src/platform/index.dart` ports `index.js`. `detectPlatform` returns the constructor
  tear-off of the class, because `core.controller.js:135` calls the result with `new`. It gives
  `FlutterPlatform` for a canvas whose parent node is a chart host. It gives `BasicPlatform` for a
  canvas that no host shows, the counterpart of an `OffscreenCanvas`, and for an item that is not
  a canvas. The upstream test `_isDomSupported()` is always false in the port. Thus one
  `DIVERGES` hunk tests for a host instead (`differences.md` row `platform-detect-host`).
- `platform.base.dart` and `platform.basic.dart` are line-by-line ports.
- `platform.flutter.dart` replaces `platform.dom.js`. Its `parity.md` status is `replaced`. It
  keeps the upstream structure and names: `eventTypes` (`EVENT_TYPES`), `fromNativeEvent`,
  `initCanvas`, `createAttachObserver`, `createDetachObserver`, `createResizeObserver`,
  `createProxyAndListen`, `releaseObserver`, and `FlutterPlatform` with `acquireContext`,
  `releaseContext`, `addEventListener`, `removeEventListener`, `getDevicePixelRatio`,
  `getMaximumSize` and `isAttached`. Each declaration has a `///` line with the `platform.dom.js`
  lines that it replaces. A port-only file has no `DIVERGES` markers.
- `lib/src/platform/native_event.dart` (port-only, pure) declares `NativeEvent`, the stand-in for
  the DOM `Event`, `MouseEvent`, `PointerEvent`, `TouchEvent` and `WheelEvent`. It has `type`,
  `offsetX` and `offsetY` (logical pixels from the top left corner of the chart), `touches` (a
  list of `NativeTouch` records `(identifier, x, y)`, sorted by pointer id), `target` (the canvas)
  and the opaque `source` (the Flutter `PointerEvent`). `fromNativeEvent` makes the `ChartEvent`
  (`type`, `chart`, `native`, `x`, `y`).

### 2. Chart host

`lib/src/platform/chart_host.dart` (port-only, not exported) declares `ChartHost`, a
`LeafRenderObjectWidget`, and `RenderChartHost`, a `RenderBox`:
- The host owns no chart. It shows one `UiCanvasElement` of the canvas layer. It is the parent
  node (`CanvasNode.parentNode`) and the `CanvasContainer` of that canvas from the creation of the
  render object to its disposal. Thus "shown by a host" means that the render object exists.
- `isRepaintBoundary` is true. `paint` calls `UiCanvasContext.paint`, also for an empty context,
  because `paint` arms `onChanged` again.
- The host reads the DPR with `MediaQuery.maybeDevicePixelRatioOf`, the ticker state with
  `TickerMode.valuesOf` and the gesture settings with `MediaQuery.maybeGestureSettingsOf` in
  `createRenderObject` and `updateRenderObject`. A DPR change paints the host again, because the
  paint scale reads the DPR (section 5). It calls `onTickerModeChanged` when the ticker state
  changes. The gesture settings give the slop limits of section 8.
- `computeDryLayout` and the intrinsic sizes give the current display size of the canvas,
  constrained. The display size is the two px styles that `retinaScale` writes, else the render
  size (section 5). They cannot predict a resize for other constraints, because a resize has side
  effects.
- The window `resize` listener and its global map (`platform.dom.js:161-189`) have no port. The
  host reports a DPR change to its resize observers. The scrollbar step (`:198-209`) has no port.
- The host does not dispose the `UiCanvasContext`. The owner of the canvas does that.

### 3. First size

The host sizes the chart in its first `performLayout`, before the first paint. The first layout
reports the attach at once, inside `performLayout`
([Chart.js ADR 0016](0016-frame-scheduling.md), decision 9). Thus the chart takes its size from the
container before the first frame shows, as upstream sizes a chart at construction. The port paints
no blank first frame.
- `CanvasContainer.isConnected` is true when the render object is attached and laid out.
- A chart that the code creates before the first layout of its host starts detached. It calls
  `_resize(0, 0)` and makes no update. The first layout then attaches it with one `'attach'`
  update. Thus the chart makes no update for a container of size zero.
- A `ContainerResizeObserver` that starts on a laid-out host gets its first notification at the
  next layout of the host, not at once ([Chart.js ADR 0022](0022-chart-test-harness.md) §10). A
  DOM `ResizeObserver` also gets it at the next rendering step. Thus a responsive chart gets a
  second resize after the attach, as upstream does.

### 4. Later size, DPR and attach changes

- A later change of the constraints or of the DPR reaches the `ContainerResizeObserver`s.
  `createResizeObserver` gives each chart one `throttled<Size?>` function
  ([Chart.js ADR 0016](0016-frame-scheduling.md), decision 9). A `null` size is a DPR change. It
  calls the listener only when `chart.currentDevicePixelRatio` differs (`platform.dom.js:171`).
- The zero-size skip of `platform.dom.js:217-222` stays. The harness emulates `display: none`
  with `SizedBox.shrink`, because `Offstage` gives its child its own constraints
  (`rendering/proxy_box.dart:3918-3923`).
- After the first layout, one post-frame callback of each host reports a net change of the
  attached state. A `GlobalKey` move gives no change. An unmount gives a detach after the frame.
  The harness reports the changes earlier, at its mutation checkpoint `flushCanvasMutations`
  ([Chart.js ADR 0022](0022-chart-test-harness.md) §10). After a checkpoint, the post-frame
  callback finds no change.
- A canvas swap on an existing host (`updateRenderObject` with a new `UiCanvasElement`) reports
  the detach of the old canvas at once, during the build, not after the frame. The new canvas
  attaches in the next layout, as a first attach.
- A new host that takes over the canvas in the same frame (a wrapper toggle, a move to a sibling
  slot without a `GlobalKey`, an `AnimatedSwitcher` cross-fade) takes over the reported attached
  state and the `ContainerResizeObserver`s of the old host. The old host reports nothing.
- The `UiCanvasContext.onChanged` callback fires one time until the next paint. To see a size
  change after the first draw, the host arms the callback again in a microtask and compares the
  display size then. Microtasks run after the transient callbacks and before the layout, so the
  resize lands in the same frame. A check in `paint` with a relayout after the frame is the
  fallback. The host never calls `markNeedsLayout` inside its own `performLayout`.

### 5. Size rules

- The container size is the max size of the incoming constraints. An unbounded side is
  `double.infinity`.
- `FlutterPlatform.getMaximumSize` resolves unbounded sides, because only it knows the aspect
  ratio:
  - Two unbounded sides: the size of the HTML canvas default, 300 x 150 logical pixels, through
    `getMaximumSize(canvas, 300, 150, aspectRatio)` of `helpers.dom.dart`. Thus an aspect ratio
    of 1 gives 150 x 150.
  - One unbounded side and a truthy aspect ratio: the bounded side and the aspect ratio give the
    other side.
  - One unbounded side and no aspect ratio: that side takes the canvas default, 300 wide or 150
    high.
- The host size is `constraints.constrain(displaySize)`. The display size is the `width` and
  `height` styles of the canvas when both are px values. `retinaScale` writes them. Else the
  display size is the render size. The CSS rule for one style keeps the aspect ratio of the render
  size. The host does not apply this rule. The harness matcher `toBeChartOfSize` applies it.
- A chart larger than its box: paint clips to the host box.
- Paint maps the bitmap to the display size with one scale for each axis: the display size
  divided by the bitmap size. When both scales are within 1e-3 of `1 / DPR`, the scale is exactly
  `1 / DPR`. Thus the bitmap pixels stay on the device pixels at a fractional `round1` size. A
  bitmap side of 0 gives a scale of 1.
- The stretch stays, because the DOM shows the bitmap at the display size. Without it, a chart
  with `options.devicePixelRatio: 1` on a DPR 3 view paints at one third of its box. Then the
  pointer positions do not agree with the drawn elements. The hit element also changes. A chart
  that is not responsive also needs the stretch when its styles differ from its attributes.
- The canvas has the `width` and `height` attributes of the DOM
  ([Chart.js ADR 0013](0013-canvas-model.md), section 2). `initCanvas` reads them with
  `getAttribute`, as `platform.dom.js:45-46` does. When an attribute is absent, the render size
  comes from the `width` and `height` styles or from the aspect ratio. `releaseContext` restores
  each attribute with `setAttribute`, or removes it with `removeAttribute`
  (`platform.dom.js:300-307`). It also restores the first `display`, `height` and `width` styles.
  Thus the default spec canvas of `acquireChart`, with the attributes 512 x 512, keeps the render
  size 512 x 512.
- `getDevicePixelRatio` reads the DPR of the host that shows the canvas of the last
  `acquireContext` call. Without a host, it reads `PlatformDispatcher.implicitView`, else 1.

### 6. Event names

Flutter input gives the DOM event names that Chrome fires. Chrome is the reference browser of the
port: [Chart.js ADR 0022](0022-chart-test-harness.md) §6 takes the event positions from Chrome,
and the phase comparisons run the pinned build in Chrome. `PointerDeviceKind` selects the names,
not the platform. `eventTypes` and the `options.events` filter stay as upstream.

| Flutter input | DOM names, in DOM order |
|---|---|
| `PointerDownEvent`, mouse-like kind | `pointerdown`, `mousedown` |
| `PointerMoveEvent` or `PointerHoverEvent`, mouse-like kind, inside the box | `pointermove`, `mousemove` |
| `PointerUpEvent`, mouse-like kind, inside the box | `pointerup`, `mouseup`, then `click` by the click rule (section 7) |
| `PointerCancelEvent`, mouse-like kind, inside the box | `pointercancel` |
| `PointerDownEvent`, touch-like kind, before the pan (section 8) | `pointerover`, `pointerenter`, `pointerdown`, `touchstart` |
| `PointerDownEvent`, touch-like kind, after the pan | `touchstart` |
| `PointerMoveEvent`, touch-like kind, with no change of position, pressure, radii, orientation or tilt | none |
| `PointerMoveEvent` of the tap candidate (section 8) that does not begin the pan | `pointermove` |
| `PointerMoveEvent` of another touch-like pointer before the pan, that does not begin the pan | `pointermove`, `touchmove` |
| the `PointerMoveEvent` that begins the pan (section 8) | `pointermove`, `touchmove`, then for each touch-like pointer of the host, in the order of the pointer ids: `pointercancel`, `pointerout`, `pointerleave` |
| `PointerMoveEvent`, touch-like kind, after the pan | `touchmove` |
| `PointerUpEvent`, touch-like kind, before the pan | `pointerup`, `pointerout`, `pointerleave`, `touchend`, then for a tap (section 8) with its tap point in the box: `mouseover` and `mouseenter` (only when the compatibility mouse is not over the host), `mousemove`, `mousedown`, `mouseup`, `click`. A tap with its tap point outside the box gives these events to no host (section 9) |
| `PointerUpEvent`, touch-like kind, after the pan | `touchend` |
| `PointerCancelEvent`, touch-like kind, before the pan | `pointercancel`, `pointerout`, `pointerleave`, `touchcancel` |
| `PointerCancelEvent`, touch-like kind, after the pan | `touchcancel` |
| a touch-like pointer held past the long-press time as the tap candidate (section 8) | `mouseover` and `mouseenter` (only when the compatibility mouse is not over the host), `mousemove`, while the pointer is down |
| `PointerScrollEvent` | `wheel` |
| pointer enter (`MouseTrackerAnnotation` for the mouse, the host for the other hovering kinds) | `pointerover`, `pointerenter`, `mouseover`, `mouseenter` |
| pointer exit (`MouseTrackerAnnotation` for the mouse, the host for the other hovering kinds) | `pointerout`, `pointerleave`, `mouseout`, `mouseleave` |
| a touch-like tap or long press that does not hit the host of the compatibility mouse (section 9) | to that host: `mouseout`, `mouseleave` |

The mouse-like kinds are mouse and trackpad. The touch-like kinds are all other kinds in contact:
touch, stylus, inverted stylus and unknown. Chrome on Android gives a stylus contact the touch
sequence (Evidence E8, D5). The hover of a stylus or of an inverted stylus has the hover names of
the mouse. The host tracks that hover itself and ignores the `MouseTracker` enter and exit of these
kinds.
- The host makes a `NativeEvent` only for a type that has a listener.
- A mouse move outside the box gives no event, because a mouse has no implicit capture. A mouse
  has no implicit capture for up and cancel either: a mouse `pointerup`, `mouseup` or
  `pointercancel` outside the host box gives no event.
- `MouseTracker` gives enter and exit only for the mouse and the stylus. It also gives them at the
  contact of a stylus that does not hover (Evidence E8, D5). Thus the host uses the
  `MouseTracker` enter and exit only for the mouse. It tracks the hover of the other kinds
  itself, for each device, as `MouseTracker` does: the engine gives each hover event the pointer
  id 0, so a hovering mouse and a hovering stylus have the same pointer id. On the first hover of
  a device that hits the host, it sends `pointerover`, `pointerenter`, `mouseover` and
  `mouseenter`. On a hover of that device that does not hit the host, or on the removal of that
  device, it sends `pointerout`, `pointerleave`, `mouseout` and `mouseleave`. The hover of
  another device, for example a mouse, gives no exit.
- A `touch*` event has NaN `offsetX` and `offsetY`, because the DOM `TouchEvent` has no offset.
  The position comes from `touches`. A `touchend` after the last finger lifts has an empty
  `touches` list. Thus it gives NaN coordinates, as upstream does (`helpers.dom.ts:81-93`).
- A `pointer*` event of a touch-like pointer has the offsets of its event. The `pointerup`,
  `pointerout` and `pointerleave` of a lift have the up position.
- The compatibility `mouse*` events and the `click` of a tap have the tap point of the pointer:
  the down position for a touch and the kind `unknown` (Evidence E8, D4), and the up position for
  a stylus and an inverted stylus, as Chrome gives a pen and an eraser no touch adjustment
  (Evidence E10, row STN10, and Evidence E11). The `mouseover`, `mouseenter` and `mousemove` of a long press have
  the down position for each kind. The host converts the point to its own coordinates at the
  time of the event, as Chromium hit-tests the screen point of the tap when it sends the tap. A
  tap point outside the host box gives the host no compatibility event and no `click`. That tap
  then moves the compatibility mouse off its owner (section 9).
- The `pointercancel`, `pointerout` and `pointerleave` of the pan begin have the position of the
  view origin in the coordinates of the host, as Chrome gives them the client point (0, 0)
  (Evidence E8, D3). A platform cancel has the position of its event (Open 17). The view origin
  is the analog of the client point (0, 0). When the Flutter view includes the status bar (an
  edge-to-edge app), the two points are not at the same place on the screen: on the Pixel 8a of
  the check, Chrome gave (-16, -40) and the port gives (-16, -86.1) for the same canvas. Both
  points are outside the chart area, and the chart events and the state are equal (Evidence
  E8).
- A `mouseout` or `mouseleave` of a tap outside has the tap point of that tap, and of a long press
  outside the down position of that pointer, in the coordinates of the host that gets it.

### 7. The click rule

The host gives `click` by the DOM rule. It adds no recognizer to the gesture arena.
- A mouse-like pointer: a down with the primary button (`buttons == kPrimaryButton`) on the host,
  then the up of the same pointer inside the box, gives `click` at the up position, after
  `mouseup`. The distance between the down and the up has no limit. An up outside the box gives
  no `click`, because the DOM sends the click to the common ancestor. A down with another button
  gives no `click`. `contextmenu` and `auxclick` have no mapping (section 16).
- A touch-like pointer: a tap (section 8) gives `click` at its tap point (section 6), after its
  compatibility mouse events. A long press gives no `click`.
- The host emits `click` in `handleEvent`, synchronously. Thus the compatibility events and
  `click` of one tap come in the DOM order.

### 8. The touch sequence, the tap rule and the long press

One set of rules decides the events of the touch-like pointers. They are the Chromium rules of a
touch sequence (Context). The device check confirmed them for D1 to D5 on Android (Evidence E8).
The epsilon of 0.05 and the stylus factor of 1.5 of the slop limit come only from the Chromium
source (Evidence E9). The device data does not show them (Open 1). The host and the route of
section 9 use the same tap rule.
- **The slop limit** of a pointer is `computeHitSlop(PointerDeviceKind.touch, gestureSettings)`
  (`gestures/events.dart:2552-2562`), times 1.5 for `PointerDeviceKind.stylus`, plus 0.05 logical
  pixels. `computeHitSlop` gives the platform touch slop of `MediaQuery`, else `kTouchSlop` (18
  logical pixels). An inverted stylus has the touch slop, as an eraser in Chromium. A pointer is
  past its slop limit when it is farther than the limit from its own down: the host compares the
  squares. On Android, the platform touch slop is the `ViewConfiguration` touch slop: 21 physical
  pixels / 2.625 = 8.0 logical pixels on the Pixel 8a. The first `touchmove` of Chrome came 8 to
  9 px from the down (Evidence E8).
- **The sequence.** A touch sequence of the host starts at a touch-like down when no touch-like
  pointer is down on the host.
- **The move filter.** A `PointerMoveEvent` of a touch-like pointer gives no event when its
  position, `pressure`, `radiusMajor`, `radiusMinor`, `orientation` and `tilt` are equal to the
  last event of that pointer that gave events. The host compares the position first, so a moving
  pointer stops at the first compare.
- **The tap candidate** starts at a touch-like down when no other touch-like pointer of the host is
  down. A second touch-like pointer on the host ends it. This stands for the primary pointer of
  Pointer Events 3 §4.1.2 and for the end of the Blink suppression at a second touch.
- **The suppression.** A move of the tap candidate that does not begin the pan gives `pointermove`
  only. A move of another touch-like pointer before the pan gives `pointermove` and `touchmove`.
- **The pan begin.** Before the pan, a touch-like move with a change begins the pan when that
  pointer is past its slop limit, or when the sequence had more than 2 touch-like pointers on the
  host. It gives `pointermove` and `touchmove` for that move. Then it cancels each touch-like
  pointer of the host, in the order of the pointer ids, with `pointercancel`, `pointerout` and
  `pointerleave` at the view origin (section 6). It ends the tap candidate, also a long-pressed
  candidate. Thus a move past the slop limit after a long press also begins the pan.
- **After the pan begin**, until all touch-like pointers of the host lift, a down gives
  `touchstart` only, a move `touchmove` only, an up `touchend` only and a cancel `touchcancel`
  only. The host keeps this state for its own pointers. Chrome keeps it for the page (Open 14).
- A cancel ends the candidate.
- An up of the candidate pointer before the long-press time is a tap. Its tap point is the down
  position, or the up position for a stylus and an inverted stylus (section 6).
- The long-press time is `kLongPressTimeout` (500 ms, `gestures/constants.dart:29`). A timer
  starts at the down of a candidate. When it fires and the candidate still exists, the candidate
  is a long press. The host sends `mouseover` and `mouseenter` (only when the compatibility mouse
  is not over the host) and `mousemove` at the down position of the pointer. The host becomes
  the host of the compatibility mouse (section 9). The lift of a long press gives no
  compatibility event and no `click`. A browser sends `contextmenu` there. It has no mapping
  (section 16).
- The host cancels the timer at the end of the candidate, at `detach` and at `dispose`.

### 9. The compatibility mouse

A browser has one compatibility mouse. The port has one for each isolate: a static owner of
`RenderChartHost`.
- A tap or a long press on a host makes that host the owner. When another host was the owner, that
  host first gets `mouseout` and `mouseleave` at the tap point of the tap, in its own
  coordinates.
  Then the new owner gets `mouseover` and `mouseenter`. A tap on the owner gives no `mouseover`
  and no `mouseenter`.
- While an owner exists, one static global pointer route
  (`GestureBinding.instance.pointerRouter.addGlobalRoute`) watches the touch-like pointers of the
  app.
  The host adds it when an owner starts and removes it when the owner ends.
- The route ignores each pointer that went down on a host. `GestureBinding.dispatchEvent` calls
  the hit path before `GestureBinding.handleEvent`, which routes the event
  (`gestures/binding.dart:506-546`). Thus the host records its pointer at the down before the
  route sees it.
- The route also ignores the pointer of the tap that made the owner. A global route that the host
  adds in its `handleEvent` of an up sees that same up, because `PointerRouter.route` copies the
  global routes after the hit path ran (`gestures/pointer_router.dart:124-131`).
- The route applies the tap rule of section 8 to the other touch-like pointers. A tap or a long
  press that does not hit a host gives the owner `mouseout` and `mouseleave` at the tap point of
  that tap or the down position of that long press, in the coordinates of the owner. Then the
  owner ends, and the route goes. A drag or a scroll outside is not a tap and gives nothing, as in
  Chrome.
- A tap on a host with its tap point outside the box of that host (a stylus that lifts outside the
  box) does not hit a host either. The host gives the owner `mouseout` and `mouseleave` at the tap
  point, also when the owner is that host. Then the owner ends. The host does not look for another
  host at the tap point (Open 19).
- The route ignores the mouse-like kinds. A real mouse keeps the `MouseTracker` path.
- At `detach` and at `dispose` of the owner, the owner ends without an event, and the route goes.
  A DOM element that leaves the document gets no `mouseout` either.

### 10. Gesture arena and touch scope

- `hitTestSelf` returns true. The host reads the raw `PointerEvent`s in `handleEvent`, with no
  claim in the gesture arena, for move, down, up, cancel, hover and scroll. Thus parent
  scrollables keep their drags, and tappable ancestors (`GestureDetector.onTap`, `InkWell`,
  `ListTile.onTap`) keep their taps. A DOM click also reaches them, by bubbling.
- `wheel` does not claim the pointer signal, because upstream registers passive listeners and the
  page still scrolls.
- The host sends `pointercancel` at the pan begin also when no parent scrolls, as Chrome does with
  the default `touch-action` of the canvas. In the device check the page could not scroll
  (Evidence E8, D3).
- Touch scope: the chart gets the pointers that hit it, through normal hit testing. The only
  global route is the route of the compatibility mouse (section 9). It gives the owner only
  `mouseout` and `mouseleave`.

### 11. Listeners, the throttle and the frame order

- The listeners live on the canvas element, as DOM listeners do. A registry in an `Expando`
  (`addCanvasEventListener`, `dispatchCanvasEvent`) stands in for the `EventTarget` of the canvas.
  The listeners stay when the canvas moves to another host.
- Each event type gets its own throttled proxy ([Chart.js ADR 0016](0016-frame-scheduling.md),
  decision 9).
  Thus a click and a mouse move in one frame both reach the chart.
- The proxies of one frame run in the order of the first event of each type in that frame.
  `SchedulerBinding` runs the transient frame callbacks in the order of their registration
  (`scheduler/binding.dart:1259-1268`), as HTML runs the animation frame callbacks. Thus a
  `mousemove` and a `mouseout` in one frame reach the legend in the upstream order, also when the
  last pointer position is inside the chart. This is the model of separate DOM events. Chrome
  coalesces the moves of one frame (Open 10). The port keeps this order. It does not sort the
  events of a frame.
- `MouseTracker.updateWithEvent` sends the enter and exit callbacks before the dispatch of the
  event to the hit path (`rendering/binding.dart:465-474`). A browser also sends the boundary
  events before the `mousemove` on the new target.
- The proxy keeps the guard of `platform.dom.js:246`: it calls the listener only while
  `chart.ctx != null`.
- The listener options `{passive: true}` have no port. The host never claims a pointer for an
  event listener.
- `BasePlatform.addEventListener` and `createResizeObserver` take a `Function` and cast it. Thus
  `core.controller` declares its listeners with these shapes:
  - `void Function(ChartEvent)` for the event types
  - `void Function([double? width, double? height])` for `'resize'`
  - `void Function()` for `'attach'` and `'detach'`

### 12. Event position

`getRelativePosition` (`helpers.dom.dart`) keeps the `Math.round` (`jsRound`) of each coordinate.
It takes the first entry of `touches`, else `offsetX` and `offsetY`. These values come from
`PointerEvent.localPosition` and are already in the logical pixels of the chart. Thus the port
drops the factor `/ chart.width * canvas.width / currentDevicePixelRatio`. `retinaScale` gives
the canvas `trunc(round1(width * dpr))` device pixels, so the factor is
`trunc(round1(width * dpr)) / (width * dpr)`. For a fractional device width the result can
differ from upstream by 1 px: width 300.5 at DPR 1 and `offsetX` 150.6 give 151, where upstream
gives 150. The port has no CSS offsets and no `clientX` fallback. One `DIVERGES` hunk carries
this, with the row `platform-relative-position`. For a `ChartEvent`, the function gives a `Point`
that reads the `x` and `y` of the event.

### 13. Type members

`lib/src/types/index.dart` has the members that the ported platform code reads:
- `Chart`: `canvas`, `ctx`, `width`, `height`, `currentDevicePixelRatio` and `platformProxies`
  (the `$proxies` of `core.controller.js:168`).
- `ChartEvent`: `native`, `x`, `y` and `chart` (`platform.dom.js:114`).
- `BasePlatform`: the full method set of `platform.base.js`.
- `ChartConfiguration` with `options` (`index.d.ts:3865`). The `Config` of `core.config`
  implements it.

The types library imports `canvas.dart` and `native_event.dart`. Both are pure, port-only
stand-ins for `lib.dom.d.ts`. This departs from the letter of
[Chart.js ADR 0003](0003-type-only-dependencies.md) but keeps its intent, purity.

### 14. What the legend and the tooltip read

The plugins read only chart events. Nothing in the plugins, in `core.controller` or in
`platform.flutter.dart` changes for input.
1. **Event types.** The legend reads `mousemove`, `mouseout`, `click` and, from user `events`,
   `mouseup`. The tooltip reads each filtered event. The default `events` stay as upstream. The
   filter reads the native type on each notify, as `core.controller.js:1170` does. The port adds
   no memo of the filter.
2. **Two hit tests.** The chart hover hit test (`_handleEvent`) and the tooltip hit test
   (`_getActiveElements`) stay two calls. The hover styles run between them. Thus a shared result
   changes the hit element (Evidence E2).
3. **The legend hit.** The host does not change. `getRelativePosition` rounds the position
   (section 12). The port of `_getLegendItemAt(x, y)` reads a Dart `null` coordinate as 0, the
   `ToNumber` of JS `null` at `_isBetween` (`x ?? 0` or `jsToNumber(x)`, equal for a
   `double?`). A NaN coordinate (a `touchend`) hits no item, as upstream. The form of the hit
   boxes is a decision of the legend port, not of the input path.
4. **#7738: the tooltip after a touch lift.** The port keeps the upstream behavior of Chrome. The
   tooltip stays after the lift. A tap on an empty point of the chart area hides it (the
   compatibility `mousemove` and `click` find no element in the default mode). A tap outside the
   chart hides it through the `mouseout` of section 9. A user who wants a hide on lift adds
   `pointerout` or `pointerleave` to `events` and removes `mousemove` and `click`, as in Chrome.
   With the default `events`, the compatibility `mousemove` and `click` of the lift come after the
   `pointerout` and show the tooltip again. The port adds no port-only hide, no fade and no
   `touchend` in the default `events`. The ledger Signal #7738 stays open: the port follows upstream
   when a release changes it.
5. **`events: ['mousemove']` on a touch device.** A tap gives the compatibility `mousemove`. The
   tooltip shows. A touch drag gives `touchmove`, which the chart does not listen to, as in Chrome.
6. **A tap outside the chart.** Section 9 gives `mouseout`. The tooltip hides, and the legend
   calls `onLeave` for a hovered item.

### 15. The harness and the gallery

- `triggerMouseEvent` and `afterEvent` of `packages/chartjs_test_utils` do not change
  ([Chart.js ADR 0022](0022-chart-test-harness.md) §5 and §6). They dispatch to the canvas
  listeners, under the host, with no hit test and no gesture arena. The legend spec cases
  (`plugin.legend.tests.js:1063`, `:1109`, `:1149`) and the tooltip spec cases use `mousemove`,
  `mouseout`, `click` and `pointerdown` through them.
- `releaseCharts` unmounts the hosts. The `detach` and `dispose` of section 9 then end the
  compatibility mouse. Thus no global route stays from one test to the next test of a file.
- The gallery has no input code. On a phone, a tap on a point shows the tooltip, a tap on a
  control outside the chart hides it, and a tap on a legend item toggles its dataset.

### 16. Scope of later phases

- Keyboard events and semantics are port-only and come in phase 9.
- The public widget of phase 9 builds on the host. It creates the chart after the `ChartHost`
  render object exists, else `detectPlatform` gives `BasicPlatform`. It disposes the
  `UiCanvasContext` with `Chart.destroy`.
- `onTickerModeChanged` connects to `animator.mute` and `animator.unmute`
  ([Chart.js ADR 0016](0016-frame-scheduling.md), decision 7).
- These inputs have no mapping: `dblclick`, `contextmenu` (a secondary click or the end of a long
  press), `auxclick`, `gotpointercapture`, `lostpointercapture` and trackpad `PointerPanZoom`
  gestures as `wheel`. Chrome sends `gotpointercapture` and `lostpointercapture` around the
  `pointerup` and the `pointercancel` of a touch (Evidence E8).
- Touch sizes (hit radius, hover radius, font size) stay with phase 9
  ([theming.md](../theming.md) §11).

### 17. Tests, rows and records

- No `differences.md` row is new. All changes are in the port-only host. "A port-only file is not
  a row" (`differences.md`, introduction). This ADR records the reference browser and the iOS
  result.
- The rows `platform-detect-host`, `platform-relative-position`, `platform-animator-mute` and
  `platform-dom-supported` cite this ADR in place of Chart.js ADR 0014. The row
  `harness-trigger-mouse-event` keeps its text.
- `test/port/platform/chart_host_test.dart` pins sections 6 to 10 with real Flutter gestures.
- A port-only reference test pins the whole path (host, throttle, `_eventHandler`, legend and
  tooltip) against the pinned build in the x64 Node.js. Its generator feeds the chart events of
  the Chrome event sequence of each gesture to `chart._eventHandler`, one call for each type in a
  frame, in the order of section 11. The Dart test drives the same gestures as Flutter pointer
  events through `ChartHost` on charts of `acquireChart`.
- The rules of section 8 that the device check found (D1 to D5) are in the port-only host. They
  need no `differences.md` row either.
- The gate of this ADR: the decision is implemented, the gates are green, the independent
  recompute of the device check agrees with Evidence E8, and a device re-run of its rows with the
  changed host (Open 1) confirms the table of section 6 and the rules of section 8. A different
  device result changes the table before the ADR goes to accepted.

## Alternatives considered

- **A. The ADR 0014 form.** No change of the host. Rejected. The rows S1 to S6, S10 and S11 stay
  different.
- **The compatibility triple only.** The host sends `mousemove`, `mousedown` and `mouseup` at the
  lift of a tap, with no boundary events and no global route. Rejected. A tap outside keeps the
  tooltip (S2, S5), and each `events` list with `pointerout`, `pointerleave`, `pointerover` or
  `pointerenter` differs on every browser (S6). It also changes ADR 0014 §6, so it saves no ADR
  work.
- **The browser model with the tap recognizer.** The host sends the boundary events, the
  compatibility events and the `mouseout` of a tap outside, and the `TapGestureRecognizer` keeps
  `click`. Rejected. S10 and S11 stay. S3 needs the recognizer for a `mousemove` listener, and
  then a tappable ancestor loses its tap. The recognizer slop (18) and the compatibility slop
  (`computeHitSlop`) also differ on a platform with another touch slop. Then a move between the
  two slops gives `click` without compatibility events, or the reverse. No browser does this.
- **Only the `mouseout` of a tap outside.** Rejected. S1, S3, S4, S6, S10 and S11 stay.
- **Hide the tooltip at a touch lift.** Rejected. It differs from every browser: `touchend` is not
  in the default `events`. It needs a `DIVERGES` hunk in `plugin.tooltip.js:1139-1172`, a hot
  module.
- **Fade the tooltip after a lift.** Rejected. As the hide on lift, with a timer state.
- **`touchend` in the default `events`.** Rejected. It changes a resolved option, and the mapped
  `mouseup` moves or hides the tooltip at each lift.
- **A `TapRegion` around the host for the tap outside.** Rejected. It fires at a pointer down,
  also at the start of a scroll, where a browser sends no compatibility event. It needs a
  `TapRegionSurface` ancestor, which the harness does not have.
- **A memo of the event filter for each native type.** Rejected. It saves 0.6 to 1.1 µs for each
  event, below 0.02 % of a frame. An in-place write `chart.options.events.push(...)` keeps a stale
  memo.
- **One hit test for the hover and the tooltip.** Rejected. It changes the hit element (E2).
- **All pointers through `pointerRouter.addGlobalRoute`.** Rejected. The chart then sees pointers
  of other widgets. Normal hit testing gives the pointers that the DOM gives to the canvas. The
  global route of section 9 gives only the `mouseout` of the compatibility mouse.
- **A pan or drag recognizer for move events.** Rejected. It takes drags from parent
  scrollables, as fl_chart #202 shows.
- **A `DoubleTapGestureRecognizer` for `dblclick`.** Rejected for now. It delays each single tap.
- **Size the chart in a post-frame callback after the first layout.** Rejected. The port then
  paints one blank first frame. Upstream sizes a chart at construction.
- **Infinity to 0 for unbounded constraints.** Rejected. A chart in a `Column` or a `ListView`
  then has no size. The canvas default of 300 x 150 is what a DOM canvas without a size has.
- **Paint a larger chart outside the box.** Rejected. It paints over the siblings. A DOM canvas
  inside a container with `overflow: hidden` is clipped too.
- **Keep the factor `/ chart.width * canvas.width / currentDevicePixelRatio`.** Rejected. Flutter
  already gives the position in the logical pixels of the chart. The factor only changes the
  digits at fractional sizes.
- **No attributes, no style reads in `initCanvas` and no style restore** (option B of
  [canvas-cuts-plan.md](../canvas-cuts-plan.md) §3.3). Rejected. Upstream gives 300 x 300 for a
  doughnut, pie, polar area or radar chart that is not responsive, on a canvas without a height.
  The port then gives 300 x 150. This needs a `DIVERGES` row and about 11 `diverges:` skips.
- **Paint at `1 / DPR` only, with no stretch.** Rejected. A chart with an
  `options.devicePixelRatio` that differs from the view DPR then paints at the wrong size. The hit
  element then changes (section 5).
- **The host size from `AspectRatio` or `SizedBox` in place of `getMaximumSize`.** Rejected. It is
  a second source of the size. It caps the attach resize by the container height. It has no
  `round1`. `onResize` and the `resize` plugin hook need `_resize` of `core.controller`.

- **The up position for the compatibility events and `click` of a touch** (the first text of this
  ADR). Rejected. Chrome puts them at the down position (Evidence E8, D4). After a move of 7 px, the
  up position misses the point that Chrome hits, and the active elements and the tooltip differ.
- **The down position for the compatibility events and `click` of a stylus** (the text of
  2026-10-23). Rejected. Chrome gives a pen no touch adjustment and puts them at the up position
  (Evidence E10, row STN10). After a stylus move of 10 px, the down position showed the tooltip of
  point 1 in the port, and Chrome showed no tooltip.
- **A hit test at the up point of each stylus tap**, to give the tap to the host under that point
  (`GestureBinding.hitTestInView`). Not now (Open 19). It changes the result only for a stylus
  tap that moves from one element onto another inside the stylus slop. It adds a second hit test
  path to the host and to the route.
- **The pan cancel at the finger position.** Rejected. Chrome gives the cancel the client point
  (0, 0). With `pointerout` or `pointerleave` in `events`, the finger position can keep a legend
  hover or an active element that the view origin clears.
- **No cancel at the pan: `pointermove` and `pointerup` to the end** (the first text of this ADR,
  and Open 3 of that text). Rejected. Chrome cancels at the slop also when nothing scrolls
  (Evidence E8, D3). A `pointerup` listener then gets an event in the port only, and a
  `pointerout` listener gets it at the lift, not at the slop.
- **The stylus as a mouse-like kind** (the first text of this ADR). Rejected. Chrome on Android
  gives a stylus contact the touch sequence (Evidence E8, D5). With the default `events`, the
  chart then gets `touchstart`, the compatibility `mousemove` and `click`, not `click` only.
- **A move filter on the delta only (`delta == Offset.zero`).** Rejected. A resting finger with a
  change of pressure gets moves in Chrome. The cost difference is five `double` compares for a
  still pointer only.
- **The cancel of only the pointer that leaves its slop, and the suppression for each pointer.**
  Rejected. Blink cancels all pointers that do not hover at the pan begin, and it ends the
  suppression at a second touch. Then the second finger gets `touchmove` in Chrome.
- **No pan begin after a long press.** Rejected. The Chromium move branch has no long-press test.
- **The `localPosition` of the down event for the compatibility events.** Rejected. Chromium
  hit-tests the screen point of the down when it sends the tap. `globalToLocal` at the time of
  the event gives the same value when the host did not move. It costs one conversion for each tap
  or long press, not for each move.

## Consequences

- A touch tap on a chart gives the Chrome sequence. With the default `events`, the chart gets
  `touchstart` at the down, and the compatibility `mousemove` and `click` at the lift. The lift
  frame has one more chart event than before: one hover hit test and one tooltip hit test for
  each tap, not for each frame. A browser pays the same cost.
- A tap anywhere outside the chart hides its tooltip, also on iOS. iOS Safari keeps the tooltip
  there (#7738). The port gives the Chrome result on all platforms.
- Parent scrollables, `PageView` and `ListView` keep their gestures. Tappable ancestors also get
  the tap of a chart with a `click` listener, as with DOM bubbling. The test 'a tappable ancestor
  gets 0 tap with the chart events [click]' of Chart.js ADR 0014 now gives 1 tap.
- A mouse click with a long move inside the box gives `click`, as in a browser.
- While the compatibility mouse is over a chart, each touch-like pointer event of the app goes
  through one more global route: about 160 ns for each event on JIT (E5).
- A touch held for 500 ms on a chart gives the compatibility `mousemove` at the down position.
  The tooltip then shows before the lift, as in Chrome.
- A finger that rests on a chart, or that moves inside the slop as the tap candidate, gives the
  default `events` no chart event, as in Chrome. Before the device check the host sent
  `touchmove` for each move, and the chart got one `mousemove` in each frame: one hover hit test
  and one tooltip hit test, about 214 µs at 10000 points on JIT (E5). The host path itself costs
  150 to 180 ns less for each of these moves (E5).
- A drag past the slop gives `pointercancel`, `pointerout` and `pointerleave` at the slop, while
  the finger is down. A `pointerup` listener gets no event for that drag, and a `pointerout`
  listener gets it at the slop, as in Chrome.
- A stylus tap and an inverted stylus tap give the touch sequence, the compatibility events and
  `click`, at the up position.
- The legend and the tooltip need no input code of their own. Their spec cases run through the
  harness with no change.
- `getRelativePosition` gives the upstream values for a chart whose canvas has the device size
  of `retinaScale`. Two `helpers.dom` spec cases skip as `diverges: platform-relative-position`.
  The DOM-only spec cases (element ids, iframes, the DOM-tree `isAttached` case, shadow DOM, CSS
  sizes) skip as `n/a`. The rows `platform-dom-container`, `platform-dom-no-css`,
  `platform-dom-computed-style` and `platform-dom-supported` record the other `helpers.dom`
  hunks.
- The live citations of Chart.js ADR 0014 move to this ADR: `AGENTS.md`, `doc/README.md`,
  `porting-flow.md` §2.7, §2.9 and §7, `status.yaml` (then `parity.md` through tool 6),
  `canvas-cuts-plan.md`, `upstream-ledger.md` (Signal #7738), `differences.md` rows
  `platform-detect-host`, `platform-relative-position`, `platform-animator-mute` and
  `platform-dom-supported`, the comment of `tool/reference/controller_doughnut_reference.mjs`,
  and the `///` and `//` lines of `lib/` and `test/`.

## Open

1. **Device check (the gate of this ADR).** The check ran on 2026-10-23 (Evidence E8). Its five
   differences D1 to D5 changed sections 6 to 10 and the model of the reference generator. These
   parts are NOT CHECKED, with their reason:
   - the mouse rows of section 6 (a move or hover, a cancel, a scroll, an enter and an exit of a
     mouse-like pointer, rows M01 and M02): no mouse in the runs;
   - the platform cancel of a touch-like pointer: no gesture of the check gives one (Open 17);
   - a tap outside while a finger is already down outside (the second part of Open 6, row H03):
     it needs a person;
   - the rule of the second touch-like pointer of section 8 (a two-finger tap, and a tap with a
     second finger down outside, Open 11, rows H01 and H02): it needs a person (Open 14);
   - the epsilon of 0.05 of the slop limit (section 8): the first `touchmove` of Chrome came 8.03
     to 8.73 px from the down, and a limit of 8.0 gives the same rows. `adb` gives whole
     physical pixels: 21 px is 8.000 px and 22 px is 8.381 px on the Pixel 8a, with the same
     result for a limit of 8.0 and of 8.05. The epsilon is 0.13 physical px. Only a finger with
     fractional positions can show it. The epsilon comes from the Chromium source (Evidence E9);
   - the stylus factor of 1.5 of the slop limit (section 8): in the re-check (Evidence E10), a
     stylus move of 9.9 to 10.3 px gave a tap (STN10) and a move of 14.1 px the pan (STN14), on
     both sides. Thus the stylus limit of Chrome is between 10.3 and 14.1 px. This agrees with
     12.05 px. `adb` cannot show the exact factor;
   - the inverted stylus (section 6): no device row.
   The device re-run of 2026-10-23 (Evidence E10) ran the rows of the check with the host of the
   input fix. It also ran a hold of 600 ms and then a drag of 30 px (LPD, Open 15), a stylus move
   of 10 and 14 px (STN10, STN14), and a touch move of 8 and 9 px (SN08, SN09). All rows but STN10
   gave the Chrome result (T15 with a difference in the moves only, Open 10). STN10 changed section
   6. The independent recompute of Evidence E8 and E10 agrees with them. The device round g1 of
   2026-10-29 (Evidence E11) ran STN10 again with the host of this revision, and the rows ST1,
   STN14, S04, S07, SN08, T01, T02 and T05 with it. All 9 rows gave the Chrome result. Thus the
   device gives the tap point of a stylus at the up position (section 6). Round g1 also ran three
   stylus rows: a long press at the down position with no `click` (STLP), a stylus tap outside
   that gives `mouseout` and `mouseleave` (STO10), and a stylus tap that lifts outside the box of
   its host and gives `mouseout` and `mouseleave` with no `click` (STE10). They gave the Chrome
   result too. The gate of this ADR is met.
2. **iOS.** Safari keeps the tooltip at a tap outside. The port gives the Chrome result on iOS
   too. A later ADR can change this for each platform if a user asks for it.
3. **`touch-action`.** Closed by the device check (D3): the host cancels the pointers at the pan
   begin (section 8). A page can set `touch-action: none` on the canvas, and then Chrome does not
   cancel. Chart.js sets no `touch-action`, and the host always gives the default.
4. **A mouse and a touch screen on one device.** A browser shares one compatibility mouse between
   them. The port keeps the `MouseTracker` path for the mouse, and the route ignores it. Phase 9.
5. **Several views.** The compatibility mouse is one for each isolate. A multi-view app can need
   one for each view (`PointerEvent.viewId`).
6. **The primary pointer.** The tap rule sees only the touch-like pointers of the host. A finger
   that is down on another widget does not stop a tap on the chart. Chrome then has no primary
   pointer on the canvas and sends no compatibility events. The device check did not run the rows
   with two fingers (Open 1). The route also knows only the touch-like pointers that went down after
   the owner started. A finger that was down outside before then does not stop a tap of a second
   finger outside: the owner gets `mouseout`. Chrome sends no compatibility event for that tap.
7. **A mouse drag from outside.** A mouse drag that starts outside the chart gives no `mousemove`
   over it, because the host is not in the hit path of that pointer. A fix needs a global route
   for the mouse pointers that are down.
8. **A DPR change on a real device** is not verified.
9. **The hit box form of the legend.** A typed hit box class is 7 to 31 times faster than a Map in
   a microbenchmark (E5). The legend port decides the form by the performance rule. It needs an
   `adapt` row if it is a class.
10. **Coalesced moves.** Chrome dispatches `mousemove`, `pointermove`, `touchmove` and `wheel`
    once in each frame, before the animation frame callbacks, and coalesces them
    (`getCoalescedEvents`). It sends the boundary events of the last position. A discrete event
    (for example the mouse leaving the window) sends the pending move first. The host sends each
    Flutter pointer event ([Chart.js ADR 0016](0016-frame-scheduling.md): `GestureBinding` does
    not coalesce). Thus a mouse that crosses the canvas edge two times between two frames gives
    `mousemove` and `mouseout` in the port, and only the boundary events of the last position in
    Chrome. The legend `onHover` and `onLeave` can then run in the port only. In the reference
    case 'mouse: legend item 2, an exit and legend item 1 in one frame', the port ends with no
    hover while the mouse is on legend item 1. The reference cases of the mouse pin the model of
    separate DOM events. Flutter on the web gets the events after the browser coalesced them. The
    device check shows the same for touch: Chrome sent 11 to 20 moves for a drag, and the port 48
    to 74. The chart events and the state were equal (Evidence E8).
11. **`touches`.** `NativeEvent.touches` holds only the touch-like pointers that went down on the
    host (the DOM `targetTouches`). The DOM `touches` holds every touch point on the screen, and
    `helpers.dom.ts:81-82` reads `touches[0]`. With a finger down outside the canvas, a `touch*`
    event can have another position in Chrome, and another hit element.
12. **A resting pointer with a change of pressure, orientation or tilt only.** The host sends
    moves, as Chromium does. The radii: Flutter gives the size of the tool
    (`AndroidTouchProcessor`, `getToolMajor` and `getToolMinor`), and Chromium compares the size
    of the touch. NOT CHECKED: no device row.
13. **A down with no touch major.** Chromium doubles the slop of the tap and of the pan begin
    (`kExpandSlopFactorForZeroTouchMajor`). Flutter gives no touch major, and the host does not
    model it. A stylus can report no touch major. NOT CHECKED: the touches of the check had a
    touch major.
14. **Two or more touch-like pointers.** The pan check of each pointer against its own down, the
    rule of more than 2 pointers, the cancel of all pointers and its order (`pointercancel`,
    `pointerout`, `pointerleave` for each pointer in the order of the ids), and the pinch. Chrome
    keeps the cancel state for the page, and the host keeps it for itself: two hosts that are
    touched at the same time can differ. NOT CHECKED: the rows with two fingers need a person.
15. **A move after a long press.** The host begins the pan, as the Chromium source does. The
    re-check row LPD gave the same events on both sides (Evidence E10).
16. **A hovering stylus, a desktop pen and the kind `unknown`.** A stylus that hovers on the
    host and then taps it gets these events two times: `pointerover` and `pointerenter` again at
    the down; `pointerout` and `pointerleave` at the up while the stylus still hovers on the host;
    the compatibility `mouseover` and `mouseenter` again with the tap; and a second `pointerout`,
    `pointerleave`, `mouseout` and `mouseleave` when the hover leaves the host. The host tracks
    the hover of each device, because the engine gives each hover event the pointer id 0. Thus
    the hover of a mouse does not end the hover of a stylus. NOT CHECKED: the phone of the check
    has no stylus that hovers.
17. **The position of a platform cancel.** The host keeps the position of the event, as Chromium
    takes the client position from the platform event. NOT CHECKED: no device row gives a
    platform cancel.
18. **The long-press time.** Chrome on the device sent the long press 485 to 492 ms after
    `touchstart` (Android `long_press_timeout` 400). The port uses 500 ms. The check found no
    difference: a hold of 450 ms is a tap and a hold of 550 ms a long press on both sides.
19. **A stylus tap that lifts on another element.** Chrome hit-tests the tap of a pen at the up
    point. When a stylus goes down on one chart and lifts on another chart inside its slop, the
    compatibility events and `click` go to the second canvas. The host of the down gives the
    owner `mouseout` and `mouseleave`, and the second host gets no event. When a stylus goes down
    outside the hosts and lifts on a host inside its slop, Chrome gives that canvas the tap. The
    route gives the owner `mouseout` and `mouseleave` only. Only a tap that starts less than the
    stylus slop limit (12.05 px on the Pixel 8a) from the edge of a host can show this. NOT
    CHECKED: no device row.

## Evidence

- **E0, upstream source** at `v4.5.1+7169e651`:
  - `src/core/core.defaults.js:47-53`, `src/core/core.controller.js:93-102`, `:135`, `:168`,
    `:976-990`, `:1163-1186`, `:1214-1215`
  - `src/platform/platform.dom.js:21-31`, `:45-46`, `:93-101`, `:109-119`, `:161-189`, `:171`,
    `:198-209`, `:217-222`, `:240-254`, `:300-307`
  - `src/helpers/helpers.extras.ts:27-45`, `src/helpers/helpers.dom.ts:73-93`, `:111-131`,
    `src/helpers/helpers.math.ts:205-207`, `src/helpers/helpers.core.ts:414-416`
  - `src/plugins/plugin.legend.js:39`, `:503-522`, `:528-554`, `:582-590`, `:630-634`,
    `:645-656`
  - `src/plugins/plugin.tooltip.js:1139-1172`, `:1183-1208`, `:1264-1272`
  - `test/specs/plugin.legend.tests.js:1063`, `:1099-1105`, `:1109`, `:1141-1144`, `:1149`,
    `:1181`. `test/specs/plugin.tooltip.tests.js` calls `triggerMouseEvent` 34 times: 30 times
    with `mousemove`, 2 times with `mouseout`, 1 time with `click` and 1 time with
    `pointerdown`.
- **E1, Flutter 3.47.7 source:** `gestures/binding.dart:506-546` (the hit path, then the routes,
  then the arena), `gestures/pointer_router.dart:81-91` (`debugGlobalRouteCount`) and `:124-131`
  (the copy of the global routes), `gestures/recognizer.dart:640-652` (the default slop),
  `gestures/events.dart:2552-2562` (`computeHitSlop`), `gestures/constants.dart:29` and `:65`,
  `scheduler/binding.dart:1259-1268`, `rendering/binding.dart:465-474`,
  `rendering/proxy_box.dart:3918-3923`, `widgets/media_query.dart:2115`
  (`maybeGestureSettingsOf`).
- **E2, Node.js probes of upstream** (x64 Node.js v24.12.0, the build at the pin, all
  registerables, the colors plugin disabled):
  - Twelve gesture cases with the Chrome event sequence on a line chart with legend callbacks.
    All 12 pass. A tap leaves the tooltip active with opacity 1 after the lift. A later
    `mouseout` outside makes it inactive with opacity 0. With `touchend` added to `events`, the
    lift does not hide the tooltip, because the NaN position is outside the chart area. With
    `pointerout` added and without the compatibility events, the lift hides it. With the
    compatibility events of the tap, the `mousemove` after the `pointerout` shows it again (the
    reference cases of `chart_host_input_test.dart`). With `events: ['mousemove']`, the
    compatibility `mousemove` shows it. A tap on legend item 1 and then a tap outside log
    `hover:mousemove:one`, `click:click:one`, `leave:mouseout:one`. With `pointerup` added, a
    tap on a legend item calls `onClick` 2 times. A `touchstart` on an empty point hides the
    tooltip. A `click` at (3, 3) outside the chart area keeps it.
  - The throttle order with a FIFO `requestAnimationFrame`: `move(in) out(outside)` gives
    `mousemove@10, mouseout@-1`. `out(outside) move(in)` gives `mouseout@-1, mousemove@10`.
    `move(A) out move(B)` gives `mousemove@20, mouseout@-1`. `out move(A) out` gives
    `mouseout@-2, mousemove@10`. `touchstart move click` in one frame gives
    `touchstart@5, mousemove@5, click@5`.
  - The event path: with `pointHoverRadius` 1, `pointRadius` 6 and `pointHitRadius` 1, a
    `mousemove` makes `[0,1]` active on the chart and none on the tooltip. Thus the two hit tests
    cannot share one result. A `mouseout` inside a legend hit box gives no `onLeave`. A click at
    `(null, null)` and at `(NaN, NaN)` hits no item. A click on the right edge of a hit box hits
    it. A replay after `update()` does not reach the legend.
  - Seven sequences on a bar chart, "browser" (with the compatibility events) against "host" (the
    ADR 0014 host). They differ on the tap outside, on `events: ['mousemove']`, on the legend
    `onHover` and `onLeave` of a tap, on `mode: 'index', intersect: false` with a tap outside, and
    on a tap of a legend item with `mouseup` in `events` (2 toggles against 1).
- **E3, Dart probes of the host** (`flutter test`, the real `ChartHost` with `FakeChart`):
  - A touch tap with all types listened gives `pointerdown`, `touchstart`, `pointerup`,
    `touchend` (NaN), `click`. A tap outside after a tap on the host gives no event.
  - A mouse move and an exit in one frame give `mousemove(100,10)`, `mouseout(100,-20)`. A move,
    an exit and a move back give `mousemove(120,30)`, `mouseout(100,-20)`. A mouse removed inside
    the box gives `mouseout(100,10)`. The same five throttle sequences of E2 give the same order
    through `dispatchCanvasEvent` on a real chart.
  - A down-up distance of 0.5, 3 and 17 px gives `click` for the mouse and for touch. 19 px gives
    no `click` for both. A `GestureDetector.onTap` ancestor of a chart with `events: ['click']`
    gets 0 taps.
  - A prototype subclass of `RenderChartHost` with the compatibility triple gives the Touch
    Events order `pointerdown`, `touchstart`, `pointerup`, `touchend`, `mousemove`, `mousedown`,
    `mouseup`, `click`. The compatibility events come before the `click` of the recognizer,
    because the hit path runs before the arena sweep. A drag of 40 px gives no compatibility
    event. A mouse click gives no extra event.
  - A global route that the host adds in its `handleEvent` of an up: the log is
    `host PointerDown p1 | host PointerUp p1 | route added | route PointerUp p1 | route
    PointerDown p2 | route PointerUp p2`. The route sees the up that added it. After the removal,
    `debugGlobalRouteCount` is 1, not 0: flutter_test has one global route of its own.
- **E4, browser probe** (the VS Code integrated browser, Electron 42 with Chromium
  148.0.7778.280, not Google Chrome, mobile emulation with touch input): a touch down on a canvas
  gives `pointerover`, `pointerenter`, `pointerdown`, `touchstart`. A long press then gives
  `mouseover`, `mouseenter` and `mousemove` with the finger still down, then `contextmenu`, and
  no `click`. A second long press on the same canvas gives `pointerdown`, `touchstart`,
  `mousemove`, `contextmenu`, with no `mouseover` and no `mouseenter`: the compatibility mouse
  stays over the canvas across gestures. The probe reached no lift.
- **E5, benchmarks:**
  - One global route with the check of section 9, `GestureBinding.handlePointerEvent`, 20000
    events, 8 rounds, median, JIT with asserts: a mouse hover 650 ns without and 808 ns with the
    route. A touch move 306 ns without and 468 ns with the route. A second series gave 160 to
    243 ns for one route.
  - The cost of one chart `mousemove` on JIT (the filter and the hover hit test, no render): 3.2
    µs at 100 points, 20.6 µs at 1000 points, 214 µs at 10000 points.
  - The host path of one touch-like move before and after the change of the device check
    (`GestureBinding.handlePointerEvent`, a `ChartHost` with platform listeners of the default
    `events` and no chart work, 20000 events, 8 rounds, median, 2 runs, JIT with asserts): a move
    at the same point 472 and 480 ns before, 298 and 331 ns after; a move of the tap candidate
    inside the slop 554 and 599 ns before, 401 and 419 ns after; a move after the pan begin 474
    and 492 ns before, 453 and 449 ns after ([performance.md](../performance.md) §14.6).
  - The event filter of 2 notifies with 7 plugins: 616 to 637 ns AOT and 1039 to 1146 ns
    dart2wasm. A memo for each native type: 9.7 to 10.2 ns AOT and 16.4 to 19.1 ns dart2wasm.
  - The legend hit test, 3 AOT and 3 dart2wasm processes (`dart compile exe`,
    `dart compile wasm -O2` in the x64 Node.js), the range of the process medians, in ns for each
    event: 2 items, a Map with `jsGet` 43 to 45 AOT and 83 to 90 wasm, a Map with a direct read
    36 to 37 AOT and 75 to 82 wasm, a typed class 5.5 to 5.7 AOT and 9.7 to 10.4 wasm. 50 items:
    1154 to 1165, 1018 to 1030 and 50 to 51 AOT, and 2177 to 2326, 2045 to 2120 and 186 to 187
    wasm. The throttle gives at most one legend hit for each event type in a frame. The worst
    cell is 0.03 % of an 8.3 ms frame.
- **E6, external sources:** W3C Touch Events, section "Interaction with Mouse Events and click".
  W3C Pointer Events Level 3 §4.1.2, §4.2.3, §4.2.6, §11.1 and §11.3. Chart.js issue #7738 and its
  comments (read with `gh issue view 7738`).
- **E8, the device check of Open 1** (2026-10-23). A Pixel 8a (Android 17, build
  `CP3A.260905.009`, density 420, DPR 2.625, `long_press_timeout` 400) with Chrome
  155.0.8059.84, and a profile build of the port at commit `ce340ca` with the host of the first
  text of this ADR. Both sides showed the same chart (a line chart with 2 datasets, legend
  callbacks that log, an inline plugin that logs each chart event) on a 360 x 360 canvas. They
  logged the DOM events of the canvas, the chart events, the legend log and the state after each
  step. `adb shell input` gave the gestures: taps, taps outside, long presses, drags (rows T01 to
  T15), a tap with a move of 4, 7, 10, 14, 20 and 30 px (S04 to S30), holds of 300 to 700 ms
  (LP300 to LP700) and a stylus tap (ST1, `pointerType` `pen` on both sides). Round r1 ran 27
  rows. Round r2 ran each row with a difference again. Round r3 ran LP550 again, because the page
  of the Chrome row of r2 was 21 px lower. The rows T01 to T11 were equal on Chrome, the port and
  the model. The differences, each in two rounds:
  - D1: Chrome sends `pointermove` from the first moved pixel, but the first `touchmove` only 8 to 9
    px from the down (8.13 to 8.73 px in the rows S10 to S30, 9 px in T14). S04 and S07 have no
    `touchmove`. In S07 the chart `mousemove` of the port at the moved position gave no active
    element, and Chrome kept point 1 active.
  - D2: a hold gives moves at the same point. Chrome sends no event for them. The port sent
    `pointermove` and `touchmove` for each one (72 to 192 events in each step). After a long press,
    `_lastEvent` had the native type `touchmove` in the port and `mousemove` in Chrome (T12, LP550,
    LP700). T12 gave 4 chart events in Chrome and 100 in the port.
  - D3: at the slop, Chrome sends `pointermove`, `touchmove`, `pointercancel`,
    `lostpointercapture`, `pointerout` and `pointerleave`, the last three at (-16, -40): the
    client point (0, 0) on a canvas at (16, 40). Then only `touchmove`, and `touchend` at the
    lift, with no `pointerup` and no `touchcancel`. The page could not scroll
    (`overflow: hidden`), and the canvas had the default `touch-action`. In T15 (`pointerout` and
    `pointerleave` in `events`) Chrome gave the chart `mouseout` at the slop, and the port at the
    lift.
  - D4: S04, down at (138, 132) and up at (142, 132): Chrome sent the compatibility events and
    `click` at (138, 132). S07, up at (145, 132): Chrome sent them at (138, 132) and showed the
    tooltip of point 1. The port sent them at the up position and missed the point.
  - D5: ST1: Chrome gave the touch tap sequence and the chart `mousedown` (`touchstart`),
    `mousemove` and `click`. The port gave the mouse rows and the chart `click` only.
  - Equal on both sides: the order `pointerup`, `pointerout`, `pointerleave`, `touchend`; the
    NaN position and the empty `touches` of `touchend`; the `mouseout` of a tap outside; the
    long press at 550 and 700 ms with no `click`; the tap at 300, 400 and 450 ms; no second
    `mouseover` at a second long press. Chrome sent the long press 485 to 492 ms after
    `touchstart`.
- **E9, Chromium source** at the tag `155.0.8059.84` (the GitHub mirror `chromium/chromium`):
  `ui/events/gesture_detection/gesture_detector.cc:202-213`, `:328-347`, `:480-493`, `:531`,
  `:555-559`, `:633-669`; `gesture_provider.cc:168`, `:408-450`, `:714-719`;
  `gesture_configuration_android.cc:53-56`; `gesture_provider_config_helper.cc:33-34`;
  `filtered_gesture_provider.cc:123-124`; `components/input/passthrough_touch_event_queue.cc:33-46`,
  `:361-363`, `:490-506`; `third_party/blink/renderer/core/events/pointer_event_factory.cc:305-350`,
  `:409-427`, `:429-452`; `third_party/blink/renderer/core/input/pointer_event_manager.cc:371-402`,
  `:616`, `:654-655`, `:850-851`;
  `third_party/blink/renderer/core/input/touch_event_manager.cc:372-385`, `:492-497`. Flutter 3.47.7
  `AndroidTouchProcessor.java:404-437` (the pressure and the radii of an Android touch) and
  `:382` (the pointer id 0 of each event), and
  `lib/ui/window/pointer_data_packet_converter.cc:157-179` (a hover keeps that id, section 6).
- **E10, the device re-check of the input fix** (2026-10-23, 22:07 to 22:14 UTC; `result-fix.md`,
  a working file of phase 8, not committed; the independent recompute agrees). The Pixel 8a and the Chrome of E8, and a profile build of
  the port at commit `363f28d` (the host of the input fix, D1 to D5). The rows of E8 ran again,
  and five new rows: LPD (a hold of 600 ms, then a drag of 30 px), SN08 and SN09 (a touch move of
  21 and 24 physical px, 8.000 and 9.14 px), STN10 and STN14 (an `adb shell input stylus swipe`
  of 26 or 27 and 37 physical px, 9.9 to 10.3 and 14.1 px, `pointerType` `pen` on both sides).
  The rows with a difference ran in two rounds (f1, f2). Results:
  - All rows but STN10 gave the Chrome result. T15 differed in the positions of 3 moves only
    (Open 10). SN08 was a tap and SN09 the pan on both sides. STN10 was a tap and STN14 the pan
    on both sides. LPD gave the pan begin after the long press on both sides.
  - STN10, down at (138, 132) and up at (148, 132) in the canvas, in both rounds: Chrome sent
    `pointermove` from 139 to 148, then `pointerup`, `pointerout`, `pointerleave` and `touchend`
    at the up position, then `mouseover`, `mouseenter`, `mousemove`, `mousedown`, `mouseup` and
    `click` at (148, 132), the up position. The chart got `mousemove` and `click` at (148, 132):
    no active element, tooltip opacity 0. The port sent the compatibility events at (138, 132),
    the down position, and showed the tooltip of point 1. The touch rows with a move inside the
    slop (S04, S07 and SN08) gave the down position on both sides. Chrome sent the last
    `pointermove` at the up position, so the data cannot tell the up point from the last move
    point. The Chromium source gives the up event (below).
  - ST1 (a stylus tap with no move): the down and the up are at the same point. It cannot show
    the tap point.
  - Chromium source at the tag `155.0.8059.84`:
    `third_party/blink/renderer/core/input/event_handler.cc:1788-1797`
    (`ShouldApplyTouchAdjustment`: false for a pen and an eraser) and `:2083-2148` (the touch
    adjustment of a gesture); `gesture_manager.cc:219-465` (`HandleGestureTap`: the compatibility
    events at the point of the tap); `ui/events/gesture_detection/gesture_detector.cc:400-417` (the
    single tap at the up event) and `:531` (the long press at the down event);
    `gesture_provider.cc:693-700` (the tap gesture at the point of its event) and `:705-722` (the
    tap area at the down point).
- **E11, the device round g1** (2026-10-29, 00:52 to 00:59 CET; `result-fix.md` and the raw logs of
  round g1, working files of phase 8, not committed). The Pixel 8a of E8 with Chrome
  155.0.8059.84, and build G of the port. Build G contains commit `102634b` (the stylus tap at the
  up position, section 6). The SHA-256 of the installed `base.apk` is
  `4d1cb08fc441f8c61cc80b66b9e2dd28d4388facff8e5bc81ab71c6295a7be1e`. The Chrome side of the 9
  rows is the record of the rounds r1, f1 and f2 on the same phone (Evidence E8 and E10). Chrome
  ran again for the 3 optional rows. Results:
  - The 9 rows STN10, ST1, STN14, S04, S07, SN08, T01, T02 and T05 pass check 1 (Chrome against
    the model) and check 2 (the port against Chrome). In STN10 both sides give the compatibility
    events and `click` at the up position (148, 132), no active element and tooltip opacity 0.
    The other 8 rows stay equal to Chrome.
  - The 3 optional stylus rows pass both checks: STLP (a long press, at the down position, no
    `click`), STO10 (a stylus tap outside gives `mouseout` and `mouseleave`) and STE10 (the stylus
    lifts above the canvas at (180, -6), then `mouseout` and `mouseleave`, no `click`).
    `pointerType` is `pen` on both sides in each stylus row.
  - An independent recompute agrees with all rows.
  - The finger rows H01 to H03 and the mouse rows M01 and M02 did not run: no person was at the
    phone, and no mouse was connected. They stay NOT CHECKED (Open 1). The inverted stylus has no
    device row.
  - Notes of the recompute, with no effect on a rule: Chrome logs the pointer type `mouse` for the
    compatibility events, and no rule reads it. The `long_press_timeout` of the phone is 400 ms,
    and the port uses 500 ms (Open 18). Round g1 cannot show this difference, because STLP holds
    600 ms.
- **E7, the host tests of Chart.js ADR 0014** stay valid for sections 1 to 5, 11 and 12:
  `test/port/platform/chart_host_test.dart` (the groups 'first layout', 'resize', 'display size
  and bitmap stretch', 'unbounded constraints', 'dry layout', 'TickerMode', 'attach and detach',
  'first resize notification at the next layout', 'flushCanvasMutations', 'events' and 'canvas
  event target'), `platform.flutter_test.dart`, `index_test.dart`, `platform.base_test.dart`,
  `platform.basic_test.dart`, `native_event_test.dart` and `helpers.dom_test.dart` 'a fractional
  device width can differ from upstream by 1 px'.
