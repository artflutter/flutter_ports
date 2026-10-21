# Spec: parsed data in the controllers

- Decision: [Chart.js ADR 0027](../../../adr/0027-parsed-data.md) (proposed). This spec gives the
  work of that ADR to the agents of the phase 7 port waves. When this spec and the ADR differ, the
  ADR wins. Report the difference to the integration agent.
- Pin: Chart.js `v4.5.1+7169e651`. "DC" is `lib/src/core/core.datasetController.dart`. "dc.js" is
  `third_party/Chart.js/src/core/core.datasetController.js`. `bar.js` and the other short names
  are the files of `third_party/Chart.js/src/controllers/`. The Dart line numbers refer to the
  working tree on 2026-10-21. Find each site again by its text before you change it.
- Scope: the reads and writes of parsed items, data items, stack objects and raw option values in
  the controllers and in DC. The other panels (Chart.js ADRs 0028-0031) decide the controller
  interfaces, the fixture runner, the test strategy and the gallery. Where a test of this spec
  needs a harness or a generator, use the layout of Chart.js ADR 0030 (proposed): one generator
  and one test file for each controller, and the harness `controller_chart_harness.dart`.
- The package paths below are relative to `packages/flutter_chartjs/`.

## 0. Order of work

| Step | Work | Gate | Owner |
|---|---|---|---|
| 1 | The runtime functions (section 2) and their pure tests (section 7.1) | `test`, `test:web`, `analyze` | the runtime agent, before the first controller wave |
| 2 | The DC reads, `core.controller.dart`, `helpers.config.dart` (section 3) | all existing tests pass without a change | the same agent, same commit as step 1 or the next commit |
| 3 | `stacksOf` and the List write (section 4), with the measurement (section 4.3) | the measurement result goes to the maintainer when it fails the threshold | the DC agent, before the bar and line waves |
| 4 | The controllers (section 5), one wave at a time | the pin tests of section 7.3 for that controller | the wave agent of each controller |
| 5 | The doc notes (section 8) | `check:port`, `parity:check` | the integration agent |

Steps 1 and 2 do not depend on any controller. Each controller wave depends on steps 1 and 2. The
bar, line and scatter waves also depend on step 3 (or on its fallback, section 4.4).

## 1. Files

| File | Change | Step |
|---|---|---|
| `lib/src/js/js_object.dart` | add `jsGetKey` and `jsGetIndex` | 1 |
| `lib/src/js/js_array.dart` | add `jsSetIndex` | 1 |
| `test/port/js/js_object_test.dart` | groups `jsGetKey`, `jsGetIndex` | 1 |
| `test/port/js/js_array_test.dart` | group `jsSetIndex` | 1 |
| `lib/src/js/js_number.dart` | add `jsLessThan` and its private `_toPrimitiveNumber` | 1 |
| `test/port/js/js_number_test.dart` | group `jsLessThan` | 1 |
| `lib/src/core/core.datasetController.dart` | remove `_item`, `_getIndex`, `_setAt`, `_lessThan`, `_toPrimitive`; switch the reads of section 3.1; add `_listStacks` and `stacksOf`; change the write of `_updateStacks` | 2, 3 |
| `lib/src/core/core.controller.dart` | remove `_item` (:2315-2322); its callers (:1161, :1682, :1719) call `jsGetIndex` | 2 |
| `lib/src/helpers/helpers.config.dart` | :920 reads `jsGetIndex(data, index)` | 2 |
| `test/port/core/core.datasetController_test.dart` | the group `js-semantics-resolver-objects` gets the unit cases of `stacksOf` (section 7.2) | 3 |
| `test/port/core/core.datasetController_chart_test.dart` | the group `js-semantics-resolver-objects` with the List items through a test controller (section 7.2) | 3 |
| `lib/src/controllers/controller.<name>.dart` (8 files) | the forms of section 5. The integration agent of the wave writes `lib/src/controllers/index.dart` (interfaces spec, section 5) | 4 |
| `test/port/controllers/controller.<name>_test.dart` | the group `parsed data` of each controller (section 7.3) | 4 |
| `tool/reference/controller_<snake>_reference.mjs` (Chart.js ADR 0030 §3; `<snake>` is `polar_area` for `polarArea`) | the cases of section 7.3 that need generated values (section 7.4) | 4 |
| `AGENTS.md`, `doc/porting-flow.md`, `doc/performance.md`, `doc/differences.md`, `doc/status.yaml` | the notes of section 8 | 5 |

No file of `lib/src/elements/` changes. `core.interaction.dart` and `helpers.extras.dart` keep
their `_parsedValue`. `lib/src/types/index.dart` keeps `ChartMeta.parsed` as `List<Object?>`.

## 2. The runtime functions (step 1)

### 2.1 `lib/src/js/js_object.dart`

Add after `jsGet`. The file already imports `js_array.dart` (for `JsProxyObject`) and
`js_undefined.dart`.

```dart
/// `object[key]` for a property name [key]: the result of [jsGet] for every
/// value (Chart.js ADR 0027).
///
/// A Map that is not a [JsProxyObject] is read inline: the value of [key],
/// or [undefined] for a key that the Map does not contain. Every other value
/// goes to [jsGet]: a resolver gives its `get` trap, a List or a String its
/// index or `length`, and `null` and [undefined] throw a [TypeError].
///
/// Use it for the reads of parsed items, data items and stack objects. A
/// read of a resolver stays [jsGet] (Chart.js ADR 0017, section 8).
Object? jsGetKey(Object? object, String key) {
  // `<dynamic, dynamic>`: see the comment of jsGet.
  if (object is Map<dynamic, dynamic> && object is! JsProxyObject) {
    final Object? value = object[key];
    return value == null && !object.containsKey(key) ? undefined : value;
  }
  return jsGet(object, key);
}

/// `object[index]` for a number [index] (Chart.js ADR 0027): for a List,
/// the item at a whole [index] below the length, else [undefined]; for
/// another value, [jsGet].
///
/// The `ToPropertyKey` of a number gives an array index only for a whole
/// number in range. -0 gives the key `'0'`. NaN, a fraction, a negative
/// number and a number past the end give [undefined].
Object? jsGetIndex(Object? object, double index) {
  if (object is List<Object?>) {
    if (index >= 0 && index < object.length) {
      final i = index.toInt();
      if (i == index) return object[i];
    }
    return undefined;
  }
  return jsGet(object, index);
}
```

- Do not add a `prefer-inline` pragma (ADR 0027, Open 5).
- Do not change `jsGet`.
- `jsGetIndex` tests `List<Object?>`. A `List<double>` is a `List<Object?>` at run time (Dart
  generics are covariant), so a typed user List takes the fast path.

### 2.2 `lib/src/js/js_array.dart`

Add next to `JsProxyObject`. Move the doc of `_setAt` (DC:539-546) with it:

```dart
/// The JS write `list[index] = value` (Chart.js ADR 0027): a write at the
/// length appends.
///
/// JavaScript leaves a hole for an index past the length. Dart throws a
/// [RangeError] (differences.md row `platform-array-events`). `parse` writes
/// the items in order from its start. `_resyncElements` gives a start at most
/// the length. `_insertElements` gives the start of the caller of
/// `onDataSplice`, which can be past the length.
void jsSetIndex<T>(List<T> list, int index, T value) {
  if (index == list.length) {
    list.add(value);
  } else {
    list[index] = value;
  }
}
```

No new import. The file stays a pure layer.

### 2.3 `lib/src/js/js_number.dart`

Add after `jsAdd`. The body is `_lessThan` and `_toPrimitive` of DC (DC:567-584), with one change:
a `DateTime` gives its time value (ADR 0027 §7).

```dart
/// The JavaScript relational comparison `a < b` (ECMAScript IsLessThan):
/// two numbers compare as numbers, two strings by their code units, and
/// other values by the `ToNumber` of their `ToPrimitive` with the hint
/// `number`. `a > b` is `jsLessThan(b, a)` (Chart.js ADR 0027).
bool jsLessThan(Object? a, Object? b) {
  if (a is num && b is num) return a < b;
  final pa = _toPrimitiveNumber(a);
  final pb = _toPrimitiveNumber(b);
  if (pa is String && pb is String) return pa.compareTo(pb) < 0;
  return jsToNumber(pa) < jsToNumber(pb);
}

/// `ToPrimitive(value, number)`: a `DateTime` (a JS `Date`) gives its time
/// value (`valueOf`); another object gives its [jsToString].
Object? _toPrimitiveNumber(Object? value) => switch (value) {
  null || Undefined() || bool() || num() || String() => value,
  final DateTime date => jsToNumber(date),
  _ => jsToString(value),
};
```

## 3. DC, `core.controller.dart` and `helpers.config.dart` (step 2)

### 3.1 The reads of DC

| DC line (today) | Text today | Text after |
|---|---|---|
| :207 | `jsGet(stack.values, _indexKey(datasetIndex))` | `jsGetKey(stack.values, _indexKey(datasetIndex))` |
| :311 | `jsGet(stack, _indexKey(meta.index))` | `jsGetKey(stack, _indexKey(meta.index))` |
| :349 | `jsGet(item, iAxis)` | `jsGetKey(item, iAxis)` |
| :350 | `jsGet(item, vAxis)` | `jsGetKey(item, vAxis)` |
| :430-437 | `jsGet(stacks, axis)`, `jsGet(jsGet(stacks, axis), datasetKey)`, `jsGet(axisStacks, '_visualValues')`, `jsGet(visualValues, datasetKey)` | `jsGetKey` for each |
| :1047-1048 | `jsGet(cur, iAxis)`, `jsGet(prev, iAxis)` | `jsGetKey` for each |
| :1221 | `jsGet(parsed, scale.axis)` | `jsGetKey(parsed, scale.axis)` |
| :1224 | `jsGet(jsGet(jsGet(parsed, '_stacks'), scale.axis), '_visualValues')` | step 2: `jsGetKey(jsGetKey(jsGetKey(parsed, '_stacks'), scale.axis), '_visualValues')`; step 3: `jsGetKey(jsGetKey(stacksOf(parsed), scale.axis), '_visualValues')` |
| :1240 | `jsGet(parsed, scale.axis)` | `jsGetKey(parsed, scale.axis)` |
| :1245 | `jsGet(jsGet(parsed, '_stacks'), scale.axis)` | step 2: `jsGetKey(jsGetKey(parsed, '_stacks'), scale.axis)`; step 3: `jsGetKey(stacksOf(parsed), scale.axis)` |
| :1279 | `jsToNumber(jsGet(parsed, otherScale.axis))` | `jsToNumber(jsGetKey(parsed, otherScale.axis))` |
| :1346, :1349 | `jsGet(parsed, iScale.axis)`, `jsGet(parsed, vScale.axis)` | `jsGetKey` for each |

Do not change these reads: :1280 and :1318 (`_parsedValue` in `isFinite`), and :351 and :428
until step 3. Do not change the reads of a resolver or an option object (for example :76-78,
:252, :784, :1006, :1366).

### 3.2 The index helpers of DC

- Remove `_item` (DC:509-517) and `_getIndex` (DC:519-522). Each caller calls `jsGetIndex`:
  :860, :1026, :1037, :1104, :1105, :1137, :1177, :1200, :1468.
- Remove `_setAt` (DC:539-553). Its caller :1052 calls `jsSetIndex(parsedItems, i + offset, cur =
  parsed[i])`.
- Remove `_lessThan` and `_toPrimitive` (DC:567-584). The sorted test at :1048 calls
  `jsLessThan(jsGetKey(cur, iAxis), jsGetKey(prev, iAxis))`.
- Keep `_at`, `_indexKeys`, `_indexKey`, `_keyOr` and `_parsedValue`.
- `getParsed` (DC:1199-1201) reads `return jsGetIndex(cachedMeta.parsed, index);`.

### 3.3 `core.controller.dart`

Remove the private `_item` (:2315-2322) and its doc. The callers :1161, :1682 and :1719 call
`jsGetIndex`. Add the import of `package:flutter_chartjs/src/js/js_object.dart` with
`show jsGetIndex` if the file has no import of it yet.

### 3.4 `helpers.config.dart`

`_parseObjectDataRadialScale` (:893-926): `:920` becomes
`final item = jsGetIndex(data, index);`. The parsing key at :914-915 and the cast at :922 stay.
Remove the import of `jsNumberToString` if it has no other user.

### 3.5 Check of step 2

- Run the full gate (`format:check`, `analyze`, `test --no-select`, `test:web`, `test:cases`,
  `check:port`). No existing test changes. The existing `getMinMax`, stack and scale reference
  tests guard the switch.
- Record nothing new in `performance.md` in this step. The integration agent copies the figures
  of the ADR (section 8.3).

## 4. `stacksOf` and the List items (step 3)

### 4.1 Code

At the end of the private helpers of DC (after `_parsedValue`):

```dart
/// The `_stacks` property of the parsed items that are Lists. A Dart List
/// has no named property. Upstream writes `item._stacks = {}` into the
/// array (core.datasetController.js:165).
final Expando<Object> _listStacks = Expando('_stacks');

/// The read `item._stacks` of a parsed item (core.datasetController.js:165,
/// :218, :599, :610; controller.bar.js:405, :615).
///
/// A Map gives Dart `null` for an absent key, as `_parsedValue` does. Each
/// reader tests the truthiness, or reads a property of the result, which
/// throws a [TypeError] for both `null` and [undefined].
@internal
Object? stacksOf(Object? item) {
  if (item is Map<dynamic, dynamic>) return item['_stacks'];
  if (item is List<dynamic>) return _listStacks[item];
  return jsGet(item, '_stacks');
}
```

The write in `_updateStacks` (DC:351-357 today):

```dart
var itemStacks = stacksOf(item);
if (!jsTruthy(itemStacks)) {
  switch (item) {
    case final Map<dynamic, dynamic> map:
      // DIVERGES(chartjs): js-semantics-resolver-objects, a narrow Map throws.
      map['_stacks'] = itemStacks = <String, Object?>{};
    case final List<dynamic> list:
      _listStacks[list] = itemStacks = <String, Object?>{};
    default:
      // A JavaScript TypeError: a property write into a primitive.
      throw TypeError();
  }
}
```

The readers: DC:351 (above), DC:428 (`final stacks = stacksOf(parsed);`), DC:1224 and DC:1245
(section 3.1, step 3 column). The bar reads `bar.js:405` and `:615` through it (section 5.1).

Update the doc of `_updateStacks` (DC:331-339): a List item takes `_stacks` through `stacksOf`;
a primitive throws; a narrow Map throws (the row).

### 4.2 Behavior check

- `stacksOf` is equal to `_parsedValue(item, '_stacks')` for each value that is not a List.
- DC:1224, DC:1245 and `bar.js:615` read a property of the result. For an absent `_stacks`, both
  `jsGetKey(null, axis)` and `jsGetKey(undefined, axis)` throw a `TypeError`, as upstream.

### 4.3 Measurement before the change lands (ADR 0027, Open 1)

- Bed: the judge benchmark,
  `/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/parsed-data-judge/`
  (`bin/judge_bench.dart`, `run.sh`, `diffs.py`). If the scratchpad is gone, rebuild the bed from
  section 2.2 of `judge.md`: AOT and wasm, plain and mixed modes, 6 rounds of 4 processes,
  paired differences.
- Loops: `updateRangeFromParsed` with a stack (DC:1238-1252) and the body of `_updateStacks`
  (DC:347-371), over 20000 Map items with `_stacks`. Forms: `_parsedValue` / `jsGetKey` (step 2)
  against `stacksOf` (step 3).
- Threshold: a paired loss of more than 0.5 ns for each item on a platform in each of the 6
  processes. Then do not land step 3. Report the figures to the maintainer, who chooses step 3 or
  the fallback.
- Record the figures in the scratchpad and give them to the integration agent for
  `performance.md`.

### 4.4 Fallback (option A of question 3)

DC keeps the throw at :354. The readers DC:351 and :428 keep `_parsedValue`. DC:1224 and DC:1245
keep the step 2 column. The bar reads `bar.js:405` and `:615` with `jsGetKey(parsed, '_stacks')`.
The integration agent adds to the row `js-semantics-resolver-objects`: "A List data item throws a
`TypeError` at the write of `_stacks`, where upstream adds the property to the array." The pin
test expects the `TypeError`.

## 5. The controllers (step 4)

### 5.1 Rules for each controller

1. Each `parsed[key]`, `item.r`, `parsed._custom`, `custom.barStart`, `stack._top` with a String
   key: `jsGetKey`. Each `parsed._stacks`: `stacksOf` (or `jsGetKey` under the fallback).
2. Each `array[i]` with a number index: `jsGetIndex`. A List that the controller makes and reads
   with an index in range: the Dart read (`ruler.pixels[index]`, `bar.js:79`, `:91-93`).
3. Each read of a resolver or an option object: `jsGet` (Chart.js ADR 0017 §8).
4. No cast of a data item, a parsed item or a data value. One cast only:
   `jsGet(getDataset(), 'data')! as List<Object?>` in the doughnut `parse`.
5. No call of `_parsedValue`. No new copy of it.
6. A destructuring default: `valueOrDefault(jsGet(parsing, '<key>'), '<default>')`, and the cast
   `! as String` at the `resolveObjectKey` call inside the loop.
7. A raw option value stays `Object?` until its upstream operator (ADR 0027 §7).
8. A `final` local for a read only under the one-read rule (ADR 0027 §8).
9. Each structure change of the step 7 list (ADR 0027 §8) stays literal.

### 5.2 `controller.bar.dart`

```dart
// controller.bar.js:153-168 `parseArrayOrPrimitive`.
final labels = iScale.getLabels();
final singleScale = identical(iScale, vScale); // :157 `iScale === vScale`
for (var i = start, ilen = start + count; i < ilen; ++i) {
  final entry = jsGetIndex(data, i);
  final item = <String, Object?>{};
  // :164 `singleScale || iScale.parse(labels[i], i)`: the value of `||`,
  // `true` for a single scale.
  item[iScale.axis] =
      singleScale ? true : iScale.parse(jsGetIndex(labels, i), i);
  parsed.add(parseValue(entry, item, vScale, i));
}
```

```dart
// controller.bar.js:324-338 `parseObjectData`.
final xAxisKey = valueOrDefault(jsGet(parsing, 'xAxisKey'), 'x');
final yAxisKey = valueOrDefault(jsGet(parsing, 'yAxisKey'), 'y');
final iAxisKey = iScale.axis == 'x' ? xAxisKey : yAxisKey;
final vAxisKey = vScale.axis == 'x' ? xAxisKey : yAxisKey;
final parsed = <AnyObject>[];
for (var i = start, ilen = start + count; i < ilen; ++i) {
  final obj = jsGetIndex(data, i);
  final item = <String, Object?>{};
  item[iScale.axis] = iScale.parse(resolveObjectKey(obj, iAxisKey! as String), i);
  parsed.add(parseValue(resolveObjectKey(obj, vAxisKey! as String), item, vScale, i));
}
```

```dart
// controller.bar.js:170-172 `isFloatBar(custom)`.
bool _isFloatBar(Object? custom) =>
    jsTruthy(custom) &&
    !identical(jsGetKey(custom, 'barStart'), undefined) &&
    !identical(jsGetKey(custom, 'barEnd'), undefined);
```

Note: upstream returns the value of `&&`. Each caller tests it as a boolean (`bar.js:410`,
`:568`), so a `bool` result keeps the behavior.

```dart
// controller.bar.js:401-405 (updateElements, the reads).
final parsed = getParsed(i);
final vpixels = reset || isNullOrUndef(jsGetKey(parsed, vScale.axis))
    ? (base: base, head: base)
    : _calculateBarValuePixels(i);
final ipixels = _calculateBarIndexPixels(i, ruler);
final itemStacks = stacksOf(parsed);
// `(parsed._stacks || {})[vScale.axis]`: literal (step 7 list).
final stack = jsGetKey(
  jsTruthy(itemStacks) ? itemStacks : <String, Object?>{},
  vScale.axis,
);
// :410 `!stack || isFloatBar(parsed._custom) || (index === stack._top || index === stack._bottom)`
final enableBorderRadius = !jsTruthy(stack) ||
    _isFloatBar(jsGetKey(parsed, '_custom')) ||
    index == jsGetKey(stack, '_top') ||
    index == jsGetKey(stack, '_bottom');
```

```dart
// controller.bar.js:443-450 `skipNull` of `_getStacks`: literal.
final currentParsed = cachedMeta.controller.getParsed(dataIndex);
final iScaleValue = jsTruthy(currentParsed)
    ? jsGetKey(currentParsed, iScale.axis)
    : currentParsed;
bool? skipNull(types.ChartMeta meta) {
  final parsed = meta.parsed.firstWhere(
    (item) => jsGetKey(item, iScale.axis) == iScaleValue,
    orElse: () => undefined,
  );
  final val = jsTruthy(parsed) ? jsGetKey(parsed, meta.vScale!.axis) : parsed;
  if (isNullOrUndef(val) || jsIsNaN(val)) return true;
  return null;
}
```

Note: `Array.prototype.find` gives `undefined` when no item matches; `orElse` gives the sentinel.
Dart `==` gives `===` for the parsed values.

```dart
// controller.bar.js:540 (`_getRuler`, the pixels).
pixels.add(iScale.getPixelForValue(jsGetKey(getParsed(i), iScale.axis), i));
```

```dart
// controller.bar.js:563-627 `_calculateBarValuePixels` (the reads and the raw options).
final baseValue = jsGet(options, 'base');
final minBarLength = jsToNumber(jsGet(options, 'minBarLength'));
final Object? actualBase = jsTruthy(baseValue) ? baseValue : 0.0; // baseValue || 0
final parsed = getParsed(index);
final custom = jsGetKey(parsed, '_custom');
final floating = _isFloatBar(custom);
Object? value = jsGetKey(parsed, vScale.axis);
Object? start = 0.0;
Object? length = jsTruthy(stacked) ? applyStack(vScale, parsed, stacked) : value;
if (length != value) {
  start = jsToNumber(length) - jsToNumber(value);
  length = value;
}
if (floating) {
  value = jsGetKey(custom, 'barStart');
  length = jsToNumber(jsGetKey(custom, 'barEnd')) - jsToNumber(value);
  // :583 `value !== 0 && sign(value) !== sign(custom.barEnd)`
  ...
  start = jsAdd(start, value);
}
final startValue = !isNullOrUndef(baseValue) && !floating ? baseValue : start;
var base = vScale.getPixelForValue(startValue);
// :592-596
head = chart.getDataVisibility(index)
    ? vScale.getPixelForValue(jsAdd(start, length))
    : base;
size = head - base;
if (size.abs() < minBarLength) {
  size = _barSign(size, vScale, actualBase) * minBarLength;
  if (value == actualBase) base -= size / 2; // `===`: 5 == '5' is false
  ...
  if (jsTruthy(stacked) && !floating) {
    // :615 `parsed._stacks[vScale.axis]._visualValues[datasetIndex] = ...`
    (jsGetKey(jsGetKey(stacksOf(parsed), vScale.axis), '_visualValues')!
        as AnyObject)[jsNumberToString(datasetIndex)] =
        vScale.getValueForPixel(head) - vScale.getValueForPixel(base);
  }
}
if (base == vScale.getPixelForValue(actualBase)) {
  final halfGrid = sign(size) * vScale.getLineWidthForValue(actualBase) / 2;
  ...
}
```

- `_barSign` (`bar.js:174-179`): `vScale.min >= jsToNumber(actualBase)`.
- The `as AnyObject` cast at :615 throws a `TypeError` for a value that is not a Map, as the
  upstream write into a primitive. The wave agent checks that `_visualValues` is always a
  `Map<String, Object?>` (DC:367-371 writes it).
- `jsTruthy(stacked)`: the `_stacked` of the meta is `bool` or `'single'`.

```dart
// controller.bar.js:532-557 `_getRuler`: the ruler record (Chart.js ADR 0003).
({
  Object? min, // barThickness || computeMinSampleSize(meta)
  List<double> pixels,
  double start,
  double end,
  double stackCount,
  types.Scale scale,
  Object? grouped,
  double ratio,
}) _getRuler() { ... }
// :544
final barThickness = jsGet(opts, 'barThickness');
final Object? min = jsTruthy(barThickness) ? barThickness : computeMinSampleSize(meta);
// :555
ratio: jsTruthy(barThickness)
    ? 1
    : jsToNumber(jsGet(opts, 'categoryPercentage')) *
        jsToNumber(jsGet(opts, 'barPercentage')),
```

```dart
// controller.bar.js:636-666 `_calculateBarIndexPixels` (the raw options).
final maxBarThickness =
    jsToNumber(valueOrDefault(jsGet(options, 'maxBarThickness'), double.infinity));
// :645
jsGet(options, 'barThickness') == 'flex' ? ... : ...;
// :652
size = jsMin(maxBarThickness, range.chunk * range.ratio);
// :655-656 (not grouped)
center = scale.getPixelForValue(jsGetKey(getParsed(index), scale.axis), index);
size = jsMin(maxBarThickness, jsToNumber(ruler.min) * ruler.ratio);
```

```dart
// controller.bar.js:61-80 `computeFitCategoryTraits` (the raw options).
final thickness = jsGet(options, 'barThickness');
// :66
size = jsToNumber(ruler.min) * jsToNumber(jsGet(options, 'categoryPercentage'));
// :72
size = jsToNumber(thickness) * stackCount;
```

```dart
// controller.bar.js:202-225 `setBorderSkipped` (the raw options).
var edge = jsGet(options, 'borderSkipped');
if (!jsTruthy(edge)) { ... }
if (edge == true) { ... }
if (edge == 'middle' && jsTruthy(stack)) {
  properties['enableBorderRadius'] = true;
  if (jsOrZero(jsGetKey(stack, '_top')) == index) {
    edge = top;
  } else if (jsOrZero(jsGetKey(stack, '_bottom')) == index) {
    edge = bottom;
  } else { ... }
}
```

```dart
// controller.bar.js:252-256 `setInflateAmount`.
void _setInflateAmount(AnyObject properties, Object? options, double ratio) {
  final inflateAmount = jsGet(options, 'inflateAmount');
  properties['inflateAmount'] = inflateAmount == 'auto'
      ? (ratio == 1 ? 0.33 : 0.0)
      // The element takes a number (Chart.js ADR 0017, section 5). Its only
      // reader applies ToNumber (element.bar.js:127-140, :179-196).
      : inflateAmount is num || identical(inflateAmount, undefined)
      ? inflateAmount
      : jsToNumber(inflateAmount);
}
```

```dart
// controller.bar.js:668-680 `draw`.
if (jsGetKey(getParsed(i.toDouble()), vScale.axis) != null && !rects[i].hidden) {
  rects[i].draw(ctx);
}
```

`!== null`: the `undefined` sentinel is not `null`, so an absent key draws, as upstream.

### 5.3 `controller.line.dart` and `controller.scatter.dart`

`updateElements` (`line.js:76-120`, `scatter.js:111-151`) with the one-read rule:

```dart
// controller.line.js:87 `let prevParsed = start > 0 && this.getParsed(start - 1);`
Object? prevParsed = start > 0 ? getParsed(start - 1) : false;
// One-read rule (Chart.js ADR 0027, section 8): the iAxis value of the
// previous pass.
Object? prevIValue;
var hasPrevIValue = false;

for (var i = 0; i < pointsCount; ++i) {
  // ... :90-96 (the skip of the points outside start..end): no read.
  final parsed = getParsed(i.toDouble());
  // :99, also :101 (one-read rule).
  final vValue = jsGetKey(parsed, vAxis);
  final nullData = isNullOrUndef(vValue);
  // :100, also :104 (one-read rule).
  final iValue = jsGetKey(parsed, iAxis);
  final iPixel = iScale.getPixelForValue(iValue, i.toDouble());
  final vPixel = reset || nullData
      ? vScale.getBasePixel()
      : vScale.getPixelForValue(
          jsTruthy(stacked) ? applyStack(vScale, parsed, stacked) : vValue,
          i.toDouble(),
        );
  // ... the writes of iPixel and vPixel into properties: as Chart.js ADR 0028.
  final skip = iPixel.isNaN || vPixel.isNaN || nullData;
  // :104 `i > 0 && Math.abs(parsed[iAxis] - prevParsed[iAxis]) > maxGapLength`
  final stop = i > 0 &&
      (jsToNumber(iValue) -
                  jsToNumber(
                    hasPrevIValue ? prevIValue : jsGetKey(prevParsed, iAxis),
                  ))
              .abs() >
          maxGapLength;
  if (jsTruthy(segment)) {
    properties['parsed'] = parsed; // :106
    properties['raw'] = jsGetIndex(jsGet(meta.dataset_, 'data'), i.toDouble()); // :107
  }
  // ... :110-116
  prevParsed = parsed; // :118
  prevIValue = iValue;
  hasPrevIValue = true;
}
```

- The scatter loop runs `i` from `start` (`scatter.js:124`). The rule is the same.
- `prevParsed` keeps its upstream statements, also where the rule makes its read rare.
- Check the rule for each local: between :99 and :104, no statement writes `parsed`
  (`applyStack` reads only, dc.js:593-605; the writes go to `properties` or the point).
- Fallback of ADR 0027 Open 4 (the 3-read form): remove `prevIValue` and `hasPrevIValue`, and
  read `jsGetKey(prevParsed, iAxis)` at each pass.
- `getMaxOverflow` (`line.js:125-136`, `scatter.js:168-178`; the scatter branch without
  `showLine` at `:160-166` returns `max > 0 && max`, a `false` or a number):
  `final Object? border = jsTruthy(dsOptions) && jsTruthy(jsGet(dsOptions, 'borderWidth')) ? jsGet(dsOptions, 'borderWidth') : 0.0;`
  as the value of `a && b || 0`. Then `jsMax` of the `jsToNumber` values.
- `line.js:59` `!!_dataset._decimated`: `jsTruthy(jsGetKey(meta.dataset_, '_decimated'))`.
- `scatter.js:42-54` `getLabelAndValue`: `jsGetIndex(labels, index)` and
  `jsGetKey(parsed, 'x')`, `jsGetKey(parsed, 'y')`; `labels[index] || ''` is
  `jsTruthy(v) ? v : ''`.

### 5.4 `controller.bubble.dart`

```dart
// controller.bubble.js:46-52 parsePrimitiveData
for (var i = 0; i < parsed.length; i++) {
  parsed[i]['_custom'] =
      jsGet(resolveDataElementOptions(i + start), 'radius');
}

// controller.bubble.js:58-64 parseArrayData: `item[2]` of a List or another value.
final item = jsGetIndex(data, start + i);
parsed[i]['_custom'] = valueOrDefault(
  jsGet(item, '2'),
  jsGet(resolveDataElementOptions(i + start), 'radius'),
);

// controller.bubble.js:70-76 parseObjectData: `item && item.r && +item.r`.
final item = jsGetIndex(data, start + i);
final Object? r;
if (!jsTruthy(item)) {
  r = item;
} else {
  final value = jsGetKey(item, 'r');
  r = jsTruthy(value) ? jsToNumber(value) : value;
}
parsed[i]['_custom'] = valueOrDefault(
  r,
  jsGet(resolveDataElementOptions(i + start), 'radius'),
);
```

- `jsGet(item, '2')` and not `jsGetIndex(item, 2)`: upstream writes the key `2`; both give the
  same result. Use `jsGetIndex(item, 2.0)` only when a measurement shows a gain (step 7).
- `bubble.js:101-103` `getLabelAndValue`: `jsGetKey(parsed, 'x')`, `jsGetKey(parsed, 'y')`,
  `jsGetKey(parsed, '_custom')`.
- `bubble.js:129-130` `updateElements`: `jsGetKey(parsed, iAxis)`, `jsGetKey(parsed, vAxis)`.
- `bubble.js:165`:
  `values['radius'] = jsAdd(jsGet(values, 'radius'), valueOrDefault(jsTruthy(parsed) ? jsGetKey(parsed, '_custom') : parsed, radius));`
- The option copy for each item stays literal (step 7 list).

### 5.5 `controller.doughnut.dart` and `controller.pie.dart`

```dart
// controller.doughnut.js:148-167 `parse(start, count)`.
@override
void parse(double start, double count) {
  // A List after _dataCheck: a falsy `data` is [] (dc.js:367), and object
  // data throws at meta.iScale! (DC:234), as upstream throws at dc.js:104.
  final data = jsGet(getDataset(), 'data')! as List<Object?>;
  final meta = cachedMeta;
  if (parsing == false) {
    meta.parsed = data; // the same List: meta._parsed === dataset.data
  } else {
    var getter = (double i) => jsToNumber(jsGetIndex(data, i));
    if (isObject(jsGetIndex(data, start))) {
      final key = valueOrDefault(jsGet(parsing, 'key'), 'value');
      getter = (double i) =>
          jsToNumber(resolveObjectKey(jsGetIndex(data, i), key! as String));
    }
    for (var i = start, ilen = start + count; i < ilen; ++i) {
      jsSetIndex<Object?>(meta.parsed, i.toInt(), getter(i));
    }
  }
}
```

- `parsing == false`: Dart `==` gives the `===` of `this._parsing === false`.
- `doughnut.js:250` `meta._parsed[i] === null`: `jsGetIndex(meta.parsed, i) == null`.
- `doughnut.js:253` `meta._parsed[i] * circumference / TAU`:
  `jsToNumber(jsGetIndex(meta.parsed, i)) * circumference / tau`.
- `doughnut.js:296-310` `calculateTotal`:

  ```dart
  final value = jsGetIndex(meta.parsed, i.toDouble());
  if (value != null &&
      !jsIsNaN(value) &&
      chart.getDataVisibility(i.toDouble()) &&
      !metaData[i].hidden) {
    total += jsToNumber(value).abs();
  }
  ```

  `total += Math.abs(value)`: `Math.abs` applies `ToNumber`, so `total` stays a number.
- `doughnut.js:320-330` `getLabelAndValue`: `jsGetIndex(labels, index)`, `labels[index] || ''`,
  `formatNumber(jsGetIndex(meta.parsed, index), ...)`.
- `getDataVisibility` stays an upstream call for each arc (step 7 list).

### 5.6 `controller.polarArea.dart`

- `polarArea.js:97-111` `getLabelAndValue`:
  `formatNumber(jsGetKey(jsGetIndex(cachedMeta.parsed, index), 'r'), locale)` and
  `jsTruthy(label) ? label : ''` for `labels[index] || ''`.
- `polarArea.js:123-142` `getMinMax` (ADR 0027 §7):

  ```dart
  // :125 `range = {min: +Infinity, max: -Infinity}`: the raw values, as
  // upstream stores `parsed` unchanged.
  Object? min = double.infinity;
  Object? max = double.negativeInfinity;
  for (var index = 0; index < meta.data.length; index++) {
    final parsed = jsGetKey(getParsed(index.toDouble()), 'r');
    if (!jsIsNaN(parsed) && chart.getDataVisibility(index.toDouble())) {
      if (jsLessThan(parsed, min)) min = parsed; // :131 `parsed < range.min`
      if (jsLessThan(max, parsed)) max = parsed; // :135 `parsed > range.max`
    }
  }
  // core.scale.js:315 and :318 apply Math.min and Math.max to the range.
  return (min: jsToNumber(min), max: jsToNumber(max));
  ```

  Two string values compare as strings: `[{r: '10'}, {r: '9'}, {r: '30'}]` gives
  `{min: '10', max: '9'}` and the ticks 0 to 9 (probe E8 of the ADR). A `jsToNumber` at the
  compare gives 9..30. `meta.data.forEach` visits each element in order; a `for` loop over the
  same indices keeps the order (the callback has no `return` that stops it).
- `polarArea.js:182`: `scale.getDistanceFromCenterForValue(jsGetKey(getParsed(i), 'r'))` (the
  `Object?` parameter of Chart.js ADR 0025 §1).
- `polarArea.js:221` `countVisibleElements`: `!jsIsNaN(jsGetKey(getParsed(index), 'r'))`.
- `polarArea.js:233-234` `_computeAngle`: `angle || defaultAngle` is
  `jsTruthy(a) ? a : defaultAngle`, then `jsToNumber` at `toRadians`.
- The parse goes through `_parseObjectDataRadialScale` (section 3.4).

### 5.7 `controller.radar.dart`

- `radar.js:39-46` `getLabelAndValue`: `label: jsGetIndex(vScale.getLabels(), index)` (no
  `'' +`: the label past the end is `undefined`, probe S-P1) and
  `value: jsToString(vScale.getLabelForValue(jsGetKey(getParsed(index), vScale.axis)))`.
- `radar.js:88` `scale.getPointPositionForValue(i, jsGetKey(getParsed(i), 'r'))` (the `Object?`
  parameter of Chart.js ADR 0025 §1).
- The parse goes through `_parseObjectDataRadialScale` (section 3.4).
- The option resolution for each point stays literal (step 7 list).

### 5.8 Review checklist of each wave

- [ ] No `_parsedValue`, no `jsGet(parsed, ...)` with a String key on a parsed item, a data item
  or a stack object (`grep -n "jsGet(parsed\|jsGet(item" lib/src/controllers`).
- [ ] No `as Map` and no `as AnyObject` on a parsed item or a data item, except the writes into
  the stack objects that DC makes (`bar.js:615`).
- [ ] Each `final` local of a parsed read has a comment that names the upstream lines it serves.
- [ ] Each raw option value is `Object?` until its operator.
- [ ] No hoist, memo or cache of the step 7 list.

## 6. `DIVERGES` rows

- New rows: none. New markers: none.
- The marker `// DIVERGES(chartjs): js-semantics-resolver-objects, a narrow Map throws.` at
  DC:355 stays at the Map case of the new switch (section 4.1).
- Row text changes (integration agent, section 8.4).

## 7. Tests

### 7.1 Pure tests (step 1)

`test/port/js/js_object_test.dart` (`package:test`, no `@TestOn`):
- group `jsGetKey`: for each receiver of the table, `jsGetKey(v, k)` is `identical` to
  `jsGet(v, k)`:
  - `<String, Object?>{'a': 1.0}` with `'a'`, with `'b'`; `{'a': null}` with `'a'` (Dart `null`,
    not `undefined`);
  - a `Map<String, double>`;
  - a resolver of `_createResolver` and a context proxy of `_attachContext` with a key of value
    `null`, an absent key and a prefixed key (for example `'_scopes'`);
  - a `List` with `'0'`, `'length'` and `'r'`; a `String` with `'0'` and `'length'`;
  - `5.0`, `true`, a `JsClass` with a static property.
  - `null` and `undefined` throw a `TypeError` in both functions.
- group `jsGetIndex`: a List with 0, 1, 1.5, -1, -0.0, NaN, infinity, the length and an index past
  it; a `List<double>`; a Map with the key `'1'` and 1.0; a String with 0.0; `null` and
  `undefined` throw a `TypeError`.

`test/port/js/js_array_test.dart`, group `jsSetIndex`: a write at the length appends; a write
below it replaces; a write past it throws a `RangeError`; a `double` into a `List<int>` throws a
`TypeError`.

`test/port/js/js_number_test.dart`, group `jsLessThan` (pure): `('10', '9')` is true;
`(10.0, 9.0)`, `('10', 9.0)` and `(9.0, '9')` are false; `(null, 1.0)` is true (`null` is 0);
`(undefined, 1.0)` and `(1.0, undefined)` are false (NaN); `(DateTime.utc(10000),
DateTime.utc(9999))` is false and the reverse is true (the time values; the `toString()` order is
the reverse); `([2.0], '10')` is false (`'2'` against `'10'` as strings: false, `'2' > '1'`).
The expected values come from the ECMAScript rules; check each in the x64 Node.js before you
commit the test.

### 7.2 DC tests (step 3)

Step 3 runs before the bar and line waves. Thus its chart cases use a test controller, not a
ported controller.

`test/port/core/core.datasetController_test.dart` (VM, no chart), group
`js-semantics-resolver-objects`: `stacksOf` gives the same value as `_parsedValue(item,
'_stacks')` for a Map, a number and Dart `null`, and the Expando entry for a List (unit tests of
the `@internal` function).

`test/port/core/core.datasetController_chart_test.dart` (`testWidgets`, `@TestOn('vm')`, as the
file has today), group `js-semantics-resolver-objects`: a test controller (a
`DatasetController` subclass with a point data element, registered in the test with its own id
and unregistered at its end) with `stacked: true`:
- `parsing: false` and items `[[0, 1], [1, 2]]`: no throw; `stacksOf(item)` is a Map with the key
  of the value axis;
- `parsing: false` and `[1.0, 2.0]`: a `TypeError`;
- a `Map<String, double>` data item still throws a `TypeError` (the row).

Under the fallback (section 4.4), the first case expects a `TypeError`.

The probe values of the ported controllers (point `x` NaN and `skip` true; bar
`enableBorderRadius` false and `borderSkipped` `{'bottom': true}`, probes F-P1 and F-P4) are rows
of section 7.3 for the bar and line units.

### 7.3 Controller pin tests (step 4)

`test/port/controllers/controller.<name>_test.dart`, group `parsed data` (`testWidgets`,
`@TestOn('vm')`, `acquireChart`). Generated values come from section 7.4. A relation test needs
no generated value.

| Controller | Case | Expected | Source |
|---|---|---|---|
| doughnut | object data `{a: 1, b: 2}`, parsing on and off | `TypeError` | S-P1, P-P1 |
| doughnut | `parsing: false`, `[1, '2', null]` | `identical(meta.parsed, dataset['data'])`; the circumferences | F-P1 |
| doughnut | `parsing: false`, `[{value: 1}, {value: 2}]`, and `[1, null, 2]` | total, circumferences, `getLabelAndValue(0).value` | S-P1 |
| polarArea | `parsing: false`, `[{r: 1}, {}, {r: 3}]` against `[{r: 1}, {r: null}, {r: 3}]` | `countVisibleElements()` 2 against 3; the arc angles | S-P2 |
| polarArea | `parsing: false`, `[5, 3]`, `[[5], [3]]` | outer radii NaN, no throw | F-P1 |
| radar | `parsing: false`, `[5, 3, 1]` | x and y NaN, `skip` true | F-P1 |
| polarArea | `parsing: false`, `[{r: '10'}, {r: '9'}, {r: '30'}]` against the numbers | `getMinMax()` 10..9 against 9..30; the scale `min` and `max` 0..9 against 0..30; the tick values | ADR 0027 E8 |
| radar | a label index past the end | `getLabelAndValue(1).label` is `undefined` (no `'' +` at `radar.js:44`) | S-P1 |
| bubble | `parsing: false`, `[[x, y, r]]` | x and y NaN, `skip` true, radius 3 | F-P1 |
| line, scatter, bubble, polarArea, radar | `parsing: false`, a `null` item | `TypeError`; for the line, with and without `segment`, `hidden`, and user `min` and `max` | F-P1, F-P2, S-P1 |
| line | `parsing: false`, `[5, {x: 1, y: 2}]`, `segment` set | `point.parsed` is 5 | P-P1 |
| scatter | logarithmic x, `parsing: false`, `{y: 5}` against `{x: null, y: 5}` | `x` is the min pixel and `skip` false, against NaN and `skip` true | S-P1, P-P1 |
| line | `parsing: false`, `x.min: 1`, `{y: 50}` against `{x: null, y: 50}` | the y range | P-P1 |
| line, scatter | one-read rule: `segment` set, `spanGaps: 2`, an update with `start > 0` | `stop` and `skip` of each point equal the generator | judge §5 |
| bar | `parsing: false`, `{x: 'b'}` against `{x: 'b', y: null}` | the draw calls of `bar.js:676` | S-P2 |
| bar | `inflateAmount` `'2'`, `null`, `true`, `'abc'` | no throw; the `rect` and `clip` calls equal those of 2, 0, 1, NaN (relation) | F-P2, P-P1 |
| bar | `base: 5` against `base: '5'`, with and without `minBarLength: 20` | the element `base` and `height` | S-P1 |
| bar | `base: '0'` against `0` with `minBarLength: 10`; `base` `''`, `'5'`, `'abc'` | `y`, `base`, `height` | F-P1, F-P2 |
| bar | `base: 'b'` on a category axis; `base: true` | the pixel of `'b'`; the bar of `base: 1` (relation) | P-P1 |
| bar | `minBarLength: '20'`, `barThickness: '20'` | the bars of 20 (relation) | S-P1 |
| bar | `barThickness: 'flex'`, `grouped: false`; `maxBarThickness` `null` and `'30'` | width NaN; width 0; width 30 | F-P2, P-P1 |
| bar | `parsing: {xAxisKey: null}` and `{xAxisKey: 5}` | `TypeError` | F-P1 |
| bar | a bad `yAxisKey` on a category index axis | the `TypeError` comes after the first label parse (the labels hold the first item label) | judge §3 Q2 |
| line, bar | `stacked: true`, `parsing: false`, items `[[0, 1], [1, 2]]` | no throw; `stacksOf(item)` has the key of the value axis; point `x` NaN and `skip` true; bar `enableBorderRadius` false and `borderSkipped` `{'bottom': true}` (under the fallback of section 4.4: a `TypeError`) | F-P1, F-P4 |
| line | `stacked: true`, `parsing: false`, `[1, 2]` | `TypeError` (a write into a primitive) | F-P4 |

### 7.4 The generator

The cases of section 7.3 that need generated values go into the generator of their controller,
`tool/reference/controller_<snake>_reference.mjs` of Chart.js ADR 0030 §3. Each case has a name
that starts with `parsed:`. A case that throws records the key `error`, and a value outside the
observations (for example `countVisibleElements()`, `getMinMax()` or the identity of
`meta._parsed`) is a probe of the key `extra` (Chart.js ADR 0030 §4). The themed run of the test
file does not run these cases. The generator runs in the x64 Node.js v24.12.0 against the pinned
build. Do not add a separate generator for this spec. Do not edit the generated files by hand.

### 7.5 Source checks

A review item of step 6 (or a test of `test/tool/` if Chart.js ADR 0030 adds one): no file of
`lib/src/controllers/` calls `_parsedValue`, and no controller casts a parsed item.

## 8. Doc notes for the integration agent (step 5)

### 8.1 `AGENTS.md`

- "The JS runtime in `lib/src/js/`" list: add `jsGetKey` (the read `object[key]` of a parsed item,
  a data item or a stack object, with the `jsGet` result; a resolver read stays `jsGet`),
  `jsGetIndex` (`object[index]` with a number index), `jsSetIndex` (`list[index] = value`,
  append at the length) and `jsLessThan` (the operator `a < b` on raw values: two strings compare
  as strings, a `DateTime` by its time value) (Chart.js ADR 0027, proposed).
- The `doc/adr/` item: Chart.js ADRs 0001-0027; add 0027 (parsed data in the controllers) to the
  proposed list.
- `core.datasetController.dart` item: `stacksOf` (`@internal`) reads `item._stacks`, also of a
  List item (Chart.js ADR 0027). Omit it under the fallback.
- The `tool/reference/` item of the Tests section: no change for this spec. The generators of
  Chart.js ADR 0030 carry the cases.

### 8.2 `doc/porting-flow.md`

§1.1 (performance rule): add one line after "A faster form that keeps the upstream structure
needs no more records": "A `final` local for a repeated read of the same key of the same item in
one loop pass keeps the structure under the one-read rule of Chart.js ADR 0027 §8."

§2: a row for Chart.js ADR 0027 in the table of decisions, and the section "§2.20 Chart.js ADR
0027: Parsed data in the controllers (gate 7)" in the form of §2.19. The phase 7 sections of §2
are, in ADR order: §2.20 ADR 0027, §2.21 ADR 0028, §2.22 ADR 0029, §2.23 ADR 0030.

### 8.3 `doc/performance.md`

- A new section "13. Controllers (phase 7)" with "13.1 The parsed read (Chart.js ADR 0027)":
  the bed and the table of section 2.4 of `judge.md`, the index read table (ADR 0027,
  Benchmarks), the Map-first `jsGet` figures (P-B4), and the `stacksOf` figures of section 4.3.
- §11.2 and §11.8 item 2: one line each that points to 13.1 ("adopted in phase 7 as the T form;
  the `isFinite` read keeps `_parsedValue`").
- The open list of section 13 (13.7, see `../work-plan.md`, "Doc numbering"): the step 7 list
  of ADR 0027 §8 with its prior evidence (P-P2, F-P3). P-B7 (`getDataVisibility`) goes to 13.2:
  Chart.js ADR 0028 §4 adopts that form.

### 8.4 `doc/differences.md`

Row `js-semantics-resolver-objects`, in the text after "The stacks stay in the user item ...":
- With section 4.1: "A List data item takes `_stacks` through `stacksOf` (an `Expando`). A
  primitive data item throws a `TypeError`, as upstream."
- Under the fallback: "A List data item throws a `TypeError` at the write of `_stacks`, where
  upstream adds the property to the array."
- In both: "With `parsing: false`, `meta.parsed` is the user List. A typed user List, for example
  `List<double>`, takes no Map: when `parsing` then changes to true, `parse` throws a `TypeError`
  at the first write, where upstream writes the parsed objects into the user array."
- The code column adds `lib/src/core/core.datasetController.dart` `stacksOf`.

Row `platform-array-events`: the code column adds `lib/src/js/js_array.dart` `jsSetIndex`.

Each row keeps its markers. `check:headers` pairs them.

### 8.5 `doc/status.yaml`

The status text of `core.datasetController` gets one sentence: "The reads of parsed items and
stack objects use `jsGetKey`; `stacksOf` reads the `_stacks` of a List item (Chart.js ADR
0027)." Each controller row gets its status from its wave. Run `dart run melos run parity`.

## 9. Not in this spec

- The interface types of the controllers, the `properties` writes and the element setters
  (Chart.js ADR 0028).
- The step 7 forms (ADR 0027 §8): no agent of a port wave does them.
- `prefer-inline` on `jsGetKey` (ADR 0027 Open 5).
- The early cast of DC `parseObjectData` (ADR 0027 Open 2): the step 6 review.
