# Gallery chart types and the stress controller: implementation spec

- Decision: [Chart.js ADR 0031](../../../adr/0031-gallery-chart-types.md) (proposed). This spec
  gives the work of the decision. Where this spec and the ADR differ, the ADR applies.
- Panel: [judge.md](judge.md), [draft-performance.md](draft-performance.md) (the winner),
  [draft-simplicity.md](draft-simplicity.md), [draft-fidelity.md](draft-fidelity.md).
- Pin: Chart.js `v4.5.1+7169e651`. Gallery tree at `4eda459`.
- Below, `G/` is `apps/chartjs_gallery/`, and `P/` is `packages/flutter_chartjs/`.

## 0. Rules for each agent of this spec

- Re-read each shared file directly before each edit. The stress tab changes often.
- Each `ValueKey` of this spec is exact. A test finds each control by its key.
- Each nested Map literal of a chart config has the type `<String, Object?>`. `Chart` and `Config`
  write into it. Each config is a function that returns new Maps for each chart.
- Number literals in configs are `double` (`65.0`), as the gallery configs are today.
- A gallery file with no upstream source starts with
  `// Original code, not ported from Chart.js: <reason>.` A file that copies upstream docs code
  starts with the rule-2 header (ADR 0031 §1.8).
- Gallery files import the ported files of `package:flutter_chartjs/src/` directly, with
  `// ignore_for_file: implementation_imports`, as today.
- After each unit: `dart run melos run format:check`, `dart run melos run analyze` (it covers
  `apps/chartjs_gallery`), and `flutter test` in `apps/chartjs_gallery`. Kill each
  `flutter_tester` process that you leave.
- No commit. No git command that changes the index or the tree.
- Docs in ASD-STE100 Simplified Technical English.

## 1. Order of work

| Unit | When | Owner | Depends on |
|---|---|---|---|
| U0. `DemoChart` members | in each port-wave unit that adds a member to `types.Chart` (Chart.js ADR 0028): the unit S2 of `../work-plan.md` (interfaces spec, step 1) | the agent of that unit | — |
| U1. `SegmentChoiceItem.icon` | gallery step (method step 5), first | gallery agent | — |
| U2. Registration, the stress chart, the timing, the benchmark, the stress entry, the stress tab | gallery step | gallery agent | `LineController`, `ScatterController` and the other six controllers in `registerables` (integration agent of step 3) |
| U3. The chart type pages and the home list | gallery step, after U2 | gallery agent | U1, U2 (`registerGalleryComponents`) |
| U4. The Core tab and the Axes tab | gallery step, after U2 | gallery agent | U1, U2 |
| U5. Doc notes | after U2-U4 pass | integration agent | U2-U4 |
| U6. The A/B of step 7 | method step 7 | performance agent | U2 |

U2, U3 and U4 change disjoint files except `G/lib/demo/demo_controls.dart` (U1 only) and the
files of U2 that U3 and U4 import. Run them in this order, or give U3 and U4 to one agent.

## 2. Files

| File | Unit | Change |
|---|---|---|
| `G/lib/demo/demo_chart.dart` | U0 | the members of §3.0 |
| `G/lib/demo/demo_controls.dart` | U1 | `SegmentChoiceItem.icon`, the icon segment |
| `G/lib/demo/stress_demo.dart` | U1, U2 | `icon: null` in the existing items (U1); the type line, the toggles, the counts, the host key, the readout (U2) |
| `G/test/stress_controls.dart` | U1 | `icon: null` in the items, if it builds items |
| `G/lib/demo/stress_point_controller.dart` | U2 | deleted |
| `G/lib/demo/gallery_components.dart` (new) | U2 | `registerGalleryComponents`, `unitScales` |
| `G/lib/demo/stress_chart_config.dart` | U2 | `StressChartType`, `StressChartScene`, the new `stressChartConfig`, `stressHiddenScale` |
| `G/lib/demo/stress_timing.dart` (new) | U2 | `StressChartTiming` (from `stress_axes.dart`), the part `elements` |
| `G/lib/demo/stress_axes.dart` | U2 | `stressAxesConfig` on the new config; the timing class moves out |
| `G/lib/main_stress.dart` | U2 | `TYPE`, `SHOWLINE`, the `SHARING` alias, the counts of the type, the `STRESS` keys |
| `G/lib/bench/chart_bench.dart` | U2 | `ChartBenchCase.counts`, the key `type`, the parts, the cases `chart.<type>` |
| `G/lib/main_bench.dart` | U2 | `N` without a default; the counts of each case |
| `G/lib/charts/chart_types.dart` (new) | U3 | `ChartTypeVariant`, `ChartTypeEntry`, `galleryChartTypes` |
| `G/lib/charts/chart_type_page.dart` (new) | U3 | `ChartTypePage` |
| `G/lib/docs/charts/{bar,bubble,doughnut,line,mixed,polar,radar,scatter}.dart` (new) | U3 | the docs configs |
| `G/lib/docs/samples/area/line_boundaries.dart` (new) | U3 | the Area config |
| `G/lib/main.dart` | U3 | the list, the first tile text; `chartTypes` goes |
| `G/lib/demo/core_demo.dart` | U4 | `type: 'line'`, `unitScales()`, the controls above the chart |
| `G/lib/demo/axes_demo.dart` | U4 | `type: 'line'`, the controls of §6.2 |
| `G/lib/canvas_host_demo.dart`, `G/README.md` and each other hit of `grep -rn StressPointController G` | U2 | the texts |
| `G/test/*` | U1-U4 | §5 |
| `AGENTS.md`, `P/doc/performance.md`, `P/doc/porting-flow.md`, `P/doc/status.yaml`, `P/doc/phase7-progress.md` | U5 | §7 |

## 3. Code forms

### 3.0 `DemoChart` (U0)

The agent of the unit that adds a member to `types.Chart` adds it to `DemoChart` in the same
change. Use the exact signature of the interface (Chart.js ADR 0028). The results:

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

/// core.controller.js:536: an update ends with a render. The demo chart
/// has only the render.
@override
void update([Object? mode]) => render();

/// The demo chart has no legend.
@override
types.LegendElement? get legend => null;
```

A member that Chart.js ADR 0028 adds to another interface that a gallery class implements gets the
same treatment. `_DemoChart` and `_DemoScale` of `G/lib/demo/ticks_demo.dart` keep
`noSuchMethod`.

### 3.1 `SegmentChoiceItem.icon` (U1)

```dart
/// One segment of a [SegmentChoice]: the key of the segment, its short
/// text, its icon, its tooltip and its value. With an [icon], the segment
/// shows the icon only.
typedef SegmentChoiceItem<T> = ({
  String key,
  String text,
  IconData? icon,
  String tooltip,
  T value,
});
```

- In `SegmentChoice.build`: a segment with `item.icon != null` gets
  `icon: Icon(item.icon, key: ValueKey(item.key))` and no `label`. Else it keeps the `Text` label
  with the key.
- A record has no optional field. Each existing item literal gets `icon: null`.

### 3.2 `gallery_components.dart` (U2)

```dart
// Original code, not ported from Chart.js: the registration and the unit scales of the gallery charts.

bool _registered = false;

/// Registers the built-in components once: `registerables`, as
/// `src/index.umd.ts:28` does. After phase 7, they include the eight
/// controllers.
void registerGalleryComponents() {
  if (_registered) return;
  _registered = true;
  Chart.register(registerables);
}

/// Two hidden linear scales of the fractions 0 to 1 (Chart.js ADR 0031
/// section 3). x has suggested bounds: a user `min` or `max` on unsorted
/// data with `parsing: false` drops points (helpers.extras.ts:94-133).
/// y has user bounds: `getMinMax` does not read the data
/// (core.scale.js:307-309). [hideTicks] adds `ticks: {display: false}`,
/// which skips the auto skip of a hidden scale (core.scale.js:457).
AnyObject unitScales({bool hideTicks = false}) => <String, Object?>{
  'x': <String, Object?>{
    'type': 'linear',
    'display': false,
    if (hideTicks) 'ticks': <String, Object?>{'display': false},
    'suggestedMin': 0.0,
    'suggestedMax': 1.0,
  },
  'y': <String, Object?>{
    'type': 'linear',
    'display': false,
    if (hideTicks) 'ticks': <String, Object?>{'display': false},
    'min': 0.0,
    'max': 1.0,
  },
};
```

The stress charts call `unitScales(hideTicks: true)`. The Core tab calls `unitScales()`.

### 3.3 `stress_chart_config.dart` (U2)

Keep `stressAnimateMs`, `stressChartBackground`, `stressChartBackgroundOdd`,
`stressScriptableBackground` and `StressPointField` unchanged. Remove the import of
`stress_point_controller.dart`. Replace `stressChartConfig`.

```dart
/// The chart types of the stress mode `chart` (`--dart-define=TYPE=<name>`).
/// The name is the `type` of the chart config.
enum StressChartType {
  line(stressPointCounts, sharing: true),
  scatter(stressPointCounts, sharing: false),
  bar(stressPointCounts, sharing: true),
  bubble(stressPointCounts, sharing: true),
  doughnut(stressArcCounts, sharing: true),
  pie(stressArcCounts, sharing: true),
  polarArea(stressArcCounts, sharing: false),
  radar(stressArcCounts, sharing: false);

  const StressChartType(this.counts, {required this.sharing});

  /// The N choices of the type, in ascending order.
  final List<int> counts;

  /// `enableOptionSharing` of the controller (controller.line.js:35-39,
  /// controller.bar.js:380, controller.bubble.js:38,
  /// controller.doughnut.js:136). A test compares it with the controller.
  final bool sharing;

  /// Whether the config is the line and scatter form of Chart.js ADR 0031
  /// section 3: `parsing: false` and the data objects of the field.
  bool get points => this == line || this == scatter;
}

/// The counts of the points: 1000, 5000 and 20000.
const List<int> stressPointCounts = [1000, 5000, 20000];

/// The counts of the radial types, as the stress mode `arcs`.
const List<int> stressArcCounts = [100, 1000, 5000];
```

Move `stressPointCounts` from `stress_demo.dart` to this file (the stress tab imports it).

```dart
/// The data of a chart of the stress mode `chart`: N items of a type, at
/// the values of a `StressPointField`.
final class StressChartScene {
  /// The first [n] items of [type], at the positions of [field].
  StressChartScene(this.type, this.n, StressPointField field);

  final StressChartType type;
  final int n;

  /// `data.labels`: `Point <i>` for bar, doughnut, pie, polarArea and
  /// radar; empty for line, scatter and bubble.
  final List<Object?> labels;

  /// The dataset data:
  /// - line, scatter: the data objects `{x, y}` of `field.data(n)`;
  /// - bubble: `{x, y, r}` with `r = 2 + 4 * (vx / 0.3)^2`;
  /// - bar, radar: the numbers `y`;
  /// - doughnut, pie, polarArea: the numbers `0.05 + 0.95 * y`.
  final List<Object?> data;

  /// Writes the moved values of [field] into [data] in place. bubble
  /// keeps its `r`.
  void write(StressPointField field);
}

/// A hidden scale with user bounds (Chart.js ADR 0031 section 5).
AnyObject stressHiddenScale(String type, {double? min, double? max}) =>
    <String, Object?>{
      'type': type,
      'display': false,
      'ticks': <String, Object?>{'display': false},
      'min': ?min,
      'max': ?max,
    };

/// The config of the stress mode `chart` (Chart.js ADR 0031 sections 3
/// and 5).
///
/// - [scriptable]: the scriptable `backgroundColor` of case (c).
/// - [showLine]: the dataset option `showLine` of line and scatter.
///   Another type throws an [ArgumentError] when it is true.
/// - [animate]: the looping animation of the call `animate`.
/// - [options]: more chart options, after the options of the mode.
/// - [plugins]: the inline plugins.
AnyObject stressChartConfig({
  required StressChartScene scene,
  required bool scriptable,
  bool showLine = false,
  bool animate = false,
  AnyObject options = const {},
  List<Object?> plugins = const [],
});
```

If the null-aware map element `'min': ?min` is not available in the Dart of the toolchain, use
`if (min != null) 'min': min`.

The body of `stressChartConfig`:

- `'type': scene.type.name`.
- `'data'`: `'labels': scene.labels` (only when not empty), one dataset:
  `'data': scene.data`, `'backgroundColor'` (`stressScriptableBackground` or
  `stressChartBackground`), `'borderColor': '#36A2EB'`, `'borderWidth': 1.0`,
  `'pointStyle': 'circle'`, `'radius': 3.0`. For `line` and `scatter` also `'showLine': showLine`
  and `'clip': false`. No `optionSharing` key.
- `'options'`: `'animation'` (as today), `'events': <String>[]`, `'maintainAspectRatio': false`,
  then by type:

  | Type | More options |
  |---|---|
  | line, scatter | `'parsing': false`, `'layout': {'autoPadding': false}`, `'scales': unitScales(hideTicks: true)` |
  | bar | `'scales': {'x': stressHiddenScale('category'), 'y': stressHiddenScale('linear', min: 0, max: 1)}` |
  | bubble | `'scales': {'x': stressHiddenScale('linear', min: 0, max: 1), 'y': stressHiddenScale('linear', min: 0, max: 1)}` |
  | doughnut, pie | none |
  | polarArea, radar | `'scales': {'r': stressHiddenScale('radialLinear', min: 0, max: 1)}` |

  then `...options`.
- `'plugins': [...plugins]`.

### 3.4 `stress_timing.dart` (U2)

Move `StressAxesTiming` from `stress_axes.dart` and rename it `StressChartTiming`. The plugin id
becomes `stressChartTiming`. Add the part `elements`:

```dart
/// The ticks of the element updates since the last [take]:
/// `beforeElementsUpdate` to `beforeLayout` (core.controller.js:497-510,
/// :611-612): `buildOrUpdateElements` of each dataset (the parse) and the
/// first `getMaxOverflow`.
int elementsTicks = 0;
```

- `beforeElementsUpdate` sets `_elementsStart`. `beforeLayout` adds
  `_watch.elapsedTicks - _elementsStart` to `elementsTicks` (only when `_elementsStart` is set for
  this update; reset it to -1 after the add), then sets `_layoutStart`.
- `take()` gives `elements`, `layout`, `datasetsUpdate` and `datasetsDraw`, in this order.
- `reset()` sets each part to 0.

### 3.5 `stress_axes.dart` (U2)

`stressAxesConfig` makes its config with `stressChartConfig` on a `line` scene of its own data, or
writes the Map directly. The result:

- `'type': 'line'`, the dataset of §3.3 with `'showLine': false` and `'clip': false`, and the data
  objects of `StressAxesScene`;
- `'parsing': false`, `'layout': {'autoPadding': false}`, `'events': []`,
  `'maintainAspectRatio': false`, `'animation': false`;
- the visible scales `x` and `y` of the scene as today, and `data.labels` for a category axis.

The doc comments name `LineController` in place of `StressPointController`.

### 3.6 `main_stress.dart` (U2)

```dart
/// The chart type of the mode `chart`: `--dart-define=TYPE=<name>` of
/// [StressChartType]. `SHARING` is an alias: without `TYPE`, `SHARING=0`
/// gives `scatter`, and `SHARING=1` or no `SHARING` gives `line`. With both
/// defines, `SHARING=1` needs `TYPE=line` and `SHARING=0` needs
/// `TYPE=scatter`. `TYPE` in another mode, an unknown name, or another pair
/// throws an [ArgumentError] at the start.
final StressChartType stressType = _type(
  const String.fromEnvironment('TYPE'),
  const String.fromEnvironment('SHARING'),
);

/// Whether line and scatter show their line: `--dart-define=SHOWLINE=1`.
/// The default is 0. `SHOWLINE=1` with another type or in another mode
/// throws an [ArgumentError] at the start.
final bool stressShowLine = ...;
```

- Remove `stressSharing`. The `STRESS` line of the mode `chart` gets: `'type': stressType.name`,
  `'sharing'` (the `enableOptionSharing` of the controller of dataset 0, read once after the first
  update; `stressType.sharing` before it), `'scriptable'`, `'showLine': true` only when true,
  `'elementsMs'`, `'layoutMs'`, `'datasetsUpdateMs'`, `'datasetsDrawMs'`. The mode `axes` also gets
  `'elementsMs'`.
- The default scenarios of the mode `chart` are the counts of `stressType` with M = 0.
- `StressProfileApp` passes `initialType: stressType` and `initialShowLine: stressShowLine`.

### 3.7 `stress_demo.dart` (U2)

- `StressDemo`: `initialSharing` becomes `initialType` (`StressChartType`, default
  `StressChartType.line`). New `initialShowLine` (default false).
- State: `_sharing` becomes `_type`. New `_showLine`. `StressStats` gets `elementsMs`.
- The N choices of the mode `chart` are `_type.counts`. A new type keeps the index of N in the
  list.
- `StressMode.chart` doc: the ported controllers of the type, not `StressPointController`.
- The options toggles of the mode `chart`: `stress.spin`, `stress.chart.scriptable`, and
  `stress.chart.showLine` (icon `Icons.timeline`, tooltip `showLine`, only for line and scatter).
  The toggle `stress.chart.sharing` goes.
- The `type` line, after the `mode` line, only in the mode `chart`:

  ```dart
  SegmentChoice<StressChartType>(
    label: 'type',
    items: [
      for (final type in StressChartType.values)
        (
          key: 'stress.chart.type.${type.name}',
          text: type.name,
          icon: _typeIcons[type],
          tooltip: type.name,
          value: type,
        ),
    ],
    value: _type,
    onChanged: (type) => setState(() => _setChartCase(type: type)),
  )
  ```

  `_typeIcons`: line `Icons.show_chart`, scatter `Icons.scatter_plot`, bar `Icons.bar_chart`,
  bubble `Icons.bubble_chart`, doughnut `Icons.donut_large`, pie `Icons.pie_chart`, polarArea
  `Icons.track_changes`, radar `Icons.radar`.
- The `KeyedSubtree` key of the mode `chart`:
  `(_n, _type, _scriptable, _showLine, _call == StressChartCall.animate)`.
- `_createChart`: `final scene = _chartScene = StressChartScene(_type, _n, _field)`, then
  `stressChartConfig(scene: scene, scriptable: _scriptable, showLine: _showLine, animate: ...,
  plugins: [_labelsPlugin, _timing.plugin])`. The update of a frame calls
  `scene.write(_field..step(...))`. The mode `chart` gets the timing plugin and the readout of the
  four parts, as the mode `axes` has.
- The source text of the mode `chart` names the controller of the type.

### 3.8 `chart_bench.dart` and `main_bench.dart` (U2)

```dart
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
  /// for [chartBenchDefaultCounts].
  final List<int>? counts;
  // the other members as today
}

/// The counts of a case without its own counts and without the define `N`.
const List<int> chartBenchDefaultCounts = [1000, 5000, 20000];
```

- `_stressCase(name, call, {required StressChartType type, bool scriptable = false})`: keys
  `{'type': type.name, 'sharing': type.sharing, 'scriptable': scriptable}`. The scene makes a
  `StressChartScene`, a `StressChartTiming`, the config with `options: chartBenchOptions` and
  `plugins: [timing.plugin]`, `change: () => scene.write(field..step(n, chartBenchStep))` and
  `takeParts: timing.take`.
- `_axesCase`: as today, with `StressChartTiming` (four parts).
- `_typeCase(StressChartType type, ChartBenchCall call)`: mode `chart`, name `type.name`, keys as
  `_stressCase` with `scriptable: false`, `counts: type.counts`.
- The case list:

  ```dart
  final List<ChartBenchCase> chartBenchCases = [
    _stressCase('a', ChartBenchCall.draw, type: StressChartType.line),
    _stressCase('b', ChartBenchCall.update, type: StressChartType.line),
    _stressCase('b', ChartBenchCall.update, type: StressChartType.scatter),
    _stressCase('c', ChartBenchCall.update,
        type: StressChartType.line, scriptable: true),
    for (final scale in StressAxisType.values)
      for (final call in ChartBenchCall.values) _axesCase(scale, call),
    for (final type in StressChartType.values)
      if (!type.points)
        for (final call in ChartBenchCall.values) _typeCase(type, call),
  ];
  ```

- `main_bench.dart`: `benchCounts` is `List<int>?`: Dart `null` without the define `N`. The run
  uses `counts ?? benchCase.counts ?? chartBenchDefaultCounts` for each case. The doc comments
  give the new cases and the selector `chart` (16 cases) and `CASES=a,b,c` for the cases of
  Chart.js ADR 0021 §8.

### 3.9 The docs configs (U3)

One Dart file for each docs source file. Line 1 is the rule-2 header, for example:

```dart
// Ported from Chart.js v4.5.1+7169e651 docs/charts/bar.md (MIT, Chart.js Contributors).
```

| File | Functions (each returns a new `AnyObject`) | Source lines |
|---|---|---|
| `lib/docs/charts/bar.dart` | `barVerticalConfig`, `barHorizontalConfig` | `bar.md:5-54`, `:304-351` |
| `lib/docs/charts/bubble.dart` | `bubbleConfig` | `bubble.md:5-36` |
| `lib/docs/charts/doughnut.dart` | `doughnutConfig`, `pieConfig` | `doughnut.md:15-47`, `:53-85` |
| `lib/docs/charts/line.dart` | `lineConfig`, `lineVerticalConfig` | `line.md:5-31`, `:233-285` |
| `lib/docs/charts/mixed.dart` | `mixedConfig` | `mixed.md:27-70` |
| `lib/docs/charts/polar.dart` | `polarAreaConfig` | `polar.md:7-43` |
| `lib/docs/charts/radar.dart` | `radarConfig` | `radar.md:7-61` |
| `lib/docs/charts/scatter.dart` | `scatterConfig` | `scatter.md:5-47` |
| `lib/docs/samples/area/line_boundaries.dart` | `areaOriginConfig` | `samples/area/line-boundaries.md:3-120` |

- Copy each block from `third_party/Chart.js/docs/` at the pin. Keep each key, value and order.
  Each function has a `///` line with its source lines.
- `Utils.months({count: n})` becomes the list of the first n English month names (`utils.js:91-104`).
- `areaOriginConfig`:
  - `labels`: `January` to `August`;
  - one dataset: `'label': 'Dataset'`,
    `'data': <Object?>[97.81, -42.3, 84.05, -46.6, -31.77, 12.48, -59.53, -0.87]` (P4: the
    algorithm of `utils.js:20-43` with the seed 2026), `'borderColor': 'rgb(255, 99, 132)'`,
    `'backgroundColor': 'rgba(255, 99, 132, 0.5)'`, `'fill': 'origin'`;
  - the options of `:95-113`: `plugins.filler.propagate: false`, `plugins.title.display: true`,
    `plugins.title.text` as a closure `(Object? ctx) => jsAdd('Fill: ', <the fill of dataset 0>)`
    that reads `ctx.chart.data.datasets[0].fill` with `jsGet`, and `interaction.intersect: false`;
  - no actions. A `///` comment says that the first state of the sample is `fill: false` and that
    the gallery shows `fill: 'origin'` (Chart.js ADR 0031 §1.2).

### 3.10 `chart_types.dart` (U3)

```dart
// Original code, not ported from Chart.js: the chart types of the gallery.

/// One variant of a chart type page: a `chart-editor` block of the docs.
typedef ChartTypeVariant = ({
  String key,
  String text,
  String source,
  AnyObject Function() config,
});

/// One entry of the home list: the page of `docs/charts/<stem>.md`.
/// [note] tells what the page lacks until a later phase, or is Dart `null`
/// when the page shows the full chart.
typedef ChartTypeEntry = ({
  String stem,
  String title,
  List<ChartTypeVariant> variants,
  String? note,
});

/// The chart types of the docs, in the order of the docs.
final List<ChartTypeEntry> galleryChartTypes = [ /* 9 entries */ ];
```

| `stem` | `title` | Variants (`key`, `text`, `source`) | `note` |
|---|---|---|---|
| `area` | Area | `origin`, `origin`, `docs/samples/area/line-boundaries.md:3-120` | `Line only: the fill needs plugin.filler (phase 8)` |
| `bar` | Bar | `vertical`, `vertical`, `docs/charts/bar.md:5-54`; `horizontal`, `horizontal`, `docs/charts/bar.md:304-351` | null |
| `bubble` | Bubble | `bubble`, `bubble`, `docs/charts/bubble.md:5-36` | null |
| `doughnut` | Doughnut and Pie | `doughnut`, `doughnut`, `docs/charts/doughnut.md:15-47`; `pie`, `pie`, `docs/charts/doughnut.md:53-85` | null |
| `line` | Line | `line`, `line`, `docs/charts/line.md:5-31`; `vertical`, `vertical`, `docs/charts/line.md:233-285` | null |
| `mixed` | Mixed | `mixed`, `mixed`, `docs/charts/mixed.md:27-70` | null |
| `polar` | Polar Area | `polar`, `polar`, `docs/charts/polar.md:7-43` | null |
| `radar` | Radar | `radar`, `radar`, `docs/charts/radar.md:7-61` | null |
| `scatter` | Scatter | `scatter`, `scatter`, `docs/charts/scatter.md:5-47` | null |

### 3.11 `chart_type_page.dart` (U3)

```dart
// Original code, not ported from Chart.js: the page of one chart type.

/// The page of one chart type: the variant line, the chart, the readout
/// and the help text (Chart.js ADR 0031 sections 1 and 10).
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

  /// The datasets: `<meta.type> <element count>` of each dataset, joined
  /// with `, `.
  @visibleForTesting
  String get datasetsLabel;

  /// The active elements: `d<dataset>#<index> <label>: <value>` of each,
  /// from `controller.getLabelAndValue(index)`, joined with `; `, or
  /// `none`.
  @visibleForTesting
  String get hoverLabel;

  Chart _create(UiCanvasElement canvas) {
    registerGalleryComponents();
    final config = widget.entry.variants[_variant].config();
    final options =
        (config['options'] ??= <String, Object?>{})! as AnyObject;
    options['onHover'] = (Object? event, Object? active, Object? chart) =>
        _readout.value++;
    return Chart(canvas, config);
  }

  @override
  void dispose() {
    _readout.dispose();
    super.dispose();
  }
}
```

The `build` body, from the top, in a `Scaffold` with an `AppBar(title: Text(entry.title))` and a
`DemoPageBody(maxWidth: 600)` (it scrolls):

1. Only when the entry has two variants: a `SegmentChoice<int>` with the label `docs` and the items
   `(key: 'type.<stem>.variant.<variant>', text: <text>, icon: null, tooltip: <source>, value: i)`.
   A tap sets `_variant` in `setState`.
2. `KeyedSubtree(key: ValueKey(_variant), child: ChartCanvas(key: ValueKey('type.<stem>.host'),
   create: _create, onChart: ...))`. No `height`: the host gets an unbounded height, and the
   platform gives the docs aspect (Chart.js ADR 0031 §1.4). Do not set `maintainAspectRatio`.
3. A `ValueListenableBuilder` of `_readout` with
   `ReadoutTable(key: ValueKey('type.<stem>.readout'), rows: [('datasets', datasetsLabel),
   ('hover', hoverLabel)])`.
4. The help text: the source of the variant at the pin, and "No legend, title, tooltip or fill:
   these plugins come in phase 8." The note of the entry, when it has one.

`getLabelAndValue` returns a record (Chart.js ADR 0028). Interpolate its `label` and `value` with
`'$label: $value'`: the readout is display text.

### 3.12 `main.dart` (U3)

- Remove `chartTypes`. The tiles come from `galleryChartTypes`:

  ```dart
  for (final entry in galleryChartTypes)
    ListTile(
      key: ValueKey('gallery.type.${entry.stem}'),
      leading: Icon(
        entry.note == null ? Icons.check_circle_outline : Icons.timelapse,
      ),
      title: Text(entry.title),
      subtitle: Text(entry.note ?? 'docs/charts/${entry.stem}.md'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ChartTypePage(entry: entry)),
      ),
    ),
  ```

  The subtitle of Area is its note. The subtitle of each other entry is its docs file.
- The first tile: "The chart types render through the ported controllers, without the plugins of
  phase 8." The doc comment of `GalleryApp` loses "marked as pending".

### 3.13 Core tab (U4)

- `_create`: `'type': 'line'`. The datasets keep their keys. `'options'` gets
  `'scales': unitScales()`. Keep the padding of 20 and the plugin `galleryValueLines`. No
  `parsing` key.
- The chart card has, from the top: the five control lines, the chart, the readout, the help text.
  The cards `Interaction` and `Animations` go. Their source texts join the source of the chart
  card.

  | Line | Widget | Keys | Values |
  |---|---|---|---|
  | `mode` | `SegmentChoice<String>` | `core.mode.<mode>` | `coreDemoModes` |
  | `axis` | `SegmentChoice<String>` | `core.axis.<axis>` | `coreDemoAxes` |
  | toggles | `SegmentToggles` | `core.intersect` (`Icons.ads_click`), `core.animation` (`Icons.animation`), `core.dataset.0`, `core.dataset.1` (`Icons.looks_one`, `Icons.looks_two`), `core.data.randomize` (`Icons.shuffle`), `core.data.add` (`Icons.add`), `core.data.remove` (`Icons.remove`) | a command has `value: false`, and its `onChanged` runs the command |
  | `hover` | `SegmentChoice<double>` | `core.hover.duration.<ms>` | 0, 200, 400, 1000, 2000 |
  | `update` | `SegmentChoice<double>` | `core.animation.duration.<ms>` | 0, 400, 1000, 2000, 3000 |

  `<ms>` is the integer text (`400`). The defaults stay (`nearest`, `xy`, 400 ms, 1000 ms).
- The host height: `constraints.maxWidth >= 560 ? 320 : 280`, as today.

### 3.14 Axes tab (U4)

- `_create`: `'type': 'line'`. No other change of the config.
- The segment keys keep the key form of the chips of today, `axes.<name>.<value>`
  (`axes_demo.dart:464-465`), with the names `x.type`, `y.type`, `x.position`, `y.position`,
  `bounds`, `time.unit`, `locale`, `ticks.align` and `count`.
- Above the chart: `x` (`axes.x.type.<type>`), `y` (`axes.y.type.<type>`) and `N`
  (`axes.count.<n>`).
- After the readout, one line each: `x pos` (`x.position`), `y pos` (`y.position`), `bounds`,
  `unit` (`time.unit`), `locale`, `align` (`ticks.align`) as `SegmentChoice`; one
  `SegmentToggles` line with `axes.reverse`, `axes.beginAtZero`, `axes.ticks.autoSkip`,
  `axes.grid.display`, `axes.grid.offset`, `axes.border.display`, `axes.title.display` and the
  data commands `axes.data.randomize`, `axes.data.add`, `axes.data.remove` (a command has
  `value: false`); `maxRotation` (0, 30, 50, 90), `minRotation` (0, 30, 45, 90),
  `maxTicksLimit` (0 for auto, 5, 10, 20) and `font size` (8, 12, 16, 24) as
  `SegmentChoice<double>` with the keys `axes.ticks.maxRotation.<v>`,
  `axes.ticks.minRotation.<v>`, `axes.ticks.maxTicksLimit.<v>` and `axes.ticks.font.size.<v>`
  (`<v>` is the integer text). Each list has the default of today.
- This split is the Open item of Chart.js ADR 0031. Put a short comment at the split.

## 4. DIVERGES rows

None. The gallery is not ported library code, and no library file changes. The gallery changes of
the docs configs (the month strings, the Area numbers and `fill: 'origin'`, the `onHover` option)
are in the `///` comments of the config files and in Chart.js ADR 0031 §1.2.

## 5. Tests

All gallery tests import `flutter_test`. The gallery tests do not run in `test:web`.

### 5.1 New `G/test/chart_types_test.dart` (U3)

For each entry and each variant (13 charts):

- The tap on `gallery.type.<stem>` opens the page.
- `chart.config.type` is the type of the docs block. Each meta controller is the expected class:
  `BarController`, `BubbleController`, `DoughnutController`, `PieController`, `LineController`,
  `PolarAreaController`, `RadarController`, `ScatterController`; Mixed has `BarController` and
  `LineController`.
- The data element counts: area 8, bar 7 (both variants), bubble 2, doughnut 3, pie 3, line 7
  (both), mixed 4 and 4, polar 5, radar 7 and 7, scatter 4.
- The host height is the host width divided by the aspect ratio, within 1 px: 1 for doughnut,
  pie, polar and radar, 2 for the others.
- No exception after the first frame and after `pumpAndSettle` (the default animation).
- At 412 x 915 and at 360 x 640 logical pixels: `tester.getRect(find.byKey(
  ValueKey('type.<stem>.host')))` lies inside the view.
- The page has no `ChoiceChip`, `FilterChip`, `ToggleChips`, `SliderControl`, `PopupMenuButton`,
  `DropdownButton` or `Scrollable` with a horizontal axis.
- Bar, Doughnut and Line: a tap on the second variant makes a new `Chart` (not identical to the
  old one) of the second variant; the old chart is destroyed.
- Area: the dataset option `fill` is `'origin'`; `chart.isPluginEnabled('filler')` is false; the
  data is the list of §3.9. The test does not fail on the printed `fill` warning (Area and Radar).
- A mouse hover over the pixel of element 2 of dataset 0 writes `d0#2` and the
  `getLabelAndValue(2)` text into the readout (bar, line, scatter, doughnut).

### 5.2 `G/test/gallery_test.dart` (U3)

The nine tiles have the keys `gallery.type.<stem>` in the docs order, each is enabled; eight have
`Icons.check_circle_outline`; Area has `Icons.timelapse` and its note.

### 5.3 `G/test/stress_chart_test.dart` (U2)

- For each `StressChartType` at its smallest count: the mode `chart` makes a chart of that type,
  the controller class of the type, `controller.enableOptionSharing == type.sharing`, the dataset
  element (a `LineElement` for line and radar, none for the others; scatter none with
  `showLine: false`).
- line and scatter, `CALL=update`, 600 frames of `StressPointField.step` at N = 5000 with
  `update('none')` (a frameless loop is enough: build a `Chart` on a `UiCanvasElement` as the
  benchmark does): after each frame, `meta.controller` drew all points (`_drawStart` 0 or unset,
  `_drawCount` N or unset), no point has `skip`, and each point is at
  `area.left + x * area.width` and `area.bottom - y * area.height` within 1e-9 px.
- The trap: data with a point at `x = 1` in the middle and unsorted x: all points draw.
- line and scatter: the chart area is the canvas (`0, 0, 800, 480` for an 800 x 480 canvas), and
  `meta.clip.disabled` is true (or the port form of a disabled clip).
- polarArea and radar: the range of `r` is `[0, 1]` after an update.
- The STRESS keys of the mode `chart`: `type`, `sharing`, `scriptable`, the four parts;
  `showLine` only with `SHOWLINE=1`.
- The tab: `stress.chart.type.<name>` exists for the 8 types, a tap makes a new chart of that
  type, the N line shows the counts of the type, `stress.chart.sharing` does not exist,
  `stress.chart.showLine` exists only for line and scatter.
- The define rules of ADR 0031 §5.6 (test the pure function behind `stressType`, for example a
  `parseStressType(String type, String sharing, StressMode mode)` in `main_stress.dart`).

### 5.4 `G/test/stress_axes_test.dart` (U2)

`chart.config.type` is `line`; the controller is a `LineController`; `showLine` is false; the
dataset clip is disabled; the chart area equals the chart area of the same host at `0e0ab93`
(record the value in the test, with its source); ticks and rotation as before; the STRESS line has
`elementsMs`.

### 5.5 `G/test/chart_bench_test.dart` (U2)

- `chart.a`, `chart.b` and `chart.c` have the key `type` (`line`, `line` and `scatter`, `line`) and
  keep `sharing` and `scriptable`.
- The cases `chart.<type>` for the six other types exist after all `axes` cases, two calls each;
  `selectChartBenchCases('bar')` and `('chart.bar')` give the two bar cases.
- A case without the define `N` runs its own counts; `N` overrides them.
- One tiny run (N = 10) of each new case gives a BENCH line with `type`, `sharing` and the four
  parts, and an update moves the values.
- No case has the type `stressPoint`.

### 5.6 `G/test/core_demo_test.dart` and `G/test/axes_demo_test.dart` (U4)

- `chart.config.type` is `line`; the controller is a `LineController`; `meta.dataset` is a
  `LineElement`.
- Core: the point pixels are `getPixelForValue` of the hidden scales, and equal the fraction
  formula within 1e-9 px; the readout keeps `PointOptions`, `$shared true`, `frozen`.
- Core: each key of §3.13 exists; a tap on `core.mode.index` and on `core.hover.duration.1000`
  changes the resolved option; a tap on `core.data.add` adds a point and leaves the segment not
  selected.
- Core at 412 x 915: the host lies inside the view. Axes at 412 x 915: the host lies inside the
  view.
- Both tabs: no `ChoiceChip`, `FilterChip`, `ToggleChips`, `SliderControl` or horizontal
  `Scrollable`.
- Replace each `find.byType(ChoiceChip)` and slider drag of the current tests with the segment
  keys.

### 5.7 Other tests

- `G/test/chart_canvas_test.dart`: the type `line`, `registerGalleryComponents` from
  `gallery_components.dart`.
- A test of `registerGalleryComponents`: the registry has the eight controllers of phase 7 and no
  `stressPoint` controller.
- The phase 3 page test (`canvas_host_demo_test.dart`) at 412 x 915: in the mode `chart`, the
  host `stress.chart.host` lies inside the view.
- `grep -rn 'StressPointController\|stress_point_controller\|initialSharing' G` gives no hit.

## 6. Bridge patch for the A/B of step 7 (U6)

Apply to a worktree of `0e0ab93` (side A'). It changes only
`apps/chartjs_gallery/lib/demo/stress_chart_config.dart`:

```diff
--- a/apps/chartjs_gallery/lib/demo/stress_chart_config.dart
+++ b/apps/chartjs_gallery/lib/demo/stress_chart_config.dart
@@ -147,6 +147,8 @@
         'borderWidth': 1.0,
         'pointStyle': 'circle',
         'radius': 3.0,
+        // Bridge (Chart.js ADR 0031 section 8): no dataset clip.
+        'clip': false,
       },
     ],
   },
@@ -156,6 +158,24 @@
         : false,
     'events': <String>[],
     'maintainAspectRatio': false,
+    // Bridge (Chart.js ADR 0031 section 8): the hidden unit scales of the
+    // phase 7 mode chart, on the scale path of StressPointController.
+    'layout': <String, Object?>{'autoPadding': false},
+    'scales': <String, Object?>{
+      'x': <String, Object?>{
+        'type': 'linear',
+        'display': false,
+        'ticks': <String, Object?>{'display': false},
+        'suggestedMin': 0.0,
+        'suggestedMax': 1.0,
+      },
+      'y': <String, Object?>{
+        'type': 'linear',
+        'display': false,
+        'ticks': <String, Object?>{'display': false},
+        'min': 0.0,
+        'max': 1.0,
+      },
+    },
     ...options,
   },
   'plugins': <Object?>[...plugins],
```

- Check with `git apply --check` in the worktree. `...options` comes last, so the mode `axes` keeps
  its own scales.
- Before the first run, a test in the worktree confirms that `StressPointController` takes its
  scale path with these scales (the pixels equal `getPixelForValue`).
- Sides: A `0e0ab93`, A' `0e0ab93` with the patch, B the phase 7 tree. Cases `chart.a`, `chart.b`
  (sharing on and off), `chart.c` on the Pixel 8a, with the protocol of the phase prompt
  ("Measurement method"). Report A to A' and A' to B separately, and the part `elements` of B.

## 7. Doc notes for the integration agent (U5)

- `AGENTS.md`, Layout, `apps/chartjs_gallery`:
  - The home list opens a page for each chart type (`lib/charts/`), with the configs of the
    docs blocks in `lib/docs/` (rule-2 headers). Area is partial until phase 8.
  - The Core tab and the Axes tab run a `LineController` chart. Replace the sentences on
    `StressPointController` and "Phase 7 replaces `StressPointController` ...".
  - The stress mode `chart` takes the chart type (`TYPE`); `lib/demo/gallery_components.dart` has
    `registerGalleryComponents`.
  - The layout rule: full-width segmented buttons, the chart in view at 412 x 915 (Chart.js ADR
    0031 §10).
  - The ADR list of `doc/adr/`: add Chart.js ADR 0031 (proposed).
- `P/doc/performance.md` §6: the define `TYPE` (8 types), `SHARING` as an alias, `SHOWLINE`, the
  part `elements` and its hooks, the new benchmark cases and `counts`, `N` without a default, the
  hidden-scale config of the mode `chart` and its reason (exact pixels, no dropped points, the
  phase 5 chart area and draw split), the A/A'/B protocol of §6. The gallery figures of Chart.js
  ADR 0031 (G1-G8, J2, J3) go to "13.5 The stress chart of phase 7 (Chart.js ADR 0031)". The step
  7 section (13.6) gets the after figures next to the before figures of `phase7/perf/before/`
  (the numbers of `../work-plan.md`, "Doc numbering").
- `P/doc/porting-flow.md`: no change, unless the integration agent finds a sentence on
  `StressPointController`; then it names the ported controllers.
- `P/doc/status.yaml`: no gallery row exists. No change. Run `dart run melos run parity` only if
  another unit changes `status.yaml`.
- `P/doc/phase7-progress.md`: record the gallery step and the Open items of Chart.js ADR 0031 (the
  Axes tab split for the maintainer; the phase 8 opt-out of the legend).
- `P/doc/adr/0021-typed-options-in-the-resolver.md`: no change (proposed; this work completes its
  §8 last item). ADR status lines never change.

## 8. Gates of the gallery step

`dart run melos run format:check`, `analyze`, `test --no-select`, `gallery:build:web`,
`gallery:build:android`. Before the push, the gallery wasm build in the VS Code integrated browser:
open each type page, hover a chart, open the stress tab in the mode `chart` for each type.
