# Chart.js ADR 0014: Input events and the chart host

- Status: proposed
- Date: 2026-10-19
- Related: [Chart.js ADR 0007](0007-frame-scheduling.md) (the scheduling of the host),
  [Chart.js ADR 0016](0016-frame-scheduling.md) (the scheduling of the host, with the first
  attach inside layout; it supersedes Chart.js ADR 0007 on acceptance),
  [Chart.js ADR 0013](0013-canvas-model.md) (the canvas layer),
  [Chart.js ADR 0012](0012-dart-file-naming.md) (the names), [porting-flow.md](../porting-flow.md)
  §2.7

## Context

`src/platform/` has four files. `index.js` selects the platform class. `platform.base.js` is the
base class. `platform.basic.js` is the platform of a canvas without a DOM, for example an
`OffscreenCanvas`. `platform.dom.js` (389 lines) connects a chart to the browser:
- `EVENT_TYPES` (`:21-31`) maps the touch and pointer event names to mouse names. `fromNativeEvent`
  (`:109-119`) makes a `ChartEvent` from a DOM event.
- `addListener` (`:97-101`) registers passive listeners on the canvas. `createProxyAndListen`
  (`:240-254`) gives each event type one throttled proxy, with a guard for a destroyed chart
  (`:246`).
- `createAttachObserver` and `createDetachObserver` (`:129-159`) watch the document with a
  `MutationObserver`. `createResizeObserver` (`:191-229`) watches the container with a
  `ResizeObserver`. A window `resize` listener and a global map (`:161-189`) watch the device
  pixel ratio (DPR).
- `initCanvas` (`:41-91`) reads the `width` and `height` attributes and the CSS display size of
  the canvas. `releaseContext` (`:293-323`) restores them.

`helpers.dom.ts` measures the container with CSS (`getMaximumSize`, `:163-200`) and computes the
event position with the CSS padding, border and box sizing (`getRelativePosition`, `:73-131`).

Flutter has no DOM and no CSS. These Flutter facts apply:
- `GestureBinding` sends each pointer event at once (`gestures/binding.dart:300-343`). Flutter
  sends one event for each pointer. It has no `TouchEvent.touches` list.
- `PointerDeviceKind` tells mouse, trackpad, stylus, inverted stylus and touch apart. A browser
  sends pointer events and mouse or touch events for each of them.
- A widget that claims a drag in the gesture arena takes the drag from its parent scrollables.
  The pan recognizer of fl_chart breaks `PageView` (fl_chart #202).
- A render object can read the DPR and the ticker state in `createRenderObject` and
  `updateRenderObject` (`MediaQuery.devicePixelRatioOf`, `TickerMode.valuesOf`). `View.of` does not
  rebuild on a DPR change.
- `Offstage` calls `layout` on its child with its own constraints
  (`rendering/proxy_box.dart:3918-3923`). Thus the child does not get the zero size of
  `display: none`.
- A Flutter `Scrollbar` paints over its child and takes no layout width.

Upstream sizes a chart at construction (spec `core.controller.tests.js:651`). The first resize
observer notification goes through `throttled` (spec `:712`). porting-flow.md §2.7 left these
items open: the first size, unbounded constraints, a chart larger than its box, the factor of
`getRelativePosition`, the touch scope and a harness detach without an unmount.

## Decision

### 1. Platform files

- `lib/src/platform/index.dart` ports `index.js`. `detectPlatform` returns the constructor
  tear-off of the class, because `core.controller.js:135` calls the result with `new`. It gives
  `FlutterPlatform` for a canvas whose parent node is a chart host. It gives `BasicPlatform` for a
  canvas that no host shows, the counterpart of an `OffscreenCanvas`, and for an item that is not
  a canvas. The upstream test `_isDomSupported()` is always false in the port. Thus one
  `DIVERGES` hunk tests for a host instead (`differences.md` row `platform-detect-host`).
- `platform.base.dart` and `platform.basic.dart` are line-by-line ports.
- `platform.flutter.dart` replaces `platform.dom.js`. Its `parity.md` status is `replaced`. It keeps
  the upstream structure and names: `eventTypes` (`EVENT_TYPES`), `fromNativeEvent`, `initCanvas`,
  `createAttachObserver`, `createDetachObserver`, `createResizeObserver`, `createProxyAndListen`,
  `releaseObserver`, and `FlutterPlatform` with `acquireContext`, `releaseContext`,
  `addEventListener`, `removeEventListener`, `getDevicePixelRatio`, `getMaximumSize` and
  `isAttached`. Each declaration has a `///` line with the `platform.dom.js` lines that it
  replaces. A port-only file has no `DIVERGES` markers.
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
- The host reads the DPR with `MediaQuery.maybeDevicePixelRatioOf` and the ticker state with
  `TickerMode.valuesOf` in `createRenderObject` and `updateRenderObject`. A DPR change paints the
  host again, because the paint scale reads the DPR (section 5). It calls `onTickerModeChanged`
  when the ticker state changes.
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
- The resize observer reports the current container size when `observe()` starts on a laid-out
  host, as the DOM `ResizeObserver` does. Thus a responsive chart gets a second resize one frame
  after the attach, as upstream does.

### 4. Later size, DPR and attach changes

- A later change of the constraints or of the DPR reaches the `ContainerResizeObserver`s.
  `createResizeObserver` gives each chart one `throttled<Size?>` function
  ([Chart.js ADR 0016](0016-frame-scheduling.md), decision 9). A `null` size is a DPR change. It
  calls the listener only when `chart.currentDevicePixelRatio` differs (`platform.dom.js:171`).
- The zero-size skip of `platform.dom.js:217-222` stays. The harness of phase 5 emulates
  `display: none` with `SizedBox.shrink`, because `Offstage` gives its child its own constraints.
- After the first layout, one post-frame callback of each host reports a net change of the
  attached state. A `GlobalKey` move gives no change. An unmount gives a detach after the frame.
- A canvas swap on an existing host (`updateRenderObject` with a new `UiCanvasElement`) reports
  the detach of the old canvas at once, during the build, not after the frame. The new canvas
  attaches in the next layout, as a first attach
  ([Chart.js ADR 0016](0016-frame-scheduling.md), decision 9).
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
  size. The host does not apply this rule. The harness matcher `toBeChartOfSize` of phase 5
  applies it.
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

Flutter input gives the DOM event names that a browser fires. `PointerDeviceKind` selects them,
not the platform. `eventTypes` and the `options.events` filter stay as upstream.

| Flutter input | DOM names, in DOM order |
|---|---|
| `PointerDownEvent`, mouse-like kind | `pointerdown`, `mousedown` |
| `PointerMoveEvent` or `PointerHoverEvent`, mouse-like kind | `pointermove`, `mousemove` |
| `PointerUpEvent`, mouse-like kind | `pointerup`, `mouseup` |
| `PointerDownEvent`, touch | `pointerdown`, `touchstart` |
| `PointerMoveEvent`, touch | `pointermove`, `touchmove` |
| `PointerUpEvent`, touch | `pointerup`, `touchend` |
| `PointerCancelEvent` | `pointercancel`, and `touchcancel` for touch |
| `PointerScrollEvent` | `wheel` |
| pointer enter (`MouseTrackerAnnotation`, or the host for an inverted stylus) | `pointerover`, `pointerenter`, `mouseover`, `mouseenter` |
| pointer exit (`MouseTrackerAnnotation`, or the host for an inverted stylus) | `pointerout`, `pointerleave`, `mouseout`, `mouseleave` |
| tap (`TapGestureRecognizer`) | `click` |

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
- A touch event has NaN `offsetX` and `offsetY`, because the DOM `TouchEvent` has no offset. The
  position comes from `touches`. A `touchend` after the last finger lifts has an empty `touches`
  list. Thus it gives NaN coordinates, as upstream does (`helpers.dom.ts:81-93`).

### 7. Gesture arena and touch scope

- `hitTestSelf` returns true. The host reads the raw `PointerEvent`s in `handleEvent`, with no
  claim in the gesture arena, for move, down, up, cancel, hover and scroll.
- Only a `click` listener adds the one `TapGestureRecognizer` of the host to the arena. Thus parent
  scrollables keep their drags. But a chart with a `click` listener wins the tap against tappable
  ancestors (`GestureDetector.onTap`, `InkWell`, `ListTile.onTap`). A DOM click would also reach
  them, by bubbling.
- `wheel` does not claim the pointer signal, because upstream registers passive listeners and the
  page still scrolls.
- Touch scope: only the pointers that hit the chart, through normal hit testing. The host does
  not use `GestureBinding.instance.pointerRouter.addGlobalRoute`.

### 8. Listeners and the throttle

- The listeners live on the canvas element, as DOM listeners do. A registry in an `Expando`
  (`addCanvasEventListener`, `dispatchCanvasEvent`) stands in for the `EventTarget` of the canvas.
  The listeners stay when the canvas moves to another host.
- Each event type gets its own throttled proxy ([Chart.js ADR 0007](0007-frame-scheduling.md)).
  Thus a click and a mouse move in one frame both reach the chart.
- The proxy keeps the guard of `platform.dom.js:246`: it calls the listener only while
  `chart.ctx != null`.
- The listener options `{passive: true}` have no port. The host never claims a pointer for an event
  listener.
- `BasePlatform.addEventListener` and `createResizeObserver` take a `Function` and cast it. Thus
  `core.controller` (phase 5) declares its listeners with these shapes:
  - `void Function(ChartEvent)` for the event types
  - `void Function([double? width, double? height])` for `'resize'`
  - `void Function()` for `'attach'` and `'detach'`

### 9. Event position

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

### 10. Type members

`lib/src/types/index.dart` gets the members that the ported platform code reads:
- `Chart`: `canvas`, `ctx`, `width`, `height`, `currentDevicePixelRatio` and `platformProxies`
  (the `$proxies` of `core.controller.js:168`).
- `ChartEvent`: `native`, `x`, `y` and `chart` (`platform.dom.js:114`).
- `BasePlatform`: the full method set of `platform.base.js`.
- `ChartConfiguration` with `options` (`index.d.ts:3865`). The `Config` of `core.config` implements
  it in phase 5.

The types library imports `canvas.dart` and `native_event.dart`. Both are pure, port-only
stand-ins for `lib.dom.d.ts`. This departs from the letter of
[Chart.js ADR 0003](0003-type-only-dependencies.md) but keeps its intent, purity.

### 11. Scope of later phases

- The harness detach without an unmount, for the specs that keep a detached chart across a task
  (`core.controller.tests.js:1065`, `:1147`, `:1179`), is phase 5 harness work.
- Keyboard events and semantics are port-only and come in phase 9.
- The public widget of phase 9 builds on the host. It creates the chart after the `ChartHost`
  render object exists, else `detectPlatform` gives `BasicPlatform`. It disposes the
  `UiCanvasContext` with `Chart.destroy`.
- Phase 5 connects `onTickerModeChanged` to `animator.mute` and `animator.unmute`
  ([Chart.js ADR 0007](0007-frame-scheduling.md), decision 7).

## Alternatives considered

- **Size the chart in a post-frame callback after the first layout.** Rejected. The port then
  paints one blank first frame. Upstream sizes a chart at construction.
- **Infinity to 0 for unbounded constraints.** Rejected. A chart in a `Column` or a `ListView`
  then has no size. The canvas default of 300 x 150 is what a DOM canvas without a size has.
- **Paint a larger chart outside the box.** Rejected. It paints over the siblings. A DOM canvas
  inside a container with `overflow: hidden` is clipped too.
- **Keep the factor `/ chart.width * canvas.width / currentDevicePixelRatio`.** Rejected. Flutter
  already gives the position in the logical pixels of the chart. The factor only changes the
  digits at fractional sizes.
- **All pointers through `pointerRouter.addGlobalRoute`.** Rejected. The chart then sees pointers
  of other widgets. Normal hit testing gives the pointers that the DOM gives to the canvas.
- **A pan or drag recognizer for move events.** Rejected. It takes drags from parent
  scrollables, as fl_chart #202 shows.
- **A `DoubleTapGestureRecognizer` for `dblclick`.** Rejected for now. It delays each single tap.
- **No attributes, no style reads in `initCanvas` and no style restore** (option B of
  [canvas-cuts-plan.md](../canvas-cuts-plan.md) §3.3). Rejected. Upstream gives 300 x 300 for a
  doughnut, pie, polar area or radar chart that is not responsive, on a canvas without a height.
  The port then gives 300 x 150. This needs a `DIVERGES` row. About 11 phase 5 spec cases then
  skip as `diverges:`. `options.devicePixelRatio` also needs a new mechanism.
- **Paint at `1 / DPR` only, with no stretch.** Rejected. A chart with an
  `options.devicePixelRatio` that differs from the view DPR then paints at the wrong size. The hit
  element then changes (section 5).
- **The host size from `AspectRatio` or `SizedBox` in place of `getMaximumSize`.** Rejected. It is
  a second source of the size. It caps the attach resize by the container height. It has no
  `round1`. `onResize` and the `resize` plugin hook need `_resize` of `core.controller`.

## Consequences

- Parent scrollables, `PageView` and `ListView` keep their gestures. A chart with a `click`
  listener takes the tap only. That chart wins the tap against tappable ancestors
  (`GestureDetector.onTap`, `InkWell`, `ListTile.onTap`), which a DOM click would also reach by
  bubbling.
- The chart has its size before the first paint. Specs that check the size after construction can
  pass in phase 5.
- A canvas that a host shows gets `FlutterPlatform`. A canvas without a host gets
  `BasicPlatform`. The `useOffscreenCanvas` spec cases skip as `blocked: core.controller`, not
  `n/a`, because phase 5 can run them with a canvas that no host shows.
- `getRelativePosition` gives the upstream values for a chart whose canvas has the device size of
  `retinaScale`. Two `helpers.dom` spec cases skip as `diverges: platform-relative-position`.
- The DOM-only spec cases (element ids, iframes, the DOM-tree `isAttached` case, the web worker
  case) skip as `n/a`.
- `differences.md` has the rows `platform-detect-host` and `platform-relative-position` for this
  ADR. The rows `platform-dom-container`, `platform-dom-no-css`, `platform-dom-computed-style` and
  `platform-dom-supported` record the other `helpers.dom` hunks.

## Evidence

- `test/port/platform/chart_host_test.dart` (41 tests, 40 of them `testWidgets`) covers the first
  size with a chart started before and after the first layout, the throttled resize (one in each frame), a DPR
  change (`tester.view.devicePixelRatio = 2`), content drawn before the host at the display size,
  the clip, the first `ResizeObserver` notification, the display size and the paint scale of
  section 5, the unbounded-constraints rule, the dry
  layout and intrinsic sizes, `TickerMode`, attach and detach (a `GlobalKey` move gives no
  change, an unmount gives a detach after the frame, a re-attach), mouse hover, enter, exit and
  click, two-finger touches with the sorted `touches` list and the NaN `touchend`, wheel, the click
  arena with a parent `ListView`, the destroyed-chart guard and dispose.
- A new host that takes over the canvas in the same frame (a wrapper toggle, a move to a sibling
  slot without a `GlobalKey`, an `AnimatedSwitcher` cross-fade) takes over the reported attached
  state and the `ContainerResizeObserver`s of the old host. The chart stays attached
  (`attachCalls == ['attached']`) and follows the new container. The old host reports nothing.
  Tests: `chart_host_test.dart` 'a wrapper toggle keeps the chart attached', 'a move to a sibling
  slot without a GlobalKey keeps the chart attached' and 'an AnimatedSwitcher cross-fade keeps the
  chart attached'.
- The tap against tappable ancestors: `chart_host_test.dart` 'a tappable ancestor gets 0 tap with
  the chart events [click]' and 'a tappable ancestor gets 1 tap with the chart events
  [mousemove]'.
- The mouse capture and the inverted stylus: `chart_host_test.dart` 'a mouse up outside the box
  gives no mouseup' and 'an inverted stylus hover gives mouseover and mouseout'.
- The event position at a fractional width: `helpers.dom_test.dart` 'a fractional device width
  can differ from upstream by 1 px'.
- The display size and the paint scale of section 5: the group 'display size and bitmap stretch'
  of `chart_host_test.dart` (8 tests). 'a chart at devicePixelRatio 1 on a view at 2 fills its
  display size' and 'a chart at devicePixelRatio 3 on a view at 1 fills its display size' probe
  the pixels. 'a pointer at the center of a stretched chart gives the center of the chart' pins
  the event position. 'a factor within 1e-3 paints at exactly 1 / devicePixelRatio' reads the
  `Canvas.scale` calls of the paint. 'a non-responsive chart shows its bitmap at the size of its
  styles' uses the attributes 165 x 85 and the styles 345 x 125. 'one style alone shows the render
  size' pins the host rule for one style. 'a non-responsive chart on canvas attributes at
  devicePixelRatio 3 keeps its display size' is the case of `core.controller.tests.js:1397`.
  'releaseContext gives the host the default 300 x 150' pins the size after the release.
- The attributes: `platform.flutter_test.dart` 'keeps the render size of the attributes' (512 x
  512, and the attributes 165 x 85 with the styles 345 x 125), 'applies the aspect ratio to a
  width attribute alone' and 'releaseContext restores the initial attributes' (the case of
  `platform.dom.tests.js:331`). The group 'attributes' of `canvas_ui_test.dart` pins the element
  ([Chart.js ADR 0013](0013-canvas-model.md), section 2).
- `test/port/platform/platform.flutter_test.dart` (21 tests), `index_test.dart` (3),
  `platform.base_test.dart` (11), `platform.basic_test.dart` (5) and `native_event_test.dart` (2)
  cover the rest of the platform. `FakeChart` (`test/port/platform/fake_chart.dart`) makes the
  platform calls of `core.controller.js` until phase 5 ports it.
- `platform.base_test.dart`, `platform.basic_test.dart` and `native_event_test.dart` also run on
  dart2js and dart2wasm.
- The specs: `platform.basic.tests.js` (5 cases) and `platform.dom.tests.js` (21 cases) have all
  their cases. 22 of them skip as `blocked: core.controller` and 4 skip as `n/a`.
  `helpers.dom.tests.js` passes 5 of 22 cases. The others skip: 11 as `n/a`, 2 as
  `diverges: platform-relative-position` and 4 as `blocked: core.controller`.
- A wasm build in a browser gave `BasicPlatform` before the attach and `FlutterPlatform` after it.

## Open

- Touch sizes (hit radius, hover radius, font size) and the tooltip after a touch lift (#7738). A
  new ADR decides the touch sizes in phase 9 ([theming.md](../theming.md) §11).
- These inputs have no mapping yet: `dblclick`, `contextmenu` (a secondary click), the mouse
  events that browsers send after a touch tap, and trackpad `PointerPanZoom` gestures as `wheel`.
- A DPR change on a real device is not verified.
- An alternative to the tap recognizer for the maintainer: an arena-free click, that is, a
  `PointerUp` within the touch slop of its `PointerDown`. It leaves the arena to the tappable
  ancestors, as DOM bubbling does.
- A mouse drag that starts outside the chart gives no `mousemove` over it, because the host is not
  in the hit path of that pointer. A fix needs a global route for the mouse pointers that are down.
