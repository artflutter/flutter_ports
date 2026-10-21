# Spec: controller interfaces and values

- Decision: [Chart.js ADR 0028](../../../adr/0028-controller-interfaces.md) (proposed). This spec
  gives the work of that ADR to the agents of the phase 7 port waves. When this spec and the ADR
  differ, the ADR wins. Report the difference to the integration agent.
- Pin: Chart.js `v4.5.1+7169e651`. "DC" is `lib/src/core/core.datasetController.dart`, "cc" is
  `lib/src/core/core.controller.dart`, "dc.js" and "cc.js" are their upstream files. `bar.js`,
  `line.js` and the other short names are the files of `third_party/Chart.js/src/controllers/`.
  `index.d.ts` is `third_party/Chart.js/src/types/index.d.ts`. The Dart line numbers refer to the
  working tree on 2026-10-21. Find each site again by its text before you change it.
- Scope: the type members that the controllers read first, the casts of the controllers, the
  label of `getLabelAndValue`, `line.points`, `getDataVisibility`, the polar area hunk of
  Chart.js #12238, the legend functions of the doughnut and polar area overrides, and the
  registration. The parsed reads and the raw option values are the work of Chart.js ADR 0027
  (`../parsed-data/spec.md`). The test files and the generators follow Chart.js ADR 0030
  (`../test-strategy/spec.md`).
- The package paths below are relative to `packages/flutter_chartjs/`.

## 0. Order of work

| Step | Work | Gate | Owner |
|---|---|---|---|
| 1 | The type members, the concrete `@override`s, the new fields, `updateElement`, the record type, the early return, the `points` setter, `getStartAndCountOfVisiblePoints`, the 9 implementers (sections 2, 3), and their tests (sections 7.1, 7.2) | `format:check`, `analyze`, `test --no-select`, `test:web`, `check:port`; all existing tests pass | the core agent, before the bar wave |
| 2 | Each controller of a wave with the forms of section 4 | `analyze`; the pin tests of section 7.3 for that controller | the wave agent of each controller |
| 3 | The registration of the controllers of a finished wave (section 5) | `test --no-select` (the changed `index_test.dart`) | the integration agent of the wave |
| 4 | The doc notes (section 8) | `check:port`, `parity:check` | the integration agent |

- Step 1 of this spec, steps 2 and 3 of the parsed-data spec and the `ctx` field of the
  test-strategy spec §1.1 all change DC. Do not run them in parallel. `../work-plan.md` gives them
  to the units S2 and S3 of wave 1, one after the other with a green gate between.
- Step 1 does not depend on any controller. Each controller wave depends on step 1.
- The wave agents do not edit `lib/src/controllers/index.dart`, `lib/src/index.dart` or
  `test/port/index_test.dart`. The integration agent of the wave does (step 3). Thus the agents of
  one wave work on disjoint files.

## 1. Files

| File | Change | Step |
|---|---|---|
| `lib/src/types/index.dart` | the members of section 2.1; the new `RadialLinearScale` and `LegendElement` | 1 |
| `lib/src/core/core.controller.dart` | `@override` on 4 `Chart` members; the field `legend`; the early return of `getDataVisibility`; `ChartMeta.total` and its by-name cases; `@override` on `ChartMeta.dataset_` | 1 |
| `lib/src/core/core.datasetController.dart` | `updateElement(types.Element ...)`; the record `({Object? label, String value})`; `@override` on `options`, `getParsed`, `getStyle`, `resolveDataElementOptions` | 1 |
| `lib/src/core/core.element.dart` | `@override` on `active` and `hidden` | 1 |
| `lib/src/core/core.scale.dart`, `lib/src/scales/*.dart` | `@override` on the 9 `types.Scale` members where a class declares them | 1 |
| `lib/src/scales/scale.radialLinear.dart` | `implements types.RadialLinearScale`; `@override` on the 5 members | 1 |
| `lib/src/elements/element.point.dart` | `@override` on `size` | 1 |
| `lib/src/elements/element.line.dart` | the `points` setter and the by-name `points` write (section 3.6); `@override` on `updateControlPoints` | 1 |
| `lib/src/helpers/helpers.extras.dart` | the parameter type of `getStartAndCountOfVisiblePoints` | 1 |
| the 9 implementers of section 3.8 | the new members | 1 |
| `test/port/types/index_test.dart` (new) | section 7.1 | 1 |
| `test/port/core/core.controller_test.dart` | groups `getDataVisibility` and `ChartMeta.total` (section 7.1) | 1 |
| `test/port/elements/element.line_test.dart` | group `adapt-line-points-elements` (section 7.2) | 1 |
| `test/port/helpers/helpers.extras_test.dart` | one case of section 7.2 | 1 |
| `lib/src/controllers/controller.<name>.dart` (8 files) | the forms of section 4 | 2 |
| `test/port/controllers/controller.<name>_test.dart` (Chart.js ADR 0030 §3) | the groups of section 7.3 | 2 |
| `tool/reference/controller_<snake>_reference.mjs` (Chart.js ADR 0030 §3) | the generated cases of section 7.5 | 2 |
| `lib/src/controllers/index.dart` (new), `lib/src/index.dart` | section 5 | 3 |
| `test/port/index_test.dart` | section 7.4 | 3 |
| `AGENTS.md`, `doc/porting-flow.md`, `doc/performance.md`, `doc/differences.md`, `doc/status.yaml` | section 8 | 4 |

## 2. `lib/src/types/index.dart` (step 1)

Add each member with a `///` line that names its upstream line and its first reader. The type
library members carry no `@internal` (Chart.js ADR 0012, type libraries).

### 2.1 Members

```dart
abstract interface class ChartMeta {
  // ... existing members ...

  /// core.controller.js:845 `_dataset`, the dataset object of the meta. The
  /// trailing underscore follows Chart.js ADR 0023. controller.line.js:43
  /// reads it.
  Object? get dataset_;

  /// index.d.ts:374 `DoughnutMetaExtensions.total`. Dart `null` stands for
  /// JS `undefined`, the value before controller.doughnut.js:235 writes it.
  abstract double? total;
}

abstract interface class Chart {
  // ... existing members ...

  /// index.d.ts:543 `readonly legend?: LegendElement`. Dart `null` stands
  /// for JS `undefined`. The legend plugin (phase 8) writes it
  /// (plugin.legend.js:602) and deletes it (:609). controller.doughnut.js:97
  /// reads it.
  LegendElement? get legend;

  /// index.d.ts:559 `update(mode?)`. controller.doughnut.js:127 calls it.
  void update([Object? mode]);

  /// index.d.ts:568 `getVisibleDatasetCount()`.
  /// controller.polarArea.js:155 calls it.
  double getVisibleDatasetCount();

  /// index.d.ts:569 `isDatasetVisible(datasetIndex)`.
  /// controller.doughnut.js:192 calls it.
  bool isDatasetVisible(double datasetIndex);

  /// index.d.ts:571 `toggleDataVisibility(index)`.
  /// controller.doughnut.js:126 calls it.
  void toggleDataVisibility(double index);
}

abstract interface class DatasetController {
  // ... existing members ...

  /// core.datasetController.js:262 `options`, the resolver of the dataset
  /// options. index.d.ts does not declare it. controller.bar.js:437 reads it.
  Map<String, Object?> get options;

  /// index.d.ts:688 `getParsed(index)`. controller.bar.js:440 calls it.
  Object? getParsed(double index);

  /// index.d.ts:656 `getStyle(index, active)`. controller.doughnut.js:101
  /// calls it.
  Map<String, Object?> getStyle(
    double? index, [
    // The upstream signature has a positional `active`.
    // ignore: avoid_positional_boolean_parameters
    bool? active,
  ]);

  /// index.d.ts:658 `resolveDataElementOptions(index, mode)`.
  /// controller.doughnut.js:354 calls it.
  Map<String, Object?> resolveDataElementOptions(double index, [String? mode]);
}

abstract interface class Scale implements Element, LayoutItem {
  // ... existing members ...
  // The 9 members of Chart.js ADR 0025 §5 without getBaseValue, in the
  // forms of the concrete Scale:
  /// core.scale.js:247 `_cache`. controller.bar.js:8 reads it.
  Map<String, Object?> get cache;
  /// index.d.ts:1321 `ticks`. controller.bar.js:47 reads it.
  List<Tick>? get ticks;
  /// index.d.ts:1346. controller.bar.js:48 calls it.
  double? getPixelForTick(int index);
  /// index.d.ts:1382. controller.bar.js:396 calls it.
  double getBasePixel();
  /// core.scale.js:237 `_startPixel`. controller.bar.js:549 reads it.
  double get startPixel;
  /// core.scale.js:239 `_endPixel`. controller.bar.js:550 reads it.
  double get endPixel;
  /// index.d.ts:1339. controller.bar.js:606 calls it.
  double getPixelForDecimal(double decimal);
  /// index.d.ts:1374. controller.bar.js:615 calls it.
  double? getValueForPixel(double pixel);
  /// index.d.ts:1357. The value is any JS value (Chart.js ADR 0025 §1).
  /// controller.bar.js:620 calls it.
  double getLineWidthForValue(Object? value);
}

/// index.d.ts:3676 `RadialLinearScale`. `RadialLinearScale` of
/// `scale.radialLinear.dart` implements it. The filler of phase 8 tests
/// `scale is RadialLinearScale` for `if (scale.getPointPositionForValue)`
/// (filler.target.js:50).
abstract interface class RadialLinearScale implements Scale {
  /// index.d.ts:3677 `xCenter`. controller.polarArea.js:167 reads it.
  double get xCenter;
  /// index.d.ts:3678 `yCenter`. controller.polarArea.js:168 reads it.
  double get yCenter;
  /// index.d.ts:3681. controller.polarArea.js:169 calls it.
  double getIndexAngle(double index);
  /// index.d.ts:3682. The value is any JS value (Chart.js ADR 0025 §1).
  /// controller.polarArea.js:182 calls it.
  double getDistanceFromCenterForValue(Object? value);
  /// index.d.ts:3685. The result is a record (Chart.js ADR 0003).
  /// controller.radar.js:88 calls it.
  ({double x, double y, double angle}) getPointPositionForValue(
    double index,
    Object? value,
  );
}

abstract interface class Element implements Point {
  // ... existing members ...

  /// core.element.ts:13 `active = false`. controller.bar.js:418 reads it.
  bool get active;

  /// The `hidden` property: core.controller.js:899 writes it,
  /// core.datasetController.js:730 reads it. core.element.ts does not
  /// declare it. Any JS value: the [undefined] sentinel in the start state.
  /// controller.bar.js:676 reads it.
  Object? get hidden;
}

abstract interface class PointElement implements Element, SplinePoint {
  // ... existing members ...

  /// element.point.ts:81 `size(options)`. controller.line.js:133 calls it.
  double size([Map<String, Object?>? options]);
}

abstract interface class LineElement implements Element {
  // ... existing members ...

  /// index.d.ts:2025 `updateControlPoints(chartArea, indexAxis)`.
  /// controller.line.js:140 calls it.
  void updateControlPoints(ChartArea chartArea, [String? indexAxis]);
}

/// index.d.ts:2414 `LegendElement`, with the members that the option
/// functions of the controllers read (controller.doughnut.js:97, :126).
/// The `Legend` class of phase 8 implements it and adds `Element` and
/// `LayoutItem`.
abstract interface class LegendElement {
  /// index.d.ts:2415 `chart`.
  Chart get chart;

  /// index.d.ts:2418 `options`, the resolver of the legend options.
  Map<String, Object?> get options;
}
```

- `types.LineElement` gets no setter. The controllers write by name (section 4.2).
- `types.DatasetController` gets no `getLabelAndValue`. Phase 8 adds it with
  `plugin.tooltip.js:130` (ADR 0028, Open 2).
- `types.Scale` gets no `getBaseValue` (phase 8, `filler.options.js:112`).
- If `ChartArea` is not visible in the type library, import it from the file that declares it
  (`lib/src/types/geometric.dart` or the existing import).

## 3. The concrete classes (step 1)

### 3.1 `core.controller.dart`: `Chart`

- `@override` on `getVisibleDatasetCount` (cc:1713), `isDatasetVisible` (cc:1718),
  `toggleDataVisibility` (cc:1744) and `update` (cc:1232, it keeps `[Object? mode = undefined]`).
- A new field after the other plugin-written fields:

```dart
  /// index.d.ts:543 `legend`: the legend element. Dart `null` stands for JS
  /// `undefined`, the start value. The legend plugin of phase 8 writes it
  /// (plugin.legend.js:602) and deletes it (:609).
  @override
  types.LegendElement? legend;
```

- `getDataVisibility` (cc:1749-1753):

```dart
  /// core.controller.js:885 `getDataVisibility(index)`.
  ///
  /// An empty `_hiddenIndices` gives `undefined` for each key, and the
  /// upstream line gives true. The early return skips the key string in that
  /// state (Chart.js ADR 0028, section 4).
  @override
  bool getDataVisibility(double index) {
    // Port-only fast path with the upstream result (Chart.js ADR 0028,
    // section 4).
    if (_hiddenIndices.isEmpty) return true;
    return !jsTruthy(_hiddenIndices[jsNumberToString(index)]);
  }
```

No `DIVERGES` marker.

### 3.2 `core.controller.dart`: `ChartMeta`

- `@override` on `dataset_` (cc:333-334). It keeps `@internal`.
- A new field:

```dart
  /// index.d.ts:374 `DoughnutMetaExtensions.total`: the total of the
  /// doughnut or pie dataset. Dart `null` stands for JS `undefined`, the
  /// start value. controller.doughnut.js:235 writes it.
  @override
  double? total;
```

- `operator []` (cc:439): add `'total' => total ?? undefined,`.
- `operator []=` (cc:487): add

```dart
      case 'total':
        total = value is Undefined ? null : (value as num?)?.toDouble();
```

  A value that is not a number throws a `TypeError`, as the other typed fields. Update the `///`
  list of the typed fields in the doc of both operators.

### 3.3 `core.datasetController.dart`

- `options` (DC:717), `getParsed` (DC:1199), `getStyle` (DC:1428) and
  `resolveDataElementOptions` (DC:1501): add `@override`. `options` is a `late` field: the
  annotation goes on the field.
- `getLabelAndValue` (DC:1334-1351): the return type becomes `({Object? label, String value})`.
  The body does not change. The doc gets:

```dart
  /// index.d.ts:641 declares a string label. The overrides of scatter,
  /// bubble, doughnut, pie, polar area and radar return the raw label of
  /// `chart.data.labels`: any value, Dart `null` for JS `null`, or the
  /// [undefined] sentinel (Chart.js ADR 0028, section 2). [value] is always
  /// a string.
```

- `updateElement` (DC:1673-1683):

```dart
  void updateElement(
    types.Element element,
    double? index,
    AnyObject properties,
    String mode,
  ) {
    if (_isDirectUpdateMode(mode)) {
      // Each data and dataset element is an Element: the casts of
      // addElements and _insertElements (row adapt-component-class-role).
      (element as Element).assign(properties);
    } else {
      resolveAnimations(index, mode).update(element, properties);
    }
  }
```

  Update its doc: `index.d.ts:674` types the parameter as `TElement | TDatasetElement`. Check
  each override of `updateElement` in `lib/`, `test/` and `apps/` (`grep -rn "void
  updateElement("`). Each override takes `types.Element`.

### 3.4 `core.element.dart`, `element.point.dart`, `element.line.dart`, the scales

- `Element.active` (`core.element.dart:208`) and `Element.hidden` (`:237`): `@override`.
- `PointElement.size` (`element.point.dart:394`): `@override`.
- `LineElement.updateControlPoints` (`element.line.dart:796`): `@override`.
- `core.scale.dart`: `@override` on `cache`, `ticks`, `getPixelForTick`, `getBasePixel`,
  `startPixel`, `endPixel`, `getPixelForDecimal`, `getValueForPixel` and
  `getLineWidthForValue`. The subclass overrides already carry `@override`.
- `scale.radialLinear.dart:731`: `class RadialLinearScale extends LinearScaleBase implements
  types.RadialLinearScale`. `@override` on `xCenter` (:826), `yCenter` (:830), `getIndexAngle`
  (:955), `getDistanceFromCenterForValue` (:967) and `getPointPositionForValue` (:1029).

### 3.5 `helpers.extras.dart`

`getStartAndCountOfVisiblePoints` (`:207-212`) takes `List<Element> points` (the type library
`Element`; the file imports `types/index.dart` without a prefix). The body reads `points.length`
and `lookupByKey(points, ...)` only. Update the `///` line: "Upstream reads the length and
`_lookupByKey` of the points. Thus the parameter takes the data elements of the meta."

### 3.6 `element.line.dart`: the `points` setter

Replace the setter at `:816-828`:

```dart
  /// element.line.js:308 `set points(points)`.
  ///
  /// Drops the segments, the path and the control points state, as
  /// `delete this._segments` and `delete this._path` do.
  ///
  /// Upstream stores any array: `index.d.ts:2026` declares `points:
  /// Point[]`, and the filler writes plain points (filler.helper.js:28-33,
  /// filler.target.stack.js:29). The port keeps a `List<types.PointElement>`:
  /// `helpers.segment` reads `skip` and `stop`, and `helpers.curve` writes
  /// the control points. A `List<types.PointElement>` stays as it is. Another
  /// list, for example the `meta.data` of a line controller, gives a typed
  /// copy with the same elements in the same order (Chart.js ADR 0028,
  /// section 3). An element that is not a `types.PointElement` throws a
  /// [TypeError] (the difference `adapt-line-points-elements`).
  // DIVERGES(chartjs): adapt-line-points-elements, point elements only.
  set points(List<types.Element> points) => _setPoints(_pointElements(points));
```

and add after `_setPoints`:

```dart
/// The points of [LineElement.points]: [points] itself when it is a
/// `List<types.PointElement>`, else a typed copy (Chart.js ADR 0028,
/// section 3). `List.generate` is the fastest copy on AOT and wasm.
List<types.PointElement> _pointElements(List<types.Element> points) =>
    points is List<types.PointElement>
    ? points
    : List<types.PointElement>.generate(
        points.length,
        (i) => points[i] as types.PointElement,
        growable: false,
      );
```

Check `growable: false` against the readers: no reader of `line.points` adds or removes an item
(`grep -n "points\.\(add\|remove\|insert\|clear\|length =\)" lib/src`). If one does, drop the
argument.

The by-name write (`operator []=`, case `'points'`, `:1152-1154`):

```dart
      case 'points':
        // DIVERGES(chartjs): adapt-line-points-elements, point elements only.
        _setPoints(
          value is List<types.Element>
              ? _pointElements(value)
              : toObjectProp<List<types.PointElement>>(prop, value),
        );
```

`toObjectProp` keeps the `undefined` case (Dart `null`) and the `ArgumentError` for another value.
The case `'_points'` does not change. Update the `///` list of `operator []=`: "`points` is the
setter [points]: it takes a `List<types.Element>` or [undefined]."

The getter stays `List<types.PointElement> get points`.

### 3.7 What does not change

- `ChartMeta.data` stays `final List<types.Element> data = []` (cc:298). `_insertElements` and
  `_hole` do not change (form T is ADR 0028 Open 1).
- `types.LineElement.points` stays a getter of `List<PointElement>`.
- No file imports `element.point.dart` for this spec.

### 3.8 The implementers

Each class gets the new members with `@override`. A fake member that no test calls throws an
`UnsupportedError`.

| Class | File | Members |
|---|---|---|
| `_Point implements PointElement` | `test/specs/helpers.segment_test.dart:12` | `bool get active => false;` `Object? get hidden => undefined;` `double size([Map<String, Object?>? options]) => throw UnsupportedError('size');` |
| `_Point` | `test/port/helpers/helpers.segment_test.dart:22` | the same |
| `_Point` | `test/port/helpers/helpers.extras_test.dart:82` | the same |
| `_Dataset implements Element` | `test/port/helpers/helpers.extras_test.dart:67` | `active`, `hidden` |
| `_Point` | `test/port/helpers/helpers.collection_test.dart:13` | the same as the first row |
| `_Point` | `tool/bench/bench_flutter_test.dart:45` | the same |
| `_PointElement` | `tool/bench/src/cases_data.dart:70` | the same |
| `_Meta implements types.ChartMeta` | `test/port/core/core.datasetController_test.dart:425` | `Object? get dataset_ => undefined;` (or the dataset that the test needs), `double? total;` |
| `DemoChart implements types.Chart` | `apps/chartjs_gallery/lib/demo/demo_chart.dart:40` | the code of the gallery spec §3.0 (Chart.js ADR 0031 §9.2): `legend` Dart `null`, `isDatasetVisible` false, `getVisibleDatasetCount` 0, `toggleDataVisibility` no action, `update` calls `render()` |

- A spec file keeps its upstream test names. The fake classes are port scaffolding. Add one
  comment line above the new members: "The members of Chart.js ADR 0028 that this test does not
  read."
- If an existing member of a fake has one of the new names, keep it and add `@override`.
- `DemoChart`: each member gets a `///` line with the upstream line, as the existing members have.
  Run the gallery tests (`flutter test` in `apps/chartjs_gallery`).
- Check again before the change: `grep -rnE "implements[^{]*\b(Element|PointElement|LineElement|Chart|ChartMeta|DatasetController|Scale)\b" packages/*/test packages/*/tool apps/*/lib apps/*/test`,
  and look for `noSuchMethod` in each class body. A new class without `noSuchMethod` gets the
  members too.

## 4. The controllers (step 2)

### 4.1 Rules for each controller

1. Read the members of other modules through `lib/src/types/`. Import no
   `core.controller.dart`, `core.scale.dart`, `core.element.dart` or element module that the
   upstream file does not import. `controller.scatter.dart` imports `core.registry.dart` (row
   `adapt-chart-registry-getter`). `controller.pie.dart` imports `controller.doughnut.dart`.
2. A cast goes only to a `types` interface or to a class of the own library or of a library that
   the upstream file imports.
3. Put a cast at the upstream read of the first member that only the subtype has. Put it earlier
   only when every path from the cast reaches that read in the same method call, and only reads
   and option resolutions lie between them. No cast in `update` for a member that upstream reads
   in `draw`.
4. Call `updateElement` with the `types.Element` of `meta.data[i]` or `meta.dataset`. No cast.
5. Call `chart.getDataVisibility(i)` through `types.Chart`. No cast.
6. The label of `getLabelAndValue` is `Object?`. The value is a `String`.

### 4.2 `line.js:41-60`, `controller.scatter.js:56-83`, `controller.radar.js:53-60`

```dart
  /// controller.line.js:41 `update(mode)`.
  @override
  void update(String mode) {
    final meta = cachedMeta;
    // `const {dataset: line, data: points = [], _dataset} = meta;`
    final line = meta.dataset;
    final points = meta.data;
    final dataset = meta.dataset_;
    final animationsDisabled = chart.animationsDisabled;
    var (:start, :count) = getStartAndCountOfVisiblePoints(
      meta,
      points,
      jsTruthy(animationsDisabled),
    );
    // ... :48-54 as upstream ...

    // Update Line. The writes of an untyped property (Chart.js ADR 0017
    // section 5, Chart.js ADR 0028 section 1).
    final access = line as types.PropertyAccess;
    access['_chart'] = chart;
    access['_datasetIndex'] = index;
    access['_decimated'] = jsTruthy(jsGetKey(dataset, '_decimated'));
    access['points'] = points;
    // ... :62-73 as upstream ...
  }
```

- `line as types.PropertyAccess` throws a `TypeError` for Dart `null`, as `undefined._chart = ...`
  does. Each element of the port is a `types.PropertyAccess` (`core.element.dart:151`).
- `access['points'] = points` goes to the setter of section 3.6: a typed copy of `meta.data`.
- `jsGetKey(dataset, '_decimated')`: the form of the parsed-data spec §5.3. `jsGetKey` gives the
  `jsGet` result for each receiver (Chart.js ADR 0027 §1), so the two specs write one line.
- Scatter (`:78-83`) and radar (`:55-60`) have the same writes. Radar has only
  `access['points'] = points` (`controller.radar.js:60`), with `final points = meta.data;` for
  `meta.data || []`.

### 4.3 `line.js:138-141` and `line.js:127-135`

```dart
  /// controller.line.js:138 `draw()`.
  @override
  void draw() {
    final meta = cachedMeta;
    // The cast stands at the upstream read of updateControlPoints (Chart.js
    // ADR 0028, section 1).
    (meta.dataset as types.LineElement).updateControlPoints(
      chart.chartArea!,
      meta.iScale!.axis,
    );
    super.draw();
  }
```

- `chart.chartArea!`: the chart draw reads `chartArea!` already (cc:1542). The reviewer of the
  line wave checks a chart whose plugin returns `false` to `beforeLayout` at the first update.
  Upstream then passes `undefined` and throws only with a tension and `capBezierPoints`. Report a
  difference to the integration agent.
- `getMaxOverflow` (`line.js:127-135`): `(data[0] as types.PointElement).size(
  resolveDataElementOptions(0))` and the same for the last item. Bubble `:88` and scatter
  `:158-163` have the same form.

### 4.4 `controller.doughnut.dart`

- `_getRotationExtents` (`:187-203`):

```dart
    for (var i = 0; i < datasets.length; ++i) {
      if (chart.isDatasetVisible(i.toDouble()) &&
          chart.getDatasetMeta(i.toDouble()).type == type) {
        // The own class: _getRotation and _getCircumference are private
        // members of this library (Chart.js ADR 0028, section 1).
        final controller =
            chart.getDatasetMeta(i.toDouble()).controller! as DoughnutController;
        final rotation = controller._getRotation();
        final circumference = controller._getCircumference();
        // ...
      }
    }
```

- `:235`: `meta.total = calculateTotal();` through `types.ChartMeta.total`.
- `calculateCircumference` (`:312-318`): `final total = cachedMeta.total;` and
  `if (total != null && total > 0 && ...)`. Dart `null` is the `undefined` of `total > 0`.
- `:101`, `:354`: `meta.controller!.getStyle(i)` and `controller.resolveDataElementOptions(i)`
  through `types.DatasetController`.
- `getLabelAndValue` (`:320-330`):

```dart
  /// controller.doughnut.js:320 `getLabelAndValue(index)`.
  @override
  ({Object? label, String value}) getLabelAndValue(double index) {
    final meta = cachedMeta;
    final chart = this.chart;
    // `chart.data.labels || []`
    final labelsValue = chart.data['labels'];
    final labels = jsTruthy(labelsValue) ? labelsValue : const <Object?>[];
    final value = formatNumber(
      /* meta._parsed[index]: the read of Chart.js ADR 0027 */,
      jsGet(chart.options, 'locale'),
    );
    // `labels[index] || ''`
    final label = jsGetIndex(labels, index);
    return (label: jsTruthy(label) ? label : '', value: value);
  }
```

  Scatter (`:42-54`), bubble (`:96-109`) and polar area (`:97-107`) have the same label lines.

### 4.5 `controller.polarArea.dart`

- `updateElements` (`:161-169`): one cast at `:166`. Every path reaches `getIndexAngle` at `:169`:

```dart
    // `const scale = this._cachedMeta.rScale;` The cast stands for the reads
    // of :167-169 (Chart.js ADR 0028, section 1).
    final scale = cachedMeta.rScale as types.RadialLinearScale;
    final centerX = scale.xCenter;
    final centerY = scale.yCenter;
    final datasetStartAngle = scale.getIndexAngle(0) - 0.5 * pi;
```

- The hunk (`:194-212`):

```dart
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
      final elementOptions = properties['options']! as AnyObject;
      if (elementOptions['spacing'] == 0) {
        elementOptions['spacing'] = jsGet(options, 'spacing');
      }
      if (elementOptions['spacingMode'] == 'angular') {
        elementOptions['spacingMode'] = jsGet(options, 'spacingMode');
      }

      updateElement(arc, i, properties, mode);
```

  - No marker. `== 0` is `=== 0` here (ADR 0028 §5). Do not add `is num`.
  - Do not set `enableOptionSharing` (`:90-95`).
  - `:155`: `chart.getVisibleDatasetCount()` through `types.Chart`.
- `getLabelAndValue` (`:97-107`): the form of section 4.4 with the parsed read
  `meta._parsed[index].r` of Chart.js ADR 0027.

### 4.6 `controller.radar.dart`

- `getLabelAndValue` (`:39-47`):

```dart
  /// controller.radar.js:39 `getLabelAndValue(index)`.
  @override
  ({Object? label, String value}) getLabelAndValue(double index) {
    final vScale = cachedMeta.vScale!;
    final parsed = getParsed(index);
    return (
      // No `|| ''`: past the end gives undefined.
      label: jsGetIndex(vScale.getLabels(), index),
      value: jsToString(
        vScale.getLabelForValue(/* parsed[vScale.axis], Chart.js ADR 0027 */),
      ),
    );
  }
```

- `updateElements` (`:81-103`): `final scale = cachedMeta.rScale;` stays a `types.Scale?`. The
  cast stands in the loop at `:88`:

```dart
      final radial = scale as types.RadialLinearScale;
      final pointPosition = radial.getPointPositionForValue(
        i.toDouble(),
        /* this.getParsed(i).r, Chart.js ADR 0027 */,
      );
      final x = reset ? radial.xCenter : pointPosition.x;
      final y = reset ? radial.yCenter : pointPosition.y;
```

  Place the cast after the `resolveDataElementOptions` of `:86`, as upstream reads the member
  after it. A radar update with no point throws nothing.

### 4.7 The legend functions (`controller.doughnut.js:90-128`, `controller.polarArea.js:34-68`)

Each file declares two private top-level functions. The static `overrides` Map holds their
tear-offs:

```dart
      'plugins': <String, Object?>{
        'legend': <String, Object?>{
          'labels': <String, Object?>{'generateLabels': _generateLabels},
          'onClick': _onClick,
        },
      },
```

Doughnut:

```dart
/// controller.doughnut.js:95 `generateLabels(chart)` of
/// `overrides.plugins.legend.labels` (Chart.js ADR 0028, section 6).
List<Object?> _generateLabels(types.Chart chart) {
  final data = chart.data;
  // `const {labels: {pointStyle, textAlign, color, useBorderRadius,
  // borderRadius}} = chart.legend.options;` A Dart null legend throws a
  // TypeError, as `undefined.options` does.
  final labelsOptions = jsGet(chart.legend!.options, 'labels');
  final pointStyle = jsGet(labelsOptions, 'pointStyle');
  final textAlign = jsGet(labelsOptions, 'textAlign');
  final color = jsGet(labelsOptions, 'color');
  final useBorderRadius = jsGet(labelsOptions, 'useBorderRadius');
  final borderRadius = jsGet(labelsOptions, 'borderRadius');
  final labels = jsGet(data, 'labels');
  if (jsTruthy(jsGet(labels, 'length')) &&
      jsTruthy(jsGet(jsGet(data, 'datasets'), 'length'))) {
    return [
      for (final (i, label) in (labels! as List<Object?>).indexed)
        _item(chart, label, i.toDouble(), pointStyle, textAlign, color,
            useBorderRadius, borderRadius),
    ];
  }
  return <Object?>[];
}

/// The callback of `data.labels.map` (controller.doughnut.js:99-119).
Map<String, Object?> _item(types.Chart chart, Object? label, double i, ...) {
  final meta = chart.getDatasetMeta(0);
  final style = meta.controller!.getStyle(i);
  return <String, Object?>{
    'text': label,
    'fillStyle': jsGet(style, 'backgroundColor'),
    'fontColor': color,
    'hidden': !chart.getDataVisibility(i),
    'lineDash': jsGet(style, 'borderDash'),
    'lineDashOffset': jsGet(style, 'borderDashOffset'),
    'lineJoin': jsGet(style, 'borderJoinStyle'),
    'lineWidth': jsGet(style, 'borderWidth'),
    'strokeStyle': jsGet(style, 'borderColor'),
    'textAlign': textAlign,
    'pointStyle': pointStyle,
    // `useBorderRadius && (borderRadius || style.borderRadius)`
    'borderRadius': jsTruthy(useBorderRadius)
        ? (jsTruthy(borderRadius) ? borderRadius : jsGet(style, 'borderRadius'))
        : useBorderRadius,
    // Extra data used for toggling the correct item
    'index': i,
  };
}

/// controller.doughnut.js:125 `onClick(e, legendItem, legend)`.
void _onClick(Object? e, Object? legendItem, types.LegendElement legend) {
  legend.chart.toggleDataVisibility(jsToNumber(jsGet(legendItem, 'index')));
  legend.chart.update();
}
```

- The `_item` helper has the parameters that the map callback reads. Name it after the upstream
  form; a local function inside `_generateLabels` is also correct.
- Polar area: the same, with the read of `chart.legend.options` inside the `if` (`:41`), the
  keys `text, fillStyle, strokeStyle, fontColor, lineWidth, pointStyle, hidden, index` in that
  order (`:47-58`), and no `textAlign` or `borderRadius`.
- The key order of each item is the order of the upstream literal.
- The functions read `jsGet(style, key)`, not `style[key]`: an absent key gives `undefined`
  (`lineJoin` in the probe).
- `'index': i` is a `double` (Chart.js ADR 0010).
- Pie inherits the doughnut functions through the class chain. Do not copy them into
  `controller.pie.dart`.

The doughnut descriptors (`:80-83`), as `core.defaults.dart:462-463`:

```dart
    '_scriptable': (String name) => name != 'spacing' && name != 'spacingMode',
    '_indexable': (String name) =>
        name != 'spacing' &&
        name != 'spacingMode' &&
        !name.startsWith('borderDash') &&
        !name.startsWith('hoverBorderDash'),
```

### 4.8 Review checklist of each wave

- [ ] No import of `core.controller.dart`, `core.scale.dart`, `core.element.dart` or
  `elements/*.dart` in `lib/src/controllers/` (`grep -n "^import" lib/src/controllers/*.dart`).
- [ ] Each `as` names a `types.` interface or `DoughnutController`
  (`grep -n " as " lib/src/controllers/*.dart`). A cast of a parsed item follows Chart.js ADR 0027.
- [ ] No cast in `update` for a member that upstream reads only in `draw`.
- [ ] No `(chart as Chart)`, no `.cast<`, no `List.of(` of `meta.data`.
- [ ] Each `getLabelAndValue` returns `({Object? label, String value})`; no `jsToString` on the
  label of scatter, bubble, doughnut, pie, polar area or radar.
- [ ] The polar area hunk is the upstream lines with `== 0` and `== 'angular'`.
- [ ] `overrides` holds tear-offs of top-level functions, not closures.

## 5. Registration (step 3)

### 5.1 `lib/src/controllers/index.dart` (new)

The final content, after the last wave. The integration agent of each wave adds the lines of the
controllers of that wave.

```dart
// Ported from Chart.js v4.5.1+7169e651 src/controllers/index.js (MIT, Chart.js Contributors).

/// Port of `src/controllers/index.js`: the controller classes that upstream
/// exports as `Chart.controllers`.
///
/// - index.js:1 `export {default as BarController} from
///   './controller.bar.js'`
/// - index.js:2 `export {default as BubbleController} from
///   './controller.bubble.js'`
/// - index.js:3 `export {default as DoughnutController} from
///   './controller.doughnut.js'`
/// - index.js:4 `export {default as LineController} from
///   './controller.line.js'`
/// - index.js:5 `export {default as PolarAreaController} from
///   './controller.polarArea.js'`
/// - index.js:6 `export {default as PieController} from
///   './controller.pie.js'`
/// - index.js:7 `export {default as RadarController} from
///   './controller.radar.js'`
/// - index.js:8 `export {default as ScatterController} from
///   './controller.scatter.js'`
///
/// Each line exports only the default export of its module. The `export`
/// directives below are in code unit order, as the lint
/// `directives_ordering` asks (Chart.js ADR 0028, section 7).
///
/// This library is not a pure layer: each controller module imports
/// `core.datasetController`, which imports `core.animations`.
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

Run `dart format`. The formatter decides the line breaks.

### 5.2 `lib/src/index.dart`

- Add `export 'package:flutter_chartjs/src/controllers/index.dart';` before the `core` export
  (`index.ts:1`).
- Add an `import` of each controller file, as for the elements and the scales.
- The `controllers` Map (`:49`), final content:

```dart
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

- Update the `///` lines of the Map: the controllers come in phase 7; the keys are in code unit
  order (Chart.js ADR 0020 §6).
- `registerables` does not change.
- `PieController` comes after `DoughnutController` in the waves. `TypedRegistry.register`
  registers the parent class first in any case (`core.typedRegistry.js:28-31`).

### 5.3 The ids

`flutter_test_config.dart` registers the namespace before `main()` of each test file. A test
controller with the id of a built-in controller is ignored (`core.typedRegistry.js:41-44`). Check
the ids of the test and gallery controllers before the first registration:
`grep -rnE "'id': '(bar|bubble|doughnut|line|pie|polarArea|radar|scatter)'" test apps/chartjs_gallery/lib`
(run from the repository root for `apps/`). On 2026-10-21 no test or gallery controller uses one
of these ids. A hit gets another id in the same change.

## 6. `DIVERGES` rows

- New rows: none. New markers: none. New skip reasons: none.
- The marker `// DIVERGES(chartjs): adapt-line-points-elements, point elements only.` stays at the
  setter and at the by-name case `'points'` of `element.line.dart`.
- Row text change: section 8.4.

## 7. Tests

### 7.1 Types and core (step 1)

`test/port/types/index_test.dart` (new, `@TestOn('vm')`, `flutter_test`,
`package:chartjs_test_utils/flutter.dart`; header `// Original code, not ported from Chart.js:
the type members of Chart.js ADR 0028.`):
- a `testWidgets` case for each interface. It acquires a real chart (bar with a category and a
  linear scale; polar area with a radial linear scale, after the polar area wave; before it, a
  chart with the `RadialTestController` of `scale_chart_harness.dart`). It reads each new member
  through a variable of the interface type and compares it with the concrete member:
  `types.Chart`: `isDatasetVisible(0)`, `getVisibleDatasetCount()`, `legend` (Dart `null`),
  `toggleDataVisibility(1)` then `getDataVisibility(1)` false, `update()`;
  `types.ChartMeta`: `dataset_` is `identical` to the dataset Map, `total` Dart `null` before a
  doughnut update; `types.DatasetController`: `options`, `getParsed(0)`, `getStyle(0)`,
  `resolveDataElementOptions(0)`; `types.Element`: `active` false, `hidden` `undefined`;
  `types.Scale`: the 9 members; `types.RadialLinearScale`: the 5 members, and
  `chart.scales['r'] is types.RadialLinearScale`.
- The analyzer is the compile-time check of the signatures: each `@override` fails when the
  interface and the concrete member differ.

`test/port/core/core.controller_test.dart`, group `getDataVisibility` (`testWidgets`):
- a chart with no hidden index: `true` for 0, 1, 1.5, -1, -0.0, NaN, infinity and 1e21;
- `toggleDataVisibility(3)`: `getDataVisibility(3)` false, the other indices true;
- a second `toggleDataVisibility(3)`: `true` (the Map holds `'3': false` and is not empty);
- `toggleDataVisibility(1.5)`: `getDataVisibility(1.5)` false, `getDataVisibility(1)` true;
- `toggleDataVisibility(double.nan)`: `getDataVisibility(double.nan)` false, each data index true;
- the moves of `_updateHiddenIndices`: the cases of `core.controller.tests.js:2100-2140` give the
  same results (a pin of the slow path after the early return).

`test/port/core/core.controller_test.dart`, group `ChartMeta.total`: a meta of a chart without a
doughnut gives `total` Dart `null` and `meta['total']` `undefined`; `meta['total'] = 5` gives
`total` 5.0; `meta['total'] = undefined` gives `null`; `meta['total'] = 'a'` throws a
`TypeError`.

### 7.2 `line.points` (step 1)

`test/port/elements/element.line_test.dart`, group `adapt-line-points-elements` (pure,
`package:test`):
- a `List<types.PointElement>`: `identical(line.points, list)` after the setter and after
  `line['points'] = list`;
- a `List<types.Element>` of 3 point elements: `line.points` is a `List<types.PointElement>` with
  `identical` items in the same order; `identical(line.points, list)` is false; the setter drops
  the segments and the path (the existing assertions of the setter);
- a `List<types.Element>` with a plain `Element`: a `TypeError`, by the setter and by name;
- `line['points'] = undefined`: the `undefined` state, as today; `line['points'] = 5`: the
  `ArgumentError`, as today.

`test/port/helpers/helpers.extras_test.dart`: `getStartAndCountOfVisiblePoints` with a
`List<types.Element>` gives the result of the same items in a `List<types.PointElement>`.

### 7.3 Controller pin tests (step 2)

`test/port/controllers/controller.<name>_test.dart` (`testWidgets`, `@TestOn('vm')`,
`acquireChart`). The values come from the probes of ADR 0028 (Evidence) or from the generator
(section 7.5).

| Controller | Group, case | Expected | Source |
|---|---|---|---|
| line, scatter (`showLine: true`), radar | `line.points`: after `chart.update()` | `line.points.length == meta.data.length`, `identical(line.points[i], meta.data[i])` for each `i` | ADR 0028 §3 |
| line, scatter, radar | the same after `data.push` and `chart.update()`; after a `splice` and an update | the same, with the new length and the order of `meta.data` | ADR 0028 §3 |
| line | a dataset element of another class (`datasetElementType` set to a class value of a test element) | `update` writes `_chart`, `_datasetIndex`, `_decimated`, `points` by name and does not throw; the draw throws a `TypeError` | `line.js:57-73`, `:140`; a generator case confirms it first |
| radar | an rScale that is not radial, no data | `update` does not throw | `controller.radar.js:81-88`; a generator case confirms it first |
| polarArea | an rScale that is not radial, with data | a `TypeError` in `update` | `controller.polarArea.js:166-169`; a generator case confirms it first |
| doughnut | `meta.total` after an update | `calculateTotal()`; `meta['total']` gives the same value | ADR 0028 §1 |
| doughnut, pie | two doughnut datasets with other `rotation` and `circumference` | the rotation extents of the generator | `_getRotationExtents` |
| scatter, bubble, doughnut, pie, polarArea | `getLabelAndValue`: labels `[['line 1', 'line 2'], 5, 0, 'd', undefined]` and `[['line 1', 'line 2'], 7, '', null, 'e']` with one more data item | label 0 is the identical `List`; label `5` and `7` are numbers; `0`, `''`, `null`, `undefined` and past the end give `''`; `'d'`, `'e'` | F `probe_label.out`, P `probe/probe_label.out` |
| radar | the same labels | `0` (number), `null` (Dart `null`), past the end `undefined` | the same |
| bar, line | the same labels | a `String`: `'line 1,line 2'`, `'5'`, `'undefined'` | the same |
| polarArea | `spacingMode hunk`: the 11 rows of the ADR 0028 table (Measurements, question 5), column `upstream` | `spacing` and `spacingMode` of each arc after a second `update()` | S `probe_spacing.out`, F `probe_spacing.out` |
| polarArea | the hover row: `elements.arc.spacingMode: 'angular'`, `setActiveElements` on arc 0, `update()` | arc 0 `spacingMode` `'angular'`, `spacing` 0 | S `probe_spacing.out` |
| polarArea | a subclass with `enableOptionSharing = true` (a class value with `superclass: PolarAreaController.jsClass`, its own id, registered in the test and unregistered at its end) | a `TypeError` in `update` for the rows that throw in column `sharing`; the other rows give the values and frozen options | the same |
| polarArea | the element options after `update` | not frozen (`jsObjectIsFrozen` false) | P `probe_spacing.out` |
| doughnut, pie, polarArea | `legend overrides`: `jsCall` of `generateLabels` with the chart and no legend | a `TypeError` (doughnut and pie); polar area without labels gives `[]` | F `probe_legend_fns.out` |
| doughnut, pie, polarArea | `generateLabels` with a test `types.LegendElement` (`chart`, `options: {labels: {pointStyle: 'circle', textAlign: 'left', color: '#666', useBorderRadius: true, borderRadius: 0}}`), data `labels: ['a', ['b1', 'b2'], 'c']`, `data: [1, 2, 3]`, `backgroundColor: ['red', 'green', 'blue']`, `borderRadius: 3` | the items of `probe_legend_fns.out`, with the keys in order (`jsObjectKeys`) and `lineJoin` `undefined` | the same |
| doughnut, pie, polarArea | `jsCall` of `onClick` with `({}, {'index': 1.0}, legend)` | `getDataVisibility(1)` false; the next `generateLabels` gives `hidden` true for index 1 only; `update` ran once (a recording plugin hook or the chart state) | the same |
| doughnut, pie | the option value | `identical` function in `overrides['doughnut']` and `overrides['pie']`, and in two reads | ADR 0028 §6 |

The spec cases `controller.polarArea.tests.js:69`, `:85` and `controller.doughnut.tests.js:49`
port with their bodies in the spec files of the test-strategy spec. They are not repeated here.

### 7.4 `test/port/index_test.dart` (step 3)

After each wave, for the registered controllers:
- the keys of `controllers` in code unit order; each value `same` the `jsClass`; the Map
  unmodifiable;
- `registerables[0]` is `same(controllers)` (no change);
- after `Registry()..add(registerables)`: the keys of `registry.controllers.items`, of
  `defaults['datasets']` and of `overrides` in the order `bar, bubble, doughnut, line, pie,
  polarArea, radar, scatter` (the registered subset);
- `registry.controllers.items['doughnut']` is `DoughnutController.jsClass`
  (`controller.doughnut.tests.js:4-7`);
- the test "the namespaces of later phases are empty" keeps only `plugins`.

### 7.5 The generator

The cases of section 7.3 that need generated values (the rotation extents, the legend items, the
spacing rows) go into the generator of their controller,
`tool/reference/controller_<snake>_reference.mjs` of Chart.js ADR 0030 §3 (`<snake>` is
`polar_area` for `polarArea`). Each case has a name that starts with `interfaces:`. A row "a
generator case confirms it first" records the key `error` (`{at, name}`) of Chart.js ADR 0030 §4.
The legend items and the rotation extents are probes of the key `extra`. The themed run of the
test file does not run these cases. The probe outputs of
the Evidence of ADR 0028 are the check values: a generated value that differs from the probe
output goes to the integration agent. Do not edit the generated files by hand.

## 8. Doc notes for the integration agent (step 4)

### 8.1 `AGENTS.md`

- The `doc/adr/` item: add 0028 (controller interfaces and values) to the proposed list.
- Layout, `lib/src/controllers/` (with the notes of the other specs): "A controller reads the
  members of other modules through `lib/src/types/` (Chart.js ADR 0028). It casts only to a
  `types` interface or to a class of its own library, at the upstream read. The line writes of
  `controller.line.js:57-60` are writes by name. `getLabelAndValue` gives
  `({Object? label, String value})`."
- `lib/src/types/`: "`RadialLinearScale` and `LegendElement` (Chart.js ADR 0028)."
- `element.line.dart`: "The `points` setter takes `List<types.Element>` and copies a list that is
  not a `List<types.PointElement>` (Chart.js ADR 0028)."
- `core.controller.dart`: "`getDataVisibility` returns `true` at once for an empty
  `_hiddenIndices`. `ChartMeta.total` is a typed field."

### 8.2 `doc/porting-flow.md`

- §2: a row for Chart.js ADR 0028 in the table of decisions, and the section "§2.21 Chart.js ADR
  0028: Controller interfaces and values (gate 7)" with a summary of sections 1-7 in the form of
  §2.19 (the numbers of `../work-plan.md`, "Doc numbering").

### 8.3 `doc/performance.md`

In the section of phase 7 (create "13. Controllers (phase 7)" if no other spec made it):
- "13.2 The interfaces and values (Chart.js ADR 0028)": the bed, the table of question 3 (judge
  run), the `points_copy` table of the copy forms, the table of question 4 with the P-B7 figures
  of Chart.js ADR 0027 (Evidence E3), and the figures of question 1 (the interface call, the
  by-name writes, `total`).
- §11.3: one line that points to it ("`getDataVisibility`: the early return of Chart.js ADR 0028
  §4; ADR 0025 Open 4 is closed").
- The open list of that section: ADR 0028 Open 1 (form T and the bar record).

### 8.4 `doc/differences.md`

Row `adapt-line-points-elements`:
- Column "Dart file and symbol": add `lib/src/helpers/helpers.extras.dart`
  `getStartAndCountOfVisiblePoints` (it takes `List<types.Element>`).
- Column "Reason", after "Upstream accepts such a list.": "The setter and the write by name copy a
  `List<types.Element>` of point elements into a `List<types.PointElement>` (Chart.js ADR 0028).
  Thus `line.points` and `meta.data` of a line controller are two lists with the same elements in
  the same order, where upstream shares one array. No reader at the pin sees the difference
  between `buildOrUpdateElements` and the controller `update` of one `chart.update()`; only a user
  plugin hook `afterLayout` can. An element that is not a `types.PointElement` throws a
  `TypeError` at the copy."
- Column "Pinning test": add `test/port/controllers/controller.line_test.dart`, group
  `line.points`.
- Column "Re-check on bump": keep; it already names the dataset controllers.

### 8.5 `doc/status.yaml`

- `src/types/index.d.ts`: replace "`lib/src/types` gets no member: ..." with the members of phase
  7: "Phase 7 adds the members that the controllers read first, `RadialLinearScale` and a minimal
  `LegendElement` (Chart.js ADR 0028, proposed)." Keep the text on `spacingMode` and the other
  keys.
- `src/core/core.controller.js`: one sentence: "`getDataVisibility` has a port-only early return
  for an empty `_hiddenIndices`; `ChartMeta.total` is a typed field (Chart.js ADR 0028)."
- `src/core/core.datasetController.js`: one sentence: "`updateElement` takes a `types.Element`,
  and `getLabelAndValue` gives an `Object?` label (Chart.js ADR 0028)."
- `src/elements/element.line.js`: one sentence on the copy of the `points` setter.
- `src/index.ts` and `src/controllers/index.js`: the `controllers` namespace and the exports.
- Each controller row gets its status from its wave. Run `dart run melos run parity`.

### 8.6 `doc/upstream-ledger.md`

Row `ab79c3bf` (#12238): the integration agent of wave 2 adds that `controller.doughnut` and
`controller.polarArea` port the controller part at the pin: the defaults, the descriptors and the
hunk of `controller.polarArea.js:204-210` (Chart.js ADR 0028 §5). The fixtures of the row come
with the fixture runner (fixture spec §8.5).

## 9. Not in this spec

- The parsed reads, `jsGetIndex` and the raw option values (Chart.js ADR 0027).
- Form T, the typed `meta.data` (ADR 0028 Open 1): no agent of a port wave does it.
- The members of phase 8: `getLabelAndValue` on `types.DatasetController`, `getBaseValue` on
  `types.Scale`, `Legend implements types.LegendElement`, the writes of `chart.legend` (ADR 0028
  Open 2).
- The ported spec cases and the lift of the skips (the test-strategy spec).
