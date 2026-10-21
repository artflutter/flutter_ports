# Draft (performance first): gallery chart types and the stress controller

- Panel: "Gallery chart types and the stress controller" (future Chart.js ADR 0031). This file is
  one of three independent drafts. The lens of this draft is performance first: it looks for the
  fastest forms that keep the behavior that Chart.js ADR 0009 protects, and it measures them.
- Pin: Chart.js `v4.5.1+7169e651` (`third_party/Chart.js` at `7169e65147a4`). The gallery tree is
  at commit `4eda459`. The phase 5 and phase 6 "before" figures are at commit `0e0ab93`
  (`doc/phase7/perf/before.md`, recorded by another agent).
- Scratch folder of the evidence (below: `<gp>`):
  `/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/gallery-performance/`.
  `<gp>/README.txt` gives the command of each probe.

## 1. Summary of the choices

| Question | Choice |
|---|---|
| 1. Chart type pages | One route for each entry of the list, with one live chart. The config of each page is the first example of `docs/charts/<type>.md` (Area: `docs/samples/area/line-boundaries.md`), with the sample actions as controls. A control writes the user config and calls `chart.update()`, as the upstream sample actions do. It never makes a new chart. The hover readout replaces the tooltip until phase 8. A `ValueNotifier` updates it, so a hover does not build the page again. Area renders its line datasets with their `fill` option. Without `plugin.filler`, the fill does not draw (phase 8), and the list marks Area as "partial". The list status is a static field. The home page makes no chart. |
| 2. Replacement of `StressPointController` | Delete the class. The mode `chart` (and the Core tab) use `type: 'line'` with `showLine: false` (`SHARING=1`) and `type: 'scatter'` (`SHARING=0`) on two hidden linear scales: `display: false`, `ticks.display: false`, `min: 0`, `max: 1` (y) and `max: 1 + 2^-20` (x), with `parsing: false`, `layout.autoPadding: false` and the dataset option `clip: false`. These give the pixels of the phase 5 fraction path (G1), the same chart area and the same dataset draw (G1, G3, G6). The x max above 1 keeps all N points visible with unsorted x (G2). The mode `axes` and the Axes tab use `type: 'line'`, `showLine: false`. The mode `axes` also gets `parsing: false`, `autoPadding: false` and `clip: false`, so that its chart area and its draw are those of phase 6 (G6). |
| 3. New stress cases | A define `TYPE=<line\|scatter\|bar\|bubble\|doughnut\|polarArea\|radar>` in the mode `chart`, a `type` line of icons in the stress tab, and the bench cases `chart.<type>` (draw and update) for the five new types. Each config follows `docs/general/performance.md`: `parsing: false` with the internal format, `min` and `max` on each scale, `animation: false`, hidden scales. Radar needs `min` and `max` on `r`, else its parsed range is wrong (G8). The timing plugin (`StressAxesTiming`, renamed `StressChartTiming`) runs in every chart mode and gets a fourth part, `elements` (the parse and the first `getMaxOverflow`). It adds no measurable time (G7). |
| 4. `types.Chart` and the analyzer | `DemoChart` keeps explicit members (no `noSuchMethod`). Each member that phase 7 adds to `types.Chart` gets an empty result in `DemoChart` in the same change. `dart run melos run analyze` covers `apps/chartjs_gallery`. |
| 5. Layout rule | At most four control lines above the chart on a page, each a full-width `SegmentChoice`, `SegmentToggles` or the new `SegmentActions`. Then the chart, the readout and the help text. Other parameters go after the readout. A widget test at 360 x 640 dp pins the chart in view for each page that phase 7 touches. |

## 2. Test bed and method

- Machine: Apple M3 Max, macOS 26.5.1, Flutter 3.44.9 (Dart 3.12.2).
- The Dart probes run the gallery code itself through `runChartBenchCase` of
  `lib/bench/chart_bench.dart`: a real `Chart` on an 800 x 480 `UiCanvasElement`, the default
  timing loop (warm-up 600 ms, 11 batches of 150 ms), the median of the batches.
  - "JIT" is `flutter test` (`flutter_tester`, arm64, JIT with checked mode). 4 rounds. Even
    rounds run the cases in reverse order. A cell is the median of the 4 rounds.
  - "wasm" is `flutter test --platform chrome --wasm` (headless Chrome). 2 rounds, the second in
    reverse order. A cell is the mean of the 2 rounds.
  - These are relative figures on a machine with other load (load average 6-7). They compare forms
    inside one process. They are not the figures of `performance.md` §6, and they do not replace
    the Pixel 8a A/B of step 7.
- The probes run in a copy of the work tree (`<gp>/repo/`), so they do not touch the build folder
  of `apps/chartjs_gallery`, which the "before" agent uses. The only change in the copy:
  `StressPointController` is a `base class`, so that a probe can subclass it.
- `StressPointController` on its scale path is the proxy of `LineController.updateElements`: its
  `_updateOnScales` is the port of `controller.line.js:76-120`. The probes cannot run the ported
  controllers, because they do not exist yet.
- The upstream probes run Chart.js built at the pin in the x64 Node.js v24.12.0 under Rosetta
  (Chart.js ADR 0010), through `loadChartJs` and `makeChart` of
  `tool/reference/scale_chart_common.mjs`. Their times are relative only.
- No probe ran on the Pixel 8a (the "before" agent uses it), on macOS or in a Chrome window
  (no maintainer window).

## 3. Evidence

### U1: upstream source (read at the pin)

- `core.scale.js:303-309`: `getMinMax` returns the user `min` and `max` when both are defined. It
  then does not call the `getMinMax` of a controller (no O(N) pass).
- `core.datasetController.js:451-462`: with `parsing: false`, `parse` sets `meta._parsed = data`
  and `meta._sorted = true`, without a check of the order.
- `core.datasetController.js:622-660`: `getMinMax(scale)` reads only the first and the last
  parsed item when `meta._sorted` and `scale === meta.iScale`.
- `helpers.extras.ts:88-128` with `helpers.collection.ts:20-61`: `_getStartAndCountOfVisiblePoints`
  makes a binary search over `_parsed` for the user `min` and `max` of the index scale when
  `meta._sorted`. The `last` comparison of `_lookupByKey` is
  `ti < value || ti === value && table[index + 1][key] === value`.
- `controller.line.js:41-74` and `controller.scatter.js:56-99`: both call
  `_getStartAndCountOfVisiblePoints`. Bubble (`controller.bubble.js:111-116`) and radar
  (`controller.radar.js:52-77`) update all points.
- `core.datasetController.js:701-705` and `core.controller.js:500-508`: each update calls
  `getMaxOverflow()` twice. JS evaluates the argument of `valueOrDefault` first, so a dataset
  `clip` option does not skip the call.
- `controller.scatter.js:155-166` (with `showLine: false`) and `controller.bubble.js:83-91`:
  `getMaxOverflow` resolves the options of each point (O(N)). `controller.line.js:125-136` reads
  the first and the last point only.
- `core.layouts.js:405` with `:109-114`: the overflow (`minPadding`) is a lower bound of the
  padding on each side when `layout.autoPadding` is true. `core.datasetController.js:12-36`:
  `defaultClip` gives `false` (no clip) only for an overflow of `false`.
- `core.scale.js:457-461`: the auto skip measures the tick labels when `ticks.display` is true,
  also for a scale with `display: false`. `core.scale.js:595-597`: no label rotation for a hidden
  scale.
- `core.scale.js:372-373`: `beforeLayout` clears `_cache`. Thus `controller.bar.js:24-53`
  (`computeMinSampleSize`, through `_getRuler` at `:532-544`) sorts all values in each update,
  unless `barThickness` is set.
- `controller.line.js:35-39`, `controller.bar.js:380`, `controller.bubble.js:38` and
  `controller.doughnut.js:136` set `enableOptionSharing`. Scatter, polar area and radar do not.
- `docs/general/performance.md:9` (`parsing: false` with the internal format), `:33-45` (no
  animation), `:50-52` (`min` and `max`), `:142-157` (`showLine: false`).
  `docs/general/data-structures.md:74`: "If parsing is disabled, data must be sorted".
- The sample actions write the config and call `chart.update()`:
  `docs/samples/bar/vertical.md:7-62`.

### G1: the hidden unit scales give the fraction path (`<gp>/repo/apps/chartjs_gallery/test/probe_chart_mode_test.dart`)

The phase 5 config against the same config with two linear scales `display: false`, `min: 0`,
`max: 1`, `layout.autoPadding: false` and `clip: false`, at the first update:
- Chart area: `0, 0, 800, 480` on both sides.
- The point pixels: `max |dx| = 0` and `max |dy| = 5.7e-14` px (N = 10 and 1000). The y pixel of
  the scale is `top + (1 - y) * h`, and the fraction path computes `bottom - y * h`.
- Upstream (`<gp>/parsing_probe.out` §2, the same scales without `autoPadding: false`): the same
  differences, and the chart area `5, 5, 795, 475`. The 5 px are the overflow of a point
  (`(max(radius 3, hoverRadius 4) + borderWidth 1)`), so `autoPadding: false` is necessary for the
  phase 5 area.

### G2: `parsing: false` with unsorted x and a user max (`<gp>/repo/apps/chartjs_gallery/test/probe_sorted_test.dart`, output `<gp>/probe_sorted.txt`)

5000 points of `StressPointField`, 600 frames of `step` and `update('none')`, the worst frame:

| x max | `parsing` | Points with `skip` or a wrong pixel |
|---|---|---:|
| 1 | false | 1250 of 5000 |
| 1 | true | 0 |
| 1 + 2^-20 | false | 0 |
| 1 + 2^-20 | true | 0 |

- The field clamps a position at exactly 1 (`StressPointField.step`). The `last` search of U1 then
  stops at a point with `x === 1` and cuts the count. The line controller marks the points after
  the cut as `skip`, and the scatter controller does not update them. The draw then has fewer
  points: the figures do not compare, and the scene is wrong.
- With `max = 1 + 2^-20`, each `ti < max`, so the search gives the full range for any order of the
  data. The x pixel moves by at most `800 * 2^-20 = 7.6e-4` px.
- `parsing: true` also fixes it: `parse` then finds the order and sets `_sorted` to false. G3
  gives its cost.

### G3: the cost of the forms of the mode `chart` (`<gp>/repo/apps/chartjs_gallery/test/probe_chart_mode2_test.dart`, outputs `<gp>/probe_chart_mode2_jit.txt` and `<gp>/probe_chart_mode2_wasm.txt`)

- `frac`: the phase 5 config (fraction path, no scales).
- `eps`: the choice: hidden unit scales, `ticks.display: false`, x max `1 + 2^-20`,
  `parsing: false`, `autoPadding: false`, `clip: false`.
- `parsed`: as `eps`, with x max 1 and `parsing: true`.
- No probe point has `skip` after the last batch.

`update('none')` without its draw, in ms:

| Sharing | N | frac JIT | eps JIT | parsed JIT | frac wasm | eps wasm | parsed wasm |
|---|---:|---:|---:|---:|---:|---:|---:|
| on (line) | 1000 | 0.093 | 0.232 | 0.367 | 0.132 | 0.278 | 0.409 |
| on | 5000 | 0.290 | 0.516 | 1.368 | 0.454 | 0.660 | 1.328 |
| on | 20000 | 0.990 | 1.590 | 6.408 | 1.738 | 2.227 | 5.130 |
| off (scatter) | 1000 | 0.164 | 0.304 | 0.457 | 0.243 | 0.383 | 0.528 |
| off | 5000 | 0.671 | 0.908 | 1.692 | 1.024 | 1.245 | 1.925 |
| off | 20000 | 3.079 | 3.734 | 8.579 | 4.018 | 4.544 | 7.421 |

`draw()` (case a), in ms: frac 0.181 / 0.922 / 3.706 and eps 0.188 / 0.933 / 3.688 (JIT, N = 1000
/ 5000 / 20000); frac 0.182 / 0.902 / 3.652 and eps 0.184 / 0.907 / 3.612 (wasm).

- The draw of `eps` equals the phase 5 draw. Case (a) stays comparable.
- The update of `eps` costs about 0.14 ms more at 1000 points and 0.6 ms more at 20000 (JIT). The
  constant part is the layout of the two hidden scales. The part for each point is
  `getPixelForValue` against the inline arithmetic of the fraction path.
- `parsing: true` costs 2.5 to 4 times the update of `eps` at 20000 points. It allocates one
  parsed object for each point in each update. The garbage collection also falls into the next
  draw: after a `parsed` update at 20000 points, the draw takes 4.87-6.60 ms against 3.88-4.15 ms
  (JIT).

### G4: `ticks.display: false` on a hidden scale (`<gp>/probe_chart_mode_jit.txt`, `<gp>/probe_chart_mode_wasm.txt`)

The first probe compared hidden scales with and without `ticks.display: false` (x max 1, so both
sides have the bias of G2). The update with sharing, in ms:

| N | ticks shown, JIT | `ticks.display: false`, JIT | ticks shown, wasm | `ticks.display: false`, wasm |
|---:|---:|---:|---:|---:|
| 1000 | 0.303 | 0.243 | 0.340 | 0.288 |
| 5000 | 0.589 | 0.531 | 0.752 | 0.680 |
| 20000 | 1.602 | 1.573 | 2.252 | 2.181 |

- The saving is a constant of 0.03-0.07 ms: the auto skip of U1 (`core.scale.js:457`) measures
  the 11 labels of each hidden scale. The option is valid upstream and changes no pixel of a
  hidden scale.

### G5: the overflow of the scatter controller (G3 runs, case `epsOverflow`)

`epsOverflow` is `eps` without sharing, with the `getMaxOverflow` of `controller.scatter.js:155-166`
added to the proxy. The update in ms, and the difference to `eps`:

| N | eps JIT | epsOverflow JIT | difference | eps wasm | epsOverflow wasm | difference |
|---:|---:|---:|---:|---:|---:|---:|
| 1000 | 0.304 | 0.507 | +0.20 | 0.383 | 0.747 | +0.36 |
| 5000 | 0.908 | 1.842 | +0.93 | 1.245 | 2.964 | +1.72 |
| 20000 | 3.734 | 8.424 | +4.69 | 4.544 | 11.522 | +6.98 |

- This is upstream work (U1): two calls in each update, each with a `clone` of the cached options
  for each point (no sharing). The ported `ScatterController` has it, `StressPointController` did
  not. Thus the `chart.b` figure without sharing grows in phase 7 by an upstream cost. The new
  part `elements` of the timing plugin shows the first call (section 6).

### G6: the dataset clip and the circle batch (`<gp>/repo/apps/chartjs_gallery/test/probe_clip_test.dart`, output `<gp>/probe_clip_jit.txt`)

The chart of the mode `axes` (linear x and y), with the dataset `clip` of a line chart (5 px)
against no clip (phase 6: the overflow of `StressPointController` is `false`). JIT, ms:

| N | draw, no clip | end, no clip | draw, clip 5 | end, clip 5 | draw + end, no clip | draw + end, clip 5 |
|---:|---:|---:|---:|---:|---:|---:|
| 1000 | 0.241 | 0.056 | 0.288 | 0.016 | 0.297 | 0.304 |
| 5000 | 1.022 | 0.220 | 1.234 | 0.021 | 1.242 | 1.254 |
| 20000 | 3.907 | 0.819 | 4.841 | 0.034 | 4.726 | 4.874 |

- The clip area ends with `restore`, which draws the pending circles of the circle batch
  (`performance.md` §5.4) inside `draw()`. Without a clip, they draw at the end of the recording.
  The sum changes by 1-3 %, but `drawMs` grows by 24 % at 20000 points. Thus the `drawMs` of the
  ported line chart with its default clip does not compare with the phase 6 figure. `clip: false`
  keeps the phase 6 split.
- The chart of the mode `chart` with a clip of 0 px could not be probed: the proxy has no overflow,
  so `defaultClip` gives no clip. The same split applies to it (the ported `LineController` gives
  an overflow of 5).

### G7: the cost of the timing plugin (`<gp>/repo/apps/chartjs_gallery/test/probe_plugin_test.dart`, output `<gp>/probe_plugin_jit.txt`)

The `eps` chart with sharing, without and with the inline plugin of `StressAxesTiming`. JIT, ms:

| N | Call | Without | With |
|---:|---|---:|---:|
| 1000 | update | 0.243 | 0.243 |
| 1000 | draw | 0.198 | 0.194 |
| 20000 | update | 1.516 | 1.492 |
| 20000 | draw | 3.806 | 3.858 |

- No difference outside the spread of the rounds. The plugin can run in each chart mode.

### G8: `parsing: false` in the upstream build (`<gp>/parsing_probe.mjs`, outputs `<gp>/parsing_probe.out` and `<gp>/parsing_probe.rerun.out`; `<gp>/radar_probe.mjs`)

- §1: a chart with parsed user data and a chart with `parsing: false` and the internal format give
  the same element properties for line, scatter, bar (`{x: index, y}`), bubble (`{x, y, _custom}`),
  doughnut, pie (numbers) and polar area (`{r}`), 40 points each.
- Radar differs. `radar_probe.mjs` shows that the meta of a radar has `iScale` and `vScale` both
  `r`. With `parsing: false`, `_sorted` is true, so `getMinMax(r)` reads only the first and the
  last value (U1). The range of `r` is then wrong, and so are the ticks and the pixels (protected
  items of Chart.js ADR 0009). With `min` and `max` on `r`, `Scale.getMinMax` does not call the
  controller, and the range is correct.
- §3 (relative, x64 Node.js): the update of a bar chart costs 3-7 times the update of the line
  chart of the same N (`computeMinSampleSize` sorts all values, a category axis makes N ticks).
  This is the upstream cost that step 7 compares with the port.
- Two runs give the same §1 and §2 output.

## 4. Question 1: the chart type pages

### Upstream form

The Chart.js docs show each type in a `chart-editor` block: a config and a list of actions. Each
action changes `chart.data` or `chart.options` and calls `chart.update()`
(`docs/samples/bar/vertical.md:7-62`). The first examples of `docs/charts/*.md` have fixed data:
`bar.md:5-54`, `bubble.md:5-36`, `doughnut.md:15-47`, `line.md:5-31`, `mixed.md:27-70`,
`polar.md:7-43`, `radar.md:7-61`, `scatter.md:5-47`. `area.md` has no `chart-editor` block. The
area samples (`docs/samples/area/line-boundaries.md:3-120`) need `plugin.filler`.

### Options

1. A page for each entry, with the docs config and the sample actions as controls. A control
   writes the config and calls `chart.update()` (the upstream form).
2. As 1, but a control makes a new chart (a new `ChartCanvas` key), as the stress tab does for a
   new N.
3. One page with all nine charts in a list.
4. Area: (a) pending; (b) the area sample, which renders its lines and ignores `fill` until
   phase 8; (c) a gallery plugin that fills the areas.

### Choice

- Option 1. It is the upstream form and the fastest: an update keeps the elements and the
  resolver caches, and it animates the change with the default animation of the sample. Option 2
  builds the chart, the scales and the caches again for each tap. Option 3 keeps nine charts
  alive: each animation and each resize of one page also runs for the others.
- Area: option 4b. Upstream ignores the `fill` option when the filler plugin is not registered, so
  the page shows the upstream behavior of a build without the filler. Phase 8 registers the filler,
  and the same page then fills, with no change in the gallery. Option 4a fails the exit criterion
  "the gallery shows every chart type". Option 4c is code of our own that phase 8 deletes.
- The list status is a static field of each entry. The home page makes no chart: a start-up
  render check would cost time at each start. The tests check that each page renders.
- The hover readout: `options.onHover` writes the active elements to a `ValueNotifier`, as the
  Core tab does (`core_demo.dart:136-139`). The readout shows `getLabelAndValue(index)` of the
  controller of each active element (the text that the tooltip of phase 8 shows). The page does
  not build again on a hover.
- The chart host has the height of the stress tab: `clamp(width * 0.6, 240, 520)`. The page sets
  `maintainAspectRatio: false`. A radial chart then fits the smaller side of the host, and the
  chart stays in view (section 8).

### The pages

| Entry (`id`) | Config | Controls above the chart (keys `type.<id>.<name>.<value>`) |
|---|---|---|
| Area (`area`) | `line-boundaries.md`: one line dataset, 8 points | `fill`: false, origin, start, end; `actions`: randomize, smooth |
| Bar (`bar`) | `bar.md` | `axis`: x, y (`indexAxis`, `horizontal.md:97`); `stack`: off, on (`stacked.md:59-62`); `actions`: randomize, add data, remove data |
| Bubble (`bubble`) | `bubble.md` | `actions`: randomize, add data, remove data |
| Doughnut and Pie (`doughnut`) | `doughnut.md` | `type`: doughnut, pie (`chart.config.type`, `core.config.js:173-175`; a new meta for the new type, `core.controller.js:427-431`); `circumference`: 360, 180; `actions` |
| Line (`line`) | `line.md` | `curve`: straight, tension, monotone, stepped (`interpolation.md:19-26`, `stepped.md:10-46`); `actions` |
| Mixed (`mixed`) | `mixed.md` | `actions` |
| Polar Area (`polarArea`) | `polar.md` | `actions` |
| Radar (`radar`) | `radar.md` | `actions` |
| Scatter (`scatter`) | `scatter.md` | `line`: off, on (`showLine`, `controller.scatter.js:71-95`); `actions` |

- `type.<id>.host` is the `ChartCanvas`, and `type.<id>.readout` the readout.
- The datasets keep `parsing` at its default: the pages show the upstream user form, not the
  stress form.

### Code form

```dart
// lib/main.dart
/// Whether a chart type renders: [rendered], or [partial] when a part
/// waits for a later phase (the note says which).
enum ChartTypeStatus { rendered, partial }

/// One entry of the chart type list.
typedef GalleryChartType = ({
  String id,
  String title,
  ChartTypeStatus status,
  String note,
  WidgetBuilder page,
});

/// The chart types of the Chart.js docs, in their order.
final List<GalleryChartType> galleryChartTypes = [
  (id: 'area', title: 'Area', status: ChartTypeStatus.partial,
   note: 'Lines only. The fill needs plugin.filler (phase 8).',
   page: (_) => const ChartTypePage(sample: areaSample)),
  // bar, bubble, doughnut, line, mixed, polarArea, radar, scatter: rendered.
];
```

```dart
// lib/types/chart_type_page.dart
/// One control line of a sample: a choice of values, written into the
/// config by [apply], then `chart.update()`.
typedef SampleChoice = ({
  String name,                  // 'axis'
  String label,                 // short label of the line
  List<SegmentChoiceItem<Object?>> items,
  Object? initial,
  void Function(AnyObject config, Object? value) apply,
});

/// One action of a sample: changes `config['data']`, then `chart.update()`.
typedef SampleAction = ({String name, IconData icon, String tooltip,
    void Function(AnyObject config, math.Random random) run});

/// The config, the controls and the help text of one chart type.
typedef ChartTypeSample = ({
  String id,
  String source,                // 'docs/charts/bar.md:5-54'
  AnyObject Function() config,  // a new config for each page
  List<SampleChoice> choices,   // at most 3: the actions take the 4th line
  List<SampleAction> actions,
  String help,
});

class ChartTypePage extends StatefulWidget {
  const ChartTypePage({required this.sample, super.key});
  final ChartTypeSample sample;
}

class ChartTypePageState extends State<ChartTypePage> {
  late final AnyObject _config = widget.sample.config();
  Chart? _chart;
  final ValueNotifier<int> _readout = ValueNotifier(0);

  void _choose(SampleChoice choice, Object? value) {
    setState(() => _values[choice.name] = value);
    choice.apply(_config, value);
    _chart?.update(); // the upstream sample action form
  }
}
```

## 5. Question 2: the replacement of `StressPointController`

### What the ported controllers do that `StressPointController` does not

- They need scales. `LineController` reads `meta.iScale` and `meta.vScale`
  (`controller.line.js:78-101`). The fraction path of `StressPointController` (no scales) has no
  upstream form.
- `LineController` has a dataset element: one `LineElement` update in each update
  (`controller.line.js:56-70`) and `updateControlPoints` before each draw (`:138-142`). With
  `showLine: false`, the line has `borderWidth: 0` (`:63-65`) and draws nothing. With
  `tension: 0` (the default), `updateControlPoints` does no work.
- `ScatterController` has no option sharing, and its `getMaxOverflow` resolves the options of each
  point twice in each update (G5).
- Both call `_getStartAndCountOfVisiblePoints`, which needs sorted x with `parsing: false` (G2).
- Both give an overflow of 5 px (a point of radius 3, hover radius 4, border 1). It changes the
  chart area (G1) and adds a dataset clip (G6), unless `layout.autoPadding: false` and
  `clip: false`.
- `spanGaps` and `segment`: the line reads `spanGaps` for `stop` (`:83`, `:104`), as the proxy did.
  The config sets neither option. `segment` is undefined, so no `parsed` and `raw` writes
  (`:105-108`).

### Options for the mode `chart`

1. Keep `StressPointController` for the mode `chart` (no change of the figures).
2. The upstream defaults: `type: 'line'`, the default scales (`_index_` category,
   `controller.line.js:24-33`), parsed data.
3. Visible linear scales, `parsing: true`.
4. Hidden unit scales, `parsing: false`, x max 1 (G2: up to 25 % of the points skip).
5. Hidden unit scales, `parsing: false`, x max `1 + 2^-20`, `ticks.display: false`,
   `autoPadding: false`, `clip: false` (the choice).
6. As 5 with sorted x (fixed x positions, only y moves).

### Choice

- Option 5.
  - Behavior: each point gets the pixel of the phase 5 fraction path, within 7.6e-4 px (G1, G2).
    No point skips. Each config value is an upstream option. The upstream performance guide gives
    `parsing: false`, `min` and `max`, and `showLine: false` (U1).
  - Performance: it is the fastest form with the ported controllers. Its draw equals the phase 5
    draw (G3). Its update costs 0.14-0.6 ms more than phase 5 (JIT, G3): the hidden scales. Option
    3 costs 2.5-4 times more in the update, and it moves garbage collection into the draw (G3).
    `ticks.display: false` saves 0.03-0.07 ms of each update (G4).
  - Option 1 contradicts Chart.js ADR 0021 §8 ("Then it removes `StressPointController`") and the
    exit criterion of the prompt. Option 2 maps a random x to a category: wrong pixels. Option 4
    skips points (G2). Option 6 changes the phase 5 scene.
- The data violates the sort rule of `data-structures.md:74` (x is random). With the user bounds
  of option 5, no code path reads the order: `getMinMax` returns the user bounds (U1), and the
  search of `_getStartAndCountOfVisiblePoints` gives the full range for any order (G2). The chart
  has `events: []`, so no interaction search runs. A test pins this (section 9).
- `SHARING=1` gives `type: 'line'` with `showLine: false`, and `SHARING=0` gives
  `type: 'scatter'`. The key `sharing` of the `STRESS` and `BENCH` lines keeps its meaning.
- Delete `StressPointController`. The A/B of step 7 does not need it in the tree: the "before"
  worktree of `0e0ab93` has it. A third side isolates the controller from the config:
  - A: `0e0ab93` (the phase 5 config, fraction path).
  - A': `0e0ab93` with `<gp>/bridge-0e0ab93.patch` (option 5 on `StressPointController`, its
    scale path; the patch changes only `stress_chart_config.dart` and applies to `0e0ab93`).
  - B: the phase 7 tree.
  - A to A' is the cost of the hidden scales. A' to B is the cost of the ported controllers.
- `registerGalleryComponents` moves to `lib/demo/gallery_components.dart`. It registers
  `registerables` once (`src/index.umd.ts:28`), which then has the controllers.

### Options for the mode `axes`, the Axes tab and the Core tab

- The mode `axes`: `type: 'line'`, `showLine: false`, `parsing: false` (the data is sorted, as in
  phase 6), `layout.autoPadding: false` and `clip: false`. The last two keep the phase 6 chart area
  and the phase 6 split of `drawMs` and `endMs` (G6). Without them, the draw of the points is the
  same work, but `drawMs` at 20000 points grows by about 24 % from the batch flush alone.
- The Core tab: `type: 'line'`, `showLine: false`, `parsing: false`, the hidden unit scales
  (x max 1: the data is sorted and inside [0, 1)), `clip: false`. The padding of 20 px is larger
  than the hover overflow (13 px), so the chart area does not change. The readout keeps
  `PointOptions`, `$shared` true and frozen, because the line controller shares options.
- The Axes tab: `type: 'line'`, `showLine: false`. It keeps `parsing: true` (labels and ISO dates),
  the default clip and `autoPadding` (8 px padding, larger than the 5 px overflow). A demo page
  shows the upstream defaults, not the stress form.

### Code form

```dart
// lib/demo/stress_chart_config.dart
/// The chart types of the mode `chart` (the define `TYPE`).
enum StressChartType {
  line(stressPointCounts, sharing: true),
  scatter(stressPointCounts, sharing: false),
  bar(stressPointCounts, sharing: true),
  bubble(stressPointCounts, sharing: true),
  doughnut(stressArcCounts, sharing: true),
  polarArea(stressArcCounts, sharing: false),
  radar(stressPointCounts, sharing: false);

  const StressChartType(this.counts, {required this.sharing});

  /// The N choices: the counts of the element mode that it compares with.
  final List<int> counts;

  /// `enableOptionSharing` of the controller (U1).
  final bool sharing;
}

/// 2^-20 above 1: no parsed x of a `StressPointField` reaches the user
/// max, so `_getStartAndCountOfVisiblePoints` keeps all points (G2).
const double stressUnitMaxX = 1 + 1 / (1 << 20);

/// A hidden scale with user bounds: no tick labels to measure, no data
/// limits to compute (core.scale.js:303-309).
AnyObject stressHiddenScale(String type, {double min = 0, double max = 1}) => {
  'type': type,
  'display': false,
  'min': min,
  'max': max,
  'ticks': <String, Object?>{'display': false},
};

/// The data of the mode `chart` for one type and N, in the internal
/// format of the type (`parsing: false`).
final class StressChartScene {
  StressChartScene(this.type, this.n, StressPointField field);
  final StressChartType type;
  final int n;
  /// `data.labels`: N labels for bar, polarArea and radar, else empty.
  final List<Object?> labels;
  /// The dataset data.
  final List<Object?> data;
  /// Writes the moving values of [field] (CALL=update).
  void write(StressPointField field);
}

AnyObject stressChartConfig({
  required StressChartScene scene,
  required bool scriptable,
  bool animate = false,
  AnyObject options = const {},
  List<Object?> plugins = const [],
}) => {
  'type': scene.type.name,
  'data': {'labels': scene.labels, 'datasets': [_dataset(scene, scriptable)]},
  'options': {
    'animation': animate ? {'duration': stressAnimateMs, 'loop': true} : false,
    'events': <String>[],
    'maintainAspectRatio': false,
    'parsing': false,
    'layout': {'autoPadding': false},
    'scales': _hiddenScales(scene.type),
    ...options,
  },
  'plugins': [...plugins],
};
// _dataset: the colors, border and radius of phase 5, `clip: false`, and
// `showLine: false` for line.
```

## 6. Question 3: the stress cases of the other controllers

### Options

1. A new `StressMode` value for each type (11 modes in the mode line).
2. A define `TYPE` and a `type` line in the mode `chart` (the choice).
3. The upstream defaults of each type (visible scales, parsed data).
4. The stress form of each type: hidden scales with user bounds, `parsing: false` with the internal
   format (the choice).

### Choice

- Option 2. The mode line keeps 6 segments. The `type` line has 7 icon segments (about 39 dp each
  at 360 dp): `show_chart`, `scatter_plot`, `bar_chart`, `bubble_chart`, `donut_large`,
  `pie_chart_outline` (polar area), `radar`, with the tooltip of the type name. The N line shows the
  counts of the type.
- Option 4. It isolates the controller path from the scale path that `performance.md` §11 already
  measures, and it follows `docs/general/performance.md` (U1). Each config is plain data plus the
  timing plugin, so the same config runs in Chart.js in Chrome on the Pixel 8a (a Baseline C next
  to the baselines of `performance.md` §4.5): step 7 can then rank the port overhead against the
  upstream cost.
- `CALL` takes `draw`, `update` and `animate` for each type.

| Type | Data (internal format) | Scales | Moves with `CALL=update` | Compares with |
|---|---|---|---|---|
| line, scatter | `{x, y}` of the field | x, y linear hidden, x max `stressUnitMaxX` | x, y | mode `chart` of phase 5 |
| bar | `{x: i, y}`, N labels `B<i>` | x category hidden; y linear hidden [0, 1] | y | mode `bars` (same N, the `_barOptions` colors, border 1, radius 4) |
| bubble | `{x, y, _custom: 2 + (i % 5) * 2}` | x, y linear hidden, x max `stressUnitMaxX` | x, y | mode `chart` without sharing |
| doughnut | numbers `0.5 + y` | none | values | mode `arcs` (the 5 colors as an indexable array, border 2, radius 4, spacing 2) |
| polarArea | `{r: 0.1 + 0.9 * y}`, N labels | r radialLinear hidden [0, 1] | r | mode `arcs` |
| radar | `{r: 0.1 + 0.9 * y}`, N labels | r radialLinear hidden [0, 1] (required, G8) | r | mode `elements` with `LINE=1` (points and one line) |

- The counts: line, scatter, bar, bubble and radar take 1000, 5000 and 20000. Doughnut and polar
  area take 100, 1000 and 5000 (`stressArcCounts`, the counts of the mode `arcs`).
- Bar keeps the category index axis of `bar.md` and the default `barThickness`. Its upstream
  update sorts all values and makes N ticks in each update (U1, G8 §3). Step 7 measures this cost;
  the stress config does not hide it.
- `TYPE` with `MODE` other than `chart` throws at the start. `TYPE` and `SHARING=0` with a type
  other than scatter throws. `SHARING=0` alone gives scatter (the command lines of the phase 5
  and phase 6 runs stay valid).
- The `STRESS` line of the mode `chart` gets the keys `type` and `sharing` (from the type), and the
  parts `elementsMs`, `layoutMs`, `datasetsUpdateMs` and `datasetsDrawMs`.

### The timing parts

`StressAxesTiming` becomes `StressChartTiming` (`lib/demo/stress_timing.dart`) and runs in the
modes `chart` and `axes` and in each `chart.*` and `axes.*` bench case (G7: no measurable cost).
It gets a fourth part:
- `elements`: `beforeElementsUpdate` to `beforeLayout`, the `buildOrUpdateElements` of each
  dataset (the parse) and the first `getMaxOverflow` (`core.controller.js:497-508`).
- The second `getMaxOverflow` stays in `datasetsUpdate` (`core.datasetController.js:701-705`).

### The frameless benchmark

- `chart.a`, `chart.b` (sharing on and off) and `chart.c` keep their names and keys, and get the
  key `type` (`line` or `scatter`). The `before.md` lines join on `mode`, `case`, `sharing` and
  `scriptable`.
- New cases `chart.<type>` for bar, bubble, doughnut, polarArea and radar, each with `draw` and
  `update`, as the `axes.<scale>` cases. A selector `bar` or `chart.bar` selects both.
- `ChartBenchCase.counts`: the default counts of a case (`StressChartType.counts`). Without the
  define `N`, each case runs its own counts. With `N`, all cases run the given counts.

```dart
// lib/bench/chart_bench.dart
final class ChartBenchCase {
  const ChartBenchCase({
    required this.mode,
    required this.name,
    required this.call,
    required this.scene,
    this.keys = const {},
    this.counts,
  });
  /// The point counts of the case without the define `N`, or Dart `null`
  /// for the counts of the define.
  final List<int>? counts;
  // ...
}

ChartBenchCase _typeCase(StressChartType type, ChartBenchCall call) =>
    ChartBenchCase(
      mode: 'chart',
      name: type.name,
      call: call,
      counts: type.counts,
      keys: {'type': type.name, 'sharing': type.sharing, 'scriptable': false},
      scene: (n) {
        registerGalleryComponents();
        final field = StressPointField(n);
        final scene = StressChartScene(type, n, field);
        final timing = StressChartTiming();
        return ChartBenchScene(
          config: stressChartConfig(
            scene: scene,
            scriptable: false,
            options: chartBenchOptions,
            plugins: [timing.plugin],
          ),
          change: () => scene.write(field..step(n, chartBenchStep)),
          takeParts: timing.take,
        );
      },
    );
```

## 7. Question 4: `types.Chart` and the analyzer

- The gallery has three implementations of the interfaces: `DemoChart implements types.Chart`
  (`lib/demo/demo_chart.dart:40`), with explicit members; `_DemoChart implements Chart` and
  `_DemoScale implements Scale` (`lib/demo/ticks_demo.dart:20`, `:32`), with `noSuchMethod`.
  `_StressChart` and `_BenchChart` extend the concrete `Chart`.
- `members-radial.md` §2.5 lists the members that the radial controllers read and that
  `types.Chart` does not declare: `isDatasetVisible`, `getVisibleDatasetCount`,
  `toggleDataVisibility`, `update` and `legend`. If the interfaces panel (ADR 0028) adds them, the
  gallery does not compile until `DemoChart` has them.
- Options: (a) explicit members with an empty result in `DemoChart`; (b) `noSuchMethod` in
  `DemoChart`; (c) `DemoChart` becomes a real `Chart`.
- Choice: (a). A missing member is then a compile error of the analyzer gate, not a
  `NoSuchMethodError` in the animator at run time. The cost is zero: no member of the element modes
  calls them. Option (c) changes the figures of the modes `primitives`, `elements`, `bars` and
  `arcs`, which `DemoChart` drives.
- The members, if ADR 0028 adds them: `isDatasetVisible` gives true, `getVisibleDatasetCount`
  gives 0, `toggleDataVisibility` and `update` do nothing, `legend` gives Dart `null`.
- `dart run melos run analyze` runs `dart analyze --fatal-infos` at the root of the workspace,
  which has `apps/chartjs_gallery` (root `pubspec.yaml`, `workspace`). Each port agent and the
  integration agent run it, as the prompt says.

## 8. Question 5: the layout rule

- Rule of the user (2026-10-21, decision D3 of `phase7-progress.md`): the chart is in view when a
  page loads on a phone. Each parameter is a full-width segmented button with short text or
  icons, one control per line, then the chart, then the readout and the help text. No popup menus,
  no horizontal scroll, no rows of chips above the chart.
- The budget: on a phone of 360 x 640 dp, the app bar (56 dp, plus 72 dp for the tab bar of the
  phase 3 page) and a chart of 240 dp leave room for four control lines of 40 dp with gaps of
  8 dp. Thus a page has at most four control lines above the chart. The other parameters go after
  the readout, each on its own line.
- `SegmentChoiceItem` gets an optional `IconData icon`: a segment shows its icon or its text.
- A new `SegmentActions` widget: a full-width segmented button of action icons with no selected
  segment. A tap runs the action of its segment. The actions line has the same look as the other
  lines.
- The pages that phase 7 touches apply the rule: the nine type pages, the stress tab (the `type`
  line, 7 control lines: the tab bar page has room for it on a 411 x 914 dp Pixel 8a, see the
  test), the Core tab and the Axes tab.
  - Core tab: the chart is first today. Its chips become `SegmentChoice` lines after the readout
    (`mode` has 6 values; `axis` 3; the toggles of `intersect`, `animation` and the two datasets
    are one `SegmentToggles` line). The two sliders become choices of 4 values.
  - Axes tab: `x`, `y` and `N` above the chart. The other options after the readout.
- No control rebuilds the chart: each control writes the user options and calls `update()`, as
  today.

## 9. Files and tests

### Files that the implementation changes

- `apps/chartjs_gallery/lib/main.dart`: `galleryChartTypes`, the status of each entry, the routes,
  the text of the first tile.
- `apps/chartjs_gallery/lib/types/chart_type_page.dart` (new): `ChartTypePage`, `SampleChoice`,
  `SampleAction`, `ChartTypeSample`.
- `apps/chartjs_gallery/lib/types/samples.dart` (new): the nine samples, with the `file:line` of
  each upstream config.
- `apps/chartjs_gallery/lib/demo/demo_controls.dart`: the `icon` of `SegmentChoiceItem`,
  `SegmentActions`.
- `apps/chartjs_gallery/lib/demo/stress_point_controller.dart`: deleted.
- `apps/chartjs_gallery/lib/demo/gallery_components.dart` (new): `registerGalleryComponents`.
- `apps/chartjs_gallery/lib/demo/stress_chart_config.dart`: `StressChartType`, `StressChartScene`,
  `stressUnitMaxX`, `stressHiddenScale`, the new `stressChartConfig`.
- `apps/chartjs_gallery/lib/demo/stress_axes.dart`: `stressAxesConfig` with `type: 'line'`,
  `showLine: false`, `parsing: false`, `autoPadding: false`, `clip: false`. The timing class moves
  out.
- `apps/chartjs_gallery/lib/demo/stress_timing.dart` (new): `StressChartTiming` with the part
  `elements`.
- `apps/chartjs_gallery/lib/demo/stress_demo.dart`: the `type` line, the counts of each type, the
  parts in the readout of the mode `chart`, the source text.
- `apps/chartjs_gallery/lib/main_stress.dart`: the define `TYPE`, the alias `SHARING=0`, the keys
  `type` and the parts.
- `apps/chartjs_gallery/lib/bench/chart_bench.dart` and `lib/main_bench.dart`: the cases
  `chart.<type>`, `ChartBenchCase.counts`, the key `type`, the part `elements`.
- `apps/chartjs_gallery/lib/demo/core_demo.dart` and `lib/demo/axes_demo.dart`: `type: 'line'`,
  the configs of section 5, the controls of section 8.
- `apps/chartjs_gallery/lib/demo/demo_chart.dart`: the members of section 7, if ADR 0028 adds them.
- `apps/chartjs_gallery/lib/canvas_host_demo.dart`: the doc text ("No chart type renders yet").
- `packages/flutter_chartjs/doc/performance.md` §6: `TYPE`, the new cases, the part `elements`,
  the three-side A/B of section 5 (in the doc step, not in this draft).

### Tests that pin the decisions

- `test/gallery_test.dart`: each entry of `galleryChartTypes` shows, is enabled, has its status
  icon and opens its page. Area shows its note.
- `test/chart_types_test.dart` (new), for each type:
  - at a 360 x 640 dp view, the rect of `type.<id>.host` lies inside the view after the first
    frame (rule 5);
  - the page has no `ChoiceChip`, `FilterChip`, `PopupMenuButton`, `DropdownButton` or horizontal
    `Scrollable`, and each `SegmentedButton` has the width of its column;
  - `chart.config.type` and the `type` of each meta are those of the docs config, and each data
    element has finite `x` and `y`;
  - each control key exists, and a tap changes the resolved option without a new chart (the same
    `Chart` object): for example `type.bar.axis.y` gives `chart.options.indexAxis == 'y'` and
    horizontal bars, `type.doughnut.type.pie` gives the meta type `pie` and `innerRadius == 0`;
  - a hover writes the `getLabelAndValue` text of the active element into the readout.
- `test/stress_chart_test.dart`:
  - for each `StressChartType`, the mode `chart` makes a chart of that type, with the counts of
    the type;
  - line and scatter, `CALL=update`, 600 frames of 5000 points: no point has `skip`, and each pixel
    is within 1e-3 px of `left + x * width` and `bottom - y * height` (G1, G2);
  - the chart area is the canvas and `meta.clip.disabled` is true (G1, G6);
  - radar: the range of `r` is [0, 1] after an update (G8);
  - `TYPE` and `SHARING` conflicts throw (`main_stress.dart`).
- `test/stress_axes_test.dart`: the chart of the mode `axes` has the meta type `line`, no
  dataset clip, and the chart area of a phase 6 chart of the same host size (a value recorded at
  `0e0ab93` in the test).
- `test/chart_bench_test.dart`: the cases `chart.<type>` exist and select by `bar` and
  `chart.bar`; a case without the define `N` runs its own counts; each chart line has the key
  `type` and the part `elements`.
- `test/core_demo_test.dart` and `test/axes_demo_test.dart`: the meta controller is a
  `LineController`; the point pixels match with `closeTo(…, 1e-9)` (the y pixel of a scale
  differs from the fraction formula by 5.7e-14 px, G1).
- `test/chart_canvas_test.dart`: the chart type is `line`.
- A test of `registerGalleryComponents`: the registry has no `stressPoint` controller and has the
  eight controllers of phase 7.
- Step 7 (not a test): the three-side A/B of section 5 for `chart.a`, `chart.b` and `chart.c`, the
  ABBA protocol of the prompt, and the new `chart.<type>` cases on the Pixel 8a, with the
  Baseline C of section 6 for the upstream cost.
