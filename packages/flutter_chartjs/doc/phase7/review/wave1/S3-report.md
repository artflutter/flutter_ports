# S3 report: `stacksOf` and the List items (wave 1)

- Unit: S3 of `../../design/work-plan.md` §1. Spec: PD §4 and §7.2. Decision D5 of the phase
  lead: PD §4.1 lands in all cases. The fallback PD §4.4 is not used.
- Status: **done**. The measurement of PD §4.3 ran first. Then PD §4.1 landed.

## 1. Measurement (PD §4.3, ADR 0027 Open 1)

### 1.1 Bed

- Folder:
  `/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave1/S3/`
  (`bin/s3_bench.dart`, `run.sh`, `diffs.py`, `run_wasm.mjs`; results in `out1/`, `out2/`,
  `out3/`, `summary1.txt`, `summary2.txt`, `summary3.txt`).
- The method of the judge bed (`../../design/` judge benchmark, `parsed-data-judge/`): AOT
  (`dart compile exe`) and wasm (`dart compile wasm`, run in Node.js v24.12.0 arm64), plain and
  mixed modes, 6 rounds of 4 processes, alternate order, 21 samples of 10 passes for each case,
  the median for each process, paired differences for each process. The mixed mode first warms
  each loop with a List item (with an `Expando` entry), a `Map<String, double>`, a number and a
  proxy.
- Items: 20000 `Map<String, Object?>` items with `_stacks`. The loops copy the DC code of the
  working tree on 2026-10-21 (`_applyStack`, `_getOrCreateStack`, `_getLastIndexInStack`,
  `_indexKey`) and use the real runtime (`jsGetKey`, `jsGet`, `jsTruthy`, `jsToNumber`). The scale
  calls are virtual over two live classes.
- Cases (step 2 form against step 3 form):
  - `range`: `updateRangeFromParsed` with a stack. Step 2:
    `jsGetKey(jsGetKey(parsed, '_stacks'), axis)`. Step 3: `jsGetKey(stacksOf(parsed), axis)`.
  - `upd`: the body of `_updateStacks`, items with `_stacks`. Step 2: `_parsedValue` and the Map
    write. Step 3: `stacksOf` and the switch of PD §4.1.
  - `fresh`: the same body, but each item loses `_stacks` after its pass, so each pass writes it
    (not in the spec; added to measure the write path). `fresh step3b` is the switch written as an
    `if`/`else if` chain.
- Machine: Apple M3 Max, macOS 26.5.1, Dart 3.12.2. Other agents ran in parallel (load average
  4 to 7). The paired differences reduce this noise, but the update loops (200 to 450 ns for each
  item) have a spread of about ±15 ns.

### 1.2 Figures (ns for each item; paired difference step 3 minus step 2, minimum..maximum of 6 processes; count of processes above +0.5 ns)

Run 2 and run 3 have the same binary. Run 1 had no `step3b` case.

| Platform, mode | Case | Run 1 | Run 2 | Run 3 |
|---|---|---|---|---|
| AOT plain | range | -2.52..-0.93 (0/6) | -2.22..-0.50 (0/6) | -2.20..-0.32 (0/6) |
| AOT plain | upd | -13.59..-0.33 (0/6) | -9.78..-2.41 (0/6) | -9.94..-7.14 (0/6) |
| AOT plain | fresh | +6.43..+11.35 (6/6) | -4.32..+3.10 (2/6) | -4.47..+7.47 (5/6) |
| AOT mixed | range | -1.05..+0.12 (0/6) | -0.91..+1.03 (3/6) | -3.46..+1.89 (3/6) |
| AOT mixed | upd | -17.90..-7.15 (0/6) | -9.98..-5.61 (0/6) | -10.86..-5.72 (0/6) |
| AOT mixed | fresh | +1.13..+12.87 (6/6) | -13.47..+0.45 (0/6) | -4.12..+3.47 (3/6) |
| wasm plain | range | -1.38..+3.84 (4/6) | -0.90..+1.41 (4/6) | +0.24..+1.72 (3/6) |
| wasm plain | upd | -16.54..-0.35 (0/6) | -22.10..+3.26 (1/6) | -29.64..-11.85 (0/6) |
| wasm plain | fresh | -14.27..-0.10 (0/6) | -26.49..-1.70 (0/6) | -20.63..-2.24 (0/6) |
| wasm mixed | range | -0.63..+5.29 (3/6) | -0.05..+0.79 (1/6) | -0.75..+1.61 (2/6) |
| wasm mixed | upd | -17.54..+13.18 (2/6) | -16.35..+5.77 (2/6) | -15.75..+7.50 (4/6) |
| wasm mixed | fresh | -7.70..+5.69 (4/6) | -8.72..+5.61 (2/6) | -10.78..+11.75 (4/6) |

Medians of the cases (run 3, ns for each item): AOT `range` 52.8-55.2, `upd` 196-215, `fresh`
292-304; wasm `range` 72.9-76.7, `upd` 349-397, `fresh` 417-440.

The `if` chain against the switch (`fresh step3b - fresh step3`): AOT plain +2.86..+9.61 (6/6)
in run 2 and -1.07..+11.80 (5/6) in run 3. The switch of PD §4.1 is the faster form. It stays.

### 1.3 Result

- The two loops of the spec (`range`, `upd`): no platform and mode has a paired loss above 0.5 ns
  in each of the 6 processes, in each of the 3 runs. The threshold of PD §4.3 is not crossed.
  `upd` is faster with `stacksOf` on AOT in each process (-0.3 to -17.9 ns). `range` is equal
  within the noise (AOT -3.5 to +1.9 ns, wasm -1.4 to +5.3 ns).
- The write path (`fresh`, not in the spec): run 1 had a loss on AOT in 6 of 6 processes in both
  modes (+1.1 to +12.9 ns). Run 2 and run 3, with a binary that has one more function, did not
  repeat it (0/6 to 5/6). This is a code layout effect within the noise of a 300 ns loop, not a
  stable loss. The write runs once for each item at the first parse only.
- Decision D5 applies: PD §4.1 landed. No report to the maintainer is necessary for the
  threshold. The phase lead can give the `fresh` row of run 1 to the maintainer if necessary.

## 2. Files that S3 changed

- `packages/flutter_chartjs/lib/src/core/core.datasetController.dart`:
  - new `_listStacks` (`Expando<Object>('_stacks')`) and `@internal stacksOf(Object? item)` after
    `_parsedValue`, with the code of PD §4.1;
  - `_updateStacks`: reads `stacksOf(item)`; the write is the switch of PD §4.1 (Map, List,
    else `TypeError`); the doc of the function names the List case;
  - `_clearStacks`: reads `stacksOf(parsed)` (DC:428 of the spec);
  - `applyStack` and `updateRangeFromParsed`: the step 3 column of PD §3.1
    (`jsGetKey(stacksOf(parsed), scale.axis)`).
  - The marker `// DIVERGES(chartjs): js-semantics-resolver-objects, a narrow Map throws.` stays.
    It is on the line above `switch (item)`, not in the Map case: at the indentation of the case,
    the line is 81 characters (`lines_longer_than_80_chars`), and `check:headers` requires the
    marker on one line.
- `packages/flutter_chartjs/test/port/core/core.datasetController_test.dart` (group
  `js-semantics-resolver-objects`).
- `packages/flutter_chartjs/test/port/core/core.datasetController_chart_test.dart` (new group
  `js-semantics-resolver-objects`).

No other file changed. `_parsedValue` stays for the `isFinite` reads (DC `getMinMax`).

## 3. Tests that S3 added

`test/port/core/core.datasetController_test.dart`, group `js-semantics-resolver-objects` (VM,
the fake chart `_Run`):
- `stacksOf reads the _stacks of a Map, a number and null`: the Map value; Dart `null` for an
  absent key; `undefined` for 5.0 (equal to `jsGet`) and `true`; a `TypeError` for `null` and
  `undefined`.
- `stacksOf gives the entry that updateStacks writes for a List`: `parsing: false`, items
  `[[0, 1], [1, 2]]`: null before the update; after it, a Map with the keys `['y']`, the same
  object at each read; both items share the stack of the index key `'undefined'` (an array has no
  property x); the stack keys `0`, `_top`, `_bottom`, `_visualValues`; another List with the same
  contents gives null.
- `a stack change moves a List item to the new stack`: after a change of the dataset `stack`, the
  item keeps its `_stacks` object, its `y` stack is the stack of the new key, and the old stack
  keeps the key `0`, because its value is `undefined` (dc.js:220 skips it).
- `a primitive data item throws a TypeError`: items `[1.0, 2.0]`.

`test/port/core/core.datasetController_chart_test.dart`, group `js-semantics-resolver-objects`
(`testWidgets`, `acquireChart`; the test controller `stacksPoint` with point data elements is
registered in each test and unregistered with `addTearDown`):
- `List data items take the stacks`: `parsing: false`, `scales.y.stacked: true`, items
  `[[0, 1], [1, 2]]`: no throw; `meta.parsed` is the user List; `stacksOf(item)` is a Map with the
  keys `['y']`, also after `chart.update()`.
- `number data items throw a TypeError`: `[1.0, 2.0]`.
- `a data item of a narrow Map type throws a TypeError`: `Map<String, double>` items (the row).

## 4. Checks

| Command (from `packages/flutter_chartjs`) | Result |
|---|---|
| `dart format` on the 3 files | 0 changed |
| `dart analyze --fatal-infos` on the 3 files | No issues found |
| `flutter test test/port/core/core.datasetController_test.dart test/port/core/core.datasetController_chart_test.dart` | 78 passed |
| `flutter test test/specs/core.datasetController_test.dart test/port/core/ test/port/scales/` | 2216 passed, 101 skipped |
| `flutter test test/specs/scale.{linear,logarithmic,category,time,radialLinear}_test.dart` | 22 passed, 211 skipped |
| `dart run tool/check_port_headers.dart` | passed, 334 files |
| `dart run tool/check_js_semantics.dart` | passed, 116 files |
| `dart run tool/check_lib_imports.dart` | passed, 297 files |

The full gate did not run: the prompt of this unit allows only targeted tests, because U0 and
U-bar run in parallel. W1-int runs it. No `flutter_tester` process of S3 is left. One
`flutter_tester` of another session (scratchpad `ec6419b7-...`) runs; S3 did not stop it.

## 5. Doc notes for W1-int

### 5.1 `AGENTS.md`

`core.datasetController.dart` item: add "`stacksOf` (`@internal`) reads `item._stacks` of a
parsed item, also of a List item, through an `Expando` (Chart.js ADR 0027)."

### 5.2 `doc/porting-flow.md`

No note from S3 (PD §8.2 is for the ADR 0027 section and §1.1).

### 5.3 `doc/performance.md` §13.1

Add the `stacksOf` figures: "`stacksOf` (Chart.js ADR 0027 Open 1, S3). Bed: the judge method,
20000 Map items with `_stacks`, AOT and wasm, plain and mixed, 3 runs of 6 rounds of 4
processes. `updateRangeFromParsed` with a stack: step 3 minus step 2 is AOT -3.5 to +1.9 ns and
wasm -1.4 to +5.3 ns for each item (52.8-55.2 ns and 72.9-76.7 ns for each item); no
platform has a loss above 0.5 ns in each process. The body of `_updateStacks`: AOT -0.3 to
-17.9 ns in each process (196-224 ns for each item), wasm -29.6 to +13.2 ns (341-397 ns). The
write path (each pass writes `_stacks`): one run of three had an AOT loss of +1.1 to +12.9 ns in
each process, the two other runs did not repeat it (a code layout effect). The `switch` of the
write is faster than an `if` chain on AOT (+2.9 to +11.8 ns for the chain). The threshold of
0.5 ns for each item is not crossed; `stacksOf` landed (decision D5)." Use the table of §1.2 of
this report if the section has tables.

### 5.4 `doc/differences.md`

Row `js-semantics-resolver-objects`, after "The stacks stay in the user item ...": "A List data
item takes `_stacks` through `stacksOf` (an `Expando`). A primitive data item throws a
`TypeError`, as upstream." The code column adds `lib/src/core/core.datasetController.dart`
`stacksOf`. The other texts of PD §8.4 (the typed user List, `jsSetIndex`) come from S1 and S2.

### 5.5 `doc/status.yaml`

`core.datasetController`: "The reads of parsed items and stack objects use `jsGetKey`;
`stacksOf` reads the `_stacks` of a List item (Chart.js ADR 0027)." Then run
`dart run melos run parity`.

## 6. Open items

1. The full gate (work-plan §1 row S3) is for W1-int.
2. U-bar reads `bar.js:405` and `:615` through `stacksOf` (PD §5.1). The function is public
   with `@internal`; U-bar imports it from DC.
3. The line and bar pin rows of PD §7.3 (`stacked: true`, `parsing: false`, List items: point
   `x` NaN and `skip` true; bar `enableBorderRadius` false and `borderSkipped`
   `{'bottom': true}`) belong to the controller units, not to S3.
4. The `fresh` row of run 1 (§1.3): a decision for the phase lead only if the maintainer wants
   the write path measured again, for example on the Pixel 8a in step 7.

## Fixes

The fixer of S3 applied the findings of `S3-review.md`. All four findings were "confirmed". The
fixes change only the files of the S3 row. Probes:
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave1/S3-fix/`
(`stacks_items.mjs`: the probe of the review with class, `Date` and boolean items added; `ws/`: a
copy of the two packages for the mutations, `ws/dc.fix` is the fixed DC file).

### S3-R1: a `DateTime` or a `JsClass` data item threw at the write of `_stacks`

- Fix: option 1 of the review. The write throws only for a JS primitive. DC
  `_updateStacks`: the `switch` has the cases Map (unchanged), List, `JsClass` (an own static
  property, `value['_stacks'] = {}`), primitive (`throw TypeError()`) and each other value (the
  Expando). The new private `_isPrimitive` is true for Dart `null`, `undefined`, `num`,
  `String`, `bool` and a record (a record is not a JS value, and an `Expando` cannot take it).
  `stacksOf`: Map, then List (Expando), then `JsClass` or primitive (`jsGet`, so a class value
  reads through its superclass chain), then the Expando for each other value. The Expando
  `_listStacks` is now `_objectStacks`, because it also holds the `_stacks` of a `DateTime` or
  a function. The docs of `_updateStacks`, `stacksOf` and the Expando tell the new cases.
- Upstream (x64 Node.js v24.12.0, pinned build, `stacks_items.mjs`): `[new Date(0), new
  Date(1)]`, `[function a() {}, function b() {}]` and class items do not throw, and
  `Object.keys(item._stacks)` is `['y']`. With `class A { static x = 0; static y = 1; }` and
  `class B extends A {}`, A gets an own `_stacks`, B has no own `_stacks` and reads the object of
  A, and the stack keys are `['0']` with `A._stacks.y[0] === 1`. `[1, 2]`, `['a', 'b']` and
  `[true, false]` throw `TypeError: Cannot create property '_stacks' on number '1'` (on string
  `'a'`, on boolean `'true'`).
- The port now gives the same results (tests below).
- Why option 1 and not option 2: option 1 removes a throw that upstream does not have (Chart.js
  ADR 0009; the reason of decision D5), and it changes only DC. Option 2 needs a change of
  `differences.md`, which is not a file of S3.
- For the phase lead: Chart.js ADR 0027, section 3 item 3, says "each other value throws the
  `TypeError` of a write into a primitive", and its code block names `_listStacks`. The fixed
  code differs from this text: a `DateTime`, a function or a class value takes `_stacks`. The ADR
  is proposed and is not a file of S3. A correction of the ADR text (or a new ADR) is a decision
  of the maintainer.
- Performance: the Map and List cases stay first in the `switch` and in `stacksOf`. The bed of
  section 1 (Map items) does not reach the new cases. No new measurement.
- Corrected doc notes for W1-int (they replace the texts of sections 5.4 and 5.5 where they
  differ):
  - 5.4 `differences.md`, row `js-semantics-resolver-objects`: "A List, a `DateTime` or a
    function data item takes `_stacks` through `stacksOf` (an `Expando`). A class value takes it
    as an own static property. A primitive data item throws a `TypeError`, as upstream."
  - 5.5 `status.yaml`, `core.datasetController`: "`stacksOf` reads the `_stacks` of a List or
    another object without a property Map (Chart.js ADR 0027)."

### S3-R2: the "primitive throws" tests did not pin the throw at the write

- Fix: `core.datasetController_test.dart`, the test `a primitive data item throws at the write
  of _stacks` (it replaces `a primitive data item throws a TypeError`) runs number, string and
  boolean items. `core.datasetController_chart_test.dart`, the test `number and string data
  items throw at the write` (it replaces `number data items throw a TypeError`) runs number and
  string items. Both expect `throwsA(predicate((e) => e.runtimeType == TypeError))`: the plain
  `TypeError` of the write, not the Dart `_TypeError` of the later cast.
- Mutation M1 (in `ws/`): the primitive case is `break;` in place of `throw TypeError();`. Both
  tests fail.

### S3-R3: no test pinned the `stacksOf` readers of `applyStack` and `updateRangeFromParsed`

- Fix: `core.datasetController_test.dart`, the test `applyStack and updateRangeFromParsed read
  the List stacks`. After the stacked update of `[[0, 1], [1, 2]]`, `applyStack(y, items[0])`
  gives `undefined`. `updateRangeFromParsed(range, y, items[0], DatasetStack([0], null))` gives
  the range `NaN`/`NaN` without a throw, and the stack values are the stack `y` of the item.
  These are the results of the Node.js probe. The test `DateTime and function data items take
  the stacks` also calls `applyStack` (`undefined`, as upstream for a `Date`).
- The test file has a new private `_MinMax` (a plain `{min, max}`) and imports `MinMax` of
  `helpers.math.dart`.
- Mutation M2 (in `ws/`): DC:1208 and DC:1229 go back to `jsGetKey(parsed, '_stacks')`. Two
  tests fail (`applyStack and updateRangeFromParsed read the List stacks` and `DateTime and
  function data items take the stacks`).
- `_clearStacks` (DC:436): no test, as the review tells: for a List item, the value of the
  dataset in the stack is always `undefined`, and dc.js:219-220 skips the item. Thus no test can
  show a difference for a List item.

### S3-R4: the citation of the stack change

- Fix: the comment of the test `a stack change moves a List item to the new stack` cites
  `core.datasetController.js:416-419` for the call and `:208-227` for `clearStacks`.
- Also: the comment at the start of the group `js-semantics-resolver-objects` of
  `core.datasetController_chart_test.dart` keeps the citation `core.datasetController.js:165`
  on one line (the note of the review).

### New tests for S3-R1

- `core.datasetController_test.dart`: `DateTime and function data items take the stacks` (two
  `DateTime` items and two Dart closures: `stacksOf` gives a Map with the key `y`, the same
  object at each read; an equal `DateTime` has no entry), and `a class value takes the stacks as
  a static property` (A with the statics `x: 0`, `y: 1` and B with the superclass A: A has an own
  `_stacks`, `stacksOf(b)` gives the object of A, the stack keys are `['0']`, the value is 1).
- `core.datasetController_chart_test.dart`: `DateTime data items take the stacks` (through
  `acquireChart`, the chart path of the review probe `PROBE`).
- Mutation M3 (in `ws/`): each other value throws again (the S3 form). The three `DateTime`
  tests fail. Mutation M4: a class value goes to the Expando. The class test fails.

### Checks

- `dart analyze` on DC and the two test files: no issues. `dart format --set-exit-if-changed`
  on `test/port/core/` and DC: 0 changed.
- `flutter test test/port/core/core.datasetController_test.dart`: 68 passed.
  `test/port/core/core.datasetController_chart_test.dart`: 14 passed.
  `test/specs/core.datasetController_test.dart`: 43 skipped, 0 failed.
- `check:headers`: passed, 335 files. `check:js-semantics`: passed, 116 files.
- Mutations M1-M4 in the scratch copy: each mutation fails the tests named above. The copy of DC
  is equal to the repository file after the mutations (`cmp`).
- No `flutter_tester` process of this unit is left.
- The full gate stays with W1-int (section 6 item 1).
