# Draft (performance first): parsed data in the controllers

- Panel: "Parsed data in the controllers" (future Chart.js ADR 0027). This file is one of three
  independent drafts. The lens of this draft is performance first: it looks for the fastest forms
  that keep the behavior that Chart.js ADR 0009 protects, and it measures them.
- Pin: Chart.js `v4.5.1+7169e651` (`third_party/Chart.js` at `7169e65147a4`). The port tree is at
  commit `0e0ab93`.
- Scratch folder of the evidence (below: `<pd>`):
  `/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/parsed-data-performance/`.
  `<pd>/README.txt` gives the command of each script.

## 1. Summary of the choices

| Question | Choice |
|---|---|
| 1. The parsed read | A new function `jsGetKey(Object? object, String key)` in `lib/src/js/js_object.dart`: the result of `jsGet`, with the Map case first. `jsGet` itself does not change: a Map-first `jsGet` is 1.9 ns slower on a resolver and 4.8 ns slower on a List (B4). `getMinMax` and the other hot readers of `core.datasetController.dart` switch to `jsGetKey` for each read that keeps `undefined`. |
| 2. The private helpers | Shared functions in the JS runtime (`lib/src/js/`, a pure layer): `jsArrayGet` and `jsArraySet` in `js_array.dart` (from `_item` and `_setAt`), `jsGetNullish` in `js_object.dart` (from the three `_parsedValue` copies). No `@internal` copies in `core.datasetController.dart`, no local copies. `_keyOr` gets no shared form: a controller writes `valueOrDefault(jsGet(parsing, 'xAxisKey'), 'x')`. |
| 3. `parsing: false` shapes | No cast of a data item or a parsed item. Each read goes through `jsGetKey`, `jsGet`, `jsArrayGet` or `jsToNumber`. The assignment `meta.parsed = data` stays: a Map `data` throws in `_dataCheck` before it, in upstream and in the port (probe P1). |
| 4. Writes by name and raw options | Raw option values stay `Object?` until the upstream operator. `jsToNumber` at each arithmetic or relational operator, `jsOrZero` only for `x \|\| 0` before arithmetic, `jsAdd` for `+`, Dart `==` for `===`. `BarElement.inflateAmount` stores the raw value, as upstream (probe P1: the draw is the draw of its `ToNumber`). `point.parsed = null` cannot occur: upstream throws before it (probe P1). |
| 5. The hot loops | Two classes. (a) Forms that keep the upstream structure, adopted now with micro benchmarks: `jsGetKey`, `jsGetNullish`, `jsArrayGet` in the radial parse helper, one read of each key of a parsed item for each loop pass (line and scatter: 5 reads become 2, -22 to -25 ns for each point on AOT, -34 to -39 ns on wasm), and the empty-Map path of `getDataVisibility` (-17 ns on AOT, -20 to -22 ns on wasm for each call). (b) Forms that change the structure (the bar memo of `_getAxis`, `getFirstScaleIdForIndexAxis` and `_getStacks`, the `skipNull` search, the bubble option copy, the double option resolution of polar area and radar): port literally, then step 7 measures each with the frameless benchmark (ABBA protocol of the kickstart prompt) on the Pixel 8a. In V8 the bar memo removes 34-43 % of the bar `updateElements` time (probe P2). |

## 2. Test bed and method

- Machine: Apple M3 Max, macOS 26.5.1, Dart 3.12.2 (stable). AOT is `dart compile exe`. wasm is
  `dart compile wasm -O2`, run in Node.js v24.12.0 (arm64), for times only.
- The benchmark package `<pd>/bench/` has the name `flutter_chartjs`. Its `lib/src/js/` is a copy
  of `packages/flutter_chartjs/lib/src/js/` without changes. Thus each benchmark calls the real
  `jsGet`, `jsToNumber`, `jsNumberToString`, `jsMin` and `jsMax`.
- The harness (`<pd>/bench/lib/harness.dart`) runs 5 warm-up rounds, then 15 or 21 rounds. In each
  round, the cases run in a rotated order. A cell is the median of the rounds, in ns for each unit.
  A range "a-b" gives the lowest and the highest median of the processes (3 or 6 processes).
- The data: 20000 parsed items `<String, Object?>{'x': i, 'y': value}`, with `null` for 10 % of
  the `y` values (the bed of Chart.js ADR 0025 E9). Other Map types run in the same program, so a
  type test is not trivial.
- The behavior probe P1 runs a build of Chart.js at the pin in the x64 Node.js v24.12.0 under
  Rosetta (Chart.js ADR 0010), through `loadChartJs` and `makeChart` of
  `tool/reference/scale_chart_common.mjs`, with all registerables.
- The timing probe P2 runs the same build in the arm64 Node.js, for times only.

## 3. Evidence

### B1: one read for each item (`<pd>/bench/bin/read2.dart`)

The loop reads `y` of each item and passes the value to a small function. 6 processes, ns for each
read (the loop cost is in each cell):

| Read | AOT | wasm |
|---|---|---|
| `jsGet` (now) | 10.82-11.94 | 16.14-17.78 |
| Chart.js ADR 0025 §8 form (Map read, `containsKey` on the null path) | 10.79-11.78 | 15.48-17.09 |
| `jsGetKey` (§8 form with the proxy guard on the null path) | 10.31-11.47 | 15.47-17.74 |
| `jsGet` with the Map case first | 10.31-11.45 | 15.43-19.16 |
| `_parsedValue` (Dart `null` for an absent key) | 9.77-10.78 | 13.68-15.14 |

Differences of the pairs in each process, mean of 6:
- `jsGetKey` - `jsGet`: -0.36 ns (AOT, 6 of 6 below 0), -0.63 ns (wasm, 5 of 6 below 0).
- `_parsedValue` - `jsGet`: -1.06 ns (AOT), -2.62 ns (wasm).
- `_parsedValue` - `jsGetKey`: -0.70 ns (AOT), -1.99 ns (wasm). The cost is the second hash
  lookup (`containsKey`) of the null values and the extra compare.

Outputs: `<pd>/bench/out/read2_aot_{1..6}.out`, `read2_wasm_{1..6}.out`.

### B2: the reads of `controller.line.js:98-104` (`<pd>/bench/bin/read.dart`)

For each point: the read `parsed[vAxis]` for `nullData` (:99), `parsed[iAxis]` (:100),
`parsed[vAxis]` again (:101), `parsed[iAxis]` and `prevParsed[iAxis]` (:104), and the virtual
`getPixelForValue(Object? value)` of two live scale classes (Chart.js ADR 0025 BF form). 3
processes, ns for each point:

| Form | AOT | wasm |
|---|---|---|
| 5 reads with `jsGet` | 50.86-52.13 | 74.12-75.43 |
| 5 reads with `jsGetKey` | 46.88-47.95 | 69.55-71.13 |
| 5 reads with `jsGetKey` and `prefer-inline` | 47.71-48.20 | 71.22-72.34 |
| 5 reads with the Map-first `jsGet` | 47.51-47.80 | 70.32-71.50 |
| `_parsedValue` for the null test, `jsGetKey` for the values | 46.15-46.27 | 67.73-70.48 |
| 5 reads with `_parsedValue` (wrong for an absent key) | 45.61-46.94 | 67.45-71.01 |
| **2 reads with `jsGetKey`: one local for each key, the previous `iAxis` value kept** | **24.58-24.95** | **36.02-36.34** |

- The count of the reads is the large effect. Each read costs about 7-8 ns (AOT) and 11-13 ns
  (wasm) in this loop. The form of the read changes 0.3-1 ns.
- The pragma `prefer-inline` gives no gain.

Outputs: `<pd>/bench/out/read_aot_{1,2,3}.out`, `read_wasm_{1,2,3}.out`.

### B3: the `getMinMax` loop (`<pd>/bench/bin/read.dart`)

The loop of `core.datasetController.dart:1265-1308` with the `skip` closure and a call of
`updateRangeFromParsed` that is not inlined. 3 processes, ns for each item:

| Reads (other axis, scale axis, range) | AOT | wasm |
|---|---|---|
| `jsGet`, `_parsedValue`, `jsGet` (now) | 32.68-33.02 | 43.13-43.62 |
| `jsGetKey`, `_parsedValue`, `jsGetKey` | 32.49-32.73 | 42.09-43.80 |
| Map-first `jsGet` for both | 32.30-32.77 | 41.92-43.24 |

The forms do not differ by more than the noise of the loop. The expected difference is 2 reads x
0.36 ns (AOT) and 2 x 0.63 ns (wasm) (B1). `performance.md` §11.8 item 2 estimates -3 to -5 % of
the linear update from the profile shares of `jsGet` (12.5 %) and `_parsedValue` (3.8 %). An
inference, not a measurement: `_parsedValue` is inlined into its caller, so the profile charges its
hash lookup to the caller, and the two shares do not compare. Step 7 measures the update with the
frameless benchmark.

### B4: a Map-first `jsGet` on the other receivers (`<pd>/bench/bin/proxy.dart`)

Two `JsProxyObject` classes (the resolver and the context proxy of `helpers.config` have this
form), and a List and a String receiver. 3 processes, ns for each read:

| Receiver | `jsGet` (now) AOT | Map-first AOT | `jsGet` (now) wasm | Map-first wasm |
|---|---|---|---|---|
| Two proxy classes | 9.18-9.38 | 11.06-11.29 | 14.26-14.72 | 15.23-15.48 |
| List and String | 13.09-13.59 | 18.09-18.32 | 9.80-10.01 | 11.68-12.10 |

The option reads go through resolvers, and `lib/src/` has 444 `jsGet(` calls. A Map-first `jsGet`
slows them. Thus `jsGet` keeps its order, and the parsed read is a separate function.

Outputs: `<pd>/bench/out/proxy_{aot,wasm}_{1,2,3}.out`.

### B5: the read `data[index]` with a number index (`<pd>/bench/bin/read2.dart`)

The read of `helpers.config.dart:920` (`_parseObjectDataRadialScale`), then `item.r`. 6 processes,
ns for each item:

| Read | AOT | wasm |
|---|---|---|
| `jsGet(data, jsNumberToString(index))` (now) | 35.41-39.13 | 35.93-44.03 |
| `_item(data, index)` (`core.datasetController.dart:511`) | 10.05-11.46 | 13.86-15.79 |

The string of the index costs about 25-28 ns for each item.

### B6: the place of a helper (`<pd>/bench/bin/placement.dart`)

The same `_item` body in the file of the loop and in a library of `lib/src/js/`. 3 processes, ns
for each read: AOT 1.67-1.68 for both, wasm 1.41-1.46 for both. The place has no cost.

### B7: `getDataVisibility` and the key of a dataset index (`<pd>/bench/bin/visibility.dart`)

`Chart.getDataVisibility` (`core.controller.dart:1751-1753`) through an interface with two live
classes, with an empty `_hiddenIndices` (the usual state). 3 processes, ns for each call:

| Form | AOT | wasm |
|---|---|---|
| Now: `!jsTruthy(_hiddenIndices[jsNumberToString(index)])` | 20.77-20.95 | 22.94-25.22 |
| `if (_hiddenIndices.isEmpty) return true;` before the same line | 3.85-3.91 | 2.88-2.98 |

The key of a dataset index from 0 to 7, ns for each key: `jsNumberToString` 6.42-6.80 (AOT),
6.28-6.62 (wasm); the cached `_indexKey` (`core.datasetController.dart:532`) 4.21-4.50 (AOT),
8.00-8.26 (wasm). The cache is slower on wasm. Thus the controllers do not need `_indexKey`.

### P1: behavior probe (`<pd>/probe/probe.mjs`, output `<pd>/probe/probe.out`)

| Row | Upstream result |
|---|---|
| line, scatter and bubble, `parsing: false`, item `{y: 5}` without `x`, logarithmic x axis | point 0 at x = 30.68 (the min pixel), `skip` false |
| the same with `{x: null, y: 5}` | point 0 at x = NaN, `skip` true |
| polar area, `parsing: false`, data `[5, {r: 3}, {r: 8}]` | `countVisibleElements()` 2, angles -1.5708..1.5708, 1.5708..4.7124, 4.7124..7.8540 |
| the same with `[{r: null}, {r: 3}, {r: 8}]` | `countVisibleElements()` 3, angles in thirds (`isNaN(null)` is false) |
| bar, `parsing: false`, item `{x: 'a'}` without `y` | `draw` draws 2 bars (`undefined !== null`) |
| the same with `{x: 'a', y: null}` | `draw` draws 1 bar |
| line, `parsing: false`, `x.min: 1`, item `{y: 50}` without `x` | y range 5..50: the item counts (`1 > NaN` is false) |
| the same with `{x: null, y: 50}` | y range 6..7: the item does not count (`1 > 0`) |
| doughnut and pie, object data `{a: 1, b: 2}`, with and without `parsing: false` | throws `TypeError` (`convertObjectDataToArray` reads `iScale.axis` of `undefined`, `core.datasetController.js:102-117`, `:374-376`) |
| polar area, object data | throws `TypeError` in `plugin.colors.ts:43-49` (phase 8). The controller path converts the data |
| doughnut, pie, polar area, radar, bubble, line, bar, scatter, `parsing: false` with numbers, strings, arrays, objects, mixed | no throw. `meta._parsed === data`. The doughnut uses `+item` (`[5]` gives 5, `[1, 2]` gives NaN). The others read `.r`, `.x`, `.y` of each item: `undefined` for a number, a string and an array |
| line, `parsing: false`, `segment` option, data `[null, {x: 1, y: 2}]` | throws `TypeError` "reading 'x'" in `getMinMax` (`core.datasetController.js:635`), before `controller.line.js:106` |
| the same with data `[5, {x: 1, y: 2}]` | `point.parsed` is 5, `point.raw` is 5 |
| bar `inflateAmount` `'2'`, `null`, `true`, `'x'`, `3` | `bar.inflateAmount` keeps the raw value. The rectangles equal those of 2, 0, 1, NaN and 3 |
| bar `base` `'2'` and `minBarLength: '3'` | base 302.96, the first bar 3 px high: both strings act as numbers |
| bar `base: true`; `base: 'b'` on a linear axis; `base: 'b'` on a category axis | `true` acts as 1; `'b'` gives NaN on linear; `'b'` gives the pixel of the label `'b'` on category (257.8) |
| bar `barThickness: 'flex'`, `grouped: false` | width NaN (`'flex' * ratio`); `'12'` gives 12 |

### P2: the bar update in V8 (`<pd>/probe/bar_timing.mjs`, output `<pd>/probe/bar_timing.out`)

The time of `updateElements` of all bar datasets (`mode 'none'`), median of 15 runs, 4 rounds in
the order ABBA. "Memo" computes `_getAxis()`, `getFirstScaleIdForIndexAxis()` and
`_getStacks(last, undefined)` once for each `updateElements` call. The element values are the same
in both forms (checked for the first 50 bars).

| Bars x datasets | Literal (ms) | Memo (ms) | Change |
|---|---|---|---|
| 1000 x 1 | 1.41 | 0.84 | -40 % |
| 5000 x 1 | 6.52 | 4.29 | -34 % |
| 1000 x 3 | 4.39 | 2.52 | -43 % |
| 5000 x 3 | 23.66 | 13.75 | -42 % |
| 1000 x 3, `skipNull: true` | 19.37 | 18.26 | -6 % |

With `skipNull`, the search `meta._parsed.find(...)` (`controller.bar.js:443-450`) takes most of
the time: it is O(bars x datasets x points) in upstream too.

## 4. Question 1: the parsed read

### Upstream form

The controllers read `parsed[axis]` and pass the value to a scale member or compare it with `===`:
`controller.bar.js:371`, `:374`, `:403`, `:441`, `:444-445`, `:540`, `:569`, `:655`, `:676`;
`controller.line.js:99-104`; `controller.scatter.js:47-48`, `:128-133`;
`controller.bubble.js:101-102`, `:129-130`; `controller.polarArea.js:101`, `:128`, `:182`, `:221`;
`controller.radar.js:45`, `:88`. An absent key gives `undefined`. P1 shows that the result changes
the ticks (the `getMinMax` row), the hit element and the item order (the polar area rows), and the
draw (the bar rows).

### Options

| Option | Behavior | Performance (B1, B2, B4) | Structure | Code |
|---|---|---|---|---|
| A. `jsGet(parsed, axis)` at each read | exact | slowest for Map items: +0.36 ns (AOT), +0.63 ns (wasm) for each read against C | the property read of Chart.js ADR 0017 §5 | none new |
| B. The form of Chart.js ADR 0025 §8: `value == null && !item.containsKey(key) ? undefined : value` for a Map, else `jsGet` | exact for a plain Map. For a `JsProxyObject` with a `null` result it gives `undefined`, where `jsGet` gives the `get` trap result | as C | as A | one function |
| C. `jsGetKey(Object? object, String key)`: B with the guard `object is! JsProxyObject` on the null path only | exact (`jsGet` result for each receiver) | fastest exact form: 10.31-11.47 ns (AOT), 15.47-17.74 ns (wasm) | as A | one function |
| D. A Map-first order inside `jsGet` | exact | as C for Map items, but +1.9 ns (AOT) and +1.0 ns (wasm) on resolvers, +4.8 ns (AOT) and +2.0 ns (wasm) on Lists and Strings (B4) | as A | no new name |
| E. `_parsedValue` (Dart `null` for an absent key) | wrong where the result reaches a scale or `===` (P1) | fastest: -0.70 ns (AOT), -1.99 ns (wasm) against C | as A | exists |

### Choice

C, with E kept for the tests that give the same result for `null` and `undefined` (question 2).

- Name: `jsGetKey`. File: `lib/src/js/js_object.dart`, next to `jsGet`. A pure layer. The `js`
  prefix follows the JS runtime of AGENTS.md (`jsGet`, `jsObjectKeys`, `jsCall`).
- Use: a receiver that is a Map in the usual case: a parsed item, a stack object (`_stacks`,
  `_visualValues`), a `_custom` object, a data item, a typed options object of
  `element_options.dart`. `jsGet` stays the read of a resolver, a List, a String and a class
  value (B4).
- D is rejected: it slows the option reads (B4).

### The hot readers of `core.datasetController.dart`

Each read that keeps `undefined` switches from `jsGet` to `jsGetKey`. The results do not change.
The figures are B1 and B3.

| Dart line (now) | Upstream | Read | New form |
|---|---|---|---|
| :349-350 `_updateStacks` | `core.datasetController.js:164` | `item[iAxis]`, `item[vAxis]` | `jsGetKey` |
| :351 `_updateStacks`, :428 `_clearStacks` | :165, :218 | `item._stacks` (truthiness) | `jsGetNullish` |
| :430-437 `_clearStacks` | :219-224 | `stacks[axis]`, `[datasetIndex]`, `_visualValues` | `jsGetKey` |
| :311 `_getLastIndexInStack` | :143 | `stack[meta.index]` | `jsGetKey` |
| :1047-1048 `parse` | :473 | `cur[iAxis]`, `prev[iAxis]` | `jsGetKey` |
| :1221-1224 `applyStack` | :596-599 | `parsed[scale.axis]`, `parsed._stacks[axis]._visualValues` | `jsGetKey` |
| :1240, :1245 `updateRangeFromParsed` | :608, :610 | `parsed[scale.axis]`, `parsed._stacks[scale.axis]` | `jsGetKey` |
| :1279 `getMinMax` (`skip`) | :635 | `parsed[otherScale.axis]`: keeps `undefined` (`jsToNumber(undefined)` is NaN, `jsToNumber(null)` is 0; P1 `getMinMax` rows) | `jsGetKey` |
| :1280 `getMinMax` (`skip`) | :636 | `parsed[scale.axis]` in `isFinite` | `jsGetNullish` |
| :1318 `getAllParsedValues` | :668 | `parsed[i][scale.axis]` in `isFinite` | `jsGetNullish` |
| :1346, :1349 `getLabelAndValue` | :693-694 | `parsed[axis]` | `jsGetKey` |

This covers `performance.md` §11.8 item 2. B3 shows no gain above the noise of the loop. The step 7
run of the frameless benchmark gives the figure of the update.

### Code form

```dart
// lib/src/js/js_object.dart

/// The property read `object[key]` for a String [key], with the result of
/// [jsGet]. The Map case comes first (Chart.js ADR 0027).
///
/// Use it where the receiver is a Map in the usual case: a parsed item
/// (`meta._parsed[i]`), a stack object, a data item, a typed options object.
/// [jsGet] stays the read of a resolver, a List, a String and a class value:
/// a Map-first order is slower for them.
///
/// A plain Map gives [undefined] for a key that it does not contain. A
/// [JsProxyObject] gives its `get` trap result, as [jsGet] does: its `has`
/// trap does not know the prefixed keys.
Object? jsGetKey(Object? object, String key) {
  // `<dynamic, dynamic>`: see jsGet.
  if (object is Map<dynamic, dynamic>) {
    final Object? value = object[key];
    return value == null &&
            object is! JsProxyObject &&
            !object.containsKey(key)
        ? undefined
        : value;
  }
  return jsGet(object, key);
}
```

## 5. Question 2: the private helpers of `core.datasetController.dart`

### The helpers and their readers

| Helper (now) | Semantics | Readers in phase 7 |
|---|---|---|
| `_item` (`core.datasetController.dart:511-516`); same body as `_item` of `core.controller.dart:2317-2322` | `array[index]` for a number index, `undefined` past the end | `labels[i]`, `data[i]`, `pixels[index]` (`controller.bar.js:79`, `:91-93`, `:162-164`, `:332`; `controller.bubble.js:61`, `:74`; `controller.doughnut.js:155-159`); `meta._parsed[index]` (`controller.polarArea.js:101`); `data[index]` of `_parseObjectDataRadialScale` (`helpers.config.ts:450`, Dart `helpers.config.dart:920`) |
| `_setAt` (`:547-553`) | `array[index] = value`, append at the length | `meta._parsed[i] = getter(i)` (`controller.doughnut.js:164`) |
| `_keyOr` (`:1188-1189`, a method) | the default of `const {xAxisKey = 'x'} = this._parsing` | `controller.bar.js:326`, `controller.doughnut.js:158` |
| `_parsedValue` (`:564-565`), with copies at `core.interaction.dart:148-149` and `helpers.extras.dart:303-304` | `item[key]`, Dart `null` for an absent key of a Map | the tests `isNullOrUndef`, `isFinite` and truthiness |

### Options

| Option | Behavior | Performance | Structure (Chart.js ADR 0012) | Code |
|---|---|---|---|---|
| A. Public with `@internal` in `core.datasetController.dart` (`item`, `setAt`, `parsedValue`) | same | same (B6) | ADR 0012 drops the `_` of an upstream member that another module reads. These helpers have no upstream name: they model JS operators | the copies in `core.controller`, `core.interaction` and `helpers.extras` stay |
| B. Shared functions of the JS runtime in `lib/src/js/` | same | same (B6) | the home of the JS semantics (AGENTS.md, "The JS runtime in `lib/src/js/`"); ADR 0008 later copies `lib/src/js/` into `js_semantics` | one copy of each; the private copies go |
| C. Local copies in each controller file | same | same (B6) | 8 files with port-only code | about 3 copies x 8 files |

### Choice

B. The names follow the `js` prefix and carry no `@internal`: `lib/src/js/` is not exported
(`lib/flutter_chartjs.dart` exports only `src/upstream.dart`).

- `jsArrayGet(List<Object?> array, double index)` in `js_array.dart`, from `_item`. It replaces
  `_item` of `core.datasetController.dart` and of `core.controller.dart`. `_item` of
  `helpers.core.dart:576` stays: it has an `int` index and another rule.
- `jsArraySet<T>(List<T> array, int index, T value)` in `js_array.dart`, from `_setAt`.
- `jsGetNullish(Object? object, String key)` in `js_object.dart`, from `_parsedValue`. It replaces
  the three copies. Its use is limited to a test that gives the same result for `null` and
  `undefined`. It is 0.70 ns (AOT) and 1.99 ns (wasm) faster than `jsGetKey` for each read (B1).
- `_keyOr`: no shared form. The destructuring default applies only to `undefined`, which is
  `valueOrDefault` (`helpers.core.dart:129`). A controller reads
  `valueOrDefault(jsGet(parsing, 'xAxisKey'), 'x')` and casts the key to `String` at the call of
  `resolveObjectKey` inside the loop. Then a key that is not a string throws a `TypeError` at the
  first item, as `resolveObjectKey` does upstream (`helpers.core.ts`, `_splitKey`), and a parse of
  0 items does not throw. The cost is one cast for each item. `_keyOr` of `core.datasetController`
  stays as it is.
- `_at`, `_getIndex` and `_indexKey` stay private: only `core.datasetController.dart` reads them.
  B7 shows that the cached `_indexKey` is slower on wasm. The bar write
  `parsed._stacks[axis]._visualValues[datasetIndex]` (`controller.bar.js:615`) uses
  `jsNumberToString(datasetIndex)`.
- `_parseObjectDataRadialScale` (`helpers.config.dart:920`) reads `jsArrayGet(data, index)` in
  place of `jsGet(data, jsNumberToString(index))`: -25 to -28 ns for each item (B5). The result is
  the same: `data` is a `List<Object?>`.

### Code form

```dart
// lib/src/js/js_array.dart

/// The JS read `array[index]` of an array for a number [index]: the item at
/// a whole index below the length, else [undefined]. `-0` names the item 0.
Object? jsArrayGet(List<Object?> array, double index) {
  if (index >= 0 && index < array.length) {
    final i = index.toInt();
    if (i == index) return array[i];
  }
  return undefined;
}

/// The JS write `array[index] = value`: a write at the length appends.
///
/// Upstream leaves a hole for an index after the length. Dart throws a
/// [RangeError] (differences.md row `platform-array-events`). A List of a
/// narrower item type throws a [TypeError] for another value
/// (differences.md row `js-semantics-resolver-objects`).
void jsArraySet<T>(List<T> array, int index, T value) {
  if (index == array.length) {
    array.add(value);
  } else {
    array[index] = value;
  }
}

// lib/src/js/js_object.dart

/// The read `object[key]` for a test that gives the same result for JS
/// `null` and `undefined`: `isNullOrUndef`, `isFinite`, [jsTruthy]. A Map
/// gives Dart `null` for a key that it does not contain. Another receiver
/// gives the [jsGet] result.
///
/// Do not pass the result to a scale member, to `===` or to `jsToNumber`:
/// use [jsGetKey] there (Chart.js ADR 0025 §8).
Object? jsGetNullish(Object? object, String key) =>
    object is Map<dynamic, dynamic> ? object[key] : jsGet(object, key);
```

## 6. Question 3: `parsing: false` with other data shapes

### Upstream form

- `core.datasetController.js:460-463`: `meta._parsed = data`, any item type (`unknown[]`,
  `index.d.ts:503`).
- `controller.doughnut.js:152-153`: `meta._parsed = data` with `data = this.getDataset().data`.
- The readers read properties of any item: `.r` (`controller.polarArea.js:101`, `:128`, `:182`,
  `:221`; `controller.radar.js:88`), `._custom` (`controller.bubble.js:103`, `:165`;
  `controller.bar.js:345`, `:368`, `:567`), `[axis]` (question 1), `+item`
  (`controller.doughnut.js:155`, `:253`), `item[2]` and `item.r` of a data item
  (`controller.bubble.js:62`, `:75`).

P1 shows: no shape of a List throws in a controller. A number, a string or an array gives
`undefined` for `.r`, `.x`, `.y` and `._custom`. A Map `data` (object data) throws a `TypeError` in
`_dataCheck` for the doughnut and the pie, before `parse`. The cartesian and radial charts convert
it (`convertObjectDataToArray`, `core.datasetController.js:374-376`).

### The Dart forms that throw today, and their fix

| Dart form | Throws for | Fix |
|---|---|---|
| a cast of a parsed item, for example `getParsed(i)! as Map<String, Object?>` | a number, string, array, `Map<String, double>` item | no cast. `jsGetKey(getParsed(i), 'r')` gives `undefined` for these items, as upstream. `jsGet` throws a `TypeError` for `null` and `undefined`, as upstream |
| `(item as List)[2]` (bubble array data) | an array of 2 items (`RangeError`), a non-array item | `jsGet(item, '2')`: `undefined` past the end. `jsGet`, not `jsGetKey`: the receiver is a List (B4) |
| `item['r']` on a cast item (bubble object data) | a non-Map item | the `&&` chain of `controller.bubble.js:75` with `jsTruthy` and `jsGet` (code below) |
| `meta.parsed = data` with a Map `data` | a Map | no fix needed: `_dataCheck` throws first, in upstream and in the port (`core.datasetController.dart:924-925` calls `_convertObjectDataToArray`, which reads `meta.iScale!`). For the cartesian and radial charts `_dataCheck` gives a List |
| `meta.parsed = data` with a `List<int>` | no throw at the assignment. A later `parse` with parsing on writes a `double` into the user List and throws a `TypeError` | the existing rule of narrow collections (row `js-semantics-resolver-objects`). Upstream writes into the user array too. No copy: a copy costs O(n) for each parse |

### Choice

No cast of a data item or a parsed item in a controller. The reads are `jsGetKey` (Map receiver in
the usual case), `jsGet` (List or unknown receiver), `jsArrayGet` (index read) and `jsToNumber`
(the unary `+`). Performance: each of these reads is the fastest exact form for its receiver (B1,
B4, B5). The assignment `meta.parsed = data` stays, with the `List<Object?>` type of
`types.ChartMeta.parsed`.

### Code form

```dart
// controller.doughnut.js:148-167 `parse(start, count)`.
@override
void parse(double start, double count) {
  final data = jsGet(getDataset(), 'data')! as List<Object?>; // a List after _dataCheck
  final meta = cachedMeta;
  if (parsing == false) {
    meta.parsed = data;
  } else {
    var getter = (double i) => jsToNumber(jsArrayGet(data, i));
    if (isObject(jsArrayGet(data, start))) {
      // `const {key = 'value'} = this._parsing`.
      final key = valueOrDefault(jsGet(parsing, 'key'), 'value');
      getter = (double i) =>
          jsToNumber(resolveObjectKey(jsArrayGet(data, i), key! as String));
    }
    for (var i = start, ilen = start + count; i < ilen; ++i) {
      jsArraySet<Object?>(meta.parsed, i.toInt(), getter(i));
    }
  }
}

// controller.bubble.js:75 `item && item.r && +item.r`: the first falsy
// operand, else the number.
final item = jsArrayGet(data, start + i);
final Object? r;
if (!jsTruthy(item)) {
  r = item;
} else {
  final value = jsGet(item, 'r');
  r = jsTruthy(value) ? jsToNumber(value) : value;
}
(parsed[i] as AnyObject)['_custom'] = valueOrDefault(
  r,
  jsGet(resolveDataElementOptions(i + start), 'radius'),
);

// controller.polarArea.js:128-130.
final parsed = jsGetKey(getParsed(index), 'r');
if (!jsIsNaN(parsed) && chart.getDataVisibility(index)) { ... }
```

## 7. Question 4: writes by name and raw option values

### Rules (Chart.js ADR 0010, ADR 0017 §8)

- A raw option value stays `Object?` until the upstream operator applies. The local or the record
  field has the type `Object?`.
- An arithmetic operator (`-`, `*`, `/`, unary `-`) and a relational operator (`<`, `>=`) apply
  `jsToNumber` to each raw operand. `Math.min` and `Math.max` are `jsMin` and `jsMax` after
  `jsToNumber`.
- `x || 0` directly before arithmetic is `jsOrZero(x)`. `x || 0` whose result is stored, returned
  or compared with `===` keeps the raw value: `jsTruthy(x) ? x : 0.0`.
- `a + b` on a raw value is `jsAdd`. `'' + v` is `jsToString`.
- `a === b` is Dart `==` for `double`, `String`, `bool` and the `undefined` sentinel (NaN is not
  equal to NaN in both; `0 == -0.0` is true in both). Two Maps or Lists compare by identity in
  both.
- A value that the upstream code reads once for several numeric uses can get its `jsToNumber`
  once, at the read, when each use applies `ToNumber`. This is the fast form, and it gives the same
  result.

### Points

| Point | Upstream | Behavior (P1) | Choice | Reason |
|---|---|---|---|---|
| `point.parsed = parsed` (`controller.line.js:106`, `controller.scatter.js:135`) | stores the item | a `null` item throws in `getMinMax` first (`core.datasetController.js:635`); a number item stores 5 | no change. `PointElement.parsed` takes an `Object`. `point.raw` goes to the extra properties | `null` cannot reach the setter |
| `properties.inflateAmount` (`controller.bar.js:252-256`) | stores the raw value | `bar.inflateAmount` keeps `'2'`, `null`, `true`; the draw uses its `ToNumber` (`element.bar.js:127-139`) | `BarElement` keeps the raw value: `Object?` field, `operator []=` takes any value, `draw` applies `jsToNumber` once (`element.bar.dart:529`). The test `inflateAmount != 0` of row `adapt-bar-clip` reads the number | Option (b), `jsToNumber` at the controller write, keeps a `double` field but changes the stored value and needs a `DIVERGES` row. The draw cost of (a) is one type test (`jsToNumber` of a `double`). Both are equal in performance. (a) keeps the upstream value |
| `base` (`controller.bar.js:564-565`, `:589-590`, `:603`, `:619-620`, `:178`) | raw in `getPixelForValue`, `===` and `>=` | `'2'` acts as 2; `'b'` is the category pixel; `true` is 1 | `baseValue` raw; `actualBase = jsTruthy(baseValue) ? baseValue : 0.0` (`Object?`); `value == actualBase`; `vScale.getPixelForValue(actualBase)` raw (Chart.js ADR 0025 §1); `barSign` reads `vScale.min >= jsToNumber(actualBase)` | the category scale reads a string label (P1) |
| `minBarLength` (`controller.bar.js:564`, `:601-602`) | `Math.abs(size) < minBarLength`, `* minBarLength` | `'3'` acts as 3 | `jsToNumber(jsGet(options, 'minBarLength'))` once in `_calculateBarValuePixels` | each use applies `ToNumber`; `undefined` gives NaN and `abs < NaN` is false |
| `barThickness` (`controller.bar.js:62-80`, `:543-555`, `:645`) | raw in `||`, `isNullOrUndef`, `*`, `=== 'flex'` | `'flex'` with `grouped: false` gives width NaN; `'12'` gives 12 | raw; the ruler field `min` is `Object?` (`barThickness \|\| computeMinSampleSize(meta)`); `jsToNumber(ruler.min)` at `*`; `== 'flex'` | the raw `'flex'` reaches `ruler.min * ruler.ratio` (`:656`) |
| `maxBarThickness` (`controller.bar.js:640`, `:652`, `:656`) | `valueOrDefault(x, Infinity)` in `Math.min` | `null` gives 0 (`Math.min(null, w)`) | `jsMin(jsToNumber(valueOrDefault(raw, double.infinity)), w)` | |
| `stack._top \|\| 0` (`controller.bar.js:220`, `:222`) | `=== index` | | `jsOrZero(stack['_top']) == index` | `_top` is a number or `null` (`core.datasetController.dart:365-366`) |
| `borderWidth \|\| 0` (`controller.line.js:128`, `controller.scatter.js:169`) | returned by `getMaxOverflow` when no point exists | | `jsTruthy(b) ? b : 0.0` (`Object?`) | the raw value reaches `_defaultClip` |
| `values.radius += x` (`controller.bubble.js:165`) | `+` on a raw option | | `values['radius'] = jsAdd(jsGet(values, 'radius'), x)` | |
| `start + length` (`controller.bar.js:593`) | `applyStack` can give a string (`core.datasetController.dart:180-221`) | | `jsAdd(start, length)` into `getPixelForValue(Object?)` | |

### Code form

```dart
// controller.bar.js:252-256 `setInflateAmount`.
void _setInflateAmount(AnyObject properties, AnyObject options, double ratio) {
  final inflateAmount = jsGetKey(options, 'inflateAmount');
  properties['inflateAmount'] =
      inflateAmount == 'auto' ? (ratio == 1 ? 0.33 : 0.0) : inflateAmount;
}

// element.bar.dart: the raw value, as element.bar.js:172 and :180.
Object? _inflateAmount; // Dart null: the undefined state
Object? get inflateAmount => _inflateAmount ?? undefined;
// operator []=: case 'inflateAmount': _inflateAmount = value;
// draw: final inflateAmount = jsToNumber(this.inflateAmount);

// controller.bar.js:563-603 (part).
final baseValue = jsGet(options, 'base');
final minBarLength = jsToNumber(jsGet(options, 'minBarLength'));
final Object? actualBase = jsTruthy(baseValue) ? baseValue : 0.0;
...
final startValue = !isNullOrUndef(baseValue) && !floating ? baseValue : start;
var base = vScale.getPixelForValue(startValue);
...
if (size.abs() < minBarLength) {
  size = _barSign(size, vScale, actualBase) * minBarLength;
  if (value == actualBase) base -= size / 2;
  ...
}
```

## 8. Question 5: the hot loops

### Policy

1. A form that keeps the upstream structure and gives the upstream result for each input is
   adopted in the port step when a micro benchmark on AOT and wasm shows a gain (porting-flow.md
   §1.1; Chart.js ADR 0020 §13 accepts a micro benchmark for such a form). The figures go to a new
   phase 7 section of `performance.md`.
2. A form that changes the upstream structure (a memo, a hoist out of a method, a new parameter, a
   cache across calls) is ported literally first. Step 7 measures it with the frameless benchmark
   (`apps/chartjs_gallery/lib/main_bench.dart`) on the Pixel 8a, with the ABBA protocol of the
   kickstart prompt. A kept form gets a `DIVERGES` marker, an `adapt` row and the figures before
   and after in `performance.md`.

### Adopted now (class 1)

| Form | Sites | Evidence |
|---|---|---|
| `jsGetKey` for the reads that keep `undefined` | question 1 | B1: -0.36 ns (AOT), -0.63 ns (wasm) for each read against `jsGet` |
| `jsGetNullish` for the null tests | question 2 | B1: -0.70 ns (AOT), -1.99 ns (wasm) against `jsGetKey` |
| `jsArrayGet` in place of `jsGet(data, jsNumberToString(i))` | `helpers.config.dart:920`, and each `data[i]` of the controllers | B5: -25 to -28 ns for each item |
| One read of each key of a parsed item for each loop pass | `controller.line.js:99-104`, `controller.scatter.js:128-133` | B2: 5 reads become 2; -22 to -25 ns (AOT) and -34 to -39 ns (wasm) for each point. 20000 points: about -0.5 ms (AOT) and -0.7 ms (wasm) for each update |
| `if (_hiddenIndices.isEmpty) return true;` in `getDataVisibility` | `core.controller.dart:1751`; called for each bar (`controller.bar.js:592`), twice for each doughnut arc (`controller.doughnut.js:250`, `:304`), up to 4 times for each polar arc (`controller.polarArea.js:130`, `:182`, `:221`, `:233`) | B7: -17 ns (AOT), -20 to -22 ns (wasm) for each call. The result is the same: an empty Map has no truthy value. This form is outside parsed data: the judge can move it to step 7 |

The rule of the one read:
- A loop pass reads each key of a parsed item once, into a `final` local, at the place of the
  first upstream read. A later upstream read of the same key uses the local.
- The rule holds only when no statement between the two reads writes that key of that item. In
  the line and scatter loops, no statement writes the item: the writes go to `properties` or to
  the point. `applyStack` reads only.
- The read of `prevParsed[iAxis]` uses the local of the previous pass. At the first pass with
  `start > 0`, it reads `getParsed(start - 1)` inside the `i > 0 &&` operand, so the read order and
  the throw of a `null` item stay as upstream.
- A read of the item through another method (`getParsed` in `_calculateBarValuePixels`,
  `controller.bar.js:566`) is not merged: that is a new parameter, a class 2 change.
- The reviewer of each unit checks each local against this rule.

```dart
// controller.line.js:89-119 (the reads only).
Object? prevParsed = start > 0 ? getParsed(start - 1) : false;
Object? prevIValue;
var hasPrev = false;
for (var i = 0; i < pointsCount; ++i) {
  ...
  final parsed = getParsed(i.toDouble());
  final vValue = jsGetKey(parsed, vAxis); // :99, also :101
  final nullData = isNullOrUndef(vValue);
  final iValue = jsGetKey(parsed, iAxis); // :100, also :104
  final iPixel = iScale.getPixelForValue(iValue, i.toDouble());
  final vPixel = reset || nullData
      ? vScale.getBasePixel()
      : vScale.getPixelForValue(
          jsTruthy(stacked) ? applyStack(vScale, parsed, stacked) : vValue,
          i.toDouble(),
        );
  final skip = iPixel.isNaN || vPixel.isNaN || nullData;
  final stop = i > 0 &&
      (jsToNumber(iValue) -
                  jsToNumber(hasPrev ? prevIValue : jsGetKey(prevParsed, iAxis)))
              .abs() >
          jsToNumber(maxGapLength);
  ...
  prevParsed = parsed;
  prevIValue = iValue;
  hasPrev = true;
}
```

### Ported literally, measured in step 7 (class 2)

| Form | Upstream | Prior evidence |
|---|---|---|
| A memo of `_getAxis()`, `getFirstScaleIdForIndexAxis()` and `_getStacks(last, undefined)` for one `updateElements` call | `controller.bar.js:434-508`, `:636-650`: each bar calls `_getAxisCount()` (`Object.keys`, a loop over the datasets), `_getAxis()` again, `getFirstScaleIdForIndexAxis()` twice and `_getStackIndex` (`getMatchingVisibleMetas` and a filter) | P2: -34 to -43 % of the bar `updateElements` time in V8. The memo reads the same values: the resolver caches `grouped`, and no statement of the loop changes the datasets, the scales or the visibility |
| An index of the parsed items by the index value for `skipNull` | `controller.bar.js:443-450`: `meta._parsed.find(...)` for each bar and each meta | P2: 19.4 ms for 3000 bars in V8; O(bars x datasets x points) |
| The copy of the shared options for each bubble item | `controller.bubble.js:46-78`, `:151-168`: `resolveDataElementOptions` for each item in each `parse*Data`, and `Object.assign` of a shared object | about 23.5 ns for each copy (Chart.js ADR 0021 §8) |
| One option resolution for each polar arc and radar point | `controller.polarArea.js:176`, `:201`, `:232-234`: `resolveDataElementOptions` twice for each arc, each a clone (no option sharing); `controller.radar.js:87` | not measured |
| The doughnut reads for each arc | `controller.doughnut.js:246-254`: `_getCircumference()` and `this.options` for each arc | not measured |
| Typed writes in the direct update | `controller.line.js:91-103`: `properties[iAxis] = ...` with `properties = point`, a write by name (`core.element.dart:330`) | not measured. `StressPointController` writes the typed setters (members-cartesian.md §6.4) |

## 9. Files that the implementation changes

- `lib/src/js/js_object.dart`: new `jsGetKey` and `jsGetNullish`. `jsGet` does not change.
- `lib/src/js/js_array.dart`: new `jsArrayGet` and `jsArraySet` (import `js_undefined.dart`).
- `lib/src/core/core.datasetController.dart`: remove `_item`, `_setAt` and `_parsedValue`; the
  reads of the table of question 1 switch to `jsGetKey` or `jsGetNullish`; `_getIndex` calls
  `jsArrayGet`.
- `lib/src/core/core.controller.dart`: `_item` (:2317) becomes `jsArrayGet`; the empty-Map line in
  `getDataVisibility` (:1751).
- `lib/src/core/core.interaction.dart` (:148) and `lib/src/helpers/helpers.extras.dart` (:303):
  `_parsedValue` becomes `jsGetNullish`.
- `lib/src/helpers/helpers.config.dart` (:920): `jsArrayGet(data, index)`.
- `lib/src/elements/element.bar.dart`: `inflateAmount` keeps the raw value (`Object?`), `draw`
  applies `jsToNumber` (:425-430, :470, :498-499, :529-545).
- `lib/src/controllers/*.dart` (new): the forms of questions 1 to 5.
- `doc/adr/0027-parsed-data-in-the-controllers.md` (new, proposed).
- `doc/performance.md`: a new phase 7 section with B1 to B7 and P2; §11.8 item 2 points to it.
- `doc/differences.md`: the row `adapt-bar-clip` reads "the `ToNumber` of `inflateAmount` is 0";
  the code columns of `js-semantics-resolver-objects` and `platform-array-events` name
  `jsGetKey` and `jsArraySet`. No new row.
- `AGENTS.md`: the list of the JS runtime gets `jsGetKey`, `jsGetNullish`, `jsArrayGet` and
  `jsArraySet`.

## 10. Tests that pin the decision

- `test/port/js/js_object_test.dart` (pure):
  - group `jsGetKey`: the result equals `jsGet` for each receiver of a matrix: a Map with a value,
    with a `null` value and without the key; a `Map<String, double>`; a resolver of
    `_createResolver` and a context proxy of `_attachContext` (an absent key, a prefixed key such
    as `_scopes`); a List (`'0'`, `'length'`, `'x'`); a String; a `JsClass`; a number; a bool.
    `null` and `undefined` throw a `TypeError`.
  - group `jsGetNullish`: Dart `null` for an absent key of a Map; the `jsGet` result for the other
    receivers.
- `test/port/js/js_array_test.dart` (pure): `jsArrayGet` for the indices 0, `-0.0`, 1.5, -1, NaN,
  the length and infinity; `jsArraySet` appends at the length, replaces below it, throws a
  `RangeError` past it, and throws a `TypeError` for a `double` into a `List<int>`.
- `test/port/core/core.controller_test.dart`: `getDataVisibility` with no hidden index, after one
  toggle (false) and after two toggles (true, the Map is not empty).
- `test/port/elements/element.bar_test.dart`, group `inflateAmount`: `bar['inflateAmount']` gives
  the raw value; the draw calls of `'2'`, `null` and `true` equal the draw calls of 2, 0 and 1;
  `'x'` gives NaN rectangles (relation tests, no generated values).
- The controller reference generators of phase 7 (`tool/reference/controller_*_reference.mjs`)
  get the configurations of P1 as cases: the absent and `null` keys on a logarithmic axis (line,
  scatter, bubble), the polar area and radar shapes, the bar draw with an absent `y`, the
  `getMinMax` rows with `x.min`, the `parsing: false` shapes of question 3, and the raw options of
  question 4. The values come from the x64 Node.js through the generators.
- `test/port/core/core.datasetController_chart_test.dart`: the doughnut and the pie with object
  data throw a `TypeError` (a relation test).
- The existing spec cases with `parsing: false` (`core.datasetController.tests.js:445`, `:510`,
  `:943`) and the radial parse cases keep their results.

## 11. Open for the judge

- B3 shows no gain of the `getMinMax` switch above the noise of the loop. The switch stays because
  it is not slower and it makes one rule for the reads. Step 7 gives the update figure.
- The `getDataVisibility` line is outside "parsed data". It is adopted here because the bar,
  doughnut and polar area loops call it for each element. A judge can move it to step 7.
- The one-read rule changes the count of the reads, not the order of the first reads or of the
  side effects. A fidelity draft can count the extra locals as a change of the structure. Then it
  needs a `DIVERGES` marker and an `adapt` row, with the figures of B2.
