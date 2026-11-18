# Chart.js ADR 0160: Shared animation options of a scatter update

- Status: accepted
- Date: 2026-11-18
- Related: [Chart.js ADR 0151](0151-shared-bar-animation-options.md), [Chart.js ADR 0054](0054-typed-internal-model.md)

## Context

A scatter chart animates by default, so each data change of an app is an animated update. Upstream resolves the
animation options again for each point (core.datasetController.js:841-861 and :902), as it does for a bar. In the
profiles of 2026-11-18, `resolveAnimations` was 50% to 62% of an animated update of 20,000 points on the macOS app,
the iPhone and the Pixel. Chart.js ADR 0151 keeps one resolution for the bars of one `BarController.update` call. Its
guard asks that a bar has no element options of its own. A scatter point always has them in an animated update: the
scatter controller shares no options (`enableOptionSharing` is false, core.datasetController.js:270 and :809).

## Decision

1. **The plan.** `ScatterController.update` makes the plan of Chart.js ADR 0151 for its point loop, and clears it in a
   `finally` block. The plan, the count `optionCallEpoch`, the kept object, its life and the side effects of a kept
   point (`getContext(index, undefined, mode)` and `Animations.update`) are those of Chart.js ADR 0151.
2. **The guard.** Items 1 and 2 of the guard of Chart.js ADR 0151 hold, with `ScatterController` in place of
   `BarController`. Item 3 changes for a point: a next point takes the kept object while the count is the same, the
   element is a `PointElement` of the exact class, its `PointProperties` object has no foreign value, and its options
   are absent or a resolved options object. The resolution of the element options of a point runs between two
   points. Each call of app code in it adds one to the count, so the test of the count covers it.
3. **The line.** The line of `showLine` keeps its own ordinary resolution: the plan exists only around the point loop.
4. **The cache rule.** The kept object lives inside one `ScatterController.update` call, as item 5 of Chart.js ADR
   0151 allows.

## Rejected

- A copy of the plan class for points: one plan with one guard for each property class keeps one place to compare
  with upstream at each bump.

## Consequences

- The three kinds of code of the app of Chart.js ADR 0151 run without a count here too.
- A scriptable option of a point, the mode `active`, a logarithmic axis and a subclass of the controller take the
  ordinary resolution for each point.
- A new place that calls a function of the app between two points of the scatter loop must add one to the count.

## Tests

`test/port/core/animation_share_point_test.dart`
