# Wave 3, unit U-pie: report

## Status

Done. The unit ports `controller.pie.js` at the pin `7169e651`, with its generator, its reference
data and its port-only test file. Pie has no upstream spec file. All 20 tests of the unit pass. The
generator gives byte-identical data on each run.

All paths are relative to `packages/flutter_chartjs/`. `<scratch>` is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad`.
The logs and the probes are in `<scratch>/wave3/U-pie/`. No file of that folder is in the
repository.

## Files that the unit changed

All files are new. The unit changed no other file.

| File | Content |
|---|---|
| `lib/src/controllers/controller.pie.dart` | The port of `controller.pie.js`: `PieController extends DoughnutController`, with `id`, `defaults` and `jsClass`. |
| `tool/reference/controller_pie_reference.mjs` | The generator: the 4 cases of Chart.js ADR 0030 §7 and 4 `interfaces:` cases (8 cases). |
| `test/port/controllers/controller_pie_reference.dart` | The generated data (511,303 bytes, one file). |
| `test/port/controllers/controller.pie_test.dart` | The port-only tests: the reference cases, the themed twins and the group `interfaces`. |
| `doc/phase7/review/wave3/U-pie-report.md` | This report. |

## The port (lib)

- The file has the 24 upstream lines in the upstream order: the import of
  `controller.doughnut.dart` (`:1`), the class (`:4`), `static id = 'pie'` (`:6`) and
  `static defaults` (`:11-23`) with the upstream comments. The numbers are doubles (Chart.js
  ADR 0010): `cutout: 0.0`, `rotation: 0.0`, `circumference: 360.0`, `radius: '100%'`.
- The constructor is the JS default constructor: `PieController(super.chart, super.datasetIndex,
  [super.newTarget])`.
- `PieController.jsClass` has `superclass: DoughnutController.jsClass` (Chart.js ADR 0028 §7,
  Chart.js ADR 0020 §3) and the own statics `id` and `defaults` only. The class value reads
  `descriptors` and `overrides` through the superclass chain (`JsClass.operator []`). Thus the
  legend functions of `overrides['pie']` are the doughnut tear-offs. The file does not copy them
  (IV §4.7, Chart.js ADR 0028 §6).
- `jsClass` has its own `construct` closure. Without it, `jsConstruct` uses the closure of the
  doughnut class value and makes a `DoughnutController`, where upstream makes a `PieController`.
  The test "a pie chart constructs a PieController" pins this.
- Dart does not inherit static members. `PieController.overrides` and
  `PieController.descriptors` do not exist in Dart. The library doc tells the reader to use
  `PieController.jsClass['overrides']` and `PieController.jsClass['descriptors']`.
- IV §4.8 checklist: the imports are `controller.doughnut.dart`, `core.datasetController.dart`
  (`controllerArgs` only), `js_class.dart` and `types/basic.dart`. The file has no cast. No
  `DIVERGES` marker. No new `differences.md` row. No performance form.

## Tests that the unit added

`test/port/controllers/controller.pie_test.dart` (20 tests, `@TestOn('vm')`):

- `testReferenceOrigin`, `testReferenceWidths` (0 widths: a pie chart has no text), and "the
  reference has the 4 cases of Chart.js ADR 0030 first". This test pins the names and the order
  of the 4 cases exactly (the fix of U-bar-tests review F1), and the prefix `interfaces:` of each
  later case.
- The 4 cases of ADR 0030 §7, in the order of the ADR:
  - `default`: one dataset, `scaleOptions: true`, and the steps `update`, `setActive`,
    `update none`, `push`, `splice`, `reset`, `update` (the steps of the doughnut `default`).
  - `the step toggleDataVisibility`: two datasets, toggle 1, 3, 1.
  - `two datasets`: the second dataset with `backgroundColor` per item, `borderColor` and
    `borderWidth`.
  - `the step hover`: `hoverOffset: 20`, `hoverBorderWidth: 5`, `hoverBackgroundColor` per item,
    the steps `hover (346, 100)`, `update`, `mouseout`. The generated observations show arc 0
    active after the hover.
- The 4 `interfaces:` cases (the pie rows of IV §7.3): two datasets with other `rotation` and
  `circumference` (probe `ringGeometry`); the labels of `getLabelAndValue`, sets 1 and 2; the
  legend functions of `overrides.pie` with a test legend (probe `legendItems`: the items, their
  key order, the visibility after `onClick`, the items after the click, and `same`: each function
  of `overrides.pie` is the function of `overrides.doughnut` in upstream too).
- The group `theming.md §8 test 3: the light preset`: the 4 cases with the light preset.
- The group `interfaces` (no generated value):
  - the class value extends `DoughnutController.jsClass`; `id` is `'pie'`; `defaults` is
    `PieController.defaults` with the 4 keys in the upstream order; `descriptors` and
    `overrides` are `identical` to the doughnut statics;
  - the registered scope `datasets.pie` has the keys of `datasets.doughnut` in the same order,
    the doughnut values, and `cutout` 0 (`core.typedRegistry.js:84-92`);
  - a pie chart constructs a `PieController`, and its meta type is `'pie'`;
  - `generateLabels` of `overrides.pie` throws a `TypeError` without a legend;
  - `onClick` of `overrides.pie` toggles index 1 and updates the chart once;
  - the legend functions of `overrides.pie` are the same function in two reads, and `identical`
    to the functions of `overrides.doughnut` (IV §7.3, row "the option value").
- D12: `_undefinedAxisIds` and `_observationAxisIds` are copies of the doughnut test file, with
  the reason in the doc. The pie has the empty doughnut `linkScales`, so the JS meta keeps the
  axis ids `null`.
- `main()` starts with `Chart.register([PieController.jsClass]);` (work plan §0 item 6, TS §2).
  `flutter_test_config.dart` registers the parent class (the doughnut controller) already.

### The data of the second dataset (a hit tie)

This section gives the wrong state of the tie. The section "Fixes", F1, gives the correct state.

The first run used the data of the doughnut generator for the second dataset (`[5, 15, 10, 20]`).
The case `the step toggleDataVisibility` then failed at step 2 in both groups: query 10 (`index`,
`intersect: false`, axis `xy`) at the hit point `(256, 288)` gave `[0, 1]` in the port and
`[0, 2]` upstream. Probe `<scratch>/wave3/U-pie/probe_tie.mjs`: with the indices 1 and 3 hidden,
the arc centers of dataset 1, indices 1 and 2, are symmetric to the vertical axis through the
chart center. Their distances to the point are 55.20926099849555 and 55.20926099849552. The last
bits of `Math.cos` and `Math.sin` select the item (the limit of porting-flow.md §3, U-doughnut
open item 4). The generator now uses `[5, 15, 12, 20]` for the second dataset of `two`, with the
reason in its doc. The case then passes. The doughnut data has the same symmetry, but its tie
breaks the same way in V8 and Dart on this machine.

### Mutation checks

Each mutation ran for one run on a copy of the lib file. The file was then restored
(byte-identical to `<scratch>/wave3/U-pie/lib_backup.dart`).

| Mutation | Result |
|---|---|
| `'cutout': '50%'` in `defaults` (`mut_m1.out`) | 13 tests fail |
| an own `overrides` (a shallow copy) in `jsClass` (`mut_m2.out`) | 1 test fails (the class value test) |
| no `construct` in `jsClass` (`mut_m3.out`) | 1 test fails ("a pie chart constructs a PieController") |

## Checks

| Command (from the repository root) | Result |
|---|---|
| `dart format --set-exit-if-changed` on the 3 Dart files of the unit | 0 changed |
| `dart analyze --fatal-infos` on the 3 Dart files of the unit | No issues found |
| `flutter test test/port/controllers/controller.pie_test.dart` (from `packages/flutter_chartjs`) | +20: All tests passed (`unit_tests.out`) |
| `dart run melos run check:lib-imports` | passed, 327 files, 0 errors |
| `dart run melos run check:headers` | passed, 364 files, 0 errors |
| `dart run melos run check:js-semantics` | passed, 130 files, 0 errors |
| The generator, two runs (x64 Node.js v24.12.0, the build at the pin) | 8 cases; SHA-256 `3abfe213191944e6a8ff5a1c06f100101d7c3c1f1c3534a60f523381f62a9986` on each run (`sha1.txt`, `sha2.txt`) |

Generator command, from `packages/flutter_chartjs`:

```
/usr/bin/arch -x86_64 <scratch>/env/node-v24.12.0-darwin-x64/bin/node \
  tool/reference/controller_pie_reference.mjs <scratch>/env/chartjs-build/dist/chart.js
```

The unit did not change an interface that the gallery implements. Thus it did not run
`dart analyze` on `apps/chartjs_gallery`. The unit did not run `test:cases`, `parity:check` or the
full gate: they are for W3-int.

No `flutter_tester` process of this unit is left. The process 67820 belongs to another session
(scratchpad `ec6419b7-...`). This unit did not start it and did not stop it.

## Doc notes for W3-int

### AGENTS.md

- Layout, `lib/src/controllers/`: "`controller.pie.dart` has `PieController extends
  DoughnutController` with the statics `id` and `defaults`. `PieController.jsClass` extends
  `DoughnutController.jsClass` and has its own `construct`. It reads `descriptors` and
  `overrides` through the superclass chain: the legend functions of `overrides['pie']` are the
  doughnut tear-offs (Chart.js ADR 0028 §6). Dart has no `PieController.overrides`: read
  `PieController.jsClass['overrides']`."
- Layout, the `index.dart` text: add `PieController` (`index.js:6`).
- Layout, `test/port/`: "`controller.pie_test.dart` compares the pie charts of
  `tool/reference/controller_pie_reference.mjs` (data `controller_pie_reference.dart`). Pie has
  no spec file."
- Tests, the generator list: add pie to the controllers of phase 7.
- Tests, the axis ids (D12): "The doughnut and pie test files map the expected `null` of
  `xAxisID` and `yAxisID` to `undefined` (`_undefinedAxisIds`): their empty `linkScales` keeps
  the JS `null`, and the Dart field is a `String?`." If W3-int moves the rule into
  `controller_chart_harness.dart`, the two copies go and the note names the harness.

### porting-flow.md

- §3, the hit ties (this text is wrong; use the text of the section "Fixes", F1): "The pie generator changes the data of its second dataset to `[5, 15, 12,
  20]`: with `[5, 15, 10, 20]` and the indices 1 and 3 hidden, two arc centers are symmetric to
  the vertical axis, and the tie broke to another element in the port (wave 3, U-pie)." The
  sentence "No case of wave 2 has such a tie" stays true for wave 2.
- §5, the phase 7 row: wave 3 adds `controller.pie` (4 reference cases and 4 themed twins, 4
  `interfaces:` cases, 6 pin tests; no spec file).

### performance.md

- No figure. The unit adds no fast path and no loop. §13.7 (the open list): no new item. §13.4
  (data sizes): `controller_pie_reference.dart` is 511,303 bytes.

### differences.md

- No new row. No new marker.

### status.yaml

- New row `src/controllers/controller.pie.js`: "ported (`PieController` extends
  `DoughnutController` and changes only the `defaults`. `PieController.jsClass` is the class as a
  value with the own statics `id` and `defaults`; it extends `DoughnutController.jsClass` and
  reads `descriptors` and `overrides` through the superclass chain, so the legend functions are
  the doughnut functions ([Chart.js ADR 0020](adr/0020-registry-and-component-classes.md) §3,
  [Chart.js ADR 0028](adr/0028-controller-interfaces.md) §6, proposed). Not a pure layer: it
  imports `controller.doughnut`. `test/port/controllers/controller.pie_test.dart` compares 8
  charts with upstream (the 4 cases of Chart.js ADR 0030 §7 and 4 `interfaces:` cases of
  Chart.js ADR 0028), the 4 charts of §7 again with the light preset, and 6 tests of the class
  value, the registered defaults and the legend functions
  ([Chart.js ADR 0030](adr/0030-controller-test-strategy.md), proposed))"
- Port-only rows for `tool/reference/controller_pie_reference.mjs` and
  `test/port/controllers/controller.pie_test.dart` in the form of the doughnut rows.
- `src/controllers/index.js` and `src/index.ts`: add `PieController`.
- `test/specs/controller.doughnut.tests.js`: remove the `blocked: controller.pie` part of the
  text when W3-int removes the skip of `:4` (D12).
- Then `dart run melos run parity`.

## Open items

1. **The registration (W3-int).** Remove `Chart.register([PieController.jsClass]);` and the
   comment paragraph about it from `main()` of `controller.pie_test.dart` when
   `flutter_test_config.dart` registers the wave. Then the file comment says that
   `flutter_test_config.dart` registers the pie controller.
2. **`controller.doughnut.tests.js:4` (D12, W3-int).** The case reads `Chart.controllers.pie`.
   Remove its `skip: 'blocked: controller.pie'` when `PieController` is in the `controllers`
   Map. No other line changes.
3. **The axis-id rule (D12, W3-int).** `controller.pie_test.dart` has a copy of the doughnut
   `_undefinedAxisIds` and `_observationAxisIds`. The two copies can move into
   `controller_chart_harness.dart` (for example: Dart `null` matches JS `null` and `undefined`
   for the keys `xAxisID` and `yAxisID`). The unit did not change the harness: it is not in the
   row of U-pie.
4. **Hit ties (phase lead).** The generated cases compare the hit queries exactly. Near ties at
   the last bit are frequent in the arc charts. A scan probe (`<scratch>/wave3/U-pie/tie_scan_lib.mjs`,
   `scan_pie.out`, `scan_doughnut.out`) finds 63 pairs of nearest centers within 1e-9 in the 8 pie
   cases and 199 in the 27 doughnut cases. The scan does not apply the filters of each query
   mode, so most pairs do not change a result. On this machine, all queries of both files agree
   with V8. Another OS can give other last bits of `Math.cos` and `Math.sin` in Dart and break a
   tie to another element. The CI legs on ubuntu and Windows show if this occurs.
5. **IV §7.3, row "doughnut, pie: the rotation extents".** As in the doughnut file,
   `_getRotationExtents` keeps its underscore. The probe `ringGeometry` reads the public results
   of the extents (`offsetX`, `offsetY`, `outerRadius`, `innerRadius`).

## Fixes

The review (`U-pie-review.md`) has 3 confirmed findings. The fixer changed 2 files of the U-pie
row: `tool/reference/controller_pie_reference.mjs` (a comment only) and
`test/port/controllers/controller.pie_test.dart`. The probes and the logs are in
`<scratch>/wave3/U-pie-fix/`.

### F1: the state of the hit tie (fixed)

The doc of `two` in the generator and the section "The data of the second dataset (a hit tie)"
gave the wrong state. The probes of the review (`<scratch>/wave3/U-pie-review/step2_node.out`,
`step2_dart.out`, `tie_node.out`, `tie_dart.out`) show the correct state:

- With the indices 1 and 3 hidden, V8 and Dart agree bit for bit. Both give `[[0, 2], [1, 2]]`.
- The failure of the old data `[5, 15, 10, 20]` is at step 2 of `the step toggleDataVisibility`.
  The steps count from 0. Step 2 is the third toggle: then only the index 3 is hidden.
- The arc centers of dataset 1, indices 1 and 2, are symmetric to the line x + y = 512 through
  the chart center. Hit point 12, `(244, 268)`, is on that line.
- Query 10 is `['index', false, 'xy', false]`. V8 gives `Math.sin(3.665191429188092) =
  -0.4999999999999997` (`bfdffffffffffffb`). Dart gives `-0.4999999999999998`
  (`bfdffffffffffffc`). Thus V8 gets the distances 61.579571549417345 and 61.579571549417324
  and selects index 2. Dart gets two equal distances (61.579571549417345) and keeps index 1.
- The `nearest` mode at that point also differs: Dart `[[1, 1], [1, 2]]`, V8 `[[1, 2]]`.

The data change to `[5, 15, 12, 20]` stays: it is a correct fix. The fix changes only the doc
of `two`. It now names step 2, the line x + y = 512, the point and the query, and the last bit
of `Math.sin`.

The corrected text for porting-flow.md §3 (W3-int), in place of the text of the section
"porting-flow.md" above: "The pie generator changes the data of its second dataset to `[5, 15,
12, 20]`. With `[5, 15, 10, 20]`, step 2 of `the step toggleDataVisibility` (only the index 3
hidden) puts two arc centers symmetric to the line x + y = 512, and the hit point (244, 268) is
on that line. `Math.sin(3.665191429188092)` differs by 1 ulp between V8 and `dart:math`, and the
`index` query selected another element in the port (wave 3, U-pie)." The sentence "No case of
wave 2 has such a tie" stays true for wave 2.

### F2: the `dart:math` sin of `ArcElement.getCenterPoint` (no fix in U-pie)

The finding is correct, and it is outside the files of U-pie: `lib/src/elements/element.arc.dart`
and `doc/differences.md`. The unit did not change them. The data change of F1 removes the tie
from the pie reference only. A user chart can still get the tie: a pie with the data
`[[10, 20, 30, 15], [5, 15, 10, 20]]`, the index 3 hidden and the point `(244, 268)` gives another
hit element than upstream in the `index` and the `nearest` modes. Chart.js ADR 0009 protects the
hit element. The row `js-semantics-dart-math` of `differences.md` covers only the easing and
srgb, and it says that no chart behavior changes.

**Open item for the phase lead (new item 6).** Select one of these:

1. An fdlibm port of `sin` and `cos` in `lib/src/js/` (the form of `fdlibm_log.dart` and
   `fdlibm_atan.dart`), with `third_party/fdlibm/` copies of `k_sin.c`, `k_cos.c`, `k_rem_pio2.c`,
   `e_rem_pio2.c`, `s_sin.c` and `s_cos.c`, and a call in `getCenterPoint` (element.arc.ts:448) and
   the other hit paths that read `Math.cos` or `Math.sin`.
2. A `DIVERGES(chartjs)` marker in `element.arc.dart` and a `differences.md` row that names the
   hit queries of the arc charts.

Open item 4 (the hit ties) of this report is the same limit.

### F3: the name test (fixed)

The test `the reference has the 4 cases of Chart.js ADR 0030 first` did not fail when the
generator dropped the `interfaces:` cases. The test now has the name `the reference has the 4
cases of Chart.js ADR 0030 first, then the 4 interfaces: cases`, and it compares the full list
of the 8 names in their order. The probe `<scratch>/wave3/U-pie-fix/names_probe.dart` (output
`names_probe.out`) applies the new comparison to 3 lists: the 4 ADR names only fails, a list
without one `interfaces:` case fails, and the 8 names pass.

### Check results

| Check | Result |
|---|---|
| Rerun of the generator with x64 Node.js v24.12.0 and the build at the pin (`gen.out`) | 8 cases, 0 widths; `controller_pie_reference.dart` is byte-identical to the copy before the rerun (`before.dart`, `cmp`) |
| `dart format --output=none --set-exit-if-changed test/port/controllers/controller.pie_test.dart` | 0 changed |
| `dart analyze --fatal-infos test/port/controllers/controller.pie_test.dart` | No issues found |
| `flutter test test/port/controllers/controller.pie_test.dart` (from `packages/flutter_chartjs`, `test.out`) | +20: All tests passed |

No `flutter_tester` process of the fixer stays.
