# Chart.js ADR 0103: The angle lines of the radial scale in one native call

- Status: proposed
- Date: 2026-11-06
- Related: Chart.js ADRs 0034, 0066, 0084, 0085, 0095, 0097. Measurements: performance.md.
- Row of `differences.md`: `adapt-radial-line-fan`.

## Context

A dense radar strokes one angle line for each label in each frame. Chart.js ADR 0095 keeps one state
for these lines, and Chart.js ADR 0097 strokes each one with `drawLine`. Each line is still one native
call from Dart. A union of the lines is no option: the grid color has alpha, and upstream blends each
line over the lines before it.

## Decision

Under the static plan of `_drawStaticAngleLines`, the scale offers the rest of its lines to an optional
capability, `LineFanCanvas.tryStrokeLineFan` of `lib/src/canvas/canvas_line_fan.dart`, in the manner of
`RectBarCanvas` and `ArcSectorCanvas`. The native context draws them with one
`Canvas.drawRawPoints(PointMode.lines, Float32List, paint)`. The first line stays the ordinary stroke
of the plan. The order of the lines is the order of the loop. No `Path2D` and no `ui.Path` are built.

This supersedes the statement of Chart.js ADR 0095 that each line of the plan keeps `beginPath`,
`moveTo`, `lineTo` and `stroke`, for a context that takes the fan. A recording context has no capability
and keeps these calls.

**Equal pixels.** Each line of the call is its own stroke on each engine that takes the fan:

- Impeller: `DlDispatcherBase::drawPoints` calls `Canvas::DrawLine` for each pair, with the paint of
  `drawLine`, also on the signed distance route of the macOS embedder. The one difference is
  `reuse_depth`: the lines share a depth value. Color draws compare with `kGreaterEqual`, and neither a
  line geometry nor a signed distance quad asks for overdraw prevention. Thus each line of one depth
  blends over the others.
- Skia on the CPU: `DlSkCanvasDispatcher` calls `SkCanvas::drawLine` for one form and
  `SkCanvas::drawPoints` for the other. The Skia source is not in the Flutter checkout, so the equal
  bytes rest on the test.

`flutter_tester` runs the twins on Skia on the CPU, on Impeller on Vulkan (`flutter test
--enable-impeller`) and on Impeller on Metal (`flutter_tester --enable-impeller
--impeller-backend=metal`). The signed distance route of the macOS embedder has no flag in
`flutter_tester`: the source above is its proof.

**Coordinates.** The numbers map through the transform in doubles as `moveTo` and `lineTo` map them.
A `Float32List` element and the argument of `drawLine` narrow to one float, below the bound of the
guard.

**The state.** The path of the last line stays the current path, with its commands deferred, as after
the ordinary last stroke: a later read, stroke, fill or `lineTo` sees it. The logical styles and the
transform do not change.

**The batches.** The call goes through the recording canvas: pending circles and sectors draw first, and
clips replay on a new recording. It counts as one draw of Chart.js ADR 0066: its picture has one
operation, with one bounds rectangle. With alpha 0 in the `srcOver` mode, nothing draws and a pending
run stays, as for a single line.

## Guards

The context declines before any state change for: a disposed context; an `onChanged` that the next draw
would call; an observer of a picture or an image, since a fan makes fewer pictures; a transform that is
not an invertible similarity; a dash; a gradient or a pattern; fewer than two lines. It declines after
`writeEnds` and with no state change for a coordinate that is not finite or is above 1e30 in bitmap
pixels, and for a line with no length, which takes the path in `_strokeLine`.

Every composite operation takes the fan: the twins pass for each one on the three engines of the tests.

**The engine.** `ui.ImageFilter.isShaderFilterSupported` is the only signal of the engine in `dart:ui`,
and it is true only on Impeller. Thus GPU Skia and the web decline: their Skia source is not available
here and no test runs on them. Skia on the CPU cannot be told from GPU Skia, so it declines in an app
too. The tests of `flutter_tester` set `UiCanvasContext.debugLineFanWithoutImpeller`.

## Fallback

The ordinary loop of the plan runs from the index after the first line, at its original place, for each
decline. A user subclass of the scale, a scriptable, indexed or foreign option, a non-empty dash and
display false take the ordinary code of Chart.js ADR 0095 as before, and never reach the capability.

## Differences

None in pixels, results, hooks, callbacks or state on the engines above. Row `adapt-radial-line-fan`
records the structure. A context that takes the fan makes fewer pictures: only `debugPictureCount` and an
observer could see that, and an observer declines the fan.

## The radar polygon

The polygon stays one path. `Path.lineTo` is already a leaf native call. The one batch form of `dart:ui`,
`Path.addPolygon`, takes a `List<Offset>`, so it needs an object for each point and a new deferred form of
the path: not small, and dropped. Only the private helpers of `UiPathBuilder.lineTo` get a
`vm:prefer-inline`.

## Tests

`test/port/canvas/canvas_line_fan_test.dart`: `drawRawPoints` against `drawLine` on the bare canvas for
each color, width, cap and blend mode, a clip and a transform, then the context method against the Canvas
2D sequence, the batches, the split budget, the path after the call and each guard with no state change.
`test/port/scales/scale.radialLinear_line_fan_test.dart`: a recording context with and without the
capability (the same calls and bits), bytes against a trivial user subclass and a picture observer for
radar and polar area and a typed `ChartView`, and each option that falls back.
