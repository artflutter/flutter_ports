# Chart.js ADR 0149: Four small costs of a bar chart

- Status: proposed
- Date: 2026-11-16
- Supersedes: of [Chart.js ADR 0106](0106-canvas-shadows.md), item 7 for the fused bar; of
  [Chart.js ADR 0070](0070-native-rectangular-bar-drawing.md), the sentence "Validation of the last two colors is
  reused only by identity"; of [Chart.js ADR 0054](0054-typed-internal-model.md) §4, the sentence "No memo or cache
  of our own" for the one kept result of item 3.
- Related: [Chart.js ADR 0034](0034-no-display-only-js-exactness.md)
- Figures: [performance.md](../performance.md) §76

## Context

The bar campaign of 2026-11-16 built seven prototypes behind switches. The maintainer asked for five of them as
production forms. Four are in this decision: the draw of a bar, the hover search, the easing curve and the shadow of
a bar. Each one costs time for each bar and has a form with the same result. Earlier records keep parts of this code
as they are. The fifth form is in "Not taken".

## Decision

Each form applies only where its guard holds. Each other case runs the code of before, which stays in place.

1. **The draw.** The native context has a solid paint and a shader paint for a fill, a stroke and a ring sector. A
   solid paint gets no `shader` write. The solid fill paint keeps its color when a fused bar asks for the identical
   color object of the class `ui.Color` itself, at a global alpha of 1 and with the same blend mode. Only
   `_setupPaint` writes the color and the blend mode of that paint. `BarElement.draw` tests `options is BarOptions`
   one time and reads each color from the typed field first; an empty field takes the generated getter. The native
   context maps one rectangle for a bar with no border. It keeps the identity of four colors that passed its full
   test, until its disposal: the two of the last bar and the last two others.
2. **The hover search.** `getIntersectItems`, and `getNearestCartesianItems` with `intersect`, call
   `scanBarInteractionItems`. In a dataset whose first element is of the class `BarElement` itself, the scan reads
   `skip` of such a bar by name only when the bar has extra properties, and it tests the bounds as scalars. A bar
   that the test rejects gets no handler call. A subclass, a bar with `$animations` under `useFinalPosition` and a
   bar with a NaN pixel take the calls of `evaluateInteractionItems`. The scan reads the position again after each
   call of code that can change it. It has no window on the index axis and keeps no result between two searches.
3. **The easing.** While an `Animator.update` call runs, a table of 256 entries holds the curve object, the input and
   the result of `Curve.transform`. A tick with the identical curve object and an equal input takes that result. Only
   a curve of the class `Cubic` itself and an input above 0 and below 1 take the table. The end of the last running
   call removes each entry, in a `finally` block.
4. **The shadow.** The shadow of a `fill()` of a path that is one rectangle with a solid color is `save`,
   `translate`, one `drawRect` with a kept paint, and `restore`. The kept paint has the fill color object, the shadow
   color object, the global alpha, the blur and the blend mode as its keys. `fillRect` and each other shape keep the
   shadow of the path. One `MaskFilter` object serves equal blur values in a row. Each fast path declines while a
   shadow is on: the circle batch and its runs, the fused arc sector, the line fan, the partitioned fill and the web
   pieces. The fused bar declines too, with one exception: it takes a bar with a shadow when the bar has no border
   and its rectangle has an area in 32-bit numbers. No pixel changes.
5. **The cache rule.** The only caches are the caches of upstream. No memo or cache of our own is allowed, with one
   exception: the table of item 3. It lives inside one `Animator.update` call, it tests the curve object and the
   input of its entry at each read, and it holds no entry after the call. No kept result lives from one call to the
   next. The paints, the filter object and the tested colors of items 1 and 4 are private objects of the port-only
   canvas layer, which has no upstream form.

## Rejected

- A shadow of 2 calls, with the rectangle moved in Dart: the moved rectangle can differ by one float step.

## Not taken

These wait for a decision of the maintainer and are not in the code: a window on the index axis for the hover
search (it keeps a walk of the bars between two searches), one native draw for a run of bars, the fast update loop
for several datasets and for each update mode, shared animation options, one layer for the shadows of a dataset,
and a curve class with the upstream formula.

The index of the `skipNull` search is not in the code either. Its guards did not prove the upstream result: code of
a program that runs between two bars of one update can replace an earlier slot of a parsed List, and then the
upstream search finds another item than the index. The form needs a proof that no such code runs. The `skipNull`
search stays the upstream search.

## Consequences

- A new writer of the color or the blend mode of the solid fill paint outside `_setupPaint` breaks the kept color. A
  debug assert fails then. The stroke paint has a second writer, `_tryStrokeInPieces`, and `_drawSector` writes the
  sector paints: these paints keep no color.

## Open

1. No run timed the production forms. The figures are those of the prototypes.
2. With the shadow form, the raster time of a sharp shadow on the iPhone read higher while the frame rate rose. The
   cause is not known.

## Tests

`test/port/canvas/canvas_ui_solid_paint_test.dart`, `test/port/elements/element.bar_draw_reads_test.dart`,
`test/port/core/bar_hover_scan_test.dart`, `test/port/core/animation_ease_test.dart`,
`test/port/core/animation_ease_animator_test.dart`, `test/port/canvas/canvas_ui_shadow_rect_test.dart`,
`test/port/canvas/canvas_ui_shadow_test.dart`
