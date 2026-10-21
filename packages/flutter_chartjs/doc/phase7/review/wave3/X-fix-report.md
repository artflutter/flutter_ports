# Wave 3, unit X-fix: report

## Status

Done. The unit did the three items of decision D11. Each item has a probe on the pinned build, a
fix in the port and pin tests. Item (c) is a fix with a key parameter, thus it needs no
`DIVERGES` marker and no `differences.md` row. The unit made no commit and ran no git command
that changes the index or the tree. It changed no file of U-scatter, U-pie or L2, and no shared
doc.

All paths are relative to `packages/flutter_chartjs/`, except where a path starts with `apps/`
(relative to the repository root). `<scratch>` is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad`.

## Files

The unit changed only these files. No other unit of wave 3 has them in its row.

| File | Item | Change |
|---|---|---|
| `lib/src/types/index.dart` | a, c | `RadialLinearScale.xCenter` and `yCenter` are `double?` (Dart `null` is JS `undefined`). `Chart.toggleDataVisibility` takes `Object? index`. |
| `lib/src/scales/scale.radialLinear.dart` | a | The fields `xCenter` and `yCenter` are `double?` with the start value `null`. The six reads in arithmetic and canvas calls use `?? double.nan`. |
| `lib/src/controllers/controller.radar.dart` | a | The reset writes `x ?? undefined` and `y ?? undefined`. `skip` is `x == null \|\| x.isNaN \|\| y == null \|\| y.isNaN` (`isNaN(undefined)` is true). |
| `lib/src/controllers/controller.polarArea.dart` | a, c | `x` and `y` are `centerX ?? undefined` and `centerY ?? undefined`. `_onClick` gives the raw index. `_legendIndex` is removed. |
| `lib/src/js/js_array.dart` | b | New class `JsStringList`: a string as an array-like value (reads of the UTF-16 code units, a `TypeError` for each write). |
| `lib/src/core/core.datasetController.dart` | b | `_dataCheck` keeps a string `data` as a `JsStringList` with no listener, and compares two strings by value. |
| `lib/src/controllers/controller.doughnut.dart` | b, c | `parse` reads a string `data`; with `parsing: false` the parsed items are its `JsStringList`. `_onClick` gives the raw index. `_legendIndex` is removed. |
| `lib/src/core/core.controller.dart` | c | `toggleDataVisibility(Object? index)` writes the key `jsToString(index)`. |
| `apps/chartjs_gallery/lib/demo/demo_chart.dart` | c | `DemoChart.toggleDataVisibility(Object? index)` (the gallery implements `types.Chart`). |
| `test/port/controllers/controller.radar_test.dart` | a | 1 pin test (group `the reset on a new radial scale`). |
| `test/port/controllers/controller.polarArea_test.dart` | a, c | 2 pin tests: the reset on a new scale, and `'01'` then `unshift`. |
| `test/port/controllers/controller.doughnut_test.dart` | b, c | 2 string-data tests (group `parsed data`), 24 key-move tests (group `interfaces`). |
| `test/port/controllers/controller.line_test.dart` | b | 1 string-data test (group `parsed data`). |
| `test/port/core/core.datasetController_test.dart` | b | 2 tests (new group `string data`). |
| `test/port/core/core.controller_test.dart` | c | 1 test (group `getDataVisibility`). |
| `test/port/scales/scale.radialLinear_test.dart` | a | The start values of `xCenter` and `yCenter` are `isNull` (were `isNaN`). |
| `test/port/js/js_array_test.dart` | b | 2 tests (new group `JsStringList`). |
| `doc/phase7/review/wave3/X-fix-report.md` | | New. This report. |

## Probes

- `<scratch>/wave3/X-fix/probe.mjs`, output `<scratch>/wave3/X-fix/probe.out`. It runs with
  `/usr/bin/arch -x86_64 <scratch>/env/node-v24.12.0-darwin-x64/bin/node <scratch>/wave3/X-fix/probe.mjs <scratch>/env/chartjs-build/dist/chart.js`
  from `packages/flutter_chartjs`. `loadChartJs` of `tool/reference/controller_chart_common.mjs`
  stops unless Node.js is x64 and the build is at the pin. The output starts with
  `arch x64 version 4.5.1`.
- `<scratch>/wave3/X-fix/strict.mjs`: the reads and the writes of a string in strict mode code
  (for `JsStringList`).
- `<scratch>/wave3/X-fix/before_fix.out`: the new pin tests on the port before the fix (15
  fail, see below). `<scratch>/wave3/X-fix/after_fix.out` and `after_fix_others.out`: the runs
  after the fix.

## Item (a): the reset position on a new radial scale

**Upstream.** `scale.radialLinear.js:416-418` sets `xCenter` and `yCenter` to `undefined`.
An existing radar or polar area controller gets a new scale (`rAxisID: 'r2'`) and a new item in
one `chart.update()`. `_insertElements` resets the new element before the first layout of the new
scale. The probe (`a radar`, `a polarArea`, a `beforeLayout` plugin and a stopped animator):

| Type | Before the layout | Animation `x` | Animation `y` |
|---|---|---|---|
| radar | `x` and `y` `undefined`, `skip` true | 25 to 25 | 256 to 256 |
| polarArea | `x` and `y` `undefined` | 256 to 256 | 256 to 256 |

`core.animation.js:32` skips the `undefined` current value, thus `from` is `to`.

**Port before the fix.** `xCenter` started at NaN. The element stored NaN, and the animation of
`x` started at NaN (the U-radar review F2). The pin tests failed at
`identical(beforeLayout['x'], undefined)` (`Actual: <false>`).

**Fix.** `types.RadialLinearScale.xCenter` and `yCenter` are `double?`, as `types.ChartMeta.total`
(Dart `null` is `undefined`). The concrete fields start at `null`. The scale reads
`xCenter ?? double.nan` in arithmetic and canvas calls: `undefined` gives NaN there, as before.
The radar and polar area controllers write `undefined` for `null`. `drawingArea` keeps NaN for
`undefined`: no reader writes it into an element.

**Tests.** `the reset on a new radial scale` in the radar and the polar area test files: the
`beforeLayout` read gives `undefined` (and `skip` true for radar), the animations have the upstream
`from` and `to`, and after 1100 ms the element is at the upstream position.

## Item (b): a string `data`

**Upstream.** `_dataCheck` (`core.datasetController.js:365-392`) keeps a string: `isObject` is
false, and `Object.isExtensible` is false (`:386`), so it gets no listener. `parse` reads
`data[i]` and `data.length`. `_data !== data` compares two strings by value. The probe:

| Case | Upstream |
|---|---|
| doughnut `'abc'` | 3 arcs, parsed NaN, `total` 0, circumferences 0 |
| doughnut `'123'`, `parsing: false` | `_parsed === data`, `total` 6, circumferences π/3, 2π/3, π, `getContext(1).raw` `'2'` |
| line `'123'` | parsed `{x: 0..2, y: 1..3}`, `y` min 1 and max 3, `raw` of index 2 `'3'`, label and value of index 1 `'b'` and `'2'` |
| line and bar `'123'` | the same element properties as `[1, 2, 3]` (`equal: true`) |
| line: an equal string, then `'4321'`, then an array | the same `_parsed` and elements; 4 elements; the array gets the listener |
| line `'12'`, `parsing: false` | 2 elements, `_parsed === data` |
| strict mode writes `s[0] = 'x'`, `s[5] = 'x'`, `s.length = 1`, `push` | `TypeError` for each |

**Port before the fix.** `_dataCheck` cast `data` to `List<Object?>` and the doughnut `parse`
cast `dataset.data`: `type 'String' is not a subtype of type 'List<Object?>' in type cast`.

**Fix.** `JsStringList` (`lib/src/js/js_array.dart`) is a `ListBase<Object?>` over the string:
item `i` is `string[i]` (one UTF-16 code unit), `length` is the count of code units, and each
write throws a `TypeError`. `_dataCheck` makes it for a string `data`, adds no listener, and
compares `oldData.string != data` when `_data` is a `JsStringList`. The doughnut `parse` reads the
raw `dataset.data` with `jsGetIndex` (which reads a String) and, with `parsing: false`, sets
`meta.parsed` to the `JsStringList`. The other readers of `dataset.data`
(`getContext`, `controller.line.dart:270`, `controller.scatter.dart:309`) use `jsGetIndex` or
`jsGet` and read a String already.

The existing tests of `_dataCheck` stay green: the `upstream scenarios`, the group
`platform-array-events` and the other groups of `test/port/core/core.datasetController_test.dart`,
and `test/specs/core.datasetController_test.dart`.

Limits (no reader sees them, no row): `isArray` of a `JsStringList` is true and `typeof` is
`'object'`, where upstream has a string; with `parsing: false`, `meta.parsed` is not the
`dataset.data` object (upstream `_parsed === data`). No ported reader makes these checks on
`_data` or on the parsed List.

**Tests.** `string data` of `core.datasetController_test.dart` (2), the doughnut tests
`the string data 'abc' ...` and `the string data '123' with parsing false ...`, the line test
`the string data '123' gives the points of [1, 2, 3]`, and `JsStringList` of
`js_array_test.dart` (2, pure: VM, dart2js and dart2wasm).

## Item (c): the legend `onClick` key after an insert or a remove

**Upstream.** `toggleDataVisibility(index)` writes `_hiddenIndices[index]` with the key
`ToString(index)` (`core.controller.js:881-883`). `moveNumericKeys` (`:72-84`) moves each key whose
`+key` is a number at or after the start. The probe: a doughnut with `[1, 2, 3, 4]`, `onClick` with
the item index, then the change and `chart.update()` (the visibility of each data index):

| Index | `unshift(9)` | `shift()` | `push(9)` |
|---|---|---|---|
| `'01'`, `' 1'`, `'1.0'` | 11011 | 011 | 11111 |
| `''` | 10111 | 111 | 11111 |
| `null`, `true` | 11111 | 111 | 11111 |
| `1`, `'1'` | 11011 | 011 | 10111 |

Polar area, `'01'` then `unshift`: 1101, outer radii 248, 27.555556, 0, 82.666667. A line chart
with `toggleDataVisibility` of `'01'`, `null`, `true` and `''`: 1111; after `unshift` 10011
(keys `1`, `2`, `null`, `true`); after `shift` 0011.

**Port before the fix.** `_legendIndex` gave NaN for a key that is not the text of a number, thus
the key `'NaN'`, which `moveNumericKeys` does not move. 7 of the 24 key-move tests and the polar
area test failed (for example `Expected: 11011`, `Actual: 11111`).

**Fix (a key parameter).** `types.Chart.toggleDataVisibility` takes `Object? index`, the form of
Chart.js ADR 0025 §1 for a raw JS value. `Chart.toggleDataVisibility` writes the key
`jsToString(index)`, the upstream `ToString`. The doughnut and polar area `_onClick` pass
`jsGet(legendItem, 'index')`, the upstream line. `_legendIndex` is removed from both files. The
interface rules of Chart.js ADR 0028 §1 stay: the member stays on `types.Chart` with its first
reader, no controller imports a concrete module or casts the chart, and the implementer
`DemoChart` of the gallery gets the new signature. A call with a number gives the key of
`jsNumberToString`, as before. `getDataVisibility(double index)` does not change. Thus no marker
and no `differences.md` row.

**Tests.** The 24 key-move tests of `controller.doughnut_test.dart`, the polar area test
`onClick with the index '01', then unshift, hides the data index 2`, and the
`core.controller_test.dart` test
`toggleDataVisibility takes the key ToString(index), and an insert or a remove moves the numeric keys`.
The existing key tables (17 doughnut and 16 polar area index values) stay green.

## Checks

All commands ran from the repository root, or from `packages/flutter_chartjs` for `flutter test`,
`dart analyze` and `dart test`.

| Command | Result |
|---|---|
| `flutter test` of the 5 changed controller and DC test files, before the fix | 15 of the new tests fail, as expected (`<scratch>/wave3/X-fix/before_fix.out`) |
| `flutter test test/port/controllers/controller.{radar,polarArea,doughnut,line,bar,bubble}_test.dart test/port/core/core.{datasetController,controller}_test.dart test/port/scales/scale.radialLinear_test.dart test/port/js/js_array_test.dart test/port/types/index_test.dart test/port/index_test.dart test/specs/controller.{doughnut,polarArea,radar,line,bubble}_test.dart test/specs/core.datasetController_test.dart test/port/theme` | +901 ~51, all passed |
| `flutter test test/specs/scale.radialLinear_test.dart test/specs/core.controller_test.dart test/specs/controller.bar_test.dart test/specs/controller.polarArea_test.dart test/port/controllers/controller.pie_test.dart` (read only; L2 and U-pie files) | +150 ~47, all passed |
| `dart test -p chrome -c dart2js -c dart2wasm test/port/js/js_array_test.dart test/specs/core.controller_test.dart` | +82, all passed |
| `dart test test/port/js/js_array_test.dart` | +41, all passed |
| `dart analyze --fatal-infos lib test tool` (flutter_chartjs) | No issues |
| `dart analyze --fatal-infos` in `packages/chartjs_test_utils` | No issues |
| `dart analyze --fatal-infos` in `apps/chartjs_gallery` | No issues |
| `dart format --output=none --set-exit-if-changed` on the 17 changed Dart files | 0 changed |
| `dart run melos run check:lib-imports` | passed, 329 files |
| `dart run melos run check:js-semantics` | passed, 131 files |
| `dart run melos run check:headers` | passed, 366 files |

The unit did not run the full gate, `test:cases`, `parity:check` or `lift_check.py` (W3-int runs
them). No generated reference data changed, so no generator ran. The unit left no
`flutter_tester` process. One `flutter_tester` process of another session (scratchpad
`ec6419b7-...`) ran during the work; the unit did not stop it.

## Doc notes for W3-int

**AGENTS.md** (Layout, `lib/src/controllers/`, the bullet of `controller.doughnut.dart`): replace
"`_onClick` gives the index of the legend item to `toggleDataVisibility` through `_legendIndex`:
a number for the text of a number, else NaN." with "`_onClick` gives the raw index of the legend
item to `toggleDataVisibility`. `Chart.toggleDataVisibility` takes any JS value (`Object?`) and
writes the key `ToString(index)`, as upstream."

**AGENTS.md** (Porting rules, the JS runtime list): add "`JsStringList` of `js_array.dart` is a
string as an array-like value: the reads `s[i]` and `s.length`, and a `TypeError` for each write.
`_dataCheck` keeps a string `data` in it, with no listener."

**AGENTS.md** (Layout, `lib/src/scales/`): add "`RadialLinearScale.xCenter` and `yCenter` are
`double?`: Dart `null` is the `undefined` before the first layout. The radar and polar area
controllers write it into a new element as `undefined`."

**porting-flow.md** (the rules of the JS values): "A numeric field whose `undefined` start value
a reader writes into an element or another observed object is `double?`, with Dart `null` for
`undefined`. NaN for `undefined` is correct only when each reader uses the value in arithmetic.
Example: `RadialLinearScale.xCenter` (D11 item a)."

**performance.md**: no new figures. Each form is the only form with the upstream behavior. The
changes add a null check in `getPointPosition` and in the polar area `updateElements`, and
`jsToString` in place of `jsNumberToString` in `toggleDataVisibility` (not a hot path).

**differences.md**: no new row, no removed row. Optional: the row `platform-array-events` can add
"A string `data` gets no listener, as upstream (`core.datasetController.js:386`)."

**status.yaml**:
- `src/controllers/controller.doughnut.js`: replace "`parse` keeps the one cast of the data List"
  with "`parse` reads a List or a string `data`; with `parsing: false`, `meta.parsed` is the data
  List, or the `JsStringList` of a string". Replace the sentence of `_onClick` with "`_onClick`
  gives the raw index of the legend item to `toggleDataVisibility`, which writes the upstream key
  `ToString(index)`." The test count: add "2 string-data tests and 24 index values of `onClick`
  with a data insert or remove".
- `src/controllers/controller.polarArea.js`: the same `_onClick` sentence. The tests: add "the
  reset on a new radial scale and one index value of `onClick` with an insert".
- `src/controllers/controller.radar.js`: add "the reset of a new point before the first layout of
  its scale writes `x` and `y` `undefined`", and one pin test.
- `src/scales/scale.radialLinear.js`: "`xCenter` and `yCenter` are `double?` (Dart `null` for the
  `undefined` start value)".
- `src/core/core.datasetController.js`: "`_dataCheck` keeps a string `data` as a `JsStringList`
  with no listener".
- `src/core/core.controller.js`: "`toggleDataVisibility` takes any JS value and writes the key
  `ToString(index)`".
- The rows of `test/port/controllers/controller.line_test.dart`, `test/port/core/core.datasetController_test.dart`,
  `test/port/core/core.controller_test.dart` and `test/port/js/js_array_test.dart`, if they give
  counts: 1, 2, 1 and 2 new tests.

**Proposed ADR and spec texts** (decision D12, W3-int aligns them):
- Chart.js ADR 0028 §1, table `types.RadialLinearScale`: `double? get xCenter` and
  `double? get yCenter` (Dart `null` is `undefined`, D11 item a). Table `types.Chart`:
  `void toggleDataVisibility(Object? index)`. The row of `DemoChart` (§1, implementers) and
  Chart.js ADR 0031 §9.2 (line 332): the signature `toggleDataVisibility(Object? index)`.
- Chart.js ADR 0028 §6, the bullet `toggleDataVisibility(jsToNumber(...))`: replace with
  "`toggleDataVisibility(jsGet(legendItem, 'index'))`: `types.Chart.toggleDataVisibility` takes
  the raw JS value and writes the key `ToString(index)`, as upstream. An absent index gives
  `'undefined'`, and `moveNumericKeys` moves a key such as `''` or `'01'` as upstream (D11 item c)."
- Chart.js ADR 0027 §5 item 4: "The doughnut reads `dataset.data` raw. `_dataCheck` keeps a
  string as a `JsStringList` (D11 item b); with `parsing: false`, `meta.parsed` is that List."
- IV spec: lines 102-104 (`toggleDataVisibility(Object? index)`), 161-164 (`double? get xCenter`,
  `double? get yCenter`), 580-581 and 646-647 (the code samples: `?? undefined`), 722 (the raw
  index).
- PD spec line 676-678: the doughnut code sample (no cast of `dataset.data`).
- GA spec line 88: `void toggleDataVisibility(Object? index) {}`.
- TS spec lines 347-348 (`chart.toggleDataVisibility(i.toDouble())`) stay valid.

## Open items

1. The two limits of `JsStringList` (item b: `isArray` and `typeof`, and the identity of
   `meta.parsed` with `dataset.data` for `parsing: false`) have no row. No ported reader sees them.
   A plugin of phase 8 that tests `isArray(meta._parsed)` or `_parsed === data` must re-check.
2. A truthy `data` that is neither a Map, a List nor a String (for example a number) still throws
   the `TypeError` of the cast in `_dataCheck`. Upstream keeps it (`_data.length` is `undefined`).
   D11 does not name it. It is outside the upstream type contract.
3. An adversarial fidelity reviewer for the `lib/` changes of this unit (work plan §0 rule 5) is
   for the phase lead.

## Fixes

The fixer of X-fix did the findings of `X-fix-review.md`. All three findings are "confirmed".
The fixer changed only two test files of the unit row:
`test/port/controllers/controller.polarArea_test.dart` (1 new test) and
`test/port/core/core.datasetController_test.dart` (3 new lines in 1 test). The fixer changed no
`lib/` file, no ADR and no shared doc. The fixer made no commit and ran no git command that
changes the index or the tree. The probes are in `<scratch>/wave3/X-fix-fix/`.

### F1: `xCenter` and `yCenter` are `double?`, but accepted Chart.js ADR 0025 §5 has `double`

**Decision.** The code stays `double?`. The fixer added the missing record for the phase lead
(open item 4 below) and a pin test that shows why `double` with NaN cannot give the upstream
behavior.

**Why the code cannot go back to `double`.** Upstream `xCenter` has two different values that
are not numbers:
- `undefined` before the first layout (`scale.radialLinear.js:416-418`). D11 item (a) needs it:
  the reset then writes `undefined`, and `resolve` skips it (`core.animation.js:31-32`).
- NaN after a layout. The reference case `position left` of
  `test/port/scales/scale_radial_linear_reference.dart` (line 40871) gives `xCenter` NaN. The
  probe `<scratch>/wave3/X-fix-fix/probe_f1c.mjs` (x64 Node.js, build at the pin, output
  `probe_f1c.out`), case `newAxisId`: a polar area chart with a finite layout gets a new scale
  `r2` with `position: 'left'`. `xCenter` is NaN, and the animation of the arc `x` goes from 256
  to NaN. The arc is then not drawn and not hit.

With `double` and NaN for both values, a controller cannot know which value it has. A mapping
"NaN to `undefined`" in the polar area controller gives the `undefined` target in the case
`newAxisId`. `resolve([cfg.to, to, currentValue, cfg.from])` (`core.animation.js:31`) then keeps
the current value 256, and the arc stays drawn. That changes the drawn element and the hit
element (Chart.js ADR 0009). Thus only `double?` (Dart `null` for `undefined`, NaN for NaN) gives
the upstream behavior.

**Pin test.** `controller.polarArea_test.dart`, group `the reset on a new radial scale`, test
`a NaN center after a layout animates x to NaN`. It checks `xCenter` NaN on the new scale and the
animation of `x` from 256 to NaN, the numbers of the probe.

**Record for the phase lead.** See open item 4. The alignment notes for W3-int now also name
these two texts:
- Chart.js ADR 0025 §5 (`doc/adr/0025-scale-value-parameters.md:463`): `double get xCenter`,
  `double get yCenter`. ADR 0025 is accepted. Thus W3-int must not edit it.
- `doc/phase7/members-radial.md:305`: `toggleDataVisibility(double)` becomes
  `toggleDataVisibility(Object?)`. Also `:249` and `:295` (`rl:826` `double xCenter`) become
  `double? xCenter`.

### F2: the IV §7.1 test passes for a `null` center

**Decision.** No change by X-fix. `test/port/types/index_test.dart` is not in the X-fix row.
W3-int moves this test to a polar area chart (D12).

**Note for W3-int.** With `double?`, `expect(t.xCenter, isNot(isNaN))` is true for `null`, and
`expect(t.xCenter, scale.xCenter)` is true when both are `null`. The moved test must assert
`isNotNull` for `xCenter` and `yCenter`, or compare them with the numbers of the laid-out polar
area chart (for example 256 and 256 for the 512 x 512 chart of the pin tests).

### F3: no assertion shows that a string `data` gets no listener

**Fix.** The test `with parsing false, the parsed items are the characters` of the group
`string data` (`core.datasetController_test.dart`) now calls
`notifyArrayListeners(meta.parsed, 'push', const ['3'])` and expects `dataChanges` to stay empty.
With parsing false, `meta.parsed` is the `_data` of `_dataCheck`. This pins
`core.datasetController.js:386` for a string.

**Mutation check.** The fixer added `listenArrayEvents(array, this)` after
`array = JsStringList(data)` in a copy of `_dataCheck`, ran the group, and put back the file from
the copy. The test failed with `Actual: [[0.0, '_insertElements', 1.0, 1.0]]`
(`<scratch>/wave3/X-fix-fix/mutation_f3.out`). The file is the same as before the check.

### Checks of the fixes

| Command | Result |
|---|---|
| `dart analyze --fatal-infos` on the 2 changed test files | No issues |
| `dart format --set-exit-if-changed` on the 2 changed test files | 0 changed |
| The `flutter test` command of the unit (see Checks) | +939 ~14, all passed (`<scratch>/wave3/X-fix-fix/after_fixes.out`). The counts differ from +901 ~51 because the other units of wave 3 changed their files in parallel. |
| `flutter test ... --plain-name 'NaN center'` (polar area) | +1, passed |
| `flutter test ... --plain-name 'string data'` (dataset controller) | +2, passed |
| `dart run melos run check:headers` | passed, 366 files |

The fixer left no `flutter_tester` process. One `flutter_tester` process (PID 67820) ran before
the fixer started. The fixer did not stop it.

### Open item 4 (new): the conflict with accepted Chart.js ADR 0025 §5

Accepted Chart.js ADR 0025 §5 fixes `double get xCenter` and `double get yCenter` of
`types.RadialLinearScale`. D11 item (a) and finding F1 need `double?`. An accepted ADR does not
change. The phase lead decides on the record. One possible record: a new proposed ADR that states
the complete decision of ADR 0025 with `double? get xCenter` and `double? get yCenter` (Dart
`null` for `undefined`, NaN for a NaN center after a layout), and supersedes ADR 0025. Its
evidence: the probes `<scratch>/wave3/X-fix/probe.mjs` (cases `a radar` and `a polarArea`) and
`<scratch>/wave3/X-fix-fix/probe_f1c.mjs` (case `newAxisId`). The ADR status lines stay with the
maintainer.
