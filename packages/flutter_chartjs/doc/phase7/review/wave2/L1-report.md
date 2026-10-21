# Wave 2, unit L1 (the lift of wave 1): report

## Status

Done. The 60 records of the wave 1 lift list have bodies, and each one passes. The lift check
for wave 1 is green: 122 of 122 records pass, 0 fail, 0 count differences.

L1 changed only spec files of its row (work plan §2). L1 changed no `lib/` file, no harness file
and no shared doc. No lifted case failed. Thus L1 found no defect in a `lib/` file of another
unit or of wave 1, and L1 added no skip.

The unit runs in parallel with the other units of wave 2. Thus the full gate did not run. W2-int
runs it.

## Files that changed

The paths are relative to `packages/flutter_chartjs/`.

| File | Change |
|---|---|
| `test/specs/core.animator_test.dart` | 1 case lifted (`:2`): a `testWidgets` case with `waitForDone`, `acquireChart`, a plugin Map with `afterDraw` and the `onProgress` and `onComplete` options. |
| `test/specs/helpers.dom_test.dart` | 2 cases lifted (`:427`, `:455`): `testWidgets` cases with `onHover` and `triggerMouseEvent`. New helper `_point` (the object `{x, y}` of a `Point` for `toEqual`). Imports `core.controller.dart`, `types/geometric.dart` and `../support/jasmine.dart`. |
| `test/specs/core.datasetController_test.dart` | Moved as a whole to `@TestOn('vm')`, `flutter_test` and `package:chartjs_test_utils/flutter.dart`, without `setUpSpecs()` (TS §4.2, Chart.js ADR 0030 §12 item 5). 3 cases lifted (`:43`, `:753`, `:797`). New helper `_dataset`. `chart._stacks` is `chart.stacks`, with the `ToString` keys of the index values. |
| `test/specs/core.layouts_test.dart` | Moved as a whole to `@TestOn('vm')`, `flutter_test` and `package:chartjs_test_utils/flutter.dart`, without `setUpSpecs()`. 5 cases lifted (`:243`, `:286`, `:334`, `:418`, `:544`). New helper `_getLabels` (`:1-3`). |
| `test/specs/scale.category_test.dart` | 2 cases lifted (`:443`, `:514`). The case of `:514` kept its body: it became a `testWidgets` case. The header comment of the two raw-label cases changed. |
| `test/specs/scale.linear_test.dart` | 25 cases lifted. New helpers `_getLabels` (`:1-3`), `_dataset`, `_optionsY` (the resolver `chart.options.scales.y`, or one key of it) and `_toBeCloseTo` (Jasmine 3.99.1 `toBeCloseTo`). New spec-form notes in the header comment. |
| `test/specs/scale.logarithmic_test.dart` | 21 cases lifted (13 single cases and the 8 cases of the first `when` group, `:755-904`). The first `when` group now keeps the shared `data`, `dataWithEmptyStacks` and `config` of upstream in its closure. The constant `_stackSetups` is removed. New helpers `_getLabels`, `_dataset`, `_chartScaleOptions`, `_side` and `_toBeCloseTo`. New spec-form notes in the header comment. |
| `test/specs/scale.time_test.dart` | 1 case lifted (`:1125`, 83 data points, copied from the upstream line by a script). Imports `toBeCloseToPixel` from `package:chartjs_test_utils/pure.dart`. |
| `doc/phase7/review/wave2/L1-report.md` (new) | This report. |

## Tests that L1 added

The 60 records of the lift list, each with its upstream name, character for character:

- `core.animator` 1, `helpers.dom` 2, `core.datasetController` 3, `core.layouts` 5,
  `scale.category` 2, `scale.linear` 25, `scale.logarithmic` 21, `scale.time` 1.
- Each one is a `testWidgets` case that calls `acquireChart` in its body.
- No assertion, config, tolerance or name changed. Changes of form only:
  - `expect(fn).not.toThrow()` is `expect(fn, returnsNormally)`.
  - `not.toEqual(undefined)` of a scale is `isNotNull`.
  - `toEqual` of an object or an array is `jasmineEquals`.
  - `index.toString()` in a tick callback is `jsToString(index)`.
  - A write into `chart.scales.y.options` or into a chain of `chart.options` writes through the
    resolver of the last read.
  - `scale.start` and `scale.end` are read on `LinearScaleBase` and `LogarithmicScale`.
  - `getDatasetMeta(index)` in the `forEach` of `scale.linear.tests.js:1199` takes
    `index.toDouble()`.

## Checks

The scratch folder is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave2/L1/`.

| Command (from `packages/flutter_chartjs` unless noted) | Result |
|---|---|
| `dart format` on the 8 spec files | 0 changed after the last edit |
| `dart analyze --fatal-infos` on the 8 spec files | No issues |
| `flutter test` on the 8 spec files | +89 ~200, all passed |
| `flutter test --reporter json test/specs test/port > <scratch>/run1.json` | exit 0; 5419 passed, 425 skipped, 0 failed |
| `python3 -I doc/phase7/tools/lift_check.py doc/phase7/classification/all.json <scratch>/run1.json 1 --list` | exit 0. Counts `phase7` 503, legend 21, tooltip 11, filler 1 (as `summary.md` §2 with D1). Wave 1 and earlier: 122 records, 122 pass, 0 fail, 0 count differences. Lift list of wave 1: 0 records |
| `dart run melos run test:cases` (repository root) | passed, 39 files, 0 errors, 0 warnings. Total 1036: 505 passed, 0 failed, 357 skipped, 174 missing (the controller spec files of the other wave 2 units, which are not complete yet, and the files without Dart tests). The 8 files: `core.animator` 2/2 passed; `core.datasetController` 3 passed, 40 skipped; `core.layouts` 6 passed, 6 skipped; `helpers.dom` 9 passed, 13 skipped; `scale.category` 4 passed, 15 skipped; `scale.linear` 32 passed, 13 skipped; `scale.logarithmic` 23 passed, 37 skipped; `scale.time` 10 passed, 76 skipped |
| `dart run melos run check:lib-imports` | passed, 316 files |
| `dart run melos run check:headers` | passed, 353 files |
| `dart run melos run check:js-semantics` | passed, 125 files |
| `dart run melos run port:next:check` | passed, 202 files |
| `dart run melos run parity:check` | failed, as expected before W2-int: `doc/parity.md` differs from tool 6 in 16 lines. 8 lines are the spec rows of L1 (the derived counts change). The other lines and the 1 error of `status.yaml` come from the controller units (`controller.bubble.js` needs `{{differences}}`, new Dart targets) and from A1 (`core.animator.js`, `harness-method-fields`). L1 did not change `status.yaml` or `parity.md` (work plan §0 item 2) |

`test:web` did not run (a parallel unit runs only its targeted tests). The two moved files now
have `@TestOn('vm')`, so `dart test -p chrome` does not compile them. L1 added no file to the web
legs.

No `flutter_tester` process of L1 is left. The process 67820 belongs to another session
(scratchpad `ec6419b7-...`). L1 did not start it and did not stop it.

## Doc notes for W2-int

### `doc/status.yaml`

Replace the texts of the 8 spec rows. Then run `dart run melos run parity`. TS §6: the moved files
do not have `on {{platforms}}`.

- `test/specs/core.animator.tests.js`:
  `"ported ({{passed}}/{{cases}} cases pass on {{platforms}}. The case of :2 is a `testWidgets` case with `acquireChart` and `waitForDone` ([Chart.js ADR 0022](adr/0022-chart-test-harness.md) §7))"`
- `test/specs/core.datasetController.tests.js`:
  `"ported ({{passed}}/{{cases}} cases pass; {{skipped:blocked|case}} skipped: {{skipped:blocked: controller.line}} `blocked: controller.line`, {{skipped:blocked: controller.scatter}} `blocked: controller.scatter` and {{skipped:blocked: controller.radar}} `blocked: controller.radar`. Each case builds a chart with a controller of phase 7 and the scales of phase 6. The cases that pass are `testWidgets` cases with a bar chart, and the file runs on the VM only ([Chart.js ADR 0030](adr/0030-controller-test-strategy.md) §12 item 5). The fixture group `auto` waits for phase 7. `test/port/core/core.datasetController_test.dart` covers the controller, also on the web legs)"`
- `test/specs/core.layouts.tests.js`:
  `"ported ({{passed}}/{{cases}} cases pass; {{skipped:blocked|case}} skipped: `blocked: plugin.legend`. The 5 bar chart cases are `testWidgets` cases with `acquireChart`, and the file runs on the VM only ([Chart.js ADR 0030](adr/0030-controller-test-strategy.md) §12 item 5). The fixture group `auto` waits for phase 7. `test/port/core/core.layouts_test.dart` covers the layout, also on the web legs)"`
- `test/specs/helpers.dom.tests.js`: remove
  `{{skipped:blocked: controller.bar|case}} skipped, `blocked: controller.bar`: they build a bar chart; `.
  Replace "because the 2 `retinaScale` cases are `testWidgets` cases" with "because the 2
  `retinaScale` cases and the 2 bar chart cases of `getRelativePosition` are `testWidgets`
  cases".
- `test/specs/scale.category.tests.js`: the skip list becomes
  `{{skipped:blocked: controller.line}} `blocked: controller.line` and {{skipped:blocked: plugin.legend}} `blocked: plugin.legend``.
  Replace "The 2 cases that pass have no chart. The skipped cases at :222 and :514 keep their
  ported bodies, with the raw label values of `getPixelForValue` (...). Phase 7 makes them
  `testWidgets` cases." with "2 cases that pass have no chart. The other 2 are `testWidgets`
  cases with a bar chart. The cases at :222 and :514 give the raw label values to
  `getPixelForValue` ([Chart.js ADR 0025](adr/0025-scale-value-parameters.md)). The case at
  :514 passes. The case at :222 keeps its ported body and waits for `controller.line`."
- `test/specs/scale.linear.tests.js`: the skip list becomes
  `{{skipped:blocked: controller.line}} `blocked: controller.line` and {{skipped:blocked: plugin.legend}} `blocked: plugin.legend``.
  Replace "The other 5 build a chart without datasets: they are `testWidgets` cases with
  `acquireChart`" with "The other 30 are `testWidgets` cases with `acquireChart`: 25 bar
  charts with datasets and 5 charts without datasets".
- `test/specs/scale.logarithmic.tests.js`: the skip list becomes
  `{{skipped:blocked: controller.line}} `blocked: controller.line``. Replace "The 2 cases that
  pass have no chart." with "2 cases that pass have no chart. The other 21 are `testWidgets`
  cases with a bar chart."
- `test/specs/scale.time.tests.js`: remove
  ` and {{skipped:blocked: controller.bar}} `blocked: controller.bar`` (put "and" before the
  `plugin.legend` item). Replace "The other 6 are `testWidgets` cases" with "The other 7 are
  `testWidgets` cases".

### `doc/porting-flow.md`

§5, the phase 7 row (result of wave 2): "L1 lifted the 60 records of wave 1 outside
`controller.bar_test.dart`: `core.animator` 1, `core.datasetController` 3, `core.layouts` 5,
`helpers.dom` 2, `scale.category` 2, `scale.linear` 25, `scale.logarithmic` 21, `scale.time` 1.
Each passes in the first run, with no change in `lib/`. `core.datasetController_test.dart` and
`core.layouts_test.dart` moved to the VM. 1 pure case lost the web legs: `core.layouts` "should
be exposed through Chart.layouts". `core.datasetController_test.dart` had no pure case that
ran."

### `AGENTS.md`

No change is necessary. The Tests bullet "A pure-layer spec file that gets a chart case moves to
`@TestOn('vm')` and `flutter_test` as a whole" already covers the two moved files.

### `doc/performance.md`, `doc/differences.md`, `doc/upstream-ledger.md`

No change. L1 adds no difference, no `DIVERGES` marker and no performance figure.

## Open items

1. Three spec files now have a private Jasmine `toBeCloseTo`: `element.arc_test.dart`
   (`closeTo` with half a unit), and `scale.linear_test.dart` and `scale.logarithmic_test.dart`
   (the exact Jasmine 3.99.1 rule with `Math.round`). L2 and L3 will need it again
   (`scale.logarithmic` `when` groups 2 and 3, `scale.radialLinear`). A later unit that owns
   `test/support/jasmine.dart` can move one copy there and remove the others.
2. The 8 `status.yaml` texts and `parity.md` (above) are for W2-int.
3. L2 starts after W2-int: the lift list of wave 2 (work plan §2, row L2).

## Fixes

The review (`L1-review.md`) found no defect. It recorded three observations with the verdict
"confirmed". The fixer did these steps:

| Finding | Fix or reason for no fix |
|---|---|
| O1: `core.interaction_test.dart:133` and `:167` skip with `blocked: controller.bar` | No fix. The file is in the row of L2, not L1 (work plan §2). The two cases must still skip, because their records also need `controller.line`. L2 lifts them. W2-int keeps `{{skipped:blocked: controller.bar}}` in the `status.yaml` text of `core.interaction.tests.js` until L2. |
| O2: `expect(x2).toEqual(x3)` of `scale.category.tests.js:534` is `expect(x2, x3)` | Fixed. `test/specs/scale.category_test.dart` now has `expect(x2, jasmineEquals(x3))`, with the import of `../support/jasmine.dart` and a line in the notes of the spec forms. Thus `0` and `-0` are different, as in Jasmine `eq`. The result of the case does not change. |
| O3: the pixel cases give a `double` where upstream gives an integer literal | Fixed. `test/specs/scale.linear_test.dart` (`scale.linear.tests.js:1311-1312` and `:1351-1352`): `const min = -30; const max = 40;`. `test/specs/scale.logarithmic_test.dart` (the first `when` group): `firstTick` is `setup['firstTick']! as num`, without `toDouble()`, and `lastTick` is `80`. Thus the cases give `getPixelForValue` an `int` where upstream has an integer literal, and a `double` for `0.1`. The VM runs the general path and the port-only `value is double` path (Chart.js ADR 0025). `_toBeCloseTo` of both files now takes a `num`, as Jasmine `toBeCloseTo` takes any number. It gives the `double` of `delta * pow` to `jsRound`. |

### Check results of the fixes

| Check | Result |
|---|---|
| `dart format` on the 3 changed files | 0 changed after the last edit |
| `dart analyze --fatal-infos` on the 3 changed files | No issues found |
| `flutter test` on the 8 spec files of the row | exit 0. +89 ~200, the same counts as the review run |
| `check:js-semantics` | passed, 128 files, 0 errors |
| `check:headers` | passed, 359 files, 0 errors |
| `check:lib-imports` | passed, 322 files, 0 errors |

The fixes changed no `lib/` file, added no skip and changed no line 1. No `flutter_tester` process
of the fixer is left.
