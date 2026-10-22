# ECharts ADR 0007: Runtime environment, chart host and input events

- Status: proposed
- Date: 2026-10-21
- Gate: split gates. ECharts phase 1 for the platform API defaults, because the pilot ports
  `zrender src/core/platform.ts`. ECharts phase 1 also fixes the `env` values. Phase 2 ports
  `core/env.ts`, `config.ts`, `core/event.ts` and the timers. ECharts phase 3 for the handler proxy
  and the input events, because phase 3 ports `Handler.ts` and `zrender.ts`. ECharts phase 5 for
  `EChartsContainer`, `EChartsHost` and `init(dom)`, because phase 5 ports `core/echarts.ts`.
- Related: [ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) (new generic
  runtime goes into `js_semantics`, no dependency on another port),
  [Chart.js ADR 0014](../../../flutter_chartjs_port/doc/adr/0014-input-events-and-chart-host.md) (the
  chart host, the event table and the arena rule of the Chart.js port),
  [Chart.js ADR 0016](../../../flutter_chartjs_port/doc/adr/0016-frame-scheduling.md) (the `Timer`
  rule and the `TickerMode` mute),
  [Chart.js ADR 0032](../../../flutter_chartjs_port/doc/adr/0032-js-numeric-semantics.md) (accepted
  2026-10-21: §6, `jsDateNow`),
  [Chart.js ADR 0034](../../../flutter_chartjs_port/doc/adr/0034-no-display-only-js-exactness.md)
  (accepted 2026-10-21: behavior that a port must keep),
  [ECharts ADR 0002](0002-file-naming-and-layout.md) (port-only folders, the pure layers),
  [ECharts ADR 0003](0003-numbers-and-js-semantics.md) (`jsRound`, `jsToInt32`, the runtime
  placement), [ECharts ADR 0004](0004-js-values-classes-and-options.md) (reads by name, user
  callbacks, `echartsDev`),
  [ECharts ADR 0005](0005-spec-harness-and-reference-tests.md) (the pure chart specs, the rows
  `harness-dom-supported` and `harness-canvas-mock-text`),
  [ECharts ADR 0006](0006-renderer-and-canvas-layer.md) (the Canvas 2D layer, `ZrViewport`, the
  frame hook and the mute),
  [ECharts ADR 0008](0008-dates-locales-and-formatting.md) (`SYSTEM_LANG`, the platform string),
  [ECharts ADR 0009](0009-dom-features-app-hooks-and-theming.md) (tooltip modes, aria, export,
  the image resolver), [differences.md](../differences.md) (the rows of this ADR)

## Context

All line numbers are at the pins: `third_party/echarts` at `6.1.0` (`c5a48f5f`) and
`third_party/zrender` at `6.1.0` (`32b66867`). The Flutter lines are at Flutter 3.44.9,
the `.fvmrc` pin on the date of this ADR. The pin moved to 3.47.7 on 2026-10-21.

**The DOM in the two repositories.** ECharts `src/` reads the DOM in few files:
- `core/echarts.ts`: `init`, `getDom`, `dispose`, the instance attribute, the DPR fallback, the
  rects of `getConnectedDataURL`, the dev globals and the WeChat flush.
- `component/tooltip/TooltipHTMLContent.ts` and `component/tooltip/helper.ts`: the HTML tooltip.
- `component/toolbox/feature/SaveAsImage.ts` and `DataView.ts`.
- `visual/aria.ts:153`, `:156` and `:246`: `role` and `aria-label` on the container.
- `core/locale.ts:39-44` (`SYSTEM_LANG`) and `model/globalDefault.ts:26` (`navigator.platform`).
- `util/format.ts:322-332` (`windowOpen`) and `util/model.ts:1032-1052` (attributes, tooltip
  mode).
- `util/decal.ts` and `chart/heatmap/HeatmapLayer.ts` through `platformApi.createCanvas()`, and
  `coord/geo/GeoSVGResource.ts` through the zrender `parseXML`.

zrender holds the rest of the DOM layer: `core/env.ts`, `core/platform.ts`, `config.ts`,
`core/event.ts`, `core/dom.ts`, `dom/HandlerProxy.ts`, `animation/requestAnimationFrame.ts`,
`canvas/Painter.ts`, `canvas/Layer.ts`, `canvas/helper.ts` and the SVG painters. A grep for
`document.`, `window.`, `navigator.`, `getComputedStyle`, `addEventListener`, `innerHTML`,
`getBoundingClientRect` and `createElement(` found 15 ECharts files and 23 zrender files. 7 of
the 15 ECharts files have only comments or local names. 7 of the zrender files are in
`svg-legacy/`.

**`env`.** `zrender src/core/env.ts` (122 lines) declares `Browser` and `Env` with `false`
defaults (`:5-28`). `hasGlobalWindow` is `typeof window !== 'undefined'` (`:27`). The detection
runs at module load (`:32-52`). The first branch detects WeChat (`:32-35`). The second branch
detects a worker (`:36-39`). With no `window`, the third branch sets `node` and `svgSupported`
(`:40-49`). Only a browser reaches `detect` (`:50-52`). `detect` (`:58-119`) reads the user agent,
`window`, `document` and CSS. The Zepto credit is `:54-56`. These sites read the flags:

| Flag | Readers | Effect of `true` |
|---|---|---|
| `node` | `echarts src/model/Series.ts:552`, `model/Model.ts:206`, `component/marker/MarkerModel.ts:134` | No animation |
| `node` | `component/tooltip/TooltipView.ts:165`, `:184`, `:298`, `:1049` | No tooltip |
| `node` | `component/axisPointer/globalListener.ts:63`, `:170` | No axis pointer listeners |
| `node`, `worker` | `core/echarts.ts:2607-2609` | No hover layer |
| `node`, `worker` | `zrender src/zrender.ts:128-130` | No handler proxy, thus no input |
| `domSupported` | `echarts src/core/locale.ts:39` | `SYSTEM_LANG` from `document` and `navigator` |
| `domSupported` | `util/model.ts:1047` | `renderMode: 'auto'` gives `'html'` |
| `domSupported` | `component/tooltip/helper.ts:36`, `zrender src/core/dom.ts:107`, `core/event.ts:96`, `dom/HandlerProxy.ts:25` | CSS probe, CSS transform coordinates, `getBoundingClientRect` coordinates, `document` listeners |
| `hasGlobalWindow` | `zrender src/config.ts:6`, `animation/requestAnimationFrame.ts:8`, `echarts src/core/echarts.ts:543`, `:908` | DPR read, `requestAnimationFrame`, dev globals, DPR fallback |
| `touchEventsSupported` | `zrender src/zrender.ts:132-140`, `dom/HandlerProxy.ts:452`, `:490` | Pointer size 44, touch listeners, no global mouse listeners |
| `pointerEventsSupported` | `dom/HandlerProxy.ts:422`, `:483` | The pointer branch of IE11 and old Edge |
| `transformSupported`, `transform3dSupported` | `echarts src/component/tooltip/TooltipHTMLContent.ts:48`, `:117`, `:132`, `:138`, `:526` | CSS of the HTML tooltip |
| `wxa` | `zrender src/canvas/Painter.ts:564`, `echarts src/component/tooltip/TooltipHTMLContent.ts:305` | WeChat mini app branches |
| `browser.*` | `zrender src/core/event.ts:12-15`, `echarts src/component/toolbox/feature/SaveAsImage.ts:60`, `core/echarts.ts:1611` | Firefox offsets, IE download, WeChat flush |
| `svgSupported` | none | None |

**A literal port.** The port has no global object. Thus `typeof window` and `typeof document` give
`'undefined'` in a literal translation. Then `env.ts` takes the node branch. `node` true switches
off the animation, the tooltip, the axis pointer, the hover layer and the handler proxy.

**The platform API.** `zrender src/core/platform.ts` (118 lines) declares `platformApi`
(`:54-109`):
- `createCanvas` gives `document.createElement('canvas')`, or `false` with no `document`
  (`:56-59`).
- `measureText` measures on a private canvas. With no canvas, it uses the width map of
  `DEFAULT_TEXT_WIDTH_MAP` (`:52`, `:61-95`).
- `loadImage` makes an `Image` (`:97-103`). `getTime` gives `Date.now()` (`:105-108`).
- `setPlatformAPI` replaces only the known members with a truthy value (`:111-118`). ECharts
  exports it (`echarts src/export/api.ts:42`). `setCanvasCreator` calls it
  (`core/echarts.ts:3312-3320`).
- The zrender spec `core/platform.test.ts:37-38` runs with no canvas. It expects the width
  `12.06` for `'A'` at 18 px.

**The device pixel ratio.** `zrender src/config.ts:3-12` reads `window.devicePixelRatio` once, at
module load. With no window, the value is 1. `:22` exports it as a `const`. Three files read it:
- `canvas/Painter.ts:270` takes `opts.devicePixelRatio || devicePixelRatio`. The painter keeps
  this value for its life. No zrender API changes it.
- `canvas/Layer.ts:159` uses it as the default of a layer.
- `core/PathProxy.ts:12` imports it. `setScale` drops path segments shorter than
  `segmentIgnoreThreshold / dpr / sx` (`:176-183`). `echarts src/chart/line/LineView.ts:1046`
  sets the threshold 2. Thus the module value changes the path data of a line. The path data
  reaches the hit test.

**Timers.** ECharts `src/` calls `setTimeout` 11 times in 8 files and `clearTimeout` 14 times in 6
files. zrender calls `setTimeout` 3 times in 3 files. Examples are `util/throttle.ts:85`, `:92`,
`component/tooltip/TooltipView.ts:263`, `:529` and `zrender src/dom/HandlerProxy.ts:104`. Neither
tree calls `setInterval`.

**The handler proxy.** `zrender src/dom/HandlerProxy.ts` has 634 lines.
- `Handler.ts:17-27` says that a host can replace `HandlerProxy`. The contract is the public
  methods of `Handler` and the eight names of `handlerNames` (`:126-129`): `click`,
  `dblclick`, `mousewheel`, `mouseout`, `mouseup`, `mousedown`, `mousemove` and `contextmenu`.
  `Handler` also reads `proxy.dom` (`:414`).
- The proxy listens on the viewport root (`:28-49`, `:419-479`). On a touch device, it adds the
  touch listeners (`:452-462`). The mouse listeners stay. They do nothing for 700 ms after a touch
  (`setTouchTimer`, `:98-108`, `:472`).
- A touch start triggers `mousemove` and `mousedown` (`:272-289`). A touch end triggers `mouseup`
  (`:304-326`). It also triggers `click` when the touch took less than `TOUCH_CLICK_DELAY`, 300
  ms (`:23`, `:323-325`).
- `wheel` triggers the zrender name `mousewheel` (`:244-257`).
- After a mouse down, the first move to another point starts the pointer capture (`:202-211`,
  `:614-627`). The capture listens to `mousemove` and `mouseup` on `document` (`:481-512`). It
  does this only when `domSupported` is true (`:25`) and `touchEventsSupported` is false
  (`:486-492`).
- A `mouseout` during the capture delays `globalout` until the release (`:221-242`). The release
  outside gives `mouseup`, then `mouseout` with `zrEventControl` `'only_globalout'` (`:403-414`).
  `Handler.mouseout` reads the control (`Handler.ts:239-252`). The block "[DRAG_OUTSIDE]" of
  `Handler.ts:31-76` explains the design.
- A global event gets its position from `normalizeGlobalEvent` with `calculate` true (`:125-134`).
  With `domSupported` false, `calculateZrXY` gives `zrX` and `zrY` 0 (`core/event.ts:90-120`).
- `FakeGlobalEvent` makes `preventDefault` a no-op for the global events (`:179-184`).
- `isLocalEl` stops at an element with `domBelongToZr` (`:139-151`). Thus a pointer that moves to
  an enterable HTML tooltip gives no `mouseout`.
- `setCursor` writes `style.cursor` of the viewport root (`:603-605`).

**Event normalization.** `zrender src/core/event.ts` (313 lines):
- `clientToLocal` takes `offsetX` and `offsetY` when the event has them (`:78-80`). Else it
  calculates from `getBoundingClientRect`, or gives 0 with `domSupported` false (`:90-120`).
- `normalizeEvent` returns at once when the event has `zrX` (`:162-164`). For a touch, it reads
  `targetTouches[0]`, or `changedTouches[0]` at `touchend` (`:176-181`).
- `zrDelta` is `wheelDelta / 120`, else `-detail / 3` (`:171-174`). With no `wheelDelta`, the
  polyfill gives `3 * |deltaY| * sign` from `deltaX` and `deltaY` (`:200-230`). A positive
  `deltaY` gives a negative sign.
- `which` comes from `button` only when the event has no `which` (`:187-190`). A browser sets
  `which`.
- `stop` calls `preventDefault` and `stopPropagation` on the raw event (`:296-300`). The comment
  of `:255-270` says that zrender listeners are not passive, because `preventDefaultMouseMove`
  needs `preventDefault`.
- `core/GestureMgr.ts` tracks the `touches` of each touch event (`:32-54`). Its `pinch`
  recognizer needs two points in two tracks (`:90-122`). `Handler.processGesture` calls it
  (`Handler.ts:403-429`).
- `Handler` drops a `click` that ends more than 4 px from its `mousedown` (`Handler.ts:463-476`).

**The `stop` callers.** ECharts claims an interaction with `eventTool.stop` at 8 sites:
- `component/helper/RoamController.ts:342` (pan) and `:438` (wheel zoom, wheel move, pinch)
- `component/dataZoom/SliderZoomView.ts:938` and `:1051`
- `component/visualMap/ContinuousView.ts:276`, `:304` and `:943`
- `component/axisPointer/BaseAxisPointer.ts:365`

`component/helper/BrushController.ts:856-859` calls `preventDefault` directly. Its callers are
`:953`, `:976` and `:990`. Thus ECharts prevents the default action at 9 code sites.

**Modifier keys.** `RoamController.ts:585` reads `e.event[setting + 'Key']` for `ctrl`, `shift`
and `alt`.

**Cursors.** zrender gives `'pointer'` to each displayable by default
(`graphic/Displayable.ts:665`). `Handler.ts:223` writes `'default'` when no element is under the
pointer. ECharts writes `move`, `grab`, `grabbing`, `crosshair`, `ew-resize` and `ns-resize`.
`BrushController.ts:146-155` and `:687` also make `nesw-resize` and `nwse-resize`. An option can
give any CSS cursor.

**The container.** `init(dom, theme, opts)` (`echarts src/core/echarts.ts:2926-2974`) needs a
`dom` unless `opts.ssr` is set (`:2931-2937`):
- In dev mode, it warns when `isDom(dom)` holds and `clientWidth` or `clientHeight` is 0
  (`:2947-2960`). `isDom` tests `nodeType` and `ownerDocument` (`zrender src/core/util.ts:576-580`).
- It writes the attribute `_echarts_instance_` (`:2913`, `:2967`). `dispose` clears it
  (`:1407-1410`). `getInstanceByDom` reads it (`:3039-3041`).
- `getDom()` returns the `dom` (`:705-707`). `TooltipView.ts:165` builds no tooltip when
  `getDom()` is null.
- `getConnectedDataURL` reads `getBoundingClientRect()` of each chart (`:1043`).
- `zrender.init` gets `devicePixelRatio`, `width`, `height` and `useCoarsePointer` from the
  options (`:569-578`). The default of `useCoarsePointer` is `'auto'` (`:535`).
- The canvas painter takes the multi-layer path when `root.nodeName` is not `CANVAS`
  (`zrender src/canvas/Painter.ts:265-266`). It writes `style` (`:276-279`), clears
  `innerHTML` (`:280`) and appends the viewport root (`:294`). `dispose` clears `innerHTML`
  again (`:1268-1269`).

**Size and resize.** ECharts has no resize observer. The app calls `resize()`
(`core/echarts.ts:1448-1510`). `resize` re-renders the chart and triggers the `updated` event to
the listeners of the app (`:1505-1509`). `getSize` (`zrender src/canvas/helper.ts:104-126`) takes
`opts.width` or `opts.height` first. Else it reads `clientWidth` or `clientHeight`, the computed
size and the inline size. It subtracts the computed paddings. It reads the computed style through
`document.defaultView.getComputedStyle(root)` (`:120`). `Painter.resize` calls `getSize` again
(`canvas/Painter.ts:1208-1255`).

**The upstream specs.** ECharts runs its specs in jsdom. There `window` and `document` exist. Thus
`domSupported` is true. The node branch needs `Node.js` in the user agent (`env.ts:43-44`).
Phase 1 confirms the jsdom user agent. zrender runs its specs in the `node` environment. No
zrender spec calls `init` or reads `env`. Two specs touch the DOM of a chart:
- `series/aria-columns-exclude.test.ts:81-84` reads `aria-label` from `getDom()`.
- `series/custom.test.ts:115-118` dispatches a `MouseEvent` with `zrX` and `zrY` on
  `chart.getDom().children.item(0)`, the viewport root.

**Flutter.** These facts apply:
- `GestureBinding` hit tests a pointer down. It keeps the result for the pointer. Each later event
  of a pressed pointer goes to that path, also outside the box (`gestures/binding.dart:397-439`).
- `GestureBinding.handleEvent` runs after the render objects of the path. It closes the arena at
  a down, sweeps it at an up and resolves the pointer signals (`gestures/binding.dart:527-536`).
- A member that accepts in an open arena becomes the eager winner. In a closed arena, it wins at
  once (`gestures/arena.dart:226-248`).
- `PointerSignalResolver.register` keeps only the first callback of an event
  (`gestures/pointer_signal_resolver.dart:86-91`).
- `kDoubleTapTimeout` is 300 ms, `kDoubleTapSlop` is 100 and `kTouchSlop` is 18
  (`gestures/constants.dart:35`, `:49`, `:65`).
- A new cursor of `RenderMouseRegion` calls `markNeedsPaint`. The mouse tracker then reads the
  cursor after the frame (`rendering/proxy_box.dart:3403-3410`, `rendering/binding.dart:510-526`).
- `SystemMouseCursors` has `basic`, `click`, `move`, `grab`, `grabbing`, `precise`,
  `resizeLeftRight`, `resizeUpDown`, `resizeUpRightDownLeft`, `resizeUpLeftDownRight`, `text`,
  `forbidden`, `wait`, `progress`, `help`, `zoomIn`, `zoomOut`, `none` and others
  (`services/mouse_cursor.dart`).

**The Chart.js precedent.** Chart.js ADR 0014 replaces `platform.dom.js` with a port-only file of
status `replaced` (§1). Its host is a `LeafRenderObjectWidget`. The host sizes the chart in the
first layout. It reads the DPR and `TickerMode`. It paints at `1 / DPR` (§2-5). Its event table
maps `PointerDeviceKind` to DOM names (§6). The host stays out of the arena, except for one tap
recognizer for `click` (§7). Its Open list keeps `dblclick`, `contextmenu`, trackpad
`PointerPanZoom` and the drag outside the box. Chart.js listeners are passive. zrender listeners
are not passive (`core/event.ts:255-270`).

## Decision

### 1. Global objects (gate 1)

1. The port has no `window`, `document`, `navigator`, `self` or `global`. A read of one of them
   translates to an absent value. A `typeof` test of one of them gives `'undefined'`. A call of an
   absent global constructor, for example `Image`, throws, as Node.js throws a `ReferenceError`.
   This is a translation rule. It needs no `DIVERGES` marker.
2. Examples: `createCanvas` of `platform.ts:56-59` gives no canvas. The dev globals of
   `core/echarts.ts:540-552` keep their defaults. The DPR fallback of `core/echarts.ts:908` gives
   the painter value or 1.
3. Items 2, 4 and 15 name the three exceptions. Each exception is a `DIVERGES(echarts)` hunk.

### 2. `env` (gate 1, file in phase 2)

1. `zrender src/core/env.ts` ports with one hunk. The classes `Browser` and `Env` (`:5-30`) port
   line by line. The hunk removes the detection and `detect` (`:32-119`). It carries
   `// DIVERGES(echarts): platform-env-detect, no browser detection in Dart`. The row
   `platform-env-detect` records it.
2. Thus every flag keeps its class default. `node`, `worker`, `wxa`, `svgSupported`,
   `touchEventsSupported`, `pointerEventsSupported`, `domSupported`, `transformSupported`,
   `transform3dSupported` and `hasGlobalWindow` are false. Each `browser` flag is false.
   `browser.version` is absent.
3. The reason: the literal port gives `node` true (Context). `node` true switches off the
   animation, the tooltip, the axis pointer, the hover layer and the input. With the hunk, these
   parts run in Flutter and in the pure specs.
4. The Flutter layer writes `env.touchEventsSupported` once, in `installFlutterPlatform()` (item
   3). The value is true when `defaultTargetPlatform` is Android or iOS. Else it is false. A pure
   layer cannot read `defaultTargetPlatform`, because it is in `package:flutter`.
5. No other code writes `env`. A test that changes a flag restores it with `addTearDown`.
6. The pure specs run with these values. The row `harness-dom-supported` of
   [ECharts ADR 0005](0005-spec-harness-and-reference-tests.md) records the difference from
   jsdom. Examples are `renderMode: 'auto'` and the global capture listeners.
7. The Zepto credit (`:54-56`) goes with `detect`. Thus the port has no Zepto code
   ([ECharts ADR 0001](0001-upstream-sources.md)).

### 3. The platform API (gate 1)

1. `zrender src/core/platform.ts` ports line by line in phase 1. Its pure default is the Node.js
   branch:
   - `createCanvas` gives no canvas (item 1.1).
   - `measureText` thus uses the width map. The zrender spec `core/platform.test.ts` passes with
     no host.
   - `getTime` reads `jsDateNow` (Chart.js ADR 0032 §6). A test that runs in `withClock` pins it.
   - `loadImage` reads the absent global `Image`. Thus the pure default throws (item 1.1).
2. The port-only library `lib/src/platform/flutter_platform.dart` declares
   `installFlutterPlatform()`. It is not a pure layer. Its header is
   `// Original code, not ported from Apache ECharts: the Flutter platform of zrender.`
3. `installFlutterPlatform()` calls `setPlatformAPI` with two members:
   - `createCanvas` gives a new canvas element of the Canvas 2D layer
     ([ECharts ADR 0006](0006-renderer-and-canvas-layer.md) items 3 and 4). Thus the upstream
     `measureText` measures on a canvas of the layer (ECharts ADR 0006 item 9).
   - `loadImage` is the Flutter loader of ECharts ADR 0006 item 10, with the image resolver of
     [ECharts ADR 0009](0009-dom-features-app-hooks-and-theming.md).
   - `getTime` keeps the ported default, because the default already reads `jsDateNow`.
4. `installFlutterPlatform()` also writes `env.touchEventsSupported` (item 2.4), the module DPR
   (item 4) and the frame hook of ECharts ADR 0006 item 11.
5. `installFlutterPlatform()` runs once. A second call does nothing. `RenderEChartsHost` calls it
   when it attaches. The public widget of phase 10 calls it before `init`.
6. The specs never call it. `createChart` installs its own `measureText`
   ([ECharts ADR 0005](0005-spec-harness-and-reference-tests.md), row
   `harness-canvas-mock-text`). A spec that installs a member restores the old member, as
   `core/platform.test.ts:21-35` does.
7. The spec `component/graphic/setOption.test.ts` gives image data URIs (`:35`, `:136`). jsdom
   makes an `Image` for them. The harness of ECharts ADR 0005 thus installs a stub `loadImage`.
   The stub returns an image object with width and height 0. It calls no callback. The phase
   of that spec compares this stub with the jsdom `Image` of the upstream run.
8. An app can call `setPlatformAPI` after the install. Its members then replace the Flutter
   members, as upstream.

### 4. The device pixel ratio (gate 1, file in phase 2)

1. `zrender src/config.ts` ports with one hunk. The export `devicePixelRatio` becomes a settable
   top-level `double`. Dart reads a top-level variable at each use, as an ES module binding. The
   hunk carries `// DIVERGES(echarts): platform-config-dpr, the host sets the module DPR`. The
   row `platform-config-dpr` records it.
2. The pure value is 1, as Node.js gives with no window (`config.ts:3-12`). The specs and the
   reference generators run with 1.
3. `installFlutterPlatform()` sets the value once. The value is the DPR of
   `PlatformDispatcher.instance.implicitView`, at least 1, as `config.ts:7-11` reads it once at
   module load. With no implicit view, the value stays 1.
4. The reason: the segment skip of `PathProxy.ts:176-183` reads this value. The skipped segments
   change the path data of a line series. The path data reaches the hit test (Chart.js ADR 0034).
5. Each instance takes its own DPR from `opts.devicePixelRatio` (`Painter.ts:270`). The public
   widget of phase 10 passes the DPR of its host, unless the app gives one.
6. The painter keeps its DPR for its life, as upstream. A later DPR change of the view repaints
   the host. The host paints each layer at `1 / dpr` of that layer (ECharts ADR 0006 item 6).
   Thus the chart keeps its size after a DPR change.

### 5. Timers (gate 2)

1. The new runtime file `js_timers.dart` of `js_semantics` declares `jsSetTimeout` and
   `jsClearTimeout` (ADR 0008 item 1, [ECharts ADR 0003](0003-numbers-and-js-semantics.md)).
2. `jsSetTimeout(callback, delay)` makes a `dart:async` `Timer`. The duration is
   `jsToInt32(delay)` milliseconds, as Chart.js ADR 0016 item 3 does. `Timer` treats a negative
   duration as zero. The function returns an opaque handle.
3. `jsClearTimeout(handle)` cancels the `Timer`. A null handle or an unknown value does nothing,
   as `clearTimeout` does.
4. Ported code calls these functions at each `setTimeout` and `clearTimeout` site. The
   `dispose` code of upstream cancels them (ECharts ADR 0006 item 11).
5. A `Timer` callback runs after the microtasks, as a JS task does. Thus `fakeAsync` and
   `withClock` tests control the timers.

### 6. The handler proxy (gate 3)

1. `zrender src/dom/HandlerProxy.ts` has the status `replaced`. The replacement is the port-only
   library `lib/src/platform/handler_proxy.dart`. Its header is
   `// Original code, not ported from Apache ECharts: the handler proxy of zrender for Flutter.`
2. The library is a pure layer, because `zrender.dart` imports it (`zrender.ts:128-130`). An
   import of a replaced file points to its replacement. The import needs no marker, because the
   `parity.md` row of the replaced file names the target.
3. The class keeps the upstream name `HandlerDomProxy`. It extends the ported `Eventful`. It
   keeps the members of `HandlerProxyInterface` (`:630-634`), `dom`, `painterRoot`, the capture
   state `__pointerCapturing`, `dispose` and `setCursor`. Each declaration has a `///` line with
   the `HandlerProxy.ts` lines that it replaces. A port-only file has no
   `DIVERGES` markers.
4. The class keeps the upstream behavior:
   - the local handler table of `:192-373`, with the zrender names of `handlerNames`
   - the touch rules: `markTouch`, `processGesture`, the synthesized `mousemove`, `mousedown`
     and `mouseup`, the `click` within `TOUCH_CLICK_DELAY` and the 700 ms timer of `:98-108`
   - the `wheel` to `mousewheel` rule of `:244-270`
   - the capture states of `:202-219` and `:614-627`, and the `zrEventControl` values of
     `:221-242` and `:403-414`
   - `isLocalEl` with `domBelongToZr` (`:139-151`), for the overlay children of item 14
   - `setCursor` and its write of `style.cursor` of `dom` (`:603-605`)
5. The class changes two parts:
   - It has no `document` listeners. The pressed pointers come from the Flutter capture (item 8).
   - It has no pointer branch for IE11 and old Edge (`:328-360`, `:422-450`).
     `pointerEventsSupported` is false (item 2).
6. The proxy listens on `dom`, the `ZrViewport` of ECharts ADR 0006 item 6. It mounts through the
   ported `addEventListener` of `core/event.ts:243-271`. This ADR adds `addEventListener`,
   `removeEventListener` and `dispatchEvent` to `ZrViewport`. Thus the spec
   `series/custom.test.ts:115-118` ports with `dispatchEvent` on `children.item(0)`.
7. The port-only pure library `lib/src/platform/native_event.dart` declares `NativeEvent`, the
   stand-in for the DOM `MouseEvent`, `WheelEvent` and `TouchEvent`. It has these members:
   - `type`, `target`, the opaque Flutter `source` event and `pointerType`
   - `offsetX` and `offsetY`: logical pixels from the top left corner of the host
   - `clientX` and `clientY`: global logical pixels
   - `button` (0 primary, 1 middle, 2 secondary) and `which` (1, 2 or 3, else 0)
   - `ctrlKey`, `shiftKey`, `altKey` and `metaKey` from `HardwareKeyboard`, read by the host
   - `deltaX`, `deltaY` and `deltaMode` 0 for `wheel`
   - `touches`, `targetTouches` and `changedTouches`: lists of `NativeTouch` records with
     `identifier`, `offsetX`, `offsetY`, `clientX` and `clientY`, sorted by pointer id
   - `preventDefault()`, `defaultPrevented`, `stopPropagation()` and `cancelBubble`
   - the zrender fields `zrX`, `zrY`, `zrDelta`, `zrByTouch`, `zrEventControl`, `gestureEvent`,
     `pinchX`, `pinchY` and `pinchScale`
8. `NativeEvent` supports reads by name
   ([ECharts ADR 0004](0004-js-values-classes-and-options.md)). Thus `RoamController.ts:585` reads `ctrlKey` by name.
9. A `NativeTouch` has `offsetX` and `offsetY`, unlike a DOM `Touch`. Thus `clientToLocal` takes
   the `offsetX` branch (`core/event.ts:78-80`). The branch of `:90-120` gives 0 with
   `domSupported` false. `core/event.ts` and `core/GestureMgr.ts` thus port with no hunk.
10. `NativeEvent` always has `which`, as a browser event has. Thus the `button` rule of
    `core/event.ts:187-190` does not run.

### 7. Event table (gate 3)

`RenderEChartsHost` (item 16) makes one `NativeEvent` for each Flutter input below. It dispatches
the event on the `ZrViewport`. The mouse-like kinds are mouse, trackpad, stylus and inverted
stylus, as Chart.js ADR 0014 §6.

| Flutter input | `NativeEvent` types, in order |
|---|---|
| `PointerDownEvent`, mouse-like | `mousedown` |
| `PointerDownEvent`, mouse-like, secondary button | `mousedown`, `contextmenu` |
| `PointerMoveEvent` or `PointerHoverEvent`, mouse-like | `mousemove` |
| `PointerUpEvent`, mouse-like | `mouseup` |
| `PointerUpEvent`, mouse-like, primary button, item 7.1 | `mouseup`, `click` |
| `PointerUpEvent`, mouse-like, primary button, item 7.2 | `mouseup`, `click`, `dblclick` |
| pointer exit (`MouseTrackerAnnotation.onExit`, or the host for an inverted stylus) | `mouseout` |
| `PointerDownEvent`, touch | `touchstart` |
| `PointerMoveEvent`, touch | `touchmove` |
| `PointerUpEvent`, touch | `touchend` |
| `PointerScrollEvent` | `wheel` |
| `PointerCancelEvent` | none |
| pointer enter | none |
| `PointerPanZoomStartEvent`, `PointerPanZoomUpdateEvent`, `PointerPanZoomEndEvent` | none (item 10) |

1. **`click`.** The host gives `click` when the down and the up of the primary button are both in
   the host box. The host claims nothing for it in the arena. A DOM `click` also reaches the
   ancestors. zrender drops a click more than 4 px from its down (`Handler.ts:463-476`).
2. **`dblclick`.** The host gives `dblclick` after a `click` when the last `click` of the same
   device came within `kDoubleTapTimeout` (300 ms). The two up positions are also within
   `kDoubleTapSlop` (100). The rule waits for nothing. Thus a single `click` has no delay.
3. **`contextmenu`.** The host gives `contextmenu` after the `mousedown` of the secondary button.
   A touch long press gives no `contextmenu` (Open).
4. **Touch.** A touch gives only the touch types. The proxy synthesizes the mouse names and the
   `click`, as upstream (item 6.4). The host gives no `mousedown` after a touch. Thus the 700 ms
   timer of the proxy has nothing to drop.
5. **Cancel.** zrender listens to no `touchcancel` and no `pointercancel` (`:28-49`). Thus a
   `PointerCancelEvent` gives no event. A drag state of zrender then stays until the next down, as
   in a browser.
6. **Enter and exit.** `MouseTrackerAnnotation` gives the exit of the mouse and the stylus. The
   host tracks the inverted stylus itself, as Chart.js ADR 0014 §6 does.
7. **Order.** The host dispatches each event at once, in `handleEvent`. It has no throttle. The
   ECharts throttles of `util/throttle.ts` stay in the ported code.

### 8. Pointer capture (gate 3)

1. Flutter sends each event of a pressed pointer to the host, also outside the box (Context).
   This is the capture of the DOM `setPointerCapture`. The proxy needs no `document` listener.
2. A touch keeps the upstream rule. Each touch event of a touch that started in the host is a
   local event, as a DOM touch target is.
3. A mouse-like pointer keeps the upstream capture states:
   - The first `mousemove` to a new point after `mousedown` starts the capture (`:202-211`).
   - During the capture, a move outside the box is the global `mousemove` of `:399-401`. Its
     `zrX` and `zrY` come from the local position, outside the box.
   - The exit of the box during the capture gives `mouseout` with `'no_globalout'` (`:236-238`).
   - An up outside the box during the capture gives `mouseup`, then `mouseout` with
     `'only_globalout'` (`:403-414`).
   - A global event has the no-op `preventDefault` of `FakeGlobalEvent` (`:179-184`).
4. Upstream mounts no global mouse listener when `touchEventsSupported` is true (`:486-492`). The
   port keeps this rule. Then a mouse move outside the box gives no event on Android and iOS.
5. With no capture, a mouse-like event outside the box gives no event, as the DOM gives none to
   the element.

### 9. Wheel (gate 3)

1. The `wheel` event has `deltaX` and `deltaY` from `PointerScrollEvent.scrollDelta`, in logical
   pixels, with `deltaMode` 0. It has no `wheelDelta`.
2. Thus the upstream polyfill computes `wheelDelta` (`core/event.ts:200-230`). `zrDelta` is
   `-deltaY / 40` for a vertical scroll. This is the upstream path of a browser with no
   `wheelDelta`. It needs no hunk.
3. `zrDelta` is behavior. `RoamController.ts:373-409` selects the zoom factor 1.4, 1.2 or 1.1 from
   `|zrDelta|`. A port-only test pins the rule: `scrollDelta` (0, 100) gives `zrDelta` -2.5. The
   roam zoom of that event is `1 / 1.2`.
4. The platforms give different `scrollDelta` values for one wheel notch. The port takes the value
   of the platform. It does not scale it.

### 10. Pinch and trackpad gestures (gate 3)

1. Two touches give `pinch` through the ported `GestureMgr` (item 6.9). The `touches` list holds
   all pointers of kind touch that are down in the host.
2. `PointerPanZoom` events of a trackpad give no event in phase 3. Phase 9 decides them with the
   roam gestures. The two candidates: pan as `wheel` with pixel deltas, and scale as `wheel` with
   `ctrlKey`, as a browser sends a trackpad pinch.

### 11. The gesture arena (gate 3)

The rule: when ECharts stops an event, the host claims that pointer. Else the host stays out of
the arena, as Chart.js ADR 0014 §7.

1. At each `PointerDownEvent` in the box, the host adds one port-only `GestureArenaMember` for the
   pointer. It adds the member in `handleEvent`, before `GestureBinding` closes the arena.
2. After each dispatch, the host reads `defaultPrevented` of the `NativeEvent`.
   `eventTool.stop` sets it (`core/event.ts:296-300`). The direct call of
   `BrushController.ts:858` sets it too.
3. On the first stopped event of the pointer, the member accepts. In an open arena, it is the
   eager winner. In a closed arena, it wins at once. A parent scrollable then loses the drag.
4. At a `PointerUpEvent` with no stop, the member rejects itself. It does this in `handleEvent`,
   before the sweep of `GestureBinding`. Thus the sweep gives the tap to a tappable ancestor.
5. When another member wins, the host keeps the dispatch of the raw events of the pointer. A later
   stop changes nothing.
6. For a stopped `wheel`, the host calls `GestureBinding.instance.pointerSignalResolver.register`
   with a no-op callback. The host is deeper than the scrollables. Thus it registers first. The
   parent then does not scroll.
7. A `wheel` with no stop registers nothing. Then a parent scrollable scrolls.
8. The reason: the roam controller stops its pan at the first move of a drag
   (`RoamController.ts:341-343`). That move comes before `kTouchSlop`. Thus a chart with a roam
   wins the drag before a parent `ListView` accepts it. A chart with no roam keeps the parent
   scroll.

### 12. Cursors (gate 3)

1. `RenderEChartsHost` implements `MouseTrackerAnnotation`. Its `cursor` reads `style.cursor` of
   the `ZrViewport`.
2. A new value of `style.cursor` calls `markNeedsPaint` of the host, as `RenderMouseRegion` does.
   The mouse tracker then reads the cursor after the frame.
3. The table maps the CSS values. A value outside the table gives `SystemMouseCursors.basic`.

| CSS cursor | `SystemMouseCursors` |
|---|---|
| `default`, `auto`, empty | `basic` |
| `pointer` | `click` |
| `move` | `move` |
| `grab` | `grab` |
| `grabbing` | `grabbing` |
| `crosshair` | `precise` |
| `ew-resize` | `resizeLeftRight` |
| `ns-resize` | `resizeUpDown` |
| `nesw-resize` | `resizeUpRightDownLeft` |
| `nwse-resize` | `resizeUpLeftDownRight` |
| `text` | `text` |
| `not-allowed` | `forbidden` |
| `wait` | `wait` |
| `progress` | `progress` |
| `help` | `help` |
| `zoom-in` | `zoomIn` |
| `zoom-out` | `zoomOut` |
| `none` | `none` |

### 13. Coarse pointer (gate 3)

1. `zrender.ts:132-140` ports as is. `useCoarsePointer: 'auto'` reads `env.touchEventsSupported`.
2. Thus a chart on Android or iOS hit tests with the pointer size 44, for each pointer kind. This
   is the upstream rule of a touch device.
3. An app sets `useCoarsePointer` and `pointerSize` in the `init` options to change it.

### 14. `EChartsContainer` (gate 5)

The port-only pure library `lib/src/platform/echarts_container.dart` declares `EChartsContainer`,
the stand-in for the `HTMLElement dom` of `init`. Its header is
`// Original code, not ported from Apache ECharts: the container element of init.`

1. **Node members.** `nodeName` is `'DIV'`. `nodeType` is 1. `ownerDocument` is a port-only
   object. Thus `isDom` gives true. The painter takes the multi-layer path (`Painter.ts:265-266`).
2. **Attributes.** `getAttribute`, `setAttribute` and `removeAttribute` keep string values, as
   the DOM does. `onAttributeChanged` tells the host about a change of `role` or `aria-label`
   ([ECharts ADR 0009](0009-dom-features-app-hooks-and-theming.md) item 2).
3. **Size.** `clientWidth` and `clientHeight` are integers. They are 0 until the host sets them.
   The harness constructor sets them, 500 x 400 for `createChart`.
4. **Client rect.** `getBoundingClientRect()` returns `left`, `top`, `right`, `bottom`, `x`,
   `y`, `width` and `height`. The host gives the origin from `localToGlobal(Offset.zero)` at each
   call. With no host, the origin is (0, 0).
5. **Style.** `style` is a string map with a `cssText` setter. It keeps the writes of
   `disableUserSelect` (`zrender src/core/util.ts:842-849`) and of `createChart`.
   `computedStyle` gives `width` and `height` as the client size in `px`. It gives `'0px'` for
   each padding.
6. **Children.** `appendChild`, `removeChild`, `firstChild` and `children` with `item(i)` and
   `length`. The first child is the `ZrViewport` of the painter. Other children are overlay
   children of later ECharts ADRs. A child with `domBelongToZr` true counts as local for
   `isLocalEl`.
7. **`innerHTML`.** The setter takes only `''`. It removes all children (`Painter.ts:280`,
   `:1268-1269`). Another value throws an `UnsupportedError`. The port has no HTML parser.
8. **Instance.** `getDom()` returns the container. Thus `TooltipView.ts:165` builds the tooltip.
   `getInstanceByDom(container)` finds the chart through the upstream attribute.

### 15. `getSize` (gate 3)

1. `zrender src/canvas/helper.ts` ports with one hunk in `getSize`. The hunk reads
   `root.computedStyle` in place of `document.defaultView.getComputedStyle(root)` (`:120`). It
   carries `// DIVERGES(echarts): platform-container-size, no document`. The row
   `platform-container-size` records it.
2. The rest of `getSize` stays. Thus `opts.width` and `opts.height` win, then `clientWidth` and
   `clientHeight`, then the computed size, then the inline size.

### 16. `EChartsHost` (gate 5)

The port-only library `lib/src/platform/echarts_host.dart` declares `EChartsHost`, a
`LeafRenderObjectWidget`, and `RenderEChartsHost`, a `RenderBox`. It is not a pure layer. It is
not exported. Its header is
`// Original code, not ported from Apache ECharts: the Flutter host of a chart container.`

1. **Ownership.** The host takes one `EChartsContainer`. It owns no chart. It finds the chart with
   `getInstanceByDom`. The owner of the chart calls `dispose` (`core/echarts.ts:1400-1443`).
2. **Render object.** `isRepaintBoundary` is true. `hitTestSelf` is true in the box. `paint` paints
   the `ZrViewport` of the container (ECharts ADR 0006 item 6). Paint clips to the box.
3. **Size rule.** A bounded side takes the max of the constraints. An unbounded side takes the
   min of the constraints. The DOM gives a `div` with no content height 0. Then the dev warning of
   `core/echarts.ts:2955-2958` fires, as upstream.
4. **Client size.** `performLayout` writes `clientWidth` and `clientHeight` as the host size
   rounded with `jsRound`. The DOM attributes are integers (`long` in CSSOM View). A port-only
   test pins the rounded value at a fractional size.
5. **First size.** The host writes the client size in its first `performLayout`, before the first
   paint. Thus a chart that the code creates after the first layout gets its size in `init`. A
   chart that exists before the first layout gets a `resize()` in that layout (item 16.6).
6. **Resize policy.** In each `performLayout`, the host compares the client size with
   `chart.getWidth()` and `chart.getHeight()`. When they differ, it calls `chart.resize()` at once.
   Thus no frame paints the chart at an old size. Upstream needs a call of the app. The host makes
   that call. An app call of `resize()` still works.
7. **Dry layout.** `computeDryLayout` gives the size rule of item 16.3 with no side effect. The
   intrinsic sizes are 0, as for a `div` with no content.
8. **DPR.** The host reads `MediaQuery.maybeDevicePixelRatioOf` in `createRenderObject` and
   `updateRenderObject`. A change repaints the host (item 4.6). The public widget of phase 10
   passes this value to `init` (item 4.5).
9. **`TickerMode`.** The host reads `TickerMode.valuesOf` in `createRenderObject` and
   `updateRenderObject`. When the value changes, it calls the mute or the unmute of ECharts ADR
   0006 item 11 on the zrender instance of the chart.
10. **Events.** `handleEvent` makes the `NativeEvent` of item 7. It dispatches the event on the
    `ZrViewport`. It applies the arena rule of item 11.
11. **Cursor and semantics.** The host is the `MouseTrackerAnnotation` of item 12. The semantics
    of `role` and `aria-label` come from ECharts ADR 0009 item 2.
12. **Attach.** `attach` calls `installFlutterPlatform()` (item 3.5).
13. **Listeners in layout.** `resize` triggers the `updated` event in `performLayout`
    (`core/echarts.ts:1505-1509`). A listener of the app must not rebuild a widget at once. The
    public widget of phase 10 moves such work to a post-frame callback.

### 17. The public widget API (phase 10)

Phase 10 decides the public widget. It decides the name, the options and the theme and locale
parameters. It also decides who creates and disposes of the chart. It connects the app hooks of
ECharts ADR 0009. The widget builds on `EChartsHost`. Before phase 10, the gallery of phase 6
uses the internal host.

## Alternatives considered

- **Keep the `env` detection.** Rejected. The literal port gives `node` true in Dart. Then the
  port has no animation, no tooltip, no hover layer and no input.
- **A run-time detection in `env.ts`.** Rejected. `lib/src/zrender/` is a pure layer. It cannot
  read `defaultTargetPlatform` or `kIsWeb` of `package:flutter`. The Flutter layer writes the one
  flag that depends on the platform.
- **A DOM stand-in for the library, as `chartjs_test_utils` has for the Chart.js specs.** Rejected.
  A `document` with `domSupported` true makes the browser branches live: the HTML tooltip, the CSS
  probes and the `getBoundingClientRect` coordinates. The stand-in then needs CSS layout. The
  Chart.js DOM stand-in is test code, not library code.
- **Port `HandlerProxy.ts` line by line on the `ZrViewport` event target.** Rejected. The capture
  path reads `document`. Its positions come from `normalizeGlobalEvent`. With `domSupported`
  false, that function gives 0. Without the capture path, `globalout` fires at the exit of the
  box, not at the release. The pointer branch of IE11 and old Edge is dead code.
- **Always claim the arena.** Rejected. A pan or drag recognizer takes the drags of parent
  scrollables (fl_chart #202, Chart.js ADR 0014 Context). A chart with no roam then blocks the
  page scroll.
- **A `Listener`-only host with no arena member, as Chart.js ADR 0014 §7.** Rejected. A roam, a
  slider, a brush or a wheel zoom then also scrolls the parent. Upstream prevents the default
  action at 9 sites. Chart.js listeners are passive. zrender listeners are not passive.
- **A `TapGestureRecognizer` for `click`, as Chart.js ADR 0014 §7.** Rejected. It takes the tap
  from tappable ancestors. A DOM `click` reaches them too. zrender drops a click after a drag
  itself.
- **A `DoubleTapGestureRecognizer` for `dblclick`.** Rejected. It delays each single tap. It also
  claims the arena.
- **A `ResizeObserver` stand-in, as Chart.js ADR 0014 §4.** Rejected. ECharts has no observer.
  The host calls the upstream `resize()` directly. A throttled observer adds one frame at the old
  size.
- **A `resize()` in a post-frame callback.** Rejected. One frame then paints at the old size.
- **The fractional host size as `clientWidth`.** Rejected. The DOM gives integers. Fractional
  client sizes give values that no browser gives to the layout.
- **The size 300 x 150 for unbounded constraints, as Chart.js ADR 0014 §5.** Rejected. 300 x 150
  is the default of a `canvas`. The ECharts container is a `div`. A `div` has no default size.
- **A constant module DPR of 1.** Rejected. The segment skip of `PathProxy.ts:176-183` then drops
  other segments than a browser at the same DPR. The hit test of a line can then change.
- **Install `measureText` and `getTime` in `installFlutterPlatform()`.** Rejected. ECharts ADR 0006
  item 9 measures through the canvas of `createCanvas`. The ported `getTime` already reads
  `jsDateNow`.
- **A `Ticker` for the frames.** Rejected. ECharts ADR 0006 gives the reasons in its alternatives.

## Consequences

- The animation, the tooltip, the hover layer and the input run in Flutter and in the pure specs.
- `differences.md` gets three rows from this ADR: `platform-env-detect` (phase 2),
  `platform-config-dpr` (phase 2) and `platform-container-size` (phase 3).
- `parity.md` gives `dom/HandlerProxy.ts` the status `replaced`. The Dart target is
  `lib/src/platform/handler_proxy.dart`. `core/env.ts`, `config.ts`, `core/platform.ts`,
  `core/event.ts`, `core/GestureMgr.ts` and `canvas/helper.ts` port at their mapped paths.
- The pure layers of tool 1 include `handler_proxy.dart`, `native_event.dart` and
  `echarts_container.dart` of `lib/src/platform/`. `flutter_platform.dart` and
  `echarts_host.dart` are not pure.
- `js_semantics` gets `js_timers.dart`. Its tests run on the VM, dart2js and dart2wasm.
- A parent `ListView` or `PageView` keeps its drags over a chart with no roam, no slider and no
  brush. A chart with a roam takes the drags that start on its roam area.
- A tappable ancestor gets the tap of a chart, as a DOM ancestor gets the bubbled `click`.
- Trackpad pan and pinch on desktop and web give no chart event until phase 9.
- A listener of the app runs inside `performLayout` when the host resizes the chart.
- These port-only tests pin the decisions:
  - `env` values after the import, and `touchEventsSupported` after `installFlutterPlatform()`
    with `debugDefaultTargetPlatformOverride`
  - the pure `platformApi` defaults and the install of `createCanvas` and `loadImage`
  - the module DPR, and the size of a chart after a DPR change of the view
  - `jsSetTimeout` with NaN, negative and fractional delays under `fakeAsync`
  - the event table of item 7, with `click`, `dblclick` and `contextmenu`
  - the capture: a drag outside the box, the `'no_globalout'` exit and the `'only_globalout'`
    release
  - the wheel rule of item 9.3
  - the arena: a roam chart in a `ListView` wins the drag. A chart with no roam loses it. A
    stopped wheel does not scroll the parent. A tappable ancestor gets the tap.
  - the cursor table
  - the size rule, the rounded client size, the first-layout size and the resize in layout
  - the `TickerMode` mute under a route that covers the host

## Open

- A touch long press as `contextmenu`.
- Trackpad `PointerPanZoom` events (phase 9, item 10.2).
- `touchEventsSupported` for each pointer kind in place of one value for each platform.
- `domBelongToZr` for the HTML tooltip overlay. The later overlay ADR of ECharts ADR 0009 decides
  it.
- A DPR change on a real device is not tested.

## Evidence

- The `env` readers: `grep -rn` of the flag names in `third_party/echarts/src` and
  `third_party/zrender/src` at the pins. The table of the Context lists each hit outside
  `env.ts`. No file reads `svgSupported`.
- The DOM files: `grep -rlE` of `\bdocument\.`, `\bwindow\.`, `\bnavigator\.`,
  `getComputedStyle`, `addEventListener`, `innerHTML`, `getBoundingClientRect` and
  `createElement\(` in both `src/` trees. 15 ECharts files and 23 zrender files.
- The timers: `grep -rF` of `setTimeout(` and `clearTimeout(` with comment lines removed. The
  four `setInterval(` hits are the method names `_resetInterval`.
- The `stop` callers: `grep -rnE` of `eventTool\.stop` and `preventDefault\(\)` in
  `third_party/echarts/src`. 8 `stop` sites and one direct `preventDefault` function with 3
  callers.
- The cursors: `grep` of `cursor` and `setCursorStyle` string values in
  `third_party/echarts/src`, with `Displayable.ts:665` and `BrushController.ts:146-155`.
- The line count of `HandlerProxy.ts`: 634 lines. The file has no final newline. `wc -l` gives
  633.
- The Flutter lines: the files of `packages/flutter/lib/src/` of Flutter 3.44.9
  (`~/fvm/versions/3.44.9`).
