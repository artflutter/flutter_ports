# Wave 3, unit U-pie: adversarial fidelity review

## Result

The port of `controller.pie.js` agrees with the pinned upstream file. This review found no
behavior difference in the files of the unit. It found 3 items: one wrong diagnosis in the
generator comment and in the report (F1), one hit-element difference outside the unit (F2), and
one weak test (F3). No item blocks the unit.

The paths are relative to `packages/flutter_chartjs/`. `<review>` is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave3/U-pie-review`.
The Node.js runs used the x64 build of Node.js v24.12.0 and the build of Chart.js at the pin. They
ran from a copy of `tool/reference/` in `<review>/mirror/` (no file of the repository changed).
The Dart probes ran with `flutter test <review>/<file>` from `packages/flutter_chartjs`. No
`flutter_tester` process of this review is left. The process 67820 was there before the review
started (`<review>/pids_before.txt`). This review did not stop it.

## Findings

### F1 (low, confirmed): the generator comment and the report give the wrong state for the hit tie

`tool/reference/controller_pie_reference.mjs:106-115` (the doc comment of `two`) and the report
section "The data of the second dataset (a hit tie)" give this cause for the failure with the data
`[5, 15, 10, 20]`: "with the indices 1 and 3 hidden", the hit point `(256, 288)`, two arc centers
"symmetric to the vertical axis", and the distances 55.20926099849555 and 55.20926099849552. The
report also proposes this text for `porting-flow.md` §3 (W3-int).

The probes show that this state is not the cause:

- In the named state (indices 1 and 3 hidden, point `(256, 288)`), Dart and V8 give the same bits
  for the angles, `cos`, `sin`, the centers and the distances. Both give `[[0, 2], [1, 2]]` for
  the query `index`, `intersect: false`, axis `xy` (`<review>/tie_node.out`,
  `<review>/tie_dart.out`; probes `mirror/packages/flutter_chartjs/tool/reference/review_tie_probe.mjs`
  and `tie_probe_test.dart`).
- The failure is at `step 2` of the harness. The harness counts the steps from 0. Thus it is the
  state after the third toggle: only index 3 is hidden. A rerun of the old data reproduces it:
  `at location [12][10][0][1] is <1.0> instead of <2>` (`<review>/old/old_data_test.dart`,
  `<review>/old_data_dart.out`; data from `review_pie_old.mjs`).
- In that state, point 12 is `(244, 268)` and query 10 is `['index', false, 'xy', false]`. The
  centers of dataset 1, indices 1 and 2, are `(287.875, 311.209119491258)` and
  `(200.79088050874202, 224.125...)`. They are symmetric to the line `x + y = 512` through the chart
  center, and the point is on that line. V8 gives `Math.sin(3.665191429188092)` =
  `-0.4999999999999997` (`bfdffffffffffffb`). Dart gives `-0.4999999999999998`
  (`bfdffffffffffffc`). Thus V8 gives the distances 61.579571549417345 and 61.579571549417324
  (index 2 is nearer). Dart gives 61.579571549417345 for both and keeps the first item (index 1).
  The query `nearest` gives `[[1, 2]]` in V8 and `[[1, 1], [1, 2]]` in Dart
  (`<review>/step2_node.out`, `<review>/step2_dart.out`; probes `review_step2_probe.mjs` and
  `step2_probe_test.dart`).

The new data `[5, 15, 12, 20]` is a correct fix: no state of the case has the symmetry. Only the
text is wrong. Fix: in the doc comment of `two`, write the state of step 2 (only index 3 hidden),
the point `(244, 268)`, the symmetry to the diagonal through the chart center, and the 1-ulp
difference of `Math.sin`. Give W3-int the same text for `porting-flow.md` §3.

### F2 (medium, confirmed, outside the unit): `Math.sin` of `ArcElement.getCenterPoint` changes the hit element, and no `differences.md` row records it

Owner: the phase lead (the files are `lib/src/elements/element.arc.dart` and `doc/differences.md`,
not files of U-pie).

The probe of F1 shows a reachable pie chart where the hit items differ from upstream. The data is
`[[10, 20, 30, 15], [5, 15, 10, 20]]` with index 3 hidden, and the point is `(244, 268)`. The query
`index` gives `[[0, 1], [1, 1]]` in Dart and `[[0, 2], [1, 2]]` in V8. Chart.js ADR 0009 protects
the hit element. The cause is the `dart:math` `sin` in `getCenterPoint` (`element.arc.dart:1136`,
element.arc.ts:448). It is 1 ulp from the fdlibm `sin` of V8 at `3.665191429188092`.

`porting-flow.md` §3 (lines 807-809) records the limit. But the row `js-semantics-dart-math` of
`differences.md` names only `helpers.easing` and `srgb`, and it says "No pixel and no chart
behavior changes". No row names `element.arc.dart` or a hit query. The package already has the
fdlibm ports `fdlibm_log.dart` and `fdlibm_atan.dart` for the same type of difference. Decide one
of: an fdlibm port of `sin` and `cos` (with `__kernel_sin`, `__kernel_cos` and
`__ieee754_rem_pio2`) for the arc centers, or a `DIVERGES(chartjs)` marker and a `differences.md`
row for the hit ties of the arc elements. Open item 4 of the report (the scan of 63 and 199 near
ties) is the same issue.

### F3 (low, confirmed): the name test does not pin the `interfaces:` cases

`test/port/controllers/controller.pie_test.dart:228-237` pins the 4 names of Chart.js ADR 0030 §7
and the prefix of each later name. It does not pin the 4 `interfaces:` cases. A generator that
drops them gives a passing test file. Then the generated pins of IV §7.3 for pie (the rotation
extents, the labels of `getLabelAndValue`, the legend items and `same`) go away without a failure.
Probe: `<review>/names_probe.dart` runs the test logic on the 4 names only and prints
`the name test passes: true` (`<review>/names_probe.out`). The test does what the report says. The
doughnut test has the same form. Fix: compare the full list of the 8 names.

## Items without a defect

- `lib/src/controllers/controller.pie.dart` against `controller.pie.js:1-24`: the import, the
  class, `static id`, `static defaults` with the 4 keys in the upstream order and the upstream
  comments, and the default constructor. The numbers are doubles (Chart.js ADR 0010). No cast, no
  marker, no performance form. The header is correct.
- `PieController.jsClass`: the own statics `id` and `defaults` are the own keys of the JS class
  (`Object.keys(PieController)` is `['id', 'defaults']` in Node.js). `descriptors` and
  `overrides` come through the superclass chain, as the JS static prototype chain gives them
  (`PieController.descriptors === DoughnutController.descriptors` is true in Node.js). The
  `construct` closure is necessary (mutation M3 of the report).
- The registration against Node.js (`<review>/probe_reg.mjs`, `<review>/review_probe_test.dart`,
  `<review>/review_probe_dart.out`): the keys of `datasets.pie` (11 keys, same order), the
  descriptors of `datasets.pie` (`_scriptable`, `_indexable`, the doughnut functions),
  `overrides.pie` is a new object (not the doughnut object, as `set` of core.defaults.js:110
  merges into a new scope), its keys `aspectRatio` and `plugins`, and the legend functions are the
  doughnut functions.
- A pie chart with a doughnut dataset: `_getRotationExtents` reads only the datasets of its own
  type. Dart and V8 give the same `offsetX`, `offsetY`, `outerRadius` and `innerRadius` for both
  controllers (`<review>/mixed_node.out` and `review_probe_dart.out`; Dart `-0.0` against JS `0`
  for one `offsetY` is the sign of a zero in a display value).
- An array `borderDash` stays an array on each arc (the descriptors of the doughnut apply to
  `datasets.pie`).
- The hover case: `(346, 100)` makes arc 0 active, with `offset` 20 and `#ff0000`
  (`<review>/hover_node.out`).
- The cited lines are correct: controller.pie.js:4, 6, 11-23; core.typedRegistry.js:28-31, 84-92;
  core.controller.js:841-842; core.datasetController.js:306-307; controller.doughnut.js:143,
  187-206, 224-238; platform.basic.js:20-22; platform.base.js:80.
- D10 does not apply (the file has no loop). D11 is not in this unit. D12: the axis-id helpers are
  exact copies of the doughnut helpers, with only the doc text and the data name changed.
- The 7 records with `blocked: controller.pie` in `classification/all.json` are in
  `core.controller_test.dart`. L3 owns them (work plan §4). The skip of
  `controller.doughnut.tests.js:4` is for W3-int (D12). No skipped case of the unit has the verdict
  `phase7`.
- The generator stops unless Node.js is x64 and the build is at the pin. A rerun in the mirror gives
  a byte-identical `controller_pie_reference.dart`.
- `flutter test test/port/controllers/controller.pie_test.dart` on the current tree (with the
  X-fix edits of `controller.doughnut.dart` in progress): `+20: All tests passed!`.
