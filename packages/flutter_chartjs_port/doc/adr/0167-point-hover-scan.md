# Chart.js ADR 0167: A typed scan of the points in the hover search

- Status: accepted
- Date: 2026-11-18
- Related: [Chart.js ADR 0149](0149-bar-chart-small-costs.md), [Chart.js ADR 0054](0054-typed-internal-model.md),
  [Chart.js ADR 0146](0146-js-numeric-semantics.md), [Chart.js ADR 0034](0034-no-display-only-js-exactness.md)

## Context

A scatter chart has the interaction mode `point`. Its axis is `xy`, so `binarySearch` gives the whole range, and each
pointer move makes two searches over each point: one for the hover state and one for the tooltip. Each update with
the pointer over the chart makes two more. Item 2 of Chart.js ADR 0149 gave the bars a typed scan. A dataset of
points still takes the upstream loop: a cast, the type switch of `skip`, one closure call, `isPointInArea`, a virtual
`inRange` and three `Math.pow` calls for each point. With dart2wasm, `Math.pow` is a call into JavaScript. The
profiles of 2026-11-18 put the search at 25% to 39% of a hover step of 20,000 points.

## Decision

1. **The scan.** `scanBarInteractionItems` serves a dataset whose first element is of the class `PointElement` itself,
   as it serves a dataset of built-in bars. For each element of that class it reads `skip` typed. When the options
   are a `PointOptions` with plain numbers in `hitRadius` and `radius`, the reach is `|hitRadius + radius|`. The scan
   rejects the point when `|px - x|` or `|py - y|` is above `reach * (1 + 1e-6) + 1e-6`. A rejected point gets no
   handler call. Each other point takes the handler, which calls `inRange` again.
2. **Why the result is the same.** The handlers of `getIntersectItems` and of `getNearestCartesianItems` with
   `intersect` do nothing for a point whose `inRange` is false. A reject needs one distance above the reach by a
   relative margin of 1e-6, far above one rounding step of a `double`. So the rounded square of that distance is above
   the rounded square of the reach, the sum of the two squares is not below it, and `inRange` is false. A NaN in the
   center, the position or the reach makes each comparison false: no reject. An infinite reach rejects nothing.
3. **The guards.** A point with `$animations` under `useFinalPosition`, options of another class, a foreign or absent
   `hitRadius` or `radius`, an element of a subclass, and a dataset whose first element is of another class take the
   calls of upstream. The scan reads the options and the position of each point at that point. It reads the position
   again after each handler call and each call of an element of another class, because these can run code of a
   program.
4. **No kept value.** The scan keeps no value from one point to the next, and no result between two searches. The
   rule of Chart.js ADR 0054 §4 holds as it is.

## Rejected

- The exact upstream expression with `x * x` in place of `Math.pow`: the last bit of `Math.pow` can differ on some
  platform, and a point at the edge of the reach can then change its result.
- A test of the chart area in the scan: the scan does not know `includeInvisible`, and the reject of item 1 already
  removes nearly all points.

## Consequences

- The items, their order and the public `Interaction.evaluateInteractionItems` do not change.
- A `ChartEvent` or a `Chart` class of a program sees fewer reads of `x`, `y` and `chartArea`, as with the bars.
- A change of `inRange` of the point upstream needs a check of the reject (differences.md row
  `adapt-point-hover-scan`).

## Open

1. The figures of the production form come from the measurement switch `hoverpt` of the night of 2026-11-18.
2. `nearest` without `intersect` keeps the upstream loop. A form that skips a point whose distance is above the
   current minimum is a separate item.

## Tests

`test/port/core/point_hover_scan_test.dart`
