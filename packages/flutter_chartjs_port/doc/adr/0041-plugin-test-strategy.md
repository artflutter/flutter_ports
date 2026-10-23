# Chart.js ADR 0041: Plugin test strategy

- Status: proposed
- Date: 2026-10-22
- Related: [Chart.js ADR 0012](0012-dart-file-naming.md) (the spec paths and the file names),
  [Chart.js ADR 0020](0020-registry-and-component-classes.md) §13 (a gain that only a
  microbenchmark measures),
  [Chart.js ADR 0022](0022-chart-test-harness.md) §5, §6 and §8 (method fields,
  `triggerMouseEvent`, the built-in components),
  [Chart.js ADR 0028](0028-controller-interfaces.md) Open 2 (the first readers of the plugin
  members),
  [Chart.js ADR 0029](0029-fixture-smoke-runner.md) §4, §9 item 6 and Open 2 (the hand ports,
  the stale-skip check of the runner, one registry for each spec file),
  [Chart.js ADR 0030](0030-controller-test-strategy.md) §3, §4, §6, §7, §8, §12, §13 and Open 1
  (the controller reference tests, the legend override cases, the lift, the spies, the
  stale-block check),
  [Chart.js ADR 0034](0034-no-display-only-js-exactness.md) (the protected behavior),
  [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md) (the input path of the legend and
  the tooltip, proposed in the same step),
  [Chart.js ADR 0038](0038-plugin-modules-class-values-and-interfaces.md) (plugin modules, class
  values and interfaces, proposed in the same step),
  [Chart.js ADR 0039](0039-tooltip-model-and-animation.md) §6 (`Tooltip.update` as a method
  field, proposed in the same step),
  [Chart.js ADR 0040](0040-filler-targets-and-plain-points.md) (filler targets, proposed in the
  same step),
  [Chart.js ADR 0042](0042-theming.md) (theming, proposed in the same step),
  [porting-flow.md](../porting-flow.md) §1 step 5, §1.1 and §4,
  [differences.md](../differences.md) rows `harness-register-builtins`,
  `harness-defaults-restore`, `harness-fixture-sources` and `harness-method-fields`

## Context

Phase 8 ports the 15 files of `src/plugins/`: colors, decimation, the 8 filler files, legend,
subtitle, title, tooltip and `plugins/index.js`. The work plan has four waves:

| Wave | Units |
| --- | --- |
| 1 | title, colors |
| 2 | subtitle, legend, filler, decimation |
| 3 | tooltip |
| 4 | `plugins/index.js`, the namespace `plugins`, `registerables`, the lift of the skips |

The tests of the phase have these parts:

1. The existing reference tests. `test/flutter_test_config.dart` registers `registerables`. In
   wave 4 the namespace `plugins` gets its 7 entries. Then each chart of the harness has the
   legend, because its default `display` is `true`. The JS generators of `tool/reference/`
   register no plugin. 34 test files in `test/port/` build charts with the built-in components.
2. Port-only reference tests for each plugin, through real charts, compared with the build at
   the pin in the x64 Node.js.
3. The legend override cases of the doughnut, pie and polar area controllers (Chart.js ADR 0030
   §7).
4. The harness: the colors line of `test/index.js:25-28`.
5. The registration of a plugin in its test files during waves 1-3, and the lift of 33 spec
   skips, 33 fixture skips and 4 precedence placeholders.
6. Chart.js ADR 0030 Open 1 (a permanent stale-block check) and Chart.js ADR 0029 Open 2 (one
   fixture registry for each spec file).
7. 28 new hand ports: 20 impure `plugin.*` fixture configs and 8 impure configs of the
   `blocked: plugin.*` skips. 8 tooltip fixtures send a raw DOM event.
8. Two Jasmine spies on methods: `spyOn(tooltip, 'update')` and `spyOn(chart, 'update')`.
9. `global.namespace.tests.js`: 1 case of phase 8 and 3 cases that need the UMD statics.

A design panel wrote three drafts (fidelity first, performance first, simplicity first). A judge
scored them against the priority order of [porting-flow.md](../porting-flow.md) §1.1 and ran its
own probes. This ADR takes the fidelity draft as the base, adds the best parts of the other two
drafts, and leaves out each claim that a probe refuted.

### Upstream facts

All lines are at `v4.5.1+7169e651` (`third_party/Chart.js` at
`7169e65147a47f3720957a6f156a33c838ab9f57`), and at `v0.4.0` for chartjs-test-utils.

| Source | Fact |
| --- | --- |
| `src/index.umd.ts:28` | The spec build registers `controllers, scales, elements, plugins` before the first spec. |
| `src/plugins/index.js:1-7` | The plugin order: Colors, Decimation, Filler, Legend, SubTitle, Title, Tooltip. |
| `src/core/core.plugins.js:125-131` | `allPlugins` takes the plugins in the key order of `registry.plugins.items`, the order of registration. Thus the hook order is the order of `Chart.register`. |
| `src/core/core.plugins.js:146-154`, `:156-173` | `getOpts` gives `null` for the option `false`. `createDescriptors` then leaves the plugin out. |
| `src/core/core.typedRegistry.js:41-44` | A second registration of an id does nothing. |
| `test/index.js:25-28` | A top-level `beforeAll` sets `Chart.defaults.plugins.colors.enabled = false` once. |
| `src/plugins/plugin.legend.js:601-605`, `:636-637` | `start` makes the legend and adds its box. The default of `display` is `true`. |
| `src/plugins/plugin.legend.js:623-627` | `afterUpdate` calls `chart.legend.buildLabels()` and `adjustHitBoxes()`, also when `display` is `false`. |
| `src/plugins/plugin.filler/index.js:48-65` | `beforeDraw` calls `source.line.updateControlPoints(area, source.axis)` (`:61`) for each line with a `$filler`, also with `fill: false`. |
| `src/controllers/controller.line.js:138-142` | The line controller calls `updateControlPoints` in its `draw`. The scatter controller has no `draw`. Thus without the filler, a scatter line with a tension keeps `NaN` control points. |
| `src/controllers/controller.radar.js:15-18` | The radar default `elements.line.fill: 'start'`. A radar chart uses the filler when the filler is registered. |
| `src/plugins/plugin.tooltip.js:1228-1232` | `afterInit` writes `chart.tooltip` for truthy plugin options. |
| `src/plugins/plugin.tooltip.js:1264-1273` | `afterEvent` sets `args.changed = true` (`:1270`) when the tooltip changes. |
| `src/core/core.controller.js:488-492` | `update` invalidates the plugin cache and then notifies `beforeUpdate` (`:490`). No other site notifies `beforeUpdate`. |
| `src/controllers/controller.doughnut.js:97`, `:125-127`, `src/controllers/controller.polarArea.js:41`, `:65-67` | The legend overrides: `generateLabels` reads `chart.legend.options`. `onClick` calls `toggleDataVisibility` and `legend.chart.update()`. |
| `src/helpers/helpers.core.ts:53-54`, `:152` | `isObject` is true only for `[object Object]`. Thus `each` does not walk an ES module namespace (`[object Module]`). |
| `src/helpers/helpers.dom.ts:128-129` | For a raw event, `getRelativePosition` gives `Math.round` of the position. |
| `test/specs/global.defaults.tests.js:110`, `:116`, `:186`, `:192` | `spyOn(chart, 'update').and.callThrough()`, then the legend `onClick`, then `expect(chart.update).toHaveBeenCalled()`. |
| `test/specs/plugin.tooltip.tests.js:964`, `:1027` | `spyOn(tooltip, 'update')`, with `and.callThrough()` at `:964`. |
| `test/specs/global.namespace.tests.js:3-5` | `expect(Chart instanceof Function).toBeTruthy()`. The other 3 cases read the UMD statics. |
| `test/fixtures/plugin.tooltip/point-style.js:50-68` | An inline `afterDraw` makes `{type: 'mousemove', target, clientX, clientY}` from `getBoundingClientRect()`, and calls `chart._handleEvent(event)`, `chart.tooltip.handleEvent(event)` and `chart.tooltip.draw(chart.ctx)`. The 7 other tooltip fixtures do the same. |
| chartjs-test-utils `src/fixture.js:45-48` | A fixture path with `plugin` keeps the registered plugins. Other paths get `options.plugins = false` unless the config has inline plugins. |

### The port before this ADR

- `test/flutter_test_config.dart` registers `[controllers, scales, elements, plugins]` with
  `setUpBuiltins` before `setUpDefaultsRestore()`. A comment holds the place of the colors line.
  `setUpDefaultsRestore` takes its snapshot in a `setUpAll`. Thus a registration in `main()` of a
  test file comes before the snapshot.
- `tool/reference/scale_chart_common.mjs` `registerPhase6` registers `scales` and `elements`.
  `tool/reference/controller_chart_common.mjs` `registerPhase7` registers `controllers`,
  `scales` and `elements`. `controller_reference.mjs` and `theme_precedence_reference.mjs`
  import the pinned source files and register no plugin.
- The doughnut and pie probes `legendItems` and the polar area probe `legend` put a test legend
  in `chart.legend`. The Dart tests do the same with `_TestLegend`.
  `test/port/types/index_test.dart` expects `chart.legend` to be `null`.
- `tool/src/spec_cases.dart` (tool 5) reads the `parity.md` statuses (`parseParityStatuses`) and
  maps a spec base name to its `src/` rows, also to a `<base>/` folder (`requiredBy`).
  `tool/src/dart_source.dart` finds the comments and the string literals of a Dart file.
- `test/fixtures/index.dart` has 119 hand ports and 72 skips, 33 of them `blocked: plugin.*`.
  The runner fails a `blocked: plugin.<id>` skip whose plugin is registered (Chart.js ADR 0029
  §9 item 6).
- `types.Chart` declares `void update([Object? mode])`. A Dart field cannot implement a method.
- `Chart.handleEvent` takes a `types.ChartEvent`. `getRelativePosition` reads a `ChartEvent` as
  it is.
- Chart.js ADR 0038 §1 names the plugin values `colors`, `decimation`, `filler`, `legend`,
  `subTitle`, `title` and `tooltip`.

### Probes

The probes ran the build at the pin in the x64 Node.js v24.12.0 under Rosetta, and Flutter
3.47.7 on a shared Mac (load average 4 to 15). The Evidence section gives the details.

- **The 16 generators on the dist, in four modes.** Mode `none` (as today) gives the committed
  data in all 16 files. Option A (the plugins registered, colors off) changes 644 of 703 cases in
  16 of 16 files, and 638 of 666 chart areas. A legend off (`legend.display: false`) still
  changes 15 cases in 2 files, and a legend and a tooltip off still change 14 cases. A second run
  of option A is byte-identical.
- **The ticks.** Option A changes 5 of 605 tick lists of the base data: 1 in
  `scale_linear`, 2 in `scale_logarithmic`, 2 in `scale_radialLinear`.
- **A stand-in legend in the Dart suite.** A 32 px legend box fails 753 tests in 20 files.
- **A `false` option against an absent plugin.** Equal observations and draw calls.
- **The plugin sets of the waves.** Equal spec results and equal fixture smoke results.
- **The registry import.** 0.38 s to 1.07 s for each `-j 1` run, below the trigger of 4 s.
- **The `beforeUpdate` spy.** The same call count as the Jasmine spy.

## Decision

### 1. The reference generators register the plugins (option A)

1. One function in `tool/reference/scale_chart_common.mjs` registers what
   `test/flutter_test_config.dart` registers. It ports `src/index.umd.ts:28` and then
   `test/index.js:25-28`:

   ```js
   /**
    * Registers the built-in components as test/flutter_test_config.dart does
    * (harness-register-builtins): src/index.umd.ts:28, then the line of
    * test/index.js:25-28. Then [extra].
    */
   export function registerBuiltins(C, ...extra) {
     C.Chart.register(C.controllers, C.scales, C.elements, C.plugins);
     // Disable colors plugin for tests (test/index.js:25-28).
     C.Chart.defaults.plugins.colors.enabled = false;
     if (extra.length) C.Chart.register(...extra);
   }
   ```

   `controller_chart_common.mjs` re-exports it. The dist `C.plugins` is a plain object, so
   `register` walks it.
2. The function comes in wave 1, for the plugin generators of section 3. In wave 4 it takes the
   place of `registerPhase6` and `registerPhase7` in the 16 generators on the dist, and the two
   old functions go. This applies the rule of Chart.js ADR 0030 §3 item 5: the generators
   register what the Dart tests register.
3. `controller_reference.mjs` and `theme_precedence_reference.mjs` import
   `src/plugins/index.js` and register its seven exports by name, in the order of `:1-7`. Then
   they set `defaults.plugins.colors.enabled = false`. They do not pass the module namespace to
   `Chart.register`: `each` does not walk it (`helpers.core.ts:53-54`, `:152`), so the call
   registers nothing.
4. The doughnut, pie and polar area generators keep their test-legend probes until wave 4
   (section 5).
5. In wave 4 one change runs all 18 generators and commits their data. A second run of each of
   the 18 generators gives byte-identical data. The data of the 16 dist generators grows by
   about 2.2 %.
6. `test/port/types/index_test.dart` takes new expected values from a probe at the pin with the
   plugins, and sets `chart.legend = null` before the check of `legend`.
7. An expected value of another chart test that changes in wave 4 comes from a probe at the pin
   (the probe harness or a generator). It never comes from a hand edit.
8. A future generator that registers no plugin is allowed. Its Dart test file then calls
   `Chart.unregister([plugins])` first in `main()`, before the snapshot of the restore. A Dart
   probe showed that this removes the plugins and their defaults for all tests of the file.

### 2. The checks of the data change

The change of wave 4 also does these checks:

1. The summed test durations of the JSON reporter for the reference test files of
   `test/port/scales/` and `test/port/controllers/` (17 files, 1137 tests, 21.54 s at the base),
   before and after the change. The estimate is +5 % to +16 %. A result above +25 % goes into
   `performance.md` with the slowest plugin path. That path is then a hot spot for step 7 of the
   phase.
2. The size of `test/port/scales/scale_time_reference.dart`. It is 2,406,449 bytes after
   option A. The limit is 2,500,000 bytes (Chart.js ADR 0030 §3 item 6). A new case that passes
   the limit splits the data into two files.

### 3. The plugin reference tests

1. One generator, one data file (two for the tooltip) and one Dart test file for each upstream
   plugin file that has behavior to pin:

   | Upstream | Generator | Data | Dart test |
   | --- | --- | --- | --- |
   | `plugin.colors.ts` | `tool/reference/plugin_colors_reference.mjs` | `test/port/plugins/plugin_colors_reference.dart` | `test/port/plugins/plugin.colors_test.dart` |
   | `plugin.decimation.js` | `plugin_decimation_reference.mjs` | `plugin_decimation_reference.dart` | `plugin.decimation_test.dart` |
   | `plugin.filler/index.js` | `plugin_filler_reference.mjs` | `test/port/plugins/plugin.filler/plugin_filler_reference.dart` | `test/port/plugins/plugin.filler/index_test.dart` |
   | `plugin.filler/filler.target.js` | `filler_target_reference.mjs` (on the source files) | `test/port/plugins/plugin.filler/filler_target_reference.dart` | `test/port/plugins/plugin.filler/filler.target_test.dart` |
   | `plugin.legend.js` | `plugin_legend_reference.mjs` | `plugin_legend_reference.dart` | `plugin.legend_test.dart` |
   | `plugin.subtitle.js` | `plugin_subtitle_reference.mjs` | `plugin_subtitle_reference.dart` | `plugin.subtitle_test.dart` |
   | `plugin.title.js` | `plugin_title_reference.mjs` | `plugin_title_reference.dart` | `plugin.title_test.dart` |
   | `plugin.tooltip.js` | `plugin_tooltip_reference.mjs` | `plugin_tooltip_reference.dart` and `plugin_tooltip_more_reference.dart` (one file with all the cases is above 2.5 MB, section 4 item 4) | `plugin.tooltip_test.dart` |

   A Dart test file at a mapped path also holds the port-only groups that Chart.js ADRs 0038,
   0039 and 0040 give for the same file.
2. Shared code: `tool/reference/plugin_chart_common.mjs` imports `controller_chart_common.mjs`.
   The Dart library `test/port/plugins/plugin_chart_harness.dart` (not a test file) imports
   `controller_chart_harness.dart`. The shared code gives the key `boxes`. Each plugin generator
   and its Dart test file give the observer of their own key `plugins.<id>`. Thus a unit of a
   later wave does not change the shared code, and the shared code needs no plugin class.
3. The shared harness gets two options, on both sides. `observeExtra` adds keys to each
   observation. `hits: false` leaves out the hit matrix. The plugins do not change the hit items
   of `getElementsAtEventForMode`, and the tooltip model covers the tooltip path. The hit matrix
   is 24.5 % to 34.4 % of the bytes of a controller data file. The check still reads exactly the
   keys of the expected Map.
4. The observation of a plugin case is the controller observation without `hits`, and these
   keys:

   | Key | Content |
   | --- | --- |
   | `boxes` | Each box of `chart.boxes` in order: the kind (`legend` for `chart.legend`, `title` for `chart.titleBlock`, `subtitle` for another `Title` box, or the scale id; the subtitle map is private on both sides), `position`, `weight`, `fullSize`, `left`, `top`, `right`, `bottom`, `width`, `height`. The order is protected. |
   | `plugins.legend` | `legendItems` (each key of an item), `legendHitBoxes`, `lineWidths`, `columnSizes`, the log of the `onHover`, `onLeave` and `onClick` callbacks of the case (the event type and the item text), the plain `options.labels` without functions. `_hoveredItem` is private in the port (Chart.js ADR 0012), and the callbacks show its effect. |
   | `plugins.title`, `plugins.subtitle` | The text lines and the plain options. The box is in `boxes`. `_padding` is private in the port (Chart.js ADR 0038 §7): the box size and the draw calls show its effect. |
   | `plugins.tooltip` | `opacity`, `x`, `y`, `width`, `height`, `caretX`, `caretY`, `xAlign`, `yAlign`, `title`, `beforeBody`, `body` (`before`, `lines`, `after`), `afterBody`, `footer`, `labelColors`, `labelPointStyles`, `labelTextColors`, `dataPoints` (`datasetIndex`, `dataIndex`, `label`, `formattedValue`, plain `parsed`, `raw`), and the active `[datasetIndex, index]` list. |
   | `plugins.filler` | `meta.$filler` of each dataset: `null`, or `visible`, `index`, the resolved `fill`, `axis` and the scale id. |
   | `plugins.decimation` | For each dataset: `_decimated`, whether `_data` is an own key, the plain `data`. The port has no accessor (Chart.js ADR 0038 §8). Upstream, `data` is an accessor exactly when `_data` is an own key, so the kind of the property adds no fact. |
   | `plugins.colors` | For each dataset of `chart.config.data.datasets`: `backgroundColor` and `borderColor` after `beforeLayout`. |

5. The draw calls of a case have the legend, title, tooltip and fill calls in their upstream
   order.
6. New steps, on both sides:

   | Step | JavaScript | Dart |
   | --- | --- | --- |
   | `['click', x, y]` | `chart._eventHandler({type: 'click', chart, native: {type: 'click'}, x, y})` | `await triggerMouseEvent(chart, 'click', point)` |
   | `['clickLegend', i]`, `['hoverLegend', i]` | The step `click` or `hover` at the rounded center of `chart.legend.legendHitBoxes[i]` | The generator writes the step `click` or `hover` with the point. The Dart test runs the same point. The observation `plugins.legend` compares the hit boxes. |
   | `['setTooltip', [[d, i], ...], x, y]` | `chart.tooltip.setActiveElements(items, {x, y})`, then `chart.update()` | The same |
   | `['setOption', path, value]` | The write `chart.options.<path> = value` (the `set` trap of the resolver), then `chart.update()` | `operator []=` of the resolver, then `chart.update()` |

   The Dart steps send the events through `triggerMouseEvent`, as the steps `hover` and
   `mouseout` do (Chart.js ADR 0022 §6). Chart.js ADR 0037 §15 keeps that path.
7. The case sets cover the option branches of the pinned source:

   | Plugin | Unit cases | Branches |
   | --- | ---: | --- |
   | colors | 10 | `enabled: true` on bar, line, doughnut, pie, polar area, radar and bubble, more datasets than the 7 colors, `forceOverride`, dataset colors given, chart colors given (no change), a string `data` (the `TypeError` of `data.map`) |
   | decimation | 10 | `lttb` with `samples`, `min-max`, `threshold` above the count, a category index axis, `parsing: true`, `indexAxis: 'y'`, a user `min` and `max`, the step `setOption` to `enabled: false`, a write of `dataset.data` after the decimation |
   | filler | 30 | `fill` `false`, `true`, `'origin'`, `'start'`, `'end'`, a number, `'+1'`, `'-1'`, `'stack'`, `{value}`, `{target, above, below}`, `'shape'`, a radar with `r` `min` and `max`, a radar with `'origin'`, stepped lines, `spanGaps`, `segment`, a hidden target with `propagate` `true` and `false`, each `drawTime`, `clip` (a scatter line with a tension and `fill: false` is the case `showLine true` of `controller_scatter_reference.mjs`) |
   | legend | 24 | each `position`, each `align`, `rtl`, `reverse`, `fullSize: false`, `maxWidth` and `maxHeight`, `usePointStyle`, `pointStyleWidth`, `boxWidth`, `boxHeight`, `padding`, `filter`, `sort`, `textAlign`, the title with `position`, rows that wrap, columns that overflow, a hidden dataset, `onHover` and `onLeave` with `hoverLegend`, `clickLegend`, `display: false` |
   | title | 10 | `display`, each `position`, `align`, `fullSize: false`, `padding` as a number and as an object, a text array, `font` and `color` |
   | subtitle | 6 | alone, with a title (the box order), `position: 'left'`, `display: false`, `padding`, with a legend |
   | tooltip | 26 | the modes `index`, `nearest`, `point`, `dataset`, `x` and `y` with `intersect`, the positioners `average`, `nearest` and a custom one, the callbacks of each text part, `xAlign` and `yAlign`, a caret near each edge, `rtl` and `textDirection`, `displayColors: false`, `usePointStyle`, `boxPadding`, `padding`, `filter`, `itemSort`, `footer`, `external`, `enabled: false`, the steps `hover`, `mouseout`, `setTooltip`, and `click` with `events: ['click']` |

8. `filler_target_reference.mjs` runs the pinned source files with the method of
   `scale_autoskip_reference.mjs`. It pins the target dispatch of Chart.js ADR 0040.
9. Each plugin test file also runs its cases with the light preset (theming.md §8 test 3), as
   Chart.js ADR 0030 §8 does. Chart.js ADR 0042 gives the plugin keys and the palette of that
   run.
10. Each case is one `testWidgets` case (Chart.js ADR 0030 §3 item 7).

### 4. Unit cases and full cases

The plugin generators call `registerBuiltins`, so their data stays valid after wave 4. In
waves 1-3 the Dart file registers only the plugins of section 7. A plugin that the Dart file does
not register changes the chart: the default title case has its chart area top at 66.4 with all
plugins and at 34.4 with the title only, and 5 boxes against 3.

1. **Unit cases.** The config of a unit case sets `options.plugins.<id>` to `false` for each
   plugin that its Dart file does not register in its wave (section 7). `getOpts` then gives
   `null`, and `createDescriptors` leaves the plugin out (`core.plugins.js:146-163`). Only
   `install` and `uninstall` run for each registered plugin, and no built-in plugin has them. A
   probe gave equal chart areas, boxes and draw calls (351 to 1483 calls) with all plugins and
   with the plugins of wave 1 only. The Dart test runs the unit cases in the wave of the unit.
   They need no change in wave 4.
2. **Full cases.** A full case has the default plugin options. It lands in wave 4, with the
   regeneration, in the same generator. No case skips with a computed reason. Thus tool 5 can
   scan each skip reason (section 8).
3. A full case exists only where a plugin outside the set of the unit changes the result. The
   first list: title with the default legend (the box order), subtitle with title and legend,
   legend with a tooltip after `hoverLegend`, filler on a radar with the colors plugin on,
   decimation with a fill, and tooltip with a title, a filler and a hidden dataset from
   `clickLegend`. The unit agent adds a full case for each other interplay that it finds.
4. Size: about 116 unit cases and about 15 full cases. At 9 to 26 KB for each case, this is about
   1.5 to 3.5 MB in 9 data files. A file above 2.5 MB splits (Chart.js ADR 0030 §3 item 6).

### 5. The legend override cases of doughnut, pie and polar area

1. Until wave 4 the test-legend probes stay as they are, on both sides.
2. In wave 4 the probes with a test legend go: the JS fakes of the three generators and
   `_TestLegend` of the three Dart files. With the real legend registered, a test legend in
   `chart.legend` breaks `chart.update()` at `plugin.legend.js:625` (`buildLabels` is not a
   function).
3. New cases in the three generators and their Dart files take their place:
   - `legend: items`: the default case with the label options of the old test legend in
     `plugins.legend.labels` (`pointStyle: 'circle'`, `textAlign: 'left'`,
     `useBorderRadius: true`, `borderRadius: 0`). The probe `realLegend` reads
     `chart.legend.legendItems` and `legendHitBoxes`.
   - `legend: click`: the step `['clickLegend', 1]`. The observations show the hidden arc and
     the new items.
   - `legend: click twice`: two steps `['clickLegend', 1]`. The item comes back.
   - The polar area generator also has `legend: off` with `plugins: {legend: false}`. Its probe
     `noLegend` calls the override `generateLabels` and pins the `TypeError` of the read of
     `chart.legend.options`.
4. The Dart probes read `legendItems` through `types.LegendElement` (Chart.js ADR 0028 Open 2)
   and `legendHitBoxes` through a cast to `Legend`. `legendHitBoxes` is not in `index.d.ts`, so
   it is not a member of the interface (Chart.js ADR 0038 §6).
5. The cases run the real path of `controller.doughnut.js:93-129` and
   `controller.polarArea.js:36-68` through `buildLabels`, the event path and the draw of the
   items.

### 6. The harness

1. `test/flutter_test_config.dart` gets the colors line in wave 4, after `setUpBuiltins(...)`
   and before `setUpDefaultsRestore()`:

   ```dart
   // index.js:25-28
   // Disable colors plugin for tests.
   //
   // Upstream runs the line in a top-level `beforeAll`, once, before the
   // first spec. Here it runs before `main()` of each test file and before
   // the snapshot of `harness-defaults-restore`, so the restore keeps it.
   // A file that calls `removeBuiltins()` puts back the scopes of before the
   // registration, without the colors plugin.
   ((defaults['plugins']! as AnyObject)['colors']! as AnyObject)['enabled'] =
       false;
   ```

   The integration agent uses the read form that the type of `defaults.plugins` allows.
2. The namespace `plugins` of `lib/src/index.dart` lists the seven plugins in the order of
   `src/plugins/index.js:1-7` (Chart.js ADR 0038 §2). `core.plugins.js:128` makes this the hook
   order.
3. `setUpSpecs()` does not change. `removeBuiltins()` removes the colors plugin and its
   defaults, so a pure-layer file has no colors line to undo.

### 7. Registration in waves 1-3 and the lift in wave 4

1. The plugins join `registerables` in wave 4 only. Thus the 18 generators run once.
2. In waves 1-3 each plugin test file registers its own plugin, and the plugins that its cases
   need, in `main()`, before the snapshot of the restore. This is the form of Chart.js ADR 0030
   §3 item 4 for a plugin. The plugin values are the names of Chart.js ADR 0038 §1. The order in
   one call is the order of `src/plugins/index.js:1-7`.

   | Test file (spec and port-only) | Registers in `main()` | Wave |
   | --- | --- | --- |
   | `plugin.title_test.dart` | `title` | 1 |
   | `plugin.colors_test.dart` | `colors`, then the colors line | 1 |
   | `plugin.subtitle_test.dart` | `subTitle`, `title` | 2 |
   | `plugin.legend_test.dart` | `legend` | 2 |
   | `plugin.filler_test.dart`, `plugin.filler/index_test.dart`, `plugin.filler/filler.target_test.dart` when its cases build a chart | `filler` | 2 |
   | `plugin.decimation_test.dart` | `decimation` | 2 |
   | `global.defaults_test.dart` | `legend` | 2 |
   | `plugin.tooltip_test.dart` | `legend`, `tooltip` | 3 |
   | `test/port/theme/precedence_test.dart` (Chart.js ADR 0042, test 2) | `colors`, then the colors line | 1 |
   | `test/port/theme/decimation_theme_test.dart` (Chart.js ADR 0042) | `colors`, `decimation` | 2 |
   | `test/port/theme/presets_plugins_test.dart` (Chart.js ADR 0042, test 3) | `legend`, `subTitle`, `title`, `tooltip` | 3 |

   The pure unit tests of the filler and of the decimation algorithms register nothing: they
   build no chart.

   ```dart
   void main() {
     // Chart.js ADR 0041 section 7: until wave 4 adds the plugins to
     // registerables, this file registers the plugins that its cases need.
     Chart.register([legend, tooltip]);
     group('Plugin.Tooltip', () { /* ... */ });
   }
   ```

3. A port-only test that needs all seven plugins (for example the hook dispatch test of Chart.js
   ADR 0038 §11) lands in wave 4.
4. The fixture smoke results do not change with the plugin set of a wave. Thus `test:fixtures`
   runs green in each wave. The run of wave 4 is the run of record.
5. The `blocked: plugin.*` skips of the other spec files stay in waves 1-3. Their files register
   no plugin, so the stale-skip check of the runner (Chart.js ADR 0029 §9 item 6) does not fire.
6. **Wave 4, one change:** the seven plugins in the namespace `plugins`, the colors line, the 18
   generators again (section 1), the legend override cases (section 5), the full cases
   (section 4), the 33 spec skips lifted with bodies at their upstream lines, the 33 fixture
   skips removed with the 8 hand ports of the impure skipped configs, the `register` lines of
   waves 1-3 removed, the 15 plugin rows of `status.yaml`
   at `ported`, and `global.namespace_test.dart` (section 12). Then `test:cases`,
   `test:fixtures`, the stale-block check and the full gate are green. The 24 phase 7 fixtures
   that run with a `plugins` key are the regression set of this change. The 4 precedence
   placeholders get their bodies earlier, in wave 1, with the colors hunks (Chart.js ADR 0042,
   test 2).

### 8. The stale-block check in tool 5 (Chart.js ADR 0030 Open 1)

1. Tool 5 fails a skip literal `'blocked: <module>'` when each `src/` row of `<module>` in
   `parity.md` has the status `ported`. It also fails a module without a `src/` row. The rows of
   a module are the rows of `requiredBy`: the file name without its extension is `<module>`, or
   the row is in a `<module>/` folder.
2. The scan reads the string literals of `test/` through `DartSource`. Comments do not count. It
   leaves out `test/tool/`, whose literals are test input, and the generated
   `*_reference*.dart` files. A run takes 63 to 85 ms without the generated files.
3. It covers the spec files, `test/port/` and `fixtureSkips` of `test/fixtures/index.dart` with
   one mechanism. The runtime check of Chart.js ADR 0029 §9 item 6 stays.
4. Tool 5 runs the check in the case mode and in the fixture mode.
5. The status rule: a module row goes to `ported` in the change that registers the module and
   lifts its skips. Before that, its status text says "in progress". In phase 8, the 15 plugin
   rows go to `ported` in wave 4.
6. Today all reasons have a row: `plugin.*` (15 rows) and `index.umd` (`src/index.umd.ts`).

```dart
/// The `src/` rows of [module] in [parity], by the rule of [requiredBy].
List<String> moduleRows(String module, Map<String, String> parity);

/// Chart.js ADR 0041 section 8: the stale `'blocked: <module>'` literals of
/// [sources] (path to text, test/ without test/tool/ and without the
/// generated `*_reference*.dart` files). A literal is stale when each `src/`
/// row of <module> in [parity] is `ported`. A module without a row is an
/// error too.
List<Finding> staleBlockedSkips(
  Map<String, String> parity,
  Map<String, String> sources,
);
```

### 9. One fixture registry (Chart.js ADR 0029 Open 2)

One registry stays. Three A/B series measured the import of `test/fixtures/index.dart` in
`-j 1` runs: the median of the largest series is 0.38 s for 119 hand ports, and a series with
147 hand ports gives 1.07 s (interval 0.54 to 1.50 s). The trigger is 4 s. Wave 4 measures again
after the 28 new hand ports, on a quiet Mac, and records the figure in `performance.md`.

### 10. The hand ports

1. 28 new hand ports in the form of Chart.js ADR 0029 §4. The 20 impure `plugin.*` configs come
   in the wave of their plugin. The 8 impure skipped configs come in wave 4. 18 of them need
   `// ignore_for_file: file_names`.
2. The 8 tooltip fixtures share one port-only helper, `test/fixtures/fixture_events.dart`
   (outside `hand/`, as `index.dart`). It gives the chart event that `getRelativePosition`
   gives for the raw `mousemove` at a point. At DPR 1, with the canvas at the origin of its
   host, this is `Math.round` of the point (`helpers.dom.ts:128-129`). Its `native` is Dart
   `null`, because the raw event has no `native` key.

   ```dart
   /// The chart event that getRelativePosition (helpers.dom.ts:105-130) gives
   /// for the raw `mousemove` of a tooltip fixture at [point]: at DPR 1 and
   /// with the canvas at the origin, Math.round of the point (:128-129).
   /// Row harness-fixture-sources.
   types.ChartEvent fixtureMouseMove(types.Point point);
   ```

   The hand port calls `chart.handleEvent(event)`, `chart.tooltip!.handleEvent(event)` and
   `chart.tooltip!.draw(chart.ctx)`. `handleEvent` keeps `replay` and `inChartArea` absent, so
   the chart keeps its active elements, as upstream (`core.controller.js:1196`, `:1249-1255`).
3. One value differs: upstream `tooltip._eventPosition` is `{x: undefined, y: undefined}` for
   the raw event, and the port has numbers. Only the positioner `nearest` reads it. The 8
   fixtures use `average`. The smoke test asserts no value (Chart.js ADR 0034). The row
   `harness-fixture-sources` records this.
4. `plugin.tooltip/opacity.js`: a module canvas of
   `document.createElement<HTMLCanvasElement>`, `createPattern` with `toImageSource()`, and
   `createLinearGradient`, as `controller.doughnut/doughnut-animation.dart` does.
5. `controller.line/fill/no-border.js`: the `run` hook uses `setTimeout` and a `Future` of the
   harness (Chart.js ADR 0022 §7), not one long pump.
6. `plugin.legend/padding/add-column.js`: the push calls `notifyArrayListeners`
   (`platform-array-events`).
7. `plugin.filler/line/points-outside-canvas-update.js`: the write
   `chart.scales.x.options.min = 5` is `operator []=` of the resolver.
8. `plugin.filler/line/dataset/interpolated.js`: `dart:math` with `js-ok`, because the smoke
   test asserts no value.
9. `plugin.legend/horizontal-rtl-hitbox.js` reads `legendHitBoxes` through a cast to `Legend`
   (Chart.js ADR 0038 §6).

### 11. Spies on methods

1. **`spyOn(tooltip, 'update')`** (`plugin.tooltip.tests.js:964`, `:1027`). Chart.js ADR 0039
   §6 makes `Tooltip.update` a method field. The spec replaces the field with a recording
   closure. With `callThrough` (`:964`) the closure calls the old function. This ADR does not
   decide the form again.
2. **`spyOn(chart, 'update').and.callThrough()`** (`global.defaults.tests.js:110`, `:186`). A
   private helper of `test/specs/global.defaults_test.dart` registers a plugin whose
   `beforeUpdate` records each update of the chart. `update` notifies `beforeUpdate` after
   `this._plugins.invalidate()` (`core.controller.js:488-492`), so a plugin registered in the
   test sees the first update. No built-in plugin returns `false` from `beforeUpdate`. The spec
   asserts only `toHaveBeenCalled()` (`:116`, `:192`). A probe gave the same calls and the same
   modes for the Jasmine spy and the plugin.

   ```dart
   /// spyOn(chart, 'update').and.callThrough(): a plugin whose beforeUpdate
   /// (core.controller.js:490) records the mode of each update of [chart].
   /// It unregisters at the end of the test.
   List<Object?> _spyOnUpdate(Chart chart) {
     final calls = <Object?>[];
     final plugin = <String, Object?>{
       'id': r'$updateSpy',
       'beforeUpdate': (Object? c, Object? args, Object? options) {
         if (identical(c, chart)) calls.add(jsGet(args, 'mode'));
       },
     };
     Chart.register([plugin]);
     addTearDown(() => Chart.unregister([plugin]));
     return calls;
   }
   ```

   `expect(chart.update).toHaveBeenCalled()` becomes `expect(calls, isNotEmpty)`. The name and
   the other assertions do not change. `Chart.update` stays a method, and `types.Chart` does not
   change. No `differences.md` row: the library does not change, and the spec keeps its
   assertion (the precedent of Chart.js ADR 0030 §13 item 5).

### 12. `global.namespace.tests.js`

1. `test/specs/global.namespace_test.dart` has `@TestOn('vm')`. The case `:3` needs `Chart`,
   and `core.controller.dart` is not a pure layer (it imports `platform/index.dart`). Thus the
   file is not a pure spec file. It has no chart, so its cases are `test()` cases.
2. `:3` "should a function (constructor)": `expect(Chart.new, isA<Function>())`.
3. `:6`, `:26` and `:35`: `test(name, () {}, skip: 'blocked: index.umd')`. The stale-block check
   keeps them valid while the row `src/index.umd.ts` is not `ported` (phase 9).
4. The file lands in wave 4.

### 13. Tests, rows and records

- The 18 generators again in wave 4: a second run gives byte-identical data. The 18 Dart files
  pass with the plugins registered.
- `test/port/flutter_test_config_test.dart`, group `harness-register-builtins`: the keys of
  `registry.plugins.items` are `colors, decimation, filler, legend, subtitle, title, tooltip` in
  this order, and `defaults.plugins.colors.enabled` is `false` at the start of a test. A test
  writes `true`. A later test reads `false` again only when the first test ran in the same shard
  (AGENTS.md, Tests). A file with `removeBuiltins()` has no `plugins.colors`.
- The 8 plugin reference test files of section 3, each with its themed run.
- The legend override cases of section 5.
- `test/tool/spec_cases_test.dart`, group `stale blocked skips`: a module with all rows `ported`
  (a finding), a module `in progress` (none), a folder module with one row `in progress` (none),
  an unknown module (a finding), a doc comment (none), a literal in `test/tool/` (not read), a
  generated data file (not read).
- `test/specs/global.defaults_test.dart`: the two legend click cases with `_spyOnUpdate`.
- `test:fixtures` in wave 4: each fixture passes or skips with a `diverges` or `n/a` reason.
- Rows, no new row. Changed rows: `harness-register-builtins` (the seven plugins in the order of
  `src/plugins/index.js:1-7`, the colors line, `registerBuiltins` of the generators),
  `harness-defaults-restore` (the colors line runs before the snapshot) and
  `harness-fixture-sources` (the 8 tooltip fixtures, `fixture_events.dart`, the
  `_eventPosition` note). Chart.js ADR 0039 changes `harness-method-fields` for
  `Tooltip.update`. This ADR adds nothing to that row.
- AGENTS.md (Commands, Tests) and [porting-flow.md](../porting-flow.md) §4 (tool 5) get the
  stale-block check, the colors line and the registration rule of section 7.

## Alternatives considered

| Alternative | Reason against it |
| --- | --- |
| B1: each of the 18 Dart reference files calls `Chart.unregister([plugins])` in `main()`, with no data change | The tests then pin a chart that no spec and no app with `registerables` makes. The plugins change protected values of the default configuration: 5 of 605 tick lists, 638 of 666 chart areas, the box list, the numeric control points of a scatter line with a tension (`plugin.filler/index.js:61`), the radar fill and the `changed` flag of `plugin.tooltip.js:1270`. B1 never pins them. A stand-in run showed that only 1 of the 11 files with hand values fails, so the cost of option A is small. The form stays allowed for a future generator without plugins (section 1 item 8). |
| B2 and B3: the Dart harnesses set `legend.display: false`, and also `tooltip.enabled: false` | They do not keep the data: 15 and 14 cases still change, from the filler and the tooltip. |
| C: option A for the controller files, B1 for the scale files | It saves less than 1 s for each CI shard and loses the legend layout of each scale case. |
| Each plugin joins `registerables` in its own wave | The 18 generators then run up to four times and change the same data each time. |
| One generator for all plugins | It loses the one-to-one map of the upstream files, makes a file above 2.5 MB, and runs all data again for a change of one plugin. |
| The hit matrix in the plugin cases | 24.5 % to 34.4 % of the bytes for values that the plugins do not change. |
| One plugin generator with all plugins and a Dart file with only the plugins of its wave, without `false` options | Each case of waves 1-3 fails: the default title case has another chart area and another box list, and a radar case draws 831 calls against 743. |
| Full cases in waves 1-3 that skip with a computed `blocked:` reason until wave 4 | Tool 5 cannot scan a computed reason. The full cases land in wave 4 instead. |
| A copy of each unit case as a full case | About 90 more cases for no new value. Only the cases where a later plugin changes the result stay. |
| Keep the test-legend probes with a save and restore of `chart.legend` | It keeps the test legend in two languages and tests the override functions out of their path. The real legend runs the path of `buildLabels`, the event and the draw. |
| Each test file registers the plugins of all finished waves (R1) | A probe of each phase 8 spec file gave 0 status differences between this set, the set of section 7 and all plugins. Section 7 registers fewer plugins. |
| No registration before wave 4 | The specs and the fixtures of waves 1-3 cannot run. |
| A runtime helper `blockedBy('plugin.legend')` at each skip site | It finds only plugin skips, not `index.umd` or `controller.*` skips, and changes 33 sites. |
| Only the temporary lift script of the phase | It ends with the phase. Chart.js ADR 0030 Open 1 asks for a permanent check. |
| A line-prefix test for comments in the stale-block scan, and no error for an unknown module | A doc comment with a quoted reason then counts, and a typo in a module name passes. |
| One registry for each spec file | The import costs 0.38 s to 1.07 s against the trigger of 4 s. |
| `Chart.update` as a method field | `types.Chart.update` becomes a getter of a function type. Each class that implements `types.Chart` changes, also in the gallery. The cost is about 1.5 ns on AOT for each update of 29 to 54 µs, below the threshold of Chart.js ADR 0020 §13, so performance does not decide. The upstream structure and less code do. |
| A tooltip substitute in the slot `chart.tooltip` | It contradicts Chart.js ADR 0039 §6 and copies the tooltip state. |
| A delegating `types.Chart` in the legend argument of the spec | The spec then passes another object than `chart.legend`. |
| `getBoundingClientRect` on the harness canvas and a raw Map event in `Chart.handleEvent` | It puts a type test of the raw event into the event path of `lib/` and changes the type of `handleEvent`. |
| A `NativeEvent` in the event of the tooltip fixtures | The raw upstream event has no `native` key. Dart `null` is closer, and the helper is shorter. |
| `global.namespace_test.dart` as a pure spec file | `check:lib-imports` fails it: `Chart` is not in a pure layer. |
| Register the source plugins with `Chart.register(namespace)` | It registers nothing: `each` does not walk an ES module namespace. |

## Consequences

- From wave 4 the reference data of the scales and the controllers pin the default
  configuration of the specs and of an app with `registerables`. A defect of a plugin can fail a
  scale or a controller test. The plugin reference tests then name the plugin.
- The data of the 16 dist generators grows by about 2.2 %. The test time of the reference files
  grows by an estimated 5 % to 16 %, about 1 s for each CI shard. The library does not change.
- The plugin reference tests of waves 1-3 run with only the plugins of their wave. Their data
  does not change in wave 4.
- The stale-block check of tool 5 is permanent. It finds a stale skip in the spec files, in
  `test/port/` and in `fixtureSkips`. A module row goes to `ported` only with the lift of its
  skips.
- `Chart.update` stays a method. `types.Chart` and the gallery do not change.
- `global.namespace_test.dart` runs on the VM only.
- Chart.js ADR 0030 stays in force. This ADR applies its rules (§3 item 4 and item 5) to the
  plugins and decides its Open 1. It also decides Chart.js ADR 0029 Open 2. It supersedes no
  ADR.

## Open

1. **The test time of option A.** Owner: the integration agent of wave 4. Trigger: the summed
   durations of section 2 item 1 grow by more than 25 %. Then `performance.md` records the
   figure and the slowest plugin path.
2. **The size of `scale_time_reference.dart`.** Owner: the porter who adds a time-scale case.
   Trigger: the file passes 2.5 MB. Then the generator writes two files.
3. **The `ellipse` of the mock context.** Owner: the legend unit. Trigger: a legend reference
   case with a point style that calls `ctx.ellipse`. The mock context of
   `scale_chart_common.mjs` has no `ellipse`. Then the unit adds it to the mock and to `dartArgs`.
4. **The registry import after the hand ports.** Owner: the integration agent of wave 4.
   Trigger: the new measurement passes 4 s. Then each spec file imports a registry of its own
   prefix (Chart.js ADR 0029 Open 2).
5. **The blue screen with the plugins.** Owner: Chart.js ADR 0042. From wave 4 each chart of
   `blue_screen_test.dart` has the legend. Chart.js ADR 0042 decides its content.
6. **The Dart-only chart tests after wave 4.** Owner: the integration agent of wave 4. Trigger:
   a test without generator data fails with the plugins registered. Then its expected value comes
   from a probe at the pin (section 1 item 7).

## Evidence

The behavior probes ran the Chart.js build at the pin in the x64 Node.js v24.12.0 under Rosetta,
through mirror copies of `tool/reference/`. The Dart runs used Flutter 3.47.7 (Dart 3.13.5) on an
Apple silicon Mac that other sessions shared (load average 4 to 15). No probe changed a file of
the package.

- **E0, upstream source** at `v4.5.1+7169e651`:
  - `src/index.umd.ts:28`, `src/plugins/index.js:1-7`, `test/index.js:25-28`
  - `src/core/core.plugins.js:125-131`, `:146-154`, `:156-173`,
    `src/core/core.typedRegistry.js:41-44`
  - `src/core/core.controller.js:488-492`, `:1196`, `:1249-1255`
  - `src/plugins/plugin.legend.js:601-605`, `:607-610`, `:615-619`, `:623-627`, `:630-634`,
    `:636-637`
  - `src/plugins/plugin.filler/index.js:48-65`, `src/controllers/controller.line.js:138-142`,
    `src/controllers/controller.radar.js:15-18`
  - `src/plugins/plugin.tooltip.js:1228-1232`, `:1264-1273`
  - `src/controllers/controller.doughnut.js:93-129`, `src/controllers/controller.polarArea.js:36-68`
  - `src/helpers/helpers.core.ts:53-54`, `:152`, `src/helpers/helpers.dom.ts:105-130`
  - `test/specs/global.defaults.tests.js:96-118`, `:172-194`,
    `test/specs/plugin.tooltip.tests.js:964`, `:1027`, `test/specs/global.namespace.tests.js:3-40`,
    `test/fixtures/plugin.tooltip/point-style.js:50-68`
  - chartjs-test-utils `src/fixture.js:45-48` at `v0.4.0`
- **E1, the affected files.** A scan for `acquireChart` and `Chart(` in `test/port/` without
  `removeBuiltins` or `setUpSpecs` gives 34 test files. 18 compare chart data of a generator: 8
  scale files, 8 controller files, `core.controller_test` (`controller_reference.mjs`) and
  `precedence_test` (`theme_precedence_reference.mjs`). The other 16 assert Dart values or the
  data of generators that build no chart with the built-in components.
- **E2, the 16 dist generators in four modes.** Mode `none` gives data equal to the committed
  data in all 16 files. Option A changes 16 of 16 files, 644 of 703 cases, 638 chart areas and
  the draw calls of 640 cases, from 19,184,608 to 19,610,181 bytes (+2.22 %). The draw-call
  lines grow from 313,184 to 337,114 (+7.6 %). The mode with the legend off changes 15 cases in
  2 files. The mode with the legend and the tooltip off changes 14 cases in 2 files: 13 radar
  cases get the fill calls, and the scatter case `showLine true` gets the control points
  `120.201171875, 233.3742857142857, ...` in place of `NaN`. Example of option A: the bar
  `default` case moves its chart area from `[31.34375, 10.2, 512.0, 483.6]` to
  `[31.34375, 32.0, 512.0, 483.6]`. The 25 cases with an expected `TypeError` keep their error
  in each mode. The 16 generators take 28.1 s (none) and 28.9 s (option A). Without a change,
  the doughnut, pie and polar area generators stop in option A with
  `TypeError: legend.buildLabels is not a function`.
- **E3, the two source generators.** Mode `none` gives the committed data. Option A changes 24
  lines of `controller_reference.dart` (the chart area, three more boxes, the element positions,
  the draw calls, and `changed=true` in 5 `afterEvent` lines) and 40 lines of
  `precedence_reference.dart` (the scale sizes). `Chart.register(namespace)` with the ES module
  namespace of `src/plugins/index.js` registers nothing (`defaults.plugins.colors` stays
  `undefined`, `toString` gives `[object Module]`). `Chart.register(...Object.values(namespace))`
  works. No probe ran these two generators twice in option A. Wave 4 shows it.
- **E4, the ticks.** A compare of the tick lists (value, label, major) of the base data and the
  option A data of the 16 dist generators: 5 of 605 cases change (`scale_linear` 'a vertical
  tick limit with a lineHeight in px', `scale_logarithmic` 'a narrow canvas' and 'a narrow
  canvas without major ticks', `scale_radialLinear` 'stepSize 1 on a small canvas' and 'a wide
  canvas').
- **E5, a stand-in legend in the Dart suite.** An archive of `HEAD` with a plugin `legend` that
  adds a full-size box of 32 px on top. `flutter test test/port test/specs --exclude-tags
  fixtures`: 753 tests fail in 20 files (base: 6229 pass). The files: the 16 files with dist
  generator data, `core.controller_test` (3), `precedence_test` (12), `types/index_test` (1) and
  `test/specs/core.interaction_test` (2, an effect of the fixed 32 px, the two cases pass
  upstream with and without the plugins). 10 of the 11 files with hand values pass.
- **E6, a `false` option against an absent plugin.** Line, bar, radar, scatter and doughnut
  charts with a title and `plugins: {legend: false, tooltip: false, filler: false, subtitle:
  false, decimation: false}`. With all plugins and with only title and colors, the chart area,
  the boxes and all draw calls (351 to 1483 calls) are equal. `chart.legend` and `chart.tooltip`
  are `undefined` in both runs.
- **E7, the wave gap.** The default title case: chart area top 66.4 and 5 boxes (legend, the
  hidden subtitle box with height 0, title, 2 scales) with all plugins, top 34.4 and 3 boxes with
  title only. The same case with the later plugins `false`: equal. A radar case with the title
  only: 831 draw calls with all plugins, 743 without the filler.
- **E8, the spec files in the wave sets.** Each phase 8 spec file, with its fixture group, ran
  in the probe harness with the set of section 7, with the plugins of all finished waves and
  with all plugins: 0 status differences in 7 files. The tooltip file with the tooltip alone
  fails 7 cases that need the legend.
- **E9, the fixtures in the wave sets.** The 118 pure data `plugin.*` fixtures with the set of
  their wave and with all plugins: 0 smoke differences. The observations differ only for
  `plugin.subtitle/basic.json` (it needs title) and `plugin.colors/radar.json` (the filler). The
  mock context has no `ellipse`, so `plugin.legend/pointStyle-width/legend-pointStyle-width.json`
  throws in every mode.
- **E10, the registry import.** Three A/B series of `flutter test --no-pub -j 1` with and without
  the import of `test/fixtures/index.dart`. 21 files and 119 hand ports, ABBA twice: 0.23, 0.53,
  0.19 and 3.73 s (the last at load 8.3), median 0.38 s. 29 files and 147 hand ports, no
  `build/test_cache`, 3 pairs: 1.50, 1.18 and 0.54 s, mean 1.07 s, 95 % bootstrap interval
  0.54 to 1.50 s. A rerun of that method: 0.88 and -0.47 s.
- **E11, the stale-block scan.** A prototype scan of the `'blocked: <module>'` literals of
  `test/` without `test/tool/`: 67 sites (33 specs, 1 precedence site that makes 4 tests, 33
  `fixtureSkips`), 0 stale today, 67 stale when each `src/plugins/` row is `ported`. 63 to 85 ms
  without the generated `*_reference*.dart` files, 250 to 294 ms with them.
- **E12, the hit matrix.** A brace-depth count of the `hits` blocks of the 8 committed controller
  data files: 24.5 % (scatter) to 34.4 % (pie) of the bytes.
- **E13, the test time.** `flutter test test/port/scales test/port/controllers --reporter json`:
  17 files, 1137 tests, 21.54 s summed (12.4 to 37.1 ms for each test), wall 7.6 s. One upstream
  case (make, update, hover, draw calls, destroy) costs 0.58 to 0.73 ms more with the plugins
  (bar x1.39, line x1.33, doughnut x2.24, radar x1.38).
- **E14, the `beforeUpdate` spy.** On a legend `onClick`, `update('none')` and
  `toggleDataVisibility` with `update()`, on doughnut, polar area and line charts: a Jasmine-form
  wrapper of `chart.update` and a registered `beforeUpdate` plugin give 3 calls with the modes
  `[null, 'none', null]` in both forms. Two legend clicks give 2 calls in both forms.
- **E15, `Chart.unregister` in `main()`.** A Dart test file registers a namespace with a
  stand-in plugin and then calls `Chart.unregister([namespace])` in `main()`: the keys of
  `defaults.plugins` are empty again, and no hook runs in two later tests. A plugin that one test
  registers runs its hooks and is gone in the next test after its `addTearDown`.
- **E16, a method and a field for `update`.** 2e7 calls through an interface: AOT 0.74 to 0.84
  ns (method) and 1.73 to 2.38 ns (field), dart2wasm in the x64 Node.js 0.74 to 1.69 ns for both.
- **E17, the rerun.** A second option A run of the 16 dist generators is byte-identical (16 of
  16). The base run equals the committed files.
