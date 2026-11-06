# Chart.js ADR 0104: The curve and the markers of a dense line draw

- Status: accepted
- Date: 2026-11-06
- Related: Chart.js ADRs 0034, 0084, 0085, 0089, 0097. Measurements: performance.md §66.
- Rows of `differences.md`: `adapt-compact-path-storage`, `adapt-partitioned-baseline-fill`,
  `adapt-spline-scalar-writes`, `adapt-line-curve-walk`, `adapt-bound-ascending-segment`,
  `adapt-point-circle-run`.

## Context

A curved line with a fill and markers at 20,000 points spent about 10 ms in each draw of a run on the test
engine. It built the same curve three times: the original path of the filler, which a partitioned fill
(Chart.js ADR 0089) leaves unread, the partitioned path and the path of the line. The path of the line made
one object for each curve. The control points made three records for each point. The bound search of the
filler called three closures for each point. Each marker wrote three styles, made a path with one circle and
then filled it.

## Decision

Six changes. Each one gives the engine the same values in the same order, so that the pixels stay.

1. **Curves in compact path storage.** `Path2D` keeps an unobserved `bezierCurveTo` in its private buffers:
   three slots of two numbers, and a chunk that lacks the room ends with padding. Inspection materializes the
   same `BezierCurveToCommand` objects as before, once. The version counts commands, as before.
2. **No engine path for an unread original.** Before the filler walks a line that a partitioned fill can
   replace, it calls `PartitionedFillCanvas.deferCurrentPath`. Only an exact `LineElement` with a native list
   of at least 1,024 points qualifies. `UiPathBuilder` then keeps each command of that path in growing
   buffers, and `reset` ends this state. A read makes the same `ui.Path` calls in the same order. The buffers
   keep their capacity for the next long path: about 1 MB at 20,000 cubic curves. Other paths keep the limit of
   32 commands.
3. **Control points with no records.** The loop of `updateBezierControlPoints` writes the four results directly.
   The reads and the writes keep their order. `splineCurve` stays for its other callers.
4. **The walk of a curved line.** For a `LineOptions`, `_pathSegment` does not read `stepped` for each point:
   the read has no effect, and the curve method ignores the value.
5. **A proof for the bound of an ascending segment.** `boundSegment` first scans a segment that is not a loop:
   points of the built-in classes, no skip, strictly ascending finite x, bounds equal to the first and the last
   x, and the next to last x further than the epsilon of `isBetween` from the end bound. Then its loop can give
   only one segment, from the start to the end. Any other case takes the loop. The scan reads nothing of a point
   of a user class.
6. **A run of markers.** `DatasetController.draw` offers its elements to `PointElement.drawCircleRun`. The run
   takes elements of the exact class with plain numeric options, the identical style `'circle'`, and a context
   that implements `CircleRunCanvas`. It keeps the tests of `draw` for each element. It runs the style setters
   once for each options object, at its first drawn element, and calls `tryAddRunCircle`. After the run, even
   after a throw, the path of the last drawn circle is the current path, through the ordinary calls. The first
   element or state that the run does not take ends it, and the ordinary loop draws the rest in order. The
   context declines a transform that is no similarity, a `globalAlpha` other than 1, a line dash, a shader, a
   blend mode other than `srcOver`, a color that the batch does not keep, a radius that it does not take, and
   observers of the canvas.

## Validation

- `test/port/elements/element.point_circle_run_test.dart`: 600 seeded lists of elements under ten canvas states,
  with the run and with `draw` for each element: equal bytes, styles and current path.
- `test/port/helpers/helpers.segment_ascending_test.dart`: the proof against the loop, through a trivial subclass,
  with 4,000 seeded sequences and values at the epsilon.
- `test/port/helpers/helpers.curve_scalar_test.dart`: the writes against `splineCurve`, with 3,000 seeded lists.
- `test/port/elements/element.line_curve_walk_test.dart`: `LineOptions` against a plain object, with 600 seeded
  lists.
- `test/port/canvas/path_chunks_test.dart`, `canvas_ui_native_test.dart` and
  `plugins/plugin.filler/partitioned_baseline_fill_test.dart`: storage at the chunk bounds, a read of a long
  deferred path, and no engine path after a partitioned fill.

Seven deliberate mutations of the new code each failed these tests.

## Consequences

- The markers of scatter, radar and bubble also take the run.
- A fill that the partition declines pays for two passes over its original path.
- Raster work does not change: the fill and the stroke of the curve stay.
