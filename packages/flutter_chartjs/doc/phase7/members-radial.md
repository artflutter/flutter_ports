# Phase 7 scout: members of the radial controllers

This file is the dependency inventory of the radial controllers of phase 7. It covers these
upstream files at the pin `v4.5.1+7169e651` (`third_party/Chart.js`, commit `7169e651`):

| Upstream file | Lines | Dart target (Chart.js ADR 0012) | Spec |
|---|---|---|---|
| `src/controllers/controller.doughnut.js` | 402 | `lib/src/controllers/controller.doughnut.dart` | `test/specs/controller.doughnut_test.dart` (13 cases) |
| `src/controllers/controller.pie.js` | 24 | `lib/src/controllers/controller.pie.dart` | none upstream. The doughnut spec tests `pie` at :4-7 |
| `src/controllers/controller.polarArea.js` | 237 | `lib/src/controllers/controller.polarArea.dart` | `test/specs/controller.polarArea_test.dart` (14 cases) |
| `src/controllers/controller.radar.js` | 104 | `lib/src/controllers/controller.radar.dart` | `test/specs/controller.radar_test.dart` (13 cases) |
| `src/controllers/index.js` | 8 | `lib/src/controllers/index.dart` | none |

The folder `lib/src/controllers/` does not exist yet. The scout read each upstream file
completely. The scout also read the Dart code of `lib/src/core/` (`core.datasetController.dart`,
`core.controller.dart`, `core.config.dart`, `core.defaults.dart`, `core.typedRegistry.dart`,
`core.scale.dart`), `lib/src/elements/`, `lib/src/scales/`, `lib/src/helpers/`, `lib/src/types/`
and `lib/src/js/`, and Chart.js ADRs 0003, 0017, 0018, 0020, 0021, 0023 and 0025.

Note on ADR 0025: the task names "sections 7 and 8". In the ADR, the members of phase 7 are in
§5 ("Members of phase 7"), and §7 is `setMinAndMaxByKey`. This file uses §5 and §8.

Legend of the status column:

- `ok`: a Dart declaration exists, and the controller can call it through the type that it has.
- `ok (cast)`: a concrete Dart declaration exists. The controller gets the object through an
  interface that does not declare the member. Thus the controller must cast the object, or the
  interface must get the member (Chart.js ADR 0003).
- `MISSING`: no Dart declaration exists.
- `MISMATCH`: a Dart declaration exists, but its type does not hold the upstream value.
- `new`: the member belongs to the new controller class.

Dart paths are relative to `packages/flutter_chartjs/lib/src/`. Abbreviations: `dc` is
`core/core.datasetController.dart`, `cc` is `core/core.controller.dart`, `ti` is
`types/index.dart`, `eo` is `elements/element_options.dart`, `rl` is
`scales/scale.radialLinear.dart`.

## 1. Imports

### controller.doughnut.js

| Import (upstream line) | Symbol | Dart counterpart | Status |
|---|---|---|---|
| :1 | `DatasetController` | `dc:626` `class DatasetController` | ok |
| :2 | `isObject` | `helpers/helpers.core.dart:91` | ok |
| :2 | `resolveObjectKey` | `helpers/helpers.core.dart:511` | ok |
| :2 | `toPercentage` | `helpers/helpers.core.dart:137` (`double toPercentage(Object? value, double dimension)`) | ok |
| :2 | `toDimension` | `helpers/helpers.core.dart:146` | ok |
| :2 | `valueOrDefault` | `helpers/helpers.core.dart:129` (only the `undefined` sentinel gives the default) | ok |
| :3 | `formatNumber` | `helpers/helpers.intl.dart:70` (`String formatNumber(double number, Object? locale, [options])`) | ok. The first parameter is a `double`: the caller applies `jsToNumber` |
| :4 | `toRadians` | `helpers/helpers.math.dart:164` (`double toRadians(double degrees)`) | ok |
| :4 | `PI` | `helpers/helpers.math.dart:21` `pi` | ok |
| :4 | `TAU` | `helpers/helpers.math.dart:24` `tau` | ok |
| :4 | `HALF_PI` | `helpers/helpers.math.dart:36` `halfPi` | ok |
| :4 | `_angleBetween` | `helpers/helpers.math.dart:241` `angleBetween(angle, start, end, [bool? sameAngleIsFullCircle])` | ok |
| :6-8 | JSDoc typedef `Chart` (`core.controller.js`) | type-only. Use `types.Chart` of `ti:263` (Chart.js ADR 0003) | ok |

### controller.pie.js

| Import | Symbol | Dart counterpart | Status |
|---|---|---|---|
| :1 | `DoughnutController` | `controllers/controller.doughnut.dart` | MISSING (phase 7 makes it) |

### controller.polarArea.js

| Import | Symbol | Dart counterpart | Status |
|---|---|---|---|
| :1 | `DatasetController` | `dc:626` | ok |
| :2 | `toRadians` (`helpers/index.js`) | `helpers/helpers.math.dart:164`, exported by `helpers/index.dart` | ok |
| :2 | `PI` | `helpers/helpers.math.dart:21` `pi` | ok |
| :2 | `formatNumber` | `helpers/helpers.intl.dart:70` | ok |
| :2 | `_parseObjectDataRadialScale` | `helpers/helpers.config.dart:901` `const JsFunction parseObjectDataRadialScale` (closure at :906). Call it with `jsCall(..., thisArg: this)` (`js/js_function.dart:131`) | ok |

`helpers/index.dart` exports `helpers.extras`, which is not a pure layer. The controllers are not
pure layers in any case (`dc` imports `core.animations`).

### controller.radar.js

| Import | Symbol | Dart counterpart | Status |
|---|---|---|---|
| :1 | `DatasetController` | `dc:626` | ok |
| :2 | `_parseObjectDataRadialScale` | `helpers/helpers.config.dart:901` | ok |

### index.js

| Export (line) | Symbol | Dart counterpart | Status |
|---|---|---|---|
| :1 | `BarController` | `controllers/controller.bar.dart` | MISSING (other scout of phase 7) |
| :2 | `BubbleController` | `controllers/controller.bubble.dart` | MISSING (other scout) |
| :3 | `DoughnutController` | `controllers/controller.doughnut.dart` | MISSING (this file set) |
| :4 | `LineController` | `controllers/controller.line.dart` | MISSING (other scout) |
| :5 | `PolarAreaController` | `controllers/controller.polarArea.dart` | MISSING (this file set) |
| :6 | `PieController` | `controllers/controller.pie.dart` | MISSING (this file set) |
| :7 | `RadarController` | `controllers/controller.radar.dart` | MISSING (this file set) |
| :8 | `ScatterController` | `controllers/controller.scatter.dart` | MISSING (other scout) |

Other places that need the controllers:

- `index.dart:46-48` `controllers` is an empty unmodifiable Map. Phase 7 adds the eight class
  values in code unit order: `BarController`, `BubbleController`, `DoughnutController`,
  `LineController`, `PieController`, `PolarAreaController`, `RadarController`,
  `ScatterController`.
- `index.dart:11` exports no `controllers/index.dart` yet (index.ts:1).
- The spec case `controller.doughnut.tests.js:4-7` reads `Chart.controllers.doughnut`. That is
  `registry.controllers.items` of `src/index.umd.ts:35`. The Dart form is
  `registry.controllers.items['doughnut']` (`core/core.registry.dart:45`,
  `core/core.typedRegistry.dart` `items`).

## 2. Members that the controllers read or call

### 2.1 controller.doughnut.js

#### On `this` (DatasetController)

| Upstream member | First use | Dart declaration | Status |
|---|---|---|---|
| `constructor(chart, datasetIndex)` | :133-134 | `dc:642` `DatasetController(this.chart, double datasetIndex, [JsClass? newTarget])` | ok. The subclass passes `newTarget` (Chart.js ADR 0020 §4) |
| `enableOptionSharing` (write `true`) | :136 | `dc:754` `bool enableOptionSharing = false` | ok |
| `innerRadius`, `outerRadius`, `offsetX`, `offsetY` | :137-140 | none | new. Start value `undefined`. The spec reads `innerRadius` and `outerRadius` (`controller.doughnut.tests.js:116-117`, :318-330) |
| `linkScales()` (override, empty) | :143 | `dc:806` | ok |
| `parse(start, count)` (override) | :148 | `dc:1017` `void parse(double start, double count)` | ok |
| `getDataset()` | :149 | `dc:859` `Object? getDataset()` | ok. `.data` is `jsGet(..., 'data')` |
| `_cachedMeta` | :150 | `dc:705` `cachedMeta` (`types.ChartMeta`) | ok |
| `_parsing` | :152, :158 | `dc:723` `parsing` (`@internal`) | ok |
| `options` (dataset resolver) | :173 | `dc:717` `late AnyObject options` | ok. Read keys with `jsGet` |
| `chart` | :191 | `dc:683` `final types.Chart chart` | ok |
| `_type` | :192 | `dc:710` `type` (`@internal`) | ok |
| `update(mode)` (override) | :211 | `dc:1375` `void update(String mode)` | ok |
| `index` | :219 | `dc:694` `double index` | ok |
| `updateElements(...)` (override) | :240, :256 | `dc:1843` `void updateElements(List<types.Element> elements, double start, double count, String mode)` | ok. `arcs.length` is an `int`: pass `.toDouble()` |
| `_getSharedOptions(start, mode)` | :267 | `dc:1650` `getSharedOptions_` (ADR 0023), record `({AnyObject? sharedOptions, bool includeOptions})` | ok |
| `resolveDataElementOptions(i, mode)` | :288 | `dc:1501` `AnyObject resolveDataElementOptions(double index, [String? mode])` | ok |
| `updateElement(arc, i, props, mode)` | :292 | `dc:1673` `void updateElement(Element element, double? index, AnyObject properties, String mode)` | ok. The first parameter is the concrete `Element` of `core/core.element.dart`: cast `arcs[i]` |
| `getLabelAndValue(index)` (override) | :320 | `dc:1339` returns `({String label, String value})` | MISMATCH. Upstream returns `labels[index] \|\| ''`, a raw label (a `List` of lines, a number, any value). See Risk R2 |
| `_getRotation()`, `_getCircumference()`, `_getRotationExtents()`, `_circumference(i, reset)`, `calculateTotal()`, `calculateCircumference(value)`, `getMaxBorderWidth(arcs)`, `getMaxOffset(arcs)`, `_getRingWeightOffset(i)`, `_getRingWeight(i)`, `_getVisibleDatasetWeightTotal()` | :172-401 | none | new. The `_` members keep the underscore: only `controller.doughnut.js` reads them (Chart.js ADR 0012) |

#### On the chart

| Upstream read | First use | Dart (interface / concrete) | Status |
|---|---|---|---|
| `chart.data.datasets` (and `.length`, `[i].weight`) | :191, :392 | `ti:370` `Map<String, Object?> get data` / `cc:870` | ok. Read `datasets` and `weight` with `jsGet` |
| `chart.isDatasetVisible(i)` | :192 | interface: none / `cc:1718` `bool isDatasetVisible(double)` | ok (cast). `types.Chart` does not declare it |
| `chart.getDatasetMeta(i)` | :192 | `ti:388` / `cc:1681` | ok |
| `chart.chartArea` (`width`, `height`, `left`, `right`, `top`, `bottom`) | :213, :217, :262 | `ti:359` `ChartArea? get chartArea`; `types/geometric.dart:64` (`width` :66, `height` :69, TRBL :93-102) | ok. Dart `null` stands for `undefined`: a read throws, as upstream |
| `chart.getDataVisibility(i)` | :250 | `ti:402` / `cc:1751` | ok. See Risk R4 (a string for each call) |
| `chart.options` (`animation`, `locale`) | :260, :324 | `ti:373` / `cc:881` | ok. Read keys with `jsGet` |
| `chart.data.labels` | :323 | `ti:370` | ok |
| `chart.legend.options` (in `overrides.plugins.legend.labels.generateLabels`) | :97 | none | MISSING. `plugin.legend.js` writes `chart.legend` (phase 8) |
| `legend.chart` (in `onClick`) | :126 | none | MISSING (phase 8, the `Legend` class) |
| `legend.chart.toggleDataVisibility(i)` | :126 | interface: none / `cc:1744` | ok (cast) |
| `legend.chart.update()` | :127 | interface: none / `cc:1232` `void update([Object? mode = undefined])` | ok (cast) |

#### On a meta

| Upstream read | First use | Dart (interface / concrete) | Status |
|---|---|---|---|
| `meta._parsed` (assign the array) | :153 | `ti:206` `abstract List<Object?> parsed` / `cc:338` | ok. The `parsing: false` path assigns `getDataset().data`. A Map `data` (object data) throws a `TypeError` at the Dart cast, where upstream assigns the object. Edge case |
| `meta._parsed[i] = value` | :164 | `List<Object?>` write | ok, with a write helper. `dc:547` `_setAt` is private. See Risk R3 |
| `meta.data` | :215 | `ti:119` `List<Element> get data` / `cc:298` | ok |
| `meta.total` (write and read) | :235, :313 | none | MISSING. The concrete `ChartMeta` takes it only by name, in its Map of extra properties (`cc:487`), through `types.PropertyAccess`. `types.ChartMeta` has no `total` |
| `meta.type` | :192 | `ti:81` / `cc:294` | ok |
| `meta.controller` | :193 | `ti:90` `DatasetController? get controller` (the interface) / `cc:308` (concrete) | ok |
| `meta.controller._getRotation()`, `._getCircumference()` | :194-195 | private members of `DoughnutController` | new. Cast the controller to `DoughnutController`. A `PieController` inherits them from the same library |
| `meta.controller.resolveDataElementOptions(i)` | :354 | interface: none / `dc:1501` | ok (cast). The controller of the first visible dataset can be of any type |
| `meta.controller.getStyle(i)` (in `generateLabels`) | :101 | interface: none / `dc:1428` `AnyObject getStyle(double? index, [bool? active])` | ok (cast) |

#### On an element

| Upstream read | First use | Dart (interface / concrete) | Status |
|---|---|---|---|
| `meta.data[i].hidden` | :250, :304 | `types.Element`: none / `core/core.element.dart:237` `Object? hidden = undefined` | ok (cast). Test it with `jsTruthy` |
| `arc.active` | :288 | `types.Element`: none / `core/core.element.dart:208` `bool active` | ok (cast) |
| arc properties `x`, `y`, `startAngle`, `endAngle`, `circumference`, `outerRadius`, `innerRadius`, `options` (through `updateElement`) | :278-288 | `Element.assign` (`core/core.element.dart:359`), `ArcElement.operator []=` (`elements/element.arc.dart`, `circumference`, `startAngle` and the others through `toNumberProp`) | ok. `toNumberProp` takes a `num` or `undefined`. Before the first `update`, `this.innerRadius` is `undefined`: pass the sentinel, not Dart `null` |

#### On element options and on the dataset options

| Upstream read | First use | Dart | Status |
|---|---|---|---|
| `options.borderAlign` | :355 | `eo:886` `ArcOptions.borderAlignValue` | ok |
| `options.borderWidth` | :356 | `eo:910` `ArcOptions.borderWidthValue` | ok |
| `options.hoverBorderWidth` | :356 | not a known key of `ArcOptions` (`eo:842`). The read goes to the extra keys, Dart `null` (JS `undefined`) | ok. `\|\| 0` gives 0, as upstream |
| `options.offset` | :367 | `eo:914` `ArcOptions.offsetValue` | ok |
| `options.hoverOffset` | :367 | not a known key: extra keys | ok |
| `style.backgroundColor`, `.borderDash`, `.borderDashOffset`, `.borderJoinStyle`, `.borderWidth`, `.borderColor`, `.borderRadius` (in `generateLabels`) | :105-115 | `eo:938`, `:894`, `:898`, `:902`, `:910`, `:890`, `:906` | ok |
| `this.options.rotation`, `.circumference`, `.spacing`, `.cutout`, `.radius`, `.animation.animateRotate` | :173, :180, :216, :218, :229, :250 | dataset resolver (`dc:717`) | ok. `jsGet`, then `jsToNumber` or `toPercentage`/`toDimension` |
| `chart.options.animation.animateScale` | :264 | chart resolver | ok. `animation: false` gives `false.animateScale`, JS `undefined`: `jsGet(false, ...)` gives `undefined` too |
| `legend.options.labels.{pointStyle, textAlign, color, useBorderRadius, borderRadius}` | :97 | phase 8 | MISSING (with `chart.legend`) |

### 2.2 controller.pie.js

| Upstream member | Line | Dart | Status |
|---|---|---|---|
| `class PieController extends DoughnutController` | :4 | none | new. `jsClass` with `superclass: DoughnutController.jsClass` |
| `static id = 'pie'` | :6 | none | new |
| `static defaults` | :11-23 | none | new |

Pie has no other member. It inherits `overrides` and `descriptors` through the static prototype
chain of `JsClass` (`js/js_class.dart`, `operator []`), as the manifest shows
(`overrides.pie.*`, `descriptors.datasets.pie.*`). `_registerDefaults`
(`core/core.typedRegistry.dart:178`) merges the defaults of `datasets.doughnut` first, because the
registry registers the parent class first.

### 2.3 controller.polarArea.js

#### On `this`

| Upstream member | First use | Dart declaration | Status |
|---|---|---|---|
| `constructor` | :90-91 | `dc:642` | ok |
| `innerRadius`, `outerRadius` | :93-94 | none | new. The spec reads them (`controller.polarArea.tests.js:171-172`, :199-200, :245-246) |
| `getLabelAndValue(index)` (override) | :97 | `dc:1339` | MISMATCH (raw label, Risk R2) |
| `_cachedMeta` | :98 | `dc:705` | ok |
| `chart` | :99 | `dc:683` | ok |
| `parseObjectData(meta, data, start, count)` (override) | :109 | `dc:1161` returns `List<AnyObject>` | ok. The helper returns `List<Map<String, Object?>>`, the same type |
| `update(mode)` (override) | :113 | `dc:1375` | ok |
| `updateElements(...)` (override and call) | :117, :161 | `dc:1843` | ok |
| `getMinMax()` (override, no parameters upstream) | :123 | `dc:1265` and `ti:461` `({double min, double max}) getMinMax(types.Scale scale, [bool? canStack])` | ok. The Dart override keeps both parameters and ignores them. `Scale.getMinMax` passes them (`core/core.scale.dart:1021`) |
| `getParsed(index)` | :128 | `dc:1199` `Object? getParsed(double index)` | ok. `.r` is the parsed read of ADR 0025 §8 |
| `_updateRadius()` | :147 | none | new (private) |
| `index` | :157 | `dc:694` | ok |
| `countVisibleElements()` | :173, :216 | none | new (public, `index.d.ts:423`) |
| `_computeAngle(index, mode, defaultAngle)` | :176, :232 | none | new (private) |
| `resolveDataElementOptions(i, mode)` | :201, :234 | `dc:1501` | ok |
| `options.spacing`, `options.spacingMode` (dataset resolver) | :206, :209 | `dc:717` | ok |
| `updateElement` | :212 | `dc:1673` | ok |

#### On the chart

| Upstream read | First use | Dart (interface / concrete) | Status |
|---|---|---|---|
| `chart.data`, `.labels`, `.datasets` | :39-40, :100 | `ti:370` | ok |
| `chart.legend.options` | :41 | none | MISSING (phase 8) |
| `chart.getDatasetMeta(0).controller.getStyle(i)` | :44-45 | interface: none / `dc:1428` | ok (cast) |
| `chart.getDataVisibility(i)` | :54, :130 | `ti:402` | ok |
| `legend.chart.toggleDataVisibility`, `.update` | :66-67 | `cc:1744`, `cc:1232` | MISSING `legend.chart` (phase 8); the members are ok (cast) |
| `chart.options.locale` | :101 | `ti:373` | ok |
| `chart.chartArea` (`right`, `left`, `bottom`, `top`) | :149, :151 | `ti:359` | ok |
| `chart.options.cutoutPercentage` | :154 | chart resolver | ok. A legacy key: usually `undefined` |
| `chart.getVisibleDatasetCount()` | :155 | interface: none / `cc:1713` `double getVisibleDatasetCount()` | ok (cast) |
| `chart.options.animation.animateScale`, `.animateRotate` | :165, :186, :189 | chart resolver | ok |

#### On a meta and on the radial scale

| Upstream read | First use | Dart (interface / concrete) | Status |
|---|---|---|---|
| `meta._parsed[index].r` | :101 | `ti:206` and `jsGet(item, 'r')` | ok. An index without an item gives `undefined`, and the read of `.r` throws a `TypeError`, as `jsGet(undefined, ...)` does |
| `meta.data` (`forEach`, `length`) | :114, :127 | `ti:119` | ok |
| `meta.rScale` | :166 | `ti:173` `abstract Scale? rScale` | ok. The radial members need `types.RadialLinearScale` |
| `scale.xCenter` | :167 | `types.RadialLinearScale`: none / `rl:826` `double xCenter` | MISSING interface (ADR 0025 §5) |
| `scale.yCenter` | :168 | `rl:830` | MISSING interface |
| `scale.getIndexAngle(0)` | :169 | `rl:955` `double getIndexAngle(double index)` | MISSING interface |
| `scale.getDistanceFromCenterForValue(value)` | :182 | `rl:967` `double getDistanceFromCenterForValue(Object? value)` | MISSING interface |

`RadialLinearScale` (`rl:731`) does not implement a `types.RadialLinearScale` yet. ADR 0025 §5
gives the interface and its five members.

#### On an element and on its options

| Upstream read | First use | Dart | Status |
|---|---|---|---|
| `arc.active` | :201 | `core/core.element.dart:208` | ok (cast) |
| `properties.options.spacing` (read `=== 0`, write) | :205-206 | `eo:918` `spacingValue`; write through `ElementOptions.operator []=` | ok. The options are a clone (no option sharing): the write does not meet the frozen state |
| `properties.options.spacingMode` (read `=== 'angular'`, write) | :208-209 | `eo:922` `spacingModeValue` | ok |
| `resolveDataElementOptions(index, mode).angle` | :234 | `eo:926` `angleValue` | ok |
| `style.backgroundColor`, `.borderColor`, `.borderWidth` (in `generateLabels`) | :49-52 | `eo:938`, `:890`, `:910` | ok |
| arc properties `x`, `y`, `innerRadius`, `outerRadius`, `startAngle`, `endAngle`, `options` | :194-202 | `Element.assign`, `ArcElement.operator []=` | ok |

### 2.4 controller.radar.js

| Upstream read | First use | Dart (interface / concrete) | Status |
|---|---|---|---|
| `getLabelAndValue(index)` (override) | :39 | `dc:1339` | MISMATCH (raw label: `vScale.getLabels()[index]` without `\|\| ''`, also `undefined` past the labels, Risk R2) |
| `_cachedMeta.vScale` | :40 | `ti:181` | ok |
| `getParsed(index)` | :41 | `dc:1199` | ok |
| `vScale.getLabels()` | :44 | `ti:585` / `core/core.scale.dart:1082` | ok |
| `vScale.getLabelForValue(parsed[vScale.axis])` | :45 | `ti:563` `Object? getLabelForValue(Object? value)` / `scales/scale.linearbase.dart:546` | ok. `'' +` is `jsToString`. The read `parsed[axis]` keeps `undefined` (ADR 0025 §8) |
| `vScale.axis` | :45 | `ti:525` | ok |
| `parseObjectData` (override) | :49 | `dc:1161` | ok |
| `update(mode)` (override) | :53 | `dc:1375` | ok |
| `meta.dataset` | :55 | `ti:125` `abstract Element? dataset` | ok |
| `meta.data \|\| []` | :56 | `ti:119` | ok (always a List) |
| `meta.iScale.getLabels()` | :57 | `ti:177`, `ti:585` | ok |
| `line.points = points` | :60 | `types.LineElement.points` (`ti:861`) has no setter / concrete setter `elements/element.line.dart:828`, by name `:1152` | ok (cast). `meta.data` is a `List<types.Element>`: pass `points.cast<types.PointElement>()`, as the gallery controller does (`apps/chartjs_gallery/lib/demo/stress_point_controller.dart:139`) |
| `resolveDatasetElementOptions(mode)` | :63 | `dc:1490` | ok |
| `this.options.showLine` | :64 | `dc:717` | ok |
| `options.borderWidth = 0` | :65 | `LineOptions` known key (`eo:543`, getter `eo:603`), write through `operator []=` | ok. The options are a clone (index `undefined`, no sharing) |
| properties `_loop`, `_fullLoop`, `options` | :69-71 | `elements/element.line.dart:1146-1148` (by name), `set loop` :760, `set fullLoop` :770 | ok |
| `updateElement(line, undefined, ...)` | :74 | `dc:1673` (`index` Dart `null`) | ok |
| `updateElements(points, ...)` | :78, :81 | `dc:1843` | ok |
| `_cachedMeta.rScale` | :82 | `ti:173` | ok, with `types.RadialLinearScale` |
| `point.active` | :87 | `core/core.element.dart:208` | ok (cast) |
| `resolveDataElementOptions(i, mode)` | :87 | `dc:1501` | ok |
| `scale.getPointPositionForValue(i, value)` | :88 | `rl:1029` `({double x, double y, double angle}) getPointPositionForValue(double index, Object? value)` | MISSING interface (ADR 0025 §5) |
| `this.getParsed(i).r` | :88 | `jsGet` | ok (ADR 0025 §8) |
| `scale.xCenter`, `scale.yCenter` | :90-91 | `rl:826`, `rl:830` | MISSING interface |
| `pointPosition.x`, `.y`, `.angle` | :90-96 | record fields | ok |
| point properties `x`, `y`, `angle`, `skip`, `options` | :93-99 | `elements/element.point.dart:325` (`angle`), `:313` (`skip`), `Element` (`x`, `y`, `options`) | ok |

### 2.5 Interface members: summary

| Interface (`ti`) | Member | Declared now | First reader |
|---|---|---|---|
| `Chart` | `isDatasetVisible(double)` | no | doughnut :192 |
| `Chart` | `getVisibleDatasetCount()` | no | polarArea :155 |
| `Chart` | `toggleDataVisibility(double)` | no | doughnut :126, polarArea :66 (through `legend.chart`) |
| `Chart` | `update([mode])` | no | doughnut :127, polarArea :67 (through `legend.chart`) |
| `Chart` | `legend` | no (no concrete member either) | doughnut :97, polarArea :41 |
| `Chart` | `data`, `options`, `chartArea`, `getDatasetMeta`, `getDataVisibility` | yes | |
| `ChartMeta` | `total` | no (no typed concrete field either) | doughnut :235, :313 |
| `ChartMeta` | `data`, `parsed`, `type`, `controller`, `dataset`, `rScale`, `iScale`, `vScale` | yes | |
| `DatasetController` | `getStyle(index, [active])` | no | doughnut :101, polarArea :45 |
| `DatasetController` | `resolveDataElementOptions(index, [mode])` | no | doughnut :354 |
| `DatasetController` | `parsing`, `cachedMeta`, `getMinMax` | yes | |
| `Element` | `active` | no | doughnut :288, polarArea :201, radar :87 |
| `Element` | `hidden` | no | doughnut :250, :304 |
| `LineElement` | `points` setter | no (getter only) | radar :60 |
| `Scale` | `getLabels`, `getLabelForValue`, `axis` | yes | |
| `RadialLinearScale` | the interface itself, with `xCenter`, `yCenter`, `getIndexAngle`, `getDistanceFromCenterForValue`, `getPointPositionForValue` | no | polarArea :166-182, radar :82-91 |

The `ok (cast)` members can stay casts to the concrete classes (`Element`, `DatasetController`,
`Chart`). A cast of the chart imports `core.controller.dart`, which upstream does not import
(only the JSDoc typedef at doughnut :6-8). Chart.js ADR 0003 prefers the interface member with
its first ported caller.

## 3. JS builtins and semantics points

| Upstream form | Line | Dart form | Note |
|---|---|---|---|
| `+data[i]` | doughnut :155 | `jsToNumber(data[i])` | A string gives its number, `null` gives 0, `undefined` NaN |
| `isObject(data[start])` | doughnut :157 | `isObject` (Map `<String, Object?>` only) | |
| `const {key = 'value'} = this._parsing` | doughnut :158 | `jsGet(parsing, 'key')`, `undefined` gives `'value'` | `parsing: true` gives `undefined`. A `null` parsing throws a `TypeError` in both |
| `+resolveObjectKey(data[i], key)` | doughnut :159 | `jsToNumber(resolveObjectKey(...))` | A key that is not a string throws |
| `meta._parsed[i] = v` | doughnut :164 | a List write with the append rule of `_setAt` (`dc:547`, private) | Risk R3 |
| `this.options.rotation - 90`, `toRadians(this.options.circumference)` | doughnut :173, :180 | `jsToNumber(jsGet(options, ...))` | |
| `Math.cos`, `Math.sin` | doughnut :19-22 | `dart:math` | Pixels only (Chart.js ADR 0009) |
| `Math.max`, `Math.min` (2 and 3 arguments) | doughnut :23-24, :197-198, :217-218, :228-230, :356, :367, :392; polarArea :151-154 | `jsMax`, `jsMin` (`js/js_math.dart:85`, :101), chained for 3 arguments | NaN and -0 rules. The arguments get `ToNumber` |
| `x \|\| 0` before `Math.max` | doughnut :356, :367 | `jsOrZero` (`js/js_number.dart:71`) | |
| `this._getRingWeightOffset(n) \|\| 1` | doughnut :400 | `jsTruthy(t) ? t : 1` | 0 and NaN give 1 |
| `valueOrDefault(dataset.weight, 1)` | doughnut :392 | `valueOrDefault(jsGet(dataset, 'weight'), 1)`, then `jsToNumber` | A Map read gives Dart `null` for an absent key: then `Math.max(null, 0)` gives 0, not 1. Use `jsGet` |
| `meta._parsed[i] === null` | doughnut :250 | `== null` on the item. The `undefined` sentinel is not `null` | |
| `reset && opts.animation.animateRotate` | doughnut :250 | `jsTruthy(jsGet(jsGet(options, 'animation'), 'animateRotate'))` | `animation: false` gives `undefined` |
| `meta._parsed[i] * circumference / TAU` | doughnut :253 | `jsToNumber(item) * c / tau` | `parsing: false` keeps raw data items |
| `value !== null && !isNaN(value)` | doughnut :304, :314 | `value != null && !jsIsNaN(value)` (`js/js_number.dart:46`) | `isNaN` coerces |
| `Math.abs(value)` | doughnut :305, :315 | `jsToNumber(value).abs()` | |
| `chart.data.labels \|\| []`, `labels[index] \|\| ''` | doughnut :323, :327; polarArea :100, :104 | `jsTruthy` and a List read that gives `undefined` past the end | Raw label value (Risk R2) |
| `formatNumber(meta._parsed[index], locale)` | doughnut :324 | `formatNumber(jsToNumber(item), jsGet(chart.options, 'locale'))` | `Intl.NumberFormat.format(null)` gives `'0'`, `undefined` gives `'NaN'`: `jsToNumber` gives the same |
| `formatNumber(meta._parsed[index].r, locale)` | polarArea :101 | `jsToNumber(jsGet(item, 'r'))` | |
| `options.borderAlign !== 'inner'` | doughnut :355 | `!=` on the raw value | |
| `useBorderRadius && (borderRadius \|\| style.borderRadius)` | doughnut :115 | JS `&&` and `\|\|` give operand values, not booleans | Keep the operand value |
| `data.labels.length && data.datasets.length` | doughnut :98, polarArea :40 | `jsTruthy` of the lengths | Throws for `undefined` labels, as upstream |
| `opts.cutoutPercentage ? (r / 100) * opts.cutoutPercentage : 1` | polarArea :154 | `jsTruthy`, `jsToNumber` | |
| `360 / this.countVisibleElements()` | polarArea :173 | `double` division | 0 elements gives `Infinity` |
| `angle \|\| defaultAngle` | polarArea :234 | `jsTruthy(a) ? jsToNumber(a) : defaultAngle` | |
| `!isNaN(parsed)`, `parsed < range.min` | polarArea :130-136 | `jsIsNaN`, then compare `jsToNumber(parsed)` | A `null` parsed value (scale `parse` of missing data) passes `!isNaN` and compares as 0. Upstream stores `null` in the range. Every reader applies `ToNumber` (`Scale.getMinMax`, `core/core.scale.dart:1021-1027`, `jsMin`/`jsMax`). Thus the record value 0 gives the same result |
| `this.getParsed(i).r` | polarArea :128, :182, :221; radar :88 | the parsed read of ADR 0025 §8: `undefined` for an absent key | `_parsedValue` (`dc:564`) gives Dart `null`. Phase 7 chooses the name and the file of the function (ADR 0025 §8) |
| `parsed[vScale.axis]` | radar :45 | the same parsed read | |
| `properties.options.spacing === 0`, `spacingMode === 'angular'` | polarArea :205, :208 | `value is num && value == 0`; `== 'angular'` | `-0 === 0` is true, and Dart `-0.0 == 0` is true. A string `'0'` is not 0 |
| `'' + value` | radar :45 | `jsToString` | |
| `isNaN(x) \|\| isNaN(y)` | radar :97 | `x.isNaN \|\| y.isNaN` (doubles) | |
| `labels.length === points.length` | radar :70 | `int ==` | |
| `meta.data.forEach((e, i) => ...)` | polarArea :127, :220 | a `for` loop | |
| `_parseObjectDataRadialScale.bind(this)(...)` | polarArea :110, radar :50 | `jsCall(parseObjectDataRadialScale, [meta, data, start, count], thisArg: this)` | Five arguments: `Function.apply` on the VM, once for each `parse` call |

No file uses `sort`, `Date.now()`, `Object.keys` or `splice`. Thus `jsSort`, `jsDateNow`,
`jsObjectKeys` and `jsSplice` are not needed. The key order of each `properties` object literal
is the order of `Element.assign` (Chart.js ADR 0017 §6) and of the animations. Keep the literal
order: doughnut :278-288, polarArea :194-202, radar :68-72 and :93-99.

## 4. Option defaults, overrides and descriptors

Numbers become `double` values (Chart.js ADR 0010). Nested Maps have the type
`<String, Object?>`. The functions of `overrides` are Dart closures (Chart.js ADR 0006).

| Class | Static | Lines | Keys and values |
|---|---|---|---|
| `DoughnutController` | `id` | :39 | `'doughnut'` |
| `DoughnutController` | `defaults` | :44-78 | `datasetElementType: false`, `dataElementType: 'arc'`, `animation: {animateRotate: true, animateScale: false}`, `animations.numbers: {type: 'number', properties: ['circumference', 'endAngle', 'innerRadius', 'outerRadius', 'startAngle', 'x', 'y', 'offset', 'borderWidth', 'spacing']}`, `cutout: '50%'`, `rotation: 0`, `circumference: 360`, `radius: '100%'`, `spacing: 0`, `spacingMode: 'angular'` (#12238), `indexAxis: 'r'` |
| `DoughnutController` | `descriptors` | :80-83 | `_scriptable: (name) => name !== 'spacing' && name !== 'spacingMode'`, `_indexable: (name) => name !== 'spacing' && name !== 'spacingMode' && !name.startsWith('borderDash') && !name.startsWith('hoverBorderDash')` (#12238 adds `spacingMode`) |
| `DoughnutController` | `overrides` | :88-131 | `aspectRatio: 1`, `plugins.legend.labels.generateLabels(chart)` (:95-122), `plugins.legend.onClick(e, legendItem, legend)` (:125-128) |
| `PieController` | `id` | :6 | `'pie'` |
| `PieController` | `defaults` | :11-23 | `cutout: 0`, `rotation: 0`, `circumference: 360`, `radius: '100%'` |
| `PieController` | `overrides`, `descriptors` | inherited | from `DoughnutController` through `JsClass.superclass` |
| `PolarAreaController` | `id` | :6 | `'polarArea'` |
| `PolarAreaController` | `defaults` | :11-27 | `dataElementType: 'arc'`, `animation: {animateRotate: true, animateScale: true}`, `animations.numbers: {type: 'number', properties: ['x', 'y', 'startAngle', 'endAngle', 'innerRadius', 'outerRadius']}`, `indexAxis: 'r'`, `startAngle: 0`, `spacing: 0`, `spacingMode: 'proportional'` (#12238) |
| `PolarAreaController` | `overrides` | :32-88 | `aspectRatio: 1`, `plugins.legend.labels.generateLabels` (:38-62), `plugins.legend.onClick` (:65-68), `scales.r: {type: 'radialLinear', angleLines: {display: false}, beginAtZero: true, grid: {circular: true}, pointLabels: {display: false}, startAngle: 0}` |
| `RadarController` | `id` | :6 | `'radar'` |
| `RadarController` | `defaults` | :11-21 | `datasetElementType: 'line'`, `dataElementType: 'point'`, `indexAxis: 'r'`, `showLine: true`, `elements: {line: {fill: 'start'}}` |
| `RadarController` | `overrides` | :26-34 | `aspectRatio: 1`, `scales.r: {type: 'radialLinear'}` |

- `doc/upstream/manifest.json` (`defaults.values`) lists all these keys, also
  `overrides.pie.*` and `descriptors.datasets.pie.*`. The function values carry hashes:
  `generateLabels` of doughnut and pie `e8dc15b7fcd5`, of polarArea `0ccf40536945`, `onClick`
  `50182dc8b78b`.
- No controller has `defaultRoutes`.
- `jsClass` of each controller (Chart.js ADR 0020 §3): `superclass: DatasetController.jsClass`
  (pie: `DoughnutController.jsClass`), the statics in the upstream order of declaration
  (`id`, `defaults`, then `descriptors` and `overrides` for doughnut, `defaults`, `overrides` for
  polarArea and radar), and a `construct` closure that passes `newTarget`
  (`controllerArgs`, `dc:611`).
- No static or instance name collides: `DatasetController` has no instance `id`, `defaults`,
  `overrides` or `descriptors`.

## 5. Element types

| Controller | `dataElementType` | `datasetElementType` | Dart element class |
|---|---|---|---|
| doughnut | `'arc'` | `false` (no dataset element) | `elements/element.arc.dart:818` `ArcElement`, options `ArcOptions` (`eo:815`) |
| pie | `'arc'` (inherited) | `false` (inherited) | as doughnut |
| polarArea | `'arc'` | not set: `undefined` | `ArcElement` |
| radar | `'point'` | `'line'` | `elements/element.point.dart:123` `PointElement` (`PointOptions`), `elements/element.line.dart:635` `LineElement` (`LineOptions`) |

- `buildOrUpdateControllers` (`cc:1186-1193`) writes the class values with `jsAssign` from
  `defaults.datasets[type]`. The polarArea `undefined` stays `undefined`: the instance field
  `datasetElementType` (`dc:770`) is the sentinel, which is falsy.
- `resolveDatasetElementOptions` of a polarArea controller reads `undefined.id` and throws a
  `TypeError` (`dc:591` `_idOf`), as upstream. `getStyle(undefined)` does not reach it, because
  `meta.dataset` is `null` (`dc:1435`).
- `createElementOptions` (`eo:1103`) gives `ArcOptions` for `'arc'`, `LineOptions` for
  `'line'` and `PointOptions` for `'point'`.

## 6. Risks for the port

### R1. Interface gaps and casts

Fifteen interface members are absent (section 2.5): four of `types.Chart`, `ChartMeta.total`,
two of `types.DatasetController`, two of `types.Element`, the `points` setter of
`types.LineElement`, and `types.RadialLinearScale` with five members. ADR 0025 §5 fixes the forms
of the radial members. The others need a choice: an interface member (Chart.js ADR 0003, a change
of a shared layer) or a cast to the concrete class. `ChartMeta.total` also has no typed concrete
field. The by-name write `meta['total']` goes to the Map of extra properties (`cc:487`), and
`calculateCircumference` reads it for each arc.

### R2. The label of `getLabelAndValue`

`dc:1339` returns `({String label, String value})`. Doughnut (:327), polarArea (:104) and radar
(:44) return the raw label: a `List` of lines, a number, or `undefined` (radar past the end of the
labels). The tooltip of phase 8 uses `item.label` for its title, and a `List` gives a title with
several lines. A `String` label changes that output. The record needs `Object? label`. This
changes the base class and the bar, bubble and scatter overrides of the other scout.

### R3. Writes and reads of the parsed items

- Doughnut `parse` writes numbers into `meta.parsed` by index (:164). The append rule of `_setAt`
  is private in `dc:547`, and `_item` (`dc:511`) is private too. The doughnut file needs a public
  helper or the same rule.
- With `parsing: false`, doughnut assigns `getDataset().data` to `meta.parsed` (:153). A Map
  `data` throws at the Dart cast, where upstream assigns the object.
- The read `getParsed(i).r` and `parsed[vScale.axis]` must give `undefined` for an absent key
  (ADR 0025 §8). Phase 7 chooses the name and the file of that function. Three private copies of
  `_parsedValue` exist (`dc:564`, `core/core.interaction.dart:148`,
  `helpers/helpers.extras.dart`), and they give Dart `null`.

### R4. Costs in the hot loops

- `Chart.getDataVisibility` (`cc:1751`) makes a string with `jsNumberToString(index)` for each
  call. polarArea calls it up to four times for each arc in one update (`getMinMax`,
  `countVisibleElements`, `_computeAngle`, `updateElements`). Doughnut calls it twice for each
  arc (`calculateTotal`, `_circumference`).
- polarArea and radar have no option sharing. Each `resolveDataElementOptions` call returns a
  `clone` of the cache entry (`dc:1528`). polarArea calls it twice for each arc (`_computeAngle`
  and `updateElements`), and once more for each arc before `start`.
- `_resolveElementOptions` builds the cache key `'$typeName-$resolvedMode'` for each call
  (`dc:1524`). Doughnut calls it three times for each arc in one update (`getMaxBorderWidth`,
  `getMaxOffset`, and `updateElements` without shared options).
- Doughnut `_circumference` reads `this.options.circumference` through the resolver for each arc
  (:249). A scriptable value runs once for each arc, as upstream.
- polarArea reads `this.options.spacing` and `this.options.spacingMode` through the resolver for
  each arc where the condition holds (:206, :209).
- `parseObjectDataRadialScale` reads each item with `jsGet(data, jsNumberToString(index))`
  (`helpers/helpers.config.dart`, the closure at :906). This makes and parses a string for each
  item.
- A change of these shared layers needs an A/B measurement (porting-flow.md §1.1, the kickstart
  decision protocol).

### R5. The #12238 parts (spacing modes)

- `ArcElement` and `ArcOptions` already have `spacingMode` (`elements/element.arc.dart:128`,
  :391-496; `eo:922`). The controllers bring the defaults (doughnut :71-75, polarArea :25-26),
  the doughnut descriptors (:81-82) and the polarArea hunk (:204-210).
- The polarArea hunk writes into the options object of `resolveDataElementOptions`. That object
  is writable only because polarArea has no option sharing: a cached shared object is frozen
  (Chart.js ADR 0021 §5), and a write then throws a `TypeError`.
- The hunk compares with `=== 0` and `=== 'angular'`. In the scope order of
  `getOptionScopes` (`core.config.js:296-325`), the dataset defaults `datasets.polarArea` come
  before `elements.arc`. The case that the hunk fixes is thus not clear from the source. A probe
  on the pinned build must pin the resolved `spacing` and `spacingMode` with and without the hunk.
- The pin brings 3 spec cases (`controller.doughnut.tests.js:49`, `controller.polarArea.tests.js:69`,
  `:85`) and fixtures (`controller.doughnut/doughnut-spacing*.js`, `selfJoin/*`).

### Other risks

- The legend overrides (`generateLabels`, `onClick`) read `chart.legend` and `legend.chart` of
  phase 8. Until then, only a direct call of the closure can test them. The spec cases
  "should not override tooltip title and label callbacks" need the tooltip of phase 8.
- `getMaxBorderWidth(arcs)` with an `arcs` argument reads `controller` before any write
  (:354). Upstream then throws a `TypeError` for a non-empty `arcs`. The Dart port must keep the
  throw (a `!` on Dart `null` throws a `TypeError`).
- Doughnut reads `controller._getRotation()` of the other datasets of the same type (:194-195).
  The Dart form casts the controller to `DoughnutController`. A user controller registered as
  `'doughnut'` that is not a `DoughnutController` throws a `TypeError`, as upstream does when the
  method is absent.
- The fields `innerRadius`, `outerRadius`, `offsetX` and `offsetY` start as `undefined`. A new
  arc of a reset before the first `update` gets `x: centerX + undefined` (NaN) and
  `innerRadius: undefined`. A `double` field with NaN gives the NaN of `x`, but the arc must get
  the sentinel for `innerRadius` to keep the `undefined` state of the element.
- The ADR 0023 survey finds no new collision. `update`, `parse`, `linkScales`, `updateElements`,
  `getLabelAndValue`, `parseObjectData` and `getMinMax` are overrides with the base signatures.
  The polarArea `getMinMax()` takes no parameters upstream. The Dart override must keep the
  parameters of `dc:1265`.
- 29 skipped spec cases wait for these controllers: `'blocked: controller.radar'` 17 times,
  `'blocked: controller.pie'` 7 times, `'blocked: controller.polarArea'` 4 times and
  `'blocked: controller.doughnut'` once. They are in `test/specs/scale.radialLinear_test.dart`,
  `core.controller_test.dart`, `core.interaction_test.dart`, `core.datasetController_test.dart`
  and `platform.dom_test.dart`.
- The controller fixtures are many: `test/fixtures/controller.doughnut` (57 files),
  `controller.polarArea` (54 files) and `controller.radar` (45 files).
