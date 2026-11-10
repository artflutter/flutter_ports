# Chart.js ADR 0113: Paths in pieces on the web, with a stroke rule for desktop browsers

- Status: accepted (2026-11-10, by the porting lead). The code and the tests of section Tests pass. By the maintainer's
  rule of 2026-10-31, a record is accepted when its code passes the tests. The maintainer approved the decision on
  2026-11-10; the lab run of the final build (Open 6) is evidence, not a gate.
- Date: 2026-11-10
- Supersedes: [Chart.js ADR 0105](0105-web-long-paths-in-pieces.md). This record states its complete decision, with the
  stroke rule of a desktop browser and the overlap of a curve.
- Related: Chart.js ADRs [0034](0034-no-display-only-js-exactness.md) (no display-only exactness),
  [0089](0089-partitioned-baseline-fill.md), [0104](0104-line-curve-draw.md) and
  [0106](0106-canvas-shadows.md). Measurements: [performance.md](../performance.md) §68 and §70.
- Row of `differences.md`: `adapt-web-long-path-pieces`.

## Context

On the web, Skia draws on WebGL. A path with large bounds takes a slow route: an experiment points to a mask that the CPU
draws and uploads as a texture. The cause is inferred from the size at which the cost jumps, and it is not read from the
Skia source. A curved line of 5,000 points took 45 ms of raster time as one stroke, and its fill took 168 ms. The
compound fill of Chart.js ADR 0089, which helps Impeller, took 247 ms on the web. Cut into pieces with small bounds, the
same stroke took 6 ms and the same fill 1 ms. The cost follows the bounds of a piece: in `forms-1.txt` and `forms-2.txt`
of [benchmarks/web-lines/](../benchmarks/web-lines/README.md), cuts stay fast on bounds of about 176 x 200 and 61 x 800
bitmap pixels, and turn slow at 246 x 200 and 123 x 800. The limit of 40,000 pixels stays below that. It is an estimate
from these figures, not a measured form.

Chart.js ADR 0105 drew a path in pieces from 128 commands. The maintainer then saw that in a desktop browser a line of
100 points had a higher raster time than a line of 1,000 points: the shorter line takes one slow draw, the longer one
takes pieces. A lab experiment on 2026-11-10 measured ten stroke rules on nine targets (the tables below). In the three
browsers of a Mac, pieces from 2 commands lower the raster time of a line of 10 to 100 points. In the browsers of the
Pixel 8a and of the iPhone 17 Pro, the same pieces cost raster time, and one draw stays best below 100 points. Native
apps gain nothing from pieces at any count.

## Decision

On the web only (`dart.library.js_interop`), `UiCanvasContext` draws a large path in pieces. A piece has at most 512
commands and bounds of at most 40,000 bitmap pixels, or one segment. The switch `debugDrawLongPathsInPieces` turns the
form on for a test on the VM. Native engines keep each path as one draw.

1. **The stroke of a `Path2D`.** The path needs `UiCanvasContext.strokePieceMinCommands` commands:
   `desktopStrokePieceCommands` (2) when Flutter's `defaultTargetPlatform`, the system of the browser, is macOS, Windows or
   Linux, else `minPieceCommands` (128). Flutter reports Android for a browser on an unknown system, iOS for an iPad that
   asks for the desktop site and Linux for a Chromebook. An Android browser in desktop-site mode, the default of Chrome
   on large Android tablets, has no `Android` in its user agent and a platform string that starts with `Linux`: it
   reports Linux and takes the desktop rule on a mobile GPU. `debugDefaultTargetPlatformOverride` also wins in a release
   web build, so an app that forces a platform look also picks the stroke rule. The context reads the platform at each stroke, after the switch
   and the shadow test, so that `debugDefaultTargetPlatformOverride` picks the rule in a test. `uiPathPiecesOf` cuts the path into
   `ui.Path` pieces and keeps them in `Path2D.cache`, with the version rule of `uiPathOf`, for one scale and one line
   width; the rule of the system does not change a cut, so the cache needs no key for it. A piece that ends at a cut also
   takes the commands after the cut, for about 1.5 bitmap pixels along the line. A longer straight segment is cut at
   that point. A curve in the overlap is cut at the larger of the remaining overlap and two line widths, at the
   parameter of that length (de Casteljau, from the polyline of 16 steps of the parameter), so that its part has the
   geometry and the start tangent of the curve; a shorter curve stays whole. Thus the engine makes the join at the cut from the real segments, and the start of the next
   piece lies inside this piece, so that no seam of two soft ends shows across the line. A zero-length command does not
   start a cut. A close of a path that a cut divided takes a line to the start and the first commands of the subpath,
   with the same rule. A translucent stroke draws opaque pieces in one layer. The stroke declines, with one draw as
   before, for a path below the minimum, a command other than a move, a line, a cubic curve or a close, a coordinate past
   1e30, a `Path2D` whose list a reader got, a path with no piece, a dash, a shadow, a shader, another blend mode, a cap
   other than `butt`, a transform that is no similarity, and a translucent line of at most one bitmap pixel, which the
   engine draws as a hairline with another tone in a layer.
2. **The fill of the current path.** The rule of the system does not apply to the fill. The filler keeps the original
   path deferred from 128 points on the web (`deferredFillMinPoints`). `fill` calls `UiPathBuilder.tryFillColumns`, which
   needs 128 commands. It takes one subpath: a top edge that goes up in x, in lines and cubic curves with control points
   inside their segments, then lines along a horizontal base, then a close. Each piece has at least 8 columns, a clip
   without anti-aliasing on whole bitmap pixels, and geometry that passes each side of the clip by 4 bitmap pixels. Thus
   each pixel column belongs to one piece, also when the bitmap is not on the device pixels, and a translucent fill has
   no seam. The fill declines, with one draw as before, for any other shape, a coordinate past 1e30, a shader and another
   blend mode. The current path stays deferred for a later read.
3. **No compound fill on the web.** `takesPartitionedFill` is false, so that `tryPartitionedBaselineFill` returns at once,
   with no preflight.

What changed against Chart.js ADR 0105: the stroke threshold of a desktop browser (2 commands in place of 128), and the
overlap of a curve and of the first commands of a divided close. In Chart.js ADR 0105 a curve stayed whole in the
overlap, and a close took whole first commands. On a dense line a curve is a few pixels long, so this cost nothing. On a
short line of a desktop browser a curve is 50 to 250 pixels long, and the overlap drew it twice: the twins of section
Pixels found up to 14.8% more ink on a thin curved line. A curve part of at least two line widths covers the inner side
of a tight turn at the cut: with a part of 1.5 pixels, a curve of a 12-pixel line that turns within 3.5 pixels of the
cut lost up to 34 pixels, because the start of the next piece has no join there. The overlap does not continue over the
following curves: on a dense curved line, where each curve is shorter than two line widths, it stays about 1.5 pixels,
so the loss of 16 pixels that Chart.js ADR 0105 recorded on a 12-pixel line stays (section Pixels).

## Measurements

The lab `apps/chart_benchmark_lab` with the experiment patch of `8084b6b` (a run-time switch of the stroke rule and
stroke counters; not committed). Chart.js port, type `line`, preset `plain` (one line), one run of 4 s per cell, a
warm-up capture before the first cell of each page load or app start. Targets: a MacBook Pro (M3 Max, 120 Hz, DPR 2,
chart 1004 x 420 logical, 2008 x 840 bitmap pixels) with Chrome 157 (WebAssembly, skwasm), Safari 27.0.1 and Firefox
159.0 (JavaScript, CanvasKit) and the macOS app; a Pixel 8a with Chrome (WebAssembly; chart 922 x 788 bitmap pixels),
Firefox 159.0.1 (JavaScript; 924 x 783) and the app; an iPhone 17 Pro with Safari 27.2 (JavaScript; 1026 x 900) and the
app. The rules: one draw (`n0`, the native rule), pieces from 128 commands (`w128`, Chart.js ADR 0105 in a browser;
`n128` in an app), pieces from 2 commands (`w2`; `narea` in an app, whose guard for a cut of one piece never fired), and variants of the piece area (20,000 and 80,000
pixels) and of the threshold (32, 64). The raw tables and the logs are in `.handover/pieces/` of the maintainer's
checkout.

Each cell gives raster p90 / raster mean in ms. FPS stayed at the cap (120 for Chrome and the apps, 60 for Safari and
Firefox on the Mac) in every desktop cell below 1,000 points, and frame p90 did not move: **the gain is raster headroom**.

### Desktop browsers (Mac), 10 to 100 points

| Points | Chrome, one draw | Chrome, pieces | Safari, one draw | Safari, pieces | Firefox, one draw | Firefox, pieces |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 10 | 1.62 / 1.47 | 1.48 / 1.30 | 1.34 / 1.23 | 0.70 / 0.65 | 2.92 / 2.29 | 2.02 / 1.71 |
| 20 | 1.68 / 1.51 | 1.52 / 1.29 | 1.40 / 1.30 | 0.68 / 0.61 | 3.12 / 2.53 | 1.84 / 1.14 |
| 40 | 1.85 / 1.64 | 1.40 / 1.20 | 1.52 / 1.45 | 0.66 / 0.62 | 3.24 / 2.21 | 0.92 / 0.79 |
| 60 | 2.04 / 1.85 | 1.44 / 1.25 | 1.78 / 1.73 | 0.66 / 0.62 | 3.76 / 2.78 | 1.88 / 1.62 |
| 80 | 2.21 / 2.01 | 1.46 / 1.27 | 1.92 / 1.72 | 0.70 / 0.63 | 4.10 / 2.97 | 1.88 / 1.64 |
| 100 | 2.34 / 2.07 | 1.46 / 1.28 | 2.18 / 1.97 | 0.82 / 0.68 | 4.38 / 3.04 | 2.18 / 1.66 |

One draw grows with the line; the pieces stay flat (8.8 pieces per stroke at 10 points, 12.6 at 100). The gain is beyond
the noise from 40 points in Chrome (at 20 points by the mean only, at 10 points at the edge of the noise) and from 10
points in Safari and Firefox (p90 in Firefox; its mean at 10 points is within the noise). At 100 points pieces of 32 and 64 commands draw the same pieces and gave 1.35 to 1.40 in Chrome,
0.76 to 1.10 in Safari and 2.04 to 2.18 in Firefox.

### Desktop browsers (Mac), 1,000 and 20,000 points

A line of 1,000 points has more than 128 commands: Chart.js ADR 0105 already cut it, and this record changes nothing
there. Two cells that cut the same pieces (14.0 and 14.7 pieces per stroke):

| Target | 1,000 points | 20,000 points |
| --- | --- | --- |
| Chrome | 1.49 / 1.35 and 1.61 / 1.39 | 1.96 / 1.96 and 1.98 / 1.80 |
| Safari | 0.88 / 0.81 and 0.98 / 0.85 | 1.44 / 1.34 and 1.46 / 1.39 |
| Firefox | 1.86 / 1.16 and 2.36 / 1.82 | 1.76 / 1.46 and 1.68 / 1.48 |

Pieces of 80,000 pixels hit a cliff in all three: Chrome 6.64 and 13.13 ms (85.5 FPS at 20,000 points), Safari 5.44 and
9.62, Firefox 6.84 and 11.76 (51% of the frames over budget). Pieces of 20,000 pixels gave no gain.

### Phone browsers, 10 to 100 points

| Points | Pixel Chrome, one draw | Pixel Chrome, pieces | Pixel Firefox, one draw | Pixel Firefox, pieces | iPhone Safari, one draw | iPhone Safari, pieces |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 10 | 11.45 / 6.24 | 11.20 / 7.36 | 2.50 / 2.06 | 3.14 / 2.27 | - | - |
| 20 | 12.15 / 6.40 | 11.17 / 6.93 | 2.58 / 2.16 | 3.64 / 2.88 | - | - |
| 40 | 11.88 / 6.42 | 11.21 / 7.41 | 2.78 / 2.32 | 3.70 / 2.92 | - | - |
| 60 | 8.18 / 5.70 | 11.55 / 7.25 | 3.18 / 2.63 | 3.50 / 2.76 | - | - |
| 80 | 9.02 / 6.48 | 11.54 / 7.37 | 3.40 / 2.85 | 3.66 / 2.95 | - | - |
| 100 | 8.99 / 7.02 | 11.62 / 7.17 | 4.18 / 3.26 | 4.62 / 3.61 | 26 / 24.27 | 49 / 34.98 |

The Pixel Chrome raster p90 falls between two groups of frames; its mean is the better statistic there: pieces cost
+0.53 to +1.55 ms at 10 to 80 points. The Pixel Firefox cells of pieces at 20 and 40 points ran 1 to 2 °C warmer than
their one-draw twins; the cells at 60 and 80 points are a cool rerun. iPhone Safari at 100 points fell from 32.25 to
23.5 FPS with pieces. No iPhone Safari cell ran below 100 points.

### Phone browsers, 1,000 and 20,000 points

Pieces from 128 commands (Chart.js ADR 0105, unchanged) against one draw:

| Target | 1,000, one draw | 1,000, pieces | 20,000, one draw | 20,000, pieces |
| --- | ---: | ---: | ---: | ---: |
| Pixel Chrome | 18.02 / 15.23 | 13.90 / 6.33 | 29.99 / 20.45 (48 FPS) | 26.75 / 19.55 (49.25 FPS) |
| Pixel Firefox | 8.16 / 8.15 | 7.08 / 6.60 | 27.70 / 12.58 (35 FPS) | 8.12 / 7.78 (42.75 FPS) |
| iPhone Safari | 75 / 73.09 | 65 / 62.75 | 84 / 82.63 | 75 / 72.66 |

On iPhone Safari, pieces of 80,000 pixels from 2 commands gave 24 / 21.59 at 35 FPS at 100 points and 71 / 68.03 at
20,000 points. This record gives that gain up (Open 4).

### Native apps

| Target | Points | One draw | Pieces from 128 | Pieces from 2 |
| --- | ---: | ---: | ---: | ---: |
| macOS | 100 | 4.33 / 3.33 | (one draw) 4.20 / 3.18 | 4.37 / 3.35 |
| macOS | 1,000 | 4.42 / 3.44 | 4.36 / 3.24 | 4.51 / 3.48 |
| macOS | 20,000 | 1.20 / 1.08 | 1.18 / 1.07 | 1.27 / 1.16 |
| iPhone | 100 | 0.85 / 0.76 | (one draw) 0.89 / 0.79 | 0.87 / 0.80 |
| iPhone | 1,000 | 0.95 / 0.86 | 1.00 / 0.91 | 1.03 / 0.92 |
| iPhone | 20,000 | 0.14 / 0.12 | 0.14 / 0.12 | 0.14 / 0.12 |
| Pixel | 100 | 3.47 / 2.73 | (one draw) 3.56 / 2.78 | 3.50 / 2.70 |
| Pixel | 1,000 | 3.20 / 2.48 | 3.27 / 2.56 | 3.12 / 2.53 |
| Pixel | 20,000 | 4.30 / 3.36 | 4.25 / 3.43 | 4.16 / 3.32 |

The rules tie within the noise; pieces add draw time on the UI thread (macOS 0.11 to 0.15, 0.41 to 0.52 and 0.86 to
1.25 ms; iPhone 0.51 to 0.65 ms; Pixel 0.71 to 0.93 ms at 1,000 points). Native apps keep one draw.

### Noise

The bar of a target is the largest gap between two cells that draw the same thing (raster p90 / raster mean / FPS). Each
bar is the largest of only 3 to 6 single-run pairs: a floor on the noise, not a bound.

| Target | Bar |
| --- | --- |
| Mac Chrome | 0.12 / 0.16 ms / 1.0 FPS |
| Mac Safari | 0.34 / 0.10 ms / 0.5 FPS |
| Mac Firefox | 0.50 / 0.66 ms / 2.5 FPS |
| macOS app | 0.15 / 0.24 ms / 1.5 FPS (0.37 / 0.44 ms with a batch at a high load) |
| iPhone app | 0.04 / 0.03 ms / 0 FPS |
| Pixel app | 0.15 / 0.11 ms / 0.25 FPS below 20,000 points, 4.5 FPS at 20,000 |
| iPhone Safari | 2 / 1.54 ms / 0.75 FPS (a timer step of 1 ms) |
| Pixel Chrome | 1.85 / 0.64 ms / 1.25 FPS |
| Pixel Firefox | 0.58 / 0.31 ms / 15 FPS at 100 points, 1 FPS at 1,000 to 20,000 |

## Pixels

The pixels differ from one draw. For a dense fill the pieces are the correct form: in Chrome, against the true area of
the shape sampled from its curve, a fill of one color at 964 x 420 logical pixels and DPR 2:

| Data | One draw | Pieces |
| --- | ---: | ---: |
| 20,000 points, large noise, monotone | +56.4% | +0.2% |
| 20,000 points, large noise, bezier | +47.1% | +0.1% |
| 5,000 points, small noise, bezier | -1.4% | 0.0% |
| 2,000 points, large noise, monotone | -16.7% | 0.0% |
| 1,000 points, large noise, monotone | -7.9% | 0.0% |
| 1,000 points, small noise, bezier | -0.1% | 0.0% |
| 300 points, large noise, bezier | -0.1% | 0.0% |

A stroke keeps its shape. On the test engine, the twins of `test/port/canvas/canvas_ui_pieces_test.dart` compare pieces
with one draw: no pixel that flips between opaque and clear, no fully opaque or clear pixel of another value, and an
inked area within 1.5%. The short strokes of a desktop browser: 2, 3, 10, 40 and 100 commands; straight and curved; open
and closed (the line of a radar); on and off the pixel grid; opaque and translucent; widths 1, 2, 6 and 12; miter, round
and bevel joins: 960 pairs. With the overlap of Chart.js ADR 0105, 90 pairs failed (an inked area up to 14.8% larger, on
a thin curved line); with a curve part of 1.5 pixels, 24 pairs had up to 34 flips at widths 6 and 12. With the overlap
of this record, all pass: the worst inked area differs by 0.43%. The long lines of Chart.js ADR 0105 (200 to 20,000
points, widths 1, 2 and 6) keep their figures, the old and the new overlap alike: 0.11% on curved lines, 0.23% on straight
lines, no flips. In Chrome, Chart.js ADR 0105 found that a stroke of a long line differs by at most 0.3% (1.1% for a
translucent stroke over a fill), and a thin spiky opaque stroke of 1.01 to 1.25 bitmap pixels by up to 3.8%, with no true
value known. This is a difference of the display only (Chart.js ADR 0034).

These differences of Chart.js ADR 0105 stay on the test engine:

- A stroke much wider than its curved segments has holes as one draw, which pieces close.
- On a nearly straight curve at a cut, a line 12 pixels wide lost 16 pixels in one seeded chart.
- One of 3,000 seeded fill shapes has one pixel that flips.
- After a same-length write to the list of a `Path2D`, a later stroke in one draw sees the write when no whole path was
  built before. Before Chart.js ADR 0105, it stayed stale.

## Tests

`test/port/canvas/canvas_ui_pieces_test.dart`:

- A short path (2, 10, 100 and 127 commands) keeps one draw with the same bytes on Android, iOS, Fuchsia and the system
  of the test (Android, which Flutter also reports for an unknown system); 128 commands take pieces there.
- On macOS, Windows and Linux, a path of 2, 3 and 100 commands takes pieces, and a lone move keeps one draw.
- An arc, a quadratic curve and a rectangle keep one draw on both rules, also an arc at 2 commands.
- The 960 twins of section Pixels.
- A filled line of 100 points on macOS strokes in pieces and fills in one draw, also from a deferred path; in a line chart
  with `fill: 'origin'`, a line of 100 points takes 1 draw in pieces on macOS and none on Android and iOS, and a line of
  200 points takes 2 (the stroke and the fill) on both; each against one draw: the same bytes where no piece is drawn,
  else the rule of the twins.
- With the switch off, a short path on macOS, Windows and Linux keeps one draw: native apps keep the rule.
- The cases of Chart.js ADR 0105 (fills, long strokes, seams, joins at a cut, the cache, the limits) pass unchanged.

## Consequences

- A short line in a desktop browser makes one `ui.Path` object for each piece (about one per segment at 10 points, 12.6
  pieces at 100 points on a chart of 2008 x 840 bitmap pixels), and one layer for a translucent line. A radar line in a
  desktop browser is always cut, and its close takes the route of a divided close.
- The stroke of `ctx.stroke()` with no `Path2D`, for a line with the option `segment`, keeps one draw.
- A fill between two lines, a fill to a number, a fill with two colors, a radar fill and a fill on the y axis keep one
  draw, so that they stay slow on the web and keep the error of one draw in the table above.
- A shadow (Chart.js ADR 0106) keeps one draw.
- `canvas_ui.dart` imports `defaultTargetPlatform` from `package:flutter/foundation.dart`. It is no core layer, and no core
  layer imports it.

## Open

1. **The system is confounded with the chart size.** The Mac chart has 1.69 million bitmap pixels, the Pixel chart 0.73
   and the iPhone chart 0.92; a line of 100 points cut into 12.3 to 12.6, 7.0 and 8.3 pieces. No cell separates the
   system from the size or the GPU: a large chart on a tablet and a small chart on a desktop are untested. An app that
   sets `debugDefaultTargetPlatformOverride` in a web build takes the rule of the system that it forces.
2. **Windows and Linux are untested.** The rule assumes that their browsers act as the three browsers of the Mac. A
   Chromebook reports Linux and takes the desktop rule, and so does an Android browser in desktop-site mode (Decision
   1), on a mobile GPU, where the Pixel Chrome cells lost 0.5 to 1.6 ms of raster mean. A run on a Windows or Linux
   desktop, a Chromebook and an Android tablet is pending: the lab bench has none of them.
3. **The switch point of phone browsers is unknown.** It lies between 100 and 1,000 points; cells at 200 to 500 points
   would place it.
4. **iPhone Safari ran abnormally slow.** JavaScript ran 26 times slower than the native app on the same phone, while Mac
   Safari matches native speed; the page was no secure context, and Safari paced it at 60 Hz. Pieces of 80,000 pixels
   gained there (-2.7 ms of mean and +2.75 FPS at 100 points, -4.6 ms at 20,000 points). They stay out until that state
   is explained: the same pieces hit a cliff in the three browsers of the Mac.
5. **The gain is raster headroom.** No frame metric moved at the cap, and frames over budget in Mac Safari did not
   improve. A slower desktop, which no cell measured, would show the benefit.
6. **The lab run of the final build** (the night of 2026-11-10): the Mac browsers at 10 to 100 points with a plain, a
   curved and a translucent line and a small chart, a chart with several datasets, and one phone batch for each browser
   that shows no change, and a repeat of the Pixel Firefox cells of pieces from 2 commands at 10 to 40 points with the
   temperature gate (the losses at 20 and 40 points came from cells that ran 1 to 2 °C warmer). performance.md §70 gets
   the figures. A one-piece guard (a stroke that gives one piece takes one draw) is worth adding only if the small or the
   translucent chart shows a cost.
7. **The overlap of a curve** was measured on the test engine only. It applies to each stroke in pieces on the web, so
   the pixels of a long line (128 commands or more) in a phone browser change too, which the measurements of this
   record did not cover. The lab run checks it in the three browsers of the Mac; the night run also compares a long
   curved line (200 to 1,000 commands, widths 1, 2 and 6, opaque and translucent) between `96f6f9d` and this build in
   headless Chrome, with JavaScript and WebAssembly.
8. **The twins run at scale 1.** A desktop browser draws at DPR 2. A scratch probe of the review drew the same lines at
   `setTransform(2, 0, 0, 2, 0, 0)`: open curved lines of widths 2 to 4 at 20 to 60 commands gave 3 to 23 pixels per
   case that are clear in one draw and opaque in pieces, each inside the true stroke (0.6 to 1.4 bitmap pixels from its
   edge): holes of one draw on the test engine, which the pieces fill. No test pins scale 2.
