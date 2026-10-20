# Phase 7 classification: summary

This file is the result of the completeness check of the phase 7 classification. The data is in the ten group files of this folder. `all.json` is the concatenation of the group files, in file name order. Each record of `all.json` also has the field `group` (the name of its group file).

## 1. Totals

| Verdict | Cases |
| --- | --- |
| `phase7` | 500 |
| `blocked: plugin.legend` | 24 |
| `blocked: plugin.tooltip` | 11 |
| `blocked: plugin.filler` | 1 |
| `n/a: <reason>` | 0 |
| Total | 536 |

The 536 records are these:
- 146 cases of the seven `controller.*.tests.js` files (11 of them without a chart).
- 366 Dart tests that skip as `blocked: controller.*`: 309 in `test/specs/` and the 57 time twins in `test/port/scales/scale.time_test.dart`.
- 24 Dart tests that skip as `blocked: plugin.*` and that also need a controller: 21 with `plugin.legend` and 3 with `plugin.tooltip`.

## 2. Counts by spec file

The column "Moves" counts the cases that skip as `blocked: controller.*` now and get the verdict `phase7`.

| Spec file | Cases | `phase7` | `plugin.legend` | `plugin.tooltip` | `plugin.filler` | Moves |
| --- | --- | --- | --- | --- | --- | --- |
| `controller.bar` | 55 | 51 | 3 | 1 | 0 | 0 |
| `controller.bubble` | 11 | 10 | 0 | 1 | 0 | 0 |
| `controller.doughnut` | 13 | 12 | 0 | 1 | 0 | 0 |
| `controller.line` | 34 | 33 | 0 | 1 | 0 | 0 |
| `controller.polarArea` | 14 | 13 | 0 | 1 | 0 | 0 |
| `controller.radar` | 13 | 11 | 0 | 1 | 1 | 0 |
| `controller.scatter` | 6 | 4 | 0 | 2 | 0 | 0 |
| `core.animator` | 1 | 1 | 0 | 0 | 0 | 1 |
| `core.controller` | 41 | 37 | 1 | 3 | 0 | 37 |
| `core.datasetController` | 43 | 43 | 0 | 0 | 0 | 43 |
| `core.interaction` | 45 | 45 | 0 | 0 | 0 | 45 |
| `core.layouts` | 11 | 5 | 6 | 0 | 0 | 5 |
| `core.scale` | 31 | 31 | 0 | 0 | 0 | 31 |
| `core.ticks` | 2 | 2 | 0 | 0 | 0 | 2 |
| `element.line` | 1 | 1 | 0 | 0 | 0 | 1 |
| `helpers.dom` | 2 | 2 | 0 | 0 | 0 | 2 |
| `platform.basic` | 2 | 0 | 2 | 0 | 0 | 0 |
| `platform.dom` | 2 | 2 | 0 | 0 | 0 | 2 |
| `scale.category` | 17 | 13 | 4 | 0 | 0 | 13 |
| `scale.linear` | 38 | 36 | 2 | 0 | 0 | 36 |
| `scale.logarithmic` | 58 | 58 | 0 | 0 | 0 | 58 |
| `scale.radialLinear` | 21 | 18 | 3 | 0 | 0 | 18 |
| `scale.time` | 18 | 15 | 3 | 0 | 0 | 15 |
| Time twins (`test/port/scales/scale.time_test.dart`) | 57 | 57 | 0 | 0 | 0 | 57 |
| Total | 536 | 500 | 24 | 11 | 1 | 366 |

The seven controller spec files have no Dart file yet. Their 146 cases have no skip now. Of them, 134 get `phase7`, and 12 stay blocked by a plugin of phase 8.

## 3. Cases that move from `blocked: controller.*` to `phase7`

All 366 Dart tests that skip as `blocked: controller.*` get the verdict `phase7`. No case of this set stays blocked by a plugin.

| Skip reason now | Dart tests | `phase7` |
| --- | --- | --- |
| `blocked: controller.line` | 266 (209 specs, 57 time twins) | 266 |
| `blocked: controller.bar` | 62 | 62 |
| `blocked: controller.radar` | 17 | 17 |
| `blocked: controller.scatter` | 9 | 9 |
| `blocked: controller.pie` | 7 | 7 |
| `blocked: controller.polarArea` | 4 | 4 |
| `blocked: controller.doughnut` | 1 | 1 |
| Total | 366 | 366 |

## 4. Cases blocked by a plugin of phase 8

| Plugin | Cases | Skip now is the plugin | Controller spec cases | Skip now is `blocked: controller.*` |
| --- | --- | --- | --- | --- |
| `plugin.legend` | 24 | 21 | 3 (`controller.bar`) | 0 |
| `plugin.tooltip` | 11 | 3 (`core.controller`) | 8 | 0 |
| `plugin.filler` | 1 | 0 | 1 (`controller.radar` "should update elements") | 0 |
| Total | 36 | 24 | 12 | 0 |

The 21 legend skips are in these files:
- `core.controller` (1)
- `core.layouts` (6)
- `platform.basic` (2)
- `scale.category` (4)
- `scale.linear` (2)
- `scale.radialLinear` (3)
- `scale.time` (3)

Each of them also needs a controller of phase 7. The legend is displayed by default. It moves the top of the chart area (32 with the legend, 10.2 without it). Thus the fixed pixels of these cases fail without it.

The phase 8 plugins `plugin.title`, `plugin.subtitle`, `plugin.decimation` and `plugin.colors` block no case.

## 5. Cases with an unsure verdict

1. **`controller.bar.tests.js:1426`, `:1442` and `:1538` (`blocked: plugin.legend`).**
   - The probe gives `pass` in the modes `all` and `none`. The legend changes only the asserted values (bar heights and positions). The assertions are relative, and they pass without the legend.
   - 49 other cases have the same pattern (a non-empty `changedBy`, `pass` in both modes) and get `phase7`. Thus these three verdicts do not agree with the rule of the other cases.
   - The critic recommends `phase7` for them. The verdict stays as it is until the phase lead decides.
2. **`core.controller.tests.js:1816` "should notify plugin in correct order" (`phase7`).** The probe gives `unsupported` in both modes, because it has no resize observer. The evidence is a variant with an explicit `chart.resize(400, 400)` (`raw/core.controller-misc/core.controller.variant1816.tests.js`).
3. **`scale.time.tests.js:548` "does not create a negative width chart when hidden" (`phase7`).** The probe gives `unsupported` in both modes (no layout for `display: none`). The evidence is static, with a variant of a 0 x 0 canvas.
4. **`core.animator.tests.js:2` "should fire onProgress for each draw" (`phase7`).** The number of expectations depends on the clock. For this reason only, `changedBy` lists all plugins.
5. **`platform.basic.tests.js:45` and `:70` (`blocked: plugin.legend`, added by the critic).** The probe has no `OffscreenCanvas`. The evidence is a variant that gives the chart the `BasicPlatform` explicitly (`raw/critic/platform.basic.variant.tests.js`). In the modes `none` and `without:legend`, the top is 10.2, not 32, and both cases fail.

## 6. Checks and results

A Python script made these checks. It read these inputs:
- the group files;
- the manifest `doc/upstream/manifest.json`;
- the output of `flutter test --reporter json` for `test/specs/` (1085 tests) and `test/port/` (5032 tests). All tests gave the result `success`.

| Check | Result |
| --- | --- |
| Each case of the seven controller spec files is in the files once. | 146 of 146. No case is missing, no case is there twice, no record is extra. |
| The 3 new cases of the pin. | `git diff v4.5.1 7169e651 -- test/specs` adds three cases (listed below this table). All three are in the files, with `phase7` (probe `pass` in both modes, values equal). |
| Each Dart test that skips as `blocked: controller.*` is in the files once. | 366 of 366. The JSON reporter resolved the groups, the helpers and the loops. The skip reason of each record is equal to the skip reason of its Dart test. |
| The 57 time twins. | 57 of 57 (`_lineTwin`, all `blocked: controller.line`). `test/port/` has no other `blocked: controller.*` skip. |
| Each Dart test that skips as `blocked: plugin.*` and needs a controller. | 22 of 24 before the critic. The critic added the 2 cases of `platform.basic_test.dart` "with offscreenCanvas". The 4 `blocked: plugin.colors` skips of `test/port/theme/precedence_test.dart` need no controller and are not in the files. |
| Each record has a valid verdict. | Yes. Each verdict is `phase7`, or `blocked: plugin.<id>` with a plugin of phase 8. |
| Each record has `verified`, `evidence`, `note` and `modules`. | Yes. `verified` is `confirmed` (534) or `critic` (2). |
| The fields `describe`, `it`, `line` and `kind` agree with the manifest. | Yes, for each record of an upstream case. |
| A `phase7` verdict with the probe status `error` in both modes. | None. Of the 500 `phase7` records, 498 give `pass` in the mode `none`. The other 2 give `unsupported` (items 2 and 3 of section 5). |
| A `blocked: plugin.*` verdict names a module of the record. | Yes, for each record. |
| A record that skips as `blocked: controller.<x>` lists `controller.<x>` in `modules`. | Yes, for each record. `controller.pie` is in `modules` for the pie skips. |

The three new cases of the pin are these:
- `controller.doughnut.tests.js:49` "should default arc spacingMode to angular"
- `controller.polarArea.tests.js:69` "should default arc spacingMode to proportional"
- `controller.polarArea.tests.js:85` "should respect chart-level spacingMode override"

The same diff also adds 3 `core.scale` "Scale Title stroke" cases and 8 `element.arc` cases. These run now, without a skip.

The critic also made two changes of form:
- `changedBy` of 4 records of `core.scale-category.json` (lines 287, 330, 406 and 479) had `plugin.legend`. It now has `legend`, the plugin id of the other records.
- `modules` of `controller.bar.json` (line 4) had `controllers.index`. It now has `controllers/index`, as the other records.

## 7. Method

The probe harness is in `../probe/` (see `../probe/README.md`). It runs one upstream spec file with these parts:
- the x64 Node.js v24.12.0, under Rosetta;
- a build of Chart.js at the pin `7169e651`;
- the moment packages;
- the `fakeCanvas` of `tool/reference/scale_chart_common.mjs`, with the text widths of Liberation Sans 2.1.5.

The time zone is UTC.

The modes are these:

| Mode | Registration |
| --- | --- |
| `all` | All registerables. `plugins.colors.enabled` is false, as in `test/index.js`. |
| `none` | The controllers, elements and scales. No plugin. |
| `without:<id>` | All registerables except the plugin `<id>`. |
| `only:<id>` | The controllers, elements and scales, and the plugin `<id>`. |

`compare.mjs` runs `all` and `none`, each in its own process. A case can give a different status, different values or a different error in the two modes. Then `compare.mjs` also runs `without:<id>` for each plugin. Its `changedBy` names the plugins whose removal changes the case. The raw output of each group is in `raw/`.

The rule for the verdict is this:
- A case gets `phase7` when the modules of phase 7 and of the earlier phases are sufficient, and the case passes in the mode `none`.
- A case gets `blocked: plugin.<id>` when the removal of the plugin `<id>` makes the case fail or throw. For the 3 cases of item 1 of section 5, the removal changes only the asserted values.
- Each record also has a static reading of the pinned upstream source (`evidence` `probe+static` or `static`).

The critic made the checks of section 6 with a Python script. The script mapped the records to the Dart tests by the full test name, as tool 5 does. The full name is the `describe` names and the test name, joined with spaces. For the gaps, the critic ran `compare.mjs` on a variant spec in `raw/critic/`.
## 8. Decision of the phase lead

Decision D1 (2026-10-21): the three cases of item 1 of section 5 (`controller.bar.tests.js:1426`,
`:1442` and `:1538`) get `phase7`. They pass in the mode `none`. The rule of the other 49 cases
with a non-empty `changedBy` applies to them too. The totals change: `phase7` 503,
`blocked: plugin.legend` 21, `controller.bar` 54 `phase7` and 0 legend cases.
