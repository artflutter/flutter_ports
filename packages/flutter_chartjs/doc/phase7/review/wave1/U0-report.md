# Wave 1, unit U0 (test infrastructure): report

## Status

Done. The test infrastructure of TS §1 (without §1.1, which S2 did) is in place: the element draws
in the draw calls of the phase 6 reference tests, the shared `Path2D` record, the controller
generator code, the controller harness, the Jasmine library and the move of the private Jasmine
copies. The targeted tests pass. `test:cases` gives the same counts before and after. The 8 phase 6
data files were generated two times with the same SHA-256. The `registerPhase7` check of TS §1.2
item 5 gives byte-identical output, so the generators keep `registerPhase6`.

The prompt of the unit limits the checks to the targeted tests and `test:cases` (U0 runs in
parallel with S3 and U-bar). Thus the full gate of the work-plan row did not run. W1-int runs it.

## Files that changed

The paths are relative to `packages/flutter_chartjs/`.

| File | Change |
|---|---|
| `tool/reference/scale_chart_common.mjs` | TS §1.2: `drawCalls` has no sink (the element draws are in the calls). `dartCall` (new) holds the mapping of one call. `dartCalls`, `jsonValue` and `CallsText` are exported. `jsonValue` writes a `Path2D` as `{path, calls}` (ids from 1 for each `dartCalls` call, in the order of the first sight; the commands have the form of a call line). The header names the controller generators as users. `writeReference` takes `notes` (comment lines after the header; no change when empty). `dart()` writes a raw string for a string with `$` or `\` that needs no escape (lint `use_raw_strings`; the phase 6 output does not change). |
| `test/port/scales/scale_*_reference.dart` (8 files) | Generated again: 8,455,931 to 9,069,771 bytes, the figure of ADR 0030. |
| `test/port/scales/scale_chart_harness.dart` | TS §1.3: `drawCalls` puts the recording context in `chart.ctx`, each `scale.ctx` and the `ctx` of each controller whose `ctx` is the chart context, and returns `recordedCalls(...)`. `expectCalls` takes `List<Object?>`. `callMatchers` maps a `{path, calls}` argument (`_callMatcher`, `_argMatcher`). `expectScaleObservations` (new) holds the key check and the `chartArea`, `scales`, `points` checks, with an optional `label`. The library doc has the new text. |
| `test/port/scales/scale_chart_harness_test.dart` | TS §1.8 row 2: group `drawCalls` (2 cases). |
| `test/port/canvas/path2d_record.dart` (new) | TS §1.4: `PathIds`, `recordedCalls`, `replayPath`. A pure helper (imports `pure.dart` and `canvas.dart` only). |
| `test/port/elements/element.line_test.dart` | TS §1.4: the private `_PathIds`, `_actual`, `_actualCalls` and `_replay` are removed; the file imports `path2d_record.dart`. |
| `tool/reference/controller_chart_common.mjs` (new) | TS §1.5: the recording `Path2D` on `globalThis` in the module body, `loadChartJs` (the checks of `scale_chart_common.mjs`, and it keeps the module), `registerPhase7`, `plain`, `hitQueries`, `hitPoints`, `hits`, `DATASET_OPTION_KEYS`, `observeControllers`, `applyStep`, `runControllerCase`, `writeControllerReference` (the probe sources as comment notes). |
| `test/port/controllers/controller_chart_harness.dart` (new) | TS §1.6: `ReferenceEvent`, `hitItems`, `observeHits`, `plainValue`, `observeControllers`, `expectControllerObservations`, `runStep`, `testControllerChartCases`, `expectNoStaleScaleKeys`. |
| `test/port/controllers/controller_chart_harness_test.dart` (new) | TS §1.8 row 3, and the spies of `jasmine.dart` (see Tests). |
| `test/support/jasmine.dart` (new) | TS §1.7: `jasmineEquals`, `objectContaining`, `anyFunction`, `JasmineOptions`, `JasmineCalls`, `JasmineSpy`, `JasmineSpyStrategy`, `spyOn`, `spyOf`, `JasmineSpyCalls`, `toHaveBeenCalled`, `spyOnElementDraw`, `spyOnDataset`, `spyOnArrayListener`. A pure helper. |
| `test/specs/core.controller_test.dart` | The private `_Options`, `_actual`, `_hasOwnProperty`, `_objectContaining`, `_JasmineObjectContaining`, `_toEqual` and `_JasmineEquals` are removed; the file uses `JasmineOptions`, `objectContaining` and `jasmineEquals`. Two imports went. |
| `test/specs/core.plugin_test.dart` | The private `_none`, `_Calls`, `_Spy`, `_SpyStrategy`, `_spies`, `_spyOn`, `_spyOf`, the extension and `_toHaveBeenCalled` are removed; the file uses `spyOn` and `toHaveBeenCalled`. |
| `test/specs/helpers.canvas_test.dart` | `_Call` and `_Calls` are removed; `_ClearRectSpy` records into a `JasmineCalls`. |
| `test/specs/core.element_test.dart` | `_objectContaining` is removed; `objectContaining` reads the `ElementProps` of `getProps`. |
| `test/specs/helpers.options_test.dart` | `_toEqual` (a flat object) is removed; the file uses `jasmineEquals`. |
| `doc/phase7/review/wave1/U0-report.md` | This report (new). |

Not changed, with the reason (TS §1.7: "a helper that only one file needs ... stays"):
- `helpers.segment_test.dart` `_toEqual` (a `Segment` matcher with SameValue), `helpers.interpolation_test.dart`
  `_toEqual` (an `InterpolatedPoint` matcher) and `helpers.easing_test.dart` `_toEqual` (a number
  list with the 1e-8 tolerance of the `DIVERGES` row `js-semantics-dart-math`): typed matchers, not
  the Jasmine `eq` of Maps.
- `helpers.curve_test.dart`: no copy (the scan of the work plan is correct).

## Deviations from the spec (for the reviewer)

1. Line 1 of two new files is shorter than the text of the spec, because the lint
   `lines_longer_than_80_chars` fails `analyze --fatal-infos` on it:
   `path2d_record.dart` "the record form of Path2D arguments." (spec: "... in the tests."),
   `controller_chart_harness.dart` "controller reference test harness." (spec: "the Dart side of
   controller_chart_common.mjs."), `jasmine.dart` "Jasmine matchers and spies." (spec: "the Jasmine
   matchers and spies of the spec ports.").
2. `hits.items` is text: one JSON line `items[p]` for each point (the form of `drawCalls`), not a
   Dart literal. A probe of 3 cases gave 1,521,132 bytes with the literal (hits: about 1.2 MB of
   it) and 495,325 bytes with the text. The semantics do not change: `items[p][q]` is the list
   `[[datasetIndex, index], ...]`, compared exactly.
3. A step that throws stands in `steps` as `{do}` without `observations`, so that the Dart test runs
   the same step and expects the throw. The `error` key keeps the form `{at, name}`.
4. `testControllerChartCases` has the extra named parameter `errorTypes` (a JS error name to a Dart
   matcher). `TypeError` maps to a Dart `TypeError` without it.
5. The themed run (`parseColors: true`) compares only the keys of the expected options Maps
   (scales, `options`, `active`, `datasetOptions`, `dataset.options`). The light theme adds own
   keys, for example `scales.x.options.ticks.font`. Upstream has no such key, and
   `expectNoStaleScaleKeys` requires those emitted keys. The unthemed run compares exact key sets.
6. `xAxisID` and `yAxisID` observe Dart `null` as `undefined`: after `linkScales`, the JS value is a
   scale id or `undefined`, and the Dart field gives `null` for `undefined`.
7. `_PointDrawSpy` and the other draw spies copy more than `active` and `options`: also `hidden`,
   `x`, `y`, `$animations` and the by-name properties of the class (in the `undefined` state they
   stay in that state). Thus a spy with `callThrough` draws at once, before the next update.
8. `spyOnArrayListener` puts the spy last in the listeners (`unlistenArrayEvents` and
   `listenArrayEvents`; the stub list is private). It has an optional `callThrough`.
9. `JasmineOptions` (the `_Options` of `core.controller_test.dart`) moved to the library as a
   public class, because the moved matchers unwrap it.

## Tests that were added

- `test/port/scales/scale_chart_harness_test.dart`, group `drawCalls`: "records the point draws of
  the test controller and puts back each context" (3 `arc` calls at the points; `chart.ctx`, each
  `scale.ctx` and `controller.ctx` are the old objects after the call); "leaves a controller with
  another context as it is".
- `test/port/controllers/controller_chart_harness_test.dart` (`@TestOn('vm')`, 20 cases):
  - `Path2D arguments`: a `Path2D` records as `{path, calls}` with ids in the order of the first
    sight; a shared `PathIds`; `expectCalls` with a `{path, calls}` argument passes, and a wrong id
    or a wrong number fails.
  - `the hit queries`: `ReferenceEvent` at the center of element 1 with the mode `point` gives
    `[[0, 1]]`; `observeHits` and `hitItems`.
  - `runStep`: `update`, `update` with a mode, `reset`; `setDatasetVisibility`,
    `toggleDataVisibility`; `setActive`; `push` and `splice` (the controller parses the new item;
    an absent dataset throws a `TypeError`); `hover` and `mouseout` at a point center; an unknown
    step throws an `ArgumentError`. All on the phase 6 test controller `scaleTest`.
  - `expectControllerObservations`: the observation of the chart passes (unthemed and themed); an
    unknown key of the observation, of a dataset and a scale id fail; a changed value fails.
  - `testControllerChartCases`: the record 'an error at initial' of the probe (`datasets: [null]`,
    `TypeError`).
  - `expectNoStaleScaleKeys`: a present path passes, a stale path fails.
  - The spies of `jasmine.dart`: `spyOnElementDraw` (the slot, the count after an update, the
    `callThrough` draw), `spyOnDataset` (draw and `updateControlPoints`), `spyOnArrayListener`
    (`_onDataPush`, `_onDataSplice` with their arguments), `spyOn`, `anyFunction`,
    `toHaveBeenCalled`, `jasmineEquals` (NaN, signed zero) and `objectContaining`.
- `test/port/elements/element.line_test.dart`: passes with the shared helper (no new case).

The end-to-end probe (not kept, in the scratch folder `wave1/U0/probe/`): a generator on
`controller_chart_common.mjs` with the phase 6 test controllers wrote 6 cases (`default` with 12
steps and an `extra` probe, stacked values with `null` and `NaN`, a radial chart, `hover` with a
real hit and `mouseout`, an error at `initial`, an error at a step). The Dart test of the harness
passed all 6 cases, and the 6 themed twins with the light preset, and `expectNoStaleScaleKeys` on a
cartesian and a radial chart. This is the evidence that the two sides give the same keys and values.

## Checks

| Command | Result |
|---|---|
| `dart run packages/flutter_chartjs/tool/spec_cases.dart` (`test:cases`) before | passed, 37 files: 1036 cases, 383 passed, 0 failed, 411 skipped, 242 missing |
| the same, after | passed, 37 files: the same counts in each row (a `diff` of the rows is empty) |
| the 8 generators (x64 Node.js v24.12.0, the build at `7169e651`), run 1 and run 2 | the same SHA-256 for the 8 files; 9,069,771 bytes; a third run after the `dart()` change gives the same SHA-256 |
| the 8 generators with `registerPhase7` (a local edit of the imports, then restored from a copy) | byte-identical with run 1: `registerPhase6` stays (TS §1.2 item 5) |
| `flutter test` of `test/specs/{core.controller,core.plugin,helpers.canvas,core.element,helpers.options}_test.dart`, `test/port/elements/element.line_test.dart`, `test/port/scales`, `test/port/controllers` | +828 ~99, all passed |
| `dart test -p chrome -c dart2js -c dart2wasm` of `core.element_test.dart`, `helpers.options_test.dart`, `element.line_test.dart` | +284, all passed |
| `dart analyze --fatal-infos` of `test/port`, `test/specs`, `test/support` | No issues |
| `dart format --set-exit-if-changed` of the changed Dart files | 0 changed |
| `check:lib-imports` | passed, 298 files |
| `check:headers` | passed, 335 files |
| `check:js-semantics` | passed, 116 files |
| `parity:check` | failed with 1 error that is not of U0: `parity.md:126`, the new `lib/src/controllers/controller.bar.dart` of U-bar with the status "not started". 4 warnings of U0: no port-only row for `test/port/canvas/path2d_record.dart`, `test/port/controllers/controller_chart_harness.dart`, `controller_chart_harness_test.dart` and `test/support/jasmine.dart` (W1-int, `doc/status.yaml`) |

No `flutter_tester` process of U0 stays. The process 67820 of another session (S1 and S2 reports)
is still there. U0 did not start it and did not kill it. `apps/chartjs_gallery` needs no analyze:
U0 changed no interface that the gallery implements.

## Result of TS §1.2 item 5 (for the phase lead, `doc/phase7-progress.md`)

"U0: the 8 phase 6 generators with `registerPhase7` (controllers, scales, elements) give
byte-identical output to `registerPhase6`. The phase 6 generators keep `registerPhase6`."

## Doc notes for W1-int

`AGENTS.md`, Tests:
- Replace "The draw calls have no element draws, because `DatasetController.ctx` is final." with:
  "The draw calls have the element draws: `drawCalls` puts the recording context in `chart.ctx`,
  in each `scale.ctx` and in the writable `DatasetController.ctx` (Chart.js ADR 0030). A `Path2D`
  argument records as `{path, calls}` (`test/port/canvas/path2d_record.dart`)."
- Add: "The controller reference tests in `test/port/controllers/` build each chart of their
  generator with `acquireChart`, run its steps, and compare the observations, the hit queries and
  the draw calls through `controller_chart_harness.dart` (`testControllerChartCases`). Each file
  also runs its cases with the light preset (theming.md §8 test 3): then the colors compare in
  their parsed form, and the options compare only the keys of upstream. A JS `TypeError` of a case
  is a Dart `TypeError`."
- Generator list: "`tool/reference/controller_chart_common.mjs` is the shared code of the
  controller generators. It defines a recording `Path2D` before the dist loads. The generators
  write `test/port/controllers/controller_<name>_reference.dart`. The bar generator also needs the
  moment packages and `TZ=UTC`." (The controller generators come with the units of the waves.)
- Replace the spy bullet: "A chart spec ports a Jasmine spy of a function value as a recording
  function value (`spyOn` of `test/support/jasmine.dart`). A spy of a method is a spy object in the
  slot that the library reads (`spyOnElementDraw` for `meta.data[i]`, `spyOnDataset` for
  `meta.dataset`, `spyOnArrayListener` for the listeners of a data array, a context in
  `chart.ctx`). `test/support/jasmine.dart` holds the shared matchers (`jasmineEquals`,
  `objectContaining`, `anyFunction`, `JasmineOptions`) and spies (Chart.js ADR 0030)."
- "Jasmine `this`: `late` variables of the group closure." (TS §6, no U0 code.)

`AGENTS.md`, Layout: `test/port/controllers/` (the reference tests and their harness
`controller_chart_harness.dart`), `test/support/jasmine.dart` (a pure helper of the specs),
`test/port/canvas/path2d_record.dart` (a pure helper).

`doc/porting-flow.md`: §2.23 and §3 "Reference tests of the controllers" as TS §6. Add to §3: "A
step that throws stands in `steps` as `{do}` without observations. `hits.items` is one JSON line
for each point."

`doc/performance.md` §13.4: the figures of ADR 0030 Evidence E3. U0 measured nothing new. The data
size: the 8 phase 6 files grow by 7.3 % (8,455,931 to 9,069,771 bytes). A probe of 3 controller
cases gave 1.52 MB with the hit items as a Dart literal and 0.50 MB as JSON lines (§13.7 or the
note of ADR 0030 Open 4).

`doc/differences.md`: no row.

`doc/status.yaml`: port-only rows for `test/port/canvas/path2d_record.dart`,
`test/port/controllers/controller_chart_harness.dart`,
`test/port/controllers/controller_chart_harness_test.dart` and `test/support/jasmine.dart` (the 4
warnings of `parity:check`). The texts of `core.controller.tests.js` and `core.plugin.tests.js`
("A Jasmine spy is a recording function value of the file") can name `test/support/jasmine.dart`.

## Open items

1. `test/specs/scale.radialLinear_test.dart` has a private `_anyFunction`, and
   `helpers.core_test.dart` and `helpers.config_test.dart` have a private `_Spy`
   (`jasmine.createSpy`). They are not in the U0 row. A later unit can move them to
   `test/support/jasmine.dart` (`anyFunction`; a `createSpy` is not in the library yet).
2. The themed compare of options reads only the upstream keys. If T-theme wants a check of the
   extra theme keys other than `expectNoStaleScaleKeys`, it needs a new rule.
3. `runStep` of `hover` and `mouseout` expects a throw only when `triggerMouseEvent` throws. An
   error in the frame callback of the event goes to flutter_test as an uncaught exception, not to
   the `error` key.
4. The data size of the controller files (ADR 0030 Open 4): with the JSON lines of the hits, the
   6 probe cases (about 21 observations of charts with 1 to 3 datasets of 1 to 6 points) took
   674,407 bytes, about 32 KB for each observation. Each step adds one observation. A unit with
   many step cases can pass 2.5 MB and then writes the second file.
5. `parity:check` fails on `controller.bar.dart` of U-bar until W1-int updates `doc/status.yaml`
   and runs `parity`.

## Fixes

The fixes of the findings of `U0-review.md`. All 7 findings are "confirmed". The paths are
relative to `packages/flutter_chartjs/`. The probes of the fixer are in
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave1/U0/`:
`fix-mirror/` (a mirror tree of `tool/reference/` with the changed generator code and the probe
generators of the review) and `fix-probe/` (a copy of the probe package of the review; its tests
import the harness files of the repository).

| Finding | Fix |
|---|---|
| R1 (high): no rule for `adapt-bar-clip` | Fixed in `test/port/scales/scale_chart_harness.dart`. `expectCalls` removes reference calls before the compare (`_barClipsToRemove`, `_evenOddFills`). The k-th `fill('evenodd')` of the reference pairs with the k-th of the recorded calls. A reference fill is a bar ring when the calls since its `beginPath` are path calls (`rect`, `moveTo`, `lineTo`, `arc`, `closePath`), at most one `clip`, then one `setFillStyle` (`element.bar.js:186-192`). When the reference ring has a `clip` and the recorded ring has none, that `clip` goes. When the counts differ, nothing goes. The path arguments still compare: an upstream amount that is not 0 moves the outer path (`inflateRect`, `element.bar.js:127-139`), so a port bar with the amount 0 in its place fails at a path argument. The generator does not change. The library doc names the rule. New group `expectCalls: adapt-bar-clip` in `scale_chart_harness_test.dart` (6 cases): the removal; a `clip` that the port also calls stays; an inflated reference outer path fails; a `clip` outside a ring (the `clipArea` form) stays; different ring counts remove nothing; a real `BarElement` with the amount 0 pairs with its upstream form. The review probes `p4_bar_border_test.dart` and `p3_bar_e2e_test.dart` (the `default` case with the `NaN` width) now pass: `+10`, all passed. |
| R2 (low): a long probe line fails `analyze` | Fixed in `tool/reference/scale_chart_common.mjs`. `writeReference` stops with an error when a note line `// <line>` has more than 80 characters, and names the line. The doc of `writeControllerReference` (`controller_chart_common.mjs`) gives the limit for a probe line (75 characters). The review probe `probe_notes.mjs` now stops: "The note line ... has 106 characters. A comment line of a data file has at most 80 ...". The phase 6 output does not change (no notes): the 8 generators, run again in `fix-mirror/`, give the same SHA-256 for the 8 files as the tree. |
| R3 (low): the themed run skips the `defaults` check after an error | Fixed in `test/port/controllers/controller_chart_harness.dart`. `_runControllerCase` takes the snapshot of `defaults`, calls the new `_runCaseSteps` (the old body, with its early returns at an expected error), and then compares `defaults`. Thus the check runs after each end of a themed case, also after an error at `initial`, at a step or at `draw`. The review probe `p1_themed_error_defaults_test.dart` now fails at "defaults after the themed case", as it must (the control test passes). No self-test was added: the function is private, and a failed case cannot run inside a passing test. |
| R4 (low): wrong citation for `datasets: [null]` | Fixed in `test/port/controllers/controller_chart_harness_test.dart`: the comment now names `mergeScaleConfig` of `initConfig` (`core.config.js:94`, `dataset.type`), on both sides. |
| R5 (low): wrong line range for `linkScales` | Fixed in `test/port/controllers/controller_chart_harness.dart`: `core.datasetController.js:306-308`. |
| R6 (low): `hits.items` as text differs from ADR 0030 §3 item 6 | Not changed in the data form. Reason: the fix needs a decision record of the phase lead, and an ADR is not a file of U0. The ADR form (a Dart literal) breaks the other rule of the same item: at most two data files of 2.5 MB. With the figures of the report (3 cases: 1,521,132 bytes with the literal, 495,325 bytes with the text), the 23 bar cases of ADR 0030 §7 need about 11.7 MB with the literal and about 3.8 MB with the text (an estimate: the size of a case depends on its steps). Only the text form fits in 5 MB. Request to the phase lead: accept the text form of `hits.items` in a decision record (for example a note of ADR 0030 Open 4, or a new ADR). The comment of `hits` in `controller_chart_common.mjs` now names the difference and this request. The semantics do not change: the items compare exactly. |
| R7 (low): a draw spy does not follow a running animation | Fixed in `test/support/jasmine.dart`. `_copyProperties` throws a `StateError` when the original element has an active animation in `$animations`: the target of an `Animation` is final (`core.animation.dart` `_target`), so the spy cannot follow it. The docs of `spyOnElementDraw` and `spyOnDataset` state the limit: a spy needs `animation: false` (the default of `acquireChart`) or the end of the animations. The copy of `active` and `options` (ADR 0030 §13 item 5) and of the other properties (report deviation 7) stays: upstream `spyOn` keeps the same object, so the spy must have the same properties for a `callThrough` draw. New case in `controller_chart_harness_test.dart`: "a draw spy of an element with a running animation throws" (and a spy after the end of the animations takes the slot). The review probe `p7_spy_animations_test.dart` now throws the `StateError`. |

### Doc notes for W1-int (from the fixes)

- `doc/differences.md`, row `adapt-bar-clip`, tests column: add
  `test/port/scales/scale_chart_harness.dart` `expectCalls` and
  `scale_chart_harness_test.dart` group `expectCalls: adapt-bar-clip`.
- TS §1.3 (and `porting-flow.md` §3 with the TS §6 text): "`expectCalls` removes the reference
  `clip` of the border ring of each bar that the port draws without a `clip` (row
  `adapt-bar-clip`)."
- TS §1.7: "A draw spy of an element with a running animation throws a `StateError`."
- R6: the decision record of the phase lead.

### Checks of the fixes

| Command | Result |
|---|---|
| `flutter test` of `test/port/scales`, `test/port/controllers`, `test/port/elements/element.line_test.dart`, `test/specs/{core.controller,core.plugin,helpers.canvas,core.element,helpers.options}_test.dart` | +835 ~99, all passed (+828 before; 6 new cases of R1 and 1 of R7) |
| `dart analyze --fatal-infos` of `test/port/scales`, `test/port/controllers`, `test/support`, `test/port/canvas`, `test/port/elements/element.line_test.dart` | No issues |
| `dart format --set-exit-if-changed` of the changed Dart files | 0 changed |
| `node --check` of `scale_chart_common.mjs` and `controller_chart_common.mjs` | passed |
| the 8 phase 6 generators in `fix-mirror/` (x64 Node.js v24.12.0, the build at `7169e651`) | the same SHA-256 as the 8 files of the tree |
| the review probes in `fix-probe/` | `p4`, `p3`, `p5`, `p6`: passed; `p1`: fails at the `defaults` check (R3 fixed); `p7`: throws the `StateError` (R7 fixed); `probe_notes.mjs`: stops (R2 fixed) |
| `check:lib-imports`, `check:headers`, `check:js-semantics` | passed: 298, 335 and 116 files |

`test:cases` did not run again: the fixes change no file of `test/specs/`. No `flutter_tester`
process of the fixer stays. The process 67820 belongs to another session.
