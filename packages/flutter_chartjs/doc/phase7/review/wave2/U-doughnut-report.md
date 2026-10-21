# Wave 2, unit U-doughnut: report

## Status

Done. The unit ports `controller.doughnut.js` at the pin `7169e651`, with its generator, its
reference data, its port-only test file and its spec file. All the tests of the unit pass. The
generator gives byte-identical data on each run. `test:cases` reports 0 missing and 0 failed cases
in `controller.doughnut.tests.js`.

One spec case does not run yet: `:4` "should be registered as dataset controller" also reads
`Chart.controllers.pie`. The pie controller comes in wave 3. The case has its full body and the
skip reason `'blocked: controller.pie'` (open item 1).

All paths are relative to `packages/flutter_chartjs/`. `<scratch>` is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad`.
The logs and the probes are in `<scratch>/wave2/U-doughnut/`.

## Files that the unit changed

All files are new.

| File | Content |
|---|---|
| `lib/src/controllers/controller.doughnut.dart` | The port of `controller.doughnut.js`: `_getRatioAndOffset`, `DoughnutController` with `id`, `defaults`, `descriptors`, `overrides` and `jsClass`, and the legend functions `_generateLabels`, `_labelItem` and `_onClick`. |
| `tool/reference/controller_doughnut_reference.mjs` | The generator: the 15 cases of Chart.js ADR 0030 §7, 8 `parsed:` cases and 4 `interfaces:` cases (27 cases). |
| `test/port/controllers/controller_doughnut_reference.dart` | The generated data (1,137,488 bytes, one file). |
| `test/port/controllers/controller.doughnut_test.dart` | The port-only tests: the reference cases, the themed twins, and the groups `parsed data` and `interfaces`. |
| `test/specs/controller.doughnut_test.dart` | The spec port: 13 cases with the exact names. |
| `doc/phase7/review/wave2/U-doughnut-report.md` | This report. |

## The port (lib)

- Each method and function follows `controller.doughnut.js` line by line, in the upstream order of
  statements and calls.
- Parsed items (Chart.js ADR 0027): `parse` reads with `jsGetIndex` and writes with
  `jsSetIndex`. It has the one cast of PD §5.1 item 4 (`jsGet(getDataset(), 'data')! as
  List<Object?>`). With `parsing: false`, `meta.parsed` is the data List (identity). The key of
  `{key = 'value'}` is `valueOrDefault(jsGet(parsing, 'key'), 'value')`, with the cast `as String`
  at `resolveObjectKey` (ADR 0027 §4). `_circumference`, `calculateTotal` and `getLabelAndValue`
  read `jsGetIndex(meta.parsed, i)`. `=== null` is Dart `== null`.
- Raw option values (ADR 0027 §7): `rotation - 90`, `toRadians(circumference)` and the ring weight
  apply `jsToNumber`. `getMaxBorderWidth() + getMaxOffset(arcs) + options.spacing` is `jsAdd`:
  a string `spacing` joins, as upstream. Each later use applies `jsToNumber`. `x || 0` in
  `Math.max` is `jsOrZero`. `|| 1` of `_getVisibleDatasetWeightTotal` is `jsTruthy`.
- Interfaces (Chart.js ADR 0028): the controller reads the chart, the metas and the other
  controllers through `lib/src/types/`. The one class cast is `controller! as
  DoughnutController` in `_getRotationExtents` (§1). `meta.total` is the typed field.
  `calculateCircumference` tests `total != null && total > 0`. `getLabelAndValue` returns
  `({Object? label, String value})` with `labels[index] || ''`.
- The legend functions (ADR 0028 §6, IV §4.7): two private top-level functions and the helper
  `_labelItem` for the `map` callback. `overrides` holds their tear-offs. `chart.legend!` throws a
  `TypeError` for no legend. The keys of each item have the order of the upstream literal.
- The descriptors have the form of `core.defaults.dart` (IV §4.7). The `defaults` have
  `spacingMode: 'angular'` (ledger row #12238).
- The constructor body sets `enableOptionSharing` and the four fields after the constructor of
  `DatasetController`, as upstream. `innerRadius`, `outerRadius`, `offsetX` and `offsetY` are
  `double?`: Dart `null` is the JS `undefined` of the constructor. `updateElements` writes
  `undefined` for a `null` radius and NaN for `centerX + undefined`.
- `getMaxBorderWidth(arcs)` with an `arcs` argument keeps `controller` as Dart `null`. The first
  arc then throws a `TypeError` at `controller!`, as `undefined.resolveDataElementOptions` does
  upstream.
- Private members keep their underscore: no other upstream module reads `_getRotation`,
  `_getCircumference`, `_getRotationExtents`, `_circumference` or the ring weight functions
  (Chart.js ADR 0012).
- `update` and `updateElements` read `chart.chartArea!` at the start of the method. Upstream reads
  `chartArea.width` after `getMaxBorderWidth()` and `getMaxOffset(arcs)`. Only option resolutions
  lie between the two reads. The chart area always exists when a controller updates.
- `getDataVisibility` stays one upstream call for each arc (ADR 0027 §8). No hoist, no memo.
- No `DIVERGES` marker. No new `differences.md` row.

## Tests that the unit added

`test/port/controllers/controller.doughnut_test.dart` (51 tests, `@TestOn('vm')`):

- `testReferenceOrigin`, `testReferenceWidths` (0 widths: a doughnut chart has no text), and
  "the reference has the 15 cases of Chart.js ADR 0030 first" (the first 15 names have no prefix,
  each later name has the prefix `parsed:` or `interfaces:`: the fix of U-bar-tests F1).
- 27 reference cases. The 15 cases of ADR 0030 §7: `default` (with `scaleOptions` and the steps
  `update`, `setActive`, `update none`, `push`, `splice`, `reset`, `update`), `cutout '25%'`,
  `cutout a number`, `partial rotation and circumference`, `two datasets with weight`,
  `the step toggleDataVisibility`, `spacing with the default spacingMode`,
  `spacing with spacingMode 'proportional'`, `spacing with spacingMode 'parallel'`,
  `offset and hoverOffset with the step hover`, `borderAlign 'inner'`,
  `the step reset with animateRotate`, `the step reset with animateScale`, `parsing false`,
  `labels that are arrays`.
- The 8 `parsed:` cases (PD §7.3): object data with parsing on and off (`TypeError` at
  `initial`); `parsing: false` with `[1, '2', null]`, with object items and with `[1, null, 2]`
  (probe `parsedIsData`); object items with the default key, with a nested parsing key, and with
  the key `5` (`TypeError`).
- The 4 `interfaces:` cases (IV §7.3): two datasets with other `rotation` and `circumference`
  (probe `ringGeometry`); the labels of `getLabelAndValue`, sets 1 and 2; the legend functions
  with a test legend (probe `legendItems`: the items, their key order, the visibility after
  `onClick`, the items after the click).
- The group `theming.md §8 test 3: the light preset`: the 15 cases with the light preset.
- The group `parsed data`: `parsing: false` with `[1, '2', null]` keeps the data List and gives the
  arcs of `[1, 2, null]`; object items with a parsing key give the arcs of the numbers.
- The group `interfaces`: `meta.total` after an update is `calculateTotal()`, and `meta['total']`
  gives it (also after a toggle); `getLabelAndValue` gives the identical label List, the number
  label and `''` for `0`, `undefined` and past the end; `generateLabels` throws a `TypeError`
  without a legend; `onClick` toggles index 1 and updates the chart once (an inline plugin counts
  `afterUpdate`); the legend functions are the same function in each read of
  `overrides['doughnut']` and of `DoughnutController.overrides`.

`test/specs/controller.doughnut_test.dart` (13 cases, `@TestOn('vm')`): the 12 `phase7` records of
`all.json` have bodies. 11 run and pass. `:4` has its body and skips as
`'blocked: controller.pie'`. `:418` skips as `'blocked: plugin.tooltip'`. The `auto` group is a
comment (F-int adds it). `toBeCloseTo` is a private copy of `_toBeCloseTo` of
`element.arc_test.dart`.

Both files call `Chart.register([DoughnutController.jsClass])` first in `main()` (work-plan §0
item 6). W2-int removes these two lines.

## Checks

| Command | Result |
|---|---|
| `dart analyze --fatal-infos` on the 4 Dart files of the unit | No issues found |
| `dart format --set-exit-if-changed` on the 4 Dart files | 0 changed |
| `flutter test test/port/controllers/controller.doughnut_test.dart test/specs/controller.doughnut_test.dart` | +62 ~2: All tests passed |
| `dart run melos run test:cases` | passed, 43 files, 0 errors, 0 warnings. `controller.doughnut.tests.js`: 13 cases, 11 passed, 0 failed, 2 skipped, 0 missing |
| `dart run melos run check:lib-imports` | passed, 322 files, 0 errors |
| `dart run melos run check:headers` | passed, 359 files, 0 errors |
| `dart run melos run check:js-semantics` | passed, 128 files, 0 errors |
| The generator, 3 runs (x64 Node.js v24.12.0, the build at the pin) | SHA-256 `06093c5f44fd8e6dceba8393828ff0b780c8ba157d3562b2b42d3e4bcd3f22c4` on each run |

Generator command, from `packages/flutter_chartjs`:

```
/usr/bin/arch -x86_64 <scratch>/env/node-v24.12.0-darwin-x64/bin/node \
  tool/reference/controller_doughnut_reference.mjs <scratch>/env/chartjs-build/dist/chart.js
```

No `flutter_tester` process of this unit is left. The process 67820 belongs to another session.
This unit did not start it and did not stop it.

### Extra probe (not in the repository)

`<scratch>/wave2/U-doughnut/probe_edges.mjs` and `probe_edges_test.dart` compare 18 more charts:
a string `spacing`, `offset`, `rotation`, `circumference` and `weight`, a `null` and a negative
`weight`, `cutout: '0'` and `1000`, `radius: '50%'`, `circumference: 0`, empty data, all zeros,
NaN, negative and string values, `hoverBorderWidth`, a hidden first dataset, negative rotation
extents, `parsing: false` with a Map, a List and a string, `{value: null}`, the steps toggle,
push, splice and `setDatasetVisibility`, and `reset` with `animateScale`. The controller values
(`x`, `y`, the angles, the radii, `total`, the options, the labels) agree in all 18 charts. 4
charts differ outside the controller (open items 3 and 4).

## Doc notes for W2-int

### AGENTS.md

- Layout, `lib/src/controllers/`: "`controller.doughnut.dart` has `DoughnutController` and its
  class value `DoughnutController.jsClass` (statics `id`, `defaults`, `descriptors`,
  `overrides`). The `overrides` hold the tear-offs of the private top-level legend functions
  `_generateLabels` and `_onClick` (Chart.js ADR 0028 §6). `controller.pie.dart` imports it."
- Layout, the `index.dart` text: add `DoughnutController` to the exports of wave 2.
- Layout, `test/port/`: "`controller.doughnut_test.dart` compares the doughnut charts of
  `tool/reference/controller_doughnut_reference.mjs` (data `controller_doughnut_reference.dart`)."
- Tests, the generator list: add doughnut to "the controllers of phase 7".
- Tests, a new bullet: "The JS reference charts get the `BasicPlatform` (a fake canvas), whose
  `updateConfig` writes `animation: false` (`platform.basic.js:20-22`). The Dart harness gives the
  platform of `platform.flutter.dart`, with the no-op `updateConfig` of `platform.base.js:80`. A
  controller generator with a case that needs an animation object (the doughnut and polar area
  `reset` cases) puts the no-op of `BasePlatform` on `BasicPlatform` before its cases." (U-polarArea
  made the same change.)

### porting-flow.md

- §3, the paragraph "Reference tests of the controllers": the platform note above, and the note of
  open item 2 (the axis ids of a doughnut meta).
- §5, the phase 7 row: wave 2 adds `controller.doughnut` (15 reference cases and 15 themed twins,
  12 pin cases, 11 of 13 spec cases pass).

### performance.md

- No figure. The unit adds no fast path. `getDataVisibility` stays one call for each arc (ADR 0027
  §8). §13.7 (the open list): no new item.

### differences.md

- No new row. No new marker.
- A candidate row for the phase lead (open item 3): `element.arc.dart` `getCenterPoint` adds a
  string `spacing` or `offset` as a number, where `element.arc.ts:459` joins the strings.

### status.yaml

- New row `src/controllers/controller.doughnut.js`: "ported (`DoughnutController` extends
  `DatasetController`. `DoughnutController.jsClass` is the class as a value with the statics
  `id`, `defaults`, `descriptors` and `overrides` ([Chart.js ADR 0020](adr/0020-registry-and-component-classes.md)
  §3). `parse` keeps the one cast of the data List and reads the parsed items with `jsGetIndex`;
  with `parsing: false`, `meta.parsed` is the data List ([Chart.js ADR 0027](adr/0027-parsed-data.md),
  proposed). A raw option value stays `Object?` until its upstream operator: a string `spacing`
  joins in `update`. The controller reads the members of other modules through `lib/src/types/`,
  and casts only the controllers of `_getRotationExtents` to `DoughnutController`
  ([Chart.js ADR 0028](adr/0028-controller-interfaces.md), proposed). The legend functions of
  `overrides` are tear-offs of top-level functions (ADR 0028 §6). From the commit pin (ledger row
  #12238), the defaults and the descriptors have `spacingMode`. Not a pure layer: it imports
  `core.datasetController`. `test/port/controllers/controller.doughnut_test.dart` compares 15
  charts with upstream, and the same 15 charts with the light preset, with 8 `parsed:` cases of
  Chart.js ADR 0027 and 4 `interfaces:` cases of Chart.js ADR 0028, and 7 tests of relations and
  identities ([Chart.js ADR 0030](adr/0030-controller-test-strategy.md), proposed))"
- New row `test/specs/controller.doughnut.tests.js`: "ported ({{passed}}/{{cases}} cases pass on
  {{platforms}}; {{skipped|case}} skipped: {{skipped:blocked: controller.pie}} `blocked:
  controller.pie` (wave 3 of phase 7: the case keeps its body) and {{skipped:blocked:
  plugin.tooltip}} `blocked: plugin.tooltip`. Each chart case is a `testWidgets` case with the
  conventions of [Chart.js ADR 0030](adr/0030-controller-test-strategy.md) §13. The fixture group
  `auto` waits for the fixture runner ([Chart.js ADR 0029](adr/0029-fixture-smoke-runner.md),
  proposed). `test/port/controllers/controller.doughnut_test.dart` covers the controller)"
- `src/controllers/index.js` and `src/index.ts`: add `DoughnutController`.
- Port-only rows for `tool/reference/controller_doughnut_reference.mjs` and
  `test/port/controllers/controller.doughnut_test.dart` in the form of the bar rows.
- `test/specs/platform.dom.tests.js`: the case with `blocked: controller.doughnut` is a lift of
  L2 (it is not in this unit's row).
- Then `dart run melos run parity`.

### upstream-ledger.md

- Row `ab79c3bf` (#12238), with the text of IV §8.6: "`controller.doughnut` ports the controller
  part at the pin: `spacingMode: 'angular'` in the defaults, `spacingMode` in the descriptors
  `_scriptable` and `_indexable` (`controller.doughnut.js:75`, `:81-82`), and the spec case
  `controller.doughnut.tests.js:49`. The reference cases `spacing with spacingMode
  'proportional'` and `'parallel'` of `controller.doughnut_test.dart` draw the spacing modes
  through the controller." U-polarArea gives the polar area part. The fixtures of the row come
  with the fixture runner.

## Open items

1. **Spec case `:4` waits for the pie controller.** The case checks `Chart.controllers.doughnut`
   and `Chart.controllers.pie`. TS §4.2 says that the 6 "should be registered" cases pass when the
   controller is registered. That is not true for this case in wave 2: the pie part fails. The
   case has its full body and `skip: 'blocked: controller.pie'`. `lift_check.py` gives the record
   wave 3 (module `controller.pie`). W3-int (or U-pie) removes the `skip:` argument when
   `PieController` is registered. No other line changes.
2. **The axis ids of a doughnut meta (harness).** `_observeDataset` of
   `controller_chart_harness.dart` (U0) maps Dart `null` of `meta.xAxisID` and `meta.yAxisID` to
   `undefined`. That is correct for a controller whose `linkScales` runs (JS writes `undefined`).
   The doughnut `linkScales` is empty: JS keeps the start value `null`
   (`core.controller.js:841-842`). The Dart field `ChartMeta.xAxisID` is `String?` and cannot
   keep both values. Thus `controller.doughnut_test.dart` maps the expected `null` of these two
   keys to `undefined` (`_undefinedAxisIds`, with its reason in the doc). No other key changes.
   No reader of the port sees the difference. U-pie needs the same map, or the phase lead moves
   the rule into the shared harness (for example: Dart `null` matches JS `null` and `undefined`
   for the two keys).
3. **`element.arc` `getCenterPoint` with a string `spacing` or `offset` (outside this row).**
   `element.arc.ts:459` computes `(innerRadius + outerRadius + spacing + offset) / 2`. A string
   option joins: `spacing: '5'` gives `'365.255' + '0'`, and the center moves (probe: x 347.31 in
   JS, 348.56 in the port; `offset: '6'` moves the center by 850 px). `element.arc.dart:1121-1124`
   applies `jsToNumber` to both. The center is the tooltip position and the point of the
   `nearest` and `index` hit modes (Chart.js ADR 0009 protects the hit element). The fix is
   `jsAdd` in `element.arc.dart` (phase 4), or a `differences.md` row. The phase lead decides.
4. **Exact ties in the hit queries (harness method).** The harness queries the midpoint of two
   neighbor arc centers. For symmetric arcs, the two distances are equal up to the last bit. V8
   and Dart give `Math.cos` and `Math.sin` different last bits, so the tie can break to another
   element (probe: "toggle and push", JS distances 146.50601500714072 and 146.5060150071407).
   The 27 cases of the unit have no such tie. A later case with symmetric arcs can fail for this
   reason only. The phase lead can record the limit in the harness doc.
5. **IV §4.8 checklist and the `labels` cast.** `_generateLabels` casts `jsGet(data, 'labels')!
   as List<Object?>` before the `map` callback, as the sketch of IV §4.7 does. The checklist of
   IV §4.8 allows only `types` interfaces and `DoughnutController` (the same point as U-bar-lib
   review F4). A value without `map` throws a `TypeError` upstream too.
6. **The rotation extents probe.** IV §7.3 asks for "the rotation extents of the generator".
   `_getRotationExtents` keeps its underscore (ADR 0012: no other upstream module reads it). Thus
   the probe `ringGeometry` reads the public results of the extents: `offsetX`, `offsetY`,
   `outerRadius` and `innerRadius` of each controller. Two quarter circles at 0° and 90° give a
   half circle of extents, so a wrong extent changes all four values.
7. **Spec text.** PD §5.5 shows `getter = (double i) => ...` inside `parse` and
   `jsSetIndex<Object?>(meta.parsed, i.toInt(), getter(i))`. The code has these forms. ADR 0030
   §7 does not name the platform patch of the generator (see the AGENTS.md note above).

## Fixes

The fixer read the review `U-doughnut-review.md` (findings R1 to R4, all confirmed) and changed
only the files of the unit. The scratch folder of the fixes is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave2/U-doughnut-fix/`
(`<fix>` below). No file of `<fix>` is in the repository.

### R1. `_onClick` with a legend item index that is not a number: fixed in the unit

- `_onClick` now gives `_legendIndex(jsGet(legendItem, 'index'))` to `toggleDataVisibility`.
  `_legendIndex` is the form of `controller.polarArea.dart` (fix F1 of the U-polarArea review):
  the key is `jsToString(index)`; when `jsNumberToString(jsToNumber(key))` is the same key, the
  function gives that number, else NaN (the key `'NaN'`, which matches no data index). Thus the
  port writes the upstream key for each number text, and no data index for any other key. The
  doc of `_onClick` and of `_legendIndex` replaces the old doc, which said that only an absent
  index differs.
- A residual stays, the same as in polar area: `moveNumericKeys` (core.controller.js:72) moves a
  key such as `''` or `'01'` after a data insert or remove, and the port moves no `'NaN'` key.
  Only a key parameter in `types.Chart.toggleDataVisibility` removes it. That interface is not a
  file of the unit.
- For the phase lead: ADR 0028 §6 still gives the form
  `toggleDataVisibility(jsToNumber(jsGet(legendItem, 'index')))` and says that no reader sees
  the difference. The code now differs from that text, because the old form changes the arcs
  and the hit element (Chart.js ADR 0009, accepted). The ADR text and a `differences.md` row
  for the residual are decisions of the phase lead. The fixer did not change the ADR.
- New tests: 17 cases "onClick with the index <name> toggles the upstream key" in
  `test/port/controllers/controller.doughnut_test.dart`. The expected visibility comes from the
  x64 Node.js probe `<fix>/onclick_keys.mjs` on the build at the pin (output
  `<fix>/onclick_node.out`): `null`, `undefined`, `true`, `false`, `''`, `'01'`, `'1.0'`,
  `' 1'`, `NaN`, `'-0'`, `{}` and `1.5` give `111`; `'1'` and `1` give `101`; `'2'` and `[2]`
  give `110`; `-0` gives `011`.
- Mutation check: with the old form `jsToNumber(...)` put back for one run, 8 of the 17 cases
  fail (`<fix>/mutation.out`, `+9 -8`). The file was then restored (byte-identical to
  `<fix>/lib_backup.dart`).

### R2. Wrong citation: fixed

`test/port/controllers/controller.doughnut_test.dart` now cites
`core.datasetController.js:306-307` for the `xAxisID` and `yAxisID` writes of `linkScales`.

### R3. The ADR 0030 §7 case "`cutout` `'50%'`": fixed in the unit

The ADR wins over the plan and the generator. The generator case is now
`runControllerCase("cutout '50%'", two({cutout: '50%'}, {}))`. The unit keeps 15 ADR cases and
27 cases in total. The rerun wrote 27 cases. A second rerun gave a byte-identical file (`cmp`).
The diff of the data file changes only the case `cutout '25%'` to `cutout '50%'` (164 diff
lines: the name, the option and the ring geometry, for example `innerRadius` 159.375 to
191.25). The case list of "Tests that the unit added" above still names `cutout '25%'`: read it
as `cutout '50%'`. The case with a non-default percent is gone. The case `cutout a number` still
catches a port that ignores `cutout`.

### R4. String `data`: not fixed in the unit (outside the row)

The `TypeError` comes from the cast in `_dataCheck` of `core.datasetController.dart`, a wave 1
file. The unit cannot change it. The fixer corrected the doc of `parse` in
`controller.doughnut.dart`: the cast cannot fail in the port because `_dataCheck` throws first
for a truthy `data` that is not a List; upstream keeps a string `data`
(core.datasetController.js:386) and parses its characters. For the phase lead: a
`differences.md` row for string `data`, or a decision that no row is necessary.

### Checks of the fixes

| Command (from `packages/flutter_chartjs`) | Result |
|---|---|
| `dart format` on the three Dart files of the unit | 0 changed |
| `dart analyze --fatal-infos` on `controller.doughnut.dart`, both test files and the data file | No issues found |
| The generator, two runs (x64 Node.js v24.12.0, build at the pin) | 27 cases; the two outputs are byte-identical |
| `flutter test test/port/controllers/controller.doughnut_test.dart test/specs/controller.doughnut_test.dart` | +79 ~2: All tests passed (`<fix>/unit_tests.out`; +62 before, +17 new cases) |

No `flutter_tester` process of the fixer is left. The process 67820 belongs to another session.
The fixer did not start it and did not stop it.
