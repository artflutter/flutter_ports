# Gallery chart types and the stress controller: fidelity draft

- Panel: "Gallery chart types and the stress controller" (the future Chart.js ADR 0031, proposed).
- Lens: fidelity first. The upstream behavior and the upstream structure get the most weight. This
  draft accepts a cost only when the evidence shows that the cost is small, or when the cost is
  upstream work that a real Chart.js chart of the same config also does.
- Pin: Chart.js `v4.5.1+7169e651`. "src/" is `third_party/Chart.js/src/`, "docs/" is
  `third_party/Chart.js/docs/`. "Gallery" is `apps/chartjs_gallery/`.
- Scratch evidence: `/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/gallery-fidelity/`
  (below: `$EV`). `$EV/README.md` gives the commands.

## 0. Evidence

All probes run in the x64 Node.js v24.12.0 under Rosetta, against the Chart.js build at the pin.
They load the build with `loadChartJs` of `tool/reference/scale_chart_common.mjs` and draw on its
mock context (`fakeCanvas`). They register the controllers, the elements and the scales, and no
plugin: the registry of phase 7. A second run of each deterministic probe in this session gave
identical output (`$EV/rerun-*.out`).

| Id | Script | Output | Topic |
|---|---|---|---|
| E1/E2 | `$EV/probe.mjs positions` | `$EV/positions.out` | point pixels of each stress config against the fraction path, drawn points |
| E2b | `$EV/probe_minmax.mjs` | `$EV/minmax.out` | `parsing: false`, unsorted x, x `min`/`max`: the visible range |
| E3 | `$EV/probe.mjs calls` | `$EV/calls.out` | calls of `parse`, `resolveDataElementOptions`, `getMaxOverflow` and `PointElement.size` in one `update('none')` |
| E4 | `$EV/run_time.sh`, `$EV/probe_time.mjs` | `$EV/time2.out`, `$EV/time3.out` | Node medians of `update('none')` and `draw()`, 3 processes for each cell |
| E5b | `$EV/probe_types2.mjs` | `$EV/types2.out` | a hidden category axis, an indexable `backgroundColor` |
| E5c | `$EV/run_types3.sh`, `$EV/probe_types3.mjs` | `$EV/types3.out` | the type scenes of question 3 |
| E6 | `$EV/probe.mjs docs` | `$EV/docs.out` | the `docs/charts/*.md` configs and `docs/samples/area/line-boundaries.md` without plugins |
| E8 | `$EV/probe_axes.mjs` | `$EV/axes.out` | the mode `axes` with `line` and `scatter` against a scale-path controller |
| E9 | `$EV/utils_values.mjs` | `$EV/utils_values.out` | the values of `Utils.numbers` for a fixed seed |

The Node times are relative only: x64 under Rosetta, a mock canvas without raster. They rank
upstream costs. They are not phone figures. Step 7 measures the port on the Pixel 8a.

**E4: the stress configs of question 2** (Node, the median of 3 processes, ms; `update` is
`update('none')` without its draw). "fraction" is the fraction path of `StressPointController`
in JavaScript (sharing on), "fractionNoShare" the same with `optionSharing: false`. P2 is the
choice of question 2 (parsing on, `min`/`max` on both axes). P1s is `parsing: false` with
unsorted data and `suggestedMin`/`suggestedMax` on x (outside the contract of
`docs/general/data-structures.md:74`).

| Variant | update 1000 | 5000 | 20000 | draw 1000 | 5000 | 20000 |
|---|---:|---:|---:|---:|---:|---:|
| fraction (sharing) | 0.12 | 0.20 | 0.56 | 0.38 | 1.72 | 6.84 |
| `line`, P2, `showLine: false` | 0.64 | 0.84 | 2.33 | 0.36 | 1.72 | 7.20 |
| `line`, P1s, `showLine: false` | 0.59 | 0.70 | 1.40 | 0.34 | 1.80 | 7.13 |
| `line`, P2, line shown | 0.69 | 0.90 | 2.27 | 0.51 | 2.02 | 9.17 |
| fractionNoShare | 0.24 | 0.68 | 2.38 | 0.39 | 1.67 | 7.72 |
| `scatter`, P2 | 0.95 | 2.72 | 9.01 | 0.30 | 1.79 | 6.71 |
| `scatter`, P1s | 0.93 | 2.27 | 8.06 | 0.32 | 1.67 | 7.47 |

- The draw does not change: `DatasetController.draw` (src/core/core.datasetController.js:712-740)
  draws the same points. The line element of `showLine: false` draws nothing
  (src/elements/element.line.js:431: `options.borderWidth` is 0, src/controllers/controller.line.js:63-65).
- `time3.out`: hidden ticks (`ticks.display: false`) save 0.13 ms of the `line` update at 1000 and
  nothing at 20000.

**E3: one `update('none')` at N = 1000.**

| Variant | sharing | `parse` | `parseObjectData` | `getMaxOverflow` | `resolveDataElementOptions` | `PointElement.size` |
|---|---|---:|---:|---:|---:|---:|
| fraction | true | 1 | 0 | 2 | 1 | 1000 |
| fractionNoShare | false | 1 | 0 | 2 | 1001 | 1000 |
| `line` P2 | true | 1 | 1 | 2 | 5 | 1004 |
| `scatter` P2 | false | 1 | 1 | 2 | 3001 | 3000 |

The 1000 calls of `size` in each row come from the draw inside `update` (the point draw tests
`_isPointInArea` with the size). The `scatter` row adds 2000 resolves and 2000 sizes: its
`getMaxOverflow` loops over all points when `showLine` is false
(src/controllers/controller.scatter.js:160-165), and `Chart.update` calls it once
(src/core/core.controller.js:507) and `_update` once more (src/core/core.datasetController.js:704).
Without sharing, each resolve returns a copy (`cloneIfNotShared`, :809).

## 1. Each chart type renders

### 1.1 What the upstream gives

- `docs/charts/<type>.md` starts each chart type with one or two `chart-editor` blocks. Each block
  has fixed data and `actions: []`. The blocks are: `bar.md:5-54` (vertical) and `:304-351`
  (horizontal), `bubble.md:5-36`, `doughnut.md:15-47` (doughnut) and `:53-85` (pie),
  `line.md:5-31` (line) and `:233-285` (`indexAxis: 'y'`), `mixed.md:27-70`, `polar.md:7-43`,
  `radar.md:7-61`, `scatter.md:5-47`. `area.md` has no block: an area chart is a `line` or `radar`
  dataset with the `fill` option of the filler plugin (`area.md:3-7`).
- `docs/samples/area/*.md` has the area samples. Each one uses the filler. `line-boundaries.md:3-120`
  starts with `fill: false` (:29) and changes `fill` through its actions (:39-75).
- The blocks use `Utils.months` (`docs/scripts/utils.js:91-104`). The area sample also uses
  `Utils.numbers`, `Utils.CHART_COLORS` and `Utils.transparentize` (:20-42, :122-135).
- E6: each `docs/charts` config builds without plugins, with the element counts line 7, bar 7,
  bubble 2, doughnut 3, polarArea 5, radar 7, mixed 4 + 4 (controllers `bar` and `line`), and
  line-boundaries 8. `radar.md` sets `fill: true`. Without the filler, upstream logs one
  `console.warn` (src/core/core.datasetController.js:286-289) and draws no fill. It does not
  throw. The same holds for `fill: 'origin'` in line-boundaries (E6, `afterFillOrigin`).

### 1.2 Options

| Option | Behavior (1) | Performance (2) | Structure (3) | Own code (4) |
|---|---|---|---|---|
| A. The `docs/charts` blocks, verbatim as Dart Map literals, one Dart file for each docs file; Area shows `line-boundaries` at its first state | same configs as upstream; phase 8 adds legend, title and fill with no change of the configs | at most 8 elements; no cost | mirrors `docs/` | Utils port (about 120 lines) and 13 configs |
| B. The `docs/samples/other-charts` samples with their actions | same configs, but 9 actions for each sample (`doughnut.md` has 9) | no cost | mirrors `docs/` | about 4 times the code; the actions do not fit above the chart on a phone |
| C. Own configs for each type | not the upstream configs | no cost | none | less code |
| D. Area: a port-only fill emulation | not upstream behavior | — | none | own code that phase 8 deletes |
| E. Area stays pending until phase 8 | — | — | — | no code; the exit criterion "The gallery shows every chart type" fails for Area |

**Choice: A**, with Area as the first state of `line-boundaries` (`fill: false`). At this state,
upstream with the filler draws the same pixels as the phase 7 registry: the dataset has no fill.
The `title` plugin option of the sample (`line-boundaries.md:104-107`) is inert until phase 8.
Phase 7 shows only the `Randomize` and `Smooth` actions of the sample. The four `Fill:` actions
(:39-75) change nothing without the filler. Phase 8 adds them as one `fill` control.

### 1.3 Page structure

One page widget for all types: `ChartTypePage`. The order follows the rule of question 5:

1. The app bar: the type name (`Bar`).
2. Controls, one control on each line, only when the type has them:
   - `sample` (`SegmentChoice`): only for the types with two docs blocks: Bar (`vertical`,
     `horizontal`), Doughnut and Pie (`doughnut`, `pie`), Line (`line`, `vertical`).
   - Area: one line with the `Randomize` command and the `Smooth` toggle (`SegmentToggles`), as
     the stress tab puts the start command and the toggles on one line.
3. The chart: a `ChartCanvas` without a height in a scroll view. The config keeps the upstream
   defaults `responsive: true` and `maintainAspectRatio: true`. The host gets unbounded height
   constraints, and `FlutterPlatform.getMaximumSize` (`lib/src/platform/platform.flutter.dart:560-605`)
   gives the height from the width and the aspect ratio, as the DOM gives it on the docs page:
   2 by default, 1 for doughnut, pie, polarArea (src/controllers/controller.doughnut.js:89,
   controller.polarArea.js:33) and radar (controller.radar.js:27). A new sample gives a new key,
   thus a new chart (as `docs` makes a new chart for each block).
4. The readout (`ReadoutTable`): `type`, `controllers` (the id of each meta controller, `bar, line`
   for Mixed), `elements` (the data element count of each dataset), `chart area`, `active` (the
   hovered elements as `d<dataset>#<index>`, from `getActiveElements`). The default `events` stay:
   hover shows the hover options (for example `hoverOffset: 4` of `doughnut.md:31`) without a
   tooltip.
5. The help text: the docs source with its lines at the pin (`docs/charts/bar.md:5-54`), and one
   sentence for the plugins: "Legend, title and tooltip come with the plugins of phase 8." Area and
   Radar add: "The fill comes with plugin.filler in phase 8."

The page body caps its width at 600 logical pixels (`DemoPageBody(maxWidth: 600)`). Thus a square
chart is at most about 544 pixels high on a desktop window.

**In view at load** (question 5). A Pixel 8a is 412 x 915 logical pixels. The chart width is
412 - 2 x 12 (page padding) - 2 x 16 (card padding) = 356. The worst case is a square chart with a
`sample` line: status and app bar 80, card title and source 50, one control line 40 with gaps,
the chart 356. The bottom of the chart is at about 560 < 915. On a 360 x 640 phone, the chart is
304 high and its bottom is at about 500 < 640. A widget test pins both sizes (section 7).

### 1.4 Code form

The configs mirror the docs tree. Each file has a rule-2 header (voluntary: `check:headers` does
not read the gallery; `REUSE.toml` already gives Chart.js MIT for `apps/chartjs_gallery/lib/**`).

```dart
// lib/docs/scripts/utils.dart
// Ported from Chart.js v4.5.1+7169e651 docs/scripts/utils.js (MIT, Chart.js Contributors).

/// docs/scripts/utils.js:7 `var _seed = Date.now()`.
double _seed = jsDateNow();

/// :9 `srand(seed)`.
void srand(double seed) => _seed = seed;

/// :13 `rand(min, max)`. Both operands of `%` are positive: the Dart `%` gives the JS result.
double rand([double? min, double? max]) { ... }

/// :20 `numbers(config)`. `Math.round` is `jsRound` (lib/src/js/js_math.dart:42).
List<double?> numbers([AnyObject? config]) { ... }

// points, bubbles, labels, months, color, transparentize (kurkle_color), CHART_COLORS,
// namedColor. Not ported: newDate, newDateString, parseISODate (luxon, :151-161).
```

```dart
// lib/docs/charts/bar.dart
// Ported from Chart.js v4.5.1+7169e651 docs/charts/bar.md (MIT, Chart.js Contributors).

/// docs/charts/bar.md:5-54, the vertical bar chart.
AnyObject barVertical() {
  final labels = months({'count': 7.0});
  final data = <String, Object?>{
    'labels': labels,
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'My First Dataset',
        'data': <Object?>[65.0, 59.0, 80.0, 81.0, 56.0, 55.0, 40.0],
        // ...
      },
    ],
  };
  return <String, Object?>{'type': 'bar', 'data': data, 'options': <String, Object?>{...}};
}
```

A config is a function: `Chart` and `Config` write into the config Maps, so each new chart gets new
Maps (AGENTS.md, Tests: "A nested Map literal of a spec config needs the type
`<String, Object?>`").

```dart
// lib/charts/chart_types.dart
// Original code, not ported from Chart.js: the chart types of the gallery.

/// One docs block or sample of a chart type.
typedef ChartSample = ({
  String id, // `vertical`: the segment key is `type.bar.sample.vertical`
  String text, // the short segment text
  String source, // `docs/charts/bar.md:5-54`
  AnyObject Function() config,
  List<String> needs, // plugin ids that the config uses and phase 7 does not register
});

/// A chart type of the list.
typedef GalleryChartType = ({
  String slug, // `bar`: the list key is `gallery.type.bar`
  String title, // `Bar`
  IconData icon,
  List<ChartSample> samples,
});

/// The chart types, in the order of docs/charts (the list order of lib/main.dart today).
final List<GalleryChartType> galleryChartTypes = [...];
```

### 1.5 Keys and the list mark

| Control | `ValueKey` |
|---|---|
| list entry | `gallery.type.<slug>` (`area`, `bar`, `bubble`, `doughnut`, `line`, `mixed`, `polarArea`, `radar`, `scatter`) |
| sample segment | `type.<slug>.sample.<id>` (`type.bar.sample.horizontal`) |
| chart host | `type.<slug>.host` |
| readout | `type.<slug>.readout` |
| Area commands | `type.area.randomize`, `type.area.smooth` |

The list entry is an enabled `ListTile` with the type icon and a trailing chevron. The subtitle
says what renders, from the table: "docs/charts/bar.md: 2 samples". When a sample has `needs`, the
subtitle adds the plugin: "Without plugin.filler (phase 8): no fill". The mark comes from the
static table, and a test proves it (section 7): each entry opens a page whose chart has the
controllers of its config. The intro text of the home page drops "no chart type renders yet".

## 2. The replacement of `StressPointController`

### 2.1 What the ported controllers do that `StressPointController` does not

From src/controllers/controller.line.js and controller.scatter.js at the pin:

| Part | `line` | `scatter` | `StressPointController` |
|---|---|---|---|
| scales | needs `iScale` and `vScale` (:100-101); overrides `_index_` category, `_value_` linear (:24-33) | x and y linear (:29-36) | fraction path without scales |
| `enableOptionSharing` | true (:35-39) | false (base default, src/core/core.datasetController.js:270) | the dataset option `optionSharing` |
| dataset element | `LineElement` (:14). Each update sets `line.points` (:60, which resets `_segments` and `_path`, element.line.js:308-313), resolves the dataset options once (:62), sets `borderWidth = 0` when `showLine` is false (:63-65) and `segment` (:66), and calls `updateElement` (:67-70) | none unless `showLine` (:71-95) | none |
| visible range | `_getStartAndCountOfVisiblePoints` and `_scaleRangesChanged` (:46-54) | same (:61-69) | the scale path only |
| `spanGaps` | `maxGapLength` (:82-83); also read in `_getStartAndCountOfVisiblePoints` (helpers.extras.ts:96) | same (:119-120) | same as line |
| `segment` | writes `parsed` and `raw` into each point when set (:105-108) | same (:134-137) | no |
| `getMaxOverflow` | sizes of the first and the last point (:125-136) | sizes of all points when `showLine` is false (:156-166) | `false` (base) |
| `draw` | `updateControlPoints` (:138-142): no work with `tension: 0` (element.line.js:299-305) | base | base |
| `supportsDecimation` | true (:37) | false | true |

Two more upstream effects follow from the scales and from `getMaxOverflow`:
- `Chart.update` gives the maximum of `getMaxOverflow` to the layout as `minPadding`
  (src/core/core.controller.js:500-510). Thus the chart area of a stress chart is 5 pixels smaller
  on each side (radius 4 with the default `hoverRadius`, plus `borderWidth` 1). E1: the area is
  `[5, 5, 795, 475]` against `[0, 0, 800, 480]`, and the points keep their fractions of the area
  (largest error 1.1e-16).
- Each update runs the scale layout. With `min` and `max` on a scale, `Scale.getMinMax` returns at
  once (src/core/core.scale.js:303-309): no loop over the data.

### 2.2 The data contract

`docs/general/data-structures.md:74`: "If parsing is disabled, data must be sorted". The stress
points move in x and y, so the data is not sorted. With `parsing: false`, `parse` sets `_sorted`
to true without a check (src/core/core.datasetController.js:460-462). Then:
- With `min`/`max` on x, `_getStartAndCountOfVisiblePoints` does a binary search on unsorted data
  (helpers.extras.ts:100-131). E2b: one point at `x = 1` at the first midpoint (a point that
  bounced on the right edge; `StressPointField.step` clamps to 1) gives `drawCount` 500 of 1000.
  Half of the points do not draw. This is wrong output.
- Without user bounds on x, `getMinMax` of the sorted case reads only the first and the last point
  (src/core/core.datasetController.js:625-657). The x range is then wrong, unless
  `suggestedMin: 0, suggestedMax: 1` covers all data by chance (P1s).

With the default parsing, `parse` checks the order (:475-483) and sets `_sorted` to false for the
moving points. Then the visible range is all points (E1: P2 draws 5000 of 5000).

### 2.3 Options for the modes `chart`

| Option | Behavior (1) | Performance (2), E4 | Structure (3) | Own code (4) |
|---|---|---|---|---|
| P0. Keep `StressPointController` | not a ported controller | the before figures | port-only controller with `@internal` calls, which each base-class change of phase 7 breaks | 369 lines kept |
| P1m. `line`/`scatter`, `parsing: false`, unsorted, x `min`/`max` | wrong: a bounce at a midpoint hides points (E2b) | no parse | upstream config | least |
| P1s. as P1m with x `suggestedMin`/`suggestedMax` | right by chance; outside the documented contract | `line` update 1.40 ms at 20000 | upstream config | least |
| P1o. `parsing: false` with sorted x (the scene of the mode `axes`) | right | no parse | upstream config | the scene changes: x does not move. The before figures of the mode `chart` do not compare |
| **P2. `line`/`scatter`, default parsing, x and y linear with `min: 0, max: 1, display: false`** | right; the documented form | `line` update +0.05 / +0.14 / +0.93 ms against P1s at 1000 / 5000 / 20000 (Node); draw equal | upstream config | small |

**Choice: P2.** It keeps the exact scene of the before figures (the same `StressPointField`,
seed 7, the same data objects, colors, border and radius). It is the only form that is right by
the documented contract and keeps the moving x. The extra cost is upstream work that a real
Chart.js chart of this scene also does: the parse of the data objects
(src/core/core.datasetController.js:962-981 parses all data at each update), two hidden scales,
the line element, and for `scatter` the loop of `getMaxOverflow`. The draw does not change (E4).

The type replaces the define `SHARING`: `SHARING=1` (sharing as in a line chart) becomes
`TYPE=line`, and `SHARING=0` (no sharing as in a scatter chart) becomes `TYPE=scatter`. These were
the two cases that `StressPointController` emulated (Chart.js ADR 0021 §8). The STRESS and BENCH
lines keep the key `sharing`, now read from `controller.enableOptionSharing`. Thus the after lines
join the before lines on `mode`, `case`, `sharing`, `scriptable` and `n`.

`showLine` stays false by default: the before scene has no line. A new define `SHOWLINE=1` shows
the line (E4: the draw at 20000 grows from 7.20 to 9.17 ms in Node).

### 2.4 Comparable figures

The after side has more upstream work in `update` (E4 and E3). To keep the parts apart, the modes
`chart` and the `chart` cases of the benchmark get the parts of the mode `axes`, and one more part.
All parts come from upstream plugin hooks (the library does not change):

| Part | Hooks | Content |
|---|---|---|
| `elements` (new) | `beforeElementsUpdate` (src/core/core.controller.js:497) to `beforeLayout` | `buildOrUpdateElements`: the parse, and `getMaxOverflow` (:501-508) |
| `layout` | `beforeLayout` to `afterLayout` | the two hidden scales |
| `datasetsUpdate` | `beforeDatasetsUpdate` to `afterDatasetsUpdate` | the loop of `updateElements`: the part that compares with the before `updateMs` |
| `datasetsDraw` | `beforeDatasetsDraw` to `afterDatasetsDraw` | the point draw: compares with the before `drawMs` (minus the clear and the plugin hooks) |

The record in `performance.md` gives each after figure next to its before figure (commit `0e0ab93`,
`phase7/perf/before.md`), and names the upstream work of each difference: the parse, the scale
layout, the line element, and the scatter loop of `getMaxOverflow`. Step 7 ranks only the port
overhead against these upstream costs.

### 2.5 The other users of `StressPointController`

| Place | Today | After | Reason |
|---|---|---|---|
| Core tab (`lib/demo/core_demo.dart:176-198`) | fraction path, no scales, layout padding 20, the value-lines plugin | `type: 'line'`, x and y linear `min: 0, max: 1, display: false`; keep the plugin and the padding | the data is sorted (`_spread`, :171), so `parsing: false` is not needed; the line chart has sharing as before; the line element also animates in `hide` and `show` |
| Axes tab (`lib/demo/axes_demo.dart:323-330`) | scale path, `parsing: true`, sorted x | `type: 'line'` | same data; the line chart gives `_index_`/`_value_` overrides, and the tab sets both scale types |
| mode `axes` (`lib/demo/stress_axes.dart:137-167`) | scale path, `parsing: false`, sorted x | `type: 'line'`, `showLine: false`, keep `parsing: false` | the data is sorted (`StressAxesScene`), so the contract holds. E8: equal ticks and rotation for linear, logarithmic and category, equal chart area for linear and logarithmic; the category area ends at 795 in place of 800 (the `minPadding` of `getMaxOverflow`) |
| `chart_canvas_test.dart` | `StressPointController.id` | `line` | — |

### 2.6 Delete `StressPointController`

**Choice: delete it** in the change that switches the gallery, with `registerGalleryComponents`
moved to a new file. Reasons:
- Chart.js ADR 0021 §8 (proposed) says: "Phase 7 runs the same scenarios again with the ported
  `LineController` and `ScatterController`. Then it removes `StressPointController`."
- The before side does not need it in the tree: it is commit `0e0ab93` in a worktree (kickstart
  "Measurement method").
- It calls `@internal` members of `DatasetController` and overrides `parse`, `update` and
  `updateElements`. The phase 7 changes of the base class (Chart.js ADR 0025 §8, the record of
  `getLabelAndValue`, `members-radial.md` R2) would need upkeep of a class that no figure needs.

```dart
// lib/demo/gallery_registry.dart
// Original code, not ported from Chart.js: the registration of the gallery.

bool _registered = false;

/// `Chart.register(controllers, scales, elements, plugins)` of src/index.umd.ts:28, once. In phase 7, `registerables`
/// has the controllers, the elements and the scales. The plugins come in phase 8.
void registerGalleryComponents() {
  if (_registered) return;
  _registered = true;
  Chart.register(registerables);
}
```

## 3. Stress cases for the other controllers

### 3.1 Options

| Option | Fit | Notes |
|---|---|---|
| S1. One new `StressMode` for each type (`bar`, `bubble`, ...) | 13 modes in one `SegmentChoice` line: about 27 pixels for each segment on a phone | breaks the rule of question 5 |
| **S2. The mode `chart` takes the chart type (`TYPE`)** | one more line of 8 icon segments | the chart type is the upstream discriminator; the modes `bars` and `arcs` (elements only) stay for the element baselines |
| S3. A separate stress app for each type | — | more code, no shared figures |

**Choice: S2.** `StressChartType` has all 8 controllers: `line`, `scatter`, `bar`, `bubble`,
`doughnut`, `pie`, `polarArea`, `radar`. `pie` is in because step 7 profiles each chart type, and
the pie arcs have no inner radius, so their path differs from the doughnut arcs.

### 3.2 The scene of each type

All scenes use `StressPointField` (seed 7), `animation: false` (or the loop of `CALL=animate`),
`events: []`, `maintainAspectRatio: false`, the background `rgba(54, 162, 235, 0.45)` (or the
scriptable color of `SCRIPTABLE=1`), and hidden scales. Each update writes the new field values
into the data in place, as the before scene does.

| Type | Data | Scales | Counts N | Upstream facts (E5c, Node, sharing from the controller) |
|---|---|---|---|---|
| `line` | `{x, y}` objects | x, y linear `min: 0, max: 1, display: false` | 1000, 5000, 20000 | section 2 |
| `scatter` | `{x, y}` objects | same | 1000, 5000, 20000 | section 2 |
| `bar` | N labels `Point i`, N numbers `y` | x category `display: false, ticks: {display: false}`; y linear `min: 0, max: 1, display: false` | 1000, 5000, 20000 | sharing true (controller.bar.js:379-386); update 2.55 / 10.75 / 43.58 ms, draw 1.27 / 6.01 / 24.30 ms |
| `bubble` | `{x, y, r}` objects, `r = 2 + 4 (vx / 0.3)^2` | as `line` | 1000, 5000, 20000 | sharing true (controller.bubble.js:37-40); area inset 6.97 (the largest `r`); update 2.08 / 6.66 / 29.37 ms |
| `doughnut` | N labels, N numbers `0.05 + 0.95 y` | none | 100, 1000, 5000 | sharing true; update 0.23 / 0.55 / 1.68 ms, draw 0.46 / 2.38 / 10.10 ms |
| `pie` | as `doughnut` | none | 100, 1000, 5000 | the doughnut controller with `cutout: 0` |
| `polarArea` | as `doughnut` | r `min: 0, max: 1, display: false` | 100, 1000, 5000 | sharing false; update 0.49 / 1.60 / 3.37 ms, draw 0.34 / 2.46 / 10.69 ms |
| `radar` | N labels, N numbers `y` | r `min: 0, max: 1, display: false` | 100, 1000, 5000 | sharing false; dataset element `line`; no fill warning (the radar default `elements.line.fill: 'start'` is not the dataset option `fill`); update 0.72 / 1.67 / 4.13 ms |

Two choices in the table come from evidence:
- **The bar x axis hides its ticks.** A hidden scale still runs the auto skip when
  `ticks.display` is true (src/core/core.scale.js:457), and the auto skip measures the labels.
  E5b at 5000 bars: update 24.0 ms with the ticks, 9.4 ms without. The label path of a category
  axis is the subject of the mode `axes` (`performance.md` §11.6, §11.8). The bar case profiles
  the controller and the elements.
- **One color, not the indexable array of the docs samples.** An indexable `backgroundColor`
  needs the context, so each element resolves its options (E5b: doughnut at 1000, 12.5 ms with the
  7 colors of `docs`, 1.0 ms with one color). `SCRIPTABLE=1` gives that path for each type (E5c:
  doughnut at 1000, 12.18 ms against 0.55 ms), as case (c) does for points.

### 3.3 Defines and keys

Stress entry (`lib/main_stress.dart`):

| Define | Values | Default | Notes |
|---|---|---|---|
| `MODE` | `primitives`, `elements`, `bars`, `arcs`, `chart`, `axes` | `primitives` | unchanged |
| `TYPE` | `line`, `scatter`, `bar`, `bubble`, `doughnut`, `pie`, `polarArea`, `radar` | `line` | mode `chart` only; another mode with `TYPE` throws |
| `CALL` | `draw`, `update`, `animate` | `draw` | `animate` for each type in the mode `chart` |
| `SCRIPTABLE` | 0, 1 | 0 | each type |
| `SHOWLINE` | 0, 1 | 0 | `line` and `scatter` only; another type throws |
| `SHARING` | — | — | removed: a value throws `ArgumentError` with "Use TYPE=line or TYPE=scatter" |
| `SCENARIO` | `NxM` | the counts of the type with M = 0 | unchanged form |

The STRESS line of the mode `chart` gets the keys `type`, `sharing` (from the controller),
`scriptable`, `showLine` (only when true), `elementsMs`, `layoutMs`, `datasetsUpdateMs` and
`datasetsDrawMs`.

Frameless benchmark (`lib/bench/chart_bench.dart`, `lib/main_bench.dart`):

| Case | Mode, name | Calls | Keys | Counts |
|---|---|---|---|---|
| `chart.a` | `chart`, `a` | draw | `type: line`, `sharing`, `scriptable: false` | 1000, 5000, 20000 |
| `chart.b` | `chart`, `b` | update | `type: line` and `type: scatter` (two cases) | 1000, 5000, 20000 |
| `chart.c` | `chart`, `c` | update | `type: line`, `scriptable: true` | 1000, 5000, 20000 |
| `chart.<type>` | `chart`, `bar` / `bubble` / `doughnut` / `pie` / `polarArea` / `radar` | draw and update (two cases each) | `type`, `sharing`, `scriptable: false` | the counts of the type |
| `axes.<scale>` | unchanged | | `type: line` added | unchanged |

- `ChartBenchCase` gets `counts` (`List<int>`). The define `N` overrides the counts of every case
  when it is given. Without `N`, each case runs its own counts. The radial types stop at 5000:
  a doughnut case at 20000 holds the UI thread for many seconds, and Android shows "App not
  responding" after 5 s (`performance.md` §6).
- The selector `chart` now selects 4 + 12 cases. A before/after run of the cases of Chart.js ADR
  0021 §8 uses `CASES=a,b,c`.
- Each `chart` case gets the four parts of section 2.4.

```dart
// lib/demo/stress_chart_config.dart (sketch)

/// The chart types of the mode `chart`: the 8 controllers of phase 7.
enum StressChartType {
  line, scatter, bar, bubble, doughnut, pie, polarArea, radar;

  /// The N choices: the radial types stop at 5000, as the mode `arcs`.
  List<int> get counts => switch (this) {
    doughnut || pie || polarArea || radar => const [100, 1000, 5000],
    _ => const [1000, 5000, 20000],
  };
}

/// The chart of the mode `chart` for a type: the config, and the write of the moving values.
final class StressChartScene {
  StressChartScene(
    this.type,
    this.n,
    StressPointField field, {
    required bool scriptable,
    bool showLine = false,
    bool animate = false,
    AnyObject options = const {},
    List<Object?> plugins = const [],
  });

  final StressChartType type;
  final int n;

  /// `new Chart(canvas, config)` takes it once.
  late final AnyObject config;

  /// Writes the values of [field] into the data of [config] in place.
  void write(StressPointField field);
}

/// The hidden axis of the points: `{type: 'linear', min: 0, max: 1, display: false}`.
AnyObject _unitAxis() => <String, Object?>{
  'type': 'linear', 'min': 0.0, 'max': 1.0, 'display': false,
};
```

## 4. `types.Chart` and the analyzer

The gallery has two classes that implement interfaces of `lib/src/types/`:
`DemoChart implements types.Chart` (`lib/demo/demo_chart.dart:40`, with explicit members and no
`noSuchMethod`) and `_DemoChart implements Chart` (`lib/demo/ticks_demo.dart:20`, with
`noSuchMethod`). `members-radial.md` R1 lists four members of `types.Chart` that phase 7 can add.

| Option | Effect |
|---|---|
| **A. Each port unit that adds a member to an interface that a gallery class implements also adds the member to that class, with the empty result that the `DemoChart` doc gives (:38-39), in the same change** | `dart run melos run analyze` (root `dart analyze --fatal-infos`, which includes `apps/`) stays green after each unit |
| B. `noSuchMethod` in `DemoChart` | the analyzer no longer finds a missing member; a call throws at run time |
| C. Replace `DemoChart` with a real `Chart` | the phase 3 tabs show the platform calls without a chart on purpose; out of scope |

**Choice: A.** Each agent prompt of the port waves and of the integration agent names
`apps/chartjs_gallery/lib/demo/demo_chart.dart` as a file to check, and runs `dart analyze` on
`apps/chartjs_gallery` (kickstart "Rules for every agent prompt"). The subclasses `_StressChart`
and `_BenchChart` extend the real `Chart` and need nothing.

## 5. The layout rule on the pages that phase 7 changes

Rule of the user (2026-10-21): the chart of each page is in view at load on a phone. Each parameter
is a full-width Material `SegmentedButton` with short text, or icons where they make sense
(`SegmentChoice` and `SegmentToggles` of `lib/demo/demo_controls.dart`). One control on each line,
then the chart, then the readouts and the help text. No popup menus, no horizontal scroll, no rows
of chips above the chart.

| Page | Phase 7 form |
|---|---|
| Chart type pages | section 1.3: at most one control line above the chart |
| Stress tab, mode `chart` | the lines: start and toggles (`spin`, `scriptable`, `showLine`), `mode`, `type`, `N`, `M`, `call`. The `sharing` toggle goes away (the type gives it). Six lines, as the mode `axes` has today |
| Stress `type` line | a `SegmentChoice` of 8 icons (`Icons.show_chart`, `scatter_plot`, `bar_chart`, `bubble_chart`, `donut_large`, `pie_chart`, `track_changes`, `radar`) with the type name as the tooltip: 8 text segments do not fit 356 pixels |
| Core tab | the chart card stays first. Its chips and sliders become `SegmentChoice` and `SegmentToggles` lines above the chart: `mode` (6 modes), `axis` (3), one toggle line (`intersect`, `animation`, the two datasets) with the three data commands, `hover ms` and `update ms` as choices of 0, 200, 400, 1000 and 2000. The keys stay: a chip key `core.mode.index` becomes the segment key `core.mode.index`; a slider key `core.hover.duration` becomes `core.hover.duration.<ms>` |
| Axes tab | changes only its chart type in phase 7. Its 15 parameters do not fit above the chart on a phone. Open item for the maintainer (section 8) |

`SegmentChoice` gets one optional parameter for icon segments:

```dart
/// The icon of the segment of [value], or `null` for the text of its item.
/// With an icon, the segment shows the icon only. The icon has the
/// [ValueKey] of the `key` of its item.
final IconData? Function(T value)? iconOf;
```

## 6. Files that the implementation changes

Gallery (`apps/chartjs_gallery/`):
- `lib/main.dart`: `galleryChartTypes` replaces `chartTypes`; enabled entries with keys, icons
  and the status subtitle; the intro text.
- New `lib/charts/chart_types.dart` (the table), `lib/charts/chart_type_page.dart` (the page).
- New `lib/docs/scripts/utils.dart`, `lib/docs/charts/{bar,bubble,doughnut,line,mixed,polar,radar,scatter}.dart`,
  `lib/docs/samples/area/line_boundaries.dart`: the ported configs, each with its rule-2 header.
- New `lib/demo/gallery_registry.dart`; delete `lib/demo/stress_point_controller.dart`.
- `lib/demo/stress_chart_config.dart`: `StressChartType`, `StressChartScene` (in place of
  `stressChartConfig`), `_unitAxis`.
- `lib/demo/stress_axes.dart`: `stressAxesConfig` gives `type: 'line'` and `showLine: false`;
  `StressAxesTiming` gets the part `elements`.
- `lib/demo/stress_demo.dart`: the `type` line, the toggles, the readout, the parts in the mode
  `chart`, the key of the chart host `(n, type, scriptable, showLine, animate)`, the source text.
- `lib/main_stress.dart`: `TYPE`, `SHOWLINE`, the `SHARING` guard, the counts of the type, the
  STRESS keys.
- `lib/bench/chart_bench.dart`, `lib/main_bench.dart`: the cases, `counts`, the parts, the `type`
  key, `N` without a default.
- `lib/demo/core_demo.dart`: `type: 'line'` with the hidden unit axes; the controls of section 5.
- `lib/demo/axes_demo.dart`: `type: 'line'`.
- `lib/demo/demo_controls.dart`: `SegmentChoice.iconOf`.
- `lib/demo/demo_chart.dart`: the members that the port waves add to `types.Chart` (section 4).
- `lib/canvas_host_demo.dart` and `README.md`: texts that name `StressPointController`.

Docs:
- `packages/flutter_chartjs/doc/adr/0031-*.md` (new, proposed).
- `packages/flutter_chartjs/doc/performance.md` §6: the defines `TYPE` and `SHOWLINE`, the removed
  `SHARING`, the part `elements`, the new benchmark cases and `counts`; the step 7 section with
  the after figures next to the before figures.
- `AGENTS.md`, Layout of `apps/chartjs_gallery`: the chart type pages, `lib/docs/`, the mode
  `chart` with `TYPE`; the sentence "Phase 7 replaces `StressPointController`" goes away.

## 7. Tests that pin the decision

All gallery tests are `flutter_test` widget tests.

- `test/gallery_test.dart`: each of the 9 entries has its key `gallery.type.<slug>`, is enabled,
  and opens its page. (It replaces "marks unported chart types as disabled".)
- New `test/chart_types_test.dart`, for each sample of `galleryChartTypes`:
  - the chart exists after the first frame; `config.type` is the type of the docs block; each meta
    controller is the expected class (`BarController`, `LineController`, ... `bar` and `line` for
    Mixed); the element counts are those of the docs data (line 7, bar 7, bubble 2, doughnut 3,
    pie 3, polarArea 5, radar 7 and 7, mixed 4 and 4, scatter 4, area 8);
  - the host rect is inside the view at 412 x 915 and at 360 x 640 logical pixels (question 5);
  - the host height is the width divided by the aspect ratio (2, or 1 for doughnut, pie,
    polarArea, radar);
  - a hover over an element shows it in the `active` readout;
  - Area: `Utils.srand(42)` before the page gives the 8 values of E9; `Smooth` sets
    `options.elements.line.tension` to 0.4.
- New `test/docs_utils_test.dart`: `srand(42)` then `numbers({min: -100, max: 100, count: 8,
  decimals: 2, continuity: 1})` gives `[77.18, 91.8, 12.39, 19.19, 40.6, 42.05, 48.24, 98.66]`
  (E9, x64 Node.js); `months({count: 7})`; `transparentize(CHART_COLORS.red)` gives
  `rgba(255, 99, 132, 0.5)`.
- `test/stress_chart_test.dart`, for each `StressChartType` and a small N:
  - the controller class, `enableOptionSharing` (line, bar, bubble, doughnut and pie true;
    scatter, polarArea and radar false), the dataset element (`line` and `radar` a
    `LineElement`, the others none);
  - `line` and `scatter`: `meta.sorted` is false, `drawStart` is 0 and `drawCount` is N, and each
    point is at its field fraction of the chart area (difference below 1e-9, E1);
  - the STRESS keys `type`, `sharing` and the four parts;
  - the `SHARING` guard and the `SHOWLINE` guard throw `ArgumentError`.
- `test/stress_axes_test.dart`: `config.type` is `line`, `showLine` is false, ticks and rotation as
  before.
- `test/chart_bench_test.dart`: the case list and the ids; the `counts` of each case; `N` overrides
  them; one tiny run of each new case gives a BENCH line with `type`, `sharing` and the parts.
- `test/core_demo_test.dart`, `test/axes_demo_test.dart`, `test/chart_canvas_test.dart`: the
  `LineController` in place of `StressPointController`; the Core keys of section 5.
- Gate: `dart run melos run analyze` covers `apps/` (section 4).

## 8. Open items

- The Axes tab has 15 parameters. The rule of question 5 puts the controls above the chart, and
  they do not fit there on a phone. The maintainer decides the split (for example a second tab).
- Phase 8 registers the plugins through `registerables`. Then the legend, the title and the
  tooltip appear on the chart type pages with no change of the configs, as on the docs pages. The
  stress configs and the benchmark then need `options.plugins.<id>: false` for each plugin, the
  upstream opt-out, to keep the figures of phase 7 comparable. Phase 8 adds the `fill` control of
  the Area page.
