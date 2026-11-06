# Chart.js ADR 0098: A data-only path through ChartView

- Status: proposed
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
| Stack, axis ids, order, `hidden` | Each `patch` wrote only `data`: no key came or went, and each other cell has an `==` value. |
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
- `updateMode` is `'none'` or null.
- The live `options` scope holds `animation: false`, from `ChartAnimation.none` or from `extra`. An
  object of `extra` over `ChartAnimation.none` fails this guard.
- `lastApplyDataOnly` is true. A first lowering, a change from a raw config and an `==` config give
  false.
- The update does not come from the reduced-motion preference that turned on, and the theme switch
  gave no mode.

### Fallback

`updateData` keeps all its checks of Chart.js ADR 0074, and this ADR does not widen them. It calls
`update('none')` by itself for an indexed or a resolved style, a scale without explicit finite `min` and
`max`, a plugin that does not opt in, enabled decimation, a data List of another length, a queued
animation, a change of the size, the device pixel ratio or the fonts, a visibility change with no update,
and the first tick after the start, because the first resize notification of a host ends the plan of
the first update.

`chart.hide` runs its own full update, and that update makes a new plan. The next tick of new data
then takes the data-only path, and it shows what a full update shows.

### The hold of mouse moves

The widget records the frame time of each config update before it picks the path, so a chart on this
path is live for Chart.js ADR 0091. `updateData` replays a held move as `update` does. A move that no
update takes is released after the frame.

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
- The hooks get the mode `'none'`, also with a null `updateMode`, because `updateData` always updates in
  that mode. With animation off, the two modes write the same element values.

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
the full path. It also pins the hooks of the mouse path. `test/port/typed/lower_data_only_test.dart`
pins the report of `apply`, and `test/port/core/data_update_test.dart` the preflight of a list of
points.

Measurements: performance.md.
