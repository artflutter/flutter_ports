# Wave 3, unit W3-int (integration): report

## Status

Done. All gates are green. The lift check of waves 1 and 2 is green.

- `lib/src/controllers/index.dart` has the final content of IV §5.1: the eight `export ... show`
  directives in code unit order. The namespace `controllers` of `lib/src/index.dart` has the eight
  controllers. Thus `flutter_test_config.dart` registers all controllers of phase 7 with the
  built-in components. `registerables` did not change.
- The three temporary `Chart.register` lines of U-scatter and U-pie are gone.
- D12: the skip `blocked: controller.pie` of `controller.doughnut.tests.js:4` is gone, and the
  case passes. The IV §7.1 tests of `test/port/types/index_test.dart` run on a bar chart and a polar
  area chart. The proposed Chart.js ADRs 0027, 0028 and 0030 and the specs PD, IV, TS and GA agree
  with the code and with the decisions D10-D12.
- The shared docs have the doc notes of U-scatter, U-pie, L2 and X-fix, and the notes of their
  fixes.
- L2 recorded no `lib/` defect (L2 report: "No lifted case failed"). W3-int found no cross-file
  error. Thus W3-int changed no `lib/` file except the two registration files, and needed no
  probe or pin test for a `lib/` fix.
- No test changed its result when scatter and pie became built-in components.

All paths are relative to `packages/flutter_chartjs/`, except where a path starts with `apps/`,
`AGENTS.md` or `REUSE.toml`. `<w3>` is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave3/W3-int`.
The logs are in `<w3>/`.

## Registration

| File | Change |
|---|---|
| `lib/src/controllers/index.dart` | The `///` lines of `index.js:1-8` in the upstream order, and eight `export ... show` directives in code unit order (`PieController` before `PolarAreaController`). The sentence about wave 3 is gone. |
| `lib/src/index.dart` | Imports of `controller.pie.dart` and `controller.scatter.dart`. The `controllers` Map has the eight class values in code unit order (IV §5.2). The `///` text of the Map and of the library names the eight controllers. |
| `test/port/index_test.dart` | IV §7.4 for 8 controllers: the keys of `controllers` in code unit order, each value `same` its `jsClass`, the Map unmodifiable. After `Registry()..add(registerables)`, the keys of `registry.controllers.items`, `defaults.datasets` and `Chart.overrides` are `bar, bubble, doughnut, line, pie, polarArea, radar, scatter`. `registry.controllers.items['pie']` and `['scatter']` are the class values. The test "the namespaces of later phases are empty" keeps only `plugins` (no change was necessary). |
| `test/specs/controller.scatter_test.dart` | The line `Chart.register([ScatterController.jsClass]);`, the comment paragraph about it and the import of `controller.scatter.dart` are gone. The comment says that `flutter_test_config.dart` registers the controller, as `index.umd.ts:28` does. |
| `test/port/controllers/controller.scatter_test.dart` | The registration line and its comment paragraph are gone. The import stays (the group `showLine` casts to `ScatterController`). |
| `test/port/controllers/controller.pie_test.dart` | The registration line and its comment paragraph are gone. The comment says that `flutter_test_config.dart` registers the pie controller and its parent class. |

The id check of IV §5.3
(`grep -rnE "'id': '(bar|bubble|doughnut|line|pie|polarArea|radar|scatter)'" test apps/chartjs_gallery/lib`)
found no test or gallery controller with the id of a built-in controller.

## D12

- `test/specs/controller.doughnut_test.dart`: the case `:4` "should be registered as dataset
  controller" has no `skip`. It is a `test` with the upstream body, and it passes. The file comment
  names only the tooltip case (`:418`).
- `test/port/types/index_test.dart` (IV §7.1): the charts are a bar chart and a polar area chart.
  The `main()` registers no test controller, and the import of `scale_chart_harness.dart` is gone.
  The test of `types.RadialLinearScale` asserts `isNotNull` for `xCenter` and `yCenter` (X-fix
  review F2), compares them with the concrete scale, and expects the center `256.0` of the
  512 x 512 canvas. The other tests read the same members on the bar chart. 9 tests pass.
- The axis-id rule: `controller.pie_test.dart` keeps its copy of `_undefinedAxisIds` and
  `_observationAxisIds` (D12: U-pie takes the rule). W3-int did not move it into
  `controller_chart_harness.dart` (open item 4). AGENTS.md, porting-flow.md §3 and TS §2 record
  the rule for both files.

### The alignment of the proposed ADRs and the specs

No status line changed. Chart.js ADR 0025 (accepted) and Chart.js ADR 0019 did not change.

| Text | Change | Source |
|---|---|---|
| Chart.js ADR 0027 §5 item 4 | The doughnut reads `dataset.data` raw. `_dataCheck` keeps a string as a `JsStringList` with no listener. With `parsing: false`, `meta.parsed` is the data List (a cast that cannot fail) or the `JsStringList`. | D11 item b |
| Chart.js ADR 0027 §8, Alternatives (question 5), Consequences, Open 4 | The one-read rule has the 3-read form: a local lives only inside one pass, and `prevParsed[iAxis]` is a read at each pass. The gain is 15 to 17 ns (AOT) and 23 to 24 ns (wasm). The 2-read form is a rejected alternative with the reason of the U-line review R2. Open 4 is closed by D10. | D10, W2-int item 1 |
| Chart.js ADR 0028 §1 | The three other kinds of casts (`List`, `String` of a parsing key, `AnyObject` of an object that the controller made). `double? get xCenter`, `double? get yCenter`, with the reason and the conflict with accepted Chart.js ADR 0025 §5 for the maintainer. `void toggleDataVisibility(Object? index)`. | W2-int item 9 (IV §4.8), D11 items a and c, X-fix review F1 |
| Chart.js ADR 0028 §6 | `toggleDataVisibility(jsGet(legendItem, 'index'))` with the key `ToString(index)`; `moveNumericKeys` moves `''` and `'01'` as upstream. | D11 item c, W2-int item 3 |
| Chart.js ADR 0030 §3 | New item 8: the `BasicPlatform` patch of the doughnut and polar area generators. | W2-int item 9 |
| Chart.js ADR 0030 §7 | No change. The doughnut generator has the case `cutout '50%'` (the U-doughnut fixer changed it to the ADR value in wave 2). | W2-int item 9 |
| Chart.js ADR 0031 §9.2 | No change: it gives the signatures of Chart.js ADR 0028. | X-fix notes |
| IV spec §2 | `toggleDataVisibility(Object? index)`, `double? get xCenter`, `double? get yCenter`, `updateControlPoints(ChartArea? chartArea, ...)`. | D11, W2-int F5 |
| IV spec §4.3 | The line draw passes `chart.chartArea` without `!`; the text says where upstream and the port throw. | W2-int item 9 |
| IV spec §4.5, §4.6 | `?? undefined` for the reset position; the radar `skip` form. | D11 item a |
| IV spec §4.7 | `_onClick` passes the raw index. | D11 item c |
| IV spec §4.8 | The checklist accepts the three other kinds of casts. | W2-int item 9 |
| PD spec §5.1 rule 4, §5.3, §5.5 | The one cast of the doughnut `parse` is for `parsing: false`; the loop sample has the 3-read form (no `prevIValue`); the doughnut sample reads a string `data`. | D10, D11 item b, U-scatter open item 5 |
| GA spec §3.0 (line 88) | `void toggleDataVisibility(Object? index) {}`. | D11 item c |
| TS spec §2 | Three rules: the generator data change for a last-bit hit tie (the pie case), the axis-id map of the doughnut and pie files (D12), the probe for an option change. | U-pie F1, D12, U-scatter R2 |

The text of Chart.js ADR 0019 line 818 (`jsMapForEach in _update`) agrees with the code: the group
of `test/port/core/core.animator_test.dart` keeps that name (A1 report). Thus no change.

## Doc notes that W3-int applied

| Doc | Change |
|---|---|
| `AGENTS.md` | Layout: `xCenter` and `yCenter` of `RadialLinearScale` are `double?`; `_dataCheck` and a string `data`; `toggleDataVisibility(Object?)`; the namespace text of the eight controllers; the `lib/src/controllers/` item (eight controllers, the three other kinds of casts); new sub-items `controller.pie.dart` and `controller.scatter.dart`; the doughnut `_onClick` and `parse`; the eight controller test files. Porting rules: `JsStringList`. Tests: the axis-id map of the doughnut and pie files, the probe of an option change, the data array change of a spec (L2), the eight controller generators. |
| `doc/porting-flow.md` | §2.14: the `double?` rule for an `undefined` start value that a reader writes (X-fix). §2.19: `xCenter` and `yCenter` against accepted ADR 0025. §2.21: `toggleDataVisibility`, the eight controllers. §3: the axis ids of doughnut and pie, the corrected pie hit-tie text (U-pie F1), the probe of an option change, the NaN control points of a scatter line. §5: the result of wave 3 in the phase 7 row. |
| `doc/performance.md` | §13.1: D10 and the 3-read form of scatter. §13.4: the sizes of the scatter and pie data files. §13.7: item 6 (D10), new item 8 (the wave 3 forms). |
| `doc/differences.md` | `adapt-chart-registry-getter`: "(phase 7)" is gone; the test column names the scatter group `showLine`. `platform-array-events`: a string `data` gets no listener; the test column names the group `string data` and the case of `core.datasetController.tests.js:841`. No new row, no new marker, no removed row. |
| `doc/status.yaml` | New rows: `src/controllers/controller.pie.js`, `src/controllers/controller.scatter.js`, `test/specs/controller.scatter.tests.js`, and the six port-only rows of the scatter and pie test files, data files and generators. New text: `controller.doughnut.js`, `controller.polarArea.js`, `controller.radar.js`, `scale.radialLinear.js`, `core.datasetController.js`, `core.controller.js`, `controllers/index.js` (now `ported`), `index.ts`, the spec rows of L2 (`controller.bar`, `core.controller`, `core.datasetController`, `core.interaction`, `core.scale`, `core.ticks`, `element.line`, `platform.dom`, `scale.category`, `scale.linear`, `scale.logarithmic`, `scale.radialLinear`, `scale.time`), `controller.doughnut.tests.js` (no pie skip), and the port-only rows of `js_array.dart`, `index_test.dart`, `types/index_test.dart`, `controller_chart_common.mjs` and `scale.time_test.dart`. |
| `doc/parity.md` | Written by tool 6. |
| `doc/canvas-cuts-plan.md` | A dated entry for wave 3 (work plan §0, deferred plans): `demo_chart.dart` and `core.controller.dart` changed, the two `platform.dom` cases of §3.6 pass since L2, the cited harness rows are at lines 697-698 of porting-flow.md. No trigger. |
| `doc/upstream-ledger.md` | No change: no unit of wave 3 recorded a ledger item. |

## Gates

| Command | Result |
|---|---|
| `dart run melos run format:check` | 406 files, 0 changed |
| `dart run melos run analyze` | No issues found (covers `apps/chartjs_gallery`) |
| `dart run melos run test --no-select` | All passed: chartjs_gallery +95; chartjs_test_utils +139; flutter_chartjs +6407 ~133; flutter_d3_port +38 |
| `dart run melos run test:web` | All passed: flutter_chartjs +7048 ~2; chartjs_test_utils +98 |
| `dart run melos run test:cases` | passed, 44 files, 0 errors, 0 warnings. Total 1036 cases: 813 passed, 0 failed, 127 skipped, 96 missing (the 10 upstream spec files without Dart tests). W2-int gave 572, 0, 362 and 102 in 43 files |
| `dart run melos run check:port` | lib-imports 329 files, headers 366, js-semantics 131, port:next 204, parity 163: all passed, 0 errors, 0 warnings |
| `dart run melos run parity` | wrote `doc/parity.md`; 0 errors, 0 warnings |
| `uvx --from 'reuse[charset-normalizer]' reuse lint` | compliant, 875 / 875 files with copyright and license information (with this report) |
| `flutter test` in `apps/chartjs_gallery` | +95, all passed |
| `dart analyze --fatal-infos` in `apps/chartjs_gallery` | No issues found |
| `dart run melos run gallery:build:web` | built `build/web` |
| `dart run melos run gallery:build:android` | built `app-debug.apk` |

The `test:web` skip count fell from ~98 to ~2: L2 moved `core.interaction_test.dart`,
`core.ticks_test.dart` and `element.line_test.dart` to `@TestOn('vm')`, so the web legs no longer
compile their skipped cases.

The controller spec files in `test:cases`:

| Spec | Cases | Passed | Skipped | Missing |
|---|---|---|---|---|
| `controller.bar.tests.js` | 55 | 54 | 1 (`blocked: plugin.tooltip`) | 0 |
| `controller.bubble.tests.js` | 11 | 10 | 1 (`blocked: plugin.tooltip`) | 0 |
| `controller.doughnut.tests.js` | 13 | 12 | 1 (`blocked: plugin.tooltip`) | 0 |
| `controller.line.tests.js` | 34 | 33 | 1 (`blocked: plugin.tooltip`) | 0 |
| `controller.polarArea.tests.js` | 14 | 13 | 1 (`blocked: plugin.tooltip`) | 0 |
| `controller.radar.tests.js` | 13 | 11 | 2 (`blocked: plugin.filler`, `blocked: plugin.tooltip`) | 0 |
| `controller.scatter.tests.js` | 6 | 4 | 2 (`blocked: plugin.tooltip`) | 0 |

Pie has no upstream spec file.

No `flutter_tester` process of W3-int is left. The process 67820 belongs to another session
(scratchpad `ec6419b7-...`). W3-int did not start it and did not stop it.

## Lift check

Command (from `packages/flutter_chartjs`):

```
flutter test --reporter json test/specs test/port > <w3>/run.json
python3 -I doc/phase7/tools/lift_check.py doc/phase7/classification/all.json <w3>/run.json 2 --list
```

- Wave 2: exit code 0. Counts of `all.json`: `phase7` 503, legend 21, tooltip 11, filler 1 (as
  `summary.md` §2 with D1). 508 records of wave 2 and earlier: 508 pass, 0 fail, 0 count
  differences. The lift list of wave 2 has 0 records (`<w3>/lift2.txt`).
- Wave 1: exit code 0. 122 of 122 records pass, 0 count differences (`<w3>/lift1.txt`).
- Wave 3 (for information, the input of L3): exit code 1, as expected before L3. 536 records:
  520 pass, 16 fail (`<w3>/lift3.txt`). The 7 controller spec files have 0 failures. The 16
  records are the placeholders of the row of L3:
  - `core.controller_test.dart`, 7 records, `blocked: controller.pie`: "Chart config
    initialization should initialize config with default dataset options"; "Chart data visibility
    should toggle data visibility by index"; "... should maintain data visibility indices when
    data changes"; "... should leave data visibility indices intact when data changes in
    non-uniform way"; "Chart getChart should get the chart from an HTMLCanvasElement"; "... from an
    CanvasRenderingContext2D"; "Chart active elements should set the active elements".
  - `core.datasetController_test.dart`, 2 records, `blocked: controller.scatter`: "should
    synchronize insert before removal when parsing is off"; "getContext should reflect updated
    data".
  - `core.interaction_test.dart`, 2 records, `blocked: controller.scatter`: "tooltip element of
    scatter chart out-of-range datapoints are not shown in tooltip"; "... are shown in tooltip if
    included".
  - `core.scale_test.dart`, 5 records, `blocked: controller.scatter`: "_layers should create the
    chart with custom scale ids without axis or position options"; "min and max should be limited
    to visible data"; "overrides should create new scale"; "overrides should create new scale
    with custom name"; "overrides should read options first to determine axis".

## Open items for the phase lead

1. **Accepted Chart.js ADR 0025 §5 and `xCenter` (X-fix open item 4, X-fix review F1).** The
   code and proposed Chart.js ADR 0028 §1 have `double? get xCenter` and `double? get yCenter`.
   Accepted ADR 0025 §5 has `double`. W3-int did not change ADR 0025. A record is necessary (for
   example a new proposed ADR that supersedes ADR 0025). The evidence: the X-fix probes
   `<scratchpad>/wave3/X-fix/probe.mjs` and `<scratchpad>/wave3/X-fix-fix/probe_f1c.mjs`.
2. **The `Math.sin` hit tie of the arc charts (U-pie review F2, U-pie open items 4 and 6).** A user
   pie with the data `[[10, 20, 30, 15], [5, 15, 10, 20]]`, the index 3 hidden and the point
   `(244, 268)` gives another hit element than upstream (`dart:math` `sin` is 1 ulp from V8 at
   `3.665191429188092`). Chart.js ADR 0009 protects the hit element. Select an fdlibm port of `sin`
   and `cos` in `lib/src/js/` with the third-party steps, or a `DIVERGES(chartjs)` marker in
   `element.arc.dart` and a `differences.md` row. The pie generator avoids the tie with
   `[5, 15, 12, 20]`. The CI legs on ubuntu and Windows can show other ties.
3. **The lift of wave 3 (L3).** The 16 records above. The pie and scatter controllers are
   registered now.
4. **The axis-id rule (D12).** The doughnut and pie test files have two copies of
   `_undefinedAxisIds` and `_observationAxisIds`. A later unit that owns
   `controller_chart_harness.dart` can move one copy there (Dart `null` matches JS `null` and
   `undefined` for `xAxisID` and `yAxisID`).
5. **The work plan text (U-scatter open item 1).** Work plan §3, row U-scatter, says that
   `controller.scatter.dart` imports `controller.line.dart`. Upstream does not import it, and the
   port does not. The plan is not a file of W3-int.
6. **`doc/phase7/members-radial.md` (X-fix review F1).** Lines 249, 295 and 305 keep
   `double xCenter` and `toggleDataVisibility(double)`. It is a scout record, not a file of
   W3-int.
7. **The `JsStringList` limits (X-fix open item 1).** `isArray` and `typeof` of the list, and the
   identity of `meta.parsed` with `dataset.data` for `parsing: false`, differ from upstream. No
   ported reader sees them. A plugin of phase 8 that tests `isArray(meta._parsed)` or
   `_parsed === data` must check again.
8. **A truthy non-List, non-String `data` (X-fix open item 2).** A number `data` still throws
   the cast `TypeError` in `_dataCheck`. Upstream keeps it. It is outside the upstream type
   contract and outside D11.
9. **A generator step that writes an option (U-scatter open item 6).** The pins of the scatter
   `showLine` switch come from a probe (recorded in `U-scatter-report.md`). A step in
   `controller_chart_common.mjs` can move them into the generator later.
10. **The copies of Jasmine `toBeCloseTo` (L2 open item 3), and `_toBeCloseToTime` of
    `scale.time_test.dart` for the unit `hour` only (L2 open item 4).**
11. **The commit checkpoint.** All gates of the checkpoint are green (full gate, `reuse lint`,
    `gallery:build:web`, `gallery:build:android`). The wasm build in the VS Code integrated
    browser before the push is for the phase lead. W3-int made no commit.
12. **`doc/phase7-progress.md`** has a change in the working tree that no unit of wave 3 made. It
    is not in the list below.

## Files changed in wave 3 (all units)

The paths are relative to the repository root. "(new)" marks a new file.

| Unit | Files |
|---|---|
| U-scatter | `packages/flutter_chartjs/lib/src/controllers/controller.scatter.dart` (new); `packages/flutter_chartjs/tool/reference/controller_scatter_reference.mjs` (new); `packages/flutter_chartjs/test/port/controllers/controller_scatter_reference.dart` (new, generated); `packages/flutter_chartjs/test/port/controllers/controller.scatter_test.dart` (new); `packages/flutter_chartjs/test/specs/controller.scatter_test.dart` (new) |
| U-pie | `packages/flutter_chartjs/lib/src/controllers/controller.pie.dart` (new); `packages/flutter_chartjs/tool/reference/controller_pie_reference.mjs` (new); `packages/flutter_chartjs/test/port/controllers/controller_pie_reference.dart` (new, generated); `packages/flutter_chartjs/test/port/controllers/controller.pie_test.dart` (new) |
| L2 | `packages/flutter_chartjs/test/specs/controller.bar_test.dart`, `core.controller_test.dart`, `core.datasetController_test.dart`, `core.interaction_test.dart`, `core.scale_test.dart`, `core.ticks_test.dart`, `element.line_test.dart`, `platform.dom_test.dart`, `scale.category_test.dart`, `scale.linear_test.dart`, `scale.logarithmic_test.dart`, `scale.radialLinear_test.dart`, `scale.time_test.dart`; `packages/flutter_chartjs/test/port/scales/scale.time_test.dart` |
| X-fix | `packages/flutter_chartjs/lib/src/types/index.dart`; `packages/flutter_chartjs/lib/src/scales/scale.radialLinear.dart`; `packages/flutter_chartjs/lib/src/controllers/controller.radar.dart`, `controller.polarArea.dart`, `controller.doughnut.dart`; `packages/flutter_chartjs/lib/src/js/js_array.dart`; `packages/flutter_chartjs/lib/src/core/core.datasetController.dart`, `core.controller.dart`; `apps/chartjs_gallery/lib/demo/demo_chart.dart`; `packages/flutter_chartjs/test/port/controllers/controller.radar_test.dart`, `controller.polarArea_test.dart`, `controller.doughnut_test.dart`, `controller.line_test.dart`; `packages/flutter_chartjs/test/port/core/core.datasetController_test.dart`, `core.controller_test.dart`; `packages/flutter_chartjs/test/port/scales/scale.radialLinear_test.dart`; `packages/flutter_chartjs/test/port/js/js_array_test.dart` |
| W3-int | `packages/flutter_chartjs/lib/src/controllers/index.dart`; `packages/flutter_chartjs/lib/src/index.dart`; `packages/flutter_chartjs/test/port/index_test.dart`; `packages/flutter_chartjs/test/port/types/index_test.dart`; `packages/flutter_chartjs/test/specs/controller.doughnut_test.dart`; the registration lines of `packages/flutter_chartjs/test/specs/controller.scatter_test.dart`, `packages/flutter_chartjs/test/port/controllers/controller.scatter_test.dart` and `packages/flutter_chartjs/test/port/controllers/controller.pie_test.dart`; `AGENTS.md`; `packages/flutter_chartjs/doc/porting-flow.md`, `performance.md`, `differences.md`, `status.yaml`, `parity.md` (generated), `canvas-cuts-plan.md`; `packages/flutter_chartjs/doc/adr/0027-parsed-data.md`, `0028-controller-interfaces.md`, `0030-controller-test-strategy.md`; `packages/flutter_chartjs/doc/phase7/design/parsed-data/spec.md`, `interfaces-values/spec.md`, `test-strategy/spec.md`, `gallery/spec.md` |
| Reports and reviews | `packages/flutter_chartjs/doc/phase7/review/wave3/` (new): `L2-report.md`, `L2-review.md`, `U-pie-report.md`, `U-pie-review.md`, `U-scatter-report.md`, `U-scatter-review.md`, `X-fix-report.md`, `X-fix-review.md`, `W3-int-report.md` |

`REUSE.toml` and the `LICENSE` files did not change: wave 3 takes no code from a new project. No
generated reference file of waves 1 and 2 changed. The FR spec and Chart.js ADRs 0029 and 0031 did
not need a change.
