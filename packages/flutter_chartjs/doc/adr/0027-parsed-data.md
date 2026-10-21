# Chart.js ADR 0027: Parsed data in the controllers

- Status: accepted (2026-10-21)
- Date: 2026-10-21
- Related: [Chart.js ADR 0003](0003-type-only-dependencies.md) (records for inline object types),
  [Chart.js ADR 0006](0006-options-representation-and-resolver.md) (the `undefined` sentinel),
  [Chart.js ADR 0009](0009-no-display-only-js-exactness.md) (the protected behavior),
  [Chart.js ADR 0010](0010-js-numeric-semantics.md) (`ToNumber`, the reference engine),
  [Chart.js ADR 0012](0012-dart-file-naming.md) (underscore names),
  [Chart.js ADR 0017](0017-element-properties.md) §3, §4, §5 and §8 (typed properties, the
  `undefined` state, the write by name, option reads),
  [Chart.js ADR 0020](0020-registry-and-component-classes.md) §13 (a gain that only a
  microbenchmark measures),
  [Chart.js ADR 0025](0025-scale-value-parameters.md) §1 and §8 (the `Object?` value parameters,
  the parsed read of phase 7),
  [Chart.js ADR 0028](0028-controller-interfaces.md) §2 and §4 (the label reads, the early return
  of `getDataVisibility`),
  [Chart.js ADR 0030](0030-controller-test-strategy.md) §3 and §4 (the generators and the test
  files of the pin tests),
  [porting-flow.md](../porting-flow.md) §1.1 (the performance rule),
  [performance.md](../performance.md) §10.3, §11.2 and §11.8 item 2,
  [differences.md](../differences.md) rows `js-semantics-resolver-objects` and
  `platform-array-events`,
  [phase7/design/parsed-data/judge.md](../../../../.handover/phase7/design/parsed-data/judge.md) (the panel result)

## Context

Phase 7 ports the eight controllers of `src/controllers/`. Each controller reads the parsed items
of its dataset, the data items, the stack objects and raw option values. The port of
`core.datasetController` (phase 5) gives these reads as private helpers. Chart.js ADR 0025 §8
asks for a parsed read with the `jsGet` result, and leaves its name and its file to phase 7.

The line numbers of upstream files refer to Chart.js `v4.5.1+7169e651` (`third_party/Chart.js`
at `7169e65147a4`), checked for this ADR. "DC" is `lib/src/core/core.datasetController.dart` and
"dc.js" is `src/core/core.datasetController.js`. `bar.js`, `line.js` and the other short names are
the files of `src/controllers/`. The Dart line numbers refer to the working tree on 2026-10-21.

The panel had five questions:
1. The form of the parsed read `parsed[key]`.
2. The form of the private helpers of DC that the controllers need: `_item`, `_getIndex`,
   `_setAt`, `_keyOr` and `_parsedValue`.
3. The data shapes with `parsing: false`.
4. The writes by name and the raw option values.
5. The policy for the hot loops.

### Upstream reads

- A parsed item is any value (`types/index.d.ts:503`, `_parsed: unknown[]`): a Map of a
  `parse*Data` method, a data item with `parsing: false` (dc.js:460-463), or a number of the
  doughnut (`doughnut.js:153`, `:164`). The controllers read it with the JS property read:
  `line.js:99-104`, `scatter.js:128-133`, `bar.js:345`, `:367-374`, `:402-405`, `:444-445`,
  `:540`, `:566-569`, `:615`, `:655`, `:676`, `bubble.js:101-103`, `:165`, `radar.js:88`,
  `polarArea.js:101`, `:128`, `:182`, `:221`.
- An absent key gives `undefined`. A `null` or `undefined` item throws a `TypeError`.
- The result reaches a scale value method, `===`, `isNaN` or `isNullOrUndef`. For three sites,
  `null` and `undefined` give different results: `isNaN` at `polarArea.js:130` and `:221`, the
  logarithmic scale at `line.js:100` and `scatter.js:129` (`undefined` gives the min pixel), and
  `!== null` at `bar.js:676`.
- The controllers read arrays with a number index: `data[i]`, `labels[i]` and `meta._parsed[i]`
  (`bar.js:162`, `:164`, `:332`, `bubble.js:61`, `:74`, `doughnut.js:153-165`, `:250`, `:253`,
  `polarArea.js:101`, `:104`, `line.js:107`, `scatter.js:136`, `helpers.config.ts:450`).
- The doughnut writes `meta._parsed[i] = getter(i)` (`doughnut.js:164`).
- `bar.js:326` destructures `{xAxisKey = 'x', yAxisKey = 'y'} = this._parsing`, and
  `doughnut.js:158` destructures `{key = 'value'}`. Only `undefined` gives the default. The key
  reaches `resolveObjectKey` inside the loop (`bar.js:334-335`), which throws a `TypeError` for a
  key that is not a string. For a bad `vAxisKey`, `iScale.parse` of the first item runs first
  (`bar.js:334`), and a category scale adds a label there.
- `updateStacks` writes `item._stacks = {}` into each parsed item (dc.js:165). With
  `parsing: false`, the item is the data item: an object, an array or a primitive.

### The port today

- DC has `_item` (DC:511), `_getIndex` (DC:521), `_indexKey` (DC:532), `_setAt` (DC:547),
  `_parsedValue` (DC:564) and `_keyOr` (DC:1188). `core.controller.dart:2317` has a copy of
  `_item`. `core.interaction.dart:148` and `helpers.extras.dart:303` have copies of
  `_parsedValue`.
- `_parsedValue` gives Dart `null` for an absent key of a Map. Its readers test with `isFinite`,
  `isNullOrUndef` or the truthiness, which give the same result for `null` and `undefined`.
- `jsGet` (`lib/src/js/js_object.dart:36`) tests `null`, `Undefined` and `JsProxyObject` before
  the Map case. A `JsProxyObject` gives its `get` trap (`:42-43`). Its `has` trap does not know the
  prefixed keys (`js_array.dart:44-52`).
- `helpers.config.dart:920` reads `jsGet(data, jsNumberToString(index))`.
- `_updateStacks` throws a `TypeError` for an item that is not a Map (DC:354). Upstream writes
  `_stacks` into an array item and does not throw (probes F-P1 and F-P4).
- `BarElement` takes `inflateAmount` through `toNumberProp` (`element.bar.dart:498-499`), which
  throws an `ArgumentError` for a `String`, a `bool` or `null`. Upstream stores the raw value
  (`bar.js:252-256`). Its only reader is `draw` (`element.bar.js:179-196`), and `inflateRect`
  (`element.bar.js:127-140`) applies `ToNumber` through `-amount` and `amount - x`.
- `PointElement` takes `parsed` through `toObjectProp<Object>` (`element.point.dart:311-312`),
  which throws an `ArgumentError` for Dart `null`.

### Probes

The probes ran the Chart.js build at the pin in the x64 Node.js v24.12.0 under Rosetta (Chart.js
ADR 0010), through `loadChartJs` and `makeChart` of `tool/reference/scale_chart_common.mjs`.
Results that this ADR uses:

| Case | Upstream result |
|---|---|
| doughnut, object data `{a: 1, b: 2}`, parsing on and off | `TypeError` in `_dataCheck` (dc.js:103-104 read `meta.iScale.axis`), before `parse` |
| doughnut, `parsing: false`, `[1, '2', null]` | `meta._parsed === dataset.data`; the `null` arc is 0 |
| polarArea, radar, bubble, line, `parsing: false`, a `null` item | `TypeError` at the first read; for the line, before `line.js:106` |
| line, `parsing: false`, number items, `segment` set | no throw; `point.parsed` is the number |
| polarArea, `parsing: false`, `[{r: 1}, {}, {r: 3}]` against `[{r: 1}, {r: null}, {r: 3}]` | `countVisibleElements()` 2 against 3 |
| scatter, logarithmic x, `parsing: false`, `{y: 5}` against `{x: null, y: 5}` | `x` is the min pixel and `skip` false, against `x` NaN and `skip` true |
| bar, `parsing: false`, `{x: 'b'}` against `{x: 'b', y: null}` | the draw test of `bar.js:676` is true against false |
| line, `parsing: false`, `x.min: 1`, `{y: 50}` against `{x: null, y: 50}` | the item counts in the y range against not |
| stacked line and stacked bar, `parsing: false`, items `[[0, 1], [1, 2]]` | no throw; `_stacks` is a property of each array (dc.js:165); x NaN, `skip` true; bar `enableBorderRadius` false, `borderSkipped` `{bottom: true}` |
| stacked line, `parsing: false`, `[1, 2]` | `TypeError: Cannot create property '_stacks' on number '1'` |
| bar `inflateAmount` `'2'`, `null`, `true`, `'x'` | no throw; the element keeps the raw value; the draw calls equal those of 2, 0, 1 and NaN |
| bar `base: 5` against `base: '5'`, with and without `minBarLength: 20` | different bases (`===` in `getLineWidthForValue` and at `bar.js:603`) |
| bar `base: 'b'` on a category axis | the pixel of the label `'b'` |
| bar `minBarLength: '20'`, `barThickness: '20'` | the bars of the numbers |
| bar `barThickness: 'flex'`, `grouped: false` | width NaN |
| bar `parsing: {xAxisKey: null}` and `{xAxisKey: 5}` | `TypeError` |
| polarArea, `parsing: false`, `[{r: '10'}, {r: '9'}, {r: '30'}]` against the numbers | `getMinMax()` gives `{min: '10', max: '9'}` (two strings compare as strings, `polarArea.js:131-137`), scale 0..9 and ticks 0 to 9; the numbers give 9..30, scale 0..30 (Evidence E8) |

### Benchmarks

The judge benchmark (Evidence E4) imports the real `jsGet`, `jsToNumber`, `jsMin`, `jsMax`,
`isFinite`, `JsProxyObject` and `undefined` of `lib/src/`. AOT is `dart compile exe`. wasm is
`dart compile wasm -O2` in the arm64 Node.js v24.12.0 (times only). 20000 items
`{'x': i, 'y': v}`, `null` for 10 % of the `y` values. "Mixed" runs each loop first over a
`JsProxyObject`, a narrow Map, a List and a number. Each cell gives the lowest and the highest
paired difference of 6 processes, in ns for each item, and the count below 0.

| Difference | AOT plain | AOT mixed | wasm plain | wasm mixed |
|---|---|---|---|---|
| `getMinMax` T minus today | -1.76..-1.13 (6/6) | -2.09..-1.04 (6/6) | -1.75..-0.46 (6/6) | -2.89..-1.50 (6/6) |
| `getMinMax` `jsGetKey` for 3 reads minus T | +0.61..+1.46 (0/6) | +0.75..+1.59 (0/6) | +0.37..+1.51 (0/6) | +0.97..+2.18 (0/6) |
| line, 5 reads: `jsGetKey` minus `jsGet` | -3.39..-2.22 (6/6) | -2.63..-0.27 (6/6) | -5.20..-1.75 (6/6) | -3.20..-1.22 (6/6) |
| line: 2 reads minus 5 reads (`jsGetKey`) | -23.28..-22.42 (6/6) | -24.33..-23.28 (6/6) | -36.46..-33.11 (6/6) | -35.29..-33.20 (6/6) |
| line: 3 reads minus 5 reads (`jsGetKey`) | -16.11..-14.97 (6/6) | -16.61..-15.97 (6/6) | -24.36..-23.05 (6/6) | -24.29..-23.07 (6/6) |

"T" is `jsGetKey` for the read of the other axis and of the range, and `_parsedValue` for the
`isFinite` read. "Today" is `jsGet`, `_parsedValue`, `jsGet` (DC:1279-1280, :1240).

The read `array[i]` with a number index (Evidence E5):

| Read | AOT | wasm |
|---|---|---|
| `jsGet(data, jsNumberToString(index))` (`helpers.config.dart:920`) | 21.49-21.93 | 17.16-17.42 |
| the `_item` body (DC:511) | 3.33-3.39 | 1.41-1.45 |
| the `_item` body behind a `List` test (`_getIndex`) | 5.61-5.84 (doughnut loop) | 5.70-6.01 (doughnut loop) |
| the `_item` body, the same loop | 5.50-5.75 | 5.69-6.00 |

A `jsGet` with the Map case first is 1.9 ns (AOT) and 1.0 ns (wasm) slower for each resolver read,
and 4.8 ns and 2.0 ns slower for each List or String read (Evidence E6). `lib/src/` has 444 `jsGet(`
calls, most of them option reads through resolvers.

## Decision

### 1. `jsGetKey`: the parsed read

`lib/src/js/js_object.dart` (a pure layer) gets this function:

```dart
/// `object[key]` for a property name [key]: the result of [jsGet] for every
/// value (Chart.js ADR 0027).
///
/// A Map that is not a [JsProxyObject] is read inline: the value of [key],
/// or [undefined] for a key that the Map does not contain. Every other value
/// goes to [jsGet]: a resolver gives its `get` trap, a List or a String its
/// index or `length`, and `null` and [undefined] throw a [TypeError].
Object? jsGetKey(Object? object, String key) {
  // `<dynamic, dynamic>`: see the comment of jsGet.
  if (object is Map<dynamic, dynamic> && object is! JsProxyObject) {
    final Object? value = object[key];
    return value == null && !object.containsKey(key) ? undefined : value;
  }
  return jsGet(object, key);
}
```

- `jsGetKey` gives the `jsGet` result for each receiver. Thus it keeps `undefined` for an absent
  key (Chart.js ADR 0025 §8), the `TypeError` of a `null` or `undefined` item, and the `get` trap
  of a resolver.
- Each controller read of a parsed item, a data item, a `_custom` object or a stack object with a
  `String` key is `jsGetKey`: `parsed[axis]`, `item.r`, `parsed._custom`, `custom.barStart`,
  `stack._top`, `_visualValues[key]`. The `_stacks` read is the exception of section 5.3.
- A read of a resolver stays `jsGet` (Chart.js ADR 0017 §8): for example `jsGet(options, 'base')`.
- `jsGet` does not change. A Map-first `jsGet` slows the resolver, List and String reads
  (Benchmarks).
- No controller calls `_parsedValue`. A controller also uses `jsGetKey` where its reader does not
  tell `null` from `undefined` (`line.js:99`, `bar.js:403`): one form for each upstream
  `parsed[key]`.
- This section fills Chart.js ADR 0025 §8 (accepted). §8 asks for the `jsGet` result and leaves
  the name and the file to phase 7. The guard `is! JsProxyObject` gives the `get` trap where the
  Map read of §8 gives `undefined` for a resolver with a `null` result. ADR 0025 does not change.

### 2. The readers of DC

DC switches its `jsGet` reads of a parsed item or a stack object to `jsGetKey`. The reads that
test with `isFinite` or the truthiness keep `_parsedValue`. This is the form "T" of the
Benchmarks: faster than today in each of the 24 processes.

| DC line | Upstream | Today | After |
|---|---|---|---|
| :207 `_applyStack` | dc.js:89 (`stack.values[datasetIndex]`) | `jsGet` | `jsGetKey` |
| :311 `_getLastIndexInStack` | dc.js:143 | `jsGet` | `jsGetKey` |
| :349-350 `_updateStacks` | dc.js:164 | `jsGet` | `jsGetKey` |
| :351 `_updateStacks`, :428 `_clearStacks` | dc.js:165, :218 | `_parsedValue` | `stacksOf` (section 5.3) |
| :430-437 `_clearStacks` | dc.js:219-224 | `jsGet` | `jsGetKey` |
| :1047-1048 `parse` (sorted test) | dc.js:473 | `jsGet` | `jsGetKey` |
| :1221 `applyStack` | dc.js:596 | `jsGet` | `jsGetKey` |
| :1224 `applyStack` (`_stacks`) | dc.js:599 | `jsGet` | `stacksOf`, then `jsGetKey` |
| :1240 `updateRangeFromParsed` | dc.js:608 | `jsGet` | `jsGetKey` |
| :1245 `updateRangeFromParsed` (`_stacks`) | dc.js:610 | `jsGet` | `stacksOf`, then `jsGetKey` |
| :1279 `getMinMax` (other axis) | dc.js:635 | `jsGet` | `jsGetKey` |
| :1280 `getMinMax` (`isFinite`) | dc.js:636 | `_parsedValue` | unchanged |
| :1318 `getAllParsedValues` (`isFinite`) | dc.js:668 | `_parsedValue` | unchanged |
| :1346, :1349 `getLabelAndValue` | dc.js:693-694 | `jsGet` | `jsGetKey` |

- The read of the other axis at :1279 keeps `undefined`: `jsToNumber(null)` is 0 and
  `jsToNumber(undefined)` is NaN (probe: the line with `x.min: 1`).
- `updateRangeFromParsed` keeps `undefined` at :1240: `_applyStack` returns `undefined` for a
  `null` value only (dc.js:75-76, DC:192), and an absent key gives NaN in the sum.
- The copies of `_parsedValue` in `core.interaction.dart:148` and `helpers.extras.dart:303` do not
  change. Their readers test `isNullOrUndef` only.

### 3. `jsGetIndex` and `jsSetIndex`: the index read and write

`lib/src/js/js_object.dart` gets `jsGetIndex`, the body of `_item` and `_getIndex`:

```dart
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

`lib/src/js/js_array.dart` gets `jsSetIndex`, the body of `_setAt`, with its doc (DC:539-546):

```dart
/// The JS write `list[index] = value` (Chart.js ADR 0027): a write at the
/// length appends.
///
/// JavaScript leaves a hole for an index past the length. Dart throws a
/// [RangeError] (differences.md row `platform-array-events`).
void jsSetIndex<T>(List<T> list, int index, T value) {
  if (index == list.length) {
    list.add(value);
  } else {
    list[index] = value;
  }
}
```

- `jsGetIndex` replaces `_item` and `_getIndex` of DC and `_item` of `core.controller.dart:2317`
  (its callers :1161, :1682, :1719). `jsSetIndex` replaces `_setAt` (its caller DC:1052).
- `helpers.config.dart:920` reads `jsGetIndex(data, index)`. The result is the same, about 18 ns
  less for each item of a radar or polar area parse.
- Each controller read `data[i]`, `labels[i]`, `meta._parsed[i]` and `_dataset.data[i]` is
  `jsGetIndex`. A List that the controller makes and reads with an index in range uses the Dart
  read: `ruler.pixels[index]` (`bar.js:79`, `:91-93`) has one item for each element.
- The `List` test costs no measured time. The `ToString` of the index costs 17 to 19 ns for each
  read (Benchmarks).
- `_at` (DC:500) and `_indexKey` (DC:532) stay private. The cached key of `_indexKey` is slower on
  wasm (Evidence E6, B7). A controller writes a dataset key with `jsNumberToString`.
- `_item` of `helpers.core.dart:576` does not change: it has an `int` index and another rule.

### 4. Parsing keys and `_parsedValue`

- A controller writes a destructuring default with `valueOrDefault` at the site, and casts the
  key to `String` at the `resolveObjectKey` call inside the loop:

  ```dart
  // controller.bar.js:326-336
  final xAxisKey = valueOrDefault(jsGet(parsing, 'xAxisKey'), 'x');
  final yAxisKey = valueOrDefault(jsGet(parsing, 'yAxisKey'), 'y');
  final iAxisKey = iScale.axis == 'x' ? xAxisKey : yAxisKey;
  final vAxisKey = vScale.axis == 'x' ? xAxisKey : yAxisKey;
  // ...
  item[iScale.axis] = iScale.parse(resolveObjectKey(obj, iAxisKey! as String), i);
  ```

  Thus, for a key that throws upstream, the `TypeError` comes at the same call as upstream, after
  the `iScale.parse` of the first item, and a parse of 0 items does not throw.
  `helpers.config.dart:922` has the same form.
- A known difference of this form: the cast throws for each key that is not a `String`.
  Upstream throws only when the cache of `resolveObjectKey` has no entry for the `ToString` of
  the key (`helpers.core.ts:379`). Then `_splitKey` calls `key.split` (`helpers.core.ts:348`),
  which throws. The cache holds `''`, `'x'` and `'y'` from the start (`helpers.core.ts:335-342`),
  and each string key of an earlier call. Thus the keys `[]` (the string `''`) and `[['y']]` (the
  option resolver gives `['y']`, the string `'y'`) do not throw upstream, but throw a `TypeError`
  in the port (U-bar-lib review, F3). The existing casts of `helpers.config.dart:922` and of DC
  `_keyOr` have the same difference. The doc of `parseObjectData` in `controller.bar.dart` states
  it. The cast does not change, for two reasons: the cache of `resolveObjectKey` is private to
  `helpers.core.dart`, and it holds the string keys of earlier calls (process state).
- `jsGet(true, 'xAxisKey')` is `undefined`, so `parsing: true` and `{}` give the defaults.
- `_keyOr` (DC:1188) stays private. The three `_parsedValue` copies stay private.
- A known residual: DC `parseObjectData` (DC:1169-1170) casts in `_keyOr`, before the loop.
  dc.js:561-571 throws in `resolveObjectKey` inside the loop. See Open 2.

### 5. `parsing: false` and the data shapes

1. No controller casts a data item, a parsed item or a data value. Each is `Object?`. Each read is
   `jsGetKey`, `jsGetIndex`, `jsGet` (a List or an unknown receiver with an index string, for
   example `item[2]` at `bubble.js:62`) or `jsToNumber` (the unary `+`).
2. A controller writes only into items that it makes: `item = {}` (`bar.js:163`, `:333`) and the
   `AnyObject` results of `super.parse*Data` (`bubble.js:47-76`).
3. The `_stacks` of an item that is not a Map. DC gets a private `Expando`, a private test for a
   JS primitive and an `@internal` reader:

   ```dart
   /// The `_stacks` property of the parsed items that are objects without a
   /// property Map: a List, and each value that is not a Map, a class value or
   /// a primitive, for example a [DateTime] or a function. Such a Dart value
   /// has no named property. Upstream writes `item._stacks = {}` into the
   /// array, the `Date` or the function (core.datasetController.js:165).
   final Expando<Object> _objectStacks = Expando('_stacks');

   /// Whether [item] is a JS primitive: a property write into it throws a
   /// `TypeError` in strict code. A record is not a JS value. It counts here,
   /// because an [Expando] cannot take it.
   bool _isPrimitive(Object? item) =>
       item == null ||
       item is Undefined ||
       item is num ||
       item is String ||
       item is bool ||
       item is Record;

   /// The read `item._stacks` of a parsed item (core.datasetController.js:165,
   /// :218, :599, :610; controller.bar.js:405, :615).
   ///
   /// A Map gives Dart `null` for an absent key, as `_parsedValue` does. Each
   /// reader tests the truthiness, or reads a property of the result, which
   /// throws a [TypeError] for both `null` and [undefined]. A class value and a
   /// primitive give [jsGet]: the static property through the superclass chain
   /// for a class value, [undefined] for a number, a [TypeError] for `null`.
   /// Each other value, for example a List or a [DateTime], gives the entry
   /// that `_updateStacks` wrote for it, or Dart `null` (Chart.js ADR 0027).
   @internal
   Object? stacksOf(Object? item) {
     if (item is Map<dynamic, dynamic>) return item['_stacks'];
     if (item is List<dynamic>) return _objectStacks[item];
     if (item is JsClass || _isPrimitive(item)) return jsGet(item, '_stacks');
     return _objectStacks[item!];
   }
   ```

   - The Map case comes first and the List case second. A Map item pays the cost of
     `_parsedValue` and no more.
   - The write in `_updateStacks` (dc.js:165) is a `switch` on the item. A Map takes the key (the
     marker of `js-semantics-resolver-objects` stays). A List takes the Expando entry. A class
     value (`JsClass`) takes an own static property `_stacks`, as upstream adds the property to
     the function (Chart.js ADR 0020). A primitive (`null`, `undefined`, a number, a string or a
     boolean) throws the `TypeError` of a write into a primitive. Each other value, for example a
     `DateTime` (a JS `Date`, Chart.js ADR 0024) or a function, takes the Expando entry.
   - The reason (S3 fix R1, [S3-report.md](../../../../.handover/phase7/review/wave1/S3-report.md)): upstream writes
     `_stacks` into a `Date`, a function and a class, and does not throw. A throw is a protected
     behavior (Chart.js ADR 0009). A subclass without an own `_stacks` reads the object of its
     superclass through `jsGet`, as upstream reads it through the prototype chain. The name of the
     Expando is `_objectStacks`, because it holds the `_stacks` of a List, a `DateTime` and a
     function.
   - The readers: DC:351, :428, :1224, :1245, `bar.js:405` and `bar.js:615`.
   - The change lands after the measurement of Open 1.
4. The doughnut reads `dataset.data` raw (`doughnut.js:149`, `:153`), with `jsGetIndex` for an
   item. `_dataCheck` replaces a falsy `data` with `[]` (dc.js:367), and throws for object data at
   `meta.iScale!` (DC:234), as upstream throws at dc.js:104. `_dataCheck` keeps a string `data` as
   a `JsStringList` of `lib/src/js/js_array.dart` (decision D11 item b): the reads `s[i]` and
   `s.length`, a `TypeError` for each write and no array listener (dc.js:386). With
   `parsing: false`, `meta.parsed` is the data List (`data! as List<Object?>`, a cast that cannot
   fail after `_dataCheck`) or the `JsStringList` of a string `data`.
5. With `parsing: false`, `meta.parsed = data` keeps the identity of the user List, as
   `meta._parsed === dataset.data` upstream.
6. A residual that does not change: a typed user List, for example `List<double>`, with
   `parsing: false`, then `parsing: true`. DC:1052 writes Maps into it and throws a `TypeError`,
   where upstream writes the parsed objects into the user array. This is a case of the narrow
   collections of the row `js-semantics-resolver-objects`.

### 6. Writes by name

- `point.parsed = parsed` (`line.js:106`, `scatter.js:135`): no change of `PointElement`. A `null`
  item throws at `line.js:99` and `scatter.js:128`, and DC `getMinMax` reads the item before that
  (dc.js:635). `jsGetKey(null, key)` throws the same `TypeError`. The other items (a Map, a
  number, a String, a bool, a List) are an `Object`, which `toObjectProp<Object>` takes.
- `inflateAmount` (`bar.js:252-256`): the controller converts the raw value at the write, except
  a `num` and `undefined`:

  ```dart
  // controller.bar.js:252-256 `setInflateAmount(properties, {inflateAmount}, ratio)`.
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

  The draw calls equal upstream for each value. `undefined` keeps the `undefined` state of the
  property (Chart.js ADR 0017 §4). A read by name of `bar.inflateAmount` gives the number, as for
  each typed numeric property of Chart.js ADR 0017 §3. No spec and no ported code reads it by
  name. `lib/src/elements/` does not change. No `DIVERGES` row.

### 7. Raw option values

A raw option value stays `Object?` until its upstream operator. Then the port applies the runtime
form of that operator (Chart.js ADR 0010, Chart.js ADR 0017 §8):

| Upstream | Dart |
|---|---|
| `bar.js:565` `actualBase = baseValue \|\| 0` | `final Object? actualBase = jsTruthy(baseValue) ? baseValue : 0.0` (not `jsOrZero`: `'0' \|\| 0` is `'0'`) |
| `bar.js:589` `!isNullOrUndef(baseValue) && !floating ? baseValue : start` | `Object? startValue` |
| `bar.js:590`, `:593`, `:619-620` `getPixelForValue(...)`, `getLineWidthForValue(actualBase)` | the raw value (Chart.js ADR 0025 §1) |
| `bar.js:571`, `:574-576` `length !== value`, `start = length - value` | `length != value`; `jsToNumber(length) - jsToNumber(value)` |
| `bar.js:593` `start + length` | `jsAdd(start, length)` |
| `bar.js:601-602` `Math.abs(size) < minBarLength`, `* minBarLength` | `final minBarLength = jsToNumber(jsGet(options, 'minBarLength'))`, once at the read |
| `bar.js:603` `value === actualBase` | `_strictEquals(value, actualBase)` |
| `bar.js:178` `vScale.min >= actualBase` | `vScale.min >= jsToNumber(actualBase)` |
| `bar.js:544` `barThickness \|\| computeMinSampleSize(meta)` | `jsTruthy(barThickness) ? barThickness : computeMinSampleSize(meta)`, the ruler field `Object? min` |
| `bar.js:66`, `:656` `ruler.min * ...` | `jsToNumber(ruler.min) * ...` |
| `bar.js:72` `thickness * stackCount` | `jsToNumber(thickness) * stackCount` |
| `bar.js:555` `barThickness ? 1 : a * b` | `jsTruthy`, and `jsToNumber` of each factor |
| `bar.js:640`, `:652`, `:656` `valueOrDefault(maxBarThickness, Infinity)` in `Math.min` | `jsMin(jsToNumber(valueOrDefault(raw, double.infinity)), ...)` |
| `bar.js:645` `options.barThickness === 'flex'` | `jsGet(options, 'barThickness') == 'flex'` |
| `bar.js:206`, `:211`, `:218` `!edge`, `edge === true`, `edge === 'middle'` | `!jsTruthy(edge)`, `edge == true`, `edge == 'middle'` |
| `bar.js:220`, `:222` `(stack._top \|\| 0) === index` | `_strictEquals(_orZero(jsGetKey(stack, '_top')), index)`, with `_orZero(v)` = `jsTruthy(v) ? v : 0.0` (not `jsOrZero`: no arithmetic follows, and the `ToNumber` of `jsOrZero` can make `'0'` or `true` equal to the dataset index, U-bar-lib review F1) |
| `line.js:104`, `scatter.js:133` `parsed[iAxis] - prevParsed[iAxis]` | `jsToNumber(...) - jsToNumber(...)`; `prevParsed` can be `false`, and `jsGetKey(false, key)` is `undefined` |
| `line.js:128`, `scatter.js:169` `dataset.options && dataset.options.borderWidth \|\| 0` | the raw value (`Object?`); `jsMax` of the `ToNumber` values |
| `bubble.js:75` `item && item.r && +item.r` | the value of the `&&` chain: `!jsTruthy(item) ? item : !jsTruthy(r) ? r : jsToNumber(r)` |
| `bubble.js:165` `values.radius += valueOrDefault(parsed && parsed._custom, radius)` | `values['radius'] = jsAdd(values['radius'], ...)` |
| `doughnut.js:155`, `:159` `+data[i]`, `+resolveObjectKey(...)` | `jsToNumber` |
| `doughnut.js:250` `meta._parsed[i] === null` | `jsGetIndex(meta.parsed, i) == null` |
| `polarArea.js:130` `!isNaN(parsed)` | `!jsIsNaN(parsed)` |
| `polarArea.js:131-137` `parsed < range.min`, `parsed > range.max`, `range.min = parsed` | `Object?` locals `min` and `max`; `jsLessThan(parsed, min)`, `jsLessThan(max, parsed)`; the return gives `jsToNumber(min)` and `jsToNumber(max)` |

- Dart `==` gives the `===` result for `double`, `String`, `bool`, `null` and the `undefined`
  sentinel. Two Maps or Lists compare by identity in both.
- Dart `==` does not give the `===` result for two `DateTime` values. Dart compares their time
  values, and `===` compares two `Date` objects by identity (a `DateTime` is a JS `Date`, Chart.js
  ADR 0024). Thus, where both operands of `===` can be a data value or an option value, the
  controller compares with a private `_strictEquals` (the function of `scale.category.dart` and
  `core.layouts.dart`): two numbers and two strings by value, each other pair by identity. The
  bar sites are `bar.js:220` and `:222` (above), `:444` (the `skipNull` find), `:462` and `:521`
  (`stacks.indexOf`, as `any` and `indexWhere`) and `:603` (above). The reason is the
  U-bar-lib review, F2: two separate `Date` stack names give two stacks upstream and one stack
  with Dart `==`, thus other bar positions and another hit element (Chart.js ADR 0009).
- A value that upstream reads once for several numeric uses gets its `jsToNumber` once, at the
  read, when each use applies `ToNumber` (`minBarLength`).
- The bar ruler (`bar.js:546-556`) is a private record (Chart.js ADR 0003) with `Object? min` and
  `Object? grouped`. Its other fields keep their types. No spec reads `_getRuler`.
- The polar area `getMinMax` compares raw parsed values. With `parsing: false`, two strings
  compare as strings, and the ticks change (Context, Evidence E8). A `jsToNumber` at the compare
  gives other ticks. The range of `getMinMax` is `({double min, double max})`
  (`types/index.dart:461`). The `jsToNumber` at the return gives the same scale limits, because
  `core.scale.js:315` and `:318` apply `Math.min` and `Math.max` to `range.min` and `range.max`.
- `lib/src/js/js_number.dart` gets `jsLessThan`, the body of `_lessThan` and `_toPrimitive` of DC
  (DC:567-584). DC:1048 calls it. A `DateTime` (a JS `Date`, Chart.js ADR 0024) gives its time
  value, as `ToPrimitive` with the hint `number` calls `valueOf`. DC today gives its `toString()`,
  and `DateTime.utc(10000) < DateTime.utc(9999)` is true for the strings
  (`'+010000-…'` before `'9999-…'`), where JavaScript gives false.

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

  `jsToString` of a `DateTime` gives the `Date.prototype.toString` text without the zone name,
  for example `'Thu Jan 01 1970 00:00:00 GMT+0000'`, and `lib/src/js/` is port-only, thus this
  has no `differences.md` row (decision D7 of the phase lead, Chart.js ADR 0009).

### 8. The hot loops

Each hot loop is ported literally first. A faster form lands in the port step only when all of
these are true:
1. It gives the upstream result for each value. A pin test shows it.
2. It keeps every upstream statement, call, loop and the order of the side effects. A local that
   holds the value of a read counts as such a form under the one-read rule below.
3. A microbenchmark on AOT and on wasm shows a gain on both platforms (Chart.js ADR 0020 §13). A
   loss on one platform defers the form to step 7.

A form that changes the structure (a hoist out of a loop, a memo, a cache across calls, a skipped
call, a new parameter) is ported literally. Step 7 measures it with the frame figures of
[performance.md](../performance.md) §6. A kept form gets a `DIVERGES` marker, an `adapt` row and
the figures before and after (porting-flow.md §1.1).

**The one-read rule.** A loop pass reads each key of a parsed item once:
- The first read goes into a `final` local at the place of the first upstream read. A later
  upstream read of the same key of the same item uses the local.
- The rule holds only when no statement between the two reads writes that key of that item.
- A local lives only inside one pass. The read `prevParsed[iAxis]` stays a read at each pass:
  `jsGetKey(prevParsed, iAxis)` inside the `i > 0 &&` operand, with the `prevParsed` of
  `line.js:87` (`getParsed(start - 1)` or `false`). A scriptable option of the previous pass can
  write `ctx.parsed` (the parsed item) after its reads, so a local of the previous pass can hold
  an old value (decision D10, the U-line review R2). Thus the read order and the throw of a `null`
  item stay as upstream.
- No local crosses a method. A read through another method (`getParsed` in
  `_calculateBarValuePixels`, `bar.js:566`) is not merged.
- The reviewer of each unit checks each local against this rule.

In one pass of `line.js:89-119` and `scatter.js:124-148`, no statement between two reads of a key
writes the parsed item: `applyStack` reads only (dc.js:593-605), and the writes go to the point or
to `properties`. Thus the five reads of `line.js:99-104` and `scatter.js:128-133` become three
(the 3-read form): `vValue` and `iValue` of the current item, and `prevParsed[iAxis]`. Gain: 15 to
17 ns (AOT) and 23 to 24 ns (wasm) for each point (a calculation from the microbenchmark, not a
frame figure).

Adopted in the port step: `jsGetKey`, `jsGetIndex`, `jsSetIndex`, `jsLessThan` (a move of a body,
no new cost), the T reads of DC (section 2) and the one-read rule (the 3-read form) in
`line.js:98-104` and `scatter.js:127-133`.

Ported literally, for step 7:
- the bar memo of `_getAxis`, `getFirstScaleIdForIndexAxis` and `_getStacks` for each bar
  (`bar.js:434-508`, `:636-650`);
- the `skipNull` find (`bar.js:443-450`), O(bars x datasets x points) upstream too;
- `(parsed._stacks || {})` with a new empty Map for each bar without stacks (`bar.js:405`);
- the option copy for each bubble item (`bubble.js:46-78`, `:151-168`);
- the double option resolution of polar area (`polarArea.js:176`, `:201`, `:232-234`) and the
  resolution for each radar point (`radar.js:87`);
- the typed setters in place of the writes by name of `line.js:91-103` and `scatter.js:126-133`.

The empty-Map path of `getDataVisibility` (`core.controller.dart:1751`) is not in this list.
[Chart.js ADR 0028](0028-controller-interfaces.md) §4 decides it: the early return lands in the
port step. It is a fast path with the upstream result, as Chart.js ADR 0025 §3, and it skips no
upstream call.

### 9. Tests, rows and records

- Pure tests of `jsGetKey`, `jsGetIndex`, `jsSetIndex` and `jsLessThan` in `test/port/js/`:
  `jsGetKey(v, k)` is identical to `jsGet(v, k)` for each receiver of a matrix, including a
  resolver and a context proxy with a prefixed key. `jsLessThan` pins two strings, a string and a
  number, `null`, `undefined` and two `DateTime` values past the year 9999.
- Port tests of each controller pin the probe rows of the Context, the one-read rule (a line and a
  scatter with `segment`, `spanGaps` as a number and `start > 0`), the throws, and the `_stacks`
  of List items.
- This ADR adds no `DIVERGES` marker, no `differences.md` row and no skip reason. The row
  `js-semantics-resolver-objects` gets new text: List items take `_stacks` (section 5.3), and the
  typed user List residual (section 5.6).
- `performance.md` gets a phase 7 section with the Benchmarks of this ADR.

## Alternatives considered

A panel wrote three drafts: fidelity (F), performance (P) and simplicity (S). A judge scored each
question in the order of the decision protocol (Evidence E1). F won three questions and is the
base of this ADR. S won question 1 and P won question 5.

| Question | Winner | Taken from the others |
|---|---|---|
| 1. The parsed read | S | the form of `jsGetKey` of F and S |
| 2. The private helpers | F | the stack-object reads of DC from P |
| 3. `parsing: false` shapes | F | the probe rows of P and S |
| 4. Writes and raw options | F | the `base` probe rows of S and P |
| 5. The hot loops | P | the three conditions of F |

**Question 1.**
- `jsGet` everywhere. Exact, but slower for each Map item (Benchmarks).
- `_parsedValue`, made public. Fastest, but wrong for an absent key at three sites (Context).
- The Map read of Chart.js ADR 0025 §8 without the proxy guard. Wrong for a resolver item with a
  `null` result. The guard costs no measured time.
- The guard on the `null` path only (P). Gains up to 1.2 ns on AOT and loses up to 4.5 ns on wasm
  against the chosen form.
- A Map-first `jsGet`. Slows the 444 other callers (Evidence E6).
- DC without change (F). F measured a wasm loss of T in `getMinMax`. The judge did not reproduce
  it: F ran Map items only, a read without the proxy guard, at a load average of 10 to 26.
- `jsGetKey` for the `isFinite` reads too. Slower than T in each process.

**Question 2.**
- A public `@internal` `item`, `setAt` or `keyOr` in DC (Chart.js ADR 0012). These helpers model
  JS operators and have no upstream name. `item` collides with the local `item` of the parse
  methods (Chart.js ADR 0023). The copies in `core.controller.dart` stay.
- Local copies in each controller file. More code, the same speed (Evidence E6, B6).
- `jsGetIndex(List<Object?>, double)` (S) or `jsArrayGet` (P) in `js_array.dart`. The `Object?`
  receiver of F also replaces `_getIndex`, at no measured cost.
- `jsGetNullish` (P), one public copy of `_parsedValue`. Equal speed, but it puts a read with Dart
  `null` for an absent key into the runtime list of the controllers, where it gives a wrong result
  at three sites.
- The cast of the parsing key at the default (S). It moves the throw before the `iScale.parse` of
  the first item, and a category scale has one more label after the throw.

**Question 3.**
- A cast of each parsed item to a Map. Throws for a number or a List item, where upstream gives
  NaN.
- `ChartMeta.parsed` as `Object?`. Each reader of `meta.parsed` then needs a cast.
- No change for List items (P, S). Keeps a `TypeError` at DC:354 where upstream writes `_stacks`
  into the array. A throw is a protected behavior (Chart.js ADR 0009).
- Option A of F: keep the throw and extend the text of the row `js-semantics-resolver-objects`.
  No code. This is the fallback of Open 1.
- A general Expando of array properties in the List branch of `jsGet`. A named read of a List goes
  from 6.7-7.3 ns to 22.6-34.0 ns, also for the array scopes of the resolvers (Evidence E2).

**Question 4.**
- Keep `toNumberProp` for `inflateAmount`. An `ArgumentError` where upstream draws.
- `BarElement.inflateAmount` as `Object?` with `jsToNumber` in `draw` (P). Changes a typed
  property of a phase 4 element (Chart.js ADR 0017 §3). A read by name of `inflateAmount` is not a
  behavior that Chart.js ADR 0009 protects. No measurement shows a performance difference.
- `jsToNumber` at the write for each value (S). Stores NaN for `undefined`, where the property
  keeps its `undefined` state.
- `jsToNumber` of the parsed value at the polar area compare (F §4.4). It gives the scale 0..30
  where upstream gives 0..9 for string values (Evidence E8). No draft probed string values there.
  The synthesis found the case in the pinned source.

**Question 5.**
- Only the reads of questions 1 and 2 now (S), or one Dart call for each upstream operation (F).
  Both reject a measured gain of 15 to 24 ns (the 3-read form) for each point of a form that keeps
  every statement.
  Performance comes before structure.
- The 2-read form: the read `prevParsed[iAxis]` uses the `iValue` local of the previous pass. It
  saves 22 to 24 ns (AOT) and 33 to 36 ns (wasm) for each point. The U-line review (wave 2, R2)
  proved that a scriptable option can write `ctx.parsed` between two passes. Then the local holds
  an old value and the segments change. Decision D10 keeps the 3-read form (section 8, Open 4).
- The bar memo now. A structure change with no frame figure yet (Chart.js ADR 0020 §13).

## Consequences

- The controllers give the upstream result for an absent key, a `null` value, a primitive item, a
  List item and a resolver item. The protected throws stay at the upstream sites.
- The JS runtime gets four generic functions. ADR 0008 later copies them into `js_semantics` with
  `lib/src/js/`.
- Three private helpers go: `_item` and `_setAt` of DC, `_item` of `core.controller.dart`.
  `_getIndex` goes too. `_lessThan` and `_toPrimitive` of DC move into `jsLessThan`.
- The sorted test of DC `parse` (DC:1048) compares two `DateTime` values by their time values.
- DC gets `stacksOf` and one `Expando`, about 25 lines, after Open 1.
- `getMinMax` gets 0.5 to 2.9 ns faster for each item. The line and scatter updates get 15 to
  24 ns faster for each point.
- `bar.inflateAmount` by name gives a number for a raw value outside `number | 'auto'`
  (`index.d.ts:2171`).
- A reviewer checks the one-read rule for each loop that uses it. A bump that adds a write between
  two reads of a key ends the rule at that loop.
- No new `DIVERGES` marker, no new row, no skip reason. Chart.js ADRs 0017, 0020 and 0025 do not
  change.

## Open

1. **`stacksOf` before it lands.** Owner: the agent of the DC change (spec step 3). Trigger: the
   change of section 5.3. The agent measures `updateRangeFromParsed` and `_updateStacks` with and
   without `stacksOf` on AOT and wasm, with the bed of the judge benchmark. A paired loss of more
   than 0.5 ns for each item on a platform goes to the maintainer, who chooses section 5.3 or the
   fallback (option A of question 3: keep the throw, extend the row text).
2. **The early cast of DC `parseObjectData`.** Owner: the step 6 review of phase 7. Trigger: the
   review of DC, or the first wave that changes `parseObjectData`. The fix is the form of
   section 4 (`valueOrDefault` and the cast at the `resolveObjectKey` call), with a pin test of
   the throw site.
3. **The step 7 list.** Owner: step 7 of phase 7. Trigger: the start of step 7. Each form of the
   list of section 8 gets an A/B with the frame figures (the frameless benchmark and the Pixel
   8a). Evidence that exists: the bar memo removes 34 to 43 % of the bar `updateElements` time in
   V8 (6 % with `skipNull`) (Evidence E3, P-P2); the shares of `_calculateBarIndexPixels`,
   `_getStacks` and `_getAxis` in an upstream bar update (Evidence E2, F-P3). The empty-Map path
   of `getDataVisibility` (17 to 22 ns for each call, Evidence E3, P-B7) is not in the list:
   Chart.js ADR 0028 §4 adopts it.
4. **The `prevIValue` local.** Closed by decision D10 (2026-10-21): the 3-read form replaces it
   in the line and scatter loops (section 8). A 2-read form only on the paths without user code
   needs a microbenchmark first (performance.md §13.7 item 6).
5. **`prefer-inline` on `jsGetKey`.** P measured no gain for the pragma in the line loop. Owner:
   step 7. Trigger: Chart.js ADR 0025 Open 3 (the same question for `jsToNumber`).

## Evidence

All files are in the session scratchpad folder
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/`
(below: `<design>`). The behavior probes ran the Chart.js build at the pin in the x64 Node.js
v24.12.0 under Rosetta. The benchmarks ran on an Apple M3 Max, macOS 26.5.1, Dart 3.12.2.

- **E0, upstream source** at `v4.5.1+7169e651`:
  - `src/controllers/controller.bar.js:61-115`, `:160-179`, `:202-256`, `:320-338`, `:398-450`,
    `:535-666`, `:668-680`
  - `src/controllers/controller.line.js:76-120`, `controller.scatter.js:111-151`
  - `src/controllers/controller.bubble.js:40-80`, `:96-109`, `:151-168`
  - `src/controllers/controller.doughnut.js:145-166`, `:246-254`
  - `src/controllers/controller.polarArea.js:97-111`, `:113-142`, `:161-236`
  - `src/controllers/controller.radar.js:39-51`, `:81-103`
  - `src/core/core.datasetController.js:75-76`, `:89`, `:102-118`, `:143`, `:150-175`,
    `:210-226`, `:365-392`, `:455-490`, `:555-571`, `:579`, `:593-617`, `:628-645`, `:662-674`,
    `:686-698`
  - `src/elements/element.bar.js:127-140`, `:152`, `:172`, `:179-196`
  - `src/helpers/helpers.config.ts:444-452`, `src/types/index.d.ts:124`, `:134`, `:503`, `:2171`
- **E1, the panel:** [judge.md](../../../../.handover/phase7/design/parsed-data/judge.md),
  [draft-fidelity.md](../../../../.handover/phase7/design/parsed-data/draft-fidelity.md),
  [draft-performance.md](../../../../.handover/phase7/design/parsed-data/draft-performance.md),
  [draft-simplicity.md](../../../../.handover/phase7/design/parsed-data/draft-simplicity.md).
- **E2, fidelity probes and benchmarks:** `<design>/parsed-data-fidelity/`: `probe.mjs` (F-P1),
  `probe2.mjs` (F-P2), `probe3.mjs` (F-P3, the shares of the bar update), `probe4.mjs` (F-P4),
  each with its `.out`; `bench/bin/index_read_bench.dart` (the index read) and
  `bench/bin/array_props_bench.dart` (the Expando in `jsGet`). `README.md` gives the commands.
- **E3, performance probes and benchmarks:** `<design>/parsed-data-performance/`:
  `probe/probe.mjs` (P-P1), `probe/bar_timing.mjs` (P-P2, the bar memo in V8),
  `bench/bin/read.dart` (P-B2, P-B3), `bench/bin/read2.dart` (P-B1, P-B5),
  `bench/bin/proxy.dart` (P-B4), `bench/bin/placement.dart` (P-B6), `bench/bin/visibility.dart`
  (P-B7). `README.txt` gives the commands.
- **E4, the judge benchmark:** `<design>/parsed-data-judge/`: `bin/judge_bench.dart`, `run.sh`,
  `diffs.py`, `out/` and `summary.txt`. Load average 4 to 6. A first series without the 3-read
  form gave the same signs.
- **E5, simplicity probes and benchmarks:** `<design>/parsed-data-simplicity/`:
  `probe/probe_parsed.mjs` (S-P1), `probe/probe_absent.mjs` (S-P2, the three sites where `null`
  and `undefined` differ), `bench/parsed_read.dart` (S-B1), `bench/index_read.dart` (S-B2).
- **E6, the other receivers:** P-B4 (a Map-first `jsGet`), P-B6 (the place of a helper has no
  cost), P-B7 (`_indexKey` against `jsNumberToString`, `getDataVisibility`).
- **E7, scans:** `grep -rn "jsGet(" lib/src | wc -l` (444 on 2026-10-21, P-B4);
  `grep -rn inflateAmount test/specs src` at the pin (only the element and the controller read
  it); `grep -rn _getRuler test/specs` (no reader).
- **E8, the synthesis probe:** `<design>/parsed-data-synthesis/probe_polar_strings.mjs`, output
  `probe_polar_strings.out`: polar area `getMinMax`, the scale limits and the ticks for string and
  number `r` values with `parsing: false`.
