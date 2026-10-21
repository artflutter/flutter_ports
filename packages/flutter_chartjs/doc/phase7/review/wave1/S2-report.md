# Wave 1, unit S2 (core layer): report

## Status

Done. The core layer of the work-plan row S2 is in place: the DC reads of PD §3, the removal of
the private index helpers of DC and of `core.controller.dart`, the type members and the concrete
`@override`s of IV §2 and §3, the `points` setter of IV §3.6, the writable `ctx` of TS §1.1, the
implementers of IV §3.8 and the `DemoChart` members of GA §3.0. The tests of IV §7.1, §7.2 and the
`ctx` case of TS §1.8 pass. The full gate passes. `flutter test` and `dart analyze` in
`apps/chartjs_gallery` pass.

## Files that changed

The paths are relative to `packages/flutter_chartjs/`, except where a path starts with `apps/`.

| File | Change |
|---|---|
| `lib/src/core/core.datasetController.dart` | PD §3.1: the reads of parsed items and stack objects call `jsGetKey` (`:207`, `:311`, `:349-350`, `_clearStacks`, `:1047-1048`, `applyStack`, `updateRangeFromParsed`, `getMinMax` `skip`, `getLabelAndValue`). PD §3.2: `_item`, `_getIndex`, `_setAt`, `_lessThan` and `_toPrimitive` are removed; the callers call `jsGetIndex`, `jsSetIndex` and `jsLessThan`. `_parsedValue` (`isFinite` reads, `_updateStacks` `:351`, `_clearStacks` `:428`) and the resolver reads do not change. IV §3.3: `@override` on `options`, `getParsed`, `getStyle` (its `ignore` line goes: the lint does not fire on an override) and `resolveDataElementOptions`; `getLabelAndValue` gives `({Object? label, String value})` with the doc of the spec; `updateElement` takes `types.Element` and casts once to `Element` for `assign`. TS §1.1: `ctx` is a writable field with the doc of the spec. |
| `lib/src/core/core.controller.dart` | PD §3.3: `_item` is removed; `buildOrUpdateControllers`, `getDatasetMeta` and `isDatasetVisible` call `jsGetIndex` (new `show jsGetIndex`). IV §3.1: `@override` on `update`, `getVisibleDatasetCount`, `isDatasetVisible`, `toggleDataVisibility`; the field `legend` (after `_minPadding`: the class has no other plugin-written field); the early return of `getDataVisibility`. IV §3.2: `@override` on `ChartMeta.dataset_`; the field `ChartMeta.total`, `'total'` in `operator []` and `operator []=`, and the docs of both operators. |
| `lib/src/core/core.element.dart` | `@override` on `active` and `hidden`. |
| `lib/src/core/core.scale.dart` | `@override` on `ticks`, `startPixel`, `endPixel`, `cache`, `getValueForPixel`, `getPixelForTick`, `getPixelForDecimal`, `getBasePixel` and `getLineWidthForValue`. |
| `lib/src/scales/scale.radialLinear.dart` | `RadialLinearScale ... implements types.RadialLinearScale` (with a doc paragraph), `@override` on `xCenter`, `yCenter`, `getIndexAngle`, `getDistanceFromCenterForValue` and `getPointPositionForValue`. The other files of `lib/src/scales/` needed no change: their overrides already carry `@override`. |
| `lib/src/types/index.dart` | IV §2.1: `ChartMeta.dataset_`, `ChartMeta.total`; the five `Chart` members; the four `DatasetController` members; the nine `Scale` members; the new `RadialLinearScale`; `Element.active` and `Element.hidden`; `PointElement.size`; `LineElement.updateControlPoints`; the new `LegendElement`. |
| `lib/src/elements/element.point.dart` | `@override` on `size`. |
| `lib/src/elements/element.line.dart` | IV §3.6: the setter `points` takes `List<types.Element>`; the by-name case `'points'` copies a `List<types.Element>`; the top-level `_pointElements` (after the class, because it is top level) with `growable: false` (no reader adds or removes an item: `grep` of `lib/`, `test/`, the gallery and `chartjs_test_utils/lib` found none); the `///` list of `operator []=`; `@override` on `updateControlPoints`. Both `DIVERGES` markers stay. |
| `lib/src/helpers/helpers.extras.dart` | IV §3.5: `getStartAndCountOfVisiblePoints` takes `List<Element>`, with the doc line. |
| `lib/src/helpers/helpers.config.dart` | PD §3.4: `_parseObjectDataRadialScale` reads `jsGetIndex(data, index)`. `jsNumberToString` has another user (`:692`), so its import stays. |
| `test/specs/helpers.segment_test.dart` | `_Point`: `active`, `hidden`, `size`; the import of `js_undefined.dart`. |
| `test/port/helpers/helpers.segment_test.dart` | `_Point` and `_RadialPoint` (a tenth implementer that the table of IV §3.8 does not list): `active`, `hidden`, `size`. |
| `test/port/helpers/helpers.extras_test.dart` | `_Point`: `active`, `hidden`, `size`; `_Dataset`: `active`, `hidden`; one new case (IV §7.2). |
| `test/port/helpers/helpers.collection_test.dart` | `_Point`: `active`, `hidden`, `size`. |
| `tool/bench/bench_flutter_test.dart` | `_Point`: `active`, `hidden`, `size`; the import of `js_undefined.dart`. |
| `tool/bench/src/cases_data.dart` | `_PointElement`: `active`, `hidden`, `size`; the import of `js_undefined.dart`. |
| `test/port/core/core.datasetController_test.dart` | `_Meta`: `dataset_` (gives the existing `datasetObject`, the `_dataset` of the fake) and `total`; `@override` on `isDatasetVisible` of `_FakeChart`. |
| `test/port/platform/fake_chart.dart` | **Not in the S2 row.** `FakeChart.update([String mode = 'default'])` is not a valid override of the new `types.Chart.update([Object? mode])`: the package does not compile without the change. The method now takes `[Object? mode = 'default']`, carries `@override`, and adds `mode! as String` to `updates`. The behavior does not change. |
| `apps/chartjs_gallery/lib/demo/demo_chart.dart` | GA §3.0: `isDatasetVisible`, `getVisibleDatasetCount`, `toggleDataVisibility`, `update` and `legend`, with the results of the spec and a `///` line with the upstream line for each. |
| `test/port/types/index_test.dart` | New (IV §7.1). |
| `test/port/core/core.controller_test.dart` | Groups `getDataVisibility` and `ChartMeta.total` (IV §7.1); the import of `notifyArrayListeners`. |
| `test/port/elements/element.line_test.dart` | Group `adapt-line-points-elements`: four new cases (IV §7.2). |
| `test/port/core/core.datasetController_chart_test.dart` | Group `the writable ctx (Chart.js ADR 0030)`: the `ctx` case of TS §1.8; the import of `createMockContext`. |
| `doc/phase7/review/wave1/S2-report.md` | This report (new). |

## Tests that were added

- `test/port/types/index_test.dart` (`@TestOn('vm')`, `flutter_test`, 9 `testWidgets` cases). The
  bar and polar area controllers are not ported yet. Thus the charts use the test controllers
  `scaleTest` (category and linear) and `radialTest` (radialLinear) of `scale_chart_harness.dart`,
  as IV §7.1 permits for the radial scale. Each case reads the new members through a variable of
  the interface type and compares them with the concrete members:
  - `types.Chart`: `isDatasetVisible(0)` true and `(1)` false, `getVisibleDatasetCount()` 1,
    `legend` Dart `null`, `toggleDataVisibility(1)` then `getDataVisibility(1)` false, and
    `update()` through the interface builds the element of a new data item.
  - `types.ChartMeta`: `dataset_` is `identical` to the dataset Map; `total` Dart `null` and
    `meta['total']` `undefined` before a write; a write through the interface.
  - `types.DatasetController`: `options` (`identical`), `getParsed(0)` (`identical`),
    `getParsed(2)` `undefined`; `getStyle(0)`, `getStyle(0, true)` and
    `resolveDataElementOptions(0)` with the same keys and values. The comparison reads the
    options with `jsObjectKeys` and `jsGet` into a `bool`: no option object goes into a failure
    message.
  - `types.Element`: `active` false, `hidden` `undefined`, then the written values.
  - `types.Scale`: the 9 members on the scales `x` and `y`.
  - `types.RadialLinearScale`: `chart.scales['r'] is types.RadialLinearScale`, the 5 members; a
    cartesian scale is not a `types.RadialLinearScale`.
  - `updateElement` with a `types.Element` variable; the record type of `getLabelAndValue`.
- `test/port/core/core.controller_test.dart`, group `getDataVisibility` (4 `testWidgets` cases):
  true for 0, 1, 1.5, -1, -0.0, NaN, infinity and 1e21 without a hidden index; one toggle and a
  second toggle of 3 (the Map keeps `'3': false`); the keys 1.5 and NaN; the moves of
  `_updateHiddenIndices` with the expected values of `core.controller.tests.js:2109` (splice,
  unshift, shift, pop, toggle and splice insert). The upstream case uses a pie chart. The case
  uses two datasets of the test controller `test` with the same changes, and calls
  `notifyArrayListeners` after each change, as the hooked array methods do. After the pop, the
  Map is empty again, and the early return gives the upstream result.
- `test/port/core/core.controller_test.dart`, group `ChartMeta.total` (1 case): Dart `null` and
  `undefined` at the start; `meta['total'] = 5` gives 5.0; `undefined` gives Dart `null`; `'a'`
  throws a `TypeError` and does not change the field.
- `test/port/elements/element.line_test.dart`, group `adapt-line-points-elements` (4 new cases, pure,
  `package:test`): a `List<types.PointElement>` stays the same list (setter and by name); a
  `List<types.Element>` of 3 point elements gives a typed copy with `identical` items in the same
  order, and drops the segments, the path and the control points state (setter and by name); a
  plain `Element` in the list throws a `TypeError` (setter and by name), and the points do not
  change; `undefined` clears the points, and `5` throws the `ArgumentError`.
- `test/port/helpers/helpers.extras_test.dart`, group `_getStartAndCountOfVisiblePoints`: the same
  items in a `List<Element>` give the result of the `List<PointElement>` (two pixel functions,
  `animationsDisabled` true and false).
- `test/port/core/core.datasetController_chart_test.dart`, group `the writable ctx (Chart.js ADR
  0030)`: `controller.ctx = recording`, `chart.draw()`: the two point circles (`arc`) and the line
  (`stroke`) are on `recording`; `chart.ctx` does not change; after the write of `chart.ctx` back,
  the next draw does not reach `recording`.

No existing test changed, except the implementers of IV §3.8 and `fake_chart.dart` (see above).

## Checks

| Command | Result |
|---|---|
| `dart run melos run format:check` | 370 files, 0 changed |
| `dart run melos run analyze` | No issues (covers `apps/chartjs_gallery`) |
| `dart run melos run test --no-select` | All passed: chartjs_gallery +95; chartjs_test_utils +139; flutter_chartjs +5366 ~474; flutter_d3_port +38 |
| `dart run melos run test:web` | All passed: flutter_chartjs +6958 ~206; chartjs_test_utils +98 |
| `dart run melos run test:cases` | passed, 37 files, 0 errors, 0 warnings (total 1036 cases: 383 passed, 0 failed, 411 skipped, 242 missing in the 17 files without Dart tests; the same counts as S1) |
| `dart run melos run check:port` | lib-imports 293 files, headers 330 files, js-semantics 115 files, port:next 195 files: passed, 0 warnings. parity: passed, 0 errors, **1 warning**: "no port-only row names `test/port/types/index_test.dart`" (`doc/status.yaml` is a W1-int file; see the doc notes) |
| `flutter test` in `apps/chartjs_gallery` | +95, all passed |
| `dart analyze --fatal-infos apps/chartjs_gallery` | No issues |

The logs of `test --no-select` and `test:web` are in
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave1/S2-test.log`
and `.../wave1/S2-web.log`. This unit leaves no `flutter_tester` process. The process 67820 of
another session (S1 report, open item 3) is still there. This unit did not start it and did not
kill it.

## Behavior changes

All existing tests pass with no change. These results change, as the specs and ADRs decide:
1. `parse` compares two `DateTime` values of the index axis by their time value
   (`jsLessThan`). The removed `_toPrimitive` of DC compared their Dart text. Thus
   `DateTime.utc(10000)` after `DateTime.utc(9999)` is now sorted, as in JavaScript (ADR 0027 §7,
   S1 open item 1).
2. `getDataVisibility` returns at once for an empty `_hiddenIndices`. The result is the upstream
   result (ADR 0028 §4).
3. A `List<types.Element>` of point elements is now a valid value of `LineElement.points`. It was
   a compile error (setter) or an `ArgumentError` (by name).

## Doc notes for W1-int

These are the notes of the specs that concern S2. W1-int adds them with the notes of S1, S3, U0
and U-bar.

`AGENTS.md`:
- `core.controller.dart` item: "`getDataVisibility` returns `true` at once for an empty
  `_hiddenIndices`. `ChartMeta.total` is a typed field (Chart.js ADR 0028). `Chart.legend` is a
  field that the legend plugin of phase 8 writes."
- `core.datasetController.dart` item: "`ctx` is writable, as the JS property `_ctx` (Chart.js ADR
  0030). `updateElement` takes a `types.Element`, and `getLabelAndValue` gives
  `({Object? label, String value})` (Chart.js ADR 0028). The reads of parsed items and stack
  objects use `jsGetKey`, and the index reads use `jsGetIndex` (Chart.js ADR 0027)."
- `lib/src/types/` (with the Layout text): "`RadialLinearScale` and `LegendElement` (Chart.js ADR
  0028). `RadialLinearScale` of `scale.radialLinear.dart` implements `types.RadialLinearScale`."
- `element.line.dart`: "The `points` setter takes `List<types.Element>` and copies a list that is
  not a `List<types.PointElement>` (Chart.js ADR 0028)."
- Tests: the sentence "The draw calls have no element draws, because `DatasetController.ctx` is
  final." is now false for the field. TS §6 gives the new text; it also needs the `drawCalls`
  change of U0. The doc of `test/port/scales/scale_chart_harness.dart` (a U0 file) has the same
  old sentence ("a final field").

`doc/porting-flow.md`: no note of its own. §2.21 (ADR 0028) and §2.23 (ADR 0030) take the summary
of the ADRs.

`doc/performance.md`: S2 did not measure. §13.2 and §13.4 take the figures of ADR 0028
(Measurements; P-B7 for `getDataVisibility`) and ADR 0030 (Evidence E3). §11.3 gets the line of
IV §8.3 ("`getDataVisibility`: the early return of Chart.js ADR 0028 §4; ADR 0025 Open 4 is
closed").

`doc/differences.md`:
- Row `adapt-line-points-elements`: the text of IV §8.4 (column "Dart file and symbol": add
  `lib/src/helpers/helpers.extras.dart` `getStartAndCountOfVisiblePoints`; column "Reason": the
  copy text; column "Pinning test": `test/port/elements/element.line_test.dart`, group
  `adapt-line-points-elements`, until U-line adds `controller.line_test.dart`, group
  `line.points`).
- Row `platform-array-events`: the code column adds `lib/src/js/js_array.dart` `jsSetIndex` (S1
  note). DC no longer has `_setAt`.

`doc/status.yaml`:
- Port-only rows: a row for `test/port/types/index_test.dart` removes the parity warning, for
  example `file: "`test/port/types/index_test.dart`"`, `contents: "The members of
  `lib/src/types/index.dart` that Chart.js ADR 0028 adds, read through the interfaces on real
  charts of the test controllers of `scale_chart_harness.dart`"`, `tests: "—"`.
- `src/types/index.d.ts`: replace "`lib/src/types` gets no member: ..." by the text of IV §8.5.
- `src/core/core.controller.js`: "`getDataVisibility` has a port-only early return for an empty
  `_hiddenIndices`; `ChartMeta.total` is a typed field (Chart.js ADR 0028)."
- `src/core/core.datasetController.js`: "`updateElement` takes a `types.Element`, and
  `getLabelAndValue` gives an `Object?` label (Chart.js ADR 0028). `ctx` is writable, as the JS
  property `_ctx` (Chart.js ADR 0030). The reads of parsed items and stack objects use
  `jsGetKey`" (and the `stacksOf` part of PD §8.5 after S3).
- `src/elements/element.line.js`: "The `points` setter copies a `List<types.Element>` of point
  elements into a `List<types.PointElement>` (Chart.js ADR 0028)."
- Then `dart run melos run parity`.

## Open items

1. `test/port/platform/fake_chart.dart` is not in the S2 row. The change is the smallest change
   that compiles (see the table). The phase lead or W1-int confirms it. Check the table of IV §3.8
   and ADR 0028 §1 ("The implementers"): they list neither this class nor `_RadialPoint` of
   `test/port/helpers/helpers.segment_test.dart`.
2. IV §3.6 says "add after `_setPoints`". `_pointElements` is a top-level function, so it is after
   the class `LineElement`, at the end of the file.
3. IV §3.1 says "after the other plugin-written fields". `Chart` has no such field. `legend` is
   after `_minPadding`, the last field of the constructor state.
4. Work-plan §0 item 5: S2 changes `lib/`, so it gets an adversarial fidelity reviewer. No
   reviewer ran in this unit.
5. The doc of `scale_chart_harness.dart` (U0) still says that `DatasetController.ctx` is final.
6. `doc/phase7-progress.md` has a change in the working tree that this unit did not make.

## Fixes

The findings are in `S2-review.md`. All three are confirmed. The fixer changed only files of the
S2 row.

| Finding | Fix |
| --- | --- |
| F1 | `lib/src/types/index.dart`, the doc of `types.Element.hidden`: core.controller.js:899 is now core.controller.js:898 (`meta.data[dataIndex].hidden = !visible;` at the pin). Note: the IV §2.1 code block (spec line 184) still gives :899. The spec is not in the S2 row, so the fixer did not change it. |
| F2 | `test/port/types/index_test.dart`, group `DatasetController.getLabelAndValue`: the `isA<({Object? label, String value})>()` check is replaced by `expect(controller.getLabelAndValue is ({String label, String value}) Function(double), isFalse)`, with a comment. The runtime type of a record comes from its field values, thus only the type of the torn-off method pins the declared return type. Probe `scratchpad/wave1/S2-fix/tearoff.dart` (`dart run`): the old return type gives `true`, the new return type gives `false`. Thus a revert of the return type fails the test. |
| F3 | `lib/src/core/core.datasetController.dart`, the doc of `getLabelAndValue`: the text now says that scatter, bubble, doughnut, pie and polar area return `labels[index] \|\| ''` of `chart.data.labels` (controller.scatter.js:51), and that radar returns `vScale.getLabels()[index]` (controller.radar.js:44), where core.scale.js:358-361 reads the scale option `labels` first, then `xLabels` or `yLabels`, and `chart.data.labels` last. The `Object?` type does not change. |

Checks after the fixes:

| Check | Result |
| --- | --- |
| `dart format` of the three files | 1 file changed by the formatter (the new `expect`), no other change |
| `dart analyze --fatal-infos` of the three files | No issues |
| `flutter test test/port/types/index_test.dart test/port/core/core.datasetController_test.dart test/port/core/core.datasetController_chart_test.dart test/port/core/core.controller_test.dart` | +122, all passed |

The full gate did not run again (work-plan §0 item 4: units in parallel run their targeted tests
only). No `flutter_tester` process of this fix stays.
