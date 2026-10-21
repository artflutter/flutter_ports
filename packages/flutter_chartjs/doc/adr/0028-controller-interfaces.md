# Chart.js ADR 0028: Controller interfaces and values

- Status: accepted (2026-10-21)
- Date: 2026-10-21
- Related: [Chart.js ADR 0003](0003-type-only-dependencies.md) (type libraries, a member with its
  first ported caller, records for inline object types),
  [Chart.js ADR 0006](0006-options-representation-and-resolver.md) (the `undefined` sentinel,
  function values),
  [Chart.js ADR 0009](0009-no-display-only-js-exactness.md) (the protected behavior),
  [Chart.js ADR 0012](0012-dart-file-naming.md) (underscore members, type libraries),
  [Chart.js ADR 0017](0017-element-properties.md) §5 and §8 (the write by name, option reads),
  [Chart.js ADR 0020](0020-registry-and-component-classes.md) §3, §6 and §13 (class values, the
  namespaces, a gain that only a microbenchmark measures),
  [Chart.js ADR 0021](0021-typed-options-in-the-resolver.md) §5 (frozen options),
  [Chart.js ADR 0023](0023-underscore-member-collisions.md) (`dataset_`),
  [Chart.js ADR 0025](0025-scale-value-parameters.md) §3, §4, §5 and Open 4 (fast paths, the
  interface members of phases 6 and 7, `getDataVisibility`),
  [Chart.js ADR 0027](0027-parsed-data.md) §3 (`jsGetIndex`),
  [Chart.js ADR 0030](0030-controller-test-strategy.md) §3 and §4 (the test files of the
  controllers, the `error` and `extra` keys of a reference case),
  [Chart.js ADR 0031](0031-gallery-chart-types.md) §9 (`DemoChart`),
  [Chart.js ADR 0033](0033-radial-scale-centers.md) (the radial scale centers),
  [porting-flow.md](../porting-flow.md) §1.1 (the performance rule),
  [performance.md](../performance.md) §10.7 and §11.3,
  [differences.md](../differences.md) rows `adapt-line-points-elements`,
  `adapt-component-class-role` and `adapt-chart-registry-getter`,
  [phase7/design/interfaces-values/judge.md](../../../../.handover/phase7/design/interfaces-values/judge.md) (the
  panel result)

## Context

Phase 7 ports the eight controllers of `src/controllers/` and `src/controllers/index.js`. A
controller reads members of the chart, the meta, the scales, the elements and the controllers of
other datasets. In the port, these objects have the types of `lib/src/types/index.dart`
(Chart.js ADR 0003). Chart.js ADR 0025 §5 fixes the Dart forms of the nine `types.Scale` members
and of `types.RadialLinearScale` of phase 7. It leaves the other interfaces, the values and
`getDataVisibility` (its Open 4) to phase 7.

The panel had seven questions:
1. The interface members that a controller reads first, and the casts that a controller can use.
2. The type of the label of `getLabelAndValue`.
3. `meta.data` and `line.points`: one shared array upstream, two Dart list types.
4. `getDataVisibility`: an interface call or a cast, and the key string.
5. The `spacing` and `spacingMode` hunk of polar area (Chart.js #12238).
6. The option functions of `defaults` and `overrides` that phase 8 calls.
7. The registration: `controllers/index.dart` and the `controllers` namespace.

The upstream lines refer to Chart.js `v4.5.1+7169e651` (`third_party/Chart.js` at `7169e65`),
checked for this ADR. `index.d.ts` is `src/types/index.d.ts`. Its line numbers differ from the
numbers in Chart.js ADR 0025, which cites v4.5.1. `bar.js`, `line.js` and the other short names
are the files of `src/controllers/`. "DC" is `lib/src/core/core.datasetController.dart`, "cc" is
`lib/src/core/core.controller.dart`, and "dc.js" and "cc.js" are their upstream files. The Dart
line numbers refer to the working tree on 2026-10-21.

### Upstream facts

- Each controller imports only `DatasetController` and helpers. It reads the members of other
  modules on the objects that it has, with no type.
- `line.js:43` takes `data: points` from the meta. `:57-60` write `line._chart`,
  `line._datasetIndex`, `line._decimated` and `line.points = points` in `update`. `:140` calls
  `meta.dataset.updateControlPoints(...)` in `draw`. `controller.scatter.js:80-83` and
  `controller.radar.js:60` have the same writes. Thus the meta and the line share one array.
- A dataset element without the line API takes the four writes upstream. The first throw comes in
  `draw` (`line.js:140`), which runs in an animation frame, not in `update`.
- The readers of `line.points` at the pin (`element.line.js`, `helpers.segment.js`, the filler)
  read the items and the length. No spec reads its identity: `grep` over `test/specs/*.js` finds
  `element.line.tests.js:11` only, a line without a meta.
- `getLabelAndValue`: `index.d.ts:641` declares `{label: string; value: string}`. The base
  (dc.js:687-697) and `bar.js:364-376` return a string label. `controller.scatter.js:51`,
  `controller.bubble.js:106`, `controller.doughnut.js:327` and `controller.polarArea.js:104`
  return `labels[index] || ''`. `controller.radar.js:44` returns `vScale.getLabels()[index]`, also
  `undefined` past the end. The value is a string in each form. The first reader through an
  interface is `plugin.tooltip.js:130` (phase 8).
- `getDataVisibility` (cc.js:885-887) is `return !this._hiddenIndices[index];`. Only
  `toggleDataVisibility` (cc.js:881-883) and `_updateHiddenIndices` (cc.js:568-575, through
  `moveNumericKeys`, cc.js:72-84) write `_hiddenIndices`. No spec reads the object. The
  controllers call `getDataVisibility` for each element: `bar.js:592`;
  `controller.doughnut.js:250`, `:304`; `controller.polarArea.js:130`, `:182`, `:221`, `:233`.
- `controller.polarArea.js:204-210` writes `this.options.spacing` into the element options when
  their `spacing` is `=== 0`, and `this.options.spacingMode` when their `spacingMode` is
  `=== 'angular'`. Polar area never sets `enableOptionSharing` (`:90-95`). Thus the options object
  is not frozen (dc.js:804-833). The doughnut sets it (`controller.doughnut.js:136`) and has no
  hunk.
- `controller.doughnut.js:95-122` and `controller.polarArea.js:38-62` define
  `overrides.plugins.legend.labels.generateLabels(chart)`. `controller.doughnut.js:125-128` and
  `controller.polarArea.js:65-68` define `overrides.plugins.legend.onClick(e, legendItem,
  legend)`. Doughnut reads `chart.legend.options` at `:97`, before its test of the labels.
  Polar area reads it at `:41`, inside the test. `chart.legend` is `readonly legend?:
  LegendElement` (`index.d.ts:543`). No controller has a tooltip callback at the pin
  (`grep -n "tooltip\|callbacks" src/controllers/*.js` gives no line).
- `controller.doughnut.js:80-83` gives the descriptors `_scriptable` and `_indexable`.
- `src/controllers/index.js:1-8` exports the eight classes in the source order Bar, Bubble,
  Doughnut, Line, PolarArea, Pie, Radar, Scatter. The bundle namespace has the keys in code unit
  order (Chart.js ADR 0020 §6).

### The port today

- `types.Chart` (`lib/src/types/index.dart:263`) has `getDataVisibility` (Chart.js ADR 0025 §4)
  and no member for the other chart reads of the controllers. `types.ChartMeta` (:78) has no
  `dataset_` and no `total`. `types.DatasetController` (:427) has no `options`, `getParsed`,
  `getStyle` or `resolveDataElementOptions`. `types.Element` (:979) has no `active` and no
  `hidden`. `types.LineElement` (:854) has getters only. `types.PointElement` (:1008) has no
  `size`.
- `ChartMeta.data` is `final List<types.Element> data = []` (cc:298). `LineElement.points` takes
  and gives a `List<types.PointElement>` (`element.line.dart:828`, `:841`; row
  `adapt-line-points-elements`). The by-name write `line['points']` takes only a
  `List<types.PointElement>` or `undefined` (`element.line.dart:1152-1154`). A
  `List<types.Element>` is not a `List<types.PointElement>` at run time.
- `getStartAndCountOfVisiblePoints` takes `List<PointElement>` (`helpers.extras.dart:207-212`).
  Its body reads `points.length` and `lookupByKey(points, ...)`, which takes `List<Object?>`.
- `DatasetController.updateElement` takes the concrete `Element` (DC:1673-1683).
  `getLabelAndValue` gives `({String label, String value})` (DC:1339).
- `Chart.getDataVisibility` makes the key `jsNumberToString(index)` for each call (cc:1751-1753).
- The concrete `ChartMeta.dataset_` is `@internal` (cc:333-334). Chart.js ADR 0012 says: a member
  of a type library drops the underscore and carries no `@internal`; the concrete member carries
  it.
- `jsCall` tests the arity with `Object? Function(Never, ...)` (`js_function.dart:241-246`). A
  closure with typed parameters passes the test.
- `lib/src/index.dart:49` has the `controllers` Map without entries.

### Measurements

The bed of all figures: Apple M3 Max, macOS 26.5.1, Dart 3.12.2. AOT is `dart compile exe`. wasm
is `dart compile wasm -O2`, run in Node.js v24.12.0 arm64 (times only). The figures are the range
of the medians of 3 or 4 processes. The behavior probes ran the Chart.js build at the pin in the
x64 Node.js v24.12.0 under Rosetta (Chart.js ADR 0010).

**Question 3, the judge run** (Evidence E2). The real `LineElement` and `PointElement` of
`lib/src/`, `animated` true (each draw runs `updateControlPoints` and builds the path again).
`draw_typed`: a draw of a line with a `List<types.PointElement>`. `draw_view`: a draw of a line
with the cast view `meta.data.cast<types.PointElement>()`. `set_copy`: the copy
`List<types.PointElement>.generate` of a `List<types.Element>`. µs for each op:

| Case | `draw_typed` | `draw_view` | view extra for each draw | `set_copy` (once for each update) |
|---|---|---|---|---|
| AOT, 1000, tension 0 | 19.70-19.91 | 23.68-23.75 | +3.8-4.1 (19-20 %) | 2.18-2.21 |
| AOT, 1000, tension 0.4 | 50.60-51.65 | 54.77-55.63 | +3.2-4.2 (6-8 %) | 2.20-2.22 |
| AOT, 20000, tension 0 | 240.82-245.26 | 252.10-261.87 | +9.5-16.6 (4-7 %) | 42.67-43.55 |
| AOT, 20000, tension 0.4 | 1420.91-1455.53 | 1482.94-1521.95 | +27-71 (2-5 %) | 43.07-43.72 |
| wasm, 1000, tension 0 | 27.60-27.97 | 31.21-31.52 | +3.3-3.9 (12-14 %) | 3.55-3.60 |
| wasm, 1000, tension 0.4 | 93.91-95.97 | 110.58-111.63 | +15.7-16.7 (17-18 %) | 3.63-3.75 |
| wasm, 20000, tension 0 | 424.85-435.59 | 470.62-483.80 | +44-58 (10-14 %) | 94.08-96.82 |
| wasm, 20000, tension 0.4 | 2257.47-2269.19 | 2588.03-2688.28 | +320-431 (14-19 %) | 94.77-95.98 |

- The view costs at each draw. The copy costs once for each update. An animation of the default
  1000 ms draws about 60 frames for each update. A hover draws with no update. The copy costs less
  than the view from 1 to 5 draws for each update.
- Of the copy forms, `generate` is the fastest by a factor of 2 to 6 (Evidence E3,
  `points_copy`): 36.3-40.5 µs (AOT) and 56.5-66.8 µs (wasm) for 20000 elements, against
  160.4-165.8 µs and 375.9-433.9 µs for `List.of(data.cast())`.

**Question 4** (Evidence E3, E4, E5). ns for each call of `getDataVisibility`. "I" is the current
body through `types.Chart`, "C" the same body after a cast to `Chart`, "IF" the interface call
with the early return of section 4:

| State | Platform | I | C | IF |
|---|---|---|---|---|
| no hidden index | AOT | 14.9-18.8 | 14.8-18.4 | 2.7-4.1 |
| no hidden index | wasm | 15.7-23.0 | 12.2-21.1 | 2.5-3.7 |
| one hidden index | AOT | 17.5-22.2 | 19.1-21.8 | 17.5-22.4 |
| one hidden index | wasm | 18.4-26.2 | 19.6-24.0 | 18.4-26.5 |

The three benchmarks of the panel agree. The early return costs 0.4-0.9 ns more than a loop
without a call (Evidence E4, B2). With a hidden index, it costs nothing measurable.

**Question 1** (Evidence E4, B3; E5, E1.2). With one class hierarchy behind an interface, the
interface call costs the same as the call after a cast: `getBasePixel()` 3.4 ns (AOT) and
3.2-3.3 ns (wasm); the `active` getter 0.4 ns and 0.3 ns. The three by-name writes of
`line.js:57-59` cost 4.7-4.8 ns (AOT) and 39.5-40.2 ns (wasm) for each update of a dataset,
against 1.1 ns and 0.6 ns for typed setters. The read of a typed `total` field costs 0.7 ns. The
by-name read through the extras Map of `ChartMeta` costs 11.2-11.7 ns (AOT) and 18.1-18.7 ns
(wasm).

**Question 2** (Evidence E3, E4, E5). Labels `[['line 1', 'line 2'], 5, 0, 'd', undefined]`,
`[['line 1', 'line 2'], 7, '', null, 'e']` and a radar index past the end:

| Chart type | Label | Upstream label | Upstream title | Title with a `String` label (`'' + label`) |
|---|---|---|---|---|
| scatter, bubble, doughnut, pie, polarArea, radar | `['line 1', 'line 2']` | the array | 2 lines | 1 line `line 1,line 2` |
| the same | `5` | `5` (number) | `[5]` | `['5']` |
| radar | `0` | `0` (number) | no title | `['0']` |
| radar | `null` | `null` | not probed | the label `'null'` |
| radar | past the end | `undefined` | no title | `['undefined']` |
| scatter, bubble, doughnut, pie, polarArea | `0`, `''`, `null`, past the end | `''` | no title (`0`, `''`, past the end) | equal |
| bar, line | each | a string | equal | equal |

A `String` label changes the count of the title lines and adds a title where upstream has none.
Phase 8 also gives `item.label` to the user callbacks with its upstream type.

**Question 5** (Evidence E3, E4, E5). Three variants of the pinned `PolarAreaController`:
`upstream`, `nohunk` (without `:204-210`) and `sharing` (`enableOptionSharing = true`). Each cell
gives `spacing, spacingMode` of the arcs after a second `update()`, and of arc 0 after a hover
when it differs:

| Case | upstream | nohunk | sharing |
|---|---|---|---|
| spec `controller.polarArea.tests.js:69`: no options | 0, proportional | same | `TypeError` |
| spec `:85`: chart `spacing: 12, spacingMode: 'parallel'` | 12, parallel | same | 12, parallel; frozen |
| dataset `spacing: 5, spacingMode: 'parallel'` | 5, parallel | same | same; frozen |
| `options.datasets.polarArea` `spacing: 4, spacingMode: 'parallel'` | 4, parallel | same | same; frozen |
| `options.elements.arc` `spacing: 3, spacingMode: 'parallel'` | 3, parallel | same | same; frozen |
| `elements.arc` `spacing: 0, spacingMode: 'angular'` | 0, **proportional**; hover 0, **angular** | 0, angular | `TypeError` |
| chart `spacing: 12`, `elements.arc.spacing: 0` | **12**, proportional | 0, proportional | `TypeError` |
| chart `spacing: 7`, `elements.arc.spacing: () => 0` | **7**, proportional | 0, proportional | 7, proportional; not shared |
| chart `spacing: 7`, `elements.arc.spacingMode: 'parallel'` | 7, parallel | same | same; frozen |
| dataset `spacing: 0`, chart `spacing: 7` | 0, proportional | same | `TypeError` |
| dataset `spacingMode: 'angular'`, chart `spacingMode: 'parallel'` | 0, angular | same | `TypeError` |

- The spec cases `:69`, `:85` and `controller.doughnut.tests.js:49` give the same values with and
  without the hunk. A sweep of 66 configurations (the spec cases, each polar area fixture and the
  doughnut spacing fixtures) finds one difference between `upstream` and `nohunk`: the case
  `elements.arc.spacingMode: 'angular'`. No polar area fixture sets `spacing` or `spacingMode`.
- The hunk changes a resolved option only for an element-level `0` or `'angular'`. The hover path
  (`setHoverStyle`, dc.js:919-940) does not run the hunk. Thus the hover options keep
  `'angular'`.
- With option sharing, the write throws a `TypeError` in both runtimes: the Dart `ElementOptions`
  in the frozen state throws for each write (`element_options.dart:250-252`, Chart.js ADR 0021
  §5).

## Decision

### 1. Interface members and casts

**The rule.** Each member that a ported controller reads through a type interface becomes a
member of that interface, with its first ported reader (Chart.js ADR 0003). A controller imports
no concrete module that its upstream file does not import. A controller casts only:
1. to an interface of `lib/src/types/`: the Dart form of a TypeScript generic argument or of a
   duck-typed read; or
2. to a class of its own library, or of a library that its upstream file imports. The one case is
   `(meta.controller as DoughnutController)` for `_getRotation()` and `_getCircumference()`
   (`controller.doughnut.js:193-195`). `controller.pie.dart` imports `controller.doughnut.dart`,
   as `controller.pie.js:1` does.

Three other kinds of casts stay. They are not casts of a module type: a `List` cast of a value
that upstream reads as an array (the `labels` of the legend functions, the data of the doughnut
`parse` with `parsing: false`, the result of `parseObjectDataRadialScale` in the polar area and
radar `parseObjectData`), the `String` cast of a parsing key
([Chart.js ADR 0027](0027-parsed-data.md) §4), and the `AnyObject` cast of an options object or a
stack object that the controller made. The `List` and `AnyObject` casts cannot throw where
upstream does not throw. The review checklist of each wave accepts these three kinds.

A cast throws a `TypeError` in the same method call as the upstream throw, at the upstream read
of the first member that only the subtype has, or earlier when every path from the cast reaches
that read. Between the two sites lie only reads and option resolutions, which no protected
behavior sees. Thus:
- `controller.polarArea.dart` casts `cachedMeta.rScale` once at `:166`. Every path reaches
  `scale.getIndexAngle(0)` at `:169`.
- `controller.radar.dart` casts the scale at `:88`, in the loop. A radar update with no point
  reads no member upstream and throws nothing.
- `controller.line.dart` casts `meta.dataset` to `types.LineElement` at the draw (`line.js:140`),
  and each `data[i]` to `types.PointElement` at `size` (`line.js:133-134`,
  `controller.bubble.js:88`, `controller.scatter.js:158-163`).
- `bar.js:677` casts the element to `types.VisualElement` at the draw, as DC already does.

**The line writes.** The four writes of `line.js:57-60`, `controller.scatter.js:80-83` and
`controller.radar.js:60` are by-name writes through `types.PropertyAccess` (Chart.js ADR 0017
§5): `line['_chart']`, `line['_datasetIndex']`, `line['_decimated']` and `line['points']`. The
by-name write is the direct form of an untyped property write. It keeps the upstream throw site:
a dataset element without the line API takes the writes, and the draw throws. A cast to
`types.LineElement` in `update` throws one call earlier than upstream (`update`, not the draw of
the frame), and no row records that throw. The by-name writes cost below 0.1 µs for each update
(Measurements).

**`updateElement`.** `DatasetController.updateElement` takes `types.Element`
(`index.d.ts:674`: `element: TElement | TDatasetElement`). DC casts once to `Element` for
`assign`. `Animations.update` takes `Object`. DC already imports `core.element.dart`. Each data
and dataset element of the port is an `Element` (the casts of `addElements` and
`_insertElements`, row `adapt-component-class-role`). Thus the cast adds no throw, and no
controller imports `core.element.dart`.

**The members.** The concrete member exists for each row unless the row says "new". Each concrete
member gets `@override`.

`types.Scale` (the forms of Chart.js ADR 0025 §5; `getBaseValue` waits for `filler.options.js`,
phase 8):

| Dart member | Upstream | First reader |
|---|---|---|
| `Map<String, Object?> get cache` | `core.scale.js:247` `_cache` | `bar.js:8`, `:15`, `:17` |
| `List<Tick>? get ticks` | `index.d.ts:1321` | `bar.js:47` |
| `double? getPixelForTick(int index)` | `index.d.ts:1346` | `bar.js:48` |
| `double getBasePixel()` | `index.d.ts:1382` | `bar.js:396`; `line.js:101` |
| `double get startPixel`, `double get endPixel` | `core.scale.js:237`, `:239` | `bar.js:549-550` |
| `double getPixelForDecimal(double decimal)` | `index.d.ts:1339` | `bar.js:606-607`; `controller.bubble.js:129` |
| `double? getValueForPixel(double pixel)` | `index.d.ts:1374` | `bar.js:615` |
| `double getLineWidthForValue(Object? value)` | `index.d.ts:1357` | `bar.js:620` |

`types.RadialLinearScale implements Scale` (new, `index.d.ts:3676-3685`; `RadialLinearScale` of
`scale.radialLinear.dart:731` implements it):

| Dart member | Upstream | First reader |
|---|---|---|
| `double? get xCenter` | `index.d.ts:3677` | `controller.polarArea.js:167`; `controller.radar.js:90` |
| `double? get yCenter` | `index.d.ts:3678` | `controller.polarArea.js:168`; `controller.radar.js:91` |
| `double getIndexAngle(double index)` | `index.d.ts:3681` | `controller.polarArea.js:169` |
| `double getDistanceFromCenterForValue(Object? value)` | `index.d.ts:3682` | `controller.polarArea.js:182` |
| `({double x, double y, double angle}) getPointPositionForValue(double index, Object? value)` | `index.d.ts:3685` | `controller.radar.js:88` |

The record stays (Chart.js ADR 0003; Chart.js ADR 0025 Open 5).

`xCenter` and `yCenter` are `double?` (decision D11 item a): Dart `null` is the `undefined` start
value before the first layout (`scale.radialLinear.js:416-418`), and NaN is the NaN center after
a layout (for example `position: 'left'`). The reset of a new radar or polar area point before the
first layout of its scale writes `undefined` into the element, and the animation then starts at
its target (`core.animation.js:31-32`). With `double` and NaN for both values, a controller cannot
tell them apart, and the drawn element and the hit element change. The scale reads
`xCenter ?? double.nan` in arithmetic and canvas calls.
[Chart.js ADR 0033](0033-radial-scale-centers.md) (proposed) records these two forms. On
acceptance, it supersedes the bullet `double get xCenter`, `double get yCenter` of Chart.js ADR
0025 §5, only.

`types.Chart`:

| Dart member | Upstream | First reader |
|---|---|---|
| `bool isDatasetVisible(double datasetIndex)` | `index.d.ts:569`, cc.js:863 | `controller.doughnut.js:192` |
| `double getVisibleDatasetCount()` | `index.d.ts:568`, cc.js:859 | `controller.polarArea.js:155` |
| `void toggleDataVisibility(Object? index)` | `index.d.ts:571`, cc.js:881 | `controller.doughnut.js:126` |
| `void update([Object? mode])` | `index.d.ts:559`, cc.js:475 | `controller.doughnut.js:127` |
| `LegendElement? get legend` | `index.d.ts:543` | `controller.doughnut.js:97`; `controller.polarArea.js:41` (new field, section 6) |

`types.ChartMeta`:

| Dart member | Upstream | First reader |
|---|---|---|
| `Object? get dataset_` | cc.js:845 `_dataset`; the name of Chart.js ADR 0023 | `line.js:43` |
| `abstract double? total` | `index.d.ts:373-375` `DoughnutMetaExtensions.total` | `controller.doughnut.js:235` (write), `:313` (read) |

- `dataset_` carries no `@internal` in the type library. The concrete member keeps it (Chart.js
  ADR 0012, type libraries). The analyzer gives no warning for a read inside the package.
- `total` is a new `double? total` field of the concrete `ChartMeta`. Dart `null` stands for
  `undefined`, the start value: `total > 0` is false for both. The by-name read gives
  `total ?? undefined`, and the by-name write sets the field. A write of a value that is not a
  number throws a `TypeError`, as the other typed fields of `ChartMeta` do (cc:487-545). The typed
  field costs 0.7 ns for each read. The extras Map costs 11-19 ns. `calculateCircumference` reads
  it for each arc.

`types.DatasetController` (the reader reaches another controller through `meta.controller`):

| Dart member | Upstream | First reader |
|---|---|---|
| `Map<String, Object?> get options` | dc.js:262, `:442` (`index.d.ts` does not declare it) | `bar.js:437` |
| `Object? getParsed(double index)` | `index.d.ts:688`, dc.js:579 | `bar.js:440` |
| `Map<String, Object?> getStyle(double? index, [bool? active])` | `index.d.ts:656`, dc.js:752 | `controller.doughnut.js:101`; `controller.polarArea.js:45` |
| `Map<String, Object?> resolveDataElementOptions(double index, [String? mode])` | `index.d.ts:658`, dc.js:797 | `controller.doughnut.js:354` |

`getLabelAndValue` stays off `types.DatasetController` until its first reader through the
interface, `plugin.tooltip.js:130` (phase 8).

`types.Element`, `types.PointElement` and `types.LineElement`:

| Interface | Dart member | Upstream | First reader |
|---|---|---|---|
| `Element` | `bool get active` | `core.element.ts:13` | `bar.js:418` |
| `Element` | `Object? get hidden` | cc.js:892-899 writes it; dc.js:730 reads it | `bar.js:676` |
| `PointElement` | `double size([Map<String, Object?>? options])` | `element.point.ts:81` | `line.js:133`; `controller.bubble.js:88` |
| `LineElement` | `void updateControlPoints(ChartArea chartArea, [String? indexAxis])` | `index.d.ts:2025`, `element.line.js:299` | `line.js:140` |

`types.LineElement` gets no setter: the controllers write by name.

`types.LegendElement` (new, `index.d.ts:2414-2418`), with the members that the option functions
read:

| Dart member | Upstream | First reader |
|---|---|---|
| `Chart get chart` | `index.d.ts:2415` | `controller.doughnut.js:126` |
| `Map<String, Object?> get options` | `index.d.ts:2418` | `controller.doughnut.js:97` |

`chart.registry.getElement('line')` (`controller.scatter.js:105`) reads the singleton `registry`
(row `adapt-chart-registry-getter`). It needs no member.

**The implementers.** These classes implement a changed interface without `noSuchMethod`. Each
gets the new members:

| Class | File | New members |
|---|---|---|
| `_Point implements PointElement` | `test/specs/helpers.segment_test.dart:12` | `active`, `hidden`, `size` |
| `_Point implements PointElement` | `test/port/helpers/helpers.segment_test.dart:22` | the same |
| `_Point implements PointElement` | `test/port/helpers/helpers.extras_test.dart:82` | the same |
| `_Dataset implements Element` | `test/port/helpers/helpers.extras_test.dart:67` | `active`, `hidden` |
| `_Point implements PointElement` | `test/port/helpers/helpers.collection_test.dart:13` | `active`, `hidden`, `size` |
| `_Point implements PointElement` | `tool/bench/bench_flutter_test.dart:45` | the same |
| `_PointElement implements PointElement` | `tool/bench/src/cases_data.dart:70` | the same |
| `_Meta implements types.ChartMeta` | `test/port/core/core.datasetController_test.dart:425` | `dataset_`, `total` |
| `DemoChart implements types.Chart` | `apps/chartjs_gallery/lib/demo/demo_chart.dart:40` | the 5 `types.Chart` members, with the results of Chart.js ADR 0031 §9.2 |

### 2. The label of `getLabelAndValue`

- The record is `({Object? label, String value})` in DC and in each override. The base body and
  `bar.js` keep a string label.
- The overrides of scatter, bubble, doughnut, pie and polar area return `labels[index] || ''`:
  `jsTruthy(label) ? label : ''` with `label = jsGetIndex(labels, index)` (Chart.js ADR 0027 §3).
  `labels` is `chart.data.labels || []`.
- Radar returns `jsGetIndex(vScale.getLabels(), index)`: `undefined` past the end, a JS `null`
  as Dart `null`.
- The value stays `String`: each body makes it with `'' +`, `'(' + ... + ')'` or
  `formatNumber`.
- Phase 8 gives the label to the tooltip item with its type.

### 3. `meta.data` and `line.points`

- The setter `LineElement.points` takes `List<types.Element>`. It keeps a
  `List<types.PointElement>` as it is. It copies another list with
  `List<types.PointElement>.generate(points.length, (i) => points[i] as types.PointElement)`.
- The by-name write `line['points']` takes the same path: a `List<types.Element>` goes to the
  setter, `undefined` clears the points, and another value throws the `ArgumentError` of row
  `adapt-line-points-elements`. The write `line['_points']` does not change.
- `getStartAndCountOfVisiblePoints` takes `List<Element>` (the type library `Element`).
- The controllers keep the upstream lines: `final points = meta.data;` and the by-name write
  `line['points'] = points`.
- Thus the line and the meta have two lists with the same elements in the same order. No reader
  sees the difference: no code reads `line.points` between `buildOrUpdateElements` and the
  controller `update` of one `chart.update()`, except a user plugin hook `afterLayout`. The draw
  reads a typed list at the speed of a direct list.
- An element that is not a `types.PointElement` throws a `TypeError` at the copy. The current
  setter throws for the list type. Upstream accepts both. The row `adapt-line-points-elements`
  covers both.
- This form keeps the upstream structure: the conversion stands in the setter of the existing
  row, and no shared layer changes. Thus the microbenchmark figures are sufficient (Chart.js ADR
  0020 §13).

### 4. `getDataVisibility`

- The controllers call `chart.getDataVisibility(i)` through `types.Chart` (Chart.js ADR 0025 §4).
  No controller casts the chart. This closes Chart.js ADR 0025 Open 4.
- `Chart.getDataVisibility` starts with the port-only statement
  `if (_hiddenIndices.isEmpty) return true;`. An empty object gives `undefined` for each key, and
  `!undefined` is `true`. Thus the result is the upstream result for each index and each state.
  A key with the value `false` (two toggles of one index) keeps the Map not empty. The body then
  takes the upstream line.
- The statement has no `DIVERGES` marker, as the fast paths of Chart.js ADR 0025 §3. Its comment
  names this ADR. `performance.md` records the figures.
- The statement keeps the upstream line and skips no upstream call. It skips only the port-only
  key string of `jsNumberToString`. Thus it is not a structure change of Chart.js ADR 0027 §8,
  and the microbenchmark figures are sufficient (Chart.js ADR 0020 §13). Chart.js ADR 0027 §8
  does not put it in the step 7 list.

### 5. The #12238 hunk

- `controller.polarArea.dart` ports `:204-210` line by line, with the upstream comment and no
  marker: `elementOptions['spacing'] == 0` and `elementOptions['spacingMode'] == 'angular'`, and
  the writes `jsGet(options, 'spacing')` and `jsGet(options, 'spacingMode')` (a resolver read,
  Chart.js ADR 0017 §8).
- Dart `==` on `Object?` is `===` here: true for `0`, `0.0` and `-0.0`, false for `'0'`, NaN,
  `null` and `undefined`. A string compares by value.
- `PolarAreaController` keeps `enableOptionSharing == false`. A subclass that sets it to `true`
  gets the `TypeError` of upstream in the rows that throw upstream.

### 6. The option functions of `defaults` and `overrides`

- The controllers port the four functions now, with the upstream bodies. A placeholder or an
  absent key changes the defaults inventory of `doc/upstream/manifest.json` (the keys
  `doughnut`, `pie` and `polarArea` of `plugins.legend.labels.generateLabels` and
  `plugins.legend.onClick`).
- Each function is a private top-level function with typed parameters:
  `List<Object?> _generateLabels(types.Chart chart)` and
  `void _onClick(Object? e, Object? legendItem, types.LegendElement legend)`. The `overrides` Map
  holds the tear-off. A tear-off of a top-level function is canonical: each read gives the same
  object. Pie inherits the doughnut functions through the class chain.
- `jsCall` of phase 8 calls them. A closure with typed parameters passes its arity test. A call
  with an argument of another type throws a `TypeError`, as the upstream property read of
  `undefined` does. The bodies do not read `this`.
- `chart.legend!` throws a `TypeError` for Dart `null`, as `undefined.options` does: always for
  the doughnut, and only with labels and datasets for polar area.
- A legend item is a `Map<String, Object?>` with the keys in the order of the upstream literal
  (`controller.doughnut.js:103-118`, `controller.polarArea.js:47-58`). A key whose value is
  `undefined` keeps the sentinel, for example `lineJoin`.
- `useBorderRadius && (borderRadius || style.borderRadius)` keeps the operand values:
  `jsTruthy(u) ? (jsTruthy(b) ? b : jsGet(style, 'borderRadius')) : u`.
- `toggleDataVisibility(jsGet(legendItem, 'index'))`: `types.Chart.toggleDataVisibility` takes
  the raw JS value (`Object?`, the form of Chart.js ADR 0025 §1) and writes the key
  `ToString(index)` (`jsToString`), as upstream (cc.js:881-883). An absent index gives the key
  `'undefined'`. After a data insert or remove, `moveNumericKeys` (cc.js:72-84) moves a key such
  as `''` or `'01'` as upstream (decision D11 item c). A number gives the key of
  `jsNumberToString`, as before. `getDataVisibility(double index)` does not change. No marker and
  no `differences.md` row.
- The doughnut descriptors are `'_scriptable': (String name) => ...` and
  `'_indexable': (String name) => ...`, as `core.defaults.dart:462-463`.

### 7. The registration

- `lib/src/controllers/index.dart` ports `src/controllers/index.js` in the form of
  `lib/src/scales/index.dart`: the header, a `///` line for each upstream line in the upstream
  order (`PolarAreaController` before `PieController`, `index.js:5-6`), `library;`, and eight
  `export ... show <Class>;` lines in code unit order. The `directives_ordering` lint of
  `very_good_analysis` fails on the source order, and `analyze` runs with `--fatal-infos`
  (Evidence E2, `lintprobe`).
- `lib/src/index.dart` exports `controllers/index.dart` (`index.ts:1`). The `controllers` Map gets
  the eight class values in code unit order (Chart.js ADR 0020 §6). `registerables` does not
  change.
- Each class value has `superclass: DatasetController.jsClass`; `PieController.jsClass` has
  `superclass: DoughnutController.jsClass` (Chart.js ADR 0020 §3).
- `flutter_test_config.dart` registers the namespace with the other built-in components. A test
  controller with the id of a built-in controller is ignored (`core.typedRegistry.js:41-44`). The
  test controllers of the repository use other ids.

### 8. Tests, rows and records

- New `DIVERGES` rows: none. New markers: none. New skip reasons: none.
- Row `adapt-line-points-elements`: the text gets the copy of section 3, and the code column gets
  `getStartAndCountOfVisiblePoints`.
- Pin tests: the interface members (section 1), the labels of each override (section 2), the
  copy and the shared elements of the line, scatter and radar controllers (section 3), the states
  of `getDataVisibility` (section 4), the rows of the hunk with the hover row and the frozen throw
  (section 5), the option functions against the probe items (section 6), and the namespace and
  the registry (section 7). The implementation spec
  (`.handover/phase7/design/interfaces-values/spec.md`) gives the cases. The test files follow Chart.js
  ADR 0030 §3.
- `performance.md` records the figures of the Measurements section.

### 9. The questions of the panel

| Question | Decision | Open |
|---|---|---|
| 1. Interface members and casts | Section 1 | Item 2 |
| 2. The label of `getLabelAndValue` | Section 2 | Items 2, 3 |
| 3. `meta.data` and `line.points` | Section 3 | Item 1 |
| 4. `getDataVisibility` | Section 4 | Item 1 (the record only) |
| 5. The #12238 hunk | Section 5 | none |
| 6. The option functions | Section 6 | Item 2 |
| 7. The registration | Section 7 | none |

## Alternatives considered

Each option has a score in the order of [porting-flow.md](../porting-flow.md) §1.1: behavior,
performance, structure, code.

**The three drafts.** A panel wrote three drafts: fidelity (F), performance (P) and simplicity
(S). A judge ranked them for each question:

| Question | 1st | 2nd | 3rd |
|---|---|---|---|
| 1. Interface members | P | F | S |
| 2. Label | F | P, S | |
| 3. `line.points` | S | P | F |
| 4. `getDataVisibility` | P | F, S | |
| 5. The hunk | S | P | F |
| 6. Option functions | P | F | S |
| 7. Registration | S | P | F |

S is the base. It wins question 3, the question with the largest effect. Its code forms are the
only ones that pass `analyze --fatal-infos`. This ADR takes from P: the by-name line writes, the
typed `total` field, the early return figures, the typed top-level functions and the sweep of 66
configurations. It takes from F: the table of members with their concrete lines, the label probe
with the titles, the scope rows of the hunk and the legend probe.

**Question 1.**
- **Casts to the concrete classes** (`chart as Chart`, `scale as Scale`, `meta as ChartMeta`).
  The same values. A `types.Chart` that is not the concrete `Chart` (`DemoChart`, the test fakes
  that drive real controllers, `core.datasetController_test.dart:514`) throws a `TypeError`.
  Equal speed for an interface with one class hierarchy. Imports of `core.controller`,
  `core.scale`, `core.element` and element modules that upstream does not have. Rejected.
- **Typed setters on `types.LineElement` and a cast in `update`** (F, S). 4 ns (AOT) and 39 ns
  (wasm) less for each update. The cast throws in `update` for a dataset element without the line API. Upstream
  throws in the draw. The precedent `adapt-component-class-role` accepts an earlier throw only in
  the same `update()` call. Rejected.

**Question 2.**
- **`({String label, String value})` with `jsToString`.** It changes the title lines and adds
  titles (Measurements). It needs a hunk in five overrides and a row. Rejected.
- **A class `LabelAndValue`.** The same values as the record, no speed gain (one call for each
  tooltip item), against the record rule of Chart.js ADR 0003. Rejected.

**Question 3.**
- **V, a cast view `meta.data.cast<types.PointElement>()` at the three writers** (F, the gallery
  form). Live sharing of the items. It costs at each draw: +9.5-71 µs (AOT) and +44-431 µs (wasm)
  for 20000 points, 10-19 % of the wasm line draw. The shared array is not a protected behavior.
  Rejected.
- **T, a typed `meta.data`** (P). `DatasetController.initialize` replaces the empty list with a
  `List<types.PointElement>` for a point element class. It keeps the identity and saves the copy:
  43 µs (AOT) and 57-97 µs (wasm) for each update of 20000 points. It changes the shared core
  layer: a setter on `types.ChartMeta.data` and on the final `ChartMeta.data` (cc:298), a rewrite
  of `_insertElements` without `_hole`, and an import of `element.point.dart` in DC, which dc.js
  does not import. An element of another class throws at the insert. The gain is below the
  0.1 ms of Chart.js ADR 0020 §13. Open item 1.
- **K2, the copy at the three writers.** The same speed as K, a port-only expression at three
  sites. Rejected.
- **W, `LineElement.points` as `List<types.Element>`.** A cast at each item read in
  `element.line.dart`, `helpers.segment.dart` and `helpers.curve.dart`: the read loop costs twice
  as much on AOT. About 25 sites, against the JSDoc `PointElement[]` of these functions. Rejected.
- **A copy with `List.of(data.cast())`.** 4 to 6 times slower than `generate`. Rejected.

**Question 4.**
- **A cast to `Chart` with the early return** (CF). 1.5 ns faster on wasm only, equal on AOT. An
  import that upstream does not have, and a `TypeError` for the other `types.Chart` classes. It
  breaks the rule of section 1. Rejected.
- **A cache of the keys of small integers** (IK). 8-12 ns faster only with a hidden index, which
  happens after a legend click on a chart with few elements. A port-only table. Rejected.

**Question 5.**
- **Drop the hunk.** It fails the cases with an element-level `0` or `'angular'`. A row.
  Rejected.
- **The dataset defaults before the element defaults in the resolver.** It changes other options
  and `core.config`. Rejected.
- **Typed reads `(options as ArcOptions).spacingValue`, or the dataset read out of the loop.**
  Below 0.2 µs for each update of 20 arcs. A cast throws for a user element class. Rejected.
- **`spacing is num && spacing == 0`** (F). `'0' == 0` is false in Dart. The `is num` test adds
  nothing. Rejected.

**Question 6.**
- **Placeholders until phase 8.** The inventory and the theme coverage test see other values.
  Rejected.
- **`Object?` parameters and a cast at the entry** (S, the precedent `core.scale.defaults.dart:50-52`).
  The same behavior, one cast line for each function. Rejected.
- **By-name reads `jsGet(chart, 'legend')`.** `jsGet` gives `undefined` for a Dart object that is
  not a Map, a List, a String, a resolver or a class value (`js_object.dart:36-62`). Rejected.

**Question 7.**
- **The source order of `index.js` in `controllers/index.dart`** (F, P). It fails
  `directives_ordering` under `--fatal-infos`. The `///` lines keep the source order. Rejected.

## Consequences

- The controllers give the upstream values and throws for the reads of other modules. They import
  no concrete chart, meta, scale or element module that upstream does not import.
- `lib/src/types/index.dart` gets 24 members on 7 interfaces and 2 new interfaces with 7 members.
  Nine test, tool and gallery classes get the new members.
- The copy of section 3 costs 2.2 µs (AOT) and 3.6 µs (wasm) for each update of 1000 points, and
  43 µs and 94-97 µs for 20000 points. The draw has no cost from the copy.
- A chart with no hidden index saves 12-19 ns for each `getDataVisibility` call. For an update of
  20000 bars, the calculation from the microbenchmark gives 0.24-0.35 ms. This is not a frame
  figure. Open item 1 records the frame figure.
- The polar area hunk keeps its two resolved values and its frozen throw.
- Phase 8 gets typed option functions, `types.LegendElement` and `types.Chart.legend` to
  implement and write.
- The `controllers` namespace and `registerables` register the eight controllers in the order of
  the bundle.
- No accepted ADR changes. This ADR decides Chart.js ADR 0025 Open 4 and keeps the record of its
  Open 5.

## Open

1. **Form T and the frame figures.** Owner: step 7 of phase 7. Trigger: the start of step 7. The
   step measures the stress mode `chart` with `LineController` and 20000 points, `CALL=update` and
   `CALL=draw`, form K against form T, on the Pixel 8a and in Chrome with dart2wasm
   ([performance.md](../performance.md) §6). A gain of 0.1 ms or more for each frame goes to a
   new ADR that supersedes section 3 of this ADR. The same session records the stress mode `axes`
   with `BarController` and 20000 bars, `CALL=update`, with and without the early return of
   section 4 (a record, not a decision).
2. **The members of phase 8.** Owner: the phase 8 units of `plugin.tooltip`, `plugin.legend` and
   `plugin.filler`. Trigger: the port of the first reader. `getLabelAndValue` goes to
   `types.DatasetController` (`plugin.tooltip.js:130`), `getBaseValue` to `types.Scale`
   (`filler.options.js:112`). `Legend` implements `types.LegendElement` with
   `implements Element, LayoutItem` (`index.d.ts:2414`) and writes `chart.legend`
   (`plugin.legend.js:602`, `:609`). The tooltip item keeps `Object? label`.
3. **The index read of the labels.** Owner: the maintainer. Trigger: the acceptance of Chart.js
   ADR 0027, or a change of its §3. The label reads of section 2 follow the index read of that
   ADR.

## Evidence

All files are in the session scratchpad folder
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/`
(below: `<design>`).

- **E0, upstream source** at `v4.5.1+7169e651`, `src/`:
  - `controllers/controller.bar.js:8`, `:15`, `:17`, `:47-48`, `:364-376`, `:396`, `:418`,
    `:437`, `:440`, `:549-550`, `:592`, `:606-607`, `:615`, `:620`, `:676-677`
  - `controllers/controller.line.js:41-60`, `:101`, `:111`, `:129-134`, `:138-141`
  - `controllers/controller.scatter.js:51`, `:56-83`, `:105`, `:158`
  - `controllers/controller.bubble.js:88`, `:106`, `:129-130`
  - `controllers/controller.doughnut.js:71-83`, `:90-128`, `:136`, `:172-195`, `:235`, `:250`,
    `:288`, `:304`, `:313`, `:327`, `:340`, `:354`, `:380`
  - `controllers/controller.polarArea.js:38-68`, `:90-95`, `:104`, `:130`, `:150-212`, `:221`,
    `:233`
  - `controllers/controller.radar.js:39-47`, `:53-60`, `:81-91`
  - `controllers/index.js:1-8`
  - `core/core.controller.js:72-84`, `:169`, `:475`, `:568-575`, `:843-846`, `:859`, `:863`,
    `:881-887`, `:892-899`
  - `core/core.datasetController.js:262`, `:442`, `:579`, `:687-697`, `:730`, `:752`, `:797`,
    `:804-833`, `:919-940`
  - `core/core.typedRegistry.js:24-44`
  - `types/index.d.ts:373-375`, `:543`, `:559`, `:568-571`, `:641`, `:656`, `:658`, `:674`,
    `:688`, `:2022-2026`, `:2414-2418`, `:3676-3685`
- **E1, the panel:** [judge.md](../../../../.handover/phase7/design/interfaces-values/judge.md),
  [draft-fidelity.md](../../../../.handover/phase7/design/interfaces-values/draft-fidelity.md),
  [draft-performance.md](../../../../.handover/phase7/design/interfaces-values/draft-performance.md),
  [draft-simplicity.md](../../../../.handover/phase7/design/interfaces-values/draft-simplicity.md).
- **E2, judge runs:** `<design>/interfaces-values-judge/`: `bin/points_judge.dart` (question 3),
  `run.sh`, `out/points_aot.out`, `out/points_wasm.out`; `lintprobe/analyze.out` (question 7);
  `out/probe_spacing_simplicity.rerun` (the rerun of the S probe, byte-identical).
- **E3, simplicity:** `<design>/interfaces-values-simplicity/`: `probe_label.mjs` and `.out`,
  `probe_spacing.mjs`, `probe_spacing.out` and `probe_spacing_colors.out` (the colors plugin on),
  `probe_registry.mjs` and `.out`; `bench/line_view_{aot,wasm}.out`,
  `bench/points_copy_{aot,wasm}.out`, `bench/visibility_{aot,wasm}.out`.
- **E4, performance:** `<design>/interfaces-values-performance/`: `bench/bench_points.dart` (B1),
  `bench/bench_visibility.dart` (B2), `bench/bench_misc.dart` (B3) with their `*_aot_*.out` and
  `w*_wasm_*.out` outputs; `probe_spacing.mjs`, `probe_spacing.out`, `probe_spacing.rerun.out`
  (the 66 configurations); `probe/probe_label.mjs` and `.out`; `probe/spacing_write.dart` and
  `.out`; `probe/typed_list.dart` and `.out`.
- **E5, fidelity:** `<design>/interfaces-values-fidelity/`: `ifaceprobe/analyze.out` (the analyzer
  probe of the member signatures on the concrete classes); `bench/bench_active.dart`,
  `bench/bench_points.dart`, `bench/bench_visibility.dart` with their outputs;
  `probe_label.mjs`, `probe_label.out`, `probe_label.rerun`; `probe_spacing.mjs`,
  `probe_spacing.out`, `probe_spacing.rerun`; `dartprobe/covariant_list.dart`,
  `dartprobe/frozen_write.dart` with their outputs; `probe_legend_fns.mjs` and `.out`;
  `probe_registry.mjs`, `probe_registry.out`, `probe_registry.rerun`.
- **E6, the implementer scan:** the judge scan of `packages/*/test`, `packages/*/tool` and
  `apps/*/lib` (judge §2.4), checked again for this ADR on 2026-10-21 with the same result.
