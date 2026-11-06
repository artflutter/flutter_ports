# Chart.js ADR 0092: The items of a hidden legend wait for a read

- Status: proposed
- Date: 2026-11-06
- Related: Chart.js ADRs 0065, 0074 and 0087; `differences.md` row `adapt-hidden-legend-items`.
- Measurements: performance.md.

## Context

`ChartLegend(display: false)` leaves the legend plugin on. Upstream calls `buildLabels` three times
for each update of a top legend: twice from the layout and once from `afterUpdate`. `fit`,
`adjustHitBoxes` and `draw` return at `display`, so nothing in the chart reads these items. The
generator of a doughnut, pie or polar area chart makes one item for each arc, so these builds are the
largest cost of a live slice chart.

## Decision

`legendItems` of `Legend` becomes a getter over a pending state, as Chart.js ADR 0065 does for tick
contexts. `update` and the `afterUpdate` hook mark the items pending when every guard holds. The first
read of `legendItems` builds them and keeps the List until the next mark. A direct `buildLabels` stays
eager. A write of `legendItems` ends the wait. All readers go through the getter.

## Guards

The guards read the resolvers behind the option views: these reads give the raw value and call no
function. Thus a guard runs no user code. The reads keep the order of `buildLabels`, the generators
and `fit`.

- The exact `Legend` class, and the box is `chart.legend`.
- The built-in chart with ordinary reads (`nativePointChart` of `core/point_options.dart`), and native
  containers for the config and the data (`CategoryLabelSource`), for `data.labels` and for
  `data.datasets`. `data.labels` is not empty, it is the List of the category source (no `xLabels` in
  its place), and `data.datasets` is not empty.
- `display` is exactly `false`. A falsy value of another kind and a function keep the eager path.
- `generateLabels` is the built-in generator of the exact doughnut, pie or polar area controller of
  dataset 0 (`DatasetController.nativeLegendGenerator`). A subclass and another controller give no
  generator. A mixed chart whose generator belongs to another controller stays eager.
- `filter` and `sort` are falsy.
- `reverse` and the label options `pointStyle`, `textAlign`, `useBorderRadius` and `borderRadius` are
  plain values: not a function, an array or an object. `color` is a plain value, or the default
  function over a plain `color` of the chart options.
- The style read of each item runs no user code. One function, `_styleReadsRunNoUserCode` of
  `plugin.legend.dart`, holds this proof, so that a later change can extend it after arcs have a
  native option plan. The proof is the cached `default` entry of the element options of dataset 0
  (`DatasetController.hasCachedDefaultDataOptions`). Indexed and scriptable colors leave no entry and
  stay eager.

A polar area update in another mode than `default` has no such entry after the dataset update, and
the entry of its mode shows the same fact (`hasStaticDataUpdateOptions`): the resolve has the same
scopes and prefixes. In `afterUpdate` only, the guard then runs `getStyle(0)`, the first read of the
ordinary build. It writes the `default` entry, so the cache holds what the ordinary build leaves in
it. This read would call a user function only if a hook also cleared the config cache and changed an
option after the dataset update. Then the eager build repeats that one call.

## Fallback

A failed guard builds at once, at the upstream point, with the upstream order and count of each call.
Thus user generators, `filter`, `sort`, scriptable options, custom classes and `display: true` keep
their call counts.

The `stop` hook takes `chart.legend`, which the generators read. It runs a pending build while the
guards hold, so a box that its owner keeps gives its items. If they do not hold, for example after the
app broke `data.labels`, the box keeps its last built items, and `stop` throws nothing. A box that is
no longer `chart.legend` gives its last built items at a read.

## Difference

Upstream `legendItems` is a snapshot of the last build. A pending build shows the state at its first
read, and that read is a snapshot until the next mark. So:

- A read after an in-place change with no update (a label, the data visibility) gives the new values.
- A read in a hook after the dataset update gives the style of this update. Upstream gives the items
  of the layout build, with the style of the last update. The two differ only when an option changed
  in this update.
- A read after a config change that removes the cached entry, in the same window, resolves the options
  at that read. It can call a scriptable option there. The `afterUpdate` build then runs as upstream.

After `afterUpdate`, the items of a read equal the items of upstream when the app changed nothing
between. Hook order, callback order and count and pixels do not change: a hidden legend draws nothing.

`plugin.legend_hidden_test.dart`, group `differences.md adapt-hidden-legend-items`, pins these reads.

## Alternatives

- **Only skip the two layout builds.** This keeps the snapshot of `afterUpdate` and has a smaller
  difference, but one full build stays in each update, with nothing to read it.
- **`plugins.legend: false`.** An app can say this already. It gives no box and no `legendItems`, so it
  does not help an app that says `display: false`.
- **A typed item in place of the Map.** This lowers the cost of a build, and does not remove it. It is
  a separate change.
