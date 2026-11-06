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
contexts. `update` and the `afterUpdate` hook mark the items pending when every guard holds, and keep
the options of the box at that mark. The first read that can run the build runs it with those options
and keeps the List until the next mark. A direct `buildLabels` stays eager. A write of `legendItems`
ends the wait. All readers go through the getter.

The options of the mark make a read before the next mark give what upstream built at that point: the
`beforeUpdate` hook of the next update replaces the options of the box, and a read in or after that
hook reads none of the new options. Thus such a read calls no new `filter`, `sort` or `generateLabels`,
gives no new option value, and caches nothing in the new resolver.

## Guards

The guards read the resolvers behind the option views: these reads give the raw value and call no
function. Each failed test returns at once, and the reads before it are the first reads of an ordinary
build, in its order. Thus a failed guard leaves the ordinary path, with its reads of the option caches.
The order of the tests is:

- The box has built items, it is of the exact `Legend` class, and it is `chart.legend`.
- The built-in chart with ordinary reads (`nativePointChart` of `core/point_options.dart`).
- `labels` is an option object, and `generateLabels` is not the generator of `plugin.legend.dart`.
- Native containers for the config and the data (`CategoryLabelSource`), for `data.labels` and for
  `data.datasets`. `data.labels` is not empty, it is the List of the category source (no `xLabels` in
  its place), and `data.datasets` is not empty.
- Dataset 0 has a meta, found with no write (`DatasetMetaSource.existingDatasetMeta`), with the
  controller of the exact doughnut, pie or polar area class, at index 0. `generateLabels` is the
  built-in generator of that controller (`DatasetController.nativeLegendGenerator`). A subclass and
  another controller give no generator. A mixed chart whose generator belongs to another controller
  stays eager.
- `_scriptable` of the label options is the built-in descriptor.
- The label keys that this generator reads (`DatasetController.nativeLegendLabelKeys`) are plain values:
  not a function, an array or an object. `color` is a plain value, or the default function over a plain
  `color` of the chart options. The polar area generator reads no `textAlign`, `useBorderRadius` or
  `borderRadius`.
- The style read of each item runs no user code. One function, `_styleReadsRunNoUserCode` of
  `plugin.legend.dart`, holds this proof, so that a later change can extend it after arcs have a
  native option plan. The proof is the cached `default` entry of the element options of dataset 0
  (`DatasetController.hasCachedDefaultDataOptions`). Indexed and scriptable colors leave no entry and
  stay eager.
- `filter` and `sort` are falsy, and `reverse` is a plain value.
- At a mark only: `display` is exactly `false`. A falsy value of another kind and a function keep the
  eager path.

A polar area update in another mode than `default` has no `default` entry after the dataset update. In
`afterUpdate` only, the guard takes an entry of another mode as the proof, when the config cleared no
cache after that entry (`DatasetController.defaultDataOptionsNeedNoContext`, `Config.resolutionGeneration`):
the resolve has the same resolver and the same `needContext` result. Then the guard runs `getStyle(0)`,
the first call of the ordinary build. It writes the `default` entry, so the cache holds what the
ordinary build leaves in it.

The mark also does the first read of the label `color` through the view, as the generator does. The
view keeps the result, so a later build reads no options of the chart.

## A read

A read runs the same guards again, except `display`, over the options of the mark. They read no new
resolver, no chart options and no option cache that the mark did not fill. They add no dataset meta.

When they hold, the build runs no user code and throws nothing. When they fail, the read gives the last
built items, and the build still waits: a later read in a good state runs it. The `stop` hook takes
`chart.legend`, which the generators read. So it runs a pending build when the guards hold, and else
the box keeps its last built items.

## Fallback

A failed guard at a mark builds at once, at the upstream point, with the upstream order and count of
each call. Thus user generators, `filter`, `sort`, scriptable options, custom classes and
`display: true` keep their call counts. A build that throws at that point does not end the wait of the
last mark, so a next read gives the snapshot of the last update, as upstream.

## Difference

Upstream `legendItems` is a snapshot of the last build. A pending build shows the state of the data at
its first read, and that read is a snapshot until the next mark. No read and no guard runs user code or
throws. So:

- A read after an in-place change with no update (a label, a new `data.labels`, the data visibility)
  gives the new values.
- A read in a hook after the dataset update gives the style of this update. Upstream gives the items
  of the layout build, with the style of the last update. The two differ only when an option changed
  in this update.
- A read that cannot run the build gives the last built items. These can be older than the snapshot of
  upstream, from an update before the last one. This read is one of:
  - after dataset 0 became a new object (a write at index 0, a new `datasets` List, the `data` setter, a
    new `ChartView.raw` config, a new key of a typed dataset, an insert at index 0), or after it became
    another dataset of the chart (a removal of the first one, a new order);
  - after `data.labels` became no native List or an empty one, or `data.datasets` an empty one;
  - after the dataset update of this update started and before its `default` entry exists: in
    `beforeDatasetUpdate`, and until `afterUpdate` for a polar area update in another mode and for
    colors that became indexed or scriptable in this update;
  - from a box that is no longer `chart.legend`, and from a box after a `stop` with failed guards.
- A hook that adds a function value under a new key of `defaults.elements.arc` after the dataset
  update of a polar area update in another mode: the proof does not see the new key. Its `getStyle(0)`
  calls the function once more than the ordinary build, in that update.

After `afterUpdate`, the items of a read equal the items of upstream when the app changed nothing
between. Apart from the last case above, hook order, callback order and count and pixels do not change:
a hidden legend draws nothing.

`plugin.legend_hidden_test.dart`, group `differences.md adapt-hidden-legend-items`, pins these reads.
Its groups `a read with a new first dataset` and `a read after an option change` pin the cases that give
the snapshot of upstream.

## Alternatives

- **Only skip the two layout builds.** This keeps the snapshot of `afterUpdate` and has a smaller
  difference, but one full build stays in each update, with nothing to read it.
- **A read with the current options.** This has no state for the mark, but a read in `beforeUpdate` then
  caches keys in the new resolver, and an in-place write of a later hook no longer reaches the update.
  It also gives the new option values in place of the snapshot.
- **`plugins.legend: false`.** An app can say this already. It gives no box and no `legendItems`, so it
  does not help an app that says `display: false`.
- **A typed item in place of the Map.** This lowers the cost of a build, and does not remove it. It is
  a separate change.
