# Chart.js ADR 0013: Canvas model

- Status: accepted (2026-10-21)
- Date: 2026-10-19
- Related: [Chart.js ADR 0009](0009-no-display-only-js-exactness.md) (no Chromium geometry),
  [Chart.js ADR 0014](0014-input-events-and-chart-host.md) (the chart host),
  [Chart.js ADR 0015](0015-text.md) (canvas text), [porting-flow.md](../porting-flow.md) §2.2

## Context

Upstream draws on the DOM `CanvasRenderingContext2D` (`lib.dom.d.ts`). The specs check the canvas
calls through the mock context of chartjs-test-utils 0.4.0. The mock has 24 methods and 9
setters (`src/context.js:102-146`). Thus specs port 1:1 only against that API.

Phase 2 ported `toFontString` and `_isPointInArea` of `helpers.canvas.ts`. `helpers.options` and
`helpers.curve` import `helpers.canvas`. These helpers are pure layers
([porting-flow.md](../porting-flow.md) §3). Thus the canvas interface that `helpers.canvas`
imports must not reach `dart:ui`.

`dart:ui` gives `Canvas`, `Path`, `Paint`, `PictureRecorder`, `Gradient`, `ImageShader` and
`PathMetrics`. It does not give these Canvas 2D semantics:
- A DOM canvas keeps its bitmap until the code clears it. A Flutter render object paints again
  in each frame that marks it.
- The current path is outside `save()` and `restore()`.
- The transform applies when the code adds a point, not when the code fills or strokes.
- A path method with a non-finite argument does nothing.
- `arc` with a negative radius throws an `IndexSizeError`.
- `arc` connects the current point to the start of the arc with a line.
- A sweep of 2π or more draws a full circle. `ui.Path.arcTo` draws nothing for a sweep that is a
  multiple of 2π.
- `setLineDash` and `lineDashOffset`. `dart:ui` has no dash.
- The bitmap has `width` x `height` device pixels. A write of `width` or `height` resets the
  context state and clears the bitmap, also with the same value. `platform.dom.js:319` relies on
  this.

`RenderView` already applies the device pixel ratio (DPR) at the root
(`rendering/view.dart:70-72`, `:267-270`). `retinaScale` (`helpers.dom.ts:208-240`) sets the
bitmap to the device size and calls `setTransform(dpr, 0, 0, dpr, 0, 0)`.

porting-flow.md §2.2 proposed a base `scale(1 / currentDevicePixelRatio)` under each transform.
The first phase 3 implementation recorded each picture on the base scale of the DPR at record
time. The host painted all pictures with one DPR that it took when it attached. A wasm build on a
DPR 2 screen showed a canvas that the code drew before the attach at 2 times its size, cropped.

## Decision

### 1. Layers

The canvas layer lives in `lib/src/canvas/`. All its files are port-only.
- `canvas.dart` is a pure layer. It declares the interfaces `CanvasPath`,
  `CanvasRenderingContext2D`, `HTMLCanvasElement`, `CSSStyleDeclaration`, `TextMetrics`,
  `CanvasImageSource`, `CanvasNode` and `CanvasContainer`, the typedef `CanvasFillRule`, and the
  concrete class `Path2D`. It re-exports `CanvasGradient` and `CanvasPattern` of
  `lib/src/types/color.dart`. The names and the argument order are the DOM names and order.
- `canvas_ui.dart`, `canvas_ui_path.dart`, `canvas_ui_paint.dart` and `canvas_ui_text.dart` are
  the `dart:ui` implementation. No helper imports them. `canvas_ui.dart` re-exports
  `UiCanvasGradient`, `UiCanvasPattern`, `UiImageSource`, `CanvasFont` and `parseCanvasFont`. The
  other names stay in their files.
- `MockContext` of `packages/chartjs_test_utils` is the recorder implementation for the specs.

A member arrives when a ported caller or the mock needs it. The interface has the 24 methods and
9 setters of the mock. It also has `ellipse`, `resetTransform`, `drawImage`, `scale`,
`globalAlpha`, `createLinearGradient`, `createRadialGradient`, `createConicGradient`,
`createPattern` and `direction`, which upstream source calls. `CanvasGradient` has
`addColorStop(offset, color)`. Style properties are nullable. A null read occurs only on the mock
context. A setter ignores `null` and each value that the DOM ignores: a non-finite or negative
line width, an unknown keyword, a font that does not parse.

`Path2D` records `PathCommand`s. `replay(target)` plays them onto another `CanvasPath`. Its
`version` changes on each command. Its `cache` slot holds the `ui.Path` of the `dart:ui` layer.

### 2. Canvas element

`UiCanvasElement implements HTMLCanvasElement, CanvasNode`:
- `width` and `height` are `int` device pixels. The start size is 300 x 150, the DOM default. A
  write resets the context state and clears the bitmap, also with the same value.
- `style` is a map-backed `CSSStyleDeclaration`. It ignores a priority other than `''`, `null`
  and `'important'`.
- `getContext('2d')` and `getContext2d()` give the one `UiCanvasContext` of the element. Other
  context ids give `null`.
- The element has the `width` and `height` attributes of the DOM, with `getAttribute`,
  `setAttribute` and `removeAttribute`. `initCanvas` and `releaseContext` use them
  ([Chart.js ADR 0014](0014-input-events-and-chart-host.md), section 5). A size at creation is an
  attribute. A `null` size has no attribute and the DOM default. A write of `width` or `height`
  sets the attribute, as the DOM reflects the property. `setAttribute` parses a non-negative
  integer. A value that does not parse gives the default size. `removeAttribute` gives the
  default size. Both reset the context. Other attribute names give `null` and do nothing.
- `parentNode` is the container of the host that shows the canvas, or `null`.
- `toImageSource()` gives a snapshot of the bitmap as a `UiImageSource` (section 7).

### 3. Container interfaces

`helpers.dom.ts` and `platform.dom.js` read the DOM `parentNode` of the canvas and its size. The
port adds two port-only interfaces to `canvas.dart`:
- `CanvasNode.parentNode` gives a `CanvasContainer` or `null`. A canvas that does not implement
  `CanvasNode` has no parent node. `getParentNode` of `helpers.dom.dart` gives `null` for it.
- `CanvasContainer.contentWidth` and `contentHeight` are the content box of the container, in
  logical pixels. A chart host gives the max sizes of its incoming constraints, and
  `double.infinity` for an unbounded side.
- `CanvasContainer.isConnected` is the test of `isAttached` (`platform.dom.js:386-387`). A chart
  host gives `true` when its render object is attached and laid out.

`HTMLCanvasElement` does not get a container member. Thus the mock canvas and other implementers
of `HTMLCanvasElement` do not change. The `differences.md` row `platform-dom-container` records the
difference. [Chart.js ADR 0014](0014-input-events-and-chart-host.md) gives the host.

### 4. Retained bitmap of pictures

`UiCanvasContext` keeps the bitmap as `ui.Picture`s:
- Draw calls record into a `ui.PictureRecorder`. The context starts a recording at the first draw
  after a paint. A new recording replays the saved states and their clips.
- The content of the canvas is the list of pictures since the last full clear.
- A full clear drops the list. A full clear is a `clearRect` that covers the whole bitmap under an
  axis-aligned transform, with no clip. `clearCanvas` makes a full clear at the start of each
  chart render. Thus a chart frame is one picture.
- A partial `clearRect` draws with `BlendMode.clear`. A composite operation other than
  `source-over` blends with the content. After either one, `paint` draws the pictures inside a
  `saveLayer`. Thus the clear does not reach the pixels below the canvas.
- `paint(ui.Canvas, ui.Offset, scaleX, scaleY)` ends the current recording, applies the scale of
  the host and clips to the bitmap. When more than
  8 pictures accumulate without a full clear, `paint` rasterizes the content one time with
  `toImageSync`, at the bitmap size. The result replaces the list. Thus memory stays bounded.
- `onChanged` tells the host that the content changed. It fires one time until the next `paint`.
  The host then calls `markNeedsPaint`.
- `isEmpty`, `dispose()` and the `@visibleForTesting` member `debugPictureCount` complete the
  port-only API.

### 5. Bitmap space and the device pixel ratio

The pictures are in bitmap space: the device pixels of the DOM bitmap. The recording has no base
scale. `paint` applies the scale that the host gives and clips to the bitmap rectangle. The host
gives the display size divided by the bitmap size. After `retinaScale`, this scale is `1 / DPR`.
- `retinaScale` stays a line-by-line port. It sets the bitmap to the device size and calls
  `setTransform(dpr, 0, 0, dpr, 0, 0)`. Thus the net transform is the identity in logical pixels.
  `clearCanvas` and the clip rectangles map onto the box.
- The content keeps its bitmap pixels across a DPR change, as a DOM bitmap does. It shows at the
  same logical size until the chart draws it again.
- The host stretches the bitmap to the display size of the canvas, as the DOM does
  ([Chart.js ADR 0014](0014-input-events-and-chart-host.md), section 5). It gives `paint` one
  scale for each axis. The canvas has no DPR.
- The flatten step and `toImageSource()` share one rasterization. It needs no DPR scale.

This decision replaces the base scale of porting-flow.md §2.2. It gives the same pixels for a
chart that calls `retinaScale`. It also gives the correct size for content that the code drew at
another DPR, or before the host attached.

### 6. Path semantics

`UiPathBuilder` (`canvas_ui_path.dart`) is a `CanvasPath` that builds a `ui.Path` in bitmap space.
`UiTransform` is the current transform matrix, with the flags axis-aligned, similarity and
invertible.
- The transform applies when the code adds a point.
- The current path is outside `save()` and `restore()`. The clip is part of the state.
- A non-finite argument does nothing. Under a transform that is not invertible, path methods and
  draws do nothing, as in Chromium.
- `arc`, `arcTo` and `ellipse` with a negative radius throw a `RangeError` for the DOM
  `IndexSizeError`.
- `arc` connects the current point to its start with a line. `lineTo` and the curves on an empty
  path start a subpath at their first point. `closePath` starts a new subpath at the start point.
- An arc uses `ui.Path.arcTo` when the transform keeps it a circle (a similarity, also with a
  reflection) or keeps an unrotated ellipse axis-aligned. Under other transforms, the arc is
  cubic Béziers of 90 degrees or less. A sweep of 2π or more is two half arcs.
  `canvasArcSweep` makes the angles canonical, as Chromium does. A full circle on an empty path
  under a similarity transform first stays a pending circle (section 8). It becomes the two half
  arcs when a later command or a read of the path needs them.
- `arcTo` is the tangent arc of the DOM.
- The fill rule `'evenodd'` is `PathFillType.evenOdd`. An unknown fill rule makes `fill` and
  `clip` do nothing. The DOM throws a `TypeError`.
- `uiPathOf` caches the user-space `ui.Path` of a `Path2D` in its `cache` slot, keyed by its
  `version`.

### 7. Paint, styles and images

- **Strokes.** Under a similarity transform, a stroke draws the bitmap-space path with
  `lineWidth` times the scale. The dash scales the same way. Under other transforms, the layer
  maps the path back to user space with the inverse matrix and draws it under `canvas.transform`.
  A `Path2D` always draws in user space under `canvas.transform`.
- **Line dash.** `dashPath` uses `PathMetric.extractPath`, the standard Flutter recipe, with
  `lineDashOffset`. The pattern starts again at each subpath, as in the DOM and in Skia.
- **Colors.** CSS color strings parse with the ported @kurkle/color (`lib/src/kurkle_color/`),
  with a cache of 512 entries. The context ignores an invalid color, as the DOM does. A read gives
  `#rrggbb`, or `rgba(r, g, b, a)` when the alpha is not 1.
- **Gradients.** `UiCanvasGradient` is linear, radial (two-point conical) or conic. `addColorStop`
  throws a `RangeError` for an offset outside [0, 1] and a `FormatException` for a bad color. The
  shader is made at draw time with the transform of the draw, because the DOM takes gradient
  coordinates in the user space at fill time. The shader is cached for each matrix. A radial
  gradient with both centers at (0, 0) and `r0 > 0` is made at (1, 1) with a matrix that moves it
  back, because the engine asserts on that case. A conic gradient is a sweep gradient, rotated by
  its start angle around its center. `createRadialGradient` with a negative radius throws a
  `RangeError`.
- **Patterns.** `UiCanvasPattern` is a `ui.ImageShader` with repeated or decal tile modes. A null
  or empty repetition is `'repeat'`. An unknown repetition throws a `FormatException`.
- **Alpha and composite.** `globalAlpha` multiplies the paint alpha.
  `globalCompositeOperation` maps the DOM names that have a `ui.BlendMode`. The context ignores the
  other names.
- **Images.** `UiImageSource(ui.Image)` is the `CanvasImageSource` of `drawImage` and
  `createPattern`. `createPattern` gives `null` for another source. The DOM also takes a canvas
  element there. `HTMLCanvasElement` cannot implement `CanvasImageSource`, because its `width` is
  an `int` and the image width is a `double`. Thus `UiCanvasElement.toImageSource()` gives a
  snapshot of the bitmap, as the DOM reads the bitmap at the call. The caller owns the image. A
  canvas without pixels throws a `StateError` for the DOM `InvalidStateError`.

### 8. Cost

The layer reuses the fill, stroke, image and clear `Paint` objects. It keeps a pool of states for
`save()` and `restore()`. A path that is one rectangle fills with `drawRect` and clips with
`clipRect`. The layer computes a shader matrix only for gradients and patterns.

A path that is one full circle on an empty path under a similarity transform stays pending
(`UiPathBuilder.singleCircle`): fill draws it with `drawCircle` and an undashed stroke with
`drawCircle`. A later path command or a read of the path makes it a `ui.Path`. A chart draws most
points as one full circle (`drawPointLegend`, `helpers.canvas.ts:200-207`). In the stress demo,
this path cut the raster time by 3 to 4 times ([performance.md](../performance.md)).

The text layer disposes the paragraph that its LRU cache evicts, and `fillText` and `strokeText`
dispose the uncached paragraph of a gradient or pattern text after the draw. A recorded picture
keeps its own reference to the painted text ([Chart.js ADR 0015](0015-text.md), section 2).

#### 8.1 Circle batch

`CircleBatch` (`canvas_ui_batch.dart`, port-only) draws a run of full circles with one
`drawRawAtlas` call.
- **Why.** A chart draws most points as one full circle with a fill and a stroke
  (`drawPointLegend`, `helpers.canvas.ts:200-207` and `:303-306`). Each fill and each stroke is one
  native `drawCircle` call. On a Pixel 8a, the native recording of these calls was about half of
  the frame. At 20000 points, the frame rate was 11.4 FPS.
- **The run.** The batch keeps consecutive full-circle fills and strokes with one radius, one fill
  color, and one stroke color and width, in bitmap space. A fill or a stroke that does not match
  draws the run first and starts a new run.
- **Which draws join.** `fill()` and the undashed `stroke()` of a pending full circle (section 8)
  join the batch only for a plain color with the `srcOver` blend mode. A shader (a gradient or a
  pattern), a dash or another composite operation draws directly. The color is multiplied by
  `globalAlpha`, as for a direct draw. A `globalAlpha` of 0 draws nothing.
- **The sub-pixel atlas.** The atlas image holds the filled circle and the stroked circle, each at
  4 x 4 sub-pixel offsets inside its pixel. Each instance takes the sprite of its kind and its
  offset, and draws it at a whole pixel of the bitmap. The instances keep the order of the calls
  (fill 1, stroke 1, fill 2, and so on). Thus the paint order of overlapping points is the order
  of the separate draws.
- **The sampling.** The atlas samples bilinearly. Where a whole bitmap pixel is a whole device
  pixel, each sample is one texel, so no sprite is resampled. A host at a fractional device pixel
  (a layout offset times a ratio of 2.625) or under a scale (a page transition) resamples the
  sprites, as it resamples the vector content, and the centers stay in place. Nearest sampling
  moved them by up to 1/2 pixel there.
- **The bounds.** A run of fewer than 16 circles draws each circle with `drawCircle`, so that a
  few circles make no sprite. An outer radius (the radius plus half the line width of a stroke)
  above 48 bitmap pixels, a bubble or a wide border, does not join the batch. Its sprite would be
  large, and a chart draws few of them. A center beyond 2^23 bitmap pixels does not join the
  batch either: the atlas transforms are float32. A center of NaN (a transform that overflowed)
  draws nothing, with or without the batch. One `drawRawAtlas` call takes at most 512 instances.
  A longer run draws with several calls, in order. Skwasm (dart2wasm) copies the transforms and
  the rects of a call to the stack of its WebAssembly module, 32 bytes for each instance. A call
  of 10000 instances overflowed that stack and corrupted the heap of the renderer (`memory access
  out of bounds`). 512 instances take 16 KB. The sprite cache holds 32 atlas
  images, with the least recently used image evicted first. It disposes the image that it evicts.
  A recorded picture keeps its own reference to the image.
- **The flush points.** Each other access to the recording canvas draws the run first: each other
  draw, `save()`, `restore()`, a clip and the end of a recording (`paint` and
  `toImageSource()`). A full clear drops the run without a draw, as it drops the pictures.
- **The difference.** The center of a circle moves to the nearest quarter pixel, at most 1/8
  pixel. The antialiased edge pixels differ from the separate draws by at most 46 of 255 in one
  channel. One sprite with bilinear sampling gave 76 of 255. This is a display-only difference:
  the ticks, the hit element, the item order, the resolved options and the throws do not change
  ([Chart.js ADR 0009](0009-no-display-only-js-exactness.md)). Thus it gets no `DIVERGES` row.

### 9. No Chromium geometry

The layer has no Chromium-exact `arcTo` or arc sweep math and no pixel matching
([Chart.js ADR 0009](0009-no-display-only-js-exactness.md)).

## Alternatives considered

- **A base `scale(1 / dpr)` at record time** (porting-flow.md §2.2 and the first phase 3 code).
  Rejected. The host cannot show content that the code drew at another DPR, or before the host
  attached, at the correct size. A wasm run on a DPR 2 screen showed it at 2 times its size,
  cropped.
- **No retained bitmap: draw the chart again in each paint.** Rejected. Chart.js draws only on a
  render, and the DOM keeps the bitmap between renders. Each Flutter paint would then run the
  chart draw code.
- **`toImageSync` after each draw.** Rejected. It rasterizes on each chart render. The picture list
  rasterizes only above the flatten bound.
- **One `drawPoints` call for all fills, then one for all strokes.** Rejected. It draws all fills
  before all strokes. That changes the paint order of overlapping points.
- **One sprite for each circle kind, drawn with bilinear sampling.** Rejected. The resampled edge
  differs from the separate draws by up to 76 of 255 in one channel. The sub-pixel atlas of
  section 8.1 gives at most 46 of 255.
- **A container member on `HTMLCanvasElement`.** Rejected. It changes each implementer of the
  interface, also the mock canvas of the harness.
- **`createPattern` and `drawImage` that take a canvas element.** Rejected. The interface keeps
  the `CanvasImageSource` parameter, and `HTMLCanvasElement` cannot implement it. A snapshot is
  what the DOM reads at the call.

## Consequences

- `helpers.canvas`, `helpers.options` and `helpers.curve` stay pure layers. Their specs run with
  `MockContext` on the VM, dart2js and dart2wasm.
- A chart frame is one picture. Memory stays bounded, also when the code never clears the canvas.
- A composite operation whose DOM effect reaches outside the shape (`source-in`, `copy`,
  `destination-in`, `destination-atop` and others) changes only the pixels that the shape covers.
  `dart:ui` draws only the coverage of the shape. Chart.js core does not use these operations.
- An unknown fill rule does nothing, where the DOM throws a `TypeError`.
- After a DPR change, the old content shows at the same logical size until the chart draws it
  again. The throttled resize of [Chart.js ADR 0014](0014-input-events-and-chart-host.md) draws it
  in the next frame.
- A caller that passes a canvas to `createPattern` or `drawImage` calls `toImageSource()` first.
  The `helpers.color` spec does this for its pattern case.
- The widget test of porting-flow.md §2.2 with a DPR other than 1 is in
  `test/port/platform/chart_host_test.dart`.

## Evidence

- `test/port/canvas/canvas_ui_test.dart` (92 tests, `flutter test`) probes the pixels of rendered
  images and reads the state. It covers the element reset, the attributes (the group
  'attributes'), the transform at point-add time, the stroke scale, skew strokes, non-finite
  arguments, a singular transform, the path outside `save()` and `restore()`, the paint scale of
  the host (the group 'paint maps the bitmap pixels with the given scale': `1 / DPR` after
  `retinaScale`, the content in bitmap pixels at another scale, a scale for each axis), the full
  and partial clears, the clip across recordings, the arc cases, the group
  "a full circle on an empty path" (fill and stroke as a circle, later commands that extend the
  same path, an evenodd ring of two circles, a dashed circle, a reflected transform), `Path2D`,
  the gradients in user space at fill time, patterns, `drawImage`, `toImageSource`, the line dash,
  the composite operation, `onChanged`, the flatten step and `dispose`. The later cases are
  "a sweep just under a full turn fills a circle", "zero-length dashes draw the caps as dots",
  "setLineDash keeps the value when it does not change", the group "a gradient or a pattern is in
  user space" (gradient and pattern text) and "a disposed paragraph still paints in the
  recording".
- The group "circle batch" of `test/port/canvas/canvas_ui_test.dart` (28 tests) pins section 8.1.
  "gives the pixels of the separate draws" compares a batch with the separate `drawCircle` calls at
  the exact centers. The largest channel difference is 46 of 255, on edge pixels. The test fails
  at 64 or more, and it checks the color at each center. The other pixel tests compare with
  `drawCircle` calls at the centers that the batch takes (the nearest quarter pixel). They differ
  by at most 7 of 255 and fail above 8. The tests pin the order of fills and strokes, the
  flush points (a later draw, `save`, a clip, `restore`, `toImageSource()`, `paint`, the flatten
  step, a partial clear and a composite operation), a full clear, `dispose` and a width reset that
  drop a run, the draws that do not join (a dash, `Path2D`, a zero radius, a wide stroke), the run
  splits (a transform, `globalAlpha`, the style, the radius and the line width), the centers out
  of range and of NaN, negative and fractional centers, 3000 points, a DPR of 2.625, the
  eviction of a sprite that a picture still uses, and the centers under a host transform (at most
  0.2 pixel from the reference).
- `test/port/canvas/canvas_test.dart` (5 tests) tests the pure `Path2D` on the VM, dart2js and
  dart2wasm.
- `test/port/platform/chart_host_test.dart` renders a host at DPR 2 with content that the code drew
  at DPR 1. It checks the pixels. This test pins the bitmap space of section 5. The group 'display
  size and bitmap stretch' of the same file pins the scale that the host gives to `paint`
  ([Chart.js ADR 0014](0014-input-events-and-chart-host.md), Evidence).
- The specs: `helpers.canvas.tests.js` passes 12 of 14 cases, and the other 2 call `acquireChart`.
  `helpers.color.tests.js` passes 4 of 4 cases with a real gradient and pattern.
- A wasm build (`flutter build web --wasm`) of an entry that imports `canvas_ui.dart`,
  `chart_host.dart`, `platform/index.dart` and `helpers/index.dart` ran in a browser. It showed
  the gradient, the dashed arc and the text at the correct size, with no console errors. The
  gallery also builds for wasm (`gallery:build:web`).
- A local micro-benchmark (debug JIT in `flutter test`, DPR 2, 1600 x 1200) ran a chart-like frame
  in about 1.5 ms: a clear, a clip, 1000 bars with fill and stroke, 50 rotated labels, 10 grid
  lines, one arc and the paint.
- [performance.md](../performance.md) records the profile builds of the gallery stress demo on
  macOS and in Chrome (dart2wasm and skwasm), before and after the full-circle path.
- [performance.md](../performance.md), section 4, records the circle batch on a Pixel 8a (Android
  17, Impeller on Vulkan, profile build, display at 60 Hz). At 20000 points, the frame rate went
  from 11.4 to 55.2 FPS, the draw time from 42.1 to 11.4 ms and the raster time from 82.7 to
  9.8 ms. At 5000 points and 50 labels, the frame rate went from 30.4 to 58.9 FPS. A plain
  Flutter `CustomPainter` with two `drawCircle` calls for each point gave 13.6 FPS at 20000
  points, and an HTML canvas 2D in Chrome on the same phone gave 26.4 FPS.
- Before the batch, the CPU profile on the phone had about half of the frame in the native
  `drawCircle` recording. After the batch, the Dart path of the canvas layer is the largest part,
  about 0.35 microseconds for each point.

## Open

- [Chart.js ADR 0009](0009-no-display-only-js-exactness.md), decision 3, lists "The `dart:ui`
  context has the DPR base scale." Section 5 of this ADR replaces that base scale with the bitmap
  space. An accepted ADR does not change. Before they accept this ADR, the maintainers decide if a
  new ADR supersedes Chart.js ADR 0009 with that item changed.
- No test suite runs the `dart:ui` layer on the web renderers (CanvasKit, skwasm) or on a device.
  The tests of `canvas_ui.dart` have `@TestOn('vm')`. Only the wasm smoke run of the Evidence
  section covers the web.
- A DPR change on a real device is not verified.
