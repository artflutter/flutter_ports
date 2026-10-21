# Wave 2, unit U-polarArea: report

## Status

Done. All checks of the unit pass. No item blocks the unit.

The paths are relative to `packages/flutter_chartjs/`. `<scratch>` is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad`.
The probes of the unit are in `<scratch>/wave2/U-polarArea/`.

## Files

| File | Change |
|---|---|
| `lib/src/controllers/controller.polarArea.dart` (new) | The port of `src/controllers/controller.polarArea.js` at the pin `7169e651`, line by line. |
| `tool/reference/controller_polar_area_reference.mjs` (new) | The generator of the reference data (Chart.js ADR 0030 §3). |
| `test/port/controllers/controller_polar_area_reference.dart` (new, generated) | 44 cases, 41 widths, 1,600,128 bytes. SHA-256 `dd5bc7b520f91e12f2fb8e44dc5eb6238b4541e70777a7dcf6225772ba487136`. |
| `test/port/controllers/controller.polarArea_test.dart` (new) | The port-only reference tests and the pin tests. |
| `test/specs/controller.polarArea_test.dart` (new) | The port of `test/specs/controller.polarArea.tests.js`. |
| `doc/phase7/review/wave2/U-polarArea-report.md` (new) | This report. |

The unit changed no shared file and no file of another unit.

## The lib file

- `PolarAreaController extends DatasetController`, with `id`, `defaults`, `overrides` and
  `jsClass` (Chart.js ADR 0020 §3). The `defaults` and the `overrides` keep the upstream keys
  and their order.
- `getLabelAndValue` (PD §5.6, IV §4.4): `chart.data['labels']`, `jsTruthy(label) ? label : ''`,
  and `formatNumber(jsToNumber(jsGetKey(jsGetIndex(meta.parsed, index), 'r')), locale)`.
  `formatNumber` takes a `double`. Thus the port applies `jsToNumber`.
  `Intl.NumberFormat.prototype.format` applies `ToIntlMathematicalValue`: for a string with more
  digits than a `double` keeps, upstream formats the exact decimal. The difference is in the
  digits only (Chart.js ADR 0009).
- `parseObjectData`: `jsCall(parseObjectDataRadialScale, [meta, data, start, count], thisArg:
  this)! as List<AnyObject>`. This is `_parseObjectDataRadialScale.bind(this)(...)`.
- `getMinMax` (PD §5.6, ADR 0027 §7): the raw values in `Object? min` and `Object? max`,
  `jsLessThan` for `<` and `>`, and the `ToNumber` of each end in the record.
- `_updateRadius`: `jsMin`, `jsMax`, two literal reads of `opts.cutoutPercentage`, and
  `chart.chartArea!` (a `TypeError` for a chart without a layout, as upstream).
- `updateElements` (IV §4.5): one cast `cachedMeta.rScale! as types.RadialLinearScale` at `:166`.
  The `!` is for the lint `cast_nullable_to_non_nullable`: a Dart `null` gives a `TypeError` at
  the same place. The #12238 hunk (`:204-210`) is line by line with `== 0` and
  `== 'angular'`, no `is num`, and no marker. The controller does not set
  `enableOptionSharing`.
- `countVisibleElements` is public, as upstream. It returns a `double`.
- `_computeAngle`: `jsTruthy(angle) ? angle : defaultAngle`, then `jsToNumber` at `toRadians`.
- The legend functions (IV §4.7): the top-level functions `_generateLabels`, `_item` and
  `_onClick`. The read of `chart.legend!.options` is inside the test (`:41`). The item keys have
  the order of `:47-58`. `'index'` is a `double`. `overrides` holds the tear-offs.
- `innerRadius` and `outerRadius` are `double?` fields. Dart `null` is the `undefined` of
  `:93-94`.
- Imports: `core.datasetController.dart`, `helpers.config.dart`, `helpers.intl.dart`,
  `helpers.math.dart`, the JS runtime and `lib/src/types/`. No concrete scale, element or chart
  module.

## Tests

### `test/port/controllers/controller.polarArea_test.dart` (63 tests)

- `main()` starts with `Chart.register([PolarAreaController.jsClass])` (work plan §0 item 6).
- The origin test, the widths test, and the test "the reference has the 9 cases of Chart.js ADR
  0030 first". This test checks each of the first 9 names and each later name (the fix F1 of the
  wave 1 review).
- The 9 cases of ADR 0030 §7: `default` (two datasets, the scale options, the steps `update`,
  `setActive`, `update none`, `push`, `splice`, `reset`, `update`), `startAngle`, `angle` (an
  indexable `angle` with `0` and `null`, and a scriptable `angle`), `toggleDataVisibility`,
  `spacing with the default spacingMode`, `spacing with the chart-level spacingMode override`,
  `scale r min and max`, `reset` (`animateScale` and `animateRotate`, see Open item 1), and
  `point labels`.
- The themed twins: the 9 cases with the light preset, and the stale-key test.
- 7 `parsed:` cases (PD §7.3, polar area rows): `[{r: 1}, {}, {r: 3}]` and
  `[{r: 1}, {r: null}, {r: 3}]` (count 2 and 3), `[5, 3]` and `[[5], [3]]` (radii NaN, no
  throw), string and number `r` values (range `10..9` and `9..30`, scale max 9 and 30), and a
  `null` item (`TypeError` at `initial`).
- `interfaces:` cases (IV §7.3, polar area rows): an `rScale` that is not radial (`TypeError` at
  `initial`), the two label sets of `getLabelAndValue`, the 11 rows of the ADR 0028 table
  (question 5) with a second `update()`, the hover row (`setActive` on arc 0 and `update()`),
  and the legend functions with and without labels.
- The group `the option-sharing subclass`: the same 11 rows on the type `polarAreaSharing`, a
  class value with `superclass: PolarAreaController.jsClass` and its own id. `setUp` registers
  it, and `tearDown` unregisters it. 5 rows throw a `TypeError` at `initial`. The other 6 rows
  give the values of the table. 5 of them have frozen options. The row with the scriptable
  `spacing` has options that are not frozen.
- The probes of the key `extra`: `polarState` (`countVisibleElements()`, the range of
  `getMinMax()`, `innerRadius`, `outerRadius`, and `jsObjectIsFrozen` of each arc option) and
  `legend` (`generateLabels` without a legend, then with a test legend, the item keys in order,
  `onClick({}, {index: 1}, legend)`, `getDataVisibility(1)`, the new `hidden` values, and the
  outer radii).
- The group `parsed data`: string `r` values give the range `10..9`, and numbers give `9..30`.
- The group `interfaces`: label 0 is the same List and the other labels keep their values; the
  same legend functions in each read of `overrides['polarArea']` and in
  `PolarAreaController.overrides`; `onClick` calls `update` one time (a recording plugin).

The generated values of the spacing rows agree with the ADR 0028 table in each cell
(`<scratch>/wave2/U-polarArea/table.mjs`).

### `test/specs/controller.polarArea_test.dart` (14 records)

- The 14 `it` cases of `controller.polarArea.tests.js` in the upstream order, with the exact
  names. 13 cases have bodies (verdict `phase7` in `all.json`). The case `:389` is
  `test(name, () {}, skip: 'blocked: plugin.tooltip')`.
- `main()` registers the controller until W2-int registers it.

### Mutation check

A probe changed `== 'angular'` of the hunk to `== 'angularX'`. Two reference cases failed:
`interfaces: spacing, elements.arc spacing 0, angular` and
`interfaces: spacing hover, elements.arc angular`. These are the rows where the hunk changes the
result (ADR 0028, question 5). The probe restored the file (`diff` gave no output).

### Throw sites

A probe (`probe_test.dart`) shows the Dart throw sites: the `rScale` of type `linear` throws at
the cast in `updateElements`. The `null` item throws at the read of `r` in `getMinMax`. Upstream
throws in the same methods.

## Checks

| Command | Result |
|---|---|
| `dart analyze --fatal-infos` on the 4 Dart files | No issues |
| `dart format --set-exit-if-changed` on the 4 Dart files | 0 changed |
| `flutter test test/port/controllers/controller.polarArea_test.dart test/specs/controller.polarArea_test.dart` | +76 ~1, all passed |
| `dart run melos run test:cases` | exit 0. `controller.polarArea.tests.js`: 14 cases, 13 passed, 0 failed, 1 skipped, 0 missing |
| The generator two more times (x64 Node.js v24.12.0, the build at the pin) | The same SHA-256 three times: `dd5bc7b5...ba487136` |
| The generator with the arm64 Node.js | It stops: "The reference is V8 on x64" |
| `dart run melos run check:headers` | passed, 359 files |
| `dart run melos run check:js-semantics` | passed, 128 files |
| `dart run melos run check:lib-imports` | passed, 322 files |

The unit changed no interface that the gallery implements. Thus it did not analyze
`apps/chartjs_gallery`. No `flutter_tester` process of this unit is left. The process 67820
belongs to another session.

## Doc notes for W2-int

### Registration

- `lib/src/controllers/index.dart`: the line `index.js:5`
  (`export {default as PolarAreaController} from './controller.polarArea.js'`) and
  `export 'package:flutter_chartjs/src/controllers/controller.polarArea.dart' show
  PolarAreaController;` in code unit order.
- `lib/src/index.dart`: the key `polarArea` of the `controllers` Map.
- Remove `Chart.register([PolarAreaController.jsClass]);` from `main()` of
  `test/port/controllers/controller.polarArea_test.dart` and
  `test/specs/controller.polarArea_test.dart`, and the comment lines that name it. Keep the
  `setUp` and `tearDown` of the group `the option-sharing subclass`: the subclass is not a
  built-in component.
- IV §7.1: `test/port/types/index_test.dart` can now use a polar area chart with a radial linear
  scale in place of the `RadialTestController`.

### `AGENTS.md`

- Layout, `lib/src/controllers/`: "`controller.polarArea.dart` has `PolarAreaController`. It casts
  the scale `r` to `types.RadialLinearScale` once (`controller.polarArea.js:166`). It ports the
  #12238 hunk with `== 0` and `== 'angular'`. `overrides` holds the legend functions
  `generateLabels` and `onClick` as tear-offs of top-level functions (Chart.js ADR 0028 §6).
  `parseObjectData` calls `parseObjectDataRadialScale` with `jsCall` and the controller as
  `thisArg`."
- Tests, the generator list: add `tool/reference/controller_polar_area_reference.mjs`. "For the
  case `reset`, it puts the `updateConfig` of `BasePlatform` on `BasicPlatform`: the
  `BasicPlatform` of Node.js writes `animation: false` (`platform.basic.js:20-22`), and the
  platform of the port keeps the option, as the DOM platform does."
- Tests: "A test-only controller subclass with its own id (the polar area subclass with option
  sharing) registers in the `setUp` of its group and unregisters in the `tearDown`."

### `doc/porting-flow.md`

- §5, the phase 7 row: wave 2 ports `controller.polarArea` (13 of 14 spec cases pass, 1
  `blocked: plugin.tooltip`), with 44 reference cases and 9 themed twins.

### `doc/performance.md`

- No new figures. The unit adds no form of the step 7 list and no fast path.

### `doc/differences.md`

- No new row and no new marker. The hunk has no marker (Chart.js ADR 0028 §5).

### `doc/status.yaml`

- `src/controllers/controller.polarArea.js`: "ported (`PolarAreaController` extends
  `DatasetController`. `PolarAreaController.jsClass` is the class as a value with the statics
  `id`, `defaults` and `overrides` ([Chart.js ADR 0020](adr/0020-registry-and-component-classes.md)
  §3). The reads of parsed items use `jsGetKey` and `jsGetIndex`, and `getMinMax` compares the
  raw values with `jsLessThan` ([Chart.js ADR 0027](adr/0027-parsed-data.md), proposed). The
  controller reads the members of other modules through `lib/src/types/`, casts the scale `r`
  to `types.RadialLinearScale` once, ports the #12238 hunk of `spacing` and `spacingMode`, and
  holds the legend functions in `overrides` ([Chart.js ADR 0028](adr/0028-controller-interfaces.md),
  proposed). Not a pure layer: it imports `core.datasetController`.
  `test/port/controllers/controller.polarArea_test.dart` compares 9 charts with upstream, and
  the same 9 charts with the light preset, with 7 `parsed:` cases of Chart.js ADR 0027 and 28
  `interfaces:` cases of Chart.js ADR 0028 (11 of them on a test subclass with option sharing),
  and 4 tests without generated values ([Chart.js ADR 0030](adr/0030-controller-test-strategy.md),
  proposed))".
- `test/specs/controller.polarArea.tests.js`: "ported ({{passed}}/{{cases}} cases pass on
  {{platforms}}; {{skipped:blocked: plugin.tooltip|case}} skipped: `blocked: plugin.tooltip`.
  The 3 cases of the spacing modes come with the commit pin (ledger row #12238). Each chart case
  is a `testWidgets` case with the conventions of
  [Chart.js ADR 0030](adr/0030-controller-test-strategy.md) §13. The fixture group `auto` waits
  for the fixture runner ([Chart.js ADR 0029](adr/0029-fixture-smoke-runner.md), proposed).
  `test/port/controllers/controller.polarArea_test.dart` covers the controller)".
- `src/controllers/index.js`: add `PolarAreaController` to the partial text.
- Port-only rows, in the form of the bar rows:
  - `test/port/controllers/controller.polarArea_test.dart`: "The reference tests of
    `lib/src/controllers/controller.polarArea.dart`: the 9 cases of §7 and the 35 pin cases (7
    `parsed:`, 28 `interfaces:`) against `controller_polar_area_reference.dart`, the 9 cases
    again with the light preset, a stale-key test, the group of the option-sharing subclass,
    and the groups `parsed data` and `interfaces`. VM only (`@TestOn('vm')`)".
  - `test/port/controllers/controller_polar_area_reference.dart`: "Generated data of
    `controller.polarArea_test.dart`: 44 cases with their observations, hit queries and draw
    calls, with the Node.js version and architecture of the run". Tests: "written by
    `tool/reference/controller_polar_area_reference.mjs`".
  - `tool/reference/controller_polar_area_reference.mjs`: "Dev-time Node.js generator of
    `controller_polar_area_reference.dart` on `controller_chart_common.mjs`: the 9 polar area
    cases of Chart.js ADR 0030 §7, then the `parsed:` and `interfaces:` cases, with the probes
    `polarState` and `legend`, and the test subclass `polarAreaSharing`. It stops unless
    Node.js is an x64 build".
- The texts of `core.interaction.tests.js` and `scale.radialLinear.tests.js` keep
  `{{skipped:blocked: controller.polarArea}}` until L2 lifts their 2 + 2 records (work plan §3).
- Run `dart run melos run parity`.

### `doc/upstream-ledger.md`

- Row `ab79c3bf` (#12238), with IV §8.6: "`controller.polarArea` ports the controller part at the
  pin: the defaults `spacing: 0` and `spacingMode: 'proportional'`, the hunk of
  `controller.polarArea.js:204-210` (Chart.js ADR 0028 §5) and the 2 new spec cases (`:69`,
  `:85`). `test/port/controllers/controller.polarArea_test.dart` pins the 11 rows of the ADR
  table, the hover row and the subclass with option sharing. The fixtures come with the fixture
  runner." U-doughnut gives the doughnut part and the third spec case
  (`controller.doughnut.tests.js:49`).
- Row `714b48cd` (#12328): `controller.polarArea` is ported. The row keeps the status `absorbed`.
  The fixture `controller.polarArea/pointLabels/overlapping` comes with the fixture runner
  (F-int). The reference case `point labels` of this unit has no overlapping labels.

## Open items

1. The case `reset` replaces `BasicPlatform.prototype.updateConfig` with the no-op of
   `BasePlatform` in the generator, for this case only. Without it, Node.js runs the chart with
   `animation: false`, and the branches `animateScale` and `animateRotate` of `:185-192` cannot
   run upstream. The port runs on its own platform, which keeps the option, as a browser does.
   The case has `duration: 0`, so each value is set at once. The first run without this change
   failed on `$animations` in the element options: the Dart chart had the animations, the Node.js
   chart did not. The reviewer can check that this generator change is acceptable.
2. Three casts are not to a `types` interface (the grep of IV §4.8): `jsGet(data, 'labels')! as
   List<Object?>` in `_generateLabels` (a `labels` value that is not a List throws a `TypeError`
   at the cast, where upstream throws a `TypeError` at `map`), `properties['options']! as
   AnyObject` (the code of IV §4.5) and `jsCall(...)! as List<AnyObject>` in `parseObjectData`
   (the result of `parseObjectDataRadialScale` is a `List<Map<String, Object?>>`). U-radar has
   the same `parseObjectData`. The step 6 review and W2-int can decide one form for the three
   casts.
3. The sharing rows rename `options.datasets.polarArea` to `options.datasets.polarAreaSharing`
   (row 4 of the table). The ADR probe patched the prototype of the class with the id
   `polarArea`. A subclass with its own id reads the dataset defaults of its own type. With the
   rename, row 4 gives the value of the table (4, parallel; frozen).
4. `controller.polarArea.js` has no `getMaxOverflow` and no `draw`. The arcs draw through
   `DatasetController.draw`. The reference draw calls cover it.

## Fixes

The fixes of the findings of `U-polarArea-review.md`. `<fix>` is
`<scratch>/wave2/U-polarArea/fix/`. The Node.js probes ran on the x64 build of Node.js v24.12.0
(`process.arch` `x64`) and the build of Chart.js at the pin.

### F1 (confirmed): fixed, with a residual for the phase lead

- `_onClick` now calls `toggleDataVisibility(_legendIndex(jsGet(legendItem, 'index')))`. The new
  top-level function `_legendIndex` takes `key = jsToString(index)` and `number =
  jsToNumber(key)`. It gives `number` when `jsNumberToString(number) == key`, else NaN. Thus the
  port writes the upstream key `ToString(index)` (`core.controller.js:882`) when that key is the
  text of a number. Any other key gives the key `'NaN'`, which matches no data index, as the
  upstream key does. The `double` parameter of `types.Chart.toggleDataVisibility` does not
  change.
- Probe `<fix>/onclick_keys.mjs` (output `onclick_keys_node.out`): the visibility of the data
  indices 0, 1 and 2 after one `onClick` on the data `[1, 2, 3]`, for 16 index values. The new
  test group "onClick with the index ... toggles the upstream key" of
  `test/port/controllers/controller.polarArea_test.dart` pins the 16 results: `null`,
  `undefined`, `true`, `false`, `''`, `'01'`, `'1.0'`, `NaN`, `'-0'`, `{}` and `1.5` give `111`;
  `'1'` and `1` give `101`; `'2'` and `[2]` give `110`; `-0` gives `011`. All 16 pass.
- Residual: `moveNumericKeys` (`core.controller.js:72-84`) moves each key whose `+key` is a
  number after a data insert or remove. This includes keys that are not the text of a number,
  for example `''` (`+''` is 0) and `'01'`. The port writes `'NaN'` for these keys, and
  `_moveNumericKeys` does not move `'NaN'`. Probe `<fix>/onclick_move.mjs` (output
  `onclick_move_node.out`): one `onClick`, then `unshift` of one item and `update()`. Upstream
  gives `1011` for `''`, `1101` for `'01'` and `1111` for `null`. The port gives `1111` for the
  three values. The form before the fix gave the upstream result after the move for `''` and
  `'01'`, but the wrong result at the click. No form with a `double` parameter gives both. The
  exact form needs a key parameter in `types.Chart` and `core.controller.dart`. These files are
  not files of this unit. The residual needs a user `generateLabels` with an index that is not
  a number, the default `onClick` and a data change after the click.
- For the phase lead: Chart.js ADR 0028 §6 (proposed) gives the form
  `toggleDataVisibility(jsToNumber(jsGet(legendItem, 'index')))` and the sentence "no reader sees
  the difference". The fix changes that form in this unit. The ADR text does not change here
  (its status and text are not files of the unit). The doughnut `_onClick`
  (`controller.doughnut.dart:713`, unit U-doughnut) has the old form. This unit did not change
  it. W2-int can apply `_legendIndex` there, or decide the key parameter for both controllers,
  and record the residual in the text of a new ADR or in `differences.md`.

### F2 (confirmed): fixed

The doc of `getLabelAndValue` and the section "The lib file" of this report now say:
`formatNumber` takes a `double`, thus the port applies `jsToNumber`.
`Intl.NumberFormat.prototype.format` applies `ToIntlMathematicalValue`. For a string with more
digits than a `double` keeps, upstream formats the exact decimal. The difference is in the
digits only (Chart.js ADR 0009). The code does not change.

### F3 (confirmed): fixed

The doc of `getMinMax` now cites `DatasetController.getMinMax` at
`core.datasetController.js:622` for the parameters `scale` and `canStack`, `Scale.getMinMax` at
`core.scale.js:303`, and the call at `core.scale.js:313`. The three lines were read at the pin.

### F4 (confirmed): fixed

Open item 2 now names the three casts that are not to a `types` interface: `:72` (`jsGet(data,
'labels')! as List<Object?>`), `properties['options']! as AnyObject` and `jsCall(...)! as
List<AnyObject>`. The step 6 review and W2-int can decide the three casts together.

### Check results

- `dart format` on the two changed Dart files: no change.
- `dart analyze --fatal-infos lib/src/controllers/controller.polarArea.dart
  test/port/controllers/controller.polarArea_test.dart test/specs/controller.polarArea_test.dart`:
  no issues.
- `flutter test test/port/controllers/controller.polarArea_test.dart
  test/specs/controller.polarArea_test.dart`: +92 ~1, all passed. The port-only file now has 79
  tests (63 and the 16 new `onClick` tests). The skip is the spec case with the reason
  `blocked: plugin.tooltip`.
- The generator and the generated data did not change.
- The fixes changed only `lib/src/controllers/controller.polarArea.dart`,
  `test/port/controllers/controller.polarArea_test.dart` and this report. No `flutter_tester`
  process of this fixer stays. The process 67820 belongs to another session.
