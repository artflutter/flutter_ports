# Phase 7 scout: members of the cartesian controllers

This file is the dependency inventory of four upstream files at the pin `v4.5.1+7169e651`:

- `third_party/Chart.js/src/controllers/controller.bar.js` (682 lines)
- `third_party/Chart.js/src/controllers/controller.line.js` (143 lines)
- `third_party/Chart.js/src/controllers/controller.scatter.js` (179 lines)
- `third_party/Chart.js/src/controllers/controller.bubble.js` (169 lines)

The upstream ledger has no row after v4.5.1 that changes these four files. The specs of the
manifest have 55 cases (`controller.bar.tests.js`), 34 cases (`controller.line.tests.js`), 6 cases
(`controller.scatter.tests.js`) and 11 cases (`controller.bubble.tests.js`).

All Dart paths are relative to `packages/flutter_chartjs/lib/src/`. "types" is
`types/index.dart`. "DC" is `core/core.datasetController.dart`. "Scale" without a prefix is the
concrete class of `core/core.scale.dart`.

Status words:

- **OK**: the Dart declaration exists and the controller can call it as it is.
- **CONCRETE**: the concrete class has the member, but the type interface that the controller
  reaches does not declare it. The port adds the member to the interface (Chart.js ADR 0003, a
  member with its first caller) or casts the receiver to the concrete class.
- **ADAPT**: the declaration exists, but its signature or type does not accept the upstream call
  as it is. The port needs a conversion or a change.
- **MISSING**: no Dart declaration exists.

## 1. Imports

| Upstream import | Symbol | Dart counterpart | Status |
|---|---|---|---|
| bar:1, line:1, scatter:1, bubble:1 | `DatasetController` | DC:626 `class DatasetController` | OK |
| bar:3 | `_arrayUnique` | `helpers/helpers.collection.dart:364` `arrayUnique<T>` | OK |
| bar:3 | `isArray` | `helpers/helpers.core.dart:69` | OK |
| bar:3, line:2, scatter:2 | `isNullOrUndef` | `helpers/helpers.core.dart:55` | OK |
| bar:4, bubble:2 | `valueOrDefault` | `helpers/helpers.core.dart:129` (only the `undefined` sentinel is `undefined`) | OK |
| bar:4 | `resolveObjectKey` | `helpers/helpers.core.dart:511` | OK |
| bar:4 | `sign` | `helpers/helpers.math.dart:48` `double sign(double x)` | OK |
| bar:4 | `defined` | `helpers/helpers.core.dart:535` | OK |
| line:3, scatter:3 | `isNumber` | `helpers/helpers.math.dart:116` | OK |
| line:4, scatter:4 | `_getStartAndCountOfVisiblePoints` | `helpers/helpers.extras.dart:207` `getStartAndCountOfVisiblePoints(ChartMeta, List<PointElement>, bool)` | ADAPT: `meta.data` is `List<types.Element>`, and `chart.animationsDisabled` is `bool?` |
| line:4, scatter:4 | `_scaleRangesChanged` | `helpers/helpers.extras.dart:338` `scaleRangesChanged` | OK |

MISSING imports: 0.

The Dart files need imports that upstream does not have:

- `core/core.registry.dart` for the singleton `registry` (scatter:105, differences.md row
  `adapt-chart-registry-getter`).
- The concrete element classes (`elements/element.line.dart`, `element.point.dart`,
  `element.bar.dart`) or new members of the type interfaces (section 2.5).
- `core/core.scale.dart` for the concrete `Scale`, or new members of `types.Scale` (section 2.3).
- `core/core.element.dart` for `Element.active`, `Element.hidden` and `Element.assign`, as DC
  already does.

## 2. Members that the controllers read or call

### 2.1 Members of `this` (DatasetController)

| Upstream member | First read | Dart declaration | Status |
|---|---|---|---|
| `_cachedMeta` | bar:346, line:42, scatter:43, bubble:84 | DC:705 `cachedMeta` (`@internal`) | OK |
| `_parsing` (destructuring `{xAxisKey = 'x', yAxisKey = 'y'}`) | bar:326 | DC:723 `parsing` | OK. The default of the destructuring is DC:1188 `_keyOr`, private: MISSING as a shared helper |
| `_type` | bar:436 | DC:710 `type` | OK |
| `_ctx` | bar:677 | DC:689 `ctx` (`CanvasRenderingContext2D?`) | OK (`ctx!` at the draw) |
| `_drawStart`, `_drawCount` (writes) | line:48-49, scatter:63-64 | DC:745 `drawStart`, DC:751 `drawCount` | OK |
| `_getSharedOptions(start, mode)` | bar:399, line:79, bubble:121 | DC:1650 `getSharedOptions_` (Chart.js ADR 0023) | OK |
| `getSharedOptions(options)` | scatter:115 | DC:1619 | OK |
| `includeOptions(mode, shared)` | scatter:116 | DC:1634 | OK |
| `updateSharedOptions(...)` | scatter:150 | DC:1694 | OK |
| `_resolveAnimations` | not called directly; `updateElement` and `updateSharedOptions` call it | DC:1575 `resolveAnimations` | OK |
| `index` | bar:395, line:58, scatter:81 | DC:694 | OK |
| `options` (dataset resolver) | bar:533, line:63, scatter:71 | DC:717 `late AnyObject options` | OK (read with `jsGet`) |
| `chart` | bar:494, line:45 | DC:683 `types.Chart chart` | OK |
| `enableOptionSharing` | bar:380, line:36, bubble:38 | DC:754 | OK |
| `supportsDecimation` | line:37 | DC:757 | OK |
| `datasetElementType` (read and write) | scatter:74, :94, :105 | DC:770 `Object? datasetElementType` | OK |
| `initialize()` (override, `super`) | bar:379, line:35, bubble:37 | DC:777 | OK. The base constructor calls it (DC:651) |
| `addElements()` (override, `super`) | scatter:75, :101, :108 | DC:946 | OK |
| `getDataset()` | bar:385, :648 | DC:859 (`Object?`, `undefined` when absent) | OK |
| `parsePrimitiveData` (override, `super`) | bar:306, bubble:47 | DC:1083 `List<AnyObject>` | OK |
| `parseArrayData` (override, `super`) | bar:315, bubble:59 | DC:1123 | OK |
| `parseObjectData` (override, `super`) | bar:324, bubble:72 | DC:1161 | OK |
| `getParsed(index)` | bar:367, line:87, scatter:46, bubble:100 | DC:1199 `Object? getParsed(double)` | OK |
| `applyStack(scale, parsed, mode)` | bar:571, line:101, scatter:130 | DC:1218 `Object? applyStack(...)` (number, string or `undefined`) | OK |
| `updateRangeFromParsed` (override, `super`) | bar:343-344 | DC:1234 `(MinMax, types.Scale, Object?, DatasetStack?)` | OK |
| `getMaxOverflow()` (override) | bar:357, line:125, scatter:156, bubble:83 | DC:1330 `Object? getMaxOverflow()` | OK |
| `getLabelAndValue(index)` (override) | bar:364, scatter:42, bubble:96 | DC:1339 `({String label, String value})` | ADAPT: scatter:51 and bubble:106 return `labels[index] \|\| ''`, a raw label (a string, an array of lines or a number). The record type `String label` does not accept it |
| `update(mode)` (override) | bar:388, line:41, scatter:56, bubble:111 | DC:1375 `void update(String mode)` | OK |
| `updateElements(...)` (override) | bar:393, line:76, scatter:111, bubble:118 | DC:1843 `(List<types.Element>, double, double, String)` | OK |
| `updateElement(el, index, props, mode)` | bar:423, line:67, scatter:87, bubble:142 | DC:1673 `(Element, double?, AnyObject, String)` | OK. The argument is the concrete `Element`: a cast of `meta.data[i]` |
| `resolveDatasetElementOptions(mode)` | line:62, scatter:85 | DC:1490 | OK |
| `resolveDataElementOptions(index, mode)` (bubble override, `super`) | bar:418, line:111, bubble:49, :151 | DC:1501 `AnyObject (double, [String?])` | OK |
| `draw()` (override, `super`) | bar:668, line:141 | DC:1383 | OK |
| `_getStacks(last, dataIndex)` | bar:434 | bar own, private | new member; only bar reads it |
| `_getStackCount(index)` | bar:485 | none | new member. `controller.bar.tests.js:85-307` and `:1803` read it: `getStackCount` with `@internal` (Chart.js ADR 0012) |
| `_getStackIndex(ds, name, dataIndex)` | bar:518 | none | new member. `controller.bar.tests.js:325-575` reads it: `getStackIndex` with `@internal` |
| `_getAxisCount()`, `_getAxis()`, `_getRuler()`, `_calculateBarValuePixels()`, `_calculateBarIndexPixels()` | bar:489-666 | none | new members; only bar reads them: they keep the `_` |
| `getFirstScaleIdForIndexAxis()` | bar:493 | none | new public member. DC:378 `_getFirstScaleId` has the same body for one axis, but it is private |

### 2.2 Members of the chart

| Upstream member | First read | Dart declaration | In `types.Chart` |
|---|---|---|---|
| `_animationsDisabled` | line:45, scatter:60 | `core/core.controller.dart:818` `bool? animationsDisabled` | yes, types:317 (`bool?`) |
| `chartArea` | line:140 | `core/core.controller.dart:768` | yes, types:359 (`ChartArea?`) |
| `scales` | bar:494 | `core/core.controller.dart` | yes, types:365 `Map<String, Scale>` |
| `options.indexAxis` | bar:495 | `core/core.controller.dart:881` `options` | yes, types:373 (read with `jsGet`) |
| `data.datasets`, `data.labels` | bar:502, scatter:44, bubble:98 | `core/core.controller.dart:870` `data` | yes, types:370 |
| `getDataVisibility(index)` | bar:592 | `core/core.controller.dart:1751` | yes, types:402 |
| `registry.getElement('line')` | scatter:105 | no instance getter. `core/core.registry.dart:256` `registry`, `:125` `getElement` | no, by design (row `adapt-chart-registry-getter`) |

MISSING chart members: 0.

### 2.3 Members of a scale (`types.Scale`)

The controllers reach each scale through `meta.iScale`, `meta.vScale`, `meta.xScale` or
`meta.yScale`, which are `types.Scale?`. Chart.js ADR 0025 §5 fixes the Dart forms of the phase 7
members.

| Upstream member | First read | Concrete declaration | In `types.Scale` |
|---|---|---|---|
| `_cache` (`$bar`) | bar:8 | Scale:886 `AnyObject cache` (`@internal`) | **no** (ADR 0025 §5: `Map<String, Object?> get cache`) |
| `getMatchingVisibleMetas(type)` | bar:9 | Scale:2863 | yes, types:536 |
| `_length` | bar:27 | Scale:824 `length` | yes, types:546 |
| `getPixelForValue(value, index)` | bar:42, line:100 | Scale:1873 and the overrides | yes, types:574 |
| `ticks` | bar:47 | Scale:809 `List<Tick>? ticks` | **no** (ADR 0025 §5) |
| `getPixelForTick(i)` | bar:48 | Scale:1897 `double? getPixelForTick(int)`; `scales/scale.category.dart:400`, `scales/scale.time.dart:938` | **no** (ADR 0025 §5) |
| `parse(raw, index)` | bar:118, :164 | Scale:975 | yes, types:577 |
| `axis` | bar:132 | Scale:766 | yes, types:525 |
| `getLabels()` | bar:156 | Scale:1082 | yes, types:585 |
| `isHorizontal()` | bar:178 | Scale:1687 | yes, `types/layout.dart:103` (through `LayoutItem`) |
| `min` | bar:178 | Scale:789 | yes, types:528 |
| `getLabelForValue(value)` | bar:371, scatter:47 | Scale:1858 and the overrides | yes, types:563 |
| `getBasePixel()` | bar:396, line:101, bubble:130 | Scale:1938; `scales/scale.category.dart:416` | **no** (ADR 0025 §5) |
| `options.stacked` | bar:438 | Scale `options` | yes, types:556 (read with `jsGet`: bar:463 tests `=== undefined`) |
| `_startPixel`, `_endPixel` | bar:549-550 | Scale:838, :843 `startPixel`, `endPixel` (`@internal`) | **no** (ADR 0025 §5) |
| `getPixelForDecimal(d)` | bar:606, bubble:129 | Scale:1911 | **no** (ADR 0025 §5) |
| `getValueForPixel(pixel)` | bar:615 | Scale:1887 `double?`; `scales/scale.linear.dart:134`, `scales/scale.category.dart:410`, `scales/scale.logarithmic.dart:427`, `scales/scale.time.dart:923`, `scales/scale.timeseries.dart:264` | **no** (ADR 0025 §5) |
| `getLineWidthForValue(value)` | bar:620 | Scale:2584 `double getLineWidthForValue(Object?)` | **no** (ADR 0025 §5) |

Interface members of `types.Scale` that are not declared: 9 (`cache`, `ticks`, `getPixelForTick`,
`getBasePixel`, `startPixel`, `endPixel`, `getPixelForDecimal`, `getValueForPixel`,
`getLineWidthForValue`). Each has a concrete declaration.

The four files read no member of `RadialLinearScale` (`xCenter`, `yCenter`, `drawingArea`,
`getIndexAngle`, `getPointPositionForValue`). Those members belong to the radar and polar area
inventory.

### 2.4 Members of a meta

| Upstream member | First read | Concrete declaration (`core/core.controller.dart`) | In `types.ChartMeta` |
|---|---|---|---|
| `iScale`, `vScale` | bar:25, :154 | :397 `iScale`, :401 `vScale` | yes, types:177, :181 |
| `xScale`, `yScale` | scatter:45, bubble:99 | :385 `xScale`, :389 `yScale` | yes, types:165, :169 |
| `type` | bar:26 | :294 `type` | yes, types:81 |
| `controller` | bar:13, :437, :440 | :308 `DatasetController? controller` | yes, types:90 (`types.DatasetController?`) |
| `stack` (read and write) | bar:385, :462 | :364 `Object? stack` | yes, types:104 |
| `index` | bar:466 | :327 `double index` | yes, types:94 |
| `_parsed` | bar:444 | :338 `parsed` | yes, types:206 |
| `data` | bar:390, line:43 | :298 `List<types.Element> data` | yes, types:119 |
| `dataset` (read and `delete`) | line:43, scatter:77, :93 | :303 `types.Element? dataset` | yes, types:125 (settable: `delete` is a write of `null`) |
| `_dataset` | line:43, :78, scatter:77, :113 | :334 `dataset_` (`@internal`, Chart.js ADR 0023) | **no** |
| `_stacked` | bar:564, line:78 | :369 `stacked` | yes, types:195 |

Interface members of `types.ChartMeta` that are not declared: 1 (`dataset_`).

### 2.5 Members of another controller (`meta.controller`)

| Upstream member | First read | Concrete declaration | In `types.DatasetController` |
|---|---|---|---|
| `getAllParsedValues(scale)` | bar:13 | DC:1312 | yes, types:453 |
| `options.grouped` | bar:437 | DC:717 `options` | **no** |
| `getParsed(dataIndex)` | bar:440 | DC:1199 | **no** |

Interface members of `types.DatasetController` that are not declared: 2 (`options`,
`getParsed`).

### 2.6 Members of the elements and their options

The items of `meta.data` and `meta.dataset` are `types.Element`. DC already casts them to the
concrete `Element` (DC:1403, :1743). The controllers can do the same, or the type interfaces get
the members.

| Upstream member | First read | Concrete declaration | In the type interface |
|---|---|---|---|
| `bars[i].active`, `point.active` | bar:418, line:111 | `core/core.element.dart:208` `bool active` | no (`types.Element` has `x`, `y`, `options`) |
| `rects[i].hidden` | bar:676 | `core/core.element.dart:237` `Object? hidden` | no |
| `bars[i].options` | bar:420 | `core/core.element.dart:216` | yes, types:994 |
| `rects[i].draw(ctx)` | bar:677 | `elements/element.bar.dart:528` | yes, `types.VisualElement` types:779 |
| `line._chart` (write) | line:57, scatter:80 | `elements/element.line.dart:750` setter `chart` | getter only, types:880 |
| `line._datasetIndex` (write) | line:58, scatter:81 | `elements/element.line.dart:784` setter `datasetIndex` | getter only, types:898 |
| `line._decimated` (write) | line:59, scatter:82 | `elements/element.line.dart:733` `bool decimated` | no |
| `line.points = points` | line:60, scatter:83 | `elements/element.line.dart:828` setter, `List<types.PointElement>` | getter only, types:861. ADAPT: `meta.data` is `List<types.Element>` |
| `animated` (through `updateElement`) | line:68, scatter:88 | `elements/element.line.dart:702` `bool animated` | by name only |
| `dataset.options.borderWidth` | line:128, scatter:169 | `LineOptions` `borderWidth` (`elements/element_options.dart:549`) | read with `jsGet` |
| `meta.dataset.updateControlPoints(area, axis)` | line:140 | `elements/element.line.dart:796` | no |
| `data[i].size(options)` | line:133, scatter:163, bubble:88 | `elements/element.point.dart:394` | no |
| point `x`, `y`, `skip`, `stop`, `parsed`, `raw`, `options` (direct write, `properties = point`) | line:91-111, scatter:127-140 | `core/core.element.dart:330` `operator []=`; `elements/element.point.dart:213` `parsed`, `:222` `skip`, `:231` `stop`; `raw` goes to the extras Map | by name. ADAPT: a by-name write of JS `null` to `parsed` throws an `ArgumentError` (`toObjectProp<Object>`), where upstream stores `null` |
| bar `horizontal`, `base`, `x`, `y`, `width`, `height`, `enableBorderRadius`, `borderSkipped`, `inflateAmount`, `options` | bar:407-423 | `elements/element.bar.dart:402`, `:411`, `:417`, `:423`, `:430`, `:446`, `:456` | by name through `assign`. ADAPT: a raw `inflateAmount` option that is not a number (bar:255) throws an `ArgumentError` in `toNumberProp`, where upstream stores it |
| element option `borderSkipped` | bar:203 | `BarOptions` (`elements/element_options.dart:723`) | Map read |
| element option `inflateAmount` | bar:252 | `BarOptions` (`elements/element_options.dart:726`) | Map read |
| line option write `borderWidth = 0`, `segment = ...` | line:64, :66, scatter:86 | `LineOptions` (`elements/element_options.dart:549`, `:558`) | Map write. The result of `resolveDatasetElementOptions` is not frozen (Chart.js ADR 0021 §5) |
| point option write `radius = 0`, `radius += ...` | bubble:138, :163, :165 | `PointOptions` (`elements/element_options.dart:391`) | Map write. `+=` is `jsAdd` |
| `values.$shared` and the copy `Object.assign({}, values, {$shared: false})` | bubble:156-157 | `elements/element_options.dart:1122` `copyOptions` | Chart.js ADR 0021 §3 gives `copyOptions(values)..[r'$shared'] = false` with marker 6 of §6 |

### 2.7 Members of the parsed items and stacks (Map keys)

These are plain objects: Maps with string keys (Chart.js ADR 0006). The keys keep the upstream
spelling, also with the `_` prefix.

| Key | Readers | Note |
|---|---|---|
| `parsed[axis]` | bar:371, :403, :441, :540, :569, :655, :676; line:99-104; scatter:47-48, :128-133; bubble:101-102, :129-130 | see section 3, the parsed read |
| `parsed._custom` | bar:134 (write), :345, :368, :410, :567; bubble:49, :62, :75 (write), :103, :165 | an object `{barStart, barEnd, start, end, min, max}` for a float bar, a number (radius) for a bubble |
| `parsed._stacks[axis]` | bar:405, :615 | written by DC:331 `_updateStacks` |
| `stack._top`, `stack._bottom` | bar:220, :222, :410 | `double?` (DC:365-366) |
| `stack._visualValues[datasetIndex]` (write) | bar:615 | the key is `jsNumberToString(datasetIndex)`; DC:532 `_indexKey` is private |
| `_dataset._decimated`, `_dataset.data[i]` | line:59, :107; scatter:82, :136 | `jsGet` on `meta.dataset_` |
| `dataset.stack`, `dataset.xAxisID`, `dataset.yAxisID` | bar:385, :504, :648 | `jsGet` on the dataset |

## 3. JS builtins and semantics points

| Upstream form | Lines | Dart form | Status |
|---|---|---|---|
| `parsed[axis]` passed to a scale value member or compared with `===` (Chart.js ADR 0025 §8: an absent key gives `undefined`) | bar:371, :374, :441, :444-445, :540, :569, :655, :676; line:100-101; scatter:47-48, :129-130; bubble:101-102, :129-130 | ADR 0025 §8 gives the form `value == null && !item.containsKey(key) ? undefined : value`. Phase 7 chooses its name and file | **MISSING** |
| `parsed[axis]` tested with `isNullOrUndef` | bar:403, line:99, scatter:128 | DC:564 `_parsedValue` (private) or the new parsed read | OK (both reads give the same result) |
| `getParsed(i)[vScale.axis] !== null` | bar:676 | the parsed read: `undefined !== null` is true, so a point without the key draws | needs the parsed read |
| `labels[i]`, `data[i]`, `pixels[index]` of an array with a number index | bar:162, :164, :79, :91; bubble:61, :74 | DC:511 `_item` (private) or `jsGet` | **MISSING** as a shared helper (DC has it as a private function) |
| `Object.keys(obj)` | bar:496, :507 | `js/js_array.dart:79` `jsObjectKeys` (array-index keys first) | OK |
| `Array.prototype.sort((a, b) => a - b)` | bar:15 | `js/js_array.dart:32` `jsSort` | OK |
| `[].concat`, `find`, `filter`, `indexOf`, `shift`, `push` | bar:13, :436-444, :462, :496, :520, :649 | Dart `List` members. `indexOf` with `==` gives the `===` result for these values (strings, numbers, the sentinel) | OK |
| `Math.min`, `Math.max` | bar:36, :107, :120-121, :348-349, :608-610, :652, :656; line:135; scatter:163, :177; bubble:88 | `js/js_math.dart:85` `jsMax`, `:101` `jsMin` | OK (apply `jsToNumber` to raw values first) |
| `Math.abs` | bar:36, :108, :125, :414, :601; line:104 | `double.abs()` | OK |
| `isNaN(val)` on a parsed value | bar:447 | `js/js_number.dart:46` `jsIsNaN` | OK |
| `isNaN(pixel)` | line:103, scatter:132, bubble:132 | `double.isNaN` | OK |
| `value \|\| 0`, `a \|\| b` on raw options | bar:220, :222, :544, :565; line:128; scatter:169 | `js/js_number.dart:71` `jsOrZero`; `jsTruthy` for the value form | OK. bar:544 and line:128 keep the raw value (`barThickness \|\| …`, `borderWidth \|\| 0` returns the option) |
| `+` on raw values (`start + length`, `'(' + x + …`, `values.radius += …`) | bar:370-374, :593; scatter:52; bubble:107, :165 | `js/js_number.dart:87` `jsAdd`; `jsToString` for the string joins | OK |
| `+item.r` | bubble:75 | `jsToNumber` | OK |
| `x - y` on raw parsed values | bar:575, line:104, scatter:133 | `jsToNumber` of each operand | OK |
| `===` on raw values (`value === actualBase`, `index === stack._top`, `edge === true`, `stacked === false`) | bar:211, :218-222, :410, :462-463, :603 | `==` on `double` and `String`; `identical(x, undefined)` for `undefined` | OK. Note: Dart `0 == 0.0` is true, as `===` for two JS numbers |
| `Number.POSITIVE_INFINITY`, `Infinity` | line:83, scatter:120, bar:640 | `double.infinity` | OK |
| `delete meta.dataset` | scatter:93 | `meta.dataset = null` | OK |
| `Object.assign({}, values, {$shared: false})` | bubble:157 | `copyOptions(values)..[r'$shared'] = false` | OK (Chart.js ADR 0021 §3) |
| `!!_dataset._decimated` | line:59 | `jsTruthy(jsGet(meta.dataset_, '_decimated'))` | OK |
| `'' + value` | bar:371, :374 | `js/js_number.dart:111` `jsToString` | OK |
| `item[2]` of a data array | bubble:62 | `jsGet(item, '2')` or a list read | OK |
| `custom.barStart !== undefined` | bar:171 | `!identical(jsGet(custom, 'barStart'), undefined)` | OK |
| `getValueForPixel(head) - getValueForPixel(base)` | bar:615 | the base `Scale` gives Dart `null` for `undefined`: `?? double.nan` | OK |

MISSING JS semantics items: 2 (the parsed read of ADR 0025 §8, the shared list read and parsing
key helpers that DC keeps private).

## 4. Option defaults, overrides and descriptors

No file of the four declares `static descriptors`.

| Controller | `static id` | `static defaults` | `static overrides` |
|---|---|---|---|
| `BarController` | bar:260 `'bar'` | bar:265-279: `datasetElementType: false`, `dataElementType: 'bar'`, `categoryPercentage: 0.8`, `barPercentage: 0.9`, `grouped: true`, `animations.numbers: {type: 'number', properties: ['x', 'y', 'base', 'width', 'height']}` | bar:284-298: `scales._index_: {type: 'category', offset: true, grid: {offset: true}}`, `scales._value_: {type: 'linear', beginAtZero: true}` |
| `LineController` | line:8 `'line'` | line:13-19: `datasetElementType: 'line'`, `dataElementType: 'point'`, `showLine: true`, `spanGaps: false` | line:24-33: `scales._index_: {type: 'category'}`, `scales._value_: {type: 'linear'}` |
| `ScatterController` | scatter:8 `'scatter'` | scatter:13-18: `datasetElementType: false`, `dataElementType: 'point'`, `showLine: false`, `fill: false` | scatter:23-37: `interaction: {mode: 'point'}`, `scales.x: {type: 'linear'}`, `scales.y: {type: 'linear'}` |
| `BubbleController` | bubble:6 `'bubble'` | bubble:11-21: `datasetElementType: false`, `dataElementType: 'point'`, `animations.numbers: {type: 'number', properties: ['x', 'y', 'borderWidth', 'radius']}` | bubble:26-35: `scales.x: {type: 'linear'}`, `scales.y: {type: 'linear'}` |

The Dart machinery for these statics exists:

- `core/core.typedRegistry.dart:105-121` reads `id`, `defaults` and `overrides` through `jsGet`
  on the class value. The registry `controllers` has the scope `datasets`
  (`core/core.registry.dart:26-28`).
- `core/core.config.dart:71-88` and `:225-232` map `_index_` and `_value_` to an axis.
- `core/core.controller.dart:1187-1199` reads `datasetElementType` and `dataElementType` from
  `defaults.datasets[type]` and writes the element classes into the class value.

Options that the controllers read from `this.options` without a controller default: `barThickness`,
`maxBarThickness`, `minBarLength`, `base`, `skipNull` (bar), `segment` (line, scatter), `spanGaps`
(scatter), `parsing` and `indexAxis` (`core.defaults.js:74`, `:65`; `core/core.defaults.dart:296`,
`:287`).

`lib/src/index.dart:49` has the `controllers` namespace as an empty Map. `lib/src/controllers/`
does not exist. The four classes, `controllers/index.dart` and the entries of `controllers` and
`registerables` are MISSING (the expected work of phase 7).

## 5. Element types

| Controller | `datasetElementType` | `dataElementType` | Element class value |
|---|---|---|---|
| bar | `false` | `'bar'` | `elements/element.bar.dart` `BarElement.jsClass` |
| line | `'line'` | `'point'` | `LineElement.jsClass`, `PointElement.jsClass` |
| scatter | `false`, then `registry.getElement('line')` when `showLine` is true (scatter:105), and `false` again when `showLine` is false (scatter:94) | `'point'` | `PointElement.jsClass`; `LineElement.jsClass` through the registry |
| bubble | `false` | `'point'` | `PointElement.jsClass` |

The options classes are `BarOptions`, `PointOptions` and `LineOptions` of
`elements/element_options.dart` (Chart.js ADR 0021 §1). `_resolveElementOptions` (DC:1515) creates
them from the element id.

## 6. Risks

### 6.1 Names that collide (Chart.js ADR 0023) and private members that another file reads

- `_getSharedOptions` is `getSharedOptions_` (bar:399, line:79, bubble:121). Scatter calls the
  public `getSharedOptions` (scatter:115). Both exist.
- `meta._dataset` is `meta.dataset_` (line:43, :78, scatter:77, :113). `types.ChartMeta` does
  not declare it. The interface needs the member, or the controller casts to the concrete
  `ChartMeta` of `core/core.controller.dart`, which a controller file does not import upstream.
- `_getStackCount` and `_getStackIndex` of the bar controller: the bar specs read them
  (`controller.bar.tests.js:85-575`, `:1803-1804`). They become `getStackCount` and
  `getStackIndex` with `@internal`. No member of `DatasetController` has these names.
- `_drawStart`, `_drawCount`: the line specs read them (`controller.line.tests.js:1099-1158`).
  They exist as `drawStart` and `drawCount`.
- `_cache`, `_startPixel`, `_endPixel`, `_length` of the scale; `_chart`, `_datasetIndex`,
  `_decimated` of the line element; `_ctx`, `_type`, `_parsing`, `_cachedMeta` of the controller:
  each has a Dart name without the underscore already.
- The static `defaults` and `overrides` of a controller class and the static `defaults` of
  `DatasetController` do not collide: Dart statics are not inherited. `datasetElementType` and
  `dataElementType` stay only properties of the class value (Chart.js ADR 0020 §3).
- `getLabelAndValue` has the record type `({String label, String value})` (DC:1339). The scatter
  and bubble overrides return the raw label (`labels[index] || ''`, scatter:51, bubble:106). A
  label can be an array of lines. The record type must widen `label` to `Object?`, or the port
  diverges.

### 6.2 Type gaps at the call sites

- `types.Scale` lacks 9 members of ADR 0025 §5. The gallery `StressPointController` casts
  `(vScale as Scale).getBasePixel()`. Phase 7 adds the members, as ADR 0025 §5 says.
- `types.DatasetController` lacks `options` and `getParsed` (bar:437, :440).
- `getStartAndCountOfVisiblePoints` and the setter `LineElement.points` take
  `List<PointElement>`. `meta.data` is `List<types.Element>`. `List.cast` gives a view. The line
  keeps the view as its `_points`, so each later read through the view pays a type check
  (segments, control points, draw). Upstream shares the same array between `meta.data` and
  `line.points`. A copy breaks that sharing.
- `chart.animationsDisabled` is `bool?`. The helper takes `bool`: `jsTruthy` or `?? false`.
- `chart.chartArea` is `ChartArea?`. `updateControlPoints` takes `ChartArea` (line:140).
- By-name writes that throw where upstream stores the value: `point.parsed = null`
  (`parsing: false` with a `null` item and a `segment` option, line:106) and a non-number
  `inflateAmount` option on a bar (bar:253-255).

### 6.3 Scriptable options

- `this.options` is the dataset resolver with the dataset context. Each of `barThickness`,
  `maxBarThickness`, `minBarLength`, `base`, `grouped`, `skipNull`, `categoryPercentage`,
  `barPercentage`, `showLine`, `spanGaps` and `segment` can be a function of that context. The
  resolver caches each resolved key, so the controller reads it once for each `configure`.
- `segment` is an object of functions. The line writes it unresolved into the line options
  (line:66). `LineOptions` keeps it as an extra value; `helpers.segment` calls the functions.
- The element options (`borderSkipped`, `inflateAmount`, `radius`) are scriptable for each data
  element through `resolveDataElementOptions`.
- Raw option values reach arithmetic and `===`: `base` (bar:565, :589, :603, :619-620),
  `barThickness` (bar:544, :555, :645, :72), `minBarLength` (bar:601-602), `inflateAmount`
  (bar:253). A string or a `null` value changes the result through `ToNumber` and the strict
  compare. The port must keep each raw value as `Object?` until the upstream operator applies.

### 6.4 Hot loops

- Bar `updateElements` (bar:401-424): for each bar, `_calculateBarIndexPixels` calls
  `_getAxisCount()` and `_getAxis()`, which loop over all datasets and call
  `getFirstScaleIdForIndexAxis()` (`Object.keys` of the scales and a filter). It also calls
  `_getStackIndex`, which calls `_getStacks`, which calls `getMatchingVisibleMetas` and filters
  the metas. The cost is O(bars x datasets) allocations for each update. With `skipNull`,
  `_getStacks` also runs `meta._parsed.find` for each meta: O(bars x datasets x points). A hoist
  of the loop-invariant values changes the upstream structure and needs a `DIVERGES` marker, an
  `adapt` row and figures in `performance.md` (porting-flow.md §1.1).
- Bar `_calculateBarIndexPixels` and `_calculateBarValuePixels` read 7 options of the resolver
  for each bar (bar:564, :638-645). Each read is a resolver read, not a typed field.
- Line and scatter `updateElements` (line:89-119, scatter:124-148): for each point, 3 to 4
  parsed reads, 2 scale calls, and either a by-name write into the point (direct update) or a new
  properties Map plus `resolveAnimations(...).update`. The parsed read with `undefined` costs
  0.3-0.9 ns (AOT) and 1.7-2.5 ns (wasm) more than `_parsedValue` for each read (ADR 0025 §8).
  The write of `raw` (line:107) creates the extras Map of each point at the first write. The
  gallery `StressPointController` writes the typed setters for `x`, `y`, `skip` and `stop`, which
  is the faster form.
- Bubble `parse*Data` (bubble:46-78) calls `resolveDataElementOptions` for each item. The bubble
  override copies the shared cache entry (`copyOptions`, about 23.5 ns for each copy, Chart.js
  ADR 0021 §8) and calls `getParsed` on an item that `parse` has not written yet.
  `updateElements` and `getMaxOverflow` resolve the options of each point again.
- Bar `parseArrayOrPrimitive` and `parseObjectData` (bar:153-168, :324-338): a Map, two
  `parse` calls and two `resolveObjectKey` calls for each item; the float bar adds a second Map
  (`_custom`).
- `getAllScaleValues` (bar:7-18) concatenates the values of all datasets in a loop (O(datasets x
  points) copies), sorts them and caches the result in `scale._cache.$bar` until the next scale
  update.

### 6.5 The #12238 `spacingMode` parts

The four cartesian files have no `spacingMode` code. At the pin, `spacingMode` is in
`element.arc.ts:147-204` and `:387` (ported in phase 4), and in `controller.polarArea.js:26`
(the default `spacingMode: 'proportional'`) and `:204` (the comment about arc defaults that mask
polar area values). The ledger row #12238 assigns the controller defaults, the 3 new spec cases
and the fixtures of `controller.doughnut` and `controller.polarArea` to phase 7. They belong to
the radial inventory, not to this file.

## 7. Counts

| Kind | MISSING | CONCRETE (interface member absent) | ADAPT |
|---|---|---|---|
| Imports | 0 | 0 | 1 (`getStartAndCountOfVisiblePoints`) |
| `this` members | 1 (shared `_keyOr` form) plus 3 new bar members read by specs or other code (`getStackCount`, `getStackIndex`, `getFirstScaleIdForIndexAxis`) | 0 | 1 (`getLabelAndValue` record) |
| Chart members | 0 | 0 | 0 (the registry getter is the row `adapt-chart-registry-getter`) |
| Scale members | 0 | 9 | 0 |
| Meta members | 0 | 1 (`dataset_`) | 0 |
| Other controller members | 0 | 2 (`options`, `getParsed`) | 0 |
| Element members | 0 | 7 (`active`, `hidden`, the 3 line setters, `decimated`, `updateControlPoints`, `size`: reachable by a cast) | 3 (`points` setter list type, by-name `parsed = null`, by-name raw `inflateAmount`) |
| JS semantics | 2 (parsed read of ADR 0025 §8, shared list read) | 0 | 0 |
| Controller files and registration | 6 (4 classes, `controllers/index.dart`, the `controllers` and `registerables` entries) | 0 | 0 |
