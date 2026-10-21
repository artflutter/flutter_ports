# Wave 1, unit W1-int (integration): report

## Status

Done. All gates are green. `lib/src/controllers/index.dart` exports `BarController`, and the
namespace `controllers` of `lib/src/index.dart` has it. Thus `flutter_test_config.dart` registers
the bar controller with the built-in components, and the two temporary `Chart.register` lines of
the U-bar test files are gone. The shared docs have the doc notes of S1, S2, S3, U0 and U-bar
(also the notes of their fixes). No test changed its result when the bar controller became a
built-in component.

All paths are relative to `packages/flutter_chartjs/`, except where a path starts with `apps/`,
`AGENTS.md` or `REUSE.toml`. The logs are in
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave1/W1-int/`.

## Files that W1-int changed

| File | Change |
|---|---|
| `lib/src/controllers/index.dart` (new) | The port of `src/controllers/index.js` for wave 1 (IV §5.1): the line `index.js:1` and `export ... show BarController`. The library doc says that the other seven lines come with waves 2 and 3. |
| `lib/src/index.dart` | IV §5.2: the import of `controller.bar.dart`, `export 'package:flutter_chartjs/src/controllers/index.dart'` before the `core` export, the entry `'BarController': BarController.jsClass` in `controllers`, and the `///` text of the library and of the Map. `registerables` does not change. |
| `test/port/index_test.dart` | IV §7.4 for `bar`: the test "the namespace controllers has the export names in code unit order" (the keys, `same` the class value, the Map is unmodifiable); the test "the namespaces of later phases are empty" keeps only `plugins`; after `Registry()..add(registerables)`, the keys of `registry.controllers.items`, of `defaults.datasets` and of `Chart.overrides` are `['bar']`. The file comment names the new state. |
| `test/port/controllers/controller.bar_test.dart` | The line `Chart.register([BarController.jsClass]);` and its import are gone. The file comment says that `flutter_test_config.dart` registers the controller. |
| `test/specs/controller.bar_test.dart` | The same line is gone. The import stays (the spec casts to `BarController`). The file comment names `index.umd.ts:28`. |
| `doc/phase7/tools/lift_check.py` (new) | The check of TS §4.1 (see "Lift check"). |
| `AGENTS.md` | The ADR list 0001-0031 (0027-0031 proposed); the JS runtime list (`jsGetKey`, `jsGetIndex`, `jsSetIndex`, `jsLessThan`, the `DateTime` text of `jsToString`); the layout items of `core.datasetController.dart`, `core.controller.dart`, `lib/src/index.dart`, the elements and types, the new item `lib/src/controllers/`, and `test/port/controllers/`, `test/port/canvas/path2d_record.dart`, `test/support/jasmine.dart`; the test notes (the element draws in `drawCalls`, the `adapt-bar-clip` rule of `expectCalls`, the controller reference tests, the temporary registration of a controller unit, the spy bullet, Jasmine `this`, the controller generators and their 80-character comment limit, the moment packages of the bar generator). |
| `doc/porting-flow.md` | §1.1: the one-read line (PD §8.2). §2: the paragraph of phase 7, the table rows of Chart.js ADRs 0027, 0028 and 0030, and the sections §2.20, §2.21 and §2.23. §3: the paragraph "Reference tests of the controllers" (TS §6 and the U0 notes). §5: the result of wave 1 in the phase 7 row. |
| `doc/performance.md` | §11.2, §11.3 and §11.8 item 2: one line each that points to section 13. New section 13 with §13.1 (the judge table, the index read table, P-B4, the `stacksOf` figures of S3, the `_strictEquals` figures of U-bar), §13.2 (question 3, `points_copy`, P-B7, question 1), §13.4 (ADR 0030 Evidence E3, the data sizes, Open 3) and §13.7 (the open list). §13.3, §13.5 and §13.6 stay for F-int, G-U5 and step 7. |
| `doc/differences.md` | `platform-array-events`: `jsSetIndex` in the code column and its text (S1, also the negative index). `js-semantics-resolver-objects`: `stacksOf` in the code column, the text of PD §8.4 with the S3-R1 correction, and the chart test group. `adapt-line-points-elements`: the text of IV §8.4 and the S2 notes (`getStartAndCountOfVisiblePoints`, the copy, the `TypeError`, the `ArgumentError` of `points` and `_points`). `adapt-bar-clip`: the harness rule of the U0 fix R1 in the tests column. No new row, no new marker. |
| `doc/status.yaml` | New rows `src/controllers/controller.bar.js` (ported), `src/controllers/index.js` (partial: `BarController`), `test/specs/controller.bar.tests.js` (ported). New text in `src/core/core.controller.js`, `src/core/core.datasetController.js`, `src/elements/element.line.js`, `src/types/index.d.ts` (IV §8.5), `src/index.ts`, `test/specs/core.controller.tests.js` and `test/specs/core.plugin.tests.js`. New port-only rows for the 9 files of the parity warnings and the two generators. New text in the port-only rows of `js_array.dart`, `js_number.dart`, `js_object.dart`, `test/port/index_test.dart`, `scale_chart_harness.dart`, `scale_chart_harness_test.dart`, `scale_chart_common.mjs`, `core.datasetController_test.dart` and `core.datasetController_chart_test.dart`. |
| `doc/parity.md` | Written by `dart run melos run parity` (tool 6). |
| `doc/phase7/review/wave1/W1-int-report.md` (new) | This report. |

Cross-file errors: none. The registration of the bar controller as a built-in component made no
test fail. The id check of IV §5.3 found no test or gallery controller with the id of a built-in
controller.

## Gates

| Command | Result |
|---|---|
| `dart run melos run format:check` | 379 files, 0 changed |
| `dart run melos run analyze` | No issues (covers `apps/chartjs_gallery`) |
| `dart run melos run test --no-select` | All passed: chartjs_gallery +95; chartjs_test_utils +139; flutter_chartjs +5543 ~478; flutter_d3_port +38 |
| `dart run melos run test:web` | All passed: flutter_chartjs +6958 ~206; chartjs_test_utils +98 |
| `dart run melos run test:cases` | passed, 38 files, 0 errors, 0 warnings. Total 1036 cases: 434 passed, 0 failed, 415 skipped, 187 missing (the missing cases are in the 6 controller spec files of waves 2 and 3 and in the files without Dart tests). `controller.bar.tests.js`: 55 cases, 51 passed, 0 failed, 4 skipped, 0 missing |
| `dart run melos run check:port` | lib-imports 302 files, headers 339 files, js-semantics 118 files, port:next 197 files, parity 163 files: all passed, 0 errors, 0 warnings |
| `dart run melos run parity` | wrote `doc/parity.md`; 0 errors, 0 warnings |
| `uvx --from 'reuse[charset-normalizer]' reuse lint` | compliant, 817 / 817 files with copyright and license information (with this report) |
| `flutter test` in `apps/chartjs_gallery` | +95, all passed |
| `dart analyze --fatal-infos` in `apps/chartjs_gallery` | No issues |

No `flutter_tester` process of W1-int is left. The process 67820 belongs to another session
(scratchpad `ec6419b7-...`). W1-int did not start it and did not stop it.

## Lift check

TS §4.1 describes the check, and no unit wrote it. W1-int wrote it as
`doc/phase7/tools/lift_check.py` (the folder of this prompt; TS §4.1 and Chart.js ADR 0030 §12
name `doc/phase7/classification/lift_check.py`). It reads the JSON reporter output, builds the
full name of each record from `describe` and `it`, gives each record the wave of its modules, and
applies the rules of TS §4.1 to the records of the given wave and of earlier waves. It also
compares the counts by spec file of `all.json` with `summary.md` §2 with decision D1.

Command (from `packages/flutter_chartjs`):

```
flutter test --reporter json test/specs test/port > <scratch>/run1.json
python3 -I doc/phase7/tools/lift_check.py doc/phase7/classification/all.json <scratch>/run1.json 1 --list
```

Result for wave 1 (exit code 1, as expected before L1):

- The counts of `all.json`: `phase7` 503, legend 21, tooltip 11, filler 1, the same as
  `summary.md` §2 with D1 for each spec file.
- Records of wave 1 and earlier: 122. 62 pass, 60 fail.
- The 62 records that pass:
  - `controller.bar_test.dart`: 51 (50 `phase7` records with the result `success`, and the 1
    `blocked: plugin.tooltip` record that skips with that reason). The 3 placeholders
    `blocked: controller.line` are records of wave 2, and "should be registered as dataset
    controller" is a record of wave 3 (module `controllers/index`). They are not in this count.
    The latter passes now.
  - `blocked: plugin.legend` records of wave 0 and 1 that skip with that reason: `core.layouts` 5,
    `platform.basic` 2, `scale.category` 1, `scale.time` 3.
- The 60 records that fail all skip as `blocked: controller.bar`. They are the lift list of L1
  (work-plan §2): `core.animator` 1, `core.datasetController` 3, `core.layouts` 5, `helpers.dom`
  2, `scale.category` 2, `scale.linear` 25, `scale.logarithmic` 21, `scale.time` 1. The list is in
  `<scratch>/wave1/W1-int/lift1.txt`.
- A run without a wave number finds each record of an existing Dart file. Only the records of the
  6 controller spec files of waves 2 and 3 (91 records) are missing.

## Doc notes that W1-int applied

| Unit | Notes |
|---|---|
| S1 | AGENTS.md runtime list (the text of the fixes, with the negative index and the `DateTime` text); `platform-array-events` (code column and text); the port-only rows of the three `js_*.dart` files. |
| S2 | AGENTS.md items of `core.controller.dart`, `core.datasetController.dart`, the types and `element.line.dart`; the drawCalls test sentence (with U0); `adapt-line-points-elements`; the status texts of `core.controller.js`, `core.datasetController.js`, `element.line.js`, `index.d.ts`; the port-only row of `test/port/types/index_test.dart`; performance.md §11.3 line. |
| S3 | AGENTS.md `stacksOf`; performance.md §13.1 (the table of S3 §1.2); `js-semantics-resolver-objects` with the corrected text of S3-R1; the status text of `core.datasetController.js` with the corrected text. |
| U0 | AGENTS.md test notes, layout and generator list; porting-flow.md §3 paragraph (with the `{do}` step, the JSON lines of the hits, the `adapt-bar-clip` rule and the spy limit); performance.md §13.4 data sizes; the four port-only rows; the Jasmine names in the two spec rows; the tests column of `adapt-bar-clip`. |
| U-bar (lib and tests) | AGENTS.md `lib/src/controllers/` item, `getStackCount` and `getStackIndex`, the test files and the generator with the moment packages; the status rows of `controller.bar.js`, `controller.bar.tests.js` and the 3 port-only rows; performance.md §13.1 `_strictEquals` figures; the removal of the two `Chart.register` lines. |

## Open items for the phase lead

1. Proposed ADR and spec texts that differ from the code after the fixes. The ADRs and the specs
   are not files of W1-int, so W1-int did not change them:
   - Chart.js ADR 0027 §5 item 3 (and PD §4.1): "each other value throws" and the name
     `_listStacks`. The code (S3-R1) gives `_stacks` to a `DateTime`, a function and a class
     value, and the Expando is `_objectStacks`.
   - Chart.js ADR 0027 §7 and PD §5.2: the row `jsOrZero(...) == index` of `bar.js:220-222`. The
     code (U-bar-lib F1) uses `_strictEquals(_orZero(...), index)`. Also the `===` of two
     possible `Date` operands (F2): ADR 0027 §7 does not name `DateTime`.
   - Chart.js ADR 0027 §4: the cast of a parsing key throws for the keys `[]` and `[['y']]`, where
     upstream does not throw (U-bar-lib F3, the doc of `parseObjectData` names it). The same form
     is in `helpers.config.dart` and DC `_keyOr`.
   - Chart.js ADR 0030 §3 item 6: the hit items are JSON lines, not Dart literals (U0 R6). The
     report of U0 asks for a decision record.
   - IV §2.1 (`core.controller.js:899` is `:898`, S2 F1) and IV §3.3 (the label text of radar, S2
     F3). The code has the correct texts.
2. `Date.prototype.toString` without the zone name (S1 fix F1): no `differences.md` row and no
   marker. A row needs a marker in `lib/src/js/js_number.dart`, a file of S1. ADR 0009 says that a
   text difference that changes no protected behavior needs no emulation. The phase lead decides
   on a row, for example `js-semantics-date-zone-name`.
3. `test/port/platform/fake_chart.dart` is not in the S2 row. Without its change the package does
   not compile. W1-int confirms the change: the full gate passes with it.
4. `stacksOf` write path (S3 §1.3, run 1): performance.md §13.7 item 5 records it.
5. U0 open items: the private `_anyFunction` of `scale.radialLinear_test.dart` and the private
   `_Spy` of `helpers.core_test.dart` and `helpers.config_test.dart` can move to
   `test/support/jasmine.dart` in a later unit. The stale-key check (U-bar-tests O1) cannot fail
   for a key that the theme emits in the four observed subtrees; the doc of
   `expectNoStaleScaleKeys` can record this limit.
6. `doc/phase7-progress.md` has a change in the working tree that no unit of wave 1 made (the
   phase lead owns the file). It is not in the list below. The decision line of Chart.js ADR 0030
   and the U0 result of TS §1.2 item 5 (U0 report) go there.
7. The commit checkpoint of the work-plan row (`gallery:build:web`, `gallery:build:android`) did
   not run: the prompt of W1-int does not ask for it, and W1-int makes no commit.

## Files changed in wave 1 (all units)

New files are marked "(new)". The paths are relative to the repository root.

| Unit | Files |
|---|---|
| S1 | `packages/flutter_chartjs/lib/src/js/js_object.dart`, `js_array.dart`, `js_number.dart`; `packages/flutter_chartjs/test/port/js/js_object_test.dart`, `js_array_test.dart`, `js_number_test.dart` |
| S2 | `packages/flutter_chartjs/lib/src/core/core.datasetController.dart`, `core.controller.dart`, `core.element.dart`, `core.scale.dart`; `packages/flutter_chartjs/lib/src/scales/scale.radialLinear.dart`; `packages/flutter_chartjs/lib/src/types/index.dart`; `packages/flutter_chartjs/lib/src/elements/element.point.dart`, `element.line.dart`; `packages/flutter_chartjs/lib/src/helpers/helpers.extras.dart`, `helpers.config.dart`; `packages/flutter_chartjs/test/specs/helpers.segment_test.dart`; `packages/flutter_chartjs/test/port/helpers/helpers.segment_test.dart`, `helpers.extras_test.dart`, `helpers.collection_test.dart`; `packages/flutter_chartjs/tool/bench/bench_flutter_test.dart`, `tool/bench/src/cases_data.dart`; `packages/flutter_chartjs/test/port/core/core.datasetController_test.dart`, `core.controller_test.dart`, `core.datasetController_chart_test.dart`; `packages/flutter_chartjs/test/port/elements/element.line_test.dart`; `packages/flutter_chartjs/test/port/platform/fake_chart.dart` (outside the row); `packages/flutter_chartjs/test/port/types/index_test.dart` (new); `apps/chartjs_gallery/lib/demo/demo_chart.dart` |
| S3 | `packages/flutter_chartjs/lib/src/core/core.datasetController.dart`; `packages/flutter_chartjs/test/port/core/core.datasetController_test.dart`, `core.datasetController_chart_test.dart` |
| U0 | `packages/flutter_chartjs/tool/reference/scale_chart_common.mjs`; `packages/flutter_chartjs/tool/reference/controller_chart_common.mjs` (new); `packages/flutter_chartjs/test/port/scales/scale_chart_harness_reference.dart`, `scale_category_reference.dart`, `scale_linear_reference.dart`, `scale_linearbase_reference.dart`, `scale_logarithmic_reference.dart`, `scale_radial_linear_reference.dart`, `scale_time_reference.dart`, `scale_timeseries_reference.dart` (generated); `packages/flutter_chartjs/test/port/scales/scale_chart_harness.dart`, `scale_chart_harness_test.dart`; `packages/flutter_chartjs/test/port/canvas/path2d_record.dart` (new); `packages/flutter_chartjs/test/port/elements/element.line_test.dart`; `packages/flutter_chartjs/test/port/controllers/controller_chart_harness.dart` (new), `controller_chart_harness_test.dart` (new); `packages/flutter_chartjs/test/support/jasmine.dart` (new); `packages/flutter_chartjs/test/specs/core.controller_test.dart`, `core.plugin_test.dart`, `helpers.canvas_test.dart`, `core.element_test.dart`, `helpers.options_test.dart` |
| U-bar (lib) | `packages/flutter_chartjs/lib/src/controllers/controller.bar.dart` (new) |
| U-bar (tests) | `packages/flutter_chartjs/lib/src/controllers/controller.bar.dart` (fix L1); `packages/flutter_chartjs/tool/reference/controller_bar_reference.mjs` (new); `packages/flutter_chartjs/test/port/controllers/controller_bar_reference.dart` (new, generated); `packages/flutter_chartjs/test/port/controllers/controller.bar_test.dart` (new); `packages/flutter_chartjs/test/specs/controller.bar_test.dart` (new) |
| W1-int | `packages/flutter_chartjs/lib/src/controllers/index.dart` (new); `packages/flutter_chartjs/lib/src/index.dart`; `packages/flutter_chartjs/test/port/index_test.dart`; `packages/flutter_chartjs/test/port/controllers/controller.bar_test.dart`; `packages/flutter_chartjs/test/specs/controller.bar_test.dart`; `packages/flutter_chartjs/doc/phase7/tools/lift_check.py` (new); `AGENTS.md`; `packages/flutter_chartjs/doc/porting-flow.md`, `performance.md`, `differences.md`, `status.yaml`, `parity.md` (generated) |
| Reports and reviews | `packages/flutter_chartjs/doc/phase7/review/wave1/` (new): `S1-report.md`, `S1-review.md`, `S2-report.md`, `S2-review.md`, `S3-report.md`, `S3-review.md`, `U0-report.md`, `U0-review.md`, `U-bar-lib-report.md`, `U-bar-lib-review.md`, `U-bar-tests-report.md`, `U-bar-tests-review.md`, `W1-int-report.md` |

`REUSE.toml` and the `LICENSE` files did not change: wave 1 takes no code from a new project.
