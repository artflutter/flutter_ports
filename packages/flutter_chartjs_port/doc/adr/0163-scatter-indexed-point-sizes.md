# Chart.js ADR 0163: Indexed point sizes in the scatter plan

- Status: accepted
- Date: 2026-11-18
- Supersedes: of [Chart.js ADR 0079](0079-scatter-point-options.md), the sentences "Only colors may vary by
  index" and "Scriptable/custom descriptors and indexed numeric fields retain ordinary resolution", for the
  three size fields of item 1; of [Chart.js ADR 0094](0094-scatter-bubble-point-loops.md), "One size in
  overflow", the words "where only colors vary", for the scatter loops of item 2.
- Related: [Chart.js ADR 0101](0101-context-refresh.md), [Chart.js ADR 0054](0054-typed-internal-model.md),
  [Chart.js ADR 0034](0034-no-display-only-js-exactness.md)
- Figures: the bench window `scatterchart.radius_n20000` (night of 2026-11-18)

## Context

A scatter chart with a radius for each point (`radius: [2, 3, 4, ...]`) resolves the options of each point
in full, three times for each update: in the overflow before the layout, in the loop and in the overflow of
`update_`. The prepared plan of ADR 0079 takes only indexed colors. The bench window
`scatterchart.radius_n20000` took 29.7 ms for each step on the Mac (3 to 6 ms with one radius), and
`getMaxOverflow` was 57% to 60% of the step.

## Decision

1. **The size fields of the plan.** In the scatter plan (`prepareIndexedPointPlan`), `radius`,
   `hoverRadius` and `borderWidth` can vary with the index, beside the two colors. Such a list must be a
   native SDK list (the class set of the indexed plan, so no subclass with its own `operator []`), not
   empty, and each item a number. The proof reads each item when the plan is made, inside the
   synchronous loop. Another list, an item of another type, or any other varying key gives no plan.
2. **One size for each index.** The overflow loops of the exact scatter controller take
   `size` of the options of index i from the template and the item `list[i % list.length]` of each
   varying list (`NativePointSizes`), with the formula of `nativePointSize`. Constant fields keep one
   size. The pass of ADR 0101 takes the maximum of these sizes, in the descending order of upstream.
3. **Fresh options.** The loop stores the items into a clone of the template, as it stores the colors:
   each point gets its own options with `$shared: false` and the raw item of each list.
4. **Scope.** Only the exact `ScatterController` takes size lists. The line and bubble loops keep the
   color plan.

## Rejected

- A plan kept across updates: Chart.js ADR 0054 §4.
- A size memo for each list: the lists stay live between updates; a new proof for each loop is cheap.

## Consequences

- The radius window does one full resolution of two points for each update in place of three of each
  point.
- Each case that is not proved keeps the ordinary resolution and `size`, with its calls in the same order.

## Tests

- `test/port/controllers/scatter_point_size_test.dart`
- `test/port/controllers/scatter_point_options_test.dart`
