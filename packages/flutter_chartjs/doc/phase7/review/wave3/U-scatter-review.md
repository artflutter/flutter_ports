# Wave 3, unit U-scatter: adversarial fidelity review

## Scope

All paths are relative to `packages/flutter_chartjs/`. `<r>` is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave3/U-scatter-review`.

The review examined the five new files of the unit:

- `lib/src/controllers/controller.scatter.dart`
- `tool/reference/controller_scatter_reference.mjs`
- `test/port/controllers/controller_scatter_reference.dart` (generated)
- `test/port/controllers/controller.scatter_test.dart`
- `test/specs/controller.scatter_test.dart`

It compared each ported statement with `third_party/Chart.js/src/controllers/controller.scatter.js`
at the pin `7169e651`, and each decision with Chart.js ADRs 0027, 0028 and 0030, PD §5.3 and §7.3,
IV §4.1-§4.3 and §7.3, TS §2 and the decisions D10-D12.

## Result

| # | Severity | Verdict | Subject |
|---|---|---|---|
| 1 | medium | confirmed | No test pins the override `interaction.mode: 'point'` (`scatter.js:25-27`) |
| 2 | low | confirmed | The probe of the group `showLine` is only in a scratch folder |

The port of `controller.scatter.js` has no behavior difference that the review found. Finding 1
is a gap in the tests, not in the library.

## Findings

### 1. No test pins the override `interaction.mode: 'point'` (medium, confirmed)

**Upstream.** `controller.scatter.js:23-37` `static overrides` sets `interaction.mode` to
`'point'` for each scatter chart. The chart uses this mode for the hover
(`core.controller.js` `_handleEvent` with `getElementsAtEventForMode(e, hoverOptions.mode, ...)`).
Thus the override selects the active elements. Chart.js ADR 0009 protects the hit element.

**Tests.** The hit queries of `controller_chart_common.mjs` (`hitQueries`, Chart.js ADR 0030 §5)
give each mode explicitly. They do not read `chart.options.interaction.mode`. The generator has no
`hover` step for scatter, and the observations do not include the chart options. The two spec
cases that read the hover (`controller.scatter.tests.js:8`, `:146`) skip as
`blocked: plugin.tooltip`. Thus no test of the unit fails when the override is not there.

**Probe.**

- `<r>/probe_hover.mjs` (x64 Node.js v24.12.0, the build at the pin, output
  `<r>/probe_hover.out`): two datasets with near points at `(1, 1)` and `(1.03, 1)` (1.3 px apart),
  `x` and `y` from 0 to 10, a `mousemove` at the center of point 0 of dataset 0. With the override
  (mode `point`), the active elements are `[[0, 0], [1, 0]]`. With the mode `nearest`, they are
  `[[0, 0]]`.
- `<r>/interaction_probe_test.dart` (`flutter test` from `packages/flutter_chartjs`, output
  `<r>/interaction_probe.out`). It runs `main()` of both test files of the unit and a hover test
  with the same chart. Without `MUTATE`, all 41 tests pass: the port gives `[[0, 0], [1, 0]]`, as
  upstream. With `MUTATE=1`, the probe removes `interaction` from `ScatterController.overrides`
  before the registration. Then all 36 tests of `controller.scatter_test.dart` and the 4 cases of
  the spec still pass. Only the probe hover test fails: the port gives `[[0, 0]]`.

**Fix (proposal).** Add one test to the group `interfaces` of `controller.scatter_test.dart`: the
chart of the probe, `triggerMouseEvent` at the center of point 0 of dataset 0, and the active
elements `[[0, 0], [1, 0]]` from `probe_hover.out`. Alternatively, add a step `['hover', x, y]`
to a scatter case of the generator. The observations then record the active elements. Chart.js
ADR 0030 §7 does not list a hover step for scatter, so the test in the group `interfaces` is the
smaller change.

### 2. The probe of the group `showLine` is only in a scratch folder (low, confirmed)

**Location.** `test/port/controllers/controller.scatter_test.dart:335-340` says that the expected
values of the group `showLine` come from the probe `probe_showline.mjs` "recorded in
phase7/review/wave3/U-scatter-report.md, with its output `probe_showline.out`".

**Fact.** The report gives only a summary of the results and the path of the probe in the
scratch folder of the session (`.../scratchpad/wave3/U-scatter/probe/`). The probe source and its
output are not in the repository (`grep -rn probe_showline test doc` finds only the test comment
and the report). A scratch folder does not stay after a restart. Thus the source of the pinned
values (the `LineElement` state, the new element after each switch on, `getMaxOverflow()` 8 and
5) cannot be run again from the repository.

**Probe.** `ls <scratchpad>/wave3/U-scatter/probe/` shows `probe_showline.mjs` and
`probe_showline.out`. `find doc/phase7 -name 'probe_showline*'` finds nothing. The values in the
test agree with `probe_showline.out` (A0-A3, B1, C0-C1).

**Fix (proposal).** W3-int puts `probe_showline.mjs` and `probe_showline.out` into
`doc/phase7/review/wave3/` (or adds an option-write step to `controller_chart_common.mjs`, report
open item 6), and the test comment names that path.

## Checks with no finding

- Each statement of `controller.scatter.js:6-179` has a Dart statement in the same order:
  `getLabelAndValue` (`:42-54`), `update` (`:56-99`, with the switch of `:71-95` and
  `delete meta.dataset` as Dart `null`), `addElements` (`:101-109`), `updateElements`
  (`:111-151`) and `getMaxOverflow` (`:156-178`, both branches). The defaults and overrides agree
  key for key.
- D10: `vValue` and `iValue` live only inside one pass. `prevParsed[iAxis]` (`:133`) is a read at
  each pass. `prevParsed` itself is the upstream local. The pin case `parsed: a scriptable option
  writes ctx.parsed` has `stop` true at point 2 in the reference data, as the generator comment
  says.
- JS forms: `start > 0 && getParsed(start - 1)` as `false` or the item; `isNumber(spanGaps)` with
  one `ToNumber` (the only use is the `>`); `sharedOptions ?? ...` for `sharedOptions || ...`
  (`getSharedOptions` gives `undefined` or an object); `max > 0 && max` gives `false` for 0 and
  NaN; `dataset.options && dataset.options.borderWidth || 0` keeps the raw value; `Math.max`
  applies `ToNumber` to `border`; `labels[index] || ''`; the `+` of the value through
  `jsToString`.
- Upstream scatter has no `initialize` and no `draw`. The port has neither, so
  `enableOptionSharing` stays false and the loop calls `getSharedOptions`, not
  `getSharedOptions_`. The base `draw` of `core.datasetController.dart` does not require a chart
  area.
- `meta.dataset` is JS `null` at the creation and `undefined` after `delete` (probe_showline.out,
  A0 against A2). The port has Dart `null` for both. The upstream readers
  (`core.datasetController.js:724`, `helpers.extras.ts:96`, the filler) test only truthiness, or
  throw for both values. No difference that ADR 0009 protects.
- The work plan row says that `controller.scatter.dart` imports `controller.line.dart`. Upstream
  `controller.scatter.js:1-4` does not import `controller.line.js`. The unit is correct (porting
  rule 2, IV §4.1 rule 1).
- The `DIVERGES(chartjs): adapt-chart-registry-getter` marker has its row in `differences.md`,
  which names `ScatterController.addElements`.
- The citations of the library, the generator and the tests agree with the pinned lines
  (`scatter.js`, `index.umd.ts:28` and `:35`, `canvas_ui_path.dart:469`).
- The spec port: the 6 names and the order agree with upstream. The verdicts agree with
  `all.json` (4 `phase7` with bodies that pass, 2 `blocked: plugin.tooltip`). No skipped case has
  the verdict `phase7`.
- The case list: the first 6 names are the ADR 0030 §7 row `scatter`, `default` has
  `scaleOptions: true`, and the themed run skips the `parsed:` and `interfaces:` cases
  (`controller_chart_harness.dart:823`). The PD §7.3 rows (null item, logarithmic x, one-read
  rule) and the IV §7.3 rows (`line.points` after update, push and splice; the labels) have
  tests.
- The generator run in `<r>/gen.mjs` (a copy that writes to `<r>/out_scatter.dart`) on the x64
  Node.js gives the committed data. The only difference is the generator path on line 3.
- `flutter test` of both test files: +40 ~2, all passed. No `flutter_tester` process of this
  review is left. The process 67820 belongs to another session; the review did not stop it.
