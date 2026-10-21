# Draft (fidelity first): controller interfaces and values

Design panel "Controller interfaces and values", phase 7 step 2. This draft is the input of the
future Chart.js ADR 0028. Lens: fidelity first. The draft gives the most weight to the upstream
behavior (Chart.js ADR 0009) and to the upstream structure (AGENTS.md rule 2). It accepts a cost
only when a measurement shows that the cost is small.

All upstream citations are at the pin `v4.5.1+7169e651` (`third_party/Chart.js`, `git log -1`
gives `7169e65`). "pin" in a citation means this commit. `index.d.ts` is
`src/types/index.d.ts`. Dart paths are relative to `packages/flutter_chartjs/lib/src/`. "DC" is
`core/core.datasetController.dart`, "cc" is `core/core.controller.dart`, "types" is
`types/index.dart`.

The evidence folder is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/interfaces-values-fidelity/`
(below: `<fid>`). The Node.js probes ran on the x64 build of Node.js v24.12.0 under Rosetta
against `dist/chart.js` of the Chart.js build at the pin (Chart.js ADR 0010). The Dart benchmarks
ran on an Apple M3 Max with Dart 3.12.2 (Flutter 3.44.9): AOT (`dart compile exe`) and dart2wasm
(`dart compile wasm`, run in Node.js v24.12.0 arm64 through `<fid>/bench/run_wasm.mjs`). Each
benchmark gives the median of 15 samples in ABBA order after 5 warm-up rounds. Each benchmark ran
in 3 or 4 processes. The ranges below are the ranges of the process medians.

## Summary of the choices

| Question | Choice |
|---|---|
| 1. Interface members | Add 28 members to 7 interfaces of `types`, and 2 new interfaces with 7 members. A controller casts only to a type interface, or to a class of its own library or of a library that the upstream file imports. `DatasetController.updateElement` takes `types.Element`. |
| 2. `getLabelAndValue` | `({Object? label, String value})`. The overrides return the raw label, as upstream. |
| 3. `line.points` | A cast view `meta.data.cast<types.PointElement>()` in one local `points`, as the upstream local. The existing row `adapt-line-points-elements` gets the view. |
| 4. `getDataVisibility` | The interface call. The body gets one port-only line: `if (_hiddenIndices.isEmpty) return true;`. |
| 5. The #12238 hunk | A line-by-line port of `controller.polarArea.js:204-210`. No option sharing in polar area, as upstream. A frozen options object throws a `TypeError`, as upstream. |
| 6. Legend functions | Port the bodies now as Dart closures. `types.LegendElement` (`chart`, `options`) and `types.Chart.legend` come with them. |
| 7. Registration | `controllers/index.dart` in the source order of `index.js`. The `controllers` Map in code unit order. `registerables` stays. |

## 1. The interface members that a controller reads first

### 1.1 Options

- **U (upstream form).** JavaScript reads each member of the object that it has. TypeScript
  types the objects through generic parameters, for example
  `ChartMeta<TType, TElement, TDatasetElement>` (`index.d.ts:507-513`) and `DatasetController<…,
  TElement, TDatasetElement>` (`index.d.ts:622-627`).
- **A (Chart.js ADR 0003, Chart.js ADR 0025 §5).** An interface member of `lib/src/types/` comes
  with its first ported caller. Chart.js ADR 0025 §5 fixes the forms of the 9 scale members and
  of `types.RadialLinearScale`.
- **K (a cast to the concrete class).** The controller casts `meta.vScale as Scale`,
  `chart as Chart`, `meta.data[i] as Element`. This form adds imports that the upstream file does
  not have: `core.scale`, `core.controller`, `core.element`, the element modules. The gallery
  controller does this now (`apps/chartjs_gallery/lib/demo/stress_point_controller.dart:231`,
  `(vScale as Scale).getBasePixel()`).

### 1.2 Choice

A. Each member that a controller reads through an object of an interface type becomes a member of
that interface. A controller casts only in two cases:

1. To a type interface of `lib/src/types/`. This cast is the Dart form of a TypeScript generic
   argument. Examples: `meta.dataset as types.LineElement` (the `TDatasetElement` of
   `ChartMeta<'line', PointElement, LineElement>`), `meta.rScale as types.RadialLinearScale`,
   `meta.data[i] as types.PointElement`, `rects[i] as types.VisualElement`.
2. To a class of its own library, or of a library that the upstream file imports. Example:
   `controller.doughnut.js:194-195` calls `controller._getRotation()` on the controller of another
   meta of the same type. The Dart form is `(meta.controller! as DoughnutController)._getRotation()`
   in `controller.doughnut.dart`. `controller.pie.dart` imports `controller.doughnut.dart`, as
   `controller.pie.js:1` does.

A controller never casts to a concrete class of a module that the upstream file does not import.

`DatasetController.updateElement` (DC:1673) takes the concrete `Element` of `core.element.dart`
now. Each controller passes `meta.data[i]`, a `types.Element`. The parameter becomes
`types.Element`, and DC casts once inside, where it calls `assign`. `index.d.ts:674` types the
parameter as `TElement | TDatasetElement`, which extend the `Element` of `core.element.ts`. DC
already imports `core.element.dart`. Thus the cast moves into the one file that has the import,
and no controller imports `core.element.dart`.

### 1.3 The members, their Dart signatures and their first readers

The first reader is the first read in the port order of the phase (bar, line, bubble, doughnut,
polarArea, radar, scatter, pie). Each line was checked with `grep -n` at the pin.

**`types.Scale`** (9 members, the forms of Chart.js ADR 0025 §5; `getBaseValue` waits for its
first reader, `filler.options.js`, in phase 8):

| Dart member | Upstream | First reader at the pin | Concrete |
|---|---|---|---|
| `Map<String, Object?> get cache` | `core.scale.js:247` `_cache` | `controller.bar.js:8`, `:15`, `:17` | `core/core.scale.dart:886` |
| `List<Tick>? get ticks` | `index.d.ts:1321` | `controller.bar.js:47` | `core/core.scale.dart:809` |
| `double? getPixelForTick(int index)` | `index.d.ts:1346` | `controller.bar.js:48` | `core/core.scale.dart:1897` |
| `double getBasePixel()` | `index.d.ts:1382` | `controller.bar.js:396`, `controller.line.js:101` | `core/core.scale.dart:1938` |
| `double get startPixel` | `core.scale.js:237` `_startPixel` | `controller.bar.js:549` | `core/core.scale.dart:838` |
| `double get endPixel` | `core.scale.js:239` `_endPixel` | `controller.bar.js:550` | `core/core.scale.dart:843` |
| `double getPixelForDecimal(double decimal)` | `index.d.ts:1339` | `controller.bar.js:606-607`, `controller.bubble.js:129` | `core/core.scale.dart:1911` |
| `double? getValueForPixel(double pixel)` | `index.d.ts:1374` | `controller.bar.js:615` | `core/core.scale.dart:1887` and 5 overrides |
| `double getLineWidthForValue(Object? value)` | `index.d.ts:1357` | `controller.bar.js:620` | `core/core.scale.dart:2584` |

Chart.js ADR 0025 cites the `index.d.ts` lines of v4.5.1 (`:1291` to `:1352`). The pin adds 58
lines to `index.d.ts` (`git diff --stat 9c5cf9fa 7169e651 -- src/types/index.d.ts`). The table
gives the lines at the pin.

**`types.RadialLinearScale implements Scale`** (new interface, `index.d.ts:3676-3685`;
`RadialLinearScale` of `scales/scale.radialLinear.dart:731` implements it):

| Dart member | Upstream | First reader at the pin | Concrete |
|---|---|---|---|
| `double get xCenter` | `index.d.ts:3677` | `controller.polarArea.js:167`, `controller.radar.js:90` | `:826` |
| `double get yCenter` | `index.d.ts:3678` | `controller.polarArea.js:168`, `controller.radar.js:91` | `:830` |
| `double getIndexAngle(double index)` | `index.d.ts:3681` | `controller.polarArea.js:169` | `:955` |
| `double getDistanceFromCenterForValue(Object? value)` | `index.d.ts:3682` | `controller.polarArea.js:182` | `:967` |
| `({double x, double y, double angle}) getPointPositionForValue(double index, Object? value)` | `index.d.ts:3685` | `controller.radar.js:88` | `:1029` |

Chart.js ADR 0025 §5 cites `controller.polarArea.js:165-166` and `:180` (v4.5.1). #12238 adds two
lines of defaults (`controller.polarArea.js:25-26`). Thus the lines at the pin are `:167-169` and
`:182`.

The read `meta.rScale as types.RadialLinearScale` throws a `TypeError` for Dart `null` (JS
`undefined`). Upstream throws a `TypeError` at `scale.xCenter` of `undefined`. For a scale of
another type, upstream throws at `scale.getIndexAngle(0)` (polarArea) or at
`scale.getPointPositionForValue` (radar), because the method is not a function. The Dart cast
throws earlier in the same call. Chart.js ADR 0009 protects the throw, not its line.

**`types.Chart`** (5 members):

| Dart member | Upstream | First reader at the pin | Concrete (cc) |
|---|---|---|---|
| `bool isDatasetVisible(double datasetIndex)` | `index.d.ts:569` | `controller.doughnut.js:192` (also `:340`, `:380`) | `:1718` |
| `double getVisibleDatasetCount()` | `index.d.ts:568` | `controller.polarArea.js:155` | `:1713` |
| `void toggleDataVisibility(double index)` | `index.d.ts:571` | `controller.doughnut.js:126`, `controller.polarArea.js:66` (through `legend.chart`) | `:1744` |
| `void update([Object? mode])` | `index.d.ts:559` | `controller.doughnut.js:127`, `controller.polarArea.js:67` | `:1232` (`[Object? mode = undefined]`) |
| `LegendElement? get legend` | `index.d.ts:543` | `controller.doughnut.js:97`, `controller.polarArea.js:41` | new field (section 6) |

**`types.ChartMeta`** (2 members):

| Dart member | Upstream | First reader at the pin | Concrete |
|---|---|---|---|
| `abstract double? total` | `index.d.ts:373-375` `DoughnutMetaExtensions.total`, the meta extension of `doughnut` and `pie` (`index.d.ts:382`, `:3792`, `:3800`) | `controller.doughnut.js:235` (write), `:313` (read) | new field of `ChartMeta` (cc:275). Dart `null` stands for JS `undefined`, the start value. `operator []` gives `total ?? undefined`, and `operator []=` writes it. Today the write goes to the Map of extra properties (cc:430, :544). |
| `Object? get dataset_` | `core.controller.js:845` `_dataset` (Chart.js ADR 0023) | `controller.line.js:43`, `:78`; `controller.scatter.js:77`, `:113` | cc:334 |

**`types.DatasetController`** (4 members):

| Dart member | Upstream | First reader at the pin | Concrete (DC) |
|---|---|---|---|
| `Map<String, Object?> get options` | `core.datasetController.js:262` (`index.d.ts` does not declare it) | `controller.bar.js:437` (`meta.controller.options.grouped`) | `:717` |
| `Object? getParsed(double index)` | `index.d.ts:688` | `controller.bar.js:440` | `:1199` |
| `Map<String, Object?> getStyle(double? index, [bool? active])` | `index.d.ts:656` | `controller.doughnut.js:101`, `controller.polarArea.js:45` | `:1428` |
| `Map<String, Object?> resolveDataElementOptions(double index, [String? mode])` | `index.d.ts:658` | `controller.doughnut.js:354` | `:1501` |

**`types.Element`** (2 members):

| Dart member | Upstream | First reader at the pin | Concrete |
|---|---|---|---|
| `bool get active` | `core.element.ts:13` | `controller.bar.js:418` (also `controller.line.js:111`, `controller.doughnut.js:288`, `controller.polarArea.js:201`, `controller.radar.js:87`, `controller.bubble.js:135`, `controller.scatter.js:140`) | `core/core.element.dart:208` |
| `Object? get hidden` | `core.datasetController.js:730` (`core.element.ts` does not declare it) | `controller.bar.js:676`, `controller.doughnut.js:250`, `:304` | `core/core.element.dart:237` |

`types.Scale implements Element`. Thus each scale gets the two getters from the concrete
`Element`, which `Scale` extends.

**`types.PointElement`** (1 member):

| Dart member | Upstream | First reader at the pin | Concrete |
|---|---|---|---|
| `double size([Map<String, Object?>? options])` | `element.point.ts:81` | `controller.line.js:133-134` (also `controller.bubble.js:88`, `controller.scatter.js:163`, `:175-176`) | `elements/element.point.dart:394` |

**`types.LineElement`** (5 members):

| Dart member | Upstream | First reader at the pin | Concrete (`elements/element.line.dart`) |
|---|---|---|---|
| `set points(List<PointElement> value)` | `index.d.ts:2026` | `controller.line.js:60`, `controller.scatter.js:83`, `controller.radar.js:60` | `:828` |
| `set chart(Chart value)` | `element.line.js:284` `_chart` | `controller.line.js:57`, `controller.scatter.js:80` | `:750` |
| `set datasetIndex(double value)` | `element.line.js:292` `_datasetIndex` | `controller.line.js:58`, `controller.scatter.js:81` | `:784` |
| `abstract bool decimated` | `element.line.js:290` `_decimated` | `controller.line.js:59`, `controller.scatter.js:82` | `:733` |
| `void updateControlPoints(ChartArea chartArea, [String? indexAxis])` | `index.d.ts:2025` | `controller.line.js:140` | `:796` |

Totals: 28 new members of 7 existing interfaces (`Scale` 9, `Chart` 5, `ChartMeta` 2,
`DatasetController` 4, `Element` 2, `PointElement` 1, `LineElement` 5). Two new interfaces:
`types.RadialLinearScale` (5 members) and `types.LegendElement` (2 members, section 6).

### 1.4 Evidence

- **E1.1, the analyzer probe.** `<fid>/ifaceprobe/lib/probe.dart` declares each new member with
  the Dart signature of section 1.3 on a local interface. Then it declares
  `abstract class _X extends <concrete class> implements <local interface> {}` for `Chart`,
  `DatasetController`, `Element`, `PointElement`, `LineElement`, `Scale` and `RadialLinearScale`.
  `dart analyze` gives no error (`<fid>/ifaceprobe/analyze.out`). The concrete members implement
  each new member as they are. `ChartMeta` is a `final class`. Thus the probe reads its
  `dataset_` through a function. `total` is a new field.
- **E1.2, interface or cast for the element getters.** `<fid>/bench/bench_active.dart`: the read
  of `active` and `hidden` in a loop of 1000 point, bar and arc elements. "I" reads through an
  interface with the two getters (an upper bound: it also casts to that interface). "C" casts to
  the concrete `Element`, as DC:1403 does now. Outputs `aot_active_{1,2,3}.out`,
  `wasm_active_{1,2,3}.out`:

  | Form | AOT (ns/element) | wasm (ns/element) |
  |---|---|---|
  | I, interface | 1.07-1.17 | 0.84-0.89 |
  | C, cast to `Element` | 1.47-1.63 | 0.85-0.89 |

  The interface read costs no more than the cast.
- **E1.3, interface or cast for a chart method.** Section 4: the cast of `getDataVisibility`
  gains 0.3-1.8 ns (AOT) and 2.0-3.2 ns (wasm) for each call.
- **E1.4, the fakes.** The classes that implement `types.Chart`, `types.ChartMeta`,
  `types.DatasetController` or `types.Scale` in the tests have `noSuchMethod`, except `_Meta` of
  `test/port/core/core.datasetController_test.dart:425`. `DemoChart`
  (`apps/chartjs_gallery/lib/demo/demo_chart.dart:40`) also has no `noSuchMethod` (Chart.js ADR
  0025, E7). Both get the new members.

### 1.5 Score

| Option | Behavior | Performance | Structure | Code |
|---|---|---|---|---|
| A, interface members | upstream throws and values | equal or better than K (E1.2, E1.3) | no import that upstream lacks | 35 declarations in `types`, 2 fakes |
| K, concrete casts | the same values; a cast to a concrete class throws for a user class that implements only the interface | 0-1.8 ns (AOT) and 0-3.2 ns (wasm) better for a chart method, worse for an element getter | imports of `core.controller`, `core.scale`, `core.element` and element modules in the controller files | no `types` change |

A wins on behavior and structure. The performance difference is at most 3.2 ns for each call
(E1.3), less than 1 % of the per-element update.

### 1.6 Code form

```dart
// types/index.dart (excerpt)

/// index.d.ts:3676 `RadialLinearScale`. `RadialLinearScale` of
/// `scales/scale.radialLinear.dart` implements it. The filler of phase 8
/// tests `scale is RadialLinearScale` for `if (scale.getPointPositionForValue)`
/// (filler.target.js:50).
abstract interface class RadialLinearScale implements Scale {
  /// index.d.ts:3677 `xCenter: number`. controller.polarArea.js:167 reads it.
  double get xCenter;
  /// index.d.ts:3678 `yCenter: number`.
  double get yCenter;
  /// index.d.ts:3681 `getIndexAngle(index: number): number`.
  double getIndexAngle(double index);
  /// index.d.ts:3682. The value is any JS value (Chart.js ADR 0025 §1).
  double getDistanceFromCenterForValue(Object? value);
  /// index.d.ts:3685. The result is a record (Chart.js ADR 0003).
  ({double x, double y, double angle}) getPointPositionForValue(
    double index,
    Object? value,
  );
}

abstract interface class Element implements Point {
  // ... x, y, options ...

  /// core.element.ts:13 `active = false`. controller.bar.js:418 reads it.
  bool get active;

  /// core.datasetController.js:730 `element.hidden`. core.element.ts does not
  /// declare it. controller.bar.js:676 tests its truthiness. Any JS value: the
  /// `undefined` sentinel in the start state, Dart `null` for JS `null`.
  Object? get hidden;
}
```

```dart
// core/core.datasetController.dart: the one cast moves into DC.
void updateElement(
  types.Element element,
  double? index,
  AnyObject properties,
  String mode,
) {
  if (_isDirectUpdateMode(mode)) {
    (element as Element).assign(properties);
  } else {
    resolveAnimations(index, mode).update(element, properties);
  }
}
```

```dart
// controllers/controller.polarArea.dart, controller.polarArea.js:166-169
final scale = cachedMeta.rScale as types.RadialLinearScale;
final centerX = scale.xCenter;
final centerY = scale.yCenter;
final datasetStartAngle = scale.getIndexAngle(0) - 0.5 * pi;
```

## 2. The label of `getLabelAndValue`

### 2.1 Options

- **U (upstream form).** The base returns `'' + iScale.getLabelForValue(…)`, a string
  (`core.datasetController.js:687-697`). Bar returns a string (`controller.bar.js:364-376`).
  Scatter, bubble, doughnut (also pie) and polarArea return `labels[index] || ''`, the raw label
  (`controller.scatter.js:51`, `controller.bubble.js:106`, `controller.doughnut.js:327`,
  `controller.polarArea.js:104`). Radar returns `vScale.getLabels()[index]`, also `undefined`
  past the labels (`controller.radar.js:44`). `index.d.ts:641` declares `{label: string; value:
  string}`, but the runtime value is the raw label.
- **S (the current Dart form).** `({String label, String value})` (DC:1339). The overrides apply
  `jsToString` to the raw label.
- **O (the choice).** `({Object? label, String value})`. The overrides return the raw label.

### 2.2 Choice

O. The record keeps the `value` as a `String`: each body makes it with `'' +`, `'(' + … + ')'`,
`'[' + … + ']'` or `formatNumber`, which gives a string. The `label` is `Object?`: a `String`, a
`List` of lines, a number, any other user value, or the `undefined` sentinel (radar).

### 2.3 Evidence

- **E2.1, probe.** `<fid>/probe_label.mjs`, output `<fid>/probe_label.out` (a rerun in this
  session, `probe_label.rerun`, is byte-identical). Labels `[['line 1', 'line 2'], 5, 0, 'd',
  undefined]`. Mode `raw` is the build. Mode `string` wraps each `getLabelAndValue` so that the
  label is `'' + label`, the result of form S. The probe also sets the tooltip active on each
  element and records `tooltip.title`:

  | Type, index | Raw label (U) | Title (U) | Title (S) |
  |---|---|---|---|
  | scatter, bubble, doughnut, pie, polarArea, radar: 0 (`['line 1', 'line 2']`) | the array | `["line 1","line 2"]`, 2 lines | `["line 1,line 2"]`, 1 line |
  | the same, 1 (`5`) | `5` (number) | `[5]` | `["5"]` |
  | radar 2 (`0`) | `0` (number) | `[]`, no title | `["0"]` |
  | radar 4, 5 (`undefined`) | `undefined` | `[]`, no title | `["undefined"]` |
  | bar, line: all | a string | equal in both modes | equal |

  Form S changes the count of title lines, and it adds a title `undefined` or `0` where upstream
  has none. These are not digits or pixels (Chart.js ADR 0009). They change the text and the size
  of the tooltip, and a user callback reads `tooltipItem.label` with its upstream type.
- **E2.2, specs.** `plugin.tooltip.tests.js:920` expects `typeof tooltipItem.label` to be
  `'string'` for a line chart. The base form gives a string. Form O keeps it.
  `controller.doughnut.tests.js:418-469` and `controller.polarArea.tests.js:389` read the title of
  a string label (phase 8).
- **E2.3, the Dart test.** `test/port/core/core.datasetController_test.dart:863-869` destructures
  `(:label, :value)` and encodes `label` with `_enc`. It accepts `Object?` with no change.

### 2.4 Effect on the code

- DC:1339: the return type becomes `({Object? label, String value})`. The base body stays.
- Bar: a string label, as today. Scatter, bubble, doughnut, polarArea: `jsTruthy(item) ? item :
  ''` of the list read. Radar: the list read of `vScale.getLabels()` with `undefined` past the
  end.
- Phase 8 (`plugin.tooltip.js:126-141` `createTooltipItem`): the tooltip item keeps
  `Object? label`. `title` (`plugin.tooltip.js:366-376`) tests `jsTruthy(item.label)` and returns
  the raw value. The `label` callback of mode `dataset` (`:390`) applies `jsAdd` to
  `tooltipItem.label + ': ' + …`. Phase 8 decides the form of the tooltip item. This ADR fixes only
  the type of the label.

### 2.5 Code form

```dart
// core/core.datasetController.dart:1334-1351
/// core.datasetController.js:687 `getLabelAndValue(index)`. @protected
///
/// `index.d.ts:641` declares a string label. The overrides of scatter, bubble,
/// doughnut, polarArea and radar return the raw label (a string, a List of
/// lines, a number, any value, or [undefined]). Thus [label] is `Object?`.
({Object? label, String value}) getLabelAndValue(double index) { ... }

// controllers/controller.polarArea.dart, controller.polarArea.js:97-107
@override
({Object? label, String value}) getLabelAndValue(double index) {
  final meta = cachedMeta;
  final chart = this.chart;
  final labels = _orEmpty(chart.data['labels']);       // `|| []`
  final value = formatNumber(
    jsToNumber(jsGet(_item(meta.parsed, index), 'r')),
    jsGet(chart.options, 'locale'),
  );
  final label = _item(labels, index);                  // `labels[index]`
  return (label: jsTruthy(label) ? label : '', value: value);  // `|| ''`
}
```

`_orEmpty` and `_item` stand for the shared list read that the parsed-data panel decides.

## 3. `meta.data` and `line.points`

### 3.1 Options

- **U (upstream form).** `const {dataset: line, data: points = []} = meta;`
  (`controller.line.js:43`), then `_getStartAndCountOfVisiblePoints(meta, points, …)` (`:47`) and
  `line.points = points` (`:60`). The line and the meta share one array. The same form is at
  `controller.scatter.js:57-83` and `controller.radar.js:56-60`.
- **V (cast view).** `final points = meta.data.cast<types.PointElement>();` One local, as
  upstream. The view reads and writes through to `meta.data`. Each read checks the item type.
- **C (copy).** `List<types.PointElement>.of(meta.data.cast())`. A new list at each update. The
  line does not see a later change of `meta.data`.
- **T (typed list on the meta).** The runtime type of `meta.data` is `List<types.PointElement>`
  for a point controller. Then `points is List<types.PointElement>` is true, and the line keeps
  the same list (identity).
- **W (a wider points type).** `types.LineElement.points` and the readers in
  `elements/element.line.dart`, `helpers/helpers.segment.dart` and `helpers/helpers.curve.dart`
  take `List<types.Element>` and cast each item.

### 3.2 Choice

V, with a `DIVERGES` marker of the existing row `adapt-line-points-elements` at the three sites.
The row text gets one sentence: "The line keeps a cast view of `meta.data`, not the same array.
The items and the length are the same at each read."

### 3.3 Evidence

- **E3.1, the specs.** No spec reads the identity of `line.points`. `grep -rn '\.points\b\|_points'
  test/specs/*.js` gives one hit: `element.line.tests.js:11`, a line without a meta. The filler
  of phase 8 reads `line.points` (`filler.drawing.js:14`, `filler.segment.js:5`,
  `filler.target.stack.js:19`, `:95`). It only reads items and the length.
- **E3.2, the line benchmark.** `<fid>/bench/bench_points.dart`: one iteration does what
  `controller.line.js:56-73` and `:138-141` do to the line in one update and one draw:
  `line.points = points`, `updateControlPoints(area, 'x')` and `draw(ctx)` of an animated line
  (the path is built again in each draw). Real `LineElement`, `PointElement` and `Path2D` code; a
  no-op canvas. Outputs `aot_points_{1,2,3,4}.out`, `wasm_points_{1,2,3,4}.out` (run 3 of wasm
  stopped before its last row). The figure is the extra cost over the typed list, in ns for each
  point, and the typed figure:

  | Case | Typed (T) | V, view | C, copy | View of the concrete class |
  |---|---|---|---|---|
  | AOT, 1000, tension 0 | 24.4-25.1 | +1.5 to +2.0 | +4.3 to +4.7 | +1.7 to +2.3 |
  | AOT, 1000, tension 0.4 | 50.2-52.0 | +4.5 to +5.7 | +4.2 to +5.0 | +5.0 to +5.9 |
  | AOT, 20000, tension 0 | 17.9-18.7 | +1.2 to +1.6 | +14.6 to +16.1 | +1.2 to +2.2 |
  | AOT, 20000, tension 0.4 | 74.1-81.9 | -1.1 to +8.3 | +14.6 to +21.5 | +1.0 to +5.3 |
  | wasm, 1000, tension 0 | 39.0-40.3 | +6.2 to +6.4 | +3.6 to +4.9 | +3.0 to +4.1 |
  | wasm, 1000, tension 0.4 | 131.4-134.0 | +18.5 to +21.2 | +2.2 to +5.0 | +12.3 to +13.5 |
  | wasm, 20000, tension 0 | 33.1-33.5 | +5.0 to +5.3 | +6.7 to +8.1 | +3.1 to +3.6 |
  | wasm, 20000, tension 0.4 | 141.2-148.8 | +20.0 to +21.2 | +5.5 to +6.5 | +11.5 to +14.2 |

  The column "typedChecked" of the outputs (the type test of form T, then the typed list) is
  -0.6 to +0.9 ns, except the noisy AOT 20000 / 0.4 row. T thus costs nothing over the typed list.
- **E3.3, the share of the frame.** `performance.md` §10.7 gives the draw cost for each point of
  a chart: 0.38-0.48 µs on the Pixel 8a and 0.25-0.27 µs on macOS. The view adds 1.2-2.0 ns
  (AOT, tension 0) and 4.5-5.7 ns (AOT, tension 0.4) for each point to the line update and draw:
  about 2 % or less of the macOS draw cost for each point. On wasm, the view adds 5-6 ns (tension
  0) and 18-21 ns (tension 0.4). This draft has no frame figure for Chrome. Open 1 records the
  measurement.
- **E3.4, the probe of form T.** `<fid>/dartprobe/covariant_list.dart`, output
  `covariant_list.out`. On a `List<types.Element>` with the runtime type
  `List<types.PointElement>`: `insertAll` of a `List<types.Element>.filled(…)` throws a
  `TypeError`, a write of a plain `Element` throws a `TypeError`. `_insertElements` (DC:1807-1825)
  does both: it moves the items with a filler `_hole`, an `Element` (DC:497), and writes
  `jsConstruct(dataElementType) as Element`. The meta is made in `getDatasetMeta` (cc) before
  the controller, and `meta.data` is `final` (cc:298). Thus form T needs a change of the meta
  and of `_insertElements`, and a user element class that is not a point element throws at the
  write. That is a change of the structure of a shared layer.
- **E3.5, form W.** `helpers/helpers.segment.dart` takes `List<PointElement>` at 6 functions
  (`:112`, `:170`, `:301`, `:353`, `:456`, `:482`). `elements/element.line.dart` uses
  `types.PointElement` at 18 sites. The upstream JSDoc of these functions also says
  `PointElement[]`. W adds a cast at each item read in these files.

### 3.4 Score

| Option | Behavior | Performance | Structure | Code |
|---|---|---|---|---|
| U | (JavaScript) | | | |
| V, view | the same items, length and liveness; identity differs (no spec reads it) | AOT +1.2-5.7 ns/point, wasm +5-21 ns/point | one local `points`, as upstream; no shared layer changes | `.cast()` at 3 sites |
| C, copy | a change of `meta.data` between the set and the next update is not seen | AOT up to +21.5 ns/point; wasm +2.2-8.1 ns/point | breaks the shared array | 3 sites |
| T, typed meta list | identity kept; a user element class that is not a point element throws | ±0 | changes `ChartMeta.data` and `_insertElements` (E3.4) | about 30 lines in 2 shared files |
| W, wider points | identity kept | a cast at each item read (not measured end to end) | changes 3 ported files against their JSDoc | about 25 sites |

V keeps the most behavior with no change of a shared layer. C is faster on wasm with tension,
but it breaks the shared array, and it is slower on AOT at 20000 points. T is the fastest, but it
changes the structure of two shared layers. The protocol needs frame figures for a form that
changes the structure (Chart.js ADR 0020 §13). This draft has none. Thus V, and Open 1.

### 3.5 Code form

```dart
// controllers/controller.line.dart, controller.line.js:41-73
@override
void update(String mode) {
  final meta = cachedMeta;
  // `const {dataset: line, data: points = [], _dataset} = meta;`
  final line = meta.dataset as types.LineElement;
  // DIVERGES(chartjs): adapt-line-points-elements, a cast view of meta.data.
  final points = meta.data.cast<types.PointElement>();
  final dataset_ = meta.dataset_;
  final animationsDisabled = jsTruthy(chart.animationsDisabled);
  var (:start, :count) =
      getStartAndCountOfVisiblePoints(meta, points, animationsDisabled);
  drawStart = start;
  drawCount = count;
  if (scaleRangesChanged(meta)) {
    start = 0;
    count = points.length.toDouble();
  }
  line
    ..chart = chart
    ..datasetIndex = index
    ..decimated = jsTruthy(jsGet(dataset_, '_decimated'))
    ..points = points;
  // ... :62-73 as upstream; updateElement(line, null, {...}, mode)
}
```

## 4. `getDataVisibility`: the call and the key

### 4.1 Options

- **U (upstream form).** `return !this._hiddenIndices[index];` (`core.controller.js:885-887`).
  JavaScript reads an integer key of an object without a string. The Dart port builds the key with
  `jsNumberToString(index)` at each call (cc:1751-1753).
- **I (Chart.js ADR 0025 §4).** The controllers call `chart.getDataVisibility(i)` through
  `types.Chart`.
- **C (cast).** `(chart as Chart).getDataVisibility(i)`. It imports `core.controller.dart`, which
  no controller file imports upstream.
- **IE (an early return in the body).** `if (_hiddenIndices.isEmpty) return true;` before the
  upstream line. An empty object gives `undefined` for each key, and `!undefined` is true. Thus
  IE gives the upstream result for each index.
- **IK (cached keys).** A table of the keys `'0'` to `'4095'`, as `_indexKey` of DC:528-539.

### 4.2 Choice

I with IE. The controllers call through the interface. The body of `Chart.getDataVisibility` gets
the early return. No `DIVERGES` marker: the result is the upstream result for each state, and the
call sites keep the upstream form. Chart.js ADR 0025 §3 is the precedent: a port-only fast path
with the upstream result, a pin test and a record in `performance.md`, and no marker. IK is not
taken: it gains only after a legend click, and it adds a table.

### 4.3 Evidence

- **E4.1, the calls for each element.** `controller.bar.js:592` (1 for each bar);
  `controller.doughnut.js:250`, `:304` (2 for each arc); `controller.polarArea.js:130`, `:182`,
  `:221`, `:233` (4 for each arc, and 1 more for each arc before `start`);
  `scale.radialLinear.js:463` (1 for each label). All calls are in `update`, not in the animation
  frames.
- **E4.2, the benchmark.** `<fid>/bench/bench_visibility.dart`: 1000 calls for each sample, 200
  rounds, with three live implementations of `types.Chart` at the call site. Outputs
  `aot_vis_{1,2,3,4}.out`, `wasm_vis_{1,2,3,4}.out`. ns for each call:

  | Form | AOT, no hidden index | AOT, index 3 hidden | wasm, no hidden index | wasm, index 3 hidden |
  |---|---|---|---|---|
  | I (the current body) | 17.4-18.8 | 20.4-21.7 | 22.0-23.0 | 24.3-26.2 |
  | C (cast, the current body) | 17.0-17.9 | 19.1-20.6 | 18.7-21.1 | 21.6-24.0 |
  | IE (interface, early return) | 3.8-4.1 | 20.0-22.1 | 3.4-3.7 | 23.8-26.5 |
  | IK (interface, cached key) | 9.4-10.0 | 11.4-12.5 | 10.7-12.3 | 12.5-14.4 |

  - The cast gains 0.3-1.8 ns (AOT) and 2.0-3.2 ns (wasm) for each call: about 10 % of the call.
    It needs an import that upstream does not have. Not taken.
  - IE gains 13.6-14.8 ns (AOT) and 18.6-19.4 ns (wasm) for each call when no index is hidden,
    the state of a chart without legend clicks. For 1000 polar area arcs (4 calls for each arc),
    that is 54-59 µs (AOT) and 74-78 µs (wasm) for each update. With a hidden index, IE costs
    the same as I (one more `isEmpty` test).
- **E4.3, `performance.md` §11.3.** The phase 6 figures (interface 6.3-6.5 ns, cast 5.2-5.3 ns on
  AOT) measured a body without the key. The key is most of the cost of the call (E4.2).

### 4.4 Code form

```dart
// core/core.controller.dart:1749-1753
/// core.controller.js:885 `getDataVisibility(index)`.
///
/// An empty `_hiddenIndices` gives `undefined` for each key, and the upstream
/// line gives true. The early return skips the `ToString` of the key in that
/// state (Chart.js ADR 0028 §4, performance.md).
@override
bool getDataVisibility(double index) {
  if (_hiddenIndices.isEmpty) return true;
  return !jsTruthy(_hiddenIndices[jsNumberToString(index)]);
}
```

The pin test: an empty map; one hidden index; the same index after two toggles (an own `false`
entry, not empty); a non-integer index (`1.5`, key `'1.5'`); NaN (key `'NaN'`).

## 5. The #12238 `spacingMode` hunk

### 5.1 The upstream code

- `controller.polarArea.js:204-210` writes into the object of
  `this.resolveDataElementOptions(i, …)` (`:201`): `spacing` when it is `=== 0`, and `spacingMode`
  when it is `=== 'angular'`. The values come from the dataset resolver `this.options`.
- Polar area does not set `enableOptionSharing` (`controller.polarArea.js:90-95`). Thus
  `_resolveElementOptions` returns a copy of the frozen cache entry
  (`core.datasetController.js:808-811`, `:831`): the write does not meet the frozen state.
- Doughnut has the defaults `spacing: 0` and `spacingMode: 'angular'`
  (`controller.doughnut.js:72`, `:75`) and the descriptors that make both keys not scriptable and not
  indexable (`:80-83`). Doughnut has no hunk. Doughnut sets option sharing
  (`controller.doughnut.js:136`).
- The element scopes are `datasets.<type>.elements.arc`, `datasets.<type>`, `elements.arc`, `''`
  (`core.config.js:252-260`), for each of the dataset, `options`, `overrides`, `defaults` and
  `descriptors` in that order (`core.config.js:296-315`). The defaults of `elements.arc` are
  `spacing: 0` and `spacingMode: 'angular'` (`element.arc.ts:386-387`).

### 5.2 Probe

`<fid>/probe_spacing.mjs`, output `<fid>/probe_spacing.out` (the rerun `probe_spacing.rerun` is
byte-identical). Three modes for polar area: `upstream` (the build), `nohunk` (the
`updateElements` of `:161-214` without `:204-210`), `sharing` (the build with
`enableOptionSharing = true`). Each row gives `[spacing, spacingMode, frozen, $shared]` of the
three arcs:

| Config | upstream | nohunk | sharing |
|---|---|---|---|
| defaults (spec `controller.polarArea.tests.js:69`) | `[0, proportional]` | the same | `TypeError: Cannot assign to read only property 'spacing'` |
| `options: {spacing: 12, spacingMode: 'parallel'}` (spec `:85`) | `[12, parallel]` | the same | `[12, parallel]`, frozen, no write |
| dataset `{spacing: 5, spacingMode: 'parallel'}` | `[5, parallel]` | the same | `[5, parallel]`, frozen |
| `options.datasets.polarArea {spacing: 4, …}` | `[4, parallel]` | the same | the same, frozen |
| `options.elements.arc {spacing: 3, …}` | `[3, parallel]` | the same | the same, frozen |
| `options.elements.arc {spacing: 0, spacingMode: 'angular'}` | `[0, proportional]` | `[0, angular]` | `TypeError` |
| dataset `{spacingMode: 'angular'}` | `[0, angular]` | the same | `TypeError` |
| `options: {spacing: 12, elements: {arc: {spacing: 0}}}` | `[12, proportional]` | `[0, proportional]` | `TypeError` |
| `options: {spacing: 7, elements: {arc: {spacing: () => 0}}}` | `[7, proportional]` | `[0, proportional]` | `[7, proportional]`, not shared |

Findings:

- The spec cases at `controller.polarArea.tests.js:69` and `:85` and
  `controller.doughnut.tests.js:49` give the same values with and without the hunk. No polar area
  fixture sets `spacing` or `spacingMode` (`grep -rln spacing test/fixtures/controller.polarArea`
  gives nothing). The doughnut fixtures with spacing (`doughnut-spacing*.js`, `selfJoin/*`) do not
  meet the hunk.
- The hunk changes the result only when the element scopes give exactly `0` or `'angular'`: an
  explicit `options.elements.arc` value, or a scriptable element value. Then the dataset value
  wins. A port-only test needs these rows.
- With the defaults, the hunk writes `spacing = 0` into each arc options object (a write of the
  same value) at each update.
- With option sharing, the hunk throws a `TypeError` at the defaults, because the shared options
  are frozen. Polar area thus never sets sharing. A scriptable element value makes the options not
  shared (`$shared` false), and the write passes.
- Doughnut: a doughnut ignores `options.datasets.polarArea`. A function for `spacing` stays the
  function value (the probe prints `null` for it in JSON), because the doughnut descriptors make
  `spacing` not scriptable.

`<fid>/dartprobe/frozen_write.dart` (output `frozen_write.out`): `createElementOptions('arc')`
with the arc defaults, `copyOptions` of it takes a write, and after `jsObjectFreeze` a write of
`spacing` or `spacingMode` throws a `TypeError`. The Dart form thus gives the upstream throw
(Chart.js ADR 0021 §5).

### 5.3 Choice

Port `:204-210` line by line, with the upstream comment. No `DIVERGES` marker. The tests pin the
probe rows of the `upstream` and `sharing` columns.

### 5.4 Code form

```dart
// controllers/controller.polarArea.dart, controller.polarArea.js:194-212
final properties = <String, Object?>{
  'x': centerX,
  'y': centerY,
  'innerRadius': 0.0,
  'outerRadius': outerRadius,
  'startAngle': startAngle,
  'endAngle': endAngle,
  'options': resolveDataElementOptions(i, arc.active ? 'active' : mode),
};
final elementOptions = properties['options']! as AnyObject;

// Arc defaults (`spacing=0`, `spacingMode='angular'`) can mask polarArea-level values.
final spacing = elementOptions['spacing'];
if (spacing is num && spacing == 0) {          // `=== 0`, also -0
  elementOptions['spacing'] = jsGet(options, 'spacing');
}
if (elementOptions['spacingMode'] == 'angular') {
  elementOptions['spacingMode'] = jsGet(options, 'spacingMode');
}

updateElement(arc, i, properties, mode);
```

`ArcOptions` keeps `spacing` and `spacingMode` as raw `Object?` values
(`elements/element_options.dart:869-870`, `:978-981`). Thus the write takes any dataset value, for
example an array of an indexable dataset option. The `===` of a string `'0'` is false, and the
`is num` test gives the same.

## 6. The option functions of the defaults and overrides

### 6.1 The functions at the pin

- `DoughnutController.overrides.plugins.legend.labels.generateLabels(chart)`
  (`controller.doughnut.js:95-122`) and `.onClick(e, legendItem, legend)` (`:125-128`). Pie
  inherits them through the static prototype chain. The registry copies the overrides object, and
  the function stays the same (`<fid>/probe_registry.out`: `pie generateLabels === doughnut true`).
- `PolarAreaController.overrides.plugins.legend.labels.generateLabels(chart)` (`:38-62`) and
  `.onClick` (`:65-68`).
- No controller has a tooltip callback at the pin: `grep -n 'tooltip\|callbacks'
  src/controllers/*.js` gives no hit. The two spec cases "… tooltip title and label callbacks"
  (`controller.doughnut.tests.js:418`, `controller.polarArea.tests.js:389`) test the defaults of
  `plugin.tooltip` (phase 8).
- `plugin.legend.js:106` calls `call(labelOpts.generateLabels, [this.chart], this)`, and `:550`
  calls `call(opts.onClick, [e, hoveredItem, this], this)`. The controller functions do not read
  `this`.

### 6.2 Options

- **F (full bodies now).** Dart closures with the upstream bodies. They read `chart.legend`,
  `legend.chart` and `legend.options` through a new interface `types.LegendElement`
  (`index.d.ts:2414-2418`) and a new member `types.Chart.legend` (`index.d.ts:543`).
- **P (placeholders until phase 8).** A closure that throws, or no key. No key changes the keys of
  `overrides.doughnut` (the defaults inventory of `doc/upstream/manifest.json` lists
  `doughnut.plugins.legend.labels.generateLabels`, `pie.…` and `polarArea.…`). A closure that
  throws is code that phase 8 replaces.
- **D (dynamic reads).** The bodies read `chart.legend` by name. `Chart` has no access by name.

### 6.3 Choice

F. The closures are the first ported callers of `chart.legend`, `legend.chart` and
`legend.options` (Chart.js ADR 0003).

- `types.LegendElement`: `Chart get chart` (`index.d.ts:2415`) and
  `Map<String, Object?> get options` (`index.d.ts:2418`). The `Legend` class of phase 8 implements
  it.
- `types.Chart`: `LegendElement? get legend`. The concrete `Chart` gets a field
  `types.LegendElement? legend`. Dart `null` stands for JS `undefined`: the legend plugin writes it
  (`plugin.legend.js:602`) and deletes it (`:609`).
- The closure types are plain Dart function types (`lib/src/js/js_function.dart`, "The
  convention": a function that does not read `this` is a Dart `Function`):
  - `generateLabels`: `List<Object?> Function(types.Chart chart)`. Each item is a
    `Map<String, Object?>` with the keys in the order of the upstream literal. A key whose value is
    `undefined` keeps the sentinel (for example `lineJoin`).
  - `onClick`: `void Function(Object? e, Object? legendItem, types.LegendElement legend)`.
    `legendItem.index` is `jsGet(legendItem, 'index')`, given to `toggleDataVisibility` after
    `jsToNumber`.
- `jsCall` calls them in phase 8 with the argument rules of `js_function.dart`.

### 6.4 Evidence

`<fid>/probe_legend_fns.mjs`, output `<fid>/probe_legend_fns.out` (controllers, elements and
scales registered, no plugin):

- `chart.legend` is `undefined`, and `generateLabels(chart)` throws a `TypeError` for doughnut,
  pie and polarArea. The Dart form `chart.legend!.options` throws a `TypeError` too.
- With a stand-in `chart.legend = {chart, options: {labels: {…}}}`, the probe records the items:
  for doughnut and pie the keys `text, fillStyle, fontColor, hidden, lineDash, lineDashOffset,
  lineJoin, lineWidth, strokeStyle, textAlign, pointStyle, borderRadius, index`; for polarArea
  `text, fillStyle, strokeStyle, fontColor, lineWidth, pointStyle, hidden, index`. A label array
  stays an array in `text`.
- `onClick({}, {index: 1}, legend)` hides index 1: `getDataVisibility(1)` is false and
  `_hiddenIndices` is `{"1": true}`. The next `generateLabels` gives `hidden: true` for index 1.

### 6.5 Code form

```dart
// controllers/controller.doughnut.dart, controller.doughnut.js:95-128
'generateLabels': (types.Chart chart) {
  final data = chart.data;
  final labelsOptions = jsGet(chart.legend!.options, 'labels');
  final pointStyle = jsGet(labelsOptions, 'pointStyle');
  // ... textAlign, color, useBorderRadius, borderRadius
  final labels = jsGet(data, 'labels');
  if (jsTruthy(jsGet(labels, 'length')) &&
      jsTruthy(jsGet(jsGet(data, 'datasets'), 'length'))) {
    return [
      for (final (i, label) in (labels! as List<Object?>).indexed)
        _legendItem(chart, label, i.toDouble(), /* … */),
    ];
  }
  return <Object?>[];
},
// ...
'onClick': (Object? e, Object? legendItem, types.LegendElement legend) {
  legend.chart.toggleDataVisibility(jsToNumber(jsGet(legendItem, 'index')));
  legend.chart.update();
},
```

`borderRadius: useBorderRadius && (borderRadius || style.borderRadius)` keeps the operand values
of `&&` and `||` (`jsTruthy(a) ? (jsTruthy(b) ? b : c) : a`).

## 7. The registration

### 7.1 Upstream

- `src/controllers/index.js:1-8` exports the eight classes in this source order: `BarController`,
  `BubbleController`, `DoughnutController`, `LineController`, `PolarAreaController`,
  `PieController`, `RadarController`, `ScatterController`.
- `src/index.ts:1` re-exports them; `:8` imports the namespace; `:20-25` `registerables`.
- `<fid>/probe_registry.out` (rerun byte-identical): the namespace keys are in code unit order
  (`…, PieController, PolarAreaController, …`), and the namespace is frozen. After
  `Chart.register(...registerables)`, the keys of `registry.controllers.items`,
  `defaults.datasets` and `overrides` are `bar, bubble, doughnut, line, pie, polarArea, radar,
  scatter`. `PieController` extends `DoughnutController`. `ScatterController` extends
  `DatasetController` (`controller.scatter.js:6`), not `LineController`.

### 7.2 Choice

- `lib/src/controllers/index.dart`: one `export … show <Class>;` for each line of `index.js`, in
  the source order, as `scales/index.dart` does.
- `lib/src/index.dart`: `export 'package:flutter_chartjs/src/controllers/index.dart';` before the
  `core` export (`index.ts:1`). The `controllers` Map gets the eight class values in code unit
  order, as `elements` and `scales` do now (Chart.js ADR 0020 §6). `registerables` does not
  change.
- Each class value: `superclass: DatasetController.jsClass`; for pie
  `DoughnutController.jsClass`. The statics in the order of declaration (Chart.js ADR 0020 §3).

### 7.3 Code form

```dart
// lib/src/controllers/index.dart
// Ported from Chart.js v4.5.1+7169e651 src/controllers/index.js (MIT, Chart.js Contributors).
library;

export 'package:flutter_chartjs/src/controllers/controller.bar.dart' show BarController;
export 'package:flutter_chartjs/src/controllers/controller.bubble.dart' show BubbleController;
export 'package:flutter_chartjs/src/controllers/controller.doughnut.dart' show DoughnutController;
export 'package:flutter_chartjs/src/controllers/controller.line.dart' show LineController;
export 'package:flutter_chartjs/src/controllers/controller.polarArea.dart' show PolarAreaController;
export 'package:flutter_chartjs/src/controllers/controller.pie.dart' show PieController;
export 'package:flutter_chartjs/src/controllers/controller.radar.dart' show RadarController;
export 'package:flutter_chartjs/src/controllers/controller.scatter.dart' show ScatterController;

// lib/src/index.dart
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

## Open

1. **The frame figures of form T (section 3).** Phase 7 step 7 profiles the line, scatter and
   radar update and draw on the Pixel 8a and in Chrome with dart2wasm. When the `CastList` reads
   show in the profile, a new ADR measures form T against V with the stress entry (frame figures)
   and decides.
2. **The cached key of `getDataVisibility` (section 4, form IK).** It gains 8-12 ns for each call
   only when an index is hidden. A later change measures it with the stress entry after a legend
   click.

## Files that the implementation changes

- `lib/src/types/index.dart`: the 28 members of section 1.3 on the existing interfaces, and the
  new interfaces `types.RadialLinearScale` and `types.LegendElement`.
- `lib/src/core/core.controller.dart`: `@override` on `isDatasetVisible`,
  `getVisibleDatasetCount`, `toggleDataVisibility`, `update`; the field `legend`; the field
  `total` of `ChartMeta` with its `operator []` and `operator []=` cases; the early return of
  `getDataVisibility`.
- `lib/src/core/core.datasetController.dart`: the record type of `getLabelAndValue`; `@override`
  on `options`, `getParsed`, `getStyle`, `resolveDataElementOptions`; `updateElement` takes
  `types.Element`.
- `lib/src/core/core.element.dart`: `@override` on `active` and `hidden`.
- `lib/src/core/core.scale.dart`: `@override` on the 9 members.
- `lib/src/scales/scale.radialLinear.dart`: `implements types.RadialLinearScale` and 5
  `@override`.
- `lib/src/elements/element.point.dart`: `@override` on `size`.
- `lib/src/elements/element.line.dart`: `@override` on the setters `points`, `chart`,
  `datasetIndex`, the field `decimated` and `updateControlPoints`.
- `lib/src/controllers/` (new): the eight controller files and `index.dart`.
- `lib/src/index.dart`: the export and the `controllers` Map.
- `apps/chartjs_gallery/lib/demo/demo_chart.dart`: `DemoChart` gets the 5 new `types.Chart`
  members.
- `test/port/core/core.datasetController_test.dart`: `_Meta` gets `total` and `dataset_`.
- `test/port/index_test.dart`: the `controllers` namespace and the registry items.
- `doc/differences.md`: the row `adapt-line-points-elements` gets the sentence of section 3.2.
- `doc/performance.md`: the figures of sections 3 and 4.
- `doc/status.yaml`: the status text of `src/types/index.d.ts` and of `src/controllers/*`; then
  tool 6.
- `doc/adr/0028-…md` (new, proposed).

## Tests that pin the decisions

- **Section 1.** `dart analyze` (each `@override` fails when the interface and the concrete
  member differ). A port-only test `test/port/types/index_test.dart` reads each new member
  through its interface type on a real chart (`acquireChart`), for example
  `(meta.rScale as types.RadialLinearScale).xCenter` and `(chart as types.Chart).isDatasetVisible(0)`.
- **Section 2.** A port-only reference test of `getLabelAndValue` for the eight types with the
  labels `[['line 1', 'line 2'], 5, 0, 'd', undefined]`. The generator writes the values of
  `probe_label.out`, mode `raw`. The test compares the raw label with its type (List, number,
  string, `undefined`).
- **Section 3.** A port-only test of the line, scatter (`showLine: true`) and radar controllers:
  `line.points.length == meta.data.length` and `identical(line.points[i], meta.data[i])` for each
  index; after a push to the data and `controller.buildOrUpdateElements()` without an update,
  `line.points.length` is the new length (the shared array of upstream; form C fails this test).
- **Section 4.** `test/port/core/core.controller_test.dart`: `getDataVisibility` with an empty
  map, a hidden index, a `false` entry after two toggles, `1.5` and NaN.
- **Section 5.** The spec cases `controller.polarArea.tests.js:69`, `:85` and
  `controller.doughnut.tests.js:49`. A port-only reference test with the nine configs of
  `probe_spacing.mjs` (mode `upstream`), and a test that a polar area subclass with
  `enableOptionSharing = true` throws a `TypeError` at the defaults and does not throw with
  `spacing: 12`.
- **Section 6.** A port-only test calls `generateLabels` and `onClick` of the doughnut, pie and
  polarArea overrides through `jsCall`: a `TypeError` without a legend, the items of
  `probe_legend_fns.out` with a stand-in `types.LegendElement`, and the hidden index after
  `onClick`. It also checks that `overrides['pie']` and `overrides['doughnut']` hold the same
  `generateLabels` closure.
- **Section 7.** `test/port/index_test.dart`: the keys of `controllers` in code unit order, the
  Map is unmodifiable, `registerables[0]` is `same(controllers)`. After registration: the keys of
  `registry.controllers.items`, `defaults['datasets']` and `overrides` are `bar, bubble, doughnut,
  line, pie, polarArea, radar, scatter`, and `registry.controllers.items['doughnut']` is
  `DoughnutController.jsClass` (`controller.doughnut.tests.js:4-7`).

## Evidence index

| Id | File in `<fid>` | Output |
|---|---|---|
| E1.1 | `ifaceprobe/lib/probe.dart` | `ifaceprobe/analyze.out` |
| E1.2 | `bench/bench_active.dart` | `bench/aot_active_{1,2,3}.out`, `bench/wasm_active_{1,2,3}.out` |
| E2.1 | `probe_label.mjs` | `probe_label.out`, `probe_label.rerun` |
| E3.2 | `bench/bench_points.dart` | `bench/aot_points_{1..4}.out`, `bench/wasm_points_{1..4}.out` |
| E3.4 | `dartprobe/covariant_list.dart` | `dartprobe/covariant_list.out` |
| E4.2 | `bench/bench_visibility.dart` | `bench/aot_vis_{1..4}.out`, `bench/wasm_vis_{1..4}.out` |
| E5 | `probe_spacing.mjs`, `dartprobe/frozen_write.dart` | `probe_spacing.out`, `probe_spacing.rerun`, `dartprobe/frozen_write.out` |
| E6 | `probe_legend_fns.mjs` | `probe_legend_fns.out` |
| E7 | `probe_registry.mjs` | `probe_registry.out`, `probe_registry.rerun` |

The Dart benchmarks compile with
`dart compile exe --packages=<repo>/.dart_tool/package_config.json <file>` and
`dart compile wasm --packages=<repo>/.dart_tool/package_config.json <file>`. The wasm modules run
with `node run_wasm.mjs <name>` in `<fid>/bench/`. The Node.js probes run with
`/usr/bin/arch -x86_64 <env>/node-v24.12.0-darwin-x64/bin/node <probe> <env>/chartjs-build/dist/chart.js`.
