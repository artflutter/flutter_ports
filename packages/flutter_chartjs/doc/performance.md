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
  date figures of phase 6 ([Chart.js ADR 0024](adr/0024-dates.md)).
- Date: 2026-10-20
- Related: [Chart.js ADR 0007](adr/0007-frame-scheduling.md) (frame scheduling),
  [Chart.js ADR 0009](adr/0009-no-display-only-js-exactness.md) (no display-only JS exactness).

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
- `chart` (phase 5): a real `Chart` of N points with the gallery controller
  `StressPointController`. The points get the typed options of the resolver. Section 6 gives its
  cases, and [Chart.js ADR 0021](adr/0021-typed-options-in-the-resolver.md) §8 gives its
  acceptance.
- `axes` (phase 6): the points of the mode `chart` on the real scales of phase 6
  (`apps/chartjs_gallery/lib/demo/stress_axes.dart`). The x axis is a linear, logarithmic,
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
  display-only ([Chart.js ADR 0009](adr/0009-no-display-only-js-exactness.md)).

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
  `--dart-define=MODE=<primitives|elements|bars|arcs|chart|axes>` selects the mode (section 1).
  Without `SCENARIO`, the modes `primitives` and `elements` run the six scenarios of section 2,
  `bars` runs 1000, 5000 and 20000 bars, and `arcs` runs 100, 1000 and 5000 arcs. The modes
  `chart` and `axes` run 1000, 5000 and 20000 chart points without labels. Each `STRESS` line
  starts with the key `mode`.
- **The mode `chart`** ([Chart.js ADR 0021](adr/0021-typed-options-in-the-resolver.md) §8)
  measures a real `Chart` with the gallery controller `StressPointController`. Each case runs with
  `animation: false`.
  - `--dart-define=CALL=draw` (the default) gives case (a): each frame calls `chart.draw()`.
  - `--dart-define=CALL=update` gives case (b): each frame writes new positions into the data
    objects, then calls `chart.update('none')`.
  - `--dart-define=SHARING=0` sets `enableOptionSharing` to false, as in a scatter chart. The
    default `SHARING=1` gives the sharing of a line chart.
  - `--dart-define=SCRIPTABLE=1` gives the points a scriptable `backgroundColor`. With
    `CALL=update`, it gives case (c).
  - `--dart-define=CALL=animate` gives the animation cost. The chart has
    `animation: {duration: 1000, loop: true}`. Its first update starts an animation of `x` and
    `y` of each point, which loops without end. In each frame, the animator ticks the N
    animations and calls `chart.draw()`. The key `animatorMs` gives the time of that tick
    without its draw. The tick includes the property writes of the animations (section 10.4).
  - The chart listens to no event (`events: []`), as the hosts of the other modes take no pointer
    input. Thus the position of the pointer does not change the figures.
  - `SHARING`, `SCRIPTABLE` and `LINE` accept only 0 or 1. Another value throws at the start.
  - Example: `flutter run --profile -t lib/main_stress.dart --dart-define=MODE=chart
    --dart-define=CALL=update --dart-define=SHARING=0 --dart-define=SCENARIO=5000x0`.
- **The mode `axes`** runs the points of the mode `chart` on real scales of phase 6
  (`lib/demo/stress_axes.dart`).
  - `--dart-define=SCALE=<linear|logarithmic|category|time>` selects the x axis (the default is
    `linear`). `--dart-define=YSCALE=<linear|logarithmic>` selects the y axis.
    `--dart-define=AUTOSKIP=0` turns off `ticks.autoSkip` of the x axis.
  - `CALL` is `draw` or `update`. `CALL=animate` throws at the start.
  - The data has `parsing: false`, so the x values must be sorted. Thus the x values are fixed and
    in order, and only the y values move. A time point has a timestamp, not an ISO text.
  - The `STRESS` line has the keys `call`, `scale`, `yScale` and `autoSkip`, the tick count
    `ticks` (after the auto skip) and the `rotation` of the x axis at the end, and the means
    `layoutMs`, `datasetsUpdateMs` and `datasetsDrawMs`. An inline plugin of the gallery takes
    them from the hooks of the chart. The library does not change.
- `--dart-define=LINE=0` turns off the line of the modes `primitives` and `elements`. The mode
  `chart` has no line. Thus the acceptance of Chart.js ADR 0021 §8 compares the mode `chart` in
  case (a) with the mode `elements` with `LINE=0`.
- Each `STRESS` line has the key `updateMs`: the time of `chart.update()` without its draw. It is
  0 outside the modes `chart` and `axes`. In these modes, `drawMs` is the time of `chart.draw()`,
  also of the draw inside `chart.update()`. Neither time includes the writes of the positions into the
  data objects. In the mode `chart`, the line also has the keys `animatorMs`, `call`, `sharing`
  and `scriptable`. With `LINE=0`, it has the key `line` with the value false.
- On macOS, run one scenario in each process. In the phase 4 runs, a process that ran several
  scenarios stopped to give frames after about 28 seconds (section 8.1).
- Take the figures from the first seconds of a fresh process (section 2.5).
- **Frameless benchmark.** `apps/chartjs_gallery/lib/main_bench.dart` times the costs of the UI
  thread of the chart path without frames (`lib/bench/chart_bench.dart`).
  - The chart is a `UiCanvasElement` of 800 x 480 without a host, so it gets `BasicPlatform`. It
    has `responsive: false`, `devicePixelRatio: 1`, `animation: false` and `events: []`. It has
    no labels and no title, so its draw is lower than `drawMs` of the stress entry.
  - After the first frame, the app runs each case for each N. It prints one line `BENCH {json}`
    for each case and N, and `BENCH done` at the end. A line has the median, p10 and p90 of
    `update('none')` without its draw, of `draw()` and of the end of the recording into a
    `ui.PictureRecorder`. The `axes` cases also give `layout`, `datasetsUpdate` and
    `datasetsDraw`, and `ticks` and `rotation` of the x axis.
  - The cases: `chart.a` (draw), `chart.b` (update, with and without sharing) and `chart.c`
    (update, scriptable), the cases (a) to (c) of the mode `chart`. For each scale type of the mode
    `axes`, a draw case and an update case, for example `axes.time`.
  - The loop is the loop of `tool/bench/src/harness.dart`: a warm-up, a calibration, then
    batches of a fixed number of iterations. A batch figure is the mean of its iterations, so
    each batch carries its part of the garbage collection. The update cases move the points
    outside the timing.
  - Defines: `CASES` (a comma list of modes, names or `mode.name`, the default is all cases), `N`
    (the default is `1000,5000,20000`), `BATCHES` (15), `BATCH_MS` (200) and `WARMUP_MS` (1000).
    An unknown selector throws at the start.
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
(index.d.ts:473). With `parsing: false` and primitive data, upstream throws nothing, where the
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
  element (`controller.bar.js:592`, `controller.polarArea.js:180`).

Source: Evidence E10 of Chart.js ADR 0025. Both choices stay Open in the ADR (Open 4 and Open 5).
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

[Chart.js ADR 0026](adr/0026-number-formatting-on-package-intl.md) (proposed) adds guards to
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

1. **The tick font for each tick.** `resolveTickFontOptions` (`core.scale.dart:2883`, called at
   `:1786` and `:2302`) takes 70.2 % of the category update at 5000 after section 11.7, about
   15 ms. It takes 10.1 / 15.0 / 12.5 % of the linear / logarithmic / time update. Upstream makes
   the same calls (`core.scale.js:1698`). The port adds a constant of about 3 µs for each call.
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
   -3 to -5 %: 0.05-0.09 ms at 5000 and 0.2-0.35 ms at 20000.
3. **`jsLog10` for each point** in `LogarithmicScale.getPixelForValue`
   (`scale.logarithmic.dart:401`, `fdlibm_log.dart`): 14.4 % of the logarithmic update, about
   59 ns for each call. The word access through `ByteData` (`_hi`, `_lo`, `_setHi`) takes 3.8 %,
   and the `k.toDouble()` conversions about 7 %. The form keeps the fdlibm arithmetic bit-exact,
   with views that do not box and a conversion that does not allocate. The fdlibm reference tests
   guard it. -7 to -11 % of the logarithmic update: 0.15-0.22 ms at 5000 and 0.6-0.9 ms at 20000.
4. **Platforms.** The figures of sections 11.6 and 11.7 come from the Pixel 8a only. The iPhone
   17 Pro was not connected, and the Mac had no idle window for the macOS and Chrome series.


## 12. Dates (phase 6)

[Chart.js ADR 0024](adr/0024-dates.md) (proposed) chooses the forms of the default date adapter
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
