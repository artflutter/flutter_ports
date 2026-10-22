# Chart.js ADR 0030: Controller test strategy

- Status: accepted (2026-10-21)
- Date: 2026-10-21
- Related: [Chart.js ADR 0001](0001-theming.md) (the four theming invariants),
  [Chart.js ADR 0006](0006-options-representation-and-resolver.md) (the `undefined` sentinel),
  [Chart.js ADR 0009](0009-no-display-only-js-exactness.md) (the protected behavior),
  [Chart.js ADR 0010](0010-js-numeric-semantics.md) (the reference engine),
  [Chart.js ADR 0012](0012-dart-file-naming.md) (the spec paths and the file names),
  [Chart.js ADR 0017](0017-element-properties.md) §11 (`Path2D`),
  [Chart.js ADR 0020](0020-registry-and-component-classes.md) §13 (a gain that only a
  microbenchmark measures),
  [Chart.js ADR 0021](0021-typed-options-in-the-resolver.md) §4 (the key order of the options),
  [Chart.js ADR 0022](0022-chart-test-harness.md) §2, §6 and §8 (the spec form,
  `triggerMouseEvent`, the built-in components),
  [Chart.js ADR 0024](0024-dates.md) (the time scale, the 57 time twins),
  [Chart.js ADR 0025](0025-scale-value-parameters.md) §9 (the skips of phase 6),
  [Chart.js ADR 0027](0027-parsed-data.md) §9 and [Chart.js ADR 0028](0028-controller-interfaces.md)
  §8 (the pin cases of the controllers),
  [Chart.js ADR 0029](0029-fixture-smoke-runner.md) (the fixture smoke runner, a parallel decision
  of phase 7),
  [theming.md](../theming.md) §6, §8 and §10,
  [porting-flow.md](../porting-flow.md) §1 step 5, §1.1, §3 and §4

## Context

Phase 7 ports the 8 controllers of `src/controllers/`. The kickstart of the phase asks for four
kinds of tests in addition to the spec ports and the fixtures:

1. Port-only reference tests for each controller. They build real charts with `acquireChart` and
   compare them with Chart.js built at the pin `7169e651` in the x64 Node.js. They compare the
   element properties, the resolved options, the parsed items, the stacks, the draw calls and the
   hit elements of `getElementsAtEventForMode`.
2. The theme tests of the phase 7 row of `theming.md` §10: test 3 for the elements and the scales
   on 8 chart types, test 5 on a doughnut and a bar chart, the hover tests, and the blue screen
   without plugins.
3. The lift of the skips: 366 Dart tests skip as `blocked: controller.*` (309 in `test/specs/`, 57
   time twins in `test/port/scales/scale.time_test.dart`).
4. The conventions of the 7 controller spec files `test/specs/controller.*_test.dart`.

This ADR decides these four questions. A design panel wrote three drafts (fidelity first,
performance first, simplicity first). A judge scored them and re-ran the main probes. The line
numbers below refer to Chart.js `v4.5.1+7169e651`, read in `third_party/Chart.js` at the pin.

### Upstream facts

- `core.datasetController.js:257`: `this._ctx = chart.ctx`. `_ctx` is a plain JS property. Any
  code can write it.
- `core.datasetController.js:712-741`: `draw()` reads `this._ctx` once (`:713`). It draws
  `meta.dataset` first (`:724-726`). It skips a hidden element (`:730-732`). With
  `drawActiveElementsOnTop`, it draws the active elements last (`:733-741`).
- `controller.bar.js:668-680`: the bar `draw` reads `this._ctx` for each bar (`:677`). It skips a
  bar with a `null` value and a hidden bar (`:676`).
- `controller.bar.js:7-17`: `getAllScaleValues` keeps the sorted values in `scale._cache.$bar`.
  `computeMinSampleSize` (`:24`) reads them. A bar on a time or a linear index axis takes this
  path.
- `element.line.js:233`: `const usePath2D = typeof Path2D === 'function'`, read when the module
  loads. With `Path2D`, a line without `segment` strokes a cached `Path2D` (`:236-237`). Node.js
  has no `Path2D`.
- `core.controller.js:442-448`: each new controller gets its element classes from the registry
  (`registry.getElement`).
- `core.controller.js:820-824`: `getElementsAtEventForMode(e, mode, options, useFinalPosition)`.
  `helpers.dom.ts:105-111`: `getRelativePosition` returns a chart event (an object with `native`)
  as it is.
- `core.interaction.js:214-216`: the axis `'r'` without `intersect` takes the radial path.
- `core.controller.js:1163-1176`: `_eventHandler(e, replay)` calls `_handleEvent` (`:1196`).
- `core.datasetController.js:815`: the active prefixes are
  `[`${elementType}Hover`, 'hover', elementType, '']`. `_setStyle` (`:919-926`) puts back the
  shared options after the hover.
- `controller.doughnut.js:75`: `spacingMode: 'angular'`. `controller.polarArea.js:26`:
  `spacingMode: 'proportional'`. `controller.polarArea.js:204-210` replaces the arc defaults
  with the chart-level values.
- `controller.bar.tests.js:1463-1464`: `[undefined, 20].forEach` makes the describe names
  `'When barThickness is ' + barThickness`.
- `controller.bar.tests.js:1181-1184` and six more files: `spyOn(meta.data[i], 'draw')`.
  `controller.line.tests.js:125-126`: `spyOn(meta.dataset, 'updateControlPoints')` and
  `spyOn(meta.dataset, 'draw')`. `core.datasetController.tests.js:15-41`: `spyOn(controller,
  '_onDataPush')` and four more methods.
- Line 2 of each controller spec file: `describe('auto', jasmine.fixture.specs('controller.<x>'))`.
- The 7 controller spec files use `jasmine.objectContaining` at 13 sites.
- The Chart.js lockfile pins jasmine-core 3.99.1 (`pnpm-lock.yaml:9733`).

### Port facts

- `lib/src/core/core.datasetController.dart:685-689`: `final CanvasRenderingContext2D? ctx`.
  `draw` reads it once into a local (`:1384`).
- `lib/src/elements/element.line.dart:590`: `const bool _usePath2D = true`. The canvas interface
  always has a `Path2D`, as a browser.
- Phase 6: `drawCalls` of `test/port/scales/scale_chart_harness.dart:313-347` puts a recording
  context in `chart.ctx` and in each `scale.ctx`. It cannot put it in the final controller field.
  Thus `drawCalls` of `tool/reference/scale_chart_common.mjs:910-940` draws the elements on a
  second context (a sink). Its comment (`:916-919`) says that the sink exists only because the
  Dart field is final. Both sides record no element draw.
- `test/port/elements/element.line_test.dart:145-192` maps a `Path2D` argument to
  `{path, calls}`. `tool/reference/line_reference.mjs:96-105` defines the recording `Path2D`.
- `test/specs/core.controller_test.dart:62-160` has a private `_objectContaining` and `_toEqual`.
  `core.plugin_test.dart:32-110` has a private `_spyOn`. `helpers.canvas_test.dart:37-79` puts a
  spy context in the slot `chart.ctx`.
- `test/port/scales/scale.time_test.dart:196-201`: `_lineTwin` skips each twin as
  `blocked: controller.line`.
- `tool/src/spec_cases.dart:24-30`: tool 5 accepts a fixture test in a fixture group of the
  manifest when its name is the fixture path.
- `classification/all.json` and `classification/summary.md` (working files of phase 7, not
  committed), with decision D1 of `summary.md` §8: 536 records, 503 `phase7`, 21
  `blocked: plugin.legend`, 11 `blocked: plugin.tooltip`, 1 `blocked: plugin.filler`. 501 of the
  503 `phase7` records pass in the probe mode `none`. 2 are `unsupported` in the probe and have a
  variant as evidence (`summary.md` §5 items 2 and 3).

## Decision

### 1. The element draws in the draw calls

1. `DatasetController.ctx` becomes a writable field, as the upstream property `_ctx`:

   ```dart
   /// core.datasetController.js:257 `_ctx`, the context of the chart.
   /// controller.bar.js:677 reads it. Dart `null` stands for the JS `null` of
   /// a chart without a context. It is writable, as the JS property: the
   /// reference tests put a recording context here.
   @internal
   CanvasRenderingContext2D? ctx;
   ```

   The constructor still writes it from `chart.ctx`. This removes a difference of form. It needs
   no `DIVERGES` marker and no `differences.md` row.
2. One `drawCalls` serves all reference tests, on both sides. The Dart `drawCalls` puts the
   recording context in `chart.ctx`, in each `scale.ctx` and in the `ctx` of each controller whose
   `ctx` is the context of the chart. It draws once and puts back each old context. The JS
   `drawCalls` loses the sink: it resets the calls of the chart context, draws once and reads the
   calls.
3. The 8 phase 6 reference files (`scale_chart_harness`, `scale_category`, `scale_linear`,
   `scale_linearbase`, `scale_logarithmic`, `scale_radial_linear`, `scale_time`,
   `scale_timeseries`) are generated again in the same change. The phase 6 scale tests then also
   compare the point draws of their test controllers.
4. The bar `draw` keeps the upstream read of `ctx` for each bar (`controller.bar.js:677`). Open
   item 3 owns a later change.

### 2. `Path2D` in the controller generators

1. `tool/reference/controller_chart_common.mjs` defines the recording `Path2D` of
   `line_reference.mjs:96-105` on `globalThis` in its module body. Its first call of
   `loadChartJs()` comes after that line. Thus the dist evaluates `usePath2D` to true, as the port
   and a browser do.
2. `dartCalls` of `scale_chart_common.mjs` writes a `Path2D` argument as
   `{path: <id>, calls: [...]}`, with the ids in the order of the first sight in one `drawCalls`
   call. This is the form of `element.line_test.dart:145-192`. The phase 6 charts have no line
   element. Thus their files do not change for this reason.
3. The Dart helpers `_PathIds`, `_actual`, `_actualCalls` and `_replay` move from
   `element.line_test.dart` to the shared helper library `test/port/canvas/path2d_record.dart`.
   `expectCalls` maps each `Path2D` argument through it. `element.line_test.dart` imports it.

### 3. Generators, files and data

1. One shared file `tool/reference/controller_chart_common.mjs` imports
   `scale_chart_common.mjs`. It keeps the checks of `loadChartJs` (x64 Node.js, the build at the
   pinned commit, a clean checkout). It adds the `Path2D` recorder, `registerPhase7(C)`
   (`C.Chart.register(C.controllers, C.scales, C.elements)`), `observeControllers`, `hits`,
   `runSteps` and `runControllerCase`.
2. One generator for each controller file:
   `tool/reference/controller_{bar,line,scatter,bubble,doughnut,pie,polar_area,radar}_reference.mjs`.
   Each writes `test/port/controllers/controller_<name>_reference.dart` with `writeReference`.
3. One Dart harness `test/port/controllers/controller_chart_harness.dart` (a library, not a test
   file). One test file for each controller at the mapped path of its `lib/src` file:
   `test/port/controllers/controller.<name>_test.dart` (`@TestOn('vm')`).
4. The Dart tests register no built-in component: `flutter_test_config.dart` registers the
   built-in components, with the controllers of each finished wave (`harness-register-builtins`).
   A unit of a wave tests its controller before the integration agent of the wave registers it.
   Until then, each test file of the unit registers the controller class in `main()`, before the
   snapshot of the defaults restore: `Chart.register([<Name>Controller.jsClass])`. A second
   registration of the same id does nothing (`core.typedRegistry.js:41-44`). The integration
   agent of the wave removes these lines when it registers the wave. A test-only subclass with
   its own id (for example the polar area subclass with option sharing of Chart.js ADR 0028)
   registers in its test and unregisters at its end.
5. The phase 6 generators keep `registerPhase6`. The infrastructure change runs them once with
   `registerPhase7`. If the output is byte-identical, `registerPhase6` stays. If not, the phase 6
   generators move to `registerPhase7` in the same change, because the phase 6 Dart tests run
   with the controllers registered.
6. The data format is the phase 6 form: Dart `const` literals, and one raw JSON-lines string of
   the draw calls for each case. The hit items (`hits.items` of each observation) are text too,
   not Dart literals: one JSON line `items[p]` for each point, in the form of the draw calls
   (decision D8 of the phase lead, 2026-10-21). The reason is the data size. A probe of 3 cases
   gave 1,521,132 bytes with the hit items as literals and 495,325 bytes with the text (the U0
   report, R6: `U0-report.md`, a working file of phase 7, not committed). Thus the 23 bar cases of
   section 7 need about 11.7 MB as literals and about 3.8 MB as text (an estimate: the size of a
   case changes with its steps). Only the text fits in two data files of 2.5 MB. The compare does
   not change: each item `items[p][q]` is the list `[[datasetIndex, index], ...]`, and the items
   compare exactly (sections 4 and 5). A data file has at most 2.5 MB. A generator with more data
   writes two data files, `controller_<name>_reference.dart` and
   `controller_<name>_reference_2.dart`, from one case list.
7. Each reference case is one `testWidgets` case. A batch saves about 4 ms for each case and hides
   the name of the failed case.
8. The JS charts get the `BasicPlatform` of Node.js, whose `updateConfig` writes
   `animation: false` (`platform.basic.js:20-22`). The Dart harness gives the platform of
   `platform.flutter.dart`, which keeps the option. A generator with a case that needs the
   animation options (the `reset` cases of `controller_doughnut_reference.mjs` and
   `controller_polar_area_reference.mjs`) puts the no-op `updateConfig` of `BasePlatform`
   (`platform.base.js:80`) on `BasicPlatform` before its cases.

### 4. The observations of a reference case

The expected Map of a case has the keys `initial`, `steps` and `drawCalls`. `initial` holds the
observations after `acquireChart`. `steps` holds one `{do, observations}` for each step. The
draw calls come from one `chart.draw()` after the last step.

Two optional keys serve the pin cases of Chart.js ADR 0027 §9 and Chart.js ADR 0028 §8:

- `error`: `{at, name}`. The generator records it when `makeChart`, a step or the last
  `chart.draw()` throws. `at` is `'initial'`, `'step <k>'` or `'draw'`. `name` is the name of the
  JS error class. The case stops there. The Dart case expects a throw at the same place: a JS
  `TypeError` is a Dart `TypeError`. Another name needs an entry in the test file, with the
  `differences.md` row that gives the Dart type.
- `extra`: a Map from a probe name to its value after the last step. A probe is a named
  function with one body in the generator and one in the Dart test file, as the `'fn:<name>'`
  functions of the configs. Examples: `countVisibleElements()`, `getMinMax()` of polar area, the
  items of `generateLabels` with a test legend, and `meta._parsed === dataset.data`. A probe reads
  only the chart and its controllers.

The case names of these pin cases start with `parsed:` (Chart.js ADR 0027) or `interfaces:`
(Chart.js ADR 0028).

One observation has these keys:

| Key | Content |
|---|---|
| `chartArea`, `scales` | The keys of `observe` of `scale_chart_common.mjs:759`, unchanged. In the first case of each generator (`default`), each scale also has `options`: the plain copy of the subtrees `grid`, `border`, `ticks` (without `callback`) and `title`, and for `radialLinear` also `angleLines` and `pointLabels`. |
| `stacks` | `chart._stacks` (`core.datasetController.js:154`; Dart `Chart.stacks`): each stack with its index keys and its values. |
| `datasets` | For each dataset index: `type`, `indexAxis`, the axis ids, `stack`, `order`, `visible`, `hidden`, `_clip`, `total` (doughnut, pie), `_drawStart` and `_drawCount` (line, scatter), `getMaxOverflow()`; `datasetOptions` (the dataset options that the controller reads through `this.options`); `parsed` (`meta._parsed`, `_custom` as a value, `_stacks` as its keys only); `dataset` (the line element: `_loop`, `_fullLoop`, the count of `points`, `segments` as `[start, end, loop]`, and its options); `data` (for each element: the properties of its type, `active`, `hidden`, `getCenterPoint()` and `tooltipPosition()`); `options` and `active` (for each element: `element.options` and `resolveDataElementOptions(i, 'active')`); `labelAndValue` (`getLabelAndValue(i)` for each index). |
| `hits` | Section 5. |

The properties of each element type:

| Type | Properties |
|---|---|
| point | `x`, `y`, `skip`, `stop` |
| bar | `x`, `y`, `base`, `horizontal`, `width`, `height` |
| arc | `x`, `y`, `startAngle`, `endAngle`, `innerRadius`, `outerRadius`, `circumference`, `fullCircles`, `pixelMargin` |

The compare rules:

- The check reads exactly the keys of the expected Map. An expected key that no check reads fails
  (the rule of `expectScaleChart`, `scale_chart_harness.dart:521-526`).
- An options object becomes a plain Map through `jsObjectKeys` and `jsGet` before the compare. A
  resolver never goes to `expect`.
- A Map of options compares as a Map: the key order does not count. Chart.js ADR 0021 §4 records
  two cases where the typed order differs from the JS order, and Chart.js ADR 0009 does not
  protect that order.
- A List compares item by item in order: the parsed items, the elements, the hit items, the
  stacks keys and the draw calls. Chart.js ADR 0009 protects this order.
- A number compares with `referenceMatcher` (`scale_chart_harness.dart:443-461`): 1e-9 absolute,
  or 1e-12 relative above 1e3. Hit items and call names compare exactly.
- An absent property is the `undefined` sentinel on both sides. A function value is the string
  `'<fn>'` on both sides.

### 5. The hit queries

- The query: `chart.getElementsAtEventForMode(e, mode, options, false)` with a chart event
  `{type: 'mousemove', native: null, x, y}` (Dart: a `types.ChartEvent` with `native` `null`).
  `getRelativePosition` returns it as it is.
- The modes: `index`, `dataset`, `point`, `nearest`, `x` and `y`. `intersect`: `true` and
  `false`. The axis: `x`, `y` and `xy`, and `r` for `polarArea` and `radar`.
  `includeInvisible: true` also in each case with a hidden dataset or a hidden index.
- The points: the center of each element (`Math.round` of `getCenterPoint()`), the midpoint of
  each two neighbor centers, the four corners of the chart area (1 px inside) and one point
  outside the chart area. Integer points give the same `x` and `y` on both sides.
- The result: the list of `[datasetIndex, index]` in order, compared exactly.

### 6. The steps of a case

Both sides run the same fixed list. Each step records the observations again.

| Step | JavaScript | Dart |
|---|---|---|
| `['update']`, `['update', mode]` | `chart.update(mode)` | `chart.update(mode)` |
| `['setDatasetVisibility', d, v]` | then `chart.update()` | the same |
| `['toggleDataVisibility', i]` | then `chart.update()` | the same |
| `['setActive', [[d, i], ...]]` | `chart.setActiveElements(...)`, then `chart.update()` | the same |
| `['push', d, ...values]` | `data.push(...)`, `chart.update()` | `add` or `addAll`, `notifyArrayListeners(data, 'push', values)`, `chart.update()` |
| `['splice', d, start, count, ...items]` | `data.splice(...)`, `chart.update()` | `jsSplice` and `notifyArrayListeners`, `chart.update()` |
| `['reset']` | `chart.reset()` | `chart.reset()` |
| `['hover', x, y]`, `['mouseout']` | `chart._eventHandler({type, chart, native: {type}, x, y})` | `await triggerMouseEvent(chart, type, point)` |

The hover step uses the real event path of the port (Chart.js ADR 0022 §6). For an integer
point, the DOM path upstream gives the same chart event.

### 7. The case sets

89 cases. Each set covers the option branches of the pinned source. The first case of each
generator is `default`. The pin cases `parsed:` and `interfaces:` of section 4 come in addition to
these 89 cases. The themed run of section 8 runs only the 89 cases.

| Controller | Cases | Branches |
|---|---|---|
| bar | 23 | vertical and `indexAxis: 'y'`; `stacked: true` and `'single'`; stack groups with negative values; floating bars `[a, b]`, also stacked; a hidden dataset and the step `setDatasetVisibility`; `barThickness` a number and `'flex'`, `maxBarThickness`; `grouped: false`; `skipNull` with `null` items; `minBarLength` with 0 and negative values; `base`; `borderSkipped` `'start'`, `'end'`, `'middle'`, an edge, `true`, `false`; `inflateAmount` `'auto'` and a number; `borderRadius`; a linear index axis; a `timeseries` index axis (`_cache.$bar`); a logarithmic value axis; reversed scales; `clip: false`; object data with `parsing` keys; `parsing: false`; string values; `null` and `NaN`; the steps `push` and `splice` |
| line | 17 | `default`; `showLine: false`; `spanGaps` `true` and a number; `stepped` `'before'`, `'after'`, `'middle'`; `tension` with `cubicInterpolationMode: 'monotone'`; `segment` with named functions; stacked lines; `indexAxis: 'y'`; a linear x scale with `min` and `max` (`_drawStart`, `_drawCount`); `pointRadius: 0`; a hidden dataset; `parsing: false`; `null` items; `drawActiveElementsOnTop: false` with the step `setActive`; the step `push` |
| scatter | 6 | `default` (no dataset element); `showLine: true`; a visible x range; object data; `getLabelAndValue` with labels; a hidden dataset |
| bubble | 7 | `r` from the data; a named `radius` function; `hoverRadius` with the step `hover`; custom parsing keys; `[x, y, r]` arrays; `getMaxOverflow`; `clip` |
| doughnut | 15 | `default`; `cutout` `'50%'` and a number; partial `rotation` and `circumference`; two datasets with `weight`; the step `toggleDataVisibility`; `spacing` with the default `spacingMode`, with `'proportional'` and with `'parallel'`; `offset` and `hoverOffset` with the step `hover`; `borderAlign: 'inner'`; the step `reset` with `animateRotate` and `animateScale`; `parsing: false`; labels that are arrays |
| pie | 4 | `default`; the step `toggleDataVisibility`; two datasets; the step `hover` |
| polarArea | 9 | `default`; `startAngle`; the step `toggleDataVisibility`; `spacing` with the default `spacingMode` and with the chart-level override; scale `r` `min` and `max`; the step `reset`; point labels |
| radar | 8 | `default`; `spanGaps`; `tension`; a hidden dataset; `null` items; `showLine: false`; scale `r` options; the step `hover` |

The `timeseries` bar case loads the moment packages through `scale_time_common.mjs`. Its Dart
case runs in `atNow` of `scale_time_harness.dart`, as the phase 6 time tests do. The legend
overrides of doughnut, pie and polarArea read `chart.legend` (`controller.doughnut.js:97`). They
wait for phase 8.

### 8. Theme test 3: the light preset equals upstream

- Each controller test file has a second group, `theming.md §8 test 3: the light preset`. It runs
  each reference case of the file again with `themeConfigKey: compileChartTheme(ChartThemes.light)`
  against the same upstream data. No new generator and no new data.
- The themed run parses each color on both sides before the compare: an option key that ends in
  `Color` or is `color`, and the argument of `setFillStyle` and `setStrokeStyle`. The parse is
  `Color(value).rgbString()` of the ported @kurkle/color, as `presets_test.dart:39` does. The
  unthemed run keeps the exact strings: the resolved option is protected behavior.
- Each element option in the modes `default` and `active` is in the observations (section 4).
  Thus the themed twin covers both modes.
- The `default` case of each file has the scale option subtrees (section 4). The themed run
  compares them. It also reads `test/port/theme/light_snapshot.json`. Each emitted path under
  `scale.` and `scales.<type>.` of a scale type of the chart must be in the observed options. A
  path that is not there fails as a stale key.
- After each themed run, the test compares `defaults` with its state before the run (theming.md
  §6: a theme does not write `defaults`).
- Phase 7 registers no plugin. Thus the colors plugin is off in each run. The run with the colors
  plugin on comes with phase 8.

### 9. Theme test 5 on a doughnut and a bar chart

- `tool/reference/theme_precedence_reference.mjs` registers the pinned
  `src/controllers/controller.bar.js` and `controller.doughnut.js` in both of its modes
  (`upstream` and `prototype`).
- 6 new scenarios of the group `test 5: a theme scale type creates no axis`
  (`precedence_test.dart:1671-1729`): a bar chart and a doughnut chart without a theme, a bar
  chart with a themed `scales.radialLinear` (the axes `x` and `y` only), a doughnut chart with
  themed `scale`, `scales.category` and `scales.linear` (no axis), and the light preset on each
  type. The form of `_axes`
  (`precedence_test.dart:679-698`) does not change: the prototype for each case, and upstream for
  the cases without a theme.
- The existing 4 scenarios with the test controllers stay. They pin the generic path.

### 10. The hover tests

- The oracle is upstream with the replaced values in `defaults`: the method of the group `a
  compiled theme on a radial chart` (`precedence_test.dart:1542-1582`). A hover theme sets the
  tokens `colors.backgroundColor` to `rgb(200, 0, 0)`, `colors.borderColor` and `colors.color`.
  The replaced values are `backgroundColor`, `borderColor` and `color` in `defaults`.
- `theme_precedence_reference.mjs` also registers the line, bubble, polarArea, radar, pie and
  scatter controllers. For each of the 8 types, it runs the step `hover` on the center of element 0
  of dataset 0, then `hover` on the center of a second element, then `mouseout`, through
  `chart._eventHandler(e)`. It records the options of both elements and the active elements
  after each step, with the replaced values in `defaults`.
- Dart: a group `hover` in `precedence_test.dart`. The same steps through `triggerMouseEvent`,
  with the hover theme under `themeConfigKey`. The test compares the options of both elements
  after each step with the reference, and `chart.getActiveElements()` with the reference.
- One absolute pin: the active `backgroundColor` of the bar is `'#B40000'`, the `getHoverColor`
  of `rgb(200, 0, 0)` (theming.md §3.2, `core.defaults.js:62-64`).

### 11. The blue screen without plugins

- A test-support raw Map theme sets each color token to the blue `#2050c0` with alpha 1
  (`(32/255, 80/255, 192/255)`). A blue with channels that are not 0 or 255 shows a rounding
  fault.
- The charts: the 8 types, 2 datasets, labels, the scale titles on, point labels and angle lines
  on the radial types, borders on bars and arcs. No active element: that case waits for
  `IdentityChartHover` (theming.md §8 item 6).
- The read: `UiCanvasContext.paint` of the chart canvas (the call of `chart_host.dart:706`) into a
  `ui.PictureRecorder` over an opaque rectangle of the same blue, `Picture.toImageSync`, then
  `Image.toByteData(format: ui.ImageByteFormat.rawStraightRgba)` in `tester.runAsync`. Each pixel
  must be exactly `20 50 c0 ff`. No tolerance. No golden file.
- A negative control: the same chart without the theme has more than 0 pixels that differ.
- A diagnosis on a failure: the test records the draw calls with the element draws (section 1).
  It names each style setter whose value does not parse to the blue or to alpha 0, with the call
  index.
- A committed known-leaks list, `Map<String, Set<String>>` from the chart type to the leaking
  setter values, each with its upstream file:line. It is empty in phase 7. The test fails when the
  set changes in either direction.
- After the charts, `defaults` is the same as before (theming.md §6).

### 12. The lift of the skips

1. **Order.** A record of `all.json` with the verdict `phase7` lifts after the wave that ports the
   last module of its `modules`. The waves are: 1 bar; 2 line, bubble, doughnut, polarArea,
   radar; 3 scatter, pie, `controllers/index`. Step 4 of the Method ports the bodies. It starts
   the list of a wave when the integration of that wave is green. It changes only spec files and
   `scale.time_test.dart`, so it can run in parallel with the port of the next wave.
2. **Registration.** The integration agent of each wave adds the controllers of the wave to
   `lib/src/controllers/index.dart` and to the `controllers` namespace of `registerables`. Then
   `flutter_test_config.dart` registers them. Wave 3 completes the port of `index.js`.
3. **Form.** A placeholder `test(name, () {}, skip: 'blocked: controller.<x>')` becomes
   `testWidgets(name, (tester) async { ... })` with the body of the upstream case at its line.
   The name does not change. A case without a chart stays `test`.
4. **The time twins.** `_lineTwin` changes in one line in wave 2:
   `void _lineTwin(String name, void Function() body) => testWidgets(name, (tester) async => body());`.
   Its doc comment changes. The 57 call sites and the name stay.
5. **The pure files.** `core.datasetController_test.dart`, `core.interaction_test.dart`,
   `core.layouts_test.dart`, `core.ticks_test.dart` and `element.line_test.dart` move as a whole
   to `@TestOn('vm')`, `flutter_test` and `package:chartjs_test_utils/flutter.dart`, without
   `setUpSpecs()`. Their pure cases (1 in `core.layouts`, 2 in `core.ticks`, 1 in
   `element.line`) then run on the VM only. `test/port/` keeps the web legs of these modules.
6. **The plugin cases.** The 21 legend skips keep `blocked: plugin.legend`, and the 3 tooltip
   skips of `core.controller` keep their reason. No skip changes its reason. The 3 cases of
   decision D1 (`controller.bar.tests.js:1426`, `:1442`, `:1538`) get bodies.
7. **The lift check.** A temporary script `lift_check.py` (a working file of phase 7) reads
   `all.json` and the output of `flutter test --reporter json test/specs test/port`. It maps each
   record to its Dart test by the field `test` (the full name). It fails when a `phase7` record does
   not pass, or when a `blocked: plugin.<id>` record does not skip with exactly that reason. The
   unit of each controller ports the records of its spec file (section 13). A record of that file
   that needs a module of a later wave stays a placeholder with `'blocked: <module>'` until that
   wave, and the lift agent of that wave lifts it. At the pin, these are 3 cases of
   `controller.bar.tests.js` that need `controller.line` (`:70`, `:310`, `:671`). The script also covers the 57 twins, which tool 5 does not read. It prints the
   counts by spec file against
   `summary.md` §2 with D1. The script goes with the working files of phase 7 in the last commit
   of the phase.
8. **A case that fails after the lift.** The classification gives a pass in the mode `none` for
   501 of the 503 records. Thus a failure is a defect of the port, of the transcription or of the
   harness. The rules:
   1. Run the case in the probe: `run_spec.mjs <dist> <spec> --mode none --filter '<it>'`.
      Compare its `values` with the Dart values. The first value that differs names the defect.
   2. Fix the defect in `lib/` or in the harness. Pin it with a reference case of the controller,
      or with a port-only test in `test/port/` when no chart shows it.
   3. Never change the config, an assertion, a tolerance or a name of a spec port. A variant goes
      to `test/port/`.
   4. Never add a `blocked:` or an `n/a:` skip to a `phase7` record. The only other skip is
      `'diverges: <row id>'`, with a `differences.md` row and a `DIVERGES` marker, for a
      difference that Chart.js ADR 0009 does not protect, with the probe output as evidence.
   5. A verdict changes only with `compare.mjs` evidence, as a decision of the phase lead in
      `summary.md` §8. The change updates the record in `all.json`.
   6. Each wave of the lift ends with `test:cases` and `lift_check.py` green: 0 failed cases.

### 13. The conventions of the 7 controller spec files

1. **File.** `test/specs/controller.<name>_test.dart` for `bar`, `bubble`, `doughnut`, `line`,
   `polarArea`, `radar` and `scatter`. Line 1 is
   `// Ported from Chart.js v4.5.1+7169e651 test/specs/controller.<name>.tests.js (MIT, Chart.js Contributors).`,
   then `@TestOn('vm')` and `library;`. The imports are `flutter_test`,
   `package:chartjs_test_utils/flutter.dart`, `package:chartjs_test_utils/pure.dart`,
   `../support/jasmine.dart` and the `lib/src` files that the cases read. No `setUpSpecs()`.
2. **Names.** `group` and `testWidgets` (or `test`) names equal the `describe` and `it` names,
   character for character. A name part that upstream joins with `+` uses `jsToString` of the JS
   value, never Dart interpolation of a `double`: `controller.bar.tests.js:1464` gives
   `'When barThickness is undefined'` and `'When barThickness is 20'`. A `forEach` that makes
   blocks becomes a Dart `for` loop over the same list in the same order. The 7 files have no
   duplicate full name (manifest), so no ` #2` suffix.
3. **The `auto` group.** It stays at its upstream position (line 2) in the form of Chart.js ADR
   0029, with the tag `fixtures`. Tool 5 already accepts its test names. The earlier spec files
   with the comment of a fixture group of phase 7 get the same call at the same position.
   `element.point_test.dart` then also moves to `@TestOn('vm')`, and its pure cases run on the VM
   only. `test/port/elements/element.point_test.dart` keeps the web legs of the module.
4. **`beforeEach`, `afterEach` and Jasmine `this`.** Jasmine `this.chart`, `this.data` and
   `this.config` are `late` variables of the group closure. A `beforeEach` that acquires a chart is
   a local function `void beforeEach()` of the group, and each test calls it first. An `afterEach`
   that acquires or reads a chart is a local function `void afterEach()`, and each test calls it
   last (`controller.bar.tests.js:1325`, `:1399`). A `beforeEach` or `afterEach` that reads no
   chart is `setUp` or `tearDown` (`controller.bar.tests.js:1313-1322`,
   `controller.line.tests.js:555-563`).
5. **Spies on methods.** A Dart object cannot replace one of its methods. The spy is a test
   subclass of the concrete element class. It takes the slot that the library reads:
   `meta.data[i]` or `meta.dataset`. Its spied method records the call and does nothing else, as a
   Jasmine spy without `callThrough`. A `callThrough` spy calls `super` after the record. The
   swap is one line at the place of `spyOn`. The controller writes the properties of the spy at
   the next update. The spy copies `active` and `options` of the original element.
6. **Array listener spies.** `spyOn(controller, '_onDataPush')` and the four others replace the
   controller in the listeners of the data array: `unlistenArrayEvents(data, controller)`,
   `listenArrayEvents(data, spy)`. `addTearDown` puts the controller back.
7. **The Jasmine support library.** One port-only library `test/support/jasmine.dart` holds
   `jasmineEquals` (Jasmine `toEqual`, the `MatchersUtil.eq` semantics of jasmine-core 3.99.1),
   `objectContaining`, `anyFunction`, `JasmineCalls`, the draw spies of section 13 item 5 and the
   listener spy of item 6. It is original code that gives the Jasmine semantics: it copies no
   jasmine-core source. The private copies of `core.controller_test.dart`, `core.plugin_test.dart`
   and `helpers.canvas_test.dart` move into it. It imports only pure layers and
   `package:test/test.dart`, as `chartjs_test_utils/lib/src/matchers.dart` does. Thus a pure spec
   file can import it, and tool 1 needs no change.
8. **Events and context.** `await jasmine.triggerMouseEvent(chart, type, point)` is
   `await triggerMouseEvent(chart, type, point)`. `expect(x).withContext(i).toEqual(y)` is
   `expect(x, jasmineEquals(y), reason: jsToString(i))`.
9. **Plugin cases.** The 9 controller spec cases that need `plugin.tooltip` (8) or
   `plugin.filler` (1) are placeholders `test(name, () {}, skip: 'blocked: plugin.<id>')`.

### 14. The questions of the panel

| Question | Decision | Open |
|---|---|---|
| 1. The reference tests of the controllers | Sections 1-7 | Items 3, 4 |
| 2. The theme tests of the phase 7 row | Sections 8-11 | Item 5 |
| 3. The lift of the skips | Section 12 | Item 1 |
| 4. The spec port conventions | Section 13 | none (Chart.js ADR 0029 closes item 2) |

## Alternatives considered

Each option has a score in the order of [porting-flow.md](../porting-flow.md) §1.1: behavior,
performance, structure, code.

**The three drafts.** The judge (`design/test-strategy/judge.md`, a working file of the phase, not
committed) chose the fidelity draft. It won questions 1, 2 and 4. The simplicity draft won
question 3. This ADR takes the fidelity draft with parts of the other two:

| Draft | Result | Defects that the judge found |
|---|---|---|
| Fidelity (chosen) | All calls, the full hit matrix, the hover oracle of upstream, the slot spies, the support library | Key order with `orderedEquals` (conflicts with Chart.js ADR 0021 §4); "21 cases change reason" (0 change); "498 of 500" (503 with D1); no time case in the bar list |
| Performance | The exact pixel read, options as a Map, 3 more cases, the data-format and granularity figures | Keeps the `final` field with a second mechanism; "7 pure cases in `core.layouts`" (1); no wave order |
| Simplicity | One `drawCalls`, the themed twin of test 3, the lift procedure and counts, the `#B40000` pin | No `Path2D` (wrong line calls); hover oracle against a Dart twin; spies through the registry (global state); no time case |

**The element draws:**

| Option | 1. Behavior | 2. Performance | 3. Structure | 4. Own code |
|---|---|---|---|---|
| A: writable `ctx` (this decision) | All calls (J3 by transfer) | Equal (J5: final 1.835 ns, writable 1.770 ns for each element draw on AOT) | The upstream form | One keyword; one `drawCalls`; the JS sink goes |
| B: `final ctx`, no element draws (phase 6) | Misses the draw order, the skips and the element paint calls | Equal | Differs from upstream | None, but the gap stays |
| C: `RecordingPlatform` through `config.platform` | All calls (J3) | Equal | Keeps `final` | A platform class, a JS option, and the phase 6 swap stays: two mechanisms |
| D: a recording context from the construction (`acquireChart` option) | All calls, and the layout calls | Equal | Changes the harness port (`src/utils.js:36-105`) | A `DIVERGES` hunk in a ported file |
| E: a static draw hook in `lib/` | All calls | Equal (B1: 1.81-1.86 ns) | A port-only hook in a ported file | About 15 lines in `lib/` |

A is the upstream structure and the least code. Chart.js ADR 0020 §13 asks for frame figures only
for a form that changes the structure. A returns to the structure.

**`Path2D`:** without a global `Path2D`, Node.js strokes a line through `beginPath`, `moveTo`,
`lineTo` and `stroke` (38 calls). The port and a browser stroke a `Path2D` (33 calls). A
generator without the recorder gives other calls than the port. Rejected.

**The observations:** all own keys of an element with a primitive value (simplicity draft) couple
the test to internal flags such as `animated`, `_decimated` and `_pointsUpdated`. No probe ran on
the Dart side. Rejected. Only the values that the specs assert: too few values for each chart.
Rejected.

**The option compare:** `orderedEquals` on the option keys fails on the two order cases of
Chart.js ADR 0021 §4, which no protected behavior reads. Rejected.

**The hit queries:** 12 or 15 queries on a few points without the axis option miss the `r` path
(`core.interaction.js:214`) and `includeInvisible`. Rejected.

**The generators:** one generator for all controllers (one data file of 4-6 MB, a rerun writes
all data, the name `controller_reference.mjs` exists for `core.controller`). Rejected. 6
generators (pie folded into doughnut, scatter into line): loses the one-to-one map of the upstream
files. Rejected.

**The data format:** JSON files read with `dart:io` (P2: cold compile equal, decode and walk 42-72
ms against 8-12 ms for the `const` walk; a pure test cannot read a file on the web). Rejected.

**Test 3:** a new generator `theme_charts_reference.mjs` with 8 charts gives a second copy of
data that the reference files already hold. A model of `_resolveElementOptions` in
`theme_light_reference.mjs` resolves without a chart. Rejected.

**The hover oracle:** a themed Dart chart against an unthemed Dart twin compares the port with
itself. The phase 6 precedent compares with the upstream run. Rejected.

**The blue screen read:** a read over transparent pixels (`captureImage` of the host layer or
`toImageSource`) loses precision at the edge pixels: 2026 of 15311 drawn pixels differ for
`#2050c0`. The premultiplied rule `r == 0`, `g == 0`, `b == a` is valid only for pure blue. A scan
of the style setters alone misses a default style that no setter writes. A golden file is
excluded by theming.md §8 item 6. Rejected.

**The spies:**

| Option | 1. Behavior | 2. Performance | 3. Structure | 4. Own code |
|---|---|---|---|---|
| A substitute in the slot (this decision) | The assertions of upstream (probe F P5) | No `lib/` change | No `lib/` change | Test code only, no global state |
| A subclass in `registry.elements.items` | The same | No `lib/` change | No `lib/` change | Global state, `addTearDown`, a flag, one more line before `acquireChart` |
| A by-name `draw` read in `lib/` | The same | +4.4 ns AOT, +4.8 ns wasm for each element draw | A hunk in the hottest loop | More |
| `draw` as a function field | The same | +1.4 ns AOT | Changes each element class | More |
| A static spy hook in `lib/` | The same | Equal | A port-only hook in a ported file | More |

**The lift check:** a permanent "stale block" error in tool 5 (a `blocked: <module>` skip of a
module with the status `ported`). It needs more tool code and a scan of the literals of
`test/port/`. The temporary script covers phase 7. Open item 1.

**The pure files:** a split into a pure file and a chart file. `check:headers` rejects a second
file with the same source, and tool 5 maps one Dart file to one upstream file. Rejected. The
chart cases in `test/port/`: tool 5 then reports them missing. Rejected.

## Consequences

- The reference tests record the real draw of the real controllers: the draw order, the skip of
  hidden elements and of `null` bars, and the active elements on top.
- `DatasetController.ctx` is writable. A write of it changes the context of the next `draw`, as
  upstream.
- The phase 6 reference files grow by about 7.3 % (8,455,931 to 9,069,771 bytes). Their tests
  compare the point draws of the test controllers.
- The 8 controller reference files hold about 4-6 MB, and 89 cases and 89 themed twins add about
  3-5 s of CPU to `test --no-select`, spread over 8 test files. These two figures are estimates
  from E5 and E6, not measurements. The unit of each controller records the real size and time
  in its report.
- The line calls of the generators match the port and a browser.
- 4 pure spec cases (4 more in `element.point`, for its `auto` group) lose the dart2js and
  dart2wasm legs.
- One Jasmine support library replaces the private copies in three spec files.
- The blue screen read is exact for any blue. A leak shows with its setter and its call index.
- No `differences.md` row and no `DIVERGES` marker come from this ADR.

## Open

1. **A permanent stale-block check.** Owner: the phase 8 lead. Trigger: phase 8 lifts the
   `blocked: plugin.*` skips, or a `blocked:` skip of a `ported` module stays after the deletion of
   `lift_check.py`. The check then goes into tool 5, with the literals of `test/port/`.
2. **The position of the fixture tests.** Closed. Chart.js ADR 0029 §2.3 keeps the fixture tests
   in the spec files, so the trigger did not occur. Section 13 item 3 applies as written.
3. **The read of `ctx` for each bar.** Owner: step 7 (Performance) of the phase. Trigger: the
   profile of the bar draw on the Pixel 8a shows the read of `ctx` in the loop. The micro figures
   are mixed: a read before the loop is 0.36 ns faster for each bar on AOT (F P3) and 0.25 ns
   slower on wasm. A change follows the performance rule and records its figures in
   `performance.md`.
4. **Data size.** Owner: the unit agent of each controller. Trigger: a data file above 2.5 MB.
   The generator then writes two data files (section 3 item 6).
5. **The full blue screen and test 3 with the colors plugin.** Owner: the phase 8 lead. Trigger:
   the ports of `plugin.colors`, `plugin.legend`, `plugin.tooltip` and `plugin.title`. The active
   element case waits for `IdentityChartHover` (theming.md §8 item 6).

## Evidence

The probes are in the session scratchpad folder
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/`
(below: `<design>`). They ran Chart.js built at `7169e651` on an x64 build of Node.js v24.12.0
under Rosetta (Chart.js ADR 0010), and Flutter 3.44.9 on macOS. `env-setup.sh` (a working file
of phase 7, not committed) makes the environment again.

- **E1, `Path2D` (fidelity P1b, judge J1):** `<design>/test-strategy-fidelity/path2d_probe.mjs`,
  modes `off` and `on`. `off`: 38 calls, `beginPath`, `moveTo`, `lineTo` x 3, `stroke`. `on`: 33
  calls, `stroke(Path2D)` with 4 commands.
- **E2, all calls through a recording context (performance P1, judge J3):**
  `<design>/test-strategy-performance/probe_all_calls.mjs` and
  `probe/test/rec/recording_platform_test.dart`. 879 calls on both sides, the same names in the
  same order, largest number difference 0, 240 element calls (30 `arc`). The 42 other mismatches
  are the text form of an empty `setLineDash` list in the probe output.
- **E3, the cost of a writable `ctx` (judge J5, fidelity P3, simplicity P1):**
  `<design>/test-strategy-performance/bench/bin/ctx_field_bench.dart` (AOT: final 1.835 ns,
  writable 1.770 ns for each element draw); `<design>/test-strategy-fidelity/ctxbench/bench.dart`
  (AOT and dart2wasm, the table of the read for each draw and for each element);
  `<design>/test-strategy-simplicity/p1_ctx_field/` (ratios 0.95-1.08 on AOT, 0.99-1.02 on wasm).
- **E4, the phase 6 data with the element draws (simplicity P2):**
  `<design>/test-strategy-simplicity/run_phase6_gens.sh` with the mirror tree. Without the switch,
  8 of 8 files are byte-identical with the committed files. With the element draws, 8,455,931
  bytes become 9,069,771 bytes. A second run gives the same SHA-256.
- **E5, the controller observations (fidelity P1, simplicity P2b):**
  `<design>/test-strategy-fidelity/controller_probe.mjs`: 7 chart types, 48-132 hit queries for
  each case with one axis, 85-689 draw calls; two runs give the same 221501 bytes.
  `<design>/test-strategy-simplicity/mirror/packages/flutter_chartjs_port/tool/reference/controller_probe.mjs`:
  17 cases in 236 ms, 9.3-26.1 KB for each case.
- **E6, the data format and the granularity (performance P2, P3, P4):**
  `<design>/test-strategy-performance/probe/run_fmt.sh` (cold compile 4.34-6.56 s for the `const`
  file, equal to the control; walk 8.2-12.3 ms against 42.5-72.2 ms for JSON);
  `probe/test/rec/recording_platform_test.dart` (one case 6-8 ms, a batch 2.2 ms for each chart);
  `probe/test/rec/match_cost_test.dart` (1.3-8.6 ms for 879 calls).
- **E7, the pixel read (performance P5, judge J4):**
  `<design>/test-strategy-performance/probe/test/px/pixels_test.dart`. The paint over an opaque
  blue: 0 of 262144 pixels differ for `#0000ff` and for `#2050c0`, read 0.9-2.9 ms. The read over
  transparent pixels: 0 of 15311 for `#0000ff`, 2026 of 15311 for `#2050c0`. A red grid leak:
  4770 pixels. Fidelity P2 (`<design>/test-strategy-fidelity/blue_blend_probe_test.dart`): a 10 %
  black line gives 512 pixels that differ.
- **E8, the test 3 twin (simplicity P4):** `<design>/test-strategy-simplicity/p3_flutter/light_test.dart`.
  A cartesian chart: 474 calls on each side, 48 differ in the color text only, 0 after the parse.
  A radial chart: 314 calls, 30 differ in the color text only, 0 after the parse.
- **E9, the slot spy (fidelity P5):** `<design>/test-strategy-fidelity/spy_probe_test.dart`. 3
  substitute points in `meta.data`: one update gives the draw counts 1, 1, 1; a second update
  keeps the slots and gives 2, 2, 2.
- **E10, the counts (judge J6, J7, J8):** `grep` of `test(` and `skip:` in the 5 pure spec files:
  `core.layouts` 1 pure case (12 tests, 11 skips), `core.ticks` 2, `element.line` 1, the other two
  0. `doc/upstream/manifest.json`: 0 duplicate full names in the 7 controller spec files.
  `classification/summary.md` §4: 0 skips change from `blocked: controller.*` to a plugin reason.
  `all.json`: 503 `phase7`, 21 legend, 11 tooltip, 1 filler.
- **E11, the upstream lines:** each file:line of the Context, read in `third_party/Chart.js` at
  `7169e65147a47f3720957a6f156a33c838ab9f57`.
