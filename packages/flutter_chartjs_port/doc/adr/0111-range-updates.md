# Chart.js ADR 0111: An opt-in range update for scale range changes

- Status: accepted (2026-11-10, the porting lead). The maintainer approved the ADR on 2026-11-10, and the code
  and the tests of section 9 pass (section "Implementation"). By the maintainer's rule, the record does not wait
  for the timing of the gate: the night run measures it (performance.md §69).
- Date: 2026-11-10
- Gate: the maintainer answers the questions of section "Open". Then the code and the tests of
  section 9 pass with the full pre-push list, and an old-against-new timing of the zoom cases of
  the frameless benchmark on the Pixel 8a, the iPhone 17 Pro and the Mac (2 runs per side)
  confirms the gain of section 10.
- Related: Chart.js ADRs [0024](0024-dates.md), [0034](0034-no-display-only-js-exactness.md),
  [0054](0054-typed-internal-model.md), [0074](0074-incremental-data-updates.md),
  [0090](0090-replay-single-draw.md), [0091](0091-live-mouse-move.md),
  [0098](0098-chart-view-data-only-updates.md), [0100](0100-data-only-indexed-colors.md) and
  [0108](0108-input-surface-and-exports-for-add-on-plugins.md);
  [ADR 0009](../../../../docs/adr/0009-add-on-ports.md) (add-on ports);
  [Zoom ADR 0003](../../../flutter_chartjs_plugin_zoom_port/doc/adr/0003-host-connection.md)
  items 2 and 14; [host-seams.md](../../../flutter_chartjs_plugin_zoom_port/doc/host-seams.md)
  seams H11, H14, H15 and H25; [differences.md](../differences.md) row
  `adapt-incremental-data-update`.
- Supersedes: nothing. Section 7 adds to Chart.js ADR 0074: a range update ends as a full update
  ends.

## Context

Each zoom or pan step of chartjs-plugin-zoom writes `min` and `max` into the options of the
scales through `scale.options`, then calls `chart.update(transition)` (`src/core.ts:90`, `:120`,
`:136`, `:156`, `:233` of the plugin; seams H14 and H15). The zoom port keeps these lines. The
wheel, the pinch and the drag box give the transition `'zoom'`, `resetZoom` gives `'default'`,
the pan and the other API calls give `'none'`.

Upstream `update` (`core.controller.js:475`) rebuilds the configuration in each call:

- `config.update()` (`core.config.js:197`) clears the caches of the scope lists and of the
  resolvers (`clearCache`, `:203`) and merges the scale options again (`mergeScaleConfig`, `:71`):
  a deep `mergeIf` of the last merged tree, the axis overrides, the theme and the scale defaults,
  for each scale and again for each dataset.
- New resolvers: the chart options, each plugin (`plugins.invalidate()`, then the descriptors at
  the next notify, `core.plugins.js:73`, `:175`), each dataset (`configure`,
  `core.datasetController.js:438`) and the element options. Each first read of an option walks
  its scopes again.
- `_updateScales` (`core.controller.js:542`): the boxes of the scales go and come back, the scale
  ids are written again, and `buildOrUpdateScales` (`:316`) checks the axis, the type and the
  position of each scale before `scale.init`.
- `buildOrUpdateControllers` (`:415`), `_checkEventBindings` and `_updateHiddenIndices`.

When only the range changed, these steps rebuild the same configuration. The rest of the update
depends on the range: the parse, the data limits, the ticks, the layout, the elements, the replay
of the last event and the draw.

Upstream must rebuild, because an app can change an option in place and the next `update`
applies it: `chart.options.plugins.title.text = 'x'`, a default, a dataset option. The host
cannot find such a change: a compare of the option trees and the defaults in each step costs what
it saves, and a change of a Map whose value a resolver cached does not show in the merged tree.
Chart.js ADR 0074 reached the same result for data: a cheaper lifecycle is an opt-in with a
contract.

### Evidence

CPU profiles of the zoom cases of the frameless benchmark
(`apps/chartjs_gallery/lib/bench/chart_bench.dart`, commit `cc4fe90`, 2026-11-10), profile builds
on a Pixel 8a (Impeller on Vulkan), an iPhone 17 Pro and a MacBook Pro M3 Max (Impeller on Metal).
The chart is a line of one dataset with 1,000 or 20,000 points (`parsing: false`, `{x, y}` Maps),
a visible linear or time x axis and a linear y axis, `animation: false`, `events: []`, no legend,
and the registered zoom plugin. The input steps are a wheel zoom, a mouse pan, a two-finger pinch,
`chart.zoom` and `chart.pan`, each one full update and draw. The shares count only the samples of
the timed steps (the untimed range restore of the benchmark is left out). A sample counts once, in
the first row that matches its stack. The ranges are over the three devices and the five inputs
(the time axis: the wheel and the pan).

| Part of an input step | 1,000 points, linear x | 1,000 points, time x | 20,000 points |
|---|---|---|---|
| `config.update()`: the cache clear and the scale merge | 7.8-11.1% | 7.8-11.3% | 0.9-2.8% |
| `_updateScales` without `scale.init` | 2.0-4.4% | 1.7-2.6% | 0.3-1.1% |
| `scale.init` | 0.0-0.9% | 1.1-2.1% | 0.0-0.4% |
| the plugin descriptors (`_createDescriptors`) | 1.7-3.2% | 1.5-2.3% | 0.3-1.0% |
| `buildOrUpdateControllers`, `_checkEventBindings`, `_updateHiddenIndices` | 0.1-1.8% | 0.4-0.9% | 0.1-0.5% |
| `configure` of the dataset | 0.3-1.0% | 0.1-1.0% | 0.0-0.5% |
| the chart resolver | 0.0-0.9% | 0.1-0.6% | 0.0-0.5% |
| the first reads of the new resolvers elsewhere (a resolver miss: the scope walk) | 7.0-12.2% | 5.3-7.6% | 1.2-2.9% |
| the data-only tokens of Chart.js ADR 0074 | 0.0-0.7% | 0.1-0.4% | 0.0-0.6% |

The rest of a step at 1,000 points is the draw (35-42%), the layout (11-21%: the ticks, their
labels, the fit) and the elements (9-16%). At 20,000 points it is the elements (29-38%) and the
draw (51-61%). The zoom code is 1.0-3.9% of a step at 1,000 points and 0.0-1.8% at 20,000 points;
the resolver misses of its option reads are 0.1-1.7% and 0.0-0.4% of the step.

On the Pixel, a step takes 1.17-1.24 ms at 1,000 points (linear x), 1.68-1.72 ms (time x), and
7.43-9.10 ms at 20,000 points (p50). The frame budget at 120 Hz is 8.33 ms, and a pinch gives
about two steps per frame (one for each finger move).

## Decision

### 1. The API

`Chart` gets a port-only public method beside `updateData`:

```dart
/// Updates the chart after a change of the `min` and `max` options of its
/// scales only (Chart.js ADR 0111).
///
/// The caller keeps the contract of the ADR: no option, default, override,
/// theme, dataset, scale or plugin changed in place since the last full
/// update, except `min` and `max` of a scale written or deleted through a
/// view of the options (`scale.options`, `chart.options.scales[id]`).
/// Data values, new data Lists and new labels are allowed. Each hook, the
/// parse, the layout, the dataset updates, the replay and the draw run as
/// in [update]; each scriptable option runs again. When a check fails, the
/// call is `update(mode)`.
///
/// Returns true when the range lifecycle ran, also when a hook cancelled
/// it; false when the call delegated to [update].
bool updateRanges([Object? mode = undefined]);
```

- `mode` is the mode of `update`: a mode `String`, a function of `{datasetIndex}`, or
  `undefined`. The hooks, the `transitions` and the contexts get it as in `update`. Unlike
  `updateData`, each mode and running animations are allowed: the element updates make the
  animations of `update`.
- `types.Chart` declares it, as it declares `updateData`. `lib/chartjs.dart` and the app library
  export `Chart` already. `doc/public_api.txt` lists no members, so the list does not change.
- With no caller of `updateRanges`, no code path changes: `update` keeps its code.

### 2. The contract

Between the last full update and a call, neither the app nor a plugin changes these in place:

- An option of the config: the chart options, the plugin options, the dataset options (also
  `type`, `label`, `order`, `stack`, `hidden`, `indexAxis` and the axis ids) and the scale
  options. The exception: `min` and `max` of a scale, written or deleted through a view of the
  options (`scale.options['min'] = v`, `scale.options.jsDelete('max')`,
  `chart.options.scales.x.min = v`), as the zoom plugin writes them. A write into a Map of the
  config, past the views, is a change in place.
- `Chart.defaults`, `Chart.overrides`, the descriptors and the theme.
- The dataset list: no dataset added, removed, replaced or moved.
- The scales: no scale added or removed.
- The plugins: the registered plugins, the inline plugins and an option that turns a plugin off.

Allowed, because `update` reads them by name in each step and not through a resolver: the `data`
of each dataset (new values, a new List, another length) and `labels`, `xLabels` and `yLabels`.
A data change that an array listener notified goes to `update` (check 5). The event handlers
`onClick` and `onHover` keep the rule of Chart.js ADR 0074. Scriptable options need no rule:
section 5 runs each of them again, as `update` does.

Call `update` after any other change. `ChartView` already does: a new config, a new theme and a
change of the reduced-motion preference reach the chart through `chart.update` (or
`chart.updateData`) in the same post-frame callback that patches the live scopes
(`lib/src/widgets/chart_view.dart`, `_update`), so no input event comes between the patch and the
full update.

### 3. The checks and the fallback

`updateRanges` calls `update(mode)` and returns false when one of these holds:

1. An update lifecycle runs (`update`, `updateData` or `updateRanges`): the call is a nested
   update (section 6).
2. No range state: no full update or range update completed since the last invalidation
   (section 6), or the last one did not lay out or did not update the datasets (a hook cancelled
   `beforeUpdate`, `beforeLayout` or `beforeDatasetsUpdate`, or a hook threw).
3. The chart or its config is not of the exact class (`Chart.supportsDataUpdates`,
   `Config.supportsDataUpdates`: a native root with no route of `data`, `options` or
   `plugins`).
4. The plugin descriptors are not cached (`Chart.register` and `Chart.unregister` invalidate
   them), or a plugin does not opt in to partial lifecycles: a `Plugin` with
   `supportsDataUpdates`, a Map plugin with the own key `supportsDataUpdates: true` (Chart.js ADRs
   0074 and 0108). Its promise, no change of the configuration, the data or the structure in a
   hook, is the one that kept resolvers need. The `dataUpdateGuard` of a plugin is not called: it
   states a concern of the data-only lifecycle, which skips the layout. The range update runs each
   hook and the layout (section 4). Enabled decimation thus takes the range update: its
   `beforeElementsUpdate` reads the new user bounds, as in `update` (Open 3).
5. `dataChanges` is not empty: a notified array change moves the hidden indices
   (`_updateHiddenIndices`).
6. The `data` or the `options` object of the config is another object than at the last range
   state, or the datasets differ: another count, or another object at an index.
   `DataUpdateSnapshot` (`lib/src/core/data_update.dart`) gets a second capture for this: the
   `data` and `options` objects and the dataset objects, read with `dataUpdateField` from native
   objects only, without the value Lists and the labels.
7. A dataset has a controller that is not of its exact built-in class
   (`DatasetController.supportsDataUpdates`): the `configure` and the `linkScales` of a subclass
   may read more than the built-in ones.

No check walks the options: the contract of section 2 is the caller's, as in Chart.js ADR 0074.
The checks read identities and flags: O(datasets + plugins) for each call.

### 4. The lifecycle

| Step of `update` (`_updateFull`, `core.controller.dart:1517`) | `updateRanges` |
|---|---|
| `config.update()`: `clearCache` and the scale merge | skipped. The merged scale options of the last update stay, with the `min` and `max` that the views wrote. |
| `config.createResolver(config.chartOptionScopes(), getContext())` | a new context view over the chart resolver of the last update |
| `animationsDisabled` from `options.animation` | the same, through the new view |
| `_updateScales`: `removeBox` of each scale, `ensureScalesHaveIDs`, `buildOrUpdateScales` | for each scale of `chart.scales`: `scale.init(options.scales[id], options)` through the new chart view, then `layouts.configure(chart, scale, scale.options)`. No id writes, no axis, type and position checks, no box removed or added. |
| `_checkEventBindings`, `_updateHiddenIndices` | skipped: no change under the contract, and `dataChanges` is empty |
| `plugins.invalidate()`, the new descriptors at the first notify | each cached descriptor gets a new context view over its resolver, with the descriptor defaults of `pluginOpts` (`scriptable: false`, `indexable: false`, `allKeys: true`). No new scope list, no new resolver, no `start` or `stop`. |
| `beforeUpdate` (cancelable) | the same |
| `buildOrUpdateControllers` | skipped |
| `beforeElementsUpdate`; `buildOrUpdateElements(reset)` with the parse; `getMaxOverflow`; `layout.autoPadding` | the same. `reset` is `!animationsDisabled`, as `update` gives it to a controller that is not new. |
| `_updateLayout(minPadding)`: the layout hooks, the data limits, the ticks, the fit | the same |
| the reset of the new controllers | none is new |
| `_updateDatasets(mode)`: `beforeDatasetsUpdate`, `configure` of each controller, `_updateDataset` with its hooks, `afterDatasetsUpdate` | the same, except that `configure` keeps the dataset resolver: a new context view over it, the `parsing` read, and the two caches of resolved options and animations cleared, as `configure` clears them |
| `afterUpdate`, the sort of the layers | the same |
| the replay of the last event (Chart.js ADRs 0090 and 0091) or the hover styles | the same |
| `render()` | the same |
| the data-only tokens of Chart.js ADR 0074 | the same (section 7), and the range state |

Each hook of `update` runs, in the same order, with the same arguments. The `options` argument of
a plugin hook is a new view, as in `update`; it is a view over the resolver of the last full
update, where `update` gives a view over a new resolver with the same values.

`scale.init` runs in the order of `chart.scales`; `buildOrUpdateScales` runs it in the order of
the keys of `options.scales`. Under the contract both hold the same ids, and `init` reads and
writes only its own scale.

### 5. Why the result is the result of `update(mode)`

Under the contract of section 2:

- The scale merge is a fixed point. `mergeIf` adds only absent keys, and the last merged tree
  already has each key of the axis overrides, the theme and the scale defaults. A new merge gives
  new objects with the same keys in the same order and the same values. The zoom writes `min` and
  `max` into that tree, so both paths read the same range. A delete through the view removes the
  key from the tree in both paths.
- A resolver caches the raw value of each option it read (`_createResolver`,
  `helpers.config.ts:27`). A context view evaluates the scriptable options and caches their
  results (`_attachContext`, `:118`, `_resolveWithContext`, `:233`). Upstream clears both in each
  `update`. The range update keeps the resolvers, whose raw values did not change, and makes a new
  view wherever `update` makes a new resolver. Thus each scriptable option of the chart, of a
  plugin, of a scale and of a dataset runs again with its context, once per update as in `update`:
  for example the scriptable title text of the gallery sample that shows the zoom level. The
  element options resolve with a new context for each element in both paths.
- A write of `min` or `max` through a view goes through the `set` trap of the view (`:189`) to the
  `set` trap of the resolver of that scale (`:101`), which writes its cache and the merged scope.
  The chart view and the scale view share that resolver: `buildOrUpdateScales` gives the sub-view
  of the chart view to `scale.init`, which makes the scale view over the same resolver. The new
  scale view of the range update reads the new values.
- `scale.init` runs as in `update`: the user bounds, the removal of the labels that a category
  parse added, the new date adapter of a time scale and its `formats()`, which clears the cache of
  the local zone once per update (Chart.js ADR 0024, `lib/src/core/date_adapter.dart`).
- The skipped structural steps write the same values under the contract: the scale ids, the
  positions, the boxes, the event bindings, the controllers, the fields of each meta and the order
  of the metasets. The order of `chart.boxes` stays: `update` removes the scale boxes and adds them
  again at the end, and no box came since the last update.
- The plugins and their order are the same, so `_notifyStateChanges` of `update` would find no
  change.

Why views over the kept resolvers, and not the upstream builders without the cache clear:
`chartOptionScopes` makes a new scope list in each call (`core.config.js:331`), and `configure`
resets the scope cache of its dataset (`getOptionScopes(..., true)`). Both would add an entry to
the resolver cache in each step, and only `clearCache` empties it. `pluginOpts` pushes the
defaults of an inline plugin onto the cached scope list (`core.plugins.js:180`), so that list would
grow by one scope in each step. A view over a kept resolver adds nothing to the caches. Section 9
pins it.

### 6. Re-entry and invalidation

- `updateRanges` counts as a full update for the re-entry rules of Chart.js ADRs 0074 and 0098.
  `updateData` from one of its hooks or callbacks throws the `StateError` of a full update. An
  `update` from a hook runs as from the hooks of `update`. `updateRanges` during any update is
  `update(mode)`, which acts as that nested `update` acts today: it runs inside the hooks of
  `update` and `updateRanges`, and throws inside the hooks of `updateData` up to `afterUpdate`
  (Chart.js ADR 0098). Thus the zoom port,
  which called `update`, keeps each behavior of a nested call.
- The range state has the invalidation points of the data-only state of Chart.js ADR 0074:
  `chart.data =`, `chart.options =`, `resize`, `reset`, `setDatasetVisibility`,
  `toggleDataVisibility` (`hide` and `show` run their own update), `destroy` and the start of each
  full update. `Chart.register` and `Chart.unregister` clear the descriptor cache (check 4). A
  range update that a hook cancels or that throws leaves the state invalid. The next call is then
  `update(mode)`, which arms the state again.
- As in `_updateFull`, an update arms the state at its end only when no nested update invalidated
  it in between (the generation token).

### 7. The data-only state after a range update

A range update starts by invalidating the data-only state of Chart.js ADR 0074 and ends by
recording it, as `_updateFull` does (`core.controller.dart:1602-1616`): the ready flag, the
`DataUpdateSnapshot` and the size, device pixel ratio and font tokens. It leaves the chart in the
state of a full update with the new ranges. A `ChartView` with `dataOnlyUpdates` then takes
`updateData` for the next data tick, with the ranges of the range update (seam H25).

This adds to Chart.js ADR 0074, whose sentence "A completed full update records cheap native
identity/count tokens" now also holds for a completed range update. It changes no rule of that ADR.

### 8. The zoom port

- The opt-in is a port-only key of the zoom options: `plugins.zoom.rangeOnlyUpdates: true`. The
  zoom defaults do not get the key, so `Chart.defaults.plugins.zoom` and the spec `defaults` stay
  as upstream. The facade `ZoomPluginOptions` (`lib/src/options.dart`) gets the getter
  `rangeOnlyUpdates`, the `jsTruthy` of the read. An app writes it in `ChartConfig.extra` or in a
  raw config, as the other zoom options (seam H18 until zoom phase 5).
- `lib/src/core.dart`: the five update calls (`zoom` `:160`, `zoomRect` `:199`, `zoomScale`
  `:221`, `resetZoom` `:249`, `pan` `:352`) call one private function:

  ```dart
  // DIVERGES(zoom): adapt-range-only-updates, the opt-in range update of
  // Chart.js ADR 0111.
  void _updateChart(Chart chart, State state, String transition) {
    if (state.options.rangeOnlyUpdates) {
      chart.updateRanges(transition);
    } else {
      chart.update(transition);
    }
  }
  ```

  `state.options` is the view that the last `beforeUpdate` stored: the read is a cache hit.
- The zoom functions write only `min` and `max` through `scale.options` (seam H14), and the fields
  `scale.min` and `scale.max` of a category scale, which the layout of both paths computes again.
  `resetZoom` deletes `min` and `max` through the view for a scale with no original limits: the
  `deleteProperty` trap of the view (`helpers.config.ts:141`) deletes the key in its resolver and
  in the merged scope. Both are inside the contract.
- The zoom plugin already opts in (`Plugin(supportsDataUpdates: true)`, Zoom ADR 0003 item 14),
  so check 4 holds for it. Its options are not scriptable (no descriptors, `pluginOpts` gives
  `scriptable: false`), so its callbacks (`onZoomComplete`, a `mode` function) are plain values;
  they need no rule.
- The listeners, the debounced `onZoomComplete` and the gesture state do not change: the
  `beforeUpdate` of the plugin runs in each range update, so `addListeners` makes the new
  debounced handler of each step, as upstream (seam H11).
- The zoom `differences.md` gets the row `adapt-range-only-updates`: the Dart file and symbols
  `lib/src/core.dart` `_updateChart` (`zoom`, `zoomRect`, `zoomScale`, `resetZoom`, `pan`) and
  `lib/src/options.dart` `ZoomPluginOptions.rangeOnlyUpdates`; upstream
  `src/core.ts`@v2.2.0+fb81d331:90, :120, :136, :156, :233; category `adapt`; the reason: with the
  port-only option, the five calls give the host `updateRanges(transition)` in place of
  `update(transition)`, the host takes `update` when a check fails, and the app keeps the contract
  of this ADR; without the option the lines are the upstream lines. The pinning test is the group
  `range-only updates` of `test/port/plugin_test.dart`.
- The implementing change adds a seam row to `host-seams.md` (section "Chart, scale and plugin
  APIs", state `connects`) and the option to the README of the zoom port, with the contract.

### 9. Tests

| File | Cases |
|---|---|
| `test/port/core/range_update_test.dart` (new, `testWidgets`, `@TestOn('vm')`) | **Twins**: two charts of one config; after the same writes of `min` and `max` through `scale.options`, one takes `update(mode)` and the other `updateRanges(mode)`; the observations, the hits and the draw calls of `controller_chart_harness.dart` compare after each step and at the end of the animations. Configs: line and scatter on linear axes, bar on a category axis, a time axis in UTC and in the local zone, a logarithmic axis, radar and polar area (the scale `r`), two datasets on two y axes, enabled decimation, a theme. Modes: `'none'`, `'zoom'` with the default animations, `'default'`, a function. **Scriptable options** run once per update on both sides with equal contexts: the title text, `layout.padding`, a dataset `clip`, a scale `ticks.color` and `grid.display`, `animation`. **Checks**: each check of section 3 returns false and gives the result of `update(mode)`. **Re-entry**: `updateData` from a hook throws; `update` from a hook; `updateRanges` from a hook and from the replay delegates. **Invalidation**: each point of section 6, and a cancelled `beforeUpdate`, `beforeLayout` and `beforeDatasetsUpdate`. **Caches**: 100 range updates leave the sizes of the scope cache, of the resolver cache and of the scope list of an inline plugin with defaults as they were. **Data**: a new data List and new labels in a range update equal `update`. |
| `test/port/core/data_update_test.dart` | after a range update, `updateData` takes the data-only path with the new ranges (section 7) |
| `test/port/options/observation_test.dart` | the digests do not change: the default path keeps its code |
| zoom: `test/port/plugin_test.dart`, group `range-only updates` | with `rangeOnlyUpdates: true`, each flow (wheel, drag box, pinch, mouse pan, `zoom`, `zoomRect`, `zoomScale`, `resetZoom`, `pan`) calls `updateRanges` and ends with the scale ranges, the zoom state, the points and the draw calls of the same steps without the option; a scriptable title text that reads `getZoomLevel` shows the level of each step; `onZoomComplete` and a `mode` function keep the range path; a `ChartView` with `dataOnlyUpdates` takes `updateData` for the data tick after a zoom step |
| zoom: the specs, the fixtures and the real input | the 8 specs and the 2 unit tests, the 12 fixtures (`test:fixtures:zoom`), `handlers_test.dart`, `gestures_test.dart` and `index_test.dart`, each also with the option written into `Chart.defaults.plugins.zoom` for the group: the same results |

### 10. The measured gain

The estimate is the share of the step samples in the skipped work (the rows of the evidence table
without `scale.init` and the data-only tokens, which the range update keeps), times the timing p50
of each case on each device. A resolver miss becomes a cache hit, which still costs a little: the
figures are an upper bound by that part. They are not a timing of an implementation.

| Case | Pixel 8a | iPhone 17 Pro | Mac (M3 Max) |
|---|---|---|---|
| input, 1,000 points, linear x (wheel, pan, pinch, `chart.zoom`, `chart.pan`) | 23.4-26.6% (274-315 µs) | 25.6-31.9% (132-160 µs) | 27.0-28.9% (150-167 µs) |
| input, 1,000 points, time x (wheel, pan) | 18.0-20.6% (310-346 µs) | 21.0-21.8% (146-153 µs) | 22.4-24.8% (179-196 µs) |
| input, 20,000 points (linear and time x) | 4.9-6.1% (392-497 µs) | 4.2-5.2% (153-190 µs) | 5.5-7.5% (213-284 µs) |
| also: the resolver misses of the zoom code, 1,000 / 20,000 points | 0.1-1.4% / 0.0-0.3% | 0.4-1.7% / 0.1-0.3% | 0.5-1.0% / 0.0-0.4% |
| drag box (a draw, no update) | none | none | none |

On the Pixel at 20,000 points, the wheel and pan steps go from 8.06 and 8.34 ms to about 7.7 and
7.9 ms (p50, the UI thread); with the exact host items of the same profile campaign, to about 7.1
and 7.3 ms. The gain applies to each caller of `updateRanges`, also an app with its own range
control, and to an idle update in the same proportions, since the bookkeeping does not depend on
the input.

The timing of the gate adds zoom cases with the option to the frameless benchmark and runs the old
and the new build on the three devices, 2 runs per side.

## Implementation

The answers to section "Open", taken by the porting lead in the implementing change:

1. The names stay: `Chart.updateRanges` and the zoom key `rangeOnlyUpdates`.
2. Data: the wider form. New values, a new data List and new labels go through the range update.
3. Decimation: the wider form. Check 4 does not call `dataUpdateGuard`, and enabled decimation takes the range
   update; the twins pin it.
4. Subclasses: check 7 as written. A user controller subclass takes `update`.
5. The gallery and the widget: the samples of the zoom page do not opt in, and `ChartView` gets no parameter. The
   typed options slot of zoom phase 5 (seam H18) is the place for it.
6. The docs: no page of `apps/chartjs_docs`.

Where the code departs from the text above, and why:

- Check 4 also reads an internal guard of a built-in plugin, `Plugin.rangeUpdateGuard` (a Dart field outside the
  JavaScript own keys, not a constructor parameter). The colors plugin sets it: with `forceOverride`, its
  `beforeLayout` writes new color Lists into the datasets in each update, a change of the config. A kept dataset
  resolver keeps the old List, and with a new data length the colors of the new elements would differ. Such a chart
  takes `update`. Without `forceOverride` the plugin writes once, before the first full update, and the guard
  passes.
- The boxes of the scales go and come back as in `update` (`layouts.removeBox`, then `layouts.configure` and
  `layouts.addBox`), where section 4 says that no box is removed or added. `addBox` writes the defaults of `weight`
  (0) and `position` after `configure`: without it, a scale with no `weight` option keeps `undefined`, and the sort
  of the layout differs. The order of `chart.boxes` is the order of `update`.
- The range update writes `meta.visible = isDatasetVisible(i)` for each dataset, the one field of
  `buildOrUpdateControllers` that a write outside the options changes: `chart.getDatasetMeta(i).hidden = true`,
  the form of the Chart.js docs. The other fields of the meta stay.
- The second capture of check 6 is the class `RangeUpdateSnapshot` of `lib/src/core/data_update.dart`, beside
  `DataUpdateSnapshot`, with the reads that section 3 names. A full update and a range update record it at their
  end with the tokens of Chart.js ADR 0074 (section 7): one walk of the dataset List.
- The cache test reads `Config.debugCacheSizes` (`@visibleForTesting`): the counts of the scope lists and of the
  resolvers.
- The zoom twins (`test/port/plugin_test.dart`, group `range-only updates (Chart.js ADR 0111)`) compare the pixels
  of `chart.toBase64Image()` in place of the draw calls: the zoom tests import only the public libraries of the
  host, and the recorder of the draw calls is a test helper of the host. The host twins compare the draw calls.
- The zoom suite runs with the option in the defaults through a define:
  `flutter test --dart-define=ZOOM_RANGE_ONLY_UPDATES=true` (`dart run melos run test:zoom:range-only`) writes
  `rangeOnlyUpdates: true` into `Chart.defaults.plugins.zoom` before the snapshot of the restore, for the specs, the
  fixtures and the tests of real input. The spec `defaults` then expects the key in the defaults. In that run, 372
  zoom and pan updates of the suite and 176 of the 12 fixtures took the range path, and 4 took `update`.
- A scriptable title text that reads `scale.min` or `chart.getZoomLevel()` shows the range of the last update in both
  paths: the layout fits the title before the scales. The title test of the host reads the range options, which the
  views give at once.

## Alternatives considered

- **A mode of `update`** (`update('ranges')`, or a flag in the mode). Rejected. The mode reaches
  the hooks, the `transitions` of the options and the contexts (`context.mode`), and the zoom
  already gives its transition as the mode. A second meaning in the same argument changes what the
  plugins see, and a user transition of that name would change its behavior.
- **A `ChartView` flag**, as `dataOnlyUpdates` (Chart.js ADR 0098). Rejected as the API. The zoom
  calls the update from its own listeners, not through the widget, and the widget does not see a
  write of `min` and `max`. A flag would need a chart field that the zoom reads, a coupling that
  no ported line shows, and a chart with no widget (the benchmark, a test) could not opt in. A
  later widget parameter can write the zoom option (Open 5).
- **A detection in `update`**: compare the options with the last update and skip the rebuild when
  only the ranges changed. Rejected: a compare of the option trees and the defaults in each step
  costs what it saves, and a change of a Map whose value a resolver cached does not show in the
  merged tree. Chart.js ADR 0074 rejected the same for data.
- **Keep the views too**: no new view for the chart, the plugins, the scales and the datasets.
  Rejected. A scriptable option of a kept view keeps the result of the last full update: the
  title text of the gallery sample would stay at the old zoom level. Exactness would then need a
  walk of the options for a function in each scriptable place, with a fallback for each, and the
  common zoom configs (a scriptable title, a scriptable point color) would fall back. The profiles
  put the cost in the scope walks of the new resolvers and in the rebuilds, not in the views.
- **The upstream builders without the cache clear** (`createResolver(chartOptionScopes())`,
  `configure`, `_createDescriptors`). Rejected: they grow the caches in each step (section 5).
- **A cache of the option values on the zoom side.** Rejected: it misses the defaults and the
  overrides, and it caches across updates, a memo over the resolver.
- **Only the exact items of the default path**: the typed merge of the scale scopes, the trims of
  the first reads of a resolver, `_isValidKey` without a list. They stay (the same campaign) and
  save about 5-9% of a step at 1,000 points. They make the rebuild cheaper; this ADR removes it for a
  caller that keeps the contract. Each serves the other's charts.

## Consequences

- An app that opts in and breaks the contract sees old option values until the next full update.
  The default path stays upstream; the doc of `updateRanges`, of the zoom option and the README
  of the zoom port state the contract.
- Two `adapt` rows: `adapt-range-updates` in the `differences.md` of this package (`Chart.updateRanges`,
  the range capture of `DataUpdateSnapshot`, the `configure` with a kept resolver, the descriptor
  views; the reuse of `src/core/core.controller.js`@v4.6.1:316-380, :415-455, :475-549,
  `src/core/core.datasetController.js`@v4.6.1:438-445 and `src/core/core.plugins.js`@v4.6.1:73-83,
  :175-188), and `adapt-range-only-updates` in the zoom `differences.md` (section 8). Each
  hunk carries its `DIVERGES` marker.
- `OptionView` gives its resolver to `core.controller.dart`, `core.plugins.dart` and
  `core.datasetController.dart` through an `@internal` getter; the resolver keeps its class.
- The kept resolvers hold their caches across range updates; a full update frees them as before.
  The caches do not grow (section 5).
- The plugins see a new view in each hook of an update, in both paths. A plugin that compares the
  identity of the resolver under its view would see the old one; no built-in plugin and no zoom
  hook does.
- The default path and its reference data, the fixtures and the observation digests do not change.

## Open

1. The names: `Chart.updateRanges` and the zoom key `rangeOnlyUpdates`. Other forms:
   `updateScaleRanges`; a key `updateRanges`.
2. Data in a range update. This ADR allows new data values, new data Lists and new labels, since
   the parse and the layout run as in `update`. The narrower form also requires the data snapshot
   of Chart.js ADR 0074 (the same lengths and labels): a zoom of a streaming chart would then take
   `update`.
3. Decimation. Check 4 does not call `dataUpdateGuard`, so enabled decimation takes the range
   update. The narrower form keeps the guard, and a zoom of a decimated chart takes `update`.
4. Subclasses. Check 7 sends a user controller subclass to `update`. A later opt-in could admit a
   subclass that keeps `configure` and `linkScales`.
5. The gallery and the widget. Should the samples of the zoom page opt in (the basic sample has
   the scriptable title and `onZoomComplete`, both on the range path)? Should `ChartView` get a
   parameter that writes the zoom option, or wait for the typed options slot of zoom phase 5
   (seam H18)?
6. The docs. Should `apps/chartjs_docs` show `updateRanges` for an app with its own range control?
