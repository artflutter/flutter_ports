# Chart.js ADR 0105: Long paths in pieces on the web

- Status: accepted
- Date: 2026-11-06
- Related: Chart.js ADRs 0034, 0089, 0104. Measurements: performance.md §68.
- Row of `differences.md`: `adapt-web-long-path-pieces`.

## Context

On the web, Skia draws on WebGL. A long path with large bounds takes a slow route: an experiment points to a mask that the
CPU draws and uploads as a texture. The cause is inferred from the size at which the cost jumps, and it is not read from
the Skia source. A curved line of 5,000 points took 45 ms of raster time as one stroke, and its fill took 168 ms. The
compound fill of Chart.js ADR 0089, which helps Impeller, took 247 ms on the web. A line with the full preset of the lab
took 286 ms, for 3.5 FPS. Cut into pieces with small bounds, the same stroke took 6 ms and the same fill 1 ms.

The cost follows the bounds of a piece. In `forms-1.txt` and `forms-2.txt`, cuts every k points stay fast on bounds of about 176
x 200 and 61 x 800 bitmap pixels, and turn slow at 246 x 200 and 123 x 800, for a plot of 964 x 420 logical pixels at DPR 2. The
limit of 40,000 pixels stays below that. It is an estimate from these figures, not a measured form. See
[benchmarks/web-lines/](../benchmarks/web-lines/README.md).

## Decision

On the web only (`dart.library.js_interop`), `UiCanvasContext` draws a long path in pieces. A piece has at most 512 commands
and bounds of at most 40,000 bitmap pixels, or one segment. A path needs at least 128 commands. The switch
`debugDrawLongPathsInPieces` turns the form on for a test on the VM. Native engines keep each path as one draw.

1. **The stroke of a `Path2D`.** `uiPathPiecesOf` cuts the path into `ui.Path` pieces and keeps them in `Path2D.cache`, with
   the version rule of `uiPathOf`, for one scale and one line width. A piece that ends at a cut also takes the commands after
   the cut, for about 1.5 bitmap pixels along the line. A long straight segment is cut to that length, and a curve stays
   whole. Thus the engine makes the join at the cut from the real segments, and the start of the next piece lies inside this
   piece, so that no seam of two soft ends shows across the line. A zero-length command does not start a cut. A close of a
   path that a cut divided takes a line to the start and the first commands of the subpath. A translucent stroke draws opaque
   pieces in one layer. The stroke declines, with one draw as before, for a path below the minimum, a command other than a
   move, a line, a cubic curve or a close, a coordinate past 1e30, a `Path2D` whose list a reader got, a dash, a shader,
   another blend mode, a cap other than `butt`, a transform that is no similarity, and a translucent line of at most one
   bitmap pixel, which the engine draws as a hairline with another tone in a layer.
2. **The fill of the current path.** The filler keeps the original path deferred from 128 points on the web
   (`deferredFillMinPoints`). `fill` calls `UiPathBuilder.tryFillColumns`. It takes one subpath: a top edge that goes up in
   x, in lines and cubic curves with control points inside their segments, then lines along a horizontal base, then a close.
   Each piece has at least 8 columns, a clip without anti-aliasing on whole bitmap pixels, and geometry that passes each side
   of the clip by 4 bitmap pixels. Thus each pixel column belongs to one piece, also when the bitmap is not on the device
   pixels, and a translucent fill has no seam. The fill declines, with one draw as before, for any other shape, a coordinate
   past 1e30, a shader and another blend mode. The current path stays deferred for a later read.
3. **No compound fill on the web.** `takesPartitionedFill` is false, so that `tryPartitionedBaselineFill` returns at once,
   with no preflight.

## Pixels

The pixels differ from one draw, and for a dense fill the pieces are the correct form. In Chrome, against the true area of the
shape, sampled from its curve, a fill of one color at 964 x 420 logical pixels and DPR 2:

| Data | One draw | Pieces |
| --- | ---: | ---: |
| 20,000 points, large noise, monotone | +56.4% | +0.2% |
| 20,000 points, large noise, bezier | +47.1% | +0.1% |
| 5,000 points, small noise, bezier | -1.4% | 0.0% |
| 2,000 points, large noise, monotone | -16.7% | 0.0% |
| 1,000 points, large noise, monotone | -7.9% | 0.0% |
| 1,000 points, small noise, bezier | -0.1% | 0.0% |
| 300 points, large noise, bezier | -0.1% | 0.0% |

A stroke keeps its shape. Its edges are slightly softer in the images, with no seam and no tick. On lines of `pixels.txt`, the
inked area of a fill and a stroke differs by at most 0.3% with an opaque stroke and by 1.1% with a translucent stroke over an
opaque fill. A thin spiky opaque stroke of 1.01 to 1.25 bitmap pixels differs by up to 3.8%, with no true value known. This is a
difference of the display only (Chart.js ADR 0034).

## Review

Three reviews tried to refute these statements, also in headless Chrome on JavaScript and WebAssembly. The first version had
seams in a fill off the pixel grid, ticks across a smooth dense line, lost joins and notches at some cuts, holes in very narrow
fill pieces, stale limits in cached pieces, and accepted shapes that it drew wrongly. The form above answers each of them. The
reviewers' tests of these cases pass on the test engine and in Chrome, and `test/port/canvas/canvas_ui_pieces_test.dart` pins
them. A native build cannot take the route: the product compile removes the branch. These differences stay:

- A stroke much wider than its curved segments has holes as one draw on the test engine, which pieces close.
- On a nearly straight curve at a cut, a line 12 pixels wide lost 16 pixels in one seeded chart on the test engine.
- One of 3,000 seeded fill shapes has one pixel that flips on the test engine.
- After a same-length write to the list of a `Path2D`, a later stroke in one draw sees the write when no whole path was built
  before. Before this form, it stayed stale.

## Consequences

- A line of pieces makes one `ui.Path` object for each piece of each new path.
- The stroke of `ctx.stroke()` with no `Path2D`, for a line with the option `segment`, keeps one draw.
- A fill between two lines, a fill to a number, a fill with two colors, a radar fill and a fill on the y axis keep one draw, so
  that they stay slow on the web and keep the error of one draw in the table above.
- Radar with a grid and a fill stays slow on the web. Its limit is not the stroke of the line.
