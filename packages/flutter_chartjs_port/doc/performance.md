# Performance of the canvas layer

- Scope: the speed of the `dart:ui` canvas layer of phase 3
  ([Chart.js ADR 0013](adr/0013-canvas-model.md)) and of canvas text
  ([Chart.js ADR 0015](adr/0015-text.md)). Section 8 adds the draw cost of the phase 4 elements
  ([Chart.js ADR 0017](adr/0017-element-properties.md)). Section 9 has the A/B test of cut 2 of
  [canvas-cuts-plan.md](canvas-cuts-plan.md) in phase 5. Section 10 has the core figures of phase 5:
  the animations, a hit test, the parsed items, the profile of the chart path, the change of
  `hidden`, the acceptance of the typed options and the final series on the phones. Sections
  10.10 and 10.11 have the phase 5 work that phase 6 closed: the CPU profile of case (c) and the
  declared `$context`, which the port does not take. Section 11 has the scale figures of phase 6
  ([Chart.js ADR 0025](adr/0025-scale-value-parameters.md)), `jsAdd` and the number formatting
  guards ([Chart.js ADR 0026](adr/0026-number-formatting-on-package-intl.md)). Section 12 has the
  date figures of phase 6 ([Chart.js ADR 0024](adr/0024-dates.md)). Section 13 has the controller
  figures of phase 7, and section 13.6 the figures of step 7 on the phones. Section 14 has the
  plugin figures of phase 8 ([Chart.js ADR 0040](adr/0040-filler-targets-and-plain-points.md)),
  section 14.5 the cost of the theme palette and the plugin tokens
  ([Chart.js ADR 0042](adr/0042-theming.md)), section 14.7 the figures of step 8 and section 14.9
  the night series after the step 8 record (Chart.js ADR 0044, P3, P5 and P6).
- Date: 2026-10-22
- Related: [Chart.js ADR 0016](adr/0016-frame-scheduling.md) (frame scheduling),
  [Chart.js ADR 0034](adr/0034-no-display-only-js-exactness.md) (no display-only JS exactness).

This document records the profile builds of the gallery stress demo and the changes that they
caused. The figures are averages over the first seconds of a fresh process. The figures of
sections 2 and 3 were measured before the circle batch (section 5.4). Section 4 has the figures
before and after it.

## 1. Test bed

The Stress tab of the gallery (`apps/chartjs_gallery/lib/demo/stress_demo.dart`) draws one chart
host again in each frame. `requestAnimFrame` (`helpers.extras`) schedules each frame, as the
Chart.js animator does. Each frame draws these items:
- N moving points, each with `drawPoint` (`helpers.canvas`), point style `circle`, radius 3, with a
  fill and a stroke.
- A polyline through N points, with `lineTo` and one `stroke`.
- M labels with `renderText` (`helpers.canvas`). Each label has a fixed angle of -45 degrees, as
  the tick labels of a chart have. The `spin labels` switch (`stress.spin`, off by default) gives
  each label a new angle in each frame.

The readout shows these figures:
- **FPS**: the frames per second of the loop.
- **draw**: the Dart time of the draw calls of one frame, the recording into a `ui.Picture`.
- **raster**: the mean `FrameTiming.rasterDuration` of the last 120 frames.

A scenario is N points and M labels, for example 5000 + 50.

Phase 4 added a mode selector (`stress.mode.<mode>`). The scene above is the mode `primitives`,
the default. The other modes draw the phase 4 elements through their `draw` methods:
- `elements`: N `PointElement` objects and one `LineElement` through N point elements, with the
  colors of `primitives`, plus the M labels. At the same N and M, this mode is comparable with
  `primitives`. The line is marked as animated, so each draw builds a new `Path2D`.
- `bars`: N `BarElement` objects in a grid, with `borderWidth` 1 and `borderRadius` 4, and heights
  that move in each frame.
- `arcs`: N `ArcElement` objects as doughnuts of 2 rings of 5 slices, with `borderWidth` 2,
  `spacing` 2 and `borderRadius` 4, and angles that move in each frame.
- `chart` (phase 5): a real `Chart` of N points. The points get the typed options of the
  resolver. Section 6 gives its cases, and
  [Chart.js ADR 0021](adr/0021-typed-options-in-the-resolver.md) §8 gives its acceptance. Phases
  5 and 6 used the gallery controller `StressPointController` (commit `0e0ab93`). From phase 7,
  the mode runs the ported controller of the chart type: `line` (the default) or `scatter` on two
  hidden unit scales with the scene of phase 5, or one of the six other types
  ([Chart.js ADR 0031](adr/0031-gallery-chart-types.md) §3 and §5).
- `axes` (phase 6): the points of the mode `chart` on the real scales of phase 6
  (`apps/chartjs_gallery/lib/demo/stress_axes.dart`), from phase 7 in a `LineController` chart
  with `showLine: false`. The x axis is a linear, logarithmic,
  category or time scale. The y axis is a linear or logarithmic scale. Section 6 gives its cases.

In each frame, the demo writes the moving properties of the elements with their typed setters.
The draw time includes these writes.

## 2. Results on macOS

The machine is an Apple M3 Max with macOS. The build is a profile build. Each scenario ran in a
fresh process. These figures were measured before the circle batch (section 5.4).

### 2.1 Before the full-circle path

| Scenario | FPS | draw (ms) | raster (ms) |
|---|---:|---:|---:|
| 1000 points | 60 | not recorded | 9.1 |
| 5000 + 50 | 27.6 | 4.8 | 35.3 |
| 20000 points | 5.3 | 46 | 158 |

Each point was a `ui.Path` with two half arcs. The raster thread tessellated each path.

### 2.2 After the full-circle path

| Scenario | FPS | draw (ms) | raster (ms) |
|---|---:|---:|---:|
| 1000 + 0 | 60 | 0.9 | 2.8 |
| 1000 + 50 | 60 | 0.9 | 2.7 |
| 5000 + 50 | 60 | 3.1 | 9.5 |
| 20000 + 0 | 39.9 | 11.9 | 23.9 |
| 1000 + 200 | 60 | 1.2 | 2.7 |
| 20000 + 200 | 39.9 | 12.1 | 23.8 |

The raster time is 3 to 4 times lower. At 5000 + 50, the frame rate went from 27.6 to 60 FPS.

### 2.3 CPU profile

At 20000 points, 46 % of the CPU profile is the native `drawCircle` recording.
The Dart overhead of the canvas layer (the state, the transform and the paint set-up) is small.

### 2.4 Rotated labels

- Labels with one fixed angle cost no measurable raster time: 1000 + 200 and 1000 + 0 have the
  same raster time.
- Labels whose angle changes in each frame cost about 85 ms of raster time for 200 labels. Impeller
  renders the glyphs again for each new angle.
- A chart rotates its tick labels by one angle, which changes only when the scale fits the labels
  again. Thus the stress tab uses a fixed angle by default. The `spin labels` switch shows the
  worst case.

### 2.5 Slowdown of the idle machine

On macOS, each run slowed down about 5 times on both the UI thread and the raster thread after
about 25 to 30 seconds. The slowdown was the same for each scene, and it also occurred without
`flutter run`. The shape of the CPU profile stayed the same. The cause is the idle desktop (the
aerial wallpaper and its video decoder were active), not the port. Thus the figures above come
from the first seconds of fresh processes.

## 3. Results in Chrome

The browser is Chrome 155 in a visible window. The build is a dart2wasm profile build with the
skwasm renderer. The raster time is on the skwasm worker. These figures were measured before the
circle batch (section 5.4).

| Scenario | draw (ms) | raster (ms) |
|---|---:|---:|
| 1000 + 0 | 0.8 | 5.9 |
| 5000 + 50 | 2.4 | 16.3 |
| 20000 + 0 | 9.3 | 38.6 |
| 20000 + 200 | 10.0 | 42.1 |

## 4. Results on Android

### 4.1 Test bed

- The phone is a Pixel 8a (Android 17, Impeller on Vulkan). The display ran at 60 Hz. Thus 60
  FPS is the highest frame rate.
- The build is a profile build. The profiling entry of section 6 ran the six scenarios in one
  process, 7 seconds each.
- The chart box has the size of the Stress tab: the width of the screen minus 24 logical pixels,
  and a height of 0.6 times that width, clamped to 240 to 520 logical pixels.
- The two baselines of section 4.4 draw the same scene in a box of the same size.

### 4.2 Before and after the circle batch

The circle batch is section 5.4. The figures "after" were measured with nearest sampling of the
atlas. The batch now samples bilinearly (section 5.4). That change is not measured again on the
phone (section 7).

| Scenario | FPS before | FPS after | draw before (ms) | draw after (ms) | raster before (ms) | raster after (ms) |
|---|---:|---:|---:|---:|---:|---:|
| 1000 + 0 | 58.5 | 58.2 | 5.5 | 4.9 | 11.8 | 4.8 |
| 1000 + 50 | 58.7 | 57.7 | 6.4 | 5.0 | 11.9 | 5.5 |
| 5000 + 50 | 30.4 | 58.9 | 15.6 | 6.7 | 26.3 | 6.3 |
| 20000 + 0 | 11.4 | 55.2 | 42.1 | 11.4 | 82.7 | 9.8 |
| 1000 + 200 | 58.0 | 58.2 | 8.0 | 6.9 | 12.2 | 7.5 |
| 20000 + 200 | 11.1 | 54.9 | 43.2 | 12.0 | 79.6 | 11.0 |

- Before the batch, the phone was 5 to 8 times slower than the Mac of section 2.
- With the batch, the raster time is 1.6 to 8.4 times lower. At 20000 points, it went from 82.7 ms to
  9.8 ms. The draw time is up to 3.7 times lower.
- At 5000 + 50 and at 20000 points, the frame rate went from 11 to 30 FPS to 55 to 59 FPS.
- At 1000 points, the frame rate stays at the 60 Hz limit of the display. The batch cuts the
  raster time from about 12 ms to about 5 ms. Thus a frame has more time left in it.

### 4.3 CPU profile

- **Before the batch.** The CPU profile had the shape of section 2.3. About half of the frame was
  the native `drawCircle` recording: two calls for each point, one fill and one stroke. The Dart
  code of the canvas layer took less than 3 % of the frame.
- **After the batch.** One `drawRawAtlas` call records a run of circles. The Dart path of the
  canvas layer is now the largest part of the draw time: about 0.35 microseconds for each point
  (`drawPoint`, the path builder and the batch, for the fill and the stroke).
- At 1000 points, about 4.5 ms of the draw time is not the points. Baseline A (section 4.4) has
  the same time. The likely causes are the `drawPath` of the polyline and a low CPU clock at a
  light load. This is not measured.

### 4.4 Baselines

Two baselines draw the scene of section 1 without port code, on the same phone, in a box of the
same size. Section 4.5 tells how to make them again.
- **Baseline A, plain Flutter.** A `CustomPainter` draws each point with two `drawCircle` calls,
  one fill and one stroke. It draws the polyline as one `ui.Path`, and the labels with cached
  `TextPainter`s at -45 degrees. This is the usual way to draw such a scene in Flutter.
- **Baseline B, Chrome canvas.** A web page in Chrome on the phone draws on an HTML canvas 2D,
  the API that Chart.js uses. For each point, it calls `beginPath`, `arc`, `closePath`, `fill`
  and `stroke`, as `drawPoint` of Chart.js does. It draws the polyline with `lineTo` and one
  `stroke`, and the labels with a rotated `fillText`. Chrome does not show its raster time to
  JavaScript. Thus the table has no raster column for Chrome. The draw time of Chrome is the time
  of the canvas calls in JavaScript only. Chrome rasterizes later, in another process.

| Scenario | Flutter FPS | Flutter draw (ms) | Flutter raster (ms) | Chrome FPS | Chrome draw (ms) |
|---|---:|---:|---:|---:|---:|
| 1000 + 0 | 59.6 | 4.8 | 11.4 | 59.5 | 1.9 |
| 1000 + 50 | 59.6 | 5.4 | 11.0 | 59.5 | 1.4 |
| 5000 + 50 | 37.0 | 12.4 | 22.5 | 59.5 | 5.3 |
| 20000 + 0 | 13.6 | 37.0 | 73.6 | 26.4 | 12.2 |
| 1000 + 200 | 59.4 | 6.5 | 11.6 | 59.5 | 2.0 |
| 20000 + 200 | 13.4 | 38.4 | 74.6 | 25.4 | 20.5 |

The frame rates side by side:

| Scenario | Port before | Port after | Flutter (A) | Chrome (B) |
|---|---:|---:|---:|---:|
| 1000 + 0 | 58.5 | 58.2 | 59.6 | 59.5 |
| 1000 + 50 | 58.7 | 57.7 | 59.6 | 59.5 |
| 5000 + 50 | 30.4 | 58.9 | 37.0 | 59.5 |
| 20000 + 0 | 11.4 | 55.2 | 13.6 | 26.4 |
| 1000 + 200 | 58.0 | 58.2 | 59.4 | 59.5 |
| 20000 + 200 | 11.1 | 54.9 | 13.4 | 25.4 |

Conclusions:
- Before the batch, the port was near plain Flutter. Its frame rate was 1 to 3 % lower at 1000
  points and 16 to 18 % lower at 5000 and 20000 points. Its draw and raster times were 3 to 26 %
  higher. The cost was the `drawCircle` calls that plain Flutter also makes, not the Dart code of
  the canvas layer.
- With the batch, the port is about 4 times faster than plain Flutter at 20000 points (55.2 FPS
  and 13.6 FPS), and about 2 times faster than the Chrome canvas (26.4 FPS). At 5000 + 50, the
  port and the Chrome canvas both keep about 59 FPS, and plain Flutter has 37 FPS.
- A `CustomPainter` that draws its circles with `drawRawAtlas` can get the same gain. The figures
  of baseline A are those of the usual code with `drawCircle`.

### 4.5 Baseline sources

The two baseline sources are not in the repository. They are not port code, and `tool/` holds
Dart tools that run with `dart run` or `flutter test`, not app entries or web pages. This section
gives the data to write them again. Both baselines use the six scenarios of section 6 in one
process, 7 seconds each. Each scenario resets its counters after 2 seconds, so the figures are
the means of the last 5 seconds. The profiling entry of section 6 uses all 7 seconds. Thus the
measure windows differ a little.

The scene of both baselines is the scene of section 1:
- The points: 20000 start positions in the unit square, from a random generator with the seed 7.
  Each point moves at 0.05 to 0.30 box sizes per second, in a random direction. A point that
  leaves the unit square turns back. The time step of a frame is at most 0.05 seconds.
- Each point is a circle of radius 3, filled with `rgba(54, 162, 235, 0.45)` and stroked with
  `#36A2EB`, width 1.
- The polyline goes through N points. Point i is at x = f * w, with f = i / (N - 1), and at
  y = h / 2 + sin(6 pi f + 1.5 t) * 0.3 h + sin(0.37 i + 6 t) * 0.04 h, where t is the time in
  seconds. Its color is `#FF6384`, width 1.5.
- The labels are `Label <j>`, 12 px, color `#666666`, centered in a grid of
  ceil(sqrt(M * w / h)) columns, each rotated by -45 degrees.
- The baselines do not draw the title of the stress demo.

Baseline A is one `lib/main.dart` in a new app of `flutter create`, run with
`flutter run --profile`:
- `MaterialApp` with a `Scaffold`. A `LayoutBuilder` gives a `SizedBox` of the box size of
  section 4.1, at the top center, with a `RepaintBoundary` and a `CustomPaint`.
- A `Ticker` moves the points and increments a `ValueNotifier`, which is the `repaint` listenable
  of the painter. `shouldRepaint` gives `true`.
- The painter has static `Paint` objects. It calls `drawCircle` with the fill paint and then
  `drawCircle` with the stroke paint for each point. Then it builds one `ui.Path` with `moveTo` and
  `lineTo` and calls `drawPath`. For each label, it calls `save`, `translate` to the cell center,
  `rotate(-pi / 4)`, `TextPainter.paint` at minus half its size, and `restore`. The
  `TextPainter`s are laid out once and kept in a map.
- A `Stopwatch` measures `paint`. `SchedulerBinding.addTimingsCallback` collects the
  `FrameTiming`s. At the end of each scenario, the app prints one line
  `BASE {"n", "m", "fps", "drawMs", "buildMs", "rasterMs"}`. The build and raster times are the
  means of `buildDuration` and `rasterDuration`.

Baseline B is one HTML file with an inline script and no library:
- One `<canvas>` with a CSS size of W x H. W is `innerWidth` minus 24, and H is 0.6 W, clamped to
  240 to 520. The bitmap is W x H times `devicePixelRatio`, rounded.
- The random generator is the Park-Miller generator (seed 7, multiplier 16807, modulus
  2^31 - 1).
- `requestAnimationFrame` runs the loop. Each frame calls `setTransform(1, 0, 0, 1, 0, 0)`,
  `clearRect` over the bitmap and `setTransform(dpr, 0, 0, dpr, 0, 0)`. For each point, it calls
  `beginPath`, `arc(x, y, 3, 0, 2 pi)`, `closePath`, `fill` and `stroke`. The polyline is one
  `beginPath`, `moveTo`, the `lineTo` calls and one `stroke`. The labels use the font
  `12px 'Helvetica Neue', 'Helvetica', 'Arial', sans-serif`, `textAlign` `center` and
  `textBaseline` `middle`. Each label is `save`, `translate`, `rotate(-pi / 4)`, `fillText` and
  `restore`.
- `performance.now()` measures the canvas calls of each frame. At the end of each scenario, the
  page sends `WEB {"n", "m", "fps", "drawMs"}` with a `POST` to `/log` of the server that serves
  the page. Any small HTTP server that prints the body of each `POST` serves it.

### 4.6 Touch input

The Events tab of the gallery ran on the Pixel 8a:
- A vertical drag on the chart host scrolls the page. The chart still gets `touchmove` events.
- The chart host coalesces the events for each frame. In one drag, 53 DOM events of the host
  gave 27 chart events.
- `touchend` gives NaN coordinates, as upstream does. Its `touches` list is empty, and a touch
  event has no offset (`NativeEvent.offsetX` and `offsetY` are NaN).
- At the device pixel ratio 2.625, the sizes are correct. A chart of 345.4 x 260 logical pixels
  has a canvas of 906 x 682 device pixels.

## 5. Changes

### 5.1 Full-circle path

`UiPathBuilder` (`lib/src/canvas/canvas_ui_path.dart`) keeps a full circle that `arc` adds to an
empty path under a similarity transform as a pending shape (`singleCircle`). The context draws it
with `drawCircle`:
- `fill()` draws it with `drawCircle` and the fill paint.
- An undashed `stroke()` draws it with `drawCircle` and the stroke paint.
- A later path command, a dashed stroke, a clip or a read of the path adds it to the `ui.Path` as
  two half arcs.

A chart draws most points as one full circle (`drawPointLegend`, `helpers.canvas.ts:200-207`).
Chart.js ADR 0013, section 8, records the decision. The test group "a full circle on an empty
path" of `test/port/canvas/canvas_ui_test.dart` pins it.

### 5.2 Paragraph disposal

- The paragraph cache of `layoutCanvasText` (`lib/src/canvas/canvas_ui_text.dart`) disposes the
  paragraph that it evicts. A recorded picture keeps its own reference to the text that a
  paragraph painted.
- `fillText` and `strokeText` dispose the uncached paragraph of a gradient or pattern text after
  the draw.
- Before this change, the garbage collector freed the paragraphs. A text that changes in each
  frame (the frame counter of the stress tab) then piled up one native paragraph for each frame.

Chart.js ADR 0015, section 2, records the decision. The test "a disposed paragraph still paints in
the recording" of `test/port/canvas/canvas_ui_test.dart` pins it.

### 5.3 Hidden gallery tabs

The gallery keeps each tab alive. `DemoTabBarView`
(`apps/chartjs_gallery/lib/demo/demo_common.dart`) turns `TickerMode` off for the hidden tabs.
Thus the animated line dash of the Canvas tab and the loop of the Stress tab stop while another
tab shows. The chart host reports the change through `ChartHost.onTickerModeChanged`. Before this
change, a hidden tab drew in each frame and added to the figures of the Stress tab. The profiling
entry (section 6) shows only the stress demo, so its figures do not have this cost.

### 5.4 Circle batch

`CircleBatch` (`lib/src/canvas/canvas_ui_batch.dart`) draws a run of full circles with one
`drawRawAtlas` call. Before this change, each point was two native `drawCircle` calls, and their
recording was about half of the frame on the phone (section 4.3).
- **The run.** The batch keeps consecutive full-circle fills and strokes with one radius, one fill
  color, and one stroke color and width. A circle that does not match draws the run first and
  starts a new run.
- **Which draws join.** `fill()` and the undashed `stroke()` of a pending full circle (section
  5.1) join the batch when the style is a plain color and the composite operation is
  `source-over`. A gradient, a pattern, a dash or another composite operation draws directly.
  `globalAlpha` multiplies the color. A circle with an outer radius (the radius plus half the
  line width) above 48 bitmap pixels (a bubble or a wide border) draws directly, and so does a
  center beyond 2^23 bitmap pixels.
- **The atlas.** The atlas image holds the filled circle and the stroked circle, each at 4 x 4
  sub-pixel offsets. Each instance takes the sprite of its kind and offset, and draws it at a
  whole pixel. The atlas samples bilinearly: at a whole device pixel no sprite is resampled, and
  at a fractional device pixel or under a scale the centers stay in place. The instances keep
  their order (fill 1, stroke 1, fill 2, and so on), so the paint order of overlapping points
  does not change.
- **The bounds.** A run of fewer than 16 circles draws with `drawCircle`, so that a few circles
  make no sprite. The sprite cache holds 32 atlas images. It disposes the image that it evicts. A
  recorded picture keeps its own reference to the image.
- **The flush points.** Each other access to the recording canvas draws the run first: each other
  draw, `save()`, `restore()`, a clip and the end of a recording. A full clear drops the run
  without a draw.
- **The difference.** The center of a circle moves to the nearest quarter pixel, at most 1/8
  pixel. In the test "gives the pixels of the separate draws", the largest channel difference
  from the separate draws is 46 of 255, on antialiased edge pixels. One sprite with bilinear
  sampling gave 76 of 255. This is the reason for the sub-pixel atlas. The difference is
  display-only ([Chart.js ADR 0034](adr/0034-no-display-only-js-exactness.md)).

- **The call size.** One `drawRawAtlas` call takes at most 512 instances. Skwasm copies the
  arrays of a call to the stack of its WebAssembly module. A call of 10000 instances overflowed
  that stack and broke the renderer in the gallery: every later frame threw `memory access out of
  bounds`, and the page did not respond.

Chart.js ADR 0013, section 8.1, records the decision. The test group "circle batch" of
`test/port/canvas/canvas_ui_test.dart` pins it.

### 5.5 Rotated text and the skwasm race

With 20000 points and 200 labels that turn in each frame ("spin labels"), the gallery crashed in
Chrome with dart2wasm. The symbols of `skwasm.js.symbols` (Flutter 3.44.9, engine 5a2a6a42) name
the crash. The main thread shapes a paragraph (HarfBuzz, then `SkFont::getWidthsBounds`). The
render worker draws text (`AtlasTextOp::onPrepareDraws`). Both crash in
`SkStrikeCache::findOrCreateStrike`. Each new rotation of a text makes a new strike, and the
strike cache churns.

| Setup (20000 points, 200 turning labels, a new paragraph in each frame) | Runs | Crashes |
|---|---:|---:|
| Port, no rotation snap | 3 | 2, and 1 page that did not respond |
| Port, rotation snapped to 0.5 degrees | 6 | 1 |
| Port, rotation snapped to 2 degrees | 6 | 0 |
| Port without a snap, single-threaded skwasm (no COOP/COEP headers) | 3 | 0 |
| Plain Flutter app (`TextPainter`, the Chart.js font family list), no port code | 6 | 2 |
| Plain Flutter app as above, without the 20000 points | 6 | 0 |
| Plain Flutter app with the default font family | 3 | 0 |

Thus the race is in the Flutter engine. Upstream fixed it on `master`.
[flutter/flutter#190048](https://github.com/flutter/flutter/pull/190048) gives each thread its own
strike cache, and [#191014](https://github.com/flutter/flutter/pull/191014) makes that flag
official. [#194139](https://github.com/flutter/flutter/pull/194139) makes the semaphores of the
FreeType locks work. Multi-threaded skwasm is built without `-pthread`, so before these changes
the locks did nothing. On 2026-10-19, the stable release 3.47.7 has none of the three changes. The
beta 3.50.0-0.1.pre has #190048 and #191014, but not #194139. No cherry-pick to stable is merged.

The race needs three things: turning text, the font fallback
of the Chart.js family list (skwasm has no `Helvetica Neue`, `Helvetica` or `Arial`), and a long
render on the worker. The canvas layer snaps the rotation of text to 2 degrees (Chart.js ADR
0015, section 3). An app can also turn the worker off with `forceSingleThreadedSkwasm`. Then the
race cannot occur, but the heaviest scene drops from 60 to 43.7 FPS, because the main thread also
renders:

| Scenario (Chrome, dart2wasm, turning labels) | Multi-threaded FPS | Single-threaded FPS |
|---|---:|---:|
| 1000 points, 50 labels | 60.3 | 60.0 |
| 5000 points, 50 labels | 60.0 | 60.0 |
| 20000 points, 200 labels | 60.0 | 43.7 |

The test group "rotated text" of `test/port/canvas/canvas_ui_test.dart` pins the snap.

## 6. How to measure

- **Stress tab.** Run `flutter run --profile` in `apps/chartjs_gallery`, open "Phase 3: canvas
  and host", then the Stress tab. Select N and M and turn on the switch. The readout shows the
  figures.
- **Profiling entry.** `apps/chartjs_gallery/lib/main_stress.dart` runs the scenarios of section 2
  in a fresh `StressDemo` each, for 7 seconds each. It prints one `STRESS {json}` line for each
  scenario. For one scenario in a fresh process:
  `flutter run --profile -t lib/main_stress.dart --dart-define=SCENARIO=5000x50`.
  `--dart-define=SECONDS=<n>` changes the time of each scenario.
  `--dart-define=MODE=<primitives|elements|bars|arcs|chart|axes|plugins>` selects the mode
  (section 1). Without `SCENARIO`, the modes `primitives` and `elements` run the six scenarios of
  section 2, `bars` runs 1000, 5000 and 20000 bars, and `arcs` runs 100, 1000 and 5000 arcs. The
  mode `chart` runs the counts of its chart type without labels: 1000, 5000 and 20000 items for
  `line`, `scatter`, `bar` and `bubble`, and 100, 1000 and 5000 items for `doughnut`, `pie`,
  `polarArea` and `radar`. The mode `axes` runs 1000, 5000 and 20000 chart points without labels.
  The mode `plugins` runs 100 and 1000 points in each dataset without labels. Each `STRESS` line
  starts with the key `mode`.
- **The mode `chart`** ([Chart.js ADR 0021](adr/0021-typed-options-in-the-resolver.md) §8,
  [Chart.js ADR 0031](adr/0031-gallery-chart-types.md) §3 and §5) measures a real `Chart` with a
  ported controller. Phases 5 and 6 used the gallery controller `StressPointController`. The
  before side of an A/B is a worktree of commit `0e0ab93`, which has the class. Each case runs
  with `animation: false`.
  - `--dart-define=TYPE=<line|scatter|bar|bubble|doughnut|pie|polarArea|radar>` selects the
    chart type. The default is `line`. The stress tab has the same choice in the `type` line (8
    icon segments, keys `stress.chart.type.<name>`). `TYPE` in another mode throws an
    `ArgumentError` at the start.
  - `line` and `scatter` keep the scene of phase 5: `type: 'line'` with `showLine: false`, or
    `type: 'scatter'`, with `parsing: false`, `layout.autoPadding: false`, the dataset option
    `clip: false` and two hidden linear scales (`display: false`, `ticks.display: false`; x with
    `suggestedMin: 0` and `suggestedMax: 1`, y with `min: 0` and `max: 1`). The reason: the x data
    is not sorted. With these bounds, all points draw, and each pixel equals the pixel of the
    phase 5 fraction path within 5.7e-14 px. A user `max` on x drops points with `parsing: false`.
    `autoPadding: false` keeps the phase 5 chart area (0, 0, 800, 480 in the benchmark), and
    `clip: false` keeps the phase 5 split of `drawMs` and of the end of the recording (section
    13.5).
  - The six other types use the default parsing of their controller, hidden scales with user
    bounds (`min: 0`, `max: 1`; the radial types on `r`), one `backgroundColor`, the border color
    `#36A2EB` and `borderWidth` 1. Doughnut and pie have no scales. The other options are the
    upstream defaults. These cases have no before figures.
  - `--dart-define=SHARING=<0|1>` is an alias of `TYPE`: without `TYPE`, `SHARING=0` gives
    `scatter` (no option sharing) and `SHARING=1` gives `line` (option sharing). Thus the command
    lines of phases 5 and 6 stay valid. With both defines, `SHARING=1` needs `TYPE=line` and
    `SHARING=0` needs `TYPE=scatter`. Another pair throws an `ArgumentError` at the start.
  - `--dart-define=SHOWLINE=1` shows the line of `line` and `scatter` (the toggle
    `stress.chart.showLine` of the stress tab). With another type or in another mode, it throws an
    `ArgumentError` at the start.
  - `--dart-define=CALL=draw` (the default) gives case (a): each frame calls `chart.draw()`.
  - `--dart-define=CALL=update` gives case (b): each frame writes new positions into the data
    objects, then calls `chart.update('none')`.
  - `--dart-define=SCRIPTABLE=1` gives the elements of each type a scriptable `backgroundColor`.
    With `CALL=update`, it gives case (c).
  - `--dart-define=CALL=animate` gives the animation cost. The chart has
    `animation: {duration: 1000, loop: true}`. Its first update starts an animation of `x` and
    `y` of each point, which loops without end. In each frame, the animator ticks the N
    animations and calls `chart.draw()`. The key `animatorMs` gives the time of that tick
    without its draw. The tick includes the property writes of the animations (section 10.4).
  - The chart listens to no event (`events: []`), as the hosts of the other modes take no pointer
    input. Thus the position of the pointer does not change the figures.
  - `SHARING`, `SCRIPTABLE`, `SHOWLINE` and `LINE` accept only 0 or 1. Another value throws at
    the start.
  - Example: `flutter run --profile -t lib/main_stress.dart --dart-define=MODE=chart
    --dart-define=CALL=update --dart-define=SHARING=0 --dart-define=SCENARIO=5000x0`. The same
    case with the new define: `--dart-define=TYPE=scatter`.
- **The timing parts.** In the modes `chart` and `axes` and in each case of the frameless
  benchmark, the inline plugin `StressChartTiming` (`lib/demo/stress_timing.dart`) takes four
  parts from the hooks of the chart. The library does not change. `elements` is
  `beforeElementsUpdate` to `beforeLayout`: `buildOrUpdateElements` of each dataset (the parse)
  and the first `getMaxOverflow`. `layout` is the layout. `datasetsUpdate` has the dataset
  updates, with the second `getMaxOverflow`. `datasetsDraw` is the draw of the datasets. A draw
  without an update gives `elements`, `layout` and `datasetsUpdate` 0. The plugin adds no time
  outside the spread (section 13.5, G7).
- **The mode `axes`** runs the points of the mode `chart` on real scales of phase 6
  (`lib/demo/stress_axes.dart`). From phase 7, the chart is `type: 'line'` with
  `showLine: false`, `parsing: false`, `layout.autoPadding: false` and the dataset option
  `clip: false`. Thus the chart area and the split of `drawMs` of phase 6 stay. A test pins the
  chart area, the x ticks and the rotation against `0e0ab93` for the linear, logarithmic and
  category axes. The time axis has no pin: its ticks depend on the local time zone.
  - `--dart-define=SCALE=<linear|logarithmic|category|time>` selects the x axis (the default is
    `linear`). `--dart-define=YSCALE=<linear|logarithmic>` selects the y axis.
    `--dart-define=AUTOSKIP=0` turns off `ticks.autoSkip` of the x axis.
  - `CALL` is `draw` or `update`. `CALL=animate` throws at the start.
  - The data has `parsing: false`, so the x values must be sorted. Thus the x values are fixed and
    in order, and only the y values move. A time point has a timestamp, not an ISO text.
  - The `STRESS` line has the keys `call`, `scale`, `yScale` and `autoSkip`, the tick count
    `ticks` (after the auto skip) and the `rotation` of the x axis at the end, and the means
    `elementsMs`, `layoutMs`, `datasetsUpdateMs` and `datasetsDrawMs` of the timing parts.
- **The mode `plugins`** (step 8 of phase 8, task S0) runs the chart of a plugin case of the
  frameless benchmark (below) in the real frame loop. Thus the legend, the title, the tooltip, the
  filler and the dispatch of their hooks get frame, build and raster figures on each platform.
  - `--dart-define=SCENE=<legend|title|hover|still|fade|gaps|stack|radar>` selects the scene. The
    default is `legend`. The stress tab has the same choice in the `scene` line (8 icon segments,
    keys `stress.plugins.scene.<name>`). A scene takes the config of the benchmark case
    `legend.line`, `title.line`, `tooltip.hover`, `tooltip.still`, `tooltip.fade`, `fill.gaps`,
    `fill.stack` or `fill.radar` (`chartBenchCases`, the same data, options and timing plugins).
    Only the options of the frameless chart change: no `responsive: false`, no fixed
    `devicePixelRatio`, `maintainAspectRatio: false`, and no `BasicPlatform`. Thus the chart fills
    its host and gets the `FlutterPlatform`, which keeps the option `animation`. The inline plugin
    of the labels and the title of the stress tab comes first, as in the mode `chart`.
  - `--dart-define=LEGEND=0` gives the scene `legend` without the legend (`plugins.legend: false`):
    the base of the legend and the title. `--dart-define=TOOLTIP=0` gives the scenes `hover` and
    `still` without the tooltip plugin: the base of the tooltip. `--dart-define=DATASETS=<3|10>`
    gives the datasets of the scenes `hover`, `still` and `fade`; the default is 10. The stress tab
    has the toggles `stress.plugins.legend` and `stress.plugins.tooltip` and the line `sets` (keys
    `stress.plugins.datasets.<3|10>`).
  - `CALL` is the call of the benchmark case. The scenes `legend`, `title`, `gaps`, `stack` and
    `radar` take `draw` (the default) or `update` (the change of the data of the case, not timed,
    then `chart.update('none')`). `still` takes `draw`. `hover` and `fade` take `frame`, their
    default. Without `CALL`, each mode and scene takes its first call. A call that the mode or the
    scene does not have throws an `ArgumentError` at the start: `frame` outside the mode
    `plugins`, `animate` in the mode `axes`, or for example `CALL=draw` with `SCENE=fade`.
  - `hover` (`animation: false`): each frame sends a `mousemove` over the next point of dataset 0
    directly to the event handler of the chart (`chart.eventHandler`), as the benchmark does. This
    goes around the host input path of Chart.js ADR 0037: the pointer conversion of the chart host
    and the throttled proxy of `createProxyAndListen` (platform.dom.js:240-254). Thus the handler
    runs in the same frame callback, with no throttle. The event draws the chart at once.
    `updateMs` is the time of the event handler of the chart only, without its draw.
  - `fade` (the default animations): the first frame of each 12 frames
    (`chartBenchFadeFrames`) sends a `mousemove` over the middle point of dataset 0 or a
    `mouseout`, in turn, directly to the event handler of the chart, around the host input path,
    as in the scene `hover`. The animator of the chart ticks the fade in its own frame callback,
    in the real frames: no manual tick. The loop schedules its next frame before the event, so its
    callback runs before the animator callback in each frame. It marks the time at its end, and
    `animatorMs` is the tick of the animator before its draw. `updateMs` is the time of the event
    handler of the chart only. Thus `updateMs + animatorMs` compares with the update of the
    benchmark cell. At 120 Hz, 12 frames are 100 ms, so each fade stops at its middle.
  - `still` (the default animations): the preparation of the benchmark case hovers the middle
    point and ends the animations; each frame calls `chart.draw()`.
  - The tooltip scenes listen to the default events. A real pointer over the chart host also gives
    events, through the host input path and the throttled proxy, and these events are not the
    events of the scene: do not move the mouse over the chart during a run. The figures of the
    scenes `hover` and `fade` do not include the cost of the host input path.
  - The `STRESS` line has the keys `animatorMs`, `call`, `scene`, `benchCase` (the id of the
    benchmark case), the keys of the benchmark case (`datasets`, and `legend` and `title`, or
    `tooltip`), the means `elementsMs`, `layoutMs`, `datasetsUpdateMs` and `datasetsDrawMs` of the
    timing parts, and in the tooltip scenes `tooltipDrawMs` (`beforeTooltipDraw` to
    `afterTooltipDraw`). The parts of this mode add the hooks of the animator frames too.
  - Example: `flutter run --profile -t lib/main_stress.dart --dart-define=MODE=plugins
    --dart-define=SCENE=hover --dart-define=TOOLTIP=0 --dart-define=SCENARIO=1000x0`.
  - The modes `primitives` to `axes`, their defines and the keys of their `STRESS` lines do not
    change. The `StressStats` value gets the field `tooltipDrawMs`.
- `--dart-define=LINE=0` turns off the line of the modes `primitives` and `elements`. The mode
  `chart` of `line` without `SHOWLINE=1` has no line: the line has `borderWidth` 0
  (`controller.line.js:63-65`). Thus the acceptance of Chart.js ADR 0021 §8 compares the mode
  `chart` in case (a) with the mode `elements` with `LINE=0`.
- Each `STRESS` line has the key `updateMs`: the time of `chart.update()` without its draw. It is
  0 outside the modes `chart` and `axes`. In these modes, `drawMs` is the time of `chart.draw()`,
  also of the draw inside `chart.update()`. Neither time includes the writes of the positions into the
  data objects. In the mode `chart`, the line also has the keys `animatorMs`, `call`, `type`,
  `sharing` (the `enableOptionSharing` of the controller of dataset 0), `scriptable`, `showLine`
  (only when true) and the four timing parts. With `LINE=0`, it has the key `line` with the value
  false.
- On macOS, run one scenario in each process. In the phase 4 runs, a process that ran several
  scenarios stopped to give frames after about 28 seconds (section 8.1).
- Take the figures from the first seconds of a fresh process (section 2.5).
- **Frameless benchmark.** `apps/chartjs_gallery/lib/main_bench.dart` times the costs of the UI
  thread of the chart path without frames (`lib/bench/chart_bench.dart`).
  - The chart is a `UiCanvasElement` of 800 x 480 without a host, so it gets `BasicPlatform`. It
    has `responsive: false` and `devicePixelRatio: 1`. The cases of the modes `chart` and `axes`
    (phases 5 to 7) also have `animation: false`, `events: []` and `plugins.legend: false` (from
    phase 8: `stressPluginOptions`, Chart.js ADR 0031 Open). The other plugins of
    `registerables` run. These charts have no labels and no title, so their draw is lower than
    `drawMs` of the stress entry. The cases of phase 8 (below) give their own options.
  - After the first frame, the app runs each case for each N. It prints one line `BENCH {json}`
    for each case and N, and `BENCH done` at the end. A line has the median, p10 and p90 of
    `update('none')` without its draw, of `draw()` and of the end of the recording into a
    `ui.PictureRecorder`. Each case also gives the four timing parts `elements`, `layout`,
    `datasetsUpdate` and `datasetsDraw`. The `chart` cases give the keys `type`, `sharing` and
    `scriptable`. The `axes` cases give `ticks` and `rotation` of the x axis.
  - From phase 8, each line also has the key `notifies`: the calls of `notifyPlugins` in the last
    iteration, also when no plugin gets the hook (Chart.js ADR 0038 §10 item 4). A draw of one
    dataset gives 6. The benchmark chart counts them in an override of `notifyPlugins`, not in
    `lib/`. The override is in each case, also in the cases of phases 5 to 7: it adds one call and
    one increment to each notify (6 for each draw of `chart.a`). A comparison of a figure of
    phases 5 to 7 with a figure of a later build of the benchmark includes this change.
  - The primary metric of a cell is the cost of one whole frame: the sum of the run medians
    `updateMedianMs + drawMedianMs + endMedianMs`, or `drawMedianMs + endMedianMs` for a draw
    case. Each case of phase 8 names it in the key `primary` (`update+draw+end` or `draw+end`).
    The lines of phases 5 to 7 have no key `primary`.
  - The call `frame` (phase 8): each iteration runs one frame of the case, for example an event
    or a tick of the animator, with the draws that they cause. The data does not change. Its
    `update` figures are the frame without its draws (the event and the tick).
  - The cases, in this order: `chart.a` (draw, `line`), `chart.b` (update, `line` with sharing and
    `scatter` without sharing) and `chart.c` (update, `line`, scriptable), the cases (a) to (c) of
    the mode `chart`. For each scale type of the mode `axes`, a draw case and an update case, for
    example `axes.time`. Then the 12 cases `chart.<type>` of Chart.js ADR 0031 §7: `bar`,
    `bubble`, `doughnut`, `pie`, `polarArea` and `radar`, each with `draw` and `update`. A default
    run thus times the cases with before figures first. The `before` lines join on `mode`, `case`,
    `sharing`, `scriptable` and `n`.
  - After them come the 30 cases of phase 8 (step 8, task P1). N is the point count of each
    dataset. The keys tell apart the cases of one id.
    - `plugins.line` (CT stage 1, Chart.js ADR 0038 §10 items 1-2): a line chart on hidden scales
      with `animation: false` and `events: []`, in two configs (key `config`). A: the seven
      plugins of `registerables`, each with its least work (`legend.display`, `title.display`
      and `subtitle.display` false, `colors.enabled` and `decimation.enabled` false, no `fill`, no
      event). B: `options.plugins: false`, so each notify visits no plugin. 3 datasets of 1000
      points and 100 datasets of 100 points (key `datasets`, 204 notifies for each draw of 100
      datasets), each with `draw` and `update`: 8 cases. A minus B is the upper bound of the gain
      of CT. The 100-dataset cells are primary. These lines have no timing parts, because B
      turns off the timing plugin too.
    - `tooltip.hover`, `tooltip.still`, `tooltip.fade`: the cases (a), (b) and (c) of Chart.js ADR
      0039 Open 1. A line chart of 3 or 10 datasets (key `datasets`) on the visible default
      scales, `interaction: {mode: 'index', intersect: false}`, the default events and no legend.
      (a) `hover` (call `frame`): each frame sends a `mousemove` over the next point, so the
      tooltip index changes in each frame. It has `animation: false`, because the frameless
      benchmark cannot tick the element animations in frame time: each animation takes its start
      from the clock. (b) `still` (call `draw`): the preparation hovers the middle point and ends
      the animations; each iteration calls `chart.draw()`. (c) `fade` (call `frame`): a tick of
      the animator 1000/60 ms after the tick before, with a `mousemove` or a `mouseout` in the
      first frame of each fade of 12 frames (the 200 ms opacity animation), so each frame draws
      the tooltip with a new opacity. Each fade moves the dates of its ticks by a phase (the
      fractional part of the fade count times 0.618 frames, `chartBenchFadePhase`), as the vsync of
      a real frame loop does. Thus the opacities of one fade do not come again in the next fades,
      and the lines of the tooltip miss the paragraph cache, as on a device (Chart.js ADR 0039
      §13). With the same dates in each fade, each line came from the cache from the third
      fade. (b) and (c) run on a `BasicPlatform` with the no-op
      `updateConfig` of `BasePlatform`, so the chart keeps its default animations. `hover` and
      `still` also run with `plugins.tooltip: false` (key `tooltip` false): the guard cells of the
      same chart without the tooltip. The lines have the part `tooltipDraw` (`beforeTooltipDraw`
      to `afterTooltipDraw`): the draw of the tooltip of the 0.1 ms rule of the ADR. 10 cases.
    - `fill.gaps`, `fill.stack`, `fill.radar` (Chart.js ADR 0040 Open 2): 3 datasets on hidden
      scales with `pointRadius: 0`, `animation: false`, `events: []` and no legend, each with
      `draw` and `update`. `gaps`: values from -1 to 1 with a gap every 12 points and
      `fill: {target: 'origin', above, below}` (the path clips). `stack`: stacked y values and
      `fill: 'stack'` (quadratic in N, as upstream). `radar`: a radar on a hidden polygon grid
      with the fills `origin`, `-1` and `-1`. 6 cases. `chart.radar` also fills (`fill: 'start'`,
      one dataset).
    - `legend.line` and `title.line`: a line chart of 3 datasets on the visible default scales,
      `animation: false` and `events: []`, each with `draw` and `update`. `legend.line` with the
      legend of the docs blocks (the defaults: `display: true`, `position: 'top'`; key `legend`
      true) and without it (`plugins.legend: false`, the base of the legend and the title).
      `title.line`: no legend and the title `{display: true, text: 'Chart.js Line Chart'}`. 6
      cases.
  - Each case has its own point counts (`ChartBenchCase.counts`): the counts of its chart type in
    the mode `chart`, 1000 (3 datasets) or 100 (100 datasets) in `plugins.line`, 100 and 1000 in
    the modes `tooltip`, `fill`, `legend` and `title`, else 1000, 5000 and 20000.
  - The loop is the loop of `tool/bench/src/harness.dart`: a warm-up, a calibration, then
    batches of a fixed number of iterations. A batch figure is the mean of its iterations, so
    each batch carries its part of the garbage collection. The update cases move the points
    outside the timing.
  - Defines: `CASES` (a comma list of modes, names or `mode.name`, the default is all cases), `N`
    (a comma list of counts for all cases; without it, each case runs its own counts), `BATCHES`
    (15), `BATCH_MS` (200) and `WARMUP_MS` (1000). A selector that selects no case throws at the
    start. The selector `chart` selects 16 cases. `CASES=a,b,c` selects the cases of Chart.js ADR
    0021 §8, for a before/after run against `0e0ab93`. The selectors `plugins`, `tooltip`, `fill`,
    `legend` and `title` select the cases of phase 8. The bare name `radar` selects `chart.radar`
    and `fill.radar`, and `line` selects `plugins.line`, `legend.line` and `title.line`: use the
    ids. A default run times all 54 cases, 124 cells (the 24 cases and 72 cells of phases 5 to 7
    first). The define `N` gives the points of each dataset to all cases, also to the 100
    datasets of `plugins.line`. The stack fill at 1000 points takes about 0.1 s for each draw in
    V8, so a run of `fill` takes longer.
  - Example: `flutter build apk --profile --target-platform android-arm64 -t lib/main_bench.dart
    --dart-define=CASES=c --dart-define=N=5000`. Install and start the APK, and read the lines
    with `adb logcat -d -s flutter:I`. On a cool Pixel 8a at 2.9 GHz, case c at 5000 gave an
    update median of 29.139 ms (p10 28.483, p90 31.635), a draw of 7.372 ms and an end of 4.523
    ms (75 iterations in 15 batches).
  - Keep the app in front: a background app gets slower cores. Do not touch the screen during a
    run. On Android, the UI thread is also the platform thread. A case holds it for about 4 s,
    and an input event that waits for more than 5 s gives an "App not responding" dialog.
  - The benchmark does not measure FPS, the raster time or the host paint. It removes the frame
    pacing, not the noise of the core frequency between processes. Thus an A/B comparison still
    runs fresh processes in ABBA order, with a gate on the temperature and the core frequency
    (section 10.11).
- **The A/B of phase 7** (Chart.js ADR 0031 §8). Step 7 measures three sides of the cases
  `chart.a`, `chart.b` (sharing on and off) and `chart.c` on the Pixel 8a:
  - A: a worktree of commit `0e0ab93` (the phase 5 config, the fraction path of
    `StressPointController`).
  - A': the same worktree with the bridge patch of Chart.js ADR 0031 §8. The patch changes only
    `apps/chartjs_gallery/lib/demo/stress_chart_config.dart`: the hidden unit scales,
    `layout.autoPadding: false` and `clip: false`, on the scale path of `StressPointController`.
    Check it with `git apply --check`. Before the first run, a test in the worktree confirms that
    the pixels equal `getPixelForValue`.
  - B: the phase 7 tree.
  - A to A' is the cost of the hidden scales. A' to B is the cost of the ported controllers. Report
    each pair apart, with the part `elements` of B. Each pair uses fresh processes in ABBA order,
    the gates on the temperature and the core frequency, and a bootstrap interval. The before
    figures of commit `0e0ab93` are a working file of phase 7, not committed. Step 7 gives them in
    section 13.6.
- **Baselines.** Section 4.5 describes the plain Flutter and the Chrome canvas baselines.

## 7. Open

- The plan [canvas-cuts-plan.md](canvas-cuts-plan.md) (proposed) needs a new baseline of the
  six scenarios on the three platforms, and a scenario with arcs, before its cuts land (its
  section 6.3). Cut 2 used an A/B test in place of this baseline (section 9).
- Cut 2: `bars` 1000 on the Pixel 8a has a draw time 0.18 ms (1.8 %) longer after C2, in code
  that C2 does not change (section 9.5). The cause is not known. The frame rate has no measured
  change. Measure it again in the phase 5 performance work.
- The 2 degree text rotation snap (section 5.5) stays until the toolchain pin is a stable release
  with the upstream fixes. Then remove it, and run the crash case of section 5.5 again.
- macOS and Chrome: section 8.1 has the figures of the `primitives` mode with the circle batch.
  They are not the baseline of the plan: they come from one process for each mode, not from 3
  fresh processes for each scenario.
- Typed element options (section 8.4): the elements read typed options without a Map lookup.
  Phase 5 makes them in a chart: `resolveNamedOptions` makes the typed class of the element type,
  and the option copies of `cloneIfNotShared` and `resolveTargetOptions` keep it
  ([Chart.js ADR 0021](adr/0021-typed-options-in-the-resolver.md)). Section 10.7 has the draw cost
  for each point of case (a) on the Pixel 8a and macOS. Section 10.9 has all cases of the mode
  `chart` on the Pixel 8a and case (a) on the iPhone. The final series of the mode `chart`, the
  animations and the regression set on macOS and in Chrome with dart2wasm did not run, because
  the Mac was in use. Options that are plain Maps still cost the lookups of section 8.2.
- Scriptable options (case c of section 10.9): the update at 5000 points takes 45.6 ms on the
  Pixel 8a, and case (c) at 20000 runs at 3.5 FPS. Section 10.10 has the CPU profile: 84 % of the
  update is the work of the resolver that upstream also does for a scriptable option. Closed in
  phase 6: the read of `element['$context']` costs 1.2 % of the update. A declared `$context`
  gave no measured gain, so the port does not declare it (section 10.11).
- Closed in phase 6: the benchmark of the chart path without frames is the gallery entry
  `lib/main_bench.dart` (section 6).
- Scales (phase 6): section 11.6 has the frame figures of the scale path on the Pixel 8a, and
  section 11.7 the change of the metrics cache. Section 11.8 lists the open forms. The iPhone,
  macOS and Chrome with dart2wasm are not measured. The logarithmic value axis with
  `CALL=update` of section 11.6 answers the Open 2 of Chart.js ADR 0025 on the Pixel 8a. In
  phase 7, it needs them for its Open 1 (a `timeseries` axis, a radar chart). Chart.js ADR 0024 needs the figures of a
  time axis with ISO labels on the Pixel 8a, macOS, Chrome with dart2wasm and the iPhone (its
  Open 1, section 12.5). The mode `axes` gives timestamps, not ISO labels.
- `elements` 20000 + 0 on the Pixel 8a: over 31 pairs, the FPS median of the phase 5 builds misses
  the criterion of plan §6.3 by 0.9 FPS. The draw follows the frequency of the big core, and at the
  same frequency the phase 5 build is not slower (section 10.8). A series at a fixed core frequency
  needs a device with root access.
- Animations: section 10.9 has the animated stress case (`CALL=animate`) on the Pixel 8a and the
  iPhone. macOS and Chrome with dart2wasm are not recorded.
- Arcs: the native path calls (`Path.arcTo`) cost the most (section 8.2). Cut 1 of
  [canvas-cuts-plan.md](canvas-cuts-plan.md) keeps the native arc path (`_nativeArc`), so it does
  not reduce this cost. The bars use `roundRect` now (section 8.4).
- macOS: the `drawDRRect` ring of the bars costs more raster time than the path on Metal (section
  8.4), at the same 60 FPS up to 5000 bars. Measure it again on a later Flutter release.
- macOS: the cause of the stop after about 28 seconds in a process with several scenarios
  (section 6) is not known.
- The circle batch with bilinear sampling on the phone: section 4.2 was measured with nearest
  sampling.
- The draw time at 1000 points on the phone (section 4.3): the cause of the 4.5 ms that is not
  the points is not measured.
- iOS: section 8.4 has the element modes on an iPhone 17 Pro. The `primitives` mode is measured
  only with the code of section 8.4, and the variants of the bars only on the other platforms.

## 8. Elements (phase 4)

### 8.1 Results

Each mode ran in one profile build, with the scenarios of section 6, 7 seconds each. The cells
give FPS / draw (ms) / raster (ms). A dash means that the scenario gave fewer than 31 frames in
7 seconds, so it has no figure. The bars rows come from the code after the change of section
8.3. The other modes do not call the changed code.

**Pixel 8a** (Android 17, Impeller on Vulkan, 60 Hz, one process for each mode):

| Scenario | `primitives` | `elements` |
|---|---|---|
| 1000 + 0 | 58.7 / 5.0 / 4.7 | 58.2 / 5.5 / 4.8 |
| 1000 + 50 | 58.7 / 5.3 / 5.6 | 58.6 / 5.9 / 5.7 |
| 5000 + 50 | 58.7 / 7.4 / 6.3 | 56.2 / 9.1 / 6.8 |
| 20000 + 0 | 57.7 / 10.6 / 10.2 | 33.7 / 17.9 / 10.9 |
| 1000 + 200 | 57.8 / 6.8 / 7.5 | 58.0 / 7.8 / 7.5 |
| 20000 + 200 | 55.5 / 11.4 / 11.6 | 31.1 / 20.1 / 12.5 |

| N | `bars` | `arcs` |
|---|---|---|
| 100 | | 58.0 / 5.6 / 7.5 |
| 1000 | 34.0 / 14.6 / 21.2 | 39.8 / 13.5 / 18.4 |
| 5000 | 13.1 / 57.3 / 64.4 | 12.9 / 53.8 / 66.6 |
| 20000 | — | |

**macOS** (Apple M3 Max). The `primitives`, `elements` and `arcs` rows come from one process for
each mode, except the two rows with 200 labels. Those rows and the `bars` rows come from one fresh
process for each scenario (section 6).

| Scenario | `primitives` | `elements` |
|---|---|---|
| 1000 + 0 | 60 / 0.5 / 2.4 | 60 / 0.8 / 2.3 |
| 1000 + 50 | 60 / 0.6 / 2.0 | 60 / 0.9 / 2.0 |
| 5000 + 50 | 60 / 1.3 / 7.4 | 60 / 2.5 / 5.0 |
| 20000 + 0 | 60 / 4.3 / 14.5 | 60 / 8.5 / 3.9 |
| 1000 + 200 | 60 / 0.7 / 2.1 | 60 / 1.0 / 2.2 |
| 20000 + 200 | 60 / 4.5 / 16.3 | 60 / 8.8 / 8.1 |

| N | `bars` | `arcs` |
|---|---|---|
| 100 | | 60 / 0.7 / 1.1 |
| 1000 | 60 / 3.2 / 6.9 | 60 / 4.2 / 6.3 |
| 5000 | 36.3 / 15.0 / 26.1 | 30.0 / 19.5 / 30.2 |
| 20000 | 10.3 / 59.8 / 98.8 | |

**Chrome** (Chrome 155 in a visible window, dart2wasm profile build, skwasm, one page for each
mode). The raster time is on the skwasm worker.

| Scenario | `primitives` | `elements` |
|---|---|---|
| 1000 + 0 | 60 / 1.3 / 6.0 | 60 / 2.5 / 6.3 |
| 1000 + 50 | 60 / 1.5 / 5.7 | 60 / 2.7 / 5.8 |
| 5000 + 50 | 60 / 4.9 / 23.8 | 60 / 10.1 / 24.1 |
| 20000 + 0 | 54.7 / 17.2 / 36.4 | 25.4 / 38.0 / 39.1 |
| 1000 + 200 | 60 / 2.1 / 6.3 | 60 / 3.3 / 6.6 |
| 20000 + 200 | 51.5 / 18.3 / 37.0 | 25.8 / 37.4 / 38.3 |

| N | `bars` | `arcs` |
|---|---|---|
| 100 | | 60 / 2.4 / 4.3 |
| 1000 | 59.9 / 15.1 / 38.3 | 47.5 / 20.1 / 40.8 |
| 5000 | 12.5 / 74.4 / 158.1 | 9.8 / 99.3 / 193.4 |
| 20000 | — | |

- Up to 5000 points, the `elements` mode keeps 56 to 60 FPS on the three platforms. At 20000
  points, the elements add about 0.37 microseconds for each point on the phone, 0.21 on macOS and
  1.0 in Chrome.
- On macOS, the `elements` mode has a lower raster time than `primitives` at 20000 points. The
  line takes the fast path of `element.line.js` (`fastPathSegment`), which joins the points of one
  x pixel. Thus its path has fewer segments than the polyline of `primitives`.
- Bars with a border and a radius cost about 15 microseconds each on the phone. Arcs with a
  border, a spacing and a radius cost about 13.5. The default Chart.js bar has no border and no
  radius. It takes the rectangle path of the canvas layer and does not clip.

### 8.2 CPU profiles

The profiles come from the Dart VM service on macOS (`bars` at 5000, `arcs` at 5000, `elements`
at 20000) and from a Chrome trace of `elements` at 20000. The percentages are shares of the
samples of the thread that draws.
- **`bars`.** `BarElement.draw` took 75.5 %. Of that, `fill` took 20.2 %, `arc` 16.4 % and `clip`
  13.9 %. These are the canvas layer and the native path calls of the rounded corners.
  `_boundingRects` took 15.7 %. Most of it was `toTRBL` and `toTRBLCorners`, which built a list of
  keys, a closure and a Map for each bar (section 8.3).
- **`arcs`.** The native `Path.arcTo` took 35.4 %, and `UiPathBuilder.arc` 45.3 % in total. With a
  `borderRadius`, `pathArc` adds about 6 arcs, and upstream builds the path twice: once for the
  fill and once for the border. `UiPathBuilder._nativeArc` makes one native call for each arc of
  up to 180 degrees. Thus the cost is the native path API.
- **`elements`, macOS.** The Map lookups of the options (the lookup, the hash code and the string
  compare) took about 18 %. `PointElement.draw` took 55.3 %, `PointElement.size` 9.7 % and
  `drawPointLegend` 29 %. A point reads about 11 option values in each draw, as upstream does.
- **`elements`, dart2wasm.** On the main thread, the Map lookups with `String` keys took 25.7 %,
  the calls from Wasm to JavaScript and the timeline marks of the profile build 19.4 %, the canvas
  layer 14.6 %, the demo code 9.4 % and the element code 7.9 %.
- **Boxed fields.** The `double?` fields of Chart.js ADR 0017 box a `double` at each write. A
  scratch AOT benchmark on macOS gave about 2 ns more for each write than a non-nullable field.
  At 20000 points with 4 writes for each point, this is less than 1 ms on the phone. Thus the
  fields stay as they are.

A cache of the option values for each options Map is not safe. Chart.js animations write into an
options object that is not shared (`core.animations.js`, `resolveTargetOptions`). A Dart Map can
also change in place.

### 8.3 Change: the number path of `toTRBL` and `toTRBLCorners`

For a value that is not an object, `_readValueToProps` gives the same number for each key
(`helpers.options.ts:55-63`). `toTRBL` and `toTRBLCorners` now build their object from that
number directly, without the Map. A test of `test/port/helpers/helpers.options_test.dart`
compares the two paths for 19 values that are not objects.

`bars` on macOS, one fresh process for each scenario, FPS / draw (ms) / raster (ms):

| N | Before | After |
|---|---|---|
| 1000 | 60 / 3.6 / 6.9 | 60 / 3.2 / 6.9 |
| 5000 | 36.1 / 17.2 / 26.2 | 36.3 / 15.0 / 26.1 |
| 20000 | 10.3 / 67.7 / 101.1 | 10.3 / 59.8 / 98.8 |

On macOS, the draw time is about 12 % lower. On the phone, the draw time went from 15.6 to 14.6
ms at 1000 bars and from 59.2 to 57.3 ms at 5000 bars. The raster time does not change, because
it comes from the clip and the paths.

### 8.4 Changes: typed options, `roundRect` and the bar clip

Three changes followed the profiles of section 8.2 and the performance rule of
[porting-flow.md](porting-flow.md) §1.1:
- **Typed element options** ([Chart.js ADR 0018](adr/0018-typed-element-options.md)):
  `PointOptions`, `LineOptions`, `BarOptions` and `ArcOptions` are Maps that keep their known
  keys in fields. The elements read these options without a Map lookup. The stress demo makes
  them.
- **`roundRect`** (`adapt-rounded-rect-path`, [differences.md](differences.md)):
  `addRoundedRectPath` calls `roundRect`. Under an axis-aligned transform, the `dart:ui` context
  adds one `addRRect`, fills one rounded rectangle with `drawRRect`, clips it with `clipRRect`, and
  fills the even-odd ring of two nested shapes with `drawDRRect`.
- **No bar clip** (`adapt-bar-clip`, [differences.md](differences.md)): a bar with an
  `inflateAmount` of 0 does not clip, because the clip changes no pixel then.

The old code is commit `7866a3e` in a git worktree. The new code is the change. Both ran in the
same session: on the Pixel 8a and the iPhone one process for each mode, on macOS one fresh process
for each scenario, and in Chrome one page for each mode. Two variants of the new code each change
one line: "no clip skip" clips each bar again, and "no ring" fills the ring with `drawPath`. The
cells give FPS / draw (ms) / raster (ms). A dash means fewer than 31 frames in 7 seconds.

**Pixel 8a:**

| Scenario | Before | After | After, no clip skip | After, no ring |
|---|---|---|---|---|
| elements 5000 + 50 | 58.2 / 8.7 / 6.6 | 59.4 / 8.0 / 6.4 | | |
| elements 20000 + 0 | 33.4 / 18.5 / 10.1 | 44.5 / 14.7 / 9.7 | | |
| elements 20000 + 200 | 31.6 / 19.1 / 12.5 | 42.5 / 15.2 / 11.5 | | |
| bars 1000 | 33.9 / 14.9 / 21.0 | 49.6 / 9.5 / 13.9 | 41.4 / 11.1 / 17.9 | 46.4 / 10.3 / 14.7 |
| bars 5000 | 12.5 / 58.5 / 69.3 | 16.8 / 33.3 / 52.1 | 15.2 / 44.9 / 51.0 | 15.3 / 35.3 / 57.2 |
| bars 20000 | — | 8.7 / 115.8 / 84.5 | — | 6.2 / 142.7 / 101.8 |
| arcs 1000 | 38.7 / 14.3 / 18.1 | 39.5 / 13.9 / 18.2 | | |
| arcs 5000 | 13.1 / 54.7 / 64.8 | 14.1 / 56.6 / 63.6 | | |

**macOS:**

| Scenario | Before | After | After, no clip skip | After, no ring |
|---|---|---|---|---|
| elements 5000 + 50 | 60 / 2.4 / 12.6 | 60 / 1.9 / 9.2 | | |
| elements 20000 + 0 | 60 / 8.3 / 8.0 | 60 / 6.6 / 7.9 | | |
| bars 1000 | 60 / 3.1 / 7.2 | 60 / 2.9 / 3.3 | 60 / 3.1 / 5.2 | 60 / 3.1 / 2.5 |
| bars 5000 | 37.1 / 14.5 / 26.1 | 60 / 12.1 / 12.7 | 40.0 / 12.9 / 22.9 | 60 / 11.7 / 8.9 |
| bars 20000 | 10.3 / 59.1 / 97.3 | 15.3 / 47.6 / 42.2 | | |
| arcs 1000 | 60 / 4.2 / 7.0 | 60 / 4.2 / 7.0 | | |
| arcs 5000 | 30.0 / 19.5 / 30.9 | 30.2 / 19.1 / 30.8 | | |

**Chrome** (dart2wasm, skwasm):

| Scenario | Before | After | After, no clip skip | After, no ring |
|---|---|---|---|---|
| elements 5000 + 50 | 60 / 10.0 / 24.0 | 60 / 7.1 / 22.0 | | |
| elements 20000 + 0 | 26.6 / 36.3 / 37.7 | 37.4 / 25.4 / 26.6 | | |
| elements 20000 + 200 | 26.2 / 36.8 / 37.7 | 37.2 / 25.5 / 26.6 | | |
| bars 1000 | 60 / 14.8 / 33.5 | 60 / 6.0 / 9.2 | 60 / 6.8 / 18.8 | 60 / 7.8 / 6.3 |
| bars 5000 | 12.6 / 74.0 / 148.7 | 32.2 / 30.3 / 58.9 | 29.3 / 33.4 / 78.3 | 24.2 / 39.6 / 38.6 |
| bars 20000 | — | 8.2 / 121.1 / 245.0 | 7.3 / 135.0 / 276.8 | 6.2 / 157.8 / 161.8 |
| arcs 1000 | 48.9 / 19.5 / 38.0 | 51.3 / 18.6 / 37.3 | | |
| arcs 5000 | 10.3 / 94.6 / 186.6 | 10.6 / 91.6 / 180.6 | | |

**iPhone 17 Pro** (iOS 26.6.2, the display runs at up to 120 Hz, a profile build connected by
cable, one process for each mode, the default renderer of Flutter on iOS):

| Scenario | Before | After |
|---|---|---|
| primitives 1000 + 0 | | 119.4 / 1.3 / 1.0 |
| primitives 20000 + 200 | | 119.7 / 3.0 / 1.0 |
| elements 5000 + 50 | 119.8 / 1.6 / 0.3 | 119.8 / 1.3 / 0.3 |
| elements 20000 + 0 | 119.9 / 6.8 / 0.5 | 119.8 / 4.9 / 0.4 |
| elements 20000 + 200 | 114.5 / 7.2 / 0.7 | 119.7 / 5.3 / 0.6 |
| bars 1000 | 120 / 2.0 / 2.7 | 119.9 / 1.8 / 1.4 |
| bars 5000 | 42.7 / 13.1 / 22.2 | 60.0 / 10.2 / 7.2 |
| bars 20000 | 15.3 / 54.8 / 57.0 | 20.3 / 41.9 / 22.1 |
| arcs 1000 | 119.9 / 2.7 / 2.1 | 119.9 / 2.6 / 2.1 |
| arcs 5000 | 42.0 / 16.4 / 13.0 | 42.7 / 16.3 / 13.2 |

- **Typed options.** At 20000 points, the draw time is 20 % lower on the Pixel 8a, 21 % on macOS,
  28 % on the iPhone and 30 % in Chrome. The frame rate went from 33 to 44 FPS on the Pixel 8a
  and from 27 to 37 FPS in Chrome.
- **Bars.** At 1000 bars, the Pixel 8a went from 34 to 50 FPS. At 5000 bars, macOS went from 37
  to 60 FPS, the iPhone from 42.7 to 60 FPS, and Chrome from 12.6 to 32.2 FPS. The draw time is
  36 to 43 % lower on the Pixel 8a, 6 to 19 % on macOS, 6 to 24 % on the iPhone and 59 % in
  Chrome. The raster time is 25 to 73 % lower.
- **No bar clip.** It is a gain on the three platforms where the variant ran: 41 to 50 FPS at
  1000 bars on the Pixel 8a, 40 to 60 FPS at 5000 bars on macOS, and half the raster time at 1000
  bars in Chrome.
- **The ring.** `drawDRRect` gives a higher frame rate than `drawPath` on the phone (46.4 to 49.6
  FPS at 1000 bars) and in Chrome (24.2 to 32.2 FPS at 5000 bars). On macOS, it costs more raster
  time (8.9 to 12.7 ms at 5000 bars), at the same 60 FPS. The ring stays, because it gives the
  larger frame-rate gain where the frame rate is under the limit.
- **Arcs.** They change little. The native arc calls of section 8.2 stay.
- The pixel tests of the fast paths (`test/port/canvas/canvas_ui_round_rect_test.dart`,
  `test/port/helpers/helpers.canvas_ui_test.dart`, `test/port/elements/element.bar_ui_test.dart`)
  compare them with the upstream arc paths on flutter_tester. A look at the bars on the Pixel 8a
  and in Chrome showed the rounded tops, the border and the open bottom of `borderSkipped`.

## 9. Cut 2 (phase 5)

Work package C2 of [canvas-cuts-plan.md](canvas-cuts-plan.md) (§3.4, §3.10) changes the paint of
the chart host. The host gives `UiCanvasContext.paint` one scale for each axis. After
`retinaScale`, both scales are `1 / DPR`, the scale of the code before C2. This section has the
performance acceptance of the plan (§6.3) as an A/B test.

### 9.1 Method

- **Code.** "Before" is commit `69f9d97`, the library without C2, in a git worktree. On the Pixel
  8a, macOS and Chrome, "after" is the C2 change on top of `69f9d97`, and both sides ran in one
  session on 2026-10-19. The iPhone ran on 2026-10-20 (see below).
- **Builds.** Each scenario and each side had its own profile build of
  `apps/chartjs_gallery/lib/main_stress.dart`, with `--dart-define=MODE=<mode>` and
  `--dart-define=SCENARIO=<N>x<M>`. Each run is a fresh process or a fresh page load. It runs one
  scenario for 7 seconds.
- **Order.** The runs of a scenario alternate: before, after, before, after. Each side has 3 runs
  for each scenario (the first series). Thus a change of the device state affects the two sides
  alike.
- **Scenarios.** The six scenarios of the mode `primitives` (section 1), `elements` at 5000 + 50
  and 20000 + 0, `bars` at 1000 and `arcs` at 1000. All modes draw through the chart host.
- **Cells.** A figure cell gives the medians of FPS / draw (ms) / raster (ms). A noise cell gives
  the range from the minimum to the maximum of the runs.
- **Acceptance** (plan §6.3). The after median FPS is at least the before median minus the larger
  of 1 FPS and 2 %. The after medians of draw and raster are at most the before median times 1.05
  plus 0.2 ms. No single after run is outside the before range, widened by the same margins. A
  scenario with a miss ran 3 more pairs (the rerun). The acceptance then used these 3 pairs. A
  miss that stays is a failure.

The platforms:
- **Pixel 8a** (Android 17, Impeller on Vulkan, 60 Hz):
  `flutter build apk --profile --target-platform android-arm64`. A script installed the APK of
  each run with `adb install`. It started the app with `am start`. It read the `STRESS` line from
  `adb logcat`. The screen was on for all runs. In the first series, the battery temperature went from 29.7
  to 34.9 degrees Celsius. In the reruns, it was 30.0 to 31.5 degrees Celsius.
- **macOS** (Apple M3 Max, a 60 Hz Studio Display): `flutter build macos --profile`. A script
  started the app binary. It read the `STRESS` line from stdout. It brought the window to the
  front with `osascript` (`activate`), because a window behind other windows gets no frames. Two
  earlier series without this step had runs without frames on both sides. This section does not
  use them. In some runs of the first series, other windows covered the stress window. These runs
  have 33 to 57 FPS on both sides. Their draw and raster times are near the times of the other
  runs.
- **Chrome** (Chrome 155 in a visible window, DPR 2): `flutter build web --wasm --profile`, with
  skwasm. Each build had its own local port, with the headers
  `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp`. One
  tab loaded the page of each run. The raster time is on the skwasm worker. A CanvasKit build
  (`flutter build web --profile`, dart2js) ran one pair at `primitives` 5000 + 50.
- **iPhone 17 Pro** (iOS 26.6.2, up to 120 Hz, connected by cable): `flutter run --profile` of each
  side, one smoke pair for each scenario (plan §6.3). "Before" ran in a worktree of `69f9d97` and
  "after" in a worktree of `cd9024f`, on 2026-10-20, one day after the other platforms. The runs
  set the Xcode team, and a script restored both project files byte for byte.

### 9.2 Results

A row "runs 4 to 6" gives the 3 pairs after a miss. The column "Result" applies the acceptance to
the row.

**Pixel 8a:**

| Scenario | Before | Before noise | After | After noise | Result |
|---|---|---|---|---|---|
| primitives 1000 + 0 | 58.0 / 5.21 / 5.28 | 57.7-58.5 / 5.07-5.22 / 5.21-5.33 | 58.4 / 5.28 / 5.14 | 58.2-58.4 / 5.12-5.34 / 5.03-5.28 | pass |
| primitives 1000 + 50 | 58.7 / 5.49 / 5.42 | 58.5-59.0 / 5.40-5.64 / 5.41-5.63 | 58.7 / 5.47 / 5.63 | 58.7-58.7 / 5.44-5.50 / 5.38-5.68 | pass |
| primitives 5000 + 50 | 58.5 / 6.98 / 6.29 | 58.3-59.2 / 6.81-7.01 / 6.13-6.33 | 58.6 / 7.11 / 6.16 | 57.9-58.7 / 7.10-7.16 / 6.04-6.31 | pass |
| primitives 20000 + 0 | 59.0 / 9.86 / 9.49 | 58.9-59.2 / 9.75-9.94 / 9.47-9.69 | 59.4 / 9.84 / 9.57 | 59.2-59.4 / 9.78-9.95 / 9.30-9.59 | pass |
| primitives 1000 + 200 | 58.7 / 6.24 / 7.02 | 58.4-58.9 / 6.13-6.28 / 6.87-7.24 | 58.7 / 6.30 / 7.01 | 58.2-58.7 / 6.26-6.55 / 6.94-7.08 | pass |
| primitives 20000 + 200 | 58.5 / 10.88 / 10.81 | 58.0-58.9 / 10.74-11.09 / 10.75-10.82 | 59.0 / 10.83 / 10.66 | 58.5-59.2 / 10.55-10.95 / 10.61-10.91 | pass |
| elements 5000 + 50 | 58.0 / 8.18 / 6.12 | 57.7-58.5 / 8.09-8.24 / 6.10-6.22 | 58.4 / 7.89 / 6.18 | 58.2-58.7 / 7.86-8.15 / 6.17-6.28 | pass |
| elements 20000 + 0 | 36.8 / 16.72 / 9.24 | 32.0-42.8 / 14.94-18.75 / 9.16-9.24 | 39.3 / 15.78 / 8.97 | 32.5-45.6 / 14.40-18.34 / 8.84-9.03 | pass |
| bars 1000 | 47.8 / 10.92 / 14.72 | 47.4-48.3 / 10.85-11.14 / 14.57-14.89 | 46.9 / 11.02 / 14.88 | 45.9-48.6 / 10.98-11.35 / 14.77-14.90 | miss: one run 45.9 FPS (limit 46.4) |
| arcs 1000 | 35.7 / 15.70 / 19.81 | 35.6-36.6 / 15.59-15.94 / 19.09-19.81 | 33.6 / 16.47 / 21.80 | 32.9-34.9 / 16.17-16.51 / 21.05-22.16 | miss: FPS 33.6 (limit 34.7), raster 21.80 (limit 21.00) |
| bars 1000, runs 4 to 6 | 49.8 / 9.46 / 13.73 | 49.5-50.5 / 9.34-9.68 / 13.46-13.87 | 48.3 / 9.74 / 13.91 | 47.4-54.1 / 8.99-10.16 / 13.14-13.96 | miss: FPS 48.3 (limit 48.8), runs 48.3 and 47.4 FPS (limit 48.5) |
| arcs 1000, runs 4 to 6 | 41.0 / 13.46 / 17.57 | 40.1-44.7 / 12.36-13.89 / 17.26-17.62 | 42.3 / 13.31 / 17.07 | 40.8-43.1 / 13.31-13.65 / 16.83-17.34 | pass |
| bars 1000, runs 7 to 9, after first | 50.5 / 9.55 / 13.61 | 49.3-53.1 / 9.36-9.68 / 13.16-13.91 | 49.6 / 9.74 / 13.79 | 49.4-51.5 / 9.41-9.77 / 13.65-14.18 | pass (more figures, not part of the rule) |

**macOS:**

| Scenario | Before | Before noise | After | After noise | Result |
|---|---|---|---|---|---|
| primitives 1000 + 0 | 60.0 / 0.46 / 2.12 | 60.0-60.0 / 0.46-0.46 / 2.08-2.14 | 60.0 / 0.45 / 2.09 | 59.5-60.0 / 0.44-0.46 / 2.05-2.12 | pass |
| primitives 1000 + 50 | 60.0 / 0.52 / 2.11 | 60.0-60.0 / 0.52-0.55 / 2.09-2.19 | 60.0 / 0.53 / 2.14 | 60.0-60.0 / 0.52-0.53 / 2.08-2.15 | pass |
| primitives 5000 + 50 | 60.0 / 1.29 / 11.28 | 60.0-60.0 / 1.26-1.30 / 10.85-14.85 | 60.0 / 1.28 / 10.86 | 60.0-60.0 / 1.26-1.28 / 10.60-10.87 | pass |
| primitives 20000 + 0 | 60.0 / 4.09 / 15.96 | 60.0-60.0 / 4.07-4.11 / 15.96-15.99 | 60.0 / 4.07 / 15.96 | 60.0-60.0 / 4.07-4.10 / 15.90-16.01 | pass |
| primitives 1000 + 200 | 60.0 / 0.75 / 2.25 | 60.0-60.0 / 0.73-0.79 / 2.23-2.31 | 60.0 / 0.77 / 2.26 | 60.0-60.0 / 0.75-0.78 / 2.23-2.32 | pass |
| primitives 20000 + 200 | 52.5 / 4.30 / 16.73 | 33.3-56.6 / 4.27-4.38 / 16.18-17.22 | 57.0 / 4.37 / 16.81 | 41.5-60.0 / 4.35-4.88 / 16.30-17.08 | miss: one run 4.88 ms draw (limit 4.80) |
| elements 5000 + 50 | 55.3 / 1.92 / 9.66 | 46.7-60.0 / 1.90-1.93 / 9.36-9.98 | 60.0 / 1.93 / 9.71 | 40.7-60.0 / 1.90-1.95 / 9.66-9.82 | miss: one run 40.7 FPS (limit 45.7) |
| elements 20000 + 0 | 60.0 / 6.54 / 8.36 | 43.1-60.0 / 6.40-6.62 / 7.83-8.47 | 60.0 / 6.49 / 7.87 | 43.5-60.0 / 6.44-6.60 / 7.87-8.47 | pass |
| bars 1000 | 60.0 / 2.78 / 2.92 | 60.0-60.0 / 2.73-2.79 / 2.90-2.95 | 60.0 / 2.79 / 2.94 | 59.5-60.0 / 2.77-2.81 / 2.93-2.95 | pass |
| arcs 1000 | 59.5 / 4.09 / 7.58 | 36.0-60.0 / 4.08-4.70 / 7.20-7.74 | 59.8 / 4.08 / 7.24 | 56.5-60.1 / 4.05-4.09 / 7.13-7.38 | pass |
| primitives 20000 + 200, runs 4 to 6 | 60.0 / 4.30 / 16.06 | 59.8-60.0 / 4.29-4.31 / 16.03-16.12 | 60.0 / 4.36 / 16.09 | 59.8-60.0 / 4.35-4.36 / 16.08-16.09 | pass |
| elements 5000 + 50, runs 4 to 6 | 60.0 / 1.89 / 9.22 | 60.0-60.0 / 1.88-1.90 / 9.19-9.23 | 60.0 / 1.90 / 9.13 | 60.0-60.0 / 1.88-1.91 / 9.11-9.20 | pass |

**Chrome** (dart2wasm, skwasm):

| Scenario | Before | Before noise | After | After noise | Result |
|---|---|---|---|---|---|
| primitives 1000 + 0 | 60.2 / 1.32 / 6.04 | 60.2-60.2 / 1.32-1.33 / 6.01-6.10 | 60.2 / 1.34 / 6.06 | 60.2-60.2 / 1.32-1.34 / 6.05-6.10 | pass |
| primitives 1000 + 50 | 60.2 / 1.54 / 6.18 | 60.1-60.2 / 1.54-1.55 / 6.12-6.23 | 60.2 / 1.54 / 6.20 | 60.2-60.3 / 1.52-1.54 / 6.15-6.22 | pass |
| primitives 5000 + 50 | 60.2 / 4.90 / 25.30 | 60.2-60.2 / 4.89-4.90 / 24.95-25.34 | 60.3 / 4.92 / 25.18 | 60.2-60.3 / 4.86-4.92 / 25.08-25.42 | pass |
| primitives 20000 + 0 | 53.7 / 17.55 / 37.74 | 53.5-53.9 / 17.43-17.60 / 37.60-38.08 | 52.4 / 17.92 / 38.82 | 52.3-53.4 / 17.64-18.00 / 38.27-38.93 | miss: FPS 52.4 (limit 52.6), one run 52.3 FPS (limit 52.4) |
| primitives 1000 + 200 | 60.2 / 2.08 / 6.53 | 60.2-60.2 / 2.08-2.09 / 6.52-6.59 | 60.3 / 2.08 / 6.52 | 60.3-60.3 / 2.07-2.10 / 6.46-6.52 | pass |
| primitives 20000 + 200 | 51.1 / 18.43 / 39.97 | 50.6-51.4 / 18.28-18.62 / 39.79-40.32 | 50.8 / 18.55 / 40.25 | 48.8-51.0 / 18.50-19.38 / 40.16-41.92 | miss: one run 48.8 FPS (limit 49.6) |
| elements 5000 + 50 | 60.2 / 7.19 / 22.97 | 60.2-60.2 / 7.15-7.23 / 22.87-23.05 | 60.2 / 7.21 / 22.96 | 60.1-60.2 / 7.17-7.23 / 22.88-22.96 | pass |
| elements 20000 + 0 | 37.0 / 25.74 / 27.59 | 36.3-37.0 / 25.70-26.22 / 27.41-28.03 | 37.3 / 25.57 / 27.39 | 37.2-37.6 / 25.34-25.62 / 26.85-27.42 | pass |
| bars 1000 | 60.3 / 6.05 / 8.73 | 60.2-60.3 / 5.94-6.05 / 8.70-8.95 | 60.2 / 6.04 / 8.76 | 60.2-60.3 / 5.91-6.06 / 8.72-8.92 | pass |
| arcs 1000 | 52.6 / 18.11 / 38.66 | 52.3-52.9 / 18.02-18.24 / 38.39-38.89 | 52.5 / 18.16 / 38.60 | 52.5-52.6 / 18.15-18.18 / 38.47-38.70 | pass |
| primitives 20000 + 0, runs 4 to 6 | 52.8 / 17.82 / 38.43 | 52.7-53.8 / 17.51-17.83 / 37.81-38.50 | 53.5 / 17.58 / 38.18 | 53.2-53.9 / 17.42-17.65 / 37.97-38.31 | pass |
| primitives 20000 + 200, runs 4 to 6 | 50.9 / 18.48 / 40.05 | 50.4-51.4 / 18.29-18.71 / 39.80-40.36 | 50.7 / 18.59 / 40.32 | 50.2-50.7 / 18.56-18.78 / 40.30-40.66 | pass |
| CanvasKit, primitives 5000 + 50, one pair | 39.4 / 2.45 / 23.52 | one run | 39.6 / 2.46 / 22.37 | one run | pass |

**iPhone 17 Pro** (one pair for each scenario):

| Scenario | Before | Before noise | After | After noise | Result |
|---|---|---|---|---|---|
| primitives 1000 + 0 | 116.4 / 1.27 / 1.00 | one run | 120.0 / 1.34 / 1.03 | one run | pass |
| primitives 20000 + 200 | 119.8 / 2.95 / 0.96 | one run | 120.0 / 3.03 / 0.95 | one run | pass |

### 9.3 Acceptance

- **Pixel 8a.** 9 of 10 scenarios pass. `arcs` 1000 missed in the first series and passed in the
  rerun. `bars` 1000 missed the FPS criterion in the first series and in the rerun. Its draw and
  raster medians stayed in the limits in all series. Thus `bars` 1000 on the Pixel 8a fails the
  acceptance of plan §6.3.
- **`bars` 1000 on the Pixel 8a, more figures.** 3 more pairs with the after run first passed
  (the row "runs 7 to 9, after first"). Over the 9 pairs, the median difference after minus before
  is -1.1 FPS (-2.1 %), +0.17 ms of draw (+1.6 %) and +0.18 ms of raster (+1.2 %). The after run
  is slower in 6 of the 9 pairs. Single runs of this mode go from 45.9 to 54.1 FPS. In each frame,
  C2 changes only the paint and the size check of the host. The paint uses one `scale` of
  `1 / DPR`, as before C2. The cause of the miss is not known. No library code changed after the
  runs. Section 9.5 gives an A/A control and 12 more pairs, and the decision.
- **macOS.** All 10 scenarios pass. `primitives` 20000 + 200 and `elements` 5000 + 50 had one run
  outside the limits in the first series. Other windows covered the stress window in these runs.
  Both scenarios passed in the rerun.
- **Chrome.** All 10 scenarios pass. `primitives` 20000 + 0 and 20000 + 200 missed the FPS
  criterion in the first series. Both passed in the rerun. The CanvasKit pair passes.
- **iPhone 17 Pro.** Both smoke pairs pass. Both sides run at the 120 Hz limit. The draw time of
  the after run is 0.07 ms and 0.08 ms longer, in the limit of 5 % + 0.2 ms.

### 9.4 Not measured

- `POINT_STYLE=rectRounded` at 5000 + 0 and 20000 + 0 (plan §6.3), also in the CanvasKit run. The
  stress entry has no `POINT_STYLE` define, because work package A3 did not run.
- The arc micro-benchmark of plan §6.3. It measures cut 1. C2 does not change the arc path.
- The cut 2 web checks of plan §6.4 (the browser zoom, a move between displays) and the look at
  the Stress tab on the Pixel 8a (plan §3.8, risk 1). They are not performance figures.

### 9.5 `bars` 1000 on the Pixel 8a: the A/A control and more pairs

The miss of section 9.3 was open item 0 of phase 5. This section tests if C2 causes it.

**Method.**
- **Code.** "Before" is commit `69f9d97` and "after" is commit `cd9024f` (C2), each in its own git
  worktree. Each side has one profile build of `bars` 1000, as in section 9.1. A third APK
  ("control") is a byte copy of the before APK.
- **Order.** Each series alternates the first side: pair 1 runs A then B, pair 2 runs B then A
  (ABBA). Thus an effect of the run position cancels.
- **Series.** An A/A control of before against control (8 pairs). 12 more A/B pairs. A padded
  control of before against before plus 200 bytes of code that runs once (12 pairs, see below).
  All series ran on 2026-10-19 with the screen on. The battery temperature was 29.1 to 30.3
  degrees Celsius in the A/A control and 30.6 to 33.6 in the A/B pairs. It was 34.1 to 35.1 in the
  padded control.
- **Interval.** The 95 % interval is the bootstrap percentile interval of the mean pair
  difference, with 20000 resamples.

**Results.** The side cells give the medians of FPS / draw (ms) / raster (ms). A difference is
the mean of the pair differences, second side minus first side, with its 95 % interval.

| Series | Pairs | First side | Second side | FPS difference (95 % interval) | Draw difference | Raster difference |
|---|---|---|---|---|---|---|
| A/A: before, control | 8 | 48.8 / 9.65 / 13.95 | 48.8 / 9.78 / 14.05 | +0.43 (-2.17 to +2.78) | -0.04 (-0.37 to +0.31) | +0.03 (-0.32 to +0.40) |
| A/B: before, after (new pairs) | 12 | 47.6 / 10.09 / 14.24 | 46.9 / 10.22 / 14.16 | -0.59 (-1.35 to +0.20) | +0.21 (+0.04 to +0.37) | -0.02 (-0.15 to +0.11) |
| A/B: before, after (section 9.2 and the new pairs) | 21 | 48.3 / 9.88 / 14.00 | 47.4 / 10.16 / 14.11 | -0.56 (-1.32 to +0.26) | +0.18 (+0.03 to +0.32) | +0.05 (-0.08 to +0.18) |
| Padded: before, before + 200 bytes | 12 | 45.5 / 10.76 / 14.68 | 46.5 / 10.91 / 14.57 | +0.29 (-1.08 to +1.88) | -0.07 (-0.35 to +0.18) | -0.04 (-0.30 to +0.23) |

- **The acceptance rule on identical APKs.** The A/A control has two blocks of 3 pairs. Both
  blocks miss the FPS criterion of plan §6.3. Single runs go from 44.5 to 53.1 FPS. Thus the 3-pair
  rule cannot resolve this scenario on this phone.
- **The new A/B pairs.** The 12 pairs pass the rule as one set. Of the 4 blocks of 3 pairs, 3 pass
  and 1 misses.
- **FPS and raster.** Over the 21 pairs, the 95 % intervals of the FPS and the raster differences
  include 0. Thus the frame rate and the raster time have no measured change.
- **The host paint.** The build time minus the draw time is the UI-thread time outside the chart
  draw. It contains the layout and the paint of the host. After C2, it is 0.05 ms shorter (mean
  over the 21 pairs).
- **The draw.** The draw time is 0.18 ms (1.8 %) longer, and its interval excludes 0. This is in
  the draw limit of the plan (5 % + 0.2 ms). C2 changes no source line of the draw path.
- **AOT code.** Both builds printed their instruction sizes
  (`--extra-gen-snapshot-options=--print-instructions-sizes-to`). Each function of
  `element.bar.dart`, `helpers.canvas.dart`, `canvas_ui_path.dart`, `canvas_ui_paint.dart` and
  `stress_demo.dart` has the same size in both builds. The per-frame host code of C2 is smaller:
  `_paintCanvas` has 380 bytes (760 before), and `displaySize` has 336 bytes (`chartSize` had 428).
  The whole snapshot is 512 bytes larger.
- **The padded control.** The variant changes one line of `canvas_ui.dart` in the before
  worktree. The `UiCanvasElement` constructor parses a string once: 200 bytes of code, in the
  class that C2 changes. The control does not show a placement effect on the draw, and its
  interval does not exclude an effect of 0.18 ms. The phone was warmer in this series.

**Decision** (decision protocol of phase 5). Cut 2 stays.
- Priority 1, the upstream behavior: cut 2 passes the 5 named spec cases of plan §3.6. A harness
  workaround needs `diverges:` rows for the cases with canvas attributes.
- Priority 2, performance: the frame rate and the raster time have no measured change. The code
  that C2 changes in each frame is smaller, and the UI-thread time outside the draw is not longer.
  Thus no faster form of the C2 code is available. The draw shift of 0.18 ms is in code that C2
  does not change. Its cause is not known.
- porting-flow.md §1.1 does not block the cut: the frame rate of `bars` 1000 is not measurably
  slower.

## 10. Core (phase 5)

### 10.1 Animations

The forms of [Chart.js ADR 0019](adr/0019-animation.md) §11 come from the judge probe J1 of that
ADR. The figures of the real port come from a scratch benchmark of the ported files. Bed: Apple M3
Max, macOS 26.5.1, Dart 3.12.2. "AOT" is `dart compile exe`. "wasm" is `dart compile wasm -O2`,
run in Node.js v24.12.0 (arm64), for times only. Each figure of the port is the median of 9 runs,
and a cell gives the lowest and the highest median of 3 runs.

One animator frame with every item active, in microseconds:

| Case | ADR 0019 §11, form N, AOT | ADR 0019 §11, form N, wasm | Port, AOT | Port, wasm |
|---|---|---|---|---|
| 20000 `PointElement` x 2 (`x`, `y`) | 738-784 | 616-670 | 503-518 | 698-705 |
| 1000 `ArcElement` x 6 | 120 | 139-145 | 100-105 | 153-155 |
| 1000 Maps x 2 colors | — | — | 556-570 | 312-314 |

Other costs:
- One `Animation` constructor (row `adapt-animation-spec`) with an `AnimationSpec` config: 185-189
  ns (AOT) and 93-99 ns (wasm). With a Map config: 298-300 ns (AOT) and 285-298 ns (wasm).
  The probe F5 of the ADR gave 105 ns (AOT) and 141 ns (wasm) with an `AnimationSpec`. The typed
  config stays the faster form. The absolute AOT figure of the port differs from the probe.
- The number path (row `adapt-animation-number-path`) has the typed field `_element`. On AOT,
  20000 x 2 takes 550-575 us before the field and 503-518 us after it. On wasm, it takes 719-748 us
  before and 698-705 us after. The 1000 arcs x 6 do not change.
- The color cache (row `adapt-animation-color-cache`): line by line, a color tick costs 1832-1943
  ns (AOT) and 1460-1732 ns (wasm). With the cache, it costs 437-489 ns (AOT) and 250-310 ns (wasm)
  (ADR 0019, Evidence F1).
- `jsMapForEach` with one chart: 99-109 ns (AOT) and 116-117 ns (wasm) in each frame.
  `Map.forEach` takes 5-7 ns.

### 10.2 A hit test with a JS `null` coordinate

The review of phase 5 made the coordinates of `inRange`, `inXRange` and `inYRange` `double?`.
Thus an interaction mode passes a JS `null` coordinate to the element unchanged
(core.interaction.js:125, :174, :234, :236). A `BarElement` reads `null` as "ignore this axis"
(element.bar.js:103-111). A nullable parameter can need a boxed value. A scratch A/B benchmark
calls `inRange` through `types.VisualElement` on 20000 elements, with non-null coordinates. Bed:
Apple M3 Max, AOT, 27 batches of each side in 3 alternating processes. A cell gives the median and
the range of the batches, in ns for each call:

| Element | Before (`double`) | After (`double?`) |
|---|---|---|
| `PointElement` | 33.8 (32.1-35.9) | 33.6 (32.2-35.6) |
| `BarElement` | 52.8 (50.2-55.4) | 53.5 (50.8-55.8) |

The change has no measured cost. The upstream hit element ranks first in any case (porting-flow.md
§1.1).

### 10.3 Parsed items of any type

The review of phase 5 made `ChartMeta.parsed` a `List<Object?>`, as `_parsed: unknown[]` is
(index.d.ts:503). With `parsing: false` and primitive data, upstream throws nothing, where the
port with a `List<Map>` threw a `TypeError`. The hot readers (`getMinMax`, `getAllParsedValues`,
the stacks, `core.interaction` and `helpers.extras`) read a Map item with the Map read, and another
item with `jsGet`. A scratch A/B benchmark reads `isFinite(item['y'])` for 20000 items. Bed: Apple
M3 Max, AOT, 13 batches. The typed list `List<Map<String, Object?>>` takes 7.8-8.7 ns for each
read. The `List<Object?>` with the test `item is Map<dynamic, dynamic>` takes 9.7-10.4 ns. A test
of `Map<String, Object?>` gives the same time. Thus a full `getMinMax` pass over 20000 items costs
about 40 us more. A sorted dataset stops at its first and last item. The upstream behavior ranks
first (porting-flow.md §1.1). The test `Map<dynamic, dynamic>` is the form that dart2wasm tests
without a compare of the type arguments (the comment of `jsGet`).

### 10.4 The animated stress case

`--dart-define=MODE=chart --dart-define=CALL=animate` (section 6) gives the frame figures of the
animator in a real chart. `drawMs` is the draw that the animator calls. `animatorMs` is the tick of
the N animations before that draw. Section 10.9 has the figures of the Pixel 8a and the iPhone.
The figures of macOS and Chrome with dart2wasm are open (section 7).


### 10.5 CPU profile of the chart path

The mode `chart` in case (a) ([Chart.js ADR 0021](adr/0021-typed-options-in-the-resolver.md)
§8: `CALL=draw`, `SHARING=1`, typed options) and the mode `elements` with `LINE=0` draw the same
N points. This section compares their CPU profiles at 20000 + 0.

**Method.**
- **Code.** Commit `286470e`, the phase 5 tree before the change of section 10.6. Each mode has
  its own profile build, as in section 9.1.
- **Profile.** A script starts one fresh process. A CPU profile of 10 seconds comes from the VM
  service (`getCpuSamples`, a sample period of 1 ms). On the Pixel 8a, `adb forward` gives the
  port of the VM service. The counts are the samples under the draw: `_StressChart.draw` in the
  mode `chart`, `DemoChart.render` in the mode `elements`.
- **Interrupt samples.** In all profiles, 16 to 44 % of the samples have the VM tag
  `DRT_InterruptOrStackOverflow`. Such a sample goes to the function with the next interrupt
  check, for example a function entry. Thus a count of one small function can include these
  samples. A comparison of two builds uses the samples without this tag.
- **GC.** The VM timeline (the streams `GC`, `Dart` and `Embedder`) of 10 seconds gives the
  scavenges of `elements` 20000 + 0 with its line, before (`cd9024f`) and after (`286470e`).

**Results.**

| Part of the draw | macOS, `chart` | macOS, `elements` | Pixel 8a, `chart` | Pixel 8a, `elements` |
|---|---|---|---|---|
| All samples of the draw | 1946 | 1923 | 5376 | 3779 |
| `PointElement.draw` | 1355 | 1376 | 4278 | 2478 |
| The loop of `DatasetController.draw` or `_drawElements` without `PointElement.draw` | 287 | 47 | 103 | 159 |
| The read `element['hidden']` of that loop | 256 (169 with the interrupt tag) | — | 31 | — |

- **Upstream work.** For each point, the chart path does the loop of
  `core.datasetController.js:728-738`: the read `element.hidden`, the read `element.active`, and
  the call `element.draw(ctx, area)`. For each draw, `Chart.draw` clears the canvas, calls the
  plugin hooks, sorts the visible metas and reads the clip of the dataset
  (`core.controller.js:698-809`). These parts of each draw are below 1 % of the samples.
- **Costs of the port.** The read `element['hidden']` goes through the `switch` of
  `PointElement.operator []` (8 names), the `switch` of `Element.operator []` (5 names) and
  `Element._extra`. On macOS it has 13 % of the samples of the chart draw (7 % without the
  interrupt samples). On the Pixel 8a it has 0.6 %. `_at` with a `double` index, `jsTruthy`, the
  casts `as Element` and `as types.VisualElement`, and the read
  `jsGet(options, 'drawActiveElementsOnTop')` have 0.1 to 0.7 % together. Section 10.6 removes
  the cost of the read `hidden`. After that change, the loop has 18 of 1757 samples (1 %) on
  macOS.
- **Work of the elements mode only.** The mode `elements` writes `x` and `y` of each point in
  each frame. Each write stores a new boxed `double` into an old element. Case (a) writes no
  positions.
- **`PointElement.draw`.** Both modes call it with the same options and the same canvas. On the
  Pixel 8a, the counts of its small functions differ between the two builds (for example
  `canvasNumber`, 6.3 % and 2.5 %). The two builds have other code, and thus other inline
  decisions.
- **GC of `elements` 20000 + 0.** Before and after, the timeline has 195 scavenges in 10 seconds.
  `CollectNewGeneration` takes 1054 ms before and 1033 ms after. `IterateStoreBuffers`, the scan of
  the old elements that point to the new boxed values, takes 1521 ms and 1441 ms on the scavenger
  tasks. The GC does not change.
- **`elements` 20000 + 0, before and after.** Without the interrupt samples, the shares of the
  functions are equal in the two builds: for example `PointElement.draw` 57.6 % and 57.8 %,
  `LineElement.draw` 27.7 % and 27.8 %, and the native atlas draw 15.5 % and 15.6 %. Section 10.8
  has the frame figures.

### 10.6 Change: the declared `hidden` of `Element`

`DatasetController.draw` reads `element.hidden` for each element in each draw
(`core.datasetController.js:730`). `core.element.ts` does not declare `hidden`.
`_updateVisibility` writes it (`core.controller.js:898`), and user code can write any value.
[Chart.js ADR 0017](adr/0017-element-properties.md) (Consequences) permits a declared property
when a ported caller reads it often.

The forms:

| Form | The read in `DatasetController.draw` |
|---|---|
| Upstream | `if (element.hidden)`: a property read of the element. A data element without the property gives `undefined`. |
| Before (the port of phase 5) | `jsTruthy(element['hidden'])`: the read by name of section 10.5, which ends in `Element._extra`. |
| After | `jsTruthy(element.hidden)`: the field `Object? hidden = undefined` of `Element`. The read and the write by name use the same field. |

A third form puts `'hidden'` first in each `switch`. It keeps a string compare for each element and
each draw. The field has less work, so the third form was not measured.

**Behavior.** The field keeps any value, as an extra property does: the `undefined` sentinel at the
start, Dart `null` for JS `null`, and other values as they are. The write by name, `assign` and the
animations write it by name. `_updateVisibility` writes it with the setter. The tests:
- `test/port/core/core.element_test.dart`, group `hidden`.
- `test/port/core/core.datasetController_test.dart`, scenario `draw with hidden values`. The
  reference comes from `src/core/core.datasetController.js` in Node.js v24.12.0 on x64. The values
  `1`, `'a'` and `{}` hide their point. The values `0`, `''`, `null`, `undefined` and `false` do
  not. The before form also passes this scenario.

**Figures.** "Before" is `286470e` and "after" is the change. Each scenario has 3 ABBA pairs of
fresh processes, as in section 9.1. A rerun has 3 more pairs. The cells give the medians of FPS /
draw (ms) / raster (ms). A difference is the mean of the pair differences, after minus before,
with its 95 % bootstrap interval.

| Platform | Scenario | Before | After | Draw difference | FPS difference |
|---|---|---|---|---|---|
| Pixel 8a | `chart` case (a), 1000 | 58.2 / 5.66 / 4.94 | 58.5 / 5.58 / 5.04 | -0.11 (-0.23 to -0.02) | +0.21 (+0.15 to +0.31) |
| Pixel 8a | the same, rerun | 58.8 / 5.42 / 4.80 | 58.9 / 5.10 / 4.83 | -0.33 (-0.36 to -0.31) | +0.06 (-0.34 to +0.50) |
| Pixel 8a | `chart` case (a), 5000 | 58.2 / 7.80 / 4.93 | 58.4 / 7.59 / 4.91 | -0.24 (-0.32 to -0.11) | +0.23 (-0.32 to +0.67) |
| Pixel 8a | `chart` case (a), 20000 | 46.7 / 14.42 / 8.18 | 53.4 / 13.02 / 8.24 | -0.50 (-2.05 to +0.82) | +2.15 (-6.00 to +11.63) |
| Pixel 8a | the same, rerun | 46.1 / 14.29 / 8.20 | 53.1 / 13.26 / 8.02 | -0.75 (-1.03 to -0.36) | +3.17 (+0.84 to +7.01) |
| Pixel 8a | `chart` case (a), `SHARING=0`, 20000 | 37.7 / 15.85 / 8.42 | 39.5 / 15.19 / 8.66 | -1.13 (-2.91 to +0.13) | +2.91 (-1.50 to +8.47) |
| macOS | `chart` case (a), 5000 | 60.0 / 1.63 / 0.78 | 60.0 / 1.57 / 0.80 | -0.07 (-0.08 to -0.06) | -0.37 (-1.10 to +0.00) |
| macOS | `chart` case (a), 20000 | 60.0 / 5.53 / 1.56 | 59.8 / 5.18 / 1.65 | -0.34 (-0.36 to -0.32) | +0.09 (-0.22 to +0.66) |
| macOS | the same, rerun | 60.0 / 5.60 / 1.60 | 60.0 / 5.27 / 1.61 | -0.31 (-0.34 to -0.29) | +0.11 (+0.00 to +0.33) |
| macOS | `chart` case (a), `SHARING=0`, 20000 | 60.0 / 5.54 / 1.54 | 60.0 / 5.24 / 1.54 | -0.31 (-0.33 to -0.30) | -0.03 (-0.09 to +0.00) |
| Chrome (dart2wasm) | `chart` case (a), 5000 | 60.2 / 1.87 / 1.85 | 60.3 / 1.76 / 1.87 | -0.11 (-0.15 to -0.05) | +0.05 (-0.02 to +0.10) |
| Chrome (dart2wasm) | `chart` case (a), 20000 | 60.2 / 5.83 / 2.32 | 60.2 / 5.40 / 2.30 | -0.42 (-0.48 to -0.34) | -0.01 (-0.09 to +0.07) |
| macOS | `elements`, `LINE=0`, 20000 | 59.9 / 5.63 / 1.54 | 60.0 / 5.69 / 1.55 | +0.04 (-0.02 to +0.07) | +0.09 (+0.00 to +0.17) |
| Pixel 8a | `bars` 1000 (6 pairs) | 45.1 / 11.31 / 14.93 | 46.7 / 10.73 / 14.50 | -0.23 (-0.63 to +0.17) | +0.66 (-0.96 to +2.35) |

- The rows with a rerun had one run outside the limits of plan §6.3 in the first series: on the
  Pixel 8a, one run of 40.7 FPS at 20000 and one raster time of 5.48 ms at 1000, and on macOS one
  raster time of 2.96 ms. The reruns pass.
- The change makes the chart draw faster on the three platforms: by 0.31 to 0.34 ms (6 %) on
  macOS and 0.42 ms (7 %) in Chrome at 20000, and by 0.11 to 0.75 ms on the Pixel 8a. No measured
  scenario is slower. `elements` and `bars` do not read `hidden`, and their figures do not change.
- Decision: keep the change (porting-flow.md §1.1). The upstream behavior is the same, and the
  lines of `DatasetController.draw` keep the upstream form. Thus it needs no `DIVERGES` marker
  and no `differences.md` row.
- The Pixel 8a battery temperature was 33.5 to 36.2 degrees Celsius in these series. In the first
  macOS series, another window was in front at the start or at the end of 5 runs. These runs have
  58.7 to 60.1 FPS, and their draw times are near the times of the other runs. The macOS rerun had
  the stress window in front in all runs. In Chrome, another window was in front at the start of
  one run, with 60.2 FPS.

### 10.7 The draw cost for each point (Chart.js ADR 0021 §8)

[Chart.js ADR 0021](adr/0021-typed-options-in-the-resolver.md) §8 gives the acceptance: in case
(a) with typed classes, the draw time for each point equals the mode `elements` with typed options.
The mode `elements` with `LINE=0` draws the same points without a line (section 6).

**Method.** Each series alternates the chart build and the elements build of the same N (ABBA, 3
pairs at each N). A difference is the mean of the pair differences, chart minus elements, with its
95 % bootstrap interval. The cost for each point is the change of the draw time from N = 1000 to N
= 20000, divided by 19000. The difference for each point comes from the pair differences.

**Results** (the draw medians in ms, with the range of the runs):

| Platform and code | N | Chart, case (a) | Elements, `LINE=0` | Chart minus elements |
|---|---|---|---|---|
| Pixel 8a, before section 10.6 | 1000 | 5.67 (5.56-5.76) | 5.53 (5.34-5.58) | +0.18 (-0.02 to +0.33) |
| | 5000 | 7.84 (7.72-7.97) | 7.67 (7.43-7.86) | +0.19 (-0.14 to +0.54) |
| | 20000 | 12.84 (12.34-13.14) | 12.98 (12.85-13.17) | -0.23 (-0.51 to -0.03) |
| Pixel 8a, after section 10.6 | 1000 | 5.75 (5.37-5.84) | 5.40 (5.38-5.59) | +0.20 (-0.22 to +0.46) |
| | 5000 | 7.50 (7.44-7.50) | 7.49 (7.48-7.77) | -0.10 (-0.27 to +0.02) |
| | 20000 | 14.79 (12.73-16.10) | 14.02 (13.36-17.05) | -0.27 (-0.95 to +0.77) |
| macOS, before section 10.6 | 1000 | 0.57 (0.57-0.57) | 0.56 (0.55-0.56) | +0.01 (+0.01 to +0.02) |
| | 5000 | 1.71 (1.71-1.71) | 1.63 (1.63-1.65) | +0.07 (+0.06 to +0.08) |
| | 20000 | 5.65 (5.61-5.72) | 5.66 (5.65-5.67) | +0.00 (-0.05 to +0.05) |
| macOS, after section 10.6 | 1000 | 0.53 (0.53-0.55) | 0.54 (0.53-0.54) | +0.00 (-0.01 to +0.01) |
| | 5000 | 1.60 (1.57-1.61) | 1.61 (1.60-1.62) | -0.02 (-0.03 to -0.01) |
| | 20000 | 5.27 (5.27-5.28) | 5.63 (5.62-5.66) | -0.36 (-0.39 to -0.34) |

The cost for each point, in µs:

| Platform and code | Chart, case (a) | Elements, `LINE=0` | Chart minus elements |
|---|---|---|---|
| Pixel 8a, before section 10.6 | 0.377 | 0.392 | -0.021 (-0.036 to -0.007) |
| Pixel 8a, after section 10.6 | 0.476 | 0.454 | -0.025 (-0.067 to +0.028) |
| macOS, before section 10.6 | 0.267 | 0.268 | -0.001 (-0.003 to +0.002) |
| macOS, after section 10.6 | 0.249 | 0.268 | -0.019 (-0.021 to -0.018) |

- **Acceptance.** Case (a) passes on the Pixel 8a and on macOS, also before section 10.6. The
  cost for each point of the chart is equal to the elements mode or smaller. After section 10.6,
  the chart draw at 20000 points is 0.36 ms (6 %) shorter than the elements mode on macOS.
- **The earlier figures.** A first measurement gave 16.63 ms for the chart at 20000 and 13.70 ms
  for the elements mode. These figures came from two series about 30 minutes apart, at a battery
  temperature of 26.6 and 36.3 degrees Celsius. On the Pixel 8a, the frequency of the big core
  changes from 1.4 to 2.9 GHz between runs (section 10.8). Thus only figures of the same ABBA
  series are comparable. The per-point medians of the second Pixel 8a series include a thermal
  drift: the 20000 runs go from 12.7 to 17.1 ms. The pair differences cancel the drift.
- **The remaining difference.** At 1000 points on the Pixel 8a, the chart draw is 0.18 to 0.20 ms
  longer, with intervals that include 0. This part does not grow with N. It is the work of each
  draw: `Chart.draw` clears the canvas, calls the plugin hooks, sorts the visible metas and reads
  the clip of the dataset (section 10.5). This is upstream work. No difference for each point
  remains.

### 10.8 `elements` 20000 + 0 on the Pixel 8a

The regression set of phase 5 (before is `cd9024f`, after is `286470e`, 3 ABBA pairs) missed the
FPS median criterion of plan §6.3 in `elements` 20000 + 0. This section measures more pairs and
looks for a cause.

**Series.** Each row is one ABBA series. "Phase 5" is `286470e` or the change of section 10.6.
That change does not touch the draw of the mode `elements`. The cells give the medians of FPS /
draw (ms) / raster (ms). The differences are phase 5 minus before.

| Series | Pairs | Before | Phase 5 | Draw difference | FPS difference | Plan §6.3 |
|---|---|---|---|---|---|---|
| `286470e`, the regression set and 6 more pairs | 9 | 43.1 / 15.15 / 8.88 | 38.1 / 16.21 / 9.10 | +0.75 (+0.12 to +1.39) | -2.59 (-4.74 to -0.56) | miss: FPS median, draw median |
| Section 10.6, set 1 | 6 | 42.6 / 15.00 / 9.00 | 42.5 / 15.41 / 9.03 | +0.15 (-0.81 to +1.03) | -0.01 (-2.94 to +2.69) | pass |
| Section 10.6, set 2 | 6 | 32.2 / 18.66 / 9.09 | 31.3 / 19.49 / 9.41 | +0.68 (-0.44 to +1.80) | -1.90 (-4.98 to +0.20) | pass |
| `286470e`, with the core frequency | 4 | 36.6 / 16.68 / 9.15 | 35.2 / 17.38 / 9.04 | +0.23 (-0.69 to +1.03) | -0.79 (-1.58 to +0.21) | miss: FPS median 35.2 (limit 35.6) |
| `286470e`, with the core frequency | 6 | 37.7 / 16.76 / 8.70 | 38.6 / 16.08 / 8.86 | -0.20 (-0.88 to +0.37) | -0.38 (-2.31 to +1.76) | pass |
| All | 31 | 38.7 / 15.84 / 8.93 | 36.8 / 16.74 / 9.09 | +0.37 (-0.03 to +0.76) | -1.30 (-2.46 to -0.20) | miss: FPS median 36.8 (limit 37.7) |

**Controls.**
- **A change in other code.** The worktree of the ADR 0021 §8 variant changes one line of
  `core.datasetController.dart`, which the mode `elements` does not run. Against `286470e`, its
  build gives +0.04 ms of draw (-0.54 to +0.62) and -0.11 FPS (-1.24 to +0.95) over 6 pairs.
- **`Element implements types.PropertyAccess`.** A probe build with `types.ElementPropertyRead`
  in place of `types.PropertyAccess` (one line, on top of section 10.6) is not faster: +0.79 ms of
  draw (+0.02 to +1.60) over 6 pairs, and -0.17 ms (-0.60 to +0.37) at the same core frequency
  (see below). The other phase 5 changes of the element files (the statics `jsClass`,
  `elementCfgArg` and `element_options.dart`) do not run in the draw of this mode.
- **Profile and GC.** Section 10.5: the shares of the functions and the GC are equal in the two
  builds.

**The core frequency.** Two series sample the frequency of the big core (cpu8) and the core of
the UI thread every 0.1 s on the device, in the window of each `STRESS` line. In 6 pairs, the mean
frequency falls from 2.82 to 1.43 GHz, and the draw rises from 13.9 to 20.1 ms. When the core is
slow, the UI thread also moves to the middle cores. A least-squares fit of the 12 runs gives
`draw = 7.95 ms + 19.11 ms GHz / f`, with a residual of 0.60 ms. At the same frequency, the phase 5
build is 0.26 ms faster (-0.76 to +0.24, a bootstrap over the pairs). The probe series gives
-0.17 ms (-0.60 to +0.37) in the same way.

**The rest of the regression set** (before `cd9024f`, after the change of section 10.6, 3 pairs):

| Scenario | Before | After | Draw difference | FPS difference | Plan §6.3 |
|---|---|---|---|---|---|
| `primitives` 20000 + 0 | 59.2 / 10.50 / 9.56 | 59.2 / 10.58 / 9.66 | +0.16 (+0.08 to +0.28) | -0.27 (-0.66 to +0.16) | pass |
| `bars` 1000 | 49.1 / 10.80 / 14.04 | 47.0 / 11.09 / 14.93 | +0.31 (-0.24 to +0.88) | -2.91 (-6.60 to -1.05) | miss: FPS median 47.0 (limit 48.1) |
| `arcs` 1000 | 34.9 / 16.23 / 20.57 | 34.4 / 16.23 / 20.52 | -0.10 (-0.70 to +0.39) | -0.51 (-1.71 to +0.13) | pass |
| `elements` 5000 + 50 | 57.8 / 8.41 / 6.08 | 58.7 / 8.28 / 6.28 | -0.16 (-0.26 to -0.10) | +0.95 (+0.82 to +1.18) | pass |

**Result.**
- Over 31 pairs, the phase 5 builds draw `elements` 20000 + 0 0.37 ms (2.7 %) longer, and the
  FPS median misses the criterion of plan §6.3 by 0.9 FPS. The raster time is 0.18 ms longer
  (+0.01 to +0.35). The time of the UI thread outside the draw does not change (-0.02 ms).
- The draw follows the frequency of the big core, which the thermal control of the phone sets.
  At the same frequency, the phase 5 build is not slower. The profile, the GC and the two controls
  show no code path that costs more. Thus no faster form is available, and no change follows.
- `bars` 1000 misses the FPS criterion against `cd9024f`. Section 10.6 does not cause the miss:
  against `286470e`, the change gives -0.23 ms of draw and +0.66 FPS over 6 pairs. Section 9.5
  has the spread of `bars` 1000 on this phone.
- `primitives` 20000 + 0 missed with one run in the regression set. It passes in this series.

### 10.9 The final series on the phones (commit `4c32e6b`)

The mode `chart` of section 6 and the regression set ran on the Pixel 8a and the iPhone 17 Pro on
2026-10-20, on commit `4c32e6b`.
- **Sides.** "Typed" is commit `4c32e6b`. "Plain" is the same commit with the one-line variant of
  Chart.js ADR 0021 §8: `_resolveElementOptions` gives `null` as `into`
  (`core.datasetController.dart:1548`), so each options object is a plain Map. "Before" is commit
  `cd9024f`.
- **Order.** Each series alternates the first side of each pair (ABBA). The Pixel ran 3 pairs for
  each scenario, and the iPhone 2 pairs for each chart scenario and 1 pair for each regression
  scenario.
- **Cells.** The medians of FPS / draw (ms) / raster (ms) / update (ms). The update is the time of
  `chart.update()` without its draw. A difference is the mean of the pair differences, typed minus
  plain, with its 95 % bootstrap interval.
- **Not measured.** macOS and Chrome (dart2wasm) did not run this series, because the Mac was in
  use (section 7). Section 10.6 has the A/B of the change of `hidden` on both.

**Pixel 8a, typed against plain** (the battery temperature went from 30.2 to 36.6 degrees Celsius):

| N | Case | Sharing | Plain | Typed | Draw difference |
|---|---|---|---|---|---|
| 1000 | (a) draw | on | 58.0 / 5.63 / 4.81 / 0.01 | 58.7 / 5.15 / 5.05 / 0.00 | -0.48 (-0.53 to -0.44) |
| 1000 | (b) update | on | 58.2 / 4.47 / 4.53 / 1.23 | 58.3 / 4.06 / 4.65 / 1.37 | -0.46 (-0.61 to -0.36) |
| 1000 | (c) update, scriptable | on | 51.9 / 2.56 / 10.64 / 8.38 | 56.0 / 2.22 / 10.68 / 7.57 | -0.35 (-0.43 to -0.22) |
| 1000 | (a) draw | off | 58.0 / 5.74 / 4.76 / 0.00 | 58.0 / 5.52 / 5.31 / 0.01 | -0.23 (-0.52 to +0.04) |
| 1000 | (b) update | off | 58.2 / 2.63 / 4.54 / 4.39 | 58.2 / 3.65 / 4.74 / 2.08 | +0.97 (+0.76 to +1.10) |
| 1000 | (c) update, scriptable | off | 52.0 / 2.61 / 10.59 / 8.44 | 54.4 / 2.24 / 10.54 / 7.73 | -0.38 (-0.43 to -0.34) |
| 5000 | (a) draw | on | 58.3 / 8.58 / 5.13 / 0.00 | 58.2 / 7.50 / 4.78 / 0.00 | -1.05 (-1.22 to -0.94) |
| 5000 | (b) update | on | 55.2 / 7.45 / 5.34 / 1.43 | 58.4 / 5.91 / 5.11 / 1.56 | -1.47 (-1.71 to -1.16) |
| 5000 | (c) update, scriptable | on | 13.5 / 12.75 / 31.40 / 48.80 | 13.9 / 12.04 / 30.04 / 45.56 | -1.28 (-2.64 to +0.97) |
| 5000 | (a) draw | off | 57.5 / 8.99 / 5.12 / 0.00 | 58.0 / 7.88 / 4.89 / 0.00 | -1.02 (-1.15 to -0.83) |
| 5000 | (b) update | off | 40.9 / 5.57 / 6.63 / 9.34 | 57.9 / 5.09 / 5.83 / 3.27 | -0.52 (-0.74 to -0.33) |
| 5000 | (c) update, scriptable | off | 11.3 / 14.87 / 34.86 / 55.32 | 13.7 / 12.01 / 31.92 / 46.53 | -3.26 (-4.16 to -2.76) |
| 20000 | (a) draw | on | 29.6 / 20.77 / 9.28 / 0.00 | 36.6 / 15.64 / 9.10 / 0.00 | -4.77 (-5.65 to -4.29) |
| 20000 | (b) update | on | 27.9 / 21.58 / 9.39 / 3.39 | 29.6 / 16.05 / 9.02 / 3.49 | -5.23 (-5.53 to -4.84) |
| 20000 | (a) draw | off | 29.6 / 21.99 / 9.35 / 0.00 | 34.2 / 16.45 / 8.48 / 0.00 | -5.60 (-5.73 to -5.37) |
| 20000 | (b) update | off | 11.2 / 24.58 / 10.92 / 52.52 | 27.9 / 16.51 / 9.59 / 9.11 | -8.41 (-9.43 to -7.74) |
| 20000 | (c), 60 seconds, 2 pairs | on | 2.8 / 65.16 / 90.15 / 261.80 | 3.5 / 48.58 / 89.04 / 199.85 | -16.6 (two pairs) |
| 20000 | (c), 60 seconds, 2 pairs | off | 2.7 / 66.88 / 90.25 / 270.17 | 3.4 / 48.94 / 98.60 / 202.22 | -18.0 (two pairs) |

- Case (c) at 20000 gives fewer than 30 frames in 7 seconds. The stress entry then reports no
  figures, because it averages only the windows after the first 30 frames. Thus case (c) at 20000
  ran 60 seconds (`--dart-define=SECONDS=60`).
- Typed options are faster in each case with a resolved difference, except one: case (b) without
  sharing at 1000. There the draw is 0.97 ms longer, but the update is 2.31 ms shorter, and the
  FPS is equal. The cause of the longer draw is not known.
- The largest gains come from the copies of case (b) without sharing, as in a scatter chart: at
  20000, the update takes 9.11 ms typed against 52.52 ms plain, and the chart runs at 27.9 FPS
  against 11.2 FPS. The copy is `clone` against the `Object.assign` loop over a Map (Chart.js ADR
  0021 §8).
- Case (c) is the slowest case. A scriptable option disables the option sharing and the cache of
  `resolveNamedOptions` (`needContext`, `core.config.js:405`). Each point then gets its own
  context and its own walk of the scope chain at each update. The scriptable color also gives each
  point its own paint, so the circle batch (section 5.4) cannot join the points. The raster time
  grows from about 5 ms (case b) to about 30 ms at 5000 points.

**Pixel 8a, the acceptance base and the animations** (typed, 2 pairs of the same build, 8 runs;
37.0 to 37.1 degrees Celsius):

| Scenario | FPS / draw / raster (median) | Draw range | Animator tick |
|---|---|---|---|
| `elements` without the line, 1000 | 58.4 / 5.65 / 5.18 | 5.39-5.88 | — |
| `elements` without the line, 5000 | 58.2 / 7.58 / 4.96 | 7.48-7.63 | — |
| `elements` without the line, 20000 | 40.5 / 15.00 / 9.05 | 13.39-17.57 | — |
| `chart` `CALL=animate`, 1000 | 58.1 / 4.80 / 5.27 | 4.62-5.09 | 0.94 ms |
| `chart` `CALL=animate`, 5000 | 58.2 / 6.25 / 5.27 | 6.23-6.42 | 1.81 ms |
| `chart` `CALL=animate`, 20000 | 30.5 / 14.89 / 9.71 | 12.81-16.75 | 4.66 ms |

- The animated case ticks two number animations (`x` and `y`) for each point. At 20000 points,
  the tick costs 4.66 ms for 40000 animations, about 0.12 µs for each animation on this phone.
- Section 10.7 gives the acceptance of ADR 0021 §8 inside one ABBA series. This series ran after
  the chart series on a hot phone, so it does not compare with the chart series above.

**Pixel 8a, the regression set** (before `cd9024f` against typed `4c32e6b`, 3 pairs; 36.6 to 37.1
degrees Celsius):

| Scenario | Before | After | FPS difference | Draw difference |
|---|---|---|---|---|
| primitives 1000 + 0 | 58.2 / 5.32 / 5.37 | 57.9 / 5.22 / 5.62 | -0.17 | -0.06 |
| primitives 1000 + 50 | 58.5 / 5.51 / 5.77 | 58.2 / 5.62 / 5.79 | -0.27 | +0.09 |
| primitives 5000 + 50 | 58.5 / 6.97 / 6.26 | 58.7 / 7.21 / 6.08 | +0.03 | +0.18 |
| primitives 20000 + 0 | 45.9 / 13.91 / 10.26 | 55.9 / 12.38 / 10.11 | +1.38 | +0.45 |
| primitives 1000 + 200 | 58.5 / 6.50 / 7.45 | 58.3 / 6.48 / 7.16 | -0.18 | +0.11 |
| primitives 20000 + 200 | 44.3 / 14.87 / 12.57 | 47.1 / 14.15 / 11.67 | -1.36 | +1.19 |
| elements 5000 + 50 | 57.5 / 8.55 / 6.28 | 58.0 / 8.72 / 6.28 | +2.29 | -0.62 |
| elements 20000 + 0 | 31.5 / 19.69 / 9.68 | 29.9 / 20.82 / 9.72 | -2.20 | +1.36 |
| bars 1000 | 41.9 / 12.20 / 16.03 | 42.7 / 12.08 / 15.95 | -0.39 | +0.29 |
| arcs 1000 | 29.2 / 19.63 / 26.64 | 32.4 / 17.07 / 22.89 | +2.85 | -2.59 |

- The series ran last, on a hot phone. Single runs of both sides fell to 32 to 37 FPS at 20000
  points, and the plan §6.3 rule misses in four scenarios on such runs. Thus this series cannot
  resolve the changes. Sections 10.6 and 10.8 have the controlled figures: the pooled 31 pairs of
  `elements` 20000 + 0 and the fit against the core frequency.

**iPhone 17 Pro** (120 Hz; 2 pairs for each chart scenario, 1 pair for each regression scenario):

| Scenario | Typed or after | Plain or before |
|---|---|---|
| chart (a), sharing on, 1000 | 119.9 / 1.54 / 0.96 | 119.9 / 1.86 / 0.86 |
| chart (a), sharing on, 5000 | 120.0 / 2.33 / 0.48 | 120.0 / 2.43 / 0.34 |
| chart (a), sharing on, 20000 | 120.0 / 3.68 / 0.51 | 120.0 / 5.42 / 0.42 |
| chart `CALL=animate`, 1000 | 119.9 / 1.48 / 0.87, tick 0.31 ms | — |
| chart `CALL=animate`, 5000 | 119.3 / 2.13 / 0.40, tick 0.58 ms | — |
| chart `CALL=animate`, 20000 | 117.7 / 3.89 / 0.39, tick 1.11 ms | — |
| primitives 1000 + 0 | 120.0 / 0.92 / 0.79 | 119.9 / 1.34 / 1.01 |
| primitives 20000 + 200 | 119.8 / 3.00 / 0.92 | 119.9 / 2.98 / 0.92 |

- At 20000 points, typed options draw 32 % faster on the iPhone (3.68 against 5.42 ms). Both
  sides run at the 120 Hz limit.
- The animator tick costs about 28 ns for each animation at 20000 points (1.11 ms for 40000
  animations), near the 18 to 20 ns of the probe of Chart.js ADR 0019 §11 on an M3 Max.
- The regression pairs show no loss against `cd9024f`.

### 10.10 CPU profile of case (c)

Section 7 of phase 5 asked where case (c) spends its update. Five CPU profiles of case (c) at 5000
points ran on the Pixel 8a on 2026-10-20, on commit `75178b5` (the library of `4c32e6b`):
- **Build.** `flutter build apk --profile --target-platform android-arm64 -t lib/main_stress.dart`
  with `MODE=chart CALL=update SHARING=1 SCRIPTABLE=1 SCENARIO=5000x0 SECONDS=30`.
- **Method.** One fresh process for each profile, with `adb forward` to its VM service. The
  profile build starts with the profiler off. Thus the script turns it on with
  `setFlag('profiler', 'true')`, as DevTools does. It waits 6 s, clears the samples, waits 10 s,
  and reads `getCpuSamples` of the `main` isolate (one sample each 1000 µs).
- **Scope.** The counts are the samples under `Chart.update` and not under `Chart.draw`: the
  update without its draw, the scope of `updateMs`. The samples with the VM tag
  `DRT_InterruptOrStackOverflow` are left out: 8 of 19,561.
- **Profiles.** Three profiles of the base (one at 28.9 degrees Celsius, two at 34.4-34.7), with
  13,611 update samples. Two profiles of the variant of section 10.11, with 9,172 update samples.

`Chart.update` has 88.5 % of all samples of the UI isolate. Its draw has 18.9 %, and the update
without its draw 69.6 %. The rest is mostly the paint of the host (`drawPicture`) and the frame
work.

Inclusive frames, in % of the update without its draw:

| Frame | Base | Variant |
|---|---|---|
| `StressPointController.updateElements` | 99.6 | 99.4 |
| `DatasetController.resolveDataElementOptions` | 97.4 | 97.7 |
| `Config.resolveNamedOptions` | 84.0 | 84.2 |
| `ContextResolver.[]` | 39.0 | 40.0 |
| `_cached` | 36.4 | 37.3 |
| `_resolveWithContext` | 21.3 | 22.7 |
| `jsGet` | 18.4 | 19.6 |
| `attachContext` (of which the Map literal `Map._fromLiteral`) | 14.7 (10.2) | 14.6 (10.2) |
| `Config.createResolver` | 11.9 | 12.8 |
| `_getResolver` (of which `List.join`) | 8.7 (6.6) | 9.0 (6.8) |
| `jsCall` (the `context()` closure and the scriptable call) | 8.4 | 7.3 |
| `_needContext` | 8.3 | 8.2 |
| `DatasetController.getContext` | 6.2 | 5.3 |
| `_resolveScriptable` | 4.5 | 4.6 |
| The read `element['$context']` (`PointElement.[]`, the Map of extra properties) | 1.2 | 0.0 |
| The scriptable function of the gallery | 0.7 | 0.7 |

- 84 % of the update is `resolveNamedOptions`. Upstream does this work too. A scriptable option
  turns off the option sharing and the cache of the resolver (`needContext`,
  `core.config.js:405`). Thus the work runs for each point in each update. The largest parts are
  the scope reads of `jsGet` (18 %), the Map writes of `_cached` (about 13 %), the Map literal of
  `attachContext` (10 %) and the cache key `prefixes.join()` (6.6 %).
- Two costs come from the port, not from upstream: the read of `element['$context']` (1.2 %) and
  the dispatch of `jsCall` without its callees (about 1.4 %).
- The draw: the FFI call `drawCircle` has 61 % of it. The scriptable color gives each point its
  own paint, so the circle batch (section 5.4) cannot join the points.

### 10.11 The declared `$context` of `Element`: dropped

The variant: `Element` declares `Object? $context = undefined`, as it declares `hidden` (section
10.6). `getContext` keeps the upstream form `element.$context || (element.$context = ...)` on the
field. `Scale` uses the field of `Element` in place of its own field. The variant has 35 lines
more and 19 lines fewer, of which 6 are code lines. In the profiles of section 10.10 it removes
the read of 1.2 % of the update: `getContext` goes from 6.2 % to 5.3 %. That is at most about
0.35-0.55 ms for each update at 5000 points, about 0.1 µs for each point.

**Stress entry.** An ABBA series ran on the Pixel 8a on 2026-10-20, 12:09-12:32, with the stress
entry: 28 A/B pairs of case (c) at 5000 and 14 A/A pairs of two byte-identical APKs. No series
that was planned before its run separates from 0:
- The first 6 A/B pairs give an update difference of +0.67 ms (-1.06 to +2.46).
- The 21 pairs without a flag (no run above 37.0 degrees Celsius, the two mean frequencies of the
  big core within 10 %, both at 1.5 GHz or more) give +0.06 ms (-0.66 to +0.87). These pairs can
  find an effect of about 1.1 ms of update or 0.36 FPS, not less.
- The A/A control moves: its draw gives +0.34 ms (+0.04 to +0.62) on 6 pairs. Thus a percentile
  interval that separates on 10 pairs or fewer is no evidence on this phone.
- The phone went from 29.9 to 37.1 degrees Celsius, and the big core from 2.9 to 1.9 GHz, with
  dips to 1.16 GHz. Some subsets separate, but their selection came after the data. The same
  selection gives a false result in the A/A control. Thus these subsets do not count.

**Frameless benchmark.** A second ABBA series ran on the Pixel 8a on 2026-10-20, 13:05-15:28, with
the frameless benchmark of section 6. The protocol below existed before the first run:
- A is `75178b5` with the bench files of the gallery. B is A with the variant. A2 is a byte copy
  of the A APK, for the A/A control.
- Two APKs for each side: `upd` (`CASES=b,c`, `N=5000,20000`: the cases b with and without
  sharing and c in one process) and `ctl` (`CASES=a`, `N=20000`). The default timing.
- One fresh process for each run. A figure is the median of the batches of one run. A difference
  is the mean of the pair differences B - A, with its 95 % bootstrap interval (20000 resamples)
  and the exact sign-flip p.
- A gate before each pair: the battery at 33.0 degrees Celsius or less and the big core at 2.8
  GHz or more in a busy loop, or 10 minutes. A run with a mean frequency below 2.5 GHz in its case
  windows leaves out its pair.
- The rule: keep the variant only when (1) the update of case c at 5000 has an interval below 0,
  (2) the A/A interval of that figure includes 0, and (3) no checked figure is slower with an
  interval above 0.
- 12 A/B pairs (10 valid for `upd`, 9 for `ctl`) and 6 A/A pairs (5 valid). The battery was at
  31.6-34.2 degrees Celsius. Each case c window ran at 2.90-2.91 GHz.

| Case | Figure | A (ms) | B (ms) | B - A (95 % interval) | p |
|---|---|---|---|---|---|
| c, 5000 | update | 33.326 | 32.677 | -0.649 (-1.863 to +0.438) | 0.332 |
| c, 20000 | update | 143.147 | 138.409 | -4.738 (-9.500 to -0.302) | 0.102 |
| b with sharing, 5000 | update | 0.554 | 0.533 | -0.021 (-0.063 to +0.021) | 0.400 |
| b with sharing, 20000 | update | 2.025 | 2.040 | +0.015 (-0.025 to +0.053) | 0.475 |
| b without sharing, 5000 | update | 1.412 | 1.410 | -0.002 (-0.030 to +0.025) | 0.908 |
| b without sharing, 20000 | update | 5.579 | 5.468 | -0.111 (-0.400 to +0.175) | 0.492 |
| a, 20000 (control) | draw | 6.932 | 6.947 | +0.015 (-0.109 to +0.158) | 0.844 |
| c, 5000 | draw / end | 8.163 / 5.085 | 8.139 / 5.097 | -0.024 / +0.011 | 0.721 / 0.775 |
| c, 20000 | draw / end | 33.115 / 12.578 | 33.169 / 12.533 | +0.054 / -0.046 | 0.832 / 0.693 |

The A/A control (A2 - A, 5 pairs) gives -0.970 ms (-2.823 to +0.841) for the update of case c at
5000.

- **Decision: drop.** Rule 1 fails: the interval of case c at 5000 includes 0. Rules 2 and 3
  hold. With no measured gain, the priority of porting-flow.md §1.1 goes to the upstream
  structure and to less code. `core.element.ts` does not declare `$context`: a data element gets
  it as a property of its own, which the Map of extra properties of the port keeps. `Scale` keeps
  its own field (`core.scale.js:249`).
- Two A/A intervals exclude 0 with the same bytes on both sides. Thus one interval alone is weak
  evidence at 5-10 pairs. This applies to case c at 20000 (p 0.102).
- An independent check rebuilt the 60 runs from the raw logs and got the same figures. The left
  out pairs leave 6 pairs with A first and 4 with B first, and the first run after a long gate
  wait is slower. The balanced difference of case c at 5000 is -0.42 ms, not -0.65 ms.
- After the data, the gain shows in the tails: p10 -0.295 ms (-0.578 to -0.045) and p90 -2.419
  ms (-4.053 to -0.957) at 5000. The A/A p10 is -1.130 ms (-2.505 to +0.193). Thus the p10 gain is
  inside the noise of the A/A control.
- Case c at 5000 takes about 33 ms in the `upd` APK and 29.1 ms in an APK with case c only. In the
  `upd` APK, case c runs after four b cases in the same process. The cause of the difference is
  not measured.

## 11. Scales (phase 6)

### 11.1 The value parameter (Chart.js ADR 0025)

[Chart.js ADR 0025](adr/0025-scale-value-parameters.md) §3 chooses the form of the value
parameter of the scales with this benchmark. The benchmark runs the hot path of
`controller.line.js:89-118`. For each of 20000 items, it reads `x` and `y` from a
`Map<String, Object?>` item of a `List<Object?>`. Then it calls `getPixelForValue` of the index
scale and of the value scale. It imports the real `jsToNumber` and `undefined` of `lib/src/js/`.
Each family has four live subclasses (linear, category, logarithmic, time), so each call is
virtual. The forms:
- **A:** a `double` parameter. The caller applies `jsToNumber`.
- **B1:** an `Object?` parameter. The body translates the upstream lines literally.
- **BT:** an `Object?` parameter with `value is double ? value : jsToNumber(value)` at each
  `ToNumber`.
- **BF:** an `Object?` parameter. An early `if (value is double)` branch repeats the upstream
  expression for a number. Then the literal lines follow. The ADR chooses this form.

Bed: Apple M3 Max, macOS 26.5.1, Dart 3.12.2. AOT is `dart compile exe`. wasm is
`dart compile wasm -O2` in Node.js v24.12.0 (arm64), for times only. 5 warm-up batches, then 15
batches of 10 passes in an alternate order. A cell gives the lowest and the highest median of 6
processes (2 builds, 3 runs each), in ns. The `ctl` rows are for each item (two calls). The `tick`
and `base` rows are for each call:

| Loop | Platform | A | B1 | BT | BF |
|---|---|---|---|---|---|
| ctl, linear x, linear y | AOT | 24.2-24.6 | 24.1-25.7 | 23.6-24.8 | 23.0-23.8 |
| ctl, category x, logarithmic y | AOT | 30.2-31.4 | 34.7-35.7 | 32.2-32.9 | 29.4-29.8 |
| tick value (a boxed `double`) | AOT | 7.5-7.9 (a layout artifact) | 3.5-3.7 | 3.6-3.7 | 3.5-3.6 |
| `getBasePixel`, logarithmic | AOT | 3.3-3.4 | 4.7-5.0 | 3.3-3.5 | 3.3-3.4 |
| ctl, linear x, linear y | wasm | 29.5-31.5 | 31.9-34.5 | 29.4-31.0 | 28.7-30.1 |
| ctl, category x, logarithmic y | wasm | 51.4-52.4 | 56.4-58.4 | 55.1-56.3 | 49.9-51.4 |
| tick value (a boxed `double`) | wasm | 1.2-1.3 | 2.2-2.4 | 2.2-2.5 | 2.2-3.0 |
| `getBasePixel`, logarithmic | wasm | 3.0-3.2 | 11.9-12.6 | 10.9-11.8 | 4.6-4.9 |

- BF is the fastest form. It is at or below A in each `ctl` loop on both platforms. On the linear
  pair, BF is about 0.6 ns for each item below BT, in each of the 6 processes.
- On a logarithmic value axis, B1 costs 4.0-6.5 ns more than A for each item: 0.08-0.13 ms for
  each update of 20000 points.
- On the same axis, BT costs 1.8-2.4 ns more than A on AOT and 3.1-4.9 ns more on wasm: 0.04 ms
  and 0.06-0.10 ms for each update of 20000 points.
- On the same axis, BF is 0.4-2.1 ns below A.
- A variant of BT with `value is num && value == x` for the strict compares of the logarithmic
  scale gives the figures of BT (AOT 31.9-33.2 ns, wasm 55.5-57.6 ns on the category and
  logarithmic pair). Thus the `Object?` tests before the `ToNumber` cost the time, not the
  compare.
- The box at a caller that holds a `double` (a tick value, `getBaseValue()`) costs 0 ns on AOT
  and about 1 ns for each call on wasm. These callers run once for each tick or once for each
  update. The AOT figure of A in the `tick` row is a layout artifact.

Source: the judge benchmark of Chart.js ADR 0025 (Evidence E8).

### 11.2 The parsed read of phase 7

[Chart.js ADR 0025](adr/0025-scale-value-parameters.md) §8 chooses the read of `parsed[axis]`
with this benchmark. It reads `x` and `y` of 20000 Map items, with 10 % `null` values. The
machine, the SDK and the compilers are those of section 11.1. In ns for each item, 3 processes:

| Read | AOT | wasm |
|---|---|---|
| `_parsedValue` (Dart `null` for an absent key) | 17.0-17.6 | 24.8-25.4 |
| Map read with `undefined` for an absent key | 17.7-17.9 | 26.7-27.8 |
| `jsGet` | 18.9-19.3 | 29.4-30.3 |

- The Map read `value == null && !item.containsKey(key) ? undefined : value` gives the result of
  `jsGet`. It costs 0.3-0.9 ns (AOT) and 1.7-2.5 ns (wasm) more than `_parsedValue` for each item.

Source: Evidence E9 of Chart.js ADR 0025.

Phase 7 adopted this read as the T form of `jsGetKey`; the `isFinite` read keeps `_parsedValue`
(section 13.1).

### 11.3 The position result and `getDataVisibility`

The machine, the SDK and the compilers are those of section 11.1. 20000 calls, 3 processes, in ns
for each call:

| Call | AOT | wasm |
|---|---|---|
| A virtual `getPointPositionForValue` that returns the record `({double x, double y, double angle})` | 24.1-25.1 | 32.6-34.0 |
| The same call that returns a class with three `final double` fields | 20.4-21.0 | 29.4-30.7 |
| `getDataVisibility` through an interface with two classes | 6.3-6.5 | 8.7-9.1 |
| `getDataVisibility` after a cast to the concrete class | 5.2-5.3 | 5.5-5.6 |

- A radar or radial draw makes tens of position calls. Thus the class gains less than 1 µs for
  each draw. The record rule of Chart.js ADR 0003 applies.
- The bar, doughnut and polar area controllers of phase 7 call `getDataVisibility` for each
  element (`controller.bar.js:592`, `controller.polarArea.js:182`).

Source: Evidence E10 of Chart.js ADR 0025. Both choices stay Open in the ADR (Open 4 and Open 5).

`getDataVisibility`: the early return of Chart.js ADR 0028 §4 (section 13.2); ADR 0025 Open 4 is
closed.
The mode `axes` of the stress entry (section 6) can give the frame figures of ADR Open 2 (a
logarithmic value axis, `CALL=update`). Phase 7 adds the frame figures of Open 1 (a `timeseries`
axis, a radar chart).

### 11.4 The fast path of `jsAdd`

`jsAdd` of `lib/src/js/js_number.dart` is the JS `+` of a raw option value (`core.scale.js`,
`scale.radialLinear.js`). Its first line returns the sum of two `double` operands. The bed of
section 11.1, AOT. One process, 5 rounds of 20,000,000 calls of `jsToNumber(jsAdd(double,
double))`. The cells give the lowest and the highest round, in ns for each call:

| Form | Not inlined | Inlined |
|---|---|---|
| With the fast path | 3.65-3.73 | 3.55-3.61 |
| Without the fast path | 4.73-4.83 | 3.60-3.63 |

- `a + b` on two doubles takes about 0.9 ns. `jsAdd` returns an `Object`, so the sum is boxed.
- A layout of a cartesian scale makes about 30 calls, and the label items make 1 or 2 calls for
  each tick. The gain is less than 1 µs for each layout. The fast path stays: it is one line, and
  it is not slower.

### 11.5 The number formatting guards (Chart.js ADR 0026)

[Chart.js ADR 0026](adr/0026-number-formatting-on-package-intl.md) adds guards to
`js_intl.dart` where package:intl gives another label than V8. The bed of section 11.1, AOT, en-US.
The best of 7 runs of 200,000 calls of `JsNumberFormat.format`, in ns for each call:

| Label | Chart.js ADR 0008 | Chart.js ADR 0026 |
|---|---:|---:|
| A standard label (`12.5`, 1 fraction digit) | — | 346-371 |
| `1e21`, standard notation | 1,133-1,136 | 506-522 |
| `1e37`, compact notation | 1,190-1,215 | 141-145 |
| `1.5e20`, compact notation | — | 766-785 |
| A tick label with 16 to 20 fraction digits | 417-467 (capped at 15) | 264-356 |
| A scientific label | 350-475 | 260-315 |

- The guards do not change the time of a standard label and of compact `1.5e20`.
- A cache miss (a new `jsNumberFormat` and a format) stays at about 1.1 µs, because the groups of
  the pattern are read only when a guard needs them.
- The compact guard computes its probe one time for each formatter. A probe for each call took
  1,395-1,402 ns for compact `1.5e20`.
- Rejected forms: `toStringAsExponential()` for the digits is 6-22 % slower than
  `jsNumberToString`. The intl mantissa for scientific notation takes 430-600 ns.

### 11.6 The scale path on the Pixel 8a

The scale path of phase 6 on the Pixel 8a (`4B071JEKB17363`), on 2026-10-20. The code is
the phase 6 work at the start of the review step: `7e6b834` and the uncommitted phase 6 changes.
The review fixes after that point do not change `canvas_ui_text.dart` or the benchmark. One of
them leaves the update at the construction and at the first resize out of the parts of the
stress line (`StressAxesTiming.reset`). Thus the benchmark times hold for commit `cd422b4`. The method is that of section 6: profile APKs,
one fresh process for each run, and a gate before each run (the battery at 33.0 degrees Celsius or
less and the big core at 2.8 GHz or more in a busy loop, or 10 minutes). A loop on the phone reads
the frequency of the big core and the core of the UI thread every 0.25 s.

**Frameless benchmark** (`CASES=axes`, `N=1000,5000,20000`, the default timing). Four processes.
A cell is the mean of the run medians of the runs whose case window ran at 2.8 GHz or more, in ms.
The time axis runs last in each process, so it has 1 or 2 such runs at 5000 and 20000.

| Scale | Figure | 1000 | 5000 | 20000 |
|---|---|---:|---:|---:|
| linear | update | 0.701 | 1.496 | 4.644 |
| linear | layout | 0.452 | 0.773 | 2.008 |
| linear | datasetsUpdate | 0.133 | 0.565 | 2.309 |
| linear | draw (`CALL=draw`) | 0.469 | 1.879 | 7.068 |
| logarithmic | update | 0.986 | 2.035 | 6.209 |
| logarithmic | layout | 0.663 | 1.009 | 2.244 |
| logarithmic | datasetsUpdate | 0.197 | 0.879 | 3.594 |
| logarithmic | draw (`CALL=draw`) | 0.544 | 1.933 | 7.270 |
| category | update | 4.108 | 127.323 | 535.352 |
| category | layout | 3.841 | 126.099 | 532.271 |
| category | datasetsUpdate | 0.144 | 0.650 | 2.479 |
| category | draw (`CALL=draw`) | 0.636 | 2.056 | 7.590 |
| time | update | 1.064 | 1.678 | 5.380 |
| time | layout | 0.764 | 0.911 | 2.599 |
| time | datasetsUpdate | 0.141 | 0.601 | 2.471 |
| time | draw (`CALL=draw`) | 0.637 | 1.945 | 7.642 |

- The x axis has 11 ticks (linear), 25 (logarithmic), 34 (category), and 33, 14 and 28 (time at
  1000, 5000 and 20000).
- The draw of the scales is small: the draw minus the dataset draw is 0.15-0.33 ms at 5000 for
  each type.
- The category update is not linear in N: 31 times from 1000 to 5000 points, then 4.2 times to
  20000. Section 11.7 gives the cause.

**Stress entry** (`MODE=axes`, `SCENARIO=1000x0,5000x0,20000x0`, `SECONDS=7`, one process for
each scale and call). FPS / update ms:

| Scale | `CALL=update`, 1000 | 5000 | 20000 | `CALL=draw`, FPS at 1000 / 5000 / 20000 |
|---|---|---|---|---|
| linear | 58.0 / 3.29 | 56.4 / 3.26 | 31.5 / 5.75 | 58.7 / 58.4 / 57.5 |
| logarithmic | 58.3 / 3.67 | 53.5 / 4.01 | 29.7 / 6.85 | 57.9 / 58.5 / 57.9 |
| category | 52.4 / 8.09 | 7.4 / 120.30 | 1.5-1.8 / 527-625 (90 s runs) | 58.2 / 58.2 / 57.8 |
| time | 57.4 / 3.93 | 53.1 / 3.55 | 30.6 / 6.06 | 58.0 / 58.1 / 57.5 |

- With a light load, the governor keeps the big core at 1.0-2.0 GHz and the UI thread often runs
  on another core. Thus the stress times are larger than the benchmark times. Use the benchmark
  for the times.
- The category axis at 20000 gave fewer than 30 frames in 7 s. The cell gives two runs of 90 s.
- The stress host is phone-sized, so the x axis has 6, 11, 14 and 11-14 ticks.

**CPU profiles** (the update at 5000 points in the stress entry, 10 s of samples at 1 ms, the
samples under `Chart.update` and not under a draw). Inclusive shares in %:

| Frame | linear | logarithmic | category | time |
|---|---:|---:|---:|---:|
| `Scale.update` | 53.7 | 52.5 | 99.4 | 57.2 |
| `DatasetController.getMinMax` | 28.0 | 21.5 | 0.1 | 23.5 |
| `generateTickLabels` | 6.5 | 6.5 | 0.9 | 5.4 |
| `_computeLabelSizes` | 9.9 | 16.6 | 98.0 | 11.8 |
| `resolveTickFontOptions` | 10.1 | 15.0 | 13.1 | 12.5 |
| `measureCanvasText` | 0.0 | 0.8 | 82.7 | 0.3 |
| `Chart._updateDatasets` | 35.8 | 40.7 | 0.5 | 31.2 |
| `jsLog10` | - | 14.4 | - | - |
| `LocalZone.offsetAt` | - | - | - | 4.2 |
| resolver reads (`ContextResolver.[]`, `Resolver.[]`) | 13.2 | 11.1 | 2.6 | 13.4 |
| `jsGet`, all callers | 32.1 | 25.3 | 2.2 | 29.6 |

- One category update with 5000 labels makes 2500 canvas measures and 5127 calls of
  `resolveTickFontOptions`. A linear update makes 0 and 94. Counted on the host.
- A category axis measures N/2 labels in each update, as upstream does. `calculateLabelRotation`
  measures all N labels (`core.scale.js:797`, `:819`). After `autoSkip`, `_labelSizes` is null
  (`core.scale.js:458-459`). `fit` then measures the kept ticks, and `garbageCollect`
  (`core.scale.js:71`, `:855`) deletes the older half of the label widths of the scale. The halves
  alternate, so the canvas layer sees a cycle of all N labels.
- Upstream makes the same calls, and the text shape cache of Chrome makes them cheap. The port
  built a paragraph for each miss of its metrics cache (section 11.7).

### 11.7 Change: the metrics cache of the canvas text

The metrics cache of `canvas_ui_text.dart` (port-only, Chart.js ADRs 0013 and 0015) held 2048
entries in LRU order. With more than about 2048 labels, a category axis missed on each of its N/2
measures in each update. Each miss built and laid out a paragraph: 63.9 % of the update at 5000.
The eviction `_metrics.remove(_metrics.keys.first)` walked the deleted slots of the
`LinkedHashMap` for each entry: 14.8 %. The paragraph cache had the same eviction.

The change:
- The bound `metricsCacheSize` is 32768. An LRU cache must hold the whole cycle of N labels to
  hit, so a bound of 16384 would miss on each label at 20000.
- `_evictOldest` removes the oldest quarter of either cache in one pass over the keys. A clear
  when full would measure all the labels of an axis again.
- An entry takes 104-128 bytes on the 64-bit Dart VM (the key record 32, the metrics 48, the
  table slots 24-48). A full cache takes 3.3-4.0 MiB, without the label strings.
- The paragraph build does not change, so the widths do not change. A test compares the cached
  widths with fresh paragraphs, and the text metrics reference test passes. The upstream
  structure does not change.

**Frameless benchmark, ABBA.** The protocol was written before the first run. A is the code of
section 11.6, and B is A with the change. One APK for each side (`CASES=axes.linear,axes.category`,
`N=5000,20000`, the default timing). 6 pairs, with the gate of section 11.6 before each pair. A
pair is left out of a case when one of its two case windows ran below 2.5 GHz. The rule: keep the
change when the category update has an interval below 0 at 5000 and at 20000, the linear update at
5000 (the control) has no interval above 0, and the ticks and the rotation are equal on both
sides.
- Pairs 2 and 6 (both B first) ran at 1.2-2.5 GHz in their case windows and are left out of every
  case. 4 pairs remain, 3 of them A first. With 4 pairs, the sign-flip p is 0.125 or more.
- The battery was at 31.4-33.2 degrees Celsius in the analyzed runs. Each analyzed case window ran
  at 2.74-2.91 GHz.

| Case | Figure | A (ms) | B (ms) | B - A (95 % interval) | % |
|---|---|---:|---:|---|---:|
| category update, 5000 | update | 126.576 | 20.864 | -105.712 (-106.173 to -105.407) | -83.5 |
| category update, 20000 | update | 531.961 | 98.078 | -433.883 (-439.944 to -429.899) | -81.6 |
| linear update, 5000 (control) | update | 1.514 | 1.518 | +0.003 (-0.016 to +0.024) | +0.2 |
| linear update, 20000 | update | 4.623 | 4.633 | +0.010 (-0.143 to +0.143) | +0.2 |
| category draw, 5000 | draw | 2.043 | 2.051 | +0.007 (-0.040 to +0.038) | +0.4 |
| category draw, 20000 | draw | 7.518 | 7.552 | +0.034 (-0.126 to +0.142) | +0.5 |
| linear draw, 5000 | draw | 1.791 | 1.832 | +0.041 (-0.054 to +0.106) | +2.3 |
| linear draw, 20000 | draw | 7.146 | 7.242 | +0.095 (-0.173 to +0.283) | +1.3 |

- **Decision: keep.** Both category intervals lie below 0, the control interval includes 0, and
  the ticks (34) and the rotation (50) are equal in each pair. The two left out pairs give the
  same sign: -135.5 and -146.9 ms at 5000, -511.2 and -623.8 ms at 20000.
- Some secondary figures have an interval that excludes 0: the `end` of the linear draw at 20000,
  +0.116 ms (+0.065 to +0.162), and the dataset draw of the category update at 5000, +0.161 ms
  (+0.063 to +0.226). The draw after a category update at 20000 is 1.342 ms faster (-2.017 to
  -0.404). At 4 pairs a percentile interval is weak evidence (section 10.11). The first run of a
  pair draws faster, and 3 of the 4 pairs run A first. The cause of these differences is not
  measured.

**Stress entry after the change** (`SCENARIO=1000x0,5000x0,20000x0`, `SECONDS=30`, one run, the
battery at 33.0 degrees Celsius). The before columns are the runs of section 11.6 with `SECONDS=7`
and 90:

| N | FPS before | FPS after | update ms before | update ms after |
|---:|---|---:|---|---:|
| 1000 | 50.9-52.4 | 50.9 | 8.09-8.35 | 8.32 |
| 5000 | 6.8-7.4 | 28.8 | 120.30-131.99 | 21.91 |
| 20000 | 1.5-1.8 | 7.65 | 527.15-625.22 | 106.09 |

**CPU profile after the change** (the category update at 5000, as in section 11.6). The paragraph
build and the eviction walk are gone. Inclusive shares, and the share times the update time of the
run (129.74 ms before, 21.75 ms after):

| Frame | Before | After |
|---|---|---|
| `measureCanvasText` | 82.7 % (107.3 ms) | 4.4 % (0.96 ms) |
| `resolveTickFontOptions` | 13.1 % (17.0 ms) | 70.2 % (15.3 ms) |
| `toFont` | 6.5 % (8.4 ms) | 33.8 % (7.4 ms) |
| `toLineHeight` | 2.7 % (3.5 ms) | 12.9 % (2.8 ms) |
| `ContextResolver.setContext` | 2.5 % (3.3 ms) | 14.5 % (3.2 ms) |
| `Scale.getContext` | 2.1 % (2.7 ms) | 10.8 % (2.3 ms) |
| `generateTickLabels` | 0.9 % (1.1 ms) | 6.9 % (1.5 ms) |
| `UiCanvasContext.font=` | 0.7 % (1.0 ms) | 3.5 % (0.8 ms) |

- The top self frame after the change is `_RegExp._ExecuteMatch`, 11.9 %: 7.0 % from
  `toLineHeight` and 4.8 % from the font style test of `toFont`.
- A cache hit costs about 0.4 µs. The LRU move (`remove` and the insert) is about 0.7 ms of each
  update at 5000.

### 11.8 Open: the scale path

The gains are profile shares times benchmark times. They are estimates, not measurements, and
each change needs the A/B evidence of section 11.7.

1. **The tick font for each tick.** `resolveTickFontOptions` (`core.scale.dart:2890`, called at
   `:1791` and `:2307`) takes 70.2 % of the category update at 5000 after section 11.7, about
   15 ms. It takes 10.1 / 15.0 / 12.5 % of the linear / logarithmic / time update. Upstream makes
   the same calls (`core.scale.js:1700`). The port adds a constant of about 3 µs for each call.
   - Form (a) keeps the structure: a number path in `toLineHeight` (`helpers.options.dart:58`)
     and a memo for the `_fontStyle` test (`:374`). For a `double`, the result of the RegExp is
     known when the JS string has no exponent and no sign. The path must keep the exponent limits
     (1e21, 1e-7) and -0. The two RegExps take about 18 % of the category update at 5000 (about
     3.8 ms) and 2-3.6 % of the other updates (0.03-0.07 ms).
   - Form (b) changes the structure: resolve the tick font once for each update when no scope of
     `ticks.font` is scriptable or indexable, and use it for each tick. It needs a `DIVERGES`
     marker and an `adapt` row. Up to -15 ms at 5000 and about -65 ms at 20000 on the category
     axis. -0.15 / -0.31 / -0.21 ms at 5000 on linear / logarithmic / time.
2. **`getMinMax` of a value axis**, O(N) as upstream: 28.0 / 21.5 / 23.5 % of the linear /
   logarithmic / time update. The generic `jsGet` reads at `core.datasetController.dart:1241`
   and `:1280` (the `skip` closure at `:1278`) take 12.5 / 10.4 / 11.3 %, against 3.8 / 3.1 /
   4.1 % for `_parsedValue`. The form is the Map read of section 11.2 for both reads. The read
   of the other axis keeps `undefined`: `jsToNumber(null)` is 0, `jsToNumber(undefined)` is NaN.
   -3 to -5 %: 0.05-0.09 ms at 5000 and 0.2-0.35 ms at 20000. Adopted in phase 7 as the T form;
   the `isFinite` read keeps `_parsedValue` (section 13.1).
3. **`jsLog10` for each point** in `LogarithmicScale.getPixelForValue`
   (`scale.logarithmic.dart:401`, `fdlibm_log.dart`): 14.4 % of the logarithmic update, about
   59 ns for each call. The word access through `ByteData` (`_hi`, `_lo`, `_setHi`) takes 3.8 %,
   and the `k.toDouble()` conversions about 7 %. The form keeps the fdlibm arithmetic bit-exact,
   with views that do not box and a conversion that does not allocate. The fdlibm reference tests
   guard it. -7 to -11 % of the logarithmic update: 0.15-0.22 ms at 5000 and 0.6-0.9 ms at 20000.
4. **Platforms.** The figures of sections 11.6 and 11.7 come from the Pixel 8a only. The iPhone
   17 Pro was not connected, and the Mac had no idle window for the macOS and Chrome series.


## 12. Dates (phase 6)

[Chart.js ADR 0024](adr/0024-dates.md) chooses the forms of the default date adapter
with these figures: its facts 1, 2, 3, 5, 7, 12 and 13, and its decision 10. Bed: Apple M3 Max,
macOS 26.5.1, Dart 3.12.2 (Flutter 3.44.9), `package:intl` 0.20.3. AOT is `dart compile exe`.
dart2wasm and dart2js ran in the x64 Node.js v24.12.0 under Rosetta. The figures are medians, in
ns for each call. The Evidence section of the ADR gives the files.

### 12.1 The dispatch

The extra cost of a call through `DateAdapterBase.prototype`, over a direct call of the same body
(fact 1):

| Form | AOT | dart2wasm | dart2js |
|---|---|---|---|
| The phase 5 path (`jsCall`) | 22-27 | 64-70 | 32-46 |
| A typed direct call of a member of the exact Dart function type | 7-8 | 21-26 | 15-22 |

The ADR takes the typed direct call.

### 12.2 The calendar, the offset cache, the ISO scanner and the format cache

- **UTC calendar** (fact 2). Integer day arithmetic against `DateTime.utc` and the `DateTime`
  fields, AOT: `startOf` day 13.1 against 82.5 ns, `add` 1 day 7.9 against 87.3 ns, `add` 1
  month 44.4 against 138.2 ns. dart2wasm: 16.0 against 120.1, 9.5 against 123.5 and 38.8 against
  232.3 ns. The results were equal in 139,264 checks.
- **Local time** (fact 3). The local `DateTime` constructor costs about 1,000 ns on AOT and
  dart2wasm, because it asks the platform for the offset. A cache keeps one interval of instants
  with one offset. Wall time to instant: 52.7 ns with the cache, 678.9 ns with the constructor on
  AOT. dart2wasm: 37.7 against 300.2 ns.
- **ISO 8601 parse** (fact 5). A code-unit scanner of the moment ISO grammar costs 35-54 ns on AOT
  and 57-140 ns on dart2wasm. `DateTime.tryParse` costs 745-1,709 ns and 796-1,606 ns, and it
  gives the moment result for fewer strings.
- **Format** (fact 7). A cached `DateFormat` costs 209-509 ns on AOT. A new `DateFormat` for each
  call costs 1,839-9,104 ns. The lower-case day period adds 0-82 ns.

### 12.3 One update

The calls of the adapter in one update (fact 12):
- 1,000 ISO labels with number data: `init` 1, `formats` 1, `parse` 2,000, `format` 14,
  `startOf` 1, `diff` 1, `add` 12.
- 1,000 numbers with `time.round: 'day'`: `startOf` 1,001.
- A `timeseries` scale with 1,000 timestamps: 1,001 `format`.
- Ten `chart.draw()` calls after an update make 0 adapter calls.

One update with N ISO labels, without the text measure and the draw (fact 13), in ms on AOT /
dart2wasm:

| Form | N = 1,000 | N = 20,000 |
|---|---|---|
| Subclass, scanner, integer calendar, cached formats, UTC | 0.15 / 0.39 | 3.34 / 6.28 |
| The same with the phase 5 dispatch | 0.20 / 0.51 | 4.23 / 11.78 |
| The same in local time with the offset cache | 0.20 / 0.37 | 5.67 / 8.26 |
| The same in local time with the `DateTime` constructor | 1.52 / 1.01 | 31.30 / 22.39 |
| The phase 5 dispatch, `tryParse`, the `DateTime` calendar, a new `DateFormat` for each call | 3.37 / 2.98 | 66.01 / 62.50 |

The typed direct call adds about 40,000 times 7-8 ns on AOT and 21-26 ns on dart2wasm to an
update with 20,000 labels: about 0.3 ms and 0.9 ms. This is a calculation from section 12.1, not a
measurement (decision 10).

### 12.4 The port

The port of `lib/src/core/date_*.dart`, through the adapter, on the bed of this section. AOT, a
benchmark outside the repository, medians in ns for each call:

| Call | UTC | Local, sorted labels one hour apart |
|---|---:|---:|
| `parse` ISO `2015-01-01T20:00:00` | 79 | 82 |
| `parse` ISO with `Z` | 80 | 83 |
| `parse` ISO, date only | 54 | 57 |
| `startOf` day (direct call: 14) | 43 | 46 |
| `add` 1 day (direct call: 16) | 47 | 51 |
| `add` 1 month (direct call: 35) | 77 | 86 |
| `format` `'MMM d'` | 217 | 221 |
| `format` `'h:mm a'` (lower-case day period) | 305 | 305 |
| `format` `'MMM d, yyyy, h:mm:ss a'` | 549 | 545 |
| The ISO default text | 271 | 323 |
| `parse` with a format | 1,047 | 1,042 |

- The ISO scanner alone costs 30-80 ns, by the form. It is slower than the 35-54 ns of fact 5,
  because it also copies the token parse and the range checks of moment.
- In local time, with dates that are years apart, each call costs about 1.1-1.6 µs: the cache of
  one interval misses at each call. A local `diff` of two dates 21 days apart costs about 1-3 µs,
  and a local `startOf` `isoWeek` with a weekday about 216 ns. Both leave the cached interval at
  each call. The time scale makes about 10 such calls in each update.

### 12.5 Open

- The frame figures of a time axis with ISO labels on the Pixel 8a, macOS, Chrome with dart2wasm
  and the iPhone (Chart.js ADR 0024, Open 1). When the frame figures show a gain of 0.1 ms or more
  for direct calls, a new ADR decides between the typed direct call and a subclass. The mode
  `axes` of the stress entry and the frameless benchmark give the time axis with timestamps. A
  case with ISO labels does not exist yet.

## 13. Controllers (phase 7)

The figures of the decisions of phase 7. Chart.js ADRs 0027, 0028, 0030 and 0031 give the
evidence files. Section 13.6 has the figures of step 7.

### 13.1 The parsed read (Chart.js ADR 0036)

Bed: Apple M3 Max, macOS 26.5.1, Dart 3.12.2. AOT is `dart compile exe`. wasm is
`dart compile wasm -O2`, run in the arm64 Node.js v24.12.0 (times only). The judge benchmark
imports the real `jsGet`, `jsToNumber`, `jsMin`, `jsMax`, `isFinite`, `JsProxyObject` and
`undefined` of `lib/src/`. 20000 items `{'x': i, 'y': v}`, `null` for 10 % of the `y` values.
"Mixed" runs each loop first over a `JsProxyObject`, a narrow Map, a List and a number. Each cell
gives the lowest and the highest paired difference of 6 processes, in ns for each item, and the
count of processes below 0.

| Difference | AOT plain | AOT mixed | wasm plain | wasm mixed |
|---|---|---|---|---|
| `getMinMax` T minus the code before phase 7 | -1.76..-1.13 (6/6) | -2.09..-1.04 (6/6) | -1.75..-0.46 (6/6) | -2.89..-1.50 (6/6) |
| `getMinMax` `jsGetKey` for 3 reads minus T | +0.61..+1.46 (0/6) | +0.75..+1.59 (0/6) | +0.37..+1.51 (0/6) | +0.97..+2.18 (0/6) |
| line, 5 reads: `jsGetKey` minus `jsGet` | -3.39..-2.22 (6/6) | -2.63..-0.27 (6/6) | -5.20..-1.75 (6/6) | -3.20..-1.22 (6/6) |
| line: 3 reads minus 5 reads (`jsGetKey`) | -16.11..-14.97 (6/6) | -16.61..-15.97 (6/6) | -24.36..-23.05 (6/6) | -24.29..-23.07 (6/6) |
| line: 2 reads minus 5 reads (`jsGetKey`) | -23.28..-22.42 (6/6) | -24.33..-23.28 (6/6) | -36.46..-33.11 (6/6) | -35.29..-33.20 (6/6) |

- "T" is `jsGetKey` for the read of the other axis and of the range, and `_parsedValue` for the
  `isFinite` read. DC has this form from phase 7.
- The 2-read form is the one-read rule of the line and scatter loops (Chart.js ADR 0036 §8): 22
  to 24 ns (AOT) and 33 to 36 ns (wasm) less for each point, about 0.47 ms (AOT) and 0.7 ms (wasm)
  for each update of 20000 points. This is a calculation from the microbenchmark, not a frame
  figure.
- Wave 2 result: `controller.line.dart` has the 3-read form, 15 to 17 ns (AOT) and 23 to 24 ns
  (wasm) less for each point than the 5-read form. It keeps `vValue` and `iValue` in a loop pass,
  and it reads `prevParsed[iAxis]` at each pass. The local of the 2-read form crossed the
  scriptable options of the user (`resolveDataElementOptions` and the animated `updateElement`),
  which can write the parsed item: a probe of the pinned build showed another `stop` value with
  such an option. The 2-read form needs a microbenchmark first (Chart.js ADR 0036 §8, section 13.7
  item 6). No new measurement.
- Chart.js ADR 0036 §8 keeps the 3-read form in the line and the scatter loops. Open 4 of Chart.js
  ADR 0027 is closed (2026-10-21). Wave 3: `controller.scatter.dart` has the 3-read form
  (`controller.scatter.js:127-133`). No new measurement.

The read `array[i]` with a number index, in ns for each read:

| Read | AOT | wasm |
|---|---|---|
| `jsGet(data, jsNumberToString(index))` (the old read of `helpers.config.dart`) | 21.49-21.93 | 17.16-17.42 |
| the body of `jsGetIndex` (the old `_item` of DC) | 3.33-3.39 | 1.41-1.45 |
| the same body behind a `List` test, in the doughnut loop | 5.61-5.84 | 5.70-6.01 |
| the same body in the same loop without the test | 5.50-5.75 | 5.69-6.00 |

A `jsGet` with the Map case first is 1.9 ns (AOT) and 1.0 ns (wasm) slower for each resolver read,
and 4.8 ns and 2.0 ns slower for each List or String read (P-B4). `lib/src/` had 444 `jsGet(`
calls on 2026-10-21, most of them option reads through resolvers. Thus `jsGet` does not change, and
the Map case comes first only in `jsGetKey`.

**`stacksOf`** (Chart.js ADR 0027 Open 1, unit S3 of wave 1). The bed of the judge benchmark: 20000
`Map<String, Object?>` items with `_stacks`, the DC code of 2026-10-21 and the real runtime,
virtual scale calls over two live classes. 3 runs of 6 rounds of 4 processes, alternate order, 21
samples of 10 passes for each case. Other agents ran in parallel (load average 4 to 7). The cells
give the paired difference "with `stacksOf`" minus "without", minimum..maximum of 6 processes, in
ns for each item, and the count of processes above +0.5 ns:

| Platform, mode | Case | Run 1 | Run 2 | Run 3 |
|---|---|---|---|---|
| AOT plain | `updateRangeFromParsed` with a stack | -2.52..-0.93 (0/6) | -2.22..-0.50 (0/6) | -2.20..-0.32 (0/6) |
| AOT plain | the body of `_updateStacks` | -13.59..-0.33 (0/6) | -9.78..-2.41 (0/6) | -9.94..-7.14 (0/6) |
| AOT plain | the write path (each pass writes `_stacks`) | +6.43..+11.35 (6/6) | -4.32..+3.10 (2/6) | -4.47..+7.47 (5/6) |
| AOT mixed | `updateRangeFromParsed` with a stack | -1.05..+0.12 (0/6) | -0.91..+1.03 (3/6) | -3.46..+1.89 (3/6) |
| AOT mixed | the body of `_updateStacks` | -17.90..-7.15 (0/6) | -9.98..-5.61 (0/6) | -10.86..-5.72 (0/6) |
| AOT mixed | the write path | +1.13..+12.87 (6/6) | -13.47..+0.45 (0/6) | -4.12..+3.47 (3/6) |
| wasm plain | `updateRangeFromParsed` with a stack | -1.38..+3.84 (4/6) | -0.90..+1.41 (4/6) | +0.24..+1.72 (3/6) |
| wasm plain | the body of `_updateStacks` | -16.54..-0.35 (0/6) | -22.10..+3.26 (1/6) | -29.64..-11.85 (0/6) |
| wasm plain | the write path | -14.27..-0.10 (0/6) | -26.49..-1.70 (0/6) | -20.63..-2.24 (0/6) |
| wasm mixed | `updateRangeFromParsed` with a stack | -0.63..+5.29 (3/6) | -0.05..+0.79 (1/6) | -0.75..+1.61 (2/6) |
| wasm mixed | the body of `_updateStacks` | -17.54..+13.18 (2/6) | -16.35..+5.77 (2/6) | -15.75..+7.50 (4/6) |
| wasm mixed | the write path | -7.70..+5.69 (4/6) | -8.72..+5.61 (2/6) | -10.78..+11.75 (4/6) |

- The medians of run 3, in ns for each item: AOT `updateRangeFromParsed` 52.8-55.2, the body of
  `_updateStacks` 196-215, the write path 292-304; wasm 72.9-76.7, 349-397 and 417-440.
- The two loops of the ADR have no platform and mode with a paired loss above 0.5 ns in each of
  the 6 processes, in each run. The threshold of Chart.js ADR 0027 Open 1 is not crossed. Thus
  `stacksOf` lands in all cases (Chart.js ADR 0036 §5.3).
- The write path is not in the ADR. Run 1 had an AOT loss of +1.1 to +12.9 ns in each process.
  Run 2 and run 3, with a binary that has one more function, did not repeat it: a code layout
  effect within the noise of a loop of 300 ns. The write runs once for each item, at the first
  parse.
- The `switch` of the write is faster than an `if` chain on AOT: the chain costs +2.86..+9.61 ns
  (6/6) in run 2 and -1.07..+11.80 ns (5/6) in run 3.

**`===` in the bar `skipNull` find** (`controller.bar.js:443-450`, unit U-bar of wave 1). Two
`Date` values are `===` only when they are the same object. Thus the find compares with
`_strictEquals` (`==` for numbers and strings, else `identical`), the only form with the upstream
behavior. AOT, 1000 parsed Maps, 20000 finds, three rounds, in ns for each compared item: Dart `==`
10.32-11.12, `_strictEquals` 11.21-11.36. The cost is 2-9 % of the find; `jsGetKey` takes most of
its time.

### 13.2 The interfaces and values (Chart.js ADR 0028)

The bed of section 13.1. The figures are the range of the medians of 3 or 4 processes.

**The points of a line** (ADR 0028 §3). The real `LineElement` and `PointElement`, `animated`
true (each draw runs `updateControlPoints` and builds the path again). `draw_typed` draws a line
with a `List<types.PointElement>`. `draw_view` draws a line with the cast view
`meta.data.cast<types.PointElement>()`. `set_copy` is the copy `List<types.PointElement>.generate`
of a `List<types.Element>`. µs for each op:

| Case | `draw_typed` | `draw_view` | view extra for each draw | `set_copy` (once for each update) |
|---|---|---|---|---|
| AOT, 1000, tension 0 | 19.70-19.91 | 23.68-23.75 | +3.8-4.1 (19-20 %) | 2.18-2.21 |
| AOT, 1000, tension 0.4 | 50.60-51.65 | 54.77-55.63 | +3.2-4.2 (6-8 %) | 2.20-2.22 |
| AOT, 20000, tension 0 | 240.82-245.26 | 252.10-261.87 | +9.5-16.6 (4-7 %) | 42.67-43.55 |
| AOT, 20000, tension 0.4 | 1420.91-1455.53 | 1482.94-1521.95 | +27-71 (2-5 %) | 43.07-43.72 |
| wasm, 1000, tension 0 | 27.60-27.97 | 31.21-31.52 | +3.3-3.9 (12-14 %) | 3.55-3.60 |
| wasm, 1000, tension 0.4 | 93.91-95.97 | 110.58-111.63 | +15.7-16.7 (17-18 %) | 3.63-3.75 |
| wasm, 20000, tension 0 | 424.85-435.59 | 470.62-483.80 | +44-58 (10-14 %) | 94.08-96.82 |
| wasm, 20000, tension 0.4 | 2257.47-2269.19 | 2588.03-2688.28 | +320-431 (14-19 %) | 94.77-95.98 |

- The view costs at each draw, the copy once for each update. The copy costs less than the view
  from 1 to 5 draws for each update. An animation of the default 1000 ms draws about 60 frames.
- Of the copy forms (`points_copy`), `generate` is the fastest by a factor of 2 to 6: 36.3-40.5 µs
  (AOT) and 56.5-66.8 µs (wasm) for 20000 elements, against 160.4-165.8 µs and 375.9-433.9 µs for
  `List.of(data.cast())`.

**`getDataVisibility`** (ADR 0028 §4, P-B7). ns for each call. "I" is the body before phase 7
through `types.Chart`, "C" the same body after a cast to `Chart`, "IF" the interface call with
the early return:

| State | Platform | I | C | IF |
|---|---|---|---|---|
| no hidden index | AOT | 14.9-18.8 | 14.8-18.4 | 2.7-4.1 |
| no hidden index | wasm | 15.7-23.0 | 12.2-21.1 | 2.5-3.7 |
| one hidden index | AOT | 17.5-22.2 | 19.1-21.8 | 17.5-22.4 |
| one hidden index | wasm | 18.4-26.2 | 19.6-24.0 | 18.4-26.5 |

- The early return costs 0.4-0.9 ns more than a loop without a call. With a hidden index, it costs
  nothing measurable. For an update of 20000 bars without a hidden index, the calculation gives
  0.24-0.35 ms less. This is not a frame figure (section 13.7).

**The interface call, the writes by name and `total`** (ADR 0028, question 1). With one class
hierarchy behind an interface, the interface call costs the same as the call after a cast:
`getBasePixel()` 3.4 ns (AOT) and 3.2-3.3 ns (wasm); the `active` getter 0.4 ns and 0.3 ns. The
three writes by name of `controller.line.js:57-59` cost 4.7-4.8 ns (AOT) and 39.5-40.2 ns (wasm)
for each update of a dataset, against 1.1 ns and 0.6 ns for typed setters. The read of the typed
`ChartMeta.total` costs 0.7 ns. A read by name through the extras Map of `ChartMeta` costs
11.2-11.7 ns (AOT) and 18.1-18.7 ns (wasm).

### 13.3 The fixture runner (Chart.js ADR 0029)

- The `refresh` field of the animator (unit A1, `harness-method-fields`) is one field call for each
  frame: AOT 0.82-0.89 ns for the field call against 0.82-0.85 ns for the method call, dart2wasm
  0.337 ns against 0.336 ns (ADR 0029 Evidence E6). No frame effect. A1 took no new measurement.
- The cost of one fixture test (ADR 0029 Evidence E5, 300 tests): an empty `testWidgets` 2.2 ms,
  with `acquireChart` 4.9 ms, with the frame of `pumpFrame` 5.5 ms, a skipped `test()` 0.04 ms.
- The first full run of `test:fixtures` (step 4, F-int, 2026-10-21, Apple M3 Max, with the
  submodule and `FIXTURES_REQUIRED=1`): 565 tests with the tag `fixtures` in 20 spec files and
  `test/port/fixtures/moment_twins_test.dart` (529 fixtures and 36 twins) in 6.2 s wall time, with
  the compile. 457 fixtures and 36 twins pass, 72 fixtures skip. The 10 slowest tests take 243-281
  ms each: each is the first chart of its test file (for example
  `controller.scatter/showLine/changed.js` 281 ms, `controller.line/borderCapStyle/scriptable.js`
  269 ms, `controller.polarArea/angle-array.json` 264 ms). The other tests take a few ms each.
  The H units measured about 1 s for the 140 tests of the three radial prefixes and less than 1 s
  for the 98 tests of `controller.bar`, `controller.bubble` and `controller.scatter`.
- `test --no-select` excludes the tag. Thus the fixtures add only the compile of the registry
  import to the default run (0.24-0.37 s for 20 test files, ADR 0029 Evidence E4).
- Open (ADR 0029 Open item 2): when the hand ports of phase 8 make the import of
  `test/fixtures/index.dart` cost more than 4 s for each run of `test:fixtures` with `-j 1`, each
  spec file imports a registry of its own prefix. Chart.js ADR 0041 §9 keeps one registry. §14.4
  has the figures of phase 8.

### 13.4 The writable `DatasetController.ctx` (Chart.js ADR 0030)

- The cost of a writable field (ADR 0030 Evidence E3): AOT, 1.835 ns for each element draw with
  the final field and 1.770 ns with the writable field. Ratios writable / final of 0.95-1.08 on AOT
  and 0.99-1.02 on wasm. No frame effect.
- The data of the reference tests: with the element draws, the 8 phase 6 reference files grow by
  7.3 % (8,455,931 to 9,069,771 bytes). The hit items of a controller observation are one JSON line
  for each point: a probe of 3 bar cases took 1,521,132 bytes with the items as a Dart literal and
  495,325 bytes as JSON lines. `controller_bar_reference.dart` has 50 cases in 1,786,242 bytes.
  Wave 2: `controller_line_reference.dart` 32 cases in 1,576,533 bytes,
  `controller_bubble_reference.dart` 18 cases in 1,148,668 bytes,
  `controller_doughnut_reference.dart` 27 cases in 1,137,577 bytes,
  `controller_polar_area_reference.dart` 44 cases in 1,600,128 bytes and
  `controller_radar_reference.dart` 16 cases in 1,029,531 bytes. Wave 3:
  `controller_scatter_reference.dart` 17 cases in 1,324,744 bytes and
  `controller_pie_reference.dart` 8 cases in 510,783 bytes (511,303 bytes before the pie data
  `[5, 15, 10, 20]` of Chart.js ADR 0032). Each file is below 2.5 MB.
- The bar `draw` reads `ctx` for each bar, as `controller.bar.js:677`. A read before the loop is
  0.36 ns faster for each bar on AOT and 0.25 ns slower on wasm (ADR 0030 Open 3, section 13.7).

### 13.5 The stress chart of phase 7 (Chart.js ADR 0031)

The figures of the decision for the config of the stress mode `chart` (section 6). The Dart
figures come from `flutter test` (JIT) or from dart2wasm, the Node.js figures from the x64 Node.js
v24.12.0 and the Chart.js build at the pin. The Node.js times are relative only. The ADR Evidence
gives the commands and the files. Section 13.6 has the phone figures of step 7.

| Id | Probe | Result |
|---|---|---|
| J2 | Node.js, 5000 points, 600 frames with bounces, `update('none')` in each frame | The chosen form (x `suggestedMin`/`suggestedMax`, y `min`/`max`, `parsing: false`, `autoPadding: false`, `clip: false`, `ticks.display: false`): chart area 0, 0, 800, 480, no dataset clip, x range 0 to 1, all points draw, pixel error 5.7e-14 px against the fraction path. x `max: 1 + 2^-20`: all points draw, error 7.6e-4 px. The default padding and clip: chart area 5, 5, 795, 475. Bounds on x and y with `parsing: false`: 5000 points (line) and 2500 points (scatter) do not draw. |
| G1 | Dart, the phase 5 config against the hidden unit scales | With `autoPadding: false` and `clip: false`, the chart area is 0, 0, 800, 480 on both sides, and the pixels are equal within 5.7e-14 px. Without `autoPadding: false`, the area is 5, 5, 795, 475. |
| G2 | Dart, 5000 points, 600 frames | `parsing: false` with x `max: 1` gives up to 1250 points with `skip` or a wrong pixel. With parsing, or with a bound that no point reaches, 0. |
| G3, J3 | Dart, `update('none')` at 20000 points with sharing | The phase 5 fraction path 0.94-0.99 ms, the hidden unit scales with `parsing: false` 1.59 ms, the same with `parsing: true` 6.4-6.99 ms. The draw after a parsed update is 4.80 ms against 3.93 ms (garbage collection). The draw of the chosen form equals the phase 5 draw: 3.69 against 3.71 ms (JIT), 3.61 against 3.65 ms (wasm). The update costs 0.14-0.6 ms more than phase 5 at 1000-20000 points: the layout of the two hidden scales and `getPixelForValue`. |
| G4 | Dart | `ticks.display: false` on the two hidden scales saves 0.03-0.07 ms of each update (no auto skip, `core.scale.js:457`). |
| G5 | Dart JIT | The `getMaxOverflow` loop of scatter adds 0.20, 0.93 and 4.69 ms to an update of 1000, 5000 and 20000 points without sharing. This is upstream work (`controller.scatter.js:156-166`) that `StressPointController` did not do. |
| G6 | Dart JIT, mode `axes` | A dataset clip of 5 px moves the circle flush into `draw()`: `drawMs` grows by 24 % at 20000 points (3.91 to 4.84 ms). The sum of the draw and the end changes by 3 %. Thus `clip: false` keeps the phase 6 split. |
| G7 | Dart JIT | The timing plugin `StressChartTiming` adds no time outside the spread: at 20000 points, update 1.516 against 1.492 ms, draw 3.806 against 3.858 ms. |
| G8 | Node.js | With `parsing: false`, a radar chart has `iScale` and `vScale` both `r`. `getMinMax(r)` then reads only the first and the last value, and the range is wrong. `min` and `max` on `r` give the correct range. Thus the radial types have bounds on `r`. |

- E5b (Node.js): a hidden category axis with `ticks.display` true costs 24.0 ms for an update of
  5000 bars, against 9.4 ms without the ticks. Thus each hidden scale of the type cases has
  `ticks.display: false`. An indexable `backgroundColor` of 7 colors gives 12.5 ms for an update
  of a doughnut of 1000 arcs, against 1.0 ms with one color. Thus the type cases have one color.
- After the gallery change, the chart areas of the mode `axes` and of the cases `axes.*` equal
  those of `0e0ab93` for the linear, logarithmic and category axes (a test of the gallery). Thus
  the phase 6 figures of sections 11.6 and 11.7 stay comparable for the chart area.
- The cases `chart.doughnut` and `chart.pie` draw arcs of the full chart area: the dataset of
  these types has no `radius` (the doughnut option `radius` is `'100%'`,
  `controller.doughnut.js:229`). Measure them only on a tree with this fix (review G-U2, F1).
- The before figures of the cases `chart.a`, `chart.b`, `chart.c` and `axes.*` and of the stress
  modes `chart` and `axes` (commit `0e0ab93`) are a working file of phase 7, not committed. Step 7
  (G-U6) measured the sides A, A' and B of section 6. Section 13.6 has these figures with the
  before figures.

### 13.6 The figures of step 7

Step 7 of phase 7 measured the chart path on the phones from 2026-10-21 to 2026-10-22. The
protocols, the raw data, the scripts and the recomputes are working files of phase 7, not
committed. This section gives the figures and the decisions.

**Method.**

- Sides. A is a detached worktree of `0e0ab93` (the phase 5 and 6 tree). A' is A with the bridge
  patch of section 6. B is `c0a6576` (the phase 7 tree). In the A/B series of the candidates, A
  is `c0a6576` and B is `c0a6576` with the patch. Each patch passed `git apply --check`, and the
  SHA-256 of `git diff` of the B worktree equals the SHA-256 of the patch.
- Toolchain. Each side was built with Flutter 3.47.7 (Dart 3.13.5). The before figures of commit
  `0e0ab93` (a working file of phase 7, section 13.5) came from Flutter 3.44.9. Step 7 measured A
  again on Flutter 3.47.7. The two toolchains differ by about -8 % to +9 %, and most cells differ
  by less than 4 %.
- Builds. Profile builds, one at a time, in worktrees outside the main checkout. An Android build
  took 3-20 s with warm caches (the before/after series: 72 APKs in 867 s). Other sessions shared
  the Mac. Its 1-minute load was 1.3-5.5 during the builds. The Mac load does not change the
  timings on the phone.
- Runs. Each run is a fresh process (`am force-stop`, then `am start`). The app stays in front,
  and nobody touches the screen. After each run, no busy loop and no sampler stays on the phone.
- Gate of the Pixel 8a. Before each run or pair: the battery at 33.0 °C or less, and `cpu8` at
  2.8 GHz or more in a busy loop of 3 s that stops by itself. The gate waits at most 10 minutes. A
  sampler records the frequency of the core of the UI thread about two times a second. A case
  window is excluded when more than 10 % of its samples are below 2.5 GHz. A run is excluded when
  the phone got user input (`mLastUserActivityTime`), when the app was not in front at the end,
  when the run gave no `BENCH done`, or on a crash.
- The A/B series (G-U6 and the candidates). Each protocol was written before its first run.
  Pair i runs A then B when i is odd, and B then A when i is even. Stage 1 has 6 pairs. Stage 2
  adds 6 pairs when a main interval includes 0, when a main cell has fewer than 6 valid pairs, or
  when a control interval lies entirely above 0. A cell gives the mean of the pair differences of
  the run medians, with a 95 % percentile bootstrap interval (20000 resamples, a fixed seed). The
  decision rule of a candidate: accept B when the upper end of each main interval is below 0 and
  no control interval lies entirely above 0; reject B when a main or a control interval lies
  entirely above 0; else the result is inconclusive. A second agent recomputed each candidate
  series from the raw files with its own script. Each recompute gives the same figures (interval
  ends within 0.007 ms) and the same decision. The recomputes found text errors in the unit
  reports only, for example the count of excluded cells. This section uses the recomputed counts.
- The before/after series run 3 processes of each side in the order A B A B A B. They give the
  ratio of the medians, with no interval.
- Device state. Pixel 8a `4B071JEKB17363`, Android 17 (`CP3A.260905.009`), on AC power at 100 %.
  The keyguard was off before and after each run. iPhone 17 Pro (iOS 26.6.2) on the cable,
  `passcodeRequired: false` before and after each run (2026-10-21, 19:16-21:00 CEST). `devicectl`
  gives no temperature of the iPhone.
- Web. From 2026-10-22 08:10 CEST, a web run of step 7 runs only in the VS Code integrated
  browser (Chromium 148.0.7778.280 in Electron 42.8.1, VS Code 1.134.0) with dart2wasm, a rule of
  the maintainer. No Google Chrome run after that time counts. The Chrome 155 figures of this
  section and of section 13.8 come from runs before that time.
- Order of the units (CEST): G-U6 on the Pixel 8a from 2026-10-21 23:13 to 2026-10-22 02:39, the
  before/after series 02:45-05:55, the profile 06:05-07:09, the A/B series of the candidates
  08:02-13:40.

**G-U6: the A/B of section 6 on the Pixel 8a.** 48 runs: 12 pairs of S1 (A against A') and 12
pairs of S2 (A' against B). Both series needed stage 2. Each run gave `BENCH done`. One run (S1
p2 A') started after 10 minutes of gate wait at 33.1 °C (`pass=0`) and stays in. No run was
excluded as a whole. S2 p1 B had 8 of 12 cells below 2.5 GHz. About 30 other cells had 1 or 2 of
their 6-10 samples on a mid core at 2.37 GHz or lower. Thus a primary cell has 6-12 valid pairs.
Cells: the median of the run medians (minimum-maximum), in ms.

S1, the cost of the hidden scales (difference A' - A):

| Case | N | Metric | Pairs | A | A' | Mean diff | 95 % interval | Rel. | Result |
|---|---:|---|---:|---|---|---:|---|---:|---|
| chart.a | 1000 | draw | 8 | 0.332 (0.322-0.338) | 0.332 (0.322-0.374) | +0.004 | -0.006 .. +0.017 | +1.2 % | unresolved |
| chart.a | 5000 | draw | 10 | 1.651 (1.634-1.714) | 1.675 (1.632-1.730) | +0.013 | -0.024 .. +0.049 | +0.8 % | unresolved |
| chart.a | 20000 | draw | 11 | 6.702 (6.656-6.963) | 6.870 (6.698-6.963) | +0.070 | -0.038 .. +0.172 | +1.0 % | unresolved |
| chart.b sharing | 1000 | update | 12 | 0.166 (0.160-0.180) | 0.400 (0.395-0.409) | +0.234 | +0.232 .. +0.237 | +140.1 % | slower |
| chart.b sharing | 5000 | update | 10 | 0.538 (0.530-0.550) | 0.879 (0.854-0.888) | +0.336 | +0.324 .. +0.346 | +62.3 % | slower |
| chart.b sharing | 20000 | update | 12 | 2.103 (2.076-2.149) | 2.833 (2.793-2.906) | +0.734 | +0.708 .. +0.759 | +34.9 % | slower |
| chart.b no-sharing | 1000 | update | 10 | 0.340 (0.331-0.349) | 0.583 (0.559-0.607) | +0.244 | +0.235 .. +0.252 | +71.9 % | slower |
| chart.b no-sharing | 5000 | update | 12 | 1.401 (1.363-1.477) | 1.794 (1.766-1.837) | +0.390 | +0.363 .. +0.413 | +27.7 % | slower |
| chart.b no-sharing | 20000 | update | 12 | 5.600 (5.304-6.233) | 5.956 (5.845-6.932) | +0.464 | +0.307 .. +0.662 | +8.3 % | slower |
| chart.c | 1000 | update | 12 | 6.411 (6.303-6.907) | 6.655 (6.575-6.763) | +0.214 | +0.093 .. +0.307 | +3.3 % | slower |
| chart.c | 5000 | update | 10 | 33.349 (32.496-34.096) | 34.091 (33.458-35.893) | +1.141 | +0.476 .. +1.814 | +3.4 % | slower |
| chart.c | 20000 | update | 11 | 146.909 (135.795-152.229) | 148.246 (145.312-151.980) | +1.112 | -1.507 .. +4.293 | +0.8 % | unresolved |

S2, the cost of the ported controllers (difference B - A'):

| Case | N | Metric | Pairs | A' | B | Mean diff | 95 % interval | Rel. | Result |
|---|---:|---|---:|---|---|---:|---|---:|---|
| chart.a | 1000 | draw | 6 | 0.330 (0.322-0.336) | 0.337 (0.326-0.367) | +0.009 | -0.001 .. +0.020 | +2.9 % | unresolved |
| chart.a | 5000 | draw | 7 | 1.713 (1.638-1.734) | 1.666 (1.629-1.834) | -0.003 | -0.057 .. +0.058 | -0.2 % | unresolved |
| chart.a | 20000 | draw | 12 | 6.823 (6.652-6.965) | 6.848 (6.716-7.383) | +0.065 | -0.047 .. +0.184 | +1.0 % | unresolved |
| chart.b sharing | 1000 | update | 12 | 0.404 (0.399-0.416) | 0.601 (0.588-0.640) | +0.197 | +0.191 .. +0.206 | +48.8 % | slower |
| chart.b sharing | 5000 | update | 11 | 0.875 (0.855-0.889) | 1.674 (1.641-1.694) | +0.795 | +0.779 .. +0.811 | +91.1 % | slower |
| chart.b sharing | 20000 | update | 10 | 2.832 (2.792-2.868) | 5.921 (5.765-6.016) | +3.076 | +3.014 .. +3.135 | +108.5 % | slower |
| chart.b no-sharing | 1000 | update | 10 | 0.581 (0.567-0.595) | 1.155 (1.132-1.184) | +0.574 | +0.561 .. +0.586 | +98.7 % | slower |
| chart.b no-sharing | 5000 | update | 11 | 1.801 (1.785-1.842) | 4.549 (4.451-4.612) | +2.739 | +2.706 .. +2.770 | +152.0 % | slower |
| chart.b no-sharing | 20000 | update | 11 | 5.939 (5.801-6.945) | 21.043 (20.012-22.548) | +15.093 | +14.606 .. +15.613 | +247.4 % | slower |
| chart.c | 1000 | update | 11 | 6.664 (6.536-6.788) | 6.941 (6.845-7.192) | +0.298 | +0.210 .. +0.394 | +4.5 % | slower |
| chart.c | 5000 | update | 9 | 34.122 (33.430-35.382) | 35.859 (34.565-37.520) | +1.686 | +0.784 .. +2.594 | +4.9 % | slower |
| chart.c | 20000 | update | 10 | 150.757 (135.651-152.208) | 150.485 (147.166-159.517) | +2.881 | -1.864 .. +8.582 | +1.9 % | unresolved |

The parts of B (median of the run medians, minimum-maximum, ms):

| Case | N | Runs | elements | layout | datasetsUpdate | datasetsDraw |
|---|---:|---:|---|---|---|---|
| chart.a | 1000 | 6 | 0.000 | 0.000 | 0.000 | 0.335 (0.324-0.364) |
| chart.a | 5000 | 7 | 0.000 | 0.000 | 0.000 | 1.661 (1.625-1.829) |
| chart.a | 20000 | 12 | 0.000 | 0.000 | 0.000 | 6.707 (6.551-7.210) |
| chart.b sharing | 1000 | 12 | 0.007 (0.006-0.007) | 0.151 (0.147-0.163) | 0.316 (0.309-0.336) | 0.362 (0.351-0.394) |
| chart.b sharing | 5000 | 11 | 0.008 (0.008-0.009) | 0.162 (0.154-0.167) | 1.350 (1.315-1.366) | 1.836 (1.814-1.872) |
| chart.b sharing | 20000 | 10 | 0.016 (0.015-0.017) | 0.228 (0.221-0.233) | 5.399 (5.244-5.464) | 8.230 (8.144-8.371) |
| chart.b no-sharing | 1000 | 10 | 0.213 (0.203-0.218) | 0.160 (0.154-0.170) | 0.657 (0.640-0.667) | 0.366 (0.354-0.378) |
| chart.b no-sharing | 5000 | 11 | 1.031 (1.011-1.052) | 0.189 (0.183-0.197) | 3.164 (3.095-3.200) | 1.829 (1.783-1.877) |
| chart.b no-sharing | 20000 | 11 | 4.786 (4.520-5.055) | 0.259 (0.248-0.264) | 15.566 (14.638-16.830) | 10.507 (9.722-11.101) |
| chart.c | 1000 | 11 | 0.042 (0.041-0.044) | 0.167 (0.165-0.179) | 6.560 (6.446-6.821) | 1.632 (1.561-1.675) |
| chart.c | 5000 | 9 | 0.069 (0.065-0.076) | 0.253 (0.242-0.282) | 35.251 (33.796-36.544) | 8.455 (8.306-8.886) |
| chart.c | 20000 | 10 | 0.084 (0.083-0.101) | 0.267 (0.261-0.304) | 149.812 (146.411-158.635) | 33.869 (31.372-37.051) |

- S1 agrees with Chart.js ADR 0031 G3 (+0.14 to +0.6 ms). The `chart.b` update with sharing at
  20000 (+0.734 ms) is a little above that range. The `chart.a` draw shows no resolved difference.
- S2: the `chart.b` update is slower in each cell, by 49-109 % with sharing and by 99-247 %
  without sharing. Without sharing, the part `elements` of B (the scatter `getMaxOverflow` loop,
  upstream work) is 0.213 / 1.031 / 4.786 ms, close to G5 (0.20 / 0.93 / 4.69 ms). The rest of the
  cost is in `datasetsUpdate`: 15.6 ms at 20000, against an A' update of 5.9 ms. The `chart.a`
  draw has no resolved difference at each count.
- Secondary S2 cells with a resolved cost: the `chart.b` draw without sharing at 20000 (+1.125 ms,
  +0.838 .. +1.445), the `chart.b` draw with sharing at 20000 (+0.131 ms), and the `chart.c` draw
  at 1000 and 5000 (+0.080 and +0.267 ms).
- By the protocol, a primary S2 cell with a cost of 0.1 ms or more for each frame is a candidate
  item of section 13.7: the six `chart.b` update cells and the `chart.c` update at 1000 and 5000
  (section 13.7 item 9).
- Builds (`--dart-define=CASES=chart.a,chart.b,chart.c --dart-define=N=1000,5000,20000`): A 20 s,
  A' 16 s and B 3 s, at a Mac load of 3.65-4.59.
- macOS (a record, not a decision of this step). Another unit ran G-U6 on macOS: pairs 1-4 on
  2026-10-21 from 18:52 to 21:15 CEST, then pairs 5-12 from 23:59 to 00:43. S1 has 9 and S2 has 11
  valid pairs. S2 on macOS: `chart.a` draw -1.6 to -2.4 %; `chart.b` update +0.13 / +0.51 /
  +1.96 ms with sharing and +0.33 / +1.62 / +7.39 ms without sharing; `chart.c` update +0.12 /
  +0.44 / +2.27 ms. Many runs were not in front, and the user gave input on the Mac during them.
  The protocol kept these runs.

**Before and after: the frameless benchmark on the Pixel 8a.** 90 runs from 02:45 to 05:55 CEST.
Each run passed the gate (battery 32.5-33.0 °C, `cpu8` at 2.91 GHz, waits of 3-366 s). No run was
excluded. A full-case process of B (72 cells, 300 s) throttles the UI core after about 97 s: 45
of the 72 windows of each B run ran below 2.5 GHz. Thus `chart.a`, `chart.b` and `chart.c` come
from the full-case processes (3 A, 3 B), and the other cells come from short groups that run alone:
`axes.linear` and `axes.logarithmic`, `axes.category` and `axes.time` (A and B, A B A B A B), and
three groups of the type cases (B, 3 runs each). Each value is the median of the run medians in
ms. "before" is commit `0e0ab93` on Flutter 3.44.9. A is `0e0ab93` and B is `c0a6576`, both on
Flutter 3.47.7.

| Case | N | update: before | update: A | update: B | update B / A | draw: before | draw: A | draw: B | draw B / A | end: A | end: B |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| chart.a | 1000 | - | - | - | - | 0.329 | 0.323 | 0.331 | 1.02 | 0.069 | 0.069 |
| chart.a | 5000 | - | - | - | - | 1.679 | 1.642 | 1.649 | 1.00 | 0.330 | 0.323 |
| chart.a | 20000 | - | - | - | - | 6.812 | 6.737 | 6.684 | 0.99 | 1.930 | 1.952 |
| chart.b sharing | 1000 | 0.162 | 0.168 | 0.593 | 3.53 | 0.353 | 0.365 | 0.367 | 1.01 | 0.076 | 0.082 |
| chart.b sharing | 5000 | 0.533 | 0.535 | 1.654 | 3.09 | 1.769 | 1.779 | 1.860 | 1.05 | 0.341 | 0.346 |
| chart.b sharing | 20000 | 2.059 | 2.086 | 5.769 | 2.77 | 8.152 | 8.184 | 8.319 | 1.02 | 2.053 | 2.109 |
| chart.b no-sharing | 1000 | 0.336 | 0.358 | 1.153 | 3.22 | 0.367 | 0.386 | 0.373 | 0.97 | 0.080 | 0.087 |
| chart.b no-sharing | 5000 | 1.395 | 1.402 | 4.519 | 3.22 | 1.820 | 1.829 | 1.832 | 1.00 | 0.354 | 0.379 |
| chart.b no-sharing | 20000 | 5.181 | 5.382 | 21.484 | 3.99 | 9.246 | 9.137 | 10.904 | 1.19 | 2.060 | 2.212 |
| chart.c | 1000 | 6.333 | 6.354 | 6.844 | 1.08 | 1.503 | 1.560 | 1.635 | 1.05 | 1.356 | 1.349 |
| chart.c | 5000 | 32.658 | 34.068 | 36.389 | 1.07 | 8.272 | 8.388 | 8.670 | 1.03 | 5.131 | 5.139 |
| chart.c | 20000 | 144.485 | 145.068 | 146.328 | 1.01 | 33.094 | 33.828 | 34.648 | 1.02 | 12.671 | 12.543 |
| axes.linear draw | 1000 | - | - | - | - | 0.464 | 0.472 | 0.473 | 1.00 | 0.099 | 0.103 |
| axes.linear draw | 5000 | - | - | - | - | 1.833 | 1.859 | 1.814 | 0.98 | 0.392 | 0.387 |
| axes.linear draw | 20000 | - | - | - | - | 6.997 | 7.127 | 7.002 | 0.98 | 2.101 | 2.104 |
| axes.linear update | 1000 | 0.705 | 0.720 | 0.904 | 1.26 | 0.697 | 0.728 | 0.751 | 1.03 | 0.113 | 0.114 |
| axes.linear update | 5000 | 1.501 | 1.521 | 2.229 | 1.47 | 2.148 | 2.223 | 2.242 | 1.01 | 0.412 | 0.407 |
| axes.linear update | 20000 | 4.598 | 4.606 | 7.452 | 1.62 | 8.708 | 8.756 | 9.031 | 1.03 | 2.203 | 2.282 |
| axes.logarithmic draw | 1000 | - | - | - | - | 0.540 | 0.553 | 0.542 | 0.98 | 0.119 | 0.118 |
| axes.logarithmic draw | 5000 | - | - | - | - | 1.937 | 1.958 | 1.915 | 0.98 | 0.415 | 0.408 |
| axes.logarithmic draw | 20000 | - | - | - | - | 7.177 | 7.262 | 7.138 | 0.98 | 2.105 | 2.101 |
| axes.logarithmic update | 1000 | 0.987 | 1.015 | 1.201 | 1.18 | 0.891 | 0.921 | 0.912 | 0.99 | 0.135 | 0.136 |
| axes.logarithmic update | 5000 | 2.044 | 2.064 | 2.825 | 1.37 | 2.373 | 2.456 | 2.402 | 0.98 | 0.444 | 0.438 |
| axes.logarithmic update | 20000 | 6.108 | 6.328 | 9.223 | 1.46 | 9.045 | 9.500 | 9.261 | 0.97 | 2.325 | 2.338 |
| axes.category draw | 1000 | - | - | - | - | 0.634 | 0.605 | 0.625 | 1.03 | 0.108 | 0.111 |
| axes.category draw | 5000 | - | - | - | - | 2.043 | 1.970 | 2.051 | 1.04 | 0.388 | 0.405 |
| axes.category draw | 20000 | - | - | - | - | 7.520 | 7.222 | 7.448 | 1.03 | 2.015 | 2.083 |
| axes.category update | 1000 | 4.084 | 4.144 | 4.382 | 1.06 | 1.106 | 1.114 | 1.115 | 1.00 | 0.131 | 0.135 |
| axes.category update | 5000 | 20.378 | 20.543 | 21.830 | 1.06 | 2.722 | 2.809 | 2.831 | 1.01 | 0.481 | 0.496 |
| axes.category update | 20000 | 97.440 | 96.511 | 101.441 | 1.05 | 10.696 | 11.638 | 11.994 | 1.03 | 2.194 | 2.252 |
| axes.time draw | 1000 | - | - | - | - | 0.632 | 0.619 | 0.633 | 1.02 | 0.116 | 0.121 |
| axes.time draw | 5000 | - | - | - | - | 1.934 | 1.884 | 1.938 | 1.03 | 0.386 | 0.398 |
| axes.time draw | 20000 | - | - | - | - | 7.437 | 7.313 | 7.369 | 1.01 | 2.071 | 2.101 |
| axes.time update | 1000 | 1.076 | 1.033 | 1.253 | 1.21 | 1.074 | 1.035 | 1.068 | 1.03 | 0.131 | 0.137 |
| axes.time update | 5000 | 1.743 | 1.645 | 2.511 | 1.53 | 2.366 | 2.247 | 2.377 | 1.06 | 0.406 | 0.430 |
| axes.time update | 20000 | 5.597 | 5.155 | 8.569 | 1.66 | 9.614 | 9.031 | 9.823 | 1.09 | 2.201 | 2.452 |

- The `chart.b` update of B is 2.8-4.0 times A. The `chart.c` update is 1.01-1.08 times A. The draw
  is 0.97-1.05 times A, except `chart.b` without sharing at 20000 (1.19).
- The `axes.*` update of B is 1.18-1.66 times A for the linear, logarithmic and time axes. It grows
  with N: this is the controller path of S2. The category update is 1.05-1.06 times A. The
  `axes.*` draw is 0.97-1.09 times A.
- The toolchain step: A on Flutter 3.47.7 is within about -8 % to +9 % of before. The largest steps
  are the `axes.time` update at 20000 (-8 %) and the `axes.category` draw at 20000 (+9 %). The
  before figures of the time update (commit `0e0ab93` on Flutter 3.44.9, a working file of phase
  7, section 13.5) ran at 2.36-2.69 GHz.

The type cases of Chart.js ADR 0031 §7 on the Pixel 8a, side B (median of the run medians in ms;
the counts of the type). The column "windows" gives the valid windows of 3. Bubble draw at 5000
and 20000 ran at 2.69-2.91 GHz. The other windows ran at 2.91 GHz.

| Type | N | draw case: draw | draw case: end | update case: update | update case: draw | update case: elements | update case: datasetsUpdate | windows (update case) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| bar | 1000 | 2.561 | 5.295 | 4.966 | 2.985 | 0.312 | 4.064 | 3 |
| bar | 5000 | 13.326 | 9.303 | 34.784 | 17.680 | 1.556 | 30.662 | 3 |
| bar | 20000 | 56.044 | 116.594 | 141.112 | 68.247 | 6.542 | 126.974 | 3 |
| bubble | 1000 | 1.492 | 1.217 | 2.685 | 1.612 | 1.059 | 1.299 | 2 |
| bubble | 5000 | 7.431 | 4.169 | 12.340 | 8.127 | 5.268 | 6.458 | 2 |
| bubble | 20000 | 30.742 | 12.370 | 68.588 | 34.884 | 27.139 | 40.754 | 2 |
| doughnut | 100 | 0.612 | 0.070 | 0.238 | 0.623 | 0.007 | 0.184 | 2 |
| doughnut | 1000 | 6.081 | 0.649 | 1.557 | 6.219 | 0.029 | 1.464 | 2 |
| doughnut | 5000 | 32.591 | 5.952 | 10.576 | 35.631 | 0.124 | 9.372 | 2 |
| pie | 100 | 0.517 | 0.047 | 0.236 | 0.535 | 0.007 | 0.182 | 3 |
| pie | 1000 | 5.270 | 1.037 | 1.568 | 5.395 | 0.028 | 1.474 | 3 |
| pie | 5000 | 28.632 | 17.595 | 10.502 | 29.814 | 0.126 | 9.945 | 3 |
| polarArea | 100 | 0.507 | 0.032 | 0.358 | 0.546 | 0.021 | 0.161 | 3 |
| polarArea | 1000 | 5.008 | 0.701 | 1.853 | 5.381 | 0.146 | 1.355 | 3 |
| polarArea | 5000 | 27.912 | 15.005 | 13.012 | 31.043 | 0.636 | 9.828 | 3 |
| radar | 100 | 0.052 | 0.016 | 0.350 | 0.065 | 0.019 | 0.155 | 3 |
| radar | 1000 | 0.423 | 0.076 | 1.748 | 0.596 | 0.253 | 1.165 | 3 |
| radar | 5000 | 2.082 | 0.350 | 8.206 | 2.880 | 1.290 | 5.746 | 3 |

**The iPhone 17 Pro.** 3 A and 3 B processes in the order A B A B A B, the default cases and
counts. The phone got slower from run to run: the run medians rose by about 15-25 % from run 1 to
run 3 on both sides. In this order, each B run follows its A run. Thus the plain ratio B / A of the
medians below is biased upward. The working files also give a bracketed ratio (each B run against
the mean of the A runs before and after it): there, the draw and the end are within -6 % to +5 %,
except the draw of `chart.b` without sharing at 20000 (1.09-1.10).

| Case | N | update B / A | draw B / A | end B / A |
|---|---:|---|---|---|
| chart.a | 1000 | - | 0.170 / 0.167 = 1.02 | 0.041 / 0.040 = 1.02 |
| chart.a | 5000 | - | 0.961 / 0.856 = 1.12 | 0.218 / 0.190 = 1.15 |
| chart.a | 20000 | - | 3.871 / 3.489 = 1.11 | 0.872 / 0.762 = 1.14 |
| chart.b sharing | 1000 | 0.354 / 0.080 = 4.42 | 0.196 / 0.173 = 1.13 | 0.048 / 0.043 = 1.12 |
| chart.b sharing | 5000 | 0.986 / 0.258 = 3.82 | 0.993 / 0.898 = 1.11 | 0.222 / 0.204 = 1.09 |
| chart.b sharing | 20000 | 3.480 / 0.927 = 3.75 | 4.346 / 3.972 = 1.09 | 0.897 / 0.809 = 1.11 |
| chart.b no-sharing | 1000 | 0.649 / 0.172 = 3.77 | 0.197 / 0.177 = 1.11 | 0.048 / 0.044 = 1.09 |
| chart.b no-sharing | 5000 | 2.592 / 0.734 = 3.53 | 1.024 / 0.931 = 1.10 | 0.226 / 0.207 = 1.09 |
| chart.b no-sharing | 20000 | 12.680 / 3.755 = 3.38 | 5.480 / 4.483 = 1.22 | 0.974 / 0.849 = 1.15 |
| chart.c | 1000 | 3.863 / 3.312 = 1.17 | 0.624 / 0.563 = 1.11 | 0.533 / 0.489 = 1.09 |
| chart.c | 5000 | 19.792 / 18.272 = 1.08 | 3.245 / 3.204 = 1.01 | 2.298 / 2.191 = 1.05 |
| chart.c | 20000 | 80.452 / 77.171 = 1.04 | 12.759 / 12.548 = 1.02 | 8.935 / 8.907 = 1.00 |
| axes.linear draw | 1000 | - | 0.250 / 0.245 = 1.02 | 0.063 / 0.063 = 1.00 |
| axes.linear draw | 5000 | - | 1.044 / 1.034 = 1.01 | 0.265 / 0.259 = 1.02 |
| axes.linear draw | 20000 | - | 4.055 / 4.104 = 0.99 | 0.987 / 0.979 = 1.01 |
| axes.linear update | 1000 | 0.553 / 0.412 = 1.34 | 0.372 / 0.358 = 1.04 | 0.067 / 0.066 = 1.02 |
| axes.linear update | 5000 | 1.313 / 0.822 = 1.60 | 1.175 / 1.200 = 0.98 | 0.269 / 0.271 = 0.99 |
| axes.linear update | 20000 | 4.376 / 2.379 = 1.84 | 4.651 / 4.683 = 0.99 | 1.038 / 1.028 = 1.01 |
| axes.logarithmic draw | 1000 | - | 0.282 / 0.279 = 1.01 | 0.068 / 0.066 = 1.03 |
| axes.logarithmic draw | 5000 | - | 1.094 / 1.080 = 1.01 | 0.272 / 0.268 = 1.01 |
| axes.logarithmic draw | 20000 | - | 4.162 / 4.143 = 1.00 | 1.018 / 0.996 = 1.02 |
| axes.logarithmic update | 1000 | 0.732 / 0.578 = 1.27 | 0.461 / 0.446 = 1.03 | 0.069 / 0.067 = 1.03 |
| axes.logarithmic update | 5000 | 1.757 / 1.152 = 1.53 | 1.299 / 1.270 = 1.02 | 0.277 / 0.271 = 1.02 |
| axes.logarithmic update | 20000 | 5.743 / 3.342 = 1.72 | 4.777 / 4.723 = 1.01 | 1.050 / 1.033 = 1.02 |
| axes.category draw | 1000 | - | 0.315 / 0.306 = 1.03 | 0.068 / 0.066 = 1.03 |
| axes.category draw | 5000 | - | 1.138 / 1.118 = 1.02 | 0.276 / 0.267 = 1.03 |
| axes.category draw | 20000 | - | 4.273 / 4.182 = 1.02 | 1.038 / 0.997 = 1.04 |
| axes.category update | 1000 | 2.609 / 2.382 = 1.10 | 0.542 / 0.524 = 1.03 | 0.070 / 0.067 = 1.04 |
| axes.category update | 5000 | 13.240 / 12.270 = 1.08 | 1.502 / 1.461 = 1.03 | 0.298 / 0.286 = 1.04 |
| axes.category update | 20000 | 62.154 / 55.427 = 1.12 | 6.344 / 6.030 = 1.05 | 1.228 / 1.123 = 1.09 |
| axes.time draw | 1000 | - | 0.319 / 0.301 = 1.06 | 0.070 / 0.065 = 1.08 |
| axes.time draw | 5000 | - | 1.093 / 1.080 = 1.01 | 0.274 / 0.265 = 1.03 |
| axes.time draw | 20000 | - | 4.244 / 4.257 = 1.00 | 1.044 / 0.995 = 1.05 |
| axes.time update | 1000 | 0.728 / 0.576 = 1.26 | 0.533 / 0.510 = 1.05 | 0.069 / 0.066 = 1.05 |
| axes.time update | 5000 | 1.441 / 0.891 = 1.62 | 1.257 / 1.222 = 1.03 | 0.282 / 0.273 = 1.03 |
| axes.time update | 20000 | 4.827 / 2.689 = 1.80 | 4.911 / 4.823 = 1.02 | 1.090 / 1.053 = 1.04 |

The type cases on the iPhone, side B (median of 3 run medians in ms):

| Type | N | draw case: draw | update case: update | update case: draw |
|---|---:|---:|---:|---:|
| bar | 1000 / 5000 / 20000 | 1.173 / 5.728 / 24.815 | 3.008 / 18.776 / 78.128 | 1.169 / 7.042 / 27.399 |
| bubble | 1000 / 5000 / 20000 | 0.649 / 3.150 / 12.506 | 1.691 / 8.243 / 43.036 | 0.648 / 3.245 / 15.035 |
| doughnut | 100 / 1000 / 5000 | 0.252 / 2.460 / 12.167 | 0.159 / 1.032 / 5.118 | 0.251 / 2.447 / 12.685 |
| pie | 100 / 1000 / 5000 | 0.212 / 2.028 / 10.405 | 0.158 / 1.028 / 5.212 | 0.212 / 2.057 / 10.956 |
| polarArea | 100 / 1000 / 5000 | 0.208 / 1.998 / 10.203 | 0.238 / 1.151 / 6.042 | 0.209 / 2.029 / 12.031 |
| radar | 100 / 1000 / 5000 | 0.030 / 0.252 / 1.240 | 0.225 / 0.958 / 4.504 | 0.032 / 0.272 / 1.388 |

- The iPhone gives the same picture as the Pixel 8a: the `chart.b` update of B is 3.4-4.4 times
  A, and the `axes.*` update of the linear, logarithmic and time axes grows with N (1.26-1.84).
- macOS and Chrome (a record of another unit, 2026-10-22 01:00-02:20 CEST, 3 + 3 processes each):
  the bracketed `chart.b` update B / A is 3.1-4.1 on macOS and 2.6-3.3 in Chrome 155 with
  dart2wasm. The `chart.c` update is 1.01-1.06 and 0.99-1.03. The `chart.a` draw is 0.99-1.00.

**The stress entry (frame figures).** Side B on the Pixel 8a: one fresh process for each scenario,
the means of the `STRESS` line in ms. A 7-s run with FPS 0.00 gave no frame in its window. Its
60-s row is the figure. The UI-core column is the median in the run: the governor keeps it low
under a light load, so the stress runs have no frequency exclusion. Each gate passed (battery
32.5-33.0 °C, `cpu8` at 2.91 GHz). "before" is the stress record of commit `0e0ab93` on Flutter
3.44.9 (a working file of phase 7, section 13.5). The maximum build and raster times are in the
working files.

| Mode / type | Call | N | s | FPS | updateMs | drawMs | buildMs | rasterMs | UI core (GHz) | before: FPS / buildMs / drawMs / rasterMs |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| chart / line | draw | 1000 | 7 | 58.34 | 0.01 | 5.72 | 6.51 | 5.78 | 0.61 | 58.02 / 6.17 / 5.53 / 5.23 |
| chart / line | draw | 5000 | 7 | 57.51 | 0.00 | 7.61 | 8.39 | 4.89 | 0.71 | 59.00 / 7.87 / 7.38 / 4.83 |
| chart / line | draw | 20000 | 7 | 50.91 | 0.00 | 11.73 | 12.36 | 7.68 | 2.77 | 56.86 / 12.75 / 12.03 / 7.72 |
| chart / line | update | 1000 | 7 | 58.00 | 3.22 | 2.99 | 7.11 | 4.86 | 0.91 | 59.01 / 6.12 / 3.85 / 4.66 |
| chart / line | update | 5000 | 7 | 57.17 | 4.02 | 4.71 | 10.03 | 5.02 | 1.42 | 57.67 / 9.12 / 6.27 / 5.04 |
| chart / line | update | 20000 | 7 | 30.45 | 6.56 | 11.65 | 21.21 | 9.90 | 2.91 | 39.52 / 16.90 / 12.14 / 9.15 |
| chart / scatter | draw | 1000 | 7 | 58.50 | 0.01 | 5.52 | 6.18 | 5.53 | 0.58 | - |
| chart / scatter | draw | 5000 | 7 | 58.01 | 0.01 | 7.53 | 8.22 | 5.04 | 0.91 | - |
| chart / scatter | draw | 20000 | 7 | 50.46 | 0.00 | 11.73 | 12.53 | 7.72 | 2.31 | - |
| chart / scatter | update | 1000 | 7 | 58.34 | 4.57 | 2.62 | 8.06 | 4.45 | 0.80 | - |
| chart / scatter | update | 5000 | 7 | 48.26 | 6.40 | 4.56 | 12.02 | 5.98 | 1.84 | - |
| chart / scatter | update | 20000 | 7 | 20.35 | 24.43 | 14.32 | 40.56 | 8.70 | 2.91 | - |
| chart / bar | draw | 1000 | 7 | 42.94 | 0.00 | 4.60 | 15.50 | 13.32 | 2.77 | - |
| chart / bar | draw | 5000 | 7 | 21.84 | 0.00 | 16.98 | 32.56 | 36.30 | 2.91 | - |
| chart / bar | draw | 20000 | 7 | 5.24 | 0.00 | 74.73 | 170.48 | 120.22 | 2.37 | - |
| chart / bar | update | 1000 | 7 | 27.72 | 7.88 | 4.96 | 23.81 | 15.68 | 2.62 | - |
| chart / bar | update | 5000 | 7 | 12.36 | 34.92 | 18.66 | 67.03 | 43.49 | 2.91 | - |
| chart / bar | update | 20000 | 60 | 3.17 | 150.63 | 63.97 | 301.48 | 163.08 | 2.91 | - |
| chart / bubble | draw | 1000 | 7 | 57.84 | 0.00 | 4.93 | 10.22 | 11.69 | 1.33 | - |
| chart / bubble | draw | 5000 | 7 | 30.90 | 0.00 | 15.14 | 18.49 | 26.52 | 1.57 | - |
| chart / bubble | draw | 20000 | 7 | 11.71 | 0.00 | 48.53 | 72.64 | 85.48 | 2.37 | - |
| chart / bubble | update | 1000 | 7 | 53.20 | 4.83 | 3.17 | 11.67 | 11.13 | 1.56 | - |
| chart / bubble | update | 5000 | 7 | 24.49 | 14.60 | 9.24 | 27.08 | 34.41 | 2.91 | - |
| chart / bubble | update | 20000 | 7 | 6.40 | 84.40 | 33.81 | 140.97 | 99.12 | 2.37 | - |
| chart / doughnut | draw | 1000 | 7 | 48.81 | 0.00 | 10.90 | 12.05 | 14.98 | 2.25 | - |
| chart / doughnut | draw | 5000 | 7 | 16.01 | 0.00 | 40.73 | 47.37 | 50.82 | 2.37 | - |
| chart / doughnut | draw | 20000 | 60 | 3.42 | 0.00 | 160.21 | 251.47 | 192.13 | 2.91 | - |
| chart / doughnut | update | 1000 | 7 | 41.27 | 2.89 | 9.90 | 13.85 | 16.08 | 2.61 | - |
| chart / doughnut | update | 5000 | 7 | 12.77 | 11.88 | 38.78 | 57.54 | 61.84 | 2.37 | - |
| chart / doughnut | update | 20000 | 60 | 3.07 | 50.94 | 153.05 | 290.47 | 201.73 | 2.91 | - |
| chart / pie | draw | 1000 | 7 | 53.88 | 0.00 | 9.55 | 11.79 | 13.70 | 1.95 | - |
| chart / pie | draw | 5000 | 7 | 13.52 | 0.00 | 34.01 | 54.45 | 60.03 | 2.37 | - |
| chart / pie | draw | 20000 | 60 | 2.73 | 0.00 | 130.82 | 314.54 | 293.29 | 2.91 | - |
| chart / pie | update | 1000 | 7 | 44.30 | 2.74 | 8.67 | 13.38 | 15.48 | 2.00 | - |
| chart / pie | update | 5000 | 7 | 12.46 | 11.02 | 31.16 | 61.20 | 62.00 | 2.91 | - |
| chart / pie | update | 20000 | 60 | 2.20 | 52.86 | 128.70 | 409.37 | 310.66 | 2.91 | - |
| chart / polarArea | draw | 1000 | 7 | 53.02 | 0.00 | 9.75 | 11.40 | 14.12 | 2.37 | - |
| chart / polarArea | draw | 5000 | 7 | 15.72 | 0.00 | 36.46 | 50.10 | 45.12 | 2.37 | - |
| chart / polarArea | draw | 20000 | 60 | 2.53 | 0.00 | 133.03 | 360.44 | 271.56 | 2.91 | - |
| chart / polarArea | update | 1000 | 7 | 44.71 | 3.37 | 8.50 | 13.18 | 15.35 | 2.04 | - |
| chart / polarArea | update | 5000 | 7 | 12.02 | 13.74 | 31.93 | 61.88 | 58.46 | 2.91 | - |
| chart / polarArea | update | 20000 | 60 | 2.22 | 67.75 | 120.46 | 408.24 | 272.05 | 2.91 | - |
| chart / radar | draw | 1000 | 7 | 58.17 | 0.01 | 5.64 | 6.41 | 5.61 | 0.70 | - |
| chart / radar | draw | 5000 | 7 | 57.51 | 0.01 | 8.42 | 9.13 | 6.06 | 0.91 | - |
| chart / radar | draw | 20000 | 7 | 57.19 | 0.00 | 11.51 | 12.50 | 11.13 | 2.85 | - |
| chart / radar | update | 1000 | 7 | 57.84 | 5.20 | 2.82 | 8.62 | 4.28 | 0.91 | - |
| chart / radar | update | 5000 | 7 | 46.16 | 9.19 | 4.46 | 14.29 | 8.00 | 2.85 | - |
| chart / radar | update | 20000 | 7 | 14.04 | 39.44 | 20.50 | 57.50 | 11.69 | 2.91 | - |
| axes / linear | draw | 5000 | 7 | 57.68 | 0.01 | 8.12 | 8.93 | 5.06 | 0.91 | 57.69 / 8.54 / 7.80 / 4.73 |
| axes / linear | update | 5000 | 7 | 56.51 | 4.57 | 5.09 | 10.65 | 5.64 | 1.57 | 56.52 / 10.04 / 5.82 / 5.28 |
| axes / logarithmic | draw | 5000 | 7 | 57.66 | 0.01 | 8.29 | 9.11 | 5.07 | 0.91 | 57.82 / 8.72 / 7.90 / 4.45 |
| axes / logarithmic | update | 5000 | 7 | 56.52 | 5.11 | 4.83 | 10.96 | 5.62 | 1.84 | 54.23 / 10.63 / 5.75 / 5.39 |
| axes / category | draw | 5000 | 7 | 58.17 | 0.01 | 8.13 | 8.92 | 5.22 | 0.91 | 58.35 / 8.40 / 7.69 / 4.76 |
| axes / category | update | 5000 | 7 | 27.91 | 22.90 | 3.49 | 27.46 | 7.50 | 2.91 | 28.43 / 26.02 / 3.28 / 6.51 |
| axes / time | draw | 5000 | 7 | 58.32 | 0.00 | 8.20 | 9.05 | 5.25 | 0.91 | 58.03 / 8.70 / 7.92 / 4.56 |
| axes / time | update | 5000 | 7 | 53.87 | 4.84 | 5.35 | 11.06 | 5.81 | 1.70 | 54.23 / 10.13 / 6.03 / 5.26 |

- Seven scenarios gave no frame in 7 s and ran again with `SECONDS=60`: bar update, doughnut draw
  and update, pie draw and update, and polar area draw and update, each at 20000.
- The 14 scenarios with a before figure agree with before within about ±2 FPS (11 of 14 within 1.5
  FPS).
  The exceptions are the line draw at 20000 (50.91 against 56.86 FPS) and the line update at
  20000 (30.45 against 39.52 FPS, `updateMs` 6.56 against 2.44 ms). The update is the S2 cost of
  G-U6. The axes scenarios keep the ticks and the rotation of before (6 / 0, 11 / 50, 14 / 50 and
  14 / 50).

The stress entry of side B on the iPhone 17 Pro (mode `chart`, `SECONDS=7`, one process each, a
120 Hz display; no scenario was below 4.5 FPS):

| Type | draw FPS at 1000 / 5000 / 20000 | update FPS at 1000 / 5000 / 20000 | update at 20000: updateMs / drawMs / buildMs / rasterMs |
|---|---|---|---|
| line | 118.32 / 119.68 / 119.83 | 119.95 / 119.85 / 116.75 | 2.77 / 4.17 / 7.39 / 0.60 |
| scatter | 119.67 / 119.53 / 119.83 | 119.61 / 119.83 / 58.43 | 9.70 / 4.85 / 15.17 / 0.61 |
| bar | 119.89 / 63.08 / 13.47 | 119.84 / 34.85 / 7.36 | 61.06 / 21.56 / 129.60 / 18.54 |
| bubble | 118.93 / 119.55 / 34.89 | 120.01 / 67.00 / 16.16 | 35.52 / 10.88 / 57.15 / 22.17 |
| doughnut | 120.01 / 59.66 / 11.01 | 119.99 / 41.62 / 8.94 | 19.66 / 40.20 / 105.71 / 29.61 |
| pie | 119.63 / 48.01 / 5.93 | 119.95 / 40.43 / 5.29 | 20.83 / 35.73 / 177.60 / 26.19 |
| polarArea | 120.04 / 56.77 / 5.88 | 120.00 / 40.11 / 4.93 | 28.90 / 33.57 / 190.03 / 25.30 |
| radar | 119.91 / 119.88 / 116.61 | 120.02 / 119.83 / 36.32 | 19.77 / 4.77 / 24.41 / 1.00 |

- The arc types are limited by the UI thread: the build time is much larger than `drawMs`. For
  example, the pie draw at 20000 has a build of 160 ms, a `datasetsDraw` of 34.6 ms and a raster
  of 26 ms.
- These figures answer Chart.js ADR 0032 Open 2 (section 13.8).

**The profile: the port against upstream.** 06:05-07:09 CEST. Nothing failed, and no run was
excluded.

- The port. 9 profile APKs of `c0a6576` (11-17 s each, Mac load 2.0-2.7), 18 fresh processes (2
  for each selector, `CASES=chart.<name>`, `BATCHES=30`) at 5000 points or 1000 arcs.
  `getCpuSamples` over the VM service, with a sample period of 1 ms.
- Upstream. The Chart.js ESM build of the pin (no plugin) in a page that Chrome 155 on the Pixel
  8a opened (through `adb reverse`). 15 timing runs of 12 cells each, and 4 runs with V8 CPU
  profiles. The data of the page equals the Dart data bit for bit, and the chart areas and the
  element counts are the same. 31 of 180 upstream windows are excluded (the core of the renderer
  main thread fell to 2.05-2.36 GHz). Each cell keeps 2-4 valid windows.
- The port figures of the ratios come from the before/after series of side B, not from the profile
  runs: the profiler adds load.

Port / upstream (median of the run medians, minimum-maximum, ms):

| Case | N | port update | upstream update | update ratio | port draw | upstream draw | draw ratio | (port draw + end) / upstream draw |
|---|---:|---|---|---:|---|---|---:|---:|
| chart.a | 1000 | - | - | - | 0.331 (0.326-0.338) | 0.298 (0.287-0.318) | 1.11 | 1.34 |
| chart.a | 5000 | - | - | - | 1.649 (1.626-1.651) | 1.482 (1.447-1.566) | 1.11 | 1.33 |
| chart.a | 20000 | - | - | - | 6.684 (6.631-6.725) | 54.843 (53.366-63.574) | 0.12* | 0.16* |
| chart.b sharing | 1000 | 0.593 (0.592-0.615) | 0.274 (0.265-0.289) | 2.17 | 0.367 (0.363-0.372) | 0.317 (0.310-0.334) | 1.16 | 1.42 |
| chart.b sharing | 5000 | 1.654 (1.639-1.655) | 0.457 (0.454-0.472) | 3.62 | 1.860 (1.826-1.900) | 1.521 (1.510-1.530) | 1.22 | 1.45 |
| chart.b sharing | 20000 | 5.769 (5.759-5.807) | 1.769 (1.574-1.811) | 3.26 | 8.319 (8.222-8.393) | 55.298 (52.857-65.195) | 0.15* | 0.19* |
| chart.b no-sharing | 1000 | 1.153 (1.150-1.186) | 0.638 (0.636-0.647) | 1.81 | 0.373 (0.370-0.394) | 0.321 (0.320-0.324) | 1.16 | 1.43 |
| chart.b no-sharing | 5000 | 4.519 (4.482-4.543) | 2.728 (2.702-2.882) | 1.66 | 1.832 (1.814-1.854) | 1.542 (1.541-1.543) | 1.19 | 1.43 |
| chart.b no-sharing | 20000 | 21.484 (21.303-21.664) | 19.622 (18.306-22.017) | 1.09 | 10.904 (10.810-11.170) | 15.378 (14.505-66.014) | 0.71* | 0.85* |
| chart.c | 1000 | 6.844 (6.839-6.889) | 4.693 (4.603-4.704) | 1.46 | 1.635 (1.613-1.639) | 0.372 (0.369-0.377) | 4.40 | 8.02 |
| chart.c | 5000 | 36.389 (35.778-38.912) | 26.079 (24.928-26.686) | 1.40 | 8.670 (8.508-8.721) | 1.844 (1.819-1.848) | 4.70 | 7.49 |
| chart.c | 20000 | 146.328 (138.869-150.939) | 98.835 (95.830-99.328) | 1.48 | 34.648 (32.987-34.883) | 9.707 (9.025-10.015) | 3.57 | 4.86 |
| chart.bar draw | 1000 | - | - | - | 2.561 (2.531-2.634) | 2.524 (2.373-2.610) | 1.01 | 3.11 |
| chart.bar draw | 5000 | - | - | - | 13.326 (13.313-14.228) | 14.087 (13.678-14.621) | 0.95 | 1.61 |
| chart.bar draw | 20000 | - | - | - | 56.044 (54.754-59.397) | 70.767 (65.935-76.575) | 0.79 | 2.44 |
| chart.bar update | 1000 | 4.966 (4.796-5.024) | 3.350 (3.255-3.474) | 1.48 | 2.985 (2.857-3.048) | 2.792 (2.673-2.867) | 1.07 | 3.18 |
| chart.bar update | 5000 | 34.784 (32.934-36.781) | 16.484 (16.477-16.491) | 2.11 | 17.680 (16.718-17.898) | 16.800 (16.680-16.921) | 1.05 | 1.67 |
| chart.bar update | 20000 | 141.112 (137.968-156.754) | 68.172 (67.580-68.765) | 2.07 | 68.247 (63.770-69.306) | 78.485 (78.095-78.875) | 0.87 | 2.03 |
| chart.bubble draw | 1000 | - | - | - | 1.492 (1.488-1.561) | 0.308 (0.308-0.308) | 4.84 | 8.80 |
| chart.bubble draw | 5000 | - | - | - | 7.431 (7.386-7.925) | 1.520 (1.505-1.535) | 4.89 | 7.63 |
| chart.bubble draw | 20000 | - | - | - | 30.742 (30.577-33.126) | 68.691 (68.640-68.741) | 0.45* | 0.63* |
| chart.bubble update | 1000 | 2.685 (2.661-2.709) | 1.886 (1.872-1.900) | 1.42 | 1.612 (1.600-1.624) | 0.337 (0.334-0.339) | 4.79 | 8.70 |
| chart.bubble update | 5000 | 12.340 (12.305-12.375) | 9.098 (9.049-9.148) | 1.36 | 8.127 (8.104-8.151) | 1.623 (1.615-1.630) | 5.01 | 8.36 |
| chart.bubble update | 20000 | 68.588 (68.501-68.675) | 39.971 (38.315-41.628) | 1.72 | 34.884 (34.481-35.287) | 8.942 (8.825-9.060) | 3.90 | 5.31 |
| chart.doughnut draw | 100 | - | - | - | 0.612 (0.612-0.612) | 0.279 (0.272-0.307) | 2.19 | 2.44 |
| chart.doughnut draw | 1000 | - | - | - | 6.081 (6.071-6.091) | 2.939 (2.875-3.186) | 2.07 | 2.29 |
| chart.doughnut draw | 5000 | - | - | - | 32.591 (32.559-32.624) | 15.429 (15.192-16.364) | 2.11 | 2.50 |
| chart.doughnut update | 100 | 0.238 (0.238-0.239) | 0.142 (0.137-0.157) | 1.68 | 0.623 (0.622-0.625) | 0.309 (0.305-0.327) | 2.01 | 2.29 |
| chart.doughnut update | 1000 | 1.557 (1.545-1.569) | 0.575 (0.547-0.579) | 2.71 | 6.219 (6.213-6.225) | 3.015 (2.963-3.202) | 2.06 | 2.29 |
| chart.doughnut update | 5000 | 10.576 (10.078-11.075) | 2.718 (2.434-2.976) | 3.89 | 35.631 (35.592-35.670) | 15.727 (15.546-16.376) | 2.27 | 2.65 |
| chart.pie draw | 100 | - | - | - | 0.517 (0.515-0.521) | 0.261 (0.258-0.263) | 1.98 | 2.16 |
| chart.pie draw | 1000 | - | - | - | 5.270 (5.109-5.494) | 2.560 (2.559-2.561) | 2.06 | 2.46 |
| chart.pie draw | 5000 | - | - | - | 28.632 (26.591-29.147) | 13.560 (13.410-13.816) | 2.11 | 3.41 |
| chart.pie update | 100 | 0.236 (0.235-0.237) | 0.150 (0.142-0.152) | 1.57 | 0.535 (0.530-0.541) | 0.275 (0.272-0.282) | 1.95 | 2.15 |
| chart.pie update | 1000 | 1.568 (1.515-1.593) | 0.546 (0.527-0.578) | 2.87 | 5.395 (5.229-5.542) | 2.690 (2.639-2.713) | 2.01 | 2.41 |
| chart.pie update | 5000 | 10.502 (9.502-10.935) | 2.733 (2.660-2.772) | 3.84 | 29.814 (28.613-29.846) | 14.433 (14.306-14.478) | 2.07 | 3.33 |
| chart.polarArea draw | 100 | - | - | - | 0.507 (0.496-0.514) | 0.237 (0.235-0.247) | 2.14 | 2.27 |
| chart.polarArea draw | 1000 | - | - | - | 5.008 (4.979-5.184) | 2.507 (2.490-2.575) | 2.00 | 2.28 |
| chart.polarArea draw | 5000 | - | - | - | 27.912 (27.666-28.867) | 13.407 (13.358-13.826) | 2.08 | 3.20 |
| chart.polarArea update | 100 | 0.358 (0.355-0.359) | 0.302 (0.299-0.315) | 1.19 | 0.546 (0.540-0.548) | 0.272 (0.270-0.277) | 2.01 | 2.17 |
| chart.polarArea update | 1000 | 1.853 (1.823-1.925) | 1.143 (1.128-1.160) | 1.62 | 5.381 (5.285-5.428) | 2.633 (2.627-2.660) | 2.04 | 2.34 |
| chart.polarArea update | 5000 | 13.012 (12.486-14.743) | 5.342 (5.128-5.358) | 2.44 | 31.043 (30.563-32.124) | 14.296 (13.952-14.463) | 2.17 | 3.35 |
| chart.radar draw | 100 | - | - | - | 0.052 (0.052-0.053) | 0.044 (0.044-0.045) | 1.18 | 1.55 |
| chart.radar draw | 1000 | - | - | - | 0.423 (0.421-0.427) | 0.374 (0.373-0.375) | 1.13 | 1.33 |
| chart.radar draw | 5000 | - | - | - | 2.082 (2.066-2.101) | 1.775 (1.750-1.808) | 1.17 | 1.37 |
| chart.radar update | 100 | 0.350 (0.348-0.356) | 0.266 (0.263-0.272) | 1.32 | 0.065 (0.062-0.070) | 0.056 (0.055-0.057) | 1.16 | 1.52 |
| chart.radar update | 1000 | 1.748 (1.702-1.869) | 0.745 (0.745-0.868) | 2.35 | 0.596 (0.579-0.601) | 0.400 (0.380-0.401) | 1.49 | 1.71 |
| chart.radar update | 5000 | 8.206 (7.451-9.220) | 3.622 (3.502-3.627) | 2.27 | 2.880 (2.661-3.244) | 1.836 (1.831-1.854) | 1.57 | 1.80 |

\* At 20000 circles, Chrome rasterizes the canvas inside `draw()`, so there the upstream draw is
not a recording only. These ratios do not show a faster port. The upstream draw is the
main-thread recording of the canvas calls: Chrome rasterizes later in the GPU process. The port
end (the picture end and the circle batch) has no upstream main-thread counterpart. Thus the last
column is an upper bound.

- Update: the port takes 1.1-3.9 times the upstream time. Draw: 0.95-1.22 times for line,
  scatter, bar and radar, 2.0-2.3 times for doughnut, pie and polar area, and 4.4-5.0 times for
  `chart.c` and bubble at 1000 and 5000.

The time above the upstream cost at the profile count (ms for each call; a group is the port
share times the port median, minus the upstream V8 share times the upstream median). V8 gives a
native canvas call a node of its own only in some profiles. Thus the draw groups put the ported
code and the canvas together. The garbage collection is outside the scopes on both sides.

| Case | Call | N | port | upstream | excess | ported code (+ canvas in a draw) | option resolution | JS runtime + typed options (port only) |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| chart.a | draw | 5000 | 1.649 | 1.482 | 0.167 | -0.07 | -0.00 | 0.24 |
| chart.b sharing | update | 5000 | 1.654 | 0.457 | 1.197 | 0.71 | 0.02 | 0.47 |
| chart.b sharing | draw | 5000 | 1.860 | 1.521 | 0.339 | 0.09 | -0.00 | 0.25 |
| chart.b no-sharing | update | 5000 | 4.519 | 2.728 | 1.791 | 0.68 | -0.02 | 1.15 |
| chart.b no-sharing | draw | 5000 | 1.832 | 1.542 | 0.290 | 0.03 | 0.00 | 0.27 |
| chart.c | update | 5000 | 36.389 | 26.079 | 10.310 | -1.94 | 2.38 | 9.93 |
| chart.c | draw | 5000 | 8.670 | 1.844 | 6.826 | 6.48 | 0.00 | 0.35 |
| chart.bar draw | draw | 5000 | 13.326 | 14.087 | -0.761 | -2.20 | 0.00 | 1.46 |
| chart.bar update | update | 5000 | 34.784 | 16.484 | 18.300 | 6.12 | 1.33 | 10.88 |
| chart.bar update | draw | 5000 | 17.680 | 16.800 | 0.880 | -0.82 | -0.01 | 1.75 |
| chart.bubble draw | draw | 5000 | 7.431 | 1.520 | 5.911 | 5.65 | 0.00 | 0.26 |
| chart.bubble update | update | 5000 | 12.340 | 9.098 | 3.242 | -2.25 | -0.26 | 5.76 |
| chart.bubble update | draw | 5000 | 8.127 | 1.623 | 6.505 | 6.25 | -0.00 | 0.26 |
| chart.doughnut draw | draw | 1000 | 6.081 | 2.939 | 3.141 | 3.00 | -0.00 | 0.14 |
| chart.doughnut update | update | 1000 | 1.557 | 0.575 | 0.982 | 0.44 | -0.01 | 0.55 |
| chart.doughnut update | draw | 1000 | 6.219 | 3.015 | 3.203 | 3.05 | 0.00 | 0.15 |
| chart.pie draw | draw | 1000 | 5.270 | 2.560 | 2.710 | 2.57 | 0.00 | 0.14 |
| chart.pie update | update | 1000 | 1.568 | 0.546 | 1.022 | 0.44 | 0.01 | 0.57 |
| chart.pie update | draw | 1000 | 5.395 | 2.690 | 2.705 | 2.56 | 0.00 | 0.15 |
| chart.polarArea draw | draw | 1000 | 5.008 | 2.507 | 2.501 | 2.36 | -0.00 | 0.15 |
| chart.polarArea update | update | 1000 | 1.853 | 1.143 | 0.710 | 0.23 | -0.03 | 0.51 |
| chart.polarArea update | draw | 1000 | 5.381 | 2.633 | 2.748 | 2.58 | -0.00 | 0.17 |
| chart.radar draw | draw | 1000 | 0.423 | 0.374 | 0.049 | 0.00 | -0.00 | 0.05 |
| chart.radar update | update | 1000 | 1.748 | 0.745 | 1.003 | 0.47 | 0.08 | 0.46 |
| chart.radar update | draw | 1000 | 0.596 | 0.400 | 0.196 | 0.13 | -0.00 | 0.07 |

The hot spots of the port (the rolled self time, in estimated ms for each call, summed over the
16 profiled case calls at 5000 points or 1000 arcs):

| # | Function | Group | Sum ms | Largest cases (ms) |
|---:|---|---|---:|---|
| 1 | `UiCanvasContext.fill` | canvas layer | 19.20 | bar update (draw) 6.57, bar draw 5.57 |
| 2 | `CircleBatch._drawDirect` | canvas layer | 17.31 | chart.c (draw) 6.07, bubble update (draw) 5.81, bubble draw 5.43 |
| 3 | `jsGet` | JS runtime | 9.58 | chart.c update 4.86, bar update 1.27 |
| 4 | `jsObjectKeys` | JS runtime | 7.26 | bar update 4.82, chart.c update 1.16 |
| 5 | `UiCanvasContext._strokeMapped` | canvas layer | 6.80 | pie, doughnut draws 1.16 each |
| 6 | `UiPathBuilder._nativeArc` | canvas layer | 6.80 | doughnut draw 1.61 |
| 7 | `DatasetController._resolveElementOptions` | ported | 5.64 | bubble update 2.27, scatter update 1.69 |
| 8 | `UiCanvasContext._dropPictures` | canvas layer | 4.98 | bar update (draw) 2.08 |
| 9 | `_cached` | option resolution | 4.90 | chart.c update 4.68 |
| 10 | `ContextResolver.[]` | option resolution | 4.65 | bar update 3.31, chart.c update 1.05 |
| 11 | `attachContext` | option resolution | 4.40 | chart.c update 4.36 |
| 12 | `_getResolver` | option resolution | 3.50 | chart.c update 3.29 |
| 13 | `jsGetKey` | JS runtime | 3.49 | bar update 1.19, bubble update 0.90 |
| 14 | `BarController.updateElements` | ported | 3.31 | bar update 3.31 |
| 15 | `Element.assign` | ported | 2.93 | bar update 1.56, bubble update 0.66 |
| 16 | `_setBorderSkipped` | ported | 2.27 | bar update 2.27 |
| 17 | `BarController.getFirstScaleIdForIndexAxis` (+ closure 0.60) | ported | 1.71 | bar update |
| 18 | `BarController._getAxis` | ported | 1.58 | bar update |
| 19 | `BarController._getStacks` | ported | 1.05 | bar update |

- The largest time above the upstream cost is the JS runtime and the typed options, which upstream
  does not have: 10.9 of 18.3 ms in the bar update, 9.9 of 10.3 ms in the `chart.c` update, and
  5.8 ms in the bubble update.
- In a draw, it is the canvas layer: the circles that the circle batch does not take (bubble has a
  radius for each item, and `chart.c` alternates two colors), and the path fill and stroke of arcs
  and bars.
- The option resolution adds only 2.4 ms to `chart.c`: V8 also spends 70 % of that update there.
- `jsSin` and `jsCos` have 0.8 % of the radar samples. The read of `ctx` for each bar has no frame
  of its own.

**The A/B series of the candidates.** Five candidates of the plan, each with its own protocol, on
the Pixel 8a, 12 pairs each (both stages), 24 or 48 fresh processes. The gate was met before each
run. A is `c0a6576`, B is `c0a6576` with the patch. The decision follows the rule above. The
macOS and web columns are the series of another unit (a record): the macOS AOT profile app and
the VS Code integrated browser with dart2wasm, 6 ABBA pairs each (the web series of
`resolve-cache-key-memo`: 2 valid pairs), with the same rule and an independent recompute that
agrees.

| Candidate | Change | Main cells, B - A | Control cells entirely above 0 | Decision | macOS series | Web series |
|---|---|---|---|---|---|---|
| `bar-index-memo` | `BarController.updateElements` computes the axis count, the axis number and the stack index of `_calculateBarIndexPixels` once for each call | `chart.bar` update -1.881 / -15.037 / -51.692 ms (-36.9 / -43.3 / -34.5 %) at 1000 / 5000 / 20000 | update call, draw: +1.459 ms (+8.1 %) at 5000, +6.675 ms (+10.3 %) at 20000; draw call, end: +0.052 ms at 1000, +0.652 ms at 5000 | reject | accept (update -34.5 / -37.1 / -32.9 %; draw in the update call +6.2 / +4.8 %) | accept (update -31.5 / -32.5 / -30.9 %) |
| `bar-ring-zero-inner` | `fill` of a shape pair with a shape of no area draws the other shape with `drawRect` or `drawRRect` | `chart.bar` draw -0.543 / -3.246 / -15.021 ms (-20.9 / -23.6 / -26.2 %) | none | **accept** | accept (draw -13.2 / -14.0 / -13.5 %) | accept (draw -28.4 / -28.1 / -30.7 %) |
| `element-assign-no-key-list` | `Element.assign` writes with `Map.forEach` when the source is a plain Map with no array-index key | bar update -0.064 (unresolved) / -1.943 ms (-5.7 %); doughnut -0.162 ms (-10.2 %) / -0.404 (unresolved); radar -0.045 / +0.231 (both unresolved) at 1000 / 5000 | doughnut draw and draw + end in all 8 cells (+1.1 to +2.3 %); radar update at 1000, end +0.045 ms (+56.5 %) | reject | reject (slower control cells) | reject (bar draw of the draw call at 1000 +0.5 %) |
| `resolve-cache-key-memo` | `_resolveElementOptions` keeps the last cache key `elementType-mode` | scatter update -0.311 / -1.522 / -7.890 ms (-26.6 / -33.8 / -36.4 %); bubble update -0.480 / -1.918 ms (-17.7 / -15.0 %) | 1 of 41: bubble update at 1000, draw +0.054 ms (+3.4 %) | reject | the line control was +1.0 to +2.4 % | inconclusive (2 valid pairs: the tab of the browser was hidden) |
| `circle-batch-instance-colors` | a run of several colors draws white sprites, and the atlas gives each instance its color (`BlendMode.modulate`) | `chart.c` draw -1.256 / -6.463 / -24.832 ms (-76.4 / -74.4 / -73.1 %); end -91.5 / -89.1 / -80.0 % | `chart.a` draw at 20000 +1.5 %, end at 5000 +2.1 %, end at 20000 +2.1 %, draw + end at 20000 +1.6 % | reject | reject (`chart.a` +1.9 to +5.3 %) | reject (`chart.c` end 0.061 / 0.290 / 1.120 ms against 0.003 / 0.007 / 0.015 ms) |

- The frame (update + draw + end) is faster in each rejected series: `bar-index-memo` -14.8 /
  -21.4 / -13.6 %; `resolve-cache-key-memo` -26.5 % (scatter at 20000);
  `circle-batch-instance-colors` -25.0 / -23.3 / -17.5 % (`chart.c`);
  `element-assign-no-key-list` -3.9 % (bar at 5000). The rule does not weigh the cells. Section
  13.7 item 10 has the open decision.
- `bar-index-memo`: a diagnostic series (6 pairs, written before its runs, not part of the rule)
  started the draw call after one `update('none')`. The draw of the bars of the memo path was then
  not slower at 5000 and 20000 (+0.073 ms, -0.185 .. +0.375; +0.371 ms, -0.844 .. +1.534). At
  1000 it was +0.035 ms (+0.003 .. +0.073). Thus work probably moves from the update into the draw
  that follows it in the same call, for example the garbage collection of the new bar values.
- `bar-index-memo`, the frame series (2026-10-22 13:49-14:10, a new protocol written before its
  first run, 6 ABBA pairs, an independent recompute agrees). The primary metric is the frame sum
  update + draw + end of the update call: -2.393 ms (-2.614 .. -2.144, -16.8 %) at 1000, -15.855
  ms (-17.612 .. -14.458, -24.9 %) at 5000 and -42.767 ms (-47.781 .. -36.611, -14.3 %) at 20000.
  The guard is the draw + end of the draw call: -1.1 % and +1.3 % (both intervals include 0) at
  1000 and 5000, and +8.925 ms (+1.478 .. +17.681, +6.0 %) at 20000. Thus the rule gives reject.
  The guard cost at 20000 is in `end`, not in `draw` (draw -1.195 ms, -2.476 .. -0.014). Two
  pairs give most of it (+18.7 and +26.6 ms), and in both the B run followed a gate wait of 386 s
  and 447 s. The draw call does not run the memo path. This is an observation: the rule stays.
- `resolve-cache-key-memo`: the patch does not change the draw. With 41 control cells at 95 %,
  about 2 cells lie above 0 by chance alone, and 1 does. The line update with sharing (a control)
  is unchanged or faster on the Pixel 8a (-0.2 / -0.8 / -1.5 %).
- `element-assign-no-key-list`: the patch does not change the draw path, but the doughnut draw
  slowdown repeats in each doughnut cell. A code layout effect of the AOT build is possible.
- `circle-batch-instance-colors`: the one-color path of `chart.a` also runs through the changed
  batch code.

The accepted change `bar-ring-zero-inner` on the Pixel 8a (12 pairs; difference B - A; the
pair counts show the excluded cells):

| Call | N | Metric | Role | Pairs | A | B | Mean B - A | 95 % interval | Relative | Result |
|---|---:|---|---|---:|---|---|---:|---|---:|---|
| draw | 1000 | **draw** | main | 12 | 2.618 (2.502-2.654) | 2.070 (1.963-2.154) | -0.543 | -0.577 .. -0.511 | -20.9 % | faster |
| draw | 1000 | end | control | 12 | 5.450 (5.246-5.545) | 5.434 (5.254-5.704) | +0.020 | -0.065 .. +0.104 | +0.4 % | unresolved |
| draw | 1000 | draw + end | control | 12 | 8.075 (7.748-8.177) | 7.512 (7.245-7.858) | -0.524 | -0.638 .. -0.410 | -6.5 % | faster |
| draw | 5000 | **draw** | main | 10 | 13.852 (13.315-14.158) | 10.544 (10.038-11.292) | -3.246 | -3.475 .. -3.036 | -23.6 % | faster |
| draw | 5000 | end | control | 10 | 9.474 (9.110-11.482) | 9.359 (9.085-9.941) | -0.312 | -0.855 .. +0.086 | -3.2 % | unresolved |
| draw | 5000 | draw + end | control | 10 | 23.431 (22.545-25.292) | 19.894 (19.140-21.233) | -3.558 | -4.265 .. -2.984 | -15.2 % | faster |
| draw | 20000 | **draw** | main | 11 | 58.054 (54.980-58.618) | 42.248 (40.346-44.944) | -15.021 | -15.966 .. -14.156 | -26.2 % | faster |
| draw | 20000 | end | control | 11 | 87.546 (73.134-116.419) | 80.244 (72.690-85.802) | -12.779 | -21.333 .. -4.584 | -13.8 % | faster |
| draw | 20000 | draw + end | control | 11 | 145.800 (131.752-172.115) | 122.900 (114.208-126.395) | -27.800 | -35.618 .. -20.422 | -18.5 % | faster |
| update | 1000 | update | control | 12 | 5.069 (4.823-5.359) | 5.127 (4.832-5.757) | +0.155 | -0.047 .. +0.366 | +3.1 % | unresolved |
| update | 1000 | draw | control | 12 | 2.917 (2.832-3.189) | 2.319 (2.177-2.565) | -0.580 | -0.686 .. -0.479 | -19.6 % | faster |
| update | 1000 | update + draw + end | control | 12 | 14.133 (13.558-14.452) | 13.494 (12.926-14.430) | -0.362 | -0.715 .. -0.010 | -2.6 % | faster |
| update | 5000 | update | control | 11 | 35.015 (32.559-35.797) | 34.058 (30.981-36.429) | -0.794 | -1.946 .. +0.406 | -2.3 % | unresolved |
| update | 5000 | draw | control | 11 | 17.862 (16.693-19.481) | 13.716 (12.667-14.568) | -4.242 | -4.913 .. -3.640 | -23.6 % | faster |
| update | 5000 | update + draw + end | control | 11 | 62.970 (60.954-65.254) | 58.305 (54.324-60.991) | -4.918 | -6.535 .. -3.309 | -7.8 % | faster |
| update | 20000 | update | control | 11 | 148.989 (137.892-157.301) | 141.753 (125.181-149.033) | -8.814 | -15.307 .. -2.851 | -5.9 % | faster |
| update | 20000 | draw | control | 11 | 65.183 (62.442-69.925) | 52.812 (47.742-58.740) | -12.743 | -15.019 .. -10.315 | -19.4 % | faster |
| update | 20000 | update + draw + end | control | 11 | 297.646 (282.743-314.297) | 273.460 (249.725-290.868) | -24.932 | -32.999 .. -17.042 | -8.4 % | faster |

The stress frame record of the same change (mode `chart`, type `bar`, `CALL=draw`, one fresh run
for each side and N; a record, no interval):

| N | Side | FPS | drawMs | datasetsDrawMs | buildMs | rasterMs |
|---:|---|---:|---:|---:|---:|---:|
| 5000 | A | 21.90 | 16.19 | 15.70 | 30.76 | 37.13 |
| 5000 | B | 27.99 | 12.13 | 11.42 | 26.65 | 20.62 |
| 20000 | A | 4.82 | 73.24 | 72.70 | 170.52 | 131.15 |
| 20000 | B | 7.34 | 47.92 | 47.30 | 128.16 | 57.72 |

- `bar-ring-zero-inner`: `fill` of a shape pair with a shape of no area draws the other shape with
  `drawRect` or `drawRRect`. A bar of the bench is narrower than its two borders of 1 px.
  `parseBorderWidth` clamps the borders, and the inner rectangle of the border ring has a width
  of 0. Before the change, such a ring took the path of the two subpaths. A subpath with no area
  adds no coverage, so the pixels equal those of `fillRect` (a test pins it). On the Pixel 8a, the
  bar draw is -20.9 / -23.6 / -26.2 % at 1000 / 5000 / 20000, and the raster time of the stress
  record falls from 37.13 to 20.62 ms and from 131.15 to 57.72 ms. On macOS AOT, the 5 pairs of
  the variant step give a `chart.bar` draw of about -15 % at N 1000, 5000 and 20000 (-0.17, -0.86
  and -3.42 ms), and the ABBA series of the A/B table gives -13.2 / -14.0 / -13.5 %. The end of the
  recording and the update do not change significantly. The change is in the port-only canvas
  layer (Chart.js ADR 0013). The canvas calls of `element.bar` do not change, so the change has no
  `DIVERGES` marker. The row `adapt-rounded-rect-path` of [differences.md](differences.md) names
  the new fill.
- Builds of the candidate series: 11-15 s each, at a Mac load of 2.07-4.8.

### 13.7 Open: the controllers

Step 7 (section 13.6) measured or decided each item. Each item has a status: **measured** (a
figure of step 7 exists), **decided** (the rule of a protocol or the profile gave the result) or
**open** (a later unit measures it, or the porting lead decides it). The shares are of the step 7
profile on the Pixel 8a at 5000 points or 1000 arcs.

1. **The step 7 list of Chart.js ADR 0036 §8** (Chart.js ADR 0036 Open 1). Each form stays ported
   literally.
   - The bar memo of `_getAxis`, `getFirstScaleIdForIndexAxis` and `_getStacks` for each bar
     (`controller.bar.js:434-508`, `:636-650`): **measured** (`bar-index-memo`). The bar update is
     -36.9 / -43.3 / -34.5 % at 1000 / 5000 / 20000. The draw in the same update call is +8.1 %
     and +10.3 % at 5000 and 20000, so the rule rejects it. The frame is -14.8 / -21.4 / -13.6 %.
     **Open**: the porting lead decides on a new protocol (item 10). The form needs a `DIVERGES`
     marker and the row `adapt-bar-index-memo`.
   - The `skipNull` find (`controller.bar.js:443-450`): **decided**, not measured. No bench case
     sets `skipNull`, and its closure has 0 samples in the bar update. The `_getStacks` work
     without `skipNull` (6.3 % of the bar update) is in the bar memo.
   - `(parsed._stacks || {})` (`controller.bar.js:405`): **decided**, not measured. `stacksOf`
     has 0.4 % of the bar update, and the empty literal has no frame of its own. This is below the
     share of 3 % of the plan.
   - The option copy for each bubble item (`controller.bubble.js:151-168`): **open**. After the
     cache key part, the copy is about 15 % of the bubble update (about 1.8 ms): `copyOptions`
     1.8 %, `PointOptions.clone` 1.7 %, the writes of `ElementOptions` and `PointOptions._store`
     about 6.6 %, and `ElementOptions.[]` 3.3 %. Upstream also copies each item (`Object.assign`).
     Measure it on top of `resolve-cache-key-memo`: both share the frame of
     `BubbleController.resolveDataElementOptions` (55.1 % total).
   - The double option resolution of polar area: **decided**. The second resolution is upstream
     (`_computeAngle`, 12.0 % of the polar area update at 1000; `resolveDataElementOptions`
     9.2 %). Its cache key part is in `resolve-cache-key-memo`. The rest is below 3 %.
   - The resolution for each radar point: **decided**. `resolveDataElementOptions` is 11.4 % of the
     radar update at 1000 (0.2 ms). Its cache key part (7.4 %) is in `resolve-cache-key-memo`. The
     rest is below 3 %.
   - The typed setters in place of the writes by name of the line and scatter loops: item 7.
2. **`prefer-inline` on `jsGetKey`** (Chart.js ADR 0036 Open 2): **open**. The self time of
   `jsGetKey` is 5.9 % of the `chart.b` update with sharing (0.098 ms) and 2.5 % without sharing.
   Its total (16.2 %) is mostly the Map read, which inlining does not remove. An earlier A/B in the
   line loop gave no gain. The trigger stays Chart.js ADR 0025 Open 3.
3. **Form T and the frame figures** (ADR 0028 Open 1): **decided** for the Pixel 8a, with no A/B.
   `_pointElements.<closure>` has 1.2 % of the `chart.b` update with sharing (0.019 ms self) and
   0.3 % of the radar update. `LineElement.[]=` has 1.5 % total. The expected gain is below 0.1
   ms for each frame, the threshold of the ADR. Thus no new ADR. **Open**: Chrome with dart2wasm
   has no profile of form T. The record of the early return of `getDataVisibility` (the stress
   mode `axes` with `BarController` and 20000 bars, `CALL=update`) was not made.
4. **The read of `ctx` for each bar** (ADR 0030 Open 3): **measured**. The bar draw profiles on the
   Pixel 8a show no frame for the read (`BarController.draw` self about 0.6 %). The trigger is not
   met. The item stays a trigger.
5. **The write path of `stacksOf`** (section 13.1): **open**, only if the maintainer wants it
   measured. `stacksOf` has 0.4 % of the bar update. The write path (`minBarLength`,
   `controller.bar.js:615`) does not run in the bench.
6. **The 2-read form of the line loop** (Chart.js ADR 0036 §8, section 13.1): **open**. The read
   `prevParsed[iAxis]` is one of the three `jsGetKey` reads of a pass: about 5 % of the `chart.b`
   update with sharing (about 0.09 ms). It needs the microbenchmark of Chart.js ADR 0036 §8
   condition 3 first. Chart.js ADR 0036 §8 keeps the 3-read form in the line and scatter loops.
7. **Wave 2 forms of the step 7 list** (item 1):
   - The writes by name into the point of a direct update (`_setProperty` of
     `controller.line.dart`, and the scatter loop): **measured** by the profile, **open**. It is
     32.2 % of the `chart.b` update with sharing (0.53 ms of 1.654 ms: `_OneByteString.==` 7.1 %,
     `Element.[]=` 6.7 %, `Element.toBoolProp` 6.2 %) and 12.1 % of the `chart.b` update without
     sharing (0.55 ms of 4.519 ms). The expected gain is about 0.3 ms for each case at 5000 and
     1-2 ms at 20000. It is the next candidate, for the S2 cost of item 9 (+0.795 ms at 5000 with
     sharing).
   - The option copy for each bubble item: item 1.
   - The cast of the scale `r` for each radar point (`controller.radar.dart`, IV §4.6):
     **decided**. The cast has no frame. `RadialLinearScale.getPointPositionForValue` has 7.5 % of
     the radar update, which is the arithmetic.
   - The `jsCall` of `parseObjectDataRadialScale` in the radar and polar area `parseObjectData`:
     **decided** for the bench. `parseObjectData` has 0 samples in the radar and polar area
     updates, because the bench data is numbers.
8. **Wave 3 forms**: **decided**. The null check of `xCenter` and `yCenter` (Chart.js ADR 0033) has
   no frame in the profiles (0.5-0.9 ns for each call, section 13.9). `jsToString` in
   `toggleDataVisibility` does not run in the bench (not a hot path). `jsSin` and `jsCos` (Chart.js
   ADR 0032) have 0.9 % and 1.5 % of the radar update, below 3 % (section 13.8).
9. **The cost of the ported controllers** (G-U6 S2, section 13.6): **open**. The protocol makes
   these primary cells candidates (a cost of 0.1 ms or more for each frame): the six `chart.b`
   update cells (+0.197 to +15.093 ms) and the `chart.c` update at 1000 (+0.298 ms) and 5000
   (+1.686 ms). The porting lead decides. The known parts: the scatter `getMaxOverflow` loop
   (upstream work, 4.79 ms at 20000, about one third of +15.1 ms), `_setProperty` (item 7), and
   the option resolution for each item without sharing (`_resolveElementOptions` 5.64 ms and
   `Element.assign` 2.93 ms summed over the profiled cases). `resolve-cache-key-memo` removes
   26.6-36.4 % of the scatter update, but the rule rejected it (item 10). The `axes.*` update B / A
   of 1.18-1.66 (linear, logarithmic, time) is the same controller path. The step 7 profile has no
   `axes.*` case.
10. **The candidates that the rule rejected** (section 13.6): **open**. `bar-index-memo`,
    `element-assign-no-key-list`, `resolve-cache-key-memo` and `circle-batch-instance-colors` have
    real main gains, and each series has a control cell entirely above 0. The rule does not weigh
    the cells, and with 18-42 control cells about 1-2 cells lie above 0 by chance alone. The
    porting lead decides on a new protocol (for example a rule on the frame sum, or a correction
    for the count of control cells) and a new series for each candidate. The patches stay out of
    the tree until then. `bar-index-memo` had such a second series with the frame sum as the
    primary metric (section 13.6). It also gives reject, on its guard at 20000. A third series
    needs a guard that runs the memo path, or more guard pairs. The circle batch can keep its
    present path for a run of one color and use the instance colors only for several colors. A change of a form of Chart.js ADR 0036 §8 (the bar memo) needs a
    `DIVERGES` marker and an `adapt` row.
11. **Hot spots with no candidate** (the step 7 profile): **decided**.
    - The arc draws (`UiCanvasContext._strokeMapped` 6.80 ms and `UiPathBuilder._nativeArc`
      6.80 ms summed; in the doughnut draw at 1000, the `drawPath` FFI 36.8 % and
      `_NativePath._arcTo` 24.2 %): the arc path on `dart:ui` is the work of cut 1 of the deferred
      plan [canvas-cuts-plan.md](canvas-cuts-plan.md). Do not do it in this phase.
    - The bubble draw (`CircleBatch._drawDirect` 5.43 ms): the radius changes for each item, so no
      sprite form takes it. `circle-batch-instance-colors` does not help it.
    - The option resolution of `chart.c` (`_cached` 4.68 ms, `attachContext` 4.36 ms,
      `_getResolver` 3.29 ms): upstream V8 spends 70 % of its `chart.c` update there too. The
      excess of the resolution group is 2.38 ms, and no single form was found.
    - `_setBorderSkipped` (8.2 % of the bar update, `_Map.[]=` 5.9 %) and the properties literal
      of each bar (`Map._fromLiteral` 7.1 %): upstream makes the same objects
      (`controller.bar.js:407-421`). A typed form changes the type of the element properties.
    - `_getRuler` and `_computeMinSampleSize` (7.5 % of the bar update): upstream work, once for
      each update.
12. **The scale path** (Chart.js ADR 0025 Open 1 and Open 2, section 11.8 items 1 and 3):
    **open**. The step 7 profile has no `axes.*` case, so it confirms no hot spot. The tick font
    for each tick (section 11.8 item 1) needs a profile of `axes.category` on `c0a6576`. Its form
    (b) needs a `DIVERGES` row. The `axes.category` update B / A is 1.05-1.06, so phase 7 did not
    change it. `jsLog10` for each point (section 11.8 item 3) is on the logarithmic axis only.
13. **The stress line draw at 20000 points**: **open**. On the Pixel 8a, B gives 50.91 FPS against
    56.86 FPS of before (one process each), with a lower build time (12.36 against 12.75 ms). The
    frameless `chart.a` draw of B equals A (0.99). The cause is not known.

### 13.8 Sine and cosine (Chart.js ADR 0032)

`jsSin` and `jsCos` (`lib/src/js/fdlibm_trig.dart`, form a2) replace `dart:math` at the 20
protected calls. The 52 display-only calls keep `dart:math`.

Micro figures of the decision (Chart.js ADR 0032, Alternatives considered): ns for each call,
direct calls, 4,096 inputs, best of 15 rounds, two runs, Apple M3 Max, Dart 3.12.2. The arc range
is `[-π/2, 3π/2)`. dart2wasm and dart2js run in Node.js v24.12.0 arm64.

| Target | Range | `dart:math` sin / cos | a1 sin | a2 sin / cos | C sin / cos | v2 sin / cos |
|---|---|---|---|---|---|---|
| AOT | arc | 3.6 / 3.3 | 10.6-11.0 | 9.8 / 9.9-10.0 | 8.7-8.9 / 9.3-9.4 | 16.0-16.1 / 15.9-16.2 |
| AOT | \|x\| < π/4 | 3.3 / 3.3 | 6.7 | 6.9-7.8 / 5.9-6.5 | 5.0 / 5.7-6.1 | 6.5-6.6 / 11.1-11.2 |
| dart2wasm | arc | 20.9-21.3 / 22.3-22.8 | 19.8-20.5 | 14.7-14.9 / 15.4-15.8 | 8.1-8.3 / 9.5-9.6 | 30.0-30.6 / 28.7-29.4 |
| dart2wasm | \|x\| < π/4 | 11.1 / 15.0 | 4.2 | 4.2 / 5.8-5.9 | 4.1 / 12.8-13.0 | 10.5 / 16.5-16.8 |
| dart2js | arc | 5.9 / 6.1 | 22.5 | 19.8 / 19.0 | 13.4 / 14.4 | 23.4 / 23.4 |
| dart2js | \|x\| < π/4 | 2.7 / 3.2 | 7.3 | 7.3 / 9.0 | 9.5 / 14.2 | 7.1 / 16.1 |

- Chrome 155 with dart2wasm: `dart:math` `sin` 6.6 ns, a2 10.5 ns for chart angles (+3.9 ns).
  On dart2wasm in Node.js, `dart:math` calls the JS `Math.sin` through a slow import, so the port
  is faster there.
- The committed file against the a2 candidate (the same bench, two runs; scratchpad
  `trig/impl/bench_*.out`): AOT arc sin 9.46-9.52 ns (a2 9.84-10.03 ns, `dart:math` 3.34-3.36
  ns), cos 9.50-9.63 ns; dart2wasm arc sin 15.13 ns (a2 14.77 ns), cos 15.45 ns; dart2js arc
  sin 20.26 ns (a2 19.78 ns). The differences are within the spread. The committed file gives 0
  mismatches against x64 V8 on 5,691,981 inputs on AOT, dart2wasm and dart2js.
- The Pixel 8a (draft P, AOT, bionic): `dart:math` 9.92-10.08 ns in the arc range, form C
  23.29-24.02 ns (+13.7 ns). a2 was not measured on the phone.
- The calls for each phase (draft P, upstream `Math.sin` and `Math.cos`, protected and display
  calls): one hit query over 1000 arcs, 2,000 calls (`getCenterPoint`); a radar update of 12
  labels and 50 datasets, 1,538 calls (`getPointPosition` 1,512, `updateLimits` 24, `_tickSize`
  2); a radar draw, 264 calls (`getPointPosition`); a line or bar update, 14 protected calls
  (`fit`, `_tickSize`, `computeTickLimit`). The draw paths with many calls (`drawPointLegend`
  60,000 for each frame of a 10,000-point `triangle` line, the arc draw and path code 11,000 for
  1000 arcs) keep `dart:math`.
- Cost: one hit query over 1000 arcs, about 12 µs on AOT M3 and 27 µs on the Pixel 8a (form C);
  one radial scale draw, at most 4.4 µs, 0.03 % of a 16.7 ms frame.
- The frame figures of step 7 (section 13.6) answer Chart.js ADR 0032 Open 2. The ADR text does
  not change.
  - The stress entry on the Pixel 8a, side B: the radar draw gives 58.17 / 57.51 / 57.19 FPS at
    1000 / 5000 / 20000 points, and the radar update 57.84 / 46.16 / 14.04 FPS. The polar area
    draw gives 53.02 / 15.72 / 2.53 FPS, and the polar area update 44.71 / 12.02 / 2.22 FPS (the
    raster time at 1000 is 14.12 and 15.35 ms). The iPhone 17 Pro gives 116.61-120.02 FPS for the
    radar at each count, except the update at 20000 (36.32 FPS).
  - The frameless benchmark on the Pixel 8a, side B: the radar update is 0.350 / 1.748 / 8.206 ms
    at 100 / 1000 / 5000 points and the radar draw 0.052 / 0.423 / 2.082 ms. Chrome 155 with
    dart2wasm on macOS (a record of another unit): the radar update is 0.181 / 0.771 / 3.431 ms,
    the radar draw 0.025 / 0.231 / 1.163 ms, the polar area update 0.191 / 0.963 / 4.531 ms and
    the polar area draw 0.220 / 2.134 / 10.684 ms.
  - The CPU profile of the radar case on the Pixel 8a: `jsSin` and `jsCos` have 0.8 % of the
    samples of the process (0.9 % and 1.5 % of the radar update). The protected calls do not limit
    a frame.
  - The arc hit case was not measured: the bench and the stress charts listen to no event
    (`events: []`). The calculation above stays its figure (one hit query over 1000 arcs, about 27
    µs on the Pixel 8a).

### 13.9 The radial centers (Chart.js ADR 0033)

`xCenter` and `yCenter` stay `double?` (Chart.js ADR 0033). The reads are
`xCenter ?? double.nan` in arithmetic and canvas calls.

Microbenchmark of the forms (ADR 0033 Alternatives; Apple M3 Max, Dart 3.12.2; ns for each call or
item; the range of 3 process medians of 15 samples; wasm on Node.js v24.12.0 arm64, V8 as in
Chrome):

| Kernel | A `double?` | N `double` | S `Object?` | F flag | R by name |
|---|---|---|---|---|---|
| `getPointPositionForValue`, AOT | 10.61-11.03 | 10.06-10.18 | 11.08-11.41 | 10.05-10.36 | 10.06-10.17 |
| `getPointPositionForValue`, wasm | 18.43-19.01 | 18.11-18.31 | 18.35-18.97 | 17.96-18.37 | 18.04-18.32 |
| radar properties, default, AOT | 97.08-98.62 | 96.55-96.88 | 96.66-99.09 | 95.77-99.01 | 94.65-97.91 |
| radar properties, default, wasm | 64.71-66.30 | 67.92-69.01 | 93.35-97.48 | 70.11-71.29 | 68.97-70.59 |
| radar properties, reset, AOT | 94.23-97.57 | 92.89-95.44 | 95.34-98.00 | 99.09-102.77 | 92.31-96.39 |
| radar properties, reset, wasm | 63.60-64.75 | 67.18-69.04 | 92.90-96.93 | 68.89-71.45 | 73.53-76.64 |
| polar area properties, AOT | 161.41-163.21 | 161.47-162.95 | 161.72-162.48 | 159.06-161.98 | 158.27-161.51 |
| polar area properties, wasm | 61.29-61.89 | 64.11-64.55 | 61.44-63.16 | 61.60-62.58 | 62.05-62.42 |

- The replica of `getPointPositionForValue` with `getIndexAngle` behind the interface: AOT A
  54.2-54.7 ns, N 53.7-53.9 ns; wasm A 75.9-77.7 ns, N 68.5-69.5 ns. A re-run under machine load
  gave A +1.2 to +7.6 ns against N on wasm.
- The update denominator: a real `chart.update()` with 1000 items (JIT, `animation: false`,
  median of 25) costs 33.58 µs for each radar item and 4.33 µs for each polar area item.
- A small inlined AOT kernel (`bench_pos.dart`) showed 12 ns when `?? double.nan` is inside the
  record literal (19.2-21.5 ns against 7.7-9.1 ns). The replica and the real code under JIT (60 ns
  for both forms) do not show it.
- Scripts (ADR 0033 Evidence E5, in the session scratchpad):
  `trig/radial-center-performance/bench/bench.dart` (`aot.out`, `wasm.out`),
  `update_cost_test.dart` (`update_cost.out`),
  `trig/radial-center-simplicity/bench/bin/bench_replica.dart` and `bench_pos.dart`
  (`aot_replica.out`, `wasm_replica.out`, `aot_pos.out`), `jit_bench.out`, and the judge re-runs
  in `trig/radial-center-judge/`.
- No frame figure. The form keeps the structure, so the microbenchmark is sufficient (Chart.js ADR
  0020 §13).

## 14. Plugins (phase 8)

The figures of the decisions of phase 8.

### 14.1 The filler points and targets (Chart.js ADR 0040)

Bed: Apple M3 Max, Dart 3.13.5. AOT is `dart compile exe`. wasm is `dart compile wasm -O2`, run
in the x64 Node.js v24.12.0 under Rosetta. Other sessions loaded the Mac (load average 6.4 to
11.8). The decisions use differences of 5 times or more, or a confirmed series of three runs.
The scripts and outputs are working files of the filler design of phase 8 (the fidelity bench,
the performance bench and the judge re-runs), not committed.

A second implementer of the point interfaces. C1 is the hot path of every line chart, 1000
points, µs for each operation. A is the form of the ADR: `PointElement` is the only class that
implements `types.PointElement`. L puts a port-only `FillerPoint` class into the filler lines. P
allocates one `FillerPoint` in `main` that never enters a line.

| C1 case | A, AOT | P, AOT | L, AOT | A, wasm | P, wasm | L, wasm |
|---|---:|---:|---:|---:|---:|---:|
| `segments` and `path`, fast path | 18.4-19.3 | 22.5-23.3 | 21.6-22.5 | 30.4-38.0 | 48.0-61.8 | 44.4-49.0 |
| `updateControlPoints` and `path`, bezier | 53.6-54.2 | 88.3-88.7 | 87.6-91.6 | 110.0-135.8 | 235.7-270.2 | 238.9-285.9 |
| `boundSegments` | 16.7-17.5 | 18.0-18.2 | 18.1-19.0 | 37.6-44.0 | 70.3-90.6 | 45.0-49.2 |

- P gives the full slowdown of L: the cause is static. The whole-program type analysis of AOT
  and dart2wasm stops the devirtualization of the reads of `skip`, `x`, `y` and the control
  points. One allocated copy of a gallery class that implements `SplinePoint` gives the same
  effect on the bezier case: 81.3-82.1 µs on AOT and 216.4-226.2 µs on dart2wasm against
  53.9-54.3 µs and 107.5-112.9 µs. The guard `test/port/plugins/plugin.filler/point_implementers_test.dart`
  keeps one implementer in `lib/` (ADR section 11).
- The wrap of one point, ns: `PointElement()` with the setters 2.2-2.3 (AOT) and 4.1-6.7
  (dart2wasm). `PointElement({'x': .., 'y': ..})` with a cfg Map 143.7-148.8 and 174.3-199.0. A
  record or a plain class 2.2 and 0.3. V8 upstream: `new PointElement()` with 2 writes 21.1,
  `{x, y}` 5.3. The port uses the cascade.
- The filler lines, ns for each line: the cfg Map `LineElement({'points': .., 'options': ..,
  '_loop': .., '_fullLoop': ..})` 280.8-289.9 (AOT) and 394.5-396.3 (dart2wasm). The cascade
  42.5-44.6 and 38.8-44.2. The port keeps the upstream cfg Map: the gain is 0.24-0.36 µs for each
  target in each frame, below the 0.1 ms rule of Chart.js ADR 0020 §13.
- `interpolate` on a line of 1000 points: 14.4-15.5 µs (AOT), 27.7-29.4 µs (dart2wasm), 13.6 µs
  (V8). The stack target of one dataset over 2 lines of 1000 points: 15.8 ms (AOT), 29.7-34.3 ms
  (dart2wasm). The `stack` fill is quadratic, as upstream: the median of `chart.draw()` with 3
  datasets in V8 is 2402 µs for a 100-point stack fill and 128163 µs for a 1000-point stack fill.
- The read of `meta.$filler`, ns for each read: the access by name 10.6-15.0 (AOT) and
  18.4-28.4 (dart2wasm). A typed field 0.6-4.3 and 0.3-4.3. An `Expando` 10.8-11.2 and
  24.2-25.0. The filler reads the slot about twice for each visible dataset and draw. The port
  keeps the access by name: the gain of a field reaches 0.1 ms only at about 1700 datasets.
- No frame figure yet. Step 8 adds the fill cases to the frameless benchmark (ADR Open 2: a line
  with gaps and `above` and `below`, a `stack` fill of 1000 points, and a radar fill).

### 14.2 The test time of the reference tests (Chart.js ADR 0041 §2)

The reference tests of `test/port/scales/` and `test/port/controllers/` (17 files), command
`flutter test test/port/scales test/port/controllers --exclude-tags fixtures --reporter json`,
summed for each test from the JSON events, on the 16-core Mac (Flutter 3.47.7):
- Before wave 4: 1137 tests, 19.46 s and 19.44 s (2 runs, load 4.6 to 6.4).
- After the regeneration of wave 4 (the seven plugins in each generator and in
  `flutter_test_config.dart`, 10 new `legend:` cases): 1147 tests, 20.97 s and 21.35 s (2 runs,
  load 7.3 to 8.8).
- The mean grows by 8.8 % (19.45 s to 21.16 s), below the limit of +25 % (24.3 s) of Chart.js
  ADR 0041 Open 1.
- The data of the 13 dist generators without new cases grows by 1.86 % (15,935,534 to 16,232,377
  bytes; Chart.js ADR 0041 §1 item 5 estimates about 2.2 %). All 16 grow by 3.86 % with the 10
  new `legend:` cases.
- `test/port/scales/scale_time_reference.dart` is 2,406,449 bytes (limit 2,500,000). The largest
  plugin data file is `plugin_tooltip_reference.dart` with 2,214,007 bytes, after the split of
  the tooltip data into two files.

### 14.3 The legend opt-out of the stress and benchmark charts (Chart.js ADR 0031 Open)

The stress and benchmark charts turn off the legend with `plugins.legend: false`, not with
`legend.display: false`. With `display: false` the legend still builds one item for each arc in
each update (plugin.legend.js:88, :623-626). Frameless benchmark, macOS release, ABBA, update
median:
- `chart.doughnut` at 5000 arcs: 16.342 and 16.895 ms with `display: false`, 5.040 and 4.892 ms
  with `legend: false`.
- `chart.polarArea` at 5000 arcs: 14.205 and 14.616 ms with `display: false`, 5.398 and 5.441 ms
  with `legend: false`.

From phase 8 the radar of `chart.radar` fills (`fill: 'start'`, controller.radar.js:16-20). Thus
its draw figures do not compare with the figures of phase 7 (JIT probe, 1000 points: 0.66-0.71 ms
with the filler, 0.30-0.32 ms with no plugin).

### 14.4 The fixture registry (Chart.js ADR 0041 §9)

The design of Chart.js ADR 0041 measured the import of `test/fixtures/index.dart` in `-j 1` runs
of 29 test files, each without the compile cache, ABBA, 3 pairs: 0.38 s for 119 hand ports, and
1.07 s for 147 hand ports (95 % interval 0.54 to 1.50 s). The trigger is 4 s. Wave 4 of phase 8
has the real 147 hand ports. The same method on the real registry (2026-10-23, Apple M3 Max,
Flutter 3.47.7): W 21.70, 21.08 and 21.16 s, N 20.79, 20.85 and 20.94 s. The pair differences are
0.91, 0.23 and 0.22 s, mean 0.45 s (95 % bootstrap interval 0.22 to 0.91 s, 20000 resamples, seed
8), 0.016 s for each file. The load average (1 minute) was 9.8 at the start and 4.4 at the end:
the Mac was not quiet, so the figure is flagged. It is far below the trigger of 4 s. Thus one
registry stays, and ADR 0029 Open item 2 does not fire. Step 4 of phase 8 measured again with the
same method, 6 pairs and a gate before each pair (the 1-minute load at or below 4.0, a wait of
at most 10 minutes; 2026-10-23, the same Mac and toolchain): W 23.74, 21.40, 21.40, 21.31, 21.37
and 21.28 s, N 21.16, 21.23, 21.00, 21.56, 21.09 and 21.31 s. The pair differences are 2.58,
0.17, 0.40, -0.25, 0.28 and -0.03 s, mean 0.53 s (95 % bootstrap interval -0.02 to 1.38 s, 20000
resamples, seed 8). Pair 1 did not pass its gate (load 5.13 after 10 minutes) and is the first
run after `flutter pub get`. The 5 pairs that passed their gate give a mean of 0.11 s (interval
-0.10 to 0.31 s), 0.004 s for each file. Both figures are far below the trigger of 4 s.
The decision compares the upper bound of the interval with the trigger, not the sign of the mean,
so the series does not add 6 pairs when the interval includes 0.

### 14.5 The theme palette and the plugin tokens (Chart.js ADR 0042)

The design panel of Chart.js ADR 0042 measured the hunks H4a-H5 and the plugin tokens of the
theme ([theming.md](theming.md) §3.5). Bed: Apple M3 Max, Dart 3.13.5. AOT is
`dart compile exe`. wasm is `dart compile wasm -O2` (probe P4: `-O1`, the default level, where
its table says so), run in Node.js v24.12.0: the x64 build under Rosetta, or the arm64 build
where a table says so. Other sessions loaded the Mac (load average 6.3 to 10.2). Thus the absolute figures are high, but the order of the forms is the same in each
run. The scripts and outputs are working files of the theme design of phase 8, not committed.

How often the colorizer runs. The JavaScript prototype of H4a-H5 of the performance draft
(`h4_h5_prototype.mjs`, its probe P1) runs on the pinned sources. It counts the runs of create and
100 updates with the default options, and the runs of 100 updates, 100 hover events and 100
`render()` calls with `forceOverride`. A Dart probe on the port (2026-10-23, Flutter 3.47.7)
counts the writes of `borderColor` into one bar dataset with the colors plugin on, without a
theme and with the light preset. The Dart probe gives all cells of the table. Where both probes
have a count, the counts are equal:

| Step | Default options | `forceOverride: true` |
|---|---:|---:|
| Create the chart | 1 | 1 |
| 100 `update()` calls | 0 | 100 |
| 100 `render()` calls | 0 | 0 |
| 100 `mousemove` events | 0 | 0 |

After the first run the datasets have colors, and the plugin returns before the colorizer
(`plugin.colors.ts:113-121`). Thus H5 and the getters run one time for each chart, or one time
for each update only with `forceOverride`. They never run in a frame of an event or of an
animation.

The getters of H4b and H4c (probe J2: direct calls, the median of 25 ABBA rounds of 1,000,000
calls), ns for each call:

| Case | Form | AOT (3 runs) | wasm, x64 (2 runs) |
|---|---|---:|---:|
| no theme | upstream | 1.39-1.42 | 1.22-1.29 |
| no theme | `??` | 2.85-2.90 | 6.86-7.04 |
| no theme | split (the port) | 1.70-1.75 | 2.50-2.54 |
| theme | `??` | 2.87-2.88 | 8.92-10.75 |
| theme | split (the port) | 2.23-2.25 | 8.65-8.68 |

The port uses the split form: the theme branch, then the unchanged upstream line. Without a
theme it costs 0.3 ns (AOT) and 1.3 ns (wasm) more than upstream for each call. A getter runs one
time for each dataset, or for each data item of a doughnut, pie or polar area dataset, in each
colorizer run. Thus a doughnut of 1000 items with `forceOverride` spends about 1.3 µs more for
each update on wasm.

H5 (probe P4: a fresh plugin options resolver with 5 scopes, as after each update, that reads
`enabled` and `forceOverride`; the median of 15 runs of 200000 iterations), ns for each colorizer
run:

| Build | Run | Upstream reads | H5 from the plugin options | H5 from the theme map (the port) |
|---|---|---:|---:|---:|
| AOT | 1 | 1597.3 | 2103.3 (+506.1) | 1656.7 (+59.5) |
| AOT | 2 | 1576.4 | 2040.2 (+463.9) | 1617.9 (+41.5) |
| AOT | 3 | 1537.0 | 2035.8 (+498.8) | 1598.0 (+61.0) |
| wasm `-O1` (the default level), x64 | 1 | 1782.6 | 2661.9 (+879.3) | 1843.5 (+60.8) |

Probe B3 gives the same order with a resolver of 3 scopes, µs for each colorizer run: the
upstream reads 1.47-1.48 (AOT), 1.22-1.23 (wasm, arm64) and 1.41 (wasm, x64); with H5 from the
theme map 1.53-1.56, 1.27-1.30 and 1.49. The port form of H5 thus costs below 0.1 µs for each
colorizer run. Chart.js ADR 0042 chose the theme map for its behavior (probe J1), not for this
gain.

The plugin tokens (probe B4: 31 tooltip option keys, that is 29 keys of the `defaults` of
`plugin.tooltip.js:1275-1325`, and `rtl` and `textDirection` of `:762, 1074`). Hunk
H2 adds the theme Map of `plugins.tooltip` as one more scope. µs for the 31 reads:

| Case | AOT (3 runs) | wasm, arm64 (3 runs) | wasm, x64 (1 run) |
|---|---:|---:|---:|
| fresh resolver, 3 scopes (no plugin tokens) | 10.78-11.65 | 10.85-11.46 | 12.45 |
| fresh resolver, 4 scopes (plugin tokens) | 12.98-13.90 | 12.07-12.67 | 14.66 |
| cached resolver, 3 scopes | 0.225-0.240 | 0.314-0.358 | 0.413 |
| cached resolver, 4 scopes | 0.223-0.233 | 0.320-0.349 | 0.362 |

In each process the tokens add 1.2-2.4 µs to the first reads after each update of a themed
chart. The cached reads of a frame or an event take the same time. Thus no part of the theme
palette or of the plugin tokens changes a frame figure: the frame figures of this document are
in milliseconds.

### 14.6 The touch input path after the device check (Chart.js ADR 0037)

The device check of Chart.js ADR 0037 (Evidence E8) changed the touch-like path of the host
(`lib/src/platform/chart_host.dart`, section 8 of the ADR): a move with no change gives no
event, the tap candidate gives only `pointermove` inside its slop limit, and after the pan begin
a move gives only `touchmove`.

Bed: Apple M3 Max, Flutter 3.47.7, `flutter test` (JIT with asserts). Other sessions loaded the
Mac (load average about 4 to 5). A temporary test sent `PointerMoveEvent`s of one touch pointer
through `GestureBinding.handlePointerEvent` to a `ChartHost` with the `FakeChart` of the host
tests (the platform listeners of the default `events`, no chart work): 20000 events in each
round, 8 rounds, the median of the rounds. Two runs before the change (the host at `ce340ca`)
and two runs after it. ns for each event:

| Case | Before (runs 1, 2) | After (runs 1, 2) | DOM events before | DOM events after |
|---|---:|---:|---|---|
| a move at the same point | 472, 480 | 298, 331 | `pointermove`, `touchmove` | none |
| a move of the tap candidate inside the slop | 554, 599 | 401, 419 | `pointermove`, `touchmove` | `pointermove` |
| a move after the pan begin | 474, 492 | 453, 449 | `pointermove`, `touchmove` | `touchmove` |

The host path costs less in each case. The larger gain is the chart work: with the default
`events`, the dropped `touchmove` events gave one chart `mousemove` in each frame, with a hover
hit test and a tooltip hit test (Chart.js ADR 0037, E5: 214 µs at 10000 points on JIT). A finger
that rests on a chart, or that moves inside the slop, now gives no chart event, as in Chrome. The
device figures come from the dispatch series on the Pixel 8a when the phone is free.

### 14.7 The figures of step 8

Step 8 of phase 8 measured the plugin paths from 2026-10-23 to 2026-10-24. The night of
2026-10-28 to 2026-10-29 ran the series that
had no data in that time, and the A/B of Chart.js ADR 0044 (section 14.9). The protocols, the
raw data, the scripts and the recomputes are working files of phase 8, not committed. Each
protocol was written before its first run, and no decision rule changed after the data. This
section gives the figures and the decisions of 2026-10-23 to 2026-10-24.

**Method.**

- Trees. The cells are the cells of C8 (`4e332a5`, section 6). All series measured `ce340ca`
  (C8s: C8 with the stress mode `plugins` and the class `StressStats`; the benchmark code does not
  change). The before side of the stress record is `ff83f19`, the last commit before the code of
  phase 8 (no plugin is registered). Flutter 3.47.7 (Dart 3.13.5), profile builds, one build at a
  time, in worktrees outside the main checkout.
- Statistics. A config comparison runs two labelled processes of one build in the ABBA order, 6
  pairs, and 6 more pairs when the stage 2 condition of the protocol is true. A cell gives the
  mean of the pair differences of the run medians (the run value is the median of 15 batches),
  with a 95 % percentile bootstrap interval (20000 resamples, seed 20261023). A series without a
  comparison gives the median of the run values and the mean with the same interval over the
  runs.
- Pixel 8a (`4B071JEKB17363`, Android 17, AC power): the gate and the window rule of section
  13.6 (the battery at 33.0 °C or less, `cpu8` at 2.8 GHz or more, a window is excluded when more
  than 10 % of its samples of the UI-thread core are below 2.5 GHz). The sampler gave about 2
  samples a second, not 4. Thus one low sample excluded a window of about 4 s (dispatch 18 of 35
  excluded cells, tooltip 21 of 60). The rule was applied as written.
- iPhone 17 Pro (iOS 26.6.2, on the cable): a fresh `flutter run --profile` for each run, the
  lock state `passcodeRequired: false` before and after each run, a pause of 60 s after it. The
  iPhone has no gate and no window rule.
- macOS (Apple M3 Max, AC power): one fresh process for each run with the app window in front,
  the gate of the quiet Mac (the 1-minute load at 4.0 or less), and an exclusion when the load
  after the run is above 8 or the app is not in front in more than 10 % of the samples.
- VS Code browser (Chromium, dart2wasm): Chromium 148.0.7778.280 in Electron 42.8.1, VS Code
  1.134.0, a dart2wasm profile build at the root of its own port with COOP and COEP headers, the
  macOS gate before each run. A run starts only in a visible tab. From the tooltip run
  `t1000-p4-off`, each run opened its own new tab, because two runs hung in a long-lived tab (the
  renderer at 99 % CPU and 1.1 GB). The recompute ran the T1 and F cells of the two tab methods
  apart: the same cells fire, and the means differ by 0.007 ms or less.
- Schedule (decisions of the porting lead). The maintainer stopped the Pixel 8a series on
  2026-10-23 at 14:10, because the battery gate waited 5-6 minutes before most runs. The iPhone
  17 Pro ran the other phone series in the day. From 2026-10-23 21:00 no iPhone run occurred
  in this phase (each app start needed a person to unlock the phone). The quiet-Mac block ran in
  the night of 2026-10-24 and ended at 08:00. The Pixel 8a ran only the stress before/after
  record and the input re-check of Chart.js ADR 0037 in that night.
- Recompute. An independent agent computed all figures, exclusions and decisions again from the
  raw files with its own scripts, and an adversarial checker did the same for the day data. All
  figures agree (means within 0.001 ms, interval ends within 0.01 ms), and all decisions agree.

What ran (runs that count):

| Topic | Pixel 8a | iPhone 17 Pro | macOS | VS Code browser (Chromium, dart2wasm) |
|---|---|---|---|---|
| Dispatch, CT stage 1 | 24 (12 pairs) | 24 (12 pairs) | 11 of 12 (5 valid pairs) | 12 (6 pairs) |
| Dispatch, CT stage 2 (P5) | not measured (no phone run) | not measured (no phone run) | 2026-10-24: not measured (night ended); then section 14.9 | 2026-10-24: not measured (night ended); then section 14.9 |
| Tooltip (a), (b), (c) | 46 of 48 (2 with user input) | 24 (6 pairs of each group) | 24 (6 pairs of each group) | 22 of 24 (2 hung) |
| Tooltip P6 (V1, V2) | not measured (no phone run) | not measured (no phone run) | 2026-10-24: not measured (night ended); then section 14.9 | 2026-10-24: not measured (night ended); then section 14.9 |
| Legend and title | not measured (stopped after 9 runs: incomplete, not used) | 24 (12 pairs) | 24 (12 pairs) | 24 (12 pairs) |
| Fill | not measured (thermal gate, then no phone run) | 12 (6 runs of each group) | 12 | 12, and 3 upstream runs |
| Fill, the A/B of Chart.js ADR 0044 | not measured (no phone run, ADR 0044 Open 1) | not measured (no phone run) | section 14.9 | section 14.9 |
| Stress S-a, S-b | 48 (12 before, 36 after) | 12 (1 run each, after) | 36 (after) | 36 (after) |
| Stress S-c (plugin scenes) | not measured (not in the night task) | 10 (1 run each) | 30 | 30 |
| Upstream comparison (P3) | not measured (thermal gate) | not measured (no phone run) | - | 2026-10-24: not measured (tab hidden); then section 14.9 |
| Input check of Chart.js ADR 0037 (no timing) | 32 rows in rounds f1 and f2 (after r1 to r3); STN10 again in round g1 | - | - | - |
| Fixture registry | - | - | 24 (12 pairs) | - |

**The hook dispatch: CT stage 1 (Chart.js ADR 0038 §10).** The benchmark cell `plugins.line`
(section 6). Config A has `registerables` with the least work of each plugin, config B has
`options.plugins: false`. A - B is an upper bound of the gain of CT: it holds the whole dispatch,
the hook bodies and three empty boxes. R1 and R2 have 3 datasets of 1000 points, R3 and R4 have
100 datasets of 100 points (204 notifies for each draw; R3 and R4 are primary). Whole frame:
`draw+end` for a draw, `update+draw+end` for an update. ms.

| Cell | Platform | Pairs | A | B | Mean A - B | 95 % interval | Rel. | Rule 1 |
|---|---|---:|---:|---:|---:|---|---:|---|
| R1, 3 datasets, draw | Pixel 8a | 6 | 1.226 | 1.252 | -0.0433 | -0.0870 .. -0.0132 | -3.4 % | pass |
| R1 | iPhone 17 Pro | 12 | 0.567 | 0.583 | -0.0141 | -0.0220 .. -0.0047 | -2.4 % | pass |
| R1 | macOS | 5 | 0.650 | 0.651 | +0.0018 | +0.0002 .. +0.0032 | +0.3 % | pass |
| R1 | VS Code browser | 6 | 0.796 | 0.782 | +0.0133 | +0.0092 .. +0.0173 | +1.7 % | pass |
| R2, 3 datasets, update | Pixel 8a | 8 | 5.173 | 5.107 | -0.0742 | -0.2627 .. +0.1015 | -1.4 % | fail |
| R2 | iPhone 17 Pro | 12 | 2.053 | 2.030 | +0.0352 | +0.0198 .. +0.0533 | +1.7 % | pass |
| R2 | macOS | 5 | 2.335 | 2.283 | +0.0670 | +0.0470 .. +0.0834 | +2.9 % | pass |
| R2 | VS Code browser | 6 | 2.785 | 2.697 | +0.0748 | +0.0603 .. +0.0920 | +2.8 % | pass |
| R3, 100 datasets, draw | Pixel 8a | 10 | 4.768 | 4.659 | +0.0843 | +0.0276 .. +0.1375 | +1.8 % | fail |
| R3 | iPhone 17 Pro | 12 | 2.221 | 2.213 | +0.0133 | -0.0113 .. +0.0378 | +0.6 % | pass |
| R3 | macOS | 5 | 2.367 | 2.323 | +0.0444 | +0.0324 .. +0.0564 | +1.9 % | pass |
| R3 | VS Code browser | 6 | 3.370 | 3.314 | +0.0638 | +0.0523 .. +0.0738 | +1.9 % | pass |
| R4, 100 datasets, update | Pixel 8a | 7 | 25.658 | 22.723 | +2.2671 | +1.5987 .. +2.8803 | +9.8 % | fail |
| R4 | iPhone 17 Pro | 12 | 12.290 | 11.729 | +0.5844 | +0.4992 .. +0.7100 | +5.0 % | fail |
| R4 | macOS | 5 | 12.765 | 12.097 | +0.6730 | +0.6472 .. +0.7026 | +5.6 % | fail |
| R4 | VS Code browser | 6 | 12.882 | 12.546 | +0.3917 | +0.3128 .. +0.4738 | +3.1 % | fail |

A and B are the medians of the run values of the valid pairs. Rule 1 passes when the upper end
is below 0.1 ms. The R2 failure on the Pixel 8a comes from the width of its interval (upper end
+0.1015 ms, mean below 0). On each platform the cost of R4 is in the part `update`: Pixel 8a
+4.96 ms (`draw` -2.69), iPhone 17 Pro +0.588 ms (`draw` -0.004), macOS +0.661 ms (`draw`
+0.012), VS Code browser +0.500 ms (`draw` -0.109). The draw alone (R3) costs 0.013-0.084 ms for
each frame. This agrees with the calculation of the ADR (30-80 µs on a phone).

**The hook dispatch: CT stage 2 (P5).** Rule 1 failed R2, R3 and R4 on the Pixel 8a and R4 on
the other three platforms, so stage 2 started. Variant B (a descriptor list for each hook in
`PluginService`, one file, +54 lines; a measurement variant, not a valid port) was frozen with its
SHA-256 before any stage 2 run, with the primary cells R2, R3 and R4 in config A and the guards
`chart.a` N 1000 and R1. With no phone run, macOS replaced the Pixel 8a as a platform of the decision. The
screen of the Mac stayed locked from before the first run to 08:00, so no stage 2 run occurred
on macOS or in the VS Code browser in that night. A calculation, not a decision: the gain of CT
cannot be larger than the stage 1 cost A - B, and R3 has an upper end of +0.0564 ms on macOS and
+0.0738 ms in the VS Code browser. Thus rule 2 (a gain of 0.1 ms or more in each primary cell) is
almost certainly false on these two platforms. Section 14.9 has the stage 2 series of
2026-10-29 and the decision.

**The tooltip (Chart.js ADR 0039 Open 1 and 2).** The cells `tooltip.hover` (a), `tooltip.still`
(b) and `tooltip.fade` (c) of section 6, with 3 or 10 datasets of N points (P1 = 3 datasets and N
100, P2 = 10 and 100, P3 = 3 and 1000, P4 = 10 and 1000). The on and off labels are the processes
with and without the tooltip plugin. Whole frame of (a), on - off, ms:

| Cell | Platform | Pairs | On | Off | Mean on - off | 95 % interval | Rel. |
|---|---|---:|---:|---:|---:|---|---:|
| P1 | Pixel 8a | 7 | 0.669 | 0.570 | +0.0941 | +0.0646 .. +0.1233 | +16.4 % |
| P2 | Pixel 8a | 7 | 2.033 | 1.071 | +0.9651 | +0.9454 .. +0.9849 | +90.4 % |
| P3 | Pixel 8a | 7 | 1.629 | 1.334 | +0.2821 | +0.2319 .. +0.3364 | +21.0 % |
| P4 | Pixel 8a | 10 | 4.954 | 3.831 | +1.1111 | +1.0837 .. +1.1357 | +28.8 % |
| P1 | iPhone 17 Pro | 6 | 0.231 | 0.194 | +0.0363 | +0.0350 .. +0.0378 | +18.7 % |
| P2 | iPhone 17 Pro | 6 | 0.659 | 0.431 | +0.2295 | +0.2275 .. +0.2317 | +53.4 % |
| P3 | iPhone 17 Pro | 6 | 0.601 | 0.548 | +0.0540 | +0.0523 .. +0.0553 | +9.9 % |
| P4 | iPhone 17 Pro | 6 | 1.922 | 1.741 | +0.1722 | +0.1570 .. +0.1863 | +9.9 % |
| P1 | macOS | 6 | 0.283 | 0.228 | +0.0543 | +0.0513 .. +0.0572 | +23.8 % |
| P2 | macOS | 6 | 0.766 | 0.458 | +0.3088 | +0.3050 .. +0.3127 | +67.3 % |
| P3 | macOS | 6 | 0.713 | 0.606 | +0.1073 | +0.1042 .. +0.1103 | +17.7 % |
| P4 | macOS | 6 | 2.033 | 1.788 | +0.2475 | +0.2382 .. +0.2573 | +13.9 % |
| P1 | VS Code browser | 6 | 0.270 | 0.206 | +0.0632 | +0.0597 .. +0.0663 | +30.7 % |
| P2 | VS Code browser | 6 | 0.891 | 0.499 | +0.3940 | +0.3872 .. +0.3990 | +79.1 % |
| P3 | VS Code browser | 4 | 0.875 | 0.710 | +0.1657 | +0.1565 .. +0.1750 | +23.4 % |
| P4 | VS Code browser | 4 | 3.030 | 2.324 | +0.7260 | +0.6795 .. +0.7830 | +31.4 % |

Most of the cost is in the part `draw` at 10 datasets (Pixel 8a P2: `update` +0.129, `draw`
+0.821, `end` +0.015 ms). At N 1000 about one hover step in four keeps the same nearest index
(the points are about 0.75 px apart, and the event position rounds to whole pixels, as upstream),
so that iteration gives no render (`notifies` 2). Thus P3 and P4 are the cost of a hover frame of
this pointer path.

(b), a still tooltip, on - off of `draw+end`, ms (P1, P2, P3, P4): Pixel 8a +0.0833, +0.1590,
+0.1167, +0.2914; iPhone 17 Pro +0.0235, +0.0473, +0.0165, +0.0397; macOS +0.0292, +0.0590,
+0.0422, +0.0753; VS Code browser +0.0290, +0.0558, +0.0348, +0.1855 (+0.0148 .. +0.4222).

(c), the fade, whole frame, the median of the runs, ms (P1, P2, P3, P4): Pixel 8a 0.816, 1.649,
2.369, 6.912; iPhone 17 Pro 0.282, 0.603, 0.969, 3.011; macOS 0.306, 0.650, 1.012, 3.027; VS Code
browser 0.333, 0.766, 1.292, 4.174.

Rule T1 reads `tooltipDraw` (`beforeTooltipDraw` to `afterTooltipDraw`) of (a) on and (b) on, the
mean over all valid runs of both labels. It fires when one cell on the Pixel 8a or in the VS Code
browser has a lower end of 0.1 ms or more. ms, mean (lower end); the iPhone 17 Pro and macOS
figures are information only:

| Cell | Pixel 8a | VS Code browser | iPhone 17 Pro | macOS |
|---|---|---|---:|---:|
| (a) 3 datasets, N 100 | 0.0505 (0.0498) | 0.0244 (0.0242) | 0.0163 | 0.0211 |
| (b) 3 datasets, N 100 | 0.0635 (0.0629) | 0.0291 (0.0287) | 0.0239 | 0.0272 |
| (a) 10 datasets, N 100 | **0.7614 (0.7542)** | **0.3098 (0.3073)** | 0.1664 | 0.2329 |
| (b) 10 datasets, N 100 | **0.1338 (0.1332)** | 0.0523 (0.0516) | 0.0463 | 0.0519 |
| (a) 3 datasets, N 1000 | **0.2451 (0.2417)** | **0.1053 (0.1039)** | 0.0461 | 0.0710 |
| (b) 3 datasets, N 1000 | 0.0860 (0.0853) | 0.0324 (0.0321) | 0.0243 | 0.0279 |
| (a) 10 datasets, N 1000 | **0.6029 (0.5971)** | **0.4685 (0.4659)** | 0.1314 | 0.1838 |
| (b) 10 datasets, N 1000 | **0.2123 (0.2093)** | **0.1467 (0.1433)** | 0.0480 | 0.0552 |

**T1 fires** (bold cells: 5 on the Pixel 8a, 4 in the VS Code browser). Rule T2 (a CPU profile of
a hover frame) applies only when T1 does not fire. The design panel of T1 (three drafts, a judge
and a synthesis) found the cause and kept the decision of Chart.js ADR 0039 §7:
- The typed snapshot of section 7 changes a resolved option. An upstream probe on the pinned
  build gives other values for a scriptable option that reads the context in 6-7 of 12 fade
  frames. A scriptable font size reaches `width` and `height`, and the defaults `boxWidth` and
  `boxHeight` are functions (`plugin.tooltip.js:1303-1304`). The port gives the upstream values
  today. Thus the snapshot fails priority 1.
- The cost is the paragraph build of each new tooltip line in the canvas layer. In case (a) the
  hover index changes in each frame, and at 10 datasets the bench cycle of 1100 lines is longer
  than the paragraph cache of 512 entries. A model of the cache gives 0, 11, 4 and 11 misses for
  each frame at P1, P2, P3 and P4, and about one `paragraph.dispose()` for each miss, in batches of
  128. A local pointer move gives 0.7-0.8 misses for each frame.
- The cost of one new line, from the (a) cells at N 100 (two bounds that need no guessed
  fraction), µs: Pixel 8a 56.6-64.6, iPhone 17 Pro 11.1-13.7, macOS 15.9-19.3, VS Code browser
  22.1-25.9. The new lines are 73-93 % of `tooltipDraw` of (a) 10 datasets, N 100 on each
  platform. Even with no other cost, that Pixel 8a cell stays at 0.622 ms or more, so no form of
  the option reads can stop T1.
- On macOS the Dart part of the tooltip draw is 17.8 of 232.9 µs (7.7 %) for (a) 10 datasets,
  N 100, and 25.5 of 51.9 µs (49 %) for (b). An exact memo of the option reads (lazy, key by key,
  with the context resolver of the frame and a reset after each resolver write) passes the
  behavior probes, but its estimated gain is 0.011-0.04 ms for each frame (macOS 0.011-0.012,
  VS Code browser 0.014 or less, Pixel 8a 0.03-0.04). That is below the 0.1 ms of Chart.js ADR
  0020 §13 for a change of the upstream structure. Thus no candidate exists, and no code A/B ran.
- The first visit of a line builds two paragraphs: a black one in `measureCanvasText` (update)
  and the colored one in `layoutCanvasText` (draw).
- The number path of `toLineHeight` (section 11.8 item 1, form (a)) also helps the tooltip:
  -5.30 µs (AOT) and -4.63 µs (dart2wasm) for each draw, -6.44 and -5.74 µs with the animation
  reads. It is evidence for section 11.8, not a T1 candidate.

Rule F reads E = `tooltipDraw` of (c) - `tooltipDraw` of (b) on, in the same run. P6 runs when one
cell on the Pixel 8a or in the VS Code browser has a mean of 0.1 ms or more and a lower end above
0. ms, mean (interval) (P1, P2, P3, P4):
- Pixel 8a: +0.1085 (+0.1069 .. +0.1101), +0.2821 (+0.2781 .. +0.2865), +0.1292 (+0.1274 ..
  +0.1310), +0.3554 (+0.3505 .. +0.3609). P6 runs (4 cells).
- VS Code browser: +0.0642 (+0.0633 .. +0.0652), +0.1719 (+0.1693 .. +0.1742), +0.0658 (+0.0654
  .. +0.0663), +0.2407 (+0.2305 .. +0.2490). P6 runs (P2 and P4).
- Information: iPhone 17 Pro +0.0238, +0.0638, +0.0220, +0.0644; macOS +0.0363, +0.1005 (+0.0998
  .. +0.1013), +0.0367, +0.1103 (+0.1079 .. +0.1126).

**P6, the fade frames.** Two variants of `lib/src/canvas/canvas_ui.dart` (`_drawText`, the fill
branch) were written, tested and frozen with their SHA-256 before any P6 run. V1 rounds the
composite alpha of a fill text to a step of 1/64, and the rounded color is the key of the
paragraph cache (an error of at most 1/128 in alpha). V2 caches an opaque paragraph and draws it
in a `saveLayer` with the global alpha. The A/B of each variant (primary cells: the whole frame of
(c) at N 1000) was to run on macOS and in the VS Code browser. The task started after 08:00, so
no P6 run occurred in that night. The raster check of V2 named a stress record on the Pixel 8a,
which the schedule did not permit. Before the first P6 run of section 14.9, an amendment of the
protocol named the stress scene `fade` (the mode `plugins`, 10 datasets, N 1000) on macOS in
its place. Section 14.9 has the P6 series and the decision.

**The legend and the title.** The cells `legend.line` and `title.line` (section 6): 3 datasets.
X has no legend and no title, Y1 has the legend, Y2 has the title. d_L = Y1 - X and d_T = Y2 - X,
whole frame, 12 pairs, ms, mean (interval):

| Cell | iPhone 17 Pro | macOS | VS Code browser |
|---|---|---|---|
| d_L draw N 100 | +0.0021 (+0.0010 .. +0.0031) | +0.0140 (+0.0133 .. +0.0147) | +0.0020 (+0.0006 .. +0.0034) |
| d_L draw N 1000 | -0.0158 (-0.0192 .. -0.0124) | +0.0138 (+0.0114 .. +0.0158) | +0.0588 (+0.0530 .. +0.0643) |
| d_L update N 100 | +0.0328 (+0.0271 .. +0.0391) | +0.0498 (+0.0442 .. +0.0552) | +0.0525 (+0.0490 .. +0.0559) |
| d_L update N 1000 | -0.0021 (-0.0212 .. +0.0180) | +0.0558 (+0.0317 .. +0.0832) | +0.0353 (+0.0094 .. +0.0634) |
| d_T draw N 100 | +0.0067 (+0.0056 .. +0.0076) | +0.0025 (+0.0014 .. +0.0035) | -0.0086 (-0.0099 .. -0.0073) |
| d_T draw N 1000 | +0.0171 (+0.0137 .. +0.0207) | +0.0030 (-0.0013 .. +0.0073) | +0.0086 (+0.0012 .. +0.0158) |
| d_T update N 100 | +0.0181 (+0.0128 .. +0.0238) | +0.0056 (+0.0009 .. +0.0101) | +0.0128 (+0.0092 .. +0.0167) |
| d_T update N 1000 | +0.0446 (+0.0236 .. +0.0650) | +0.0295 (+0.0204 .. +0.0394) | +0.0009 (-0.0277 .. +0.0310) |

The base X (median, ms; draw N 100, draw N 1000, update N 100, update N 1000): iPhone 17 Pro
0.164, 0.707, 1.073, 4.394; macOS 0.187, 0.753, 1.142, 4.636; VS Code browser 0.184, 0.845, 1.131,
4.904. The legend costs 0.06 ms or less for each frame, the title 0.05 ms or less. The fit of the
boxes (the part `layout` of an update) costs about 0.02 ms for the legend at N 100. On the iPhone
the legend frame at N 1000 draws 0.016 ms faster: the legend box takes height from the chart
area, so the lines are shorter (`datasetsDraw` -0.021 ms). No ADR rule reads these cells.

**The filler (Chart.js ADR 0040 Open 2 and 3).** The cells `fill.gaps` (a line with gaps and
`above` and `below`), `fill.stack` (the `stack` fill) and `fill.radar` (section 6), 3 datasets.
Whole frame, the median of 6 runs (minimum-maximum), ms:

| Cell | Call | N | iPhone 17 Pro | macOS | VS Code browser |
|---|---|---:|---|---|---|
| fill.gaps | draw | 100 | 0.185 (0.184-0.193) | 0.215 (0.213-0.218) | 0.220 (0.217-0.222) |
| fill.gaps | draw | 1000 | 4.998 (4.957-5.107) | 5.203 (5.120-5.311) | 5.989 (5.965-6.000) |
| fill.gaps | update | 100 | 0.570 (0.565-0.577) | 0.643 (0.639-0.657) | 0.662 (0.656-0.667) |
| fill.gaps | update | 1000 | 6.793 (6.743-6.905) | 7.028 (6.961-7.155) | 8.332 (8.309-8.383) |
| fill.stack | draw | 100 | 0.414 (0.411-0.419) | 0.438 (0.437-0.441) | 0.507 (0.505-0.513) |
| fill.stack | draw | 1000 | 30.692 (30.185-30.904) | 31.160 (30.636-31.621) | 36.770 (36.615-36.928) |
| fill.stack | update | 100 | 0.945 (0.937-0.953) | 1.014 (1.009-1.019) | 1.148 (1.139-1.154) |
| fill.stack | update | 1000 | 36.821 (35.815-37.058) | 36.599 (36.420-36.900) | 41.451 (41.406-41.661) |
| fill.radar | draw | 100 | 0.059 (0.058-0.060) | 0.063 (0.061-0.064) | 0.068 (0.066-0.068) |
| fill.radar | draw | 1000 | 0.404 (0.400-0.412) | 0.410 (0.408-0.421) | 0.500 (0.496-0.503) |
| fill.radar | update | 100 | 0.472 (0.470-0.476) | 0.510 (0.507-0.517) | 0.481 (0.479-0.483) |
| fill.radar | update | 1000 | 2.632 (2.614-2.648) | 2.881 (2.865-2.903) | 2.595 (2.568-2.613) |

The part `datasetsDraw` has almost all of the draw. The `stack` fill grows by a factor of 75 for
10 times the points (iPhone 17 Pro draw 0.411 to 30.688 ms), the quadratic stack target of
upstream. The raster figures come from the stress scenes (`rasterMs`, median, ms): macOS `gaps`
1.79, `stack` 0.63 (N 1000) and 1.26 (N 100), `radar` 1.58; iPhone 17 Pro `gaps` 1.01, `stack`
0.50 and 0.95, `radar` 0.83. The VS Code browser gives no raster time for each frame (see the
stress figures below).

Open 3 compares the port draw of `fill.stack`, call `draw`, N 1000 (the median of the run values
of `drawMedianMs`) with the upstream draw of the same cell (the median of the run medians of 3
runs of the pinned build in the VS Code browser, a new tab for each run). Port 36.755 ms
(36.601-36.913), upstream 19.862 ms (the run medians 20.163, 19.862 and 19.678 ms): **R = 1.85**
(1.85 with `draw+end`, an upper bound). R is 1.5 or more, so Open 3 went to a design panel. The
panel wrote [Chart.js ADR 0044](adr/0044-stack-fill-search.md) (the stack fill search): the loop
of `_boundSegment` with direct calls and an `int` index, and a window search in the stack line.
Section 14.9 has its A/B and the ratio R after the change. On macOS the port draw is 31.151 ms.
The Pixel 8a has no fill figure and no upstream figure.

**The stress frames.** `lib/main_stress.dart`, the 7-s window, the means after the first 30
frames. S-a is the line chart and S-b the radar chart of the mode `chart` (the legend off, the
other plugins on). S-c is the mode `plugins` with N 1000 (and `stack` also at N 100). No scenario
fell below 4 FPS, so none needed `SECONDS=60`. The Pixel 8a before/after record: before is 1 run
of `ff83f19`, after is the median of 3 runs of `ce340ca`, with the ratio after / before:

| Scenario | fps | updateMs | drawMs | buildMs | rasterMs |
|---|---|---|---|---|---|
| line draw 1000 | 58.49 to 58.32 (1.00x) | 0.01 to 0.01 | 5.25 to 5.45 (1.04x) | 6.27 to 6.38 (1.02x) | 5.39 to 5.61 (1.04x) |
| line update 1000 | 58.33 to 58.16 (1.00x) | 3.25 to 3.50 (1.08x) | 2.97 to 2.90 (0.98x) | 7.16 to 7.37 (1.03x) | 4.49 to 4.79 (1.07x) |
| line draw 5000 | 58.17 to 57.65 (0.99x) | 0.00 to 0.00 | 7.67 to 7.74 (1.01x) | 8.43 to 8.55 (1.01x) | 4.88 to 5.05 (1.03x) |
| line update 5000 | 56.68 to 56.51 (1.00x) | 4.10 to 4.17 (1.02x) | 4.91 to 4.89 (1.00x) | 10.27 to 10.30 (1.00x) | 4.82 to 5.19 (1.08x) |
| line draw 20000 | 56.19 to 51.22 (0.91x) | 0.00 to 0.00 | 10.80 to 11.59 (1.07x) | 11.57 to 12.45 (1.08x) | 7.29 to 7.94 (1.09x) |
| line update 20000 | 30.46 to 29.75 (0.98x) | 6.35 to 6.71 (1.06x) | 11.61 to 12.15 (1.05x) | 20.73 to 21.94 (1.06x) | 9.72 to 9.59 (0.99x) |
| radar draw 1000 | 58.33 to 58.32 (1.00x) | 0.01 to 0.00 | 5.60 to 5.76 (1.03x) | 6.33 to 6.42 (1.01x) | 5.87 to 5.54 (0.94x) |
| radar update 1000 | 57.99 to 57.50 (0.99x) | 5.18 to 4.79 (0.92x) | 2.76 to 3.54 (1.28x) | 8.56 to 8.97 (1.05x) | 4.49 to 4.70 (1.05x) |
| radar draw 5000 | 58.34 to 57.50 (0.99x) | 0.01 to 0.00 | 8.51 to 9.58 (1.13x) | 9.10 to 10.19 (1.12x) | 5.99 to 6.52 (1.09x) |
| radar update 5000 | 48.55 to 43.14 (0.89x) | 8.45 to 8.84 (1.05x) | 4.23 to 6.72 (1.59x) | 13.04 to 16.24 (1.25x) | 7.77 to 8.38 (1.08x) |
| radar draw 20000 | 56.72 to 29.29 (0.52x) | 0.00 to 0.00 | 11.21 to 20.23 (1.80x) | 12.05 to 21.58 (1.79x) | 10.83 to 16.94 (1.56x) |
| radar update 20000 | 14.35 to 12.61 (0.88x) | 40.85 to 37.23 (0.91x) | 18.30 to 32.34 (1.77x) | 57.83 to 71.68 (1.24x) | 12.26 to 14.00 (1.14x) |

- The line chart with the real plugins: `drawMs`, `updateMs` and `buildMs` are 0.98-1.08x of the
  before record, within the spread of the phase 7 figures (section 13.6). The one high before run
  of line draw 20000 (56.19 FPS) explains its FPS change: phase 7 gave 50.91 FPS with the same
  draw time. The plugin dispatch adds no large cost in a real frame.
- The radar chart draws more, because the filler now draws the fill `start` of the radar defaults
  (`controller.radar.js:16-20`), which `ff83f19` did not draw. At 20000 points the draw goes from
  11.21 to 20.23 ms and the scene from 57 to 29 FPS. The iPhone 17 Pro shows the same against its
  phase 7 figures (radar draw 20000: 5.81 to 11.02 ms, 117 to 75 FPS). The line chart there is
  unchanged (draw and update within 0.03 ms).

The plugin costs in a real frame (S-c, the scene median minus the base median, ms; the iPhone 17
Pro has 1 run of each scene; fps differences are in FPS):

| Cost | Platform | fps | updateMs | drawMs | buildMs | rasterMs |
|---|---|---:|---:|---:|---:|---:|
| legend (legend on - off) | iPhone 17 Pro | +0.04 | +0.00 | +0.01 | +0.02 | -0.04 |
| legend | macOS | +0.00 | +0.00 | +0.06 | +0.05 | +0.01 |
| legend | VS Code browser | +0.05 | +0.00 | +0.04 | +0.50 | not measured (no frame raster time) |
| title (title - legend off) | iPhone 17 Pro | -0.15 | +0.00 | -0.01 | +0.00 | -0.02 |
| title | macOS | +0.01 | +0.00 | +0.01 | -0.01 | +0.00 |
| title | VS Code browser | +0.04 | +0.00 | +0.02 | +0.35 | not measured (no frame raster time) |
| tooltip hover (tooltip on - off) | iPhone 17 Pro | -0.49 | +0.18 | -0.01 | +0.25 | +0.02 |
| tooltip hover | macOS | -0.06 | +0.40 | -0.15 | +0.28 | -0.02 |
| tooltip hover | VS Code browser | -0.05 | +0.37 | +0.31 | +1.20 | not measured (no frame raster time) |
| tooltip fade (fade - hover off) | iPhone 17 Pro | +0.05 | -0.09 | +1.25 | +1.23 | -0.88 |
| tooltip fade | macOS | -0.06 | -0.20 | +1.83 | +1.62 | -0.15 |
| tooltip fade | VS Code browser | -0.05 | -0.14 | +2.03 | +0.43 | not measured (no frame raster time) |

- The legend and the title cost 0.06 ms of draw or less. Each S-c scene holds the frame rate
  (60 FPS on macOS and in the VS Code browser, 120 FPS on the iPhone 17 Pro), except
  `fill.stack` at N 1000: 30.28 FPS (iPhone 17 Pro), 29.55 FPS (macOS), 25.90 FPS (VS Code
  browser). Of S-a and S-b on these platforms, only the radar at 20000 points is below the frame
  rate: the update at 29.15 (iPhone 17 Pro), 27.21 (macOS) and 37.45 FPS (VS Code browser), and
  the draw at 75.08 FPS on the iPhone 17 Pro.
- The fade row is not the cost of the tooltip alone: the fade sends one event in 12 frames, and
  the animator draws the chart in each frame. The events of the tooltip scenes go directly to
  `chart.eventHandler`, not through the host input path of Chart.js ADR 0037.
- `tooltipDrawMs` (median, ms; hover on, fade): iPhone 17 Pro 0.12, 0.12; macOS 0.25, 0.36; VS
  Code browser 0.43, 0.68.
- In the VS Code browser, `rasterMs` is not a raster time for each frame: it is 13-900 ms in the
  radar, legend, title, tooltip and fill scenes while the page holds 60 FPS. Thus no browser
  raster figure is given.
- `buildMaxMs` and `rasterMaxMs` of a `STRESS` line are the maximum of the last statistics window
  only (`main_stress.dart` writes `last?.rasterMaxMs`), not of the run. This section gives no
  maximum.

**The upstream comparison (P3).** Not measured in the series of 2026-10-23 to 2026-10-24. The
Pixel 8a series stopped at the thermal gate before it. The Safari runs on the iPhone 17 Pro
stopped with the end of the iPhone runs and are not data. In the VS Code browser the screen of the
Mac locked after the quiet-Mac block, the tab stayed hidden for 10 minutes, and no page loaded:
not measured (tab hidden). Section 14.9 has the VS Code browser series of
2026-10-29. The Pixel 8a and the iPhone 17 Pro have no upstream
figure. Thus the fix candidates of a plugin path (an excess of 0.1 ms or more on the Pixel 8a and
a CPU profile) have no data.

**The input check of Chart.js ADR 0037 (no timing).** The device check compares the DOM events,
the chart events and the chart state of the port on the Pixel 8a with Chrome on the same phone
(the pinned build through `adb reverse`), for each gesture row. Rounds r1 to r3 (2026-10-23)
found the five differences of Evidence E8 of the ADR. The fix `78129b8` changed the touch path of
the host (section 14.6). The re-check (rounds f1 and f2, build F at `363f28d`, Chrome 155) gave
the Chrome result in 31 of 32 rows. T15, a fast drag, differs only in the positions of three move
events (the frame coalescing of Chrome, ADR Open 10), which the protocol allows. STN10, a stylus
tap with a move inside the stylus slop, failed: Chrome gives the compatibility events and `click`
at the up position, and the port gave them at the down position. The fix `102634b` puts the tap
of a stylus at the up position (Evidence E10). Round g1 ran STN10 and the regression rows ST1,
STN14, S04, S07, SN08, T01, T02 and T05 again with the fixed host (2026-10-29, build G at
`1d271cd`): all 9 rows pass. In STN10 the port now gives the compatibility events and `click` at
the up position, as Chrome does. Three optional stylus rows also pass on both sides: STLP (a long
press: the compatibility events at the down position, no `click`), STO10 (a tap outside the chart
area) and STE10 (a lift outside the box of the host: no `click`). No row had a difference, so no
further round ran. Not checked: the rows with a finger (H01-H03, a
person at the phone), the mouse rows (M01, M02: no mouse), a platform cancel (rows 4 and 8 of
section 6 of the ADR) and the epsilon 0.05 of the slop limit (`adb` gives whole pixels).

**The fixture registry on a quiet Mac (Chart.js ADR 0029 Open 2).** Section 14.4 flagged its
figures: the Mac was busy. The same method ran again on 2026-10-24 at night, at `ce340ca`. W
imports the registry of 147 hand ports in each of 29 test files, N does not. Each run is
`flutter test --no-pub -j 1` without the compile cache. ABBA, 12 pairs, each run with a passed
gate (the 1-minute load 2.90-3.94 before the run, 4.14 or less after it), and one warm run of
each side first. W median 21.48 s, N median 21.10 s, mean W - N **+0.703 s (95 % interval
-0.444 .. +1.882 s)**, +24.2 ms for each file. Pairs 1-6 alone: +0.360 s (-1.082 .. +2.010 s).
Five runs of both sides took 23.9-25.3 s against 20.9-21.6 s for the others: noise of the shared
Mac. The upper end is below the trigger of 4 s, so one registry stays and Open 2 does not fire.
This confirms section 14.4.

**The rule decisions of step 8.**

| Rule | Platforms | Result | Consequence |
|---|---|---|---|
| CT rule 1 (Chart.js ADR 0038 §10 item 5) | Pixel 8a, iPhone 17 Pro, macOS, VS Code browser | fail: R2, R3, R4 on the Pixel 8a; R4 on the other three | stage 2 (P5) starts; Chart.js ADR 0020 Open 1 does not close by rule 1 |
| CT rule 2 (item 7, P5) | macOS and VS Code browser (in place of the Pixel 8a: no phone run) | 2026-10-24: no data (night ended); 2026-10-29 (section 14.9): rule 2 (a) false on both platforms, (c) false in the VS Code browser | CT is not adopted; Chart.js ADR 0038 Open 1 and Chart.js ADR 0020 Open 1 close with this figure |
| Tooltip T1 (Chart.js ADR 0039 Open 1) | Pixel 8a (5 cells), VS Code browser (4 cells) | fires | the design panel keeps Chart.js ADR 0039 §7; no candidate, no code A/B |
| Tooltip T2 | Pixel 8a, VS Code browser | does not apply (T1 fires) | no CPU profile |
| Tooltip F (Chart.js ADR 0039 Open 2) | Pixel 8a (4 cells), VS Code browser (2 cells) | P6 runs | V1 and V2 frozen |
| P6, V1 and V2 | macOS and VS Code browser (in place of the Pixel 8a) | 2026-10-24: not measured (night ended); 2026-10-29 (section 14.9): V1 and V2 REJECT on macOS and ACCEPT in the VS Code browser; the V2 raster check on macOS fails (+0.16 ms `rasterMs`) | no variant lands; the present paragraph cache stays; Chart.js ADR 0039 Open 2 closes |
| Fill, Open 2 (frame, draw and raster figures) | iPhone 17 Pro, macOS, VS Code browser (raster: iPhone 17 Pro and macOS) | done for these platforms; the Pixel 8a not measured (the thermal gate, then no phone run) | Chart.js ADR 0040 Open 2 stays open for the Pixel 8a |
| Fill, Open 3 (R of `fill.stack`) | VS Code browser (dart2wasm against V8) | R = 1.85, 1.5 or more | a design panel: Chart.js ADR 0044 (proposed); the Pixel 8a part has no data |
| The A/B of Chart.js ADR 0044 (§6) | macOS, VS Code browser | ACCEPT on macOS; REJECT in the VS Code browser (the guard `fill.radar` wholly above 0, h = 9); R_B = 0.056 | the change goes out of the tree, and Chart.js ADR 0046 records the result; Chart.js ADR 0044 is rejected; Chart.js ADR 0040 Open 3 stays open |
| Upstream comparison (P3) | VS Code browser (V8 against dart2wasm) | done (2026-10-29); the largest excess of a plugin cell: `fill.stack` update N 1000, +19.598 ms (1.90 times upstream) | figures only: no profile in the browser, so no fix candidate |
| Fix candidates of a plugin path | Pixel 8a | no data (no upstream comparison on the Pixel 8a) | none |
| Input check of Chart.js ADR 0037 (protocol §6) | Pixel 8a (no timing) | f1 and f2: 31 of 32 rows pass, STN10 fails; fix `102634b`; round g1 (2026-10-29): all 9 rows and the 3 optional stylus rows pass | the device part of the acceptance condition holds: rows 5, 6, 7, 9 and 13 of section 6 of the ADR are confirmed |
| Legend, title, stress | all | no rule reads them | figures only |
| Registry (Chart.js ADR 0029 Open 2) | macOS, quiet | does not fire (upper end +1.882 s) | one registry stays |

### 14.8 Open: the plugins

Step 8 (sections 14.7 and 14.9) measured or decided each item. Each item has a status, as in
section 13.7: **measured**, **decided** or **open**.

1. **CT, the typed hook slots** (Chart.js ADR 0038 §10 and Open 1, Chart.js ADR 0020 Open 1):
   decided. Rule 1 of stage 1 failed on each platform (section 14.7). Stage 2 (P5) on macOS and in
   the VS Code browser: rule 2 (a) is false on both platforms (section 14.9), so CT is not
   adopted. The two Open items close with these figures.
2. **P6, the fade frames** (Chart.js ADR 0039 Open 2): decided. V1 and V2 on macOS and in the
   VS Code browser, and the raster check of V2 on macOS: the rule rejects V1 and V2 on macOS and
   accepts them in the VS Code browser, and V2 fails the raster check (section 14.9). Thus no
   variant is accepted, the present paragraph cache stays, and Chart.js ADR 0039 Open 2 closes
   with these figures.
3. **`interpolate` and the quadratic stack** (Chart.js ADR 0040 Open 3): open. The code A/B of
   Chart.js ADR 0044 (the stack fill search) gave ACCEPT on macOS and REJECT in the VS Code
   browser (section 14.9). Thus the change goes out of the tree, and Chart.js ADR 0046 records the
   result. The stack fill stays quadratic, as upstream, and R stays 1.85 in the VS Code browser.
   With the change, R was 0.056, but the draw of the radar fill (the guard G2) was 5.5 % slower,
   and 9 control cells were slower in the VS Code browser. A new candidate needs a new design and
   a new code A/B.
4. **The Pixel 8a**: open. It has no fill, legend, title, S-c, upstream or ADR 0044 figure (the
   battery gate, then the schedule). Chart.js ADR 0040 Open 2 stays open for it.
5. **The upstream comparison (P3)**: measured in the VS Code browser (section 14.9). The
   Pixel 8a and the iPhone 17 Pro have no upstream figure: open. The fix candidates of a plugin
   path need the excess on the Pixel 8a and a CPU profile, so none exists.
6. **The paragraph build of new tooltip lines** (rule T1): open. It is a cost of the canvas layer:
   57-65 µs for each new line on the Pixel 8a. A change of the paragraph cache must not use (a) at
   N 100 as its primary cell: a cache of more than about 1150 entries makes the bench cycle all
   hits, a false gain. The facts go to the revisit of
   [canvas-cuts-plan.md](canvas-cuts-plan.md) ("after phase 8, before phase 9").
7. **An exact memo of the tooltip option reads**: open. It stays specified, with a reference
   implementation, for a later trigger: a device figure where the option reads of one tooltip draw
   cost 0.1 ms or more (about 30-70 body items), or a change of the threshold of Chart.js ADR 0020
   §13. It needs a `DIVERGES` marker and an `adapt` row.
8. **Not explained, no rule asks for it:** (b) at 10 datasets costs more at N 1000 than at N 100
   on the Pixel 8a (0.134 to 0.212 ms) and in the VS Code browser (0.052 to 0.147 ms), but not on
   macOS and the iPhone 17 Pro. A CPU profile of (b) 10 datasets, N 1000 in the VS Code browser
   can show the cause.
9. **The sampler of the Pixel 8a** gives about 2 samples a second. A later protocol that keeps
   the 10 % rule of a window must take the sample rate into account.
10. **Decided in step 8:** the tooltip option reads (Chart.js ADR 0039 Open 1: T1 fired, and the
    design panel kept §7 of the ADR, section 14.7); the fixture registry (Chart.js ADR 0029 Open
    2 does not fire on a quiet Mac, section 14.7); the legend opt-out of the stress and benchmark
    charts (section 14.3); the filler frame, draw and raster figures on the iPhone 17 Pro, macOS
    and the VS Code browser (Chart.js ADR 0040 Open 2, section 14.7); a second implementer of the
    point interfaces in the stress and benchmark closures (Chart.js ADR 0040 Open 4): none, by a
    check of the closures before the runs.

### 14.9 The night series after the step 8 record

The record of section 14.7 left P3, P5 and P6 with no data, and the design panel of Chart.js
ADR 0040 Open 3 wrote Chart.js ADR 0044, which lands only after a code A/B (porting-flow.md
§1.1). These series ran in the night of 2026-10-28 to 2026-10-29 on macOS and in the VS Code
browser (Chromium, dart2wasm). The protocols, the raw data, the scripts and the
recomputes are working files of phase 8, not committed. Each protocol was written before its
first run. The amendments before the data: on 2026-10-28, the side A of each A/B series at
`1d271cd` (the ADR 0044 A/B, P5 and P6), the P6 patches rebased to `1d271cd` with their SHA-256
values, macOS in place of the Pixel 8a as a deciding platform of P6, the VS Code browser as the
platform of the choice rule of P6, and macOS as the platform of the raster check of V2 (P6); on
2026-10-29 at 03:39 CET, before the pilot of P3, the source of the port runs of group 2 (a port series
of the same night in the same tab, P3); on 2026-10-29 at 02:40 CET, the iPhone 17 Pro as an added
platform that does not decide (the ADR 0044 A/B, P5 and P6; the iPhone series stopped before its
first run, because the app launch failed). No decision rule changed after the data.

**Method.**

- Platforms. macOS: Apple M3 Max, macOS 27.0.1, AC power, the gate of the quiet Mac of section
  14.7. VS Code browser: Chromium 150.0.7871.250 in Electron 43.7.7, VS Code 1.143.1, a dart2wasm
  profile build at the root of its own port with COOP and COEP headers, one own tab for each
  series with `about:blank` before and after each run, a run only in a visible tab, the macOS gate
  before each run. `caffeinate -dimsu` held the display and the Mac awake for the whole block, so
  the screen did not lock and the tab stayed visible: no run found a locked screen or a hidden
  tab. No phone ran these series: the follow-up A/B series run on macOS and in the VS Code browser
  (a decision of the porting lead, section 14.7).
- Builds. Flutter 3.47.7 (Dart 3.13.5), profile builds of `lib/main_bench.dart` (P3 also the
  upstream page of the pinned build), one at a time, in worktrees outside the main checkout. Each
  B side is its A side with one frozen patch: `git apply --check` passed first, and the SHA-256 of
  `git diff` of the B worktree equals the SHA-256 of the patch.
- Sides.
  - Chart.js ADR 0044: A is `1d271cd`, where `helpers.segment.dart`,
    `element.line.dart` and `filler.target.stack.dart` are byte-equal to `363f28d`. B is A with
    the change of the ADR (one patch of the three files, 507 lines, SHA-256
    `456d3b0be62b8e696699005f8be5f8cf7848ae0a195ded522882f450b8187a2f`).
  - P5: A is `1d271cd`, B is A with the descriptor lists of section 14.7 (SHA-256
    `82bd01d20f1b6da9c9755bb28e394e49ce5b70f53b712975c3281f998f45b403`). From `ce340ca` to
    `1d271cd`, the library and the gallery change only `chart_host.dart`, which the benchmark
    does not use. Thus the measured code is the code of `ce340ca`.
  - P6: A is `1d271cd`, B is A with V1 or V2. The variants were frozen on 2026-10-24 at `ce340ca`
    (SHA-256 `35cafb3edcd3ce083bf1567335e87f17660612f7e84184b841d151d451561a25` and
    `9078718fe8c2f517ca05f6702747d672821babf9a8d70043f5c5ccdf9fe0fc9d`). The patches of the series
    are rebased to `1d271cd`: only the entry of `canvas-cuts-plan.md` moves, and the code and test
    hunks are byte-equal (SHA-256 `fc652d8e091700fbfcca079c010f6a1b4d59abdd69a04a0d894a0f37074ecda2`
    and `24d307e89ed9bf00d7e6630733ec608f21104b79488fd5d594229b02c0b3fc76`). V1 ran first.
  - P3: the pinned build of Chart.js with the plugins against the port at `ce340ca` (group 1:
    4 builds, `chart.*`; group 2: 6 builds of the plugin selectors `plugins`, `tooltip` at N 100,
    `tooltip` at N 1000, `legend,title`, `fill.gaps,fill.radar` and `fill.stack`, 3 runs of each
    in the same tab and the same night).
- Statistics. As section 14.7: ABBA, 6 pairs, and 6 more pairs when the stage 2 condition of
  the protocol is true; the mean of the pair differences of the run medians, with a 95 %
  percentile bootstrap interval (20000 resamples, seed 20261023).
- The rule of a code A/B, for each platform after its last stage. ACCEPT when the upper end of
  each primary interval is below 0 (or meets the stricter threshold of the topic rule), no guard
  interval lies wholly above 0, the control screen passes and no large control hit is confirmed.
  REJECT when a primary or a guard interval lies wholly above 0, the control screen fails or a
  large control hit is confirmed. Else INCONCLUSIVE. The control screen counts the control cells
  whose interval lies wholly above 0 (h) and passes when h is below h*, the limit of a binomial
  test at 0.05 for K control cells. A large control hit (a lower end of 0.1 ms or more and of 5 %
  or more of the A mean) starts a confirmation series of 6 pairs with the selector of that case.
- Recompute. An independent agent computed all figures and decisions again from the raw files
  with its own scripts: all figures agree (means within 0.001 ms, interval ends within 0.01 ms;
  the largest difference is below 1e-12 ms), and all decisions agree. The recompute used exact
  integer arithmetic. It confirms that the lower end of the macOS interval of G2 of the ADR 0044
  A/B is exactly 0 (a float sum of the resamples gives 1.85e-17 ms). It also found that the macOS
  ACCEPT of that A/B depends on one excluded pair (see below). That dependence does not change the
  result of the A/B.

**The stack fill search (Chart.js ADR 0044 §6).** Groups `f1` (`fill.gaps`, `fill.radar`) and
`f2` (`fill.stack`), 3 datasets, as in section 14.7. Primary: P1 and P2, the whole frame of
`fill.stack` at N 1000 with the calls `draw` and `update`. Guards: G1 `fill.gaps` and G2
`fill.radar` (call `draw`, N 1000), G3 `fill.stack` (call `draw`, N 100). 37 control cells, h* =
4. B - A, whole frame, ms:

| Cell | Platform | Pairs | A | B | Mean B - A | 95 % interval | Rel. |
|---|---|---:|---:|---:|---:|---|---:|
| P1 `fill.stack` draw N 1000 | macOS | 9 | 31.222 | 1.126 | -29.9979 | -30.1282 .. -29.8468 | -96.4 % |
| P2 `fill.stack` update N 1000 | macOS | 9 | 36.331 | 4.405 | -31.9189 | -32.0337 .. -31.8049 | -87.9 % |
| G1 `fill.gaps` draw N 1000 | macOS | 9 | 5.163 | 2.990 | -2.1839 | -2.2141 .. -2.1573 | -42.2 % |
| G2 `fill.radar` draw N 1000 | macOS | 9 | 0.407 | 0.409 | +0.0023 | 0 .. +0.0049 | +0.6 % |
| G3 `fill.stack` draw N 100 | macOS | 9 | 0.434 | 0.129 | -0.3051 | -0.3060 .. -0.3042 | -70.3 % |
| P1 | VS Code browser | 6 | 35.692 | 1.118 | -34.5790 | -34.6368 .. -34.5240 | -96.9 % |
| P2 | VS Code browser | 6 | 40.412 | 5.003 | -35.4873 | -35.6263 .. -35.3533 | -87.7 % |
| G1 | VS Code browser | 5 | 5.821 | 2.928 | -2.9032 | -2.9262 .. -2.8878 | -49.8 % |
| G2 | VS Code browser | 5 | 0.484 | 0.509 | +0.0266 | +0.0230 .. +0.0302 | +5.5 % |
| G3 | VS Code browser | 6 | 0.488 | 0.127 | -0.3605 | -0.3625 .. -0.3580 | -74.0 % |

Valid pairs. macOS: 12 pairs ran, because after pairs 1-6 each primary cell had only 3 valid
pairs (stage 2). 9 pairs of each group are valid. In group `f1` pairs 1, 3 and 4 are not valid,
and in group `f2` pairs 1, 3 and 5: in pair 1 the front-app sampler of the driver read no sample
on macOS 27.0.1 (a fault of the script); in pair 3 the app was in front in less than 90 % of the
samples; in pair 4 a driver stopped during a run, and a second driver made a duplicate run; in
pair 5 of `f2` a second benchmark process ran during the B run (a decision of the porting lead
from the overlap facts only). VS Code browser: 6 pairs, with no stage 2 (each
primary cell had 6 valid pairs, and no primary interval included 0); pair 1 of `f1` is not valid
(the 1-minute load after its B run was 9.74, above 8).

Control screen: h = 0 on macOS and 9 in the VS Code browser (h* = 4). The 9 control cells above 0
in the VS Code browser are the update cells of `fill.gaps` and `fill.radar` and the draw of
`fill.radar` at N 1000. No large control hit. On macOS the lower end of G2 is exactly 0, so the
interval includes 0. With pair 1 of `f1` (excluded only by the sampler fault), G2 on macOS is
+0.0025 (+0.0004 .. +0.0048), wholly above 0, and macOS gives REJECT too (a check of the
independent recompute, information only). The decision: **ACCEPT on macOS** and **REJECT in the
VS Code browser** (G2 lies wholly above 0, and the control screen fails).

The ratio after the change (Chart.js ADR 0040 Open 3): the median of `drawMedianMs` of the B runs of
`fill.stack`, call `draw`, N 1000, in the VS Code browser is 1.116 ms over the upstream 19.862 ms of
section 14.7: **R_B = 0.056** (0.056 with `draw+end`, an upper bound). The A runs give R_A = 1.80
(35.687 ms), a check against R = 1.85 of section 14.7. For comparison (information only): the
benchmark of the design judge gave a stack build of dataset 2 at N 1000 of 13.886 to 0.248 ms on AOT
and 22.351 to 0.286 ms on dart2wasm in Node.js (Chart.js ADR 0044, Evidence E3), and the protocol
expected a macOS draw of P1 of about 3 ms. The macOS B draw of P1 is 1.126 ms.

Consequence (Chart.js ADR 0044 §6): the A/B rejects the change in the VS Code browser. Thus the
change goes out of the tree, and [Chart.js ADR 0046](adr/0046-stack-fill-search-result.md)
records the result. Chart.js ADR 0044 is rejected, and Chart.js ADR 0040 Open 3 stays open. R_B is
below 1.5, but section 6 of Chart.js ADR 0044 needs ACCEPT on both platforms.

**CT stage 2 (P5, Chart.js ADR 0038 §10 item 7).** Selector `CASES=plugins,chart.a`. Primary: R2,
R3 and R4 in config A (whole frame). Guards: G1 `chart.a` N 1000 and G2 R1 in config A
(`draw+end`). 32 control cells, h* = 3. Rule 2 adopts CT only when (a) on at least one of the
two platforms the gain A - B of each primary cell has a lower end of 0.1 ms or more, (b) on
neither platform a guard interval of B - A lies wholly above 0, (c) on neither platform the
control screen fails, and (d) no large control hit is confirmed. Else CT stays closed, and
Chart.js ADR 0020 Open 1 closes with the figures. B - A, whole frame, ms:

| Cell | Platform | Pairs | A | B | Mean B - A | 95 % interval | Rel. |
|---|---|---:|---:|---:|---:|---|---:|
| R2, 3 datasets, update | macOS | 6 | 2.297 | 2.204 | -0.0925 | -0.0990 .. -0.0863 | -4.0 % |
| R3, 100 datasets, draw | macOS | 6 | 2.321 | 2.290 | -0.0330 | -0.0418 .. -0.0267 | -1.4 % |
| R4, 100 datasets, update | macOS | 6 | 12.508 | 12.172 | -0.3532 | -0.4218 .. -0.2897 | -2.8 % |
| G1 `chart.a` N 1000 | macOS | 6 | 0.213 | 0.212 | -0.0010 | -0.0020 .. -0.0002 | -0.5 % |
| G2 R1 | macOS | 6 | 0.637 | 0.630 | -0.0067 | -0.0090 .. -0.0042 | -1.0 % |
| R2 | VS Code browser | 12 | 2.633 | 2.624 | -0.0008 | -0.0128 .. +0.0112 | -0.0 % |
| R3 | VS Code browser | 12 | 3.104 | 3.098 | -0.0060 | -0.0135 .. +0.0022 | -0.2 % |
| R4 | VS Code browser | 12 | 12.418 | 12.281 | -0.1374 | -0.2821 .. -0.0008 | -1.1 % |
| G1 | VS Code browser | 12 | 0.221 | 0.220 | -0.0008 | -0.0022 .. +0.0005 | -0.4 % |
| G2 | VS Code browser | 12 | 0.730 | 0.726 | -0.0049 | -0.0110 .. +0.0015 | -0.7 % |

macOS: 6 pairs, all valid; the stage 2 condition was not met (no primary interval included 0
or -0.1 ms). VS Code browser: 12 pairs, all valid; stage 2 ran, because after pairs 1-6 the
intervals of R2, R3 and R4 included 0. Control screen: h = 1 on macOS and 4 in the VS Code browser
(h* = 3). The 4 control cells above 0 in the VS Code browser are cells of config B, whose work the
patch does not change. No guard interval lies wholly above 0, and no large control hit occurred.
Rule 2: (a) is false on both platforms (on macOS only R4 has a gain with a lower end of 0.1 ms or
more; in the VS Code browser no primary cell has), (b) is true on both platforms, (c) is true on
macOS and false in the VS Code browser, and (d) is true. The decision: **CT not adopted**.
Chart.js ADR 0038 Open 1 and Chart.js ADR 0020 Open 1 close with this figure: the gain of CT is
below 0.1 ms in R2 and R3 on both platforms (the largest gain, R4 on macOS, is 0.35 ms in an update
of 100 datasets).

**P6, the fade frames (Chart.js ADR 0039 Open 2).** Selector
`CASES=tooltip,title`, `N=1000`, 12 cells. Primary: the whole frame of (c) with 3 and with 10
datasets. Guards: G1 (b) on, 10 datasets, `draw+end`; G2 (a) off, 10 datasets,
`update+draw+end`; G3 `title.line` `draw` and `draw+end`. 38 control cells, h* = 4. A variant is
accepted when the rule accepts it on both platforms, and V2 also needs the raster check: 3 stress
runs of each side, A B A B A B; V2 fails when the median `rasterMs` of B is more than 0.1 ms above
A, or the median FPS of B is more than 1 FPS below A. When both variants are accepted, the choice
rule takes the larger mean gain of the primary cell at 10 datasets in the VS Code browser (the
platform where rule F fired, in place of the Pixel 8a); when the two intervals overlap
and the means differ by less than 10 %, it takes the patch with fewer changed lines. When no
variant is accepted, the present cache stays, and Chart.js ADR 0039 Open 2 closes with the
figures. B - A, whole frame, ms:

| Variant | Cell | Platform | Pairs | A | B | Mean B - A | 95 % interval | Rel. |
|---|---|---|---:|---:|---:|---:|---|---:|
| V1 | (c) 3 datasets | macOS | 6 | 0.983 | 0.951 | -0.0335 | -0.0380 .. -0.0295 | -3.4 % |
| V1 | (c) 10 datasets | macOS | 6 | 2.931 | 2.911 | -0.0223 | -0.0347 .. -0.0078 | -0.8 % |
| V1 | (c) 3 datasets | VS Code browser | 6 | 1.259 | 1.175 | -0.0842 | -0.0935 .. -0.0752 | -6.7 % |
| V1 | (c) 10 datasets | VS Code browser | 6 | 3.998 | 3.899 | -0.1043 | -0.1460 .. -0.0695 | -2.6 % |
| V2 | (c) 3 datasets | macOS | 6 | 0.991 | 0.953 | -0.0382 | -0.0427 .. -0.0340 | -3.9 % |
| V2 | (c) 10 datasets | macOS | 6 | 2.951 | 2.848 | -0.1015 | -0.1092 .. -0.0912 | -3.4 % |
| V2 | (c) 3 datasets | VS Code browser | 6 | 1.244 | 1.172 | -0.0677 | -0.0763 .. -0.0590 | -5.4 % |
| V2 | (c) 10 datasets | VS Code browser | 6 | 3.974 | 3.781 | -0.1802 | -0.1920 .. -0.1683 | -4.5 % |

All runs are valid, and no stage 2 ran (each primary cell had 6 valid pairs, and no primary
interval included 0). Guards and control screen: V1 on macOS: G1 (+0.0240, +0.0132 .. +0.0342) and
G3 (+0.0035, +0.0010 .. +0.0060) wholly above 0, h = 12. V1 in the VS Code browser: no guard above
0, h = 0. V2 on macOS: G1 (+0.0203, +0.0060 .. +0.0353), G2 (+0.0188, +0.0078 .. +0.0327) and G3
(+0.0057, +0.0042 .. +0.0072) wholly above 0, h = 18. V2 in the VS Code browser: no guard above 0,
h = 1. No large control hit. Both patches change `_drawText`, which also draws the tick labels
and the title: the slower guard and control cells on macOS are text draws. The raster check of V2
on macOS, the stress scene `fade` (the mode `plugins`, 10 datasets, N 1000, 7 s for each run, A B
A B A B): the median `rasterMs` is 1.44 ms for A and 1.60 ms for B (+0.16 ms; the limit is
0.1 ms), and the median FPS is 60.11 for A and 60.06 for B (-0.05 FPS; the limit is 1 FPS): V2
fails. A raster output check of V2 before the night (no timing, 63 images) found no wrong output:
each pixel difference is a rounding of the alpha. The decision: **V1 rejected (REJECT on macOS,
ACCEPT in the VS Code browser); V2 rejected (REJECT on macOS, ACCEPT in the VS Code browser, and
the raster check fails); the choice rule does not apply**. The present paragraph cache stays,
and Chart.js ADR 0039 Open 2 closes with these figures.

**The upstream comparison (P3), VS Code browser.** The pinned build of Chart.js with the plugins
(V8) against the port (dart2wasm) in the same browser: 11 upstream groups in 3 rounds, and 10
port groups with 3 runs each (4 groups of the chart cells and 6 groups of the plugin cells), after
a pilot of 11 runs whose figures are not used. The excess is the port frame (update + draw +
end) minus the upstream frame, in ms for each frame. The browser gives no frequency of the main
thread, so no window rule applies on either side. The plugin cells with the largest excess:

| Cell | Port frame | Upstream frame | Excess | Port / upstream |
|---|---:|---:|---:|---:|
| `fill.stack` update, 3 datasets, N 1000 | 41.394 | 21.796 | +19.598 | 1.90 |
| `fill.stack` draw, 3 datasets, N 1000 | 36.117 | 18.388 | +17.729 | 1.96 |
| `plugins.line` update, config A, 100 datasets, N 100 | 12.621 | 5.913 | +6.708 | 2.13 |
| `plugins.line` update, config B, 100 datasets, N 100 | 11.758 | 5.508 | +6.250 | 2.13 |
| `fill.gaps` update, 3 datasets, N 1000 | 8.156 | 3.814 | +4.342 | 2.14 |
| `fill.gaps` draw, 3 datasets, N 1000 | 5.827 | 3.124 | +2.703 | 1.86 |

No run was excluded: 33 of 33 upstream runs and 30 of 30 port runs are valid, and each cell has 3
valid run values on each side. 86 of the 100 cells have an excess of 0.1 ms or more: 43 of the 48
cells of phase 7 and 43 of the 52 plugin cells. The median ratio of the port frame to the upstream
frame is 1.93 (phase 7 cells 2.08, plugin cells 1.82). The largest excess of all cells is `chart.c`
update, N 20000 (+49.771 ms, 2.07 times upstream). The port is faster than upstream only in
`chart.bar` draw at N 5000 (-0.123 ms) and N 20000 (-0.537 ms). The port tree `ce340ca` does not
have the change of Chart.js ADR 0044, which did not land. In this series the upstream draw of
`fill.stack` at N 1000 is 18.388 ms; R uses the 19.862 ms of section 14.7. The protocol takes no CPU
profile in the browser (the profile method of the port does not exist for dart2wasm), and the fix
candidates of a plugin path read the Pixel 8a only. Thus this series gives figures and an order of
the cells, and no fix candidate.

**The rule decisions of the night.**

| Rule | Platforms | Result | Consequence |
|---|---|---|---|
| Chart.js ADR 0044 §6, the code A/B | macOS, VS Code browser | ACCEPT on macOS; REJECT in the VS Code browser (G2 wholly above 0, h = 9) | the change goes out of the tree, and Chart.js ADR 0046 records the result; Chart.js ADR 0044 is rejected |
| Chart.js ADR 0040 Open 3 with R_B | VS Code browser | R_B = 0.056, below 1.5; the A/B rejects the change | stays open |
| CT rule 2 (P5) | macOS, VS Code browser | (a) false on both platforms; (b) true on both platforms; (c) true on macOS, false in the VS Code browser (h = 4); (d) true | CT is not adopted; Chart.js ADR 0038 Open 1 and Chart.js ADR 0020 Open 1 close with these figures |
| P6, V1 | macOS, VS Code browser | REJECT on macOS (G1 and G3 wholly above 0, h = 12); ACCEPT in the VS Code browser | not accepted |
| P6, V2 and its raster check | macOS, VS Code browser; raster: macOS | REJECT on macOS (G1, G2 and G3 wholly above 0, h = 18); ACCEPT in the VS Code browser; the raster check fails (+0.16 ms `rasterMs`) | not accepted; the present paragraph cache stays; Chart.js ADR 0039 Open 2 closes with these figures |
| P3, the excess | VS Code browser | measured (2026-10-29) | figures only |
