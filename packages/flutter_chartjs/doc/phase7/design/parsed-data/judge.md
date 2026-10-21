# Judge: parsed data in the controllers

- Panel: "Parsed data in the controllers" (the future Chart.js ADR 0027, proposed). Phase 7,
  step 2 (Design).
- Inputs: [draft-fidelity.md](draft-fidelity.md) (F), [draft-performance.md](draft-performance.md)
  (P) and [draft-simplicity.md](draft-simplicity.md) (S).
- Pin: Chart.js `v4.5.1+7169e651` (`third_party/Chart.js` at `7169e65147a4`). "DC" is
  `lib/src/core/core.datasetController.dart`. "dc.js" is `src/core/core.datasetController.js`.
  `bar.js`, `line.js` and the other short names are files of `src/controllers/`.
- Judge evidence (below: `<j>`):
  `/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/parsed-data-judge/`.
  `<j>/bin/judge_bench.dart` is the benchmark, `<j>/run.sh` the runner, `<j>/diffs.py` the paired
  differences, `<j>/out/` the raw output and `<j>/summary.txt` the result.

## 1. Result

| Question | Winner | Take from the other drafts |
|---|---|---|
| 1. The parsed read | S | F and S: the form of `jsGetKey` (the proxy test in the Map test). |
| 2. The private helpers | F | P: the reader table of DC for the stack objects. |
| 3. `parsing: false` shapes | F | P and S: the probe rows of the radial charts and the bar draw test. |
| 4. Writes and raw options | F | S and P: the probe rows of `base` as pin tests. |
| 5. The hot loops | P | F: the three conditions of the policy, and probe P3 for step 7. |

Overall winner: **F (the fidelity draft)**. It wins three of five questions. It is the only draft
that finds a throw that upstream does not have (section 4, question 3). Its answers to questions 2
and 4 keep the upstream throw site and the `undefined` state. Its two losses are performance
losses. In question 1, its "no change" for the readers of DC rests on a wasm loss that the judge
run does not reproduce. In question 5, its rule "one Dart call for one upstream operation" rejects
a measured gain of 22 to 36 ns for each point.

ADR 0027 takes F as its base. It replaces the readers of DC (F §1.4) with the "T" form of S §2.
It replaces the policy condition 2 of F §5.1 with the one-read rule of P §8.

## 2. Judge benchmark

### 2.1 Why a new run

Two figures decide scores, and the drafts disagree on the first:
1. The `getMinMax` loop with `jsGetKey` for the two reads that keep `undefined` and `_parsedValue`
   for the `isFinite` read ("T" of S, "PK" of F). F measures a wasm loss of +0.50 to +9.20 ns for
   each item. S measures a wasm gain of -0.88 to -2.32 ns. P measures no difference above the
   noise.
2. The one-read rule of P (5 reads become 2 in `line.js:98-104`). P is the only draft that
   measures it.

The F bench (`parsed-data-fidelity/bench/bin/parsed_read_bench.dart`) runs Map items only, so each
type test sees one class. Its "PK" form uses the read without the proxy test. Its runs had a load
average of 10 to 26. The S bench warms up each loop with other receiver classes.

### 2.2 Method

- Bed: Apple M3 Max, macOS 26.5.1, Dart 3.12.2. AOT is `dart compile exe`. wasm is
  `dart compile wasm -O2`, run in the arm64 Node.js v24.12.0 (times only). The load average was 4
  to 6.
- The benchmark imports the real `jsGet`, `jsToNumber`, `jsMin`, `jsMax`, `isFinite`,
  `JsProxyObject` and `undefined` of `lib/src/` through the workspace package config.
- Data: 20000 items `<String, Object?>{'x': i, 'y': v}`, with `null` for 10 % of the `y` values.
- The line loop calls a virtual `getPixelForValue(Object? value, [double? index])` of two live
  scale classes.
- Two modes: "plain" (Map items only) and "mixed" (each loop first runs 200 times over a fake
  `JsProxyObject`, a `Map<String, double>`, a List and a number).
- 5 warm-up batches, then 21 rounds in a rotated order. A cell is the median of the rounds, in ns
  for each item. `run.sh` runs 6 rounds of 4 processes (AOT and wasm, plain and mixed) in an
  alternate order. The table gives the lowest and the highest paired difference of the 6
  processes, and the count below 0.
- A first series of the same benchmark (without the 3-read form) gave the same signs.

### 2.3 Forms

- `now`: the `getMinMax` reads of DC today (`jsGet`, `_parsedValue`, `jsGet`; DC:1279-1280, :1240).
- `T`: `jsGetKey`, `_parsedValue`, `jsGetKey` (S §2, P §4 with `jsGetNullish`).
- `K3`: `jsGetKey` for the three reads (F §1.4 "K").
- `5G`, `5X`, `5Y`: the five reads of `line.js:99-104` with `jsGet`, with `jsGetKey` of F and S
  (the proxy test in the Map test), and with `jsGetKey` of P (the proxy test on the `null` path).
- `3X`: one local for each key of the current item; the read `prevParsed[iAxis]` stays.
- `2X`: the form of P §8: also the previous `iAxis` value in a local.

### 2.4 Results (ns for each item)

| Difference | AOT plain | AOT mixed | wasm plain | wasm mixed |
|---|---|---|---|---|
| T - now | -1.76..-1.13 (6/6) | -2.09..-1.04 (6/6) | -1.75..-0.46 (6/6) | -2.89..-1.50 (6/6) |
| K3 - T | +0.61..+1.46 (0/6) | +0.75..+1.59 (0/6) | +0.37..+1.51 (0/6) | +0.97..+2.18 (0/6) |
| 5X - 5G | -3.39..-2.22 (6/6) | -2.63..-0.27 (6/6) | -5.20..-1.75 (6/6) | -3.20..-1.22 (6/6) |
| 5Y - 5X | -1.22..-0.08 (6/6) | -1.12..-0.03 (6/6) | -0.68..+4.47 (1/6) | +1.85..+3.30 (0/6) |
| 3X - 5X | -16.11..-14.97 (6/6) | -16.61..-15.97 (6/6) | -24.36..-23.05 (6/6) | -24.29..-23.07 (6/6) |
| 2X - 5X | -23.28..-22.42 (6/6) | -24.33..-23.28 (6/6) | -36.46..-33.11 (6/6) | -35.29..-33.20 (6/6) |
| 2X - 3X | -7.71..-7.17 (6/6) | -8.30..-7.31 (6/6) | -12.25..-9.94 (6/6) | -11.99..-9.91 (6/6) |

Findings:
- T is faster than the code of today in each of the 24 processes, on both platforms and in both
  modes. The wasm loss of F §1.4 does not occur. T is also faster than K3 in each process: the
  `isFinite` read keeps `_parsedValue`.
- `jsGetKey` (X) is faster than `jsGet` in each process. The guard placement of P (Y) gains up to
  1.2 ns on AOT and loses up to 4.5 ns on wasm. X wins.
- The 2-read form of P saves 22 to 24 ns (AOT) and 33 to 36 ns (wasm) for each point. P §3 B2
  gives -22 to -25 and -34 to -39. The figures agree. For 20000 points, this is about 0.47 ms
  (AOT) and 0.7 ms (wasm) for each update (a calculation from the figures, not a frame figure).

## 3. Scores per question

Each cell scores one criterion of the decision protocol: behavior (Chart.js ADR 0009), performance,
structure (AGENTS.md rule 2), less code. "+" is the best answer of the three, "=" is equal to the
best, "-" is worse. A "-" in behavior decides against the draft.

### Question 1: the parsed read

| Draft | Answer | Behavior | Performance | Structure | Code |
|---|---|---|---|---|---|
| F | `jsGetKey` (X) in `js_object.dart`. DC keeps its reads (`jsGet`, `_parsedValue`). | = | - (the T gain is lost; section 2.4) | = | = |
| P | `jsGetKey` (Y). DC switches to `jsGetKey` and `jsGetNullish` (a T form). | = | - (Y loses on wasm) | = | - (a new public function) |
| S | `jsGetKey` (X). DC switches its `jsGet` reads to `jsGetKey` and keeps `_parsedValue` (T). | = | + | = | + |

Winner: S. All three keep the `jsGet` result for each receiver, also for a resolver item. The guard
`is! JsProxyObject` gives the `get` trap where the form of Chart.js ADR 0025 §8 gives `undefined`
(`js_object.dart:42-43`, `js_array.dart:52`). This is compatible with Chart.js ADR 0025 (accepted):
§8 left the name and the file to phase 7 and asks for the `jsGet` result.

Checked claims:
- F §1.4 "wasm loses 0.5 to 4.5 ns": not reproduced (section 2.4). The cause is the bench: one
  item class, a read without the proxy test, a load average of 10 to 26.
- P §3 B3 "no gain above the noise": the judge run shows a gain of 0.5 to 2.9 ns for each item on
  both platforms.
- S §1.4 "T minus today: below 0 in each of the 12 processes": confirmed.
- P B4 (a Map-first `jsGet` is slower on resolvers and Lists): not re-run. All three drafts keep
  `jsGet` unchanged, so the figure does not decide a score.

### Question 2: the private helpers of DC

| Draft | Answer | Behavior | Performance | Structure | Code |
|---|---|---|---|---|---|
| F | `jsGetIndex(Object? object, double index)` in `js_object.dart` replaces `_item`, `_getIndex` and the `_item` of `core.controller.dart:2317`. `jsSetIndex` in `js_array.dart`. `_keyOr`: `valueOrDefault` at the site, cast at the `resolveObjectKey` call. `_parsedValue` copies stay. | + | = | = | + (one function for two helpers) |
| P | `jsArrayGet(List, double)`, `jsArraySet`, `jsGetNullish` (merges the three `_parsedValue` copies). `_keyOr` as F. | = | = | = | = |
| S | `jsGetIndex(List, double)`, `jsSetIndex` in `js_array.dart`. `_keyOr` inline with the cast at the default. `_parsedValue` copies stay. | - (throw site) | = | = | = |

Winner: F.
- The throw site of a bad parsing key: upstream throws in `resolveObjectKey` inside the loop
  (`bar.js:334-335`). For a bad `vAxisKey`, `iScale.parse` of the first item runs first, and a
  category scale adds a string label there. F casts at the call (`bar.js:334-335`), as
  `helpers.config.dart:914-922` does. S casts at the default, before the loop. S cites
  `helpers.config.dart:914-915` as its model, but that code casts at the call (:922). The
  difference is the state after the throw, so S gets "-".
- `jsGetIndex` with an `Object?` receiver: F measures no cost for the `List` test (5.50-5.75 ns
  against 5.61-5.84 ns, F §2.1). It removes `_getIndex` too.
- `jsGetNullish` (P): the same body as `_parsedValue`, so equal behavior and performance. It
  removes two 2-line copies. It also puts a read that gives Dart `null` for an absent key in the
  runtime list of the controllers. Probe P2 of S shows three controller sites where that read
  gives a wrong result (`polarArea.js:130`, `:221`; `line.js:100`; `bar.js:676`). The controllers
  do not need it. ADR 0027 keeps the private copies.
- All drafts drop `_indexKey` for the controllers. P B7 shows that the cached key is slower on
  wasm.

Note for the ADR: DC `parseObjectData` (DC:1169-1170, `_keyOr`) has the early cast of S today
(dc.js:561-571 casts in `resolveObjectKey`). ADR 0027 names it as a known residual. Its fix is a
one-line change of DC and the step 6 review decides it.

### Question 3: `parsing: false` and the data shapes

| Draft | Answer | Behavior | Performance | Structure | Code |
|---|---|---|---|---|---|
| F | No cast of an item. Doughnut cast stays (object data throws in `_dataCheck` first). An `Expando` for the `_stacks` of a List item (`stacksOf`, `@internal`), about 25 lines. | + | = (not measured; see below) | = | - |
| P | No cast. No change for List items. | - (keeps a throw) | = | = | + |
| S | No cast. No change for List items. | - (keeps a throw) | = | = | + |

Winner: F. Probes P1 and P4 of F show that upstream writes `_stacks` into an array item
(dc.js:165) and does not throw: a stacked line and a stacked bar with `parsing: false` and items
`[[0, 1], [1, 2]]`. DC:354 throws a `TypeError` for a List item. The row
`js-semantics-resolver-objects` covers a narrow Map item only (`differences.md:48`). A throw is a
protected behavior (Chart.js ADR 0009), so P and S get "-". F option A (extend the row, no code)
is the fallback when the maintainer rejects the 25 lines.

Unsupported claim: F says that "the normal data path has no new cost". Its `stacksOf` tests
`List` before the Map read, so a Map item pays one more type test at each read of `_stacks`
(DC:1224, :1245, `bar.js:405`, `:615`). ADR 0027 orders the Map case first. The implementation
step measures `updateRangeFromParsed` with and without `stacksOf` (AOT and wasm) before it lands.

All three agree on the other shapes. Object data with the doughnut throws in `_dataCheck`
(dc.js:103-104, DC:234), and `meta.parsed = data` keeps the identity of the user array (P1 of each
draft).

### Question 4: writes by name and raw option values

| Draft | `point.parsed = null` | `inflateAmount` | Raw options | Behavior | Performance | Structure | Code |
|---|---|---|---|---|---|---|---|
| F | cannot occur (throw at `line.js:99`); pin test | `jsToNumber` at the write, except a `num` and `undefined` | `Object?` until the operator; full table | + | = | + | = |
| P | as F | `BarElement.inflateAmount` becomes `Object?`; `jsToNumber` in `draw` | as F | + | = (not measured) | - (changes a phase 4 element) | - |
| S | as F | `jsToNumber` at the write for every value | as F | = (`undefined` becomes NaN) | = | + | + |

Winner: F.
- `point.parsed = null`: all three are right. `line.js:99` reads `parsed[vAxis]` before
  `line.js:106`, and dc.js:635 reads the item earlier in `getMinMax` (P P1).
- `inflateAmount`: the only reader is `draw` (`element.bar.js:180-196`), and `inflateRect`
  (`element.bar.js:127-139`) applies `ToNumber` through `-amount` and `amount - x`. Thus the
  conversion at the write gives the upstream draw. F passes a `num` and `undefined` unchanged, so
  the property keeps its `undefined` state (Chart.js ADR 0017 §4). S stores NaN for `undefined`.
  P keeps the raw value, but it changes a typed property of Chart.js ADR 0017 §3 (proposed) in a
  phase 4 element. A by-name read of `inflateAmount` is not a behavior that Chart.js ADR 0009
  protects.
- P says that the conversion at the write "needs a `DIVERGES` row". No evidence: Chart.js ADR 0017
  §3 and §5 type the property, and no spec or ported code reads it by name (F §4.2 grep). P also
  says that the two forms "are equal in performance" without a measurement.
- Raw options: the three tables agree. ADR 0027 takes the F table (`bar.js:66`, `:72`, `:178`,
  `:206-222`, `:544`, `:555`, `:565`, `:571-576`, `:589-593`, `:601-603`, `:619-620`, `:640-656`)
  and the `jsToNumber` of `minBarLength` once (F, P).

### Question 5: the hot loops

| Draft | Policy | Adopted now | Behavior | Performance | Structure | Code |
|---|---|---|---|---|---|---|
| F | Literal first. Adopt now only a form with one Dart call for each upstream operation and a gain on AOT and wasm. | `jsGetKey`, `jsGetIndex` | = | - (rejects the one-read gain) | + | = |
| P | Structure-keeping form with a micro-benchmark gain: now. Structure change: literal, step 7. | `jsGetKey`, `jsGetNullish`, `jsArrayGet`, the one-read rule (line, scatter), the `getDataVisibility` fast path | = | + | = | = |
| S | Literal first. Adopt now only the reads of questions 1 and 2. | `jsGetKey`, T, `jsGetIndex` | = | - | + | + |

Winner: P.
- The one-read rule keeps every upstream statement, call, loop and order of side effects. It
  stores the value of a read in a local. Chart.js ADR 0020 §13 accepts a micro-benchmark gain for
  such a form. The judge run confirms the gain on both platforms (section 2.4). By the decision
  protocol, performance comes before structure. Thus the stricter condition 2 of F §5.1 loses.
- P lists the conditions of the rule (P §8): a local only when no statement between the reads
  writes that key of that item; the first read at the place of the first upstream read; the
  `prevParsed` read at the first pass inside the `i > 0 &&` operand; no merge across methods. In
  `line.js:89-119` and `scatter.js:124-148`, no statement writes the parsed item: `applyStack`
  reads only (dc.js:593-605), and the writes go to the point or to `properties`.
- Fallback: when the maintainer reads the local `prevIValue` (carried across the passes) as a
  structure change, the 3-read form keeps `prevParsed[iAxis]`. It still saves 15 to 17 ns (AOT)
  and 23 to 24 ns (wasm) for each point (section 2.4).
- The `getDataVisibility` fast path (P B7, `core.controller.dart:1751`) is outside the questions of
  this panel. The judge did not re-run it. It goes to the step 7 list.
- The structure changes stay literal in all drafts: the bar memo of `_getAxis`,
  `getFirstScaleIdForIndexAxis` and `_getStacks` (`bar.js:434-508`, `:636-650`), the `skipNull`
  find (`bar.js:443-450`), the bubble option copy (`bubble.js:46-78`), the double resolution of
  polar area (`polarArea.js:176`, `:201`, `:232-234`) and radar (`radar.js:87`). Step 7 measures
  each with frame figures (Chart.js ADR 0020 §13). Evidence for step 7: P P2 (the memo removes 34
  to 43 % of the bar `updateElements` time in V8; 6 % with `skipNull`) and F P3 (the shares of
  `_calculateBarIndexPixels`, `_getStacks` and `_getAxis`).

## 4. Flags

Claims without evidence, or with evidence that the judge did not reproduce:
1. F §1.4: the wasm loss of the T form. Not reproduced (section 2.4).
2. F §3.3: "no new cost" of `stacksOf` for a Map item. Not measured (question 3).
3. P §7: the conversion at the write of `inflateAmount` "needs a `DIVERGES` row", and the two forms
   "are equal in performance". No evidence.
4. P §3 B3: "no gain above the noise" for the switch of `getMinMax`. The judge run shows a gain.
5. S §3: the `_keyOr` form cites `helpers.config.dart:914-915`, but that code casts at the call
   (:922), not at the default.

Answers that break a protected behavior or an existing ADR:
1. P and S, question 3: keep a `TypeError` at DC:354 where upstream writes `_stacks` into an array
   item (F P1, P4). A protected throw (Chart.js ADR 0009).
2. S, question 2: the early cast of a parsing key moves the throw before the `iScale.parse` of the
   first item (`bar.js:334-335`).
3. P, question 4: changes the typed property `inflateAmount` of Chart.js ADR 0017 §3 (proposed).
   This is not a break of an accepted ADR, but the panel has no mandate to change a phase 4 ADR.
4. No draft changes an accepted ADR. The guard `is! JsProxyObject` agrees with Chart.js ADR 0025
   §8 (accepted).

## 5. The decision for Chart.js ADR 0027

1. `jsGetKey(Object? object, String key)` in `lib/src/js/js_object.dart` (a pure layer), the form
   of F §1.3 and S §2: the Map read for a Map that is not a `JsProxyObject`, else `jsGet`. Each
   controller read `parsed[key]`, `item.r`, `parsed._custom` and `stack._top` uses it. A read of a
   resolver stays `jsGet` (Chart.js ADR 0017 §8).
2. DC: the `jsGet` reads of a parsed item or a stack object switch to `jsGetKey` (S §2 table, and
   P §4 rows DC:311 and :430-437). The `isFinite` and truthiness reads keep `_parsedValue`
   (DC:1280, :1318, :351, :428). Evidence: section 2.4, T.
3. `jsGetIndex(Object? object, double index)` in `js_object.dart` (F §2.1) replaces `_item` and
   `_getIndex` of DC and `_item` of `core.controller.dart:2317`. `helpers.config.dart:920` reads
   `jsGetIndex(data, index)`. `jsSetIndex<T>` in `js_array.dart` replaces `_setAt` (DC:547).
4. `_keyOr` stays private. A controller writes `valueOrDefault(jsGet(parsing, 'xAxisKey'), 'x')`
   and casts at the `resolveObjectKey` call (F §2.3). The three `_parsedValue` copies stay private.
   No controller calls `_parsedValue`.
5. No controller casts a data item or a parsed item. The doughnut keeps
   `jsGet(getDataset(), 'data')! as List<Object?>` (`doughnut.js:149`, `:153`).
6. The `_stacks` of a List item: F §3.3 option B, with the Map case first in `stacksOf`, and the
   measurement of question 3 before it lands. Fallback: option A.
7. `inflateAmount`: the conversion of F §4.2. Raw options: the table of F §4.3.
8. Hot loops: the policy of F §5.1 with condition 2 replaced by the one-read rule of P §8. Adopted
   now: `jsGetKey`, `jsGetIndex`, the T reads of DC, the one-read rule in `line.js:98-104` and
   `scatter.js:127-133`. Step 7: every form that changes the structure, and the `getDataVisibility`
   fast path.

Pin tests: F §7, with these cases of the other drafts:
- S P2: polar area `parsing: false`, `[{r: 1}, {}, {r: 3}]` against `[{r: 1}, {r: null}, {r: 3}]`
  (`countVisibleElements` 2 against 3); bar `{x: 'b'}` against `{x: 'b', y: null}` (the draw test
  of `bar.js:676`); bar `base: 5` against `base: '5'`, with and without `minBarLength: 20`.
- P P1: bar `base: 'b'` on a category axis (the label pixel); line `x.min: 1` with an item
  `{y: 50}` against `{x: null, y: 50}` (the y range of `getMinMax`).
- A test of the one-read rule: a line and a scatter with `segment`, `spanGaps` as a number and
  `start > 0` (the first `prevParsed` read) give the `stop` and `skip` values of the generator.

Records: `performance.md` gets a phase 7 section with section 2.4 of this file, F §2.1 (index
read) and the figures of question 3.
