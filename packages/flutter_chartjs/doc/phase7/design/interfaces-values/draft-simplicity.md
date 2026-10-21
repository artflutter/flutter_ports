# Draft (simplicity first): controller interfaces and values

This file is one of three independent drafts of the design panel "Controller interfaces and
values" of phase 7, step 2. The judge and the synthesis of the panel write Chart.js ADR 0028
from the drafts. The lens of this draft is "simplicity first": for each question, this draft
looks for the form with the least code of our own and the fewest new concepts that still keeps
the behavior that Chart.js ADR 0009 protects. The decision protocol of the phase still applies:
1. the protected behavior, 2. performance, 3. the upstream structure, 4. less code. Thus the
draft chooses a faster form when a measurement shows a gain, and the simplest form when the
options are equal.

All upstream lines are at the pin `v4.5.1+7169e651` (`third_party/Chart.js`). The draft checked
each cited line in that checkout. Line numbers of `index.d.ts` at the pin differ from the
numbers in Chart.js ADR 0025, which cites v4.5.1 (`9c5cf9fa`). For example,
`RadialLinearScale` is at `index.d.ts:3676` at the pin.

Evidence folder (below: `<ev>`):
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/interfaces-values-simplicity/`

- Probes run on the x64 Node.js v24.12.0 under Rosetta against the Chart.js build at the pin,
  through `loadChartJs` of `tool/reference/scale_chart_common.mjs` (it stops unless the build is
  at the pin and Node.js is x64).
- Benchmarks import the real `lib/src` files through `<ev>/bench/shadow/flutter_chartjs`, a
  package with the name `flutter_chartjs` whose `lib` is a symbolic link to the real
  `packages/flutter_chartjs/lib`. It has no Flutter dependency. Only pure layers compile.
- Bed: Apple M3 Max, macOS 26.5.1, Dart 3.12.2. AOT is `dart compile exe`. wasm is
  `dart compile wasm -O2`, run in Node.js v24.12.0 arm64 (`<ev>/bench/run_wasm.mjs`), for
  times only. Each figure is the range of the medians of 3 processes. Each process runs 5
  warm-up batches, then 21 or 31 batches in an alternate order.

## Summary of the choices

| Question | Choice |
|---|---|
| 1. Interface members | Add each member that a controller reads first to its `lib/src/types` interface (Chart.js ADR 0003). A controller casts only to a `types` interface, never to a concrete class of another module. One exception: the doughnut casts another controller to `DoughnutController` for its own private members. `DatasetController.updateElement` takes a `types.Element`. |
| 2. `getLabelAndValue` | `({Object? label, String value})`. The label is the raw value. |
| 3. `meta.data` and `line.points` | The `LineElement.points` setter takes `List<types.Element>`. It keeps a `List<types.PointElement>` as it is, and makes a typed copy of another list. No cast view. `getStartAndCountOfVisiblePoints` takes `List<types.Element>`. |
| 4. `getDataVisibility` | Through the interface. The body gets a port-only fast path: `if (_hiddenIndices.isEmpty) return true;`. |
| 5. The #12238 hunk | Port it literally. It writes into options that are not frozen, because `PolarAreaController` has no option sharing. A frozen object throws a `TypeError` in both runtimes. |
| 6. Option functions of phase 8 | Dart closures with `Object?` parameters, as `core.scale.defaults.dart:50-52`. A cast to a `types` interface at the entry. A minimal `types.LegendElement` and `types.Chart.legend` now. No tooltip callbacks exist at the pin. |
| 7. Registration | `lib/src/controllers/index.dart` with 8 `export ... show` lines. The `controllers` Map of `lib/src/index.dart` gets the 8 class values in code unit order. `registerables` does not change. |

## 1. The interface members that a controller reads first

### Options

| Option | 1. Behavior | 2. Performance | 3. Structure | 4. Own code |
|---|---|---|---|---|
| U: upstream form. JS reads each member on the object, with no type. | — | — | — | — |
| A: an interface member in `lib/src/types` for each member that a ported controller reads first (Chart.js ADR 0003; Chart.js ADR 0025 §5 for the scale members) | Same | An interface call. For `getDataVisibility`: 0.1-0.5 ns slower than a direct call on AOT, 1.5-2.9 ns slower on wasm (question 4) | Keeps the imports of upstream: a controller imports no concrete chart, scale or element module | One declaration for each member, plus `@override` on the concrete member. Each implementer without `noSuchMethod` gets the member |
| C: a cast to the concrete class at each reader (`chart as Chart`, `meta as ChartMeta`, `element as Element`) | Same for the concrete classes. A `types.Chart` that is not the concrete `Chart` (the test fakes, `DemoChart`) throws a `TypeError` at the cast | Same as A, or faster by the figures above | Imports that upstream does not have: `core.controller.dart`, `core.element.dart`, `core.scale.dart`, `elements/*.dart` in each controller | A cast at each reader of a member of another module (more than 30 sites over 8 files) |
| M: a mix: A for the members of other modules, a cast to the controller's own class for its private members | Same | As A | As A | Least: no interface for a member that only one class has |

Choice: **M**. It is A with one exception. Doughnut reads `controller._getRotation()` and
`controller._getCircumference()` of the controllers of the other doughnut datasets
(`controller.doughnut.js:193-195`). Only `DoughnutController` and its subclass `PieController`
have these members, and they are private to `controller.doughnut.dart`. The cast
`controller as DoughnutController` adds no import and no interface.

Rule for the casts:

- A cast to a `types` interface is allowed. It adds no import, and it stands for the duck typing
  of JS: `meta.rScale! as types.RadialLinearScale`, `meta.dataset! as types.LineElement`,
  `meta.data[i] as types.PointElement`.
- A cast to a concrete class of another module is not allowed in a controller.
- `DatasetController.updateElement` takes `types.Element` (`index.d.ts:676`: `element: TElement |
  TDatasetElement`). It casts once to `Element` in its body. `core.datasetController.dart`
  imports `core.element.dart` already (line 43). Without this change, each of the 10
  `updateElement` calls of the controllers needs a cast and an import of `core.element.dart`.

### The members and their first readers

Each line was checked at the pin. "First reader" is the first line in the wave order of the
kickstart (bar, line, bubble, doughnut, polarArea, radar, scatter, pie).

`types.Scale` (Chart.js ADR 0025 §5 fixes the forms; the concrete `Scale` has each member):

| Dart member | Upstream | First reader |
|---|---|---|
| `Map<String, Object?> get cache` | `core.scale.js:247` `_cache` | `controller.bar.js:8`, `:15`, `:17` |
| `List<Tick>? get ticks` | `index.d.ts` `Scale.ticks`, `core.scale.js:226` | `controller.bar.js:47` |
| `double? getPixelForTick(int index)` | `index.d.ts` `Scale.getPixelForTick` | `controller.bar.js:48` |
| `double getBasePixel()` | `index.d.ts` `Scale.getBasePixel` | `controller.bar.js:396`; `controller.line.js:101` |
| `double get startPixel`, `double get endPixel` | `core.scale.js:237`, `:239` | `controller.bar.js:549-550` |
| `double getPixelForDecimal(double decimal)` | `index.d.ts` `Scale.getPixelForDecimal` | `controller.bar.js:606-607`; `controller.bubble.js:129` |
| `double? getValueForPixel(double pixel)` | `index.d.ts` `Scale.getValueForPixel` | `controller.bar.js:615` |
| `double getLineWidthForValue(Object? value)` | `index.d.ts` `Scale.getLineWidthForValue` | `controller.bar.js:620` |

These are the 9 members of Chart.js ADR 0025 §5 without `getBaseValue`. Its first reader is
`filler.options.js:112` (phase 8). Thus it waits for phase 8.

`types.RadialLinearScale implements Scale` (`index.d.ts:3676-3688`; `RadialLinearScale` of
`scale.radialLinear.dart` implements it):

| Dart member | First reader |
|---|---|
| `double get xCenter` | `controller.polarArea.js:167`; `controller.radar.js:90` |
| `double get yCenter` | `controller.polarArea.js:168`; `controller.radar.js:91` |
| `double getIndexAngle(double index)` | `controller.polarArea.js:169` |
| `double getDistanceFromCenterForValue(Object? value)` | `controller.polarArea.js:182` |
| `({double x, double y, double angle}) getPointPositionForValue(double index, Object? value)` | `controller.radar.js:88` |

`types.Chart` (`index.d.ts:524-575`):

| Dart member | Upstream | First reader |
|---|---|---|
| `bool isDatasetVisible(double datasetIndex)` | `index.d.ts:569`, `core.controller.js:863` | `controller.doughnut.js:192` |
| `double getVisibleDatasetCount()` | `index.d.ts:568`, `core.controller.js:859` | `controller.polarArea.js:155` |
| `void toggleDataVisibility(double index)` | `index.d.ts:571`, `core.controller.js:881` | `controller.doughnut.js:126` (legend `onClick`) |
| `void update([Object? mode])` | `index.d.ts:559`, `core.controller.js:475` | `controller.doughnut.js:127` (legend `onClick`) |
| `LegendElement? get legend` | `index.d.ts:543` | `controller.doughnut.js:97`; `controller.polarArea.js:41` (question 6) |

`getDataVisibility` is in the interface already (Chart.js ADR 0025 §4). The concrete members
exist: `core.controller.dart:1713`, `:1718`, `:1744`, `:1232`. They get `@override`.

`types.ChartMeta` (`index.d.ts:471-506`, `ChartMetaCommon`; `DoughnutMetaExtensions` at
`:373-375`):

| Dart member | Upstream | First reader |
|---|---|---|
| `Object? get dataset_` | `core.controller.js:845` `_dataset`; Chart.js ADR 0023 gives the name | `controller.line.js:43`, `:59`, `:78`, `:107` |
| `abstract double? total` | `index.d.ts:374` `total: number` in `DoughnutMetaExtensions`. The `DeepPartial` of `ChartMeta` makes it optional | `controller.doughnut.js:235` (write), `:313` (read) |

- `dataset_`: the concrete `ChartMeta` has `final Object? dataset_` (`core.controller.dart:334`).
- `total`: the concrete `ChartMeta` gets a field `double? total`. Dart `null` stands for the
  `undefined` start value: `total > 0` with `undefined` is false, and `total != null && total > 0`
  gives the same result. The by-name read and write (`operator []` and `operator []=`,
  `core.controller.dart:439`, `:487`) get the key `'total'`, so that `meta['total']` and the
  field agree. A typed field is faster than the extras Map for the read of each arc
  (`calculateCircumference`, `controller.doughnut.js:313`), and it needs 4 lines.

`types.DatasetController` (`index.d.ts:622-690`). The reader reaches another controller through
`meta.controller`:

| Dart member | Upstream | First reader |
|---|---|---|
| `Map<String, Object?> get options` | `core.datasetController.js:262`, `:442` (no `index.d.ts` line) | `controller.bar.js:437` |
| `Object? getParsed(double index)` | `index.d.ts:688`, `core.datasetController.js:579` | `controller.bar.js:440` |
| `Map<String, Object?> getStyle(double? index, [bool? active])` | `index.d.ts:656`, `core.datasetController.js:752` | `controller.doughnut.js:101`; `controller.polarArea.js:45` |
| `Map<String, Object?> resolveDataElementOptions(double index, [String? mode])` | `index.d.ts:658`, `core.datasetController.js:797` | `controller.doughnut.js:354` |

The concrete members exist (`core.datasetController.dart:717`, `:1199`, `:1428`, `:1501`). They
get `@override`. `getLabelAndValue` does not go to the interface in phase 7: its first reader
through the interface is `plugin.tooltip.js:130` (phase 8).

`types.Element` (`core.element.ts:6`, `index.d.ts` imports the class):

| Dart member | Upstream | First reader |
|---|---|---|
| `bool get active` | `core.element.ts:13` | `controller.bar.js:418` |
| `Object? get hidden` | `core.controller.js:898` writes it; `core.datasetController.js:730` reads it | `controller.bar.js:676` |

`types.PointElement`:

| Dart member | Upstream | First reader |
|---|---|---|
| `double size([Map<String, Object?>? options])` | `element.point.ts:81` | `controller.line.js:133`; `controller.bubble.js:88` |

`types.LineElement` (`index.d.ts:2022-2033`):

| Dart member | Upstream | First reader |
|---|---|---|
| `set points(List<Element> points)` | `index.d.ts:2026`, `element.line.js:308` | `controller.line.js:60` (question 3) |
| `set chart(Chart value)` | `element.line.js:284` `_chart` | `controller.line.js:57` |
| `set datasetIndex(double value)` | `element.line.js:292` `_datasetIndex` | `controller.line.js:58` |
| `set decimated(bool value)` | `element.line.js:290` `_decimated` | `controller.line.js:59` |
| `void updateControlPoints(ChartArea chartArea, [String? indexAxis])` | `index.d.ts:2025`, `element.line.js:299` | `controller.line.js:140` |

The concrete setters exist (`element.line.dart`: `set chart`, `set datasetIndex`, `bool
decimated`, `updateControlPoints`). The type library drops the underscore without `@internal`
(Chart.js ADR 0025 §6).

`chart.registry.getElement('line')` (`controller.scatter.js:105`) stays the singleton `registry`
of `core.registry.dart` (row `adapt-chart-registry-getter`). It needs no interface member.

### Evidence

- The member scans: `grep -n` over `src/controllers/*.js` at the pin for each member name (the
  lines in the tables). The scout files `doc/phase7/members-cartesian.md` §2 and
  `doc/phase7/members-radial.md` §2.5 list the same set.
- The implementers that the new members break: a scan of `packages/*/test`, `packages/*/tool`,
  `packages/*/lib` and `apps/*/lib` for `implements` of `Chart`, `ChartMeta`,
  `DatasetController`, `Element`, `PointElement`, `LineElement` and `Scale` without
  `noSuchMethod`. Three classes outside `lib/` break:
  - `apps/chartjs_gallery/lib/demo/demo_chart.dart` `DemoChart` (`types.Chart`): it gets
    `isDatasetVisible`, `getVisibleDatasetCount`, `toggleDataVisibility`, `update` and `legend`.
  - `test/specs/helpers.segment_test.dart` and `test/port/helpers/helpers.collection_test.dart`:
    a fake `PointElement` gets `active`, `hidden` and `size`, or a `noSuchMethod`.

## 2. The label of `getLabelAndValue`

### Upstream

- Base: `core.datasetController.js:687-697` returns `'' + iScale.getLabelForValue(...)`: a
  string. Bar: `controller.bar.js:364-376`, a string.
- Scatter `controller.scatter.js:42-54`, bubble `controller.bubble.js:96-109`, doughnut
  `controller.doughnut.js:320-330` and polarArea `controller.polarArea.js:97-107` return
  `labels[index] || ''`: the raw label, or `''` for a falsy label.
- Radar `controller.radar.js:39-47` returns `vScale.getLabels()[index]`: the raw label, also
  `undefined` past the end of the labels.
- The value is a string in each override: `'' + ...`, `formatNumber(...)` or `'(' + ... + ')'`.
- `index.d.ts:641` declares `{ label: string; value: string }`. The runtime does not follow it.
- The reader is `plugin.tooltip.js:130` (`createTooltipItem`). The default `title` callback
  (`:364-378`) returns `item.label` when it is truthy. `splitNewlines` and `pushOrConcat`
  (`:542`) push each line of an array.

### Probe

`<ev>/probe_label.mjs`, output `<ev>/probe_label.out`. Labels `[['Line 1', 'Line 2'], 7, '',
'plain']`, one dataset, `tooltip.setActiveElements` at each element. The second run forces the
label to `'' + label`, the result of a Dart `String label` with `jsToString`:

| Chart type | Label | Raw: label, title | As a string: label, title |
|---|---|---|---|
| pie, doughnut, polarArea, scatter, bubble, radar | `['Line 1', 'Line 2']` | the array; `['Line 1', 'Line 2']` (2 lines) | `'Line 1,Line 2'`; `['Line 1,Line 2']` (1 line) |
| same | `7` | `7`; `[7]` | `'7'`; `['7']` |
| radar | past the end (index 4 of 4 labels) | `undefined`; `[]` (no title) | `'undefined'`; `['undefined']` |
| bar, line | `['Line 1', 'Line 2']` | `'Line 1,Line 2'`; 1 line | the same |

A `String` label changes the count of the title lines and adds a title `'undefined'`. The
tooltip items of phase 8 also give `item.label` to the user callbacks, and an array changes its
type there.

### Options

| Option | 1. Behavior | 2. Perf | 3. Structure | 4. Own code |
|---|---|---|---|---|
| U: upstream: any label | — | — | — | — |
| S: the current record `({String label, String value})` with `jsToString` in each override | Fails: the rows above (title lines, `'undefined'`) | Same | A `jsToString` hunk in 5 overrides and a `DIVERGES` row | 5 hunks and a row |
| O: `({Object? label, String value})` | Same as upstream | Same: one record for each tooltip item | Each override translates its lines | One type change |
| R: a class `LabelAndValue` | Same as O | Same | Against the record rule of Chart.js ADR 0003 (ported code only reads it) | More |

Choice: **O**.

### Code form

```dart
// core.datasetController.js:687
({Object? label, String value}) getLabelAndValue(double index) { ... } // body unchanged

// controller.doughnut.js:320-330 (polarArea, scatter and bubble: the same label line)
@override
({Object? label, String value}) getLabelAndValue(double index) {
  final meta = cachedMeta;
  final labels = jsGet(chart.data, 'labels');
  final list = jsTruthy(labels) ? labels : const <Object?>[];
  final value = formatNumber(
    jsToNumber(jsGet(meta.parsed, jsNumberToString(index))),
    jsGet(chart.options, 'locale'),
  );
  final label = jsGet(list, jsNumberToString(index));
  return (label: jsTruthy(label) ? label : '', value: value);
}

// controller.radar.js:39-47: no `|| ''`; past the end gives `undefined`.
label: jsGet(vScale.getLabels(), jsNumberToString(index)),
```

The list read gives `undefined` past the end, as JS does (`jsGet`, or the shared list read that
the parsed-read panel chooses). A Dart `list[index]` throws a `RangeError` there.

Effects:
- `core.datasetController.dart:1339`: the record type changes. The base body does not change.
- `test/port/core/core.datasetController_test.dart:863-870` destructures the record and encodes
  `label` as `Object?`. It does not change.
- Phase 8: the tooltip item has `Object? label`. The default `title` callback and
  `pushOrConcat` handle a `List` and a number, as upstream does.

## 3. `meta.data` and `line.points`

### Upstream

`controller.line.js:43` takes `data: points` of the meta, and `:60` writes `line.points =
points`. `controller.scatter.js:58`, `:83` and `controller.radar.js:56`, `:60` do the same. Thus
`meta.data` and `line._points` are one array. In Dart, `ChartMeta.data` is a
`List<types.Element>` (`core.controller.dart:298`), and the setter takes
`List<types.PointElement>` (`element.line.dart`, row `adapt-line-points-elements`). A
`List<types.Element>` is not a `List<types.PointElement>` at run time.

Readers of the shared identity: none. `grep` over `src/` at the pin finds the readers of
`.points` in `element.line.js`, `helpers.segment.js` and `plugins/plugin.filler/*`. Each reads
the elements or the length. No reader compares `line.points` with `meta.data`. No spec of
`test/specs/` reads `line.points` except `element.line.tests.js:11`, which writes plain
numbers (already the row `adapt-line-points-elements`). The elements are the same objects in
each form below. Thus `updateElements(points, ...)` writes `x`, `y` and `skip` into the objects
that the line draws.

The live sharing: upstream `_insertElements` and `_removeElements` change `meta.data` in place.
They run in `buildOrUpdateElements` during `chart.update()`, before `_updateDatasets` calls the
controller `update`, which writes `line.points` again (`core.controller.js` `update`). Between
the two, no code reads `line.points`. Thus a copy at the write gives the same elements to each
reader.

### Options

| Option | 1. Behavior | 2. Performance (20000 points, real `LineElement`) | 3. Structure | 4. Own code |
|---|---|---|---|---|
| U: one shared array | — | — | — | — |
| V: a cast view `meta.data.cast<types.PointElement>()` at the 3 writers (the gallery form, `stress_point_controller.dart:139`) | Same; live sharing | A type test at each read in each draw. Draw frame: AOT +22-34 µs (tension 0), +84-87 µs (tension 0.4); wasm +116-129 µs, +392-448 µs | Keeps the controller lines | One `.cast` at 3 writers |
| K: a typed copy in the `LineElement.points` setter, which takes `List<types.Element>`; a `List<types.PointElement>` stays as it is | Same elements; a new list only for a list that is not typed | One copy at each update: 36-41 µs (AOT), 57-67 µs (wasm). The draw is at the speed of a direct list | `line.points = points` stays verbatim in the 3 controllers | The setter body: 3 lines. No change in the controllers |
| K2: the same copy at the 3 writers in the controllers | As K | As K | A port-only expression at 3 writers | 3 expressions and a helper |
| W: widen `LineElement.points` to `List<types.Element>` | Same; live sharing | A cast at each read in `helpers.segment`, `helpers.curve` and the draw: the cost of V | Changes phase 4 code | Many sites |
| T: `ChartMeta.data` gets the run-time type of the element class (for example `<types.PointElement>[]` for a point controller), and the writers cast the list (`as List<types.PointElement>`, O(1)) | Same; live sharing. A `TypeError` when an element of another class enters the list (a user changes `dataElementType`) | 0 per update, 0 per draw | Changes `getDatasetMeta` (`core.controller.js:829-848`) and `_insertElements`: a shared layer | A list factory on the element class value, and a settable `ChartMeta.data` |

### Measurements

`<ev>/bench/bin/line_view.dart`, outputs `<ev>/bench/line_view_aot.out` and
`line_view_wasm.out`. Each frame does what `controller.line.js:57-60` and `:140` do to the line:
`line.points = ...`, `updateControlPoints(area, 'x')`, `draw(ctx, area)`, on the real
`LineElement` and `PointElement`. The context records the path commands (3.5 million for each
run). The column "copy" makes a new typed copy in each frame: the worst case, one update for
each draw. µs for each frame:

| Platform | Tension | direct | view (V) | copy (K) |
|---|---|---|---|---|
| AOT | 0 | 376.5-383.2 | 405.8-410.0 | 424.8-434.2 |
| AOT | 0.4 | 1567.7-1658.4 | 1652.4-1742.7 | 1626.8-1665.7 |
| wasm | 0 | 668.6-679.8 | 791.9-804.6 | 779.2-791.3 |
| wasm | 0.4 | 2534.8-2601.4 | 2983.0-2993.6 | 2649.9-2673.2 |

`<ev>/bench/bin/points_copy.dart`, outputs `<ev>/bench/points_copy_aot.out` and
`points_copy_wasm.out`: the cost of one conversion of 20000 elements, µs:

| Form | AOT | wasm |
|---|---|---|
| `cast` view object only | 0.0 | 0.1 |
| `[for (final e in data) e as types.PointElement]` | 222.8-234.8 | 110.5-123.6 |
| `List<types.PointElement>.of(data.cast())` | 160.4-165.8 | 375.9-433.9 |
| `List<types.PointElement>.from(data)` | 263.1-269.4 | 81.2-91.2 |
| `List<types.PointElement>.generate(n, (i) => data[i] as types.PointElement)` | 36.3-40.5 | 56.5-66.8 |
| `as List<types.PointElement>` of a typed list (T) | 0.0 | 0.0-0.1 |

Reading of the figures:
- A view costs at each draw. An animation draws about 60 frames for each update, and a hover
  draws without an update. A copy costs once for each update.
- Even in the worst case (one update for each draw), K is at or below V on wasm, and at or
  below V on AOT with tension. Only AOT with tension 0 and one update for each draw gives K
  15-28 µs above V (4-7 %).
- `generate` is the fastest copy on both platforms by a factor of 2 to 6.

### Choice: **K**

- K and V keep the protected behavior and the upstream lines of the controllers. K is faster
  for each frame of an animation and for each hover draw. The microbenchmarks are sufficient
  evidence, because K keeps the upstream structure (Chart.js ADR 0020 §13).
- K puts the conversion in one place: the setter of the row `adapt-line-points-elements`. The
  controllers keep `line.points = points` verbatim. Thus K has less code than K2 and V.
- T is the fastest form, but it changes `getDatasetMeta` and `_insertElements`, a shared layer.
  Such a form needs frame figures. It goes to Open.

### Code form

```dart
// element.line.js:308 `set points(points)`.
// DIVERGES(chartjs): adapt-line-points-elements, point elements only.
@override
set points(List<types.Element> points) => _setPoints(
  points is List<types.PointElement>
      ? points
      : List<types.PointElement>.generate(
          points.length,
          (i) => points[i] as types.PointElement,
        ),
);

// helpers.extras.ts:88 `_getStartAndCountOfVisiblePoints(meta, points, ...)`.
// The body reads `points.length` and `lookupByKey(points, ...)` only.
({double start, double count}) getStartAndCountOfVisiblePoints(
  ChartMeta meta,
  List<Element> points,
  bool animationsDisabled,
)

// controller.line.js:43-60: unchanged lines.
final meta = cachedMeta;
final line = meta.dataset! as types.LineElement;
final points = meta.data;
...
line.points = points;
```

- A `List<types.PointElement>` keeps its identity. Thus `line.points = line.points` of the
  element tests and the typed lists of the tests do not change.
- A `List<types.Element>` with an element that is not a `types.PointElement` throws a
  `TypeError` at the copy. The current setter throws at the type of the argument. Upstream
  accepts it (row `adapt-line-points-elements`). The row text gets one sentence: "The setter
  copies a list that is not a `List<types.PointElement>`. Thus `line.points` and `meta.data`
  are two lists with the same elements."
- The by-name write `line['points'] = value` takes the same path.
- The gallery call `getStartAndCountOfVisiblePoints(meta, points.cast<PointElement>(), ...)`
  (`stress_point_controller.dart:139`) loses its `.cast` when phase 7 replaces the class.

## 4. `getDataVisibility`: interface or cast, and the string key

### Upstream

`core.controller.js:885-887`: `return !this._hiddenIndices[index];`. The port
(`core.controller.dart:1751-1753`) builds the key `jsNumberToString(index)` for each call. The
controllers call it for each element: `controller.bar.js:592`; `controller.doughnut.js:250`,
`:304`; `controller.polarArea.js:130`, `:182`, `:221`, `:233` (four calls for each arc in one
polar area update).

### Options

| Option | 1. Behavior | 2. Performance | 3. Structure | 4. Own code |
|---|---|---|---|---|
| I: interface call (Chart.js ADR 0025 §4), body as now | Same | Reference | Keeps it | None |
| C: cast to the concrete `Chart`, direct call | Same for the concrete chart. A `TypeError` for another `types.Chart` | 0.1-0.5 ns faster on AOT, 2.2-2.9 ns on wasm | An import of `core.controller.dart` in 4 controllers | A cast at 8 sites |
| IF: I, and the body starts with `if (_hiddenIndices.isEmpty) return true;` | Same: an empty object gives `undefined` for each key, and `!undefined` is true | 15.5-17.3 ns faster for each call with no hidden index; 0-1 ns slower with a hidden index | A port-only early branch with the upstream result, as the fast paths of Chart.js ADR 0025 §3 | 1 line |
| CF: C and IF | As C | 1.5 ns faster than IF on wasm, equal on AOT | As C | As C, plus 1 line |
| IK: I, and a cache of the keys of the small integers | Same | 0.8-4.4 ns faster | A port-only table | 5 lines and a table |

### Measurements

`<ev>/bench/bin/visibility.dart`, outputs `<ev>/bench/visibility_aot.out` and
`visibility_wasm.out`. The body uses the real `jsNumberToString` and `jsTruthy`. Three classes
implement the interface. ns for each call, 20000 calls for each pass:

| State | Platform | I | C | IF | CF | IK |
|---|---|---|---|---|---|---|
| no hidden index | AOT | 18.41-18.68 | 18.01-18.36 | 2.88-2.94 | 3.00-3.08 | 17.18-17.60 |
| no hidden index | wasm | 19.89-19.95 | 17.00-17.28 | 2.61-2.65 | 1.06-1.07 | 15.60-16.00 |
| one hidden index | AOT | 21.13-22.20 | 21.23-21.76 | 21.26-22.43 | 21.61-22.48 | 20.33-20.93 |
| one hidden index | wasm | 22.52-23.18 | 19.65-20.28 | 22.59-23.22 | 21.05-21.70 | 17.54-18.41 |

For a polar area update of 20000 arcs (80000 calls), IF saves 1.2-1.3 ms on AOT and 1.4 ms on
wasm when no index is hidden. This is the usual state: only `toggleDataVisibility` and
`_updateVisibility` write the object.

### Choice: **IF**

- IF has the largest measured gain of the forms that keep the structure, on both platforms.
- CF is 1.5 ns faster than IF on wasm only (about 0.12 ms for 80000 calls) and equal on AOT. It
  adds an import that upstream does not have and a `TypeError` for the `types.Chart` fakes. A
  form that changes the structure needs frame figures (Chart.js ADR 0020 §13). Thus CF goes to
  Open.
- IK gains less than IF in the usual state and adds a table.

### Code form

```dart
/// core.controller.js:885 `getDataVisibility(index)`.
@override
bool getDataVisibility(double index) {
  // Port-only fast path: an empty `_hiddenIndices` gives `undefined` for each
  // key (Chart.js ADR 0028, section 4).
  if (_hiddenIndices.isEmpty) return true;
  return !jsTruthy(_hiddenIndices[jsNumberToString(index)]);
}
```

A key with the value `false` (after two toggles of one index) keeps the object not empty. Then
the body takes the upstream line. This is correct, and it is also the upstream state of the
object.

## 5. The #12238 hunk of polarArea

### Upstream

`controller.polarArea.js:204-210`:

```js
// Arc defaults (`spacing=0`, `spacingMode='angular'`) can mask polarArea-level values.
if (properties.options.spacing === 0) {
  properties.options.spacing = this.options.spacing;
}
if (properties.options.spacingMode === 'angular') {
  properties.options.spacingMode = this.options.spacingMode;
}
```

- `properties.options` is `this.resolveDataElementOptions(i, ...)` (`:201`).
  `PolarAreaController` never sets `enableOptionSharing` (`:90-95`), and the base default is
  `false`. Thus `_resolveElementOptions` (`core.datasetController.js:804-835`) returns `values`
  (not frozen) at the first call and `cloneIfNotShared(cached, false)` (a new clone) after it.
  The write meets an object that is not frozen.
- The scopes of the arc options of a polar area (`core.config.js:252-259`, `:296-325`): the
  probe lists them. Scope 3 is `defaults.datasets.polarArea` (`spacing: 0`, `spacingMode:
  'proportional'`). Scope 4 is `defaults.elements.arc` (`spacing: 0`, `spacingMode:
  'angular'`). The user scopes come before both.
- Doughnut has no hunk. Its default `spacingMode: 'angular'` (`controller.doughnut.js:74`) is
  in `datasets.doughnut`. Doughnut has option sharing (`:136`) and writes no option.

### Probe

`<ev>/probe_spacing.mjs`, output `<ev>/probe_spacing.out` (the colors plugin off, as
`test/index.js:25-28`) and `<ev>/probe_spacing_colors.out` (on). Three variants of the pinned
`PolarAreaController.prototype`: `upstream`, `nohunk` (the `updateElements` of `:161-214`
without `:204-210`), and `sharing` (`enableOptionSharing = true` before `initialize`). A
subclass with the same id cannot replace the registered class (`core.typedRegistry.js:24-43`:
`register` registers the parent first, then returns when the id exists). Thus the probe patches the prototype. Each row gives
`spacing` and `spacingMode` of both arcs after the first update, after a second `update()`, and
of arc 0 after a hover (`setActiveElements`, then `update()`):

| Case | upstream | nohunk | sharing |
|---|---|---|---|
| spec `controller.polarArea.tests.js:69`: no options | 0, proportional; hover 0, proportional | same | **`TypeError`** (write of `spacing` into a frozen object) |
| spec `:85`: chart `spacing: 12, spacingMode: 'parallel'` | 12, parallel | same | 12, parallel; options frozen |
| dataset `spacing: 5, spacingMode: 'parallel'` | 5, parallel | same | same; frozen |
| chart `elements.arc: {spacing: 0, spacingMode: 'angular'}` | 0, **proportional**; hover 0, **angular** | 0, **angular**; hover 0, angular | `TypeError` |
| chart `spacing: 7`, `elements.arc.spacingMode: 'parallel'` | 7, parallel | same | same; frozen |
| dataset `spacing: 0`, chart `spacing: 7` | 0, proportional | same | `TypeError` |
| dataset `spacingMode: 'angular'`, chart `spacingMode: 'parallel'` | 0, angular | same | `TypeError` |
| `elements.arc.spacing` scriptable | 0 and 3, proportional | same | same; not frozen (`$shared` false) |
| doughnut, no options | 0, angular | — | — |
| doughnut, chart `spacing: 20, spacingMode: 'parallel'` | 20, parallel | — | — |

Findings:
- The two spec cases (`:69`, `:85`) read the same values with and without the hunk.
- No polar area fixture sets `spacing` or `spacingMode`
  (`grep -rn spacing test/fixtures/controller.polarArea` gives no line). The doughnut fixtures
  with `spacing` (`doughnut-spacing*.js`, `selfJoin/*`, `borderJoinStyle/*`) do not reach the
  hunk.
- The hunk changes a resolved option in one case: an explicit `elements.arc.spacingMode:
  'angular'` (or `elements.arc.spacing: 0`) of the user. The hunk replaces it with the dataset
  value. The hover path (`setHoverStyle` and `_setStyle`, `core.datasetController.js:919-940`) does not run
  the hunk. `Chart.update` replays the hover styles at its end (`core.controller.js:533`). Thus the hover options keep `'angular'`. A resolved option is protected (Chart.js
  ADR 0009). The port keeps the hunk.
- With option sharing, the write throws a `TypeError` in 4 of 8 cases, also for a write of the
  same value (`spacing = 0`). The Dart `ElementOptions` in the frozen state throws a
  `TypeError` for each write (`element_options.dart:250-252`, Chart.js ADR 0021 §5). The Dart
  `_resolveElementOptions` freezes and clones as upstream does
  (`core.datasetController.dart:1528`, `:1560`). Thus both runtimes give the same throw.

### Options

| Option | 1. Behavior | 2. Perf | 3. Structure | 4. Own code |
|---|---|---|---|---|
| L: the literal hunk (upstream form) | Same, also the hover and the frozen throw | 2 Map reads for each arc; a resolver read only when the condition holds | Same | 6 lines |
| D: drop the hunk | Fails the `elements.arc.spacingMode: 'angular'` case | 2 reads less | A `DIVERGES` row | Less, plus a row |
| P: give the dataset defaults precedence in the resolver | Changes other options too | — | Changes `core.config` | More |

Choice: **L**.

### Code form

```dart
// controller.polarArea.js:204-210
final options = properties['options']! as Map<String, Object?>;
// Arc defaults (`spacing=0`, `spacingMode='angular'`) can mask
// polarArea-level values.
if (options['spacing'] == 0) {
  options['spacing'] = this.options['spacing'];
}
if (options['spacingMode'] == 'angular') {
  options['spacingMode'] = this.options['spacingMode'];
}
```

- `=== 0`: Dart `==` on `Object?` is true for `0.0`, `-0.0` and an `int` 0, and false for the
  string `'0'` and NaN, as `===` with a number.
- `=== 'angular'`: Dart `==` on a `String`.
- `options` is the typed `ArcOptions` (Chart.js ADR 0021). `operator []=` writes the field of a
  known key. `PolarAreaController` keeps `enableOptionSharing == false`.

## 6. The option functions of phase 8 in the defaults and overrides

### Upstream at the pin

- `DoughnutController.overrides.plugins.legend.labels.generateLabels(chart)`
  (`controller.doughnut.js:95-122`) and `onClick(e, legendItem, legend)` (`:125-128`).
  `PieController` inherits them (`controller.pie.js`, the static chain).
- `PolarAreaController.overrides.plugins.legend.labels.generateLabels(chart)`
  (`controller.polarArea.js:38-62`) and `onClick` (`:65-68`).
- Descriptors: `DoughnutController.descriptors._scriptable` and `_indexable`
  (`controller.doughnut.js:80-83`).
- Tooltip callbacks: none. `grep -n "tooltip\|callbacks" src/controllers/*.js` gives no line at
  the pin. The tooltip reads the controllers through `getLabelAndValue` only (question 2).
- `chart.legend` is an expando that `plugin.legend.js:602` writes and `:609` deletes.
  `index.d.ts:543` declares `readonly legend?: LegendElement`.
- Doughnut reads `chart.legend.options` at `:97`, before its `if`. Thus it throws a `TypeError`
  for each call without a legend. Polar area reads it at `:41`, inside its `if`. Thus it throws
  only when the chart has labels and datasets.

### Options

| Option | 1. Behavior | 2. Perf | 3. Structure | 4. Own code |
|---|---|---|---|---|
| T: typed closures, for example `List<Map<String, Object?>> Function(types.Chart chart)` | Same for the calls of phase 8 | Same | Same | The parameter types fix the call of the phase 8 plugin now |
| O: closures with `Object?` parameters and a cast to a `types` interface at the entry (the precedent `core.scale.defaults.dart:50-52`) | Same: a cast of a value that is not a chart throws a `TypeError`, as the read of `.data` of `undefined` does | Same | Same | Same as T |
| N: the closures wait for phase 8 | The manifest inventory and `overrides` miss two keys in phase 7 | — | A gap in the defaults | Less now, more later |

For `chart.legend`:

| Option | Behavior | Code |
|---|---|---|
| L1: `types.LegendElement? get legend` on `types.Chart`, a minimal interface `types.LegendElement` (`index.d.ts:2414-2420`: `chart`, `options`), and a field `types.LegendElement? legend` on the concrete `Chart` | `chart.legend!` throws a `TypeError` for `null`, as `undefined.options` does | 3 declarations, 1 field, 1 getter in `DemoChart` |
| L2: a by-name read `jsGet(chart, 'legend')` | `Chart` is not a `PropertyAccess`. It needs an extras Map on the chart | More |

Choice: **O** with **L1**. `chart.legend` is a member with its first ported reader
(`controller.doughnut.js:97`), as Chart.js ADR 0003 says. Phase 8 writes the field.

### Code form

```dart
// controller.doughnut.js:95-122
'generateLabels': (Object? chart) {
  final c = chart as types.Chart;
  final data = c.data;
  final labelsOptions = jsGet(c.legend!.options, 'labels');
  final pointStyle = jsGet(labelsOptions, 'pointStyle');
  // ... textAlign, color, useBorderRadius, borderRadius
  final labels = data['labels']! as List<Object?>;
  final datasets = data['datasets']! as List<Object?>;
  if (labels.isNotEmpty && datasets.isNotEmpty) {
    return [
      for (var i = 0; i < labels.length; i++)
        _legendItem(c, labels[i], i.toDouble(), /* the read options */),
    ];
  }
  return <Map<String, Object?>>[];
},

// controller.doughnut.js:125-128
'onClick': (Object? e, Object? legendItem, Object? legend) {
  final chart = (legend as types.LegendElement).chart;
  chart
    ..toggleDataVisibility(jsToNumber(jsGet(legendItem, 'index')))
    ..update();
},

// controller.doughnut.js:80-83
'_scriptable': (String name) => name != 'spacing' && name != 'spacingMode',
'_indexable': (String name) =>
    name != 'spacing' &&
    name != 'spacingMode' &&
    !name.startsWith('borderDash') &&
    !name.startsWith('hoverBorderDash'),
```

- `useBorderRadius && (borderRadius || style.borderRadius)` keeps the operand values:
  `jsTruthy(u) ? (jsTruthy(b) ? b : style['borderRadius']) : u`.
- `toggleDataVisibility(legendItem.index)`: the item of `generateLabels` has a number `index`.
  `jsToNumber` of an absent index gives NaN, and the key `'NaN'`. Upstream gives the key
  `'undefined'`. Neither key matches a data index. Thus the visible result is the same.
- Phase 8 calls the closures through `jsCall`. A Dart closure has no `this`. The upstream bodies
  do not read `this`.

## 7. The registration

### Probe

`<ev>/probe_registry.mjs`, output `<ev>/probe_registry.out`:
- The keys of the `controllers` namespace: `BarController, BubbleController,
  DoughnutController, LineController, PieController, PolarAreaController, RadarController,
  ScatterController`. The namespace is frozen.
- After `Chart.register(...registerables)`: the controller ids in the order `bar, bubble,
  doughnut, line, pie, polarArea, radar, scatter`, and the same order of `defaults.datasets`.
- `Object.getPrototypeOf(PieController) === DoughnutController`. `overrides.pie` is its own
  object with the keys `aspectRatio` and `plugins`.

### Choice

The form of phase 6 (Chart.js ADR 0020 §6), with no new concept:

```dart
// Ported from Chart.js v4.5.1+7169e651 src/controllers/index.js (MIT, Chart.js Contributors).
library;

export 'package:flutter_chartjs/src/controllers/controller.bar.dart'
    show BarController;
export 'package:flutter_chartjs/src/controllers/controller.bubble.dart'
    show BubbleController;
export 'package:flutter_chartjs/src/controllers/controller.doughnut.dart'
    show DoughnutController;
export 'package:flutter_chartjs/src/controllers/controller.line.dart'
    show LineController;
export 'package:flutter_chartjs/src/controllers/controller.pie.dart'
    show PieController;
export 'package:flutter_chartjs/src/controllers/controller.polarArea.dart'
    show PolarAreaController;
export 'package:flutter_chartjs/src/controllers/controller.radar.dart'
    show RadarController;
export 'package:flutter_chartjs/src/controllers/controller.scatter.dart'
    show ScatterController;
```

```dart
// lib/src/index.dart, index.ts:1 and :8
export 'package:flutter_chartjs/src/controllers/index.dart';

final AnyObject controllers = Map<String, Object?>.unmodifiable(
  <String, Object?>{
    'BarController': BarController.jsClass,
    'BubbleController': BubbleController.jsClass,
    'DoughnutController': DoughnutController.jsClass,
    'LineController': LineController.jsClass,
    'PieController': PieController.jsClass,
    'PolarAreaController': PolarAreaController.jsClass,
    'RadarController': RadarController.jsClass,
    'ScatterController': ScatterController.jsClass,
  },
);
```

- The `export` lines of `controllers/index.dart` follow the `directives_ordering` lint. The
  `///` lines give `index.js:1-8` in the upstream order (`PolarAreaController` before
  `PieController` at `:5-6`).
- `registerables` (`lib/src/index.dart`) does not change. `setUpBuiltins()` of
  `chartjs_test_utils` then registers the 8 controllers before `main()` of each test file
  (the row `harness-register-builtins`). `TypedRegistry.register` registers
  `DoughnutController` before `PieController` in both orders, because the registry registers a
  parent first (`core.typedRegistry.js:24-43`).
- The `jsClass` of each controller: `superclass: DatasetController.jsClass`, and
  `DoughnutController.jsClass` for `PieController` (Chart.js ADR 0020 §3).

## Open

1. **T for `meta.data`** (question 3): a `ChartMeta.data` with the run-time type of the element
   class removes the copy of 36-67 µs for each update of 20000 points. It changes a shared
   layer. Step 7 of phase 7 measures the frame figures of a line chart with `CALL=update`. A
   gain adds a new ADR.
2. **CF for `getDataVisibility`** (question 4): 1.5 ns for each call on wasm only. Step 7
   measures a polar area chart on Chrome dart2wasm. A gain adds a new ADR.
3. The parsed read of Chart.js ADR 0025 §8 and the shared list read (`labels[index]`,
   `meta._parsed[i]`) belong to the panel of the parsed read. This draft uses `jsGet` in its
   sketches.

## Files that the implementation changes

- `lib/src/types/index.dart`: the members of question 1; `RadialLinearScale`; `LegendElement`;
  the `points` setter of `LineElement`.
- `lib/src/core/core.controller.dart`: `@override` on `isDatasetVisible`,
  `getVisibleDatasetCount`, `toggleDataVisibility`, `update`; the field `legend`; the fast path
  of `getDataVisibility`; `ChartMeta.total` and its by-name keys; `@override` on `dataset_`.
- `lib/src/core/core.datasetController.dart`: the record `({Object? label, String value})`;
  `updateElement(types.Element ...)`; `@override` on `options`, `getParsed`, `getStyle`,
  `resolveDataElementOptions`.
- `lib/src/core/core.element.dart`: `@override` on `active` and `hidden`.
- `lib/src/core/core.scale.dart`, `lib/src/scales/scale.category.dart`,
  `lib/src/scales/scale.time.dart` and the other scales that override a member: `@override` on
  the 9 members.
- `lib/src/scales/scale.radialLinear.dart`: `implements types.RadialLinearScale`.
- `lib/src/elements/element.line.dart`: the setter `points`, the by-name `points` write, and
  `@override` on `chart`, `datasetIndex`, `decimated`, `updateControlPoints`.
- `lib/src/elements/element.point.dart`: `@override` on `size`.
- `lib/src/helpers/helpers.extras.dart`: the parameter type of
  `getStartAndCountOfVisiblePoints`.
- `lib/src/controllers/controller.*.dart` (8 files) and `lib/src/controllers/index.dart`.
- `lib/src/index.dart`: the export and the `controllers` Map.
- `apps/chartjs_gallery/lib/demo/demo_chart.dart`: the 5 new `types.Chart` members.
- `test/specs/helpers.segment_test.dart`, `test/port/helpers/helpers.collection_test.dart`:
  the fake point elements get the new members or a `noSuchMethod`.
- `doc/differences.md`: one sentence in the row `adapt-line-points-elements`.
- `doc/adr/0028-*.md` (new, proposed).

## Tests that pin the decision

- `test/port/types/` or the test of each concrete class: each new interface member returns the
  value of the concrete member (a compile-time check that the concrete class implements it, and
  one call each).
- `test/port/controllers/controller.doughnut_test.dart` and the polar area, radar, scatter and
  bubble files, group `getLabelAndValue`: labels `[['Line 1', 'Line 2'], 7, '']` give the
  identical `List`, `7` and `''`; radar past the end gives `undefined`; bar and line give the
  string `'Line 1,Line 2'` (the rows of `<ev>/probe_label.out`).
- `test/port/elements/element.line_test.dart`, group `adapt-line-points-elements`: a
  `List<types.PointElement>` keeps its identity; a `List<types.Element>` of point elements gives
  a list with the identical elements in the same order; an element of another class throws a
  `TypeError`.
- `test/port/controllers/controller.line_test.dart`: after `chart.update()`,
  `identical(line.points[i], meta.data[i])` for each `i`, and after a data push and an update,
  `line.points.length == meta.data.length`.
- `test/port/core/core.controller_test.dart`, group `getDataVisibility`: with no hidden index,
  the result is true for `0`, `1.5`, `-1`, NaN and infinity; after one toggle, false for that
  index; after two toggles, true (the slow path).
- `test/port/controllers/controller.polarArea_test.dart`, group `spacingMode hunk`: the 8 rows
  of `<ev>/probe_spacing.out` for `upstream`, also the hover row of the
  `elements.arc.spacingMode: 'angular'` case; a subclass with `enableOptionSharing = true` throws
  a `TypeError` in the 4 rows that throw upstream.
- `test/specs/controller.polarArea_test.dart` `:69`, `:85` and
  `test/specs/controller.doughnut_test.dart` `:49`: the spec cases.
- `test/port/controllers/controller.doughnut_test.dart`, group `legend overrides`: a direct call
  of `generateLabels` without a legend throws a `TypeError`; with a fake `types.LegendElement`,
  it returns the items; `onClick` toggles the index and calls `update` once on a recording
  chart. The polar area `generateLabels` returns `[]` without a legend when the chart has no
  labels.
- `test/port/index_test.dart` (or the existing namespace test): the keys of `controllers` in
  code unit order, each value `identical` to the `jsClass`, the Map unmodifiable;
  `registry.controllers.items['doughnut']` is `DoughnutController.jsClass`
  (`controller.doughnut.tests.js:4-7`).
