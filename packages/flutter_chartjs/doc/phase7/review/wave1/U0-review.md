# Wave 1, unit U0 (test infrastructure): adversarial fidelity review

## Result

One finding of high severity (R1). The harness of U0 has no rule for the `DIVERGES` row
`adapt-bar-clip`. Thus each bar reference case with a border fails in `draw` when U-bar adds its
cases. The ADR 0030 §7 set of bar cases has such cases (`borderSkipped`, `borderRadius`,
`inflateAmount`). The phase lead must give the fix to an owner before U-bar adds its reference
tests.

The other six findings have low severity. Two findings are wrong citations (R4, R5). One finding
is a check that does not run on all paths (R3). One finding is a latent failure of `analyze` in
the data files of later units (R2). One finding is a deviation from the ADR that the report gives
only as a deviation from the spec (R6). One finding is a spy that does not follow a running
animation (R7).

The rest of the unit agrees with the ADR, the spec and upstream:

- The 8 phase 6 generators, run again in a mirror tree outside the repository (x64 Node.js
  v24.12.0, the build at `7169e651`), give 8 files that are byte-identical with the files of the
  tree. Thus the data is not edited by hand, and a rerun gives the same bytes.
- The targeted tests pass: `flutter test` of `test/port/scales`, `test/port/controllers`,
  `test/port/elements/element.line_test.dart` and the 5 changed spec files gives `+828 ~99`, as
  the report says.
- An end-to-end probe ran the JS side and the Dart side of the harness on real bar charts (the
  lib file of U-bar). 4 cases (with all 8 kinds of steps, stacks with `null` and `NaN`, floating
  bars, `indexAxis: 'y'`, the scale options), and a case with `hover` at a bar center, `mouseout`
  and a step that throws. Each observation (`chartArea`, `scales`, `stacks`, `datasets`, `hits`)
  agrees, unthemed and with the light preset. The only failure is the `clip` of R1.
- The moved Jasmine helpers keep their semantics. `jasmineEquals`, `objectContaining` and the
  spy of a function value are the private copies, with no change of a statement.
  `objectContaining` also accepts the `ElementProps` of `getProps`, the matcher of
  `core.element_test.dart` that it replaces.
- `drawCalls` (both sides), `dartCalls`, `jsonValue` with the `Path2D` branch, `recordedCalls`,
  `PathIds`, `replayPath`, `hitPoints`, `hitQueries`, `observeControllers`, `applyStep`,
  `runStep` and `testControllerChartCases` have the forms of TS §1.2-§1.7 and ADR 0030 §1-§6.
  The `Path2D` ids get their number before the commands on both sides.
- The headers of the new files are correct. The `dart()` raw strings are correct: a raw string
  is used only for a string with no control character and no quote of its kind.

All paths are relative to `packages/flutter_chartjs/`. The probes are in
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave1/U0-review/`
(below: `<review>`):

- `<review>/mirror/`: a copy of `tool/reference/` and `tool/port_sources.yaml` at the repository
  layout, with links to `third_party/` and to the test font. The generators write their data
  there, not in the repository. The probe generators are
  `<review>/mirror/packages/flutter_chartjs/tool/reference/probe_*.mjs`. Run each from
  `<review>/mirror/packages/flutter_chartjs` with
  `/usr/bin/arch -x86_64 <scratchpad>/env/node-v24.12.0-darwin-x64/bin/node tool/reference/<probe>.mjs <scratchpad>/env/chartjs-build/dist/chart.js`.
- `<review>/probe/`: a scratch Flutter package with path dependencies on `flutter_chartjs` and
  `chartjs_test_utils`. Its `test/flutter_test_config.dart` calls the `testExecutable` of the
  package. Its tests import the harness files of the repository by `file:` URIs. Run each with
  `flutter test test/<file>` from `<review>/probe`.

## Findings

### R1 (high, confirmed): the harness has no rule for `adapt-bar-clip`

`BarElement.draw` of the port does not call `ctx.clip()` when `inflateAmount` is 0
(`lib/src/elements/element.bar.dart:543-544`, `differences.md` `adapt-bar-clip`). Upstream calls
it when the outer and the inner rectangles differ (`element.bar.js:186-189`). The row says: "The
mock context records no `clip` call for a bar with the amount 0, and the tests remove `clip` from
the reference calls of such a bar." `RecordingContext`, `expectCalls` and `callMatchers` of
`test/port/scales/scale_chart_harness.dart` and `dartCalls` of
`tool/reference/scale_chart_common.mjs` have no such rule. The harness has the same kind of rule
for `adapt-rounded-rect-path` only (`replayRoundRectAsUpstream`).

Probe: `probe_bar_border.mjs` writes one case, a bar chart with `borderWidth: 2` (the amount
`'auto'` gives 0, `controller.bar.js:252-256`). `<review>/probe/test/p4_bar_border_test.dart`
runs it through `testControllerChartCases`. Result: all observations agree, and `draw` fails at
call 434: expected `{'name': 'clip', 'args': [null, null]}`, actual `rect`. The case `default` of
`probe_bar.mjs` fails at the same kind of call (a bar with a `NaN` width, call 394;
`p3_bar_e2e_test.dart`, `p3b_debug_test.dart`).

Effect: TS §2 says "A failed reference case is a defect of the port. Fix it in `lib/`. Never
change the generator to match the port." Thus U-bar has no permitted fix: the port form is a
recorded `adapt` row. Neither TS §1 nor ADR 0030 names the row. ADR 0030 Evidence E2 counted
the element calls on charts without a bar border.

Possible fixes (for the phase lead): a rule in the Dart compare that removes an expected `clip`
of a bar border ring when the port bar has the amount 0 (the rule of the
`element.bar_test.dart` group `adapt-bar-clip`), with a note in TS §1.3 and in the row. The
generator must not change.

### R2 (low, confirmed): a long probe body makes a data file that fails `analyze`

`writeControllerReference` (`tool/reference/controller_chart_common.mjs:576-592`) writes each
line of the source text of a probe as the comment line `//   <line>`, with no wrap. A probe line
of more than 75 characters gives a comment line of more than 80 characters. The lint
`lines_longer_than_80_chars` of `very_good_analysis` 10.3.0 then fails `analyze --fatal-infos`.
A data file must not be edited by hand. Thus the unit must change its probe body, and the Dart
function of the probe must change with it. Report deviation 1 shows the same lint on line 1 of
three files.

Probe: `probe_notes.mjs` writes one bar case with the probe
`(chart) => chart.getDatasetMeta(0).data.filter((element) => !element.hidden && element.active).length`.
Line 10 of the output has 106 characters. `dart analyze --fatal-infos` of a copy
(`<review>/probe/lib/probe_notes_reference.dart`, with `<review>/probe/analysis_options.yaml`
that enables the lint) gives
`probe_notes_reference.dart:10:81 - The line length exceeds the 80-character limit. - lines_longer_than_80_chars`.

Possible fix: the generator stops with a clear message for a note line of more than 80
characters, or the header gets `// ignore_for_file: lines_longer_than_80_chars` when it has
notes.

### R3 (low, confirmed): the themed run does not check `defaults` after a case with an `error`

ADR 0030 §8: "After each themed run, the test compares `defaults` with its state before the run."
TS §1.6 gives the same rule. `_runControllerCase` (`test/port/controllers/controller_chart_harness.dart`)
returns at `at == 'initial'`, at a step without observations and at `at == 'draw'` before the
`defaults` check at the end of the function. Thus a themed case with an `error` does not check
`defaults`. The pin cases (`parsed:`, `interfaces:`) do not run themed, so the gap affects only
an `error` case of the 89 cases.

Probe: `<review>/probe/test/p1_themed_error_defaults_test.dart`. An inline plugin writes
`defaults['u0ReviewProbe']` in `beforeUpdate`. Then `buildOrUpdateControllers` throws on an
unknown dataset type. The control test shows the write. The themed case with
`error: {at: 'initial', name: 'Error'}` passes: `+2`, all passed.

Possible fix: put the `defaults` check in a `try`/`finally` or before each `return`.

### R4 (low, confirmed): a wrong citation for the throw of `datasets: [null]`

`test/port/controllers/controller_chart_harness_test.dart:446-447`: "`datasets: [null]` throws a
TypeError at `buildOrUpdateControllers` (core.controller.js:416, `dataset.type`)." Line 416 is
`const newControllers = [];`. The throw is in `mergeScaleConfig` during `initConfig`, at
`core.config.js:94` (`const type = dataset.type || config.type;`), before the chart reaches
`buildOrUpdateControllers`.

Probe: `probe_error_site.mjs` gives the stack
`mergeScaleConfig (chart.js:5327)`, `initOptions`, `initConfig`. The Dart probe
`<review>/probe/test/p6_null_dataset_site_test.dart` gives `jsGet` from `_mergeScaleConfig`
(`core.config.dart:223`), `_initOptions`, `_initConfig`, `new Config`. Both sides throw at the
same place. Only the comment is wrong.

### R5 (low, confirmed): a wrong line range for `linkScales`

`test/port/controllers/controller_chart_harness.dart:306-308` cites
`core.datasetController.js:301-303` for "linkScales gives a scale id or JS `undefined`". At the
pin, lines 301-303 are the end of the constructor and `linkScales() {`. The writes of
`meta.xAxisID`, `meta.yAxisID` and `meta.rAxisID` are at `:306-308`
(`grep -n "meta.xAxisID = " src/core/core.datasetController.js` gives 306).

### R6 (low, confirmed): `hits.items` as text is a deviation from ADR 0030, not only from the spec

ADR 0030 §3 item 6: "The data format is the phase 6 form: Dart `const` literals, and one raw
JSON-lines string of the draw calls for each case." U0 writes `hits.items` of each observation as
a second raw JSON-lines string (`hits` of `controller_chart_common.mjs`, `hitItems` of the Dart
harness). The report gives this as deviation 2 "from the spec". Where the plan or a spec and an
ADR differ, the ADR wins. Thus the phase lead must accept the change in a decision record (for
example a new ADR, or the note of Open 4 that the report proposes). The semantics do not change:
the items compare exactly. The size figures of the report (1.52 MB against 0.50 MB for 3 cases)
support the change.

Probe: the probe outputs `<review>/probe/test/probe_bar_hover_reference.dart:336` and `:624`
have `'items': '''`.

### R7 (low, confirmed): a draw spy does not follow a running animation

ADR 0030 §13 item 5: "The spy copies `active` and `options` of the original element." The spies
of `test/support/jasmine.dart` (`_copyProperties`) also copy `hidden`, `x`, `y`, `$animations`
and the properties of the class (report deviation 7). The copy of `$animations` gives the spy the
`Animation` objects of the old element. Their target stays the old element. Upstream, `spyOn`
keeps the same object, so the animation moves it. The specs of the 7 controller files run with
the default `animation: false` of `acquireChart`. Thus no known spec is affected.

Probe: `<review>/probe/test/p7_spy_animations_test.dart`. A chart with `animation.duration: 500`
starts an animation with a data change and `update()`. After 16 ms, `spyOnElementDraw(meta, 1)`
takes the slot. After 60 more frames: the old element has `y = 483.6` (the final value), and the
spy has `y = 318.9` (the value at the time of the spy).

Possible fix: copy `active` and `options` only, as the ADR says, and state in the doc comment
that a spy needs `animation: false`. Or record the limit in TS §1.7.

## Checks that found no defect

1. The `///` citations of the new code against the pin: `core.datasetController.js:257`,
   `:386-388`, `:712-741`; `core.controller.js:357-362`; `helpers.dom.ts:105-111` and `:109-111`;
   `element.line.js:233`; `line_reference.mjs:96-105`; `pnpm-lock.yaml:9733`. All are correct,
   except R4 and R5. `core.element.ts:39` points into `getProps` (the method starts at `:33`).
2. ADR 0010 forms: `null` against `undefined` in `xAxisID`, `yAxisID`, `total`, `_drawStart`,
   `_drawCount`, `hidden` and `datasetOptions` (an absent key stays absent on both sides);
   `jasmineEquals` keeps NaN equal to NaN and 0 different from -0; key order through
   `jsObjectKeys` (the stacks keys, also in order); `jsSplice` with `ToIntegerOrInfinity`; the
   `push` and `splice` steps change the List first and then notify (`platform-array-events`).
3. The hit queries: the event `{type: 'mousemove', native: null, x, y}` on both sides, the points
   and the queries of the generator, the items compared exactly.
4. The tests of TS §1.8 rows 2-5 exist and pin what they claim. The self-test of
   `expectControllerObservations` compares an observation with itself. Thus it shows the key
   rules and the failures, not the agreement with the generator. The end-to-end probe above
   covers that agreement on bar charts.
5. No `flutter_tester` process of this review stays. The process 67820 belongs to another
   session.
