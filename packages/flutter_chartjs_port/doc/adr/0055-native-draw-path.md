# Chart.js ADR 0055: The native draw path of the canvas layer

- Status: proposed. It waits for the night series CV of
  [canvas-cuts-plan.md](../canvas-cuts-plan.md) §7.6: the rule ACCEPT on both deciding platforms
  (macOS AOT and the dedicated Chrome with dart2wasm) and the raster check. A form of section 8
  (N1 to N5) that the night rejects goes out of the tree and out of this ADR before the acceptance.
  The other forms stay. On acceptance, this ADR supersedes Chart.js ADR 0013.
- Date: 2026-10-30
- Supersedes (on acceptance): [Chart.js ADR 0013](0013-canvas-model.md)
- Related: [Chart.js ADR 0015](0015-text.md) (canvas text),
  [Chart.js ADR 0022](0022-chart-test-harness.md) §4 (the canvas attributes),
  [Chart.js ADR 0034](0034-no-display-only-js-exactness.md) (no display-only JS exactness; it
  supersedes Chart.js ADR 0009, which Chart.js ADR 0013 cites),
  [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md) (the chart host; it supersedes
  Chart.js ADR 0014), [Chart.js ADR 0048](0048-entry-points-and-public-library.md) §8
  (`toDataURL`), [canvas-cuts-plan.md](../canvas-cuts-plan.md) §7 (the design and the night),
  [performance.md](../performance.md) §4, §5.4, §8.4, §13.6, §13.7 and §14.9,
  [differences.md](../differences.md) rows `adapt-rounded-rect-path` and `adapt-bar-clip`,
  [porting-flow.md](../porting-flow.md) §1.1 (the performance rule) and §2.2

## Context

### The decision of the maintainer

The draw of the port is slower than the draw of Chart.js for arcs, for circles with one paint for
each item and at the end of the bar recording. In the same browser, the frame of the port is a
median 1.93 times Chart.js ([performance.md](../performance.md) §14.9, P3). The typed internal
model of phase 10 removes the update cost, but not this draw cost. On 2026-10-30 the maintainer
decided that a sixth agent works on the native draw path of `lib/src/canvas/`, in parallel with
the agents of the typed model, with its own A/B in the same measurement night. The maintainer
wants the native forms of `dart:ui` and no layer on top of a layer. This decision brought
canvas-cuts-plan.md forward (its §7).

### The draw cells

On the Pixel 8a ([performance.md](../performance.md) §13.6), `(draw + end) / upstream draw` is
2.16 to 3.41 for the doughnut, pie and polar area draws, 4.86 to 8.02 for the `chart.c` draw (two
colors that alternate) and 7.63 to 8.80 for the bubble draw (a radius for each item). The bar draw
is 1.41 to 2.97 after `bar-ring-zero-inner`, because the end of its recording takes 5.4 ms at 1000
bars. In the doughnut draw at 1000 arcs, the `drawPath` FFI has 36.8 % and `_NativePath._arcTo`
24.2 % of the samples ([performance.md](../performance.md) §13.7 item 11). Cut 1 of
canvas-cuts-plan.md keeps the arc path of a similarity transform, so it does not reach these
cells.

### What Chart.js ADR 0013 decided

Chart.js ADR 0013 decided the canvas layer: the interface, the canvas element, the container
interfaces, the retained bitmap, the bitmap space, the path semantics, the paint, the cost
(the pending full circle and the circle batch) and no Chromium geometry. Later decisions added to
the layer and stay valid: the canvas attributes and the reflection of the `style` attribute
(Chart.js ADR 0022 §4), `toDataURL` (Chart.js ADR 0048 §8), the rounded rectangle fast paths and
the ring of a bar ([differences.md](../differences.md) `adapt-rounded-rect-path`, porting-flow.md
§1.1) and the sole shape of a pair (`bar-ring-zero-inner`, [performance.md](../performance.md)
§13.6). This ADR states the complete decision with these parts and the native forms N1 to N5.

## Decision

### 1. Layers

The canvas layer lives in `lib/src/canvas/`. All its files are port-only.
- `canvas.dart` is a pure layer. It declares the interfaces `CanvasPath`,
  `CanvasRenderingContext2D`, `HTMLCanvasElement`, `CSSStyleDeclaration`, `TextMetrics`,
  `CanvasImageSource`, `CanvasNode` and `CanvasContainer`, the typedef `CanvasFillRule`, and the
  concrete class `Path2D`. It re-exports `CanvasGradient` and `CanvasPattern` of
  `lib/src/types/color.dart`. The names and the argument order are the DOM names and order.
- `canvas_ui.dart`, `canvas_ui_path.dart`, `canvas_ui_paint.dart`, `canvas_ui_text.dart` and
  `canvas_ui_batch.dart` are the `dart:ui` implementation. No helper imports them.
- `MockContext` of `packages/chartjs_test_utils` is the recorder implementation for the specs.

A member arrives when a ported caller or the mock needs it. The interface has the 24 methods and 9
setters of the mock, the members that upstream source calls (`ellipse`, `resetTransform`,
`drawImage`, `scale`, `globalAlpha`, the gradient and pattern factories, `direction`) and the
port-only `roundRect` of `addRoundedRectPath`. Style properties are nullable. A setter ignores
`null` and each value that the DOM ignores. `Path2D` records `PathCommand`s, replays them onto
another `CanvasPath`, and has a `version` and a `cache` slot for the `ui.Path` of the `dart:ui`
layer.

### 2. Canvas element

`UiCanvasElement implements HTMLCanvasElement, CanvasNode`:
- `width` and `height` are `int` device pixels, 300 x 150 by default. A write resets the context
  state and clears the bitmap, also with the same value.
- `style` is a map-backed `CSSStyleDeclaration`. The `style` attribute reflects it (Chart.js ADR
  0022 §4).
- `getContext('2d')` and `getContext2d()` give the one `UiCanvasContext` of the element.
- The element has the `width` and `height` attributes of the DOM, with `getAttribute`,
  `setAttribute` and `removeAttribute`, for `initCanvas` and `releaseContext`. Another attribute
  keeps its value as a string.
- `parentNode` is the container of the host that shows the canvas, or `null`.
- `toImageSource()` gives a snapshot of the bitmap as a `UiImageSource`. `toDataURL` gives a
  Future of the PNG data URL of that snapshot (Chart.js ADR 0048 §8).

### 3. Container interfaces

`CanvasNode.parentNode` gives a `CanvasContainer` or `null`. `CanvasContainer.contentWidth` and
`contentHeight` are the content box of the container in logical pixels (`double.infinity` for an
unbounded side), and `isConnected` is the test of `isAttached`. `HTMLCanvasElement` gets no
container member (the row `platform-dom-container`). The chart host is the decision of Chart.js
ADR 0037.

### 4. Retained bitmap of pictures

`UiCanvasContext` keeps the bitmap as `ui.Picture`s:
- Draw calls record into a `ui.PictureRecorder`. The context starts a recording at the first draw
  after a paint. A new recording replays the clips of the saved states (section 8.3).
- The content of the canvas is the list of pictures since the last full clear: a `clearRect` that
  covers the whole bitmap under an axis-aligned transform, with no clip. `clearCanvas` makes one at
  the start of each chart render, so a chart frame is one picture.
- A partial `clearRect` draws with `BlendMode.clear`. A composite operation other than
  `source-over` blends with the content. After either one, `paint` draws the pictures inside a
  `saveLayer`.
- `paint(ui.Canvas, ui.Offset, scaleX, scaleY)` ends the current recording, applies the scale of
  the host and clips to the bitmap. Above 8 pictures without a full clear, `paint` rasterizes the
  content one time with `toImageSync`.
- `onChanged` fires one time until the next `paint`. `isEmpty`, `dispose()` and the
  `@visibleForTesting` members complete the port-only API.

### 5. Bitmap space and the device pixel ratio

The pictures are in bitmap space: the device pixels of the DOM bitmap. The recording has no base
scale. `paint` applies the scale that the host gives (the display size over the bitmap size,
`1 / DPR` after `retinaScale`) and clips to the bitmap. `retinaScale` stays a line-by-line port.
The content keeps its bitmap pixels across a DPR change, as a DOM bitmap does.

### 6. Path semantics

`UiPathBuilder` (`canvas_ui_path.dart`) is a `CanvasPath` that builds a `ui.Path` in bitmap space.
`UiTransform` is the current transform, with the flags axis-aligned, similarity and invertible.
- The transform applies when the code adds a point. The current path is outside `save()` and
  `restore()`. The clip is part of the state.
- A non-finite argument does nothing. Under a transform that is not invertible, path methods and
  draws do nothing. `arc`, `arcTo` and `ellipse` with a negative radius throw a `RangeError`.
- `arc` connects the current point to its start with a line. `lineTo` and the curves on an empty
  path start a subpath at their first point. `closePath` starts a new subpath at the start point.
- An arc uses `ui.Path.arcTo` when the transform keeps it a circle or keeps an unrotated ellipse
  axis-aligned, else cubic Béziers of 90 degrees or less. A sweep of more than half a turn is two
  half arcs. `canvasArcSweep` makes the angles canonical, as Chromium does. `arcTo` is the tangent
  arc of the DOM.
- `roundRect` follows `roundRectGeometry`. Under an axis-aligned transform it adds one
  `ui.Path.addRRect` when the path goes clockwise in bitmap space, else the HTML segments.
- `'evenodd'` is `PathFillType.evenOdd`. An unknown fill rule makes `fill` and `clip` do nothing.
- `uiPathOf` caches the user-space `ui.Path` of a `Path2D`, keyed by its `version`.
- **The deferred commands (N3).** The builder keeps the first 32 commands of a path
  (`deferredPathCommands`) in a typed buffer: their codes, their numbers in bitmap space and the
  `ui.RRect` of an `addRRect`. The first read of `path`, or a 33rd command, builds the `ui.Path`
  with the calls of an eager build, in the same order and with the same values, and the later
  commands of the path go to it directly. An arc keeps its center and radii; its oval is
  `Rect.fromLTRB(cx - r, cy - r, cx + r, cy + r)`, the four values of `Rect.fromCircle`.
  `beginPath()` resets the `ui.Path` only when it has commands.
- **The current point on an arc (N3).** The current point and the start of the subpath are
  `_PathPoint`s. A point on an arc keeps the arc (its center, radii and angle) and gets its
  coordinates at the first read, with the expression of an eager build. Only the DOM `arcTo` reads
  them.
- **The pending full circle.** One full circle on an empty path under a similarity transform stays
  pending (`singleCircle`). A later command or a read of the path adds it as two half arcs.

### 7. Paint, styles and images

- **Strokes.** Under a similarity transform, a stroke draws the bitmap-space path with `lineWidth`
  times the scale, and the dash scales the same way. Under other transforms, the layer maps the
  path back to user space and draws it under `canvas.transform`. A `Path2D` draws in user space.
- **Line dash.** `dashPath` uses `PathMetric.extractPath` with `lineDashOffset`. The pattern
  starts again at each subpath.
- **Colors.** CSS color strings parse with the ported @kurkle/color, with a cache. An invalid
  color does nothing. A read gives `#rrggbb` or `rgba(r, g, b, a)`.
- **Gradients and patterns.** `UiCanvasGradient` (linear, radial, conic) makes its shader at draw
  time with the transform of the draw, cached for each matrix. `UiCanvasPattern` is a
  `ui.ImageShader` with repeated or decal tile modes.
- **Alpha and composite.** `globalAlpha` multiplies the paint alpha. `globalCompositeOperation`
  maps the DOM names that have a `ui.BlendMode`.
- **Images.** `UiImageSource(ui.Image)` is the `CanvasImageSource` of `drawImage` and
  `createPattern`.

### 8. Cost and the native forms

The layer reuses its paints and keeps a pool of states. It computes a shader matrix only for
gradients and patterns. It gives `dart:ui` the fewest native calls that give the Canvas 2D
result. The canvas calls of the ported code do not change, so the recorded calls of the specs and
of the reference tests do not change.

#### 8.1 The fast paths of fill and clip

`fill()` of the current path takes the first form that fits:
- one rectangle: `drawRect`; one full circle: `drawCircle` or the circle batch (section 8.5); one
  rounded rectangle: `drawRRect`;
- two rectangles or rounded rectangles where one has no area: the other alone (`_soleShape`);
- the even-odd fill of two shapes, one inside the other (`rrectContains`): `drawDRRect`;
- **a circular sector (N4):** `drawArc`;
- else `drawPath`.

**No draw for no area (N2).** A rectangle, a rounded rectangle or a sole shape with no area makes
no draw call. The fill still starts the recording and marks the content as drawn. Chromium, Skia
and Impeller give such a fill no pixel.

**The sector (N4).** `UiPathBuilder.singleSector` reads the deferred commands of one subpath:
moves at the start only, lines, circular arcs and a close at the end only. Arcs on one circle that
go on from each other in one direction make one arc group. A point within 1e-6 bitmap pixels of the
end of the item before it, or of the start of the arc after it, adds no line and is dropped, also
across the close. The rest is a sector when it is:
- one arc group with 0 < |sweep| < 2π and one point at its center: a wedge (the arc of a pie or a
  polar area, `element.arc.ts:230-286`, where the inner arcs have NaN angles and add nothing);
- two arc groups on one center with two radii, where the second group starts at the end angle of
  the first and goes back over its sweep, each within 1e-9 radians: a ring sector (the arc of a
  doughnut).

Both shapes are simple, so the nonzero and the even-odd rule fill the same pixels. The fill draws a
wedge with `drawArc(..., useCenter: true)` and the fill paint. It draws a ring sector with
`drawArc(..., useCenter: false)` on the middle circle and a stroke paint with butt caps, the width
of the ring and the color, shader and blend mode of the fill. The butt stroke of a circular arc
covers the region between its two radii and its two end angles: the region of the path. `stroke()`
and `clip()` keep the path. A path that a reader built is no sector.

`clip()` takes `clipRect` for one rectangle, `clipRRect` for one rounded rectangle, else
`clipPath`.

#### 8.2 The deferred path (N3)

Section 6 gives the rule. Thus a path that a fast path of section 8.1 draws makes no `ui.Path`
call, and a sector fill makes no `arcTo` and no `drawPath`. A polyline of more than 32 commands
builds its path at the 33rd command, with the calls of today.

#### 8.3 The native save (N1)

The recording canvas has a save for a state only when the state has a clip of its own: its clip
list is not the list of the state below it. The first clip of a saved state makes its native save.
`restore()` of a state with a clip of its own draws the pending circles and restores the native
canvas. `save()`, and `restore()` of a state with no clip of its own, do not touch the native
canvas and do not draw the pending circles. A new recording replays a save and the clips only for
the levels with clips of their own. The layer maps each point through the transform when the point
is added, so a native save and restore with no clip between them change no pixel.

#### 8.4 The paragraphs

The text layer disposes the paragraph that its LRU cache evicts, and `fillText` and `strokeText`
dispose the uncached paragraph of a gradient or pattern text after the draw (Chart.js ADR 0015,
section 2).

#### 8.5 Circle batch

`CircleBatch` (`canvas_ui_batch.dart`) draws a run of full circles with one `drawRawAtlas` call.
- **The run.** The batch keeps consecutive full-circle fills and strokes with one radius and one
  stroke width, in bitmap space, with one fill color and one stroke color.
- **Several colors (N5).** A run of fewer than `minAtlasRun` (16) circles that meets a fill or a
  stroke of another color goes on with a color for each instance, and then takes any color. Such a
  run draws white sprites, and `drawRawAtlas` multiplies each one by the color of its instance
  (`BlendMode.modulate`): white times a color is the color. Below 16 circles, it draws each circle
  with `drawCircle` in its color. A run of 16 circles or more of one color that meets another
  color draws first and starts a new run, with its colored sprites.
- **Which draws join.** `fill()` and the undashed `stroke()` of a pending full circle join the
  batch for a plain color with the `srcOver` blend mode. The color is multiplied by
  `globalAlpha`. A shader, a dash or another composite operation draws directly.
- **The sub-pixel atlas.** The atlas holds the filled and the stroked circle at 4 x 4 sub-pixel
  offsets. Each instance takes the sprite of its kind and offset and draws at a whole pixel. The
  instances keep the order of the calls. The atlas samples bilinearly.
- **The bounds.** A run of fewer than 16 circles draws with `drawCircle`. An outer radius above 48
  bitmap pixels or a center beyond 2^23 bitmap pixels does not join. A center of NaN draws
  nothing. One `drawRawAtlas` call takes at most 512 instances (the stack of skwasm). The sprite
  cache holds 32 atlas images and disposes the image that it evicts.
- **The flush points.** Each other draw, a clip, the `restore()` of a state with a clip of its own
  and the end of a recording (`paint`, `toImageSource()`) draw the run first. `save()`, and the
  `restore()` of a state with no clip of its own, do not (N1). A full clear drops the run.
- **The difference.** A center moves to the nearest quarter pixel, at most 1/8 pixel. The edge
  pixels differ from the separate draws by at most 46 of 255 in one channel. This is display-only
  (Chart.js ADR 0034).

### 9. No Chromium geometry

The layer has no Chromium-exact `arcTo` or arc sweep math and no pixel matching (Chart.js ADR
0034). The forms of section 8 change antialiased edge pixels only.

### 10. The gate of each form

The forms N1 to N5 are performance additions (porting-flow.md §1.1). They keep the canvas calls of
the ported code, so they get no `DIVERGES` row. Each form landed as its own commit with its tests.
The night series CV of [canvas-cuts-plan.md](../canvas-cuts-plan.md) §7.6 decides them with the
rule that is written there before any run. The forms stay when both deciding platforms give
ACCEPT and the raster check passes. After a REJECT or an OPEN, the next night runs the frozen
patch of each form alone on side A for the cells that failed. A form that the rule rejects goes out
of the tree and out of this ADR before the acceptance.

## Alternatives considered

- **A base `scale(1 / dpr)` at record time.** Rejected (Chart.js ADR 0013): the host cannot show
  content that the code drew at another DPR at the correct size.
- **No retained bitmap.** Rejected (Chart.js ADR 0013): each Flutter paint would run the chart
  draw code.
- **`toImageSync` after each draw.** Rejected (Chart.js ADR 0013).
- **One `drawPoints` call for all fills, then one for all strokes** (also R4 of the plan).
  Rejected: the paint order of overlapping points changes. One paint for each call.
- **One sprite for each circle kind with bilinear sampling.** Rejected: up to 76 of 255 on edges.
- **A container member on `HTMLCanvasElement`; `createPattern` and `drawImage` that take a
  canvas.** Rejected (Chart.js ADR 0013).
- **R1: the stroke of a sector as two arcs, two lines and four bevel triangles.** Rejected: an
  overlap doubles the alpha of a border color with an alpha below 1, and edges that touch give
  antialiasing seams.
- **R2: a cache of built paths across frames, keyed by their commands.** Rejected: a hit needs the
  same geometry, and each miss keeps a new native path for each element and frame. It is a layer
  on top, with an allocation for each item.
- **R3: circles of any radius and color as feathered triangles in one `drawVertices` call.**
  Rejected: no coverage antialiasing, and more vertex data than the draws that it replaces.
- **R5: an atlas of radius classes of 1/4 pixel for bubbles.** Deferred: 0.5 MB at a DPR of 1 and
  1.3 to 5.4 MB at a DPR of 2.6 for the radii of the benchmark, and an animated radius makes a new
  atlas in each frame (Open 1).
- **R6: the bars as one atlas call of a white sprite, or as triangles.** Rejected: an
  `RSTransform` has one scale for both axes, and neither call antialiases the edges of a bar at a
  fractional pixel.
- **The colors of N5 for all runs** (`circle-batch-instance-colors`, [performance.md](../performance.md)
  §13.6). Rejected by its code A/B: the runs of one color went through the colors, and `chart.a`
  was +1.9 to +5.3 %. N5 keeps the code of a run of one color.

## Consequences

- `helpers.canvas`, `helpers.options` and `helpers.curve` stay pure layers.
- A chart frame is one picture. Memory stays bounded.
- An arc of a doughnut, a pie or a polar area fills with one `drawArc` and no `ui.Path` call. Its
  border keeps `drawPath` (Open 2).
- A bar makes no path call, no native save and restore, and at 1000 bars and more one draw call
  in place of two.
- Points with a scriptable or an indexable color draw as one atlas run.
- A pending circle and an arc compute no cosine and sine unless the DOM `arcTo` reads the current
  point.
- A composite operation whose DOM effect reaches outside the shape changes only the pixels that the
  shape covers. An unknown fill rule does nothing, where the DOM throws a `TypeError`.
- After a DPR change, the old content shows at the same logical size until the chart draws it
  again.

## Evidence

- `test/port/canvas/canvas_ui_test.dart`, `canvas_ui_round_rect_test.dart`, `canvas_test.dart`
  and `canvas_ui_text_test.dart` pin sections 1 to 8 as Chart.js ADR 0013 and the later decisions
  pinned them. They stay green with no change after N1 to N5. The group "circle batch" pins the run
  of one color and its flush points.
- `test/port/canvas/canvas_ui_native_test.dart` (29 tests) pins N1 to N5:
  - N1 (5 tests): a circle run across a save and a restore with no clip; a clip in a nested state
    until its restore; a new recording in nested states; a restore without a save; a resize in a
    nested state. The pixels equal plain `dart:ui` draws.
  - N2 (3 tests): fills with no area draw nothing and still count as drawn content; the ring and
    the inner fill of a bar of 0.6 pixels give the pixels of `fillRect`.
  - N3 (7 tests): the deferred path of each kind of command, under the identity, a similarity, a
    non-uniform scale, a skew and a mirror, equals the path of a builder that sends each command
    directly (bounds, contour lengths and exact pixels); the pending circle; the buffer bound; the
    current point on an arc for the DOM `arcTo`; no `ui.Path` for the fast paths.
  - N4 (8 tests): the sector of the `pathArc` calls and of `ArcElement.draw`; ten paths that are
    no sector; 21 sector fills, styles (a gradient, `globalAlpha`, a rotation, a mirror, a DPR of
    2.625, a composite operation) and a doughnut of 24 arcs with borders against the same calls
    with the path built. At the device scale no pixel differs in area or flips. At four times the
    scale (the mean of 4 x 4 pixels) the worst channel differs by at most 24 of 255 and the ink by
    less than 1 %.
  - N5 (6 tests): runs of two and more colors, `globalAlpha`, the break of a long run of one
    color, a short run with `drawCircle`, a run of more than 512 instances, against `drawCircle`
    at the centers of the batch (8 of 255; 16 for `globalAlpha` 0.5, below).
- Probes on flutter_tester (Skia on the CPU, 2026-10-30): `drawArc` and the bitmap-space path of
  one ring sector differ by at most 38 of 255 on edge pixels (85 with an opaque gradient). The same
  path in user space under `Canvas.transform` differs from the bitmap-space path by 41 and 89: the
  difference is the flattening of the curves. A stroke of 1 pixel in a translucent color blends
  some edge pixels twice where the pieces of its outline meet, and an opaque white stroke clamps
  them: a white sprite times the color gives up to 13 of 255 less there than the colored sprite and
  `drawCircle`. For a fill, the white sprite times the color equals the colored sprite.
- The expected gains of [canvas-cuts-plan.md](../canvas-cuts-plan.md) §7.3 (Pixel 8a): the
  doughnut draw -24 to -31 % at N 1000, the pie and the polar area draws -20 to -26 %, the bar
  draw about -44 % with the end -50 to -75 %, and the `chart.c` draw -73 to -76 % (the measured
  A/B of `circle-batch-instance-colors`).
- The gates of each commit: `format:check`, `analyze`, `parity`, `check:port`, `test --no-select`,
  `test:cases` and `test:fixtures` with `FIXTURES_REQUIRED=1`; `test:web` before the last one.
- The figures of the night series CV come here before the acceptance.

## Open

1. **Bubble.** The bubble draw stays at about 7.6 times upstream (R5). Measure first: the share of
   `_drawDirect` at a DPR of 2.6, and the count of radius classes of real bubble charts.
2. **The stroke of a sector** keeps `drawPath`, about 1.12 µs for each arc on the Pixel 8a. No
   native form gives the bevel joins of the border with equivalent pixels (R1).
3. **The end of the bar recording.** No profile splits the end into its operations, so the
   expected gain is a range. A profile of `chart.bar` draw after the night gives it.
4. **The web.** No repository suite runs the `dart:ui` layer on the web renderers. `drawArc` and
   `drawRawAtlas` with colors exist in skwasm and CanvasKit. The browser runs of the night are the
   first check of the forms there.
5. **A DPR change on a real device is not verified** (Chart.js ADR 0013, Open).
