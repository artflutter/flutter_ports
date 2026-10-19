# Performance of the canvas layer

- Scope: the speed of the `dart:ui` canvas layer of phase 3
  ([Chart.js ADR 0013](adr/0013-canvas-model.md)) and of canvas text
  ([Chart.js ADR 0015](adr/0015-text.md)).
- Date: 2026-10-19
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
- Take the figures from the first seconds of a fresh process (section 2.5).
- **Baselines.** Section 4.5 describes the plain Flutter and the Chrome canvas baselines.

## 7. Open

- The plan [canvas-cuts-plan.md](canvas-cuts-plan.md) (proposed) needs a new baseline of the
  six scenarios on the three platforms, and a scenario with arcs, before its cuts land (its
  section 6.3).
- The 2 degree text rotation snap (section 5.5) stays until the toolchain pin is a stable release
  with the upstream fixes. Then remove it, and run the crash case of section 5.5 again.
- macOS and Chrome: the figures with the circle batch are still to measure. Sections 2 and 3 have
  the figures before the batch.
- The circle batch with bilinear sampling on the phone: section 4.2 was measured with nearest
  sampling.
- The draw time at 1000 points on the phone (section 4.3): the cause of the 4.5 ms that is not
  the points is not measured.
- iOS: not measured.
