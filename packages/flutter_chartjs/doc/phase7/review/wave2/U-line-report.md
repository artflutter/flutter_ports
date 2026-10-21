# Wave 2, unit U-line: report

## Status

Done. `lib/src/controllers/controller.line.dart` ports `src/controllers/controller.line.js` at the
pin `7169e651` line by line, with the forms of Chart.js ADR 0027 (parsed reads, the one-read rule
of decision D6) and Chart.js ADR 0028 (writes by name of the line, casts to `types` interfaces).
The generator, its data, the reference test file and the spec port are in place. All targeted
checks pass:

- `test/port/controllers/controller.line_test.dart`: 60 tests pass.
- `test/specs/controller.line_test.dart`: 33 pass, 1 skips (`blocked: plugin.tooltip`).
- `test:cases` for `controller.line.tests.js`: 34 cases, 33 passed, 0 failed, 1 skipped,
  0 missing.
- Three runs of the generator give the same SHA-256.

The unit runs in parallel with other units. Thus the full gate did not run. W2-int runs it.

One difference stays open (open item 1): the draw of a chart whose plugin cancels the first
layout. The fix needs files outside the row of this unit.

All paths are relative to `packages/flutter_chartjs/`. The scratch folder is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave2/U-line/`
(below: `<scratch>`).

## Files that changed

| File | Change |
|---|---|
| `lib/src/controllers/controller.line.dart` (new) | The port of `controller.line.js`: `LineController` with `id`, `defaults`, `overrides` and the class value `jsClass` (superclass `DatasetController.jsClass`), and the overrides of `initialize`, `update`, `updateElements`, `getMaxOverflow` and `draw`. The private function `_setProperty` is the JS write `properties[key] = value` of :94-111 (the point of a direct update, or the new object). |
| `tool/reference/controller_line_reference.mjs` (new) | The line generator: the 17 cases of Chart.js ADR 0030 §7, then 11 `parsed:` cases (PD §7.3, line rows) and 3 `interfaces:` cases (IV §7.3, line rows). Two named functions of the `segment` option (`segColor`, `segWidth`) and two probes of the key `extra` (`stackKeys`, `pointParsed`). |
| `test/port/controllers/controller_line_reference.dart` (new, generated) | 31 cases, 85 widths, 1,548,014 bytes (one file: the limit is 2.5 MB). SHA-256 `ec7573a936a2ac56e3fb923265ee7f272b3bb37d4f5a0c7dad2801329b095d2c`. |
| `test/port/controllers/controller.line_test.dart` (new) | The reference tests (TS §2): the origin tests, the order test, the 30 cases, the group `a dataset element of another class`, the themed run of the 17 cases with the stale-key test, the group `parsed data` (3 tests) and the group `interfaces` (4 tests). `main()` starts with `Chart.register([LineController.jsClass])`. |
| `test/specs/controller.line_test.dart` (new) | The spec port (TS §5, ADR 0030 §13): the 34 `it` cases of `controller.line.tests.js` with the exact `describe` and `it` names, in the upstream order. 33 `phase7` cases have bodies; `:1161` is a placeholder with the skip reason `'blocked: plugin.tooltip'`. `main()` starts with `Chart.register([LineController.jsClass])`. |
| `doc/phase7/review/wave2/U-line-report.md` (new) | This report. |

No other file of the repository changed.

## Forms of the port

- Parsed items: `jsGetKey` for each `parsed[axis]` and `_dataset._decimated`, `jsGetIndex` for
  `_dataset.data[i]`. No `_parsedValue`, no `jsGet(parsed` and no cast of a parsed item.
- The one-read rule (ADR 0027 §8, D6) in `updateElements`: `vValue` serves `:99` and `:101`,
  `iValue` serves `:100` and `:104`. `prevIValue` is the `iValue` of the previous pass that is not
  skipped. The first pass that is not skipped reads `jsGetKey(prevParsed, iAxis)` inside the
  `i > 0 &&` operand, with the `prevParsed` of `:87` (`getParsed(start - 1)` or `false`). Each
  local has a comment with its upstream lines. No statement between `:99` and `:104` writes the
  parsed item (`applyStack` reads only).
- `:91 properties = directUpdate ? point : {}`: `object` is the new Map (Dart `null` for a direct
  update), and `properties` is `object ?? point as types.PropertyAccess`. Each write is
  `_setProperty` in the upstream order. `updateElement(point, i, object!, mode)` only when the
  update is not direct. The writes by name stay (ADR 0027 §8, step 7 list).
- `isNumber(spanGaps) ? spanGaps : Infinity` gets one `jsToNumber` at the read: its only use (the
  `>` of `:104`) applies `ToNumber` (ADR 0027 §7). A pin case (`parsed: spanGaps '2'`) and a
  relation test show it.
- `update`: `line! as types.PropertyAccess` for the four writes of `:57-60` (IV §4.2). The null
  check throws a `TypeError` for a missing dataset element, as `undefined._chart = ...`.
- `getMaxOverflow`: `dataset.options && dataset.options.borderWidth || 0` keeps the raw value
  (read once), `jsMax` of the `jsToNumber` values, and the cast to `types.PointElement` at `size`
  (IV §4.3).
- `draw`: `(meta.dataset! as types.LineElement).updateControlPoints(chart.chartArea!, ...)`
  (IV §4.3). See open item 1 for `chart.chartArea!`.
- `grep -n " as " lib/src/controllers/controller.line.dart`: 5 casts, each to a `types`
  interface (`PropertyAccess` 2, `PointElement` 2 in one method, `LineElement` 1; lines 148, 224,
  322, 325, 339). The imports are DC, helpers, the JS runtime and the types only (IV §4.8).

## The cases of the generator

The 17 cases of ADR 0030 §7 (row `line`), in this order: `default` (with the scale options; steps
`update`, `update none`, `reset`, `update`), `showLine false`, `spanGaps true`, `spanGaps a
number` (2 and 3.5 on a linear x scale with gaps), `stepped before, after and middle`, `tension`
(also `capBezierPoints: false`), `cubicInterpolationMode monotone`, `segment with named
functions`, `stacked lines`, `indexAxis y`, `a linear x scale with min and max` (with the step
`update`: start > 0), `pointRadius 0`, `a hidden dataset and setDatasetVisibility` (two steps),
`parsing false`, `null items`, `drawActiveElementsOnTop false with setActive`, `push` (two steps).

The 11 `parsed:` cases: a `null` item with `parsing: false`, also with `segment`, `hidden` and a
user `min` and `max` (each a `TypeError` at `initial`; the hidden dataset throws in
`updateElements`, `:99`); a number item with `segment` (probe `pointParsed`: `point.parsed` is 5);
`x.min 1` with an item without `x` and with `x: null` (the y range); the one-read rule with
`segment`, `spanGaps 2` and start > 0 (steps `update`, `push`, `update`); `spanGaps '2'`; stacked
List items with `parsing: false` (probe `stackKeys`); stacked numbers with `parsing: false`
(`TypeError`).

The 3 `interfaces:` cases: the two label sets of IV §7.3 (a String label), and a dataset element
of another class (the element class `OtherLine` with the id `otherLine`, named in
`defaults.datasets.line.datasetElementType`; `TypeError` at `initial`, from the draw at `:140`:
`meta.dataset.updateControlPoints is not a function`). The generator puts the default back and
unregisters the class after the case.

## Tests that were added

`test/port/controllers/controller.line_test.dart` (60 tests):

- `the reference comes from Node.js v24.12.0 on x64 and a build of the pinned Chart.js`, 1 width
  test, `the reference has the 17 cases of Chart.js ADR 0030 first`.
- The 30 reference cases (`testControllerChartCases` with `_functions` and `_extras`).
- Group `a dataset element of another class`: `setUp` registers the Dart class value `OtherLine`
  (superclass `Element.jsClass`, id `otherLine`), unregisters it with `addTearDown`, and writes
  the line default. The generated case, and the relation test `the update writes the four
  properties of the line by name, and the draw throws a TypeError` (a plugin cancels the chart
  draw; `_chart`, `_datasetIndex`, `_decimated`, `points` by name, `points` is the same List as
  `meta.data`; the draw of the controller throws a `TypeError`).
- Group `theming.md §8 test 3: the light preset`: the 17 cases with the light preset, and `the
  light preset leaves no stale scale key`.
- Group `parsed data`: `stacked List items with parsing false take a stack object with the key
  of the value axis` (point `x` NaN, `skip` true); `spanGaps '2' gives the points of spanGaps 2`;
  `an animated update ends at the points of an update without animation` (the path of the new
  object and `updateElement`; also `raw` and `parsed` of `:106-107` after a second update with new
  data).
- Group `interfaces`: `line.points` after `chart.update()`, after `data.push` and
  `chart.update()`, after a splice and `chart.update()` (ADR 0028 §3); `getLabelAndValue gives a
  String label`.

`test/specs/controller.line_test.dart`: 34 tests (33 bodies, 1 placeholder). The `auto` fixture
group is a comment at its upstream position. Spec forms (also in the comment block of the file):
`spyOn(meta.dataset, ...)` is `spyOnDataset(meta)`; the hooks of `dataset global defaults` read
no chart, so they are `setUp` and `tearDown`; the `beforeEach` of `Interactions` is a local
function; `chart._handleEvent` is `chart.handleEvent`, and the event `{type, native: true,
...point}` is a private `_PointEvent` with `native` Dart `null` (the port types `native` as a
`NativeEvent`; `getRelativePosition` tests only the key). `should render a million points` runs
in less than 1 s on the VM.

Evidence that the compare is effective (`<scratch>/mut1.log` to `mut6.log`; the lib file was put
back each time, `diff` empty):

- `prevParsed[iAxis]` read as the current `iValue`: 5 tests fail (`spanGaps a number` and its
  themed twin, `parsed: spanGaps '2'`, the relation test, the one-read case).
- The first-pass read `jsGetKey(prevParsed, iAxis)` replaced by `iValue`: the first data had no
  such case. The one-read case got `min: 4.5` (start 2 after the gap 3) and a pushed point after a
  gap 4. Then only that case fails, as expected.
- `raw` and `parsed` only for a direct update: the animated relation test fails (`Expected: 7.0,
  Actual: 1.0`) after it got the second update.

## Checks

| Command | Result |
|---|---|
| `/usr/bin/arch -x86_64 <scratchpad>/env/node-v24.12.0-darwin-x64/bin/node tool/reference/controller_line_reference.mjs <scratchpad>/env/chartjs-build/dist/chart.js`, three runs | rc 0; the same SHA-256 `ec7573a9...095d2c` for each run |
| `flutter test test/port/controllers/controller.line_test.dart test/specs/controller.line_test.dart` | +93 ~1, all passed |
| `dart run melos run test:cases` | passed, 42 files, 0 errors, 0 warnings; `controller.line.tests.js` 34 cases, 33 passed, 0 failed, 1 skipped, 0 missing |
| `dart analyze --fatal-infos lib/src/controllers test/port/controllers test/specs/controller.line_test.dart` | No issues |
| `dart format --output=none --set-exit-if-changed` of the 4 Dart files | 0 changed |
| `dart run melos run check:headers` | passed, 359 files |
| `dart run melos run check:lib-imports` | passed, 322 files |
| `dart run melos run check:js-semantics` | passed, 128 files |

`parity:check` did not run: W2-int changes `doc/status.yaml` and runs `parity` (rule 2 of the
work plan). The gallery does not change: the unit changed no interface.

No `flutter_tester` process of this unit is left. The process 67820 belongs to another session
(`ec6419b7-...`). This unit did not touch it.

## Doc notes for W2-int

`AGENTS.md`:

- Layout, `lib/src/controllers/`: add "`controller.line.dart` has `LineController` and its class
  value `LineController.jsClass`. `updateElements` reads each key of a parsed item once (the
  one-read rule of Chart.js ADR 0027 §8). `update` writes `_chart`, `_datasetIndex`, `_decimated`
  and `points` into the line by name (`types.PropertyAccess`), and `draw` casts the line to
  `types.LineElement` (Chart.js ADR 0028)."
- Layout, `test/port/controllers/`: "`controller.line_test.dart` compares the line charts of
  `tool/reference/controller_line_reference.mjs` (data `controller_line_reference.dart`)."
- Tests, the generator list: "`tool/reference/controller_line_reference.mjs` writes
  `test/port/controllers/controller_line_reference.dart`. It needs no moment packages."
- Tests: remove the temporary `Chart.register([LineController.jsClass])` lines of
  `test/port/controllers/controller.line_test.dart` and `test/specs/controller.line_test.dart`
  when `flutter_test_config.dart` registers the wave (Chart.js ADR 0030 §3 item 4). The import of
  `controller.line.dart` stays in both files (the specs and the tests use the class).

`doc/porting-flow.md`: §5, the phase 7 row: `controller.line` is ported in wave 2 (33/34 spec
cases, 17 reference charts and their themed twins). No other change.

`doc/performance.md`:

- §13.1: "The one-read rule landed in `controller.line.dart` (decision D6): two reads of each
  parsed item for each point, in place of five. The figures are those of Chart.js ADR 0027,
  Benchmarks (22 to 24 ns AOT and 33 to 36 ns wasm for each point). This unit measured nothing
  new."
- §13.7: "The writes by name into the point of a direct update (`_setProperty` of
  `controller.line.dart`) are in the step 7 list (typed setters, Chart.js ADR 0027 §8)."

`doc/differences.md`: no new row and no new marker. Open item 1 needs a decision (a fix in the
shared layer, preferred, or a row).

`doc/status.yaml`:

- `src/controllers/controller.line.js`: the Dart target `lib/src/controllers/controller.line.dart`,
  status "ported"; text: "`test/port/controllers/controller.line_test.dart` compares 17 charts
  with upstream, and 17 more with the light preset; 14 pin cases (11 `parsed:` of Chart.js ADR
  0027, 3 `interfaces:` of Chart.js ADR 0028) and 8 relation tests."
- `test/specs/controller.line.tests.js`: the Dart target `test/specs/controller.line_test.dart`;
  text: "ported ({{passed}}/{{cases}} cases pass on {{platforms}}; {{skipped:blocked:
  plugin.tooltip|case}} skipped, `blocked: plugin.tooltip`. Each chart case is a `testWidgets`
  case with the conventions of Chart.js ADR 0030 §13. The fixture group `auto` waits for the
  fixture runner (Chart.js ADR 0029). `test/port/controllers/controller.line_test.dart` covers
  the controller)".
- `src/controllers/index.js`: `LineController` in the partial text (W2-int adds the export).
- Port-only rows: `test/port/controllers/controller.line_test.dart`,
  `test/port/controllers/controller_line_reference.dart` and
  `tool/reference/controller_line_reference.mjs` (as the bar rows).
- Then run `dart run melos run parity`.

`doc/upstream-ledger.md`: row #12155: "The fixture `controller.line/stacking/stack-cache.js` waits
for the fixture runner (Chart.js ADR 0029); `controller.line` is ported in wave 2 of phase 7." No
other row names `controller.line`.

## Open items

1. **The draw with no chart area (IV §4.3, the reviewer item of the line wave).** A plugin that
   returns `false` from `beforeLayout` at the first update leaves `chart.chartArea` undefined.
   Upstream passes `undefined` to `updateControlPoints` and throws only when the line computes
   control points with `capBezierPoints`. The port throws a `TypeError` at `chart.chartArea!`
   (`controller.line.dart:340`) for each such chart: the chart draw reaches the dataset draw
   without a read of `chartArea!` (IV §4.3 says that the chart draw reads it first; the probe
   shows that it does not). Probes (`<scratch>/probe_layout.mjs`, `<scratch>/layout_probe_test.dart`):

   | Chart | Upstream | Port |
   |---|---|---|
   | line, no tension | no throw | `TypeError` at `controller.line.dart:340` |
   | `tension: 0.4` | `TypeError` in `capBezierPoints` (`area.left`) | `TypeError` at `:340` |
   | `tension: 0.4`, `capBezierPoints: false` | no throw | `TypeError` at `:340` |
   | `clip: false` | no throw | `TypeError` at `:340` |

   A throw is a protected behavior (Chart.js ADR 0009). The fix is outside the row of this unit:
   `ChartArea?` in `types.LineElement.updateControlPoints` (`lib/src/types/index.dart`), in
   `LineElement.updateControlPoints` (`lib/src/elements/element.line.dart:797`), in
   `updateBezierControlPoints` and `_capBezierPoints` (`lib/src/helpers/helpers.curve.dart:255`,
   `:289`; a `TypeError` at the read of the area when it is `null`), and in `_LineSpy` of
   `test/support/jasmine.dart`. Then `controller.line.dart` passes `chart.chartArea` without `!`.
   `plugin.filler/index.js:61` is the only other caller (phase 8). The phase lead decides.
2. ADR 0027 Open 4 (the maintainer reviews `prevIValue`): the local crosses the passes of the
   loop and keeps each upstream statement. The fallback (the 3-read form) removes `prevIValue` and
   `hasPrevIValue` and reads `jsGetKey(prevParsed, iAxis)` at each pass. The one-read pin case
   passes with both forms.
3. The spec case `should correctly calc visible points on update` gives the event `native: null`
   where upstream gives `native: true`. No reader of `_handleEvent` reads `native` (only `'native'
   in e`). No row: the value does not reach a protected behavior.
4. L2 lifts the `blocked: controller.line` placeholders of the other spec files (work plan §3),
   with the 3 placeholders of `controller.bar_test.dart`.

## Fixes

The fixer read `U-line-review.md` and changed only the files of the row of this unit. The scratch
folder of the fixes is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave2/U-line-fix/`
(below: `<fix>`). It has a copy of each file before the fixes.

### U-line-R1 (confirmed): the draw with no chart area

Partly fixed. The fix of the throw stays open (open item 1): it needs files outside the row of
this unit (`lib/src/types/index.dart`, `lib/src/elements/element.line.dart`,
`lib/src/helpers/helpers.curve.dart`, `test/support/jasmine.dart`). The phase lead decides
between that fix and a `DIVERGES` row.

- `lib/src/controllers/controller.line.dart`: the doc comment of `draw` is correct now.
  `chart.chartArea` can be Dart `null`, the chart draw does not read it first, upstream throws
  only when the line caps its control points, and the null check throws for each such chart. The
  comment names the shared-layer fix and the pin tests.
- `test/port/controllers/controller.line_test.dart`: the new group `interfaces` > `a plugin
  cancels the first layout` (a plugin `beforeLayout: () => false`, labels a to c, data 1 to 3):
  - `tension 0.4: the draw throws a TypeError` runs. It passes now (the throw of the null check)
    and after the shared-layer fix (the throw of `_capBezierPoints`).
  - The group `the draw does not throw` has 4 cases: `no tension`, `clip false`, `tension 0.4 and
    capBezierPoints false`, `tension 0.4 and one point`. Each expects no throw and
    `chart.chartArea` `null`. The group is skipped with the reason `U-line open item 1:
    chart.chartArea! throws; the fix changes the shared layer`. The change of the shared layer
    removes the `skip`.
- The generator cannot give these cases: `observe` of `scale_chart_common.mjs:790` (a U0 file)
  reads `chartArea.left` and stops the generator. Thus the expected results come from a probe
  (`<fix>/probe_no_area.mjs`, `<fix>/probe_no_area.out`, x64 Node.js v24.12.0, the pinned
  build):

  | Variant | Upstream |
  |---|---|
  | no tension | no throw, `chartArea` undefined |
  | `clip: false` | no throw, `chartArea` undefined |
  | `tension: 0.4` | `TypeError` "Cannot read properties of undefined (reading 'left')" in `capBezierPoints` |
  | `tension: 0.4`, `capBezierPoints: false` | no throw, `_pointsUpdated` true |
  | `tension: 0.4`, one point | no throw, `_pointsUpdated` true (`capBezierPoints` reads `area.left` only for a neighbour in the area) |

- Evidence (`<fix>/mut_skipped.log`): `flutter test --run-skipped --plain-name 'a plugin
  cancels'` gives 1 pass and 4 failures, each a `TypeError` "Null check operator used on a null
  value" at `LineController.draw (controller.line.dart:348:22)`. Thus the skipped cases pin the
  difference, and they pass when the shared-layer fix lands.

### U-line-R2 (confirmed): `prevIValue` crosses user code

Fixed with the 3-read form of Chart.js ADR 0027 (Question 5 and Open 4). The local of the
previous pass does not obey the one-read rule of ADR 0027 §8 ("only when no statement between
the two reads writes that key of that item"), and condition 1 of §8 (the upstream result for
each value) fails for the probe of the reviewer. The ADR wins over the plan.

- `lib/src/controllers/controller.line.dart`: `prevIValue` and `hasPrevIValue` are removed.
  The read `prevParsed[iAxis]` of `:104` is `jsGetKey(prevParsed, iAxis)` at each pass. `vValue`
  and `iValue` stay (the one-read rule in a pass, decision D6). The doc comments of the library
  and of `updateElements` state the cross-pass interval: `resolveDataElementOptions` (`:111`) and
  the animated `updateElement` (`:115`) run the scriptable options of the user, and their context
  holds the parsed item.
- `tool/reference/controller_line_reference.mjs`: the new pin case `parsed: a scriptable option
  writes ctx.parsed` (linear x, data `{x: 0..3, y: 1..4}`, `spanGaps: 1.5`, the named function
  `radiusWrite` for `pointRadius`: it writes `ctx.parsed.x = 10` for the data index 1 and gives
  3). The test file has `radiusWrite` with the same body.
- Evidence (`<fix>/mut_prev.log`): with the file of before the fix, only the new case fails
  (`at location ['segments'][0][1] is <3.0>`; upstream breaks the line between the points 1 and
  2). With the fix, it passes.
- Cost: the ADR figures of the 3-read form are 15 to 17 ns (AOT) and 23 to 24 ns (wasm) for each
  point, in place of 22 to 24 ns and 33 to 36 ns of the 2-read form. This fix measured nothing
  new.
- Input to Open 4 for the maintainer: a form with the local only when no user code runs between
  the reads (a direct update with shared options) gives the upstream result too and keeps the
  2-read gain on that path. It needs a microbenchmark (§8 condition 3). This fix does not add it.
  The scatter unit has the same item (`scatter.js:124-148`).

### U-line-R3 (confirmed): wrong citations

Fixed. `test/specs/controller.line_test.dart`: `:304-326`, `:369-391`, `:449-471`, `:505-527`
(the stacked pixels); `:657-667` and `:695-705` (the options of `lineOptions`); `:675-685` and
`:713-723` (the expectations, two comments). `tool/reference/controller_line_reference.mjs`:
`core.datasetController.js:687` (`getLabelAndValue`). Each range was read again at the pin with
`sed -n`.

### Checks after the fixes

| Command | Result |
|---|---|
| The generator (`/usr/bin/arch -x86_64 <scratchpad>/env/node-v24.12.0-darwin-x64/bin/node tool/reference/controller_line_reference.mjs <scratchpad>/env/chartjs-build/dist/chart.js`), three runs | rc 0; 32 cases, 85 widths, 1,576,533 bytes; the same SHA-256 `457780eac443fc10097988a0372018680381ca293e5a014c461b22d2a69cf531` for each run |
| `flutter test test/port/controllers/controller.line_test.dart test/specs/controller.line_test.dart` | +95 ~5, all passed (the 4 skips of open item 1 and `blocked: plugin.tooltip`) |
| `dart analyze --fatal-infos` of the lib file, the two test files and the data file | No issues |
| `dart format --output=none --set-exit-if-changed` of the 4 Dart files | 0 changed |
| `dart run melos run check:js-semantics` | passed, 128 files |
| `dart run melos run check:headers` | passed, 359 files |
| `dart run melos run check:lib-imports` | passed, 322 files |

The spec file changed in comments only: the spec run gives 33 passes and 1 skip, as before. No
interface changed, thus the gallery does not change.

No `flutter_tester` process of the fixes is left. The process 67820 belongs to another session
(`ec6419b7-...`). The fixer did not touch it.

### Changes to the doc notes for W2-int

- `doc/status.yaml`, `src/controllers/controller.line.js`: "15 pin cases (12 `parsed:` of
  Chart.js ADR 0027, 3 `interfaces:` of Chart.js ADR 0028), 9 relation tests and 4 tests skipped
  for open item 1".
- `doc/performance.md` §13.1: the line loop uses the 3-read form (two locals in a pass, and the
  read `prevParsed[iAxis]` at each pass): 15 to 17 ns (AOT) and 23 to 24 ns (wasm) for each
  point, the figures of Chart.js ADR 0027. The 2-read form waits for Open 4.
- `doc/differences.md`: no row for U-line-R2 (the port gives the upstream result). Open item 1
  still needs a decision (the shared-layer fix, preferred, or a row).
