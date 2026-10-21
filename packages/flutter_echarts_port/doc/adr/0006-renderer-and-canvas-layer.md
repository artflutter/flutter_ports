# ECharts ADR 0006: Renderer: the zrender canvas painter on a Canvas 2D layer

- Status: proposed
- Date: 2026-10-21
- Gate: ECharts phase 3. Phase 3 ports the zrender canvas painter, the layers, the text, the
  images and the frames.
- Related: [ADR 0007](../../../../docs/adr/0007-package-names.md) (the names of shared packages),
  [ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) (the method of a
  shared package, no dependency on another port),
  [Chart.js ADR 0013](../../../flutter_chartjs/doc/adr/0013-canvas-model.md) (the canvas layer),
  [Chart.js ADR 0014](../../../flutter_chartjs/doc/adr/0014-input-events-and-chart-host.md) (the
  chart host), [Chart.js ADR 0015](../../../flutter_chartjs/doc/adr/0015-text.md) (text),
  [Chart.js ADR 0016](../../../flutter_chartjs/doc/adr/0016-frame-scheduling.md) (frames and
  `TickerMode`), [Chart.js ADR 0019](../../../flutter_chartjs/doc/adr/0019-animation.md) (the
  animation clock),
  [Chart.js ADR 0032](../../../flutter_chartjs/doc/adr/0032-js-numeric-semantics.md) (the JS
  numeric rules and the reference engine),
  [Chart.js ADR 0034](../../../flutter_chartjs/doc/adr/0034-no-display-only-js-exactness.md) (no
  display-only JS exactness),
  [D3 ADR 0003](../../../flutter_d3_port/doc/adr/0003-number-to-string.md) (number strings),
  [D3 ADR 0005](../../../flutter_d3_port/doc/adr/0005-path-context.md) (the path context),
  [ECharts ADR 0002](0002-file-naming-and-layout.md) (paths and the pure layers),
  [ECharts ADR 0003](0003-numbers-and-js-semantics.md) (`Float32List`, the protected sites),
  [ECharts ADR 0004](0004-js-values-classes-and-options.md) (ad hoc properties, values),
  [ECharts ADR 0005](0005-spec-harness-and-reference-tests.md) (the spec harness and the
  reference tests),
  [ECharts ADR 0007](0007-environment-host-and-input-events.md) (`env`, the platform API, the host
  and the events),
  [ECharts ADR 0009](0009-dom-features-app-hooks-and-theming.md) (pixel reads, data URLs and
  exports)

## Context

All paths are at the pins: `zrender@6.1.0` (`32b66867`) and `echarts@6.1.0` (`c5a48f5f`). The
Chart.js figures are at commit `4d50cd8` of `main`.

**The size of zrender.** `zrender src/` has 31,449 lines of TypeScript. The folders of the
renderer are these:

| Folder | Files | Lines | Role |
|---|---:|---:|---|
| root (`zrender.ts`, `Element.ts`, `Storage.ts`, `Handler.ts`, `PainterBase.ts`, `config.ts`, `export.ts`, `all.ts`, `global.d.ts`) | 9 | 3,718 | instance, element tree, display list, event dispatch, painter contract |
| `animation/` | 6 | 1,952 | frame loop, `Animator`, `Clip`, easing, `requestAnimationFrame` |
| `canvas/` | 6 | 2,909 | canvas painter: `Painter`, `Layer`, `graphic` (the brush), `helper`, `dashStyle`, `canvas` |
| `contain/` | 9 | 947 | hit-test math, text measure helpers |
| `core/` | 22 | 6,800 | `PathProxy`, matrix and vector math, `platform`, `env`, events, `LRU`, `timsort` |
| `dom/` | 1 | 633 | `HandlerProxy`, the DOM event listeners |
| `graphic/` | 13 | 3,441 | `Displayable`, `Path`, `Text`, `TSpan`, `Image`, `Group`, gradients, patterns |
| `graphic/helper/` | 8 | 1,803 | `parseText`, `image`, `roundRect`, `roundSector`, `poly`, `smoothBezier` |
| `graphic/shape/` | 16 | 1,039 | the built-in shapes |
| `mixin/` | 1 | 117 | `Draggable` |
| `svg/` | 12 | 2,549 | SVG painter: virtual DOM, SSR string, CSS animation |
| `svg-legacy/` | 8 | 1,617 | the old DOM SVG painter |
| `tool/` | 8 | 3,802 | color, SVG parse, XML parse, path tools, morph |
| `debug/` | 1 | 122 | the dirty-rect debug overlay (DOM) |

**The pipeline.**
- `init(dom, opts)` makes a `ZRender` (`zrender.ts:527-531`). The instance has a `Storage`, a
  painter, a `Handler` and an `Animation`.
- `registerPainter(name, Ctor)` fills the painter table (`zrender.ts:559-561`).
  `canvas/canvas.ts` registers the canvas painter.
- A `HandlerProxy` exists only outside node, worker and SSR mode (`zrender.ts:128-130`).
- `refresh()` marks the instance dirty and starts the loop. The next frame calls `_flush`
  (`zrender.ts:282-313`). `_flush` calls `painter.refresh()` and triggers `'rendered'`.
- After 10 still frames, `_flush` stops the loop (`_sleepAfterStill`, `zrender.ts:79`,
  `:305-310`).

**The Canvas 2D calls of the painter.** A grep of `\b(ctx|ctxBack|_ctx)\.` over
`canvas/graphic.ts`, `Layer.ts`, `Painter.ts` and `helper.ts` gives 82 code sites. The comment
lines are not in the count.

| Member | Sites | Where |
|---|---:|---|
| `globalAlpha` (read and write) | 9 | brush 8, motion blur 1 |
| `save()`, `restore()` | 8, 9 | brush, layers, painter |
| `setLineDash` | 6 | brush (`[]` resets) |
| `drawImage` (5- and 9-argument forms) | 6 | `brushImage`, motion blur, `_compositeManually`, `getRenderedCanvas` |
| `fill()`, `stroke()` | 5, 4 | brush |
| `fillStyle`, `strokeStyle` | 4, 3 | brush, the clear color |
| `clip()` | 4 | `updateClipStatus`, the dirty-rect clip |
| `beginPath`, `fillRect` | 3, 3 | brush, painter, the clear color |
| `setTransform`, `lineWidth`, `lineDashOffset`, `fillText`, `strokeText`, `clearRect` | 2 each | brush, layers |
| `ctxBack.scale` | 2 | the back buffer of the motion blur |
| `font`, `textAlign`, `textBaseline`, `shadowColor`, `shadowBlur`, `globalCompositeOperation`, `rect`, `moveTo`, `lineTo`, `closePath`, `createLinearGradient`, `createRadialGradient`, `createPattern` | 1 each | brush, helpers, painter |

- Two loops write properties by name. `SHADOW_NUMBER_PROPS` (`canvas/graphic.ts:367`) writes
  `shadowBlur`, `shadowOffsetX` and `shadowOffsetY` as `dpr * value` (`:409-418`).
  `STROKE_PROPS` (`:368-370`) writes `lineCap`, `lineJoin` and `miterLimit` (`:484-494`). A grep
  of `ctx.` does not find these writes.
- The brush writes raw style values into the context. Two `FIXME` comments say that an invalid
  value leaves the previous value (`canvas/graphic.ts:416`, `:492`). The DOM setters ignore the
  invalid value.
- `setContextTransform` writes `dpr * m` with `setTransform` (`canvas/graphic.ts:517-526`).
- `CanvasGradient.addColorStop` (`canvas/helper.ts:78`). `CanvasPattern.setTransform` takes a
  `DOMMatrix` with `translateSelf`, `rotateSelf` and `scaleSelf` (`canvas/graphic.ts:76-87`).
  The code makes the call only when `typeof DOMMatrix === 'function'`.
- `Layer.initContext` adds the expando `ctx.dpr` (`canvas/Layer.ts:191`). The brush reads it at
  `canvas/graphic.ts:205`, `:417` and `:519`.
- `createDom` writes `width * dpr` into `canvas.width` (`canvas/Layer.ts:35-36`). The DOM
  attribute is an `unsigned long`. Thus the DOM truncates a fraction.
- `Painter.ts:564-571` calls `ctx.draw()` for a WeChat mini-program (`env.wxa`).
- `PathProxy` passes path calls to the context while a shape builds its path
  (`canvas/graphic.ts:211`). It replays its data into a `PathRebuilder` (`core/PathProxy.ts:738`).
  `PathRebuilder` (`core/PathProxy.ts:1000-1010`) has `moveTo`, `lineTo`, `bezierCurveTo`,
  `quadraticCurveTo`, `arc`, `ellipse`, `rect` and `closePath`. This is the `CanvasPath` of D3
  ADR 0005 without `arcTo`, with `ellipse`.
- The shapes call only `moveTo`, `lineTo`, `arc`, `bezierCurveTo`, `quadraticCurveTo`, `rect`
  and `closePath`. A clip path builds its path on the real context (`canvas/graphic.ts:528-537`).
- `core/platform.ts:61-95` sets `font` and calls `measureText` on a private canvas. zrender reads
  only `width` of the result.
- zrender calls none of these members: `isPointInPath`, `isPointInStroke`, `Path2D`,
  `getImageData`, `putImageData`, `roundRect`, `createConicGradient`, `rotate`, `translate`,
  `transform`, `resetTransform`, `strokeRect`, `getLineDash`, `filter`, `OffscreenCanvas`.

**ECharts calls the canvas in five places.**
- `src/util/decal.ts:132-214` makes a canvas with `platformApi.createCanvas()`. It brushes the
  decal tile onto it. The canvas becomes the image of a pattern.
- `src/chart/heatmap/HeatmapLayer.ts:47-154` draws a blurred brush with `shadowBlur`
  (`:145`). It reads the pixels with `getImageData` (`:96`) and writes them back with
  `putImageData` (`:122`).
- `src/chart/helper/LargeSymbolDraw.ts:93-170` takes the context of the path and calls
  `fillRect` for each point in `afterBrush`.
- `src/core/echarts.ts:1012-1120` (`getConnectedDataURL`) makes a canvas (`:1062`). It starts a
  second zrender on it in single-canvas mode (`:1063`). It calls `toDataURL` (`:1116`).
- `src/component/toolbox/feature/SaveAsImage.ts:47-124` downloads the data URL.

**Layers.**
- Each `Layer` is one canvas. The painter puts the canvases in a root `div` (`createRoot`,
  `canvas/Painter.ts:59-80`). `_insertLayer` keeps the DOM order equal to the z order
  (`:756-824`). It calls `insertBefore`, `appendChild`, `firstChild` and `nextSibling`.
- The doc block `canvas/Painter.ts:869-982` states the layer rules. Each `zlevel` has up to three
  canvases (`LIMITED_TO_3_CANVAS_LAYERS_PER_ZLEVEL`, `:895`).
- A `LayerDrawCursor` (`canvas/Layer.ts:63-86`) keeps the draw range of each incremental key.
  When the content is retained, the layer draws only the new tail. Thus the layer needs a
  retained bitmap.
- `_paintPerCursorInRect` (`canvas/Painter.ts:620-691`) stops after 15 ms on an incremental layer
  (`:675-682`). `_paintList` then calls `requestAnimationFrame` again (`:479-505`).
- The hover layer has `HOVER_LAYER_ZLEVEL = 1e5` (`canvas/Painter.ts:22`). `_paintHoverList`
  clears it and brushes the elements with `__inHover` (`:399-463`). ECharts uses it above
  `hoverLayerThreshold: 3000` (`src/model/globalDefault.ts:124`).
- Dirty rects: `Layer.createRepaintRects` (`canvas/Layer.ts:216-390`) merges the paint rects into
  at most `maxRepaintRectCount = 5` rects (`:132`). ECharts sets `useDirtyRect` to `false` by
  default (`src/core/echarts.ts:536`, `:575`).
- `Layer.clear` (`canvas/Layer.ts:430-512`) clears, fills the background and applies the motion
  blur. The motion blur copies the last frame to a back buffer with `'copy'`. It draws it again
  with `lastFrameAlpha` (`:509`). ECharts uses it for the trail of `lines` effects
  (`src/chart/lines/LinesView.ts:78-82`).
- Single-canvas mode: a root without `nodeName`, or a `CANVAS` root, gives one layer at
  `CANVAS_ZLEVEL = 314159` (`canvas/Painter.ts:24`, `:265-327`). Other zlevels are virtual layers.
  `_compositeManually` draws them with `drawImage` (`:507-518`).
- `getRenderedCanvas` (`canvas/Painter.ts:1280-1328`) draws each layer canvas into a new canvas.

**Hit tests.**
- No zrender or ECharts file calls `isPointInPath` (0 hits in each `src/`). Hit tests are math.
- `Path.contain` (`graphic/Path.ts:394-424`) maps the point to local space. It then calls
  `containStroke` and `contain` of `contain/path.ts`. These count windings over the `PathProxy`
  data.
- The coarse pointer (`zrender.ts:132-140`, default size 44) samples rings around the point with
  `Math.cos` and `Math.sin`.
- `PathProxy.toStatic` stores the data in a `Float32Array` when it has more than 11 values
  (`core/PathProxy.ts:473-488`). Thus the windings read float32 coordinates.
- `setScale` drops segments below `_ux = |segmentIgnoreThreshold / dpr / sx|`
  (`core/PathProxy.ts:175-183`). Here `dpr` is the module value of `config.ts`
  (`core/PathProxy.ts:12`). Thus the stored path and the hit test depend on that value.

**Text.**
- `platformApi.measureText` (`core/platform.ts:61-95`) measures on a canvas. Without a canvas, it
  uses the width map of `DEFAULT_TEXT_WIDTH_MAP` (`:33-53`).
- `contain/text.ts` keeps an LRU of 100 fonts and an LRU of 500 widths for each font (`:26-48`).
  `tryCreateASCIIWidthMap` builds an ASCII width map from 128 calls of `measureText`
  (`:57-77`). It times the build with `+new Date()` (`:64`, `:69`). A build of more than 2 ms
  adds 1 to a global count. A build of more than 16 ms sets the count to its limit 5 (`:70-75`,
  `:79`). At the limit, every later font gets no map. Then each ASCII character of that font has
  the width of `'a'` (`asciiCharWidth`, `:43`, `:92`).
- `measureCharWidth` (`contain/text.ts:84-95`) gives each UTF-16 code unit above 127 the width of
  `'国'` (`stWideCharWidth`, `:42`, `:94`). The wrap (`wrapText`,
  `graphic/helper/parseText.ts:739`) and the truncation (`estimateLength`, `:182`) read it. Thus
  the width of `'国'` sets the wrap and the truncation of all non-ASCII text: Cyrillic, accented
  Latin, Arabic and emoji.
- A layout of a Flutter `ui.Paragraph` can take more time than a measure of the Chrome canvas.
  The research of phase 0 did not measure the two times. Thus the port can cross the 2 ms limit
  where Chrome does not. The wrap and the truncation then change with the device and the run.
- The line height is the width of `'国'` (`getLineHeight`, `contain/text.ts:180-183`). The
  upstream comment calls it "A rough approach". This value sizes each text box.
- `graphic/helper/parseText.ts` (951 lines) wraps, truncates and lays out rich text.
  `graphic/Text.ts` (1,113 lines) makes one `TSpan` for each line. Each `TSpan` sets
  `textBaseline` to `'middle'` (`graphic/Text.ts:629`, `:866`).
- Text boxes reach hit tests, label layout and the axis label interval. Chart.js ADR 0034 calls
  such values behavior.

**Images.** `graphic/helper/image.ts` keeps a global LRU of 50 images (`:6`). The default
`platformApi.loadImage` makes an `Image` (`core/platform.ts:97-103`). zrender also takes a canvas
as an image: decal tiles, the heatmap, the motion blur, the single-canvas composite and the
connected export.

**Frames.**
- `animation/requestAnimationFrame.ts` takes `window.requestAnimationFrame`. Without a window, it
  calls `setTimeout(func, 16)`.
- `Animation._startLoop` (`animation/Animation.ts:168-181`) requests a frame in each step while
  the loop runs. `pause()` stops the updates (`:207-221`). The paused loop still requests frames.
- `Animation` reads the time with `new Date().getTime()` (`animation/Animation.ts:14-15`).
  `platformApi.getTime` gives `Date.now()` (`core/platform.ts:105-108`).
- The painter has its own loop for progressive layers (`canvas/Painter.ts:492`).

**The SVG painters.**
- `svg/Painter.ts` mounts a virtual DOM with `document.createElement` (`:78-80`). It updates the
  DOM with `patch.ts` (321 lines) and `domapi.ts` (55 lines).
- The string parts of `svg/` make the SSR output of `renderToSVGString`.
- `animation/Animator.ts:23` imports `isLinearGradient` and `isRadialGradient` from
  `svg/helper.ts`. `graphic/Pattern.ts:2` imports the type `SVGVNode` from `svg/core.ts`.
- `svg-legacy/` writes the DOM directly. Nothing in `echarts.all.ts` reaches it.

**The Chart.js canvas layer.** `packages/flutter_chartjs/lib/src/canvas/` has 6 files with 5,066
lines. Chart.js ADR 0013 states its model:
- a pure interface (`canvas.dart`) and a `dart:ui` implementation (`UiCanvasElement`,
  `UiCanvasContext`)
- a retained bitmap as a list of `ui.Picture`s, with a flatten step above 8 pictures (§4)
- bitmap space in device pixels, with a host scale of `1 / DPR` (§5)
- the path rules, dashes, gradients, patterns, composite modes and images of §6-7
- the context ignores an invalid value, as the DOM does (§7)
- text on a single-line `ui.Paragraph` with LRU caches (Chart.js ADR 0015 §2-3)
- a host for one canvas (Chart.js ADR 0014) and frames on `scheduleFrameCallback` (Chart.js ADR
  0016 item 1)

The layer has seven gaps for zrender and ECharts:
1. Shadows: the layer has no shadow member (`grep -ci shadow` gives 0 in each file).
2. `CanvasPattern` is an empty interface (`lib/src/types/color.dart:49`). It has no
   `setTransform`. The layer has no `DOMMatrix`.
3. A canvas is not a `CanvasImageSource`. A caller passes a snapshot from `toImageSource()`
   (Chart.js ADR 0013 §7).
4. `getImageData` and `putImageData` are absent.
5. `toDataURL` is absent.
6. The host shows one canvas (`ChartHost`, `lib/src/platform/chart_host.dart:267`).
7. The canvas has no `ctx.dpr` expando. The `width` setter takes an `int`.

**Dependencies of the Chart.js layer.** `canvas.dart:26` imports `lib/src/types/color.dart` of the
Chart.js port. `canvas_ui_paint.dart:23` imports the `@kurkle/color` port (MIT, Jukka Kurkela).
The WebIDL setter conversions are in `lib/src/js/js_webidl.dart` (86 lines). ADR 0008 item 3
keeps this file in the Chart.js port. A file that another port needs moves by the method of item
5.

**ADR 0008 and the deferred plan.** ADR 0008 item 1 says that no port depends on another port.
D3 ADR 0005 §4 kept a shared canvas layer as a deferred plan. Its trigger is "A D3 caller that
needs styles, text or transforms on a context" (D3 `porting-flow.md` §5.1). zrender needs all of
these. `packages/flutter_chartjs/doc/canvas-cuts-plan.md` cites `lib/src/canvas/` 23 times.

## Decision

### 1. Port the canvas painter

- `canvas/Painter.ts`, `Layer.ts`, `graphic.ts`, `helper.ts`, `dashStyle.ts` and `canvas.ts` port
  line by line to `lib/src/zrender/canvas/` ([ECharts ADR 0002](0002-file-naming-and-layout.md)).
- They call a pure Canvas 2D interface: `CanvasRenderingContext2D`, `HTMLCanvasElement` and their
  objects. A `dart:ui` implementation draws the calls.
- The brush, the path batch (`flushPathDrawn`), the clip stack, the dirty rects and the cursors
  stay as upstream. Thus upstream diffs replay.
- `PathProxy` keeps its pass-through and its `rebuildPath`. The Dart `PathRebuilder` keeps the 8
  members of `core/PathProxy.ts:1000-1010`.
- In tests, a context that records the calls implements the interface. Thus a test compares the
  canvas calls, as the Chart.js controller reference tests do.

### 2. Purity

- All of `lib/src/zrender/` and `lib/src/echarts/` is pure ([ECharts ADR 0002](0002-file-naming-and-layout.md)).
  No file there imports `dart:ui` or `package:flutter`.
- The `dart:ui` implementation, the host, the image loader and the frame source are outside the
  two mapped trees. The Flutter layer of `lib/src/platform/` installs them through
  `setPlatformAPI` and the frame hook of item 11.
- Thus the zrender and ECharts specs run on the VM, with dart2js and with dart2wasm
  ([ECharts ADR 0005](0005-spec-harness-and-reference-tests.md)).

### 3. A shared Canvas 2D layer

The Canvas 2D layer comes from a shared layer. A new root ADR decides it. Its number is the next
free number of `docs/adr/` (0009 on 2026-10-21). The ADR is proposed before ECharts phase 3. It
takes the method of ADR 0008:
- **End state.** A shared pure interface and a shared `dart:ui` implementation. ADR 0007 item 6
  gives the name rules: the pure part has no `flutter_` prefix. The implementation has it. The
  root ADR selects the names and records the pub.dev examination of ADR 0007 item 7.
- **Stage 1 (gate: ECharts phase 3).** Copy `packages/flutter_chartjs/lib/src/canvas/` at one
  commit. Record the commit. Add the gaps of item 5. Add a drift check of the shared files against
  the Chart.js copies. Change no file of the Chart.js packages and app.
- **Stage 2.** The Chart.js port moves onto the shared layer at a Chart.js phase boundary. That
  change updates `canvas-cuts-plan.md` (the deferred-plan rule of AGENTS.md).
- **The canvas cuts.** The root ADR states how the work of `canvas-cuts-plan.md` and the drift
  check interact. A cut of a copied file changes both copies, as ADR 0008 item 6 asks.
- **License.** The canvas files are port-only code of the Chart.js port. `REUSE.toml` gives
  them the MIT notice of `packages/flutter_chartjs/**`. The shared package keeps that notice.
- **Dependencies.** The layer parses CSS colors with the `@kurkle/color` port. It takes
  `CanvasGradient` and `CanvasPattern` from a Chart.js type library. The root ADR moves both into
  the shared layer, with the MIT notice of Jukka Kurkela. Or it gives the layer a color parser
  hook. `js_webidl.dart` moves to `js_semantics` by the method of ADR 0008 item 5.
- **D3.** The root ADR also updates the deferred plan of D3 ADR 0005 §4. ECharts is the trigger.
- ECharts code stays Apache-2.0. The zrender ports are `BSD-3-Clause AND Apache-2.0`: the
  zrender code and the changes of the port. [ECharts ADR 0001](0001-upstream-sources.md) item 12
  annotates them so.

### 4. The fallback

If the root ADR of item 3 is not accepted before phase 3, this package writes its own port-only
`lib/src/canvas/`. It is new code. It does not copy the Chart.js files across licenses (the D3
ADR 0005 precedent). It follows Chart.js ADR 0013 and 0015 as a design. It covers the gaps of
item 5. Its cost is about the 5,066 lines of the Chart.js layer.

### 5. The gaps

The shared layer (or the fallback) adds these members. Each item names its Dart form.
1. **Shadows.** `shadowBlur`, `shadowColor`, `shadowOffsetX` and `shadowOffsetY`.
   - A draw with a visible shadow draws the shape a second time first. The paint has the shadow
     color and `MaskFilter.blur(BlurStyle.normal, shadowBlur / 2)`. The HTML standard gives the
     sigma as half the blur value.
   - The offsets and the blur are in bitmap space. The transform does not apply to them, as in
     the DOM. zrender already multiplies them by `dpr` (`canvas/graphic.ts:417`).
   - The shadow of text uses the same mask on the paragraph paint, or a `ui.Shadow`.
   - The shadow of an image needs a probe on Impeller and skwasm before stage 1 ends.
   - The shadow is display only (Chart.js ADR 0034). Its blur pixels can differ from Chrome.
2. **`DOMMatrix`.** A port-only pure `DOMMatrix` with `translateSelf`, `rotateSelf(0, 0, deg)`
   and `scaleSelf`. `CanvasPattern.setTransform(DOMMatrix)` gives the pattern shader its matrix.
   - The feature tests `typeof DOMMatrix === 'function'` and `canvasPattern.setTransform` are
     true in the port. The port keeps the branch. This is a translation rule. It needs no row.
3. **A canvas as an image source.** `drawImage` and `createPattern` take a canvas element, as the
   DOM does. The layer takes an implicit snapshot of the bitmap at the call.
   - zrender passes canvases at many sites (the Context). An explicit snapshot needs a `DIVERGES`
     hunk at each site.
   - The root ADR decides the Dart signature. One form is an `Object` parameter that accepts a
     `CanvasImageSource` or an `HTMLCanvasElement`. Another value throws a `TypeError`, as
     WebIDL does.
   - The layer can cache the snapshot until the next change of the canvas content.
4. **Several canvases in one host.** The canvas element gets the node members that the painter
   reads: `nodeName` (`'CANVAS'`), `parentNode` and `nextSibling`. Item 6 gives the parent.
5. **The `unsigned long` size.** A write of `width` or `height` takes the JS number of the
   upstream code. The setter applies the WebIDL conversion of an `unsigned long` (`jsToUint32`,
   [ECharts ADR 0003](0003-numbers-and-js-semantics.md)). Thus `500 * 2.625` gives `1312`, as in
   the DOM.
6. **The WebIDL setters.** zrender writes raw style values. The context setters apply the
   conversions of `js_webidl.dart` (`canvasStyle`, `canvasNumber`, `canvasKeyword`,
   `canvasLineDash`) at the sites where the value is raw, as the Chart.js port does. An invalid
   value leaves the previous value. Thus the upstream `FIXME` style leak stays as in the DOM.
7. **`ctx.dpr`.** The expando becomes an `Expando<num>` of the ported `canvas/Layer.dart`
   ([ECharts ADR 0004](0004-js-values-classes-and-options.md), ad hoc properties). The brush reads
   it at the three upstream sites.

`getImageData`, `putImageData` and `toDataURL` are not part of this ADR. ECharts ADR 0009 decides
them (item 14).

### 6. Layers and `ZrViewport`

- One zrender `Layer` is one canvas element of the layer, with its own retained picture list. A
  layer needs no render object of its own.
- The port-only pure class `ZrViewport` replaces the root `div` of `createRoot`. It keeps the
  ordered list of layer canvases. It implements `appendChild`, `insertBefore`, `removeChild`,
  `firstChild`, `style` and the size of the root. Thus `_insertLayer` ports line by line.
- `createRoot` (`canvas/Painter.ts:59-80`) makes a `ZrViewport` in place of
  `document.createElement('div')`. This is one `DIVERGES(echarts)` hunk with the row
  `platform-zr-viewport`.
- `EChartsHost` ([ECharts ADR 0007](0007-environment-host-and-input-events.md)) paints the
  canvases of the `ZrViewport` in list order. Each canvas paints at the scale `1 / dpr`
  (Chart.js ADR 0013 §5). The host is one repaint boundary.
- A hover refresh records only the hover layer again. The other layers paint their retained
  pictures again.
- A progressive layer adds one picture in each frame. The flatten step above 8 pictures bounds
  the list (Chart.js ADR 0013 §4).
- ECharts ADR 0007 decides the container members that `getSize` reads
  (`canvas/helper.ts:104-126`) and `root.innerHTML = ''` (`canvas/Painter.ts:280`).

### 7. Dirty rects, motion blur and the single-canvas mode

- The dirty-rect code stays as upstream. `useDirtyRect` stays `false` by default. A partial
  `clearRect` and a `clip` work on the retained bitmap of the layer. The raster thread draws the
  whole picture list. Thus the dirty rect saves less in Flutter than in a browser.
- The motion blur uses the canvas image source of item 5.3 for its back buffer.
- The single-canvas mode stays. `getConnectedDataURL` and `getRenderedCanvas` use it on
  offscreen canvases with no host.

### 8. Paths and hit tests

- Hit tests stay zrender math. They are a pure layer. The port adds no `isPointInPath` and no
  `Path2D`.
- `PathProxy.data` is a `Float32List` after `toStatic`, as upstream
  ([ECharts ADR 0003](0003-numbers-and-js-semantics.md)). The windings read float32 values on all
  three test legs.
- The segment skip reads the `dpr` of `config.ts`. ECharts ADR 0007 decides that value. The specs
  and the reference generators run with `dpr` 1, as Node.js does without a window
  (`config.ts:3-12`).
- The `Math` calls of the hit tests are protected sites
  ([ECharts ADR 0003](0003-numbers-and-js-semantics.md)): `jsSin`, `jsCos`, the fdlibm `atan2`
  and `acos`.

### 9. Text

- `core/platform.ts` ports as is. The Flutter layer sets `createCanvas`. Thus the upstream measure
  path calls `measureText` on a canvas of the layer. The layer measures with a single-line
  `ui.Paragraph` (Chart.js ADR 0015 §2).
- The caches of `contain/text.ts` stay above the layer cache.
- `parseText.ts`, `Text.ts` and `TSpan.ts` port line by line. zrender keeps its own wrap,
  truncation and rich-text layout. The layout is behavior: it reaches label overlap and the axis
  label interval.
- `fillText` and `strokeText` draw one line with `textBaseline` `'middle'` on the em box of
  Chart.js ADR 0015 §3.
- The time reads of `contain/text.ts:64-69` call `jsDateNow`. The specs pin the clock. Thus the
  ASCII width map always builds in a test.
- The measure of the layer must stay fast enough for `tryCreateASCIIWidthMap`
  (`contain/text.ts:57-77`, the limit 5 at `:79`). That function counts a build of more than 2 ms. Five such builds,
  or one build of more than 16 ms, stop the map. After that, every new font uses the width of
  `'a'` for ASCII. The layer caches the advance of each single character for each font. The
  phase 3 benchmark records the time of 128 calls of `measureText` for each target. A time above
  2 ms is a defect of the layer.
- `measureCharWidth` (`contain/text.ts:84-95`) gives each UTF-16 code unit above 127 the width of
  `'国'`. The CJK fallback font thus sets the wrap and the truncation of all non-ASCII text, not
  only the line height.
- Phase 3 runs the text-metric probe of the Chart.js port
  (`packages/flutter_chartjs/tool/reference/text_metrics/`, headless Chrome) on the zrender font
  strings: `12px sans-serif`, a bold 14px font, CJK, Cyrillic and emoji. It writes
  `doc/text-metrics.md`. A difference of label overlap or of the axis label interval between
  Flutter and Chrome is display only when the probe shows width differences below 0.5 px.
- **The Flutter test font.** Phase 3 copies Liberation Sans 2.1.5 (SIL OFL 1.1) into
  `test/fonts/`. The same change adds its OFL notice to the package `LICENSE` and a `REUSE.toml`
  table. `LICENSES/OFL-1.1.txt` is present. A Flutter test that paints text registers a fixed
  advance for `'国'` (the em size) through the layer. The package ships no CJK font.
- **Risk: the width of `'国'`.** The line height is the width of `'国'`. The wrap and the
  truncation use it for each non-ASCII code unit. Liberation Sans has no CJK glyph. A Flutter
  test then measures the glyph in a fallback font. That font differs for each platform. ECharts
  ADR 0005 pins the spec widths. The fixed advance of the test font item pins the width of the
  Flutter tests.

### 10. Images

- The port-only `platformApi.loadImage` of the Flutter layer returns an image object with
  `width` and `height` 0 until the load ends. It calls `onload` or `onerror` from the listener of
  the image stream.
- It decodes `data:` URIs with `ui.instantiateImageCodec`. An app resolver gives other sources
  ([ECharts ADR 0009](0009-dom-features-app-hooks-and-theming.md)). `lib/` has no network or
  asset plugin.
- `UiImageSource(ui.Image)` is the image source of the layer. `isImageReady` reads its width and
  height, as upstream.
- The LRU of `graphic/helper/image.ts` stays.
- `dart:ui` has no SVG image decoder. A `data:image/svg+xml` source calls `onerror` until a later
  ADR decides it.

### 11. Frames

- `animation/requestAnimationFrame.ts` ports with one `DIVERGES(echarts)` hunk. The row is
  `platform-request-anim-frame`. The hunk calls a settable frame hook.
- The pure default of the hook is the upstream fallback: a `Timer` of 16 ms. The Flutter layer
  sets the hook to `SchedulerBinding.instance.scheduleFrameCallback`, as Chart.js ADR 0016 item 1
  does.
- `Animation`, `_flush`, `_sleepAfterStill` and the progressive loop of the painter stay as
  upstream.
- `getTime` of `Animation.ts` and `platformApi.getTime` give `jsDateNow`. The specs and the
  reference generators run on a frozen clock ([ECharts ADR 0005](0005-spec-harness-and-reference-tests.md)).
- **`TickerMode`.** The host mutes the `Animation` of its instance when `TickerMode` turns off.
  While muted, `step` requests no frame. When the loop runs, unmute requests a frame again. The clips then
  continue at the current time, as Chart.js ADR 0016 item 7 does. This is a `DIVERGES(echarts)`
  hunk in `Animation.ts` with the row `platform-animation-mute`.
  - `pause()` is not the mute. A paused loop still requests a frame in each step
    (`animation/Animation.ts:172-177`).
- `setTimeout` and `setInterval` of zrender and ECharts become a `dart:async` `Timer`. `dispose`
  cancels them (Chart.js ADR 0016 items 3 and 4).

### 12. SVG

- `svg-legacy/` (8 files) is `n/a: DOM SVG painter`.
- The DOM parts of `svg/` are `n/a: DOM mount`. These are `patch.ts`, `domapi.ts` and the DOM
  mount of `svg/Painter.ts`.
- `svg/helper.ts` ports in phase 3, because `animation/Animator.ts:23` imports it.
- The string parts port in phase 10 for `renderToSVGString` and SSR. These are `core.ts`,
  `graphic.ts`, `SVGPathRebuilder.ts`, `mapStyleToAttrs.ts`, `cssAnimation.ts`, `cssEmphasis.ts`,
  `cssClassId.ts` and the string path of `svg/Painter.ts`. Their number strings are behavior
  (D3 ADR 0003).
- Until phase 10, `graphic/Pattern.ts` gets the type `SVGVNode` by the forward-type rule of
  ECharts ADR 0002.

### 13. Out of scope

- `debug/showDebugDirtyRect.ts` is `n/a: DOM debug overlay`.
- The custom layers of echarts-gl (`insertLayer`, virtual WebGL layers) port as plain code with
  `Painter.ts`. The port gives no WebGL layer.
- The `env.wxa` branches port as plain code. `env.wxa` is `false`
  ([ECharts ADR 0007](0007-environment-host-and-input-events.md)).

### 14. Pixel reads and data URLs

ECharts ADR 0009 decides `getImageData` and `putImageData` of the heatmap, `toDataURL`,
`getDataURL`, `getConnectedDataURL` and the decal tiles. `dart:ui` reads pixels only
asynchronously (`ui.Image.toByteData`).

### 15. Tests of the renderer

- The phase 3 specs run with a context that records the calls ([ECharts ADR 0005](0005-spec-harness-and-reference-tests.md)).
- Reference tests of zrender scenes run zrender in single-canvas mode on a canvas that records the
  calls, under the x64 build of Node.js v24.12.0 (Chart.js ADR 0032). A Dart test compares the calls of
  the same scene.
- A Flutter test paints a scene through the `dart:ui` layer. It compares the image with its own
  golden. No test compares pixels with Chrome.

### 16. Performance

- One `EChartsHost` render object paints all layers.
- A `PictureLayer` or an `OffsetLayer` for each zrender layer comes only after a measurement of
  the phase 6 frame figures in `doc/performance.md`. The engine can then raster-cache a stable
  layer. Phase 3 creates that file with the large-data benchmark
  ([porting-flow.md](../porting-flow.md) §7 risk 17).
- A layer batch for runs of `fillRect` (the circle batch of the Chart.js canvas layer) comes only
  after the large-data benchmark of phase 3.

## Alternatives considered

- **A port-only Flutter painter through `registerPainter`.** Rejected. It replaces 2,909 lines of
  upstream code with new code. Upstream diffs of `canvas/` then do not replay. The layer rules,
  the cursors and the hover layer need a new design. Tests cannot record Canvas 2D calls.
- **One `ui.Picture` for all layers.** Rejected. A hover then records all layers again. A
  progressive layer needs its own retained bitmap.
- **`Path2D` or `isPointInPath` hit tests.** Rejected. Upstream has no such call. Engine hit
  tests do not count windings over float32 data. Hit tests then need `dart:ui` and leave the pure layer.
- **A `Ticker` for each instance.** Rejected. A `Ticker` needs a `TickerProvider`. An instance
  can exist before a host or with no host: `init` before the mount, and the offscreen export
  instance. The painter is a second frame user. A `Ticker` also calls `scheduleFrameCallback`.
- **`ui.Paragraph` wrap and truncation.** Rejected. zrender lays out text itself. The layout
  reaches label overlap and the axis label interval. A Flutter wrap changes that behavior.
- **A live SVG renderer** (the zrender SVG painter on a Dart SVG widget). Rejected. Flutter has no
  DOM. It parses again what the canvas painter can draw directly.
- **Import the Chart.js canvas layer.** Rejected. ADR 0008 item 1 forbids a dependency on another
  port. The `implementation_imports` lint also flags `package:flutter_chartjs/src/`.
- **Explicit snapshots with a `DIVERGES` hunk at each canvas source site.** Rejected as the first
  choice. It adds hunks in `Painter.ts`, `Layer.ts`, `decal.ts` and `echarts.ts`. The root ADR can
  select it if the implicit snapshot fails.

## Consequences

- zrender and ECharts stay pure layers. The specs run on three legs with no `testWidgets`.
- ECharts phase 3 needs the root ADR of item 3 or the fallback of item 4. The root ADR is proposed
  before phase 3. Its stage 1 has the gate ECharts phase 3.
- The Chart.js port changes no file in stage 1. Stage 2 waits for a Chart.js phase boundary.
- Three rows come from this ADR: `platform-request-anim-frame`, `platform-zr-viewport` and
  `platform-animation-mute`. The phase 3 change adds them to `differences.md`.
- The width of `'国'` is a risk for each Flutter test that paints text. ECharts ADR 0005 pins the
  spec widths. A Flutter test registers a fixed advance for `'国'` (section 9).
- Phase 3 adds the text-metric probe, the measure-time benchmark and the test font with its
  notice (section 9).
- The shadow of an image needs a probe on Impeller and skwasm.
- The SVG export and SSR wait for phase 10.

## Evidence

- The folder table: `git ls-files src` and `wc -l` at `zrender@6.1.0`.
- The 82 call sites: `grep -nE '\b(ctx|ctxBack|_ctx)\.[A-Za-z]+'` over `canvas/graphic.ts`,
  `Layer.ts`, `Painter.ts` and `helper.ts`, without the comment lines.
- No `isPointInPath`: `grep -rn isPointInPath` over both `src/` trees gives 0 lines.
- The Chart.js layer: `wc -l packages/flutter_chartjs/lib/src/canvas/*.dart` at `4d50cd8` gives
  5,066 lines. `grep -ci shadow` gives 0 for each file.
