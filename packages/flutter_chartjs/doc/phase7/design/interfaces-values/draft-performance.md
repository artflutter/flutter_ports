# Design panel "Controller interfaces and values": draft "performance first"

- Panel: phase 7, step 2 (Design). Future Chart.js ADR 0028 (proposed).
- Lens: performance first. For each question, this draft looks for the fastest form that keeps
  the behavior that Chart.js ADR 0009 protects (the ticks, the hit element, the item order, the
  resolved option, a throw). It measures each candidate on AOT and on dart2wasm.
- Pin: Chart.js `v4.5.1+7169e651` (`third_party/Chart.js`, `git log -1` gives `7169e65`). All
  upstream `file:line` citations below are at the pin. The line numbers of `index.d.ts` differ
  from the ones in Chart.js ADR 0025, which cites v4.5.1 (`9c5cf9fa`).
- Inputs: `doc/phase7/members-cartesian.md`, `doc/phase7/members-radial.md`, Chart.js ADRs 0003,
  0006, 0009, 0017, 0020, 0021, 0023 and 0025, `doc/performance.md` §11.2-§11.3.

## 0. Method and evidence

### 0.1 Scripts

Scratch folder `S` =
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/interfaces-values-performance/`.

| Id | Script | Output | Question |
|---|---|---|---|
| B1 | `S/bench/bench_points.dart` | `S/bench/points_all_aot_{1,2,3}.out`, `S/bench/wpoints_all_wasm_{1,2,3}.out` | Q3 |
| B2 | `S/bench/bench_visibility.dart` | `S/bench/vis_aot_{1,2,3}.out`, `S/bench/wvis_wasm_{1,2,3}.out` | Q4, Q1 |
| B3 | `S/bench/bench_misc.dart` | `S/bench/misc_aot_{1,2,3}.out`, `S/bench/wmisc_wasm_{1,2,3}.out`, `S/bench/ins_aot_{1,2,3}.out`, `S/bench/wins_wasm_{1,2,3}.out` (`-Dinserts=true`) | Q1, Q3, Q5 |
| P1 | `S/probe_spacing.mjs` (x64 Node.js, pinned build) | `S/probe_spacing.out`, `S/probe_spacing.rerun.out` (byte-identical) | Q5 |
| P2 | `S/probe/spacing_write.dart` | `S/probe/spacing_write.out` | Q5 |
| P3 | `S/probe/typed_list.dart` | `S/probe/typed_list.out` | Q3 |
| P4 | `S/probe/probe_label.mjs` (x64 Node.js, pinned build) | `S/probe/probe_label.out` | Q2 |

Shared files: `S/bench/harness.dart` (the timer: a warm-up, then 15 rounds of about 120 ms for
each case, in a rotated order; it prints the median, the min and the max of the rounds),
`S/bench/run_wasm.mjs` (runs a dart2wasm module in Node.js), `S/bench/summarize.py` (the range of
the process medians).

Commands (from `S/bench`, `P` = `/Users/vasilich/IdeaProjects/flutter_ports/.dart_tool/package_config.json`):

```sh
dart compile exe  --packages=$P bench_visibility.dart -o vis.exe
dart compile wasm --packages=$P bench_visibility.dart -o wvis.wasm
for r in 1 2 3; do ./vis.exe > vis_aot_$r.out; node run_wasm.mjs wvis > wvis_wasm_$r.out; done
python3 -I summarize.py 'vis_aot_*.out' 'wvis_wasm_*.out'
```

The Node.js probes run with
`CHARTJS_DIST=<scratchpad>/env/chartjs-build/dist/chart.js /usr/bin/arch -x86_64 <scratchpad>/env/node-v24.12.0-darwin-x64/bin/node <probe>`.
`tool/reference/scale_chart_common.mjs` (`loadChartJs`) stops unless Node.js is x64 and the
build has the version of the pin.

### 0.2 Machine and reading of the figures

- Apple M3 Max, Darwin 25.5, Dart SDK 3.12.2. dart2wasm modules run in Node.js v24.12.0 (V8, as
  in Chrome). The x64 rule of Chart.js ADR 0010 applies to JS reference values, not to the
  timing of Dart code.
- Other sessions used the machine (load average 5-6). Each process runs all forms of one question
  in a rotated order. Thus each A/B pair shares the same load. The tables give the range of the
  three process medians.
- These are micro benchmarks. The decision protocol accepts them for a form that keeps the
  upstream structure. Section 8 lists the frame figures that phase 7 step 7 records.

## Q1. The interface members that a controller reads first

### Q1.1 Options

- **A. Interface members** (Chart.js ADR 0003: a member with its first ported caller; Chart.js
  ADR 0025 §5 for `types.Scale` and `types.RadialLinearScale`). The controllers import only
  `lib/src/types/`, `core.datasetController.dart` and helpers, as upstream imports only
  `DatasetController` and helpers.
- **B. Casts to the concrete classes** (`chart as Chart`, `scale as Scale`, `el as Element`,
  `meta as ChartMeta`). This is the form of the scout risk lists (members-radial.md R1). It adds
  imports of `core.controller.dart`, `core.scale.dart` and `core.element.dart` that upstream
  does not have.
- **C. Mixed**: interface members, and a cast only where a measurement shows a gain.

### Q1.2 Evidence: the cost of an interface call

B3 and B2, ns for each call (range of the 3 process medians):

| Call | AOT | wasm |
|---|---|---|
| `getBasePixel()` through an interface that one class hierarchy implements, receivers of 3 subclasses (`basePixel_if`) | 3.4 | 3.2-3.3 |
| The same call after a cast to the base class (`basePixel_cast`) | 3.4 | 3.2-3.3 |
| The `active` getter through the interface (`active_if`) | 0.4 | 0.3 |
| The `active` getter after a cast (`active_cast`) | 0.4 | 0.3 |
| `getDataVisibility` (upstream body) through `types.Chart` with two classes (`up_if`, 1000 / 20000 indices) | 14.9-15.2 / 18.0-18.3 | 15.7-16.5 / 19.2-19.9 |
| The same after a cast to the concrete chart (`up_cast`) | 14.8-15.0 / 17.7-18.1 | 12.2-13.2 / 16.0-16.6 |

- In the app, one class hierarchy implements each of `types.Scale` (`Scale` and its
  subclasses), `types.Element`, `types.ChartMeta` and `types.DatasetController`. The test fakes
  are not in the app. For such an interface, the interface call costs the same as the call after
  a cast, on AOT and on wasm.
- `types.Chart` has two implementors in the gallery (`Chart`, `DemoChart`,
  `apps/chartjs_gallery/lib/demo/demo_chart.dart:40`). There, a cast saves 0-0.3 ns on AOT and
  2.5-3.5 ns on wasm for each call. Q4 removes most of the cost in another way (12-17 ns for each
  call).
- A cast to `Chart` narrows the accepted chart. `controllerArgs`
  (`core.datasetController.dart:612`) accepts any `types.Chart`. The test fakes `_FakeChart`
  (`test/port/core/core.datasetController_test.dart:514`) and the platform `FakeChart` drive real
  controllers. A cast throws a `TypeError` there, where upstream reads the members of any object.

### Q1.3 Choice: A

Interface members everywhere. No controller casts to `Chart`, `Scale`, `ChartMeta` or
`DatasetController` of the concrete core files. The only casts are:

1. A cast to the own class or to a superclass in the own library, for an upstream `_` member that
   only that library reads: `meta.controller as DoughnutController` for `_getRotation()` and
   `_getCircumference()` (`controller.doughnut.js:192-195`). This adds no import. Upstream
   throws a `TypeError` for a controller without these methods. The Dart cast also throws a
   `TypeError`.
2. A cast to a type interface for a member that only a subtype declares:
   `meta.rScale as types.RadialLinearScale` (`controller.polarArea.js:166`,
   `controller.radar.js:82`), `meta.dataset as types.LineElement` at the draw
   (`controller.line.js:140`), `data[i] as types.PointElement` for `size` (`controller.line.js:133`,
   `controller.bubble.js:88`), `element as types.VisualElement` at the draw
   (`controller.bar.js:677`, as `core.datasetController.dart:1403` already does). Each cast runs
   once for each update or each draw call of an element. Upstream throws a `TypeError` at the
   first absent member. The cast throws a `TypeError` in the same call.

`DatasetController.updateElement` takes `types.Element` (`index.d.ts:674`
`element: TElement | TDatasetElement`) and casts to `Element` inside (`core.datasetController.dart`
already imports `core.element.dart`). Thus no controller imports `core.element.dart`. The cast
moves from the call site into the callee. Its cost is the same (`active_cast`: 0.4 ns).

### Q1.4 The members, with their first readers

Each first reader was checked at the pin. "dc.js" is `src/core/core.datasetController.js`, "cc.js"
is `src/core/core.controller.js`, "cs.js" is `src/core/core.scale.js`, "rl.js" is
`src/scales/scale.radialLinear.js`.

**`types.Scale`** (the forms of Chart.js ADR 0025 §5, unchanged):

| Dart member | index.d.ts | Core source | First reader |
|---|---|---|---|
| `Map<String, Object?> get cache` | none (`_cache`) | cs.js:247, :373 | `controller.bar.js:8`, :15, :17 |
| `List<Tick>? get ticks` | :1321 | cs.js:226, :410, :435 | `controller.bar.js:47` |
| `double? getPixelForTick(int index)` | :1346 | cs.js `getPixelForTick` | `controller.bar.js:48` |
| `double getBasePixel()` | :1382 | cs.js `getBasePixel` | `controller.bar.js:396`; `controller.line.js:101`, `controller.scatter.js:130`, `controller.bubble.js:130` |
| `double get startPixel`, `double get endPixel` | none (`_startPixel`, `_endPixel`) | cs.js:237, :239 | `controller.bar.js:549-550` |
| `double getPixelForDecimal(double decimal)` | :1339 | cs.js `getPixelForDecimal` | `controller.bar.js:606-607`, `controller.bubble.js:129` |
| `double? getValueForPixel(double pixel)` | :1374 | cs.js `getValueForPixel` | `controller.bar.js:615` |
| `double getLineWidthForValue(Object? value)` | :1357 | cs.js `getLineWidthForValue` | `controller.bar.js:620` |

`getBaseValue` (:1376) waits for its first reader, `filler.options.js` (phase 8).

**`types.RadialLinearScale implements Scale`** (index.d.ts:3676-3688, Chart.js ADR 0025 §5):

| Dart member | index.d.ts | rl.js | First reader |
|---|---|---|---|
| `double get xCenter` | :3677 | :416, :431 | `controller.polarArea.js:167`, `controller.radar.js:90` |
| `double get yCenter` | :3678 | :418, :432 | `controller.polarArea.js:168`, `controller.radar.js:91` |
| `double getIndexAngle(double index)` | :3681 | :482 | `controller.polarArea.js:169` |
| `double getDistanceFromCenterForValue(Object? value)` | :3682 | :489 | `controller.polarArea.js:182` |
| `({double x, double y, double angle}) getPointPositionForValue(double index, Object? value)` | :3685 | :529 | `controller.radar.js:88` |

The record stays (Chart.js ADR 0003, ADR 0025 Open 5). A class is 3.5-4.5 ns faster for each
call (performance.md §11.3). A radar update makes one call for each point. The gain is below
1 µs for each update of a radar chart with 200 points. That gain does not justify a new ADR that
supersedes the record rule.

**`types.Chart`**:

| Dart member | index.d.ts | cc.js | First reader |
|---|---|---|---|
| `bool isDatasetVisible(double datasetIndex)` | :569 | :863 | `controller.doughnut.js:192`, :340, :380 |
| `double getVisibleDatasetCount()` | :568 | :859 | `controller.polarArea.js:155` |
| `void toggleDataVisibility(double index)` | :571 | :881 | `controller.doughnut.js:126`, `controller.polarArea.js:66` |
| `void update([Object? mode])` | :559 | :475 | `controller.doughnut.js:127`, `controller.polarArea.js:67` |
| `LegendElement? get legend` | :543 | written by `plugin.legend.js:602` | `controller.doughnut.js:97`, `controller.polarArea.js:41` (Q6) |

`getDataVisibility` exists (Chart.js ADR 0025 §4). Q4 changes its body only.

**`types.ChartMeta`**:

| Dart member | Upstream | First reader |
|---|---|---|
| `abstract double? total` | index.d.ts:373-375 `DoughnutMetaExtensions.total` | write `controller.doughnut.js:235`, read :313 |
| `Object? get dataset_` | cc.js:845 `_dataset` (index.d.ts does not declare it); the name of Chart.js ADR 0023 | `controller.line.js:43`, :78, :107; `controller.scatter.js:77`, :113, :136 |
| `abstract List<Element> data` (a setter beside the getter) | index.d.ts:484 `data: TElement[]` (not readonly); cc.js:837 | the port-only write of Q3 in `DatasetController.initialize` |

`total` is a typed field of the concrete `ChartMeta`, not an extra property of the Map of
`operator []`. B3: the field read costs 0.7 ns. The by-name read through the extras Map costs
11.2-11.7 ns (AOT) and 18.1-18.7 ns (wasm). `calculateCircumference` reads it for each arc
(`controller.doughnut.js:313`). The by-name read `meta['total']` and write `meta['total'] = v`
map to the field: Dart `null` reads as `undefined`, the start value. A write of a value that is
not a number throws a `TypeError`, as for the other typed fields of `ChartMeta`
(`core.controller.dart:483-487`).

**`types.DatasetController`**:

| Dart member | Upstream | First reader |
|---|---|---|
| `Map<String, Object?> get options` | dc.js:262, :442 (index.d.ts does not declare it) | `controller.bar.js:437` (`meta.controller.options.grouped`) |
| `Object? getParsed(double index)` | index.d.ts:688, dc.js:579 | `controller.bar.js:440` |
| `Map<String, Object?> getStyle(double? index, [bool? active])` | index.d.ts:656, dc.js:752 | `controller.doughnut.js:101`, `controller.polarArea.js:45` |
| `Map<String, Object?> resolveDataElementOptions(double index, [String? mode])` | index.d.ts:658, dc.js:797 | `controller.doughnut.js:354` |

**`types.Element`**:

| Dart member | Upstream | First reader |
|---|---|---|
| `bool get active` | `core.element.ts:13` | `controller.bar.js:418`, `controller.line.js:111`, `controller.doughnut.js:288`, `controller.polarArea.js:201`, `controller.radar.js:87`, `controller.scatter.js:140`, `controller.bubble.js:135` |
| `Object? get hidden` | cc.js:892-899 (`_updateVisibility` writes it); not declared in `core.element.ts` | `controller.bar.js:676`, `controller.doughnut.js:250`, :304 |

**`types.LineElement`** and **`types.PointElement`**:

| Dart member | Upstream | First reader |
|---|---|---|
| `void updateControlPoints(ChartArea chartArea, [String? indexAxis])` on `LineElement` | index.d.ts:2025, `element.line.js:299` | `controller.line.js:140` |
| `double size([Map<String, Object?>? options])` on `PointElement` | `element.point.ts:81` | `controller.line.js:133`, `controller.scatter.js:163`, `controller.bubble.js:88` |
| No `points` setter on `LineElement` | index.d.ts:2026, `element.line.js:308` | see below |

The four line writes of `controller.line.js:57-60`, `controller.scatter.js:80-83` and
`controller.radar.js:60` go through the by-name write of `types.PropertyAccess`
(`line['_chart']`, `line['_datasetIndex']`, `line['_decimated']`, `line['points']`;
`element.line.dart:1139-1170`). Reasons:

- Upstream writes these properties on any dataset element. A dataset element that is not a line
  (a user `datasetElementType`) takes them upstream. The by-name write of `Element` takes them
  too (the extras Map). A cast to `types.LineElement` throws a `TypeError` in `update`.
  Upstream throws later, at `meta.dataset.updateControlPoints` in `draw` (`controller.line.js:140`),
  which runs in an animation frame. The by-name form keeps the throw in the same call as
  upstream.
- B3: the three by-name writes cost 4.7-4.8 ns (AOT) and 39.5-40.2 ns (wasm) for each update
  of a dataset. The interface setters cost 1.1 ns and 0.6 ns. The difference is below 0.04 µs for
  each update. Thus the faster form gives no measurable gain.

### Q1.5 Code form (`lib/src/types/index.dart`)

```dart
abstract interface class Chart {
  // ... existing members ...

  /// index.d.ts:543 `readonly legend?: LegendElement`. Dart `null` stands
  /// for JS `undefined`: only the legend plugin (phase 8) writes it
  /// (plugin.legend.js:602).
  LegendElement? get legend;

  /// index.d.ts:559 `update(mode?)`. controller.doughnut.js:127 calls it.
  void update([Object? mode]);

  /// index.d.ts:568 `getVisibleDatasetCount(): number`.
  double getVisibleDatasetCount();

  /// index.d.ts:569 `isDatasetVisible(datasetIndex: number): boolean`.
  bool isDatasetVisible(double datasetIndex);

  /// index.d.ts:571 `toggleDataVisibility(index: number): void`.
  void toggleDataVisibility(double index);
}

/// index.d.ts:2414 `LegendElement`, with the members that the option
/// functions of the controllers read (controller.doughnut.js:97, :126).
/// Phase 8 adds `implements Element, LayoutItem` with the `Legend` class.
abstract interface class LegendElement {
  /// index.d.ts:2415 `chart: Chart`.
  Chart get chart;

  /// index.d.ts:2418 `options: LegendOptions`, the resolver of the
  /// legend options.
  Map<String, Object?> get options;
}

abstract interface class ChartMeta {
  /// index.d.ts:484 `data: TElement[]`. The setter is port-only: it lets
  /// `DatasetController.initialize` give a typed list (Chart.js ADR 0028,
  /// section 3).
  abstract List<Element> data;

  /// core.controller.js:845 `_dataset`. The trailing underscore follows
  /// Chart.js ADR 0023: [dataset] is the dataset element.
  Object? get dataset_;

  /// index.d.ts:374 `DoughnutMetaExtensions.total`. Dart `null` stands
  /// for JS `undefined`, the value before controller.doughnut.js:235.
  abstract double? total;
}

abstract interface class DatasetController {
  /// core.datasetController.js:442 `options`, the dataset resolver.
  Map<String, Object?> get options;
  /// index.d.ts:688 `getParsed(index)`.
  Object? getParsed(double index);
  /// index.d.ts:656 `getStyle(index, active)`.
  Map<String, Object?> getStyle(double? index, [bool? active]);
  /// index.d.ts:658 `resolveDataElementOptions(index, mode)`.
  Map<String, Object?> resolveDataElementOptions(double index, [String? mode]);
}

abstract interface class Element implements Point {
  /// core.element.ts:13 `active = false`.
  bool get active;
  /// core.controller.js:899 `meta.data[dataIndex].hidden`: any value.
  Object? get hidden;
}
```

`types.Scale` gets the nine members of the table, `types.RadialLinearScale` the five members.
`RadialLinearScale` (`scale.radialLinear.dart:731`) implements `types.RadialLinearScale`. Each
concrete member gets `@override`.

## Q2. The label of `getLabelAndValue`

### Q2.1 Upstream and the existing forms

- index.d.ts:641 declares `{label: string; value: string}`.
- dc.js:687-695 (base) and `controller.bar.js:364-376` return strings (`'' + …`, or `''`).
- `controller.scatter.js:42-53`, `controller.bubble.js:96-109`, `controller.doughnut.js:320-330`
  and `controller.polarArea.js:97-107` return `labels[index] || ''`, the raw label.
- `controller.radar.js:39-47` returns `vScale.getLabels()[index]` without `|| ''`.
- `value` is a string in all eight forms (`'' + …`, `'(' + … + ')'`, or `formatNumber`).
- The Dart base is `({String label, String value})` (`core.datasetController.dart:1339`).

P4 (x64 Node.js at the pin, labels `[['line 1', 'line 2'], 7, '', null, 'e']`, 6 data points):

| Type | index 0 | 1 | 2 | 3 (`null` label) | 5 (no label) | `typeof value` |
|---|---|---|---|---|---|---|
| bar, line | `"line 1,line 2"` | `"7"` | `""` | `"undefined"` | `"undefined"` | string |
| scatter, bubble, doughnut, pie, polarArea | `["line 1","line 2"]` | `7` | `""` | `""` | `""` | string |
| radar | `["line 1","line 2"]` | `7` | `""` | `null` | `undefined` | string |

The reader is `createTooltipItem` (`plugin.tooltip.js:126-142`). The default `title` callback
returns `item.label` (`plugin.tooltip.js:372-373`). An array label gives a title with one line for
each item. The spec reads `tooltip.title` (`controller.bar.tests.js:1831`,
`controller.bubble.tests.js:404`).

### Q2.2 Options

- **A. `({String label, String value})`** (the current Dart form): the overrides convert the raw
  label with `jsToString`. An array label then gives one title line `line 1,line 2`, where
  upstream gives two lines. This changes a spec-read value of phase 8. Rejected.
- **B. `({Object? label, String value})`**: the raw label. Dart `null` is JS `null`, the
  `undefined` sentinel is JS `undefined` (radar index 5).
- **C. A class with `Object? label` and `String value`**: no gain. The method runs once for each
  tooltip item, not in a loop of the update or the draw.

### Q2.3 Choice: B

Performance does not separate the options: the record and the class cost the same for one call
for each tooltip item. B keeps the upstream values. It changes only the type of one record field.

### Q2.4 Code form and effects

```dart
/// core.datasetController.js:687 `getLabelAndValue(index)`.
/// @protected
///
/// index.d.ts:641 declares `label: string`. The scatter, bubble, doughnut,
/// polar area and radar overrides return the raw label of
/// `chart.data.labels` (Chart.js ADR 0028, section 2): any value. Dart
/// `null` is JS `null`, and the [undefined] sentinel is JS `undefined`.
/// [value] is always a string.
({Object? label, String value}) getLabelAndValue(double index) { ... }
```

- `core.datasetController.dart`: the record type changes. The body stays.
- The eight overrides use the same record type. `labels[index] || ''` is
  `jsTruthy(label) ? label : ''` with `label = jsGet(labels, index)`; `labels` is
  `jsGet(chart.data, 'labels')`, or `<Object?>[]` when that value is falsy.
- `test/port/core/core.datasetController_test.dart:863-869` reads the record. It encodes the
  label as `Object?` already. It needs no change.
- Phase 8: the tooltip item gets `Object? label` from the record.

## Q3. `meta.data` and `line.points`

### Q3.1 Upstream

- `controller.line.js:43` destructures `data: points` from the meta, and :60 writes
  `line.points = points`. Thus the line and the meta share one array. `controller.scatter.js:83`
  and `controller.radar.js:60` do the same.
- `element.line.js:308-313` stores the array as `_points`.
- `_getStartAndCountOfVisiblePoints(meta, points, …)` (`controller.line.js:46`,
  `helpers.extras.ts:88`) reads `points.length` and the points through `_lookupByKey`.
- The Dart types: `ChartMeta.data` is `final List<types.Element> data = []`
  (`core.controller.dart:296-298`). `LineElement.points` and `getStartAndCountOfVisiblePoints`
  take `List<types.PointElement>` (`element.line.dart:826-828`, `helpers.extras.dart:207`;
  difference `adapt-line-points-elements`).

### Q3.2 Options

- **view** (the gallery form, `apps/chartjs_gallery/lib/demo/stress_point_controller.dart:139`):
  `line.points = meta.data.cast<types.PointElement>()`. Each read through the view checks the
  type of the item. `identical(line.points, meta.data)` is false.
- **copy**: `List<types.PointElement>.of(meta.data.cast())` at each update. No sharing.
- **fast**: a non-generic `ListBase<types.PointElement>` over `meta.data` that casts each item
  (`PointList` of B1). `identical` is false.
- **wide points**: `LineElement.points` becomes `List<types.Element>`, and each reader in
  `element.line.dart`, `helpers.segment.dart` and `helpers.curve.dart` casts each point. B1
  `read_as` measures the read. This changes three phase 4 files and the row
  `adapt-line-points-elements`.
- **typed**: the runtime type of `meta.data` is `List<types.PointElement>` when the data elements
  are points. The line keeps the same object. `identical(line.points, meta.data)` is true, as
  upstream (P3 item 4).

### Q3.3 Evidence

B1: the real `LineElement` and `PointElement` of `lib/src/elements/`, a stub context that
records the path. `draw_*`: one `LineElement.draw` for each op, with `animated` true, so each draw
builds the path again (`element.line.js:440-444`). `update_*`: `line.points = …`, then one draw.
`read_*`: a loop that reads `x`, `y` and `skip` of each point. µs for each op:

| Form | draw 1000 AOT | draw 20000 AOT | draw 1000 wasm | draw 20000 wasm |
|---|---|---|---|---|
| typed | 23.3-23.7 | 265-289 | 28.3-29.2 | 412-423 |
| view | 24.5-24.8 | 281-300 | 32.2-33.0 | 475-489 |
| copy | 23.4-24.0 | 264-292 | 28.3-29.4 | 411-423 |
| fast | 23.3-24.5 | 273-296 | 28.6-29.6 | 418-432 |

| Form | update+draw 1000 AOT | 20000 AOT | 1000 wasm | 20000 wasm |
|---|---|---|---|---|
| typed | 27.6-28.4 | 345-372 | 39.2-40.3 | 620-638 |
| view | 29.3-30.7 | 392-403 | 46.3-47.4 | 754-776 |
| copy | 34.8-35.3 | 484-510 | 60.7-63.0 | 1074-1113 |
| fast | 28.4-29.6 | 381-389 | 40.4-41.6 | 641-661 |

| Read loop (µs) | 1000 AOT | 20000 AOT | 1000 wasm | 20000 wasm |
|---|---|---|---|---|
| typed | 1.13-1.14 | 34.9-35.3 | 1.12-1.15 | 29.8-30.8 |
| view | 3.59-3.73 | 72.9-73.5 | 5.78-5.97 | 118-125 |
| fast | 3.45-3.50 | 69.2-70.0 | 1.34-1.38 | 32.5-33.7 |
| `as` on each item (wide points) | 3.48-3.50 | 69.6-70.4 | 1.26-1.30 | 31.6-32.5 |

- The view costs 4-6 % of the line draw on AOT and 13-15 % on wasm, and 8-14 % (AOT) and
  21-22 % (wasm) of an update with a draw. On wasm that is 63-66 µs for each draw and 116-156 µs
  for each update and draw of a line with 20000 points.
- The copy breaks the sharing and costs the most at each update (+39 % AOT, +73 % wasm).
- The fast list and the wide points read each point with a type check: the read loop costs 2x on
  AOT. They are close to typed in the draw on wasm, but not on AOT.
- typed is the fastest form in each column, within the noise of copy for the draw only.

P3 (the Dart semantics of a typed list):

1. `insertAll` of a `List<types.Element>` into a `List<types.PointElement>` throws a
   `TypeError`, also when each item is a point element. The check is on the type of the iterable.
2. The hole filler of `_insertElements` (`core.datasetController.dart:497`, an `Element`) throws a
   `TypeError` in a typed list.
3. Element writes (`add`, `[]=`) check each item and pass for point elements. A non-point item
   throws a `TypeError`.
4. `LineElement.points` keeps the typed list object (`identical` true). A cast view is a new
   object (`identical` false).
5. The by-name write `line['points'] = list` accepts the typed list, and throws an
   `ArgumentError` for a `List<types.Element>` (row `adapt-line-points-elements`).

B3: the insert of new data elements, ns for each element, with the construction of the
`PointElement`:

| Form | 1000 AOT | 20000 AOT | 1000 wasm | 20000 wasm |
|---|---|---|---|---|
| current: hole filler, then a write of each element (`List<types.Element>`) | 5.3-5.4 | 11.0-11.1 | 2.9 | 5.0-5.3 |
| typed, append: `data.add(element)` for each element | 4.4-4.5 | 11.0-11.4 | 3.0-3.1 | 5.5-5.6 |
| typed, move: build the elements, grow, shift, write | 9.0-9.3 | 22.9 | 5.9-6.1 | 11.0-11.4 |

The append path costs the same as the current form. The move path (an insert before the end, as
`onDataSplice` and `unshift` give) costs 4-12 ns more for each inserted element, once. A line
draw then saves 0.6-3.3 ns for each point in each frame.

### Q3.4 Choice: typed, made by `DatasetController.initialize`

- `ChartMeta.data` stays `List<types.Element>` in its static type.
  `DatasetController.initialize` (dc.js:280) replaces the empty list with a
  `List<types.PointElement>` when the data element class is `PointElement.jsClass` or a
  subclass. This covers line, scatter, radar and bubble, and user controllers with point
  elements. The controller constructor sets `dataElementType` before `initialize`
  (dc.js:275-277, `core.datasetController.dart:648-651`). The meta has no element then: elements
  come only from `_insertElements` (dc.js:994-1010).
- A controller with other data elements keeps a `List<types.Element>`. Its line writes then throw
  the `ArgumentError` of `adapt-line-points-elements`, as today.
- `_insertElements` writes elements only: the append path adds each new element. Another start
  grows the list with the new elements, shifts the items from the end, and writes the new
  elements at `start`. This is the move of dc.js:1000-1010 without the hole. The hole filler
  `_hole` goes.
- The line controllers pass `meta.data` unchanged: `line['points'] = points`, and
  `getStartAndCountOfVisiblePoints(meta, points as List<types.PointElement>, …)`. The `as` on the
  list is one check for each update.
- This keeps the upstream structure: no new member, the same call order, the same shared array.
  It adds one port-only statement to `initialize` and one private helper. Thus micro benchmarks
  are the evidence (decision protocol). Section 8 still records the frame figures.

### Q3.5 Code form

```dart
// core.datasetController.dart

/// Port-only (Chart.js ADR 0028, section 3): whether [elementType] is the
/// class value of `PointElement` or of a subclass.
bool _isPointClass(Object? elementType) {
  for (Object? c = elementType; c is JsClass; c = c.superclass) {
    if (identical(c, PointElement.jsClass)) return true;
  }
  return false;
}

/// core.datasetController.js:280 `initialize()`.
void initialize() {
  final meta = cachedMeta;
  // Port-only: a typed list of point elements, so that `line.points =
  // points` (controller.line.js:60) shares it without a cast view
  // (Chart.js ADR 0028, section 3).
  if (meta.data.isEmpty && _isPointClass(dataElementType)) {
    meta.data = <types.PointElement>[];
  }
  configure();
  // ... unchanged ...
}

void _insertElements(double start, double count, [bool? resetNewElements]) {
  final meta = cachedMeta;
  final data = meta.data;
  final s = start.toInt();
  final n = count.toInt();
  // `arr.length += count`, the move and `data[i] = new
  // this.dataElementType()` (:1000-1010). Each write checks one element,
  // so a typed list takes the new elements.
  final created = <types.Element>[
    for (var k = 0; k < n; k++)
      // DIVERGES(chartjs): adapt-component-class-role, the cast throws earlier.
      jsConstruct(dataElementType, const []) as Element,
  ];
  if (s == data.length) {
    for (final element in created) {
      data.add(element);
    }
  } else {
    final end = s + n;
    for (final element in created) {
      data.add(element);
    }
    for (var i = data.length - 1; i >= end; i--) {
      data[i] = data[i - n];
    }
    for (var i = s; i < end; i++) {
      data[i] = created[i - s];
    }
  }
  // ... parsed move, parse, reset: unchanged ...
}
```

`core.controller.dart`: `List<types.Element> data = [];` loses `final`. The by-name write
`meta['data'] = v` takes a `List<types.Element>` and throws a `TypeError` for another value, as
the other typed fields do.

```dart
// controller.line.dart, update (controller.line.js:41-60)
final meta = cachedMeta;
final line = meta.dataset;
final points = meta.data;
final dataset = meta.dataset_;
final animationsDisabled = chart.animationsDisabled;
var (:start, :count) = getStartAndCountOfVisiblePoints(
  meta,
  points as List<types.PointElement>,
  jsTruthy(animationsDisabled),
);
// ...
final access = line! as types.PropertyAccess;
access['_chart'] = chart;
access['_datasetIndex'] = index;
access['_decimated'] = jsTruthy(jsGet(dataset, '_decimated'));
access['points'] = points;
```

## Q4. `getDataVisibility`: interface or cast, and the key string

### Q4.1 Upstream

`cc.js:885-887`: `return !this._hiddenIndices[index]`. The property read converts `index` to a
key string. Only `toggleDataVisibility` (cc.js:881-883) and `_updateHiddenIndices`
(cc.js:570-574, which moves keys) write `_hiddenIndices`. In `src/`, only the legend `onClick` of
doughnut, pie and polar area calls `toggleDataVisibility` (`controller.doughnut.js:126`,
`controller.polarArea.js:66`). Readers for each element: `controller.bar.js:592`,
`controller.doughnut.js:250`, :304, `controller.polarArea.js:130`, :182, :221, :233,
`scale.radialLinear.js:463`.

Dart: `!jsTruthy(_hiddenIndices[jsNumberToString(index)])` (`core.controller.dart:1751-1753`).

### Q4.2 Options

- **up_if**: the upstream body, called through `types.Chart` (Chart.js ADR 0025 §4).
- **up_cast**: the upstream body, called after a cast to `Chart` (ADR 0025 Open 4).
- **empty_if**: a port-only first statement `if (hiddenIndices.isEmpty) return true;`, called
  through the interface. An empty Map gives `undefined` for each key, and `!undefined` is `true`.
  Thus the result is the upstream result for every index, also NaN, -0 and `1e21`.
- **empty_cast**: the same body after a cast.
- **cached keys**: a key table for small integer indices (as `_indexKey` of
  `core.datasetController.dart:530`) for a non-empty Map.

### Q4.3 Evidence (B2)

ns for each call, 1000 / 20000 indices:

| Form | AOT | wasm |
|---|---|---|
| up_if | 14.9-15.2 / 18.0-18.3 | 15.7-16.5 / 19.2-19.9 |
| up_cast | 14.8-15.0 / 17.7-18.1 | 12.2-13.2 / 16.0-16.6 |
| empty_if | 2.8-2.9 / 2.7-2.9 | 2.6-2.7 / 2.5-2.6 |
| empty_cast | 3.4-3.5 / 3.4-3.5 | 0.7 / 0.7 |
| hid_up_if (one hidden index) | 17.5-17.7 / 20.5-20.9 | 18.4-19.5 / 22.0-23.1 |
| hid_empty_if (one hidden index) | 17.5-17.8 / 20.8-21.1 | 18.4-19.2 / 22.3-23.1 |
| loop only (a constant `true`) | 2.3-2.4 / 2.3 | 2.0-2.1 / 2.0 |

- The key string and the Map read are 12-17 ns of each call. The empty test removes them. The
  call then costs 0.4-0.9 ns more than the loop alone.
- With a hidden index, the empty test costs nothing measurable (`hid_empty_if` against
  `hid_up_if`).
- The cast gains nothing on AOT. On wasm it gains 2-3.5 ns. It also narrows the accepted chart
  (Q1.2).
- A bar chart with 20000 bars calls it once for each bar: the empty test saves 0.24-0.34 ms for
  each update on AOT, and 0.33-0.35 ms on wasm. A polar area chart calls it up to four times for
  each arc.

### Q4.4 Choice: empty_if

- The interface call stays (Chart.js ADR 0025 §4).
- `Chart.getDataVisibility` gets the port-only empty test, with a comment that names the ADR, as
  the `value is double` fast paths of Chart.js ADR 0025 §3. It keeps the upstream structure and
  the result. It needs no `DIVERGES` marker.
- No key cache: the Map is not empty only after a legend click on a doughnut, pie or polar area
  chart, or a user call of `toggleDataVisibility`. Those charts have few elements.

```dart
/// core.controller.js:885 `getDataVisibility(index)`.
@override
bool getDataVisibility(double index) {
  final hiddenIndices = _hiddenIndices;
  // Port-only fast path (Chart.js ADR 0028, section 4): an empty object
  // gives `undefined` for each key.
  if (hiddenIndices.isEmpty) return true;
  return !jsTruthy(hiddenIndices[jsNumberToString(index)]);
}
```

## Q5. The #12238 `spacing` and `spacingMode` hunk

### Q5.1 Upstream

- `controller.polarArea.js:194-212`: `properties.options` is
  `this.resolveDataElementOptions(i, …)`. Then :204-210 writes `this.options.spacing` when the
  element value is `0`, and `this.options.spacingMode` when the element value is `'angular'`.
- `controller.polarArea.js:11-27` gives the defaults `spacing: 0`, `spacingMode:
  'proportional'`. `controller.doughnut.js:71-75` gives `spacing: 0`, `spacingMode: 'angular'`,
  and :80-83 makes both keys neither scriptable nor indexable. The doughnut has no hunk.
- dc.js:804-833 (`_resolveElementOptions`): with option sharing, the cached `$shared` object is
  frozen and returned as it is (`cloneIfNotShared`, dc.js:230). Without sharing, the result is
  the new object or a copy. The polar area controller does not set `enableOptionSharing`
  (default `false`). The doughnut sets it to `true` (`controller.doughnut.js:136`).

### Q5.2 Probe P1 (x64 Node.js, pinned build)

P1 runs 66 configurations: the spec cases `controller.polarArea.tests.js:69`, :85,
`controller.doughnut.tests.js:49`, five extra polar area configurations, every fixture of
`test/fixtures/controller.polarArea` (3 animation fixtures need `document.createElement` and do
not load), and the `spacing` and `selfJoin` fixtures of `controller.doughnut`. Each runs four
variants. It reads `spacing`, `spacingMode` and `Object.isFrozen` of each arc after a second
`update()`.

| Variant | Result |
|---|---|
| A: upstream | The default polar area arc gets `spacing: 0`, `spacingMode: 'proportional'`. The scope `datasets.polarArea` comes before `elements.arc` (`core.config.js` `datasetElementScopeKeys`). Options not frozen. |
| B: the hunk removed | Equal to A in 65 of 66 runs. The one difference: `options.elements.arc.spacingMode: 'angular'` gives `'proportional'` in A and `'angular'` in B. |
| C: polar area with `enableOptionSharing = true` | 11 runs throw `TypeError: Cannot assign to read only property 'spacing'` (spec :69 and the `value-*` fixtures). 4 more runs differ only in the frozen state. |
| D: doughnut with `enableOptionSharing = false` | Equal to A in all runs. |

Thus the hunk changes a resolved option only when a user sets an element-level `0` or
`'angular'`. The write is legal only because the polar area controller does not share options.

### Q5.3 Probe P2 (Dart)

- The write into the `ArcOptions` of a polar area result (not frozen) works and gives the new
  value.
- The same write after `jsObjectFreeze` throws a `TypeError` (Chart.js ADR 0021 §5), as variant C
  of P1.
- `value == 0` is true for `0` (an `int` of `jsonDecode`), `0.0` and `-0.0`, and false for
  `'0'`, `null` and `undefined`. This is `=== 0` of JavaScript. `value == 'angular'` is
  `=== 'angular'`.

### Q5.4 Options

- **A. Upstream form**: by-name reads and writes on the result Map, the dataset resolver read for
  each arc where the test holds.
- **B. Typed reads**: `(o as ArcOptions).spacingValue`. A string switch less for each arc, and a
  new import of `element_options.dart` in the controller. A user `dataElementType` with other
  options throws at the cast, where upstream writes the key.
- **C. Hoist `this.options.spacing` out of the loop.** B3: a cached resolver read costs 5.6-5.7 ns
  (AOT) and 8.4-8.5 ns (wasm). The resolver caches the key, so a scriptable dataset value runs
  once in both forms. The gain is below 0.2 µs for each update of a chart with 20 arcs.

### Q5.5 Choice: A

The gains of B and C are below 0.2 µs for each update. Neither justifies a change of the
structure. The Dart form keeps the order of the reads and the writes:

```dart
// controller.polarArea.dart, updateElements (controller.polarArea.js:194-212)
final properties = <String, Object?>{
  'x': centerX,
  'y': centerY,
  'innerRadius': 0.0,
  'outerRadius': outerRadius,
  'startAngle': startAngle,
  'endAngle': endAngle,
  'options': resolveDataElementOptions(i, arc.active ? 'active' : mode),
};

// Arc defaults (`spacing=0`, `spacingMode='angular'`) can mask
// polarArea-level values.
final elementOptions = properties['options']! as Map<String, Object?>;
if (elementOptions['spacing'] == 0) {
  elementOptions['spacing'] = jsGet(options, 'spacing');
}
if (elementOptions['spacingMode'] == 'angular') {
  elementOptions['spacingMode'] = jsGet(options, 'spacingMode');
}

updateElement(arc, i, properties, mode);
```

- No `DIVERGES` marker. A user subclass that sets `enableOptionSharing = true` gets the
  `TypeError` of upstream (ADR 0021 §5).
- The doughnut port copies the defaults and descriptors of `controller.doughnut.js:44-83`. Its
  `_scriptable` and `_indexable` closures take `String name`, as
  `core.defaults.dart:462` does.

## Q6. The option functions of `defaults` and `overrides`

### Q6.1 Upstream

- At the pin, the controllers have no tooltip callbacks: `grep tooltip src/controllers` gives no
  line. The specs "should not override tooltip title and label callbacks"
  (`controller.bar.tests.js:1808`, `controller.bubble.tests.js:363`) need `plugin.tooltip` of
  phase 8. They skip as `'blocked: plugin.tooltip'`.
- `controller.doughnut.js:95-122` `generateLabels(chart)` reads `chart.legend.options` (:97)
  before the label test. `controller.polarArea.js:38-62` reads it inside the test (:41).
- `controller.doughnut.js:125-128` and `controller.polarArea.js:65-68` `onClick(e, legendItem,
  legend)` call `legend.chart.toggleDataVisibility(legendItem.index)` and `legend.chart.update()`.
- The legend plugin calls them through `call(fn, args, this)`: `plugin.legend.js:106`
  (`generateLabels`, `[this.chart]`) and :550 (`onClick`, `[e, hoveredItem, this]`). Neither
  function reads `this`.
- `pie` inherits `overrides` through the class chain (`controller.pie.js:4`).

### Q6.2 Options

- **A. Plain Dart functions with typed parameters** (Chart.js ADR 0006: a function value is a
  Dart closure; `js_function.dart`: a function that does not read `this` is a plain `Function`).
  `List<Object?> _generateLabels(types.Chart chart)` and
  `void _onClick(Object? e, Object? legendItem, types.LegendElement legend)`. The
  `types.LegendElement` interface and `types.Chart.legend` of Q1.4.
- **B. `Object?` parameters and by-name reads** (`jsGet(chart, 'legend')`). `jsGet` gives
  `undefined` for a Dart object that is not a Map, a List, a String, a resolver or a class value
  (`js_object.dart:36-62`). Thus `chart.legend` reads `undefined` also after phase 8. Rejected.
- **C. Placeholders until phase 8**: the defaults inventory (`doc/upstream/manifest.json`, hashes
  `e8dc15b7fcd5`, `0ccf40536945`, `50182dc8b78b`) and the theme coverage test
  (`test/port/theme/coverage_test.dart`) then see other values. Rejected.

### Q6.3 Choice: A

Performance does not apply: these functions run once for each legend build or click.

- `jsCall` (`js_function.dart:131`) gives `undefined` to an absent argument. A typed parameter
  then throws a `TypeError`, as the upstream property read of `undefined` does.
- The functions are top-level private tear-offs. A tear-off of a top-level function is canonical.
  Thus each read of the option gives the same function object, and the defaults restore of the
  harness compares equal values.
- The legend items are plain objects: `Map<String, Object?>` with the keys in the upstream
  literal order (`controller.doughnut.js:103-118`, `controller.polarArea.js:47-58`).
- `useBorderRadius && (borderRadius || style.borderRadius)` keeps the operand values:
  `jsTruthy(a) ? (jsTruthy(b) ? b : c) : a`.

```dart
/// controller.doughnut.js:95 `generateLabels(chart)` of
/// `overrides.plugins.legend.labels`.
List<Object?> _generateLabels(types.Chart chart) {
  final data = chart.data;
  final labelsOptions = jsGet(chart.legend!.options, 'labels');
  // ... the destructuring of :97, then the map of :99-119 ...
}

/// controller.doughnut.js:125 `onClick(e, legendItem, legend)`.
void _onClick(Object? e, Object? legendItem, types.LegendElement legend) {
  legend.chart
    ..toggleDataVisibility(jsToNumber(jsGet(legendItem, 'index')))
    ..update();
}
```

`chart.legend!` throws a `TypeError` for Dart `null`, as `undefined.options` does. Phase 7 tests
the functions with a test class that implements `types.LegendElement`. Phase 8 makes `Legend`
implement it and writes `chart.legend` (`plugin.legend.js:602`).

## Q7. The registration

### Q7.1 Upstream

- `src/controllers/index.js:1-8` exports the eight classes in this source order: Bar, Bubble,
  Doughnut, Line, PolarArea, Pie, Radar, Scatter.
- `src/index.ts:1` re-exports them, :8 imports the namespace, :20-25 lists it first in
  `registerables`. The bundle namespace has the keys in code unit order (Chart.js ADR 0020,
  probe 2): `PieController` comes before `PolarAreaController`.
- The registry registers the items of a namespace in key order (`core.registry.js`
  `_each`). The doughnut defaults then come before the pie defaults. `_registerDefaults` of the pie
  class merges the inherited doughnut values (`core.typedRegistry.js:25-50`).

### Q7.2 Options and choice

- **A. A Map literal in code unit order** (Chart.js ADR 0020 §6, the form of `elements` and
  `scales` in `lib/src/index.dart`). Chosen.
- **B. The source order of `index.js`**: pie after polar area. Same result for the defaults,
  because pie inherits from doughnut, not from polar area. Rejected: it gives another key order
  of `defaults.datasets` and `overrides`, which `Object.keys` and the theme snapshot read.

Performance does not apply: registration runs once.

```dart
// lib/src/controllers/index.dart
// Ported from Chart.js v4.5.1+7169e651 src/controllers/index.js (MIT, Chart.js Contributors).

/// index.js:1-8: the eight controller classes.
library;

export 'package:flutter_chartjs/src/controllers/controller.bar.dart' show BarController;
export 'package:flutter_chartjs/src/controllers/controller.bubble.dart' show BubbleController;
export 'package:flutter_chartjs/src/controllers/controller.doughnut.dart' show DoughnutController;
export 'package:flutter_chartjs/src/controllers/controller.line.dart' show LineController;
export 'package:flutter_chartjs/src/controllers/controller.polarArea.dart' show PolarAreaController;
export 'package:flutter_chartjs/src/controllers/controller.pie.dart' show PieController;
export 'package:flutter_chartjs/src/controllers/controller.radar.dart' show RadarController;
export 'package:flutter_chartjs/src/controllers/controller.scatter.dart' show ScatterController;
```

```dart
// lib/src/index.dart
export 'package:flutter_chartjs/src/controllers/index.dart'; // index.ts:1

final AnyObject controllers = Map<String, Object?>.unmodifiable(<String, Object?>{
  'BarController': BarController.jsClass,
  'BubbleController': BubbleController.jsClass,
  'DoughnutController': DoughnutController.jsClass,
  'LineController': LineController.jsClass,
  'PieController': PieController.jsClass,
  'PolarAreaController': PolarAreaController.jsClass,
  'RadarController': RadarController.jsClass,
  'ScatterController': ScatterController.jsClass,
});
```

- `registerables` does not change.
- `test/flutter_test_config.dart:99-102` registers `controllers` with the other built-ins. Thus
  each chart test of `flutter test` gets the eight controllers. The test controllers of the
  repository use other ids (`scaleTest`, `typedLine`, `test`, and others). A second class with the
  id of a built-in controller is ignored (`core.typedRegistry.js:41`).
- The spec `controller.doughnut.tests.js:4-7` reads `Chart.controllers.doughnut`:
  `registry.controllers.items['doughnut']`.

## 8. Frame figures for phase 7 step 7

The micro benchmarks decide the forms above. Step 7 records these A/B frame figures in
`performance.md` (protocol of the kickstart prompt, frameless benchmark and stress entry):

1. Q3: the stress mode `chart` with `LineController` and 20000 points, `CALL=update` and
   `CALL=draw`, typed list against the cast view, on the Pixel 8a and in Chrome with dart2wasm.
2. Q4: the stress mode `axes` with `BarController` and 20000 bars, `CALL=update`, with and
   without the empty test.

## 9. Files that the implementation changes

| File | Change |
|---|---|
| `lib/src/types/index.dart` | `types.Scale` +9 members; new `RadialLinearScale` (5 members); `Chart` +5 members (`legend`, `update`, `getVisibleDatasetCount`, `isDatasetVisible`, `toggleDataVisibility`); new `LegendElement` (`chart`, `options`); `ChartMeta` + `data` setter, `dataset_`, `total`; `DatasetController` + `options`, `getParsed`, `getStyle`, `resolveDataElementOptions`; `Element` + `active`, `hidden`; `LineElement` + `updateControlPoints`; `PointElement` + `size` |
| `lib/src/core/core.controller.dart` | `getDataVisibility` empty test; `@override` on the new `Chart` members; field `types.LegendElement? legend`; `ChartMeta.data` not final; `ChartMeta.total` field and its by-name cases |
| `lib/src/core/core.datasetController.dart` | `getLabelAndValue` record `({Object? label, String value})`; `@override` on `options`, `getParsed`, `getStyle`, `resolveDataElementOptions`; `updateElement(types.Element …)`; the typed list in `initialize` and `_isPointClass`; `_insertElements` without the hole; `_hole` removed; import of `elements/element.point.dart` |
| `lib/src/core/core.scale.dart` | `@override` on the nine members |
| `lib/src/scales/scale.radialLinear.dart` | `implements types.RadialLinearScale`; `@override` on the five members |
| `lib/src/core/core.element.dart` | `@override` on `active` and `hidden` |
| `lib/src/elements/element.line.dart`, `element.point.dart` | `@override` on `updateControlPoints` and `size` |
| `lib/src/controllers/` (new) | the eight controllers and `index.dart` |
| `lib/src/index.dart` | the export of `controllers/index.dart`; the eight entries of `controllers` |
| `apps/chartjs_gallery/lib/demo/demo_chart.dart` | the new `types.Chart` members (`legend => null`, `isDatasetVisible => true`, and the others) |
| `doc/differences.md` | row `adapt-line-points-elements`: add the line controllers to the Dart column and the typed `meta.data` to the text |
| `doc/performance.md` | a new section with the figures of B1, B2 and B3, and later the frame figures of section 8 |
| `doc/adr/0028-…` | the ADR (proposed) |
| `doc/status.yaml` | the rows of the controllers and of `types/index.d.ts` |

## 10. Tests that pin the decisions

| Decision | Test |
|---|---|
| Q1 interface members | `test/port/core/core.controller_test.dart`, group `types.Chart members`: each new member through a `types.Chart` variable on a real chart. `test/port/scales/scale.radialLinear_test.dart`: `chart.scales['r'] is types.RadialLinearScale`. Compile-time: the controllers import no `core.controller.dart`, `core.scale.dart` or `core.element.dart` (a `check:lib-imports` rule or a port test that reads the import lines) |
| Q1 `ChartMeta.total` | `test/port/controllers/controller.doughnut_test.dart`: `meta.total` and `meta['total']` give the same value after `update`; `undefined` before the first update of a meta without a doughnut controller |
| Q2 label | Reference tests of each controller (`test/port/controllers/*_reference.dart`, generated in the x64 Node.js): the labels of P4, also the array label, `null` and `undefined` of radar |
| Q3 typed list | `test/port/controllers/controller.line_test.dart`: `identical(meta.dataset.points, meta.data)` after the first update and after a push and an update; `meta.data is List<types.PointElement>` for line, scatter, radar and bubble; `meta.data is! List<types.PointElement>` for bar and doughnut; an `unshift` and a `splice` of the data keep the element order (the specs of `core.datasetController.tests.js` for the array events also cover it); a line dataset with `dataElementType: 'bar'` throws the `ArgumentError` of `adapt-line-points-elements` |
| Q4 empty test | `test/port/core/core.controller_test.dart`, group `getDataVisibility`: an empty Map gives `true` for 0, 1.5, NaN, -0 and 1e21; one toggle gives `false`; two toggles give `true` (Map not empty); `_updateHiddenIndices` moves keep the results of `core.controller.tests.js:2100-2131` |
| Q5 hunk | Specs `controller.polarArea.tests.js:69`, :85, `controller.doughnut.tests.js:49`. Port tests in `controller.polarArea_test.dart`: `elements.arc.spacingMode: 'angular'` gives `'proportional'` (the one A/B difference of P1); a subclass with `enableOptionSharing = true` throws a `TypeError` in `update` for the config of spec :69; the element options are not frozen after `update` |
| Q6 option functions | `controller.doughnut_test.dart` and `controller.polarArea_test.dart` (port): `generateLabels` with a test `types.LegendElement` gives the items of a Node.js reference (the reference generator sets `chart.legend = {options: …}` on an upstream chart); a `null` legend throws a `TypeError` for doughnut and gives `[]` for a polar area chart without labels; `onClick` toggles the index and updates the chart |
| Q7 registration | `test/port/index_test.dart`: the keys of `controllers` in code unit order; `add(registerables)` registers doughnut before pie; `registry.controllers.items['doughnut']` is `DoughnutController.jsClass` (spec `controller.doughnut.tests.js:4-7`). The theme coverage test (theming.md §8 test 4) gets the controller defaults |
| Performance records | `performance.md`: B1, B2, B3 and the frame figures of section 8 |
