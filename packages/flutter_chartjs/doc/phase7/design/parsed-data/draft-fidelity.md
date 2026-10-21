# Parsed data in the controllers: fidelity draft

- Panel: "Parsed data in the controllers" (the future Chart.js ADR 0027, proposed).
- Lens: fidelity first. The upstream behavior and the upstream structure get the most weight. This
  draft accepts a cost only when a measurement shows that the cost is small.
- Pin: Chart.js `v4.5.1+7169e651`. Each `controller.*.js` citation is
  `third_party/Chart.js/src/controllers/`. "DC" is
  `packages/flutter_chartjs/lib/src/core/core.datasetController.dart`. "dc.js" is
  `third_party/Chart.js/src/core/core.datasetController.js`.
- Scratch evidence: `/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/parsed-data-fidelity/`
  (below: `$EV`). `$EV/README.md` gives the commands.

## 0. Evidence

### 0.1 Upstream probes

The probes run in the x64 Node.js v24.12.0 under Rosetta, against the Chart.js build at the pin
(`env/chartjs-build/dist/chart.js`). They load the build with `loadChartJs` and make each chart with
`makeChart` of `tool/reference/scale_chart_common.mjs`. Thus each chart has the Liberation Sans
mock context, `animation: false` and a 512 x 512 canvas. They register the controllers, the scales
and the elements, and no plugin.

| Probe | Script | Output | Topic |
|---|---|---|---|
| P1 | `$EV/probe.mjs` | `$EV/probe.out` | data shapes with `parsing: false`, stacks of array items, `point.parsed`, raw bar options, parsing keys |
| P2 | `$EV/probe2.mjs` | `$EV/probe2.out` | the reach of `point.parsed = null`, `inflateAmount` against its `ToNumber`, `barThickness`, `maxBarThickness`, a string `base` |
| P3 | `$EV/probe3.mjs` | `$EV/probe3.out` | the share of the per-bar members in an upstream bar update |
| P4 | `$EV/probe4.mjs` | `$EV/probe4.out` | a stacked bar chart with `parsing: false` and array items |

### 0.2 Benchmarks

Bed: Apple M3 Max, macOS 26.5.1, Dart 3.12.2. AOT is `dart compile exe`. wasm is
`dart compile wasm -O2`, run in the arm64 Node.js v24.12.0 (times only). Each benchmark imports
the real `jsGet`, `jsToNumber`, `isFinite` and `undefined` of `lib/src/`. Each process makes 5
warm-up batches and then 25 batches of 10 passes over 20000 items, in an alternate order. A
process gives the median of its batches. `bench/run6.sh` runs 10 AOT and 10 wasm processes in an
alternate order. `bench/diffs.py` computes the difference of two forms inside each process. The
tables give the lowest and the highest difference of the 10 processes, in ns for each item.

Other sessions used the Mac during the runs (load average 10 to 26). The paired differences inside
one process remove most of that noise. Three series (`bench/run1`, `run2`, `run3`) give the same
signs.

## 1. The parsed read (Chart.js ADR 0025 §8)

### 1.1 The upstream form

Each controller reads a parsed item with the JS property read `parsed[key]`:
`controller.line.js:99-104`, `controller.scatter.js:128-133`, `controller.bubble.js:101-103`,
`:129-130`, `:152`, `:165`, `controller.bar.js:345`, `:367-374`, `:402-405`, `:441-445`, `:540`,
`:566-569`, `:615`, `:655`, `:676`, `controller.radar.js:45`, `:88`, `controller.polarArea.js:101`,
`:128`, `:182`, `:221`. A parsed item is any value (`index.d.ts:503`): a Map of `parse*Data`, a data
item with `parsing: false`, or a number of the doughnut (`controller.doughnut.js:153`, `:164`). An
absent key gives `undefined`. A `null` or `undefined` item throws a `TypeError`.

### 1.2 Options

| Form | Result | Line loop: 4 reads for each point (AOT / wasm) | Notes |
|---|---|---|---|
| U: `parsed[key]` | upstream | - | JavaScript |
| E1: `jsGet(parsed, key)` (Chart.js ADR 0006, ADR 0010) | the result of U for each value | G - P: +4.07..+7.16 / +3.15..+7.35 | The switch tests `null`, `Undefined` and `JsProxyObject` before the Map case. |
| E2: `_parsedValue` (DC:564) | Dart `null` for an absent key | reference (P) | Wrong for the controllers: ADR 0025 probe P2 case (h), a logarithmic axis with `parsing: false` and no `x`, gives NaN where upstream gives the min pixel. |
| F1: Map read with `undefined`, else `jsGet` (ADR 0025 §8) | the result of U, except for a resolver item (see F2) | K - P: +1.28..+2.54 / -0.75..+2.75; K - G: -5.02..-2.47 / -5.46..-2.42 | |
| F2: F1 with `is! JsProxyObject` before the Map read | the result of U for each value | X - P: +1.15..+2.57 / -0.85..+3.16 | X - K: no measured difference |
| F3: `jsGet` with the Map case first (a full copy) | the result of U | R2 - G: -3.49..-0.86 / -0.42..+1.76 | Slower than F1 on both platforms; on wasm not faster than E1 |

Source: `$EV/bench/bin/parsed_read_bench.dart`, series `run2` and `run3` (10 processes each). The
loop is `controller.line.js:98-104`: `isNullOrUndef(parsed[vAxis])`, `parsed[iAxis]`,
`parsed[vAxis]` and `prevParsed[iAxis]`, over 20000 Map items with 10 % `null` values. The absolute
medians are 40.8-42.0 ns (P), 42.2-44.1 ns (K) and 45.2-48.5 ns (G) on AOT, and 54.4-57.2 ns (P),
55.9-58.8 ns (K) and 59.8-62.9 ns (G) on wasm.

A `JsProxyObject` (a resolver of `helpers.config.dart`) implements `Map<String, Object?>`
(`lib/src/js/js_array.dart:52`). `jsGet` gives its get trap unchanged (`js_object.dart:42-43`). F1
also calls `containsKey`, the `has` trap, for a `null` result. F2 sends a resolver to `jsGet`, so F2
gives the result of `jsGet` for every value. The test costs no measured time.

### 1.3 Choice: F2, `jsGetKey` in `lib/src/js/js_object.dart`

- Behavior: F2 gives the result of `jsGet` for every receiver, also a resolver, a List, a number,
  and the `TypeError` of `null` and `undefined`. E2 fails ADR 0025 case (h).
- Performance: F2 is 0.6 to 1.3 ns faster than `jsGet` for each read on both platforms. It costs
  0.3 to 0.6 ns for each read more than `_parsedValue`.
- Structure: each upstream `parsed[key]` stays one call, `jsGetKey(parsed, key)`. The function is a
  JS runtime function, not a member of `DatasetController`. Upstream has no helper here: the JS
  engine does the read. Thus the file is `js_object.dart`, next to `jsGet`, a pure layer (root
  `lib/src/js/**` of `tool/src/lib_imports.dart:120`). ADR 0008 later copies `lib/src/js/` into
  `js_semantics`, and the function is generic.
- The name follows the `js` prefix of the runtime (AGENTS.md, "The JS runtime"). "Key" says that
  the key is a `String` (a property name), where `jsGet` takes any key.

```dart
/// `object[key]` for a property name [key]: the result of [jsGet].
///
/// The fast path reads a Map that is not a resolver: the value of [key], or
/// [undefined] for a key that the Map does not contain. Every other value
/// goes to [jsGet]: a resolver gives its get trap, a List or a String its
/// index or `length`, and `null` and [undefined] throw a [TypeError].
///
/// Use it for the property reads of parsed items, data items and stacks
/// (Chart.js ADR 0027). An absent key gives [undefined], not Dart `null`
/// (Chart.js ADR 0025, section 8).
Object? jsGetKey(Object? object, String key) {
  // `<dynamic, dynamic>`: see the comment of jsGet.
  if (object is Map<dynamic, dynamic> && object is! JsProxyObject) {
    final Object? value = object[key];
    return value == null && !object.containsKey(key) ? undefined : value;
  }
  return jsGet(object, key);
}
```

Rules for the controllers:

- Each `parsed[key]`, `parsed._custom`, `parsed._stacks`, `getParsed(i).r`, `item.r`,
  `custom.barStart`, `stack._top` and `_dataset._decimated` is `jsGetKey`.
- A read of the dataset resolver `this.options.x` stays `jsGet(options, 'x')` (Chart.js ADR 0017
  §8). `jsGetKey` gives the same result there, with two more type tests.
- A read with a number index is `jsGetIndex` (section 2.1).

### 1.4 `getMinMax` and the other hot readers of DC: no change now

`performance.md` §11.8 item 2 proposes the Map read for `getMinMax` (DC:1278-1283, `jsGet` at
DC:1279 and DC:1240). The benchmark loop is dc.js:633-643 with `updateRangeFromParsed` (dc.js:607-617),
unsorted, without a stack. Paired differences, ns for each item (3 reads):

| Form | AOT (run2 / run3) | wasm (run2 / run3) |
|---|---|---|
| now: `_parsedValue` for `isFinite`, `jsGet` for the other two reads | reference | reference |
| K: `jsGetKey` for the three reads | -1.52..-0.55 / -2.22..-1.41 | +2.54..+4.51 / +2.17..+3.39 |
| PK: `_parsedValue` for `isFinite`, `jsGetKey` for the other two | -2.32..-1.44 / -3.15..-2.12 | +0.50..+3.02 / +0.51..+9.20 |
| G3: `jsGet` for the three reads | +2.03..+2.74 (run3) | +2.32..+4.58 (run3) |

- AOT gains 0.6 to 3.2 ns for each item. wasm loses 0.5 to 4.5 ns for each item. In this loop on
  wasm, the `_parsedValue` read of the `isFinite` test is the fast part, and `jsGetKey` is not
  faster than `jsGet` (K - G3: -1.43..+1.07).
- All forms give the same range: `isFinite` gives the same result for `null` and `undefined`, the
  read of the other axis keeps `undefined` in each form, and `parsedValue === null ? NaN :
  parsedValue` gives NaN for both.
- Decision: DC keeps its reads (`_parsedValue`, `jsGet`) in this phase. No form gains on every
  platform, and a change of a shared layer needs a gain. Step 7 measures K and PK with the frame
  figures of the bar and line update on the Pixel 8a, macOS and Chrome (`performance.md` §11.8
  item 2). Each form keeps the upstream structure, so step 7 needs no `DIVERGES` marker.
- The same applies to `applyStack` (DC:1221-1224), `updateRangeFromParsed` (DC:1240, :1245),
  `_updateStacks` (DC:341-372) and `getAllParsedValues` (DC:1318).

## 2. The private helpers of DC that the controllers need

Chart.js ADR 0012 gives the names of upstream `_` exports and members. These helpers are
port-only: upstream has the JS operator, not a function. Thus ADR 0012 does not give their names.
The JS runtime gives the names (`js` prefix).

### 2.1 `_item` and `_getIndex`: `jsGetIndex` in `js_object.dart`

Upstream reads an array with a number index: `controller.bar.js:162` (`data[i]`), `:164`
(`labels[i]`), `controller.bubble.js:61`, `:74` (`data[start + i]`), `controller.doughnut.js:155`,
`:157`, `:159` (`data[i]`), `:250`, `:253`, `:324` (`meta._parsed[i]`), `controller.polarArea.js:101`,
`controller.line.js:107`, `controller.scatter.js:136` (`_dataset.data[i]`),
`helpers.config.ts:450` (`data[index]`), and `labels[index] || ''` (`controller.scatter.js:51`,
`controller.bubble.js:106`, `controller.doughnut.js:327`, `controller.polarArea.js:104`). DC has the
private `_item` (DC:511) and `_getIndex` (DC:521). `core.controller.dart:2317` has a copy of
`_item`.

| Form | AOT | wasm | Result |
|---|---|---|---|
| `_item` (DC:511) | 5.50-5.75 | 5.69-6.00 | `undefined` past the end, for a fraction, for a negative index and for NaN |
| `getIndex`: `_item` for a `List`, else `jsGet` | 5.61-5.84 | 5.70-6.01 | the same, and the `jsGet` result for any other receiver |
| `jsGet(data, i)` (`ToString` of the index) | 22.64-23.66 | 24.41-25.68 | the same |

Source: `$EV/bench/bin/index_read_bench.dart`, 6 processes. The loop is the doughnut parse
(`controller.doughnut.js:163-165`, `meta._parsed[i] = +data[i]`) over 20000 numbers, ns for each item.

Choice: one public function `jsGetIndex(Object? object, double index)` in `js_object.dart`, the body
of `_getIndex` and `_item`. The `List` test costs no measured time. `jsGet` with a number index
costs 17 to 19 ns more for each item. DC replaces `_item` and `_getIndex` with it.
`core.controller.dart` replaces its copy of `_item`. `helpers.config.dart:920` replaces
`jsGet(data, jsNumberToString(index))` with `jsGetIndex(data, index)` (the same result, about 18 ns
less for each item of a radar or polar area parse; Risk R4 of `members-radial.md`).

```dart
/// `object[index]` for a number [index]: for a List, the item at a whole
/// [index] below the length, else [undefined]; for another value, [jsGet].
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

### 2.2 `_setAt`: `jsSetIndex` in `lib/src/js/js_array.dart`

`controller.doughnut.js:164` writes `meta._parsed[i] = getter(i)`, as dc.js:475 does. DC has the
private `_setAt` (DC:547). Choice: the public `jsSetIndex<T>(List<T> list, int index, T value)` in
`js_array.dart`, the body of `_setAt`. DC uses it at DC:1052. The doc of `_setAt` (DC:540-546) moves
with it: a write at the length appends, and a write past the length throws a `RangeError` where
upstream leaves a hole (row `platform-array-events`). No benchmark: the body does not change.

### 2.3 `_keyOr`: the destructuring default at each site

`controller.bar.js:326` (`{xAxisKey = 'x', yAxisKey = 'y'} = this._parsing`),
`controller.doughnut.js:158` (`{key = 'value'}`) and `helpers.config.ts:444` (`{key = 'r'}`) use a
destructuring default. Its rule is the rule of `valueOrDefault` (`helpers.core.dart:129`): only
`undefined` gives the default.

| Option | Behavior | Code |
|---|---|---|
| A public `@internal` `keyOr` on `DatasetController` | upstream | a member that upstream does not have |
| A copy of `_keyOr` in each controller | upstream | one line in each file |
| `valueOrDefault(jsGet(parsing, 'xAxisKey'), 'x')` at the site | upstream | no new code |

Choice: `valueOrDefault` at the site. DC keeps its private `_keyOr` (DC:1188); the file has no
other reason to change it. The key is a `String` cast at the argument of `resolveObjectKey`. Thus
the throw comes at the same call as upstream, after the `iScale.parse` of the first item (bar:334
before :335). Probe P1: `parsing: {xAxisKey: null}` and `{xAxisKey: 5}` throw a `TypeError`
upstream (`Cannot read properties of null (reading 'split')`, `key.split is not a function`). Dart
throws a `TypeError` for `null as String` and `5 as String`. `parsing: true` and `{}` give the
defaults (`jsGet(true, 'xAxisKey')` is `undefined`).

```dart
// controller.bar.js:326-336
final parsing = this.parsing;
final xAxisKey = valueOrDefault(jsGet(parsing, 'xAxisKey'), 'x');
final yAxisKey = valueOrDefault(jsGet(parsing, 'yAxisKey'), 'y');
final iAxisKey = iScale.axis == 'x' ? xAxisKey : yAxisKey;
final vAxisKey = vScale.axis == 'x' ? xAxisKey : yAxisKey;
...
item[iScale.axis] = iScale.parse(resolveObjectKey(obj, iAxisKey! as String), i);
```

### 2.4 The three `_parsedValue` copies: no change

DC:564, `core.interaction.dart:148` and `helpers.extras.dart:303` give Dart `null` for an absent
key. Their readers test with `isFinite`, `isNullOrUndef` or `jsTruthy`. ADR 0025 §8 keeps them. The
measurement of section 1.4 shows that the `isFinite` read of `getMinMax` is the fastest part on
wasm. The controllers do not call them: each controller read is `jsGetKey`, also where the reader
does not tell `null` from `undefined` (`controller.line.js:99`, `controller.bar.js:403`). One form
for each upstream `parsed[key]` keeps the structure. It costs 0.3 to 0.6 ns for each read.

### 2.5 Other private names of DC

- `_indexKey` (DC:532) stays private. `controller.bar.js:615` writes
  `_visualValues[datasetIndex]` only in the `minBarLength` branch. The bar uses
  `jsNumberToString(datasetIndex)`, the key that `_indexKey` gives.
- `_getFirstScaleId` (DC:378) stays private. `getFirstScaleIdForIndexAxis` (`controller.bar.js:493`)
  is a public member of the bar with its own body, as upstream.

## 3. `parsing: false` and the data shapes

### 3.1 Probe P1, P4

| Case | Upstream |
|---|---|
| doughnut, object data `{a: 1, b: 2}`, parsing on and off | `TypeError: Cannot read properties of undefined (reading 'axis')`: dc.js:103-104 (`convertObjectDataToArray`) reads `meta.iScale.axis`, and the doughnut links no scale (`controller.doughnut.js:143`). The throw comes in `_dataCheck` (dc.js:365), before `parse`. |
| doughnut, `[1, '2', null]`, parsing off | `meta._parsed === dataset.data` (the same array). `total` 3. Circumferences 2.094, 4.189, 0. |
| doughnut, `[{value: 1}, {value: 2}]`, parsing off | `total` 0, circumferences 0 (`+item` is NaN). |
| polarArea, `[{r: 5}, {r: 3}]`, parsing off | outer radii 248, 148.8 |
| polarArea, `[5, 3]` or `[[5], [3]]`, parsing off | outer radii NaN (`(5).r` and `[5].r` are `undefined`) |
| polarArea, object data, parsing on and off | outer radii NaN (the items of `convertObjectDataToArray` have no key `r`) |
| radar, `[{r: 5}, ...]`, parsing off | points at their positions |
| radar, `[5, 3, 1]` or object data, parsing off | x and y NaN, `skip` true |
| bubble, `[{x, y, r}]`, parsing off | points drawn, radius 3 (the default: no `_custom`) |
| bubble, `[[x, y, r]]`, parsing off | x and y NaN, `skip` true, radius 3 |
| stacked line, `[[0, 1], [1, 2]]`, parsing off | no throw. dc.js:165 writes `_stacks` into each array item (`Object.keys` gives `0, 1, _stacks`). x NaN, `skip` true. |
| stacked line, `[1, 2]`, parsing off | `TypeError: Cannot create property '_stacks' on number '1'` |
| stacked bar, `[[0, 1], [1, 2]]`, parsing off (P4) | no throw. x and `height` NaN, `enableBorderRadius` false, `borderSkipped` `{bottom: true}`: `controller.bar.js:405` reads the `_stacks` of the array item. |

### 3.2 The Dart casts today

- The doughnut cast of `meta._parsed = data` (`controller.doughnut.js:153`, Risk R3 of
  `members-radial.md`) never sees a Map. Upstream throws in `_dataCheck` for object data. DC throws
  there too: `meta.iScale!` (DC:234) throws a `TypeError`. No change.
- polarArea, radar and bubble call the base `parse` (dc.js:460-463). `_data` is always a List after
  `_dataCheck` (DC:924-941). With `parsing: false`, `meta.parsed = data` takes the List. The items
  are `Object?`. `jsGetKey` reads a List, a number or a Map item with the upstream result. No cast.
- `_updateStacks` throws a `TypeError` for a List item (DC:354, `if (item is! Map) throw`).
  Upstream writes the property into the array (P1, P4). This is a throw that upstream does not
  have. The row `js-semantics-resolver-objects` covers a narrow Map item, not an array item.

### 3.3 Choice

1. The controllers add no cast of a data item, a parsed item or a data value. Each is `Object?`
   and each read is `jsGetKey` or `jsGetIndex`. A cast stays only where the upstream line throws a
   `TypeError` at the same value: `meta.parsed = jsGet(getDataset(), 'data')! as List<Object?>` at
   `controller.doughnut.js:153` (object data throws earlier, P1; a missing `data` is `[]` after
   `_dataCheck`, dc.js:367).
2. The doughnut assigns the same List, not a copy (P1: `meta._parsed === dataset.data`).
3. The `_stacks` of a List item. Options:
   - A: keep the throw, and extend the text of the row `js-semantics-resolver-objects` with array
     data items. No code.
   - B: a private `Expando<Object>` in DC for the `_stacks` of a List item. A port-only reader
     `stacksOf(Object? item)` gives the Map value, the Expando value for a List, else `jsGet`.
     DC writes through it at DC:354-356 and reads through it at DC:351, :428, :1224, :1245. The
     bar reads through it at `controller.bar.js:405` and `:615`, so it is a public top-level
     function of DC with `@internal`. About 25 lines.
   - B2: a general Expando of array own properties in the List branch of `jsGet`. Benchmark
     `$EV/bench/bin/array_props_bench.dart`: a named read of a List costs 6.7-7.3 ns now and
     22.6-34.0 ns with the Expando (no entry), 44-67 ns with an entry. Every named read of a List
     pays it, also the array scopes of the resolvers. Rejected: a cost on a shared path with no
     frame figures.

   Choice: B. It removes a throw that upstream does not have (Chart.js ADR 0009). A Map item takes
   the first branch, so the normal data path has no new cost. The chart of these configs draws no
   point (P1, P4: x NaN), but the element properties (`enableBorderRadius`, `borderSkipped`) and the
   absence of the throw equal upstream. The row `js-semantics-resolver-objects` loses the sentence
   about array items, and keeps the narrow Map item. If the judge weighs the 25 lines higher than
   a throw in a chart without points, A is the fallback.

```dart
/// The `_stacks` property of the parsed items that are Lists. A Dart List has
/// no named property. Upstream writes `item._stacks = {}` into the array
/// (core.datasetController.js:165).
final Expando<Object> _listStacks = Expando('_stacks');

/// The read `item._stacks` of a parsed item (core.datasetController.js:165,
/// :218, :599, :610; controller.bar.js:405, :615).
@internal
Object? stacksOf(Object? item) => switch (item) {
  final List<Object?> list => _listStacks[list] ?? undefined,
  _ => jsGetKey(item, '_stacks'),
};
```

The write at DC:353-356 becomes: a Map takes the key, a List takes the Expando entry, and every
other value throws the `TypeError` of a write into a primitive (P1: `Cannot create property
'_stacks' on number '1'`).

4. Residual, not changed: with `parsing: false`, `meta.parsed` is the user List. A typed user List,
   for example `List<double>`, takes no Map. If `parsing` then changes to true, DC:1052 writes Maps
   into it and throws a `TypeError`, where upstream writes the parsed objects into the user array.
   This is a case of the row `js-semantics-resolver-objects` (a narrow collection), and the row
   text names it.

## 4. Writes by name and raw option values

### 4.1 `point.parsed = null` (`controller.line.js:106`, `controller.scatter.js:135`)

`PointElement.operator []=` takes `parsed` through `toObjectProp<Object>` (`element.point.dart:311-312`),
which throws an `ArgumentError` for Dart `null`. Probe P1 and P2: a `null` item with `parsing:
false` never reaches line 106. Upstream throws `TypeError: Cannot read properties of null` at
`controller.line.js:99` (`parsed[vAxis]`): with a visible dataset, with a hidden dataset, and with
user `min` and `max` on both scales (then `getMinMax` does not run). The scatter case throws in the
same way. `jsGetKey(null, ...)` throws the same `TypeError` (through `jsGet`, `js_object.dart:39-41`).

- Choice: no change. `PointElement.parsed` keeps `toObjectProp<Object>`. A number or a boolean item
  reaches line 106 and is an `Object` (P1: `parsed` 1 and 2 for the items `[1, 2]`).
- Pin: a spec-free port test expects the `TypeError` of a `null` item, with and without `hidden`.

### 4.2 `inflateAmount` (`controller.bar.js:252-256`)

The option is `number | 'auto'` (`index.d.ts:2171`). A scriptable option can still return a string
(P2: the element stores `'2'`). `BarElement.operator []=` takes `inflateAmount` through
`toNumberProp` (`element.bar.dart:498-499`), which throws an `ArgumentError` for a `String`, a
`bool` or `null` (`core.element.dart:372-376`). Upstream stores the raw value. Its only reader is
`draw` (`element.bar.js:180-196`), and `inflateRect` (`element.bar.js:139-150`) applies only
`-amount` and `amount - x`, each a `ToNumber`.

Probe P2 compares the draw calls (`rect`, `clip`) of each raw value with those of its `ToNumber`:
`'2'` = 2, `null` = 0, `true` = 1, `false` = 0, `'abc'` = NaN, `''` = 0, `[3]` = 3. All equal.

| Option | Behavior | Structure | Code |
|---|---|---|---|
| Keep `toNumberProp` | throws an `ArgumentError` where upstream draws (Chart.js ADR 0017 §5 calls it outside the type contract) | literal | none |
| Widen `BarElement` to store `Object?`, `jsToNumber` in the getter | upstream, also the value of a read by name | a change of a phase 4 element and its typed getter | about 10 lines, a `jsToNumber` for each draw |
| `jsToNumber` at the write in the controller, except for a `num` and `undefined` | upstream draw calls; a read by name of `bar.inflateAmount` gives 2.0 for `'2'` | one expression at `controller.bar.js:253-255` | 3 lines |

Choice: the conversion at the write. It removes the throw. It gives the upstream draw calls for
every value (P2). The read by name is a typed property of Chart.js ADR 0017 §3, as for each other
numeric property of an element; no ported code and no spec reads it (`grep inflateAmount
test/specs src` gives only the element and the controller). `undefined` passes as it is, so the
property keeps its `undefined` state (Chart.js ADR 0017 §4).

```dart
// controller.bar.js:252-256 `setInflateAmount(properties, {inflateAmount}, ratio)`.
void _setInflateAmount(AnyObject properties, Object? options, double ratio) {
  final inflateAmount = jsGet(options, 'inflateAmount');
  properties['inflateAmount'] = inflateAmount == 'auto'
      ? (ratio == 1 ? 0.33 : 0.0)
      // The element takes a number (Chart.js ADR 0017, section 5). Its only
      // reader applies ToNumber (element.bar.js:139-150, :188-196).
      : inflateAmount is num || identical(inflateAmount, undefined)
      ? inflateAmount
      : jsToNumber(inflateAmount);
}
```

### 4.3 Raw option values in arithmetic and `===` (`controller.bar.js`)

Each raw value stays `Object?` until the upstream operator applies. The operator gives the runtime
form of Chart.js ADR 0010 and ADR 0017 §8. Probe P1 and P2 give the expected results.

| Upstream | Dart | Probe result to pin |
|---|---|---|
| `:565` `actualBase = baseValue \|\| 0` | `jsTruthy(baseValue) ? baseValue : 0.0` (an `Object?`: not `jsOrZero`, because `'0' \|\| 0` is `'0'`) | `base: '0'` with `minBarLength: 10` gives `y` 473.6, `base` 483.6, `height` 10; `base: 0` gives 483.1 and 9.5 (P2) |
| `:589` `!isNullOrUndef(baseValue) && !floating ? baseValue : start` | `Object? startValue` | `base: ''` draws as `base: 0`; `base: '5'` as `base: 5`; `base: 'abc'` gives NaN (P1) |
| `:590`, `:619` `getPixelForValue(startValue)`, `(actualBase)` | the `Object?` parameter of Chart.js ADR 0025 §1 | |
| `:571`, `:574-576` `length !== value`, `start = length - value` | `length != value`; `jsToNumber(length) - jsToNumber(value)` | Dart `!=` gives `!==` for these values: `double`, `String`, `null`, `undefined`; NaN differs from itself in both |
| `:593` `start + length` | `jsAdd(start, length)` | |
| `:601-602` `Math.abs(size) < minBarLength`, `* minBarLength` | `final minBarLength = jsToNumber(jsGet(options, 'minBarLength'))` once | `'10'` = 10; `null`, `'abc'` and `undefined` never apply (P1) |
| `:603` `value === actualBase` | `value == actualBase` | see `:565` |
| `:178` `vScale.min >= actualBase` | `vScale.min >= jsToNumber(actualBase)` | |
| `:620` `getLineWidthForValue(actualBase)` | `Object?` parameter (ADR 0025 §1) | |
| `:544` `min = barThickness \|\| computeMinSampleSize(meta)` | `Object? min = jsTruthy(barThickness) ? barThickness : computeMinSampleSize(meta)` | |
| `:66`, `:656` `ruler.min * ...` | `jsToNumber(ruler.min) * ...` | `barThickness: 'flex'` with `grouped: false` gives `width` NaN; `'20'` gives 20 (P2) |
| `:72` `thickness * stackCount` | `jsToNumber(thickness) * stackCount` | `'20'` = 20 (P1) |
| `:555` `barThickness ? 1 : opts.categoryPercentage * opts.barPercentage` | `jsTruthy`, `jsToNumber` of each factor | |
| `:640`, `:652` `valueOrDefault(maxBarThickness, Infinity)`, `Math.min(...)` | `jsMin(jsToNumber(valueOrDefault(...)), ...)` | `maxBarThickness: null` gives `width` 0; `'30'` gives 30 (P2) |
| `:645` `options.barThickness === 'flex'` | `jsGet(options, 'barThickness') == 'flex'` | |
| `:206`, `:211`, `:218` `!edge`, `edge === true`, `edge === 'middle'` | `!jsTruthy(edge)`, `edge == true`, `edge == 'middle'` | `borderSkipped` `true`, `'middle'`, `'start'`, `0` (P1) |
| `:220`, `:222` `(stack._top \|\| 0) === index` | `jsOrZero(jsGetKey(stack, '_top')) == index` (`_top` is a number or `null`, DC:361-362) | |

The ruler (`controller.bar.js:546-556`) is a private record of the bar with `Object? min`. No spec
reads `_getRuler` (`grep -rn _getRuler test/specs` gives nothing). Thus its other fields keep their
types: `List<double> pixels`, `double start`, `double end`, `double stackCount`, `Object? grouped`,
`double ratio`.

### 4.4 Other controllers

- `controller.line.js:104`, `controller.scatter.js:133`:
  `(jsToNumber(jsGetKey(parsed, iAxis)) - jsToNumber(jsGetKey(prevParsed, iAxis))).abs() > maxGapLength`.
  `prevParsed` can be `false` (`start > 0 && ...`); `jsGetKey(false, key)` gives `undefined`, as
  upstream.
- `controller.line.js:128`, `controller.scatter.js:169` `dataset.options && dataset.options.borderWidth || 0`:
  the raw value (`Object?`), and `jsMax` of the `ToNumber` values at `:135`. `getMaxOverflow`
  returns `Object?` (DC:1330).
- `controller.bubble.js:75` `item && item.r && +item.r`: the value of the `&&` chain, not a
  boolean: `!jsTruthy(item) ? item : !jsTruthy(r) ? r : jsToNumber(r)`. Then
  `valueOrDefault(...)`. A `null` item gives `_custom` `null`.
- `controller.bubble.js:165` `values.radius += valueOrDefault(parsed && parsed._custom, radius)`:
  `values['radius'] = jsAdd(values['radius'], ...)` (Chart.js ADR 0017 §8, `performance.md` §11.4).
- `controller.doughnut.js:155`, `:159` `+data[i]`, `+resolveObjectKey(...)`: `jsToNumber`.
- `controller.doughnut.js:250` `meta._parsed[i] === null`: `jsGetIndex(meta.parsed, i) == null`.
  The `undefined` sentinel is not `null`.
- `controller.polarArea.js:130-136`: `jsIsNaN(parsed)`, and the compare with `jsToNumber(parsed)`.

## 5. The hot loops: the policy

### 5.1 Policy

Port each hot loop literally first. Adopt a faster form in this phase only when all of these are
true:

1. It gives the upstream result for each value (a pin test shows it).
2. It keeps the upstream structure: one Dart call for one upstream operation, the same loops, the
   same calls of other members, the same order.
3. A micro-benchmark on AOT and on wasm shows a gain on both. A loss on one platform defers the
   form to step 7.

A form that changes the structure (a hoist out of the loop, a cache, a skipped call) waits for
step 7. It needs the frame figures of `performance.md` (Chart.js ADR 0020 §13, `porting-flow.md`
§1.1), a `DIVERGES` marker and an `adapt` row.

### 5.2 Forms adopted now

| Form | Evidence | Where |
|---|---|---|
| `jsGetKey` for each `parsed[key]` | -0.6 to -1.3 ns for each read against `jsGet`, AOT and wasm (section 1.2) | all controllers |
| `jsGetIndex` for each `array[i]` | -17 to -19 ns for each read against `jsGet` with a number key, AOT and wasm (section 2.1) | bar, bubble, doughnut, polarArea, line, scatter, `helpers.config.dart:920` |

### 5.3 Forms not adopted now (step 7)

- Bar `updateElements` (`controller.bar.js:401-424`). For each bar, `_calculateBarIndexPixels`
  calls `_getAxisCount` and `_getAxis` (a loop over the datasets, `Object.keys`) and
  `_getStackIndex`, which calls `_getStacks` (`getMatchingVisibleMetas` and a filter). With
  `skipNull`, `_getStacks` runs `meta._parsed.find` for each meta. Probe P3 measures the share of
  these members in an upstream update (shares only; the timing wrapper adds its own cost):

  | Case | `updateElements` | `_calculateBarIndexPixels` | of it `_getStacks` | of it `_getAxis` | `_calculateBarValuePixels` |
  |---|---|---|---|---|---|
  | 1000 bars, 1 dataset | 45.3 % | 21.6 % | 2.7 % | 8.5 % | 15.8 % |
  | 1000 bars, 3 datasets | 49.3 % | 26.0 % | 6.3 % | 9.7 % | 12.2 % |
  | 1000 bars, 3 datasets, `skipNull` | 79.5 % | 70.2 % | 61.3 % | 4.0 % | 6.0 % |
  | 5000 bars, 1 dataset | 32.0 % | 17.5 % | 3.9 % | 5.3 % | 8.7 % |

  These costs are upstream costs. A hoist of `_getAxis`, `getFirstScaleIdForIndexAxis` or
  `_getStacks` out of the loop changes the structure. Step 7 ranks the port overhead against these
  upstream shares (kickstart, Method step 7) and decides with frame figures.
- The `skipNull` find (`controller.bar.js:444`): `meta.parsed.firstWhere((item) =>
  jsGetKey(item, iScale.axis) == iScaleValue, orElse: () => undefined)`. Dart `==` gives `===` for
  the parsed values. Literal.
- `(parsed._stacks || {})[vScale.axis]` (`controller.bar.js:405`): a new empty Map for each bar
  without stacks, as upstream. A `const` empty Map is a step 7 candidate (no measurement now).
- Bubble `parse*Data` (`controller.bubble.js:46-78`) calls `resolveDataElementOptions` for each
  item, and the override copies the shared options (`copyOptions`, about 23.5 ns, Chart.js ADR 0021
  §8). Literal.
- polarArea and radar call `resolveDataElementOptions` for each arc or point
  (`controller.polarArea.js:201`, `:234`, `controller.radar.js:87`); doughnut reads
  `this.options.circumference` for each arc. Literal.
- Line and scatter `updateElements` (`controller.line.js:89-119`, `controller.scatter.js:124-148`):
  the direct update writes `properties[iAxis]`, `skip` and `stop` into the point by name
  (`point[iAxis] = iPixel` through `Element.operator []=`). The typed setters of the gallery
  `StressPointController` are faster, but a switch on `iAxis` is a port-only branch. Step 7
  measures it with the frame figures of the Core and Axes tabs.
- `getMinMax` and the other DC readers (section 1.4).

## 6. Files that the implementation changes

| File | Change |
|---|---|
| `lib/src/js/js_object.dart` | add `jsGetKey` and `jsGetIndex` |
| `lib/src/js/js_array.dart` | add `jsSetIndex` (the body of `_setAt`) |
| `lib/src/core/core.datasetController.dart` | `_item` and `_getIndex` become `jsGetIndex`; `_setAt` becomes `jsSetIndex`; the Expando of the `_stacks` of a List item and the `@internal` `stacksOf` (DC:351-356, :428, :1224, :1245); `_keyOr`, `_parsedValue`, `_indexKey` and the reads of `getMinMax` stay |
| `lib/src/core/core.controller.dart` | its private `_item` (:2317) becomes `jsGetIndex` (:1161, :1682, :1719) |
| `lib/src/helpers/helpers.config.dart` | `:920` reads `jsGetIndex(data, index)` |
| `lib/src/controllers/controller.*.dart` (8 files) | the reads and writes of sections 1.3, 2, 3.3, 4 |
| `doc/differences.md` | row `js-semantics-resolver-objects`: drop the array data item case (choice B), name the typed user List (section 3.3 item 4) |
| `doc/performance.md` | a section of phase 7 with the tables of sections 1.2, 1.4 and 2.1; §11.8 item 2 gets the result of section 1.4 |
| `doc/adr/0027-…md` (new, proposed) | the decision |
| `AGENTS.md` | the runtime list names `jsGetKey`, `jsGetIndex` and `jsSetIndex` |

No file of `lib/src/elements/` changes. `core.interaction.dart` and `helpers.extras.dart` keep their
`_parsedValue`.

## 7. Tests that pin the decision

- `test/port/js/js_object_test.dart`, group `jsGetKey`: for each receiver, `jsGetKey(o, k)` is
  identical to `jsGet(o, k)`: a Map with the key, without the key, with a `null` value; a narrow
  Map (`Map<String, double>`); a resolver of `_createResolver` with a key of value `null`, an
  absent key and a prefixed key; a List with `'0'`, `'length'` and `'r'`; a String; a number; a
  boolean; a `JsClass`. `null` and `undefined` throw a `TypeError` in both. Pure, runs in
  `test:web`.
- Same file, group `jsGetIndex`: a List with 0, 1, 1.5, -1, -0.0, NaN, the length and an index past
  it; a Map with the key `'1'`; a String; `null` throws a `TypeError`.
- `test/port/js/js_array_test.dart`, group `jsSetIndex`: a write at the length appends; a write
  below it replaces; a write past it throws a `RangeError`.
- `test/port/core/core.datasetController_test.dart`:
  - group `js-semantics-resolver-objects`: a stacked line and a stacked bar with `parsing: false`
    and List items: no throw, `stacksOf(item)` is the stack Map, and the values of P1 and P4
    (`x` NaN, `skip` true, `enableBorderRadius` false, `borderSkipped` `{bottom: true}`). Number
    items still throw a `TypeError`.
  - the existing `getMinMax` tests stay green without a change (section 1.4).
- A generator `tool/reference/controller_parsed_reference.mjs` writes
  `test/port/controllers/controller_parsed_reference.dart` from the cases of probes P1 and P2. The
  port tests of each controller (`test/port/controllers/controller.<name>_test.dart`, a group
  `parsed data`) build each chart with `acquireChart` and compare:
  - doughnut: object data throws a `TypeError`; `parsing: false` gives `identical(meta.parsed,
    dataset['data'])` and the circumferences of P1;
  - polarArea, radar, bubble: the rows of section 3.1;
  - line and scatter: a `null` item with `parsing: false` throws a `TypeError` (also `hidden`, and
    with user bounds); number items with `segment` give `parsed` 1 and 2;
  - ADR 0025 case (h): a scatter on a logarithmic x axis, `parsing: false`, an item without `x`:
    the point is at the min pixel and `skip` is false (the `undefined` of `jsGetKey`);
  - bar: `inflateAmount` `'2'`, `null`, `true`, `'abc'`: no throw, and the `rect` and `clip`
    calls of `draw` equal those of 2, 0, 1 and NaN; `base` `'0'` against 0 with `minBarLength`;
    `base` `''`, `'5'`, `'abc'`; `barThickness` `'20'`, `'flex'` with `grouped: false`;
    `maxBarThickness` `null` and `'30'`; `minBarLength` `'10'`; `parsing` `{xAxisKey: null}` and
    `{xAxisKey: 5}` throw a `TypeError`.
- A source test (or a review item of step 6): no file of `lib/src/controllers/` calls
  `_parsedValue`, and no controller casts a parsed item.

## 8. Open points for the judge

1. Section 3.3 choice B against A: 25 lines of DC and the bar against a throw in a chart that draws
   no point.
2. Section 4.2: the read by name of `bar.inflateAmount` gives a number where upstream gives the raw
   value. This draft treats it as the typed property of Chart.js ADR 0017 §3 and adds no row. A
   judge who reads it as a behavior difference adds the row `adapt-bar-inflate-amount-number`.
3. Section 1.4: the wasm loss of `jsGetKey` in the `getMinMax` loop is the opposite of its gain in
   the line loop. The cause is not known. Step 7 measures both forms in real charts.
4. All benchmark series ran while other sessions loaded the Mac. The paired differences have the
   same sign in each series, but the absolute times are not the times of an idle machine.
