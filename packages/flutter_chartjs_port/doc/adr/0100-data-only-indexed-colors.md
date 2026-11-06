# Chart.js ADR 0100: Native indexed colors on the data-only path

- Status: proposed
- Date: 2026-11-06
- Related: Chart.js ADRs 0074, 0076, 0078, 0079, 0080, 0092, 0093 and 0098; `differences.md` row
  `adapt-data-update-indexed-plan`.
- Measurements: performance.md.

## Context

`Chart.updateData` keeps the layout and the ticks when only the data changed. It tested for a cached
element option entry, its proof that a resolve runs no user code. An indexed List leaves no entry:
`needContext` is true for it. So each chart with alternating colors ran the full lifecycle in each tick
of a live chart, with its layout, its scales and its tick callbacks, for nothing.

## Decision

A data element may also prove this through the native indexed plan of its resolver. This supersedes
the statement of Chart.js ADR 0074 that indexed element styles use the full lifecycle, and the statements
of Chart.js ADR 0098 that `updateData` goes to the full update for an indexed style and that the full
cells of bar, scatter, bubble, pie, doughnut and polar area take the full update. All other statements
of these two records stay.

`DatasetController.hasDataUpdateOptions` replaces the test in `updateData`. It holds when all of these
hold:

- Each option that the view of the dataset read has a raw value that is no function, in native scopes
  (`OptionView.readsNoFunctionValue`). A data-only update keeps the results of this view, and a
  scriptable option would run again in a full update.
- The data element has a cached entry, as before, or the proof below.
- A dataset element, when the meta has one, has a cached entry, as before. It has no native plan: a
  line with an indexed color keeps the full lifecycle.

`hasStaticDataUpdateOptions` does not change. Chart.js ADR 0092 reads it: an indexed chart has no entry,
and its `getStyle` needs a context.

### The proof

`Config.hasStaticIndexedElementOptions` finds the resolver that the last resolves of the data element
used, through the native chain of `prepareIndexedPointColors`: the exact Config, native root, data and
dataset, the scope list and the resolver of the prefixes `[type, '']`, and the exact options scope of
`defaults.elements[type]`, which gives the keys. `OptionResolver.hasStaticIndexedOptions` then needs:

- An indexed plan for these keys, with its template, and no write into the resolver after it. The set
  and delete traps drop the plan. A plan exists only after the resolver read each key: it refuses a
  function and an object, and the descriptors are the built-in ones (`nativeElementDescriptors`).
- Native scopes for all (`nativeOptionScope`). A custom Map keeps the full path.
- For each input, `hasStaticInputs`: a scalar, or a non-empty native list of scalars. In a color key a
  value is an exact `Color`, `null` or `undefined`, the forms that the canvas draws with no error. In
  another key no value is a `Color`. Each item is read, also one that the data does not reach. A raw
  `borderDash` holds scalars only.

Each resolve then takes the plan for any index, so no resolve runs user code or a conversion. The resolver
reads a key through all of its scopes: the dataset, the options, the overrides of the type, the theme, the
defaults and the descriptors. Thus the proof covers the scopes that `staticDataUpdateOptions` does not
walk. That walk of the options and the datasets stays. A function in `Chart.defaults.elements.arc` keeps
the full path unless a nearer scope has the same key: then neither path reads it, and it cannot matter.

The per-item resolve of each color stays as it is: a fresh options object, with its context refresh, in
the plans of Chart.js ADRs 0078, 0079, 0080 and 0093.

The walk of the items runs once for each cache generation of the config
(`Config.resolutionGeneration`). Each clear of the scopes or of the resolvers changes that generation,
so a new full update proves again. The options cannot change between two proofs under the contract below.

### The contract

The caller contract of Chart.js ADR 0074 stays. Options, defaults, overrides and the theme stay unchanged
between the last full update and `updateData`. An edit in place of an option List, or a new List in a
dataset, is outside this contract and waits for the next full update, as other option edits do. The
items of a list stay live reads in a resolve, but the proof does not run again for them.

### The lifecycle of these charts

- `getMaxOverflow` and the padding test: `updateData` runs them with the resolved options of this update.
  A style list of a radius or a border width takes part, so a changed result runs a layout, as a plain
  bubble does. Colors do not reach a layout, so a kept layout stays valid.
- Bars: the bulk remainder of Chart.js ADR 0078 runs, with `prepareIndexedBarColors`. Its guards do not
  change.
- Doughnut and pie: the scans of Chart.js ADR 0093 stop on the plan, under their own guards, and the loop
  writes each context again. Polar area: as in that record.
- Hover: the resolves of active elements stay ordinary, as in a full update.
- The legend: `afterUpdate` builds the items, also for a hidden legend, because its proof reads a cached
  entry (Chart.js ADR 0092). Colors of a palette plugin stay: the plugin writes an indexed List in
  `beforeLayout`, and its items depend on the index only, under the same data length.

### Typed and raw configs

`ChartConfigLowering.apply` does not change. A const `ChartValue.indexed` and a new one with equal items
report a data-only change. A patch stores the new List in the live scope, and the plan keeps the old List
with equal items. A List of other colors, a `ChartValue.resolver` and a new List of `extra` report a
change, so they keep `chart.update`.

`Chart.updateData` is public, so a raw config takes the path too. `nativeDataUpdateList` also accepts the
const Lists of `Color` and `Object` and a growable List of `Color?`, so that the walk reads them. Any
other List class keeps the full path.

## Fallback

Each of these keeps the full path, as the first call of `updateData` decides, with no read of user code to
qualify: a function of an element key that a resolve reads; a function of an option that the view of a
dataset read; a dataset element with no cached entry; a foreign or nested item; an empty list; a custom list;
a custom scope; a user subclass of a controller, element, scale, chart or config class. No plan after the last
full update, for example a dataset with no element, also keeps it. The next full update proves again.

The proof covers the keys of an element and of a dataset view. A function of a chart or plugin option in the
defaults or the overrides, for example `layout.padding` or a legend `filter`, and a tick callback in any scope
do not keep the full path. The contract of Chart.js ADR 0074 applies to them: a data-dependent configuration
callback needs a full update. A chart with a plain style had this rule first. A chart with an indexed style now
has it too. The options of the user keep the walk of Chart.js ADR 0074, which refuses a function.

A function of a dataset option in the defaults or the overrides now keeps the full path also for a chart
with no indexed style. Before this record its result stayed that of the last full update, against the rule
that a dataset with such a function falls back. No cell of the lab has one.

## Differences

No new difference from upstream. A chart on this path has the differences of the rows
`adapt-incremental-data-update` and `adapt-view-data-only-updates`. Its elements, options, contexts and
pixels equal those of a full update, as the twins pin. The new row names the code that is no translation.

## Lab cells

`apps/chart_benchmark_lab/test/data_only_cells_test.dart` pins that each cell of the matrix takes the
data-only path. A bubble cell also runs a layout in a tick where its largest radius changes.

## Tests

`test/port/core/data_update_test.dart` and `test/port/widgets/chart_view_data_only_test.dart` compare the
six chart types with a chart of full updates: elements, options with their key order, contexts and, through
the widget, pixels. The steps are ticks, a later full update, a hidden item, a hover, a resize, a visible
legend, a theme and an overflow that grows.

The group `a function of the chart or of a plugin in a shared scope` of `data_update_test.dart` pins the rule of
the shared scopes on a plain and an indexed chart. The group `each guard of the proof takes the full path` has a
test for each guard that a public input reaches, with the results of a full update. No public input reaches
these guards, which stay as a defense with no test: the touched-slot test and the template test of
`hasStaticIndexedOptions`, the sub-prefix test and the class tests of `hasStaticIndexedElementOptions`, and
`nativePointDatasetIndex`. The test of the memo of the proof uses an edit in place, which is outside the
contract, because the memo changes no result within the contract.
