# Performance of the canvas layer

| Status | Chapter |
| --- | --- |
|  | [1. Test bed](#1-test-bed) |
|  | [2. Results on macOS](#2-results-on-macos) |
|  | [3. Results in Chrome](#3-results-in-chrome) |
|  | [4. Results on Android](#4-results-on-android) |
|  | [5. Changes](#5-changes) |
|  | [6. How to measure](#6-how-to-measure) |
|  | [7. Open](#7-open) |
|  | [8. Elements (phase 4)](#8-elements-phase-4) |
|  | [9. Cut 2 (phase 5)](#9-cut-2-phase-5) |
|  | [10. Core (phase 5)](#10-core-phase-5) |
|  | [11. Scales (phase 6)](#11-scales-phase-6) |
|  | [12. Dates (phase 6)](#12-dates-phase-6) |
|  | [13. Controllers (phase 7)](#13-controllers-phase-7) |
|  | [14. Plugins (phase 8)](#14-plugins-phase-8) |
|  | [15. The widget (phase 9)](#15-the-widget-phase-9) |
|  | [16. The typed internal model and the native draw path (phase 10)](#16-the-typed-internal-model-and-the-native-draw-path-phase-10) |
| ✅ | [17. Color parsing across Flutter 3.44 and 3.47](#chapter-17) |
| ✅ | [18. Color decoder gain across platforms](#chapter-18) |
| ✅ | [19. Android profiling and further color optimization](#chapter-19) |
| ✅ | [20. Direct typed color to canvas: Android experiment](#chapter-20) |
| ✅ | [21. Direct-color implementation: macOS, Chrome and Android](#chapter-21) |
| ✅ | [22. Color-only implementation](#chapter-22) |
| ✅ | [23. Stacked-fill exact-point experiment](#chapter-23) |
| ✅ | [24. Private boundary endpoint search on Android](#chapter-24) |
| ✅ | [25. Private boundary segment matching on Android](#chapter-25) |
| ✅ | [26. Element option cache-key reuse on Android](#chapter-26) |

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
  the night series after the step 8 record (Chart.js ADR 0044, P3, P5 and P6). Section 15 has the
  widget figures of phase 9: night 1, with the series A-N1 and A-N3 of
  [Chart.js ADR 0049](adr/0049-chart-view-widget.md). Section 16 has the figures of phase 10: the
  typed internal model ([Chart.js ADR 0054](adr/0054-typed-internal-model.md)) and the native draw
  path ([Chart.js ADR 0055](adr/0055-native-draw-path.md)) against the code before them, and the
  five speed fixes.
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
  - The mode `zoom` (`chartBenchZoomCases`, after the mode `theme`, 1000 and 20000 points): the
    plugin of chartjs-plugin-zoom on a line chart of one dataset with a visible x axis (linear,
    and also time for `base`, `idle`, `wheel` and `pan`) and a visible linear y axis.
    `zoom.base` and `zoom.idle` time `draw()` and `update('none')` without and with the plugin
    and its default options. `zoom.wheel`, `zoom.pan`, `zoom.drag` and `zoom.pinch` dispatch one
    input event in each step (`canvas.dispatchEvent`, Chart.js ADR 0108), and `zoom.api` and
    `zoom.apiPan` call the zoom API; a step is the listener, its update and draw, and the end of
    the recording. A case registers the plugin for its own run only. Before each pair of steps,
    it puts the scale ranges back outside the timing, so the range stays bounded. Each line has
    `id`, `scale`, `zoomPlugin`, `steps` and the percentiles of the single steps `stepP50Ms`,
    `stepP90Ms` and `stepMaxMs`. The define `PROFILE_MARKS=true` prints `BENCH_MARK {json}`
    (`id`, `n`, `scale`, `phase` and `t`, `Timeline.now` in microseconds) before and after the
    timed window of each case.
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
  AOT. dart2wasm: 37.7 against 300.2 ns. Since Chart.js ADR 0110, the cache keeps up to 64
  intervals, and the VM reads `timeZoneOffset` (§69).
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
  each call. The time scale makes about 10 such calls in each update. The 64 intervals of
  Chart.js ADR 0110 keep most of them (§69).

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
   hits, a false gain. The facts went to the revisit of
   [canvas-cuts-plan.md](canvas-cuts-plan.md) on 2026-10-29. That plan has no work package for
   the paragraph cache, and the maintainer kept the plan deferred. Thus this item stays open.
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
first run, because the app launch failed, and ran on the day of 2026-10-29: see the paragraph
"The iPhone 17 Pro" below). No decision rule changed after the data.

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

**The iPhone 17 Pro, an added platform (2026-10-29, day).** The iPhone series of the night
did not run: the launch of the first app failed, and the phone needed a restart and a trust of the
developer profile. The series ran on the day of 2026-10-29 from 07:15 to 08:09 UTC with the same
builds of `1d271cd` and the same patches. The phone was an iPhone 17 Pro with iOS 26.6.2, on a
cable and unlocked before and after each run. Each run installed its app and started a new
process. The Mac only installed the apps and read the console. One warm-up run of each side came
before the first timed run of each topic and is not data. Each topic ran stage 1 only (6 pairs,
ABBA), with the statistics and the rules of the night. All 60 timed runs are valid. An
independent recompute from the raw files agrees with each figure and each class. These figures
do not change a decision: the iPhone is an added platform (the amendment of 2026-10-29). B - A,
ms (the frame metric of each cell, as in the tables above):

| Topic | Cell | Pairs | A | B | Mean B - A | 95 % interval | Rel. |
|---|---|---:|---:|---:|---:|---|---:|
| ADR 0044 | P1 `fill.stack` draw N 1000 | 6 | 32.831 | 1.166 | -32.0563 | -33.0723 .. -31.3878 | -96.5 % |
| ADR 0044 | P2 `fill.stack` update N 1000 | 6 | 38.982 | 4.388 | -34.7435 | -35.8960 .. -33.9107 | -88.8 % |
| ADR 0044 | G1 `fill.gaps` draw N 1000 | 6 | 5.531 | 2.751 | -2.7690 | -2.7917 .. -2.7457 | -50.0 % |
| ADR 0044 | G2 `fill.radar` draw N 1000 | 6 | 0.421 | 0.423 | -0.0007 | -0.0070 .. +0.0033 | -0.2 % |
| ADR 0044 | G3 `fill.stack` draw N 100 | 6 | 0.459 | 0.126 | -0.3318 | -0.3433 .. -0.3227 | -72.1 % |
| P5 | R2, 3 datasets, update | 6 | 2.620 | 2.622 | +0.0017 | -0.0065 .. +0.0112 | +0.1 % |
| P5 | R3, 100 datasets, draw | 6 | 2.723 | 2.737 | +0.0068 | -0.0088 .. +0.0203 | +0.3 % |
| P5 | R4, 100 datasets, update | 6 | 15.656 | 15.780 | +0.1167 | +0.0525 .. +0.1868 | +0.7 % |
| P5 | G1 `chart.a` N 1000 | 6 | 0.211 | 0.211 | +0.0000 | -0.0012 .. +0.0013 | +0.0 % |
| P5 | G2 R1 | 6 | 0.669 | 0.668 | -0.0008 | -0.0092 .. +0.0068 | -0.1 % |
| P6 V1 | (c) 3 datasets | 6 | 1.032 | 1.010 | -0.0220 | -0.0285 .. -0.0153 | -2.1 % |
| P6 V1 | (c) 10 datasets | 6 | 3.397 | 3.377 | -0.0237 | -0.0358 .. -0.0105 | -0.7 % |
| P6 V2 | (c) 3 datasets | 6 | 1.189 | 1.152 | -0.0307 | -0.0400 .. -0.0215 | -2.6 % |
| P6 V2 | (c) 10 datasets | 6 | 3.527 | 3.458 | -0.0735 | -0.0830 .. -0.0637 | -2.1 % |

The results for this platform:

- The ADR 0044 A/B gives **ACCEPT**: no guard interval lies wholly above 0, and the control screen
  passes (h = 0, h* = 4). This is the result of macOS. The VS Code browser rejects the change, so
  Chart.js ADR 0044 stays rejected.
- P5 gives **CT not adopted**: (a) is false, because no primary cell has a gain with a lower end
  of 0.1 ms or more. R4 is slower with B. The control screen fails (h = 5, h* = 3). The stage 2
  condition of the protocol was true (the intervals of R2 and R3 include 0), but stage 2 did not
  run, because no decision depends on this platform.
- P6-V1 gives **ACCEPT**: no guard above 0, h = 0. P6-V2 gives **REJECT**: G2 (+0.0100,
  +0.0007 .. +0.0197) lies wholly above 0, and h = 10. No raster check ran on the iPhone, because
  the protocol gives it for macOS only. In the V2 series the A side is about 15 % slower than in
  the V1 series (fade, 3 datasets: 1.189 ms against 1.032 ms). It is possible that the phone was
  warmer, because devicectl gives no thermal state. The pair differences use A and B of the same
  series.

**The rule decisions of the night.**

| Rule | Platforms | Result | Consequence |
|---|---|---|---|
| Chart.js ADR 0044 §6, the code A/B | macOS, VS Code browser | ACCEPT on macOS; REJECT in the VS Code browser (G2 wholly above 0, h = 9) | the change goes out of the tree, and Chart.js ADR 0046 records the result; Chart.js ADR 0044 is rejected |
| Chart.js ADR 0040 Open 3 with R_B | VS Code browser | R_B = 0.056, below 1.5; the A/B rejects the change | stays open |
| CT rule 2 (P5) | macOS, VS Code browser | (a) false on both platforms; (b) true on both platforms; (c) true on macOS, false in the VS Code browser (h = 4); (d) true | CT is not adopted; Chart.js ADR 0038 Open 1 and Chart.js ADR 0020 Open 1 close with these figures |
| P6, V1 | macOS, VS Code browser | REJECT on macOS (G1 and G3 wholly above 0, h = 12); ACCEPT in the VS Code browser | not accepted |
| P6, V2 and its raster check | macOS, VS Code browser; raster: macOS | REJECT on macOS (G1, G2 and G3 wholly above 0, h = 18); ACCEPT in the VS Code browser; the raster check fails (+0.16 ms `rasterMs`) | not accepted; the present paragraph cache stays; Chart.js ADR 0039 Open 2 closes with these figures |
| P3, the excess | VS Code browser | measured (2026-10-29) | figures only |
| The added platform (stage 1) | iPhone 17 Pro (2026-10-29, day) | the ADR 0044 A/B ACCEPT; P5 CT not adopted; P6-V1 ACCEPT; P6-V2 REJECT | figures only; no decision changes |

## 15. The widget (phase 9)

Phase 9 adds the public widget `ChartView` ([Chart.js ADR 0049](adr/0049-chart-view-widget.md)).
The design panel of phase 9 wrote six night series, A-N1 to A-N6. The gate of Chart.js ADR 0049
needs the figures of two of them: A-N1, the overhead of the widget, and A-N3, the read of the
reduced-motion flag (§7 of the ADR). Night 1 ran both. Section 15.1 has its method, section 15.2
the figures of A-N1, section 15.3 the figures of A-N3, section 15.4 the observations and section
15.5 the decisions. The protocol, the raw data, the scripts and the recompute are working files of
phase 9, not committed.

### 15.1 Night 1: the method

Night 1 ran from 2026-10-29 22:00 to 2026-10-30 08:00 CET. The protocol was written before the
first timed run. No decision rule changed after the data. The amendments:
- 2026-10-29 18:05, before the first run: the maintainer paused the Mac at 17:40. Thus the macOS
  and the browser series did not start at 22:00. The Pixel 8a was the only deciding platform of
  that time, and the iPhone 17 Pro became an added platform that does not decide.
- 2026-10-30 01:30: the maintainer freed the Mac at 01:24. A late Mac thread ran the macOS and the
  browser series from 01:38 with the same drivers, the same rules and the same night end. Thus
  the three deciding platforms of the method decide: macOS, the Pixel 8a and the VS Code browser.
  The run of A-N3 pair 2, side A, of the motion build on the Pixel 8a is not valid: at 01:07
  another app came to the front, and the phone recorded user input.
- 2026-10-30 02:15: the maintainer wired the iPhone. The iPhone thread ran from 02:16 to 04:07,
  next to the Mac thread. Each iPhone run installed its app through `devicectl`, which gave the
  Mac a short load. The ABBA order gives this load to both sides.

**Method.**

- Trees. The base is `main` at `223e70c`. A-N1: side A is `lib/main_stress.dart` with
  `HOST=canvas` (the gallery host `ChartCanvas`), and side B is the same source with `HOST=view`
  (`ChartView`). A-N3: side A is `223e70c` with no hunk, and side B is A with the patch of side B
  of Chart.js ADR 0049 §7 (the `Expando` read keyed by the canvas). The patch was frozen on
  `901b46f` (SHA-256 `72fb46e0b10fd32dfa7ce92383bd35d0ed90c877ad89a85c9ec4023c35fee496`, 187
  lines). On `223e70c`, the diff of the B worktree has the SHA-256
  `4cf074a902cd301ae8932c335e48f4af0887519948567d75cd132eb3eb603c20`: only the two `index` lines
  and two hunk headers differ. Without these lines, both patches have the SHA-256
  `7dffe785d1e0e01158f4f8b1a22892b7e73731e62c4bbb86a1a5becf3d8f86e4`. The hunk of
  `core.animations.dart` and the file `reduced_motion.dart` that landed are the code of this
  patch. Side C (a `bool` field of `UiCanvasElement`) was not built.
- Builds. Profile builds, also for A-N3: one build mode with section 14.9, a decision of the
  porting lead in place of the release builds of the A-N3 design. Flutter 3.47.7 (Dart 3.13.5),
  one build at a time, in worktrees outside the main checkout. Each define is a compile-time
  constant, so each cell, side and platform has its own build: 18 builds on each platform. Each
  driver compared the SHA-256 of the binary with the build list before each run.
- Platforms.
  - macOS: Apple M3 Max, macOS 27.0.1, AC power. The gate of the quiet Mac before each run: the
    1-minute load at 4.0 or less, at most 10 minutes. A fresh process for each run, with the app
    window in front.
  - Pixel 8a: `4B071JEKB17363`, Android 17 (`CP3A.260905.009`), AC power. The gate before each
    pair: the battery at 33.0 °C or less and `cpu8` at 2.8 GHz or more, at most 10 minutes. After
    10 minutes, the pair starts with `pass=0` in its headers (protocol §5.3). A-N3 has the window
    rule of section 13.6: a case window with more than 10 % of its UI-core samples below 2.5 GHz
    is not valid. A-N1, the stress entry, has no window rule, as in section 13.6.
  - VS Code browser: Chromium 150.0.7871.250 in Electron 43.7.7, VS Code 1.143.1. Each dart2wasm
    profile build is at the root of its own port with COOP and COEP headers. Each series has one
    own tab, with `about:blank` before and after each run, and the gate of the quiet Mac before
    each run. All 216 runs had a visible page of 719 x 562 CSS px at DPR 2.5, cross-origin
    isolated.
  - iPhone 17 Pro, an added platform: iOS 26.6.2, on the cable, unlocked before and after each
    run, one warm-up run of each side before its series. It has no temperature gate, because
    `devicectl` gives no thermal state.
- Statistics. ABBA: pair i runs A then B when i is odd, and B then A when i is even. Stage 1 has
  6 pairs. Stage 2 adds 6 pairs by the condition of each series (sections 15.2 and 15.3). The run
  value is the median of 15 batches. The cell value is the mean of the pair differences B - A,
  with a 95 % percentile bootstrap interval (20000 resamples, seed 20261023).
- Recompute. An independent agent computed all figures and decisions again from the raw files
  with its own script. The 5681 run values and their validity, the 441 windows of the Pixel 8a
  and all 241 cells agree with the summary of the night. The largest difference is 7.1e-15 ms.

### 15.2 A-N1: the overhead of `ChartView` (Chart.js ADR 0049 gate)

Cells, 7 on each platform: `MODE=chart`, `CALL=draw` (one `chart.draw()` in each frame and no
widget rebuild), the types `line`, `bar` and `doughnut` at `SCENARIO=1000x0` and `20000x0`; and
`hover-1000`: `MODE=plugins`, `SCENE=hover`, `CALL=frame` (one `mousemove` through the event
handler in each frame), 10 datasets, N 1000. The stress entry runs `SECONDS=15` with
`BATCHES=15`. Figures: `buildP50Ms` (primary, the UI thread: build, layout and paint) and
`rasterP50Ms`, each the median of the p50 of the `FrameTiming` durations of the 15 batches.
`buildP90Ms`, `rasterP90Ms` and FPS are recorded and do not decide. Side B times its draws with
two inline plugins, about 1-2 µs for each frame: a bias against B.

The rule, written before the first run: **PASS** when no interval of B - A of `buildP50Ms` or
`rasterP50Ms` lies wholly above 0.1 ms on a deciding platform. Else **DEFECT**: the porting lead
finds the cause before 0.1.0. Stage 2 runs on a platform when a p50 interval includes 0.1 ms, or
when a cell has fewer than 6 valid pairs.

B - A, ms (A is the mean of the A runs):

| Platform | Cell | Pairs | Build A | Build B - A (95 % interval) | Raster A | Raster B - A (95 % interval) |
|---|---|---:|---:|---|---:|---|
| macOS | `line-1000` | 12 | 1.456 | -0.0017 (-0.0183 .. +0.0142) | 1.185 | +0.0050 (-0.0050 .. +0.0158) |
| macOS | `line-20000` | 12 | 4.817 | +0.0183 (-0.0083 .. +0.0458) | 0.505 | +0.0017 (-0.0092 .. +0.0125) |
| macOS | `bar-1000` | 11 | 6.254 | +0.0691 (-0.0118 .. +0.1682) | 3.883 | +0.0927 (-0.0091 .. +0.2236) |
| macOS | `bar-20000` | 11 | 74.140 | -0.0718 (-0.2600 .. +0.1136) | 8.666 | +0.0245 (-0.0827 .. +0.1300) |
| macOS | `doughnut-1000` | 11 | 3.245 | -0.0073 (-0.0182 .. +0.0027) | 1.722 | +0.0164 (+0.0027 .. +0.0309) |
| macOS | `doughnut-20000` | 12 | 95.631 | +0.0667 (-0.1592 .. +0.3108) | 26.256 | -0.1817 (-0.5675 .. +0.1800) |
| macOS | `hover-1000` | 12 | 3.797 | +0.0008 (-0.0067 .. +0.0075) | 1.081 | -0.0025 (-0.0083 .. +0.0050) |
| Pixel 8a | `line-1000` | 9 | 5.381 | +0.2789 (+0.0733 .. +0.4500) | 5.468 | +0.2711 (+0.0744 .. +0.4811) |
| Pixel 8a | `line-20000` | 8 | 11.518 | -0.3800 (-1.0062 .. +0.2462) | 9.011 | -0.1350 (-0.3588 .. +0.0350) |
| Pixel 8a | `bar-1000` | 9 | 13.340 | +0.3622 (-2.0611 .. +2.7300) | 9.416 | +0.8556 (-0.8522 .. +2.3911) |
| Pixel 8a | `bar-20000` | 9 | 130.830 | -3.0911 (-9.2600 .. +4.1333) | 56.903 | -0.5622 (-1.7678 .. +0.8756) |
| Pixel 8a | `doughnut-1000` | 9 | 12.709 | -0.0656 (-0.3722 .. +0.2411) | 15.507 | -0.2278 (-0.6478 .. +0.1222) |
| Pixel 8a | `doughnut-20000` | 8 | 247.689 | +4.2200 (-4.3675 .. +13.1063) | 138.821 | +9.5950 (-6.5988 .. +35.2400) |
| Pixel 8a | `hover-1000` | 8 | 0.917 | +0.0137 (+0.0050 .. +0.0237) | 9.961 | -0.0337 (-0.1537 .. +0.0725) |
| VS Code browser | `line-1000` | 12 | 1.038 | +0.0050 (-0.0225 .. +0.0325) | 0.710 | -0.0042 (-0.0200 .. +0.0125) |
| VS Code browser | `line-20000` | 12 | 6.125 | -0.0108 (-0.0817 .. +0.0533) | 1.187 | -0.0017 (-0.0108 .. +0.0075) |
| VS Code browser | `bar-1000` | 12 | 1.866 | +0.0375 (-0.0275 .. +0.1117) | 1.150 | +0.0133 (-0.0158 .. +0.0425) |
| VS Code browser | `bar-20000` | 12 | 23.152 | -0.3067 (-0.6300 .. +0.0300) | 23.107 | -0.3325 (-0.6675 .. +0.0150) |
| VS Code browser | `doughnut-1000` | 12 | 3.822 | +0.0250 (+0.0017 .. +0.0450) | 3.088 | -0.0008 (-0.0142 .. +0.0117) |
| VS Code browser | `doughnut-20000` | 12 | 75.229 | -3.4467 (-4.1300 .. -2.8467) | 71.712 | -1.5542 (-1.9817 .. -1.1383) |
| VS Code browser | `hover-1000` | 12 | 6.872 | -0.2792 (-1.9142 .. +1.3592) | 482.978 | +1.2133 (-0.4642 .. +3.0617) |
| iPhone 17 Pro | `line-1000` | 12 | 1.716 | +0.0042 (-0.0017 .. +0.0108) | 1.111 | -0.0042 (-0.0083 .. +0.0000) |
| iPhone 17 Pro | `line-20000` | 12 | 5.923 | +0.0933 (-1.1350 .. +1.3283) | 0.764 | +0.0150 (-0.1633 .. +0.1933) |
| iPhone 17 Pro | `bar-1000` | 12 | 3.243 | -0.0092 (-0.0192 .. +0.0017) | 0.443 | +0.0000 (-0.0042 .. +0.0042) |
| iPhone 17 Pro | `bar-20000` | 12 | 84.462 | -1.7083 (-8.0717 .. +4.4942) | 8.586 | -0.2900 (-0.9725 .. +0.3733) |
| iPhone 17 Pro | `doughnut-1000` | 12 | 2.269 | +0.0167 (-0.0058 .. +0.0442) | 1.483 | +0.0133 (-0.0058 .. +0.0342) |
| iPhone 17 Pro | `doughnut-20000` | 12 | 127.164 | -2.4450 (-4.6433 .. -0.4850) | 43.706 | -0.3442 (-1.0775 .. +0.4467) |
| iPhone 17 Pro | `hover-1000` | 12 | 0.060 | +0.0008 (+0.0000 .. +0.0025) | 1.076 | +0.0000 (-0.0042 .. +0.0050) |

Valid pairs. macOS: 12 pairs. Stage 2 ran, because after pair 6 the intervals of `bar-20000`
(raster) and `doughnut-20000` (build and raster) included 0.1 ms. Five runs of pair 9 are not
valid (`bar-1000` A and B, `bar-20000` A and B, `doughnut-1000` A): the Mac recorded user input,
and in two of them the app was in front in less than 90 % of the samples. VS Code browser: 12
pairs, all valid. Stage 2 ran, because the intervals of `bar-1000` (build) and `hover-1000`
(build and raster) included 0.1 ms. Pixel 8a: stage 2 ran, because 10 intervals included 0.1 ms
and `line-20000` had 5 valid pairs. The night end cut stage 2: pairs 7 and 8 ran, pair 9 ran for
5 of the 7 cells, and pairs 10 to 12 were not measured. Run A of `line-20000` pair 1 is not
valid (user input). iPhone 17 Pro: 12 pairs, all valid.

The result: **PASS** on each deciding platform. No interval lies wholly above 0.1 ms. The largest
lower end is +0.0027 ms on macOS (`doughnut-1000`, raster), +0.0017 ms in the VS Code browser
(`doughnut-1000`, build) and +0.0744 ms on the Pixel 8a (`line-1000`, raster). The added iPhone
17 Pro also gives PASS (the largest lower end is 0.0000 ms).

Caveats:
- **The Pixel 8a `line-1000` cell is fragile.** Its lower ends are +0.0733 ms (build) and
  +0.0744 ms (raster). The means are +0.2789 and +0.2711 ms, about 5 % of the A means. Without
  pair 6 (build), or without pair 1 or pair 6 (raster), the interval lies wholly above 0.1 ms:
  for example +0.2275 .. +0.4875 ms (build, the pairs without pair 6). Five other seeds of the
  bootstrap give lower ends of 0.070 to 0.077 ms. The effect is on the Pixel 8a only: on macOS,
  in the VS Code browser and on the iPhone, the mean of `line-1000` is within 0.005 ms of 0.
- **The pairs after a gate with `pass=0` stay valid** (a ruling of the porting lead). The battery
  was at 32.8 to 35.9 °C at the gates, and `cpu8` was at 2.914 GHz at each gate. The gate did not
  pass in its 10 minutes before 23 of the 61 cell pairs of A-N1 and before 6 of the 16 cell pairs
  of A-N3. Protocol §5.3 starts such a pair with `pass=0`, and section 13.6 has the precedent (S1
  p2 A' stays in). With these pairs excluded, `line-1000` keeps 3 pairs (7 to 9), and both its
  intervals lie wholly above 0.1 ms (build +0.2400 .. +0.6400 ms, raster +0.2600 .. +0.5800 ms).
  That reading would give DEFECT on the Pixel 8a. The ruling keeps the protocol as written.
- **The night end cut the stage 2 of the Pixel 8a** (see the valid pairs above). Thus the Pixel
  8a cells have 8 or 9 pairs, not 12.
- **The semantics were on in each Pixel 8a run.** The accessibility service of the TeamViewer
  Universal Add-On was on, so Flutter built the semantics tree in each run, on both sides. The
  pairs stay paired. But the absolute Pixel 8a figures include the semantics work, and the
  `line-1000` effect of the Pixel 8a cannot be separated from it. A record run with the service
  off is open.

### 15.3 A-N3: the read of the reduced-motion flag (Chart.js ADR 0049 §7)

Primary cells: the frameless benchmark (`lib/main_bench.dart`, `CASES=motion`), the cases
`motion.line` and `motion.bar` at N 1000 and 20000, with the flag off. Each iteration calls
`chart.stop()` (not timed) and then `chart.update()` in the default mode, on the
`_AnimatedPlatform`. The figure is `update`, the median of 15 batches of the update and its
render. Control cells: the `chart.*` cases of section 6 at N 1000 (`CASES=chart`), with the
figures `update` (the update cases) and `draw` (all cases): 25 control cells, h* = 3. h is the
count of control cells whose interval lies wholly above 0. A large control hit has a lower end of
0.1 ms or more and of 5 % or more of the A mean.

The rule, written before the first run: side B lands when, on each deciding platform, the upper
end of each primary interval of B - A is below 0.1 ms, h is below h*, and no large control hit is
confirmed. Else side C lands by the same rule against A. Else the porting lead opens the item A11
(Chart.js ADR 0049 §7) again with the figures. Side C was not built in night 1. Thus the rule
sends the decision to the porting lead when side B does not land.

B - A, `update`, ms. The last column gives 0.1 ms as a share of the A mean:

| Platform | Cell | Pairs | A | B | Mean B - A | 95 % interval | Rel. | 0.1 ms of A |
|---|---|---:|---:|---:|---:|---|---:|---:|
| macOS | `motion.line` N 1000 | 12 | 7.769 | 7.771 | +0.0020 | -0.0277 .. +0.0310 | +0.03 % | 1.29 % |
| macOS | `motion.line` N 20000 | 12 | 157.737 | 157.878 | +0.1412 | -0.4666 .. +0.6946 | +0.09 % | 0.063 % |
| macOS | `motion.bar` N 1000 | 12 | 11.136 | 11.148 | +0.0119 | -0.0385 .. +0.0623 | +0.11 % | 0.90 % |
| macOS | `motion.bar` N 20000 | 12 | 235.963 | 236.161 | +0.1977 | -1.5096 .. +1.8798 | +0.08 % | 0.042 % |
| Pixel 8a | `motion.line` N 1000 | 2 | 14.233 | 15.241 | +1.0070 | -0.2010 .. +2.2150 | +7.07 % | 0.70 % |
| Pixel 8a | `motion.line` N 20000 | 5 | 305.190 | 309.894 | +4.7048 | -1.0960 .. +10.5056 | +1.54 % | 0.033 % |
| Pixel 8a | `motion.bar` N 1000 | 5 | 24.406 | 24.723 | +0.3170 | -0.4822 .. +1.1162 | +1.30 % | 0.41 % |
| Pixel 8a | `motion.bar` N 20000 | 6 | 519.703 | 522.163 | +2.4605 | -11.8863 .. +16.5572 | +0.47 % | 0.019 % |
| VS Code browser | `motion.line` N 1000 | 12 | 8.016 | 8.004 | -0.0124 | -0.1049 .. +0.0702 | -0.15 % | 1.25 % |
| VS Code browser | `motion.line` N 20000 | 12 | 158.322 | 156.723 | -1.5997 | -2.8254 .. -0.4102 | -1.01 % | 0.063 % |
| VS Code browser | `motion.bar` N 1000 | 12 | 11.197 | 11.218 | +0.0216 | -0.1276 .. +0.1730 | +0.19 % | 0.89 % |
| VS Code browser | `motion.bar` N 20000 | 12 | 227.772 | 226.820 | -0.9520 | -2.6416 .. +0.6999 | -0.42 % | 0.044 % |
| iPhone 17 Pro | `motion.line` N 1000 | 12 | 7.720 | 7.786 | +0.0658 | -0.5919 .. +0.7165 | +0.85 % | 1.30 % |
| iPhone 17 Pro | `motion.line` N 20000 | 12 | 162.405 | 164.498 | +2.0928 | -12.0936 .. +16.4039 | +1.29 % | 0.062 % |
| iPhone 17 Pro | `motion.bar` N 1000 | 12 | 11.868 | 12.011 | +0.1434 | -0.8836 .. +1.1733 | +1.21 % | 0.84 % |
| iPhone 17 Pro | `motion.bar` N 20000 | 12 | 278.471 | 277.775 | -0.6958 | -11.5797 .. +9.7715 | -0.25 % | 0.036 % |

Valid pairs and stage 2. macOS, the VS Code browser and the iPhone: 12 pairs, all valid. Stage 2
ran on each of them. Pixel 8a: pairs 1 to 8 ran, and the night end cut pairs 9 to 12. The window
rule and the user input of pair 2 leave 2 to 6 pairs in each primary cell. Only 10 of the 25
control cells have a valid pair.

Control screen: h = 4 on macOS, 0 in the VS Code browser, 1 on the Pixel 8a (one pair) and 2 on
the iPhone 17 Pro (h* = 3). The 4 hits of macOS are in the update cases: the `draw` figure of
`chart.b.line.update`, `chart.b.scatter.update` and `chart.bar.update`, and the `update` figure
of `chart.b.scatter.update`. Their means are 2.2 to 8.9 µs, and their lower ends are 0.9 to
4.6 µs. No platform has a large control hit, so no confirmation series ran.

The result of the rule: **side B does not land on any deciding platform.** On macOS, the upper
ends at N 20000 (+0.6946 and +1.8798 ms) are above 0.1 ms, and h = 4 is not below h* = 3. In the
VS Code browser, the upper ends of `motion.bar` (+0.1730 and +0.6999 ms) are above 0.1 ms. On the
Pixel 8a, each upper end is above 0.1 ms. The iPhone 17 Pro, an added platform, gives the same
result. But no primary interval lies wholly above 0 on any platform. The bound of 0.1 ms is 0.02
to 0.06 % of the A mean at N 20000, and the intervals at N 20000 are 1.2 to 28.5 ms wide. Thus
the rule asks for a resolution that the noise of the night does not give.

**The decision of the porting lead (2026-10-30).** The fallback of the rule sends the item A11
back to the porting lead. The porting lead opened A11 again and kept side B, the `Expando` read
of `reduced_motion.dart`. The reasons:
- The read is one `Expando` lookup in each `_createAnimations` call: a constant cost next to the
  loop over the keys of the call.
- No primary interval lies wholly above 0 on any platform.
- Side C changes a canvas class (a port-only field of `UiCanvasElement`, read through a type
  test) for a gain that no night can resolve.

The commit `feat(flutter_chartjs_port): honor reduced motion` landed side B. Chart.js ADR 0049 §7
and its Open 3 give the decision.

### 15.4 Observations of night 1

These facts do not change a decision.
- **The A-N3 data of the Pixel 8a.** The window rule kept few windows of the second run of each
  pair. In the control build (about 65 s for each run), the first run of a pair kept 7 to 16 of
  its 16 case windows, and the second run kept 0 to 5. The motion build holds the UI thread for a
  whole case. The system reported the focus ANR of protocol §5.4 ("Input dispatching timed out")
  in 13 of the 16 motion runs: in 12 of the 15 runs that gave `BENCH done`, and in the run that
  died. The rule keeps a run with an ANR. With each run with an ANR not valid (`runs-noanr.csv`
  of the protocol), no primary cell has a pair.
- **The VS Code browser, `hover-1000`.** `rasterP50Ms` is about 483 ms on both sides (A 482.978
  ms, B 484.192 ms), at 60.1 FPS. Thus this figure is not the raster time of one frame. The cause
  is not known. B - A is +1.2133 ms (-0.4642 .. +3.0617).
- **The VS Code browser, `doughnut-20000`.** B is faster in the p50 figures (build -3.4467 ms,
  raster -1.5542 ms) and gives 0.80 more frames each second (+0.6592 .. +0.9658). But
  `rasterP90Ms` of B is +43.1725 ms (+28.3642 .. +56.6833) above A (87.434 ms). Thus the two
  sides draw at a different frame cadence in this cell. The p90 figures do not decide.

### 15.5 The decisions of night 1

| Rule | Deciding platforms | Result | Consequence |
|---|---|---|---|
| A-N1, the overhead of `ChartView` (Chart.js ADR 0049 gate) | macOS, Pixel 8a, VS Code browser | PASS on each; the largest lower end is +0.0744 ms (Pixel 8a, `line-1000`, raster) | the gate figure of A-N1 is recorded; the caveats of section 15.2 stay, and a record run of the Pixel 8a without the accessibility service is open |
| A-N3, the read of the reduced-motion flag (Chart.js ADR 0049 §7) | macOS, Pixel 8a, VS Code browser | side B does not land on any platform (upper ends above 0.1 ms; h = 4 on macOS); side C not built; no primary interval wholly above 0 | the porting lead opened A11 again and kept side B (2026-10-30) |
| The added platform | iPhone 17 Pro | A-N1 PASS; A-N3 side B does not land (upper ends above 0.1 ms; h = 2) | figures only; no decision changes |

## 16. The typed internal model and the native draw path (phase 10)

Phase 10 changed two layers. The typed internal model
([Chart.js ADR 0054](adr/0054-typed-internal-model.md)) replaced the Map model with Dart classes:
the options, the parsed data, the element properties and the contexts. The native draw path
([Chart.js ADR 0055](adr/0055-native-draw-path.md)) added five forms to the canvas layer. Section
16.1 gives the method, and section 16.2 the new code against the old code. Sections 16.3 to 16.6
give the five speed fixes, the canvas A/B on the phones, the decisions and the open items. The raw
data, the scripts and the driver logs are working files of phase 10, not committed.

### 16.1 The method

The maintainer set lean rules for the measurements of phase 10 on 2026-10-31. Each series of this
section has two pairs for each cell: pair 1 runs A, then B, and pair 2 runs B, then A. No gate of
the quiet Mac applies, because the alternating order gives the load of the Mac to both sides. No
stage 2, no confirmation series and no independent recompute ran. A figure over 2 pairs shows a
direction only. The porting lead accepts a design record when its code passes the tests, and a
later measurement can still reject a change. Thus Chart.js ADRs 0054 and 0055 were accepted before
these figures.

**The speed series (sections 16.2 and 16.3).**
- Sides. A is `62b5477`, the `main` before phase 10. B is `0165c25`, the `main` with the typed
  internal model, the native draw path and the close step of Chart.js ADR 0054. The benchmark files
  differ in one line: the parameter type of the `notifyPlugins` override of the bench chart.
- Builds. Profile builds of the frameless benchmark (`apps/chartjs_gallery/lib/main_bench.dart`,
  section 6) with Flutter 3.47.8 (Dart 3.13.7), one at a time. The selector is
  `CASES=chart,chart.c.indexable,motion,plugins,tooltip,fill,legend,title`, with `BATCHES=15`,
  `BATCH_MS=200` and `WARMUP_MS=1000`: 107 cells. The driver compared the SHA-256 of each binary
  before each run.
- macOS: Apple M3 Max, macOS 27.0.1, AOT, a fresh process for each run with its window in front.
- Chrome: a dedicated Google Chrome 156.0.8078.79 with its own profile and the dart2wasm build. The
  page is 800 x 600 CSS px at DPR 2, cross-origin isolated, with `about:blank` before each run.
- Metric. As in section 14.9: `draw+end` for a draw cell, `update+draw+end` for an update or a
  frame cell, and `update` for a motion cell. The run value is the median of 15 batches.
- Valid pairs. On macOS, pair 1 is not usable. In its A run, the app window was in front in 9 of
  1180 checks. The median ratio of these A values to the A values of pair 2 is 5.6. Thus the macOS
  figures come from pair 2 only, whose two runs had the window in front in each check. In Chrome,
  both pairs are valid. Other processes loaded the Mac during the Chrome runs (a 1-minute load of
  10.5 to 27.4 after the runs).

**The fix checks (section 16.3).** macOS profile builds with Flutter 3.47.8. A scratch profiling
entry calls `runChartBenchCase` of the same benchmark file with the same batch settings. Each check
runs the old code, the build before the fix and the build with the fix in turn, 2 or 3 times. After
the fifth fix, one pair ran all 107 cells: the old code, then the new code.

**The canvas A/B (section 16.4).** A is `62b5477`. B is `f3a79e7`, the tip of the canvas branch.
The trees differ only in `packages/flutter_chartjs_port/lib/src/canvas/` (3 files, +718/-124). The
rule is §7.6 of [canvas-cuts-plan.md](canvas-cuts-plan.md) with the lean rules above. Its selector
has 103 cells: 18 primary cells, 9 guard cells and 76 control cells. A cell is GAIN when the upper
end of its 95 % interval lies below 0. It is REGRESSION when the lower end lies above the larger of
0.1 ms and 2 % of A. Else it is NEUTRAL. The interval is the percentile bootstrap of section 14.9
over the 2 pair differences. A cell whose interval lies wholly above 0 is a possible regression,
not confirmed. The raster check runs the stress entry 2 times for each side, A B A B, 7 s each. It
fails when the median `rasterMs` of B is above A by more than the larger of 0.1 ms and 2 %. It also
fails when the median FPS of B is more than 1 FPS below A.
- Pixel 8a: Android 17 (`CP3A.260905.009`), profile APKs with Flutter 3.47.7 on both sides, a 3 A
  charger, the temperature gate of section 15.1 for at most 60 s, the window rule of section 13.6.
- iPhone 17 Pro: iOS 26.6.2, on the cable, profile builds with Flutter 3.47.8 on both sides. It has
  no gate, because `devicectl` gives no thermal state.

### 16.2 The new code against the old code (before the speed fixes)

On macOS (pair 2), 47 of the 107 cells are faster by more than 5 %, and 37 are slower by more than
5 %. In Chrome, with more than 5 % in both pairs, 44 cells are faster and 27 cells are slower. The
table gives the main cells in ms. The macOS columns give the A run and the B run of pair 2. The
Chrome columns give the mean of the two runs of each side, and the change of each pair in brackets.

| Cell | macOS A | macOS B | macOS | Chrome A | Chrome B | Chrome (pair 1, pair 2) |
|---|---:|---:|---:|---:|---:|---|
| `chart.a` line draw, N 20000 | 4.414 | 3.918 | -11.2 % | 4.5680 | 4.1830 | -8.4 % (-9.0, -7.9) |
| `chart.bar` draw, N 5000 | 9.748 | 7.992 | -18.0 % | 5.2370 | 2.8810 | -45.0 % (-44.4, -45.5) |
| `chart.doughnut` draw, N 1000 | 2.860 | 2.446 | -14.5 % | 2.8510 | 2.1090 | -26.0 % (-25.6, -26.4) |
| `chart.pie` draw, N 5000 | 19.534 | 12.763 | -34.7 % | 12.6105 | 8.9800 | -27.6 % (-14.6, -40.6) |
| `chart.c` line update, N 20000 | 101.367 | 80.787 | -20.3 % | 104.4520 | 73.5600 | -29.6 % (-29.1, -30.1) |
| `chart.b` line update, N 1000 | 0.609 | 1.161 | +90.6 % | 0.6090 | 0.8995 | +47.7 % (+46.7, +48.7) |
| `chart.polarArea` update, N 100 | 0.476 | 0.854 | +79.4 % | 0.4945 | 0.6535 | +32.6 % (+40.3, +24.9) |
| `chart.radar` draw, N 1000 | 0.430 | 0.545 | +26.7 % | 0.4870 | 0.5435 | +11.8 % (+16.0, +7.5) |
| `plugins.line` update, config A, 100 datasets, N 100 | 13.447 | 32.358 | +140.6 % | 14.4225 | 24.5980 | +70.9 % (+63.9, +77.8) |
| `legend.line` update, legend on, N 100 | 1.240 | 3.015 | +143.1 % | 1.2615 | 2.4080 | +90.8 % (+88.2, +93.5) |
| `legend.line` update, legend on, N 1000 | 4.990 | 8.970 | +79.8 % | 5.6155 | 7.8335 | +39.5 % (+44.1, +34.9) |
| `fill.gaps` update, N 100 | 0.670 | 1.708 | +154.9 % | 0.8275 | 1.4875 | +79.7 % (+72.2, +87.3) |
| `fill.radar` draw, N 1000 | 0.439 | 0.623 | +41.9 % | 0.5490 | 0.7370 | +34.2 % (+34.7, +33.8) |
| `motion.line`, N 1000 | 8.182 | 17.308 | +111.5 % | 9.0595 | 12.7195 | +40.4 % (+49.8, +30.9) |
| `motion.bar`, N 20000 | 249.081 | 409.656 | +64.5 % | 251.5250 | 307.8535 | +22.4 % (+31.2, +13.6) |

The observations:
- The draws of the bar, the doughnut, the pie, the polar area and the line points are faster. They
  gain 9 to 35 % on macOS and 7 to 47 % in Chrome. The `chart.c` updates and the large bar and
  bubble updates are faster too.
- The regressions are in the update path. They hit the line charts with real scales, a legend, a
  title or a fill. They also hit the animated updates (`motion`), the radar and the small `chart.b`
  and polar area updates.
- The small cells regress most in %. The added time grows much less than N. On macOS,
  `legend.line` update with the legend adds 1.775 ms at N 100 and 3.980 ms at N 1000. This points
  to a cost for each update or each option read, not for each data item.
- The speed series measures both changes together. Section 16.4 separates the canvas forms.

### 16.3 The causes and the five speed fixes

A CPU profile of the slow cells on macOS found five causes. Each fix is one commit on `main` after
`0165c25` (`0165c25..8a4b461`, pushed on 2026-10-31). AOT micro-benchmarks gave the unit costs.

| Commit | The cause | The fix |
|---|---|---|
| `fae9c8a` | `optionKeyOf` was a switch over 339 string constants. The VM compares the names one by one: about 285 ns for each lookup. Each read by name of a typed scope paid it. In `legend.line` update at N 100, these comparisons took 31 % of the samples. | A hashed `Map` from the JS name to the key: about 6.5 ns for each lookup. |
| `b4bd7d2` | The resolver cache scanned its key list at each read. The cache of a scale has dozens of keys, and the radial scale reads `startAngle` and `reverse` for each point. In `chart.radar` draw at N 1000, the scan took 22 % of the samples. | A cache of more than 8 keys also keeps a `Map` of the key positions. |
| `8caf131` | The generator wrote the dispatches on an `OptionKey` or a `ScopeKind` as switch expressions. The VM compiles them to one comparison for each case, in order. In `fill.radar` draw at N 1000, `rawOption` took 22 % of the samples. | Switch statements, which the VM compiles to a jump table: `isPresent` 5.4 to 2.0 ns, `rawOption` 7.1 to 4.1 ns. |
| `663c96a` | `_pathSegment` read `stepped` of each point through `rawOption`, with a dispatch on the key. In `fill.radar` draw at N 1000, `rawOption` had 16 % of the self time. | The getter `LineOptions.steppedValue` gives the same raw value with no dispatch. |
| `8a4b461` | The position `Map` of the cache hashes the enum constant: about 6 ns for each read. | A `Uint16List` at `OptionKey.index`: about 1 ns. A `Map` keeps the names that are not keys. |

Chart.js ADR 0054 calls `optionKeyOf` a switch. The accepted ADR does not change, because the form
of the lookup is an implementation detail.

The check of each fix, in ms (`update+draw+end`), one value for each pass of the three builds:

| Fix | Cell | Old code | Before the fix | With the fix |
|---|---|---|---|---|
| `fae9c8a` | `legend.line` update, legend on, N 100 | 1.418, 1.275 | 2.809, 2.837 | 1.245, 1.229 |
| `fae9c8a` | `motion.line`, N 1000 | 8.311, 7.714 | 15.351, 14.679 | 6.448, 6.027 |
| `b4bd7d2` | `chart.radar` draw, N 1000 | 0.432, 0.418 | 0.590, 0.540 | 0.453, 0.450 |
| `b4bd7d2` | `fill.radar` update, N 1000 | 3.063, 2.924 | 2.351, 2.335 | 2.050, 1.996 |
| `8caf131` | `fill.radar` draw, N 1000 | 0.443, 0.441, 0.458 | 0.526, 0.526, 0.524 | 0.502, 0.507, 0.506 |
| `663c96a` | `fill.radar` draw, N 1000 | 0.468, 0.473 | 0.526, 0.539 | 0.514, 0.521 |
| `8a4b461` | `chart.radar` update, N 1000 | 1.388, 1.454 | 1.052, 1.051 | 0.992, 0.950 |
| `8a4b461` | `legend.line` update, legend on, N 1000 | 5.059, 5.237 | 4.731, 4.261 | 4.464, 4.372 |

After the fifth fix, one pair ran all 107 cells on macOS: the old code `62b5477`, then the new code
`8a4b461`. 103 cells are faster than the old code, and 4 cells are slower. The column "Before the
fixes" gives the macOS change of pair 2 of section 16.2. The other columns are in ms.

| Cell | Before the fixes | Old code | New code | Change |
|---|---:|---:|---:|---:|
| `chart.b` line update, N 1000 | +90.6 % | 0.614 | 0.480 | -21.8 % |
| `chart.radar` update, N 1000 | +25.3 % | 1.454 | 0.997 | -31.4 % |
| `plugins.line` update, config A, 100 datasets, N 100 | +140.6 % | 13.699 | 11.231 | -18.0 % |
| `legend.line` update, legend on, N 100 | +143.1 % | 1.416 | 1.217 | -14.1 % |
| `fill.gaps` update, N 100 | +154.9 % | 0.753 | 0.749 | -0.5 % |
| `motion.line`, N 1000 | +111.5 % | 9.333 | 6.362 | -31.8 % |
| `motion.bar`, N 20000 | +64.5 % | 325.008 | 249.906 | -23.1 % |
| `chart.c` line update, N 20000 | -20.3 % | 99.899 | 58.044 | -41.9 % |
| `fill.radar` draw, N 100 | +26.9 % | 0.077 | 0.079 | +2.6 % |
| `fill.radar` draw, N 1000 | +41.9 % | 0.560 | 0.601 | +7.3 % |
| `fill.gaps` draw, N 100 | +3.1 % | 0.262 | 0.270 | +3.1 % |
| `fill.stack` update, N 100 | +101.7 % | 1.214 | 1.378 | +13.5 % |

The tooltip cells are 4.5 to 17.2 % faster, and the draw gains of section 16.2 stay. The last four
rows are the slower cells. In the check of `8a4b461`, `fill.radar` draw at N 1000 gives +12.9 % and
+5.9 % against the old code. Thus `fill.radar` draw stays 3 to 13 % slower. `fill.stack` update at
N 100 has one pair after the fixes.

### 16.4 The native draw path on the phones (Chart.js ADR 0055)

Chart.js ADR 0055 has five forms. The recording canvas saves its state only for a clip, and a fill
of a shape with no area makes no draw call. The path builder defers the native path. A circular
sector gets `drawArc`, and a short circle run takes a color for each circle.

**The iPhone 17 Pro.** The bench pairs ran back to back, from 04:47 to 05:16 CET. All 4 bench runs
and all 20 raster runs are valid. Primary cells: 11 GAIN, 7 NEUTRAL, no REGRESSION. Guard cells: 9
NEUTRAL. Control cells: 8 GAIN, 68 NEUTRAL, no REGRESSION. The intervals of h = 10 control cells
lie wholly above 0 (h* = 5). No control cell has a lower end of 0.1 ms and 5 % of A. B - A, ms:

| Cell | Role | A | B - A | Rel. | 95 % interval | Class |
|---|---|---:|---:|---:|---|---|
| `chart.pie` draw, N 5000 | primary | 18.4610 | -4.1900 | -22.7 % | -4.9770 .. -3.4030 | GAIN |
| `chart.polarArea` draw, N 5000 | primary | 16.9105 | -1.6190 | -9.6 % | -2.5290 .. -0.7090 | GAIN |
| `chart.bar` draw, N 5000 | primary | 8.8625 | -0.7935 | -9.0 % | -1.5170 .. -0.0700 | GAIN |
| `chart.c.indexable` update, N 20000 | primary | 100.4830 | -16.6280 | -16.5 % | -17.8640 .. -15.3920 | GAIN |
| `chart.a` draw, N 20000 | guard | 3.9290 | +0.1570 | +4.0 % | -0.0200 .. +0.3340 | NEUTRAL |
| `chart.doughnut` draw, N 1000 | primary | 2.6140 | +0.1610 | +6.2 % | +0.0810 .. +0.2410 | NEUTRAL |
| `chart.doughnut` update, N 1000 | control | 3.6175 | +0.1175 | +3.2 % | +0.0500 .. +0.1850 | NEUTRAL |
| `chart.radar` draw, N 1000 | guard | 0.4310 | +0.0115 | +2.7 % | +0.0010 .. +0.0220 | NEUTRAL |
| `chart.radar` draw, N 5000 | control | 2.1185 | +0.0980 | +4.6 % | +0.0060 .. +0.1900 | NEUTRAL |
| `chart.radar` update, N 1000 | control | 1.3425 | +0.0365 | +2.7 % | +0.0030 .. +0.0700 | NEUTRAL |
| `chart.radar` update, N 5000 | control | 6.5820 | +0.2700 | +4.1 % | +0.1170 .. +0.4230 | NEUTRAL |
| `fill.radar` draw, N 100 | control | 0.0675 | +0.0035 | +5.2 % | +0.0010 .. +0.0060 | NEUTRAL |
| `fill.radar` draw, N 1000 | control | 0.4565 | +0.0255 | +5.6 % | +0.0210 .. +0.0300 | NEUTRAL |
| `fill.radar` update, N 1000 | control | 2.9260 | +0.0590 | +2.0 % | +0.0110 .. +0.1070 | NEUTRAL |
| `fill.gaps` draw, N 100 | control | 0.2270 | +0.0075 | +3.3 % | +0.0030 .. +0.0120 | NEUTRAL |
| `fill.gaps` draw, N 1000 | control | 6.0215 | +0.1400 | +2.3 % | +0.1190 .. +0.1610 | NEUTRAL |
| `tooltip.fade`, 3 datasets, N 1000 | control | 1.0970 | +0.0270 | +2.5 % | +0.0180 .. +0.0360 | NEUTRAL |

The last 12 rows are the possible regressions: their intervals lie wholly above 0, and 2 pairs do
not confirm them. Most of them draw long filled paths: the radar, the fills and the doughnut ring.
The plain line (`chart.a`, points only) is NEUTRAL at +3.7 to +4.0 %, and each interval includes 0.

The raster check on the iPhone passes in each cell (medians of the 2 runs of each side). At N 1000
both sides run at 120 FPS, the display limit, and `rasterMs` changes by +3.7 % (bar) to -28.2 %
(polar area). At N 5000:

| Type | FPS A | FPS B | UI build B - A | `rasterMs` A | `rasterMs` B |
|---|---:|---:|---:|---:|---:|
| bar | 63.39 | 74.52 | -2.1 % | 1.61 | 1.69 |
| doughnut | 59.52 | 60.11 | -5.7 % | 8.45 | 4.76 |
| pie | 46.95 | 60.07 | -19.4 % | 7.02 | 4.52 |
| polar area | 54.01 | 59.97 | -12.0 % | 7.75 | 4.71 |
| line, scriptable colors, update | 39.95 | 45.85 | -19.6 % | 5.83 | 0.48 |

**The Pixel 8a.** The bench ran from 00:57 to 02:32 CET, with a pause of the maintainer from 01:21
to 02:23. The phone throttled while it charged. The battery was at 34.1 to 38.2 °C, and the median
clock of a case window was 1.16 to 2.91 GHz. The window rule left 2 cells with a valid pair, so
the bench has no class. Single pairs whose two sides have median clocks within 10 % give a
direction only. Doughnut draw at N 1000 is -30.8 %, and pie draw is -16.4 % at N 100 and -23.2 %
at N 5000. `chart.c.indexable` update at N 20000 is -27.4 %, and radar update at N 5000 is
-20.8 %. Bar draw at N 1000 is +0.1 %. `chart.a` draw in pair 2 is +6.0 to +11.8 %.

The `chart.a` figure has a confound. The B run of pair 2 started at 01:13 at 38.2 °C, and the A
run at 02:24 at 34.1 °C. A code reading found less work for each point in B: no
`ui.Path.reset()` call and no cos or sin. On the iPhone, whose pairs ran back to back, `chart.a`
is NEUTRAL.

The raster check on the Pixel 8a, medians of the 2 runs of each side:

| Type | N | FPS A | FPS B | UI build B - A | `rasterMs` A | `rasterMs` B | Check |
|---|---:|---:|---:|---:|---:|---:|---|
| bar | 1000 | 45.03 | 50.88 | -18.2 % | 9.67 | 8.37 | pass |
| bar | 5000 | 29.39 | 29.51 | -7.6 % | 19.68 | 20.45 | FAIL (`rasterMs` +4.0 %) |
| doughnut | 1000 | 48.23 | 51.98 | -1.5 % | 15.04 | 12.77 | pass |
| doughnut | 5000 | 15.84 | 16.75 | -18.6 % | 45.39 | 50.39 | FAIL (`rasterMs` +11.0 %) |
| pie | 1000 | 53.83 | 55.47 | -4.2 % | 13.74 | 12.00 | pass |
| pie | 5000 | 14.04 | 18.40 | -23.2 % | 58.48 | 45.48 | pass |
| polar area | 1000 | 54.42 | 55.31 | -0.8 % | 13.46 | 12.12 | pass |
| polar area | 5000 | 15.36 | 17.95 | -22.4 % | 46.61 | 47.41 | pass |
| line, scriptable colors, update | 5000 | 15.82 | 19.45 | -19.7 % | 36.16 | 8.16 | pass |

The FPS rose in each cell, and the UI build time fell in each cell. At N 5000, the raster time rose
for the doughnut (+5.0 ms), the polar area (+0.80 ms) and the bar (+0.78 ms). The doughnut and the
bar fail the check by its rule, and the polar area stays below its limit of 2 %. At N 5000, the
raster time of the doughnut (50.39 ms) is now above its UI build time (39.56 ms).

The decision of the porting lead after the Pixel 8a run (2026-10-31): the five forms stay. Chart.js
ADR 0055 was accepted when the merged code passed the tests, by the lean rule. A later measurement
on macOS or in Chrome can still reject a form.

### 16.5 The decisions

| Series | Platforms | Result | Consequence |
|---|---|---|---|
| The new code against the old code, before the fixes | macOS (pair 2), Chrome | The draws are faster: -9 to -35 % on macOS, -7 to -47 % in Chrome. Many updates are slower: up to +154.9 % on macOS and +103.2 % in Chrome. | A CPU profile and the five speed fixes of section 16.3 |
| The five speed fixes | macOS | 103 of 107 cells are faster than the old code in one pair. `fill.radar` draw stays 3 to 13 % slower. | The fixes are on `main` (`0165c25..8a4b461`). Chrome was not measured again. |
| The native draw path | iPhone 17 Pro | 11 GAIN and 7 NEUTRAL of 18 primary cells, no REGRESSION, h = 10 (h* = 5). The raster check passes. | Figures only. The 12 possible regressions stay open. |
| The native draw path | Pixel 8a | No bench class (the window rule). The FPS rose in each raster cell. The raster check fails at doughnut and bar, N 5000. | The five forms stay. Chart.js ADR 0055 is accepted. |

### 16.6 Open

1. **Chrome after the speed fixes.** Chrome ran only the code before the fixes (section 16.2). A
   2-pair run of the old code against the current `main` waits for a free Mac.
2. **The fill draws on macOS.** `fill.radar` draw stays 3 to 13 % slower than the old code.
   `fill.gaps` draw at N 100 is +3.1 %. `fill.stack` update at N 100 is +13.5 % in one pair and
   needs a check.
3. **The possible regressions of the canvas forms on the iPhone** (the radar, the fills, the
   doughnut at N 1000 and the tooltip fade). The canvas work proposed three cleanups of the path
   builder. They are a test of `_built` before `_circle` in `_direct()`, plain fields for the
   current point and a narrower copy in `closePath`. Then a 2-pair check of the radar, the fills
   and the doughnut at N 1000 follows. On the iPhone, the canvas forms alone give `fill.radar` draw
   +5.6 % at N 1000. Thus it is possible that item 2 has the same cause.
4. **The canvas forms alone on macOS and in Chrome.** The canvas A/B ran on the phones only. The
   speed series measures the forms together with the typed model. The Pixel 8a bench has no class.
5. **The accessibility path.** The maintainer took the accessibility measurement out of phase 10
   on 2026-10-30. No figure exists for the semantics path.

<a id="chapter-17"></a>

<details>
<summary>17. Color parsing across Flutter 3.44 and 3.47</summary>

## 17. Color parsing across Flutter 3.44 and 3.47

Investigation of 2026-10-31, at repository commit `b752133`. This concerns the ported
`kurkle_color`, not the colors plugin or the Flutter renderer. The initial investigation
changed no production code; section 17.5 records the subsequent implementation.

### 17.1 Scope and measurements

The same current `lib/src/kurkle_color/` and `lib/src/js/` sources were copied to a scratch
package and compiled with Dart 3.12.2 (Flutter 3.44.9), 3.13.5 (Flutter 3.47.7) and 3.13.7
(Flutter 3.47.8). The scratch package used language version 3.12 on every side, so the
comparison changes the SDK, not the source or language version. It does not lower the
workspace's published SDK floor. The benchmark copies the seven color cases and the harness
from `tool/bench/`. Its hover case calls the same parse/saturate/darken/hex-string sequence
directly, without the canvas pattern/gradient type checks.

Machine: Apple M3 Max, arm64, macOS 27.0.1. Runtime: Node.js 24.22.1, V8 13.6.233.17-node.58.
Compilation: `dart compile wasm -O2`; the control is `dart compile js -O4`. Each Wasm process
warms a case for 400-500 ms, then measures 15 batches of 30-50 ms. Runs are sequential, in
alternating SDK order. These are web-target CPU measurements in Node, not Chrome frame or
rendering measurements. Browser automation was unavailable in this session. Absolute times
and the size of the regression still need confirmation in the affected browser/build.

The table uses the median of the first three complete runs per SDK (two for 3.13.5), in ns
per operation. The JavaScript control uses two runs per SDK with the harness defaults.

| Case | Dart 3.12.2 Wasm | Dart 3.13.5 Wasm | Dart 3.13.7 Wasm |
|---|---:|---:|---:|
| Parse `#ff6384` | 147.434 | 168.864 | 175.783 |
| Parse RGBA string | 828.146 | 812.128 | 824.424 |
| Parse HSL string | 738.800 | 750.920 | 740.306 |
| Parse named color | 139.587 | 148.347 | 143.990 |
| `rgbString` | 115.919 | 114.180 | 114.414 |
| `clone().mix(...)` | 60.756 | 60.944 | 60.462 |
| RGBA hover sequence | 1179.596 | 1180.759 | 1183.160 |

The repeatable regression is hex parsing: **19.2% more time** on 3.13.7. The dart2js hex
control is 98.420 ns on 3.12.2 and 96.894 ns on 3.13.7. The measurements do not support a
general slowdown of every color operation. An isolated six-digit map-lookup case also slows
from 109.410 to 133.566 ns, while string indexing, string hashing and `jsToInt32` do not slow
in that probe. Timings vary with the surrounding compiled program and input distribution.

### 17.2 Cause and causal check

`lib/src/kurkle_color/hex.dart` decodes each digit with `_map[str[i]]`. A six-digit color
does six string-keyed map lookups. Dart commit
[`ab3c67ff886`](https://github.com/dart-lang/sdk/commit/ab3c67ff8865c7569b0ead686f0f5eef941e2ec7)
(2026-06-30, present in 3.13.5 and 3.13.7) changes the VM/Wasm hash table's equality order
from `_equals(key, _data[d])` to `_equals(_data[d], key)`. This is a correctness fix for
[Dart issue 63681](https://github.com/dart-lang/sdk/issues/63681): equality belongs to the
stored key. It also changes the hot path of this color parser.

The generated Wasm map lookup has this operand-order difference. To test its effect without
changing the compiler, optimization settings, module layout or parser, a diagnostic script
changes exactly five operand bytes in the compiled `_OperatorEqualsAndHashCode._equals`
function. It swaps the two parameter reads; module size and every other byte stay unchanged.
This reverses the map equality order for this probe. It is **not a production SDK patch**:
reversing equality globally would undo the correctness fix for asymmetric user equality.

| Diagnostic binary | Hex parse, ns/op |
|---|---:|
| Dart 3.13.7, unchanged, A/B/B/A baseline runs | 172.084, 172.874 |
| Same binary, equality order reversed | 144.594, 145.156 |
| Dart 3.12.2, unchanged | 139.014 |
| Same old binary, changed to the new equality order | 179.979 |

Thus the SDK equality-order change causes the measured regression on this Wasm/V8 path.
The reverse experiment also makes the old binary slower. This identifies the triggering SDK
change; it does not establish which lower-level V8 optimization or string representation
accounts for the asymmetric cost. No claim of a measured browser frame-rate loss follows
from these nanosecond figures.

### 17.3 Fix options

1. **Decode hex digits from character codes (recommended).** Replace the private `_digit`
   string/map lookup with `codeUnitAt` and ASCII range checks for `0-9`, `A-F`, and `a-f`.
   Keep `double.nan` for every other code unit, and keep the remaining parser arithmetic.
   A scratch candidate measures 23.29 ns per hex parse on Dart 3.13.7 (median of two runs),
   about 7.5 times faster than the present implementation and faster than the old SDK.
   A direct comparison of the original and candidate parsers passes **1,426,256 cases**:
   every UTF-16 code unit in each digit position of lengths 3, 4, 6 and 8, plus 50,000
   deterministic strings. It compares raw RGBA channels, including NaN and signed zero.
   A separate varied-input run, which consumes channel values instead of just `valid`,
   measures 34.389 ns for `hexParse` and 31.809 ns for `Color(...).rgb.r`. This supports a
   gain beyond the constant-input benchmark, though it is only one run.
   Invalid-hex behavior must stay: this parser does not simply reject all invalid digits.
   Section 17.5 records the implementation, the VM and web tests, and the structural
   adaptation. A varied-input performance measurement in the affected browser remains
   useful; the recorded speed measurements here use Node/V8.
2. **Report the minimal map-lookup regression upstream.** Preserve the stored-key equality
   semantics and ask for a Wasm/compiler/runtime optimization. The same-binary experiments
   provide a useful reproducer. No issue was submitted during this investigation, and no
   fixed SDK version has been verified.
3. **Use dart2js as a deployment workaround if application measurements support it.** This
   probe shows no corresponding dart2js regression. It is a whole-application build choice;
   measure chart update and rendering performance before selecting it.

Downgrading Flutter is not the preferred fix: this workspace requires Dart `^3.13.0` and
Flutter `>=3.47.0`. Caching can avoid repeated parsing, but the animation path already caches
its endpoint colors (Chart.js ADR 0019), and `Color` is mutable, so returning a shared cached
instance would change behavior. Do not replace the parser with `int.parse` without preserving
its invalid-digit semantics, or replace the mixing algorithm with Flutter `Color.lerp`.

### 17.4 Evidence and earlier notes

The working evidence is `.handover/kurkle-web-regression/` at the repository root: source
snapshots, benchmark and equivalence probes, JSON timing logs, the five-byte diagnostic
patcher, and a reproduction script. `.handover/` is local working evidence, not a committed
artifact. The initial SDK checkout and builds are under `/private/tmp/flutter-web-regression/`.

No previous note specifically identifying a 3.44-to-3.47 `kurkle_color` regression was found
in the committed docs, saved handovers or project memory. Chart.js ADR 0019 §5 and its
Evidence section do record an earlier color cost: on Dart 3.12.2, caching parsed endpoints
reduces an animation color tick from 1460-1732 ns to 250-310 ns in Wasm. That is a different
comparison and predates this SDK regression.

### 17.5 Implementation and verification

Implemented on 2026-10-31: `_digit` reads the UTF-16 code unit, checks the three ASCII
ranges and returns NaN for every other value. The string-keyed `_map` is removed. All
remaining hex parsing and serialization arithmetic stays unchanged. The adaptation is
`adapt-kurkle-hex-code-units` in `differences.md`; `status.yaml` and generated `parity.md`
record it.

The added `index.esm_test.dart` group checks all 65,536 UTF-16 code units in short alpha
against the upstream digit alphabet, all four supported hex lengths with mixed-case
digits, invalid high and low nibbles, and a surrogate pair in a short RGB string. The
explicit examples were also checked against the pinned JavaScript source in Node.

Verification on Flutter 3.47.8 / Dart 3.13.7:
- The focused kurkle and color-helper tests: 130 passed on the VM and 260 passed across
  headless Chrome with dart2js and dart2wasm.
- The spec suite passed with its existing 78 skips, excluding fixtures. Its JSON results
  regenerated `parity.md`; the generator's check mode passed with the same results.
- Workspace analysis with fatal infos, formatting of both changed Dart files, and
  `git diff --check` passed.
- All seven port checks passed: imports, headers, JS semantics, port order, parity,
  typed reads and generated options.

The applied production source was recompiled with `dart compile wasm -O2`. Its comparison
uses the saved original source, the same Dart 3.13.7 compiler and language version 3.13
on both sides, the same harness, and Node/V8 as in section 17.1. Four sequential runs in
before/after/after/before order, each with 500 ms warm-up and 15 batches of 50 ms, gave:

| Hex parse | Run medians, ns/op | Median, ns/op |
|---|---|---:|
| Original map decoder | 158.827, 164.030 | 161.429 |
| Applied character-code decoder | 23.269, 23.272 | 23.271 |

The applied decoder takes 85.6% less time (about 6.9 times faster) in this isolated check.
The raw results are `raw/implementation-*.jsonl` in the working evidence directory. This
does not measure whole-chart frame time or browser performance.

</details>

<a id="chapter-18"></a>

<details>
<summary>18. Color decoder gain across platforms</summary>

## 18. Color decoder gain across platforms

Measured on 2026-10-31 after implementing section 17. This compares the original string-keyed
map decoder with the applied character-code decoder, on the **same Dart 3.13.7 SDK** on each
side. It measures the fix, not another SDK upgrade. The two source sets differ only in
`kurkle_color/hex.dart`; the scratch package rewrites the package import prefix equally on
both sides. The library and gallery in the working tree were not changed for this series.

### 18.1 Protocol and scope

The scratch suite has 13 cases. Its main parsing cases select among several input strings
and consume all four channels from `Color(input).rgb`. Thus they include construction,
parsing, the RGBA copy and alpha conversion; they are not the constant-input `valid` check
of section 17. The constant-input check is also kept as a separate microbenchmark. All
inputs are valid colors. The suite also measures RGBA/HSL/name parsing, `rgbString`, mixing
cached parsed colors, parsing and mixing two hex colors followed by `hexString`, and the
hover sequence (parse, saturate, darken, hexString) for hex and RGBA inputs.

- Four fresh processes per target: before, after, after, before. Each case warms for 400 ms
  and then runs 15 batches targeting 30 ms each. A process reports the median batch time;
  the tables use the median of the process medians for each side. Each operation returns
  a checksum consumed by the harness. Builds and measured processes do not run together.
- Chrome and Firefox Wasm received one additional before/after pair after one process on
  each browser showed a slowdown in unchanged controls. Those results are included, not
  substituted for the noisy runs: three process medians per side on these two targets.
  Other targets have two. This is a small repeated measurement, not a confidence-interval
  study; small differences in the controls are not established regressions or gains.
- macOS: Apple M3 Max, macOS 27.0.1, standalone `dart compile exe` AOT. The windowed Flutter
  attempt paused while awaiting a frame when its window became hidden; that incomplete
  series is excluded. The CLI runs have no dependency on window visibility.
- Android: Pixel 8a, Android 17, Flutter 3.47.8 **release AOT**, foreground benchmark app.
  Battery temperature was 28.0-28.1 °C across the four runs, with USB power. No CPU-frequency
  gate was applied. Only this separate benchmark app was installed and launched.
- iOS: iPhone 17 Pro, iOS 26.6.2, Flutter 3.47.8 **release AOT**, unlocked before and after
  each run. Every case records `AppLifecycleState.resumed`. Results are written outside the
  timed loop to the benchmark app's own temporary file and copied back with `devicectl`;
  release console capture did not deliver the Dart records. No thermal telemetry is available.
- Linux: official `dart:3.13.7-sdk` arm64 image, LinuxKit 7.0.14 in Docker Desktop on the same
  Mac, standalone AOT. This is a **virtualized Linux result**, not a separate physical Linux
  machine. Both sides use the same container environment and collection 1.19.1.
- Web: Chrome 156.0.8078.79 and Firefox 158.0.1 on the Mac. Explicitly precompiled test
  wrappers use `dart compile js -O4` and `dart compile wasm -O2`, without assertions.
  `package:test` only launches browsers and transports results. Its default Wasm test
  compiler uses `-O0` with assertions and is not used for these measurements. One initial
  Firefox JS launch exited before connecting; the successful complete retry is measured.

### 18.2 Main operation timings

Times are ns per operation. Speedup is before / after; greater than 1 is faster. Compare
before and after within a row, not absolute speed across different machines or runtimes.

| Target | Varied six-digit hex + RGBA, before → after (ns) | Speedup | Parse + mix hex speedup | Hex hover speedup |
|---|---:|---:|---:|---:|
| macOS arm64 AOT | 100.8 → 59.6 | 1.69x | 1.20x | 1.07x |
| Pixel 8a / Android 17 | 182.2 → 95.6 | 1.91x | 1.25x | 1.08x |
| iPhone 17 Pro / iOS 26.6.2 | 99.6 → 55.1 | 1.81x | 1.33x | 1.12x |
| Linux arm64 AOT / Docker VM | 104.9 → 59.8 | 1.75x | 1.25x | 1.11x |
| Chrome 156 / dart2js | 156.9 → 81.5 | 1.93x | 1.47x | 1.12x |
| Chrome 156 / dart2wasm | 134.1 → 42.0 | 3.20x | 1.99x | 1.25x |
| Firefox 158 / dart2js | 132.2 → 98.7 | 1.34x | 1.34x | 1.04x |
| Firefox 158 / dart2wasm | 366.2 → 97.7 | 3.75x | 2.42x | 1.37x |

### 18.3 All 13 cases

Percent of time saved, `100 × (before - after) / before`. Negative values mean an observed
slowdown. The unaffected operations are controls; there is no reason to expect the hex
change to speed up cached mixing, RGB formatting or non-hex parsing. The earlier roughly
7x result is a different, constant-input `valid`-only microbenchmark, not a whole-library
speedup. No figure here measures chart frame rate, GPU work, or a warm color-cache hit.

| Case | macOS AOT | Android | iOS | Linux VM | Chrome JS | Chrome Wasm | Firefox JS | Firefox Wasm |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `hex6_constant_valid` | +44.2% | +52.1% | +50.2% | +46.4% | +45.6% | +75.9% | +16.9% | +76.0% |
| `hex3` | +27.3% | +37.3% | +32.7% | +30.5% | +34.0% | +52.4% | +27.0% | +62.0% |
| `hex4` | +31.3% | +39.5% | +34.6% | +35.8% | +42.9% | +57.6% | +24.7% | +68.8% |
| `hex6` | +40.9% | +47.5% | +44.7% | +43.0% | +48.1% | +68.7% | +25.4% | +73.3% |
| `hex8` | +44.2% | +49.0% | +45.4% | +46.3% | +46.0% | +70.2% | +32.7% | +74.1% |
| `parse_mix_hex` | +16.9% | +19.9% | +24.6% | +19.7% | +31.8% | +49.7% | +25.3% | +58.8% |
| `hover_hex` | +7.0% | +7.3% | +10.8% | +9.6% | +10.9% | +20.0% | +4.3% | +27.1% |
| `rgba` | +0.6% | -1.6% | -0.1% | +0.7% | -0.2% | -1.0% | +0.0% | +0.0% |
| `hsl` | -0.6% | -2.2% | -2.0% | +1.2% | +1.1% | +0.1% | -0.6% | +1.4% |
| `name` | -0.0% | -0.9% | -1.6% | +2.3% | +2.1% | -1.4% | +0.8% | +0.0% |
| `rgbString` | -2.7% | -2.3% | +1.9% | +0.2% | -2.0% | +0.1% | +4.1% | -0.7% |
| `clone_mix_cached` | +1.7% | +0.1% | +1.6% | -0.3% | +1.3% | +0.0% | +0.0% | +0.0% |
| `hover_rgba` | +0.5% | -0.9% | +5.3% | +1.4% | +2.5% | +0.1% | +0.7% | +1.7% |

### 18.4 Coverage limits and evidence

Windows native was not measured: no Windows host or configured Parallels VM was available.
Safari 27.0.1 was attempted, but `package:test` timed out waiting for it to connect; it has
no valid result. The web results are desktop-browser measurements, not iPhone Safari or
Android Chrome measurements. JIT/debug builds and x64 native targets were not benchmarked.

The local evidence is `.handover/kurkle-platform-bench/`: the 13-case source and harness,
frozen before/after hex files, build/run scripts, metadata, complete raw timing logs,
`summary.json` and `summary.csv` (all before/after ns values and individual process medians).
Failed or incomplete attempts are retained separately and contribute no timing results.
The executable builds remain under `/private/tmp/kurkle-platform-bench/artifacts/`.
The temporary benchmark app is separate from the gallery; the gallery was not replaced.

</details>

<a id="chapter-19"></a>

<details>
<summary>19. Android profiling and further color optimization</summary>

## 19. Android profiling and further color optimization

Completed; partly superseded by [section 22](#22-color-only-implementation).
The numerical mixing, cloning, byte-conversion and hue optimizations remain relevant
to hover and animation. Parsing and string-formatting optimizations no longer speed
up chart rendering, because the Color-only path keeps colors native. The measurements
below remain evidence for the implementation tested at the time; they are not current
whole-chart gains. The ADR status recorded below is historical.

Decision record: [Chart.js ADR 0056](adr/0056-color-performance.md) (proposed).
"Accepted" below means the selected benchmark candidate; ADR acceptance still needs the
explicit policy change and durable reproduction evidence described in that record.

Measured and implemented on 2026-10-31. The baseline is the implementation **after** the
character-code hex fix of section 17, not the older string-map decoder. The source snapshots
and every experimental variant are working evidence under `.handover/kurkle-android-tuning/`.
The shipped changes remain pure Dart and keep the pinned @kurkle/color behavior.

### 19.1 What the profiles found

A separate Flutter profile app on the Pixel 8a exposes a VM service extension that runs one
color workload for 3 s after a 400 ms warm-up. The sampler is enabled at a requested period
of 100 µs. Each capture has roughly 9,700-12,200 samples. Eight workloads were captured
before the changes, and again after the first combined candidate. These profiles locate
work; the timing comparisons below use release AOT with the profiler off.

The initial profile found:
- Hex parsing spent substantial time converting bounded digits through `_int32`,
  `jsToInt32` and double/integer conversions. These conversions are unnecessary once a
  character is known to represent a hex nibble.
- In RGBA parsing, 52.3% of samples carry the `RegExp_ExecuteMatch` VM tag and another
  15.2% carry `RegExp_getGroupCount`. Captures also allocate substrings and repeat general
  numeric validation.
- `hexString` accounts for 59.1% of inclusive samples in parse-and-mix; the `String_concat`
  VM tag alone accounts for 31.8% of that workload's samples.
- Cached cloning/mixing spends 36.2% of self samples in `jsToInt32`, with further work in
  `_clone`, `_fromObject`, the RGB getter and setter.
- Hue conversion allocates mapped iterables, another result list, and a list grown by a
  collection-if. The follow-up profile also exposed the generic array-input adapter used
  by the private HSL modifier.

### 19.2 Accepted implementation

1. Hex decoding keeps bounded digits as integers. Invalid bitwise digits still produce 0;
   invalid short alpha still produces NaN. Formatting converts arbitrary channel values
   with the original ToInt32 fallback outside the safe range.
2. `simple_parse.dart` handles only a guarded subset: comma notation, ASCII spaces, unsigned
   one-to-three-digit channels, the required hue percentages, and optional unsigned decimal
   alpha. Every other form goes to the original regex. Short alpha fractions use one
   correctly rounded division of exact integers; long decimals still use `double.tryParse`.
   RGB and hue keep their different alpha rules, including overflow/wrapping behavior.
3. Regex captures already have a decimal-only alphabet, so their conversion uses
   `double.tryParse` with NaN on malformed captures, without repeating general JS number
   syntax validation. Dispatch skips irrelevant name lookups for clear hex/function forms.
   Name parsing only performs the U+0130 replacement when the character is present.
4. The RGB getter and clone copy their known private fields directly. Clone preserves the
   b2n/n2b alpha round trip. Mix reuses its own fresh copy instead of copying again through
   the setter, and converts weighted channels to an integer directly inside the int32
   range before applying the byte mask. `RGBA` is a final class; there is no external getter
   override that these direct field reads could bypass.
5. Byte conversions have bounded fast paths, with the original full arithmetic retained for
   negative/out-of-range inputs, NaN and infinities. Hue conversion reuses its private result
   list and constructs a fixed three-element literal. The private HSL modifier passes its
   own known components directly. Local inlining improves that hover path.
6. Native and Wasm RGB/hex formatting use one ASCII buffer. Non-byte RGB channels retain
   `jsNumberToString`. **dart2js uses string concatenation**: the unconditional buffer form
   was about 5x slower for RGB formatting in Chrome JS, despite being faster on Android.
   The compiler environment selects the form at compile time, without a platform import.

The final code is accounted for by the `adapt-kurkle-*` rows of `differences.md`. No global
parsed-color cache, approximation table, change to the public API, or JS-runtime change was
needed. The tested remainder-arithmetic replacement did not improve the screening runs,
and the broad `jsToInt32` inlining experiment was not retained. The late mix-channel
conversion saved roughly another 6 ns per cached mix on Android and passed web guards.

### 19.3 Pixel 8a release results

Flutter 3.47.8, Dart 3.13.7, Android 17, arm64, USB power. The final accepted series runs
baseline/final/final/baseline in fresh processes with 16 cases each. Battery temperature is
31.3 °C before and after every run. No CPU-frequency gate is applied. Each case warms for
400 ms, then measures 15 batches targeting 30 ms each. The value below is the median of
its two process medians. This is a small repeated benchmark, not a confidence-interval study.

The same cases and data are used on both sides. Parsing cases vary the input and consume
all RGBA channels. The guards add long decimal alpha, fractional/percentage/exponent RGB
notation, and non-canonical hue notation. Timed loops contain no result logging or file I/O.

| Operation | Before (ns/op) | After (ns/op) | Speedup | Time saved |
|---|---:|---:|---:|---:|
| Constant hex / valid only | 70.9 | 30.8 | 2.31x | 56.7% |
| Short RGB hex + RGBA | 79.5 | 42.1 | 1.89x | 47.1% |
| Short RGBA hex + RGBA | 84.1 | 46.3 | 1.82x | 44.9% |
| Six-digit hex + RGBA | 100.2 | 46.0 | 2.18x | 54.0% |
| Eight-digit hex + RGBA | 120.7 | 53.6 | 2.25x | 55.6% |
| Common RGBA parsing | 1239.8 | 89.8 | 13.80x | 92.8% |
| Common HSL parsing | 1348.5 | 190.0 | 7.10x | 85.9% |
| Named color parsing | 101.0 | 62.4 | 1.62x | 38.2% |
| RGBA with long alpha | 1718.1 | 191.4 | 8.98x | 88.9% |
| RGB fallback syntax | 1246.5 | 1157.4 | 1.08x | 7.1% |
| Hue fallback syntax | 1423.4 | 1143.8 | 1.24x | 19.6% |
| RGB string formatting | 198.7 | 45.9 | 4.33x | 76.9% |
| Clone and mix parsed colors | 183.2 | 84.2 | 2.17x | 54.0% |
| Parse and mix hex colors | 848.9 | 164.7 | 5.15x | 80.6% |
| Hex hover color | 1156.2 | 280.3 | 4.12x | 75.8% |
| RGBA hover color | 2489.3 | 339.2 | 7.34x | 86.4% |

These are additional gains over the earlier hex fix. They are color-operation CPU costs,
not whole-chart frame-rate gains. Existing caller caches avoid parsing on a cache hit;
that hit cannot receive the parsing speedup. Gamma-correct `interpolate`, cold-start costs,
allocation byte counts and other native devices were not profiled in this series.

### 19.4 Web guard and correctness

Optimized Chrome 156.0.8078.79 runs use dart2js `-O4` and dart2wasm `-O2`, assertions off,
through precompiled package:test wrappers. Baseline/final/final/baseline runs cover the
16 Android cases plus standalone hex formatting. The main web comparison precedes only
the last mix-channel conversion; that conversion has its own two-case A/B/B/A guard.

| Operation | Chrome JS speedup | Chrome Wasm speedup |
|---|---:|---:|
| Six-digit hex + RGBA | 2.58x | 2.61x |
| Common RGBA parsing | 4.90x | 11.19x |
| Common HSL parsing | 3.66x | 6.23x |
| RGBA with long alpha | 2.73x | 5.59x |
| RGB string formatting | 1.18x | 1.44x |
| Standalone hex formatting | 2.01x | 3.06x |
| Hex hover color | 2.69x | 2.53x |
| RGBA hover color | 3.09x | 5.26x |

The final mix-channel guard improves cached mixing by another 1.33x in Chrome JS and 1.11x
in Chrome Wasm, and parse-and-mix by 1.12x and 1.02x respectively, relative to the preceding
candidate in that guard. Small differences are not treated as established gains.

The differential oracle compares the frozen baseline and final candidate in **1,234,644
comparisons on each of VM AOT, dart2js and dart2wasm**. It covers all UTF-16 code units in
hex positions, malformed and valid function syntax, short/long alpha, wide and non-finite
channels, byte conversion bounds, clone quantization, hue manipulation and wide-channel
mixing with exceptional weights. It reports zero differences on all three targets.
The permanent regression tests additionally pin the fast-path contracts and fallback
behavior, including the upstream rejection of a trailing newline after `)`.

Final verification: the focused color/helper/animation suite passes 163 tests on the VM
and 326 across Chrome JS/Wasm; the spec suite passes with its existing skips. Workspace
analysis, formatting and the seven port checks pass. `status.yaml` and generated `parity.md`
record the adaptations. No golden image was rewritten.

The working evidence contains both raw CPU profiles, the profiling service and collector,
all screening variants and raw timings, the final paired APK hashes/temperature records,
the differential oracle, correctness logs, and `accepted-summary.csv`. A small retained
Dart/js/bootstrap copy permits rebuilding the comparison. APKs remain in
`/private/tmp/kurkle-android-tuning/artifacts/`. The temporary Android benchmark app is removed
after collection; the gallery is not replaced.

</details>

<a id="chapter-20"></a>

<details>
<summary>20. Direct typed color to canvas: Android experiment</summary>

## 20. Direct typed color to canvas: Android experiment

Completed; superseded by [section 22](#22-color-only-implementation).
This Android prototype justified the direct Color-to-Paint path. The subsequent
Color-only implementation handles hover, animation, themes and public color values,
and includes measurements on all four platforms. The results and implementation
limitations below describe the historical prototype, not outstanding work.

Measured on 2026-11-01 against `175337ff09d37b6aa7a5de76cdf5f90e44be6bc8`, after
the color-parser optimization of section 19. This investigates the direct `Color` to
`Paint` follow-up of Chart.js ADR 0054 Open 2. The candidate exists only in an isolated
copy; no production library code changed.

### 20.1 Candidate and protocol

The current typed lowering converts Flutter colors to CSS strings. The canvas parses
those strings through a 512-entry cache, clearing the cache when full. The candidate
lowers colors directly to normalized `dart:ui` colors and lets the canvas setters keep
them. It preserves the existing extended-sRGB conversion, RGB clamping and canvas
alpha quantization. Raw CSS strings still use the existing parser and cache.

Pixel 8a, Android 17, Flutter 3.47.8 / Dart 3.13.7, release AOT for arm64, profiler off.
The existing gallery frameless harness measures real chart update, draw and recording
completion. The scene is a line controller showing points without a connecting line,
with hidden scales, no animation or events, and an 800 × 480 bitmap at DPR 1. It calls
the real typed `colorOption` and `colorScript` lowering functions; the rest of the
config is identical raw configuration on both sides. Colors are preconstructed.

Eight fresh processes ran A/B/B/A/B/A/A/B. Each cell uses a 300 ms warm-up and nine
approximately 100 ms batches. The table gives medians across four process results
per variant. A process result is the sum of its update/draw/end medians, as in the
existing harness. Initial construction and initial list lowering are outside that
timing. This measures CPU-side chart work, not GPU rasterization, widget cost or FPS.

Battery temperature rose from 29.3 to 33.6 °C; reported thermal status stayed 0.
The last B process also slowed in raw-string controls. All completed runs are retained,
including that process; the small differences are not treated as established gains.

### 20.2 Chart results

The first series uses translucent palettes with varying byte alpha values. A static
color is shared by every point; `script16` returns one of 16 colors; `script-unique`
returns a distinct color per point; `indexable-unique` supplies a list of distinct
colors. The latter two exceed the canvas cache capacity at both measured counts.

| Workload, N 5000 | A, ms | B, ms | Time reduction |
|---|---:|---:|---:|
| Static color, update + draw + end | 2.153 | 2.090 | 2.9% |
| Scriptable, 16 colors, update + draw + end | 28.605 | 25.007 | 12.6% |
| Scriptable, distinct colors, update + draw + end | 30.472 | 25.135 | 17.5% |
| Indexable, distinct colors, update + draw + end | 26.451 | 25.040 | 5.3% |
| Scriptable, distinct colors, draw + end | 3.343 | 1.299 | 61.2% |
| Indexable, distinct colors, draw + end | 3.293 | 1.275 | 61.3% |

At N 1000, update + draw + end falls by 1.9% for static colors, 7.4% for
`script16`, 17.8% for `script-unique`, and 6.7% for `indexable-unique`.

The strongest result is the draw with more colors than the cache can hold: every
adjacent pair reduces that time by 52.6–61.8% at N 5000. It saves about 2 ms in
the median. The `script-unique` whole-update gain stays positive in all four pairs
(4.5–19.1%), saving 5.337 ms in the median. The other whole-update cells each have
at least one slower candidate pair. Static colors save only 0.063 ms at N 5000,
below the project's 0.1 ms threshold.

The raw-static and raw-script16 controls at N 5000 have whole-update medians 0.3%
and 2.6% slower in B. Their final pair is 6.7% and 15.9% slower. This is a reason
to keep the weaker results provisional, not to discard the last pair. This experiment
does not claim that the candidate passes a production regression gate.

### 20.3 Conversion costs

Microbenchmarks consume each result, with 100 ms warm-up and seven approximately
40 ms batches. These figures are also medians across four processes per variant.

| Operation | A, ns/op | B, ns/op | Speedup |
|---|---:|---:|---:|
| Typed lowering, 16 colors | 428.4 | 42.4 | 10.09x |
| Typed lowering, 4096 colors | 420.8 | 39.9 | 10.55x |
| Lowering + canvas color lookup, 16 colors | 501.9 | 41.6 | 12.05x |
| Lowering + canvas color lookup, 4096 colors | 879.5 | 40.5 | 21.74x |

The last two operations produce a paint color; they do not issue a draw. A repeated
palette benefits by removing string formatting and cache lookup. A palette larger
than the cache additionally avoids repeated parsing and cache eviction. The chart
update benefits less because option resolution and the rest of the chart still run.

### 20.4 Opaque and simple-alpha colors

The first palette's varying byte alpha values often produce long decimal strings.
A separate guard uses a 16-color callback with either alpha 1 or alpha 0.45, plus
raw-string controls of the same colors. Four fresh processes run A/B/B/A with the
same chart timing settings. The phone had settled at 34.0–34.3 °C, thermal status 0;
the guard's starting gate was 35 °C. These results are not pooled with section 20.2.

| Scriptable palette, N 5000, update + draw + end | A, ms | B, ms | Time reduction |
|---|---:|---:|---:|
| 16 opaque colors | 26.009 | 25.452 | 2.1% |
| 16 colors, alpha 0.45 | 26.909 | 24.991 | 7.1% |

Both adjacent pairs improve: 1.4–2.9% for opaque and 6.4–7.9% for alpha 0.45.
Their raw-string controls are respectively 1.3% and 1.2% slower in the median in B.
At N 1000, the typed medians improve 5.8% and 2.1%, while the raw controls are 3.6%
and 4.6% slower. This is a small guard, not a precision estimate for the weaker gains.

Lowering plus canvas color lookup falls from 261.2 to 34.7 ns/op for opaque colors
(7.52x), and from 304.1 to 36.6 ns/op for alpha 0.45 (8.32x). Thus the conversion
gain also exists for common colors, but the complete update remains dominated by
other work. It would be misleading to apply the 10–22x microbenchmark gain of
section 20.3 to a whole chart, or to every input palette.

### 20.5 Correctness and implementation boundary

Each main-series process passed 17,002 direct-versus-CSS color comparisons: an alpha sweep,
the palette, Display P3 colors and an extended-sRGB value. Six 600-point rendered
charts have matching full-image byte hashes and nontransparent pixel counts across
all eight processes. No golden was rewritten.

This establishes the conversion and rendering checks for these workloads, not full
behavior parity. The direct prototype changes resolved option values from strings
to `ui.Color`. The public option face and typed/raw twin tests currently expose or
expect strings. Hover and color animation also need adaptation: a focused VM probe
shows `getHoverColor` of the CSS form of `Color(0xFF2050C0)` gives `#003CCA`, while
passing the Flutter color directly gives `#000`. The current pure color parser
does not read Flutter color channels. Theme compilation is outside this experiment.

Conclusion: bypassing the string round trip merits further implementation work,
especially for scriptable colors and palettes exceeding 512 entries. It does not
close ADR 0054 Open 2. A production implementation must preserve observable option
behavior, hover and animation semantics, then repeat the affected measurements.

The [reproduction package](benchmarks/direct-color/README.md) retains the candidate
patch, benchmark entries, pinned source revision and dependencies, build/run/report
scripts, individual measurements and device/thermal metadata. The setup script was
checked to reconstruct the measured source and successfully rebuild a release APK. APKs remain under
`/private/tmp/chart-direct-color-20261101/artifacts/`; the experiment uses a separate
application identifier and does not replace the gallery. The temporary benchmark
app was uninstalled after collection.

</details>

<a id="chapter-21"></a>

<details>
<summary>21. Direct-color implementation: macOS, Chrome and Android</summary>

## 21. Direct-color implementation: macOS, Chrome and Android

Completed; superseded by [section 22](#22-color-only-implementation).
This intermediate implementation supported both native colors and CSS strings.
Section 22 replaces that compatibility layer with the Color-only API and adds
iOS measurements. The implementation details and results below describe the
historical compatible candidate, not the current API.

Implemented and measured on 2026-11-01, without committing. [ADR 0057](adr/0057-direct-typed-colors.md)
records the representation and compatibility boundaries. These are measurements of
the implementation, not the simpler prototype of section 20.

### 21.1 Implementation and validation

Typed colors retain prepared native paints. Public option reads, generated getters,
mutable color lists and callback reads still expose their original CSS values.
Callbacks run as often as before. Shared unanimated option copies retain paints;
the built-in elements use them directly on the native canvas. Custom and recording
canvases continue receiving the ordinary CSS form. Hover and animation preserve
their CSS behavior and the existing animation cache. Raw CSS keeps its bounded
canvas cache. Theme compilation is unchanged.

The affected typed API, option, resolver, canvas, animation and public-export tests
were checked. Four typed/raw chart twins exposed a plugin/scale boundary that was
fixed; the 52-test twin/direct-color subset then passed. The final six direct-color
regressions pass on the VM. The spec run reports 958 passing cases, 78 existing
skips and zero failures. Static analysis, headers, import restrictions, JS semantics,
the typed-read ratchet and generated options checks pass. Parity was regenerated
from the saved spec results. No golden was rewritten.

### 21.2 Small release comparison

Baseline: `175337ff09d37b6aa7a5de76cdf5f90e44be6bc8`. Candidate: the uncommitted
working-tree library, compared byte-for-byte with the benchmark source snapshot.
Flutter 3.47.8 / Dart 3.13.7. Platforms: Apple M3 Max on macOS 27.0.1, headless
Chrome 156 running release Wasm (verified by the application), and Pixel 8a arm64.
No iOS run: the device is to be connected later.

Four fresh processes per platform, A/B/B/A. Five cases, each measuring draw and
update separately at N 5000: a CSS-background callback control, static typed color,
a 16-color typed callback with alpha 0.45, a callback with distinct translucent
colors and an indexable list of those distinct colors. Each cell uses 250 ms warm-up
and seven approximately 100 ms batches. One earlier macOS screen found overhead
in the public color conversion helper; an inlining hint was added. Its results are
retained separately and excluded from the final figures below. No further tuning
series was run.

This uses actual typed dataset lowering, a line controller drawing points without
a connecting line, a hidden category x axis, a hidden linear y axis, an 800 × 480
bitmap at DPR 1, and `update('none')`. Initial configuration, palette construction,
widget/host work, GPU rasterization and FPS are outside the timing. The category
scale and the compatibility implementation differ from section 20's prototype, so
its percentages must not be treated as a before/after for this series.

Each entry is A → B, milliseconds for update + draw + recording completion, followed
by the percentage reduction. Negative percentages mean the candidate was slower.
The values are medians of two process results per side, without confidence intervals.

| Workload, 5000 points | macOS | Chrome Wasm | Pixel 8a |
|---|---:|---:|---:|
| Static typed color | 10.857 → 10.743 (1.1%) | 13.024 → 13.017 (0.1%) | 21.600 → 20.379 (5.7%) |
| Callback, 16 colors | 25.148 → 24.605 (2.2%) | 34.711 → 33.560 (3.3%) | 45.347 → 46.761 (-3.1%) |
| Callback, distinct colors | 26.992 → 24.624 (8.8%) | 37.355 → 33.661 (9.9%) | 50.752 → 45.590 (10.2%) |
| List, distinct colors | 24.956 → 24.157 (3.2%) | 34.708 → 33.111 (4.6%) | 43.267 → 47.014 (-8.7%) |
| CSS-background callback control | 24.805 → 25.260 (-1.8%) | 35.183 → 35.227 (-0.1%) | 43.809 → 47.416 (-8.2%) |

The control still has a typed border color, so a small drawing gain is possible
even though its background callback keeps the CSS path.

For draw + recording completion alone:

| Workload, 5000 points | macOS | Chrome Wasm | Pixel 8a |
|---|---:|---:|---:|
| Callback, distinct colors | 1.902 → 0.778 (59.1%) | 2.992 → 1.156 (61.3%) | 3.189 → 1.187 (62.8%) |
| List, distinct colors | 1.898 → 0.776 (59.1%) | 3.130 → 1.137 (63.7%) | 3.220 → 1.188 (63.1%) |

### 21.3 Interpretation and limits

Large-palette drawing is the consistent win: it bypasses repeated parsing when
the palette exceeds the 512-entry CSS cache. Distinct-color callback updates also
improve on all three platforms. Static colors and small palettes have much smaller
whole-update gains because the rest of the chart still runs.

Android's update results are mixed. The 16-color callback, indexed palette and
CSS-background control are slower in this short series. Battery readings stayed
29.2–29.3 °C, but CPU frequency was not pinned, and update batch times vary. The
control slowdown is a reason for caution, not evidence that the regressions can
be dismissed as noise. Keep these as provisional regressions; this is not an
across-the-board performance acceptance or an FPS claim. The code remains an
uncommitted candidate for review, with iOS and broader release qualification pending.

The [implementation reproduction package](benchmarks/direct-color/implementation/README.md)
retains the exact library patch, workload, dependency lockfile, commands, native
binary hashes, individual process results and summaries. The standalone Android
benchmark app was removed after collection; the gallery was not replaced.

</details>

<a id="chapter-22"></a>

<details>
<summary>22. Color-only implementation</summary>

## 22. Color-only implementation

2026-11-01. Final user-requested API: solid colors are Flutter `Color` in typed
and raw configurations, callbacks and gradient stops. CSS strings throw
`ArgumentError`. Typed lowering retains the native color; the canvas assigns it
directly. There is no CSS parser or string-color cache in the chart path.
Numerical defaults, hover and animation preserve the pure-Dart architecture.
The existing per-animation endpoint cache remains; it caches numerical endpoints,
not strings or user callback answers. See [ADR 0057](adr/0057-direct-typed-colors.md).

### Bounded release comparison

A is commit `175337ff09d37b6aa7a5de76cdf5f90e44be6bc8`; B is the uncommitted
Color-only implementation. Flutter 3.47.8 / Dart 3.13.7. macOS: Apple M3 Max,
macOS 27.0.1; Chrome 156.0.8078.79, release WebAssembly; Android: Pixel 8a,
Android 17; iOS: iPhone 17 Pro, iOS 26.6.2. Each platform ran A/B/B/A, two
processes per variant. Each cell uses
5000 points, 250 ms warmup and seven 100 ms batches. Measurements cover CPU
chart update/draw/recording completion, not rasterization or FPS. Initial config
lowering is outside the timer. The raw callback returns CSS in A and Color in B.

Positive percentages below mean less time. Draw means drawing plus recording
completion; update includes update, draw and completion. All measured process
values and millisecond medians are in the [reproduction package](benchmarks/direct-color/strict/README.md).

| Case | Operation | macOS | Chrome Wasm | Android | iOS |
| --- | --- | ---: | ---: | ---: | ---: |
| Raw callback, 16 colors | draw | +12.4% | +17.4% | +13.6% | +13.6% |
| Raw callback, 16 colors | update | +3.8% | +7.1% | -0.1% | +4.0% |
| Static color | draw | +11.3% | +18.6% | +15.1% | +13.7% |
| Static color | update | +0.3% | +1.8% | +13.0% | -0.5% |
| Typed callback, 16 colors | draw | +10.9% | +17.6% | +15.4% | +13.7% |
| Typed callback, 16 colors | update | +2.2% | +7.8% | -0.9% | +2.6% |
| Typed callback, 5000 colors | draw | +61.4% | +61.7% | +63.6% | +62.6% |
| Typed callback, 5000 colors | update | +12.5% | +14.6% | +13.0% | +11.9% |
| List, 5000 colors | draw | +60.6% | +62.8% | +64.6% | +62.5% |
| List, 5000 colors | update | +6.0% | +6.7% | +4.2% | +3.3% |

Distinct colors show the strongest result: about 61–65% less drawing CPU time,
with full updates about 12–15% faster for distinct callbacks and 3–7% faster
for distinct lists. For example, Android distinct callbacks draw in 1.147 ms
instead of 3.152 ms, and update in 43.477 ms instead of 49.948 ms.
The baseline's bounded string cache cannot retain that palette.

Repeated-color updates are workload-dependent: Android raw/typed 16-color
callbacks changed by −0.1%/−0.9%, effectively unchanged at this sample size.
Static updates ranged from −0.5% to +13.0%; the latter is not evidence of a
universal static-color gain. Two pairs are insufficient for confidence intervals.
The macOS host also compiled isolated iOS builds during part of its series;
small macOS shifts are inconclusive. No further tuning/repetitions were done.

These compare the original implementation with the complete direct-color change.
They do **not** isolate the incremental benefit of forbidding strings compared
with a compatible direct-color fast path. Removing compatibility mainly simplifies
code and eliminates the parser/cache; the direct native path supplies the main
measured gain. Native alpha and wide-gamut colors also avoid the old CSS
quantization, so pixel output can intentionally differ from the old route.

### iOS and verification

iOS completed the release A/B/B/A comparison after the development-profile
launch rejection was resolved. Distinct callback colors reduced draw CPU time
from 1.575 ms to 0.589 ms (62.6%), and full update time from 21.453 ms to
18.901 ms (11.9%). Distinct lists reduced draw time by 62.5% and full updates
by 3.3%. Static updates changed by −0.5%, effectively unchanged in this run.

The app's release console did not expose benchmark output. Results were instead
written into its own temporary directory after timing and retrieved with
`devicectl`. Subsequent launches first replace the old result with a sentinel;
each result must contain ten release cells of the expected variant. One initial
console-only launch is excluded. The same production library and timed workload
were used; only result collection changed. The reproduction package includes the
iOS runner and completion helper.

The VM spec suite passed 958 tests (78 existing skips), and the observation oracle
passed 1476 cases. Its reviewed native-color representation retains callback
counts/order; all fixtures construct except the deliberate recursion probes.
Nine focused Color-only contract tests passed on VM and Chrome Wasm. Affected
reference tests (4155 passed, 61 existing skips in the final affected-file run)
and gallery assertions were migrated to native colors while
retaining their geometry, ordering, option and callback checks. Static analysis,
import/header rules, JS semantics, typed-read counts and generated options were
checked; parity is regenerated from the saved passing spec run. Pre-push
verification additionally runs the full workspace suite, Chrome JS/Wasm suites,
spec-case coverage and fixture checks. Golden and device UI suites were not
repeated for this change.


</details>

<a id="chapter-23"></a>

<details>
<summary>23. Stacked-fill exact-point experiment</summary>

## 23. Stacked-fill exact-point experiment

2026-11-01. **Revised implementation completed.** The initial candidate
failed its guard comparison. The follow-up below records the diagnosis and corrected
comparison separately; the initial evidence remains intact.
[ADR 0058](adr/0058-stack-exact-point-search.md) records the design and the protocol.
The baseline is
`3ea45085a961adc2fc50770294d6cce04417ac2d`, including native Color inputs.

### Candidate and limits

For ordinary lines with one contiguous, non-looping segment and strictly increasing,
finite x values separated beyond the segment tolerance, an exact x match returns
the existing target point. A forward cursor reuses the search position; a backward
query uses binary search. Geometry and point identity match the original `[i, i]`
interpolation result. The source and target must have ordinary point/list/segment
implementations; options cannot execute custom reads in the fallback.

Missing matches, gaps, duplicate/near-equal coordinates, loops and custom objects
retain the original interpolation. Validation is lazy, so unreached lower lines
stay unread. A potentially effectful fallback disables all lookup reuse for that
build. State lasts for one stack construction and is rebuilt after mutations.
The boundary line retains the original path. Shared `LineElement.interpolate`,
segment helpers, radar and canvas sources were not edited.

This specifically improves aligned stacks. It does not make arbitrary stacked
fills linear, and unsupported/unmatched inputs remain quadratic. Their correctness
was checked, but their performance was not benchmarked in this initial experiment.

### Initial bounded release results (candidate B)

Flutter 3.47.8 / Dart 3.13.7. macOS: Apple M3 Max, macOS 27.0.1. Chrome:
156.0.8078.79, release Wasm, headless Flutter CLI runner. The existing gallery cases
use three datasets for fills. A/B/B/A, two fresh processes per variant, ten cells
per process; 250 ms warmup, seven batches targeting 100 ms. The agent ran no builds
or tests concurrently with timing. No run was discarded and no tuning rerun was
pooled into the series. No Android/iOS measurement was added.

Values sum the process medians of draw + recording completion, or update + draw +
completion, then take the median across the two processes. These are CPU timings,
not GPU raster time or FPS. Positive percentages mean less time. Two pairs provide
no confidence interval; small shifts remain inconclusive.

| Case | N | Operation | macOS A → B, ms (time saved) | Chrome Wasm A → B, ms (time saved) |
| --- | ---: | --- | ---: | ---: |
| `fill.stack` | 100 | draw | 0.459 → 0.121 (+73.6%) | 0.732 → 0.178 (+75.7%) |
| `fill.stack` | 100 | update | 1.092 → 0.738 (+32.4%) | 1.774 → 1.224 (+31.0%) |
| `fill.stack` | 1000 | draw | 31.428 → 0.947 (+97.0%) | 46.855 → 1.381 (+97.1%) |
| `fill.stack` | 1000 | update | 36.237 → 4.524 (+87.5%) | 52.539 → 6.466 (+87.7%) |
| `fill.gaps` | 1000 | draw | 5.463 → 5.379 (+1.5%) | 8.197 → 9.040 (-10.3%) |
| `fill.gaps` | 1000 | update | 6.987 → 6.910 (+1.1%) | 11.063 → 11.635 (-5.2%) |
| `fill.radar` | 1000 | draw | 0.436 → 0.454 (-4.1%) | 0.696 → 0.700 (-0.6%) |
| `fill.radar` | 1000 | update | 1.713 → 1.756 (-2.5%) | 2.562 → 2.510 (+2.1%) |
| `chart.a` | 1000 | draw | 0.167 → 0.168 (-0.3%) | 0.294 → 0.299 (-1.9%) |
| `chart.b` | 1000 | update | 0.455 → 0.460 (-1.1%) | 0.780 → 0.781 (-0.1%) |

At N=1000 the primary stacked-fill draw drops from 31.428 to 0.947 ms on macOS
and from 46.855 to 1.381 ms in Chrome. Full updates drop from 36.237 to 4.524 ms
and from 52.539 to 6.466 ms respectively. This confirms substantial headroom in
stack target construction without replacing shared interpolation.

**The candidate does not pass the guard criterion.** Chrome gap-filled draws are
0.844 ms slower (+10.3%), with both B processes slower than either A process;
gap-filled full updates are 0.572 ms slower (+5.2%). macOS radar drawing is 0.018 ms
slower (+4.1%), also in both B processes. Chrome radar drawing changes by only
+0.6%, so the earlier radar-specific browser regression was not reproduced at
that size, but a different browser guard regressed. No profile in this experiment
establishes why unchanged paths shifted. These results are not evidence that the
shortcut directly executes in the gaps or radar cases.

### Verification and evidence

Six focused differential tests pass on VM, dart2js and dart2wasm. They include 150
seeded generated comparisons with the original algorithm, exact-hit identity,
forward/backward queries, epsilon-near and duplicate coordinates, gaps, loops,
stepped/curved options, mutation between builds, custom interpolation, lazy access
and disabling indexed reuse before a foreign fallback. A real-chart test confirms
the shortcut is reached and its recorded draw commands are identical. Existing
stack/filler reference checks pass, as do 76 filler specification/fixture tests.
Import/header rules, the typed-read ratchet and JS semantics checks pass.

The [reproduction package](benchmarks/stack-exact-points/README.md) retains the
measured two-file patch, protocol metadata, source hashes, benchmark entry points,
setup/build/run scripts and all eight process records. The measured candidate was
byte-for-byte equal to the working source at collection. `summary.json` retains
individual process values, not just averages. Diagnose the guard regressions before
any merge decision; this experiment makes no release or cross-device claim.

### Follow-up: isolated guards and revised implementation

The isolated Chrome check used original candidate B, running just gap drawing and
updating in fresh A/B/B/A processes. Draw medians were 8.869 → 8.916 ms (+0.54%);
full updates were 11.794 → 11.854 ms (+0.51%). The earlier 10.3%/5.2% difference
did not reproduce. It depended on the short mixed benchmark context; the initial
guards followed drastically different amounts of stack work. This evidence points
to workload-order sensitivity but does not establish a particular GC/JIT mechanism.
Two query-selection setup attempts ran the wrong cell count and failed validation;
they are excluded by protocol, not by their timings. The valid diagnostic used an
explicit GUARD_ONLY define and is not pooled with the original or final series.

Candidate C also removes the dummy LineElement previously used to discover the
private segment type. An internal constant gives that type identity directly,
avoiding the extra line/list construction. It is hidden from public helpers.
Existing interpolation, segment-scanning and radar routines are unchanged. This
code cleanup is separate from the benchmark-order diagnosis.

The final series uses **A/C/C/A**, with gaps, radar and ordinary-line guards first,
then stacked fills. All other settings remain 250 ms warmup, seven 100 ms batches,
the same gallery scenes and point counts, and two processes per variant. Neither
builds nor tests ran alongside timing. No result was discarded.

| Case | N | Operation | macOS A → C, ms (time saved) | Chrome Wasm A → C, ms (time saved) |
| --- | ---: | --- | ---: | ---: |
| `fill.gaps` | 1000 | draw | 5.283 → 5.271 (+0.2%) | 9.117 → 9.169 (-0.6%) |
| `fill.gaps` | 1000 | update | 6.590 → 6.634 (-0.7%) | 11.992 → 11.883 (+0.9%) |
| `fill.radar` | 1000 | draw | 0.429 → 0.435 (-1.4%) | 0.669 → 0.686 (-2.5%) |
| `fill.radar` | 1000 | update | 1.671 → 1.675 (-0.3%) | 2.383 → 2.337 (+1.9%) |
| `chart.a` | 1000 | draw | 0.163 → 0.164 (-0.6%) | 0.273 → 0.272 (+0.4%) |
| `chart.b` | 1000 | update | 0.444 → 0.446 (-0.6%) | 0.737 → 0.728 (+1.2%) |
| `fill.stack` | 100 | draw | 0.434 → 0.115 (+73.6%) | 0.736 → 0.164 (+77.7%) |
| `fill.stack` | 100 | update | 1.022 → 0.694 (+32.2%) | 1.663 → 1.053 (+36.7%) |
| `fill.stack` | 1000 | draw | 30.434 → 0.927 (+97.0%) | 54.279 → 1.374 (+97.5%) |
| `fill.stack` | 1000 | update | 34.745 → 4.178 (+88.0%) | 59.787 → 6.185 (+89.7%) |

**The large gap-fill guard concern is resolved in the revised validation.** Chrome
gap draw time is +0.053 ms (+0.6%), with overlapping process ranges, and gap full
updates are 0.110 ms faster (0.9%). The stack improvement is retained: roughly
97% less drawing CPU time and 88–90% less full-update time at N=1000. Residual
radar draw shifts are +0.006 ms on macOS and +0.017 ms in Chrome; small differences
in two pairs are inconclusive. This is not a promise of zero regression, an FPS
result, or validation on Android/iOS.

The revised implementation is retained. Its guard/identity tests pass on VM,
dart2js and dart2wasm, and public export checks confirm no new helper API leaks.
The [revision evidence](benchmarks/stack-exact-points/revision/README.md) retains
all isolated and final process records, the four-file measured patch, source
hashes, the corrected harness and reproduction scripts. The original failed
candidate and data remain in the parent evidence package.

</details>

<a id="chapter-24"></a>

## 24. Private boundary endpoint search on Android

2026-11-02. Implemented, with bounded release validation on the connected Pixel
8a. [ADR 0059](adr/0059-boundary-exact-point-search.md) records the decision;
[the report and reproduction package](benchmarks/boundary-exact-points/README.md)
retain the profile, raw runs, source hashes and exact measured patch.

The baseline is `3441804`, after the stack-fill work. Its Android CPU profile
collected 12,984 samples: `boundSegments` has 66.9% inclusive, `boundSegment`
64.5%, and `interpolatedLineTo` 45.2%. These shares overlap. Endpoint interpolation
repeatedly scans the generated constant boundary for every source segment and
both above/below color passes.

The filler now validates a private origin/start/end linear boundary once per draw
and binary-searches exact endpoints. Each hit returns the same existing point as
original interpolation. Misses and unsupported inputs use the original path.
Shared interpolation, segment matching and canvas code are unchanged. This does
not make the complete fill algorithm linear. Dataset targets retain their user
callbacks, and no index survives into another draw.

### Release comparison

Flutter 3.47.8 / Dart 3.13.7, Android 17, arm64 release, profiler off. A/B/B/A,
two fresh processes per variant; ten cells, nine 150 ms batches after 500 ms
warmup. Three fill datasets, 800 × 480 canvas, DPR 1. Controls run first. No
builds or tests ran alongside timing, and no run was discarded. The values sum
per-process medians of draw + recording completion, plus update for full updates,
then take the median across processes. Positive percentages mean less CPU time.

| Cell | N | Operation | Baseline → candidate, ms | Time saved |
| --- | ---: | --- | ---: | ---: |
| `fill.gaps` | 100 | draw | 0.486 → 0.362 | 25.4% |
| `fill.gaps` | 100 | update | 1.244 → 1.152 | 7.4% |
| `fill.gaps` | 1000 | draw | 10.704 → 5.339 | 50.1% |
| `fill.gaps` | 1000 | update | 14.914 → 8.183 | 45.1% |
| `chart.a` | 1000 | draw | 0.285 → 0.282 | 1.2% |
| `chart.b` | 1000 | update | 0.815 → 0.831 | -2.0% |
| `fill.radar` | 1000 | draw | 0.913 → 0.903 | 1.1% |
| `fill.radar` | 1000 | update | 3.645 → 3.585 | 1.7% |
| `fill.stack` | 1000 | draw | 1.805 → 1.768 | 2.1% |
| `fill.stack` | 1000 | update | 8.578 → 8.241 | 3.9% |

At N=1000, paired draw reductions are 50.2% and 50.0%; full-update reductions
are 40.4% and 49.3%. Baseline update results vary (13.937 and 15.891 ms), so
45.1% is a directional aggregate, not a precise universal gain. No control
exceeds both predeclared regression limits, 0.1 ms and 5%; the only slower
control is ordinary-line update, +0.0165 ms (+2.0%). Battery temperatures were
29.2–29.4 °C and every before/after thermal status was 0.

Two pairs provide no confidence interval. These are CPU measurements, not GPU
raster time or FPS. There is no performance claim for other platforms. The raw
records remain available, including the small control shifts.

### Correctness

Two hundred seeded private boundaries on both axes compare exact point identity
with original interpolation. Guards exercise duplicate/near/non-finite/reversed
coordinates, nonconstant and looping boundaries, foreign getters and misses.
Twelve real-chart cases compare every draw command for origin/start/end, both
axes, normal/reversed scales, curved/stepped lines and mutations between updates.
A custom dataset target retains the same interpolation callbacks and draw commands.
The pure boundary and related filler tests pass on both dart2js and dart2wasm.

Final verification: workspace tests pass (10,572, with 87 skips), the full web
suite passes on dart2js and dart2wasm (7,894 chart-port and 110 test-utils tests,
with four skips), upstream case coverage passes (958 passed, 78 skipped), and
fixtures pass (628 passed, 39 skipped). Formatting, fatal-info analysis and all
seven port checks pass. Parity is regenerated. The reproduction package rebuilds
the exact measured library sources by hash; the implementation is retained.

<a id="chapter-25"></a>

## 25. Private boundary segment matching on Android

2026-11-02. [ADR 0060](adr/0060-boundary-segment-search.md) extends the private
boundary lookup of chapter 24 to exact segment bounds. The baseline is `e942d50`,
which already includes the endpoint improvement. The current Android profile
collected 13,025 samples: matching `segments` has 50.3% inclusive, `boundSegments`
43.7%, and `boundSegment` 44.6% (26.0% self). The inclusive shares overlap.

A cursor now advances across ordered exact bounds on the same private constant
boundary; backward/overlapping queries use binary search. A hit returns the same
native segment type and fields as the original scan. Source geometry and shared
scanner loops stay unchanged, and misses or unsupported cases use the original
path. No new segment implementer or public API is introduced. State is per draw.

### Android release comparison

Pixel 8a, Android 17, Flutter 3.47.8 / Dart 3.13.7, arm64 release, profiler off.
The prewritten protocol uses A/B/B/A, two fresh processes per variant, controls
first, nine 150 ms batches after 500 ms warmup. Three fill datasets, 800 × 480
canvas at DPR 1. No builds or tests ran alongside timing; no run was discarded.
Values sum per-process draw + recording-completion medians, plus update for full
updates, then take the median across processes. Positive means less CPU time.

| Cell | N | Operation | Baseline → candidate, ms | Time saved |
| --- | ---: | --- | ---: | ---: |
| `fill.gaps` | 100 | draw | 0.3655 → 0.3345 | 8.5% |
| `fill.gaps` | 100 | update | 1.1535 → 1.0970 | 4.9% |
| `fill.gaps` | 1000 | draw | 5.2980 → 2.8820 | 45.6% |
| `fill.gaps` | 1000 | update | 8.5565 → 5.9920 | 30.0% |
| `chart.a` | 1000 | draw | 0.2785 → 0.2840 | -2.0% |
| `chart.b` | 1000 | update | 0.8115 → 0.8090 | 0.3% |
| `fill.radar` | 1000 | draw | 0.8925 → 0.8955 | -0.3% |
| `fill.radar` | 1000 | update | 3.8060 → 3.5435 | 6.9% |
| `fill.stack` | 1000 | draw | 1.7385 → 1.7565 | -1.0% |
| `fill.stack` | 1000 | update | 8.1355 → 8.3205 | -2.3% |

The N=1000 paired draw reductions are 45.3% and 45.9%; full updates improve by
37.8% and 21.5%. Baseline update processes give 8.927/8.186 ms; candidate processes
give 5.556/6.428 ms. Thus 30.0% is a directional aggregate. The largest slower
control, stack update, is +0.185 ms (+2.3%); it does not exceed both predeclared
thresholds of 0.1 ms and 5% in aggregate. Its pairs differ: one improves 3.5%,
while the other is +0.663 ms (+8.4%), exceeding both limits once. This does not
meet the protocol's repeatability criterion; its cause remains unestablished.
The smaller draw-control shifts remain inconclusive. No unrelated control
improvement is attributed to the change. Temperatures were 29.0–29.4 °C and all
before/after thermal statuses were 0.

Two pairs do not give a confidence interval. This is bounded CPU evidence, with
no GPU time, FPS or other-device performance claim. The
[report and reproduction package](benchmarks/boundary-segment-search/README.md)
retain all four processes, the profile, source hashes and the exact measured patch.

### Correctness

Two hundred generated boundaries compare native segment type and fields with
the original scanner on both axes and reordered/overlapping/repeated ranges.
Another 200 generated source cases compare complete fill parts for both color
passes, including source mutations after boundary construction. Explicit guards
cover misses, tolerance-near values, invalid/reversed/non-finite bounds and cursor
recovery. Real charts compare every draw command with no shortcut, with the prior
endpoint shortcut only, and with both enabled. Custom dataset callbacks and the
public export list remain unchanged. Focused pure tests pass on VM, dart2js and
dart2wasm. The reproduction script reconstructs all five measured library files
with matching hashes.

Final verification: workspace tests pass (10,575, 87 skipped), the full
web suite passes (7,900 chart-port and 110 test-utils tests, four skips), upstream
coverage passes (958 cases, 78 skipped), and fixtures pass (628, 39 skipped).
Formatting, fatal-info analysis and all seven port checks pass. Parity is
regenerated; final library hashes match the measured candidate. The implementation
is retained.

<a id="chapter-26"></a>

## 26. Element option cache-key reuse on Android

2026-11-02. [ADR 0062](adr/0062-element-option-cache-key.md) reuses the last
joined `elementType-mode` string per DatasetController. The baseline is `6197449`,
the direct Flutter Color core, pushed before this work; its CI run 41370124105
passed. The candidate has three private fields and one key-selection branch.
It still converts the element id on every call and retains the original string
map, collisions, clearing, sharing, clones and scriptable option callbacks.

The Pixel 8a baseline profile collected 11,548 samples at bubble N=5000 update.
_resolveElementOptions has 12.4% inclusive frame samples. Within that function,
String hashCode has 2.59% self, _concatAll 2.28% and _interpolate 2.12% of the
capture. Those profile costs motivated reuse of the string, not additional
option-result caching. Drawing circles and recording pictures remain large costs.

### Android release comparison

Flutter 3.47.8 / Dart 3.13.7, Android 17, arm64 release, profiler off. The
prewritten protocol uses A/B/B/A, 15 cells with controls first, 500 ms warmup and
nine 150 ms batches. No builds/tests ran alongside timing; no run was discarded.
Temperatures were 28.2–29.5 °C; all before/after thermal statuses were 0.

Values are medians across two process results per variant. The full-call result
sums each process's update + draw + recording-completion medians first. The
predeclared primary metric is update CPU at N=5000 for bubble and unshared
scatter; both must improve by at least 5% in each pair. Full-call totals are also
guarded against repeatable increases exceeding both 0.1 ms and 5%.

| Workload | N | Update CPU, A → B ms | Saved | Full call, A → B ms | Saved |
| --- | ---: | ---: | ---: | ---: | ---: |
| Bubble update | 1000 | 1.8775 → 1.6365 | 12.8% | 4.4990 → 4.3225 | 3.9% |
| Unshared scatter update | 1000 | 1.0545 → 0.7900 | 25.1% | 1.4030 → 1.1580 | 17.5% |
| Bubble update | 5000 | 8.5060 → 7.1360 | 16.1% | 20.1270 → 19.5200 | 3.0% |
| Unshared scatter update | 5000 | 3.6850 → 2.2965 | 37.7% | 5.3965 → 4.0060 | 25.8% |

The protocol passes. Bubble update CPU decreases 16.9% and 15.3% in the two
pairs; scatter decreases 39.1% and 36.2%. Full scatter calls improve 26.7% and
24.8%; full bubble calls improve 3.7% and 2.3%. No full-call control has a
repeatable increase above both thresholds.

The tradeoffs remain in the record. Bubble's draw portion inside its N=5000
update rises 7.1655 → 7.9185 ms (+10.5%, +9.3%/+11.7% in the pairs), offsetting
much of the update gain. Its separate draw-only control changes +0.3%. Bar full
update at N=5000 changes 40.603 → 41.4315 ms (+2.0%): +4.05% in one pair and
almost zero in the other; the update component alone is +6.9% in aggregate.
The profile does not establish the cause of these component/control shifts.

Other full-call changes: ordinary line draw +3.2% (+0.0435 ms), radar draw +1.1%,
gap fill draw +1.9%, shared line update +0.3%, tooltip hover +0.4%, bar draw -0.2%,
scriptable line update -2.8%, polar-area update -4.0% and radar update -5.7%.
Small changes in two pairs remain inconclusive. No GPU/FPS, other-device or
zero-regression claim is made.

The [full report and reproduction package](benchmarks/element-option-cache-key/README.md)
retain every process/component value, the baseline profile, APK/source hashes,
prewritten protocol and exact measured patch. Reconstruction matches the measured
library hash. Five new semantic tests passed on the unchanged baseline, then on
the candidate; the focused controller/reference/specification run passes 133 tests.

Final verification: workspace tests pass (10,583, 87 skipped); Flutter
JavaScript and WebAssembly each pass 3,950 chart-port and 55 harness tests with
two existing skips. Upstream coverage passes (958, 78 skipped), fixtures pass
(628, 39 skipped), and formatting, fatal-info analysis and all seven port checks
pass. Parity is regenerated. The final library hash matches the measured candidate.
The performance change is retained; baseline 6197449 is pushed and its
GitHub CI run 41370124105 passed.

## 27. Category-axis label layout on macOS

2026-11-02. The reported stress configuration is `MODE=axes`, N=20000, M=0,
`CALL=update`, category x and logarithmic y. Its screenshot reports 57.06 ms
layout out of 61.10 ms update, with 5.85 ms draw and 1.14 ms raster. M controls
the extra plugin labels, not axis tick labels. The 44 displayed x ticks are the
result of auto-skip, after the full candidate list has been processed.

A fresh macOS profile of that configuration confirms the hot path. The capture
has 4629 samples and includes startup: `_computeLabelSizes` appears in 3480
samples (75.2%), `resolveTickFontOptions` in 2596 (56.1%), `toFont` in 1634
(35.3%), and `getContext` in 552 (11.9%). These are overlapping inclusive
shares of the capture, not additive phase times. This supports optimizing the
per-label work; it does not establish an FPS gain by itself.

The change preserves every candidate tick, font callback and measurement:

- `toFont` reads known option keys through `readOption`, avoiding string-key
  dispatch for typed resolvers while retaining raw-object reads and callback order.
- For a double line height, use the result of JavaScript's decimal conversion and
  the anchored regex directly. Zero (also -0) parses as positive zero; values in
  [1e-6, 1e21) multiply the size; negative, nonfinite and exponent-form values
  use the default. Strings and other inputs retain the original regex path.
- The six literal font-style alternatives bypass the regex. Oblique angles and
  invalid styles retain the regex and warnings.
- A tick context is constructed directly with the same prototype, field values,
  own-key order and identity lifetime, without allocating and copying a Map.

There is no new cache of resolved fonts, no sampling option, and no change to
label rotation, auto-skip, text metrics caches or the chart configuration.

### A/B comparison

Baseline `8bcbe47`; Apple M3 Max, macOS 27.0.1, Flutter 3.47.8 / Dart 3.13.7,
arm64 profile AOT, Impeller. The existing frameless benchmark runs the same
stress scene at its fixed 800 × 480 canvas: category/logarithmic and the
linear/logarithmic control, at 1000/5000/20000 points, each with update and draw.
Each cell has 1000 ms warmup and nine 250 ms batches. Process order is A/B/B/A;
no builds or tests run alongside timing, and no process result is discarded.
Values below are medians of the two process results per variant. This is a local
exploratory comparison, not a claim about other devices, debug builds or web.

| X axis | N | Update ms, A → B | Saved | Layout ms, A → B | Full call ms, A → B |
| --- | ---: | ---: | ---: | ---: | ---: |
| category | 1000 | 2.784 → 1.942 | 30.2% | 2.470 → 1.632 | 3.309 → 2.436 |
| category | 5000 | 11.922 → 7.919 | 33.6% | 11.075 → 7.046 | 13.332 → 9.296 |
| category | 20000 | 51.155 → 35.152 | 31.3% | 48.029 → 32.229 | 56.873 → 40.907 |
| linear | 1000 | 0.784 → 0.689 | 12.1% | 0.505 → 0.401 | 1.206 → 1.094 |
| linear | 5000 | 1.428 → 1.334 | 6.6% | 0.679 → 0.570 | 2.671 → 2.545 |
| linear | 20000 | 3.917 → 3.868 | 1.2% | 1.328 → 1.227 | 8.303 → 8.247 |

Full call sums update, draw and recording-completion medians within each process
before combining processes. At category N=20000 it falls 28.1%. The draw-only
full call is 4.111 → 4.097 ms; drawing is not the improvement. The maximum
increase among draw-only full-call controls is 0.0015 ms. All four runs have
exactly equal x/y tick values, labels, rotation and chart bounds in each cell.
The category x axis has 33 ticks at 50 degrees at this benchmark size; the
screenshot has a different size and therefore 44 ticks.

**Keep the change.** It removes measurable overhead without reducing label
coverage or changing the callback contract. It does not eliminate the O(N)
category layout or reach a 16.7 ms frame budget at 20000 points. A future reuse of
resolved fonts needs separate treatment of scriptable/indexed options and
mutation; the current change deliberately evaluates each tick as before.

[Reproduction and raw measurements](benchmarks/category-layout/README.md) include
the probe, original CPU samples, four process results and the numerical summary.
The regression cases cover numeric boundaries, signed zero, nonfinite values,
scriptable/indexed font fields, literal font styles, and tick-context identity,
prototype inheritance and own-key order. The existing upstream scale reference
cases cover the resulting layout and drawing commands.

Validation: all 10063 non-fixture/non-golden package tests pass (84 skips);
76 targeted helper tests pass in each of Chrome JavaScript and WebAssembly.
The full fixture smoke runner passes (26 files, no errors or warnings).
Workspace analysis and format checks pass, as do all check:port steps. The
parity report is regenerated from status.yaml.

## 28. Guarded reuse of static tick fonts

2026-11-02. [ADR 0063](adr/0063-static-tick-font.md) follows §27: the baseline
already has that optimization, after which the user observed 18–19 FPS in the
same stress configuration. This comparison measures the additional change.

`Scale.resolveTickFontOptions` still creates/reads each tick context. It then
checks already-cached raw font inputs, or the live default-font scalar cells
when `ticks.font` is absent. With ordinary resolver slots, no sub-proxy, inert
cached descriptors and a plain unrouted global fallback, equal scalar inputs
reuse a private parsed-font template. Each caller gets a fresh `ParsedFont`.
Inputs are checked every time, so resolver writes/deletes and global-default
changes cannot leave an old font in use. Functions, arrays, partial/foreign
values, invalid styles, custom getters and overrides retain normal resolution.
This is not a cache of a function's result. No candidate tick or text measurement
is removed, and auto-skip and rotation are unchanged.

### A/B comparison against §27

Apple M3 Max, macOS 27.0.1, Flutter 3.47.8 / Dart 3.13.7, arm64 profile AOT,
Impeller. The same frameless probe uses an 800 × 480 canvas, category x /
logarithmic y and linear x / logarithmic y, N=1000/5000/20000, update and draw.
Each cell has 1000 ms warmup and nine 250 ms batches; process order is A/B/B/A.
No builds or tests run during timing. All four final process results are kept.
The protocol requires at least 15% less category N=20000 update time in each
pair and exact layout output, and checks full-call controls against repeatable
increases above both 5% and 0.1 ms.

Values are medians across the two process results of each variant. Full call
sums each process's update, draw and recording-completion medians first.

| X axis | N | Update ms, A → B | Saved | Layout ms, A → B | Full call ms, A → B |
| --- | ---: | ---: | ---: | ---: | ---: |
| category | 1000 | 1.725 → 0.919 | 46.7% | 1.464 → 0.665 | 2.162 → 1.328 |
| category | 5000 | 7.050 → 3.380 | 52.1% | 6.319 → 2.690 | 8.265 → 4.583 |
| category | 20000 | 30.869 → 16.075 | 47.9% | 28.066 → 13.216 | 35.932 → 21.991 |
| linear | 1000 | 0.608 → 0.490 | 19.5% | 0.355 → 0.242 | 0.969 → 0.829 |
| linear | 5000 | 1.190 → 1.068 | 10.2% | 0.509 → 0.401 | 2.293 → 2.156 |
| linear | 20000 | 3.430 → 3.334 | 2.8% | 1.098 → 1.008 | 7.400 → 7.352 |

**Keep the change.** Category N=20000 update improves 48.2% and 47.7% in the two
pairs, and full-call cost improves 39.3% and 38.3%. All axes' tick values, labels,
rotation and chart bounds match exactly across all four runs in all 12 cells.
No full-call control reaches the regression threshold. The largest draw-only
full-call increase is 0.043 ms (linear N=20000, 1.2%).

Retain the component tradeoff: the draw inside a category update at N=20000 is
4.210 → 5.068 ms (+20.4%), despite the lower full-call time. Draw-only is
3.7315 → 3.7680 ms including recording completion. The cause of that component
shift has not been isolated; the net full-call comparison includes it. This
local CPU result is not a promise of user FPS or mobile/web performance.

Two preliminary implementations were measured and are retained in the evidence:
one inspected descriptor keys as strings instead of typed keys; the next did
not handle the absent `ticks.font` that this workload uses. Neither is retained.
The final four-run comparison uses the complete default-font guard described
above. [Protocol, patches and raw measurements](benchmarks/static-tick-font/README.md)
allow reproducing the baseline and candidate independently of the uncommitted
working-tree documentation.

Validation: 10086 non-fixture/non-golden package tests pass (84 skips), including
22 new cache cases and the scale integration case. All 150 targeted font/resolver
browser tests pass in both Chrome JavaScript and WebAssembly. The fixture runner
passes (26 files, no errors or warnings). Analysis, formatting, all port checks
and the regenerated parity report pass. The cache is an explicit framework-free
root in the import guard; its 33 checker tests pass as well.

## 29. Axis pipeline scan: options, bounds and invalidation

2026-11-02. This is an investigation, not a new production implementation.
[The complete report](axis-pipeline-options.md) inventories 18 improvement
families, describes the dependency/invalidation model, and distinguishes measured
configuration changes, unsafe structural ceilings and unimplemented estimates.
[Evidence and reproduction](benchmarks/axis-pipeline-scan/README.md) retain all
three 20-case sweeps, paired layout observations, a fresh CPU profile and a label
comparison microbenchmark. The baseline includes §27 and §28.

At 20,000 points, category x/logarithmic y and an 800 × 480 canvas, the current
baseline has 14.675 ms layout and a 24.192 ms full chart call. sampleSize 100
reduces these to 1.507 / 8.966 ms. With known bounds they become 0.686 / 8.061 ms.
A prototype reusing x-layout gives 0.998 / 7.655 ms with automatic y, and
0.223 / 7.204 ms with fixed bounds. Reusing all layout skips that phase and leaves
2.534 ms update and a 6.675 ms full call. These are local profile-AOT CPU figures,
not actual gallery FPS. Point drawing/updating remains a separate workload.

All of these alternatives match the unchanged scene's checked layout outputs.
Sampling misses a deliberately long unsampled label; blind caches fail on size,
label and domain changes. A warmed pass still makes 20,000 candidate ticks,
20,000 label conversions and 20,066 font requests. A cheap comparison of 20,000
ordinary string labels costs only 0.0201 ms in a separate AOT microbenchmark,
so a guarded cache need not require immutable inputs for that common case.

The recommended architecture caches content/metrics, axis geometry and paint
separately, retaining the full path for dynamic callbacks or unsupported hooks.
The target is roughly 0.3–0.6 ms of validated steady-state layout with known
bounds; this production cache has not been implemented. Configuration-only
sampling/bounds is a smaller option with explicit behavioral tradeoffs. The
report also records ineffective fixed rotation, hidden-axis work, and a large
hidden-tick draw regression caused by retaining 20,000 tick candidates while
preparing grid items before the grid display check.

## 30. Guarded category label measurement plans

2026-11-02. [ADR 0064](adr/0064-axis-label-plan.md) implements the content/metrics
part of the pipeline study, with live geometry. It keeps one full string-label
measurement plan per category scale, checks ordered content, static font inputs
and the native font environment, and reuses matching width/height aggregates.
It still creates fresh ticks and contexts, invokes user callbacks and hooks, and
runs rotation, auto-skip and fit against current dimensions and domains.

The exact built-in formatter also has guarded native-source dispatch after its
first normal read. Unknown Chart/Config subclasses, custom containers/tick lists,
non-default callbacks and dynamic/foreign fonts retain their ordinary paths.
Flutter font notifications advance a native metrics generation and clear text
caches. No sampling, fixed bounds or reduced point count is enabled.

A/B/B/A against the retained §28 implementation, Apple M3 Max, macOS 27.0.1,
Flutter 3.47.8 / Dart 3.13.7, arm64 profile AOT, Impeller, 800 × 480 at DPR 1.
Each cell has 1000 ms warmup and nine 250 ms batches. No builds/tests run alongside
measurement; all results are kept. Values are medians of two process results per
variant. Full calls sum each process's update, draw and recording-completion
medians first.

| X axis | N | Update ms, A → B | Layout ms, A → B | Full call ms, A → B |
| --- | ---: | ---: | ---: | ---: |
| category | 1000 | 0.936 → 0.570 | 0.675 → 0.287 | 1.353 → 1.006 |
| category | 5000 | 3.549 → 1.284 | 2.809 → 0.591 | 4.808 → 2.449 |
| category | 20000 | 16.331 → 5.425 | 13.553 → 2.483 | 22.571 → 10.724 |
| linear | 1000 | 0.515 → 0.493 | 0.253 → 0.240 | 0.873 → 0.837 |
| linear | 5000 | 1.099 → 1.074 | 0.412 → 0.399 | 2.216 → 2.175 |
| linear | 20000 | 3.452 → 3.425 | 1.029 → 1.016 | 7.591 → 7.551 |

**Keep the change.** At N=20000 the primary category update improves 66.0% and
67.6% in the paired runs, exceeding the 40% gate. Full-call savings are 52.0% and
53.0%, exceeding 30%. All x/y tick values, labels, rotation and chart bounds match
in all cells. No full-call control exceeds both the 5% and 0.1 ms regression gates.
Draw-only category N=20000 is 3.891 → 3.849 ms including recording completion.

A separate foreground 30-second run of the actual stress screen reports **60 FPS**,
44 visible x ticks at 50°, 5.31 ms update, 2.37 ms layout, 4.64 ms draw, 10.76 ms
average build (14.70 ms maximum), and 1.02 ms average raster. The existing runner
excludes startup. A background launch was throttled and yielded no valid FPS
summary; its log is retained but is not used as performance evidence. This result
is for profile mode on this Mac, not a promise about debug or other devices.

The measured approach is intentionally more conservative than the frozen-layout
prototypes of §29: fresh candidate/context work and automatic y limits remain.
The sub-1ms axis target is not claimed. Correctness checks additionally cover
in-flight getter mutation: the resolved first font must match its scalar inputs,
and root context, tick-list and option identities must remain valid before a hit.
Non-string labels cannot populate a plan after side-effectful conversion.

[Raw measurements, protocol, patches, frame statistics and validation](benchmarks/axis-label-plan/README.md)
include the preliminary measurement-only candidate and the final conservative
guard refinements. Cached/uncached twins compare all point positions through
label/font/domain/viewport changes, and user callback/getter behavior is pinned.

Final validation: 10107 VM package tests pass (84 skips; fixtures/goldens excluded),
43 final integration/guard cases pass on each of Chrome JavaScript and WebAssembly,
and the fixture runner passes (26 files, zero errors/warnings). Analysis, formatting,
all port checks and regenerated parity pass. The temporary browser harness was
removed from test/ after validation. No golden files were changed.

## 31. Deferred contexts for unobserved ticks

2026-11-02. [ADR 0065](adr/0065-lazy-tick-context.md) is a focused follow-up to
§30: after a label-plan hit, Tick captures the original parent and index, then
constructs its context on first read. Repeated reads retain identity, explicit
writes/clears override pending creation, and retained skipped ticks still expose
the context from their own update. Hooks that inspect every context still obtain
every context. No callback, point, label or geometry calculation is suppressed.

A/B/B/A against the validated §30 implementation, Apple M3 Max, macOS 27.0.1,
Flutter 3.47.8 / Dart 3.13.7, profile AOT, Impeller, 800 × 480, 20000 points.
Seven 200 ms batches follow 800 ms warmup; no builds/tests run alongside timing.
All four runs are kept. Full-call figures sum update, draw and recording completion
within each process before taking the median across processes.

| Case | Layout ms, A → B | Full chart call ms, A → B |
| --- | ---: | ---: |
| Category/logarithmic, automatic bounds | 2.598 → 2.013 | 11.083 → 9.337 |
| Same, known bounds | 1.779 → 1.172 | 10.116 → 8.518 |
| sampleSize 100 control | 1.504 → 1.566 | 8.796 → 8.907 |
| Custom scale/font control | 8.889 → 9.012 | 16.806 → 17.047 |
| Draw-only control | 0 → 0 | 3.865 → 3.893 |

The primary layout reduction is 22.5%, and the full-call reduction is 15.8%.
Both primary pairs exceed the 10% layout gate. No control has a repeatable
full-call increase above both 5% and 0.1 ms. Keep the measured tradeoff: unsupported
paths still allocate the slightly larger Tick objects; their small increases are
shown rather than described as zero. Tick values/labels, limits, rotation and chart
bounds agree exactly across all runs.

This change adds CPU headroom to the previously measured 60 FPS implementation;
no higher FPS is claimed or newly measured here. Layout is still about 2 ms with
automatic y limits. The numeric-range and further label-loop experiments are not
part of this change. [Protocol, raw data and reproduction](benchmarks/lazy-tick-context/README.md).

Validation: all 10112 permanent VM package tests pass (84 skips), as do all 19
context/layout integration cases on each of JavaScript and WebAssembly. The
fixture runner passes with zero errors/warnings; analysis, formatting, parity and
all port checks pass. The temporary browser harness was removed after testing.
Only this focused runtime change is retained.

## 32. Bar updates, looping animation and native picture painting

2026-11-02. [Investigation and implementation priorities](bar-performance.md),
with [raw evidence and reproduction](benchmarks/bar-pipeline/README.md). No
production runtime or gallery configuration change is included.

The existing 20,000-bar stress configuration reproduces a 41.323 ms update,
13.145 ms draw and 51.482 ms host paint/record completion: a 105.950 ms full CPU
call. A looping animation frame is 63.721 ms, including only 1.513 ms ticking
animations. These are local arm64 macOS profile-AOT figures at 800 × 480, DPR 1,
from two forward/reverse sweeps. They are not measured FPS.

Separate profiles attribute 50.2% of update samples and 77.6% of animation
samples to native `Canvas.drawPicture`. A pure Flutter rectangle reproduction
confirms the cost independently of Chart.js. Its 20,000-rectangle full call drops
from 53.941 to 7.210 ms when recording at most 256 rectangles per picture;
`drawPicture` drops from 50.367 to 3.443 ms. All twelve local Impeller RGBA
comparisons match exactly, including translucency, overlap and fractional clips.
This is a native prototype, not an integrated canvas change: the existing
8-picture flattening threshold and the full canvas state/compositing API need
explicit treatment before adopting it.

An isolated, unguarded per-update bar-index memo reduces the chart update from
41.323 to 23.425 ms; full calls improve from 105.950 to 88.864 ms. The draw
component increases from 13.145 to 14.791 ms and is retained in the comparison.
Two geometry tests pass for all checked properties through four updates and
resize, at N=1000 and 20000. Dynamic callbacks/getters, subclasses and indexed
stack behavior remain production design requirements.

Prioritize bounded native recordings, then a guarded bar-index plan. Removing
borders or animating fewer properties barely changes the dominating host paint
cost. Fixed bar thickness with automatic inflation makes this workload much
worse by enabling per-bar clipping. No combined-candidate gain, actual FPS
improvement or mobile/web result is claimed.

## 33. Bounded native recordings for dense bar charts

2026-11-02. [ADR 0066](adr/0066-bounded-canvas-recordings.md) implements the first
recommendation of §32. `UiCanvasContext` ends a picture after 256 non-batched
paint calls. The next recorder replays existing logical clips. Drawing order,
current paths, styles, transforms, composite behavior and all chart items remain
unchanged. Circle runs keep their existing batching. Retention now counts eight
completed paint/snapshot generations, rather than eight internal picture chunks,
so a large frame does not immediately trigger image flattening.

A/B/B/A against `1d37d64`, Apple M3 Max, macOS 27.0.1, Flutter 3.47.8 / Dart
3.13.7, arm64 profile AOT, Impeller, 800 × 480 at DPR 1. Seven 200 ms batches
follow 800 ms warmup. No builds/tests ran alongside measurement. Full CPU calls
sum update/tick, draw and host paint/record completion within each process, then
take the median across its two process results.

| N | Bar update full call, before → after | Draw-only full call, before → after | Animation frame CPU, before → after |
| ---: | ---: | ---: | ---: |
| 1000 | 4.527 → 3.222 ms | 2.380 → 1.113 ms | 2.083 → 1.114 ms |
| 5000 | 19.071 → 15.300 ms | 7.928 → 4.127 ms | 8.056 → 4.346 ms |
| 20000 | 108.629 → 60.291 ms | 64.376 → 15.596 ms | 63.474 → 17.151 ms |

**Keep the change.** At 20k, updates improve 44.5%, draw-only calls 75.8%, and
animation CPU 73.0%. Both pairs pass the predeclared primary gates. The update's
host paint/completion falls from 51.766 to 2.323 ms; update logic remains about
43–44 ms and drawing about 14 ms. There is no bar-index cache in this change.
Line and bubble controls stay within the combined 5%/0.1 ms regression limits.
Doughnut drawing and fixed-thickness bars also improve; all control figures are
retained rather than inferred from the primary case.

Separate 25-second runs of the actual stress screen activate each exact process
and retain 24–25 timing windows. The final foreground comparison at N=20000, M=0 is:

| Operation | Before FPS | After FPS | Before/after average build | Before/after average raster |
| --- | ---: | ---: | ---: | ---: |
| Update each frame | 8.33 | 15.00 | 115.91 → 61.20 ms | 15.41 → 14.13 ms |
| Looping animation | 12.72 | 49.42 | 73.79 → 18.64 ms | 15.01 → 13.89 ms |

These are local profile-mode FPS measurements, one process per cell, not mobile
or web performance claims. The remaining bar-controller work still limits update
FPS. Animation is much smoother but does not reach a measured 60 FPS here.

[Protocol, harnesses, patches, every raw measurement and validation](benchmarks/bar-implementation/README.md)
include an initial mislabeled line-control selector (excluded from bar-update
results) and preliminary foreground runs with short candidate windows (excluded
from the final FPS comparison). The corrected explicit bar-update series and
process-specific foreground activation provide the reported results.

Validation: all 10,678 workspace tests pass (the Chart.js package has 10,144
passes and 84 skips), as do all 32 new canvas cases in each of Chrome JavaScript
and WebAssembly. The fixture runner passes 26 files with zero errors/warnings.
Analysis, formatting, regenerated parity and all port checks pass. The temporary
browser harness was removed. No golden image was changed.

## 34. Scalar geometry for ordinary bar drawing

2026-11-02. [ADR 0067](adr/0067-scalar-bar-geometry.md) removes temporary corner,
bounds and inflated-rectangle objects from the ordinary BarElement draw. The
branch accepts only the exact built-in element, final typed options/edges,
numeric zero radius, positive-zero inflation, finite scalar border width and
positive finite outer bounds. It preserves every canvas call, its order, the
color-setter timing and the final current path. Other inputs keep the original
path. There is no option/geometry cache or native renderer substitution.

A/B/B/A against §33's bounded-recording implementation, Apple M3 Max,
macOS 27.0.1, Flutter 3.47.8 / Dart 3.13.7, arm64 profile AOT, Impeller,
800 × 480 at DPR 1. Seven 200 ms batches follow 800 ms warmup. Full CPU calls
sum update/tick, draw and host paint/completion in each process before taking
the median of its two results. No builds/tests ran alongside measurements.

| N | Bar draw full call, before → after | Animation frame CPU, before → after | Bar update full call, before → after |
| ---: | ---: | ---: | ---: |
| 1000 | 1.101 → 0.967 ms | 1.119 → 0.997 ms | 3.237 → 3.269 ms |
| 5000 | 4.039 → 3.327 ms | 4.374 → 3.635 ms | 14.584 → 13.563 ms |
| 20000 | 15.569 → 13.182 ms | 17.532 → 14.883 ms | 59.498 → 56.507 ms |

**Keep the change.** At 20k, draw full calls improve 15.3% and animation frame
CPU 15.1%. Both pairs pass the predeclared 10% gate. Drawing itself is
13.389 → 10.949 ms in draw-only and 13.937 → 11.284 ms during animation.
No rounded/inflated-bar or line/bubble/doughnut control has a repeatable full-call
regression above both 5% and 0.1 ms. The 20k full-update result is noisier:
its pairs improve 0.6% and 9.3%; dataset updating is unchanged and dominates it.

Separate foreground stress runs at 20k bars give:

| Operation | Before FPS | After FPS | Before/after average build | Before/after average raster |
| --- | ---: | ---: | ---: | ---: |
| Update each frame | 15.15 | 16.28 | 60.01 → 57.56 ms | 14.44 → 14.49 ms |
| Looping animation | 48.88 | 58.43 | 18.84 → 16.50 ms | 14.41 → 14.72 ms |

These are one local profile-mode process per cell, with exact process activation,
not a platform-wide FPS guarantee. Each scenario runs for 25 seconds; the candidate
animation has 18 complete timing windows and the other cells 24. The shorter
coverage is retained in the raw evidence. Its build P90 is 17.26 ms: animation is
close to 60 FPS but is not a measured sustained 60 FPS result. Continuous updates
remain limited by dataset-controller work.

[Protocol, patches, raw profiles/timings, foreground windows and validation](benchmarks/bar-draw/README.md)
retain the preliminary scalar implementation and the final signed-zero/degenerate
fallback refinements separately. The test grid compares drawing traces for 3,456 input combinations,
extra fallback/getter cases, and 108 exact pixel twins against the
unchanged subclass path. No bar is aggregated or dropped, and no golden is updated.

Validation: all 10,688 workspace tests pass (the Chart.js package has 10,154
passes and 84 skips). All ten targeted tests pass in both Chrome JavaScript and
WebAssembly. Fixtures pass 26 files with zero errors/warnings. Analysis,
formatting, regenerated parity and all port checks pass. The temporary browser
harness was removed; no golden files were changed.

## 35. Live bar update layout and property construction

2026-11-02. [ADR 0068](adr/0068-live-bar-update-layout.md) targets the remaining
update cost after §34. For the ordinary single-dataset case it proves the current
axis count and axis/stack position through guarded native reads. It observes
state before and after category-trait resolution, reusing a proof only across
cached primitive reads that cannot execute user code. Container types are
classified by identity, but values, routes, list lengths and metadata remain live.
Unknown/custom/multiple-dataset/indexed-stack cases retain the original path.

Owned finite nondecreasing scale values also skip sorting, with uniqueness
unchanged. BarProperties constructs its initial seven fields and key-order bits
together, preserving independent objects, field order and later mutations.
No parsing, point, callback or draw is suppressed.

A/B/B/A against the validated §34 runtime, Apple M3 Max, macOS 27.0.1,
Flutter 3.47.8 / Dart 3.13.7, arm64 profile AOT, Impeller, 800 × 480 at DPR 1.
Seven 200ms batches follow 800ms warmup; no builds/tests run alongside timing.
Full calls sum update, draw and host paint/completion in each process first.

| N | Full update CPU, before → after | Improvement |
| ---: | ---: | ---: |
| 1000 | 3.070 → 2.039 ms | 33.6% |
| 5000 | 14.020 → 8.062 ms | 42.5% |
| 20000 | 55.747 → 35.962 ms | 35.5% |

At 20k, update-only work falls 42.436 → 21.764ms, including dataset updating
37.855 → 17.404ms. Keep the component tradeoff: draw inside an update increases
11.012 → 11.948ms; paint/completion stays about 2.3ms. Full calls improve in both
pairs (34.9% and 36.1%), exceeding the predeclared 20% gate.

**Keep the change.** No control has a repeatable regression above both 5% and
0.1ms. The controls include rounded/inflated bars, multiple datasets, skipNull,
scriptable colors and line/bubble/doughnut. The 20k animation pairs vary (+5.5%
and -3.7%); both are retained. Draw-only remains essentially unchanged.

Foreground 25-second stress runs at 20k bars give:

| Operation | Before FPS | After FPS | Before/after average build | Before/after average raster |
| --- | ---: | ---: | ---: | ---: |
| Update each frame | 16.59 | 23.97 | 56.88 → 37.55 ms | 12.56 → 13.54 ms |
| Looping animation | 59.90 | 59.81 | 15.85 → 16.08 ms | 13.46 → 13.71 ms |

These are local profile-mode measurements with exact process activation and
24–25 complete one-second windows per run. Continuous updates still do not reach
60 FPS: the remaining update, parsing and drawing exceed the 16.67ms frame budget.
No mobile/web performance gain is inferred.

[Protocol, patches, profiles, all timings, foreground windows and validation](benchmarks/bar-update/README.md)
retain the failed initial guard (runtimeType inspection dominated it), the
identity-classification iteration and the final pure-trait/property-construction
version. The native branch is tested against the original subclass path through
mutations and reentrant updates, with explicit cold-cache and custom-source guards.

Validation: all 10,700 workspace tests pass (the Chart.js package has 10,166
passes and 84 skips). All twelve targeted tests pass in each of Chrome JavaScript
and WebAssembly. Fixtures pass 26 files with zero errors/warnings. Analysis,
formatting, regenerated parity and all port checks pass. The temporary browser
harness was removed. No golden files were changed.

## 36. Bulk numeric bar updates

2026-11-02. [ADR 0069](adr/0069-bulk-numeric-bar-updates.md) preserves the first
ordinary item and preflights the remainder of an update in mode `none`. Eligible
native numeric bars reuse scalar settings and base/grid calculations and write
element fields directly, preserving order, visibility, fresh skipped-edge
objects, shared options and undefined state. No parsing, hook, callback or bar
is dropped. Unsupported inputs retain the ordinary loop before any bulk writes.
Visible axes qualify only with proven static grid lookups; scriptable grids do not.

A/B/B/A against §35, Apple M3 Max, macOS 27.0.1, Flutter 3.47.8 / Dart 3.13.7,
arm64 profile AOT, Impeller, 800 × 480 at DPR 1. Seven 200ms batches follow 800ms
warmup, with no concurrent builds/tests. Full calls sum update, draw and host
paint/completion within each process before taking the median of its two runs.

| N | Full update CPU, before → after | Improvement |
| ---: | ---: | ---: |
| 1000 | 2.187 → 1.577 ms | 27.9% |
| 5000 | 8.923 → 5.530 ms | 38.0% |
| 20000 | 37.582 → 26.876 ms | 28.5% |

At 20k, update-only work falls 22.872 → 10.382ms and dataset updating
18.212 → 4.704ms. Retain the component tradeoff: drawing inside updates rises
12.394 → 14.042ms, and element preparation 3.697 → 4.540ms in this series.
The full call includes these costs. Their shifts have not been isolated.

**Keep the change.** Both 20k pairs exceed the 15% gate (31.1% and 25.5%). No
control has a repeatable regression above both 5% and 0.1ms. Controls include
rounded/inflated bars, multiple datasets, skipNull, scriptable colors, other chart
types, draw and animation. All measurements are retained.

A fresh foreground comparison checks process activity throughout each 25-second
scenario; every check is active and both runs retain 24 one-second windows:

| Metric at 20000 bars | Before | After |
| --- | ---: | ---: |
| Continuous update FPS | 23.88 | 31.12 |
| Average update computation | 21.86 ms | 9.89 ms |
| Average Flutter build | 37.54 ms | 27.22 ms |
| Average raster | 14.09 ms | 13.74 ms |

These are local profile-mode results, one process per cell. The full frame still
exceeds the 16.67ms budget for 60 FPS; drawing/painting now costs more than the
bulk update. No mobile/web performance gain is inferred.

[Protocol, source patches, every timing run, activity monitoring and validation](benchmarks/bar-bulk/README.md)
retain the initial inactive guard and the shorter preliminary foreground sample.
Activation and geometry tests cover both orientations, static visible grids,
callback-preserving fallbacks, partial ranges, custom classes and late invalid
items. An owner-mismatch guard also prevents borrowing a scale from another chart.

Validation: all 10,713 workspace tests pass (the Chart.js package has 10,179
passes and 84 skips), as do all thirteen targeted tests in each of Chrome
JavaScript and WebAssembly. Fixtures pass 26 files with zero errors/warnings.
Analysis, formatting, regenerated parity and all port checks pass. The temporary
browser harness was removed. No golden files were changed.

## 37. Direct native drawing of ordinary rectangular bars

[ADR 0070](adr/0070-native-rectangular-bar-drawing.md) offers the existing scalar
bar geometry to an optional native context operation. Supported solid-color bars
skip intermediate border paths and save-state copying. The final inner path,
styles, clips, draw order, notifications and recording counts remain. Callback-
observable, complex and unsupported cases retain the ordinary sequence. No bars
are merged, approximated or removed.

A/B/B/A against `5dafa22`, Apple M3 Max, macOS 27.0.1, Flutter 3.47.8 / Dart
3.13.7, arm64 profile AOT, Impeller, 800 × 480 at DPR 1. Seven 200ms batches
follow 800ms warmup; no builds/tests run alongside timing. Full calls sum update,
draw and host paint/completion within each process before aggregating its two runs.

| N | Full draw call, before → after | Full update call, before → after | Animation frame CPU, before → after |
| ---: | ---: | ---: | ---: |
| 1000 | 0.934 → 0.813 ms | 1.545 → 1.413 ms | 0.958 → 0.822 ms |
| 5000 | 3.223 → 2.554 ms | 5.476 → 4.714 ms | 3.479 → 2.845 ms |
| 20000 | 12.586 → 10.051 ms | 25.627 → 21.912 ms | 13.970 → 11.206 ms |

**Keep the change.** Full draw calls improve 20.1% at 20k, with both pairs passing
the 15% gate (19.7% and 20.6%). Updates improve 14.5% and animation CPU 19.8%.
Draw-only drawing falls 10.518 → 8.001ms; recording completion stays about 2.1ms.
No rounded/inflated, other-chart, multi-dataset, indexed or scriptable control has
a repeatable regression above both 5% and 0.1ms. All component shifts are retained.

Monitored foreground 25-second stress runs at N=20000, M=0:

| Operation | Before FPS | After FPS | Before/after average build | Before/after average raster |
| --- | ---: | ---: | ---: | ---: |
| Update each frame | 31.15 | 35.61 | 27.11 → 24.05 ms | 14.29 → 14.21 ms |
| Looping animation | 59.87 | 59.92 | 16.00 → 13.73 ms | 13.91 → 13.72 ms |

The original baseline update run lost focus and is excluded. Its replacement
and all reported candidate/animation runs pass the activity monitor and retain
24 complete one-second windows. These are one local process per cell, not a
cross-device guarantee. Updates still exceed the 16.67ms budget for 60 FPS;
animation gains CPU headroom while remaining at the display-rate ceiling.

[Protocol, source, every timing run, activity logs and validation](benchmarks/bar-native/README.md)
retain the invalid foreground run and its replacement. Exact pixel/state twins
cover all blend modes, errors, observers and current-path use. No golden changed.

Validation: all 10,748 workspace tests pass (the Chart.js package has 10,214
passes and 84 skips), as do all 35 new tests in each of Chrome JavaScript and
WebAssembly. Fixtures pass 26 files with zero errors/warnings. Analysis, format,
regenerated parity and all port checks pass. The temporary browser harness was
removed; no golden files were changed.

Pre-push validation also passes the complete Chrome JavaScript and WebAssembly
suites (3,982 Chart.js tests and 55 utility tests per backend) and the upstream
case check (958 passed, 78 skipped, zero failures).

A separate candidate CPU profile identifies parsing as the next update target:
20.9% of samples within `Chart.update` include parsing, with repeated category
label retrieval a major contributor. The proposed guarded numeric/category
parse path and raw profile are recorded in the benchmark README. This is a
profiling recommendation, not a measured gain from an implemented change.

## 38. Guarded numeric category parsing

[ADR 0071](adr/0071-numeric-category-parsing.md) shares a primitive parsing
shortcut between bars and the base dataset controller. It retains the initial
ordinary label-source read, then preflights native data and labels under exact
category/linear scale guards. Each parsed record remains fresh; custom sources,
scales, floating bars, coercible values and unusual labels use ordinary parsing.
There is no cross-update cache or data aggregation.

A/B/B/A against `65fc68f`, Apple M3 Max, macOS 27.0.1, Flutter 3.47.8 / Dart
3.13.7, arm64 profile AOT, Impeller, 800 × 480 at DPR 1. Seven 200ms batches
follow 800ms warmup. No builds/tests run concurrently. Full-call figures sum
update, draw and host completion within each process before aggregation.

| N | Full update call, before → after | Improvement |
| ---: | ---: | ---: |
| 1000 | 1.423 → 1.304 ms | 8.4% |
| 5000 | 4.744 → 4.267 ms | 10.1% |
| 20000 | 21.697 → 19.582 ms | 9.7% |

Both 20k pairs pass the predeclared 8% full-call gate (11.3%, 8.2%). Element
preparation, which includes parsing, falls 4.220 → 1.231ms (70.8%); update CPU
falls 10.625 → 8.443ms (20.5%). The measured layout component rises
1.171 → 1.827ms; the reported totals include that increase. Drawing and
animation-only controls are broadly unchanged. No control has a repeatable regression above both 5% and 0.1ms.
The object-data line control does not use the primitive shortcut; activation
and behavior for primitive line data are verified separately in the twins.

[Protocol, source hashes, raw timing runs, controls and validation](benchmarks/primitive-parse/README.md)
retain the complete comparison. The full update still exceeds 16.67ms; this is
not a claim of 60 FPS or of equivalent gains on mobile/web.

Separate 25-second foreground runs at N=20000, M=0 improve **34.92 → 39.73 FPS**.
Average build falls 24.46 → 22.04ms, with raster 14.29 → 14.17ms. Both processes
remain active at every monitor check and yield 24 complete one-second windows.
These are local single-process observations, not a cross-device guarantee.

Validation: the workspace suite passes, including all 15 new regressions. The
same 15 pass in Chrome JavaScript and WebAssembly. Fixtures pass 26 files with
zero errors/warnings; analysis, format, regenerated parity and all port checks
pass. The temporary browser probe is removed and no golden files change.

A fresh candidate CPU profile identifies bar spacing calculation as the next
update target: ruler creation appears in 19.9% of samples within `Chart.update`,
including 7.7% in hash-set deduplication. Parsing is now 8.8%. These inclusive
shares overlap. The benchmark README records the raw profile and a proposal to
reuse projected positions and linearly deduplicate sorted values under native
scale guards. The proposed follow-up has no measured speedup yet.

Pre-push checks also pass the complete Chrome JavaScript and WebAssembly suites
(3,982 Chart.js tests and 55 utility tests per backend) and the upstream case
check (958 passed, 78 skipped, zero failures).

## 39. Sequential bar spacing experiments

The two proposals were implemented and evaluated separately against `3d10094`.
[ADR 0072](adr/0072-bar-position-reuse.md) records the rejected position-reuse
experiments. Native projection/value guards passed correctness tests, but copied
indexes added overhead; an allocation-free version also failed the gate. The
final fused version improved its isolated pilot but regressed the first complete
full-workload pair, 20.511 → 20.898ms. It was removed before step 2. No projection
reuse or cross-update geometry cache remains in the library.

[ADR 0073](adr/0073-sorted-bar-values.md) is retained. It replaces hash-based
uniqueness checks only for owned finite sorted bar values. Unique input lists
retain identity and signed zero; duplicate results remain growable and normalize
zero exactly like the old Set. Unsorted/nonfinite values retain sort/arrayUnique.
User controller calls and source enumeration still run before the owned scan.

M3 Max, macOS 27.0.1, Flutter 3.47.8 / Dart 3.13.7, arm64 profile AOT,
Impeller, 800 × 480 DPR 1. A/B/B/A, seven 200ms batches after 800ms warmup;
no builds/tests run alongside measurements. Full calls sum per-process update,
draw and host-completion medians before averaging the two process results.

| N | Full update before → after | Improvement |
| ---: | ---: | ---: |
| 1000 | 1.330 → 1.280 ms | 3.8% |
| 5000 | 4.367 → 4.092 ms | 6.3% |
| 20000 | 20.100 → 19.620 ms | 2.4% |

Both 20k pairs pass the predeclared 2% gate (2.3%, 2.5%). Dataset update CPU
falls 5.232 → 4.615ms (11.8%); total update CPU falls 8.817 → 8.320ms (5.6%).
No control exceeds both 5% and 0.1ms in both pairs. The animation CPU control
moves 11.442 → 11.963ms (+4.6% overall, +5.5%/+3.6% per pair); all these
component shifts are retained, without attributing each shift to this change.

Separate foreground 25-second update runs improve **39.06 → 42.87 FPS** at
N=20000, M=0. Average build falls 22.13 → 20.90ms; raster is 13.76 → 13.91ms.
Both stay active at every check and retain 24 complete one-second windows.
These are local measurements, not a mobile/web or 60-FPS guarantee.

[Protocol, every attempt, exact sources, measurements and validation](benchmarks/bar-spacing/README.md)
retain the unsuccessful position-reuse work as well as the accepted scan.

Monitored animation remains 59.92 → 59.96 FPS, with average build
13.77 → 14.12ms and raster 14.09 → 13.71ms; both runs remain active for all
24 windows. This provides no evidence of a display-rate regression on this host.

Validation: all 10,779 workspace tests pass (10,245 Chart.js passes and 84 skips).
All 16 new helper cases pass in Chrome JavaScript and WebAssembly. Fixtures
pass 26 files with zero errors/warnings; analysis, format, generated parity and
all port checks pass. The helper is registered as a framework-free root so its
tests stay in the regular web suites. No golden files change.

## 40. Architectural review: lifecycle, representation and display resolution

This investigation changes no production runtime or gallery source. The current
worktree includes ADR 0073. Diagnostic probes run in separate temporary profile
apps on M3 Max / macOS 27.0.1 / Flutter 3.47.8 / Dart 3.13.7, Impeller,
800 × 480 DPR1, seven 200ms batches after 800ms warmup. Two runs reverse the case
order; no builds/tests run during timing. These are isolation experiments, not
shipping candidates or measured foreground FPS.

### Full update versus restricted values-only work

| Work at 20k bars | CPU update/draw/record completion |
| --- | ---: |
| Change data and call full update | 20.198 ms |
| Restricted values-only geometry and ordinary draw | 10.521 ms |
| Call full update without changing data | 18.538 ms |
| Existing-chart draw only | 10.081 ms |

Both changing cases include simulation and data writes in the timed call. The
values-only prototype fixes axes, layout, index positions and styles, and only
updates y/height for one positive numeric dataset. It deliberately omits parsing,
update hooks and parsed-data synchronization. After each case, every bar's
x/y/base/width/height matches a full update of that current data. This verifies
geometry only for this restricted scene; it is not a production update API or a
promise of 60 FPS. Implementing a real contract must preserve data, interactions,
metadata, plugin behavior and invalidation rules within its documented scope.

`core.controller.dart` update still refreshes configuration/resolvers, scales,
event bindings, plugin state, parsing/elements, layout and datasets before draw.
Mode none is an animation mode, not a values-only change declaration. The typed
facade reconciles scopes in `typed/lower.dart`, but ChartView still ends in the
same full update path. Raw mutable Maps and callbacks prevent reliable cheap
inference of unchanged configuration. This explains why additional guards and
per-point validation can consume the benefit of local reuse.

The hidden category axis still reports 20,000 ticks. CategoryScale.buildTicks
constructs that list, and Scale.update rebuilds ticks and invalidates layout
caches. Primitive parsing constructs fresh ParsedItems. Those are specific
allocation/lifecycle costs even when labels, domain and layout are stable; GC's
share has not been separately measured here.

### Prepared-data performance cliff

A second independent sweep compares data representations, with all three cases
including simulation and writes. Prepared inputs update their existing objects;
all geometry is checked against a fresh ordinary numeric chart of the same data.

| Representation at 20k bars | Full-frame CPU |
| --- | ---: |
| Ordinary numeric input with parsing | 19.003 ms |
| parsing:false, ordinary x/y Maps | 28.917 ms |
| parsing:false, internal ParsedItem records | 17.193 ms |

All prepared geometry checks pass. The internal-record case is diagnostic only,
not a recommendation to import private types. The bulk numeric updater explicitly
requires ParsedItem; ordinary prepared Maps keep generic reads and the ordinary
per-element update path. Thus skipping parsing can disable another optimization.
A coherent public native data representation is a more useful direction than
adding unrelated type-specific fast paths. Earlier reference checks that toggled
parsing mode in the existing chart produced invalid geometry and were excluded;
only the fresh-reference sweeps are summarized.

### Resolution, rendering and scheduling

The 20k/800px scene draws 25 bars per horizontal physical pixel at DPR1. Full
frames at N=800 cost 1.508ms. This is a complexity comparison, not an equivalent
aggregation: an overview mode needs an explicit binning/selection policy and
must retain full data for zoom and interaction. Chart.js's decimation plugin is
for lines, not a ready-made bar aggregation feature.

A raw native control with opaque, borderless prebuilt rectangles costs 6.989ms
at 20k, including recording/completion. It is not visually equivalent to the
chart and does not include raster timing. It shows that per-shape native work
has a cost even without the port. Existing foreground results put UI/build near
21ms and raster near 14ms, with looping animation already near 60 FPS. These
thread durations overlap and must not be added as a single frame budget.

The host is already a canvas repaint boundary. Canvas change notifications and
scheduled frame requests are coalesced; the stress stats update at half-second
intervals. There is no evidence here of a 20k-widget rebuild or duplicate-frame
storm. Stress-mode simulation/data writes are outside the displayed update/draw
stopwatches, so FPS and full-frame measurements remain necessary. ChartView's
post-frame update scheduling also warrants end-to-end latency measurement.

### Recommended direction

Prioritize an explicit incremental/streaming update contract: declare values,
indexes, styles/options and viewport changes separately; version stable inputs;
reuse layout/ticks/index geometry when those versions are unchanged; and use a
consistent typed numeric data path. Keep the full Chart.js-compatible update for
raw arbitrary mutation and unsupported hooks. Define metadata/plugin/interaction
semantics before treating the 10.5ms prototype as a shipping implementation.
Resolution-aware overview rendering is a separate opt-in feature. A general GPU
rewrite is not the first recommendation from these results.

[Probe sources, raw runs, reference checks and metadata](benchmarks/bar-architecture/README.md)
retain both comparisons. Supporting upstream guidance: [Chart.js updates](https://www.chartjs.org/docs/latest/developers/updates.html),
[Chart.js performance](https://www.chartjs.org/docs/latest/general/performance.html),
[decimation scope](https://www.chartjs.org/docs/latest/configuration/decimation.html),
and [Flutter profiling](https://docs.flutter.dev/perf/ui-performance).

## 41. Production incremental data updates

[ADR 0074](adr/0074-incremental-data-updates.md) adds Chart.updateData as an
explicit shared lifecycle across the eight native controllers. Parsing,
metadata/stacks, geometry, compatible hooks and interaction replay remain live;
unchanged settings, ranges, ticks and layout are retained. A completed full
update defines the generation. Each native source is preflighted once per
generation/replacement; callers keep record implementations/keys and numeric
value kinds stable within an existing source. Known unsupported conditions use
update('none'). In-place configuration/label/metadata edits require full update.

Two forward/reverse profile-AOT sweeps, M3 Max / macOS 27.0.1 / Flutter 3.47.8 /
Dart 3.13.7 / Impeller, 800×480 DPR1. Seven 200ms batches after 800ms warmup, no
concurrent builds/tests. Both cases include identical simulation and data writes.
Full CPU calls sum per-process update/draw/record completion before aggregation.
Line/scatter use explicitly bounded, sorted fixed x indexes; the original
suggested-bound stress presets correctly select full fallback.

| Chart/input | N | Full → incremental CPU | Improvement |
| --- | ---: | ---: | ---: |
| Bar, numeric | 20000 | 19.883 → 15.550 ms | 21.8% |
| Bar, prepared Maps | 20000 | 28.212 → 15.111 ms | 46.4% |
| Bar, numeric | 5000 | 4.012 → 3.282 ms | 18.2% |
| Bar, prepared Maps | 5000 | 6.388 → 3.664 ms | 42.6% |
| Bar | 1000 | 1.250 → 0.966 ms | 22.8% |
| Line | 1000 | 0.492 → 0.277 ms | 43.8% |
| Scatter | 1000 | 0.591 → 0.396 ms | 33.1% |
| Bubble | 1000 | 1.814 → 1.616 ms | 10.9% |
| Doughnut | 1000 | 2.407 → 2.330 ms | 3.2% |
| Pie | 1000 | 2.059 → 1.970 ms | 4.3% |
| Radar | 1000 | 0.858 → 0.643 ms | 25.0% |
| Polar area | 1000 | 2.349 → 2.093 ms | 10.9% |

Numeric bars pass the 15% full-call gate in both 20k pairs (20.6%, 22.9%). Every
final incremental case selects the intended path with zero fallback calls and
matches complete parsed state, geometry and selected styles against a subsequent
full update. These are restricted supported configurations, not a guarantee for
all options/plugins. Pie/doughnut remain drawing-dominated.

An A/B/B/A control of ordinary full updates against the pre-feature binary shows
no repeatable regression above both 5% and 0.1ms: 20k pair shifts are -1.2% and
-2.5%; smaller cases remain within the gate. Initial regressions from repeated
record preflight and a narrow prepared-list guard were corrected, with their
sources and measurements retained rather than discarded.

After the desktop was unlocked, monitored foreground runs at N=20000, M=0
improve **43.17 → 56.29 FPS** (+30.4%). Both use the same logical canvas,
736.0 × 441.6 at DPR 2; every activity check is true and the incremental route
is confirmed. The runs retain 24 and 25 complete one-second windows respectively
(window-mean FPS: 42.92 and 55.92).

Average UI/build falls 20.70 → 16.89ms; its p50 is 20.85 → 15.95ms and p90
23.09 → 19.68ms. Raster is 12.77 → 13.13ms. This is a substantial foreground
gain, but not steady 60 FPS: UI frame-time spikes still exceed 16.67ms. These
are local observations from one process per case. Earlier locked-desktop runs
remain retained and excluded; foreground-unlocked.json records the valid runs.

[Source snapshots, full/partial controls, raw runs and validation](benchmarks/data-update/README.md)
retain the production comparison separately from the §40 upper-bound prototype.

Validation: 10,812 workspace tests pass (10,278 Chart.js passes, 84 skips).
All 31 incremental lifecycle tests and eight category-source tests pass on both
browser backends. The complete web suites pass 4,000 Chart.js cases and 55 utility
cases per backend. Fixtures pass 26 files with zero errors/warnings. Public API,
analysis, format, generated parity and all port checks pass. No golden changed.

## 42. Cached native indexed element options

[ADR 0076](adr/0076-indexed-element-options.md) reuses already-cached scalar and
indexed element-option inputs for native PointOptions and BarOptions. The common
options no longer require fresh contextual resolver views and caches per element.
Lists remain live; each result is fresh and normally unshared. Context refresh,
including the original pre-context `$shared` store, remains observable. Custom
callbacks, descriptors, containers, nested/empty values and unsupported result
classes retain ordinary resolution. Numeric indices convert to JavaScript numbers
before remainder, including VM integers above 2^53.

The controller qualifies key-list producers by identity and declares its own
containers. This avoids expensive generic runtime-type probes per element. A
conservative rejected-plan memo avoids taxing scriptable fallback. Preliminary
versions with callback regressions and the profiles that located them are retained.

macOS 27.0.1 arm64, Flutter 3.47.8 / Dart 3.13.7, native profile AOT, 800×480/DPR1.
A/B/B/A processes, forward/reverse case order, 800ms warmup and seven 200ms batches.
All scenes have 5000 elements and the same color supplied as a static value,
a one-entry list or a constant callback. No builds/tests run during measurement.
The table compares baseline and final indexed scenes:

| Chart | Update CPU | Update reduction | Full CPU estimate | Full reduction |
| --- | ---: | ---: | ---: | ---: |
| Line | 12.348 → 6.066 ms | 50.9% | 13.290 → 7.018 ms | 47.2% |
| Bar | 14.960 → 9.687 ms | 35.3% | 17.913 → 12.546 ms | 30.0% |
| Radar | 13.610 → 7.299 ms | 46.4% | 15.873 → 9.436 ms | 40.6% |

Full CPU sums update/draw/paint-end phase medians per process, then averages the
two processes; it is not a full-call percentile. Data simulation is outside the
phase timers. Per-process values and paired gains are retained; local variation
is visible in the raw results. This is not FPS, raster or mobile/web performance.

Static and constant-callback controls have no repeated full-call regression above
both 5% and 0.1ms. A separate A/B/B/A `theme.switch` doughnut control at N=1000
exercises the unsupported indexed-arc path and remains within that gate.
The indexed path remains slower than shared static options: it retains fresh
options, context refresh and the controller's ordinary key/scope discovery.

The native list allowlist includes ordinary SDK Color/Object/primitive list
instantiations. Color subclasses inside a `List<Color>` are accepted. For raw
Flutter swatches, `<Color>[Colors.red, Colors.blue]` selects the supported native
container type; a list inferred as `List<MaterialColor>` retains ordinary fallback.
No new public configuration option is required.

Validation: 10,838 workspace tests pass; all 24 final focused regressions pass on
VM, JS and Wasm. The complete browser suites passed 4,020 Chart.js and 55 utility
cases per backend before the final guard hardening; the final three-backend run
covers the new rounding, color-subclass/opaque-value and context/store-order cases.
The 5000-element same-color geometry/style comparison confirms activation and
matches all three chart types. Fixtures, case coverage, analysis, formatting,
parity and all port checks pass. No public export, generated schema/output,
golden image or upstream pin changes.

[Source patch, raw paired measurements, profiles and verification](benchmarks/indexed-options/README.md).

## 43. Sealed background-color API prototype

[ADR 0077](adr/0077-background-chart-value.md) changes only the typed dataset
background color to ChartValue<Color>, with constant/indexed/resolver variants.
The old backgroundColors/backgroundColorFor companions are removed. Border,
hover, element-style and raw APIs retain their existing forms. The variants
write OptValue/OptList/OptFunction cells directly; the indexed engine list is a
mutable copy, and the callback bridge stays lazy and preserves typed context.

This is a source-breaking API experiment, not a second resolution engine. Both
baseline and candidate include ADR 0076's optimized indexed core. The runtime
resolver's raw-value compatibility path remains. The experiment separately times
Dataset construction plus lowerDataset and full update plus native paint.

macOS 27.0.1 arm64, Flutter 3.47.8 / Dart 3.13.7, profile AOT, 800×480/DPR1,
5000 numeric items, hidden category/linear axes, fixed y bounds, no animation or
legend. A/B/B/A processes reverse case order in B2/A2. Each stage warms for 800ms
and measures seven 200ms batches. No builds or tests overlap measurement.
Each number below is the mean of two process medians:

| Case | Construct + lower | Update + paint |
| --- | ---: | ---: |
| line.static | 0.462 → 0.437 µs | 1.808 → 1.858 ms |
| line.indexed | 0.477 → 0.442 µs | 8.120 → 8.207 ms |
| line.resolver | 0.463 → 0.442 µs | 14.944 → 14.904 ms |
| bar.static | 0.308 → 0.275 µs | 3.656 → 3.654 ms |
| bar.indexed | 0.321 → 0.289 µs | 12.550 → 12.460 ms |
| bar.resolver | 0.313 → 0.279 µs | 17.545 → 17.629 ms |

Construction/lowering is 5–11% lower in this microbenchmark, but the absolute
saving is only about 0.02–0.04 microseconds per dataset. Its checksum consumes
ownKeyCount, so this isolated result is not an application-level saving. Full
chart-call changes range from -0.7% to +2.8%; there is no meaningful additional
rendering/update speedup. Static line's +0.050ms is below the material regression
gate. The value of this prototype is the single typed choice, compile-time
exclusion of conflicting forms, and simpler copyWith variant switching.

The update loop does not mutate data or rebuild the widget. No raster, FPS,
mobile or web performance claim is made. The diagnostic color strings in the
profile logs are not an output oracle; typed/raw chart twins and focused tests
validate the actual values and callback behavior.

Validation includes 442 typed API tests, 20 new value cases on VM/JS/Wasm, 10,867
workspace tests, public exports/name collisions, and executed README snippets.
[Raw measurements, source snapshots and verification](benchmarks/chart-value/README.md)
record the prototype and its limits.

## 44. Controlled estimates for further option/update improvements

An isolated checkout of ba58aa8 compares per-update option setup caching,
prepared color-only style templates, bulk bar geometry with individual colors,
and a diagnostic indexed-style extension of updateData. Production library
source is unchanged. Every measured case compares its parsed data, geometry and
selected styles against a subsequent ordinary update; callback counts match.

At 5000 items, setup caching alone saves 9–15% of full CPU for indexed line/bar
and 5–9% for their simple color callbacks. Prepared styles reduce indexed line
update CPU 6.189 → 1.671ms and callback line 12.976 → 2.175ms; their full-call
reductions are 62.3% and 76.9%. Bulk geometry alone saves 20.6% for indexed bars.
Prepared styles plus bulk geometry saves 58.6% for indexed bars and 68.7% for
callback bars. Indexed radar's prepared-style full-call reduction is 49.4%.
The separately measured indexed-bar data-only gate bypass saves 6.3% full CPU.

At 20000 indexed bars, the combined style/bulk prototype reduces update CPU
43.340 → 14.348ms and full CPU 54.140 → 25.754ms. This remains over a 16.67ms CPU
budget; no 60-FPS claim follows. These are controlled-case estimates with
incomplete production guards, not accepted optimizations or guaranteed gains.
The static controls, instrumented baseline, reverse runs, callback counts,
reference checks and fresh CPU profiles are retained.

[Full matrix, scope, limitations and reproduction](benchmarks/update-estimates/README.md).

## 45. Prepared indexed styles and color-only bulk bars

ADR 0078 implements private static style templates inside the existing native
indexed plan, with fresh copies and live indexed selections. General scope/key
discovery, context refresh and ordinary fallbacks remain. The native numeric bar
remainder additionally accepts indexed background/border colors after proving
that no user callbacks or custom reads can run in that synchronous loop.

Final A/B/B/A macOS profile measurements against ba58aa8, moving data at
800×480/DPR1:

| Case | N | Update before → after | Full CPU before → after | Full reduction |
| --- | ---: | ---: | ---: | ---: |
| Indexed line | 5000 | 6.325 → 5.669ms | 7.575 → 6.890ms | 9.0% |
| Indexed bar | 5000 | 10.231 → 2.467ms | 13.249 → 5.266ms | 60.2% |
| Indexed bar | 20000 | 47.624 → 16.178ms | 59.316 → 28.512ms | 51.9% |

Both pairs reproduce the line and bar gains. Indexed radar averages 3.0% full
CPU improvement but its pairs disagree (-0.7%/+6.6%); no reliable full-call radar
gain is claimed. Static/scriptable control means range from 2.4% slower to 1.9%
faster. The scriptable-line control is 0.349ms/2.4% slower in this final matrix;
callback counts are unchanged. These controls remain in the evidence.

All 10,886 workspace tests pass, as do 230 focused tests on each browser backend,
analysis, formatting and port checks. General prepared styles do not reproduce
the earlier unguarded prototype's line/radar gains. No callback, raster, FPS,
mobile or browser-performance claim follows. There is no public API change.

[Raw results, checks and reproduction](benchmarks/prepared-options/README.md).

## 46. Remaining point, context and drawing estimates

Controlled prototypes compare against the current ADR 0078 implementation.
Without whole-input scans, prepared indexed point options plus cheaper context
writes reduce 5000-point line full CPU 7.111 → 2.546ms (64.2%) and scatter
17.474 → 3.691ms (78.9%). The point/template and context costs were also measured
separately, with static/scriptable and instrumented mode-0 controls.

Validation work can consume that headroom. Four full native input/element scans
per update add about 7.1ms: line becomes 32.9% slower than production, while
scatter retains 38.7% improvement. A separate one-scan cost experiment gives:

| Indexed case | N | Current → prototype full CPU | Reduction |
| --- | ---: | ---: | ---: |
| Line | 5000 | 7.021 → 4.160ms | 40.7% |
| Scatter | 5000 | 17.221 → 5.400ms | 68.6% |

These are conditional planning targets: reusing one qualification across modes
and observation points needs a production proof. The scan experiment does not
establish arbitrary mutation, route, callback or subclass compatibility.

Context refresh alone saves about 4–6% at N=5000. Deferring intermediate native
bar path bookkeeping preserves the tested pixels but gives no repeatable
drawing-only full-call gain. Dense-bar results and their controls are noisy;
no dependable additional 20000-bar gain is claimed. The current profiles place
much of bar drawing in native drawRect/drawPicture calls.

Across three A/B/B/A matrices, all 76 candidate geometry/options/context/path
and exact-pixel comparisons pass (104 timing cells); callback counts match.
Production library source is unchanged. No general speed, raster or FPS claim
follows. [Evidence, limits and reproduction](benchmarks/next-estimates/README.md).

## 47. Native scatter option loops

ADR 0079 prepares indexed point colors within scatter update/overflow loops.
Each plan is local to one synchronous loop, with native chart/element/source
guards. Coordinate eligibility is checked at the original iteration rather
than by rescanning the dataset. Custom reads, active callbacks and custom points
end reuse before user code runs. Context setters and fresh options remain.

Final macOS profile A/B/B/A results over the current ADR 0078 implementation:

| Indexed scatter | Update before → after | Full CPU before → after | Full reduction |
| --- | ---: | ---: | ---: |
| 5000 points | 16.249 → 4.503ms | 17.531 → 5.644ms | 67.8% |
| 20000 points | 66.780 → 18.299ms | 71.233 → 23.855ms | 66.5% |

Both run orders agree within 0.04 percentage points. Static/scriptable and
line/bar control means range from 1.6% slower to 2.9% faster; all are retained.
Callback counts match. The implementation avoids the repeated full-input scans
that erased gains in §46 and retains ordinary context writes. No public API or
callback optimization is introduced; no raster, mobile/web speed or FPS claim
follows. The 20000-point CPU time still exceeds a 16.67ms frame budget.

All 10,899 workspace tests, 233 focused tests on each browser backend, analysis,
formatting and port checks pass. [Raw results and reproduction](benchmarks/scatter-options/README.md).

## 48. Native line charts at 20,000 items

2026-11-03–04; [ADR 0080](adr/0080-line-20k-options.md). Apple M3 Max,
macOS 27.0.1, Flutter 3.47.8 / Dart 3.13.7, profile AOT and Impeller MetalSDF.
The baseline includes the existing ADR 0078/0079 working-tree optimizations.
[Evidence, complete matrix and reproduction](benchmarks/line-20k/README.md).

**60 FPS in every mode remains unachieved.** This pass preserves all 20,000
points, callback execution, geometry, drawing order and operation semantics.
It adds guarded indexed preparation in the native line loop, private static
point/bar templates around live scriptable color calls, lazy unused second
arguments under exact arity guards, one prefix-key construction per resolution,
and synchronized context-key membership masks. Unsupported inputs keep ordinary
resolution; resolver mutation invalidates scriptable preparation immediately.

Full CPU below is update + draw + paint-end component medians at 800×480/DPR1,
averaged across two baseline and two final processes. It is not a combined-call
percentile. Data movement is outside these CPU stopwatches.

| Full update, 20k | Connected | Before ms | After ms | Reduction |
| --- | --- | ---: | ---: | ---: |
| Static colors | off | 5.15 | 5.37 | -4.3% |
| Static colors | on | 7.03 | 7.21 | -2.5% |
| Indexed colors | off | 30.21 | 13.90 | 54.0% |
| Indexed colors | on | 31.97 | 16.50 | 48.4% |
| Scriptable colors | off | 59.86 | 28.25 | 52.8% |
| Scriptable colors | on | 60.48 | 29.66 | 51.0% |

Static and redraw are controls, with no improvement claimed. The actual frame
run includes data motion and Flutter work: 1036×520/DPR2, four operations × three
color modes × connections off/on × 0/50/200 labels (72 accepted cells), plus
24 cells with 200 rotating labels. Undersampled cells were repeated with the
display kept awake; rejected samples are retained separately.

Redraw and static full/data updates measured approximately 60 FPS. Indexed
full/data updates ranged about 50–60 FPS; scriptable full updates 27–30 FPS and
data-only fallback about 30 FPS. Most animation cells measured 60 FPS. One
short scriptable animation cell measured 45.7 FPS despite UI p90 8.56 ms; its
separate ten-second repeat measured 60 FPS. The original result remains in the
matrix. These are short local observations, not sustained frame-rate guarantees.
Data-only selected full-update fallback in these scenes. Looping animation
measures ticks after initialization, not a new animated update every frame.

Worst measured UI p90 was 21.98 ms for indexed full updates and 35.82 ms for
scriptable full updates: approximately 5.3 ms and 19.1 ms above a 16.67 ms budget.
Raster p90 stayed below 2.6 ms in the non-rotating matrix. A separate final CPU
profile had 63.1% of its 7,102 sampled stacks inside element-option resolution.
The next work is reducing repeated key/prefix/scope setup and temporary objects,
with mutation-safe preparation; skipping layout alone will not close the gap.
Arbitrary callbacks have no bounded execution time, so a universal every-custom-
configuration 60 FPS promise is not possible.

Validation: 10,929 workspace VM tests; 179 focused tests on each of JavaScript
and WebAssembly; workspace analysis, formatting, parity generation and all port
checks. The final focused VM regressions also pass. No full browser, fixture,
golden or mobile suite was run. Raw results, source/binary hashes, profiles,
ordinary-path twins and validation scope are retained with the evidence.

## 49. Native option setup and owned results

2026-11-04; [ADR 0081](adr/0081-option-resolution-setup.md). This pass starts
from the ADR 0080 working tree. [Estimation, production comparison, frame data
and reproduction](benchmarks/option-setup/README.md). Apple M3 Max, macOS 27.0.1,
Flutter 3.47.8 / Dart 3.13.7, native profile AOT, Impeller MetalSDF.

The isolated experiment separates setup reuse, allocation removal and their
combination, and includes a clean baseline to expose instrumentation overhead.
At 20k scriptable line items, setup alone reduces full CPU cost by about 3–4%;
allocation alone has no clear standalone gain. Together they reduce it by about
9–10%. These are measured combinations, not added percentages or allocation counts.

Production reuses immutable native default-key snapshots, private native prefix
lists and the last joined scope-key string. Key mutation and restore invalidate
snapshots; conversions, cache lookup, scope/value reads and custom getters remain
live. Native plan matching uses identity only for an explicitly immutable input.
The new internal owned-result entry uses private frozen point/bar type tokens;
prepared results remain fresh, and fallback allocates its real result while
preserving an already-created context. Legacy virtual signatures are unchanged.

Production A/B/B/A CPU comparison, 800×480/DPR1. Figures average two process
medians of update + draw + paint-end, not a combined-call percentile:

| Scriptable chart | Items | Connected | Before ms | After ms | Reduction |
| --- | ---: | --- | ---: | ---: | ---: |
| Line | 20000 | off | 27.13 | 24.45 | 9.9% |
| Line | 20000 | on | 28.37 | 26.01 | 8.3% |
| Scatter control | 5000 | off | 14.26 | 11.99 | 15.9% |
| Bar control | 5000 | — | 11.12 | 10.34 | 7.0% |

The disconnected scriptable line has noticeable process variation; individual
runs and paired reductions are retained. Static/indexed controls are reported
in full, with no speed claim. The indexed disconnected line averaged 2.7% slower;
static scatter 2.6% slower and indexed bar 1.6% slower. Other controls varied too.

Matched real-frame runs use a 1036×520/DPR2 chart, eight seconds per cell with
first-two-second readouts excluded. Each build runs 16 cells: full/data-only ×
indexed/scriptable × connections off/on × 0/200 labels. Scriptable full updates
measure about 30–33 FPS after the change, and data-only fallback about 31–35 FPS.
Indexed frame performance is largely unchanged. Data-only remains full-update
fallback in these scenes. These short observations are not sustained FPS claims.

**The every-mode 60 FPS target remains unmet.** Worst scriptable full-update UI
p90 in this comparison moves from 33.84 ms to 31.71 ms. The work retained for
observable behavior—scope/value lookup, context refresh, final options and
rendering—still exceeds the 16.67 ms budget. No points or callback results are
sampled, omitted or memoized.

Validation: 10,955 workspace VM tests, 72 focused regressions, 164 focused tests
on each of JavaScript and WebAssembly, workspace analysis/formatting, parity
regeneration and all seven port checks. No full browser, fixture, golden or
mobile suite was run. Runtime source hashes match the isolated measured build.

## 50. Loop-local native line resolver and context sources

2026-11-04; [ADR 0082](adr/0082-native-line-resolution.md). Baseline: the ADR 0081
working tree. [Profiles, separate estimates, production runs and source hashes](benchmarks/line-resolution/README.md).
Native M3 Max, macOS 27.0.1, Flutter 3.47.8 / Dart 3.13.7, profile AOT, Impeller.

The refreshed baseline profile still places element-option resolution in 58.4%
of 6,793 CPU samples, with context refresh in 8.7%. The shares overlap. Allocation
RPC responses are retained as heap snapshots: accumulated/current counters are
equal for every class, so they do not establish per-frame allocation rates.

An isolated scope-only/context-only/combined experiment finds that prepared
lookup provides most of the scriptable gain. Combined 20k scriptable full CPU
moves from 26.65 to 17.37 ms without connections, and 28.44 to 20.65 ms with them.
The production build removes the experiment switches and revalidates all guards.

Production retains a warmed native color resolver within a single mode-none
line loop. Source/default identities, route absence, key snapshot, cache
invalidation, class/id/index and cached-result priority remain live. The native
context reader uses current metadata elements and live array items, preserves
the original six setters, and falls back before custom reads or context creation.
Typed roots and unsupported geometry retain ordinary resolution. Callbacks and
all points remain; no rendering or geometry substitution is introduced.

Production A/B/B/A, 800×480/DPR1; full CPU is the sum of update/draw/paint-end
component medians, averaged over two runs, not a combined-call percentile:

| Line / 20k items | Connected | Before ms | After ms | Reduction |
| --- | --- | ---: | ---: | ---: |
| Indexed | off | 16.87 | 14.39 | 14.7% |
| Indexed | on | 20.22 | 18.12 | 10.4% |
| Scriptable | off | 32.48 | 20.60 | 36.6% |
| Scriptable | on | 34.21 | 25.47 | 25.5% |

Absolute costs vary across processes; both paired scriptable reductions remain
positive (about 34–39% disconnected and 23–28% connected). Static line and
scatter/bar controls are retained in full. No gain is claimed for controls;
static connected line averages 3.2% slower, with inconsistent paired changes.

Matched frame runs cover 16 full/data-only × indexed/scriptable × connections
on/off × 0/200-label cases per build, at 1036×520/DPR2. Scriptable full update
moves from about 29–30 FPS to 40–43 without connections and 33–34 with them;
data-only fallback reaches about 42–44 and 35–36 respectively. Data-only remains
full-update fallback. These short local runs do not establish sustained FPS.

One connected indexed full-update cell moves from 52 to 45 FPS in the first
matrix. A separate A/B/B/A ten-second repeat gives about 48/50 FPS for baseline
and 50/54 FPS for production; original and repeat results are both retained.
The evidence supports a CPU reduction, not an unconditional per-cell FPS gain.
**The every-mode 60 FPS target remains unmet.** Worst scriptable full-update
UI p90 remains about 30.7 ms versus a 16.67 ms budget.

Validation: 10,988 workspace VM tests, 61 focused regressions, 168 tests on each
of JavaScript and WebAssembly, analysis, formatting, parity generation and all
seven port checks. No full browser, fixture, golden or mobile suite was run.

## 51. Estimates for varying fields, scalar callbacks and native point drawing

2026-11-04. [Detailed estimates, prototype sources and checks](benchmarks/three-estimates/README.md).
This investigation leaves production library sources unchanged. Baseline is the
ADR 0082 working tree; native M3 Max, profile AOT, 20k items, 800×480/DPR1.

Runtime-switch overhead was large enough to obscure small gains, so the primary
comparison uses separate binaries with switches compiled out. Each value is the
mean of two process medians of update + draw + paint-end, not a combined-call
percentile or a measured frame time. Data generation is outside the stopwatches.

| Proposal | Connections off: CPU ms | Saved | Connections on: CPU ms | Saved |
| --- | ---: | ---: | ---: | ---: |
| Specialized all-off baseline | 22.21 | — | 26.18 | — |
| Visit only varying color fields | 19.82 | 2.39 ms / 10.8% | 24.60 | 1.58 ms / 6.0% |
| Separate scalar callback path | 18.46 | 3.75 ms / 16.9% | 24.24 | 1.94 ms / 7.4% |
| Direct native-circle entry | 17.00 | 5.21 ms / 23.4% | 24.60 | 1.58 ms / 6.0% |
| Reuse fill/stroke packing centers | 21.95 | 0.26 ms / 1.2% | 25.79 | 0.39 ms / 1.5% |
| First three combined, without packing | 13.73 | 8.48 ms / 38.2% | 19.62 | 6.56 ms / 25.1% |

The unchanged-library controls averaged 22.34/27.63 ms. The table uses the
specialized all-off baseline, with all original rows retained. Native-circle
entry reduces draw-only CPU by about 0.7–0.8 ms in these scenes. Packing alone
has no meaningful draw-only gain. Full-update phases can shift as allocation
and GC costs interact; combined gains are measured, not added.

129 focused resolver tests pass across the variants, including two varying
callbacks and mutation order. Counted updates retain 20,006 color calls. After
a two-second startup warmup, 300 native RGBA comparisons match at DPR1/2, and
checked atlas command buffers and packing coordinates match. An earlier
cold-start small-circle scene differed; it remains a renderer-validation issue
before any drawing change is shipped. These prototypes have not passed the
complete production validation matrix.

The optional frame probe produced no frame callbacks and its zero-sample rows
are rejected. **These are CPU estimates, not a 60 FPS claim.** The combined
unconnected estimate approaches the budget, but omits host/data-motion/raster
costs. The connected estimate still exceeds 16.67 ms before host overhead.

## 52. Ordered varying colors and scalar callback production path

2026-11-04. [Evidence and reproduction](benchmarks/color-resolution/README.md),
[ADR 0083](adr/0083-ordered-color-resolution.md). This implements proposals 1 and
2 from §51: ordered varying-color operations and a separate scalar callback loop.
Fresh options, live callbacks, context timing and ordinary mutation continuation
remain. This pass changes one production runtime file, helpers.config.dart.

Native macOS profile AOT, 20k line points, 800×480/DPR1, A/B/B/A. Full CPU is
update + draw + paint-end component medians, averaged across two processes.
Data movement is excluded; these are not measured frame times.

| Colors | Connections | Before ms | After ms | Reduction |
| --- | --- | ---: | ---: | ---: |
| Scriptable | off | 16.33 | 12.77 | 21.8% |
| Scriptable | on | 18.31 | 15.14 | 17.3% |

Static/indexed line controls vary within about 1.5%. Scriptable scatter/bar 5k
controls improve 14.7%/6.4%. All original rows and both pairs are retained.
Absolute timings differ from prior sessions; only matched comparisons apply.

The frame comparison could not be completed: the baseline process stopped
receiving callbacks, and the shorter retry also had no callbacks. Raw rejected
runs are retained. **There is no fresh FPS claim, and every-mode 60 FPS remains
unverified.** The CPU sums exclude host/data-motion work and do not prove it.

The separate renderer startup check reproduces the original cold pixel transition
in both unchanged baseline and native-circle prototype. Four independent
six-render sequences have identical pixels at matched stages and identical
commands throughout. This clears that specific differential concern; the engine
startup cause is not identified. No renderer change is included in this pass.

Validation: 11,021 VM tests, 195 focused tests each on JavaScript and WebAssembly,
analysis, formatting, parity generation and all seven port checks. No full
browser, fixture, golden or mobile suite was run.

## 53. Native frame verification after ordered-color resolution

2026-11-04. [Full results and raw evidence](benchmarks/color-verification/README.md).
This closes the missing frame comparison of §52. The unchanged ADR 0082/0083
profile chart binaries run in identical temporary native hosts that keep their
benchmark windows visible and record occlusion. No production runtime changes.

The accepted matrix has 96 production cases: all four operations, three color
modes, connections off/on, 0/50/200 static labels and 200 rotating labels. Sixteen
matched baseline cases cover indexed/scriptable full/data-only updates with
0/200 labels. Each case runs eight seconds, excluding two seconds of warmup,
at 1036×520/DPR2. All accepted processes pass visibility checks. One interrupted
six-case group was repeated; original attempts are retained.

| Operation | Observed FPS range | Worst UI p90 ms | Worst raster p90 ms |
| --- | ---: | ---: | ---: |
| Redraw | 58.2–120.0 | 10.29 | 2.96 |
| Full update | 35.6–118.6 | 28.36 | 3.13 |
| Data-only request | 34.9–60.0 | 29.12 | 2.94 |
| Animation | 53.2–60.0 | 25.36 | 2.99 |

Matched scriptable full-update FPS rises from 35.8–37.6 to 49.9–54.2 without
connections and from 31.9–32.0 to 40.3–40.7 with them. Every data-only scene
falls back to the full lifecycle. Indexed controls have mixed/regressive results
in the first comparison; the evidence preserves them and a targeted repeat.
The largest indexed control drop (57.2 → 47.9 FPS) does not reproduce in a
12-second A/B/B/A repeat: baseline 57.9/54.7, production 53.7/55.8. The repeat
averages differ by 2.7%, with opposite pair signs; a small regression is not
ruled out and no indexed gain is claimed.

**Every-mode 60 FPS remains unmet.** The worst case has UI p90 29.123 ms versus
a 16.67 ms budget, a gap of 12.46 ms / 42.8%. Raster p90 stays below 3.2 ms.
These short local measurements locate the remaining UI-thread budget gap; they
do not establish sustained or cross-device performance. Some observed rates
exceed 60 because the measurements do not impose a 60 FPS cap.

All 112 accepted rows have at least 11 readouts and 174 captured timings;
39,228 timings in total. Runtime source/framework hashes match the implementation
evidence. Earlier correctness suites were not repeated because this pass changes
only benchmark infrastructure and documentation.

## 54. Drawing, data-only fallback and slow-frame investigation

2026-11-04. [Detailed evidence and reproduction](benchmarks/ui-priorities/README.md).
Unchanged ADR 0083 production build, native macOS profile AOT, 20k points,
1036×520/DPR2. Timers and configuration experiments stay in an isolated copy;
this pass changes no production library/gallery behavior.

In the heavy connected scriptable update with 200 rotating labels, coarse
phase timers measure point drawing 6.18 ms, connected-line work 2.18 ms,
labels/title 1.97 ms and whole Chart.draw 10.35 ms. The 0.96 ms circle-batch
flush is nested inside labels/title and must not be added again. Cached line
draw costs about 0.02 ms on redraw, while moving updates rebuild/replay paths.
Circle records/boxed numeric work and connected Path2D command objects are
allocation-related candidates; this is not a new renderer speedup claim.

The original data-only cases all reject at x-scale bounds: x uses suggested
bounds, while data-only requires explicit finite min/max. An explicit-bound
experiment enables static data-only updates, but is rejected as an optimization.
The scene is unsorted with parsing:false; fixed bounds trigger sorted binary
visible-range selection. A 20k-point boundary case draws only 10k points.
Six unchanged-library tests reproduce that omission and show that parsing:true
preserves all points. Indexed colors additionally lack static cached element
options; scriptable colors also fail static-settings validation. A safe extension
needs range/order correctness and a separate color-option contract.

Fresh CPU profiles still show substantial element update, source checks,
context refresh and callback work. The VM timeline identifies GC-labelled UI
work as a major contributor to slow frames. In the heavy-update trace, it
averages 4.70 ms/frame, rising from 4.39 ms in other frames to 7.40 ms in the
slowest decile. With CPU sampling disabled, a repeat measures 4.53 ms/frame,
with 4.25 versus 7.07 ms. Higher GC time accounts for 88.3% of that repeat's
slow-frame mean duration gap; an animation repeat gives 82.2%.

These are short retained timelines (2.37–6.78 seconds), with overlapping GC
spans unioned on the UI thread and background GC excluded. Heap accumulated
counters equal current counters, so no allocation-rate claim is made. Diagnostic
costs must not be subtracted from §53 timings to predict FPS. The next measured
candidate should reduce temporary marker/path objects, then verify both average
UI cost and slow frames. No guard removal or callback-result memoization is
justified by these results.

Evidence: four CPU profiles, two GC-only repeats, 18 phase/fallback cases,
12 bound experiment cases, six focused eligibility tests and matching production
source hashes. Full correctness suites were not repeated for this diagnostics-only
pass; no 60 FPS achievement is claimed.

## 55. Scalar circles and compact native Path2D storage

2026-11-04. [ADR 0084](adr/0084-scalar-circles-and-compact-paths.md),
[full evidence and reproduction](benchmarks/circle-path/README.md).
Three runtime files remove native circle records/boxing and pack unobserved
move/line/close commands before native path conversion. Command inspection and
complex operations materialize one stable mutable list; public/custom replay
keeps the original platform-specific loop behavior. Cache/version semantics,
canvas operations, batching/quantization and data-only guards stay intact.

Native macOS profile AOT, 20k items, 1036×520/DPR2. The comparison covers 20
cases per build across scriptable redraw/update/animation and static/indexed
update/animation controls. All use 0 or 200 rotating labels, with connections
on/off. Twelve-second A/B/B/A repeats target connected scriptable updates and
animation with 200 labels:

| Operation | Mean UI before ms | Mean UI after ms | Reduction | UI p90 before → after ms |
| --- | ---: | ---: | ---: | --- |
| Full update | 19.04 | 16.44 | 13.7% | 21.26–21.32 → 18.13–18.48 |
| Animation | 11.44 | 10.53 | 8.0% | 14.91–16.09 → 13.20–14.83 |

Means average two process means; p90 ranges list their individual results and
are not combined percentiles. The full-update pairs both improve (about 12–15%).
All initial mean UI pairs improve except one indexed-animation control. Its
separate A/B/B/A repeat gives baseline 11.79/12.33 and production 10.31/10.17 ms;
the initial regression does not reproduce. Original and repeat data are retained.

GC-only traces disable CPU sampling. In heavy updates, mean GC-labelled UI time
falls 5.16→3.74 ms/frame (about 28%); the slowest-decile mean falls 9.49→7.96 ms.
Because bounded timeline retention differs, a matched final-three-second check
is also retained: mean GC 5.38→3.83, slowest-decile GC 10.68→6.74 ms/frame.
Animation mean GC is nearly unchanged in matched windows (1.64→1.62 ms), so no
substantial animation-GC improvement is claimed. GC intervals are unioned on the
UI thread, excluding background workers. Heap snapshots are not allocation rates.

**Every-mode 60 FPS remains unmet.** Connected full-update FPS reaches about
58–59 in the repeats, but UI p90 remains above 16.67 ms; the initial matrix has
21.89 ms for that heavy candidate case. These short local runs do not establish
sustained/cross-device FPS. Diagnostic GC timelines are separate from ordinary
frame readouts and must not be subtracted from them to predict gains.

Validation: 11,034 workspace VM tests, 58 finalized focused canvas/path tests,
247 tests each on JavaScript and WebAssembly, fixture validation across 26 files,
analysis, formatting, parity and all seven port checks. All 300 native RGBA
comparisons are identical, including transformed circles, mixed/mutable paths
and 20k-segment lines. Forty paired frame cells, eight heavy-repeat cells and
four indexed-repeat cells pass viewport/sample/visibility checks. Four GC
captures are retained. No full browser, golden or mobile suite was run. The
previous 96-case matrix was not repeated; data-only remains separate work.

## 56. Path-buffer growth triage

2026-11-04. [Isolated candidates, measurements and checks](benchmarks/path-growth/README.md).
Production remains ADR 0084. Three native profile builds compare current doubling
buffers, a delayed count-based reservation, and adaptive 1,024-command chunks.
No old path storage is recycled, and no data-only/callback guard changes.

At 20k unobserved commands, construction + native conversion + bounds query
averages 0.750 ms baseline, 0.600 reserved and 0.498 chunked: about 20% and 34%
less microbenchmark cost. Small and exposed-path controls are broadly similar.
The payload model requests about 1.11 MB through baseline growth versus 348 KB
reserved / 365 KB chunked, excluding headers and chunk lists; these are source
calculations, not measured allocation rates.

Balanced A/B/C/C/B/A frame runs use connected scriptable 20k points and 200
rotating labels, twelve seconds per cell at 1036×520/DPR2. Full-update mean UI
moves 15.61→15.26/15.41 ms, smaller than unconnected-control variation; no robust
average-update gain is claimed. UI p90 is more promising: 17.40–17.55 baseline,
16.15–16.66 reserved and 16.20–16.23 chunked. One baseline animation run changes
from 60 to 117 FPS, so animation averages/FPS remain cadence-confounded.

GC-only final-five-second windows show mean GC-labelled UI time 3.35→2.58/2.20
ms per update frame, and slowest-decile GC 6.19→4.24/2.85 ms. Nested intervals
are unioned on the UI thread; background GC is excluded. These diagnostics are
separate from ordinary frame readouts. A new baseline CPU profile still places
43.8% of sampled stacks in element updates and 39.1% in drawing (overlapping
inclusive shares). The remaining work is broader than path buffers alone.

**Recommend chunks for production hardening; do not declare every-mode 60 FPS.**
Chunks avoid the count hint's sparse-path over-allocation and require no ported
line-algorithm change. Their replay loop also differs, so gains are for the whole
candidate, not allocation changes alone. Each variant passes 170 focused tests
and 12 boundary/retention cases. Both candidates match 300 native pixel scenes
exactly (600 comparisons total). Browser/full production regressions and a broader
native matrix remain prerequisites to promotion. Production source hashes are
unchanged; this pass adds evidence only.

## 57. Production chunked path storage

2026-11-04. [ADR 0085](adr/0085-chunked-path-storage.md),
[complete production validation](benchmarks/path-chunks/README.md).
Promote the adaptive chunk candidate from §56. The first private buffer grows
from 16 to 1,024 commands, then full chunks are retained without copying or
cross-path pooling. Public materialization, replay, native command order and
cache/version semantics remain. Only canvas.dart changes in the runtime; no
line algorithm, public API or data-only eligibility change.

Validation passed: 11,060 workspace VM tests, 84 focused canvas/path tests,
4,206 tests per backend in the full JavaScript and WebAssembly suites, cases,
fixtures, formatting, analysis, parity and all port checks. All 300 native RGBA
comparisons are identical. Boundary/ownership tests cover paths through 50k
commands. No golden/mobile suite was run or macOS goldens updated.

Native verification is complete on the user-selected built-in Retina display,
DPR2 with a 120-Hz maximum, at 1036×520. It contains 96 production cells, eight
fresh matched-repeat cells and four GC captures. Earlier fixed-60-Hz Studio
Display repeats/controls remain a separate cohort. Display movement/minimization
attempts are rejected and preserved. No display settings or runtime sources
changed during the resumed verification.

| Heavy scriptable case | Mean UI before → after ms | Reduction | UI p90 before → after ms |
| --- | ---: | ---: | --- |
| Connected full update, 200 rotating labels | 15.94 → 14.64 | 8.1% | 17.69–18.06 → 15.43–15.71 |
| Connected animation, 200 rotating labels | 8.00 → 7.83 | 2.1% | 8.98–9.22 → 8.35–8.55 |

Means average two process means; p90 ranges list individual results. In the
complete matrix, redraw is about 120 FPS and animation 115–120; full update is
57–120 and data-only requests 52–120. Every data-only cell still falls back to
the full lifecycle. Seven cells exceed 16.67 ms UI p90, with one additional cell
below 59 mean FPS. **Every-mode 60 FPS remains unmet.** The worst observed cell
is connected scriptable data-only fallback with 200 static labels: 51.9 FPS and
17.66 ms UI p90. Raster p90 remains below 2.46 ms.

Separate GC-only final-five-second windows show update mean GC-labelled UI time
3.46→2.20 ms/frame (36.5% lower), and slowest-decile mean GC 8.78→2.92 ms. Full
retained traces support the direction (3.19→2.15 ms/frame). Animation also has
lower GC time in these diagnostic captures, while its ordinary mean improves
only modestly. CPU sampling is disabled, nested intervals are unioned on the UI
thread and background workers excluded. Heap counters remain snapshots, not
allocation rates. GC and ordinary frame figures must not be added/subtracted.

All 104 built-in ordinary rows have at least eight readouts and 195 timings;
43,545 timings total. These are short local observations with variable delivered
cadence up to 120 Hz, not sustained/cross-device guarantees. Source hashes match
the measured implementation. Raw rows, controls and rejected attempts are kept.

## 58. Indexed-update classification and numeric-loop triage

2026-11-05. [Full candidates, controls and raw evidence](benchmarks/indexed-update-triage/README.md).
Production remains ADR 0085. A fresh 20k indexed profile places coordinate
eligibility in 32.2% of sampled stacks and runtimeType in 28.1%, versus about
0.8% for PointOptions.clone. The unconnected profile agrees; the scriptable
control spends almost no time in coordinate qualification. Shares overlap.

Separate baseline/guard/numeric/fresh/combined binaries are measured in forward
and reverse order on the built-in display, 1036×520/DPR2, 200 static labels.
Warm-map mean UI (off/on connections): baseline 14.39/16.71 ms; weak per-slot
native classification cache 10.32/11.86; numeric projection/direct writes
14.23/16.42; fresh background-copy specialization 14.29/16.46; combination
10.08/12.42. Numeric/fresh gains are small and do not consistently add value.

The uncapped weak cache regresses every-update map replacement by about 7–11%.
A bounded-fill prototype creates at most 1,024 new weak entries per prepared
pass and retains existing hits. Matched stable-data means become 13.64→9.48 ms
off and 15.29→11.54 ms on (30.5%/24.5% lower). Replacement-data means are
18.77→18.70 and 20.93→21.14 ms, approximately flat within this sample. No value,
option or callback result is cached; x/y and route/fallback checks remain live.

The bounded profile drops runtimeType to about 0.07% of samples. Matched GC-only
windows change mean UI-thread GC from about 1.80→1.58 ms/frame, with slow-decile
GC about 2.48→2.45 ms. The main improvement is CPU classification, not elimination
of GC. Heap counters remain snapshots, not allocation rates.

**Recommend bounded weak native-map classification reuse for production hardening.**
Do not promote the uncapped cache or claim a universal 60 FPS result. Production
review must address lifecycle/partial-range/custom-container semantics, cold and
mixed/churning workloads, memory overhead, browser coverage and the full mode
matrix. The six final variants pass 54 existing focused regressions each plus
extra projection/cache/copy cases. Generator edits are regenerated rather than
hand-editing .g.dart files. Production source hashes remain unchanged; this
investigation changes no runtime behavior or data-only guard.

## 59. Production bounded weak coordinate-map cache

2026-11-05. [ADR 0086](adr/0086-weak-point-coordinate-cache.md),
[complete verification](benchmarks/coordinate-cache/README.md).

LineController retains weak identities of accepted SDK coordinate maps at
absolute point indexes. Each prepared indexed-color loop fills at most 1,024 new
entries. The classifier itself remains loop-local; values/routes, callbacks,
geometry, fresh options and fallback guards remain live. Unsupported paths clear
storage. Scatter and data-only eligibility are unchanged.

Matched native macOS A/B/B/A runs on the built-in display (maximum 120 Hz, DPR2,
1036×520 chart) measure 20k indexed points with 200 static labels. Mean UI falls
13.22→9.21 ms without connections (30.3%) and 14.94→10.89 ms with connections
(27.1%). Connected UI p90 changes 16.05/16.86→11.99/12.05 ms. Replacement-data
means change 17.46→17.05 and 19.49→19.14 ms, with comparable tails; the uncapped
prototype's churn regression is absent in this sample. Static/scriptable
controls differ by about 0.05 ms, with no targeted speedup claimed.

All 32 indexed cells meet the near-60 screen in the complete 96-case matrix.
Overall 90/96 meet mean FPS ≥59 and UI/raster p90 ≤16.67 ms. The six misses are
connected scriptable full updates or data-only fallbacks, at 57.2–58.6 FPS.
The two slowest cells run around 60 FPS for both binaries in longer matched
repeats. Every-mode sustained 60 FPS is not established. An occluded animation
batch was rejected and rerun; all accepted window logs are valid.

The final CPU profile has runtime-type retrieval at about 0.12% of sampled
stacks, compared with 28.1% in the triage baseline. Equal five-second GC windows
show mean GC-labelled UI time 1.72→1.61 ms/frame and slow-decile mean 2.66→2.58 ms.
The main gain is CPU classification work. Heap snapshots show 19,998 additional
weak entries (639,936 bytes) plus the cache and 20k-slot array; no old map is
strongly retained by the cache. Initial 60-frame means also improve, but initial
construction still has approximately 31 ms maximum UI frames.

Validation: 11,068 workspace VM tests; 4,212 tests per browser backend; formatting,
analysis, spec cases, fixtures, regenerated parity and all seven port checks.
Regressions cover bounded fill, replacement/mixed input, constructor differences,
growth/shrink, partial ranges, custom observations, routes, live values, active
callback mutation, exceptions and recovery. Two early DDC test-fixture assumptions
were corrected without widening the existing native-container allowlist.

## 60. Shared native point contracts: regression verification

2026-11-05. [ADR 0087](adr/0087-shared-native-point-contracts.md),
[verification and reproduction](benchmarks/native-contracts/README.md).

Line/scatter now share capability/class predicates, update prerequisites and
indexed point preparation. Exact-controller gates and per-item observation
points remain local. NativePointResolution validates sources before calling its
private executor; callback-time generation checks remain with Config/resolvers.
Weak identity facts, plan validity and live coordinate/capability checks retain
their different lifetimes. No new cache, eligibility or public API is introduced.

This is an architectural consolidation, with no speedup claim. Matched native
A/B/B/A comparisons cover line/scatter full updates, 20k items, 200 static labels,
three color modes and connections off/on: 48 cells and 20,706 captured timings.
The built-in display remains at maximum 120 Hz, DPR2, with the same 1036×520 chart.
Most mean UI changes are within approximately 0–2.5%; scriptable line means are
lower in this sample but vary notably between baseline processes. A longer
connected-indexed line repeat is effectively flat, 11.03→11.01 ms, with p90
12.15/12.24→11.98/12.00 ms. No consistent regression is demonstrated. One occluded
repeat was rejected and rerun; all accepted visibility logs pass.

Validation passes: 11,073 VM tests; 4,217 tests per browser backend; formatting,
analysis, spec cases, fixtures, regenerated parity and all seven port checks.
Shared-contract tests pin capability liveness, projection/grid scope, class
metadata changes and validation before contexts/execution. Existing line/scatter
and resolver twins retain mutation, callback, fallback and cache-lifetime checks.
The 96-case matrix of §59 is not rerun for this behavior-preserving refactor.

## 61. Direct prepared scalar point resolution

2026-11-05. [ADR 0088](adr/0088-prepared-scalar-point-resolution.md),
[full measurements and reproduction](benchmarks/scriptable-headroom/README.md).

Fresh profiles identify general option-resolution setup around already-prepared
scalar point colors as avoidable work. A captured native executor now bypasses
that setup and the successful context/result record. Complete source validation,
post-context generation/plan/key checks, fresh options, callback order and the
existing mutation/non-scalar continuation remain. Context-time failure resumes
ordinary resolution with the already-observed context, without invoking it again.
No callback-result cache, drawing change or data-only extension is introduced.

Matched A/B/B/A runs cover 20k connected scriptable points with 200 static or
rotating labels. Mean UI improves 4.6–5.3%, about 0.7–0.8 ms: static-label full
update 14.56→13.81 ms and data-only fallback 14.88→14.20 ms; rotating-label full
update 14.71→14.03 ms and fallback 15.07→14.27 ms. Heavy-case candidate UI p90
ranges 14.74–15.72 ms. Static/indexed controls remain close to baseline.

The complete 96-cell matrix contains 38,433 timings; 95/96 meet mean FPS ≥59 and
UI/raster p90 ≤16.67 ms. The single miss is connected scriptable data-only fallback
with 50 static labels: 59.01 FPS, UI p90 16.904 ms. Its longer matched repeat passes
on the candidate (63.3–63.9 FPS; p90 14.52–14.70 ms), but the original miss remains
recorded. The roughly 14 ms p90 headroom target is not achieved across heavy label
cases, and every-mode sustained 60 FPS remains unproven. Covered control/data
batches were rejected and rerun; all accepted visibility logs pass.

The final CPU profile confirms that the prepared executor replaces the general
Config/scriptable-resolution route while callbacks still execute. Equal five-
second GC-only windows show mean GC-labelled UI time 2.09→1.73 ms/frame and
slow-decile mean 2.64→2.54 ms. No allocation-rate inference is made from snapshots.

Validation passes: 11,091 VM tests; 4,235 tests per browser backend; formatting,
analysis, spec cases, fixtures, regenerated parity and all seven port checks.
Eighteen new native-vs-ordinary cases exercise pre/post-context invalidation,
replacement plans, callback mutation, non-scalar returns, exceptions and reentrancy.

## 62. Dart-side partitioned baseline fill

ADR 0089 adds a guarded compound fill for dense, repeatedly varying cubic lines
against private horizontal origin/start/end boundaries. It retains all control
points, the original current path and the stroke. One native nonzero fill draws
32-cubic subcontours. Flat/gently varying and unsupported cases retain the
ordinary renderer. Gradients, custom geometry and observable native lifecycle
hooks decline. No engine patch or dataset reduction is involved.

The real benchmark chart on Flutter 3.50.0-0.4.pre, M3 Max, built-in 120 Hz,
DPR 2, 964 x 420 logical plot, live 20k smooth + fill, measured original /
optimized / original after two-second warmups and four-second windows:

| Metric | Original A | Partitioned | Original B |
| --- | ---: | ---: | ---: |
| Approximate engine FPS | 53.0 | 109.5 | 53.0 |
| Median GPU command, ms | 23.903 | 2.560 | 25.206 |
| Complete chart update median, ms | 6.460 | 7.226 | 6.378 |

The extra CPU validation/path work costs about 0.8 ms in this sample, while
GPU time drops by over 20 ms. UI-build timing alone excludes the post-frame
chart update, so it is not used as the complete CPU measurement. Engine FPS is
not presentation feedback. Native chart pixels matched exactly at a fixed
frame; software-renderer twins explicitly bound small AA rounding differences.
Actual emitted index bytes increased 968,548 to 981,028 (+1.29%), both within
the same 1,024,000-byte native allocation block. The additional path and boundary
vertices are separate costs. Sequential RSS was lower during the faster run,
but this is not an isolated allocation measurement or a general RAM claim.

See [the comparison report](../../../apps/chart_benchmark_lab/doc/dart-baseline-fill/comparison.txt)
and its JSON records. The standalone diagnostic switch
`CHARTJS_PARTITIONED_BASELINE_FILL=false` disables the optimization for a matched
baseline build. It is recorded in benchmark exports. Correctness validation:
485 filler/canvas/API tests, focused geometry/state/pixel tests, analyzer and
port guards. Broader device-specific performance remains unmeasured.

## 63. One draw for an update that replays an event

[Chart.js ADR 0090](adr/0090-replay-single-draw.md) removes the first of two draws in an update
that replays the last mouse event with no queued animation. Upstream has the same double draw. The
second draw clears the first, so the pixels do not change.

The chart was the Chart.js line of `apps/chart_benchmark_lab` on an Apple M3 Max: built-in 120 Hz
display, DPR 2, Flutter 3.50.0-0.4.pre, native profile build, 964 x 420 logical plot, 20k live
points, tooltips on, animation off. Each case has 2 runs of a 10-second capture. The mouse is a
synthetic hover at the center of the chart. A moving mouse sends a new position every 8 ms.

| Case | FPS before | FPS after |
| --- | ---: | ---: |
| Markers, mouse still | 101.0, 101.2 | 120.0, 120.0 |
| Markers, mouse moving | 90.5, 89.9 | 112.1, 108.9 |
| Markers, no mouse | 119.9, 120.0 | 119.9, 119.9 |
| No markers, mouse still | 120.0, 120.0 | 120.0, 120.0 |
| No markers, mouse moving | not measured | 120.0, 119.9 |

The FPS values are engine frame timings, not presentation feedback. The FPS drop was large because
a frame that misses 8.33 ms waits for the next display refresh.

Mean chart work for each update with markers and a still mouse, from plugin hook timing:

| Phase, ms | Before | After |
| --- | ---: | ---: |
| Update | 2.27 | 2.31 |
| Replay: hover search and tooltip update | 0.97 | 0.94 |
| Draw | 5.12 (2 draws of 2.56) | 3.19 (1 draw) |
| Sum | 8.36 | 6.44 |

The second draw costs almost nothing without markers (2 x 0.45 ms against 1 x 0.94 ms before the
change). With markers, it costs about 2.1 ms. Thus only charts with markers reached the 8.33 ms
limit. UI p90 did not show this cost: it stayed near 1.7 ms, because the chart work runs after the
build phase that this metric times.

A moving mouse stays below 120 FPS with markers, because each new mouse event can draw by itself.
The driver and logs are in [`benchmarks/replay-single-draw/`](benchmarks/replay-single-draw/README.md).
Broader device-specific performance remains unmeasured.

## 64. One hover pass and one draw for each frame of a live chart

[Chart.js ADR 0091](adr/0091-live-mouse-move.md) makes a mouse move of a live `ChartView` wait for
the update of its frame. The setup is the setup of §63. The mouse is synthetic. "On the curve" follows
the middle of the moving data, so it hits a point on almost every frame. "Wiggle" stays near the
center of the chart. Each case has 2 runs of a 10-second capture, with Chart.js ADR 0090 in both
columns.

| Case | FPS before | FPS after |
| --- | ---: | ---: |
| Markers, mouse on the curve, every 8 ms | 89.8, 89.7 | 120.0, 120.0 |
| Markers, mouse on the curve, every 2 ms | not measured | 120.0, 119.9 |
| Markers, wiggle, every 8 ms | 112.1, 108.9 | 119.9, 119.9 |
| Markers, mouse still | 120.0, 120.0 | 119.9, 120.0 |
| No markers, mouse on the curve, every 8 ms | 120.0, 120.0 | 120.0, 119.9 |

The FPS values are engine frame timings, not presentation feedback.

Mean work for each update with markers and a mouse on the curve every 8 ms, from plugin hook timing:

| Phase, ms | Before | After |
| --- | ---: | ---: |
| Mouse event: hover search and tooltip update | 1.10 | 0 |
| Draw after the mouse event | 2.74 | 0 |
| Update | 2.23 | 2.33 |
| Replay: hover search and tooltip update | 1.09 | 1.12 |
| Draw after the update | 2.96 | 3.15 |
| Sum | 10.12 | 6.60 |

The median time from the start of the frame callbacks to the end of the post-frame work went from
10.4 ms to 7.3 ms. The margin is small: 17% of the frames still run past 8.33 ms in this measure, with
no loss of engine FPS. Other load on the machine can reduce the FPS. Cheaper marker drawing would add
margin: a CPU profile before this change gave `PointElement.draw` 43% of the time in port code.

A move now appears one frame later in a live chart: about 8 ms at 120 Hz. The driver and logs are in
[`benchmarks/live-mouse/`](benchmarks/live-mouse/README.md). Broader device-specific performance
remains unmeasured.

## 65. Common performance work on all chart types

Chart.js ADRs 0092 to 0103 remove work that each chart type repeated on each frame. The setup is in
[`benchmarks/common-chart-wins/`](benchmarks/common-chart-wins/README.md). A cell is a chart type, an item
count and a preset of `apps/chart_benchmark_lab`. "Plain" has the defaults of the lab. "Full" has markers,
fill, curves, axes, a grid and alternating colors. Old and new are passes on a locked screen. The first
column is the only pass with the window in view.

The cells that started or stayed below 118.5 FPS:

| Cell | FPS at the start, visible | FPS old, 2 runs | FPS new, 2 runs | FPS new, no data-only |
| --- | ---: | ---: | ---: | ---: |
| Line, 20,000, full | 89.5 | 88.8, 91.2 | 106.0, 105.8 | 102.2 |
| Bar, 20,000, plain | 42.2 | 44.5, 45.0 | 56.5, 57.0 | 55.0 |
| Bar, 20,000, full | 31.8 | 33.8, 34.5 | 50.2, 51.2 | 41.8 |
| Scatter, 20,000, plain | 92.5 | 96.5, 96.2 | 120.0, 120.0 | 120.0 |
| Scatter, 20,000, full | 55.2 | 57.2, 56.8 | 118.8, 117.8 | 118.8 |
| Bubble, 20,000, plain | 31.0 | 31.5, 31.2 | 120.0, 120.0 | 120.0 |
| Bubble, 20,000, full | 11.5 | 11.8, 11.8 | 100.8, 98.8 | 97.5 |
| Pie, 20,000, plain | 13.0 | 13.5, 13.8 | 120.0, 120.0 | 120.0 |
| Pie, 20,000, full | 2.2 | 2.2, 2.0 | 83.2, 84.5 | 77.2 |
| Doughnut, 20,000, plain | 13.2 | 13.0, 13.2 | 120.0, 120.0 | 120.0 |
| Doughnut, 20,000, full | 2.2 | 2.0, 2.2 | 71.2, 69.2 | 69.0 |
| Polar area, 20,000, plain | 14.5 | 14.5, 14.8 | 73.0, 72.8 | 73.8 |
| Polar area, 20,000, full | 3.0 | 3.0, 3.0 | 67.2, 67.2 | 61.0 |
| Radar, 20,000, plain | 62.5 | 68.2, 70.0 | 120.0, 120.0 | 120.0 |
| Radar, 20,000, full | 8.8 | 9.0, 9.0 | 57.5, 57.0 | 56.8 |
| Bubble, 5,000, full | 49.0 | 49.5, 50.0 | 120.0, 120.0 | 120.0 |
| Pie, 5,000, plain | 64.5 | 63.8, 64.0 | 120.0, 120.0 | 120.0 |
| Pie, 5,000, full | 9.0 | 8.8, 8.8 | 120.0, 120.0 | 120.0 |
| Doughnut, 5,000, plain | 57.0 | 63.0, 63.5 | 120.0, 120.0 | 120.0 |
| Doughnut, 5,000, full | 8.8 | 8.8, 8.8 | 120.0, 120.0 | 120.0 |
| Polar area, 5,000, plain | 57.5 | 60.2, 60.0 | 120.0, 120.0 | 120.0 |
| Polar area, 5,000, full | 11.5 | 11.5, 11.5 | 120.0, 120.0 | 120.0 |
| Radar, 5,000, full | 33.8 | 34.8, 35.0 | 120.0, 120.0 | 120.0 |
| Pie, 1,000, full | 44.5 | 45.0, 44.5 | 120.0, 120.0 | 120.0 |
| Doughnut, 1,000, full | 44.5 | 44.2, 44.2 | 120.0, 120.0 | 120.0 |
| Polar area, 1,000, full | 57.8 | 57.8, 58.5 | 120.0, 120.0 | 120.0 |

All other cells stay at 119 FPS or above on both sides. 22 of the 48 cells reached 119 FPS on the old code.
38 of the 48 cells reach it in both new passes. The 10 cells below 119 FPS all have 20,000 items. The two new
passes differ by less than 3% in each cell. One more pass of the delivered code (`final-pass.txt`, commit
`fc4e1de`) differs from their mean by less than 4% in each cell. It has 39 cells at 119 FPS or above, because
scatter, 20,000, full is at the limit: 117.8 to 119.5 FPS over the three passes.

The times at 20,000 items, the mean of the two old passes to the mean of the two new passes:

| Cell | Update, ms | Draw, ms | UI busy P90, ms | Raster P90, ms |
| --- | ---: | ---: | ---: | ---: |
| Line, 20,000, plain | 2.17 to 0.91 | 0.90 to 0.93 | 5.0 to 3.5 | 1.1 to 1.1 |
| Line, 20,000, full | 2.34 to 0.99 | 6.21 to 6.04 | 12.1 to 10.6 | 8.7 to 8.6 |
| Bar, 20,000, plain | 8.66 to 3.74 | 8.88 to 7.75 | 25.5 to 13.7 | 15.2 to 18.0 |
| Bar, 20,000, full | 13.93 to 7.46 | 10.11 to 10.34 | 34.1 to 25.1 | 15.4 to 18.4 |
| Scatter, 20,000, plain | 6.22 to 2.72 | 2.59 to 2.41 | 12.0 to 7.5 | 1.1 to 1.2 |
| Scatter, 20,000, full | 13.00 to 3.67 | 2.98 to 2.52 | 19.9 to 8.8 | 1.4 to 1.4 |
| Bubble, 20,000, plain | 19.83 to 3.20 | 5.81 to 2.45 | 33.8 to 8.1 | 14.5 to 1.3 |
| Bubble, 20,000, full | 72.62 to 5.54 | 5.72 to 2.88 | 88.1 to 12.5 | 14.6 to 1.4 |
| Pie, 20,000, plain | 57.12 to 1.38 | 14.59 to 1.10 | 77.3 to 4.4 | 11.9 to 1.0 |
| Pie, 20,000, full | 442.42 to 4.94 | 14.21 to 5.42 | 471.5 to 12.3 | 12.8 to 12.0 |
| Doughnut, 20,000, plain | 57.18 to 1.33 | 16.51 to 1.10 | 79.5 to 4.1 | 12.0 to 1.0 |
| Doughnut, 20,000, full | 443.11 to 5.08 | 16.11 to 7.57 | 470.2 to 14.9 | 12.9 to 12.2 |
| Polar area, 20,000, plain | 50.53 to 3.43 | 14.48 to 5.07 | 70.6 to 9.5 | 11.8 to 14.0 |
| Polar area, 20,000, full | 332.86 to 7.47 | 13.59 to 5.62 | 358.4 to 17.5 | 12.8 to 14.2 |
| Radar, 20,000, plain | 11.52 to 3.74 | 1.47 to 1.38 | 17.3 to 8.4 | 1.7 to 1.6 |
| Radar, 20,000, full | 49.04 to 3.21 | 60.21 to 5.38 | 116.5 to 13.0 | 16.5 to 19.7 |

A frame at 120 Hz needs both the UI busy time and the raster time below 8.33 ms. Three causes explain most
of the gain:

- A hidden legend built its items on each update of a pie, doughnut or polar area chart, also with no reader
  (Chart.js ADRs 0092 and 0099). The build was 82.7% of the samples of pie at 20,000 items, full preset.
- The option resolver ran per item, for options that a loop can prove static (Chart.js ADRs 0093, 0094, 0095,
  0096 and 0102). A context refresh was 21.6% of the samples of scatter (Chart.js ADR 0101).
- Slices and circles with varying radii drew through a path for each item. Native arcs, one arc for a run of
  slices of one color and a circle atlas replace these paths (Chart.js ADR 0097). The angle lines and the point
  labels of a radar take static plans (Chart.js ADR 0095).

The data-only path of `ChartView` is opt-in (Chart.js ADRs 0098 and 0100), and the lab turns it on. The last
column of the first table is the same code with a full update on each tick. It shows that most of the gain
does not need the opt-in. The data-only path adds the most in bar, 20,000, full: 41.8 to about 50.8 FPS.

The scene layers of Chart.js ADR 0097 move work from the UI thread to the raster thread. One pass with
layers and one pass without them:

| Cell | FPS with layers | FPS without | UI busy P90, ms, with and without | Raster P90, ms, with and without |
| --- | ---: | ---: | ---: | ---: |
| Bar, 20,000, plain | 56.5 | 62.8 | 13.5, 16.7 | 18.1, 15.0 |
| Bar, 20,000, full | 50.2 | 43.2 | 25.2, 28.7 | 18.5, 15.5 |
| Polar area, 20,000, plain | 73.0 | 83.0 | 9.4, 12.3 | 13.9, 11.5 |
| Polar area, 20,000, full | 67.2 | 57.5 | 17.2, 19.8 | 14.3, 11.7 |
| Bar, 5,000, plain | 120.0 | 120.0 | 3.8, 5.3 | 6.6, 5.3 |
| Bar, 1,000, plain | 120.0 | 120.0 | 1.0, 2.2 | 3.7, 3.1 |

Bar and polar area at 20,000 items are the only cells with a difference above 3% in FPS. The layers lose in
the plain preset, where the raster thread is the limit, and win in the full preset, where the UI thread is the
limit. The two presets have about the same chunk count, so that a rule by chunk count cannot separate them.
Thus the layers stay. Below 20,000 items, both forms reach 119 FPS or above in each cell.

The causes of what remains, from the profiles at 20,000 items:

- Bar: one `drawRect` for each bar, 29% to 37% of the UI samples, and a raster P90 of 18 ms. Impeller issues
  one draw for each bar. 120 FPS needs a form with other pixels, for example `drawVertices`.
- Pie and doughnut, full preset, and polar area: one `drawArc` for each slice that a run cannot merge, because
  of another color or another radius. It is 31% to 38% of the UI samples of the three profiles. The raster P90
  is 12 ms to 14 ms.
- Radar, full preset: one Impeller draw for each of the 20,000 angle lines. The raster P90 of about 20 ms is
  the limit, and the one native call of Chart.js ADR 0103 gains only UI time.
- Line, full preset: the filler and the cubic path work, with both threads near 8.33 ms.
- Bubble and scatter, full preset: the per-point update on the UI thread, with almost no raster load.

All FPS values are engine frame timings on one Mac, with no presentation feedback.

## 66. The curve and the markers of a dense line draw

Chart.js ADR 0104 removes repeated work from a line draw and from the markers of each chart type with points. These
figures come from the test engine, with no window: `flutter test` on the VM, a real chart at 20,000 items, one
`update('none')` for each step, and the time from `beforeDraw` to `afterDraw` over the last 100 of 200 steps. Each
side has 2 runs, in the order old, new, old, new. The figures give the direction of the Dart cost only. They do not
contain the raster thread, and 2 runs are a weak interval.

| Chart | Draw P50, ms, old | Draw P50, ms, new | Draw P90, ms, old | Draw P90, ms, new |
| --- | ---: | ---: | ---: | ---: |
| Line: curve, fill and markers | 11.1 | 7.7 | 19.1 | 12.9 |
| Scatter: alternating colors | 6.4 | 3.0 | 8.3 | 7.2 |
| Bubble: alternating colors | 3.9 | 2.3 | 7.7 | 5.1 |
| Radar: line and markers, no grid | 12.7 | 9.5 | 20.0 | 18.3 |

On the line chart, the parts on a settled chart were: the bound search of the fill 0.5 ms before and 0.06 ms after,
one native curve path with its walk about 1.15 ms, and the markers about 2.6 ms before and about 0.6 ms after. The
draw still builds two native curve paths: the partitioned fill and the line.

A pass of `apps/chart_benchmark_lab` on Impeller, in [`benchmarks/line-full/`](benchmarks/line-full/README.md), gave
these means of 2 runs for each side, at 20,000 items with the full preset:

| Cell | FPS, old | FPS, new | UI busy P90, ms, old | UI busy P90, ms, new | Raster P90, ms, old | Raster P90, ms, new |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Line | 100.9 | 116.4 | 11.4 | 7.4 | 8.8 | 8.8 |
| Scatter | 116.9 | 120 | 9.8 | 8.3 | 1.4 | 1.5 |
| Bubble | 92.5 | 108.4 | 13.4 | 12.1 | 1.4 | 1.4 |
| Radar | 51.5 | 52.3 | 13.8 | 11.9 | 22.6 | 21.7 |

The mean draw of the line fell from 6.3 ms to 3.6 ms. The UI thread of the line is now below 8.33 ms. Its raster P90
of 8.8 ms and raster mean of 8.5 ms are the limit that remains. The raster thread of the radar stays its limit, as
§65 states. The update of the bubble, 5.7 ms, stays the largest part of its UI thread.

## 67. The lab on the web and on phones

The setup is in [`benchmarks/devices/`](benchmarks/devices/README.md). Each pass ran once, so that the figures are a map
and not a comparison.

FPS of the lab matrix at 5,000 items with the full preset. The Mac column is the last pass of §65:

| Chart | Mac | iPhone 17 Pro | Pixel 8a | Web, WebAssembly | Web, JavaScript |
| --- | ---: | ---: | ---: | ---: | ---: |
| Line | 120 | 120 | 120 | 3.5 | 3.8 |
| Bar | 120 | 120 | 81 | 120 | 71 |
| Scatter | 120 | 120 | 120 | 120 | 120 |
| Bubble | 120 | 120 | 120 | 120 | 120 |
| Pie | 120 | 120 | 80 | 67 | 59 |
| Doughnut | 120 | 120 | 86 | 37 | 29 |
| Polar area | 120 | 120 | 93 | 118 | 64 |
| Radar | 120 | 120 | 70 | 22 | 17 |

At 1,000 items, every cell holds at least 119 FPS on both phones. On the web, the exceptions are line with 44 to 115 FPS,
and radar with the full preset on JavaScript, at 107 FPS. At 20,000 items with the full preset, the iPhone gives 30 to
102 FPS, the Pixel 13 to 75 FPS and WebAssembly 0.5 to 119 FPS.

**The web.** A long path is the limit. The raster P90 of a line with the full preset is 21 ms at 1,000 points, 286 ms at
5,000 and 1,951 ms at 20,000. A plain line with no curve also takes 21 ms at 5,000 points, against 2 ms for 1,000 bars.
§68 gives the fix, and Chart.js ADR 0105 the cause as far as it is known. JavaScript adds a slow draw on the UI thread: 8 ms at 5,000 bars and 33 ms
at 20,000, against 1.4 ms and 7 ms on WebAssembly.

**Everyday use.** The tests with a FPS below 110, of 62 tests with a meaningful FPS (no `mount` tests) on each target:

| Target | Tests below 110 FPS |
| --- | --- |
| Mac | none |
| iPhone 17 Pro | none |
| Pixel 8a | bubble 2,000: hover 88, animate 99; scatter 1,000: resize 80; line 1,000: resize 98; line 5,000: hover 108; 5 stacked bar series of 200, new data each frame: 91 |
| Web, WebAssembly | line 1,000: animate 96, hover 86, resize 79; line 5,000: animate 48, hover 22; 5 lines of 1,000: animate 42, new data each frame 18 |

Each failure on the web is a curved line. A line of 1,000 points with no curve on a time axis holds 120 FPS.

The time from a new chart to the end of its first draw, P50 over the chart types: Mac 4 to 12 ms, iPhone 4 to 5 ms, Pixel
15 to 17 ms and web 6 to 7 ms, with a P90 of at most 28 ms. First paint is no limit.

**A long first frame of an animated update.** FPS hides it. The first update of an animation creates the animation objects
of each element. On scatter at 5,000 points, it takes 36 ms on the web, 53 ms on the Mac and the iPhone, and 73 ms on the
Pixel, once for each change of the data. On the Pixel, it takes 16 to 19 ms at 1,000 points of line or scatter.

## 68. Long paths in pieces on the web

Chart.js ADR 0105 draws a long stroke and a long line fill in pieces on the web. The setup is in
[`benchmarks/web-lines/`](benchmarks/web-lines/README.md). The old figures are the pass of §67. Each side ran once, with the
Mac in use by day.

| Lab matrix | WebAssembly, FPS, old | WebAssembly, FPS, new | Raster P90, ms, old | Raster P90, ms, new | JavaScript, FPS, old | JavaScript, FPS, new |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Line 1,000 full | 48.5 | 120 | 21.2 | 3.6 | 44.5 | 120 |
| Line 5,000 plain | 49.3 | 120 | 20.9 | 1.8 | 51.3 | 120 |
| Line 5,000 full | 3.5 | 120 | 286.5 | 8.6 | 3.8 | 82 |
| Line 20,000 plain | 44.3 | 120 | 24.0 | 1.9 | 43.8 | 120 |
| Line 20,000 full | 0.5 | 46 | 1,951 | 22.6 | 0.5 | 31 |
| Radar 5,000 plain | 95.5 | 120 | 11.2 | 2.0 | 82.5 | 120 |
| Radar 20,000 plain | 16.5 | 119 | 65.0 | 9.7 | 15.8 | 70.5 |

| Everyday tests, WebAssembly | FPS, old | FPS, new | Raster P90, ms, old | Raster P90, ms, new |
| --- | ---: | ---: | ---: | ---: |
| Line 1,000, animate | 95.8 | 120 | 11.8 | 3.2 |
| Line 1,000, hover | 85.8 | 120 | 12.3 | 3.2 |
| Line 1,000, resize | 78.5 | 120 | 15.4 | 8.4 |
| Line 5,000, animate | 48.3 | 118.5 | 48.4 | 6.5 |
| Line 5,000, hover | 21.8 | 120 | 48.3 | 7.7 |
| 5 lines of 1,000, animate | 42.3 | 83.5 | 60.4 | 13.0 |
| 5 lines of 1,000, new data each frame | 18.3 | 80.5 | 64.8 | 13.8 |

Tests below 110 FPS fell from 7 to 2 of 62, and both are the 5 lines. Other cells do not take this code. Some of them moved by up
to about 20% between the two passes, in both directions, for example pie at 5,000 with the full preset from 67 to 56 FPS. This
gives the noise of one pass by day.

What stays slow on the web at the full preset: radar at 5,000 and 20,000 (24 and 5 FPS), pie and doughnut at 5,000 (56 and 29 FPS)
and at 20,000 (12 and 6 FPS). JavaScript also keeps its slow draw on the UI thread: bar at 20,000 gets 18 FPS, against 36 on
WebAssembly.

## 69. Zoom and pan steps

The steps of the zoom port `flutter_chartjs_plugin_zoom_port` on three devices, profiled before a change, and nine
exact host changes that the profiles chose. Two more changes need a decision first: Chart.js ADRs 0111 and 0112.

**The bench cases** (commit `cc4fe90`). The mode `zoom` of `apps/chartjs_gallery/lib/bench/chart_bench.dart` times a
line chart of one dataset with a visible x axis (linear or time) and a visible linear y axis, at 1,000 and 20,000
points: `parsing: false` with `{x, y}` Maps, `animation: false`, `events: []`, a canvas of 800 x 480 at DPR 1.

| Case | Step |
| --- | --- |
| `zoom.base`, `zoom.idle` | `draw()` and `update('none')`, without and with the plugin and its default options |
| `zoom.wheel` | one `wheel` event at the center, `deltaY` -100 and +100 in turn; the listener zooms with the mode `'zoom'` |
| `zoom.pan` | one `pointermove` of 20 px back and forth, after a press past the threshold, mode `x` |
| `zoom.drag` | one `mousemove` of the drag box; the listener only draws |
| `zoom.pinch` | one `pointermove` of the second of two touch pointers, a spread and a pinch in turn |
| `zoom.api`, `zoom.apiPan` | `chart.zoom(1.05)` and `chart.zoom(1 / 1.05)`, `chart.pan(+20 px)` and `chart.pan(-20 px)` in turn |

A step dispatches one event with `canvas.dispatchEvent` (Chart.js ADR 0108) or calls the API, and ends the
recording: the work of one frame with one input. The cases put the scale ranges back with `zoomScale` before each
pair of steps, outside the timing.

**The method.** Profile builds of `lib/main_bench.dart` with `--dart-define=CASES=zoom`, 16 cases at 1,000 and
20,000 points. The timing build has no marks: 2 runs on each device, and the step p50 below is the mean of the two
runs. A second build with `PROFILE_MARKS=true` prints the `BENCH_MARK` lines, and a VM service client fetched the CPU
samples of the UI isolate (`getCpuSamples`, a period of 1 ms, native time with its Dart caller) for the window of
each case, one run. A share counts the samples of the timed steps only, not the range restore.

- Pixel 8a: Impeller on Vulkan, 120 Hz, started with `adb` with no VM service client for the timing, a gate on the
  battery temperature, the thermal status and the big-core frequency. The two runs differ by at most 1.5% in 29 of
  32 cases.
- iPhone 17 Pro: iOS 27.2, wired, started with `devicectl`. Run 2 was 0.4% to 6.7% slower than run 1.
- MacBook Pro, M3 Max: Impeller on Metal, by day with the Mac in use. The two runs differ by at most 3% in 31 of 32
  cases.

**Before** (commit `cc4fe90`), step p50 in ms, the mean of 2 runs:

| Case | Points | x axis | Pixel 8a | iPhone 17 Pro | Mac |
| --- | ---: | --- | ---: | ---: | ---: |
| `zoom.idle` update | 1,000 | linear | 1.249 | 0.554 | 0.618 |
| `zoom.idle` update | 20,000 | linear | 9.956 | 4.253 | 4.672 |
| `zoom.idle` update | 1,000 | time | 1.752 | 0.720 | 0.832 |
| `zoom.idle` update | 20,000 | time | 10.678 | 4.555 | 4.899 |
| `zoom.idle` draw | 1,000 | linear | 0.265 | 0.124 | 0.139 |
| `zoom.idle` draw | 20,000 | linear | 3.641 | 1.587 | 1.738 |
| `zoom.wheel` | 1,000 | linear | 1.219 | 0.521 | 0.576 |
| `zoom.wheel` | 20,000 | linear | 8.058 | 3.433 | 3.769 |
| `zoom.wheel` | 1,000 | time | 1.678 | 0.693 | 0.792 |
| `zoom.wheel` | 20,000 | time | 8.764 | 3.661 | 4.040 |
| `zoom.pan` | 1,000 | linear | 1.185 | 0.515 | 0.562 |
| `zoom.pan` | 20,000 | linear | 8.340 | 3.593 | 3.868 |
| `zoom.pan` | 1,000 | time | 1.718 | 0.704 | 0.798 |
| `zoom.pan` | 20,000 | time | 9.096 | 3.829 | 4.117 |
| `zoom.drag` | 1,000 | linear | 0.281 | 0.130 | 0.139 |
| `zoom.drag` | 20,000 | linear | 3.792 | 1.639 | 1.714 |
| `zoom.pinch` | 1,000 | linear | 1.172 | 0.502 | 0.557 |
| `zoom.pinch` | 20,000 | linear | 7.434 | 3.300 | 3.664 |
| `zoom.api` | 1,000 | linear | 1.244 | 0.538 | 0.602 |
| `zoom.api` | 20,000 | linear | 8.253 | 3.569 | 3.950 |
| `zoom.apiPan` | 1,000 | linear | 1.196 | 0.517 | 0.565 |
| `zoom.apiPan` | 20,000 | linear | 8.373 | 3.591 | 3.865 |

At 20,000 points the Pixel misses a frame of 8.33 ms at 120 Hz with a pan (8.34 ms) and with each input on a time
axis (8.76 to 9.10 ms), and comes close with a wheel or an API call (8.06 to 8.37 ms). The hooks of the registered plugin cost 0.4% to 1.6% of an idle update at 1,000 points and 0.1% at 20,000.

**Where the time goes.** The work of the zoom port itself, with the host helpers that it calls but without the
update and the draw that it starts, is 1.0% to 3.9% of an input step at 1,000 points and 0.0% to 1.8% at 20,000:
at most 47 µs (Pixel, wheel at 1,000) and 132 µs (Pixel, pinch at 20,000). Reads of the option facades are about two
thirds of it. 92% to 99% of each input step is the `update` and the `draw` of the host. An input step at 20,000
points costs 15% to 25% less than an idle update, because the range restore sets `min` and `max` of both scales and
the update skips the scan of the data limits; in an app that zooms x only, the y scale has no bounds and the scan
(14.8% to 15.9% of a 20,000-point update) stays.

**The floor.** The ticks, the layout, the element update and the draw, which even a range update must do, are
65% to 78% of an input step at 1,000 points, 91% to 96% at 20,000 and 99% to 100% of a drag-box step. At 1,000
points the draw is 35% to 42% of the step (the scale layers with tick text and grid 12% to 22%), the layout 11% to
21% and the elements 9% to 16%. At 20,000 points the elements are 29% to 38% (the parsed reads of
`LineController.updateElements` 10% to 17%) and the draw 51% to 61% (the circle batch with `drawRawAtlas` 16% to
26%, the work of each point in the batch 12% to 18%, the line stroke about 10% to 13%).

**The changes.** Each is exact: every case outside its guards keeps the old path. The gain is what the profiles
give for the removed work, as a share of a step on Pixel / iPhone / Mac; the measured gains go into the table
"After".

| # | Change | What it removes | Record | Expected gain, 1,000 points | Expected gain, 20,000 points |
| ---: | --- | --- | --- | --- | --- |
| 1 | The previous x of the gap test | the read `prevParsed[iAxis]` of each point in the line and scatter loops, when no user code can run between the two reads | Chart.js ADR 0109, row `adapt-native-gap-reads` | 0.8-1.2% / 1.3-2.2% / 1.4-1.6% | 3.5-4.4% / 4.4-5.8% / 4.1-5.0% |
| 2 | The held circle run | the bound, color and batch tests of each fill and stroke after the first circle of a run | `CircleBatch.hold` and `addHeld` (port-only) | 0.4-1.4% / 0.8-1.5% / 1.5-2.0% | 1.7-2.6% / 2.8-3.5% / 3.5-5.2%; drag box 4.2% / 6.3% / 9.6% |
| 3 | The typed scope merge | the walk by name of `mergeIf` and `merge` between typed scopes in `mergeScaleConfig` | row `adapt-typed-scope-merge` | 4.2-5.3% / 4.9-5.9% / 4.9-6.0% | 0.8-1.2% / 0.5-0.9% / 0.9-1.5% |
| 4 | The loop-invariant truthiness | `jsTruthy` of `stacked` and `segment` at each point (the `alignToPixels` part is reverted, see below) | row `adapt-loop-invariant-truthiness` | 0.0-0.4% / 0.5-1.3% / 0.6-1.7% | 0.3-0.8% / 1.9-3.0% / 2.3-4.3% |
| 5 | The record key of the number format | the String key and the options Map of each tick label | row `adapt-numeric-tick-format-key` | 2.2-3.0% / 2.0-3.0% / 1.4-3.1% | 0.2-0.8% |
| 6 | The local-zone offsets | the field form of the offset read on the VM and the misses of a cache of one interval | Chart.js ADR 0110 | time axis: 2.1-2.7% / 2.4-2.8% / 2.8-3.2% | time axis: 0.6-1.1% |
| 7 | The first reads of the resolvers | the second walk of the scopes of a sub-resolver when it adds nothing, and the second key lookup of a miss | row `adapt-resolver-single-walk` | 0.9-1.4% / 1.3-2.0% / 1.5-2.0% | 0.1-0.5% |
| 8 | `_isValidKey` | a list literal for each merged key | none (the same three compares) | 0.2-0.6% / 0.6-1.1% / 0.5-1.1% | 0.0-0.3% |
| 9 | The category parse | the label scan for a value that is not a String, with native `List<String>` labels | row `adapt-category-string-labels` | no bench case | no bench case |

Together, with the overlaps counted once, the profiles give 12.5% / 15.7% / 14.5% of a wheel step at 1,000 points,
8.1% / 12.1% / 14.2% at 20,000 and 4.2% / 6.3% / 9.6% of a drag-box step at 20,000. On the Pixel, the wheel and pan
steps at 20,000 points would fall from 8.06 and 8.34 ms to about 7.4 and 7.6 ms.

Notes of the changes:

- Item 1 holds the x only on the paths of its guards: the exact controller, a direct update, no stack and no
  `segment`, axes x and y, the native linear projection of both scales, native items, and options that are shared
  or come from the indexed-color plan. The built-in scatter shares no options, so its loop holds the x only in that
  plan, and a time x axis is no native projection: the time cases keep the read. On AOT the read costs 8.6-9.1 ns
  per point, the guard of the item class 2.4 ns. On dart2wasm only `ParsedItem` qualifies. The define
  `CHARTJS_NATIVE_GAP_READS=false` gives the old reads.
- Item 2 on the Mac test VM (JIT, indicative): the loop of 20,000 stroked circles takes 490-556 µs against
  1,023-1,117 µs.
- Item 3 on the Mac test VM (JIT, indicative): `mergeIf` of `defaults.scale` into a new scale scope 10.3 to 5.6 µs, a
  `Config` with two linear scales 30.5 to 19.1 µs.
- Item 6: one update of a 1,000-point local time axis reads the platform offset 227 times in place of 335 (20,000
  points: 348 in place of 528). Fewer than 64 slots gave no gain, because one update makes 37 to 58 intervals.

**Proposed, with no code.** Chart.js ADR 0111 (an opt-in range update, `Chart.updateRanges(mode)` with the zoom
option `rangeOnlyUpdates`) would skip the rebuild of the configuration in each zoom or pan step: 23% to 32% of a
1,000-point linear step, 18% to 25% with a time axis and 4.2% to 7.5% at 20,000 points. Chart.js ADR 0112 (frame-aligned
coalescing of the continuous input of the host) would run one update for each pointer and frame. The input probe
`apps/chartjs_gallery/lib/main_input_probe.dart` counts the input of each frame: on the Pixel 8a, `adb shell input
swipe` (one synthetic pointer, 0.5 s) gave 1.35 to 1.44 moves per frame, at most 2, with as many updates and draws,
at about 58 frames per second against a vsync of 120 Hz. `FrameTiming` build times leave the input work out; the
frame rate shows it. The counts of a real pinch and pan on both phones go into Chart.js ADR 0112.

**Dropped.**

| Change | Reason (measured) |
| --- | --- |
| The zoom draw hooks | 0.3% to 0.6% of an idle draw at 1,000 points, 0.0% to 0.1% at 20,000 |
| `_values`, `getScaleUnderPoint` and the second `isHorizontal()` of the zoom port | 0.1% to 0.2% of a step |
| `_GestureManager._buildEvent` of the zoom port | 0.0% to 0.2% of a pinch or pan step |
| A typed slot for the zoom options | 0.4% to 1.6% at 1,000 points; it comes with zoom phase 5 as an API item |
| The string switch of `PluginHook.of` and the compares of `notify` | 0.0% to 0.5% of each step |
| `_notifyStateChanges` and `pluginScopeKeys` | 0.2% to 1.0% and 0.1% to 0.3% of a 1,000-point step, within the noise; the rebuild of the descriptors is a part of Chart.js ADR 0111 |
| One `Animations` for each update of the line element | 0.1% to 0.6%; the loops already take the direct path with `animation: false` |
| The bounding box of the canvas, the `List.of` of `_invokeListeners`, the replay of the last event | not in the bench (no host, `events: []`); estimates below 1% |
| An animated zoom | not measurable: the bench runs with `animation: false` |
| A cache of the data-limit scan and the other changes that `update` does not allow | they change the behavior of `update` |

**After.** Old code `cc4fe90` against new code `d14d36f`, on 2026-11-10: step p50 in ms. Each side ran once on each
target, old first. Safari ran twice on each side, and its figures are the mean of the two runs. The iPhone figures use a
second new run: the first new run was slower, probably from heat. The native apps are profile builds of
`lib/main_bench.dart`, as above. The browsers loaded one web build of each side,
`flutter build web --wasm --profile`. Chrome ran WebAssembly with skwasm, and Firefox and Safari ran JavaScript with
CanvasKit, each with `crossOriginIsolated` true.

These figures are of `d14d36f`, before commit `8084b6b` reverted the `alignToPixels` part of item 4 (see below). The
revert brings the two slow Safari rows, `zoom.base` and `zoom.idle` update on the time axis at 20,000 points, back to
the old time. It can cost a small part of the gain on the other targets. That part was not measured.

Native apps:

| Case | Points | x axis | Pixel 8a, old | Pixel 8a, new | iPhone 17 Pro, old | iPhone 17 Pro, new | Mac, old | Mac, new |
| --- | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `zoom.idle` update | 1,000 | linear | 1.265 | 1.144 | 0.534 | 0.480 | 0.619 | 0.533 |
| `zoom.idle` update | 20,000 | linear | 9.941 | 8.467 | 4.184 | 3.569 | 4.562 | 3.837 |
| `zoom.wheel` | 1,000 | linear | 1.219 | 1.075 | 0.510 | 0.443 | 0.574 | 0.487 |
| `zoom.wheel` | 20,000 | linear | 7.992 | 6.937 | 3.454 | 2.860 | 3.758 | 2.956 |
| `zoom.wheel` | 1,000 | time | 1.684 | 1.505 | 0.685 | 0.598 | 0.778 | 0.674 |
| `zoom.wheel` | 20,000 | time | 8.694 | 7.632 | 3.674 | 3.125 | 3.971 | 3.305 |
| `zoom.pan` | 1,000 | linear | 1.182 | 1.049 | 0.504 | 0.435 | 0.555 | 0.473 |
| `zoom.pan` | 20,000 | linear | 8.230 | 7.008 | 3.650 | 2.975 | 3.775 | 3.060 |
| `zoom.pinch` | 1,000 | linear | 1.153 | 1.035 | 0.505 | 0.432 | 0.556 | 0.474 |
| `zoom.pinch` | 20,000 | linear | 7.426 | 6.382 | 3.335 | 2.737 | 3.507 | 2.853 |
| `zoom.drag` | 1,000 | linear | 0.281 | 0.235 | 0.126 | 0.106 | 0.137 | 0.110 |
| `zoom.drag` | 20,000 | linear | 3.838 | 2.880 | 1.594 | 1.196 | 1.709 | 1.168 |
| `zoom.api` | 1,000 | linear | 1.214 | 1.092 | 0.528 | 0.468 | 0.585 | 0.497 |
| `zoom.api` | 20,000 | linear | 8.229 | 6.919 | 3.600 | 2.949 | 3.781 | 3.058 |

Browsers:

| Case | Points | x axis | Mac Chrome, old | Mac Chrome, new | Mac Firefox, old | Mac Firefox, new | Mac Safari, old | Mac Safari, new | Pixel Chrome, old | Pixel Chrome, new | Pixel Firefox, old | Pixel Firefox, new |
| --- | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `zoom.idle` update | 1,000 | linear | 0.725 | 0.646 | 1.780 | 1.540 | 1.230 | 1.160 | 1.776 | 1.675 | 4.980 | 4.400 |
| `zoom.idle` update | 20,000 | linear | 5.151 | 4.805 | 10.480 | 8.720 | 6.640 | 6.780 | 11.525 | 11.065 | 23.120 | 20.960 |
| `zoom.wheel` | 1,000 | linear | 0.666 | 0.594 | 1.760 | 1.560 | 1.200 | 1.120 | 1.941 | 1.870 | 5.060 | 4.481 |
| `zoom.wheel` | 20,000 | linear | 4.076 | 3.760 | 8.160 | 7.620 | 5.000 | 4.820 | 10.510 | 9.825 | 20.660 | 18.040 |
| `zoom.wheel` | 1,000 | time | 0.829 | 0.760 | 2.240 | 1.960 | 1.480 | 1.390 | 2.225 | 2.020 | 6.400 | 5.720 |
| `zoom.wheel` | 20,000 | time | 4.534 | 4.109 | 8.700 | 8.580 | 5.470 | 5.500 | 12.175 | 11.029 | 22.500 | 20.280 |
| `zoom.pan` | 1,000 | linear | 0.646 | 0.580 | 1.680 | 1.500 | 1.140 | 1.050 | 1.750 | 1.670 | 4.880 | 4.340 |
| `zoom.pan` | 20,000 | linear | 4.689 | 3.971 | 8.200 | 7.200 | 5.090 | 5.370 | 11.130 | 10.425 | 20.440 | 18.200 |
| `zoom.pinch` | 1,000 | linear | 0.639 | 0.555 | 1.640 | 1.480 | 1.080 | 0.960 | 1.695 | 1.615 | 4.900 | 4.300 |
| `zoom.pinch` | 20,000 | linear | 4.326 | 3.645 | 7.620 | 7.140 | 4.860 | 4.560 | 10.260 | 9.620 | 19.920 | 18.040 |
| `zoom.drag` | 1,000 | linear | 0.154 | 0.135 | 0.240 | 0.220 | 0.200 | 0.190 | 0.350 | 0.330 | 0.860 | 0.680 |
| `zoom.drag` | 20,000 | linear | 2.196 | 1.799 | 1.900 | 1.480 | 1.470 | 1.290 | 4.795 | 4.200 | 4.900 | 3.860 |
| `zoom.api` | 1,000 | linear | 0.669 | 0.580 | 1.760 | 1.520 | 1.200 | 1.070 | 1.796 | 1.685 | 5.080 | 4.480 |
| `zoom.api` | 20,000 | linear | 4.714 | 4.015 | 8.120 | 7.240 | 5.100 | 4.800 | 11.415 | 10.830 | 20.720 | 18.320 |

The geometric mean of new/old over all 16 cases, at 1,000 / 20,000 points: Pixel 8a 0.887 / 0.832,
iPhone 17 Pro 0.869 / 0.811, Mac 0.846 / 0.778, Mac Chrome 0.875 / 0.843, Mac Firefox 0.885 / 0.854,
Mac Safari 0.943 / 0.974, Pixel Chrome 0.930 / 0.915, Pixel Firefox 0.882 / 0.869.

The new code is faster in all 32 cases on each target except Safari. On the Pixel 8a at 20,000 points, each input step
is now below the frame of 8.33 ms at 120 Hz: the wheel and pan steps fell from 7.99 and 8.23 ms to 6.94 and 7.01 ms, and
on a time axis from 8.69 and 9.08 ms to 7.63 and 7.84 ms. The noise of a single row: the old native runs are within
4.8% of the table "Before", a second old run gave -15% to +17.5% on Pixel Chrome and -2.1% to +24.2% on Pixel Firefox,
`zoom.pan` on the time axis at 20,000 points went from -13.6% in the first Safari run to +15.9% in the second, and
Firefox and Safari give times in steps of 0.020 ms. Files: `.handover/zoom-perf/ab/`, outside the repository.

**Safari and the `alignToPixels` field.** In the first Safari run, the base and idle updates on the time axis at
20,000 points were 22% slower with the new code. A second run gave +17.5% and +13.2%. The extra time was all in the
dataset update (60-79% slower). A bisect of the nine commits in Safari found commit `a06746b` (item 4), and a run
with only its `Scale._alignToPixels` part reverted brought the dataset update back to the old time (1.97 ms against
2.02-2.17 ms). The part made `_alignToPixels` a `bool` with the `ToBoolean` at its write, so that
`getPixelForDecimal` became very small. With the time cases first in the page, the new code was not slower (time
dataset update 2.195 → 2.115 ms). Thus Safari's engine probably optimizes the point loop for the linear scale of the
first chart and loses that form when a time chart comes later. A Flutter web app is one page, so a dashboard with a
linear chart and then a time chart reaches the slow state. Chrome and Firefox got faster on the same rows. The
`alignToPixels` part is reverted; the loop part of item 4 stays. Files:
`.handover/zoom-perf/ab/mac-safari/` (bisect.md, confirm.md), outside the repository.

**Chart.js ADR 0111, implemented** (2026-11-10). `Chart.updateRanges(mode)` and the zoom option `rangeOnlyUpdates`
are in the tree, default off: no behavior of `update` changed (the observation digests hold). A full update of an
exact chart now also records the snapshot of the range path (one pass over the dataset List). The twins of
`test/port/core/range_update_test.dart` and of the group `range-only updates` of the zoom `test/port/plugin_test.dart`
give the results of `update`. The bench define `--dart-define=ZOOM_RANGE_UPDATES=true` writes
`rangeOnlyUpdates: true` into the input cases of the mode `zoom` (the key `rangeUpdates` of their BENCH lines); the
cases `zoom.base` and `zoom.idle` stay as they are. The night run measures it on the Pixel 8a, the iPhone 17 Pro and
the Mac: one build of the same commit without and with the define, 2 runs per side, with the gain of the ADR's
section 10 as the estimate. It also times `zoom.base` and `zoom.idle` of the parent commit against this commit
without the define, for the cost of the snapshot on the default path. Its figures go here.

## 70. Stroke pieces in desktop browsers

Chart.js ADR 0113 strokes a `Path2D` in pieces from 2 commands when Flutter reports macOS, Windows or Linux for the
browser, and keeps the 128 commands of Chart.js ADR 0105 in other browsers and for the fill. Native apps keep one draw.
The question came from §68: in a desktop browser a line of 100 points had a higher raster time than a line of 1,000
points, because the shorter line takes one draw.

**The experiment** (2026-11-10, by day). `apps/chart_benchmark_lab` with a patch on `8084b6b` that sets the stroke rule
at run time and counts the strokes (not committed): the Chart.js port, type `line`, preset `plain`, one run of 4 s per
cell, a warm-up capture before the first cell of each page load or app start. Targets: a MacBook Pro M3 Max (120 Hz,
DPR 2, chart 1004 x 420 logical, 2008 x 840 bitmap pixels) with Chrome 157 (WebAssembly), Safari 27.0.1 and Firefox
159.0 (JavaScript) and the macOS app; a Pixel 8a with Chrome (WebAssembly, 922 x 788 bitmap pixels), Firefox 159.0.1
(JavaScript, 924 x 783) and the app; an iPhone 17 Pro with Safari 27.2 (JavaScript, 1026 x 900) and the app. The rules:
one draw, pieces from 128 commands (today's web rule), pieces from 2 commands, pieces from 32 and 64 commands, and
pieces of 20,000 and 80,000 pixels. Files: `.handover/pieces/` (`results/*.md`, `analysis.md`), outside the repository.

Raster p90 / raster mean in ms. FPS stayed at the cap in each desktop cell below 1,000 points (Chrome 119.5 to 120.25,
Safari 59.25 to 60.25, Firefox 57.75 to 60.25), and frame p90 did not move.

| Points | Mac Chrome, one draw | Mac Chrome, pieces | Mac Safari, one draw | Mac Safari, pieces | Mac Firefox, one draw | Mac Firefox, pieces |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 10 | 1.62 / 1.47 | 1.48 / 1.30 | 1.34 / 1.23 | 0.70 / 0.65 | 2.92 / 2.29 | 2.02 / 1.71 |
| 20 | 1.68 / 1.51 | 1.52 / 1.29 | 1.40 / 1.30 | 0.68 / 0.61 | 3.12 / 2.53 | 1.84 / 1.14 |
| 40 | 1.85 / 1.64 | 1.40 / 1.20 | 1.52 / 1.45 | 0.66 / 0.62 | 3.24 / 2.21 | 0.92 / 0.79 |
| 60 | 2.04 / 1.85 | 1.44 / 1.25 | 1.78 / 1.73 | 0.66 / 0.62 | 3.76 / 2.78 | 1.88 / 1.62 |
| 80 | 2.21 / 2.01 | 1.46 / 1.27 | 1.92 / 1.72 | 0.70 / 0.63 | 4.10 / 2.97 | 1.88 / 1.64 |
| 100 | 2.34 / 2.07 | 1.46 / 1.28 | 2.18 / 1.97 | 0.82 / 0.68 | 4.38 / 3.04 | 2.18 / 1.66 |

| Points | Pixel Chrome, one draw | Pixel Chrome, pieces | Pixel Firefox, one draw | Pixel Firefox, pieces | iPhone Safari, one draw | iPhone Safari, pieces |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 10 | 11.45 / 6.24 | 11.20 / 7.36 | 2.50 / 2.06 | 3.14 / 2.27 | - | - |
| 20 | 12.15 / 6.40 | 11.17 / 6.93 | 2.58 / 2.16 | 3.64 / 2.88 | - | - |
| 40 | 11.88 / 6.42 | 11.21 / 7.41 | 2.78 / 2.32 | 3.70 / 2.92 | - | - |
| 60 | 8.18 / 5.70 | 11.55 / 7.25 | 3.18 / 2.63 | 3.50 / 2.76 | - | - |
| 80 | 9.02 / 6.48 | 11.54 / 7.37 | 3.40 / 2.85 | 3.66 / 2.95 | - | - |
| 100 | 8.99 / 7.02 | 11.62 / 7.17 | 4.18 / 3.26 | 4.62 / 3.61 | 26 / 24.27 (32.25 FPS) | 49 / 34.98 (23.5 FPS) |

At 1,000 and 20,000 points the line has more than 128 commands, so both rules cut the same pieces. Today's pieces
against one draw there: Pixel Chrome 13.90 / 6.33 against 18.02 / 15.23 and 26.75 / 19.55 against 29.99 / 20.45; Pixel
Firefox 7.08 / 6.60 against 8.16 / 8.15 and 8.12 / 7.78 (42.75 FPS) against 27.70 / 12.58 (35 FPS); iPhone Safari 65 /
62.75 against 75 / 73.09 and 75 / 72.66 against 84 / 82.63. Pieces of 80,000 pixels hit a cliff in the Mac browsers
(Chrome 13.13 ms and 85.5 FPS at 20,000 points). In the native apps the three rules tie within the noise at each count
(macOS 4.33 / 3.33, 4.42 / 3.44 and 1.20 / 1.08 with one draw), and pieces add 0.04 to 0.39 ms of draw time on the UI
thread. Chart.js ADR 0113 has the tables of each target, the noise of each target and the open points.

The noise: the largest gap between two cells that draw the same thing is 0.12 / 0.16 ms in Mac Chrome, 0.34 / 0.10 in Mac
Safari, 0.50 / 0.66 in Mac Firefox, 1.85 / 0.64 in Pixel Chrome, 0.58 / 0.31 in Pixel Firefox and 2 / 1.54 in iPhone
Safari, from 3 to 6 single-run pairs.

**The gain is raster headroom.** Against one draw, the desktop rule lowers raster p90 by 0.14 to 0.88 ms in Mac Chrome,
by 0.64 to 1.36 ms in Mac Safari and by 0.90 to 2.32 ms in Mac Firefox at 10 to 100 points, with no change of FPS. The
phone browsers keep one draw below 128 commands: there pieces cost raster mean in Pixel Chrome (+0.53 to +1.55 ms at 10 to
80 points) and Pixel Firefox, and 23 ms of p90 and 9 FPS in iPhone Safari at 100 points.

**The night run** (the night of 2026-11-10, pending). One lab run of the final build: the Mac browsers at 10 to 100
points with a plain, a curved and a translucent line and a small chart, a chart with several datasets, and one phone
batch for each browser that shows no change; a repeat of the Pixel Firefox cells of pieces from 2 commands at 10 to 40
points with the temperature gate; and a pixel compare of a long curved line (200 to 1,000 commands, widths 1, 2 and 6,
opaque and translucent) between `96f6f9d` and this build in headless Chrome, for the new overlap of a curve, which also
changes the long lines of phone browsers. A run on Windows, Linux, a Chromebook or an Android tablet in desktop-site
mode waits for such hardware. Figures: to come.
