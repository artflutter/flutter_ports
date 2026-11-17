# Chart.js ADR 0152: The fast bar loop for update modes, several datasets and stacks

- Status: proposed
- Date: 2026-11-17
- Supersedes: of [Chart.js ADR 0069](0069-bulk-numeric-bar-updates.md), the words "In mode `none`" and the sentence
  "It also requires the live single-dataset proof of ADR 0068"; of
  [Chart.js ADR 0074](0074-incremental-data-updates.md), section "Controller specialization", the words "only for one
  primitive numeric dataset" (item 2 keeps the index ruler for several bar datasets); of
  [Chart.js ADR 0054](0054-typed-internal-model.md) §4, the sentence "The bar index memo [...] are not allowed" for
  two parts: the one search of items 2 and 3, which lives inside one `updateElements` call, and the index ruler of
  each bar controller that item 2 keeps across data-only updates.
- Related: [Chart.js ADR 0068](0068-live-bar-update-layout.md), [Chart.js ADR 0149](0149-bar-chart-small-costs.md)

## Context

The fast loop of the bar controller (Chart.js ADR 0069) runs only in the update mode `none` and only for one
dataset. A chart with several datasets runs the search of the axes and the stacks again for each bar. A stacked
chart also runs this search, and its stack tables read a tree map and scan the visible datasets for each item. The
bar campaign of 2026-11-16 measured these costs: 5 x 4,000 grouped bars update in 47.4 ms on the macOS app against
4.0 ms for one dataset of 20,000 bars. Stacking adds 28.1 ms more. The first build, a resize and a zoom step with
`animation: false` pay about 0.7 µs more for each bar than the mode `none`.

## Decision

1. **Each update mode with `animation: false`.** The fast loop runs in each mode except `reset` and `active` when the
   chart options are an exact `OptionView`, the cached chart option `animation` is the value `false` itself, and the
   controller holds no cached animations of the mode. Then `resolveAnimations` gives an empty `Animations`, and
   `updateElement` writes the properties directly, as in the mode `none`. The mode goes to the context of each bar.
2. **Several datasets.** When the proof of one dataset (Chart.js ADR 0068) fails, the fast loop takes a chart with
   several datasets if the search of `_calculateBarIndexPixels` for the axes and the stacks reads only native
   state (`fastBarSearchIsNative`). It runs that search one time, after the first ordinary bar, and uses the axis
   count and the stack index for each bar. The fast loop runs no user code, so the search of each bar gives the same
   result. A data-only update of several controllers keeps the index ruler of each bar controller when each
   controller has primitive data and `parsing` is not `false`. This is a cache of our own that lives across
   data-only updates: it widens the one-dataset ruler of Chart.js ADR 0074 to several bar datasets. The
   invalidation of Chart.js ADR 0074 applies without change: a full update clears it, and a change of a count, of
   an option or of the visibility of a dataset or of a data item gives a full update.
3. **One search in the ordinary loop.** When the fast loop declines after the first bar, for example for stacked
   datasets, the ordinary loop takes the result of one search for the rest of the bars, under a guard that proves
   that no user code runs until the last bar: shared options, a mode of item 1 or `none`, the built-in chart, value
   scale and elements, cached plain dataset options and grid, typed parsed items with no foreign key and no floating
   bar, and native dataset objects. For a stacked dataset, `applyStack` takes the sorted visible dataset indexes
   that the same guard reads one time. Each other line of the ordinary loop stays, also the stack sums, the border
   edge of a stack and `enableBorderRadius`. Both results live only inside one `updateElements` call.
4. **The stack values.** `IndexValues` keeps the values by dataset index in a dense list with a marker for an
   absent index. The list is made at the first write. A negative index, an index above 1,024, or a new index above
   `2 * count + 16` (`count` is the number of own indexes) moves all values into the tree map of before. Thus the
   list holds at most about two slots for each own index, also for a stack that few datasets with high indexes
   share. The key order of `Object.keys` stays ascending.
5. **The stack loop.** `updateStacks` reads the visible metas of the value scale and the sub-stack of the stack key
   one time for the loop, when the chart and the value scale have the built-in reads, the dataset objects are
   native and each item is a typed parsed item. The sub-stack is read at the first item, as `getOrCreateStack`
   does: a dataset with no item makes no sub-stack. A write into a `_visualValues` object of the user drops both
   reads, and the next item reads them again.
6. **No change of a result.** Each guard declines to the code of before. The pixels, the options, the contexts, the
   stack tables and the read counts on objects of the user are the upstream ones.

## Rejected

- A stack table that lives between two updates: it is a memo layer.
- The fast write loop for stacked bars: item 3 removes the search, which is the larger cost, with no second
  form of the value pixels.

## Consequences

- A later callback inside the fast loop or inside the guarded ordinary loop breaks the proof of the one search.
- A later change of `resolveAnimations` must keep the guard of item 1 in step.
- The kept rulers of item 2 depend on the data-only contract of Chart.js ADR 0074: equal counts, options, stacks and
  visibility. A new kind of data-only change must clear them.
- Four tests that count the writes of the fast loop now count the update of a resize too: the count is an internal
  detail, the geometry is the behavior.

## Open

1. No run timed the production forms. The figures of the prototypes are in `.handover/bar-perf-2026-11-16/`.

## Tests

`test/port/controllers/bar_fast_loop_test.dart`, `test/port/options/index_values_test.dart`,
`test/port/controllers/bar_bulk_update_test.dart`
