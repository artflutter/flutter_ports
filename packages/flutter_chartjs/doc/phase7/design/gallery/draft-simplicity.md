# Gallery chart types and the stress controller: simplicity draft

Design panel of phase 7, step 2, for the future Chart.js ADR 0031. Lens: simplicity first. This
draft looks for the form with the least code of our own and the fewest new concepts that keeps
the protected behavior (Chart.js ADR 0009) and keeps the phase 5 and phase 6 figures comparable.

## Summary

1. Each of the 9 entries of the home list opens one generic page, `ChartTypePage`. The page shows
   the `chart-editor` configs of `docs/charts/<entry>.md` at the pin, unchanged, as its variants.
   Area has no config in `docs/charts/area.md`. It shows the config of
   `docs/samples/area/line-boundaries.md` with `fill: 'origin'`, and the list marks it as partial:
   without `plugin.filler`, upstream draws the line only (probe P2).
2. `StressPointController` is deleted. Each of its uses gets `type: 'line'`. The stress mode
   `chart` with `SHARING=0` gets `type: 'scatter'`. The stress charts keep `parsing: false`, get
   `showLine: false` and get two hidden linear scales of the fractions 0 to 1: `x` with
   `suggestedMin`/`suggestedMax`, `y` with `min`/`max`. The Core and Axes tabs show the line.
3. One new stress mode, `type`, with the define `TYPE=<bar|bubble|doughnut|line|polarArea|radar>`.
   Each case is the docs sample of its type scaled to N items (100, 1000, 5000). The frameless
   benchmark gets the cases `type.<name>` (draw and update), after all current cases.
4. `DemoChart` implements each member that phase 7 adds to `types.Chart`, with a "no datasets"
   result. The workspace `analyze` gate already covers the gallery.
5. The layout rule applies to every page that phase 7 adds: one control per line, then the chart,
   then the readout and the help text. A widget test pins "the chart is in view" at the Pixel 8a
   size for each chart type page and for the Core and Axes tabs.

## Evidence

The probes ran on 2026-10-21 with the x64 Node.js v24.12.0 under Rosetta and the Chart.js build
at the pin `7169e65147a47f3720957a6f156a33c838ab9f57` (`dist/chart.js`, SHA-256 prefix
`bc550e26bbb4efa6`). The scripts and their outputs are in
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/gallery-simplicity/`
(`node.sh` starts the x64 Node.js):

| Probe | Script | Output | What it gives |
|---|---|---|---|
| P1 | `p1_stress_configs.mjs` | `p1_count.out`, `p1_count2.out`, `p1_trap.out`, `p1_time.out`, `p1_time2.out` | The stress mode `chart` with a JS copy of `StressPointController` against line and scatter configs: call counts of one update at N = 1000, the draw truncation of user bounds, and update and draw times at 1000, 5000 and 20000 |
| P2 | `p2_samples.mjs` | `p2_none.out`, `p2_all.out` | The 13 configs of the type pages with no plugin (phase 7) and with all registerables (phase 8): controllers, elements, scales and canvas call counts |
| P3 | `p3_type_cases.mjs` | `p3_types.out` | The proposed `type` stress cases at 100, 1000 and 5000: update and draw times, and `measureText` calls for each iteration |
| P4 | `p4_area_numbers.mjs` | `p4_area_numbers.out` | The fixed numbers of the Area page through the `Utils.numbers` algorithm of `docs/scripts/utils.js:20-43` |

- The times of P1 and P3 are V8 times with a no-op context behind a JS `Proxy`. They give the
  upstream cost of each form relative to the other forms. They do not predict the Dart times.
- No Dart probe ran. The choices of this draft are gallery configs (port-only code). Behavior
  (P1 trap, P2) and comparability decide them. The step 7 series measures the Dart figures, with
  the before side at `0e0ab93` (`doc/phase7/perf/before/`, raw files only: `before.md` does not
  exist yet).

## 1. The chart type pages

### 1.1 Options

| Option | Behavior | Performance | Structure | Code of our own |
|---|---|---|---|---|
| A. The `chart-editor` configs of `docs/charts/<entry>.md`, unchanged, as variants of one generic page (upstream form) | Upstream configs: what the docs show | Small charts: not at stake | Mirrors the docs page of each entry | One page widget and 13 config literals |
| B. The `docs/samples/other-charts/*.md` samples with their actions (Randomize, Add Dataset, Add Data, Remove Dataset, Remove Data) | Upstream configs | Not at stake | Mirrors the samples | A port of `docs/scripts/utils.js` (`numbers`, `rand`, `months`, `transparentize`, `CHART_COLORS`) and an action row for each page |
| C. Gallery configs of our own | Not upstream | Not at stake | None | As A, with no upstream reference |

Choice: **A**. It has the least code and no new concept. The 9 entries of `lib/main.dart:11-21`
are the 9 pages of `docs/charts/` in the order of the docs. Thus each entry has one source file.

### 1.2 The variants

Each `js chart-editor` block of `docs/charts/<entry>.md`, in file order, is one variant. Only
`bar.md`, `doughnut.md` and `line.md` have two blocks.

| Entry (`key`) | Variant (`key`: source) | Chart type | Controllers (P2) | Elements (P2) | Scales (P2) |
|---|---|---|---|---|---|
| Area (`area`) | `origin`: `samples/area/line-boundaries.md:20-33`, `:95-113`, with `fill: 'origin'` | line | `LineController` | 1 line, 8 points | x category, y linear |
| Bar (`bar`) | `vertical`: `bar.md:5-54`; `horizontal`: `bar.md:304-351` | bar | `BarController` | 7 bars | x category / y linear; y category / x linear |
| Bubble (`bubble`) | `bubble`: `bubble.md:5-36` | bubble | `BubbleController` | 2 points | x, y linear |
| Doughnut and Pie (`doughnut`) | `doughnut`: `doughnut.md:15-47`; `pie`: `doughnut.md:53-85` | doughnut, pie | `DoughnutController`, `PieController` | 3 arcs | none |
| Line (`line`) | `vertical`: `line.md:5-31`; `horizontal`: `line.md:233-285` | line | `LineController` | 1 line, 7 points | x category / y linear; y category / x linear |
| Mixed (`mixed`) | `mixed`: `mixed.md:27-70` | scatter with a bar and a line dataset | `BarController`, `LineController` | 4 bars; 1 line, 4 points | x category (from the bar overrides), y linear |
| Polar Area (`polar`) | `polar`: `polar.md:7-43` | polarArea | `PolarAreaController` | 5 arcs | r radialLinear |
| Radar (`radar`) | `radar`: `radar.md:7-61` | radar | `RadarController` | 2 lines, 7 points each | r radialLinear |
| Scatter (`scatter`) | `scatter`: `scatter.md:5-47` | scatter | `ScatterController` | 4 points | x, y linear |

- `Utils.months({count: 7})` gives `'January'` to `'July'` (`docs/scripts/utils.js:91-103`). The
  page writes the 7 strings.
- P2 ran all 13 configs with the controllers, the elements and the scales, and no plugin. Each
  config made its chart with no throw, with the controllers, elements and scales of the table.
  The Mixed chart gets a category x axis from the overrides of its bar dataset, although its
  `type` is `scatter`.

### 1.3 Area

| Option | Behavior | Code of our own |
|---|---|---|
| A. Pending until phase 8 | No chart: the entry does not render | None |
| B. The config of `samples/area/line-boundaries.md` with `fill: 'origin'`, partial until `plugin.filler` (phase 8) | What upstream draws with the modules of phase 7 | One config literal and one note |
| C. A fill of our own in the gallery | Not upstream. Phase 8 deletes it | A fill plugin |

Choice: **B**.

- Evidence (P2, no plugin): `area.origin` and `area.false` give the same canvas calls (`fill` 8,
  `stroke` 47, `lineTo` 46). With all registerables, `area.origin` gives `lineTo` 58 against 46
  for `area.false`: the filler draws the area. Thus in phase 7 the Area page shows the line chart
  that upstream draws without the filler.
- Upstream prints a warning for a dataset with `fill` and no filler
  (`core.datasetController.js:286-289`). The port prints it too
  (`lib/src/core/core.datasetController.dart:784-789`, through `print`). The Area page and the
  Radar page (`fill: true`, `radar.md:22`, `:32`) print it once for each dataset. The tests accept
  the line. P2 shows the 3 warnings.
- `docs/charts/area.md` has no `chart-editor` block (it describes the filler,
  `area.md:1-7`). `line-boundaries.md` is the first sample of the docs group "Area".
- The data of the sample is `Utils.numbers(inputs)` (`line-boundaries.md:4-18`), with a seed
  from `Date.now()` (`docs/scripts/utils.js:7`). The page uses fixed numbers: the algorithm of
  `utils.js:20-43` with the seed 2026 gives
  `[97.81, -42.3, 84.05, -46.6, -31.77, 12.48, -59.53, -0.87]` (P4). The labels are
  `Utils.months({count: 8})`.
- The config keeps its `plugins.filler` and `plugins.title` options (`line-boundaries.md:100-108`).
  Phase 7 has no title plugin, so the options have no effect. Phase 8 then shows the title
  `Fill: origin` with no change of the page.
- Phase 8 deletes the note. It can add the other fill modes of the sample actions (`false`,
  `start`, `end`) as variants.

### 1.4 The page

One generic widget for the 9 entries. Structure, from the top:

1. The app bar with the title of the entry.
2. The variant control: one `SegmentChoice<int>` at the full width, only when the entry has two
   variants. A tap makes a new chart (a new key of the host), as a docs page makes a new chart for
   each example.
3. The chart: a `ChartCanvas` (`lib/demo/chart_canvas.dart`) with the height
   `(width * 0.75).clamp(240, 420)`. The page adds `maintainAspectRatio: false` and an `onHover`
   callback to the options of the config. These keys change no other option.
4. The readout: one `ReadoutTable` with `datasets` (the `meta.type` and the element count of each
   dataset, for example `bar 4, line 4`) and `active` (the active elements, as `d0#2`).
5. The help text: the source file at the pin, and "No legend, tooltip or fill: these plugins come
   in phase 8." Area adds its note.

- No action buttons. The docs chart pages have `actions: []` (for example `bar.md:51`). The
  default animation of each chart shows the update path at the start, and the hover shows the
  hover options (for example `hoverOffset: 4` of the doughnut, `doughnut.md:31`).
- Each nested Map literal of a config has the type `<String, Object?>`: `new Chart` and the
  page write into it (AGENTS.md, Tests).
- The configs are functions that return a new Map for each chart. A chart writes into its config.
- The page needs no new registration: `registerables` holds the controllers after phase 7.

Code form (`apps/chartjs_gallery/lib/chart_types.dart`, port-only):

```dart
// Original code, not ported from Chart.js: the chart type pages of the gallery.

/// One variant of a chart type page: a `chart-editor` block of the docs.
typedef ChartTypeVariant = ({
  String key,
  String text,
  String source,
  AnyObject Function() config,
});

/// One entry of the home list: the page of `docs/charts/<key>.md`.
/// [note] tells what the page lacks until a later phase, or is Dart
/// `null` when the page shows the full chart.
typedef ChartTypeEntry = ({
  String key,
  String title,
  List<ChartTypeVariant> variants,
  String? note,
});

/// The chart types of the docs, in the order of the docs.
final List<ChartTypeEntry> chartTypes = [
  (
    key: 'area',
    title: 'Area',
    variants: [
      (
        key: 'origin',
        text: 'origin',
        source: 'docs/samples/area/line-boundaries.md',
        config: areaOriginConfig,
      ),
    ],
    note: 'Line only: the fill needs plugin.filler (phase 8)',
  ),
  (
    key: 'bar',
    title: 'Bar',
    variants: [
      (key: 'vertical', text: 'vertical', source: 'docs/charts/bar.md:5', config: barConfig),
      (key: 'horizontal', text: 'horizontal', source: 'docs/charts/bar.md:304', config: barHorizontalConfig),
    ],
    note: null,
  ),
  // bubble, doughnut (doughnut, pie), line (vertical, horizontal), mixed,
  // polar, radar, scatter.
];

/// The page of one chart type.
class ChartTypePage extends StatefulWidget {
  const ChartTypePage({required this.entry, super.key});

  final ChartTypeEntry entry;

  @override
  State<ChartTypePage> createState() => ChartTypePageState();
}

class ChartTypePageState extends State<ChartTypePage> {
  int _variant = 0;
  Chart? _chart;
  final ValueNotifier<int> _readout = ValueNotifier(0);

  /// The chart, once it exists. For the tests.
  @visibleForTesting
  Chart? get chart => _chart;

  Chart _create(UiCanvasElement canvas) {
    registerGalleryComponents();
    final config = widget.entry.variants[_variant].config();
    final options = (config['options'] ??= <String, Object?>{})! as AnyObject;
    options
      ..['maintainAspectRatio'] = false
      ..['onHover'] = (Object? event, Object? active, Object? chart) =>
          _readout.value++;
    return Chart(canvas, config);
  }
  // build: SegmentChoice (2 variants only), KeyedSubtree(key: ValueKey(_variant),
  // child: ChartCanvas(...)), ValueListenableBuilder(ReadoutTable), help text.
}
```

The config literals are in `apps/chartjs_gallery/lib/samples/chart_samples.dart` (port-only:
the gallery copies docs configs, it does not port library code). Each function names its source
block in its `///` line, for example
`/// docs/charts/bar.md:5-54 at Chart.js v4.5.1+7169e651.`

### 1.5 The home list

The disabled tiles of `lib/main.dart:88-94` become tiles that open the page:

```dart
for (final entry in chartTypes)
  ListTile(
    key: ValueKey('gallery.type.${entry.key}'),
    leading: Icon(
      entry.note == null ? Icons.check_circle_outline : Icons.timelapse,
    ),
    title: Text(entry.title),
    subtitle: Text(entry.note ?? 'docs/charts/${entry.key}.md'),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ChartTypePage(entry: entry)),
    ),
  ),
```

- A rendered type has the icon `check_circle_outline`. A partial type (Area) has `timelapse` and
  its note. No tile is disabled after phase 7.
- Rejected: a status that the tile reads from the registry (`registry.plugins.get('filler')`).
  It updates itself in phase 8, but it adds a lookup and a list of plugin ids for each entry. A
  static note is one string, and phase 8 deletes it.
- The text of the first tile (`lib/main.dart:57-61`) changes: "The chart types render through
  the ported controllers, without the plugins of phase 8."

### 1.6 Keys

| Control | `ValueKey` |
|---|---|
| Home tile of an entry | `gallery.type.<entry>`, for example `gallery.type.doughnut` |
| Variant segment | `type.<entry>.variant.<variant>`, for example `type.doughnut.variant.pie` |
| Chart host | `type.<entry>.host` |
| Readout | `type.<entry>.readout` |

The variant key is on the label of its segment, as `SegmentChoice` does
(`lib/demo/demo_controls.dart:212-217`).

## 2. The replacement of `StressPointController`

### 2.1 What the ported controllers do more

`StressPointController` (`lib/demo/stress_point_controller.dart`) copies
`controller.line.js:76-120` without the line. The fraction path (Core tab, mode `chart`) has no
scales. The scale path (Axes tab, mode `axes`) has the scales of the config.

| Work | `LineController` | `ScatterController` | `StressPointController` | P1, one `update('none')` at N = 1000 |
|---|---|---|---|---|
| Dataset element | `LineElement` (`controller.line.js:14`). `update` sets its points and resolves its options once (`:56-70`). `showLine: false` sets `borderWidth: 0` (`:63-65`) | None with `showLine: false` (`controller.scatter.js:14-16`, `:91-95`) | None (`stress_point_controller.dart:70-74`) | line: `resolveDatasetElementOptions` 1 |
| Scales | Needs `iScale` and `vScale` (`controller.line.js:80-81`). Default scales: category and linear (`:24-33`) | Linear x and y (`controller.scatter.js:29-36`) | Fraction path: none | 2 scale updates, 22 `ctx.font` writes, 2000 `getPixelForValue` |
| Visible range | `_getStartAndCountOfVisiblePoints` and `_scaleRangesChanged` (`controller.line.js:46-54`) | The same (`controller.scatter.js:61-69`) | Scale path only (`stress_point_controller.dart:132-149`) | start 0, count N with the chosen scales |
| Option sharing | On (`controller.line.js:35-39`) | Off: one copy for each point (`controller.scatter.js:114-116`, no `initialize`) | Dataset option `optionSharing` | line 5 resolves; scatter 3001 |
| `segment` | `parsed` and `raw` on each point when the option is set (`controller.line.js:105-108`) | The same (`controller.scatter.js:134-137`) | None | Not set by the stress configs |
| `spanGaps` | `maxGapLength` (`controller.line.js:82-83`) | The same (`:119-120`) | The same | `false`: no stop |
| `getMaxOverflow` | 2 resolves and 2 `size` calls (`controller.line.js:125-136`) | With `showLine: false`, a resolve and a `size` for each point (`controller.scatter.js:160-166`) | `false` (base, `core.datasetController.js:680-682`) | Called twice for each update (`core.controller.js:507`, `core.datasetController.js:704`) |
| Padding and clip | `layout.autoPadding` gets the overflow (`core.controller.js:507-509`). `meta._clip` is not disabled (`core.datasetController.js:23-36`, `:704`) | The same | No padding, clip disabled | 1 `rect` and 1 `clip` for each draw; chart area 790 x 470 of 800 x 480 |
| Draw | `updateControlPoints` (no work with `tension: 0`, `element.line.js:299-306`), then the line draw (no work with `borderWidth: 0`, `element.line.js:431-437`) and the points (`controller.line.js:138-142`) | The points | The points | Same point draw calls in each form |

P1 update times (V8, the update without its draw, ms):

| Config | 1000 | 5000 | 20000 |
|---|---:|---:|---:|
| `stressPoint` (JS copy, sharing on), run 1 / run 2 | 0.112 / 0.159 | 0.399 / 0.333 | 1.173 / 0.747 |
| `stressPoint0` (sharing off), run 1 / run 2 | 0.226 / 0.250 | 0.848 / 0.718 | 1.933 / 2.676 |
| `lineMixed` (chosen, sharing on) | 0.431 | 0.816 | 1.981 |
| `scatterMixed` (chosen, sharing off) | 0.675 | 2.121 | 7.675 |
| `lineParsed` (as `lineMixed`, with parsing) | 0.515 | 1.106 | 3.197 |
| `lineBounds` / `lineSuggested` | 0.385 / 0.433 | 0.847 / 0.750 | 1.719 / 2.339 |
| `scatterBounds` / `scatterSuggested` | 0.697 / 0.663 | 2.637 / 2.549 | 8.216 / 8.423 |

- The draw times of all configs are equal within the noise: 1.18-1.24 ms at 1000, 5.97-6.46 ms at
  5000, 23.7-25.3 ms at 20000. The draw makes the same point calls. The line forms add one
  `save`, `rect`, `clip` and `restore` for the clip.
- Upstream, the line controller costs about 2 to 3 times the update of the gallery class, and
  the scatter controller about 3 times the update of the gallery class without sharing. The
  scatter cost comes from `getMaxOverflow`: 2N resolves and copies for each update.

### 2.2 Options for the stress charts

| Option | Behavior | Performance | Structure | Code |
|---|---|---|---|---|
| A. Keep `StressPointController` beside the ported controllers | Not the ported path | Fastest (no scales) | A gallery copy of a ported class | 369 lines kept |
| B. Line and scatter on visible linear scales | Ported path | Adds the scale draw, which the phase 5 figures do not have | Upstream | Config only |
| C. Line and scatter on hidden linear scales with `min: 0, max: 1` on both axes | **Drops points from the draw**: the data of the stress mode is not sorted, and `_getStartAndCountOfVisiblePoints` (`helpers.extras.ts:88-133`) searches it with `_lookupByKey` (`helpers.collection.ts:51-61`). P1 trap: 6 points with `x = 1` at index 2 give `drawCount` 3 | Skips both `getMinMax` scans | Upstream | Config only |
| D. As C with `suggestedMin`/`suggestedMax` on both axes | All points drawn (P1 trap: `drawCount` 6) | Adds the O(N) `getMinMax` scan of y (`core.scale.js:303-318`) | Upstream | Config only |
| E. As D on x, and `min`/`max` on y (chosen) | All points drawn (P1 trap: `drawCount` 6). x range [0, 1] | No y scan (`core.scale.js:307-309`). The x scan reads 2 points (`core.datasetController.js:625`, `:644-655`) | Upstream | Config only |
| F. As E with `parsing` on | All points drawn; the parse finds the order | +0.08 / +0.29 / +1.22 ms against E (P1) | Upstream | One key less |

Choice: **E**, with `parsing: false` as before.

- C fails rank 1 of the protocol: the draw loses points (`core.datasetController.js:719-728`
  draws `_drawStart` to `_drawStart + _drawCount`). `StressPointField` clamps a point to exactly
  1 at each bounce (`lib/demo/stress_chart_config.dart:81-88`), so the trap happens in the stress
  runs.
- `parsing: false` needs sorted data (`docs/general/data-structures.md:74`). The data of the mode
  `chart` is not sorted, as before (`stress_point_controller.dart:116-119` also set
  `sorted = true`). With E, the misuse changes no result: the x scan reads the first and the last
  point (`core.datasetController.js:625`), and `suggestedMin: 0` and `suggestedMax: 1` give the
  range [0, 1] in any case (P1: `xRange` [0, 1]). The stress charts have `events: []`, so no
  binary search of an interaction mode runs.
- F is slower and changes the phase 5 scenario (the parse was not in the before figures).
- A is the form of Chart.js ADR 0021 §8 before phase 7. That ADR says that phase 7 removes the
  class.

### 2.3 The choice for each use

| Use | Before | After |
|---|---|---|
| Stress mode `chart`, `SHARING=1` (cases a, b, c and `CALL=animate`) | `stressPoint`, sharing on, no scales | `type: 'line'`, `showLine: false`, `parsing: false`, scales E |
| Stress mode `chart`, `SHARING=0` | `stressPoint`, sharing off, no scales | `type: 'scatter'`, `parsing: false`, scales E |
| Stress mode `axes` | `stressPoint`, sharing on, visible scales | `type: 'line'`, `showLine: false`, `parsing: false`, the same scales |
| Benchmark `chart.*` and `axes.*` | as the stress modes | as the stress modes |
| Core tab | `stressPoint`, fraction path | `type: 'line'`, scales E, `parsing` on, the line shown |
| Axes tab | `stressPoint`, scale path, `parsing: true` | `type: 'line'`, the line shown |
| `test/chart_canvas_test.dart` | `stressPoint` | `type: 'line'` |

- The Core and Axes tabs show the line: it is the default of a line chart (`controller.line.js:17`),
  so the config needs no key. Their data is sorted by x (`core_demo.dart:171`,
  `axes_demo.dart:256-260`). The tabs then show the ported `LineController` and `LineElement`.
- The stress charts hide the line (`showLine: false`). The draw then makes the point calls of the
  before figures, and the acceptance of Chart.js ADR 0021 §8 (mode `chart` against `elements`
  with `LINE=0`) stays valid.
- The define `SHARING` keeps its name and its values: `SHARING=0` gives the scatter chart, as
  `lib/main_stress.dart:95-97` already says ("as in a scatter chart"). The run scripts of the
  before figures run without a change. The STRESS and BENCH lines keep the key `sharing` and get
  the key `type` (`line` or `scatter`).
- The stress configs get `plugins: {legend: {display: false}}`. In phase 7, no legend plugin
  reads it. In phase 8, `registerables` registers the legend, which is displayed by default and
  changes the chart area. The key keeps the phase 7 figures comparable with phase 8. The tooltip
  needs no key: the charts have `events: []`.

### 2.4 Comparability

| Before scenario (`0e0ab93`) | After scenario | Same | Different (upstream work, section 2.1) |
|---|---|---|---|
| `chart` a, b, c, `CALL=animate`, sharing on | line, scales E | N, the points, the colors, the defines, the STRESS and BENCH keys, the point draw calls | 2 hidden scale updates, the dataset element, `getMaxOverflow`, the clip, chart area -5 px on each side |
| `chart` b, sharing off | scatter, scales E | as above | as above, and 2N resolves of `getMaxOverflow` |
| `axes` (4 x scales, 2 calls) | line, the same scales | as above, also the ticks and the rotation | the dataset element, `getMaxOverflow`, the clip |
| `elements` `LINE=0` (acceptance base) | unchanged | all | none |

- Step 7 reports each after figure with its before figure, and the upstream ratio of P1 as the
  expected part of the difference. A difference above that ratio is port overhead.
- The before side of an A/B in the same session is a worktree of `0e0ab93` (the measurement
  method of the phase prompt). It has `StressPointController`.

### 2.5 Delete or keep

Choice: **delete** `lib/demo/stress_point_controller.dart`.

- Chart.js ADR 0021 §8: "Phase 7 runs the same scenarios again with the ported `LineController`
  and `ScatterController`. Then it removes `StressPointController`."
- The before figures exist (`doc/phase7/perf/before/`), and the worktree of `0e0ab93` gives them
  again. A copy in the tree adds 369 lines and a second registration, and no figure that the
  worktree does not give.
- `registerGalleryComponents()` moves to a new file `lib/demo/gallery_charts.dart` with the
  scales E. It registers `registerables` once. The file has no `invalid_use_of_internal_member`
  ignore: the gallery no longer subclasses `DatasetController`.

Code form:

```dart
// Original code, not ported from Chart.js: the registration and the scales of the gallery charts.

bool _registered = false;

/// Registers the built-in components (`registerables`, as
/// `src/index.umd.ts:28` does) once. After phase 7 they include the
/// controllers.
void registerGalleryComponents() {
  if (_registered) return;
  _registered = true;
  Chart.register(registerables);
}

/// The hidden linear scales of the fractions 0 to 1, for the Core tab and
/// the stress mode `chart`. x has suggested bounds: user bounds with data
/// that is not sorted drop points from the draw
/// (helpers.extras.ts:100-132). y has user bounds: no scan of the data
/// (core.scale.js:307-309).
AnyObject fractionScales() => <String, Object?>{
  'x': <String, Object?>{
    'type': 'linear',
    'display': false,
    'suggestedMin': 0.0,
    'suggestedMax': 1.0,
  },
  'y': <String, Object?>{
    'type': 'linear',
    'display': false,
    'min': 0.0,
    'max': 1.0,
  },
};
```

`lib/demo/stress_chart_config.dart`, the body of `stressChartConfig` (the signature does not
change):

```dart
AnyObject stressChartConfig({
  required List<AnyObject> data,
  required bool sharing,
  required bool scriptable,
  bool animate = false,
  AnyObject options = const {},
  List<Object?> plugins = const [],
}) => <String, Object?>{
  // SHARING=1: a line chart without its line. SHARING=0: a scatter chart.
  'type': stressPointsType(sharing),
  'data': <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'data': data,
        'showLine': false,
        'backgroundColor': scriptable
            ? stressScriptableBackground
            : stressChartBackground,
        'borderColor': '#36A2EB',
        'borderWidth': 1.0,
        'pointStyle': 'circle',
        'radius': 3.0,
      },
    ],
  },
  'options': <String, Object?>{
    'animation': animate
        ? <String, Object?>{'duration': stressAnimateMs, 'loop': true}
        : false,
    'events': <String>[],
    'maintainAspectRatio': false,
    'parsing': false,
    'scales': fractionScales(),
    'plugins': <String, Object?>{
      'legend': <String, Object?>{'display': false},
    },
    ...options,
  },
  'plugins': <Object?>[...plugins],
};

/// The chart type of the stress mode `chart`: `line` with the option
/// sharing, `scatter` without (controller.line.js:35-39).
String stressPointsType(bool sharing) => sharing ? 'line' : 'scatter';
```

`stressAxesConfig` (`lib/demo/stress_axes.dart:147-171`) keeps its body: its `scales` option
replaces `fractionScales()`, because `...options` comes last.

## 3. New stress cases for the other controllers

### 3.1 Options

| Option | Behavior | Performance | Structure | Code |
|---|---|---|---|---|
| A. One new mode `type` and the define `TYPE`; each case is the docs sample of the type scaled to N items, with `parsing` on and the default scales (chosen) | The path of a user chart | The cost that step 7 must rank, also the label cost of the category and radial scales | Upstream configs | One enum, one scene class, one config function |
| B. One new `StressMode` for each type (`MODE=bar`, ...) | As A | As A | As A | 5 or 6 more modes; the mode row gets 11 or 12 segments, too narrow on a phone |
| C. As A with `parsing: false`, data in the internal format and linear index axes | Not the default path of a user | Faster: no parse, no category labels | Upstream configs with a changed shape | More data code for each type |
| D. Only the frameless benchmark | As A | Times only: no FPS, no raster time, no CPU profile in the stress entry | — | Less code, but step 7 needs the stress entry for the CPU profiles (`performance.md` §10.10, §11.6) |

Choice: **A**. It reuses the pattern of the mode `axes`: one mode, one define, one control row.

### 3.2 The cases

`enum StressChartType { bar, bubble, doughnut, line, polarArea, radar }`. The name is the chart
type id. `line` is the line chart with its line, which the mode `chart` does not measure. The
mode `chart` keeps the line and scatter cases without the line. `pie` uses the doughnut code
(`controller.pie.js` sets only defaults) and is not a case.

| Type | Data of N items | Labels | Scales |
|---|---|---|---|
| bar, line | numbers `1 + 99 * y` | `P0` to `P<N-1>` | category x, linear y (defaults) |
| doughnut | numbers `1 + 99 * y` (above 0) | `P0` ... | none |
| polarArea, radar | numbers `1 + 99 * y` | `P0` ... | r radialLinear |
| bubble | `{x: 100 * x, y: 100 * y, r: 3 + i % 5}` | none | linear x and y |

- The positions come from `StressPointField` (seed 7), as in the other modes. An update writes
  the moved values into the data array in place. The update parses all items again
  (`core.datasetController.js:976-981`).
- One dataset with the colors of the mode `chart` (`rgba(54, 162, 235, 0.45)`, `#36A2EB`, border
  width 1), `animation: false`, `events: []`, `maintainAspectRatio: false`,
  `plugins.legend.display: false`.
- N is 100, 1000 and 5000 for each type: the same N for each type lets step 7 rank the types.

P3 (V8, ms; `measureText` calls for each iteration):

| Type | update 100 / 1000 / 5000 | draw 100 / 1000 / 5000 | `measureText` at 5000 |
|---|---|---|---:|
| bar | 1.706 / 3.918 / 17.095 | 0.155 / 0.709 / 3.184 | 2500 |
| bubble | 0.722 / 1.554 / 6.384 | 0.057 / 0.295 / 1.420 | 0 |
| doughnut | 0.121 / 0.401 / 1.819 | 0.124 / 1.118 / 5.597 | 0 |
| line | 0.747 / 2.153 / 9.564 | 0.080 / 0.372 / 1.608 | 2500 |
| polarArea | 0.288 / 0.925 / 3.770 | 0.162 / 1.202 / 5.746 | 20 |
| radar | 0.757 / 5.243 / 27.658 | 0.759 / 7.145 / 35.713 | 5020 |

- Each upstream case stays below 36 ms in V8, so 5000 is a usable top count. The category axis
  measures N/2 labels for each update (bar, line), and the radar measures N + 20 labels and draws
  N point labels. These are the upstream paths of `performance.md` §11.6 and §11.8 item 1.
- The frameless benchmark keeps its global define `N`. The type cases run with
  `--dart-define=CASES=type --dart-define=N=100,1000,5000`.

### 3.3 Defines and lines

| Entry | Define | Values |
|---|---|---|
| `lib/main_stress.dart` | `MODE=type` | the new mode; default scenarios `100x0`, `1000x0`, `5000x0` |
| `lib/main_stress.dart` | `TYPE` | `bar` (default), `bubble`, `doughnut`, `line`, `polarArea`, `radar`; another name throws an `ArgumentError` at the start |
| `lib/main_stress.dart` | `CALL` | `draw` or `update`; `animate` throws in the mode `type`, as in the mode `axes` |
| `lib/main_bench.dart` | `CASES` | `type`, `type.bar`, `bar`, ... (the existing selector rule: mode, name or both) |

- STRESS line of the mode `type`: the keys of the mode `axes` without the scale keys: `call`,
  `type`, `layoutMs`, `datasetsUpdateMs` and `datasetsDrawMs` (the hooks of `StressAxesTiming`,
  which time any chart).
- BENCH line of a `type` case: `mode: 'type'`, `case: <type>`, the key `type`, and the parts
  `layout`, `datasetsUpdate` and `datasetsDraw`.
- The type cases come last in `chartBenchCases`. A default run then times the `chart` and `axes`
  cases first, in the thermal state of the before runs.
- Example: `flutter build apk --profile --target-platform android-arm64 -t lib/main_stress.dart
  --dart-define=MODE=type --dart-define=TYPE=doughnut --dart-define=CALL=update
  --dart-define=SCENARIO=1000x0`.

### 3.4 The stress tab

The mode row gets the segment `type` (key `stress.mode.type`): 7 segments (`prim`, `elem`,
`bars`, `arcs`, `chart`, `axes`, `type`). In the mode `type`, the rows are: start and options,
mode, N, M, call (draw, upd), type. The type row has the segments `bar`, `bub`, `dnut`, `line`,
`polar`, `radar` with the keys `stress.type.<name>` and the full names as tooltips. That is 6
rows, one less than the mode `axes`, whose chart is in view on the Pixel 8a (commit `4eda459`).
A new N or type makes a new chart (the `KeyedSubtree` key of `stress_demo.dart:1410-1423` gets
the type).

### 3.5 Code form

`apps/chartjs_gallery/lib/demo/stress_types.dart` (port-only):

```dart
/// The chart types of the stress mode `type` (`--dart-define=TYPE=<name>`).
/// The name is the `type` of the chart config.
enum StressChartType { bar, bubble, doughnut, line, polarArea, radar }

/// The data of a chart of the stress mode `type`: N items in the shape of
/// the docs sample of the type, with the values of a `StressPointField`.
final class StressTypeScene {
  StressTypeScene(this.n, {required this.type, required StressPointField positions})
    : labels = [
        if (type != StressChartType.bubble)
          for (var i = 0; i < n; i++) 'P$i',
      ],
      data = [for (var i = 0; i < n; i++) _item(type, positions, i)];

  final int n;
  final StressChartType type;

  /// `data.labels`: empty for a bubble chart.
  final List<Object?> labels;

  /// The numbers, or the objects `{x, y, r}` of a bubble chart.
  final List<Object?> data;

  /// A value from 1 to 100: above 0, as an arc needs.
  static double value(double fraction) => 1 + 99 * fraction;

  static Object _item(StressChartType type, StressPointField p, int i) =>
      type == StressChartType.bubble
          ? <String, Object?>{'x': p.x[i] * 100, 'y': p.y[i] * 100, 'r': 3.0 + i % 5}
          : value(p.y[i]);

  /// Writes the positions of [positions] into [data], in place. Each
  /// update parses all items again (core.datasetController.js:976-981).
  void write(StressPointField positions) {
    for (var i = 0; i < n; i++) {
      if (type == StressChartType.bubble) {
        (data[i]! as AnyObject)
          ..['x'] = positions.x[i] * 100
          ..['y'] = positions.y[i] * 100;
      } else {
        data[i] = value(positions.y[i]);
      }
    }
  }
}

/// The config of a chart of the stress mode `type`: the default scales and
/// the default parsing of the type.
AnyObject stressTypeConfig({
  required StressTypeScene scene,
  AnyObject options = const {},
  List<Object?> plugins = const [],
});
```

`lib/bench/chart_bench.dart`:

```dart
ChartBenchCase _typeCase(StressChartType type, ChartBenchCall call) =>
    ChartBenchCase(
      mode: 'type',
      name: type.name,
      call: call,
      keys: {'type': type.name},
      scene: (n) {
        registerGalleryComponents();
        final field = StressPointField(n);
        final scene = StressTypeScene(n, type: type, positions: field);
        final timing = StressAxesTiming();
        return ChartBenchScene(
          config: stressTypeConfig(
            scene: scene,
            options: chartBenchOptions,
            plugins: [timing.plugin],
          ),
          change: () {
            field.step(n, chartBenchStep);
            scene.write(field);
          },
          takeParts: timing.take,
        );
      },
    );

final List<ChartBenchCase> chartBenchCases = [
  // ... the current cases, unchanged ...
  for (final type in StressChartType.values)
    for (final call in ChartBenchCall.values) _typeCase(type, call),
];
```

`StressMode.type([100, 1000, 5000], 'chart items')`, and `runsChart` includes it.

## 4. `types.Chart` and the analyzer

| Option | Code | Guard |
|---|---|---|
| A. `DemoChart` (`lib/demo/demo_chart.dart:40`) implements each new member of `types.Chart` with a "no datasets" result (chosen) | About 2 lines for each member | The analyzer fails until the member exists |
| B. `DemoChart` gets `noSuchMethod`, as `_DemoChart` of `lib/demo/ticks_demo.dart:20-28` | 1 line, once | None: a missing member throws at run time |
| C. Replace `DemoChart` with a real `Chart` in the phase 3 tabs | A rewrite of 5 tabs | Not needed by phase 7 |

Choice: **A**. `DemoChart` drives the animator and the platform, so a compile error is better
than a `NoSuchMethodError` at run time. B stays for `_DemoChart`, `_DemoScale` and `_DemoTick` of
the ticks tab, which use only 2 members.

- The members that the scout lists as absent from `types.Chart` (`members-radial.md` §2.5):
  `isDatasetVisible`, `getVisibleDatasetCount`, `toggleDataVisibility`, `update` and `legend`.
  The interfaces-values panel decides which of them become interface members. For each one:

```dart
/// The demo chart has no datasets.
@override
bool isDatasetVisible(double datasetIndex) => false;

/// The demo chart has no datasets.
@override
double getVisibleDatasetCount() => 0;

/// The demo chart has no data.
@override
void toggleDataVisibility(double index) {}

/// An update of the demo chart is a render.
@override
void update([String? mode]) => render();

/// The demo chart has no legend.
@override
Object? get legend => null;
```

- The rule for the port waves: the agent that adds a member to a type interface that the gallery
  implements also adds it to the gallery class in the same unit. The integration agent owns
  `apps/chartjs_gallery/lib/demo/demo_chart.dart`. The wave gate `dart run melos run analyze`
  (`dart analyze --fatal-infos` over the workspace, `pubspec.yaml:27-29`, the workspace includes
  `apps/chartjs_gallery`, `pubspec.yaml:12`) finds a miss.
- After the deletion of `StressPointController`, no gallery class extends `DatasetController`,
  and the gallery has no `invalid_use_of_internal_member` ignore. The `noSuchMethod` classes of
  the ticks tab (`Chart`, `Scale`) compile with any new member.

## 5. The layout rule

| Option | Rule kept | Code |
|---|---|---|
| A. Restyle every page of the gallery now (phases 2 to 6 too) | Everywhere | All tabs; the Axes tab has about 24 controls, which cannot all be above a chart that is in view |
| B. Apply the rule to the pages that phase 7 adds and to the stress rows that it adds; pin "chart in view" for every page with a chart that phase 7 touches (chosen) | On the new pages; in-view on Core and Axes | New pages only |
| C. Only the type pages | On the new pages | Least |

Choice: **B**.

- The type pages have at most one control row (the variant), then the chart, then the readout and
  the help text. No chips, no menus, no horizontal scroll. The variant row uses `SegmentChoice`
  (`lib/demo/demo_controls.dart:166-227`), short texts (`vertical`, `horizontal`, `doughnut`,
  `pie`).
- The stress mode `type` adds one `SegmentChoice` row with short texts, as the mode `axes` does.
- The Core and Axes tabs change only their chart config in phase 7. Their help text is above the
  chart and their controls are below it: no control row is above the chart. The test of section
  7 pins that their chart is in view at the Pixel 8a size. A restyle of their controls into
  `SegmentChoice` rows is a separate gallery change: the integration list of phase 7 records it
  for the maintainer.

## 6. Files that the implementation changes

`apps/chartjs_gallery/`:

| File | Change |
|---|---|
| `lib/main.dart` | `chartTypes` moves to `lib/chart_types.dart`; the tiles open the pages (section 1.5); the text of the first tile |
| `lib/chart_types.dart` (new) | `ChartTypeEntry`, `ChartTypeVariant`, `chartTypes`, `ChartTypePage` |
| `lib/samples/chart_samples.dart` (new) | The 13 config functions of section 1.2 |
| `lib/demo/stress_point_controller.dart` | Deleted |
| `lib/demo/gallery_charts.dart` (new) | `registerGalleryComponents`, `fractionScales` |
| `lib/demo/stress_chart_config.dart` | The body of `stressChartConfig`, `stressPointsType` |
| `lib/demo/stress_axes.dart` | Doc comments: `LineController`, `parsing: false` from the config |
| `lib/demo/stress_types.dart` (new) | `StressChartType`, `StressTypeScene`, `stressTypeConfig` |
| `lib/demo/stress_demo.dart` | `StressMode.type`, the type row, the type in the host key, the readout of the parts, the source text |
| `lib/main_stress.dart` | `TYPE`, `CALL` check, the keys `type` (modes `chart` and `type`) |
| `lib/bench/chart_bench.dart` | `_typeCase`, the key `type` of the `chart` cases, the doc comment of `chartBenchCases` |
| `lib/main_bench.dart` | Doc comment: the `type` cases |
| `lib/demo/core_demo.dart` | `type: 'line'`, `scales: fractionScales()`, the doc comment and the source text |
| `lib/demo/axes_demo.dart` | `type: 'line'`, the doc comment and the source text |
| `lib/demo/demo_chart.dart` | The new members of `types.Chart` (section 4) |
| `lib/canvas_host_demo.dart` | Doc comment: the controllers of phase 7 |
| `test/*` | Section 7 |

Docs: `packages/flutter_chartjs/doc/performance.md` §6 (the mode `chart` with line and scatter,
the mode `type`, the type cases of the benchmark), `AGENTS.md` (the gallery paragraph: "Phase 7
replaces `StressPointController`" becomes the current state, the type pages), the new Chart.js
ADR 0031 (proposed), and `doc/phase7-progress.md` (the decisions).

## 7. Tests that pin the decisions

| Test file | What it pins |
|---|---|
| `test/gallery_test.dart` | The 9 tiles with the keys `gallery.type.<entry>`, in the docs order; 8 tiles with `check_circle_outline`; the Area tile with `timelapse` and its note; no tile disabled |
| `test/chart_types_test.dart` (new) | For each entry and variant (13 charts): the tap on the tile opens the page; `chart.config.type`; the `meta.type`, the controller class (`isA<BarController>()`, ...) and the element count of each dataset; the scale ids and types of the P2 table; no exception; the host rect inside the view at the Pixel 8a size (`tester.view.physicalSize = Size(1080, 2400)`, `devicePixelRatio = 2.625`); the variant segment makes a new chart of the other type (doughnut and pie); the Area config has `fill: 'origin'` and the filler is not enabled (`chart.isPluginEnabled('filler')` is false); the readout `active` after a hover on an element |
| `test/core_demo_test.dart` | `chart.config.type` is `line`; the controller is a `LineController`; `meta.dataset` is a `LineElement`; the point pixels are `getPixelForValue` of the hidden scales; the shared `PointOptions` stay; the chart host is in view at the Pixel 8a size |
| `test/axes_demo_test.dart` | `chart.config.type` is `line`; the controller is a `LineController`; the chart host is in view at the Pixel 8a size |
| `test/chart_canvas_test.dart` | The type `line` |
| `test/chart_bench_test.dart` | `chart.a` has the type `line`; `chart.b` with sharing off has the type `scatter` and a `ScatterController`; each BENCH line of a `chart` case has `sharing` and `type`; the x scale has the range [0, 1] and every point is drawn (`_drawCount` is N) with data that has a point at `x = 1` in the middle (the trap of P1); `selectChartBenchCases('type')` gives 12 cases after all `chart` and `axes` cases; one tiny run of each type case (N = 10) gives its parts and N elements, and the values move after an update |
| `test/stress_chart_test.dart` | The mode `chart` makes a line chart (sharing on) and a scatter chart (sharing off); the STRESS keys `type` |
| `test/stress_type_test.dart` (new) | The mode `type`: the rows and the keys `stress.mode.type`, `stress.type.<name>`; `animate` is not offered; a new type makes a new chart; the STRESS line of `StressProfileApp(mode: StressMode.type, ...)` has `type`, `call` and the parts; the chart host is in view at the Pixel 8a size |
| `test/stress_axes_test.dart` | The controller is a `LineController` with no line drawn (`showLine: false`) |
| `test/elements_demo_test.dart`, `test/canvas_host_demo_test.dart` | No change, unless they name `StressPointController` |

Each test file that imports `flutter_test` keeps the gallery form of the current tests (the
gallery tests do not run in `test:web`).
