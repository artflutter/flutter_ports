# Draft (simplicity first): Parsed data in the controllers

- Panel: "Parsed data in the controllers" (future Chart.js ADR 0027), phase 7 step 2.
- Lens: SIMPLICITY FIRST. The draft looks for the form with the least code of our own and the
  fewest new concepts that keeps the protected behavior. It still scores each option in the order
  of the decision protocol: behavior, performance, structure, less code.
- Pin: Chart.js v4.5.1+7169e651. The upstream lines below are lines of `third_party/Chart.js` at
  that pin. The Dart lines are lines of the working tree on 2026-10-21.
- Abbreviations: `DC` is `lib/src/core/core.datasetController.dart`. `dc.js` is
  `src/core/core.datasetController.js`. `bar.js`, `line.js` and the other names are the files of
  `src/controllers/`.
- Scratch folder (below: `<s>`):
  `/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/parsed-data-simplicity/`

## 0. The choices in one table

| Question | Choice | New names |
|---|---|---|
| 1. The parsed read | `jsGetKey(Object? object, String key)` in `lib/src/js/js_object.dart`: the result of `jsGet` for every value, with an inline read for a plain Map. The controllers use it for each `parsed[key]`. `getMinMax`, `updateRangeFromParsed`, `applyStack`, `_updateStacks` and the sorted test of `parse` switch their `jsGet` reads to it. The `_parsedValue` reads stay. | `jsGetKey` |
| 2. The private helpers | `_item` becomes `jsGetIndex` and `_setAt` becomes `jsSetIndex`, both in `lib/src/js/js_array.dart`. The two `_item` copies go. `_keyOr` stays private: bar and doughnut write the default inline, as `helpers.config.dart:914-915` does. The three `_parsedValue` copies stay unchanged. | `jsGetIndex`, `jsSetIndex` |
| 3. `parsing: false` | No new code. A parsed item stays `Object?`. No controller casts a parsed item. Every read goes through `jsGetKey` or `jsGetIndex`, which give the JS result and the JS `TypeError`. The doughnut cast of `data` cannot fail, because `_dataCheck` throws first, as upstream does. | none |
| 4. Writes and raw options | `point.parsed = null` cannot occur: upstream throws at the read before the write. `inflateAmount` gets `jsToNumber` at the write. The raw options stay `Object?` until their JS operator: `jsToNumber` for arithmetic and `<`, `jsTruthy(a) ? a : b` for `a \|\| b`, Dart `==` for `===`, the raw value for a scale value method. | none |
| 5. The hot loops | Port each loop literally. Adopt now only the three reads of questions 1 and 2, with the figures below. Step 7 decides every other form with an A/B on the frameless benchmark. | none |

The draft adds three functions of 5 to 7 lines each to the JS runtime. It removes three private
functions (`_item` of DC, `_item` of `core.controller.dart`, `_setAt` of DC). It adds no
`DIVERGES` marker, no `differences.md` row, no skip reason and no change of an element class.

## 1. Evidence

### 1.1 Upstream source read for this draft

- `bar.js:7-18`, `:61-115`, `:117-168`, `:170-172`, `:174-179`, `:202-256`, `:320-338`,
  `:343-351`, `:364-377`, `:393-425`, `:434-479`, `:485-527`, `:532-557`, `:563-631`,
  `:636-666`, `:668-680`.
- `line.js:76-120`; `scatter.js:42-54`, `:111-151`.
- `bubble.js:37-78` (the three `parse*Data` overrides), `:84-91`, `:96-109`, `:118-144`,
  `:151-168`.
- `doughnut.js:146-166` (`parse`), `:246-254`, `:256-294`, `:296-318`, `:320-330`.
- `polarArea.js:97-111`, `:113-142`, `:161-214`, `:216-236`.
- `radar.js:39-51`, `:53-79`, `:81-103`.
- `dc.js:102-117` (`convertObjectDataToArray`), `:152-175` (`updateStacks`), `:208-227`
  (`clearStacks`), `:365-392` (`_dataCheck`), `:451-500` (`parse`, the sorted test at `:473`),
  `:561` (the `{xAxisKey = 'x', yAxisKey = 'y'}` default), `:579` (`getParsed`), `:593-605`
  (`applyStack`), `:607-620` (`updateRangeFromParsed`), `:622-660` (`getMinMax`, the reads at
  `:635-636`), `:662-674` (`getAllParsedValues`), `:962-989` (`_resyncElements`: `parse(0,
  count)` at each update).
- `src/elements/element.bar.js:127-139` (`inflateRect`), `:172`, `:180-196` (`draw`).
- `src/types/index.d.ts:124` (`barThickness: number | 'flex'`), `:134` (`minBarLength:
  number`), `:2152` (`base: number`), `:2171` (`inflateAmount: number | 'auto'`).

### 1.2 Dart source read for this draft

- DC:226-245 (`_plus`, `_convertObjectDataToArray` with `meta.iScale!` at `:234`), `:331-372`
  (`_updateStacks`, the reads at `:349-351`), `:415-441` (`_clearStacks`), `:499-565` (`_at`,
  `_item`, `_getIndex`, `_indexKey`, `_setAt`, `_parsedValue`), `:905-940` (`_dataCheck`),
  `:1017-1062` (`parse`, the sorted test at `:1046-1048`), `:1167-1189` (`parseObjectData`,
  `_keyOr`), `:1199-1201` (`getParsed`), `:1218-1257` (`applyStack`, `updateRangeFromParsed`),
  `:1265-1307` (`getMinMax`, the `skip` closure at `:1277-1283`), `:1312-1325`
  (`getAllParsedValues`), `:1340-1351` (`getLabelAndValue`).
- `lib/src/core/core.interaction.dart:144-149` and `lib/src/helpers/helpers.extras.dart:299-304`
  (the two other `_parsedValue` copies). `lib/src/core/core.controller.dart:2315-2322` (the
  second `_item`). `lib/src/helpers/helpers.core.dart:574-577` (an `_item` with an `int` index, a
  different read).
- `lib/src/helpers/helpers.config.dart:893-926` (`_parseObjectDataRadialScale`: the inline
  default `{key = 'r'}` at `:914-915`, the read `jsGet(data, jsNumberToString(index))` at `:920`).
- `lib/src/js/js_object.dart:15-62` (`jsGet`), `lib/src/js/js_array.dart:44-58`
  (`JsProxyObject`: `operator []` is the `get` trap, `containsKey` is the `has` trap),
  `lib/src/js/js_number.dart:24-71` (`jsToNumber`, `jsTruthy`, `jsOrZero`).
- `lib/src/core/core.element.dart:302-424` (`operator []=`, `toNumberProp`, `toObjectProp`),
  `lib/src/elements/element.point.dart:203-213`, `:312` (`parsed`),
  `lib/src/elements/element.bar.dart:385-430`, `:455-500` (`inflateAmount`).
- Chart.js ADR 0025 §8 and its benchmark table, `performance.md` §10.3, §11.2 and §11.8 item 2,
  Chart.js ADR 0017 §5 and §8, Chart.js ADR 0020 §13, `porting-flow.md` §1.1.

### 1.3 Probes (x64 Node.js v24.12.0 under Rosetta, the Chart.js build at the pin)

Both scripts load the build through `loadChartJs` of `tool/reference/scale_chart_common.mjs`,
which stops unless Node.js is x64 and the build is at the pinned commit.

- **P1** `<s>/probe/probe_parsed.mjs`, output `<s>/probe/probe_parsed.out`. All registerables,
  legend and tooltip off.
- **P2** `<s>/probe/probe_absent.mjs`, output `<s>/probe/probe_absent.out`. The controllers,
  elements and scales only (no plugin).

Results that this draft uses:

| Case | Upstream result |
|---|---|
| doughnut, `parsing: false`, object data `{a: 1, b: 2}` and `{0: 3, 1: 1}` | throws `TypeError: Cannot read properties of undefined (reading 'axis')` (`dc.js:104`, in `_dataCheck` before `parse`) |
| doughnut, `parsing: false`, `[1, 2, 3]` | total 6, circumferences 1.047 / 2.094 / 3.142, `meta._parsed === dataset.data` |
| doughnut, `parsing: false`, `[{value: 1}, {value: 2}]` | total 0, circumferences 0, value label `'NaN'` |
| doughnut, `parsing: false`, `[1, null, 2]` | total 3, the `null` arc 0 |
| polarArea, radar, bubble, line, `parsing: false` with a `null` item | throws `TypeError: Cannot read properties of null (reading 'r' / 'x')` |
| line, `parsing: false`, `null` item, with and without `segment` | throws the same `TypeError` before `line.js:106` |
| line, `parsing: false`, number items, `segment` set | no throw, `point.parsed` is the number |
| polarArea / radar, `parsing: false`, number or array items | NaN radius / NaN point, `skip: true`, no throw |
| polarArea, `parsing: false`, `[{r: 1}, {}, {r: 3}]` | `countVisibleElements()` 2, arcs of a half circle |
| polarArea, `parsing: false`, `[{r: 1}, {r: null}, {r: 3}]` | `countVisibleElements()` 3, arcs of a third, `getMinMax().min` is `null` |
| scatter, logarithmic x, `parsing: false`, item `{y: 5}` | `x` is the pixel of the min (30.682), `skip: false` |
| scatter, logarithmic x, `parsing: false`, item `{x: null, y: 5}` | `x` NaN, `skip: true` |
| bar, `parsing: false`, item `{x: 'b'}` | the draw test of `bar.js:676` is true (`undefined !== null`) |
| bar, `parsing: false`, item `{x: 'b', y: null}` | the draw test is false |
| bar, `base: 5` against `base: '5'` | base 247.4 against 246.9, height 236.2 against 236.7: `getLineWidthForValue('5')` finds no tick (`===`), so no half grid |
| bar, `base: 5` against `base: '5'`, `minBarLength: 20` | the bar of value 5 moves by `size / 2` only for `base: 5` (`value === actualBase`, `bar.js:603`) |
| bar, `minBarLength: '20'` | the same bars as `minBarLength: 20` |
| bar, `barThickness: '20'` | width 20, as for `20` |
| bar, `barThickness: 'flex'`, `grouped: false` | width NaN (`'flex' * ratio`) |
| bar, `inflateAmount: '2'`, `null`, `'x'` | no throw; the element stores `'2'`, `null`, `'x'` |
| radar, a label index past the end | `label: undefined` |
| bar, labels shorter than the data | the parsed index value of the item past the labels is `null` (category `parse(undefined)`) |

The polarArea case with `{r: 3}` and object data throws in the colors plugin
(`plugin.colors.ts:49`, `dataset.data.map`). That is a plugin of phase 8 and not a parsed read.

### 1.4 Benchmarks

Bed: Apple M3 Max, macOS 26.5.1, Dart 3.12.2. AOT is `dart compile exe`. wasm is
`dart compile wasm -O2`, run in Node.js v24.12.0 (arm64), for times only. The benchmarks import
the real files of `lib/src/js/` and `lib/src/helpers/helpers.core.dart` through the workspace
package config. A warm-up runs each loop over mixed items (a `JsProxyObject`, a `List`, a number,
Maps), so each type test sees more than one class. Then 5 warm-up batches and 15 batches of 10
passes, in an alternate order. A cell gives the lowest and the highest median of the processes,
in ns for each item.

**B1, the parsed read** (`<s>/bench/parsed_read.dart`, outputs `<s>/bench/aot_{1..6}.out`,
`wasm_{1..6}.out`, `summary.txt`, `diffs.txt`; runner `<s>/bench/run_wasm.mjs`). 20000 Map items,
10 % with `y: null`, 1 % without `y`. 6 processes for each platform.

Forms of the read:
- **P**: `_parsedValue` of DC:564 (Dart `null` for an absent key).
- **J**: `jsGet`, unchanged.
- **U**: the Map read of Chart.js ADR 0025 §8, else `jsGet`.
- **X**: U only for a Map that is not a `JsProxyObject`, else `jsGet`. It gives the result of
  `jsGet` for every value. This is the proposed `jsGetKey`.

Loops:
- **minmax**: the loop of DC `getMinMax` (`:1277-1299`) with `updateRangeFromParsed` inline: three
  reads for each item. "minmax P" is the form of today: P for the `isFinite` read, J for the two
  other reads. "minmax T" is the proposed form: P for the `isFinite` read, X for the two other
  reads.
- **line**: the reads of `line.js:98-104`: four reads for each item.

| Loop | AOT | wasm |
|---|---|---|
| minmax P (today) | 34.74-36.31 | 42.11-43.00 |
| minmax J (all `jsGet`) | 36.06-36.87 | 42.08-45.52 |
| minmax U | 34.11-35.15 | 41.17-43.12 |
| minmax X | 34.30-35.70 | 40.92-42.69 |
| **minmax T (proposed)** | **32.94-34.48** | **39.99-41.63** |
| line P (wrong result for an absent key) | 39.99-41.15 | 50.02-51.44 |
| line J | 43.71-45.24 | 54.32-56.81 |
| line U | 42.13-42.95 | 54.99-56.27 |
| **line X (proposed)** | **42.69-44.15** | **55.12-56.51** |

The differences in each process (`diffs.txt`):
- T minus today: -0.69 to -2.29 ns on AOT and -0.88 to -2.32 ns on wasm, below 0 in each of the
  12 processes. About 4 % of the loop.
- X minus J, minmax: -0.90 to -1.96 ns (AOT) and -0.83 to -3.53 ns (wasm), below 0 in each of the
  12 processes.
- X minus J, line: -1.42 to -1.96 ns in 5 of 6 AOT processes (+0.44 in one). On wasm -1.45 to
  +1.54 ns: no measured gain and no measured loss.
- X minus P, line: +1.98 to +4.16 ns (AOT) and +4.85 to +5.91 ns (wasm). P is faster, but it
  gives `null` for an absent key (section 2, option C).
- X against U: equal within the spread on both platforms. The `is! JsProxyObject` test costs no
  measured time.

**B2, the read `data[i]` with a number index** (`<s>/bench/index_read.dart`, outputs
`<s>/bench/idx_aot_{1,2,3}.out`, `idx_wasm_{1,2,3}.out`). 20000 Map items, 3 processes.

| Read | AOT | wasm |
|---|---|---|
| `jsGet(data, jsNumberToString(index))` (`helpers.config.dart:920`) | 21.49-21.93 | 17.16-17.42 |
| `jsGetIndex(data, index)` (the `_item` form of DC:511) | 3.33-3.39 | 1.41-1.45 |

## 2. Question 1: the parsed read

### Options

| Option | Form | Behavior | Performance (B1) | Structure | Code |
|---|---|---|---|---|---|
| A. Upstream form | `parsed[key]`: no Dart equivalent for `Object?` | - | - | - | - |
| B. `jsGet` everywhere (the form of the test controllers of Chart.js ADR 0025 §9) | `jsGet(parsed, key)` | exact | slowest: line J, minmax J | kept | 0 new lines |
| C. `_parsedValue` (P), made public | `item is Map ? item[key] : jsGet(item, key)` | wrong for an absent key: probe P2 (polarArea count 3 instead of 2, log scale NaN instead of the min pixel, the bar draw test) | fastest | kept | 0 new lines, one more export |
| D. The form of Chart.js ADR 0025 §8 (U) | Map read with `undefined`, else `jsGet` | exact for each value except a `JsProxyObject` item (`containsKey` is the `has` trap, which does not know the prefixed keys, `js_object.dart:20-21`, `js_array.dart:48`) | as X | kept | 6 lines |
| **E. X: `jsGetKey`** | D, with `is! JsProxyObject` | exact: the result of `jsGet` for every value | minmax T and line X | kept | 7 lines |
| F. A Map fast path at the top of `jsGet` | no new name | exact | not measured. `jsGet` has about 500 callers in `lib/`. The fast path adds two type tests to each resolver read, and the body stays too large to inline. A change of every caller needs its own A/B (kickstart, decision protocol 4). | kept | 4 lines |

### Choice: E, `jsGetKey`

- Behavior: E gives the `jsGet` result for every value. Thus it keeps `undefined` for an absent
  key (Chart.js ADR 0025 §8), the `TypeError` for a `null` or `undefined` item (probe P1: all five
  controllers throw at the read), and the `get` trap of a resolver.
- Performance: E is faster than B in both minmax runs and in the AOT line run, and equal to B in
  the wasm line run (B1). By `porting-flow.md` §1.1 and Chart.js ADR 0020 §13, a microbenchmark
  gain is enough for a form that keeps the structure.
- Simplicity: one rule for each `x[key]` of a parsed or data item with a String key. No reader
  needs a proof that `null` and `undefined` give the same result. Option C needs such a proof at
  each site, and probe P2 shows three sites where the proof fails: `isNaN` gives false for `null`
  and true for `undefined` (`polarArea.js:130`, `:221`), the log scale maps `undefined` to the min
  (`line.js:100`, `scatter.js:129`), and `!== null` is true for `undefined` (`bar.js:676`).
- Name: `jsGetKey`. It is `jsGet` for a String key, as `jsGetIndex` (question 2) is `jsGet` for a
  number index on a List. The pair needs no other new concept.
- File: `lib/src/js/js_object.dart`, next to `jsGet`. It is a pure layer. `core.interaction` and
  `helpers.extras` can import it; they cannot import DC, which is not a pure layer.

### Code form

```dart
/// `object[key]` for a String [key]: the result of [jsGet] for every value
/// (Chart.js ADR 0027).
///
/// A Map that is not a [JsProxyObject] is read inline: the value of [key],
/// or [undefined] for a key that the Map does not contain. Every other
/// value goes to [jsGet]: a resolver, a List, a String, a number, and the
/// [TypeError] of `null` and [undefined]. The controllers read the parsed
/// items and the data items with it.
Object? jsGetKey(Object? object, String key) {
  if (object is Map<dynamic, dynamic> && object is! JsProxyObject) {
    final Object? value = object[key];
    return value == null && !object.containsKey(key) ? undefined : value;
  }
  return jsGet(object, key);
}
```

- `Map<dynamic, dynamic>` is the form that dart2wasm tests without a compare of the type
  arguments (the comment of `jsGet`, `js_object.dart:44-46`).
- No `prefer-inline` pragma. B1 measured the function without it. Step 7 can measure the pragma
  (Chart.js ADR 0025, Open 3, has the same open point for `jsToNumber`).

### The readers of DC

| DC line | Upstream | Read today | Read after |
|---|---|---|---|
| `:349-350` `_updateStacks` | `dc.js:164` | `jsGet` | `jsGetKey` |
| `:351`, `:428` (`_stacks`) | `dc.js:165`, `:218` | `_parsedValue` (truthiness only) | unchanged |
| `:1047-1048` the sorted test of `parse` | `dc.js:473` (`=== null`, `<`) | `jsGet` | `jsGetKey` |
| `:1221`, `:1224` `applyStack` | `dc.js:596`, `:598` | `jsGet` | `jsGetKey` |
| `:1240`, `:1245` `updateRangeFromParsed` | `dc.js:608`, `:610` | `jsGet` | `jsGetKey` |
| `:1279` the other axis in `skip` | `dc.js:635` | `jsGet` | `jsGetKey` |
| `:1280` the axis in `skip` | `dc.js:636` (`isFinite`) | `_parsedValue` | unchanged |
| `:1318` `getAllParsedValues` | `dc.js:668` (`isFinite`) | `_parsedValue` | unchanged |
| `:1346`, `:1349` `getLabelAndValue` | `dc.js:693-694` | `jsGet` | `jsGetKey` |

- This is the "minmax T" form of B1: -0.7 to -2.3 ns for each item on both platforms. It is item 2
  of `performance.md` §11.8 with one change: the `isFinite` read keeps `_parsedValue`, because
  `isFinite` gives false for both `null` and `undefined`, and B1 measures T below X.
- `updateRangeFromParsed` must keep `undefined`: `_applyStack` returns `undefined` for a `null`
  value only (`dc.js:75-76`, DC:192). An absent key gives `undefined`, which the sum turns into
  NaN. `jsGetKey` keeps this, as `jsGet` does today.
- The `_parsedValue` copies of `core.interaction.dart:148` and `helpers.extras.dart:303` stay.
  Their readers test `isNullOrUndef` only. Chart.js ADR 0025 §8 keeps `_parsedValue` for such
  readers, and B1 measures P as the fastest read.

## 3. Question 2: the private helpers of DC

### `_keyOr` (DC:1188, the default of `{xAxisKey = 'x'} = this._parsing`)

| Option | Code | Note |
|---|---|---|
| A. Public `@internal` method `keyOr` of DC (Chart.js ADR 0012) | rename and annotate | one more member of the controller API for a one-line idiom |
| B. A shared function in `lib/src/js/` | a new concept: "destructuring default" | three callers |
| **C. Inline at each site** | `identical(v, undefined) ? 'x' : v! as String` | the form of `helpers.config.dart:914-915` for `{key = 'r'}`; a JS destructuring default is inline syntax |

Choice: C. The readers are `bar.js:326` (two keys) and `doughnut.js:158` (one key). Each reads the
key once for each `parse`, so the form has no cost. `v! as String` throws a `TypeError` for
`null` and for a key that is not a String, where `resolveObjectKey` throws a `TypeError`
upstream (the doc of DC:1160). `_keyOr` of DC stays private and unchanged.

### `_item` (DC:511) and the copy in `core.controller.dart:2317`

| Option | Code | Note |
|---|---|---|
| A. Public `@internal` top-level `item` of DC (Chart.js ADR 0012) | rename | collides with the local `Object? item` of `parseArrayData`, `parseObjectData` and the controllers. Chart.js ADR 0023 then gives `item_`. The copy of `core.controller.dart` stays. |
| B. Local copies in each controller file | 6 lines in each of 5 files | more code |
| C. `jsGet(list, index)` | no new code | `jsGet` makes the key string and parses it back: B2 measures 21.5 ns (AOT) and 17.2 ns (wasm) for each read |
| **D. `jsGetIndex(List<Object?> list, double index)` in `lib/src/js/js_array.dart`** | 7 lines; two copies go | 3.3 ns (AOT) and 1.4 ns (wasm) for each read (B2) |

Choice: D. One function replaces the two private copies. The controllers use it for `data[i]`,
`labels[i]` and `meta._parsed[i]`:
- `bar.js:162`, `:164`, `:332`; `bubble.js:61`, `:74`; `doughnut.js:155`, `:159`, `:250`,
  `:253`, `:303`, `:324`; `polarArea.js:101`, `:104`; `radar.js:44`; `scatter.js:51`;
  `bubble.js:106`; `line.js:107`, `scatter.js:136` (`_dataset.data[i]`).
- `helpers.config.dart:920` switches from `jsGet(data, jsNumberToString(index))` to
  `jsGetIndex(data, index)` (`_parseObjectDataRadialScale`, the parse of polarArea and radar).
  B2: -18.1 ns (AOT) and -15.8 ns (wasm) for each item. The upstream form `data[i]`
  (`helpers.config.ts:449`) has no key string, so the change keeps the structure.
- A list that the controller makes itself and reads with an index in range uses the Dart read:
  `ruler.pixels[index]` (`bar.js:79`, `:91-93`) is a `List<double>` of `meta.data.length` items,
  and the index is a data index below that length.

### `_setAt` (DC:547)

| Option | Note |
|---|---|
| A. Public `@internal` top-level `setAt` of DC (Chart.js ADR 0012) | possible; no collision. The read and the write then live in two files. |
| B. A local copy in `controller.doughnut.dart` | 6 lines of duplicate code |
| **C. `jsSetIndex<T>(List<T> list, int index, T value)` in `lib/src/js/js_array.dart`** | next to `jsGetIndex`; the DC copy goes |

Choice: C. The only new caller is `doughnut.js:164` (`meta._parsed[i] = getter(i)`). The doc
keeps the reason of DC:539-546: a write at the length appends, and a write past the length throws
a `RangeError` where JavaScript leaves a hole (the row `platform-array-events`). No new row.

### The three `_parsedValue` copies

Choice: no change. Each copy has readers that do not tell `null` from `undefined` (DC `isFinite`
and truthiness, `core.interaction` and `helpers.extras` `isNullOrUndef`). P is the fastest read in
B1. A merge into one public function adds a port-only concept ("Dart `null` for an absent key")
that a controller could use where the result differs (probe P2). Chart.js ADR 0025 §8 already
keeps it for these readers.

### Code form

```dart
/// The JS read `list[index]` for a number [index] (Chart.js ADR 0027): the
/// item at a whole index below the length, else [undefined].
///
/// The `ToPropertyKey` of a number gives an array index only for a whole
/// number in range. -0 gives the key `'0'`. NaN, a fraction, a negative
/// number and a number past the end give [undefined], as the read of an
/// absent key does.
Object? jsGetIndex(List<Object?> list, double index) {
  if (index >= 0 && index < list.length) {
    final i = index.toInt();
    if (i == index) return list[i];
  }
  return undefined;
}

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

`js_array.dart` gets an import of `js_undefined.dart`. Both files are roots of the pure layers.

## 4. Question 3: `parsing: false` with an object or array data shape

### What upstream does (probe P1)

- The base `parse` assigns `this._data` (`dc.js:461`). `_dataCheck` (`dc.js:374-376`) converts
  object data to an array before. Thus polarArea, radar and bubble always get an array of raw
  items. The items are any value: a Map, an array, a number, `null`.
- Doughnut assigns `this.getDataset().data` (`doughnut.js:149`, `:153`). Object data never
  reaches it: `convertObjectDataToArray` reads `meta.iScale.axis` (`dc.js:103-104`), and the
  doughnut meta has no `iScale`. Upstream throws a `TypeError` in `_dataCheck` (probe P1, also
  for the numeric keys `{0: 3, 1: 1}`).
- A raw item gives the JS property read: a number or an array gives `undefined` for `r`, `x` and
  `y` (NaN pixel, `skip: true`); a `null` item throws a `TypeError` at the first read.

### Options

| Option | Behavior | Code |
|---|---|---|
| A. A cast of a parsed item to a Map in the controllers | throws for a number or an array item where upstream gives NaN | casts at each read |
| B. Make `ChartMeta.parsed` an `Object?` for the doughnut assignment | exact, but each reader of `meta.parsed` needs a cast | large change of a shared type |
| C. Convert object data in the doughnut `parse` | not needed: upstream throws before `parse` | new code for a case that throws |
| **D. No cast of a parsed item; every read through `jsGetKey` or `jsGetIndex`** | exact (probe P1) | none |

### Choice: D

- A parsed item stays `Object?`, as `getParsed` gives it (DC:1199, `index.d.ts:503`
  `_parsed: unknown[]`).
- A controller writes only into items that it makes itself: `item = {}` of `bar.js:163`, `:333`
  and the `List<AnyObject>` results of `super.parse*Data` in `bubble.js:47-76`. These are typed
  `AnyObject` locals. They need no cast.
- The doughnut reads `final data = jsGet(getDataset(), 'data')! as List<Object?>;`. The cast
  cannot fail: `_dataCheck` (DC:911-940) has replaced a falsy `data` with `[]`, has thrown in the
  cast `data! as List<Object?>` (DC:935) for a value that is neither a List nor a Map, and has
  thrown at `meta.iScale!` (DC:234) for a Map, as upstream throws at `dc.js:104`. The `///` line
  of the doughnut `parse` names these three facts.
- With `parsing: false`, `meta.parsed = data` keeps the identity of the dataset array, as
  `meta._parsed === dataset.data` upstream (probe P1). The reads `meta._parsed[i]` then use
  `jsGetIndex` and `jsToNumber` (`doughnut.js:253`, `:303-305`): an object item gives NaN, a
  `null` item gives the `=== null` branch (`doughnut.js:250`, `:304`).
- The bubble reads `item[2]` (`bubble.js:62`) with `jsGet(item, '2')`, and `item && item.r &&
  +item.r` (`bubble.js:75`) with `jsTruthy` and `jsGetKey`. A `null` item of the first index makes
  `isArray(data[start])` false, so the bubble reaches `parsePrimitiveData` or
  `parseObjectData`, as upstream.

## 5. Question 4: writes by name and raw option values

### `point.parsed = null` (`line.js:106`, `scatter.js:135`)

- Upstream reads `parsed[vAxis]` at `line.js:99` and `scatter.js:128` before the write. A `null`
  parsed item throws a `TypeError` there (probe P1, with and without `segment`). DC `getMinMax`
  reads the item even before that.
- `getParsed(i)` for `i < meta.data.length` names an item. Thus `undefined` does not reach the
  write either.
- The values that reach the write are a Map, a number, a String, a bool or a List. Each is an
  `Object`, which `toObjectProp<Object>` of `element.point.dart:312` accepts.

Choice: no change of `PointElement`. `jsGetKey(null, vAxis)` throws the `TypeError` at the same
read. A port-only test pins the throw.

### `inflateAmount` (`bar.js:252-256`)

| Option | Behavior | Code |
|---|---|---|
| A. Keep the write of the raw value: `toNumberProp` throws an `ArgumentError` for `'2'` and `null` | a throw where upstream stores the value (probe P1). Chart.js ADR 0017 §5 accepts a throw outside the type contract, and `index.d.ts:2171` is `number \| 'auto'`. But a JSON config or a scriptable option gives such values. | 0 |
| B. `BarElement.inflateAmount` becomes `Object?` with a `jsToNumber` in `draw` | exact for each by-name read | element field, getter, `draw`, `operator []` |
| **C. `jsToNumber` at the write in the controller** | the same draw: the only reader, `inflateRect` (`element.bar.js:127-139`), applies `ToNumber` through `-amount` and `amount - x`. A by-name read gives the number, not the raw value. | 1 call |

Choice: C. The draw for `'2'` is the draw for 2, for `null` the draw for 0, and for `'x'` the draw
for NaN, in both forms. The by-name read of `bar.inflateAmount` differs only for a value outside
`number | 'auto'`, which Chart.js ADR 0017 §5 does not count as a difference. No `DIVERGES` hunk.

```dart
// bar.js:252 setInflateAmount
void _setInflateAmount(AnyObject properties, AnyObject options, double ratio) {
  final inflateAmount = jsGet(options, 'inflateAmount');
  // The element applies ToNumber at each read (element.bar.js:127-139).
  properties['inflateAmount'] = inflateAmount == 'auto'
      ? (ratio == 1 ? 0.33 : 0.0)
      : jsToNumber(inflateAmount);
}
```

### Raw option values in arithmetic and `===` (`bar.js:61-115`, `:532-557`, `:563-631`, `:636-666`)

The options come from the dataset resolver as `Object?`. The port must convert them before Dart
arithmetic in each case. The JS runtime form is as short as a cast, and it is exact. Thus the rule
is: keep each raw value as `Object?` until its upstream operator, then apply that operator.

| Upstream form | Dart form | Lines |
|---|---|---|
| a raw value in arithmetic or in `<`, `>=` with a number | `jsToNumber(value)` at the operator | `bar.js:66`, `:72`, `:107-108`, `:555`, `:601-602`, `:652`, `:656`, `:178` |
| `a \|\| b` that keeps the value | `jsTruthy(a) ? a : b`, typed `Object?` | `bar.js:544` (`barThickness \|\| computeMinSampleSize(meta)`), `:565` (`baseValue \|\| 0`) |
| `a \|\| 0` before arithmetic only | `jsOrZero(a)` | `bar.js:220`, `:222` |
| `===` on raw values | Dart `==` on the `Object?` values: it gives the `===` result for numbers, strings, `bool`, `null` and the sentinel | `bar.js:603` (`value === actualBase`), `:645` (`=== 'flex'`), `:253` (`=== 'auto'`), `:211` |
| a raw value given to a scale value method | the raw value: the method takes `Object?` (Chart.js ADR 0025 §1) | `bar.js:590` (`startValue`), `:619-620` (`actualBase`) |
| `valueOrDefault(options.maxBarThickness, Infinity)` | `valueOrDefault` of `helpers.core`, then `jsToNumber` at `Math.min` | `bar.js:640`, `:652`, `:656` |
| `start + length` (a stacked value can be a String) | `jsAdd(start, length)` | `bar.js:593` |
| `values.radius += …` | `values['radius'] = jsAdd(values['radius'], …)` | `bubble.js:165` |

The ruler is a record (Chart.js ADR 0003, a record for an inline object type) with raw fields
where upstream keeps raw values:

```dart
// bar.js:546-556
({
  Object? min, // barThickness || computeMinSampleSize(meta): a raw option or a number
  List<double> pixels,
  double start,
  double end,
  double stackCount,
  types.Scale scale,
  Object? grouped, // opts.grouped, tested with jsTruthy
  double ratio,
}) _getRuler() { ... }
```

```dart
// bar.js:564-605, the raw options
final baseValue = jsGet(options, 'base');
final minBarLength = jsGet(options, 'minBarLength');
final actualBase = jsTruthy(baseValue) ? baseValue : 0.0; // baseValue || 0
...
final startValue = !isNullOrUndef(baseValue) && !floating ? baseValue : start;
var base = vScale.getPixelForValue(startValue);
...
if (size.abs() < jsToNumber(minBarLength)) {
  size = _barSign(size, vScale, actualBase) * jsToNumber(minBarLength);
  if (value == actualBase) base -= size / 2; // ===: 5 == '5' is false
  ...
}
if (base == vScale.getPixelForValue(actualBase)) {
  final halfGrid = sign(size) * vScale.getLineWidthForValue(actualBase) / 2;
  ...
}
```

Probe P1 pins each row: `base: '5'` gives a different base than `base: 5`, both through the
`===` of `getLineWidthForValue` and through `value === actualBase`; `minBarLength: '20'` and
`barThickness: '20'` act as numbers; `barThickness: 'flex'` with `grouped: false` gives a NaN
width.

## 6. Question 5: the hot loops

### Options

| Option | Behavior | Performance evidence | Structure | Code |
|---|---|---|---|---|
| **A. Literal port first. Step 7 changes a form only with an A/B** | upstream | the frameless benchmark and the stress entry of step 7 | kept | least |
| B. Hoist the loop invariants of the bar now (`_getAxis`, `getFirstScaleIdForIndexAxis`, `_getStacks` for each bar) | upstream if done right | no frame figure yet | changed: `DIVERGES` marker and `adapt` row | more |
| C. Typed setters in place of the by-name writes of `line.js:91-104` now | upstream | the gallery `StressPointController` form, not measured against the ported loop | changed | more |
| D. A cache of the bubble options for each item now | upstream if done right | none | changed | more |

### Choice: A, with the three reads of questions 1 and 2 adopted now

- The reads `jsGetKey` (B1), the "minmax T" form of `getMinMax` (B1) and `jsGetIndex` (B2) keep the
  upstream structure. A microbenchmark gain is enough for them (`porting-flow.md` §1.1, Chart.js
  ADR 0020 §13). Step 7 records their figures in `performance.md`.
- Each other candidate changes the upstream structure. Chart.js ADR 0020 §13 asks for a gain in
  the frame figures, at least 0.1 ms. Only step 7 has the instruments for that: the frameless
  benchmark (`apps/chartjs_gallery/lib/main_bench.dart`), the stress entry, the ABBA protocol of
  the kickstart and the Pixel 8a. A form chosen now has no such figure.
- The literal port is the "before" of each A/B. A form chosen now removes that baseline.
- The upstream complexity stays. Upstream has the same O(bars x datasets) work in
  `_calculateBarIndexPixels`, and the same O(bars x datasets x points) work with `skipNull`.

The list for step 7, with the upstream lines:

| Loop | Upstream | Cost for each update | Candidate form |
|---|---|---|---|
| bar, for each bar | `bar.js:642` and `:649` (`_getAxis`: `Object.keys` of the scales and a loop over the datasets, twice), `:650` (`_getStackIndex` -> `_getStacks`: `getMatchingVisibleMetas` and a filter) | O(bars x datasets) allocations | a hoist out of `updateElements` |
| bar, `skipNull` | `bar.js:444` (`meta._parsed.find` for each meta, for each bar), `:644` | O(bars x datasets x points) | a Map from the index value to the item for each meta |
| bar, options for each bar | `bar.js:638-645` (seven resolver reads) | 7 resolver reads for each bar | read once for each update |
| line, scatter, for each point | `line.js:91-115`, `scatter.js:127-144` (by-name writes into the point, or a new properties Map) | `operator []=` switch for each property | the typed setters of `StressPointController` |
| bubble, for each item | `bubble.js:46-78`, `:87-89`, `:135`, `:151-168` (`resolveDataElementOptions` and a `copyOptions` of the shared entry) | about 23.5 ns for each copy (Chart.js ADR 0021 §8) and the resolve | none chosen |
| polarArea, for each arc | `polarArea.js:128-130`, `:176`, `:181-182`, `:201`, `:221`, `:233-234` (up to four `getDataVisibility` calls and two option resolves) | a key string for each `getDataVisibility` call (`members-radial.md` R4) | the cast of Chart.js ADR 0025 Open 4 |
| radar, for each point | `radar.js:87-88` | one option resolve without sharing | none chosen |

Before the first change, step 7 records the figures of `StressPointController` in the Core and
Axes tabs, as the kickstart asks, so that the phase 5 and phase 6 figures stay comparable.

## 7. Files that the implementation changes

- `lib/src/js/js_object.dart`: add `jsGetKey`.
- `lib/src/js/js_array.dart`: add `jsGetIndex` and `jsSetIndex`, and the import of
  `js_undefined.dart`.
- `lib/src/core/core.datasetController.dart`: remove `_item` and `_setAt`, and call `jsGetIndex`
  and `jsSetIndex` (`:511`, `:521-522`, `:547`, and their callers `:1026`, `:1037`, `:1052`,
  `:1104-1105`, `:1137`, `:1177`, `:1200`). Switch the `jsGet` reads of the table in section 2 to
  `jsGetKey`. `_keyOr` and `_parsedValue` stay.
- `lib/src/core/core.controller.dart`: remove `_item` (`:2315-2322`) and call `jsGetIndex`.
- `lib/src/helpers/helpers.config.dart:920`: `jsGetIndex(data, index)`.
- `lib/src/controllers/controller.*.dart` and `index.dart` (new): the forms of sections 2 to 5.
- No change: `lib/src/elements/`, `lib/src/types/index.dart` (`ChartMeta.parsed` stays
  `List<Object?>`), `core.interaction.dart`, `helpers.extras.dart`.
- Docs (by the integration step, not by this draft): Chart.js ADR 0027 (proposed); the JS runtime
  list of `AGENTS.md` (the three functions); a section of `performance.md` with B1 and B2; the
  status texts of the controllers in `doc/status.yaml`. No `differences.md` row.

## 8. Tests that pin the decision

- `test/port/js/js_object_test.dart`, group `jsGetKey` (pure, `package:test`): for each value of
  a table, `jsGetKey(v, k)` is `identical` to `jsGet(v, k)`. The table has a Map with the key, a
  Map with a `null` value, a Map without the key, a `Map<String, num>`, a resolver of
  `helpers.config` with a prefixed key and with an absent key, a List, a String, a number, a
  `bool`, a `JsClass`. `null` and `undefined` throw a `TypeError` in both.
- `test/port/js/js_array_test.dart`, groups `jsGetIndex` and `jsSetIndex` (pure): the index 0,
  the last index, the length, -1, -0.0, 1.5, NaN and infinity; a write at the length appends, a
  write below it replaces, a write past it throws a `RangeError`.
- The controller reference tests of step 3 (`test/port/controllers/`, generated from the pinned
  build in the x64 Node.js), with the cases of probes P1 and P2:
  - polarArea, `parsing: false`, `[{r: 1}, {}, {r: 3}]` against `[{r: 1}, {r: null}, {r: 3}]`:
    `countVisibleElements`, `getMinMax` and the arc angles.
  - scatter, logarithmic x, `parsing: false`, `{y: 5}` against `{x: null, y: 5}`: `x` and `skip`.
  - bar, `parsing: false`, `{x: 'b'}` against `{x: 'b', y: null}`: the draw calls of `bar.js:676`.
  - bar, `base: 5` and `'5'`, with and without `minBarLength: 20`; `minBarLength: '20'`;
    `barThickness: '20'`; `barThickness: 'flex'` with `grouped: false`; `inflateAmount: '2'`,
    `null` and `'x'`: the element properties, the draw calls and the hit element.
  - doughnut, `parsing: false`, `[1, 2, 3]`, `[{value: 1}, {value: 2}]` and `[1, null, 2]`: the
    total, the circumferences and `getLabelAndValue(0).value`.
  - radar, a label past the end: `getLabelAndValue(1).label` is `undefined`.
- Port-only throw tests (`testWidgets`, `@TestOn('vm')`): `parsing: false` with a `null` item
  throws a `TypeError` for line (with and without `segment`), scatter, bubble, polarArea and
  radar; doughnut object data throws a `TypeError`.
- The existing tests of `getMinMax`, `getAllParsedValues` and the stacks
  (`test/specs/core.datasetController_test.dart`, `test/port/core/`, `test/port/scales/`) guard
  the switch to `jsGetKey` without a change.

## 9. Open points for the judge

1. On wasm, `jsGetKey` gives no measured gain in the line loop (B1). This draft keeps one read for
   all sites for the reasons of section 2. A judge with the performance lens can keep `jsGet` at
   the per-point sites of line and scatter on wasm only; that needs a second form at each site
   for a gain that B1 does not show.
2. The name `jsGetKey` and the pair `jsGetIndex` / `jsSetIndex` are a choice of this draft.
   Chart.js ADR 0025 §8 left the name to phase 7.
3. ADR 0008 later copies the generic runtime of `lib/src/js/` into `js_semantics`. The three new
   functions are generic, so they move with it.
