# Chart.js ADR 0164: The kept circle run of point markers

- Status: accepted
- Date: 2026-11-18
- Supersedes: of [Chart.js ADR 0104](0104-line-curve-draw.md), in item 6 "A run of markers" the words "It runs the
  style setters once for each series of elements with one options object, at its first drawn element, and calls
  `tryAddRunCircle`", for the options of this decision.
- Related: [Chart.js ADR 0055](0055-native-draw-path.md), [Chart.js ADR 0034](0034-no-display-only-js-exactness.md),
  [Chart.js ADR 0054](0054-typed-internal-model.md). Row of `differences.md`: `adapt-kept-circle-run`.

## Context

A scatter chart has no option sharing upstream. Each point gets its own options object in each update. The circle
run of Chart.js ADR 0104 compares the options of each point with the options of the run by identity. Thus each point
of a scatter chart ran the three style setters, `tryStartCircleRun` (which releases the held batch and runs about 15
tests) and the slow path of `tryAddRunCircle` (`_batchCircle` for the fill and the stroke, then `hold`). The profiles
of the scatter night (2026-11-18, `draw_n20000`) show `tryStartCircleRun` at 9.4% and `_batchCircle` at 26% of the
draw on the macOS app, and about 60% of the draw in these functions on the Pixel. A chart with a color for each point
(`colors_n20000`) also paid `Color.toARGB32` two times for each circle.

## Decision

1. **The kept run.** In `PointElement.drawCircleRun`, a point whose options are another object keeps the run when
   the run has started and the new options have the same `radius`, `hoverRadius` and `borderWidth` (`==` on the
   plain doubles; NaN never keeps). The other tests of the run stay: the exact class, plain sizes, the style
   `circle`. Another size gives the setters and a new start, as before.
2. **The colors of a kept point.** When both paints of the kept options are `SolidChartPaint` values, the circle goes
   to the new `CircleRunCanvas.tryAddRunCircleColors(x, y, fill, stroke)` with their colors (the stroke only when
   the border width is above 0). No setter runs. `UiCanvasContext` takes the circle when its batch holds the run, the
   stroke presence matches the run, the batch keeps both colors (`batchKeepsColor`, with the last two colors that
   passed first) and the center is in bounds. `CircleBatch.addHeldColors` then adds the instances as `accepts`,
   `add` and `hold` would: in a run with a color for each instance, with the ARGB values of the last two colors of
   each kind first; in a run of one color, only for equal colors. Else it gives false with no change. The last two
   colors and their ARGB values hold for one run: `tryStartCircleRun` clears them, because a subclass of `Color`
   of a program can change its value between two draws.
3. **The owed setters.** The options of the last circle that took item 2 are owed. Their three setters run at the end
   of the run (in the `finally`), or before the next setters or start of the run, or before a `tryAddRunCircle`
   that reads the styles. Thus the canvas styles at each read, and after the run, are those of the upstream loop.
4. **The fallback.** A paint that is not solid (a gradient, a pattern, `ChartPaint.unchanged()`, an absent key, a
   foreign value), a color that the batch does not keep, a batch that does not hold, or a run of one color that would
   take a color for each instance: the owed setters run, then the setters of the point, `tryStartCircleRun` and
   `tryAddRunCircle`, as before. These calls give the result of the old form.
5. **The test switch.** `UiCanvasContext.debugKeepRunColors` (tests only) turns item 2 off. The twins compare both
   forms.

## Upstream

`core.datasetController.js:728-742` calls `element.draw` for each point, and `element.point.ts:89-100` sets
`strokeStyle`, `lineWidth` and `fillStyle` and draws the point. The kept run gives the same draws in the same order:
the batch of Chart.js ADR 0055 gets the same instances with the same colors, so the atlas calls and the pixels are
the same. The setters of a solid color write only the color and clear the shader; they cannot throw. Between two
points no other canvas call runs and no program code runs (the exact class, plain fields). The styles are written
before each read and at the end. Thus each observable state equals the state of the upstream loop.

## Rejected

- A test of the options objects by value (each key): the run needs only the sizes and the two paints.
- A cache of the styles across draws: Chart.js ADR 0054 §4 forbids a memo across updates. All state of the kept run
  lives in one call of `drawCircleRun`.
- Sharing the options of the scatter points in the update: upstream makes an object for each point, and a program can
  read and write `element.options`.

## Consequences

- `CircleRunCanvas` has one more member. A context of a program that implements it must add the member.
- A point with a size of its own (an indexed radius) still restarts the run at each change.

## Open

1. No run timed the form yet. The measurement switch is `runkeep`: bench windows `draw_n20000`, `plain_n20000`,
   `dataonly_n20000`, `colors_n20000`, `hover_n20000`; lab cells `20000:-`, `20000:agl`, `20000:x`.

## Tests

`test/port/elements/element.point_kept_run_test.dart` (300 seeded lists of points with options of their own under six
canvas states: the same native calls and styles with and without the kept colors, the same pixels and styles as the
draw of each element; the end state after a break, a gradient, an unchanged paint and a color that the batch does not
keep), `test/port/controllers/scatter_kept_run_test.dart` (scatter charts: one color, two alternating colors with a
border, a scriptable color, a gradient in the middle, a list of radii, hovered points; the same native calls, styles
and pixels), `test/port/elements/element.point_circle_run_test.dart`, `test/port/canvas/canvas_ui_circle_run_test.dart`.
