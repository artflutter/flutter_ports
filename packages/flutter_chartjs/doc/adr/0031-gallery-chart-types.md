# Chart.js ADR 0031: Gallery chart types and the stress controller

- Status: accepted (2026-10-21)
- Date: 2026-10-21
- Related: [Chart.js ADR 0009](0009-no-display-only-js-exactness.md) (the protected behavior),
  [Chart.js ADR 0010](0010-js-numeric-semantics.md) (the reference engine),
  [Chart.js ADR 0014](0014-input-events-and-chart-host.md) (the chart host, unbounded constraints),
  [Chart.js ADR 0020](0020-registry-and-component-classes.md) §3, §8 and §13 (the class values,
  `registerables`, a gain that only a microbenchmark measures),
  [Chart.js ADR 0021](0021-typed-options-in-the-resolver.md) §8 (the stress mode `chart`,
  `StressPointController` and its removal in phase 7),
  [Chart.js ADR 0027](0027-parsed-data.md) (the parsed data, a parallel decision of phase 7),
  [Chart.js ADR 0028](0028-controller-interfaces.md) §1 and §2 (the controller interfaces and
  values, a parallel decision of phase 7),
  [porting-flow.md](../porting-flow.md) §1.1 (the performance rule),
  [performance.md](../performance.md) §6, §9 and §11.6,
  decision D3 of the phase 7 progress file (the layout rule of the user),
  `design/gallery/judge.md` (the panel; the progress file and the judge are working files of
  phase 7, not committed)

## Context

Phase 7 ports the eight controllers of `src/controllers/`. Two exit items of the phase prompt
(`kickstart-prompt.md`, a working file of phase 7, not committed) touch the gallery
`apps/chartjs_gallery`:

- "The gallery shows every chart type." Today the home list (`lib/main.dart:11-21`, `:88-94`)
  shows nine disabled tiles with "Not ported yet".
- "`LineController` and `ScatterController` replace `StressPointController` in the Core and Axes
  tabs, in the stress modes and in the frameless benchmark. Keep the phase 5 and phase 6 figures
  comparable." Chart.js ADR 0021 §8 says: "Phase 7 runs the same scenarios again with the ported
  `LineController` and `ScatterController`. Then it removes `StressPointController`."

The panel had five questions:

1. How does each chart type render in the gallery?
2. What replaces `StressPointController`, and how do the before figures stay comparable?
3. Which stress cases do the other six controllers get?
4. How does the gallery follow the members that phase 7 adds to `types.Chart`?
5. How does the layout rule of the user (decision D3, 2026-10-21) apply to the pages that phase 7
   changes?

The line numbers below refer to Chart.js `v4.5.1+7169e651` (`third_party/Chart.js` at
`7169e65147a47f3720957a6f156a33c838ab9f57`). The gallery lines refer to commit `4eda459`.

### Upstream facts

| Source | Fact |
|---|---|
| `docs/charts/bar.md:5-54`, `:304-351`; `bubble.md:5-36`; `doughnut.md:15-47`, `:53-85`; `line.md:5-31`, `:233-285`; `mixed.md:27-70`; `polar.md:7-43`; `radar.md:7-61`; `scatter.md:5-47` | The 13 `chart-editor` blocks of the chart docs. Each has fixed data and `actions: []` (for example `bar.md:51`). |
| `docs/charts/area.md:1-109` | No `chart-editor` block. An area chart is a `line` or `radar` dataset with the `fill` option of the filler plugin. |
| `docs/samples/area/line-boundaries.md:3-120` | The first area sample: `Utils.numbers` data (`:4-18`), `fill: false` at the start (`:29`), four `Fill:` actions and a `Smooth` action, the options `plugins.filler` and `plugins.title` (`:95-113`). |
| `docs/scripts/utils.js:7`, `:13-43`, `:91-104`, `:122-135` | `_seed = Date.now()`, `rand`, `numbers`, `months`, `transparentize` (alpha 0.5), `CHART_COLORS`. |
| `src/core/core.datasetController.js:280-289` | `initialize` warns once (`console.warn`) for a truthy dataset `fill` without the filler. No throw. |
| `src/controllers/controller.doughnut.js:88-89`, `controller.polarArea.js:32-33`, `controller.radar.js:26-27` | The overrides `aspectRatio: 1`. The chart default is 2. |
| `src/core/core.datasetController.js:451-462` | With `parsing: false`, `parse` sets `meta._parsed = data` and `meta._sorted = true` without a check of the order. With parsing, `:475-483` checks the order. |
| `docs/general/data-structures.md:74` | "If parsing is disabled, data must be sorted". |
| `src/core/core.scale.js:283-297` | `getUserBounds`: `minDefined` and `maxDefined` are true only for a user `min` and `max`. `suggestedMin` and `suggestedMax` give `min` and `max`, but not `minDefined` and `maxDefined`. |
| `src/core/core.scale.js:303-325` | `getMinMax` returns the user bounds when both are defined. Else it reads each matching controller, and a suggested bound widens the range. |
| `src/core/core.datasetController.js:622-660` | `getMinMax(scale)` reads only the first and the last parsed item when `meta._sorted` and `scale === meta.iScale`. |
| `src/helpers/helpers.extras.ts:88-133` with `helpers.collection.ts:20-61` | `_getStartAndCountOfVisiblePoints` searches `_parsed` only when `meta._sorted` and the index scale has a user `min` (`minDefined`) or `max` (`maxDefined`). The `last` compare is `ti < value \|\| ti === value && table[index + 1][key] === value` (`helpers.collection.ts:40`). |
| `src/controllers/controller.line.js:35-39`, `:46`, `:63-65`, `:125-136` | Line: option sharing on; the visible range; `showLine: false` sets the line `borderWidth` to 0; `getMaxOverflow` reads the first and the last point. |
| `src/controllers/controller.scatter.js:16`, `:61`, `:156-166` | Scatter: `showLine: false` by default; the visible range; `getMaxOverflow` resolves the options of each point when `showLine` is false. No option sharing (`core.datasetController.js:270`). |
| `src/core/core.controller.js:497-510`, `:536` | `update` notifies `beforeElementsUpdate`, calls `buildOrUpdateElements` and `getMaxOverflow` for each dataset, gives the overflow to the layout as `minPadding` when `layout.autoPadding` is true, and ends with `render()`. |
| `src/core/core.controller.js:611-616` | `_updateLayout` notifies `beforeLayout`, then `layouts.update`. |
| `src/core/core.datasetController.js:12-36`, `:701-705` | `defaultClip` gives no clip only for an overflow of `false`. `_update` calls `getMaxOverflow` again for the clip, also when the dataset option `clip` is set (the argument runs first). |
| `src/core/core.scale.js:457-458` | The auto skip runs when `ticks.display` is true, also on a scale with `display: false`. |
| `src/controllers/controller.bar.js:380`, `controller.bubble.js:38`, `controller.doughnut.js:136` | These controllers set `enableOptionSharing`. Scatter, polar area and radar do not. |
| `docs/general/performance.md:9`, `:33`, `:50-52` | The performance guide: `parsing: false` with the internal format, no animation, `min` and `max` on the scales. |
| `src/index.umd.ts:28` | `Chart.register(controllers, scales, elements, plugins)`. |
| `src/core/core.datasetController.js:687-697` | `getLabelAndValue(index)`: the label and the value texts of the scales. The tooltip of phase 8 shows them. |

### Gallery and port facts

| Source | Fact |
|---|---|
| `apps/chartjs_gallery/lib/demo/stress_chart_config.dart:77-91` | `StressPointField.step` clamps a position to exactly 0 or 1 at each bounce. The x data of the mode `chart` is not sorted. |
| `apps/chartjs_gallery/lib/demo/stress_point_controller.dart` | 369 lines. A port-only `DatasetController` subclass with `@internal` calls. It has a fraction path (no scales) and a scale path. Its `getMaxOverflow` is `false`. |
| `apps/chartjs_gallery/lib/demo/demo_chart.dart:40` | `DemoChart implements types.Chart` with explicit members and no `noSuchMethod`. |
| `apps/chartjs_gallery/lib/demo/core_demo.dart:350`, `:366`, `:432` | The Core tab uses `ChoiceChip`, `SliderControl` and `ToggleChips`, below the chart. |
| `packages/flutter_chartjs/lib/src/canvas/canvas_ui.dart:948-955` | `restore` flushes the circle batch. Thus a dataset clip moves the circle draw into `draw()`. |
| `packages/flutter_chartjs/lib/src/platform/platform.flutter.dart:560-605` | With an unbounded height and a truthy aspect ratio, the bounded width and the ratio give the height (Chart.js ADR 0014). |
| `packages/flutter_chartjs/lib/src/core/core.datasetController.dart:784-789` | The port prints the `fill` warning. |
| `packages/flutter_chartjs/doc/performance.md` §6 | The define `SHARING` of the mode `chart`, and the acceptance of Chart.js ADR 0021 §8: case (a) against the mode `elements` with `LINE=0`. |
| `perf/before/` (a working file of phase 7, not committed) | The before figures at commit `0e0ab93` (raw files). |

### Probe results

The Evidence section gives the commands and the files. The Node.js times are relative only.

- J2 (judge, x64 Node.js, 5000 points, 600 frames with bounces, `update('none')` each frame):

  | Form | Chart area | Dataset clip | x range | Points not drawn | Pixel error against the fraction path |
  |---|---|---|---|---:|---:|
  | x `suggestedMin`/`suggestedMax`, y `min`/`max`, `parsing: false`, `autoPadding: false`, `clip: false`, `ticks.display: false` (this ADR) | 0, 0, 800, 480 | disabled | 0, 1 | 0 | 5.7e-14 |
  | x `max: 1 + 2^-20` | 0, 0, 800, 480 | disabled | 0, 1.00000095 | 0 | 7.6e-4 |
  | x suggested, y bounds, default padding and clip | 5, 5, 795, 475 | left and right 5 | 0, 1 | 0 | 5.7e-14 |
  | bounds on x and y, `parsing` on | 5, 5, 795, 475 | 0 on each side | 0, 1 | 0 | 5.7e-14 |
  | bounds on x and y, `parsing: false` | 0, 0, 800, 480 | disabled | 0, 1 | 5000 (line), 2500 (scatter) | — |

- G1 (Dart): the phase 5 config against hidden unit scales with `autoPadding: false` and
  `clip: false`: the chart area `0, 0, 800, 480` on both sides, the pixels equal within
  5.7e-14 px. Without `autoPadding: false`, the area is `5, 5, 795, 475`.
- G2 (Dart, 5000 points, 600 frames): `parsing: false` with x `max: 1` gives up to 1250 points
  with `skip` or a wrong pixel. With parsing, or with a bound that no point reaches, 0.
- G4 (Dart): `ticks.display: false` on the two hidden scales saves 0.03-0.07 ms of each update.
- G5 (Dart): the `getMaxOverflow` loop of scatter adds 0.20 / 0.93 / 4.69 ms to an update of 1000
  / 5000 / 20000 points without sharing (JIT). This is upstream work that `StressPointController`
  did not do.
- G3 and J3 (Dart, `flutter test`, the gallery code): `update('none')` at 20000 points with
  sharing: the phase 5 fraction path 0.94-0.99 ms, hidden unit scales with `parsing: false`
  1.59 ms, the same with `parsing: true` 6.4-6.99 ms. The draw after a parsed update: 4.80 ms
  against 3.93 ms (garbage collection). The draw of the hidden-scale form equals the phase 5 draw
  (3.69 against 3.71 ms, JIT; 3.61 against 3.65 ms, wasm).
- G6 (Dart JIT): a dataset clip of 5 px in the mode `axes` moves the circle flush into `draw()`.
  `drawMs` grows by 24 % at 20000 points (3.91 to 4.84 ms). The sum of draw and end changes by 3 %.
- G7 (Dart JIT): the timing plugin adds no time outside the spread (20000 points: update 1.516
  against 1.492 ms, draw 3.806 against 3.858 ms).
- G8 (x64 Node.js): with `parsing: false`, a radar chart has `iScale` and `vScale` both `r`.
  `getMinMax(r)` then reads only the first and the last value: the range is wrong. `min` and `max`
  on `r` give the correct range.
- E5b (x64 Node.js): a hidden category axis with `ticks.display` true: 24.0 ms for an update of
  5000 bars, 9.4 ms without the ticks. An indexable `backgroundColor` of 7 colors: a doughnut of
  1000 arcs updates in 12.5 ms, with one color in 1.0 ms.
- P2 (x64 Node.js): the 13 docs configs build with the controllers, elements and scales of phase 7
  and no plugin. The Area config with `fill: 'origin'` gives the canvas calls of `fill: false` and
  one warning. With all registerables, the filler draws the area (46 against 58 `lineTo` calls).
- P4 (x64 Node.js): `Utils.numbers` of `line-boundaries.md:4-10` with the seed 2026 gives
  `[97.81, -42.3, 84.05, -46.6, -31.77, 12.48, -59.53, -0.87]`.

## Decision

### 1. The chart type pages

1. Each of the nine list entries opens one generic page, `ChartTypePage`. A page shows the
   `chart-editor` blocks of `docs/charts/<stem>.md` at the pin as its variants, in file order. The
   stems are the docs file names: `area`, `bar`, `bubble`, `doughnut`, `line`, `mixed`, `polar`,
   `radar`, `scatter`.

   | Entry | Variant: source | Chart type |
   |---|---|---|
   | Area | `origin`: `docs/samples/area/line-boundaries.md:3-120`, with `fill: 'origin'` | line |
   | Bar | `vertical`: `bar.md:5-54`; `horizontal`: `bar.md:304-351` | bar |
   | Bubble | `bubble`: `bubble.md:5-36` | bubble |
   | Doughnut and Pie | `doughnut`: `doughnut.md:15-47`; `pie`: `doughnut.md:53-85` | doughnut, pie |
   | Line | `line`: `line.md:5-31`; `vertical`: `line.md:233-285` | line |
   | Mixed | `mixed`: `mixed.md:27-70` | scatter with a bar and a line dataset |
   | Polar Area | `polar`: `polar.md:7-43` | polarArea |
   | Radar | `radar`: `radar.md:7-61` | radar |
   | Scatter | `scatter`: `scatter.md:5-47` | scatter |

2. The configs are the docs blocks unchanged, with three exceptions:
   - The strings of `Utils.months({count: n})` replace the call (`utils.js:91-104`).
   - Area: the fixed numbers of P4 replace `Utils.numbers`. The dataset has `fill: 'origin'`, not
     the first state `fill: false`. The colors are the values of `CHART_COLORS.red` and
     `transparentize(CHART_COLORS.red)`: `rgb(255, 99, 132)` and `rgba(255, 99, 132, 0.5)`. The
     page has no actions.
   - The page adds the option `onHover` (item 5).
3. The page has no actions. The docs chart blocks have `actions: []`. The default animation shows
   the update path at the start, and the hover shows the hover options.
4. The page does not set `maintainAspectRatio` or a host height. The host is in a scroll view, so
   it gets an unbounded height. The platform then gives the height from the width and the
   upstream aspect ratio: 2, or 1 for doughnut, pie, polar area and radar (Chart.js ADR 0014,
   `platform.flutter.dart:560-605`). The page body caps its width at 600 logical pixels.
5. The readout shows the datasets (`meta.type` and the element count of each dataset) and the
   hover: for each active element `d<dataset>#<index>` and the text of
   `controller.getLabelAndValue(index)`. A `ValueNotifier` that `onHover` changes rebuilds only the
   readout. The text is the text of the tooltip of phase 8.
6. A tap on a variant makes a new chart (a new key of the host), as a docs page makes a new chart
   for each block.
7. Area renders its line in phase 7. Upstream without the filler draws the line and warns once
   for each dataset with a truthy `fill` (`core.datasetController.js:280-289`). The Radar page
   (`fill: true`, `radar.md:22`, `:32`) warns the same. Phase 8 registers the filler, and the same
   configs then fill with no gallery change.
8. Each config file is a copy of upstream docs code. It starts with the rule-2 header of AGENTS.md,
   for example `// Ported from Chart.js v4.5.1+7169e651 docs/charts/bar.md (MIT, Chart.js
   Contributors).` `check:headers` does not read the gallery. `REUSE.toml` already gives the
   Chart.js notice for `apps/chartjs_gallery/lib/**`.

### 2. The list, the status and the keys

1. Each tile of the list is enabled and opens its page. A type that renders in full has the icon
   `check_circle_outline` and the docs source as its subtitle. A partial type has the icon
   `timelapse` and a static note. After phase 7, only Area is partial: "Line only: the fill needs
   plugin.filler (phase 8)". Phase 8 removes the note.
2. The status is a static field of the entry. The home page makes no chart.
3. The keys:

   | Control | `ValueKey` |
   |---|---|
   | List tile | `gallery.type.<stem>` |
   | Variant segment | `type.<stem>.variant.<variant>` |
   | Chart host | `type.<stem>.host` |
   | Readout | `type.<stem>.readout` |

### 3. The stress chart of line and scatter

1. The gallery deletes `lib/demo/stress_point_controller.dart`. The before side of an A/B is a
   worktree of commit `0e0ab93`, which has the class.
2. The stress mode `chart`, its cases (a), (b) and (c), `CALL=animate`, and the benchmark cases
   `chart.a`, `chart.b` and `chart.c` use this config:
   - `type: 'line'` with the dataset option `showLine: false`, or `type: 'scatter'`;
   - the chart options `parsing: false`, `layout.autoPadding: false`, `events: []`,
     `maintainAspectRatio: false`, and `animation: false` (or the loop of `CALL=animate`);
   - the dataset option `clip: false`, and the colors, the border and the radius of phase 5;
   - two hidden linear scales:
     `x: {type: 'linear', display: false, ticks: {display: false}, suggestedMin: 0, suggestedMax: 1}`
     and `y: {type: 'linear', display: false, ticks: {display: false}, min: 0, max: 1}`.
3. The reasons, in the order of the decision protocol:
   - Behavior: all points draw, and each pixel equals the pixel of the phase 5 fraction path within
     5.7e-14 px (J2). The data is not sorted, which `data-structures.md:74` forbids with
     `parsing: false`. With these bounds, no code path reads the order: x has no `minDefined` or
     `maxDefined`, so `_getStartAndCountOfVisiblePoints` gives start 0 and count N
     (`helpers.extras.ts:94-133`). The x range is `[0, 1]`, because `suggestedMin: 0` and
     `suggestedMax: 1` contain each data value (`core.scale.js:303-325`). y has user bounds, so
     `getMinMax` does not read the data (`:307-309`). The chart has `events: []`, so no
     interaction search runs. A user `max` on x drops points (J2, last row).
   - Performance: the draw equals the phase 5 draw (G3). The update costs 0.14-0.6 ms more than
     phase 5 at 1000-20000 points (G3, J3): the layout of the two hidden scales and
     `getPixelForValue`. Parsing costs 4.4 times this form at 20000 points and moves garbage
     collection into the next draw (J3). `ticks.display: false` skips the auto skip of the hidden
     scales (`core.scale.js:457`, G4). `autoPadding: false` keeps the phase 5 chart area (G1).
     `clip: false` keeps the phase 5 and phase 6 split of `drawMs` and the end of the recording
     (G6).
   - Structure: each key is an upstream option. The performance guide names `parsing: false`,
     `min` and `max`, and no animation (`docs/general/performance.md:9`, `:33`, `:50-52`).
4. The define `SHARING` stays as an alias of the define `TYPE` (section 5). `SHARING=1` gives
   `TYPE=line` (option sharing on, `controller.line.js:35-39`). `SHARING=0` gives `TYPE=scatter`
   (no sharing). The before command lines of `performance.md` §6 stay valid. The `STRESS` and
   `BENCH` lines keep the key `sharing` and get the key `type`.
5. The acceptance of Chart.js ADR 0021 §8 (case (a) against the mode `elements` with `LINE=0`)
   stays valid: the line has `borderWidth: 0` (`controller.line.js:63-65`), so the draw has only
   the point calls.

### 4. The other users of `StressPointController`

| Use | Config after phase 7 | Reason |
|---|---|---|
| Stress mode `axes` and the `axes.*` cases | `type: 'line'`, `showLine: false`, `parsing: false` (the data is sorted), `layout.autoPadding: false`, `clip: false`. The visible scales of the scene do not change. | The phase 6 chart area and the phase 6 split of `drawMs` stay (G6). |
| Core tab | `type: 'line'` with the line shown (the default), default parsing (the data is sorted), the hidden scales of item 3.2 without `ticks` (the function `unitScales`), the padding of 20 px and the value-lines plugin as today. | A demo shows the upstream line chart. It is not a source of figures. |
| Axes tab | `type: 'line'` with the line shown. The data and the scale options do not change. | As the Core tab. |
| `test/chart_canvas_test.dart` | `type: 'line'`. | — |

- `registerGalleryComponents` moves to the new file `lib/demo/gallery_components.dart`. It
  registers `registerables` once (`src/index.umd.ts:28`). After phase 7, `registerables` has the
  controllers. No gallery class extends `DatasetController` after the change.

### 5. The chart types in the stress mode `chart`

1. The mode `chart` gets the define `TYPE` and a `type` line in the stress tab. The values are the
   eight controllers: `line`, `scatter`, `bar`, `bubble`, `doughnut`, `pie`, `polarArea`, `radar`.
   The default is `line`. No new `StressMode` value.
2. `line` and `scatter` use the config of section 3. The other types use the default parsing of
   their controller, hidden scales with user bounds, and one color:

   | Type | Data (N items, from `StressPointField`) | Scales | Counts |
   |---|---|---|---|
   | bar | N labels `Point <i>`, N numbers `y` | x category, y linear `min: 0, max: 1` | 1000, 5000, 20000 |
   | bubble | `{x, y, r}` with `r = 2 + 4 * (vx / 0.3)^2` | x and y linear `min: 0, max: 1` | 1000, 5000, 20000 |
   | doughnut, pie | N labels, N numbers `0.05 + 0.95 * y` | none | 100, 1000, 5000 |
   | polarArea | as doughnut | r radialLinear `min: 0, max: 1` | 100, 1000, 5000 |
   | radar | N labels, N numbers `y` | r radialLinear `min: 0, max: 1` | 100, 1000, 5000 |

   - Each scale has `display: false` and `ticks: {display: false}`. The auto skip of a hidden
     category axis with ticks costs 2.5 times the update of 5000 bars (E5b). The mode `axes`
     measures the label path already (`performance.md` §11.6).
   - The `r` bounds are necessary: they give the correct range for any order of the data (G8),
     and `getMinMax` then reads no data.
   - The default parsing measures the parse of each controller, which Chart.js ADR 0027 changes.
     The timing part `elements` (item 6) shows it apart.
   - One color: `backgroundColor` `rgba(54, 162, 235, 0.45)`, `borderColor` `#36A2EB`,
     `borderWidth` 1. An indexable color puts the resolver cost of each element in front of the
     controller cost (E5b). `SCRIPTABLE=1` gives that path for each type.
   - The radial types stop at 5000, as the mode `arcs` does.
   - The other options are the upstream defaults (padding, clip). These cases have no before
     figures.
3. Each update writes the moved values of the field into the data in place, as the phase 5 scene
   does.
4. `CALL` takes `draw`, `update` and `animate` for each type. `SCRIPTABLE` applies to each type.
5. The new define `SHOWLINE=1` shows the line of `line` and `scatter`. Another type, or another
   mode, with `SHOWLINE=1` throws an `ArgumentError` at the start.
6. The define rules:
   - `TYPE` with a `MODE` other than `chart` throws an `ArgumentError`.
   - Without `TYPE`, `SHARING=0` gives `scatter`, and `SHARING=1` or no `SHARING` gives `line`.
   - With `TYPE` and `SHARING`, `SHARING=1` needs `TYPE=line` and `SHARING=0` needs
     `TYPE=scatter`. Another pair throws an `ArgumentError`.
7. The `STRESS` line of the mode `chart` has the keys `type`, `sharing` (the
   `enableOptionSharing` of the controller), `scriptable`, `showLine` (only when true), and the
   parts `elementsMs`, `layoutMs`, `datasetsUpdateMs` and `datasetsDrawMs`.

### 6. The timing parts

1. `StressAxesTiming` becomes `StressChartTiming` in the new file `lib/demo/stress_timing.dart`.
   It runs in the modes `chart` and `axes` and in each case of the frameless benchmark (G7: no
   measurable cost).
2. It gets a fourth part, `elements`: `beforeElementsUpdate` to `beforeLayout`
   (`core.controller.js:497-510`, `:611-612`). The part has `buildOrUpdateElements` of each dataset
   (the parse) and the first `getMaxOverflow`. The second `getMaxOverflow` stays in
   `datasetsUpdate` (`core.datasetController.js:704`).
3. The other parts do not change: `layout`, `datasetsUpdate` and `datasetsDraw`.

### 7. The frameless benchmark

1. The cases `chart.a`, `chart.b` (sharing on and off) and `chart.c` keep their names and their
   keys, and get the key `type` (`line` or `scatter`) and the four parts. The `before` lines join
   on `mode`, `case`, `sharing`, `scriptable` and `n`.
2. The new cases `chart.<type>` for `bar`, `bubble`, `doughnut`, `pie`, `polarArea` and `radar`,
   each with `draw` and `update`, come after all the `axes` cases. A default run then times the
   before cases first.
3. `ChartBenchCase` gets `counts`, the point counts of the case. Without the define `N`, each case
   runs its own counts. With `N`, each case runs the counts of `N`.

### 8. The A/B of step 7

Step 7 measures three sides of the line and scatter cases:

- A: commit `0e0ab93` (the phase 5 config, the fraction path).
- A': commit `0e0ab93` with the bridge patch of the spec: the scales, the padding and the clip of
  section 3 on `StressPointController` (its scale path). The patch changes only
  `lib/demo/stress_chart_config.dart`.
- B: the phase 7 tree.

A to A' is the cost of the hidden scales. A' to B is the cost of the ported controllers. Each pair
follows the measurement method of the phase prompt (ABBA order, gates, bootstrap interval). The
`elements` part and the upstream ratios of the probes (G5: the `getMaxOverflow` loop of scatter)
name the upstream part of each difference.

### 9. `types.Chart` and the analyzer

1. `DemoChart` keeps explicit members. It does not get `noSuchMethod`. A missing member is then a
   compile error of the `analyze` gate, not a `NoSuchMethodError` at run time.
2. The port unit that adds a member to an interface that a gallery class implements also adds the
   member to that class, in the same change. For the members of Chart.js ADR 0028, `DemoChart`
   gives: `isDatasetVisible` false, `getVisibleDatasetCount` 0, `toggleDataVisibility` no
   action, `update` a call of `render()` (upstream `update` ends with `render()`,
   `core.controller.js:536`), `legend` Dart `null`. The signatures are those of Chart.js ADR 0028.
3. `dart run melos run analyze` covers `apps/chartjs_gallery` (root `pubspec.yaml`, `workspace`).
   Each port-wave prompt names `apps/chartjs_gallery/lib/demo/demo_chart.dart` as a file to check.
4. `_DemoChart` and `_DemoScale` of `lib/demo/ticks_demo.dart` keep `noSuchMethod`.

### 10. The layout rule

1. The rule applies to each page that phase 7 adds or changes: the nine type pages, the stress
   tab, the Core tab and the Axes tab.
2. Each parameter is a full-width `SegmentChoice` or `SegmentToggles` of
   `lib/demo/demo_controls.dart`, with short text or icons. A command (randomize, add, remove) is
   a segment of a `SegmentToggles` that never stays selected. These pages have no `ChoiceChip`,
   `FilterChip`, `ToggleChips`, `SliderControl`, `PopupMenuButton`, `DropdownButton` or horizontal
   `Scrollable`.
3. The order is: the controls, one control on each line, then the chart, then the readout, then
   the help text. The Axes tab is the exception of item 7.
4. The chart host is fully in view after the first frame at 412 x 915 logical pixels (the Pixel 8a
   of the user) on each page of item 1. The type pages are also fully in view at 360 x 640. A
   widget test pins each case. The test is the gate, not a count of lines.
5. `SegmentChoiceItem` gets the field `IconData? icon`. A segment with an icon shows the icon only,
   with the `ValueKey` of its item on the icon, as `SegmentToggles` does.
6. The pages:
   - Type pages: at most one control line (the variant), then the chart.
   - Stress tab, mode `chart`: the start and options line (the toggles `spin`, `scriptable` and
     `showLine`; the `sharing` toggle goes), `mode`, `type` (8 icon segments), `N`, `M`, `call`.
     That is six lines. The mode `axes` has seven today, in view on the Pixel 8a.
   - Core tab: all controls above the chart: `mode` (6 segments), `axis` (3), one
     `SegmentToggles` line (`intersect`, `animation`, the two datasets, and the commands
     `randomize`, `add` and `remove`), `hover` (0, 200, 400, 1000, 2000 ms), `update` (0, 400,
     1000, 2000, 3000 ms). The text of the card goes after the readout.
7. The Axes tab has 20 parameters (`lib/demo/axes_demo.dart:549-735`): the two scale types, the
   two positions, `bounds`, the time unit, the locale, seven toggles, four sliders, `ticks.align`
   and the point count. They do not fit above an in-view chart. It gets `x`, `y`
   and `N` above the chart, and the other parameters after the readout, each a full-width
   `SegmentChoice` or `SegmentToggles` line. This departs from item 3. The maintainer decides
   (Open).

### 11. The questions of the panel

| Question | Sections |
|---|---|
| 1. Each chart type renders | 1, 2 |
| 2. The replacement of `StressPointController` | 3, 4, 8 |
| 3. The stress cases of the other controllers | 5, 6, 7 |
| 4. `types.Chart` and the analyzer | 9 |
| 5. The layout rule | 10, Open |

## Alternatives considered

- **Pages with the sample actions** (Randomize, Add Data, a `fill` control on Area). The docs chart
  blocks have `actions: []`. The actions need a port of `docs/scripts/utils.js` and an action line
  on each page. The Area `fill` control changes no pixel in phase 7 (P2). Rejected: more code for
  no more upstream behavior.
- **Area pending until phase 8.** The exit item "the gallery shows every chart type" fails.
  Rejected.
- **Area at `fill: false`** (the first state of the sample). It gives the same pixels as
  `fill: 'origin'` in phase 7, but phase 8 then shows no area. Rejected: `fill: 'origin'` shows the
  area config that phase 8 completes with no change.
- **A port-only fill in the gallery.** Not upstream behavior, and phase 8 deletes it. Rejected.
- **A fixed host height with `maintainAspectRatio: false`.** Simple, but it replaces the upstream
  aspect of each type. Rejected: the unbounded host height gives the docs aspect with no code.
- **A `fill` status that the tile reads from the registry.** It updates itself in phase 8, but it
  needs a list of plugin ids for each entry. Rejected: a static note is one string.
- **Keep `StressPointController`.** Contrary to Chart.js ADR 0021 §8 and to the exit item. The
  before figures come from the worktree of `0e0ab93`. Rejected.
- **Parsing on, `min` and `max` on x and y.** The only form inside `data-structures.md:74`. All
  points draw. But the parse costs 4.4 times the chosen update at 20000 points in Dart and moves
  garbage collection into the next draw (J3). The overflow of 5 px changes the chart area, and the
  dataset clip moves the circle flush into `draw()` (J2, G6). The before figures do not compare.
  Rejected on rank 2.
- **`parsing: false` with `min` and `max` on x.** The search of `_getStartAndCountOfVisiblePoints`
  on unsorted data drops up to all points (J2, G2). Rejected on rank 1.
- **x `max: 1 + 2^-20`.** All points draw, with a pixel offset up to 7.6e-4 px (J2). The
  suggested bounds give exact pixels at the same cost. Rejected.
- **Suggested x and bounded y with the default padding and clip.** Exact pixels, but the chart area
  is 790 x 470. The clip alone makes `drawMs` 24 % larger at 20000 points (G6). Rejected on rank 2
  (comparability).
- **Sorted x with only y moving.** It changes the phase 5 scene. Rejected.
- **One `StressMode` for each type, or a new mode `type`.** Eleven or more segments in the mode
  line, or a second chart mode with its own keys. Rejected: the chart type is the upstream
  discriminator of one chart path.
- **`parsing: false` with the internal format for the other types.** It skips the parse that phase
  7 ports and that a user chart runs. Rejected for these cases. The line and scatter cases keep
  `parsing: false` for the comparability of section 3.
- **The docs data shapes with visible scales for the type cases.** The label work of the scales
  dominates (P3: 5020 `measureText` calls for a radar of 5000). The mode `axes` measures that path.
  Rejected.
- **Remove the define `SHARING`.** It breaks the before command lines. Rejected: it stays as an
  alias.
- **`noSuchMethod` in `DemoChart`.** A missing member then throws at run time in the animator.
  Rejected.
- **A fixed budget of four control lines above the chart.** The stress tab has seven lines today
  and is in view on the Pixel 8a. Rejected: the in-view test is the gate.
- **The Core tab restyle in a later change.** The Core tab changes in phase 7, and the rule of the
  user covers it. Rejected.
- **`SegmentChoice.iconOf`.** A second way to give an icon. Rejected: the field `icon` of the item
  has the form of `SegmentToggleItem`.

## Consequences

- The gallery shows nine enabled chart types. Area is partial until phase 8.
- The gallery has no port-only controller. Each chart of the gallery runs a ported controller.
- The line and scatter cases of phase 7 measure the same scene, chart area and draw split as phase
  5 and phase 6. Their update adds the upstream work of the hidden scales and of the controllers.
  The three-side A/B separates the two.
- Six new chart types in the stress tab and 12 new benchmark cases give the step 7 figures of each
  controller. A default benchmark run is longer.
- The data of the line and scatter cases is not sorted, outside the docs contract. A test pins
  that all points draw (section 3).
- The selector `chart` of the benchmark selects 16 cases. A before/after run of the cases of
  Chart.js ADR 0021 §8 uses `CASES=a,b,c`.
- Each port unit that changes a type interface also changes `DemoChart`.
- The Core tab loses its chips and sliders. The slider keys `core.hover.duration` and
  `core.animation.duration` become the prefixes of segment keys.
- The Area and Radar pages print the `fill` warning in phase 7.

## Open

- **The Axes tab split** (section 10.7). Owner: the maintainer. Trigger: the review of the gallery
  step of phase 7, before the gallery commit. Until then, the split of section 10.7 applies.
- **The plugins of phase 8 in the stress and benchmark charts.** When phase 8 adds the plugins to
  `registerables`, the legend displays by default and changes the chart area. Owner: the phase 8
  plugins panel. Trigger: the first phase 8 change that adds a plugin to `registerables`. The
  candidate form is the upstream opt-out `options.plugins.legend.display: false` in the stress and
  benchmark configs. The tooltip needs nothing (`events: []`).
- **The Area `fill` control.** Owner: the phase 8 filler port. Trigger: the filler port. Phase 8
  can add the other fill modes of `line-boundaries.md:40-75` as variants and removes the note.

## Evidence

- Upstream sources: the file:line table of the Context, read at `7169e651`.
- Judge (`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/gallery-judge/`):
  - J1: `p1_count.rerun.out`, `p1_trap.rerun.out` (re-run of P1, x64 Node.js v24.12.0 under
    Rosetta).
  - J2: `judge_form.mjs <dist>`, output `judge_form.out`.
  - J3: `probe_chart_mode2_jit.rerun.txt` (re-run of G3, `flutter test`, `ROUND=9`).
- Performance draft (`.../scratchpad/design/gallery-performance/`, `README.txt` gives each
  command): G1 `repo/apps/chartjs_gallery/test/probe_chart_mode_test.dart`; G2
  `probe_sorted.txt`; G3 `probe_chart_mode2_jit.txt`, `probe_chart_mode2_wasm.txt`; G4
  `probe_chart_mode_jit.txt`, `probe_chart_mode_wasm.txt`; G5 the `epsOverflow` rows of G3; G6
  `probe_clip_jit.txt`; G7 `probe_plugin_jit.txt`; G8 `parsing_probe.out`,
  `parsing_probe.rerun.out`, `radar_probe.mjs`; the bridge patch `bridge-0e0ab93.patch` (the form
  `1 + 2^-20`; the spec gives the patch of this ADR).
- Fidelity draft (`.../scratchpad/design/gallery-fidelity/`, `README.md`): E1-E4 `positions.out`,
  `minmax.out`, `calls.out`, `time2.out`, `time3.out`; E5b `types2.out`; E5c `types3.out`; E6
  `docs.out`; E8 `axes.out`; E9 `utils_values.out`.
- Simplicity draft (`.../scratchpad/design/gallery-simplicity/`): P1 `p1_*.out`; P2 `p2_none.out`,
  `p2_all.out`; P3 `p3_types.out`; P4 `p4_area_numbers.out`.
- The Chart.js build at the pin: `.../scratchpad/env/chartjs-build/dist/chart.js`.
- The drafts and the judge: `design/gallery/` (working files of phase 7, not committed).
