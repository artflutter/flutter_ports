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

The cost follows the area of the bounds of a piece. A piece stays fast up to about 49,000 bitmap pixels, on the data of the
experiment, at any height. See [benchmarks/web-lines/](../benchmarks/web-lines/README.md).

## Decision

On the web only (`dart.library.js_interop`), `UiCanvasContext` draws a long path in pieces. A piece has at most 64 commands
and bounds of at most 40,000 bitmap pixels, or one segment. A path needs at least 128 commands. The switch
`debugDrawLongPathsInPieces` turns the form on for a test on the VM. Native engines keep each path as one draw.

1. **The stroke of a `Path2D`.** `uiPathPiecesOf` cuts the path into `ui.Path` pieces and keeps them in `Path2D.cache`, with
   the version rule of `uiPathOf`. A piece ends at a vertex, with a line of half a bitmap pixel along the next segment, so
   that the join at that vertex stays. A close of a path that a cut divided is a line to the start, with the same short line.
   A translucent stroke draws opaque pieces in one layer, so that pieces do not blend over each other. The stroke declines,
   with one draw as before, for a path below the minimum, a command other than a move, a line, a cubic curve or a close, a
   dash, a shader, another blend mode, a cap other than `butt`, a transform that is no similarity, and a translucent line of
   at most one bitmap pixel, which the engine draws as a hairline with another tone in a layer.
2. **The fill of the current path.** The filler keeps the original path deferred from 128 points on the web
   (`deferredFillMinPoints`). `fill` calls `UiPathBuilder.tryFillColumns`. It takes one subpath: a top edge that goes up in
   x, in lines and cubic curves with control points inside their segments, then lines along a horizontal base, then a close.
   Each piece has a clip without anti-aliasing on whole bitmap pixels, so that each pixel column belongs to one piece, and
   one extra vertex on each side, so that a piece has the geometry of the whole shape in its columns. Pieces do not overlap,
   so that a translucent fill has no seam. The fill declines, with one draw as before, for any other shape, a shader and
   another blend mode. The current path stays deferred for a later read.
3. **No compound fill on the web.** `takesPartitionedFill` is false, so that `tryPartitionedBaselineFill` returns at once,
   with no preflight.

## Pixels

The shape, the colors and the fill stay. The pieces take another route of Skia, so that anti-aliased edge pixels differ:
the edges of the stroke are slightly softer. In Chrome, on a line that covers 1928 x 840 bitmap pixels, the inked area
differs by at most 0.09% with an opaque stroke and by 1.1% with a translucent stroke over an opaque fill. The largest change
of one channel is 118 of 255, on few edge pixels. Most changed pixels differ by at most 32. Images of both forms show no
seam. This is a difference of the display only (Chart.js ADR 0034).

## Consequences

- At 20,000 points, a line of pieces makes about 310 `ui.Path` objects for each new path.
- The stroke of `ctx.stroke()` with no `Path2D`, for a line with the option `segment`, keeps one draw.
- A fill between two lines, a radar fill and a fill on the y axis keep one draw.
- Radar with a grid and a fill stays slow on the web. Its limit is not the stroke of the line.
