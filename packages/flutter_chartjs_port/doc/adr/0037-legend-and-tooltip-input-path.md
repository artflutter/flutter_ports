# Chart.js ADR 0037: Legend and tooltip input path

- Status: proposed
- Date: 2026-10-22
- Supersedes: [Chart.js ADR 0014](0014-input-events-and-chart-host.md) on acceptance
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
| S6 | `events` with `pointerout` or `pointerleave`, touch lift | The tooltip hides | Nothing |
| S7 | `events` with `pointerup`, tap on a legend item | `onClick` 2 times | Same |
| S8 | Mouse move and exit in one frame | `mousemove`, then `mouseout` | Same |
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
  changes. The gesture settings give the touch slop of section 8.
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
| `PointerDownEvent`, touch | `pointerover`, `pointerenter`, `pointerdown`, `touchstart` |
| `PointerMoveEvent`, touch | `pointermove`, `touchmove` |
| `PointerUpEvent`, touch | `pointerup`, `pointerout`, `pointerleave`, `touchend`, then for a tap (section 8): `mouseover` and `mouseenter` (only when the compatibility mouse is not over the host), `mousemove`, `mousedown`, `mouseup`, `click` |
| `PointerCancelEvent`, touch | `pointercancel`, `pointerout`, `pointerleave`, `touchcancel` |
| a touch held past the long-press time within the slop (section 8) | `mouseover` and `mouseenter` (only when the compatibility mouse is not over the host), `mousemove`, while the finger is down |
| `PointerScrollEvent` | `wheel` |
| pointer enter (`MouseTrackerAnnotation`, or the host for an inverted stylus) | `pointerover`, `pointerenter`, `mouseover`, `mouseenter` |
| pointer exit (`MouseTrackerAnnotation`, or the host for an inverted stylus) | `pointerout`, `pointerleave`, `mouseout`, `mouseleave` |
| a touch tap or long press that does not hit the host of the compatibility mouse (section 9) | to that host: `mouseout`, `mouseleave` |

The mouse-like kinds are mouse, trackpad, stylus and inverted stylus.
- The host makes a `NativeEvent` only for a type that has a listener.
- A mouse move outside the box gives no event, because a mouse has no implicit capture. A mouse
  has no implicit capture for up and cancel either: a mouse `pointerup`, `mouseup` or
  `pointercancel` outside the host box gives no event.
- `MouseTracker` gives enter and exit only for the mouse and the stylus. Thus the host tracks the
  hovering pointers of the other kinds (the inverted stylus) itself. On the first hover that hits
  the host, it sends `pointerover`, `pointerenter`, `mouseover` and `mouseenter`. On a hover that
  does not hit the host, or on the removal of the pointer, it sends `pointerout`, `pointerleave`,
  `mouseout` and `mouseleave`.
- A `touch*` event has NaN `offsetX` and `offsetY`, because the DOM `TouchEvent` has no offset.
  The position comes from `touches`. A `touchend` after the last finger lifts has an empty
  `touches` list. Thus it gives NaN coordinates, as upstream does (`helpers.dom.ts:81-93`).
- A `pointer*` event of a touch has the offsets of the touch. A compatibility `mouse*` event and
  the `click` of a tap have the offsets of the up position. A `mouseout` or `mouseleave` of a tap
  outside has the position of that tap in the coordinates of the host that gets it.

### 7. The click rule

The host gives `click` by the DOM rule. It adds no recognizer to the gesture arena.
- A mouse-like pointer: a down with the primary button (`buttons == kPrimaryButton`) on the host,
  then the up of the same pointer inside the box, gives `click` at the up position, after
  `mouseup`. The distance between the down and the up has no limit. An up outside the box gives
  no `click`, because the DOM sends the click to the common ancestor. A down with another button
  gives no `click`. `contextmenu` and `auxclick` have no mapping (section 16).
- A touch: a tap (section 8) gives `click` after its compatibility mouse events. A long press
  gives no `click`.
- The host emits `click` in `handleEvent`, synchronously. Thus the compatibility events and
  `click` of one tap come in the DOM order.

### 8. The tap rule and the long press

One rule decides the compatibility events and `click` of a touch. The host and the route of
section 9 use the same rule.
- A tap candidate starts at a touch down when no other touch pointer of the host is down. A
  second touch pointer on the host ends the candidate. This stands for the primary pointer of
  Pointer Events 3 §4.1.2.
- A move of the candidate pointer farther than the touch slop from its down ends the candidate.
  The slop is `computeHitSlop(PointerDeviceKind.touch, gestureSettings)`
  (`gestures/events.dart:2552-2562`): the platform touch slop of `MediaQuery`, else
  `kTouchSlop` (18 logical pixels).
- A cancel ends the candidate.
- An up of the candidate pointer before the long-press time is a tap.
- The long-press time is `kLongPressTimeout` (500 ms, `gestures/constants.dart:29`). A timer
  starts at the down of a candidate. When it fires and the candidate still exists, the candidate
  is a long press. The host sends `mouseover` and `mouseenter` (only when the compatibility mouse
  is not over the host) and `mousemove` at the current position of the pointer. The host becomes
  the host of the compatibility mouse (section 9). The lift of a long press gives no
  compatibility event and no `click`. A browser sends `contextmenu` there. It has no mapping
  (section 16).
- The host cancels the timer at the end of the candidate, at `detach` and at `dispose`.

### 9. The compatibility mouse

A browser has one compatibility mouse. The port has one for each isolate: a static owner of
`RenderChartHost`.
- A tap or a long press on a host makes that host the owner. When another host was the owner, that
  host first gets `mouseout` and `mouseleave` at the position of the tap, in its own coordinates.
  Then the new owner gets `mouseover` and `mouseenter`. A tap on the owner gives no `mouseover`
  and no `mouseenter`.
- While an owner exists, one static global pointer route
  (`GestureBinding.instance.pointerRouter.addGlobalRoute`) watches the touch pointers of the app.
  The host adds it when an owner starts and removes it when the owner ends.
- The route ignores each pointer that went down on a host. `GestureBinding.dispatchEvent` calls
  the hit path before `GestureBinding.handleEvent`, which routes the event
  (`gestures/binding.dart:506-546`). Thus the host records its pointer at the down before the
  route sees it.
- The route also ignores the pointer of the tap that made the owner. A global route that the host
  adds in its `handleEvent` of an up sees that same up, because `PointerRouter.route` copies the
  global routes after the hit path ran (`gestures/pointer_router.dart:124-131`).
- The route applies the tap rule of section 8 to the other touch pointers. A tap or a long press
  that does not hit a host gives the owner `mouseout` and `mouseleave` at the position of that
  pointer, in the coordinates of the owner. Then the owner ends, and the route goes. A drag or a
  scroll outside is not a tap and gives nothing, as in Chrome.
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
  last pointer position is inside the chart. The port keeps this order. It does not sort the
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
   `pointerout` or `pointerleave` to `events`, as in Chrome. The port adds no port-only hide, no
   fade and no `touchend` in the default `events`. The ledger Signal #7738 stays open: the port
   follows upstream when a release changes it.
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
  press), `auxclick` and trackpad `PointerPanZoom` gestures as `wheel`.
- Touch sizes (hit radius, hover radius, font size) stay with phase 9
  ([theming.md](../theming.md) §11).

### 17. Tests, rows and records

- No `differences.md` row is new. All changes are in the port-only host. "A port-only file is not
  a row" (`differences.md`, introduction). This ADR records the reference browser and the iOS
  result.
- The rows `platform-detect-host` and `platform-relative-position` cite this ADR in place of
  Chart.js ADR 0014. The row `harness-trigger-mouse-event` keeps its text.
- `test/port/platform/chart_host_test.dart` pins sections 6 to 10 with real Flutter gestures.
- A port-only reference test pins the whole path (host, throttle, `_eventHandler`, legend and
  tooltip) against the pinned build in the x64 Node.js. Its generator feeds the chart events of
  the Chrome event sequence of each gesture to `chart._eventHandler`, one call for each type in a
  frame, in the order of section 11. The Dart test drives the same gestures as Flutter pointer
  events through `ChartHost` on charts of `acquireChart`.
- The gate of this ADR: the decision is implemented, the gates are green, and the device check
  of Open 1 confirms the table of section 6. A different device result changes the table before
  the ADR goes to accepted.

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
- While the compatibility mouse is over a chart, each touch pointer event of the app goes through
  one more global route: about 160 ns for each event on JIT (E5).
- A touch held for 500 ms on a chart gives the compatibility `mousemove`. The tooltip then shows
  before the lift, as in Chrome.
- The legend and the tooltip need no input code of their own. Their spec cases run through the
  harness with no change.
- The live citations of Chart.js ADR 0014 move to this ADR: `AGENTS.md`, `doc/README.md`,
  `porting-flow.md` §2.7 and §7, `status.yaml` (then `parity.md` through tool 6),
  `canvas-cuts-plan.md`, `upstream-ledger.md` (Signal #7738), `differences.md` rows
  `platform-detect-host` and `platform-relative-position`, and the `///` and `//` lines of
  `lib/` and `test/`.

## Open

1. **Device check (the gate of this ADR).** A page with the pinned build logs the DOM events of a
   canvas in Chrome on the Pixel 8a (through `adb reverse`, phase 8 step 8). It records a tap, a
   tap outside, a drag, a long press, a two-finger tap and a stylus tap. It confirms the order of
   `pointerup`, `pointerout`, `pointerleave` and `touchend`, the `mouseout` of a tap outside, the
   position of the compatibility events and of `click` (this ADR uses the up position), the touch
   slop and the long-press time on Android. A different result changes section 6 or 8 before the
   ADR goes to accepted.
2. **iOS.** Safari keeps the tooltip at a tap outside. The port gives the Chrome result on iOS
   too. A later ADR can change this for each platform if a user asks for it.
3. **`pointercancel` at a pan.** A browser sends `pointercancel` when a parent scrollable takes the
   pan, and then no more `pointermove`. The host sends `pointermove` and `touchmove` to the end.
   The default `events` list no `pointer*` type. Phase 9 decides it with the public widget.
4. **A mouse and a touch screen on one device.** A browser shares one compatibility mouse between
   them. The port keeps the `MouseTracker` path for the mouse, and the route ignores it. Phase 9.
5. **Several views.** The compatibility mouse is one for each isolate. A multi-view app can need
   one for each view (`PointerEvent.viewId`).
6. **The primary pointer.** The tap rule sees only the touch pointers of the host. A finger that is
   down on another widget does not stop a tap on the chart. Chrome then has no primary pointer
   on the canvas and sends no compatibility events. The device check records the two-finger
   case.
7. **A mouse drag from outside.** A mouse drag that starts outside the chart gives no `mousemove`
   over it, because the host is not in the hit path of that pointer. A fix needs a global route
   for the mouse pointers that are down.
8. **A DPR change on a real device** is not verified.
9. **The hit box form of the legend.** A typed hit box class is 7 to 31 times faster than a Map in
   a microbenchmark (E5). The legend port decides the form by the performance rule. It needs an
   `adapt` row if it is a class.

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
    `pointerout` added, the lift hides it. With `events: ['mousemove']`, the compatibility
    `mousemove` shows it. A tap on legend item 1 and then a tap outside log
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
- **E7, the host tests of Chart.js ADR 0014** stay valid for sections 1 to 5, 11 and 12:
  `test/port/platform/chart_host_test.dart` (the groups 'first layout', 'resize', 'display size
  and bitmap stretch', 'unbounded constraints', 'dry layout', 'TickerMode', 'attach and detach',
  'first resize notification at the next layout', 'flushCanvasMutations', 'events' and 'canvas
  event target'), `platform.flutter_test.dart`, `index_test.dart`, `platform.base_test.dart`,
  `platform.basic_test.dart`, `native_event_test.dart` and `helpers.dom_test.dart` 'a fractional
  device width can differ from upstream by 1 px'.
