# Chart.js ADR 0098: A data-only path through ChartView

- Status: accepted
- Date: 2026-11-06
- Related: Chart.js ADRs 0049, 0052, 0074, 0090, 0091; `differences.md` row
  `adapt-view-data-only-updates`.

## Context

`Chart.updateData` (Chart.js ADR 0074) keeps the layout, the ticks and the settings when only the data
changed, but a `ChartView` always calls `chart.update`. A chart that gets a new data List in each
frame thus runs its layout and all scale work in each frame.

The widget cannot find out by itself that only the data changed: an edit of `chart.options`, a write
into `Chart.defaults` and a tick callback that reads the data are outside the config. Thus the path is
an opt-in of the app, not a guess of the widget.

## Decision

`ChartView` gets the parameter `dataOnlyUpdates`, default `false`. With it, a new typed config that
differs from the last one only in its dataset data Lists calls `chart.updateData()` in place of
`chart.update(mode)`. `ChartView.raw` has no such parameter. Each other update of the widget stays as
it was, and with the default value no code path changes.

`ChartConfigLowering.apply` proves the change and reports it as `lastApplyDataOnly`. All of these hold:

| Contract of Chart.js ADR 0074 | The proof in `apply` |
| --- | --- |
| Options | The type and the option fields are `==` (`optionFieldsEqual`): the `options` scope stays. |
| Labels | `labels` is the same List. |
| Dataset identity and order | Each dataset keeps its live scope at its index: the `data` scope stays. |
| Stack, axis ids, order, `hidden` | Each `patch` changed only `data`: no key came or went, and each other cell has an `==` value or is a style
List with equal items. |
| Plugins | The plugin Lists are `==` by identity of their items. |
| Theme | The theme switch gives no mode: a new theme updates with the mode of the switch, as before. |

A style List of a dataset (`ChartValue.indexed`, `borderDash`) lowers to a new List in each lowering, so
two such Lists compare by their items, which is the compare of `ChartIndexed ==`. A List of `extra` goes
by reference, so a new one is a new value. The `extra` Maps of a dataset are compared first, for this
reason. A `ChartValue.resolver` lowers to a new bridge, and an object of `extra` to a new scope: both
report a change, so such a dataset takes `chart.update`. A patch writes the same keys as before: the
report reads the patch and does not change it.

### Guards of the widget

The widget calls `updateData` only when all of these hold, and else takes `chart.update` with its mode.

- `dataOnlyUpdates` is true.
- `updateMode` is `'none'`. `updateData` always updates in that mode, so a null `updateMode` takes
  `chart.update()`: the hooks and the context of a scriptable option keep the default mode.
- The live `options` scope holds `animation: false`, from `ChartAnimation.none` or from `extra`. An
  object of `extra` over `ChartAnimation.none` fails this guard.
- `lastApplyDataOnly` is true. A first lowering, a change from a raw config and an `==` config give
  false.
- The update does not come from the reduced-motion preference that turned on, and the theme switch
  gave no mode.

### Fallback

`updateData` keeps all its checks of Chart.js ADR 0074, and this ADR does not widen them. It calls
`update('none')` by itself for an indexed or a resolved style, a numeric scale without explicit finite
`min` and `max`, a category scale that does not qualify (below), a plugin that does not opt in, enabled
decimation, a data List of another length, a queued animation, a change of the size, the device pixel
ratio or the fonts, a visibility change with no update, and the first tick after the start, because the
first resize notification of a host ends the plan of the first update.

`chart.hide` runs its own full update, and that update makes a new plan. The next tick of new data
then takes the data-only path, and it shows what a full update shows.

### The hold of mouse moves

The widget records the frame time of each config update before it picks the path, so a chart on this
path is live for Chart.js ADR 0091. `updateData` replays a held move as `update` does. A move that no
update takes is released after the frame.

### The lifecycle of `updateData`

The path makes these cases reachable from a widget, so `updateData` now holds them. They hold for a
direct call too, and the full update does not change.

- Legend hit boxes. `adjustHitBoxes` adds the position of the legend to the hit boxes of the last `fit`.
  An update that keeps the layout runs no `fit`, so the `afterUpdate` of the legend skips it. The update
  tells the hook through `UpdateHookArgs.layoutKept`, a Dart field and not a key of the object. An update
  that runs a layout adjusts its new hit boxes once.
- Draw layers. `_updateLayout` gives the layers in the order of the boxes. `updateData` sorts them after
  `afterUpdate` when a layout ran, at the position of the sort of `update`. Kept layers stay sorted.
- Event replay and draw. The state of the lifecycle ends after `afterUpdate`. The steps after it are the
  steps of `update`, and their callbacks act as in a full update: `onHover` or a draw hook may call
  `chart.update`, and the outer update still draws. `chart.updateData` from these callbacks throws the
  `StateError` of a full update. The hooks up to `afterUpdate` still cannot re-enter, as Chart.js ADR 0074
  states. This replaces its re-entry rule for the replay and the draw.
- Category scale. It qualifies for the path only with a `bounds` option that is the string `'ticks'`, because other
  limits come from the data, and only with no label that its `parse` added, because only the `init` of a
  full update removes such a label. An update that adds a label is a full update, so the next tick is also
  a full update, and the tick after it can take the path.

### Preflight

`dataUpdateValues` reads a new data List once for each replacement. It now keeps the class of the last
typed point, so a list of one point class does no set lookup for each item. The classification of each
item does not change.

## Differences from upstream

Upstream has no widget and no data-only lifecycle. The terms of the opt-in are in the doc of the
parameter and in the row `adapt-view-data-only-updates`.

- The hooks of the layout and of the scales run only when the overflow of the new data needs a new
  layout.
- Tick and scale callbacks do not run again.
- An edit of `chart.options` or of a dataset, an edit in place of the labels and a write into
  `Chart.defaults` wait for the next full update.
- A plugin that cancels `beforeLayout` makes upstream add to the legend hit boxes in each update, because
  no `fit` ran. After a cancelled layout, `updateData` takes the full update until a layout runs, so that the
  chart adds as upstream does and no tick keeps a layout of an old size or of old labels. The group
  `a plugin that cancels beforeLayout` of `test/port/core/data_update_test.dart` pins this.
- A plugin that opts in and reads a data context, `legendItems` or `legendHitBoxes` in an update hook before
  the dataset update sees the values of the last tick, because the legend build of the layout did not run.
  From `afterUpdate` on, the values agree. Writing these values earlier costs the time that the path saves.
- After an update that throws in the dataset update, the order of the layers can differ from a full update,
  because no layout restarted it. The input throws on both paths.

## Lab cells

`apps/chart_benchmark_lab` sets the parameter behind one const, `chartJsDataOnlyUpdates`, and records it
under `engineOptions`. The cells of the matrix at the pin of this ADR, pinned by
`apps/chart_benchmark_lab/test/data_only_cells_test.dart`:

- Data-only path: line, radar (plain and full), bar, scatter, pie, doughnut and polar area (plain).
- Data-only path with a layout in most ticks: bubble (plain). Its radius comes from the data, so the
  overflow changes.
- Full update: bar, scatter, bubble, pie, doughnut and polar area (full). Their alternating colors are
  an indexed style, and Chart.js ADR 0074 sends an indexed style to the full lifecycle.

## Tests

`test/port/widgets/chart_view_data_only_test.dart` compares the elements and the pixels of the eight
chart types with the same ticks on the full path, and takes each guard and each other kind of change to
the full path. It also pins the hooks of the mouse path, the hit boxes, a click and the keys of the legend,
the pixels of the draw layers after a layout (with a layer of z above 0), an update from `onHover`, and
the category axis. `test/port/typed/lower_data_only_test.dart` pins the report of `apply`, and
`test/port/core/data_update_test.dart` the preflight of a list of points, the callbacks of the replay and
the guards of the category scale.

Measurements: performance.md §65.
